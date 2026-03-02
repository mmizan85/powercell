<#
    Project: WinSetup CLI - Professional Installer
    Author: Mohammad Mizanur Rahman
    Description: 5 =>> 0+ Tools Installer with Queue System & Smart Detection
    Version: 1.5
    Compatibility: PowerShell 3.0+
#>

# $size = New-Object System.Management.Automation.Host.Size(75,80)
# $host.UI.RawUI.WindowSize = $size
# $host.UI.RawUI.BufferSize = $size

# ---------------------------------------------------------
# 1. INITIALIZATION & COMPATIBILITY
# ---------------------------------------------------------
# Clear screen and set basic settings
$Host.UI.RawUI.WindowTitle = "`nWinSetup CLI - Professional Installer (500+ Tools)"
try {
    [console]::ForegroundColor = "Cyan"
} catch {
    # Fallback for older PowerShell versions
    $Host.UI.RawUI.ForegroundColor = "Cyan"
}
Clear-Host

# Global Variables
$global:InstallQueue = @()
$global:AllSoftwareList = @()
$global:IsAdmin = ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
$global:PSVersion = $PSVersionTable.PSVersion.Major

# ---------------------------------------------------------
# 2. SYSTEM DETECTION FUNCTIONS
# ---------------------------------------------------------
function Get-SystemInfo {
    $systemInfo = @{}
    
    # Get OS Architecture
    if ([Environment]::Is64BitOperatingSystem) {
        $systemInfo.Architecture = "x64"
        $systemInfo.Bits = "64-bit"
    } else {
        $systemInfo.Architecture = "x86"
        $systemInfo.Bits = "32-bit"
    }
    
    # Get OS Version
    $os = Get-WmiObject -Class Win32_OperatingSystem
    $systemInfo.OSVersion = $os.Version
    $systemInfo.OSName = $os.Caption
    $systemInfo.BuildNumber = $os.BuildNumber
    
    # Get .NET Framework Version
    try {
        $netRegistry = Get-ItemProperty "HKLM:\SOFTWARE\Microsoft\NET Framework Setup\NDP\v4\Full" -ErrorAction SilentlyContinue
        if ($netRegistry -and $netRegistry.Release) {
            $systemInfo.DotNetVersion = $netRegistry.Release
        }
    } catch {
        $systemInfo.DotNetVersion = "Unknown"
    }
    
    # Get Windows Edition
    $systemInfo.Edition = $os.OSArchitecture
    
    # Get Total RAM
    $systemInfo.TotalRAM = [math]::Round($os.TotalVisibleMemorySize / 1MB, 2)
    
    return $systemInfo
}

function Test-AdminPrivileges {
    if (-not $global:IsAdmin) {
        Write-Host "Warning: Running without administrator privileges!" -ForegroundColor Yellow
        Write-Host "Some installations may require admin rights." -ForegroundColor Yellow
        Write-Host ""
        return $false
    }
    return $true
}

# ---------------------------------------------------------
# 3. ENHANCED SOFTWARE DATABASE (500+ Tools)
# ---------------------------------------------------------
$Catalog = [ordered]@{
    "01" = @{ 
        Category = "Web Browsers"
        Description = " =>> Internet browsers for web surfing"
        Apps = [ordered]@{
            "001" = @{Name="Google Chrome [Free]"; ID="Google.Chrome"; Type="Browser"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "002" = @{Name="Mozilla Firefox [Free]"; ID="Mozilla.Firefox"; Type="Browser"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "003" = @{Name="Microsoft Edge [Free]"; ID="Microsoft.Edge"; Type="Browser"; ReqArch="x64"; ReqOS="Windows 10+"; License="Free"}
            "004" = @{Name="Opera Browser [Free]"; ID="Opera.Opera"; Type="Browser"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "005" = @{Name="Brave Browser [Free]"; ID="Brave.Brave"; Type="Browser"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "006" = @{Name="Vivaldi Browser [Free]"; ID="VivaldiTechnologies.Vivaldi"; Type="Browser"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "007" = @{Name="Tor Browser [Free]"; ID="TorProject.TorBrowser"; Type="Browser"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "008" = @{Name="Maxthon Browser [Free]"; ID="Maxthon.Maxthon"; Type="Browser"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "009" = @{Name="Waterfox [Free]"; ID="Waterfox.Waterfox"; Type="Browser"; ReqArch="x64"; ReqOS="Windows 7+"; License="Free"}
            "010" = @{Name="Pale Moon [Free]"; ID="MoonchildProductions.PaleMoon"; Type="Browser"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
        }
    }
    
    "02" = @{ 
        Category = "Communication Tools"
        Description = " =>> Messaging, chat and video calling applications"
        Apps = [ordered]@{
            "001" = @{Name="WhatsApp Desktop [Free]"; ID="WhatsApp.WhatsApp"; Type="Messenger"; ReqArch="x64,x86"; ReqOS="Windows 8+"; License="Free"}
            "002" = @{Name="Telegram Desktop [Free]"; ID="Telegram.TelegramDesktop"; Type="Messenger"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "003" = @{Name="Discord [Free]"; ID="Discord.Discord"; Type="Messenger"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "004" = @{Name="Zoom [Free/Paid]"; ID="Zoom.Zoom"; Type="VideoCall"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "005" = @{Name="Skype [Free]"; ID="Microsoft.Skype"; Type="VideoCall"; ReqArch="x64,x86"; ReqOS="Windows 10+"; License="Free"}
            "006" = @{Name="Signal Desktop [Free]"; ID="Signal.Signal"; Type="Messenger"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "007" = @{Name="Slack [Free/Paid]"; ID="SlackTechnologies.Slack"; Type="Business"; ReqArch="x64,x86"; ReqOS="Windows 10+"; License="Freemium"}
            "008" = @{Name="Microsoft Teams [Free]"; ID="Microsoft.Teams"; Type="Business"; ReqArch="x64,x86"; ReqOS="Windows 10+"; License="Free"}
            "009" = @{Name="Viber [Free]"; ID="Viber.Viber"; Type="Messenger"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "010" = @{Name="LINE Desktop [Free]"; ID="LINE.LINE"; Type="Messenger"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
        }
    }
    
    "03" = @{ 
        Category = "Development Tools"
        Description = " =>> Programming, coding and development environments"
        Apps = [ordered]@{
            "001" = @{Name="Visual Studio Code [Free]"; ID="Microsoft.VisualStudioCode"; Type="IDE"; ReqArch="x64,x86"; ReqOS="Windows 8+"; License="Free"}
            "002" = @{Name="Python 3.12 [Free]"; ID="Python.Python.3.12"; Type="Runtime"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "003" = @{Name="Node.js LTS [Free]"; ID="OpenJS.NodeJS.LTS"; Type="Runtime"; ReqArch="x64,x86"; ReqOS="Windows 8+"; License="Free"}
            "004" = @{Name="Git [Free]"; ID="Git.Git"; Type="VersionControl"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "005" = @{Name="Docker Desktop [Free]"; ID="Docker.DockerDesktop"; Type="Container"; ReqArch="x64"; ReqOS="Windows 10+"; License="Free"}
            "006" = @{Name="Postman [Free/Paid]"; ID="Postman.Postman"; Type="API"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "007" = @{Name="Android Studio [Free]"; ID="Google.AndroidStudio"; Type="IDE"; ReqArch="x64"; ReqOS="Windows 8+"; License="Free"}
            "008" = @{Name="Java JDK [Free]"; ID="Oracle.JDK.21"; Type="Runtime"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "009" = @{Name="Visual Studio Community [Free]"; ID="Microsoft.VisualStudio.2022.Community"; Type="IDE"; ReqArch="x64"; ReqOS="Windows 10+"; License="Free"}
            "010" = @{Name="Notepad++ [Free]"; ID="Notepad++.Notepad++"; Type="Editor"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
        }
    }
    
    "04" = @{ 
        Category = "Media & Entertainment"
        Description = " =>> Music, video players and media applications"
        Apps = [ordered]@{
            "001" = @{Name="VLC Media Player [Free]"; ID="VideoLAN.VLC"; Type="Player"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "002" = @{Name="Spotify [Free/Paid]"; ID="Spotify.Spotify"; Type="Music"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "003" = @{Name="iTunes [Free]"; ID="Apple.iTunes"; Type="Music"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "004" = @{Name="K-Lite Codec Pack [Free]"; ID="CodecGuide.K-LiteCodecPack.Full"; Type="Codec"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "005" = @{Name="PotPlayer [Free]"; ID="Daum.PotPlayer"; Type="Player"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "006" = @{Name="Winamp [Free]"; ID="Winamp.Winamp"; Type="Music"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "007" = @{Name="Foobar2000 [Free]"; ID="PeterPawlowski.foobar2000"; Type="Music"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "008" = @{Name="Kodi [Free]"; ID="XBMCFoundation.Kodi"; Type="MediaCenter"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "009" = @{Name="OBS Studio [Free]"; ID="OBSProject.OBSStudio"; Type="Streaming"; ReqArch="x64,x86"; ReqOS="Windows 8+"; License="Free"}
            "010" = @{Name="Audacity [Free]"; ID="Audacity.Audacity"; Type="AudioEditor"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
        }
    }
    
    "05" = @{ 
        Category = "System Utilities"
        Description = " =>> Tools for system maintenance and optimization"
        Apps = [ordered]@{
            "001" = @{Name="WinRAR [Paid]"; ID="WinRAR.WinRAR"; Type="Compression"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Trial"}
            "002" = @{Name="7-Zip [Free]"; ID="7zip.7zip"; Type="Compression"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "003" = @{Name="CCleaner [Free/Paid]"; ID="Piriform.CCleaner"; Type="Cleaner"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "004" = @{Name="Rufus [Free]"; ID="Rufus.Rufus"; Type="USB"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "005" = @{Name="Everything [Free]"; ID="voidtools.Everything"; Type="Search"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "006" = @{Name="PowerToys [Free]"; ID="Microsoft.PowerToys"; Type="Productivity"; ReqArch="x64"; ReqOS="Windows 10+"; License="Free"}
            "007" = @{Name="CPU-Z [Free]"; ID="CPUID.CPU-Z"; Type="Monitor"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "008" = @{Name="GPU-Z [Free]"; ID="TechPowerUp.GPU-Z"; Type="Monitor"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "009" = @{Name="HWMonitor [Free]"; ID="CPUID.HWMonitor"; Type="Monitor"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "010" = @{Name="Revo Uninstaller [Free/Paid]"; ID="RevoUninstaller.RevoUninstaller"; Type="Uninstaller"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
        }
    }
    
    "06" = @{ 
        Category = "Office & Productivity"
        Description = " =>> Office suites and productivity applications"
        Apps = [ordered]@{
            "001" = @{Name="Microsoft Office [Paid]"; ID="Microsoft.Office"; Type="Office"; ReqArch="x64,x86"; ReqOS="Windows 10+"; License="Paid"}
            "002" = @{Name="LibreOffice [Free]"; ID="TheDocumentFoundation.LibreOffice"; Type="Office"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "003" = @{Name="OnlyOffice [Free]"; ID="ONLYOFFICE.DesktopEditors"; Type="Office"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "004" = @{Name="WPS Office [Free/Paid]"; ID="Kingsoft.WPSOffice"; Type="Office"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "005" = @{Name="Google Drive [Free]"; ID="Google.Drive"; Type="Cloud"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "006" = @{Name="OneDrive [Free]"; ID="Microsoft.OneDrive"; Type="Cloud"; ReqArch="x64,x86"; ReqOS="Windows 10+"; License="Free"}
            "007" = @{Name="Adobe Acrobat Reader [Free]"; ID="Adobe.Acrobat.Reader.64-bit"; Type="PDF"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "008" = @{Name="Foxit Reader [Free]"; ID="Foxit.FoxitReader"; Type="PDF"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "009" = @{Name="SumatraPDF [Free]"; ID="SumatraPDF.SumatraPDF"; Type="PDF"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "010" = @{Name="Calibre [Free]"; ID="calibre.calibre"; Type="Ebook"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
        }
    }
    
    "07" = @{ 
        Category = "Security & Privacy"
        Description = " =>> Antivirus, VPN and security software"
        Apps = [ordered]@{
            "001" = @{Name="Malwarebytes [Free/Paid]"; ID="Malwarebytes.Malwarebytes"; Type="Antivirus"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "002" = @{Name="Bitdefender [Free/Paid]"; ID="Bitdefender.Bitdefender"; Type="Antivirus"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "003" = @{Name="Avast Free Antivirus [Free]"; ID="Avast.Antivirus"; Type="Antivirus"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "004" = @{Name="AVG Antivirus [Free]"; ID="AVG.Antivirus"; Type="Antivirus"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "005" = @{Name="Kaspersky [Free/Paid]"; ID="Kaspersky.Kaspersky"; Type="Antivirus"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "006" = @{Name="VeraCrypt [Free]"; ID="IDRIX.VeraCrypt"; Type="Encryption"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "007" = @{Name="KeePass [Free]"; ID="KeePassXCTeam.KeePassXC"; Type="Password"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "008" = @{Name="Bitwarden [Free/Paid]"; ID="Bitwarden.Bitwarden"; Type="Password"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "009" = @{Name="ProtonVPN [Free/Paid]"; ID="ProtonTechnologies.ProtonVPN"; Type="VPN"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "010" = @{Name="NordVPN [Paid]"; ID="NordVPN.NordVPN"; Type="VPN"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Paid"}
        }
    }
    
    "08" = @{ 
        Category = "Graphics & Design"
        Description = " =>> Photo editing, design and 3D modeling"
        Apps = [ordered]@{
            "001" = @{Name="GIMP [Free]"; ID="GIMP.GIMP"; Type="Design"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "002" = @{Name="Inkscape [Free]"; ID="Inkscape.Inkscape"; Type="Vector"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "003" = @{Name="Blender [Free]"; ID="BlenderFoundation.Blender"; Type="3D"; ReqArch="x64"; ReqOS="Windows 8+"; License="Free"}
            "004" = @{Name="Paint.NET [Free]"; ID="dotPDN.Paint.NET"; Type="Editor"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "005" = @{Name="Krita [Free]"; ID="KDE.Krita"; Type="Painting"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "006" = @{Name="Adobe Photoshop [Paid]"; ID="Adobe.Photoshop"; Type="Design"; ReqArch="x64"; ReqOS="Windows 10+"; License="Paid"}
            "007" = @{Name="Adobe Illustrator [Paid]"; ID="Adobe.Illustrator"; Type="Design"; ReqArch="x64"; ReqOS="Windows 10+"; License="Paid"}
            "008" = @{Name="CorelDRAW [Paid]"; ID="Corel.CorelDRAW"; Type="Design"; ReqArch="x64"; ReqOS="Windows 10+"; License="Paid"}
            "009" = @{Name="Figma [Free/Paid]"; ID="Figma.Figma"; Type="Design"; ReqArch="x64"; ReqOS="Windows 10+"; License="Freemium"}
            "010" = @{Name="Canva [Free/Paid]"; ID="Canva.Canva"; Type="Design"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
        }
    }
    
    "09" = @{ 
        Category = "Gaming Platforms"
        Description = " =>> Game launchers and gaming platforms"
        Apps = [ordered]@{
            "001" = @{Name="Steam [Free]"; ID="@Valve.Steam"; Type="Platform"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "002" = @{Name="Epic Games Launcher [Free]"; ID="EpicGames.EpicGamesLauncher"; Type="Platform"; ReqArch="x64"; ReqOS="Windows 7+"; License="Free"}
            "003" = @{Name="Ubisoft Connect [Free]"; ID="Ubisoft.Connect"; Type="Platform"; ReqArch="x64"; ReqOS="Windows 7+"; License="Free"}
            "004" = @{Name="EA App [Free]"; ID="ElectronicArts.EADesktop"; Type="Platform"; ReqArch="x64"; ReqOS="Windows 10+"; License="Free"}
            "005" = @{Name="GOG Galaxy [Free]"; ID="GOG.Galaxy"; Type="Platform"; ReqArch="x64"; ReqOS="Windows 7+"; License="Free"}
            "006" = @{Name="Battle.net [Free]"; ID="Blizzard.BattleNet"; Type="Platform"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "007" = @{Name="Xbox App [Free]"; ID="Microsoft.GamingApp"; Type="Platform"; ReqArch="x64"; ReqOS="Windows 10+"; License="Free"}
            "008" = @{Name="Rockstar Games Launcher [Free]"; ID="RockstarGames.RockstarGamesLauncher"; Type="Platform"; ReqArch="x64"; ReqOS="Windows 10+"; License="Free"}
            "009" = @{Name="Origin [Free]"; ID="ElectronicArts.Origin"; Type="Platform"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "010" = @{Name="itch.io [Free]"; ID="itchio.itch"; Type="Platform"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
        }
    }
    
    "10" = @{ 
        Category = "Networking Tools"
        Description = " =>> Network utilities, FTP and remote access"
        Apps = [ordered]@{
            "001" = @{Name="FileZilla [Free]"; ID="FileZilla.FileZilla"; Type="FTP"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "002" = @{Name="PuTTY [Free]"; ID="PuTTY.PuTTY"; Type="SSH"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "003" = @{Name="WinSCP [Free]"; ID="WinSCP.WinSCP"; Type="FTP"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "004" = @{Name="Wireshark [Free]"; ID="WiresharkFoundation.Wireshark"; Type="Analyzer"; ReqArch="x64,x86"; ReqOS="Windows 8+"; License="Free"}
            "005" = @{Name="TeamViewer [Free/Paid]"; ID="TeamViewer.TeamViewer"; Type="Remote"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "006" = @{Name="AnyDesk [Free/Paid]"; ID="AnyDeskSoftwareGmbH.AnyDesk"; Type="Remote"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "007" = @{Name="OpenVPN [Free]"; ID="OpenVPN.OpenVPN"; Type="VPN"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "008" = @{Name="Hamachi [Free]"; ID="LogMeIn.Hamachi"; Type="VPN"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "009" = @{Name="Angry IP Scanner [Free]"; ID="AngryIPScanner.AngryIPScanner"; Type="Scanner"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "010" = @{Name="Advanced IP Scanner [Free]"; ID="Famatech.AdvancedIPScanner"; Type="Scanner"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
        }
    }
    
    "11" = @{ 
        Category = "Database Tools"
        Description = " =>> Database management and development"
        Apps = [ordered]@{
            "001" = @{Name="MySQL [Free]"; ID="Oracle.MySQL"; Type="Database"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "002" = @{Name="PostgreSQL [Free]"; ID="PostgreSQL.PostgreSQL"; Type="Database"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "003" = @{Name="MongoDB [Free]"; ID="MongoDB.MongoDB"; Type="Database"; ReqArch="x64"; ReqOS="Windows 7+"; License="Free"}
            "004" = @{Name="SQLite [Free]"; ID="SQLite.SQLite"; Type="Database"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "005" = @{Name="DBeaver [Free]"; ID="DBeaver.DBeaver"; Type="DatabaseTool"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "006" = @{Name="HeidiSQL [Free]"; ID="HeidiSQL.HeidiSQL"; Type="DatabaseTool"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "007" = @{Name="phpMyAdmin [Free]"; ID="phpMyAdmin.phpMyAdmin"; Type="DatabaseTool"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "008" = @{Name="Azure Data Studio [Free]"; ID="Microsoft.AzureDataStudio"; Type="DatabaseTool"; ReqArch="x64"; ReqOS="Windows 10+"; License="Free"}
            "009" = @{Name="Redis [Free]"; ID="Redis.Redis"; Type="Database"; ReqArch="x64"; ReqOS="Windows 7+"; License="Free"}
            "010" = @{Name="MariaDB [Free]"; ID="MariaDB.MariaDB"; Type="Database"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
        }
    }
    
    "12" = @{ 
        Category = "Backup & Recovery"
        Description = " =>> Data backup and recovery solutions"
        Apps = [ordered]@{
            "001" = @{Name="EaseUS Todo Backup [Free/Paid]"; ID="EaseUS.TodoBackup"; Type="Backup"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "002" = @{Name="Macrium Reflect [Free/Paid]"; ID="Macrium.MacriumReflect"; Type="Backup"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "003" = @{Name="AOMEI Backupper [Free/Paid]"; ID="AOMEI.Backupper"; Type="Backup"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "004" = @{Name="Cobian Backup [Free]"; ID="CobianSoftware.CobianBackup"; Type="Backup"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "005" = @{Name="Duplicati [Free]"; ID="Duplicati.Duplicati"; Type="Backup"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "006" = @{Name="Recuva [Free]"; ID="Piriform.Recuva"; Type="Recovery"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "007" = @{Name="TestDisk [Free]"; ID="TestDisk.TestDisk"; Type="Recovery"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "008" = @{Name="MiniTool Partition Wizard [Free/Paid]"; ID="MiniTool.PartitionWizard"; Type="Partition"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "009" = @{Name="AOMEI Partition Assistant [Free/Paid]"; ID="AOMEI.PartitionAssistant"; Type="Partition"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "010" = @{Name="SyncBackFree [Free]"; ID="2BrightSparks.SyncBackFree"; Type="Sync"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
        }
    }
    
    "13" = @{ 
        Category = "Education & Learning"
        Description = " =>> Educational and learning software"
        Apps = [ordered]@{
            "001" = @{Name="GeoGebra [Free]"; ID="GeoGebra.GeoGebra"; Type="Math"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "002" = @{Name="Google Earth Pro [Free]"; ID="Google.GoogleEarthPro"; Type="Geography"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "003" = @{Name="Anki [Free]"; ID="Anki.Anki"; Type="Flashcards"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "004" = @{Name="MuseScore [Free]"; ID="MuseScore.MuseScore"; Type="Music"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "005" = @{Name="Jupyter Notebook [Free]"; ID="ProjectJupyter.JupyterLab"; Type="Programming"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "006" = @{Name="RStudio [Free]"; ID="RStudio.RStudio"; Type="Programming"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "007" = @{Name="GNU Octave [Free]"; ID="GNU.Octave"; Type="Math"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "008" = @{Name="Scilab [Free]"; ID="Scilab.Scilab"; Type="Math"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "009" = @{Name="KiCad [Free]"; ID="KiCad.KiCad"; Type="Electronics"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "010" = @{Name="Stellarium [Free]"; ID="Stellarium.Stellarium"; Type="Astronomy"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
        }
    }
    
    "14" = @{ 
        Category = "Virtualization"
        Description = " =>> Virtual machines and container platforms"
        Apps = [ordered]@{
            "001" = @{Name="VirtualBox [Free]"; ID="Oracle.VirtualBox"; Type="VM"; ReqArch="x64"; ReqOS="Windows 8+"; License="Free"}
            "002" = @{Name="VMware Workstation Player [Free]"; ID="VMware.WorkstationPlayer"; Type="VM"; ReqArch="x64"; ReqOS="Windows 8+"; License="Free"}
            "003" = @{Name="Docker Desktop [Free]"; ID="Docker.DockerDesktop"; Type="Container"; ReqArch="x64"; ReqOS="Windows 10+"; License="Free"}
            "004" = @{Name="Windows Subsystem for Linux [Free]"; ID="Microsoft.WSL"; Type="VM"; ReqArch="x64"; ReqOS="Windows 10+"; License="Free"}
            "005" = @{Name="QEMU [Free]"; ID="QEMU.QEMU"; Type="VM"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "006" = @{Name="Sandboxie [Free/Paid]"; ID="Sandboxie.Sandboxie"; Type="Sandbox"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "007" = @{Name="Hyper-V [Free]"; ID="Microsoft.HyperV"; Type="VM"; ReqArch="x64"; ReqOS="Windows 10+"; License="Free"}
            "008" = @{Name="Vagrant [Free]"; ID="HashiCorp.Vagrant"; Type="VM"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "009" = @{Name="Parallels Desktop [Paid]"; ID="Parallels.ParallelsDesktop"; Type="VM"; ReqArch="x64"; ReqOS="Windows 10+"; License="Paid"}
            "010" = @{Name="Citrix Hypervisor [Free]"; ID="Citrix.Hypervisor"; Type="VM"; ReqArch="x64"; ReqOS="Windows 10+"; License="Free"}
        }
    }
    
    "15" = @{ 
        Category = "Programming Languages"
        Description = " =>> Programming language runtimes and compilers"
        Apps = [ordered]@{
            "001" = @{Name="Python [Free]"; ID="Python.Python"; Type="Runtime"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "002" = @{Name="Java Runtime Environment [Free]"; ID="Oracle.JavaRuntimeEnvironment"; Type="Runtime"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "003" = @{Name="C++ Redistributable [Free]"; ID="Microsoft.VCRedist.2015+.x64"; Type="Runtime"; ReqArch="x64"; ReqOS="Windows 7+"; License="Free"}
            "004" = @{Name=".NET Framework [Free]"; ID="Microsoft.DotNet.Framework.4.8"; Type="Runtime"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "005" = @{Name="Go [Free]"; ID="GoLang.Go"; Type="Runtime"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "006" = @{Name="Rust [Free]"; ID="Rustlang.Rust"; Type="Runtime"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "007" = @{Name="PHP [Free]"; ID="PHP.PHP"; Type="Runtime"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "008" = @{Name="Perl [Free]"; ID="ActiveState.Perl"; Type="Runtime"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "009" = @{Name="Ruby [Free]"; ID="RubyInstallerTeam.Ruby"; Type="Runtime"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "010" = @{Name="Lua [Free]"; ID="Lua.Lua"; Type="Runtime"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
        }
    }
    
    "16" = @{ 
        Category = "Video Production"
        Description = " =>> Video editing and production software"
        Apps = [ordered]@{
            "001" = @{Name="DaVinci Resolve [Free/Paid]"; ID="BlackmagicDesign.DaVinciResolve"; Type="Editor"; ReqArch="x64"; ReqOS="Windows 10+"; License="Freemium"}
            "002" = @{Name="Shotcut [Free]"; ID="Shotcut.Shotcut"; Type="Editor"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "003" = @{Name="OpenShot [Free]"; ID="OpenShot.OpenShot"; Type="Editor"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "004" = @{Name="Lightworks [Free/Paid]"; ID="LWKS.Lightworks"; Type="Editor"; ReqArch="x64"; ReqOS="Windows 7+"; License="Freemium"}
            "005" = @{Name="Kdenlive [Free]"; ID="KDE.Kdenlive"; Type="Editor"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "006" = @{Name="HitFilm Express [Free]"; ID="FXhome.HitFilm"; Type="Editor"; ReqArch="x64"; ReqOS="Windows 7+"; License="Free"}
            "007" = @{Name="Adobe Premiere Pro [Paid]"; ID="Adobe.PremierePro"; Type="Editor"; ReqArch="x64"; ReqOS="Windows 10+"; License="Paid"}
            "008" = @{Name="Adobe After Effects [Paid]"; ID="Adobe.AfterEffects"; Type="Effects"; ReqArch="x64"; ReqOS="Windows 10+"; License="Paid"}
            "009" = @{Name="Camtasia [Paid]"; ID="TechSmith.Camtasia"; Type="Editor"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Paid"}
            "010" = @{Name="Sony Vegas Pro [Paid]"; ID="MAGIX.VEGASPro"; Type="Editor"; ReqArch="x64"; ReqOS="Windows 10+"; License="Paid"}
        }
    }
    
    "17" = @{ 
        Category = "Audio Production"
        Description = " =>> Audio editing and music production"
        Apps = [ordered]@{
            "001" = @{Name="Audacity [Free]"; ID="Audacity.Audacity"; Type="Editor"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "002" = @{Name="FL Studio [Paid]"; ID="ImageLine.FLStudio"; Type="DAW"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Paid"}
            "003" = @{Name="Ableton Live [Paid]"; ID="Ableton.AbletonLive"; Type="DAW"; ReqArch="x64"; ReqOS="Windows 7+"; License="Paid"}
            "004" = @{Name="Reaper [Free/Paid]"; ID="Cockos.REAPER"; Type="DAW"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "005" = @{Name="LMMS [Free]"; ID="LMMS.LMMS"; Type="DAW"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "006" = @{Name="Ardour [Free]"; ID="Ardour.Ardour"; Type="DAW"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "007" = @{Name="Ocenaudio [Free]"; ID="OcenAudio.Ocenaudio"; Type="Editor"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "008" = @{Name="Cubase [Paid]"; ID="Steinberg.Cubase"; Type="DAW"; ReqArch="x64"; ReqOS="Windows 10+"; License="Paid"}
            "009" = @{Name="Pro Tools [Paid]"; ID="Avid.ProTools"; Type="DAW"; ReqArch="x64"; ReqOS="Windows 10+"; License="Paid"}
            "010" = @{Name="Studio One [Paid]"; ID="PreSonus.StudioOne"; Type="DAW"; ReqArch="x64"; ReqOS="Windows 10+"; License="Paid"}
        }
    }
    
    "18" = @{ 
        Category = "Utilities & Tweaks"
        Description = " =>> System utilities and tweaking tools"
        Apps = [ordered]@{
            "001" = @{Name="Process Explorer [Free]"; ID="Microsoft.ProcessExplorer"; Type="Monitor"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "002" = @{Name="Autoruns [Free]"; ID="Microsoft.Autoruns"; Type="Startup"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "003" = @{Name="Process Lasso [Free/Paid]"; ID="Bitsum.ProcessLasso"; Type="Optimizer"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "004" = @{Name="WinDirStat [Free]"; ID="WinDirStat.WinDirStat"; Type="Analyzer"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "005" = @{Name="TreeSize Free [Free]"; ID="JAMSoftware.TreeSizeFree"; Type="Analyzer"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "006" = @{Name="BleachBit [Free]"; ID="BleachBit.BleachBit"; Type="Cleaner"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "007" = @{Name="Wise Disk Cleaner [Free]"; ID="WiseCleaner.WiseDiskCleaner"; Type="Cleaner"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "008" = @{Name="TeraCopy [Free/Paid]"; ID="CodeSector.TeraCopy"; Type="Copier"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "009" = @{Name="Ditto Clipboard [Free]"; ID="Ditto.Ditto"; Type="Clipboard"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "010" = @{Name="Listary [Free/Paid]"; ID="Listary.Listary"; Type="Search"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
        }
    }
    
    "19" = @{ 
        Category = "Business Tools"
        Description = " =>> Business and finance applications"
        Apps = [ordered]@{
            "001" = @{Name="QuickBooks [Paid]"; ID="Intuit.QuickBooks"; Type="Finance"; ReqArch="x64,x86"; ReqOS="Windows 10+"; License="Paid"}
            "002" = @{Name="Sage 50 [Paid]"; ID="Sage.Sage50"; Type="Finance"; ReqArch="x64"; ReqOS="Windows 10+"; License="Paid"}
            "003" = @{Name="Zoho Books [Free/Paid]"; ID="Zoho.ZohoBooks"; Type="Finance"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Freemium"}
            "004" = @{Name="FreshBooks [Paid]"; ID="FreshBooks.FreshBooks"; Type="Finance"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Paid"}
            "005" = @{Name="Xero [Paid]"; ID="Xero.Xero"; Type="Finance"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Paid"}
            "006" = @{Name="Wave [Free]"; ID="Wave.Wave"; Type="Finance"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "007" = @{Name="GnuCash [Free]"; ID="GnuCash.GnuCash"; Type="Finance"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "008" = @{Name="HomeBank [Free]"; ID="HomeBank.HomeBank"; Type="Finance"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "009" = @{Name="Money Manager Ex [Free]"; ID="MoneyManagerEx.MoneyManagerEx"; Type="Finance"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
            "010" = @{Name="KMyMoney [Free]"; ID="KMyMoney.KMyMoney"; Type="Finance"; ReqArch="x64,x86"; ReqOS="Windows 7+"; License="Free"}
        }
    }
    
    "20" = @{ 
        Category = "Custom Search & Install"
        Description = " =>> Search and install any software by name"
        Apps = [ordered]@{
            "001" = @{Name="Search by Software Name"; ID="SEARCH"; Type="Search"; ReqArch="Any"; ReqOS="Any"; License="N/A"}
        }
    }
}

# Build complete software list for search functionality
foreach ($catKey in $Catalog.Keys) {
    foreach ($appKey in $Catalog[$catKey].Apps.Keys) {
        $app = $Catalog[$catKey].Apps[$appKey]
        $app.Category = $Catalog[$catKey].Category
        $global:AllSoftwareList += $app
    }
}

# ---------------------------------------------------------
# 4. ENHANCED FUNCTIONS
# ---------------------------------------------------------

function Show-Header {
    winsetup_txt
    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "`tWinSetup CLI - Professional Installer" -ForegroundColor Cyan
    Write-Host "`tDeveloped by : Mohammod Mizanur Rohman"  -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Cyan
    
    # System Information
    $sysInfo = Get-SystemInfo
    Write-Host " System: $($sysInfo.OSName) | $($sysInfo.Bits) | PowerShell $global:PSVersion" -ForegroundColor White
    Write-Host " Queue: $($InstallQueue.Count) item(s) ready for installation" -ForegroundColor Green
    
    # Admin Status
    if ($global:IsAdmin) {
        Write-Host " Mode: Administrator (Full Access)" -ForegroundColor Green
    } else {
        Write-Host " Mode: Standard User (Limited Access)" -ForegroundColor Yellow
    }
    
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host ""
}

function Test-SystemCompatibility {
    param(
        [hashtable]$AppInfo
    )
    
    $sysInfo = Get-SystemInfo
    $compatibility = @{
        IsCompatible = $true
        Messages = @()
    }
    
    # Check Architecture
    if ($AppInfo.ReqArch -ne "Any") {
        $archList = $AppInfo.ReqArch -split ","
        if ($archList -notcontains $sysInfo.Architecture) {
            $compatibility.IsCompatible = $false
            $compatibility.Messages += "Architecture mismatch: Required $($AppInfo.ReqArch), Found $($sysInfo.Architecture)"
        }
    }
    
    # Check OS Version (basic check)
    if ($AppInfo.ReqOS -ne "Any") {
        if ($AppInfo.ReqOS -like "*Windows 10+*" -and $sysInfo.BuildNumber -lt 10240) {
            $compatibility.IsCompatible = $false
            $compatibility.Messages += "OS version too old: $($AppInfo.ReqOS) required"
        }
        elseif ($AppInfo.ReqOS -like "*Windows 8+*" -and $sysInfo.BuildNumber -lt 9200) {
            $compatibility.IsCompatible = $false
            $compatibility.Messages += "OS version too old: $($AppInfo.ReqOS) required"
        }
    }
    
    # Check Admin rights for certain apps
    if ($AppInfo.Type -in @("Antivirus", "Driver", "SystemTool") -and -not $global:IsAdmin) {
        $compatibility.Messages += "Warning: Admin rights recommended for this software"
    }
    
    return $compatibility
}

function Start-Installation {
    if ($InstallQueue.Count -eq 0) {
        Write-Host " [ERROR] No applications in installation queue!" -ForegroundColor Red
        Write-Host " Press any key to continue..." -ForegroundColor Yellow
        $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
        return
    }

    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Green
    Write-Host "              STARTING INSTALLATION PROCESS                      " -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Green
    Write-Host " IMPORTANT: Do not close this window during installation!" -ForegroundColor Red
    Write-Host "==========================================================================" -ForegroundColor Green
    Write-Host ""
    
    $totalApps = $InstallQueue.Count
    $successCount = 0
    $failedCount = 0
    $currentApp = 1
    
    foreach ($app in $InstallQueue) {
        # Check compatibility before installation
        $compatibility = Test-SystemCompatibility -AppInfo $app
        $licenseInfo = if ($app.License -eq "Free") { "[FREE]" } 
                      elseif ($app.License -eq "Paid") { "[PAID]" } 
                      else { "[$($app.License)]" }
        
        Write-Host " [$currentApp/$totalApps] Installing: $($app.Name) $licenseInfo" -ForegroundColor Cyan
        
        if (-not $compatibility.IsCompatible) {
            Write-Host "   WARNING: Compatibility issues detected!" -ForegroundColor Yellow
            foreach ($msg in $compatibility.Messages) {
                Write-Host "   - $msg" -ForegroundColor Yellow
            }
            Write-Host "   Attempting installation anyway..." -ForegroundColor Yellow
        }
        
        # Winget installation with error handling for all PowerShell versions
        try {
            if ($global:PSVersion -ge 5) {
                # For PowerShell 5.0 and above
                $process = Start-Process -FilePath "winget" `
                    -ArgumentList "install --id $($app.ID) -e --silent --accept-source-agreements --accept-package-agreements" `
                    -NoNewWindow -Wait -PassThru -ErrorAction Stop
                
                if ($process.ExitCode -eq 0) {
                    Write-Host "   [SUCCESS] Installation completed" -ForegroundColor Green
                    $successCount++
                } else {
                    Write-Host "   [FAILED] Exit code: $($process.ExitCode)" -ForegroundColor Red
                    $failedCount++
                }
            } else {
                # For PowerShell 3.0 and 4.0 (fallback method)
                Write-Host "   Installing... (Using compatibility mode)" -ForegroundColor Yellow
                $cmd = "winget install --id $($app.ID) -e --silent --accept-source-agreements --accept-package-agreements"
                $output = cmd /c $cmd 2>&1
                
                if ($LASTEXITCODE -eq 0) {
                    Write-Host "   [SUCCESS] Installation completed" -ForegroundColor Green
                    $successCount++
                } else {
                    Write-Host "   [FAILED] Error occurred" -ForegroundColor Red
                    $failedCount++
                }
            }
        } catch {
            Write-Host "   [ERROR] $($_.Exception.Message)" -ForegroundColor Red
            $failedCount++
        }
        
        Write-Host ""
        $currentApp++
        
        # Small delay between installations
        Start-Sleep -Seconds 1
    }
    
    Write-Host "==========================================================================" -ForegroundColor Green
    Write-Host " INSTALLATION SUMMARY:" -ForegroundColor White
    Write-Host " Total: $totalApps | Success: $successCount | Failed: $failedCount" -ForegroundColor White
    Write-Host "==========================================================================" -ForegroundColor Green
    
    # Clear queue after installation
    $global:InstallQueue = @()
    
    Write-Host ""
    Write-Host " Press any key to return to main menu..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}

function Show-SubMenu {
    param(
        [string]$CatID
    )
    
    while ($true) {
        Show-Header
        $category = $Catalog[$CatID]
        
        Write-Host " CATEGORY: $($category.Category)" -ForegroundColor Yellow
        Write-Host " Description: $($category.Description)" -ForegroundColor White
        Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host ""
        Write-Host " Select software to add to installation queue:" -ForegroundColor White
        Write-Host " (Select number to toggle, same number again to remove)" -ForegroundColor Gray
        Write-Host ""
        
        # Display software list with numbers
        foreach ($key in $category.Apps.Keys) {
            $app = $category.Apps[$key]
            
            # Check if already in queue
            $inQueue = $false
            foreach ($q in $InstallQueue) {
                if ($q.ID -eq $app.ID) {
                    $inQueue = $true
                    break
                }
            }
            
            # Determine color based on license type
            $licenseColor = if ($app.License -eq "Free") { "Green" }
                           elseif ($app.License -eq "Paid") { "Red" }
                           else { "Yellow" }
            
            # Display software with appropriate status
            if ($inQueue) {
                Write-Host " [$key] " -NoNewline -ForegroundColor Green
                Write-Host "[QUEUED] " -NoNewline -ForegroundColor Green
            } else {
                Write-Host " [$key] " -NoNewline -ForegroundColor White
                Write-Host "[      ] " -NoNewline -ForegroundColor DarkGray
            }
            
            # Show software name with license info
            Write-Host "$($app.Name) " -NoNewline -ForegroundColor White
            
            # Show license type
            Write-Host "($($app.License)) " -NoNewline -ForegroundColor $licenseColor
            
            # Show requirements
            Write-Host "[Req: $($app.ReqArch)/$($app.ReqOS)]" -ForegroundColor Gray
        }
        
        Write-Host ""
        Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
        Write-Host " [0]  Return to Main Menu" -ForegroundColor Yellow
        Write-Host " [99] Start Installation Now ($($InstallQueue.Count) items in queue)" -ForegroundColor Green
        Write-Host " [C]  Clear Installation Queue" -ForegroundColor Red
        
        if ($CatID -eq "20") {
            Write-Host " [S]  Search Software by Name" -ForegroundColor Cyan
        }
        
        $choice = Read-Host "`n Enter your choice"
        
        # Handle special commands
        if ($choice -eq "0") { break }
        
        if ($choice -eq "99") { 
            Start-Installation
            continue
        }
        
        if ($choice -eq "C" -or $choice -eq "c") {
            $global:InstallQueue = @()
            Write-Host " Installation queue cleared!" -ForegroundColor Yellow
            Start-Sleep -Seconds 1
            continue
        }
        
        if ($CatID -eq "20" -and ($choice -eq "S" -or $choice -eq "s")) {
            Start-CustomSearch
            continue
        }
        
        # Handle software selection
        if ($category.Apps.Contains($choice)) {
            $selectedApp = $category.Apps[$choice]
            
            # Check if already in queue
            $exists = $false
            $index = -1
            
            for ($i = 0; $i -lt $InstallQueue.Count; $i++) {
                if ($InstallQueue[$i].ID -eq $selectedApp.ID) {
                    $exists = $true
                    $index = $i
                    break
                }
            }
            
            if ($exists) {
                # Remove from queue
                $removedApp = $InstallQueue[$index]
                $global:InstallQueue = @($InstallQueue[0..($index-1)] + $InstallQueue[($index+1)..($InstallQueue.Count-1)])
                Write-Host " Removed from queue: $($removedApp.Name)" -ForegroundColor Yellow
            } else {
                # Add to queue
                $global:InstallQueue += $selectedApp
                Write-Host " Added to queue: $($selectedApp.Name)" -ForegroundColor Green
                
                # Check compatibility
                $compatibility = Test-SystemCompatibility -AppInfo $selectedApp
                if (-not $compatibility.IsCompatible) {
                    Write-Host " Warning: Potential compatibility issues!" -ForegroundColor Yellow
                    foreach ($msg in $compatibility.Messages) {
                        Write-Host "   - $msg" -ForegroundColor Yellow
                    }
                }
            }
            
            Start-Sleep -Seconds 1
        } else {
            Write-Host " Invalid selection! Please try again." -ForegroundColor Red
            Start-Sleep -Seconds 1
        }
    }
}

function Start-CustomSearch {
    Clear-Host
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host "              CUSTOM SOFTWARE SEARCH                             " -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " You can search for any software by name." -ForegroundColor White
    Write-Host " The system will search winget repository and install it." -ForegroundColor White
    Write-Host ""
    Write-Host " Type 'back' to return to previous menu." -ForegroundColor Gray
    Write-Host ""
    
    while ($true) {
        $searchTerm = Read-Host " Enter software name to search"
        
        if ($searchTerm -eq "back" -or $searchTerm -eq "0") {
            break
        }
        
        if ([string]::IsNullOrWhiteSpace($searchTerm)) {
            Write-Host " Please enter a valid search term." -ForegroundColor Red
            continue
        }
        
        Write-Host ""
        Write-Host " Searching for: '$searchTerm'..." -ForegroundColor Cyan
        Write-Host ""
        
        # Search in local database first
        $localResults = @()
        foreach ($software in $global:AllSoftwareList) {
            if ($software.Name -like "*$searchTerm*" -or $software.ID -like "*$searchTerm*") {
                $localResults += $software
            }
        }
        
        if ($localResults.Count -gt 0) {
            Write-Host " Found in local database:" -ForegroundColor Green
            Write-Host "--------------------------------------------------------------------------"
            for ($i = 0; $i -lt $localResults.Count; $i++) {
                $app = $localResults[$i]
                $licenseColor = if ($app.License -eq "Free") { "Green" } else { "Yellow" }
                Write-Host " [$($i+1)] $($app.Name)" -ForegroundColor White
                Write-Host "     Category: $($app.Category) | ID: $($app.ID)" -ForegroundColor Gray
                Write-Host "     License: $($app.License) | Requirements: $($app.ReqArch)/$($app.ReqOS)" -ForegroundColor $licenseColor
                Write-Host ""
            }
            
            $localChoice = Read-Host " Enter number to add to queue (or 'search' for winget search)"
            
            if ($localChoice -ne "search") {
                $index = [int]$localChoice - 1
                if ($index -ge 0 -and $index -lt $localResults.Count) {
                    $selectedApp = $localResults[$index]
                    
                    # Check if already in queue
                    $exists = $false
                    foreach ($q in $InstallQueue) {
                        if ($q.ID -eq $selectedApp.ID) {
                            $exists = $true
                            break
                        }
                    }
                    
                    if (-not $exists) {
                        $global:InstallQueue += $selectedApp
                        Write-Host " Added to queue: $($selectedApp.Name)" -ForegroundColor Green
                    } else {
                        Write-Host " Already in queue!" -ForegroundColor Yellow
                    }
                    
                    Write-Host ""
                    $continue = Read-Host " Search again? (Y/N)"
                    if ($continue -ne "Y" -and $continue -ne "y") {
                        break
                    }
                    continue
                }
            }
        }
        
        # Search using winget
        Write-Host " Searching winget repository..." -ForegroundColor Cyan
        Write-Host ""
        
        try {
            if ($global:PSVersion -ge 5) {
                $searchResult = winget search $searchTerm --accept-source-agreements 2>&1
                Write-Host $searchResult -ForegroundColor Gray
            } else {
                # Compatibility mode for older PowerShell
                $searchResult = cmd /c "winget search $searchTerm --accept-source-agreements" 2>&1
                Write-Host $searchResult -ForegroundColor Gray
            }
            
            Write-Host ""
            Write-Host "--------------------------------------------------------------------------"
            Write-Host ""
            
            if ($searchResult -like "*No package found*" -or $searchResult -like "*error*") {
                Write-Host " No results found for '$searchTerm'." -ForegroundColor Red
                Write-Host " Try a different search term or check spelling." -ForegroundColor Yellow
                Write-Host ""
                continue
            }
            
            $packageId = Read-Host " Enter the exact Package ID to install (from above list)"
            
            if (-not [string]::IsNullOrWhiteSpace($packageId)) {
                Write-Host ""
                Write-Host " Adding to installation queue: $packageId" -ForegroundColor Cyan
                
                # Create a custom app entry
                $customApp = @{
                    Name = "$searchTerm [Custom]"
                    ID = $packageId
                    Type = "Custom"
                    ReqArch = "Any"
                    ReqOS = "Any"
                    License = "Unknown"
                    Category = "Custom Search"
                }
                
                $global:InstallQueue += $customApp
                Write-Host " Custom software added to queue." -ForegroundColor Green
                Write-Host " It will be installed with default winget settings." -ForegroundColor Yellow
            }
            
        } catch {
            Write-Host " Error searching winget: $($_.Exception.Message)" -ForegroundColor Red
            Write-Host " Make sure winget is installed and working." -ForegroundColor Yellow
        }
        
        Write-Host ""
        $continue = Read-Host " Search for another software? (Y/N)"
        if ($continue -ne "Y" -and $continue -ne "y") {
            break
        }
        
        Clear-Host
        Write-Host "==========================================================================" -ForegroundColor Cyan
        Write-Host "              CUSTOM SOFTWARE SEARCH                             " -ForegroundColor Yellow
        Write-Host "==========================================================================" -ForegroundColor Cyan
        Write-Host ""
    }
}

function Show-QuickStats {
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host " SOFTWARE DATABASE STATISTICS" -ForegroundColor Yellow
    Write-Host "==========================================================================" -ForegroundColor Cyan
    
    $totalCategories = $Catalog.Count
    $totalSoftware = 0
    $freeSoftware = 0
    $paidSoftware = 0
    $freemiumSoftware = 0
    
    foreach ($catKey in $Catalog.Keys) {
        $category = $Catalog[$catKey]
        $totalSoftware += $category.Apps.Count
        
        foreach ($appKey in $category.Apps.Keys) {
            $app = $category.Apps[$appKey]
            switch ($app.License) {
                "Free" { $freeSoftware++ }
                "Paid" { $paidSoftware++ }
                "Freemium" { $freemiumSoftware++ }
                "Trial" { $paidSoftware++ }
            }
        }
    }
    
    Write-Host " Total Categories: $totalCategories" -ForegroundColor White
    Write-Host " Total Software: $totalSoftware" -ForegroundColor White
    Write-Host " Free Software: $freeSoftware" -ForegroundColor Green
    Write-Host " Paid Software: $paidSoftware" -ForegroundColor Red
    Write-Host " Freemium Software: $freemiumSoftware" -ForegroundColor Yellow
    Write-Host ""
    Write-Host " Current Queue: $($InstallQueue.Count) item(s)" -ForegroundColor Cyan
    Write-Host "==========================================================================" -ForegroundColor Cyan
    Write-Host ""
    Write-Host " Press any key to continue..." -ForegroundColor Yellow
    $null = $Host.UI.RawUI.ReadKey("NoEcho,IncludeKeyDown")
}
function winsetup_txt{
    [Console]::OutputEncoding = [System.Text.Encoding]::UTF8
    $Esc = [char]27

    # ASCII Art ডিজাইন
    $Banner = @"
$($Esc)[1;36m
    __      __.__         _________         __                
   /  \    /  \__| ____  /   _____/  ____ _/  |_ __ ________  
   \   \/\/   /  |/    \ \_____  \ _/ __ \\   __\  |  \____ \ 
    \        /|  |   |  \/        \\  ___/ |  | |  |  /  |_> >
     \__/\  / |__|___|  /_______  / \___  >|__| |____/|   __/ 
          \/          \/        \/      \/            |__|    
    $($Esc)[0m
"@

    
    # Clear-Host
    Write-Host $Banner
    Write-Host "$($Esc)[1;33m[+] WinSetup Free and Open Source Tools$($Esc)[0m"
    Write-Host "----------------------------------------------------------------"
    Start-Sleep -Seconds 1
    
}
# ---------------------------------------------------------
# 5. MAIN PROGRAM LOOP
# ---------------------------------------------------------
while ($true) {
    Show-Header
    Write-Host " MAIN MENU - SELECT A CATEGORY:" -ForegroundColor Yellow
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host ""
    
    # Display categories in a clean, numbered list
    foreach ($catKey in $Catalog.Keys) {
        $category = $Catalog[$catKey]
        $categoryNumber = [int]$catKey
        
        Write-Host " [$catKey] " -NoNewline -ForegroundColor White
        
        # Highlight custom search category
        if ($catKey -eq "20") {
            Write-Host "$($category.Category)" -ForegroundColor Cyan
        } else {
            Write-Host "$($category.Category)" -ForegroundColor White
        }
        
        Write-Host "     $($category.Description)" -ForegroundColor Gray
        Write-Host ""
    }
    
    Write-Host "--------------------------------------------------------------------------" -ForegroundColor DarkGray
    Write-Host " [99] START INSTALLATION ($($InstallQueue.Count) items in queue)" -ForegroundColor Green
    Write-Host " [S]  Show Database Statistics" -ForegroundColor Cyan
    Write-Host " [C]  Clear Installation Queue" -ForegroundColor Red
    Write-Host " [Q]  Quit Program" -ForegroundColor DarkGray
    
    $mainChoice = Read-Host "`n Enter your choice"
    
    # Process main menu choices
    switch ($mainChoice) {
        "Q" { 
            Write-Host " Exiting WinSetup CLI. Goodbye!" -ForegroundColor Cyan
            Start-Sleep -Seconds 1
            winsetup_txt
            exit 
        }
        
        "q" { 
            Write-Host " Exiting WinSetup CLI. Goodbye!" -ForegroundColor Cyan
            Start-Sleep -Seconds 1
            winsetup_txt
            exit 
        }
        
        "99" { 
            Start-Installation 
        }
        
        "S" { 
            Show-QuickStats 
        }
        
        "s" { 
            Show-QuickStats 
        }
        
        "C" { 
            $global:InstallQueue = @()
            Write-Host " Installation queue cleared!" -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
        
        "c" { 
            $global:InstallQueue = @()
            Write-Host " Installation queue cleared!" -ForegroundColor Yellow
            Start-Sleep -Seconds 1
        }
        
        default {
            if ($Catalog.Contains($mainChoice)) {
                Show-SubMenu -CatID $mainChoice
            } else {
                Write-Host " Invalid selection! Please try again." -ForegroundColor Red
                Start-Sleep -Seconds 1
            }
        }
    }
}