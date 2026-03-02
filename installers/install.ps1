#Requires -Version 3.0
<#
.SYNOPSIS
    PowerCell — Windows Installer Script
.DESCRIPTION
    Downloads and installs PowerCell on Windows.
    Run with:  irm https://raw.githubusercontent.com/yourusername/powercell/main/installers/install.ps1 | iex
.AUTHOR
    Mohammad Mizanur Rahman
#>

$ErrorActionPreference = "Stop"

$REPO_RAW   = "https://raw.githubusercontent.com/yourusername/powercell/main"
$INSTALL_DIR = "$env:LOCALAPPDATA\PowerCell"
$SCRIPT_URL  = "$REPO_RAW/PowerCell.py"
$ICON_URL    = "$REPO_RAW/assets/powercell.ico"

# ── Colours ──────────────────────────────────────────────────
function Write-Info    ($msg) { Write-Host "  [•] $msg" -ForegroundColor Cyan }
function Write-Success ($msg) { Write-Host "  [✔] $msg" -ForegroundColor Green }
function Write-Warn    ($msg) { Write-Host "  [!] $msg" -ForegroundColor Yellow }
function Write-Err     ($msg) { Write-Host "  [✘] $msg" -ForegroundColor Red }

# ── Banner ───────────────────────────────────────────────────
Clear-Host
$ESC = [char]27
Write-Host ""
Write-Host "${ESC}[96m  ____                          ____     _ _  ${ESC}[0m"
Write-Host "${ESC}[96m |  _ \ _____      _____ _ __  / ___|___| | | ${ESC}[0m"
Write-Host "${ESC}[96m | |_) / _ \ \ /\ / / _ \ '__|| |   / _ \ | | ${ESC}[0m"
Write-Host "${ESC}[96m |  __/ (_) \ V  V /  __/ |   | |__|  __/ | | ${ESC}[0m"
Write-Host "${ESC}[96m |_|   \___/ \_/\_/ \___|_|    \____\___|_|_| ${ESC}[0m"
Write-Host ""
Write-Host "  ${ESC}[1;33mPowerCell Windows Installer${ESC}[0m"
Write-Host "  ${ESC}[37mCross-Platform Software Installer${ESC}[0m"
Write-Host "  ${ESC}[37mAuthor: Mohammad Mizanur Rahman${ESC}[0m"
Write-Host ""
Write-Host ("─" * 60) -ForegroundColor DarkGray

# ── Check Windows version ────────────────────────────────────
$WinVer = [System.Environment]::OSVersion.Version
Write-Info "Windows $($WinVer.Major).$($WinVer.Minor) (Build $($WinVer.Build)) detected"

if ($WinVer.Major -lt 10) {
    Write-Warn "Windows 10+ recommended. Some features may not work on older versions."
}

# ── Check/Install Python ─────────────────────────────────────
Write-Info "Checking for Python 3.9+..."
$PythonCmd = $null

foreach ($cmd in @("python", "python3", "py")) {
    try {
        $ver = & $cmd --version 2>&1
        if ($ver -match "Python (\d+)\.(\d+)") {
            $major = [int]$Matches[1]; $minor = [int]$Matches[2]
            if ($major -ge 3 -and $minor -ge 9) {
                $PythonCmd = $cmd
                Write-Success "Python $major.$minor found: $cmd"
                break
            }
        }
    } catch { }
}

if (-not $PythonCmd) {
    Write-Warn "Python 3.9+ not found."
    
    # Check winget
    if (Get-Command winget -ErrorAction SilentlyContinue) {
        Write-Info "Installing Python via winget..."
        winget install --id Python.Python.3.12 `
            --silent --accept-package-agreements --accept-source-agreements
        $PythonCmd = "python"
        Write-Success "Python installed via winget."
    } else {
        Write-Err "winget not available. Please install Python 3.9+ from https://python.org"
        Write-Err "Then re-run this installer."
        Read-Host "`n  Press Enter to exit"
        exit 1
    }
}

# ── Check winget ─────────────────────────────────────────────
Write-Info "Checking for winget..."
if (Get-Command winget -ErrorAction SilentlyContinue) {
    $wgVer = (winget --version) 2>&1
    Write-Success "winget found: $wgVer"
} else {
    Write-Warn "winget not found."
    Write-Warn "Install 'App Installer' from Microsoft Store, then re-run."
    Write-Warn "https://aka.ms/getwinget"
}

# ── Create install directory ─────────────────────────────────
if (-not (Test-Path $INSTALL_DIR)) {
    New-Item -ItemType Directory -Path $INSTALL_DIR -Force | Out-Null
}
Write-Success "Install directory: $INSTALL_DIR"

# ── Download PowerCell.py ────────────────────────────────────
Write-Info "Downloading PowerCell.py..."
try {
    Invoke-WebRequest -Uri $SCRIPT_URL -OutFile "$INSTALL_DIR\PowerCell.py" -UseBasicParsing
    Write-Success "Downloaded PowerCell.py"
} catch {
    Write-Err "Download failed: $_"
    Read-Host "`n  Press Enter to exit"
    exit 1
}

# ── Download icon ────────────────────────────────────────────
try {
    Invoke-WebRequest -Uri $ICON_URL -OutFile "$INSTALL_DIR\powercell.ico" -UseBasicParsing
    Write-Success "Downloaded icon"
} catch {
    Write-Warn "Icon download failed (non-critical)"
}

# ── Create launcher batch file ───────────────────────────────
$LauncherContent = "@echo off`r`n$PythonCmd `"$INSTALL_DIR\PowerCell.py`" %*"
Set-Content -Path "$INSTALL_DIR\powercell.cmd" -Value $LauncherContent -Encoding ASCII
Write-Success "Launcher created: $INSTALL_DIR\powercell.cmd"

# ── Add to PATH (user) ───────────────────────────────────────
$CurrentPath = [System.Environment]::GetEnvironmentVariable("Path", "User")
if ($CurrentPath -notlike "*$INSTALL_DIR*") {
    $NewPath = $CurrentPath.TrimEnd(";") + ";$INSTALL_DIR"
    [System.Environment]::SetEnvironmentVariable("Path", $NewPath, "User")
    $env:Path += ";$INSTALL_DIR"
    Write-Success "Added to user PATH"
}

# ── Create Desktop shortcut ──────────────────────────────────
try {
    $DesktopPath = [System.Environment]::GetFolderPath("Desktop")
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut("$DesktopPath\PowerCell.lnk")
    $Shortcut.TargetPath   = "cmd.exe"
    $Shortcut.Arguments    = "/k `"$INSTALL_DIR\powercell.cmd`""
    $Shortcut.WorkingDirectory = $INSTALL_DIR
    $Shortcut.Description  = "PowerCell - Software Installer"
    if (Test-Path "$INSTALL_DIR\powercell.ico") {
        $Shortcut.IconLocation = "$INSTALL_DIR\powercell.ico"
    }
    $Shortcut.WindowStyle  = 1
    $Shortcut.Save()
    Write-Success "Desktop shortcut created"
} catch {
    Write-Warn "Could not create desktop shortcut: $_"
}

# ── Start Menu shortcut ──────────────────────────────────────
try {
    $StartMenu = "$env:APPDATA\Microsoft\Windows\Start Menu\Programs"
    $WScriptShell = New-Object -ComObject WScript.Shell
    $Shortcut = $WScriptShell.CreateShortcut("$StartMenu\PowerCell.lnk")
    $Shortcut.TargetPath   = "cmd.exe"
    $Shortcut.Arguments    = "/k `"$INSTALL_DIR\powercell.cmd`""
    $Shortcut.WorkingDirectory = $INSTALL_DIR
    $Shortcut.Description  = "PowerCell - Software Installer"
    if (Test-Path "$INSTALL_DIR\powercell.ico") {
        $Shortcut.IconLocation = "$INSTALL_DIR\powercell.ico"
    }
    $Shortcut.Save()
    Write-Success "Start Menu shortcut created"
} catch {
    Write-Warn "Could not create Start Menu shortcut"
}

# ── Done ─────────────────────────────────────────────────────
Write-Host ""
Write-Host "  ╔══════════════════════════════════════════╗" -ForegroundColor Green
Write-Host "  ║   PowerCell installed successfully! ⚡   ║" -ForegroundColor Green
Write-Host "  ╚══════════════════════════════════════════╝" -ForegroundColor Green
Write-Host ""
Write-Host "  Run from terminal:   " -NoNewline
Write-Host "powercell" -ForegroundColor Cyan
Write-Host "  Or double-click:     " -NoNewline
Write-Host "Desktop shortcut" -ForegroundColor Cyan
Write-Host ""
Write-Host "  GitHub: https://github.com/yourusername/powercell" -ForegroundColor Gray
Write-Host ""

$launch = Read-Host "  Launch PowerCell now? [y/N]"
if ($launch -eq "y" -or $launch -eq "Y") {
    & $PythonCmd "$INSTALL_DIR\PowerCell.py"
}
