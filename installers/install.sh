#!/usr/bin/env bash
# ============================================================
#  PowerCell — Linux & macOS Installer
#  Author : Mohammad Mizanur Rahman
#  Usage  : curl -fsSL https://raw.githubusercontent.com/yourusername/powercell/main/installers/install.sh | bash
# ============================================================

set -euo pipefail

REPO="https://github.com/yourusername/powercell"
RAW="https://raw.githubusercontent.com/yourusername/powercell/main"
INSTALL_DIR="$HOME/.local/share/powercell"
BIN_DIR="$HOME/.local/bin"
SCRIPT_URL="$RAW/PowerCell.py"

# ── Colours ──────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; RESET='\033[0m'

info()    { echo -e "${CYAN}[•]${RESET} $*"; }
success() { echo -e "${GREEN}[✔]${RESET} $*"; }
warn()    { echo -e "${YELLOW}[!]${RESET} $*"; }
error()   { echo -e "${RED}[✘]${RESET} $*" >&2; }
die()     { error "$*"; exit 1; }

# ── Banner ───────────────────────────────────────────────────
echo -e "${CYAN}${BOLD}"
cat << 'BANNER'
  ____                          ____     _ _
 |  _ \ _____      _____ _ __  / ___|___| | |
 | |_) / _ \ \ /\ / / _ \ '__|| |   / _ \ | |
 |  __/ (_) \ V  V /  __/ |   | |__|  __/ | |
 |_|   \___/ \_/\_/ \___|_|    \____\___|_|_|

BANNER
echo -e "${RESET}${BOLD}  PowerCell Installer${RESET}"
echo -e "  ${CYAN}Cross-Platform Software Installer by Mohammad Mizanur Rahman${RESET}"
echo ""

# ── Detect OS ────────────────────────────────────────────────
OS="$(uname -s)"
ARCH="$(uname -m)"
info "Detected OS: $OS ($ARCH)"

# ── Check Python ─────────────────────────────────────────────
PYTHON=""
for cmd in python3 python; do
    if command -v "$cmd" &>/dev/null; then
        VER=$("$cmd" --version 2>&1 | grep -oP '\d+\.\d+' | head -1)
        MAJOR=$(echo "$VER" | cut -d. -f1)
        MINOR=$(echo "$VER" | cut -d. -f2)
        if [ "$MAJOR" -ge 3 ] && [ "$MINOR" -ge 9 ]; then
            PYTHON="$cmd"
            success "Python $VER found: $cmd"
            break
        fi
    fi
done

if [ -z "$PYTHON" ]; then
    warn "Python 3.9+ not found. Attempting to install..."
    if command -v apt-get &>/dev/null; then
        sudo apt-get update -qq && sudo apt-get install -y python3 python3-pip
        PYTHON="python3"
    elif command -v dnf &>/dev/null; then
        sudo dnf install -y python3
        PYTHON="python3"
    elif command -v pacman &>/dev/null; then
        sudo pacman -Sy --noconfirm python
        PYTHON="python3"
    elif command -v brew &>/dev/null; then
        brew install python
        PYTHON="python3"
    else
        die "Could not install Python automatically. Please install Python 3.9+ manually and re-run this script."
    fi
fi

# ── Install Homebrew on macOS if missing ─────────────────────
if [ "$OS" = "Darwin" ] && ! command -v brew &>/dev/null; then
    info "Installing Homebrew (required for macOS package installs)..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

# ── Create install directory ─────────────────────────────────
mkdir -p "$INSTALL_DIR" "$BIN_DIR"

# ── Download PowerCell.py ────────────────────────────────────
info "Downloading PowerCell.py..."
if command -v curl &>/dev/null; then
    curl -fsSL "$SCRIPT_URL" -o "$INSTALL_DIR/PowerCell.py"
elif command -v wget &>/dev/null; then
    wget -q "$SCRIPT_URL" -O "$INSTALL_DIR/PowerCell.py"
else
    die "Neither curl nor wget found. Please install one and retry."
fi
chmod +x "$INSTALL_DIR/PowerCell.py"
success "Downloaded to $INSTALL_DIR/PowerCell.py"

# ── Create launcher script ───────────────────────────────────
cat > "$BIN_DIR/powercell" << LAUNCHER
#!/usr/bin/env bash
exec $PYTHON "$INSTALL_DIR/PowerCell.py" "\$@"
LAUNCHER
chmod +x "$BIN_DIR/powercell"
success "Launcher created at $BIN_DIR/powercell"

# ── Add BIN_DIR to PATH if needed ────────────────────────────
SHELL_RC=""
case "$SHELL" in
    */zsh)  SHELL_RC="$HOME/.zshrc" ;;
    */bash) SHELL_RC="$HOME/.bashrc" ;;
    */fish) SHELL_RC="$HOME/.config/fish/config.fish" ;;
esac

if [ -n "$SHELL_RC" ] && ! grep -q "$BIN_DIR" "$SHELL_RC" 2>/dev/null; then
    echo "" >> "$SHELL_RC"
    echo "# PowerCell" >> "$SHELL_RC"
    echo "export PATH=\"\$PATH:$BIN_DIR\"" >> "$SHELL_RC"
    info "Added $BIN_DIR to PATH in $SHELL_RC"
    info "Run: source $SHELL_RC  (or open a new terminal)"
fi

# ── Desktop entry (Linux only) ───────────────────────────────
if [ "$OS" = "Linux" ] && [ -d "$HOME/.local/share/applications" ]; then
    cat > "$HOME/.local/share/applications/powercell.desktop" << DESKTOP
[Desktop Entry]
Name=PowerCell
Comment=Cross-Platform Software Installer
Exec=$BIN_DIR/powercell
Icon=$INSTALL_DIR/powercell_256.png
Terminal=true
Type=Application
Categories=System;PackageManager;
DESKTOP
    # Try to download icon too
    curl -fsSL "$RAW/assets/powercell_256.png" \
        -o "$INSTALL_DIR/powercell_256.png" 2>/dev/null || true
    success "Desktop entry created"
fi

# ── Done ─────────────────────────────────────────────────────
echo ""
echo -e "${GREEN}${BOLD}╔══════════════════════════════════════════╗${RESET}"
echo -e "${GREEN}${BOLD}║   PowerCell installed successfully! ⚡   ║${RESET}"
echo -e "${GREEN}${BOLD}╚══════════════════════════════════════════╝${RESET}"
echo ""
echo -e "  Run:  ${CYAN}${BOLD}powercell${RESET}"
echo -e "  Or:   ${CYAN}${BOLD}$PYTHON $INSTALL_DIR/PowerCell.py${RESET}"
echo ""
echo -e "  GitHub: ${CYAN}$REPO${RESET}"
echo ""

# Launch immediately if user wants
read -r -p "  Launch PowerCell now? [y/N] " LAUNCH
if [[ "${LAUNCH,,}" == "y" ]]; then
    exec "$PYTHON" "$INSTALL_DIR/PowerCell.py"
fi
