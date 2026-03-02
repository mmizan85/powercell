#!/usr/bin/env python3
"""
╔══════════════════════════════════════════════════════════════════════════════╗
║           PowerCell - Cross-Platform Professional Software Installer        ║
║           Author  : Mohammad Mizanur Rahman                                  ║
║           Version : 2.0                                                      ║
║           Compatibility: Windows · Linux · macOS                             ║
╚══════════════════════════════════════════════════════════════════════════════╝
"""

# ─────────────────────────────────────────────────────────────────────────────
# IMPORTS
# ─────────────────────────────────────────────────────────────────────────────
import os
import sys
import platform
import subprocess
import shutil
import textwrap
import re
from dataclasses import dataclass, field
from typing import Optional
from enum import Enum

# ─────────────────────────────────────────────────────────────────────────────
# COLOR / ANSI HELPERS
# ─────────────────────────────────────────────────────────────────────────────
class Colors:
    """ANSI colour codes with automatic Windows console fix."""
    RESET   = "\033[0m"
    BOLD    = "\033[1m"
    CYAN    = "\033[96m"
    YELLOW  = "\033[93m"
    GREEN   = "\033[92m"
    RED     = "\033[91m"
    MAGENTA = "\033[95m"
    BLUE    = "\033[94m"
    WHITE   = "\033[97m"
    GREY    = "\033[90m"
    BG_BLUE = "\033[44m"

    @staticmethod
    def enable_windows_ansi() -> None:
        """Enable ANSI codes on Windows 10+ consoles."""
        if platform.system() == "Windows":
            try:
                import ctypes
                kernel = ctypes.windll.kernel32        # type: ignore[attr-defined]
                kernel.SetConsoleMode(kernel.GetStdHandle(-11), 7)
            except Exception:
                pass

C = Colors
Colors.enable_windows_ansi()


def c(color: str, text: str) -> str:
    """Wrap *text* in an ANSI colour."""
    return f"{color}{text}{C.RESET}"


# ─────────────────────────────────────────────────────────────────────────────
# ENUMS & CONSTANTS
# ─────────────────────────────────────────────────────────────────────────────
class OS(Enum):
    WINDOWS = "Windows"
    LINUX   = "Linux"
    MACOS   = "macOS"
    ALL     = "All"


class License(Enum):
    FREE      = "Free"
    PAID      = "Paid"
    FREEMIUM  = "Free/Paid"
    TRIAL     = "Trial"


OS_BADGE = {
    OS.WINDOWS : c(C.BLUE,    "[ Windows ]"),
    OS.LINUX   : c(C.GREEN,   "[  Linux  ]"),
    OS.MACOS   : c(C.MAGENTA, "[  macOS  ]"),
    OS.ALL     : c(C.CYAN,    "[   All   ]"),
}

LICENSE_BADGE = {
    License.FREE     : c(C.GREEN,  "[Free]"),
    License.PAID     : c(C.RED,    "[Paid]"),
    License.FREEMIUM : c(C.YELLOW, "[Free/Paid]"),
    License.TRIAL    : c(C.YELLOW, "[Trial]"),
}

WIDTH = 80   # console width


# ─────────────────────────────────────────────────────────────────────────────
# DATA MODELS
# ─────────────────────────────────────────────────────────────────────────────
@dataclass
class AppEntry:
    """A single installable software entry."""
    name         : str
    win_id       : Optional[str]        # winget package ID
    linux_pkg    : Optional[str]        # apt/dnf/pacman package name
    mac_pkg      : Optional[str]        # homebrew cask or formula
    app_type     : str
    os_support   : list[OS]
    license_type : License
    req_arch     : list[str]            # ["x64", "x86", "arm64", "any"]
    req_os_min   : str                  # e.g. "Windows 10+", "Ubuntu 20.04+"
    category     : str = ""

    # extra alternate IDs tried when primary ID fails
    alt_win_ids  : list[str] = field(default_factory=list)
    alt_linux_pkgs: list[str] = field(default_factory=list)
    alt_mac_pkgs : list[str] = field(default_factory=list)

    def os_badge(self) -> str:
        if len(self.os_support) >= 3:
            return OS_BADGE[OS.ALL]
        return " ".join(OS_BADGE[o] for o in self.os_support)

    def license_badge(self) -> str:
        return LICENSE_BADGE.get(self.license_type, "")

    def display_name(self) -> str:
        return f"{self.name} {self.license_badge()}"


@dataclass
class InstallResult:
    app    : AppEntry
    status : str   # "ok" | "fail" | "skip"
    notes  : str = ""


# ─────────────────────────────────────────────────────────────────────────────
# SYSTEM DETECTOR
# ─────────────────────────────────────────────────────────────────────────────
class SystemDetector:
    """Gather information about the running system once at startup."""

    def __init__(self) -> None:
        self.os_name     : str = platform.system()          # 'Windows', 'Linux', 'Darwin'
        self.os_release  : str = platform.release()
        self.os_version  : str = platform.version()
        self.machine     : str = platform.machine()         # 'AMD64', 'x86_64', 'arm64'
        self.python_ver  : str = platform.python_version()
        self.hostname    : str = platform.node()
        self.arch        : str = self._normalise_arch()
        self.current_os  : OS  = self._detect_os()
        self.is_admin    : bool = self._check_admin()
        self.distro      : str = self._detect_distro()
        self.pkg_manager : str = self._detect_pkg_manager()
        self.winget_ok   : bool = self._check_tool("winget")
        self.brew_ok     : bool = self._check_tool("brew")

    # ------------------------------------------------------------------
    def _normalise_arch(self) -> str:
        m = self.machine.lower()
        if m in ("amd64", "x86_64"):
            return "x64"
        if m in ("i386", "i686", "x86"):
            return "x86"
        if "arm" in m or "aarch" in m:
            return "arm64"
        return m

    def _detect_os(self) -> OS:
        s = self.os_name
        if s == "Windows":
            return OS.WINDOWS
        if s == "Darwin":
            return OS.MACOS
        return OS.LINUX

    def _check_admin(self) -> bool:
        try:
            if self.os_name == "Windows":
                import ctypes
                return bool(ctypes.windll.shell32.IsUserAnAdmin())  # type: ignore[attr-defined]
            return os.geteuid() == 0  # type: ignore[attr-defined]
        except Exception:
            return False

    def _detect_distro(self) -> str:
        if self.os_name != "Linux":
            return ""
        try:
            result = subprocess.run(
                ["lsb_release", "-ds"], capture_output=True, text=True, timeout=5
            )
            if result.returncode == 0:
                return result.stdout.strip().strip('"')
        except Exception:
            pass
        try:
            with open("/etc/os-release") as f:
                for line in f:
                    if line.startswith("PRETTY_NAME="):
                        return line.split("=", 1)[1].strip().strip('"')
        except Exception:
            pass
        return "Linux"

    def _detect_pkg_manager(self) -> str:
        managers = ["apt", "apt-get", "dnf", "yum", "pacman", "zypper", "apk"]
        for mgr in managers:
            if shutil.which(mgr):
                return mgr
        return ""

    @staticmethod
    def _check_tool(name: str) -> bool:
        return shutil.which(name) is not None

    # ------------------------------------------------------------------
    def summary(self) -> str:
        os_label = self.distro if self.distro else f"{self.os_name} {self.os_release}"
        admin_label = c(C.GREEN, "Admin") if self.is_admin else c(C.YELLOW, "Standard User")
        return (
            f" OS: {c(C.CYAN, os_label)} | "
            f"Arch: {c(C.CYAN, self.arch)} | "
            f"Python: {c(C.CYAN, self.python_ver)} | "
            f"Mode: {admin_label}"
        )

    def os_display(self) -> str:
        if self.current_os == OS.WINDOWS:
            return c(C.BLUE, f"Windows {self.os_release}")
        if self.current_os == OS.MACOS:
            return c(C.MAGENTA, f"macOS {self.os_release}")
        return c(C.GREEN, self.distro or "Linux")


# ─────────────────────────────────────────────────────────────────────────────
# INSTALLER ENGINE
# ─────────────────────────────────────────────────────────────────────────────
class InstallerEngine:
    """
    Handles the actual installation of software on all platforms.
    • Tries primary IDs first, then alternative IDs.
    • Skips gracefully if a package manager is unavailable.
    • Never raises — always returns an InstallResult.
    """

    def __init__(self, detector: SystemDetector) -> None:
        self.det = detector

    # ------------------------------------------------------------------
    # PUBLIC API
    # ------------------------------------------------------------------
    def install(self, app: AppEntry) -> InstallResult:
        """Install *app* and return an InstallResult."""
        os_ = self.det.current_os
        if os_ not in app.os_support:
            return InstallResult(app, "skip", f"Not available for {os_.value}")

        try:
            if os_ == OS.WINDOWS:
                return self._install_windows(app)
            if os_ == OS.LINUX:
                return self._install_linux(app)
            return self._install_macos(app)
        except Exception as exc:
            return InstallResult(app, "fail", str(exc))

    # ------------------------------------------------------------------
    # WINDOWS
    # ------------------------------------------------------------------
    def _install_windows(self, app: AppEntry) -> InstallResult:
        if not self.det.winget_ok:
            return InstallResult(app, "fail", "winget not found. Install App Installer from Microsoft Store.")

        ids_to_try = [app.win_id] + app.alt_win_ids
        ids_to_try = [i for i in ids_to_try if i]

        for pkg_id in ids_to_try:
            ok, notes = self._run_winget(pkg_id)
            if ok:
                return InstallResult(app, "ok", notes)

        # Last-resort: search by name
        ok, notes = self._winget_search_and_install(app.name)
        if ok:
            return InstallResult(app, "ok", f"Installed via name search: {notes}")

        return InstallResult(app, "fail", f"All IDs failed: {ids_to_try}")

    def _run_winget(self, pkg_id: str) -> tuple[bool, str]:
        cmd = [
            "winget", "install", "--id", pkg_id,
            "--silent", "--accept-package-agreements",
            "--accept-source-agreements", "--disable-interactivity",
        ]
        if not self.det.is_admin:
            cmd += ["--scope", "user"]
        return self._exec(cmd)

    def _winget_search_and_install(self, name: str) -> tuple[bool, str]:
        """Search winget for a package by name and install the first match."""
        try:
            result = subprocess.run(
                ["winget", "search", "--query", name, "--accept-source-agreements"],
                capture_output=True, text=True, timeout=30,
            )
            # Parse first real result line
            lines = result.stdout.strip().splitlines()
            for line in lines[2:]:                       # skip header rows
                parts = line.split()
                if len(parts) >= 2:
                    found_id = parts[-2]                 # ID is second-to-last column
                    if re.match(r"^[A-Za-z]", found_id):
                        ok, notes = self._run_winget(found_id)
                        if ok:
                            return True, found_id
        except Exception:
            pass
        return False, ""

    # ------------------------------------------------------------------
    # LINUX
    # ------------------------------------------------------------------
    def _install_linux(self, app: AppEntry) -> InstallResult:
        pkgs = [app.linux_pkg] + app.alt_linux_pkgs
        pkgs = [p for p in pkgs if p]

        if not pkgs:
            return InstallResult(app, "skip", "No Linux package defined")

        mgr = self.det.pkg_manager
        if not mgr:
            return InstallResult(app, "fail", "No supported package manager found (apt/dnf/pacman…)")

        for pkg in pkgs:
            ok, notes = self._run_linux_install(mgr, pkg)
            if ok:
                return InstallResult(app, "ok", notes)

        return InstallResult(app, "fail", f"All package names failed: {pkgs}")

    def _run_linux_install(self, mgr: str, pkg: str) -> tuple[bool, str]:
        prefix = ["sudo"] if not self.det.is_admin else []
        if mgr in ("apt", "apt-get"):
            cmd = prefix + [mgr, "install", "-y", pkg]
        elif mgr in ("dnf", "yum"):
            cmd = prefix + [mgr, "install", "-y", pkg]
        elif mgr == "pacman":
            cmd = prefix + ["pacman", "-S", "--noconfirm", pkg]
        elif mgr == "zypper":
            cmd = prefix + ["zypper", "install", "-y", pkg]
        elif mgr == "apk":
            cmd = prefix + ["apk", "add", pkg]
        else:
            return False, f"Unknown manager: {mgr}"
        return self._exec(cmd)

    # ------------------------------------------------------------------
    # MACOS
    # ------------------------------------------------------------------
    def _install_macos(self, app: AppEntry) -> InstallResult:
        pkgs = [app.mac_pkg] + app.alt_mac_pkgs
        pkgs = [p for p in pkgs if p]

        if not pkgs:
            return InstallResult(app, "skip", "No macOS package defined")

        if not self.det.brew_ok:
            return InstallResult(app, "fail", "Homebrew not found. Install it from https://brew.sh")

        for pkg in pkgs:
            ok, notes = self._run_brew(pkg)
            if ok:
                return InstallResult(app, "ok", notes)

        return InstallResult(app, "fail", f"All Homebrew names failed: {pkgs}")

    def _run_brew(self, pkg: str) -> tuple[bool, str]:
        # try cask first, then formula
        for flag in [["--cask"], []]:
            cmd = ["brew", "install"] + flag + [pkg]
            ok, notes = self._exec(cmd)
            if ok:
                return True, notes
        return False, f"brew cask and formula both failed for {pkg}"

    # ------------------------------------------------------------------
    # GENERIC RUNNER
    # ------------------------------------------------------------------
    @staticmethod
    def _exec(cmd: list[str]) -> tuple[bool, str]:
        try:
            result = subprocess.run(
                cmd,
                capture_output=True,
                text=True,
                timeout=300,
            )
            if result.returncode == 0:
                return True, "Installed successfully"
            # winget exit code 0x8A15002B → already installed
            if result.returncode in (0x8A15002B, -1978335189):
                return True, "Already installed"
            err = (result.stderr or result.stdout or "").strip()[:200]
            return False, err or f"Exit code {result.returncode}"
        except FileNotFoundError as exc:
            return False, f"Command not found: {exc.filename}"
        except subprocess.TimeoutExpired:
            return False, "Installation timed out (>5 min)"
        except Exception as exc:
            return False, str(exc)


# ─────────────────────────────────────────────────────────────────────────────
# SOFTWARE CATALOG
# ─────────────────────────────────────────────────────────────────────────────
def build_catalog() -> dict[str, dict]:
    """
    Returns an ordered dict of categories, each containing a list of AppEntry.
    Format: { "01": { "category": str, "description": str, "apps": [AppEntry, …] }, … }
    """
    W  = [OS.WINDOWS]
    L  = [OS.LINUX]
    M  = [OS.MACOS]
    WL = [OS.WINDOWS, OS.LINUX]
    WM = [OS.WINDOWS, OS.MACOS]
    LM = [OS.LINUX, OS.MACOS]
    A  = [OS.WINDOWS, OS.LINUX, OS.MACOS]

    FREE     = License.FREE
    PAID     = License.PAID
    FREEMIUM = License.FREEMIUM
    TRIAL    = License.TRIAL

    def app(name, win=None, linux=None, mac=None, app_type="General",
            os_sup=None, lic=FREE, arch=None, req_os="Any",
            alt_win=None, alt_linux=None, alt_mac=None):
        if os_sup is None:
            os_sup = A
        if arch is None:
            arch = ["x64", "x86", "arm64"]
        return AppEntry(
            name=name,
            win_id=win, linux_pkg=linux, mac_pkg=mac,
            app_type=app_type, os_support=os_sup,
            license_type=lic, req_arch=arch,
            req_os_min=req_os,
            alt_win_ids=alt_win or [],
            alt_linux_pkgs=alt_linux or [],
            alt_mac_pkgs=alt_mac or [],
        )

    catalog = {
        "01": {
            "category"    : "Web Browsers",
            "description" : "Internet browsers for web surfing",
            "apps": [
                app("Google Chrome",    win="Google.Chrome",                linux="google-chrome-stable",   mac="google-chrome",        app_type="Browser",    os_sup=A,  lic=FREE,  alt_linux=["chromium-browser","chromium"]),
                app("Mozilla Firefox",  win="Mozilla.Firefox",              linux="firefox",                mac="firefox",              app_type="Browser",    os_sup=A,  lic=FREE),
                app("Microsoft Edge",   win="Microsoft.Edge",               linux="microsoft-edge-stable",  mac="microsoft-edge",       app_type="Browser",    os_sup=A,  lic=FREE,  alt_linux=["microsoft-edge"]),
                app("Brave Browser",    win="Brave.Brave",                  linux="brave-browser",          mac="brave-browser",        app_type="Browser",    os_sup=A,  lic=FREE),
                app("Opera Browser",    win="Opera.Opera",                  linux="opera",                  mac="opera",                app_type="Browser",    os_sup=A,  lic=FREE),
                app("Vivaldi Browser",  win="VivaldiTechnologies.Vivaldi",  linux="vivaldi-stable",         mac="vivaldi",              app_type="Browser",    os_sup=A,  lic=FREE,  alt_linux=["vivaldi"]),
                app("Tor Browser",      win="TorProject.TorBrowser",        linux="torbrowser-launcher",    mac="tor-browser",          app_type="Browser",    os_sup=A,  lic=FREE),
                app("Waterfox",         win="Waterfox.Waterfox",            linux="waterfox",               mac="waterfox",             app_type="Browser",    os_sup=A,  lic=FREE),
                app("Pale Moon",        win="MoonchildProductions.PaleMoon",linux=None,                     mac=None,                   app_type="Browser",    os_sup=W,  lic=FREE),
                app("Chromium",         win="Hibbiki.Chromium",             linux="chromium",               mac="chromium",             app_type="Browser",    os_sup=A,  lic=FREE),
            ],
        },
        "02": {
            "category"    : "Communication Tools",
            "description" : "Messaging, chat and video calling apps",
            "apps": [
                app("WhatsApp Desktop", win="WhatsApp.WhatsApp",            linux="whatsapp",               mac="whatsapp",             app_type="Messenger",  os_sup=A,  lic=FREE,  alt_linux=["whatsapp-desktop"]),
                app("Telegram Desktop", win="Telegram.TelegramDesktop",     linux="telegram-desktop",       mac="telegram",             app_type="Messenger",  os_sup=A,  lic=FREE,  alt_linux=["telegram"]),
                app("Discord",          win="Discord.Discord",              linux="discord",                mac="discord",              app_type="Messenger",  os_sup=A,  lic=FREE),
                app("Zoom",             win="Zoom.Zoom",                    linux="zoom",                   mac="zoom",                 app_type="VideoCall",  os_sup=A,  lic=FREEMIUM),
                app("Skype",            win="Microsoft.Skype",              linux="skypeforlinux",          mac="skype",                app_type="VideoCall",  os_sup=A,  lic=FREE),
                app("Signal",           win="OpenWhisperSystems.Signal",    linux="signal-desktop",         mac="signal",               app_type="Messenger",  os_sup=A,  lic=FREE,  alt_win=["Signal.Signal"]),
                app("Slack",            win="SlackTechnologies.Slack",      linux="slack-desktop",          mac="slack",                app_type="Business",   os_sup=A,  lic=FREEMIUM),
                app("Microsoft Teams",  win="Microsoft.Teams",              linux="teams",                  mac="microsoft-teams",      app_type="Business",   os_sup=A,  lic=FREE,  alt_linux=["teams-for-linux"]),
                app("Viber",            win="Viber.Viber",                  linux="viber",                  mac="viber",                app_type="Messenger",  os_sup=A,  lic=FREE),
                app("Element (Matrix)", win="Element.Element",              linux="element-desktop",        mac="element",              app_type="Messenger",  os_sup=A,  lic=FREE),
            ],
        },
        "03": {
            "category"    : "Development Tools",
            "description" : "Programming IDEs, runtimes and SDKs",
            "apps": [
                app("Visual Studio Code",      win="Microsoft.VisualStudioCode",          linux="code",                mac="visual-studio-code",   app_type="IDE",         os_sup=A,  lic=FREE,  arch=["x64","arm64"]),
                app("Python 3.12",             win="Python.Python.3.12",                  linux="python3",             mac="python@3.12",           app_type="Runtime",     os_sup=A,  lic=FREE),
                app("Node.js LTS",             win="OpenJS.NodeJS.LTS",                   linux="nodejs",              mac="node",                  app_type="Runtime",     os_sup=A,  lic=FREE),
                app("Git",                     win="Git.Git",                             linux="git",                 mac="git",                   app_type="VCS",         os_sup=A,  lic=FREE),
                app("Docker Desktop",          win="Docker.DockerDesktop",                linux="docker.io",           mac="docker",                app_type="Container",   os_sup=A,  lic=FREE,  arch=["x64"],  alt_linux=["docker-ce"]),
                app("Postman",                 win="Postman.Postman",                     linux="postman",             mac="postman",               app_type="API",         os_sup=A,  lic=FREEMIUM),
                app("Android Studio",          win="Google.AndroidStudio",                linux="android-studio",      mac="android-studio",        app_type="IDE",         os_sup=A,  lic=FREE,  arch=["x64"]),
                app("Java JDK 21",             win="Oracle.JDK.21",                       linux="default-jdk",         mac="openjdk",               app_type="Runtime",     os_sup=A,  lic=FREE,  alt_linux=["openjdk-21-jdk"]),
                app("Notepad++",               win="Notepad++.Notepad++",                 linux=None,                  mac=None,                    app_type="Editor",      os_sup=W,  lic=FREE),
                app("Sublime Text",            win="SublimeHQ.SublimeText.4",             linux="sublime-text",        mac="sublime-text",          app_type="Editor",      os_sup=A,  lic=FREEMIUM),
                app("IntelliJ IDEA Community", win="JetBrains.IntelliJIDEA.Community",    linux="intellij-idea-community",mac="intellij-idea-ce",   app_type="IDE",         os_sup=A,  lic=FREE),
                app("PyCharm Community",       win="JetBrains.PyCharm.Community",         linux="pycharm-community",   mac="pycharm-ce",            app_type="IDE",         os_sup=A,  lic=FREE),
                app("GitHub Desktop",          win="GitHub.GitHubDesktop",                linux="github-desktop",      mac="github",                app_type="VCS",         os_sup=A,  lic=FREE),
                app("Rust (rustup)",           win="Rustlang.Rustup",                     linux="rustup",              mac="rustup-init",            app_type="Runtime",     os_sup=A,  lic=FREE),
                app("Go (Golang)",             win="GoLang.Go",                           linux="golang",              mac="go",                    app_type="Runtime",     os_sup=A,  lic=FREE),
            ],
        },
        "04": {
            "category"    : "Media & Entertainment",
            "description" : "Music, video players and media tools",
            "apps": [
                app("VLC Media Player",  win="VideoLAN.VLC",                    linux="vlc",                mac="vlc",               app_type="Player",      os_sup=A,  lic=FREE),
                app("Spotify",           win="Spotify.Spotify",                 linux="spotify",            mac="spotify",           app_type="Music",       os_sup=A,  lic=FREEMIUM),
                app("iTunes",            win="Apple.iTunes",                    linux=None,                 mac=None,                app_type="Music",       os_sup=W,  lic=FREE),
                app("PotPlayer",         win="Daum.PotPlayer",                  linux=None,                 mac=None,                app_type="Player",      os_sup=W,  lic=FREE),
                app("MPV",               win="mpv.net",                         linux="mpv",                mac="mpv",               app_type="Player",      os_sup=A,  lic=FREE,  alt_win=["shinchiro.mpv"]),
                app("OBS Studio",        win="OBSProject.OBSStudio",            linux="obs-studio",         mac="obs",               app_type="Streaming",   os_sup=A,  lic=FREE),
                app("Audacity",          win="Audacity.Audacity",               linux="audacity",           mac="audacity",          app_type="AudioEditor", os_sup=A,  lic=FREE),
                app("Foobar2000",        win="PeterPawlowski.foobar2000",       linux=None,                 mac=None,                app_type="Music",       os_sup=W,  lic=FREE),
                app("Kodi",              win="XBMCFoundation.Kodi",             linux="kodi",               mac="kodi",              app_type="MediaCenter", os_sup=A,  lic=FREE),
                app("HandBrake",         win="HandBrake.HandBrake",             linux="handbrake",          mac="handbrake",         app_type="Converter",   os_sup=A,  lic=FREE),
                app("IINA",              win=None,                              linux=None,                 mac="iina",              app_type="Player",      os_sup=M,  lic=FREE),
                app("Clementine",        win="Clementine.Clementine",           linux="clementine",         mac="clementine",        app_type="Music",       os_sup=A,  lic=FREE),
            ],
        },
        "05": {
            "category"    : "System Utilities",
            "description" : "Tools for system maintenance and optimisation",
            "apps": [
                app("7-Zip",             win="7zip.7zip",                       linux="p7zip-full",          mac="sevenzip",          app_type="Compression", os_sup=A,  lic=FREE,  alt_mac=["p7zip"]),
                app("WinRAR",            win="WinRAR.WinRAR",                   linux="unrar",               mac=None,                app_type="Compression", os_sup=WL, lic=TRIAL),
                app("CCleaner",          win="Piriform.CCleaner",               linux=None,                  mac="ccleaner",          app_type="Cleaner",     os_sup=WM, lic=FREEMIUM),
                app("Rufus",             win="Rufus.Rufus",                     linux=None,                  mac=None,                app_type="USB",         os_sup=W,  lic=FREE),
                app("Balena Etcher",     win="Balena.Etcher",                   linux="balena-etcher",       mac="balenaetcher",      app_type="USB",         os_sup=A,  lic=FREE),
                app("Everything",        win="voidtools.Everything",            linux=None,                  mac=None,                app_type="Search",      os_sup=W,  lic=FREE),
                app("PowerToys",         win="Microsoft.PowerToys",             linux=None,                  mac=None,                app_type="Productivity",os_sup=W,  lic=FREE,  arch=["x64"]),
                app("CPU-Z",             win="CPUID.CPU-Z",                     linux=None,                  mac=None,                app_type="Monitor",     os_sup=W,  lic=FREE),
                app("HWMonitor",         win="CPUID.HWMonitor",                 linux="lm-sensors",          mac=None,                app_type="Monitor",     os_sup=WL, lic=FREE),
                app("Revo Uninstaller",  win="RevoUninstaller.RevoUninstaller", linux=None,                  mac=None,                app_type="Uninstaller", os_sup=W,  lic=FREEMIUM),
                app("Bleachbit",         win="BleachBit.BleachBit",             linux="bleachbit",           mac=None,                app_type="Cleaner",     os_sup=WL, lic=FREE),
                app("Homebrew",          win=None,                              linux=None,                  mac="brew",              app_type="PackageMgr",  os_sup=LM, lic=FREE),
            ],
        },
        "06": {
            "category"    : "Office & Productivity",
            "description" : "Office suites, PDF readers and cloud storage",
            "apps": [
                app("LibreOffice",           win="TheDocumentFoundation.LibreOffice",  linux="libreoffice",         mac="libreoffice",       app_type="Office",  os_sup=A,  lic=FREE),
                app("OnlyOffice",            win="ONLYOFFICE.DesktopEditors",          linux="onlyoffice-desktopeditors",mac="onlyoffice",   app_type="Office",  os_sup=A,  lic=FREE),
                app("WPS Office",            win="Kingsoft.WPSOffice",                 linux="wps-office",          mac="wpsoffice",         app_type="Office",  os_sup=A,  lic=FREEMIUM),
                app("Google Drive",          win="Google.Drive",                       linux=None,                  mac="google-drive",      app_type="Cloud",   os_sup=WM, lic=FREE),
                app("OneDrive",              win="Microsoft.OneDrive",                 linux=None,                  mac="onedrive",          app_type="Cloud",   os_sup=WM, lic=FREE),
                app("Dropbox",               win="Dropbox.Dropbox",                   linux="dropbox",             mac="dropbox",           app_type="Cloud",   os_sup=A,  lic=FREEMIUM),
                app("Adobe Acrobat Reader",  win="Adobe.Acrobat.Reader.64-bit",        linux="acroread",            mac="adobe-acrobat-reader",app_type="PDF",   os_sup=A,  lic=FREE,  alt_win=["Adobe.Acrobat.Reader"]),
                app("Foxit PDF Reader",      win="Foxit.FoxitReader",                 linux=None,                  mac="foxitpdf",          app_type="PDF",     os_sup=WM, lic=FREE),
                app("SumatraPDF",            win="SumatraPDF.SumatraPDF",             linux=None,                  mac=None,                app_type="PDF",     os_sup=W,  lic=FREE),
                app("Calibre",               win="calibre.calibre",                   linux="calibre",             mac="calibre",           app_type="Ebook",   os_sup=A,  lic=FREE),
                app("Notion",                win="Notion.Notion",                     linux="notion-app",          mac="notion",            app_type="Notes",   os_sup=A,  lic=FREEMIUM),
                app("Obsidian",              win="Obsidian.Obsidian",                 linux="obsidian",            mac="obsidian",          app_type="Notes",   os_sup=A,  lic=FREE),
            ],
        },
        "07": {
            "category"    : "Security & Privacy",
            "description" : "Antivirus, VPN, encryption and password managers",
            "apps": [
                app("Malwarebytes",   win="Malwarebytes.Malwarebytes",     linux=None,              mac="malwarebytes",     app_type="Antivirus",  os_sup=WM, lic=FREEMIUM),
                app("Avast Antivirus",win="Avast.Antivirus",              linux=None,              mac="avast-security",   app_type="Antivirus",  os_sup=WM, lic=FREE),
                app("AVG Antivirus",  win="AVG.Antivirus",                linux=None,              mac="avg-antivirus",    app_type="Antivirus",  os_sup=WM, lic=FREE),
                app("Bitdefender",    win="Bitdefender.Bitdefender",      linux=None,              mac="bitdefender-virus-scanner",app_type="Antivirus",os_sup=WM,lic=FREEMIUM),
                app("VeraCrypt",      win="IDRIX.VeraCrypt",              linux="veracrypt",       mac="veracrypt",        app_type="Encryption", os_sup=A,  lic=FREE),
                app("KeePassXC",      win="KeePassXCTeam.KeePassXC",     linux="keepassxc",       mac="keepassxc",        app_type="Password",   os_sup=A,  lic=FREE),
                app("Bitwarden",      win="Bitwarden.Bitwarden",         linux="bitwarden",       mac="bitwarden",        app_type="Password",   os_sup=A,  lic=FREEMIUM),
                app("ProtonVPN",      win="ProtonTechnologies.ProtonVPN", linux="protonvpn",       mac="protonvpn",        app_type="VPN",        os_sup=A,  lic=FREEMIUM),
                app("NordVPN",        win="NordVPN.NordVPN",             linux="nordvpn",         mac="nordvpn",          app_type="VPN",        os_sup=A,  lic=PAID),
                app("OpenVPN",        win="OpenVPN.OpenVPN",             linux="openvpn",         mac="openvpn",          app_type="VPN",        os_sup=A,  lic=FREE),
                app("Mullvad VPN",    win="MullvadVPN.MullvadVPN",       linux="mullvad-vpn",     mac="mullvadvpn",       app_type="VPN",        os_sup=A,  lic=PAID),
                app("ClamAV",         win=None,                           linux="clamav",          mac="clamav",           app_type="Antivirus",  os_sup=LM, lic=FREE),
            ],
        },
        "08": {
            "category"    : "Graphics & Design",
            "description" : "Photo editing, design and 3D modelling",
            "apps": [
                app("GIMP",         win="GIMP.GIMP",                     linux="gimp",         mac="gimp",          app_type="Design",   os_sup=A,  lic=FREE),
                app("Inkscape",     win="Inkscape.Inkscape",             linux="inkscape",     mac="inkscape",      app_type="Vector",   os_sup=A,  lic=FREE),
                app("Blender",      win="BlenderFoundation.Blender",     linux="blender",      mac="blender",       app_type="3D",       os_sup=A,  lic=FREE,  arch=["x64","arm64"]),
                app("Paint.NET",    win="dotPDN.Paint.NET",              linux=None,           mac=None,            app_type="Editor",   os_sup=W,  lic=FREE),
                app("Krita",        win="KDE.Krita",                     linux="krita",        mac="krita",         app_type="Painting", os_sup=A,  lic=FREE),
                app("Figma",        win="Figma.Figma",                   linux="figma-linux",  mac="figma",         app_type="Design",   os_sup=A,  lic=FREEMIUM),
                app("Darktable",    win="darktable.darktable",           linux="darktable",    mac="darktable",     app_type="Photo",    os_sup=A,  lic=FREE),
                app("RawTherapee",  win="RawTherapee.RawTherapee",       linux="rawtherapee",  mac="rawtherapee",   app_type="Photo",    os_sup=A,  lic=FREE),
                app("Pencil2D",     win="Pencil2D.Pencil2D",             linux="pencil2d",     mac="pencil2d",      app_type="Animation",os_sup=A,  lic=FREE),
                app("LibreSprite",  win=None,                            linux="libresprite",  mac="libresprite",   app_type="Pixel",    os_sup=LM, lic=FREE),
            ],
        },
        "09": {
            "category"    : "Gaming Platforms",
            "description" : "Game launchers and gaming platforms",
            "apps": [
                app("Steam",              win="Valve.Steam",                       linux="steam",             mac="steam",           app_type="Platform", os_sup=A,  lic=FREE),
                app("Epic Games Launcher",win="EpicGames.EpicGamesLauncher",       linux=None,                mac="epic-games",      app_type="Platform", os_sup=WM, lic=FREE),
                app("GOG Galaxy",         win="GOG.Galaxy",                        linux=None,                mac="gog-galaxy",      app_type="Platform", os_sup=WM, lic=FREE),
                app("Ubisoft Connect",    win="Ubisoft.Connect",                   linux=None,                mac=None,              app_type="Platform", os_sup=W,  lic=FREE),
                app("EA App",             win="ElectronicArts.EADesktop",          linux=None,                mac=None,              app_type="Platform", os_sup=W,  lic=FREE),
                app("Battle.net",         win="Blizzard.BattleNet",                linux=None,                mac="battle-net",      app_type="Platform", os_sup=WM, lic=FREE),
                app("itch.io",            win="itchio.itch",                       linux="itch",              mac="itch",            app_type="Platform", os_sup=A,  lic=FREE),
                app("Heroic Games",       win="HeroicGamesLauncher.HeroicGamesLauncher",linux="heroic",       mac="heroic",          app_type="Platform", os_sup=A,  lic=FREE),
                app("Lutris",             win=None,                                linux="lutris",            mac=None,              app_type="Platform", os_sup=L,  lic=FREE),
                app("RetroArch",          win="Libretro.RetroArch",                linux="retroarch",         mac="retroarch",       app_type="Emulator", os_sup=A,  lic=FREE),
            ],
        },
        "10": {
            "category"    : "Networking Tools",
            "description" : "Network utilities, FTP, SSH and remote access",
            "apps": [
                app("FileZilla",        win="FileZilla.FileZilla",               linux="filezilla",      mac="filezilla",       app_type="FTP",      os_sup=A,  lic=FREE),
                app("PuTTY",            win="PuTTY.PuTTY",                       linux="putty",          mac="putty",           app_type="SSH",      os_sup=A,  lic=FREE),
                app("WinSCP",           win="WinSCP.WinSCP",                     linux=None,             mac=None,              app_type="FTP",      os_sup=W,  lic=FREE),
                app("Wireshark",        win="WiresharkFoundation.Wireshark",     linux="wireshark",      mac="wireshark",       app_type="Analyzer", os_sup=A,  lic=FREE),
                app("TeamViewer",       win="TeamViewer.TeamViewer",             linux="teamviewer",     mac="teamviewer",      app_type="Remote",   os_sup=A,  lic=FREEMIUM),
                app("AnyDesk",          win="AnyDeskSoftwareGmbH.AnyDesk",       linux="anydesk",        mac="anydesk",         app_type="Remote",   os_sup=A,  lic=FREEMIUM),
                app("Angry IP Scanner", win="AngryIPScanner.AngryIPScanner",     linux="ipscan",         mac="angry-ip-scanner",app_type="Scanner",  os_sup=A,  lic=FREE),
                app("nmap",             win="Nmap.Nmap",                         linux="nmap",           mac="nmap",            app_type="Scanner",  os_sup=A,  lic=FREE),
                app("mRemoteNG",        win="mRemoteNG.mRemoteNG",               linux=None,             mac=None,              app_type="Remote",   os_sup=W,  lic=FREE),
                app("Termius",          win="Termius.Termius",                   linux="termius-app",    mac="termius",         app_type="SSH",      os_sup=A,  lic=FREEMIUM),
            ],
        },
        "11": {
            "category"    : "Database Tools",
            "description" : "Database servers and management clients",
            "apps": [
                app("MySQL",          win="Oracle.MySQL",                    linux="mysql-server",      mac="mysql",         app_type="Database",    os_sup=A,  lic=FREE),
                app("PostgreSQL",     win="PostgreSQL.PostgreSQL",           linux="postgresql",        mac="postgresql",    app_type="Database",    os_sup=A,  lic=FREE),
                app("MongoDB",        win="MongoDB.MongoDB",                 linux="mongodb-org",       mac="mongodb-community",app_type="Database", os_sup=A,  lic=FREE),
                app("SQLite",         win="SQLite.SQLite",                   linux="sqlite3",           mac="sqlite",        app_type="Database",    os_sup=A,  lic=FREE),
                app("DBeaver",        win="DBeaver.DBeaver",                 linux="dbeaver-ce",        mac="dbeaver-community",app_type="DBTool",  os_sup=A,  lic=FREE),
                app("HeidiSQL",       win="HeidiSQL.HeidiSQL",               linux=None,                mac=None,            app_type="DBTool",      os_sup=W,  lic=FREE),
                app("TablePlus",      win="TablePlus.TablePlus",             linux="tableplus",         mac="tableplus",     app_type="DBTool",      os_sup=A,  lic=FREEMIUM),
                app("Redis",          win="Redis.Redis",                     linux="redis-server",      mac="redis",         app_type="Database",    os_sup=A,  lic=FREE),
                app("MariaDB",        win="MariaDB.MariaDB",                 linux="mariadb-server",    mac="mariadb",       app_type="Database",    os_sup=A,  lic=FREE),
                app("Azure Data Studio",win="Microsoft.AzureDataStudio",    linux="azuredatastudio",   mac="azure-data-studio",app_type="DBTool",  os_sup=A,  lic=FREE),
            ],
        },
        "12": {
            "category"    : "Cloud & DevOps",
            "description" : "Cloud tools, containers and CI/CD",
            "apps": [
                app("AWS CLI",         win="Amazon.AWSCLI",              linux="awscli",            mac="awscli",          app_type="Cloud",    os_sup=A,  lic=FREE),
                app("Azure CLI",       win="Microsoft.AzureCLI",         linux="azure-cli",         mac="azure-cli",       app_type="Cloud",    os_sup=A,  lic=FREE),
                app("Google Cloud CLI",win="Google.CloudSDK",            linux="google-cloud-sdk",  mac="google-cloud-sdk",app_type="Cloud",    os_sup=A,  lic=FREE),
                app("Kubernetes (kubectl)",win="Kubernetes.kubectl",     linux="kubectl",           mac="kubectl",         app_type="DevOps",   os_sup=A,  lic=FREE),
                app("Helm",            win="Helm.Helm",                  linux="helm",              mac="helm",            app_type="DevOps",   os_sup=A,  lic=FREE),
                app("Terraform",       win="Hashicorp.Terraform",        linux="terraform",         mac="terraform",       app_type="DevOps",   os_sup=A,  lic=FREE),
                app("Ansible",         win=None,                         linux="ansible",           mac="ansible",         app_type="DevOps",   os_sup=LM, lic=FREE),
                app("Jenkins",         win=None,                         linux="jenkins",           mac="jenkins",         app_type="CI/CD",    os_sup=LM, lic=FREE),
                app("Vagrant",         win="Hashicorp.Vagrant",          linux="vagrant",           mac="vagrant",         app_type="DevOps",   os_sup=A,  lic=FREE),
                app("VirtualBox",      win="Oracle.VirtualBox",          linux="virtualbox",        mac="virtualbox",      app_type="VM",       os_sup=A,  lic=FREE),
            ],
        },
        "13": {
            "category"    : "Writing & Notes",
            "description" : "Note-taking, Markdown editors and writing tools",
            "apps": [
                app("Typora",       win="Typora.Typora",               linux="typora",           mac="typora",         app_type="Editor",  os_sup=A,  lic=PAID),
                app("Joplin",       win="Joplin.Joplin",               linux="joplin",           mac="joplin",         app_type="Notes",   os_sup=A,  lic=FREE),
                app("Logseq",       win="Logseq.Logseq",               linux="logseq",           mac="logseq",         app_type="Notes",   os_sup=A,  lic=FREE),
                app("Zettlr",       win="Zettlr.Zettlr",               linux="zettlr",           mac="zettlr",         app_type="Editor",  os_sup=A,  lic=FREE),
                app("MarkText",     win="MarkText.MarkText",           linux="marktext",          mac="mark-text",      app_type="Editor",  os_sup=A,  lic=FREE),
                app("Standard Notes",win="StandardNotes.StandardNotes",linux="standard-notes",    mac="standard-notes", app_type="Notes",   os_sup=A,  lic=FREEMIUM),
                app("Scrivener",    win="LiteratureAndLatte.Scrivener3",linux=None,               mac="scrivener",      app_type="Writing", os_sup=WM, lic=PAID),
                app("FocusWriter",  win=None,                          linux="focuswriter",        mac="focuswriter",    app_type="Writing", os_sup=LM, lic=FREE),
                app("Gedit",        win=None,                          linux="gedit",              mac=None,             app_type="Editor",  os_sup=L,  lic=FREE),
                app("Kate",         win="KDE.Kate",                    linux="kate",               mac="kate",           app_type="Editor",  os_sup=A,  lic=FREE),
            ],
        },
        "14": {
            "category"    : "Finance & Business",
            "description" : "Accounting, finance and business applications",
            "apps": [
                app("GnuCash",        win="GnuCash.GnuCash",           linux="gnucash",          mac="gnucash",         app_type="Finance",  os_sup=A,  lic=FREE),
                app("KMyMoney",       win="KMyMoney.KMyMoney",         linux="kmymoney",          mac="kmymoney",        app_type="Finance",  os_sup=A,  lic=FREE),
                app("HomeBank",       win="HomeBank.HomeBank",          linux="homebank",          mac="homebank",        app_type="Finance",  os_sup=A,  lic=FREE),
                app("Money Manager Ex",win="MoneyManagerEx.MoneyManagerEx",linux="moneymgr-ex",  mac="money-manager-ex",app_type="Finance",  os_sup=A,  lic=FREE),
                app("Skrooge",        win=None,                        linux="skrooge",            mac=None,              app_type="Finance",  os_sup=L,  lic=FREE),
                app("QuickBooks",     win="Intuit.QuickBooks",         linux=None,                mac=None,              app_type="Finance",  os_sup=W,  lic=PAID),
                app("Wave Accounting",win=None,                        linux=None,                mac=None,              app_type="Finance",  os_sup=[],  lic=FREE),
                app("Metatrader 5",   win="MetaQuotes.MetaTrader5",    linux=None,                mac=None,              app_type="Finance",  os_sup=W,  lic=FREE),
                app("Xero",           win=None,                        linux=None,                mac=None,              app_type="Finance",  os_sup=[],  lic=PAID),
                app("Zoho Books",     win="Zoho.ZohoBooks",            linux=None,                mac=None,              app_type="Finance",  os_sup=W,  lic=FREEMIUM),
            ],
        },
        "15": {
            "category"    : "Linux-Specific Tools",
            "description" : "Tools designed primarily for Linux",
            "apps": [
                app("GNOME Tweaks",  win=None, linux="gnome-tweaks",       mac=None, app_type="System",     os_sup=L, lic=FREE),
                app("Synaptic",      win=None, linux="synaptic",           mac=None, app_type="PackageMgr", os_sup=L, lic=FREE),
                app("htop",          win=None, linux="htop",               mac="htop",app_type="Monitor",  os_sup=LM,lic=FREE),
                app("Timeshift",     win=None, linux="timeshift",          mac=None, app_type="Backup",     os_sup=L, lic=FREE),
                app("Flameshot",     win=None, linux="flameshot",          mac="flameshot",app_type="Screenshot",os_sup=LM,lic=FREE),
                app("Neovim",        win="Neovim.Neovim",linux="neovim",   mac="neovim",app_type="Editor",  os_sup=A, lic=FREE),
                app("tmux",          win=None, linux="tmux",               mac="tmux",app_type="Terminal",  os_sup=LM,lic=FREE),
                app("zsh",           win=None, linux="zsh",                mac="zsh", app_type="Shell",     os_sup=LM,lic=FREE),
                app("Fish Shell",    win=None, linux="fish",               mac="fish",app_type="Shell",     os_sup=LM,lic=FREE),
                app("Flatpak",       win=None, linux="flatpak",            mac=None, app_type="PackageMgr", os_sup=L, lic=FREE),
            ],
        },
        "16": {
            "category"    : "macOS-Specific Tools",
            "description" : "Tools designed primarily for macOS",
            "apps": [
                app("Alfred",        win=None, linux=None, mac="alfred",         app_type="Launcher",   os_sup=M, lic=FREEMIUM),
                app("Raycast",       win=None, linux=None, mac="raycast",        app_type="Launcher",   os_sup=M, lic=FREE),
                app("Rectangle",     win=None, linux=None, mac="rectangle",      app_type="WM",         os_sup=M, lic=FREE),
                app("Magnet",        win=None, linux=None, mac="magnet",         app_type="WM",         os_sup=M, lic=PAID),
                app("Bartender",     win=None, linux=None, mac="bartender",      app_type="Utility",    os_sup=M, lic=PAID),
                app("CleanMyMac",    win=None, linux=None, mac="cleanmymac",     app_type="Cleaner",    os_sup=M, lic=PAID),
                app("Mosaic",        win=None, linux=None, mac="mosaic",         app_type="WM",         os_sup=M, lic=PAID),
                app("Lungo",         win=None, linux=None, mac="lungo",          app_type="Utility",    os_sup=M, lic=FREE),
                app("Amphetamine",   win=None, linux=None, mac=None,             app_type="Utility",    os_sup=M, lic=FREE),
                app("Homebrew",      win=None, linux=None, mac="brew",           app_type="PackageMgr", os_sup=M, lic=FREE),
            ],
        },
    }

    # stamp category name on each AppEntry
    for data in catalog.values():
        for entry in data["apps"]:
            entry.category = data["category"]

    return catalog


# ─────────────────────────────────────────────────────────────────────────────
# UI HELPERS
# ─────────────────────────────────────────────────────────────────────────────
def clear() -> None:
    os.system("cls" if platform.system() == "Windows" else "clear")


def divider(char: str = "─", width: int = WIDTH) -> str:
    return c(C.GREY, char * width)


def header_line(text: str, color: str = C.CYAN) -> None:
    pad = (WIDTH - len(text) - 2) // 2
    print(c(color, "╔" + "═" * (WIDTH - 2) + "╗"))
    print(c(color, "║") + " " * pad + c(C.BOLD + color, text) + " " * (WIDTH - 2 - pad - len(text)) + c(color, "║"))
    print(c(color, "╚" + "═" * (WIDTH - 2) + "╝"))


def box(lines: list[str], color: str = C.CYAN) -> None:
    w = WIDTH - 4
    print(c(color, "┌" + "─" * (WIDTH - 2) + "┐"))
    for line in lines:
        clean = re.sub(r"\033\[[0-9;]*m", "", line)  # strip ANSI for length
        pad = w - len(clean)
        print(c(color, "│ ") + line + " " * max(pad, 0) + c(color, " │"))
    print(c(color, "└" + "─" * (WIDTH - 2) + "┘"))


def banner() -> None:
    """ASCII art banner."""
    art = r"""
  ____                          ____     _ _
 |  _ \ _____      _____ _ __  / ___|___| | |
 | |_) / _ \ \ /\ / / _ \ '__|| |   / _ \ | |
 |  __/ (_) \ V  V /  __/ |   | |__|  __/ | |
 |_|   \___/ \_/\_/ \___|_|    \____\___|_|_|
"""
    print(c(C.CYAN + C.BOLD, art))
    print(c(C.YELLOW, "  Cross-Platform Professional Software Installer"))
    print(c(C.GREY, "  Author: Mohammad Mizanur Rahman  •  Version 2.0"))
    print()


def status_icon(status: str) -> str:
    return {
        "ok"   : c(C.GREEN,  "✔"),
        "fail" : c(C.RED,    "✘"),
        "skip" : c(C.YELLOW, "⊘"),
    }.get(status, "?")


def input_prompt(msg: str) -> str:
    return input(c(C.YELLOW, " ❯ ") + c(C.WHITE, msg + " ")).strip()


# ─────────────────────────────────────────────────────────────────────────────
# INSTALL QUEUE MANAGER
# ─────────────────────────────────────────────────────────────────────────────
class InstallQueue:
    def __init__(self) -> None:
        self._items: list[AppEntry] = []

    def add(self, app: AppEntry) -> bool:
        if app in self._items:
            return False
        self._items.append(app)
        return True

    def remove(self, app: AppEntry) -> bool:
        if app in self._items:
            self._items.remove(app)
            return True
        return False

    def clear(self) -> None:
        self._items.clear()

    def __len__(self) -> int:
        return len(self._items)

    def __iter__(self):
        return iter(self._items)

    def __contains__(self, app: AppEntry) -> bool:
        return app in self._items


# ─────────────────────────────────────────────────────────────────────────────
# MAIN APPLICATION
# ─────────────────────────────────────────────────────────────────────────────
class PowerCellApp:
    """
    Main controller class. Owns the detector, catalog, queue and installer.
    """

    def __init__(self) -> None:
        self.det      = SystemDetector()
        self.catalog  = build_catalog()
        self.queue    = InstallQueue()
        self.engine   = InstallerEngine(self.det)
        self._flat    : list[AppEntry] = self._flatten_catalog()

    # ------------------------------------------------------------------
    def _flatten_catalog(self) -> list[AppEntry]:
        apps = []
        for data in self.catalog.values():
            apps.extend(data["apps"])
        return apps

    # ------------------------------------------------------------------
    # HEADER
    # ------------------------------------------------------------------
    def _print_header(self) -> None:
        clear()
        banner()
        print(divider())
        print(self.det.summary())
        queue_info = c(C.GREEN, f"{len(self.queue)} item(s) in queue")
        print(f" Queue: {queue_info}")
        print(divider())
        print()

    # ------------------------------------------------------------------
    # MAIN MENU
    # ------------------------------------------------------------------
    def run(self) -> None:
        while True:
            self._print_header()
            print(c(C.BOLD + C.YELLOW, "  MAIN MENU — SELECT A CATEGORY"))
            print(divider("─"))
            print()

            cat_keys = list(self.catalog.keys())
            for key in cat_keys:
                data = self.catalog[key]
                apps = data["apps"]
                # count apps available for current OS
                avail = sum(1 for a in apps if self.det.current_os in a.os_support)
                label = f"[{key:>2}] {data['category']}"
                desc  = data["description"]
                avail_str = c(C.GREY, f"({avail} available)")
                print(f"  {c(C.WHITE, label):<36} {c(C.GREY, desc)}")
                print(f"       {avail_str}")
                print()

            print(divider("─"))
            print(f"  {c(C.GREEN,  '[99]')}  START INSTALLATION  {c(C.GREY, f'({len(self.queue)} items)')}")
            print(f"  {c(C.CYAN,   '[S ]')}  Search software by name")
            print(f"  {c(C.CYAN,   '[I ]')}  Install a single package by ID / name")
            print(f"  {c(C.CYAN,   '[V ]')}  View installation queue")
            print(f"  {c(C.YELLOW, '[C ]')}  Clear queue")
            print(f"  {c(C.GREY,   '[Q ]')}  Quit")
            print()

            choice = input_prompt("Enter choice:").upper()

            if choice == "Q":
                print(c(C.CYAN, "\n  Goodbye from PowerCell!\n"))
                sys.exit(0)
            elif choice == "99":
                self._run_installation()
            elif choice == "S":
                self._search_menu()
            elif choice == "I":
                self._quick_install()
            elif choice == "V":
                self._view_queue()
            elif choice == "C":
                self.queue.clear()
                print(c(C.YELLOW, "  Queue cleared."))
                input(c(C.GREY, "  Press Enter to continue…"))
            elif choice in self.catalog:
                self._category_menu(choice)
            else:
                print(c(C.RED, "  Invalid choice — please try again."))
                input(c(C.GREY, "  Press Enter to continue…"))

    # ------------------------------------------------------------------
    # CATEGORY SUB-MENU
    # ------------------------------------------------------------------
    def _category_menu(self, cat_key: str) -> None:
        data = self.catalog[cat_key]
        apps = data["apps"]

        while True:
            self._print_header()
            header_line(f"  {data['category']}  ")
            print(c(C.GREY, f"  {data['description']}"))
            print()

            for idx, app in enumerate(apps, 1):
                in_q  = "●" if app in self.queue else " "
                avail = self.det.current_os in app.os_support
                color = C.WHITE if avail else C.GREY
                num   = c(C.CYAN, f"[{idx:>2}]")
                q_mark = c(C.GREEN, in_q)
                compat = c(C.GREEN, "✔") if avail else c(C.GREY, "✘")
                os_b  = app.os_badge()
                lic_b = app.license_badge()
                name  = c(color, app.name)
                print(f"  {num} {q_mark} {compat} {name:<30} {os_b}  {lic_b}")

            print()
            print(divider("─"))
            print(f"  Enter number to {c(C.GREEN,'add/remove from queue')} | {c(C.YELLOW,'A')}=add all | {c(C.CYAN,'B')}=back")
            print()

            choice = input_prompt("Choice:").upper()

            if choice == "B":
                break
            elif choice == "A":
                added = 0
                for a in apps:
                    if self.det.current_os in a.os_support:
                        if self.queue.add(a):
                            added += 1
                print(c(C.GREEN, f"  Added {added} app(s) to queue."))
                input(c(C.GREY, "  Press Enter to continue…"))
            elif choice.isdigit():
                idx = int(choice) - 1
                if 0 <= idx < len(apps):
                    app = apps[idx]
                    if app in self.queue:
                        self.queue.remove(app)
                        print(c(C.YELLOW, f"  Removed '{app.name}' from queue."))
                    else:
                        if self.det.current_os not in app.os_support:
                            print(c(C.YELLOW, f"  '{app.name}' is not available for {self.det.current_os.value}. Added anyway."))
                        self.queue.add(app)
                        print(c(C.GREEN, f"  Added '{app.name}' to queue."))
                    input(c(C.GREY, "  Press Enter…"))
                else:
                    print(c(C.RED, "  Invalid number."))
                    input(c(C.GREY, "  Press Enter…"))
            else:
                print(c(C.RED, "  Invalid input."))
                input(c(C.GREY, "  Press Enter…"))

    # ------------------------------------------------------------------
    # SEARCH MENU
    # ------------------------------------------------------------------
    def _search_menu(self) -> None:
        while True:
            self._print_header()
            header_line("SOFTWARE SEARCH")
            print()
            query = input_prompt("Enter name to search (or blank to go back):")
            if not query:
                break

            results = [a for a in self._flat if query.lower() in a.name.lower()]
            if not results:
                print(c(C.RED, "  No results found."))
                input(c(C.GREY, "  Press Enter…"))
                continue

            print()
            print(c(C.BOLD, f"  Found {len(results)} result(s):"))
            print()
            for i, app in enumerate(results, 1):
                avail = c(C.GREEN, "✔") if self.det.current_os in app.os_support else c(C.GREY, "✘")
                print(f"  [{i:>2}] {avail} {app.name:<32} {app.os_badge()}  {app.license_badge()}")
                print(f"        Category: {c(C.GREY, app.category)}")

            print()
            choice = input_prompt("Enter number to add to queue (or blank to search again):")
            if choice.isdigit():
                idx = int(choice) - 1
                if 0 <= idx < len(results):
                    self.queue.add(results[idx])
                    print(c(C.GREEN, f"  Added '{results[idx].name}'."))
                    input(c(C.GREY, "  Press Enter…"))

    # ------------------------------------------------------------------
    # QUICK INSTALL
    # ------------------------------------------------------------------
    def _quick_install(self) -> None:
        self._print_header()
        header_line("QUICK INSTALL BY PACKAGE ID / NAME")
        print()
        pkg = input_prompt("Enter winget/apt/brew ID or software name:")
        if not pkg:
            return

        # Check catalog first
        matches = [a for a in self._flat if pkg.lower() in a.name.lower()
                   or (a.win_id and pkg.lower() in a.win_id.lower())
                   or (a.linux_pkg and pkg.lower() in a.linux_pkg.lower())
                   or (a.mac_pkg and pkg.lower() in a.mac_pkg.lower())]

        if matches:
            print(c(C.CYAN, f"\n  Found {len(matches)} catalog match(es). Installing first match…"))
            result = self.engine.install(matches[0])
        else:
            # Build ad-hoc entry
            print(c(C.YELLOW, "  Not in catalog — attempting direct install…"))
            ad_hoc = AppEntry(
                name=pkg, win_id=pkg, linux_pkg=pkg, mac_pkg=pkg,
                app_type="Custom", os_support=[self.det.current_os],
                license_type=License.FREE, req_arch=["any"], req_os_min="Any",
            )
            result = self.engine.install(ad_hoc)

        icon = status_icon(result.status)
        print(f"\n  {icon}  {result.app.name}: {result.notes}")
        input(c(C.GREY, "\n  Press Enter to continue…"))

    # ------------------------------------------------------------------
    # VIEW QUEUE
    # ------------------------------------------------------------------
    def _view_queue(self) -> None:
        self._print_header()
        header_line("INSTALLATION QUEUE")
        print()
        if not self.queue:
            print(c(C.YELLOW, "  Queue is empty."))
        else:
            for i, app in enumerate(self.queue, 1):
                print(f"  {c(C.CYAN, f'[{i:>2}]')} {app.name:<35} {app.os_badge()}  {app.license_badge()}")
            print()
            print(c(C.GREY, f"  Total: {len(self.queue)} item(s)"))
        print()
        input(c(C.GREY, "  Press Enter to go back…"))

    # ------------------------------------------------------------------
    # RUN INSTALLATION
    # ------------------------------------------------------------------
    def _run_installation(self) -> None:
        if not self.queue:
            print(c(C.RED, "\n  Queue is empty — nothing to install!\n"))
            input(c(C.GREY, "  Press Enter…"))
            return

        clear()
        banner()
        header_line(f"INSTALLING {len(self.queue)} APP(S)", C.GREEN)
        print()

        results: list[InstallResult] = []
        total = len(list(self.queue))

        for i, app in enumerate(list(self.queue), 1):
            pct = int((i - 1) / total * 100)
            bar_len = 30
            filled = int(bar_len * (i - 1) / total)
            bar = c(C.GREEN, "█" * filled) + c(C.GREY, "░" * (bar_len - filled))
            print(f"\n  [{bar}] {pct:>3}%")
            print(f"  {c(C.CYAN, f'({i}/{total})')} Installing: {c(C.WHITE, app.name)}")
            print(f"         {app.os_badge()}  {app.license_badge()}")

            result = self.engine.install(app)
            icon   = status_icon(result.status)
            color  = C.GREEN if result.status == "ok" else (C.YELLOW if result.status == "skip" else C.RED)
            print(f"         {icon}  {c(color, result.notes)}")
            results.append(result)

        # Summary
        print()
        print(divider("═"))
        ok_n    = sum(1 for r in results if r.status == "ok")
        fail_n  = sum(1 for r in results if r.status == "fail")
        skip_n  = sum(1 for r in results if r.status == "skip")
        box([
            f"  Installation Complete!",
            f"",
            f"  {c(C.GREEN,  '✔ Succeeded')} : {ok_n}",
            f"  {c(C.RED,    '✘ Failed   ')} : {fail_n}",
            f"  {c(C.YELLOW, '⊘ Skipped  ')} : {skip_n}",
        ])

        if fail_n:
            print()
            print(c(C.RED, "  Failed installs:"))
            for r in results:
                if r.status == "fail":
                    print(f"    • {r.app.name} — {c(C.GREY, r.notes)}")

        self.queue.clear()
        print()
        input(c(C.GREY, "  Press Enter to return to main menu…"))


# ─────────────────────────────────────────────────────────────────────────────
# ENTRY POINT
# ─────────────────────────────────────────────────────────────────────────────
def main() -> None:
    try:
        app = PowerCellApp()
        app.run()
    except KeyboardInterrupt:
        print(c(C.CYAN, "\n\n  PowerCell interrupted. Goodbye!\n"))
        sys.exit(0)


if __name__ == "__main__":
    main()
