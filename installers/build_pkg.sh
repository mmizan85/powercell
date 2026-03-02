#!/usr/bin/env bash
# ============================================================
#  PowerCell — macOS .pkg Builder
#  Builds a macOS installer package (.pkg)
#
#  Requirements:
#    macOS with Xcode Command Line Tools
#    pkgbuild and productbuild (included in Xcode CLT)
#
#  Usage:
#    chmod +x installers/build_pkg.sh
#    ./installers/build_pkg.sh
#
#  Output: dist/PowerCell-2.0.pkg
# ============================================================

set -euo pipefail

VERSION="2.0"
APP_NAME="PowerCell"
IDENTIFIER="com.mizanur.powercell"
INSTALL_LOCATION="/usr/local/share/powercell"
BIN_LOCATION="/usr/local/bin"

BUILD_DIR="$(mktemp -d)"
PKG_ROOT="$BUILD_DIR/pkg_root"
SCRIPTS_DIR="$BUILD_DIR/scripts"
DIST_DIR="dist"

RED='\033[0;31m'; GREEN='\033[0;32m'; CYAN='\033[0;36m'; RESET='\033[0m'
info()    { echo -e "${CYAN}[•]${RESET} $*"; }
success() { echo -e "${GREEN}[✔]${RESET} $*"; }
error()   { echo -e "${RED}[✘]${RESET} $*" >&2; exit 1; }

info "Building $APP_NAME $VERSION macOS .pkg..."

# ── Check tools ──────────────────────────────────────────────
command -v pkgbuild    >/dev/null || error "pkgbuild not found. Install Xcode Command Line Tools."
command -v productbuild>/dev/null || error "productbuild not found."

# ── Set up package root ──────────────────────────────────────
mkdir -p "$PKG_ROOT$INSTALL_LOCATION"
mkdir -p "$PKG_ROOT$BIN_LOCATION"
mkdir -p "$SCRIPTS_DIR"
mkdir -p "$DIST_DIR"

# Copy application files
cp PowerCell.py              "$PKG_ROOT$INSTALL_LOCATION/"
cp assets/powercell_256.png  "$PKG_ROOT$INSTALL_LOCATION/" 2>/dev/null || true
cp assets/powercell_512.png  "$PKG_ROOT$INSTALL_LOCATION/" 2>/dev/null || true
chmod +x "$PKG_ROOT$INSTALL_LOCATION/PowerCell.py"

# Create launcher
cat > "$PKG_ROOT$BIN_LOCATION/powercell" << 'LAUNCHER'
#!/usr/bin/env bash
exec python3 /usr/local/share/powercell/PowerCell.py "$@"
LAUNCHER
chmod +x "$PKG_ROOT$BIN_LOCATION/powercell"

# ── Post-install script ──────────────────────────────────────
cat > "$SCRIPTS_DIR/postinstall" << 'POSTINSTALL'
#!/usr/bin/env bash
# Install Homebrew if not present
if ! command -v brew &>/dev/null; then
    echo "[PowerCell] Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)" || true
fi
echo "[PowerCell] Installation complete!"
echo "[PowerCell] Run: powercell"
POSTINSTALL
chmod +x "$SCRIPTS_DIR/postinstall"

# ── Build component .pkg ─────────────────────────────────────
info "Building component package..."
pkgbuild \
    --root "$PKG_ROOT" \
    --identifier "$IDENTIFIER" \
    --version "$VERSION" \
    --scripts "$SCRIPTS_DIR" \
    --install-location "/" \
    "$BUILD_DIR/component.pkg"

# ── Create distribution .pkg ─────────────────────────────────
cat > "$BUILD_DIR/distribution.xml" << XML
<?xml version="1.0" encoding="utf-8"?>
<installer-gui-script minSpecVersion="1">
    <title>PowerCell $VERSION</title>
    <welcome file="welcome.html" mime-type="text/html"/>
    <license file="license.txt" mime-type="text/plain"/>
    <options require-scripts="true" customize="never" allow-external-scripts="no"/>
    <pkg-ref id="$IDENTIFIER"/>
    <choices-outline>
        <line choice="default">
            <line choice="$IDENTIFIER"/>
        </line>
    </choices-outline>
    <choice id="default"/>
    <choice id="$IDENTIFIER" visible="false">
        <pkg-ref id="$IDENTIFIER"/>
    </choice>
    <pkg-ref id="$IDENTIFIER" version="$VERSION" onConclusion="none">component.pkg</pkg-ref>
</installer-gui-script>
XML

# Welcome HTML
cat > "$BUILD_DIR/welcome.html" << HTML
<html><body>
<h2>Welcome to PowerCell $VERSION</h2>
<p>PowerCell is a cross-platform software installer by <strong>Mohammad Mizanur Rahman</strong>.</p>
<p>This installer will place PowerCell in <code>/usr/local/share/powercell</code>
and create a <code>powercell</code> command in <code>/usr/local/bin</code>.</p>
<p>After installation, open Terminal and type: <code>powercell</code></p>
</body></html>
HTML

# License
cp LICENSE "$BUILD_DIR/license.txt" 2>/dev/null || echo "MIT License - Mohammad Mizanur Rahman" > "$BUILD_DIR/license.txt"

info "Building distribution package..."
productbuild \
    --distribution "$BUILD_DIR/distribution.xml" \
    --resources "$BUILD_DIR" \
    --package-path "$BUILD_DIR" \
    "$DIST_DIR/${APP_NAME}-${VERSION}.pkg"

rm -rf "$BUILD_DIR"
success "Built: $DIST_DIR/${APP_NAME}-${VERSION}.pkg"
echo ""
echo "  To install:  sudo installer -pkg $DIST_DIR/${APP_NAME}-${VERSION}.pkg -target /"
echo "  To run:      powercell"
