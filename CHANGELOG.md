# Changelog

All notable changes to PowerCell are documented here.  
Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/).

---

## [2.0.0] — 2024-12-01

### 🎉 Major Rewrite — Python

This release is a complete rewrite of the original PowerShell `WinSetupCLI.ps1`
into Python, with full cross-platform support.

### Added
- Full Python rewrite (zero external dependencies)
- **Linux support** — apt, dnf, yum, pacman, zypper, apk auto-detection
- **macOS support** — Homebrew cask + formula with automatic fallback
- 16 software categories (was 20 in legacy, now reorganised and expanded)
- 170+ app entries with Windows, Linux, and macOS package IDs
- OS badge display per app (`[ Windows ]`, `[ Linux ]`, `[ macOS ]`, `[ All ]`)
- `InstallerEngine` — fallback chain: primary ID → alt IDs → name search
- `SystemDetector` — auto-detects OS, architecture, distro, admin status
- `InstallQueue` — add/remove/clear with duplicate prevention
- Error-safe installation: one failure never stops remaining installs
- Quick install by package ID (option `I` in main menu)
- Software search by name (option `S`)
- ANSI colour UI with box-drawing, status icons, progress bar
- Auto Windows ANSI console fix via ctypes
- Dedicated **Linux-Specific Tools** category (cat 15)
- Dedicated **macOS-Specific Tools** category (cat 16)
- GitHub Actions release workflow
- Shell installer (`install.sh`) for Linux/macOS
- PowerShell installer (`install.ps1`) for Windows
- PyInstaller spec for building standalone `.exe`
- macOS `.pkg` builder script
- Full project documentation (`README.md`, `USAGE.md`)

### Changed
- Project renamed from `WinSetup CLI` to **PowerCell**
- Version numbering restarted at 2.0 to reflect full rewrite
- All classes and functions follow PEP 8 and type-annotated

### Removed
- PowerShell-only codebase (kept as `WinSetupCLI.ps1` for reference)

---

## [1.5.0] — 2024-06-01 *(WinSetup CLI — Legacy)*

### Added
- 500+ software entries across 20 Windows categories
- Queue system for batch installation
- Custom search & install by software name
- System compatibility checking (architecture, OS version)
- Admin privilege detection
- ASCII art banner

### Fixed
- WMI query fallback for older PowerShell versions

---

## [1.0.0] — 2024-01-01 *(WinSetup CLI — Initial Release)*

### Added
- Initial release of WinSetup CLI
- Basic winget-based installer for Windows
- 10 software categories
- Simple numbered menu interface
