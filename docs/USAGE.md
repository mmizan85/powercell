# PowerCell — Extended Usage Guide

> Author: Mohammad Mizanur Rahman

---

## Starting PowerCell

```bash
# Any platform
python3 PowerCell.py

# If installed via installer
powercell
```

---

## Navigation Reference

### Main Menu
```
[01]–[16]  → Open a software category
[99]       → Run installation of all queued apps
[S]        → Search for software by name
[I]        → Quick install a single package by ID or name
[V]        → View and review the current queue
[C]        → Clear (empty) the queue
[Q]        → Quit PowerCell
```

### Category Menu
```
[1]–[N]    → Toggle app in / out of queue
[A]        → Add ALL compatible apps in this category to queue
[B]        → Back to Main Menu
```

Symbols shown next to each app:
| Symbol | Meaning |
|--------|---------|
| `●`   | App is in the queue |
| ` `   | App is not queued |
| `✔`   | Compatible with your OS |
| `✘`   | Not available for your OS |

---

## OS Badges Explained

Every app shows a coloured badge indicating which platforms it supports:

| Badge | Color | Meaning |
|-------|-------|---------|
| `[ Windows ]` | Blue | Windows only — installed via **winget** |
| `[  Linux  ]` | Green | Linux only — installed via **apt/dnf/pacman…** |
| `[  macOS  ]` | Purple | macOS only — installed via **Homebrew** |
| `[   All   ]` | Cyan | Supports all three platforms |

---

## Search Feature (S)

1. Press `S` from the Main Menu.
2. Type any part of the software name (case-insensitive).
3. Results show compatibility and OS badges.
4. Enter the result number to add it to your queue.
5. Press Enter without typing to go back.

---

## Quick Install (I)

Directly install any package without browsing the catalog:

```
Enter winget/apt/brew ID or software name: Microsoft.VisualStudioCode
```

- If the name matches a catalog entry, it installs via the proper method.
- If not found in catalog, it attempts a direct install using your platform's package manager.

---

## Installation Process

When you press `99` to start:

1. PowerCell shows a live progress bar.
2. Each app is attempted in order.
3. For each app, the engine tries:
   - Primary package ID
   - Alternative IDs (fallback chain)
   - Name-based search (last resort, Windows)
4. Whether an app succeeds, fails, or is skipped — the next app always continues.
5. A final summary shows counts and any failures.

### Exit codes during install
| Code | Meaning |
|------|---------|
| `0` | Success |
| `0x8A15002B` | Already installed (treated as success) |
| Any other | Failure — logged, next app continues |

---

## Platform-Specific Notes

### Windows
- Requires **winget** (App Installer). Pre-installed on Windows 11.
- For Windows 10: [Download from Microsoft Store](https://aka.ms/getwinget)
- Admin mode (`--scope machine`) used when running as Administrator.
- User mode (`--scope user`) used for standard accounts.

### Linux
- PowerCell auto-detects your package manager on startup.
- Supported: `apt`, `apt-get`, `dnf`, `yum`, `pacman`, `zypper`, `apk`
- `sudo` is prepended automatically when not running as root.
- Some packages (like Google Chrome) require adding third-party repos first.

### macOS
- Requires [Homebrew](https://brew.sh).
- Tries `brew install --cask <name>` first, then `brew install <name>`.
- Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

---

## Adding Your Own Software

Edit `PowerCell.py`, find `build_catalog()`, and add an entry:

```python
app("My App",
    win   = "Publisher.AppName",     # winget search ID
    linux = "my-app",                # apt/dnf/pacman package
    mac   = "my-app-cask",           # homebrew cask name
    app_type = "Utility",
    os_sup   = A,                    # A=All, W=Windows only, L=Linux only, M=macOS only
    lic      = FREE,
    req_os   = "Any",
    # Optional fallbacks:
    alt_win   = ["OldPublisher.MyApp"],
    alt_linux = ["my-app-alternative"],
    alt_mac   = ["my-app-formula"],
),
```

---

## Uninstalling PowerCell

### Linux/macOS (shell installer)
```bash
rm -rf ~/.local/share/powercell
rm ~/.local/bin/powercell
rm ~/.local/share/applications/powercell.desktop
```

### Windows (PowerShell installer)
```powershell
Remove-Item "$env:LOCALAPPDATA\PowerCell" -Recurse -Force
# Remove from PATH manually in System Properties > Environment Variables
```

### .deb package
```bash
sudo dpkg -r powercell
```

---

## Troubleshooting

| Problem | Solution |
|---------|----------|
| `winget: command not found` | Install App Installer from Microsoft Store |
| `brew: command not found` | Install Homebrew: `https://brew.sh` |
| App fails with "Exit code 1" | Run PowerCell as Administrator / with sudo |
| ANSI colours not showing | Update Windows Terminal or use Windows 10 1903+ |
| Python not found | Install from `https://python.org` or via your package manager |
| Package ID changed | PowerCell will try alternative IDs automatically |

---

*For more help, open an issue at https://github.com/mmizan85/powercell*
