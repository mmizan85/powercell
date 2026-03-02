<div align="center">

<img src="assets/powercell_256.png" width="120" alt="PowerCell Logo"/>

# ⚡ PowerCell

### Cross-Platform Professional Software Installer

[![Python](https://img.shields.io/badge/Python-3.9%2B-blue?logo=python&logoColor=white)](https://python.org)
[![Windows](https://img.shields.io/badge/Windows-✔-0078D4?logo=windows&logoColor=white)](https://microsoft.com/windows)
[![Linux](https://img.shields.io/badge/Linux-✔-FCC624?logo=linux&logoColor=black)](https://kernel.org)
[![macOS](https://img.shields.io/badge/macOS-✔-999999?logo=apple&logoColor=white)](https://apple.com/macos)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)
[![Version](https://img.shields.io/badge/Version-2.0-cyan)](CHANGELOG.md)
[![Author](https://img.shields.io/badge/Author-Mohammad%20Mizanur%20Rahman-orange)](https://github.com/yourusername)

> **PowerCell** is a beautiful, zero-dependency, command-line software installer that works on Windows, Linux, and macOS. Select software from 16 categories (170+ apps), queue them, and install everything with a single keystroke.

</div>

---

## 📋 Table of Contents

- [Features](#-features)
- [Screenshots](#-screenshots)
- [Requirements](#-requirements)
- [Installation](#-installation)
  - [Windows](#windows)
  - [Linux](#linux)
  - [macOS](#macos)
- [Usage](#-usage)
- [Software Categories](#-software-categories)
- [How It Works](#-how-it-works)
- [Architecture](#-architecture)
- [Contributing](#-contributing)
- [Author](#-author)
- [License](#-license)

---

## ✨ Features

| Feature | Description |
|--------|-------------|
| 🖥️ **Cross-Platform** | Runs natively on Windows, Linux, and macOS |
| 📦 **170+ Apps** | Curated catalog across 16 categories |
| 🏷️ **OS Badges** | Every app shows which OS it supports at a glance |
| 🔍 **Smart Search** | Find any software by name instantly |
| 🔁 **Fallback IDs** | Tries multiple package IDs if the primary one fails |
| 🛡️ **Error-Safe** | Failed installs never stop the rest of the queue |
| ⚡ **Queue System** | Add multiple apps, then install all at once |
| 🎨 **ANSI UI** | Beautiful coloured terminal interface |
| 0️⃣ **No Dependencies** | Pure Python standard library only |
| 🔧 **Auto-Detection** | Detects OS, architecture, package manager, and admin status |

---

## 📸 Screenshots

```
╔══════════════════════════════════════════════════════════════════════════════╗
║                  PowerCell — Cross-Platform Software Installer               ║
╚══════════════════════════════════════════════════════════════════════════════╝

  OS: Ubuntu 22.04 | Arch: x64 | Python: 3.12.0 | Mode: Admin
  Queue: 3 item(s) in queue
────────────────────────────────────────────────────────────────────────────────

  MAIN MENU — SELECT A CATEGORY
────────────────────────────────────────────────────────────────────────────────

  [01] Web Browsers               Internet browsers for web surfing
       (10 available)

  [02] Communication Tools        Messaging, chat and video calling apps
       (10 available)
  ...
  [99]  START INSTALLATION  (3 items)
  [ S ]  Search software by name
  [ I ]  Install a single package by ID / name
```

---

## 📋 Requirements

| Platform | Requirement |
|----------|------------|
| **All** | Python 3.9 or newer |
| **Windows** | [winget](https://aka.ms/getwinget) (App Installer — pre-installed on Windows 11, available for Windows 10) |
| **Linux** | `apt`, `dnf`, `pacman`, `zypper`, or `apk` (auto-detected) |
| **macOS** | [Homebrew](https://brew.sh) |

> **No Python packages required.** PowerCell uses only the Python standard library.

---

## 🚀 Installation

### Quickest way (all platforms)

```bash
# 1. Clone the repository
git clone https://github.com/mmizan85/powercell.git
cd powercell

# 2. Run
python PowerCell.py
```

---

### Windows

#### Option A — Run directly (recommended)
```powershell
# Ensure winget is available (Windows 10/11)
winget --version

# Clone and run
git clone https://github.com/mmizan85/powercell.git
cd powercell
python PowerCell.py
```

#### Option B — Windows Installer (.exe)
Download the pre-built installer from [**Releases**](https://github.com/mmizan85/powercell/releases):

```
PowerCell-Setup-Windows.exe
```

Double-click to install, then launch **PowerCell** from the Start Menu or Desktop shortcut.

#### Option C — PowerShell one-liner
```powershell
irm https://raw.githubusercontent.com/mmizan85/powercell/main/installers/install.ps1 | iex
```

---

### Linux

#### Option A — Run directly
```bash
# Clone
git clone https://github.com/mmizan85/powercell.git
cd powercell

# Make executable
chmod +x PowerCell.py

# Run
python3 PowerCell.py
# or
./PowerCell.py
```

#### Option B — Shell one-liner installer
```bash
curl -fsSL https://raw.githubusercontent.com/mmizan85/powercell/main/installers/install.sh | bash
```

#### Option C — Debian/Ubuntu .deb package
```bash
# Download from Releases page
wget https://github.com/mmizan85/powercell/releases/latest/download/powercell_2.0_amd64.deb
sudo dpkg -i powercell_2.0_amd64.deb
powercell
```

---

### macOS

#### Option A — Run directly
```bash
git clone https://github.com/yourusername/powercell.git
cd powercell
python3 PowerCell.py
```

#### Option B — Homebrew (recommended)
```bash
brew tap mmizan85/powercell
brew install powercell
powercell
```

#### Option C — macOS installer (.pkg)
Download from [**Releases**](https://github.com/mmizan85/powercell/releases):
```
PowerCell-2.0.pkg
```

---

## 🎮 Usage

### Main Menu Navigation

| Key | Action |
|-----|--------|
| `01`–`16` | Open a software category |
| `99` | Start installing all queued apps |
| `S` | Search for software by name |
| `I` | Quick install by package ID or name |
| `V` | View current installation queue |
| `C` | Clear the queue |
| `Q` | Quit |

### Category Menu

| Key | Action |
|-----|--------|
| `1`–`N` | Toggle app in/out of queue |
| `A` | Add all compatible apps to queue |
| `B` | Back to main menu |

### Quick Install (Option I)
Type any package name or ID directly:
```
winget ID   →  e.g.  Microsoft.VisualStudioCode
apt package →  e.g.  neovim
brew cask   →  e.g.  rectangle
```

### OS Badge Legend
| Badge | Meaning |
|-------|---------|
| `[ Windows ]` | Windows only (installed via winget) |
| `[  Linux  ]` | Linux only (installed via apt/dnf/pacman…) |
| `[  macOS  ]` | macOS only (installed via Homebrew) |
| `[   All   ]` | All three platforms supported |

---

## 📦 Software Categories

| # | Category | Apps | Platforms |
|---|----------|------|-----------|
| 01 | 🌐 Web Browsers | 10 | All |
| 02 | 💬 Communication Tools | 10 | All |
| 03 | 💻 Development Tools | 15 | All |
| 04 | 🎵 Media & Entertainment | 12 | All |
| 05 | 🔧 System Utilities | 12 | All |
| 06 | 📄 Office & Productivity | 12 | All |
| 07 | 🔒 Security & Privacy | 12 | All |
| 08 | 🎨 Graphics & Design | 10 | All |
| 09 | 🎮 Gaming Platforms | 10 | Win/Mac+ |
| 10 | 🌐 Networking Tools | 10 | All |
| 11 | 🗄️ Database Tools | 10 | All |
| 12 | ☁️ Cloud & DevOps | 10 | All |
| 13 | ✍️ Writing & Notes | 10 | All |
| 14 | 💰 Finance & Business | 10 | Win/Mac |
| 15 | 🐧 Linux-Specific Tools | 10 | Linux |
| 16 | 🍎 macOS-Specific Tools | 10 | macOS |

---

## ⚙️ How It Works

### Installation Flow

```
User selects apps
        │
        ▼
   InstallQueue
        │
        ▼
SystemDetector ──► Detects OS, arch, package manager, admin status
        │
        ▼
 InstallerEngine
        │
   ┌────┴────┐
   │         │
Windows    Linux/macOS
   │         │
winget    apt/dnf/      brew
install   pacman…    cask/formula
   │         │
   └────┬────┘
        │
Primary ID ──► Alt IDs ──► Name search ──► InstallResult
                                                │
                              ┌─────────────────┼─────────────────┐
                            "ok"             "fail"            "skip"
                              │                 │                 │
                         Logged             Logged            Logged
                    (queue continues in all cases)
```

### Package Manager Detection (Linux)
PowerCell automatically selects the right package manager:
- **apt / apt-get** → Debian, Ubuntu, Mint, Pop!_OS
- **dnf** → Fedora, RHEL 8+, CentOS Stream
- **yum** → RHEL 7, CentOS 7
- **pacman** → Arch Linux, Manjaro, EndeavourOS
- **zypper** → openSUSE
- **apk** → Alpine Linux

---

## 🏗️ Architecture

```
powercell/
├── PowerCell.py              # Main application (single file)
├── WinSetupCLI.ps1           # Original PowerShell version (legacy)
├── assets/
│   ├── powercell.ico         # Windows icon (multi-size: 16–256px)
│   ├── powercell_256.png     # PNG icon 256×256
│   └── powercell_512.png     # PNG icon 512×512
├── installers/
│   ├── install.sh            # Linux/macOS shell installer
│   ├── install.ps1           # Windows PowerShell installer
│   ├── build_exe.spec        # PyInstaller spec (Windows .exe)
│   └── build_pkg.sh          # macOS .pkg builder script
├── .github/
│   └── workflows/
│       └── release.yml       # GitHub Actions release workflow
├── docs/
│   └── USAGE.md              # Extended usage guide
├── README.md                 # This file
├── LICENSE                   # MIT License
├── CHANGELOG.md              # Version history
└── .gitignore                # Git ignore rules
```

### Class Overview

| Class | Responsibility |
|-------|---------------|
| `SystemDetector` | One-time OS/arch/admin/tool detection at startup |
| `AppEntry` | Data model for a single installable application |
| `InstallResult` | Result of a single install attempt |
| `InstallerEngine` | Platform-specific install logic with fallback chains |
| `InstallQueue` | Manages the ordered list of apps to install |
| `PowerCellApp` | Main controller: UI loop, menus, orchestration |
| `Colors` | ANSI colour constants + Windows console fix |

---

## 🤝 Contributing

Contributions are very welcome!

1. **Fork** the repository
2. **Create** a feature branch: `git checkout -b feature/add-new-apps`
3. **Add** your apps to the `build_catalog()` function in `PowerCell.py`
4. **Test** on your platform: `python3 PowerCell.py`
5. **Commit**: `git commit -m "feat: add 10 new Linux tools to cat 15"`
6. **Push**: `git push origin feature/add-new-apps`
7. **Open** a Pull Request

### Adding a New App

```python
app("App Name",
    win   = "Publisher.AppName",     # winget ID
    linux = "package-name",          # apt/dnf/pacman name
    mac   = "homebrew-cask-name",    # brew cask or formula
    app_type = "Category",
    os_sup   = A,                    # A=All, W=Windows, L=Linux, M=macOS
    lic      = FREE,                 # FREE, PAID, FREEMIUM, TRIAL
    alt_win  = ["Alt.WingetID"],     # fallback IDs
),
```

---

## 👤 Author

<div align="center">

**Mohammad Mizanur Rahman**

[![GitHub](https://img.shields.io/badge/GitHub-yourusername-181717?logo=github)](https://github.com/mmizan85)

*Passionate developer building tools that make everyday computing easier.*

</div>

---

## 📄 License

This project is licensed under the **MIT License** — see the [LICENSE](LICENSE) file for details.

```
MIT License © 2024 Mohammad Mizanur Rahman
```

---

<div align="center">

Made with ❤️ by **Mohammad Mizanur Rahman**

⭐ If PowerCell helped you, please give it a star!

</div>
