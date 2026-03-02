# Contributing to PowerCell

Thank you for your interest in contributing! 🎉

---

## How to Contribute

### 1. Fork & Clone
```bash
git clone https://github.com/yourusername/powercell.git
cd powercell
```

### 2. Create a branch
```bash
git checkout -b feature/add-new-apps
# or
git checkout -b fix/install-fallback
```

### 3. Make your changes

- All app entries live in the `build_catalog()` function in `PowerCell.py`
- Each category is a dictionary entry
- Follow the existing `app(...)` helper pattern
- Test on your platform before submitting

### 4. Verify — no syntax errors
```bash
python3 -c "import ast; ast.parse(open('PowerCell.py').read()); print('OK')"
python3 PowerCell.py   # manual smoke test
```

### 5. Commit with a clear message
```bash
git commit -m "feat: add 5 new Linux tools to System Utilities"
git commit -m "fix: add fallback ID for VLC on macOS"
git commit -m "docs: improve README installation section"
```

### 6. Open a Pull Request

---

## Adding New Software

```python
app("Software Name",
    win   = "winget.PackageID",
    linux = "apt-package-name",
    mac   = "homebrew-cask-or-formula",
    app_type = "TypeLabel",
    os_sup   = A,       # A / W / L / M / WL / WM / LM
    lic      = FREE,    # FREE / PAID / FREEMIUM / TRIAL
    alt_win   = [],     # fallback winget IDs
    alt_linux = [],     # fallback apt/dnf names
    alt_mac   = [],     # fallback brew names
),
```

### Finding the correct IDs
- **winget**: `winget search "Software Name"`
- **apt**: `apt-cache search keyword`
- **dnf**: `dnf search keyword`
- **brew**: `brew search keyword`

---

## Code Style

- Python 3.9+ compatible
- Follow PEP 8
- Use type annotations for new functions
- Keep all logic inside appropriate classes
- No external dependencies — standard library only

---

## Reporting Bugs

Open an issue with:
- Your OS and version
- Python version (`python3 --version`)
- The software that failed to install
- The error message shown

---

*Thank you for making PowerCell better!*
