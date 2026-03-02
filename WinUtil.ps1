#Requires -RunAsAdministrator

# ─── SMART ELEVATION (Final Universal Fix) ──────────────────────────────────
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Elevating Ray's Chamber to Admin..." -ForegroundColor Cyan
    
    if ($PSCommandPath) {
        # Running from a local file
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    } else {
        # Running via 'irm | iex' (downloaded from GitHub)
        $url = "https://raw.githubusercontent.com/raysutil/main/WinUtil.ps1"
        $scriptContent = (Invoke-RestMethod -Uri $url -ErrorAction SilentlyContinue)
        
        if ($null -eq $scriptContent) {
            $scriptContent = $MyInvocation.MyCommand.ScriptBlock.ToString()
        }
        
        # Use Base64 to prevent special character/bracket corruption during elevation
        $bytes = [System.Text.Encoding]::Unicode.GetBytes($scriptContent)
        $encoded = [Convert]::ToBase64String($bytes)
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -EncodedCommand $encoded" -Verb RunAs
    }
    exit
}
# ─── ASSEMBLIES ─────────────────────────────────────────────────────────────────
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# ─── DWM HELPER (Mica / Dark Title Bar) ─────────────────────────────────────────
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DwmHelper {
    [DllImport("dwmapi.dll", PreserveSig = true)]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int value, int size);
    public static void EnableDarkTitle(IntPtr h) {
        int v = 1; DwmSetWindowAttribute(h, 20, ref v, 4);
    }
    public static void EnableMica(IntPtr h) {
        int v = 2; DwmSetWindowAttribute(h, 38, ref v, 4);
    }
}
"@ -ErrorAction SilentlyContinue

# ─── MEMORY HELPER ──────────────────────────────────────────────────────────────
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class MemHelper {
    [DllImport("kernel32.dll")]
    public static extern bool SetProcessWorkingSetSize(IntPtr proc, int min, int max);
    [DllImport("psapi.dll")]
    public static extern int EmptyWorkingSet(IntPtr proc);
}
"@ -ErrorAction SilentlyContinue

# ─── HARDWARE DETECTION (The "Brain") ───────────────────────────────────────────
$cpuInfo    = Get-CimInstance Win32_Processor
$cpuName    = $cpuInfo.Name.Trim()
$cpuCores   = $cpuInfo.NumberOfCores
$cpuThreads = $cpuInfo.NumberOfLogicalProcessors
$ramSticks  = Get-CimInstance Win32_PhysicalMemory
$ramGB      = [math]::Round(($ramSticks | Measure-Object Capacity -Sum).Sum / 1GB)
$ramSpeed   = ($ramSticks | Select-Object -First 1).Speed
$ramMax     = try { [math]::Round((Get-CimInstance Win32_PhysicalMemoryArray).MaxCapacity / 1MB) } catch { 0 }
$gpuInfo    = Get-CimInstance Win32_VideoController | Where-Object { $_.Status -eq 'OK' } | Select-Object -First 1
$gpuName    = if ($gpuInfo) { $gpuInfo.Name.Trim() } else { "Unknown GPU" }
$isLaptop   = if (Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue) { $true } else { $false }
$HardwareType = if ($isLaptop) { "LAPTOP" } else { "DESKTOP" }
$isIGPU     = $gpuName -match "Intel|UHD|Iris|Vega|Radeon Graphics"
$osVersion  = (Get-CimInstance Win32_OperatingSystem).Caption
$monitorHz  = try { (Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction SilentlyContinue | Select-Object -First 1).ActiveEncoding } catch { 60 }
if ($monitorHz -lt 30 -or $monitorHz -gt 500) { $monitorHz = 60 }

# WinSAT Score
$winsat = try { Get-CimInstance Win32_WinSAT -ErrorAction SilentlyContinue } catch { $null }
$cpuScore   = if ($winsat) { $winsat.CPUScore } else { 0 }
$memScore   = if ($winsat) { $winsat.MemoryScore } else { 0 }
$diskScore  = if ($winsat) { $winsat.DiskScore } else { 0 }
$gpuScore   = if ($winsat) { $winsat.GraphicsScore } else { 0 }
$totalScore = if ($winsat) { [math]::Round(($cpuScore + $memScore + $diskScore + $gpuScore) / 4, 1) } else { 0 }

# Tier Detection
$SuggestedTier = "Mid-Range"
if ($ramGB -le 8 -or $cpuName -match "Celeron|Pentium|Athlon|i3-[2-7]|A[4-9]-") { $SuggestedTier = "Low-End" }
if ($ramGB -ge 32 -and $cpuCores -ge 8 -and -not $isLaptop) { $SuggestedTier = "High-End" }
if ($ramGB -ge 64 -and $cpuCores -ge 12) { $SuggestedTier = "High-End" }

$StatusColor = if ($isLaptop) { "Yellow" } else { "Cyan" }
$StatusHex   = if ($isLaptop) { "#FFD700" } else { "#00D9FF" }

# ─── CYBER-ASCII STARTUP ────────────────────────────────────────────────────────
Clear-Host
$Header = @"

  ██████╗  █████╗ ██╗   ██╗███████╗
  ██╔══██╗██╔══██╗╚██╗ ██╔╝██╔════╝
  ██████╔╝███████║ ╚████╔╝ ███████╗
  ██╔══██╗██╔══██║  ╚██╔╝  ╚════██║
  ██║  ██║██║  ██║   ██║   ███████║
  ╚═╝  ╚═╝╚═╝  ╚═╝   ╚═╝   ╚══════╝
    O P T I M I Z A T I O N   C H A M B E R   v5.0
  ──────────────────────────────────────────────────
  DEVICE: $HardwareType | CPU: $cpuName
  RAM: ${ramGB}GB @ ${ramSpeed}MHz | GPU: $gpuName
  CORES: $cpuCores C / $cpuThreads T | SCORE: $totalScore/10
  SUGGESTED TIER: $SuggestedTier
  ──────────────────────────────────────────────────

"@
Write-Host $Header -ForegroundColor $StatusColor

# ─── COLOUR PALETTE ─────────────────────────────────────────────────────────────
$C = @{
    BG       = '#000B1A';  Surface  = '#001F3F';  Surface2 = '#003366'
    Accent   = $StatusHex; NavBG    = '#000814';   Text     = '#F0F0F0'
    TextDim  = '#8090A0';  Green    = '#00FFCC';   Gold     = '#FFD700'
    Red      = '#FF4D6A';  Border   = '#002A4A';   LogBG    = '#00050A'
}

# ─── APP CATALOGUE ──────────────────────────────────────────────────────────────
$AppCatalogue = @(
    @{N='Google Chrome';       Id='Google.Chrome';                Cat='Browser'}
    @{N='Mozilla Firefox';     Id='Mozilla.Firefox';              Cat='Browser'}
    @{N='Brave Browser';       Id='Brave.Brave';                  Cat='Browser'}
    @{N='Microsoft Edge';      Id='Microsoft.Edge';               Cat='Browser'}
    @{N='Opera GX';            Id='Opera.OperaGX';                Cat='Browser'}
    @{N='Discord';             Id='Discord.Discord';              Cat='Communication'}
    @{N='Telegram';            Id='Telegram.TelegramDesktop';     Cat='Communication'}
    @{N='Zoom';                Id='Zoom.Zoom';                    Cat='Communication'}
    @{N='Microsoft Teams';     Id='Microsoft.Teams';              Cat='Communication'}
    @{N='Slack';               Id='SlackTechnologies.Slack';      Cat='Communication'}
    @{N='Steam';               Id='Valve.Steam';                  Cat='Gaming'}
    @{N='Epic Games Launcher'; Id='EpicGames.EpicGamesLauncher';  Cat='Gaming'}
    @{N='GOG Galaxy';          Id='GOG.Galaxy';                   Cat='Gaming'}
    @{N='EA App';              Id='ElectronicArts.EADesktop';     Cat='Gaming'}
    @{N='Prism Launcher';      Id='PrismLauncher.PrismLauncher';  Cat='Gaming'}
    @{N='VLC Media Player';    Id='VideoLAN.VLC';                 Cat='Media'}
    @{N='Spotify';             Id='Spotify.Spotify';              Cat='Media'}
    @{N='OBS Studio';          Id='OBSProject.OBSStudio';         Cat='Media'}
    @{N='Audacity';            Id='Audacity.Audacity';            Cat='Media'}
    @{N='HandBrake';           Id='HandBrake.HandBrake';          Cat='Media'}
    @{N='7-Zip';               Id='7zip.7zip';                    Cat='Utility'}
    @{N='Notepad++';           Id='Notepad++.Notepad++';          Cat='Utility'}
    @{N='Everything Search';   Id='voidtools.Everything';         Cat='Utility'}
    @{N='WinRAR';              Id='RARLab.WinRAR';                Cat='Utility'}
    @{N='PowerToys';           Id='Microsoft.PowerToys';          Cat='Utility'}
    @{N='TreeSize Free';       Id='JAMSoftware.TreeSize.Free';    Cat='Utility'}
    @{N='VS Code';             Id='Microsoft.VisualStudioCode';   Cat='Development'}
    @{N='Git';                 Id='Git.Git';                      Cat='Development'}
    @{N='Python 3';            Id='Python.Python.3.12';           Cat='Development'}
    @{N='Node.js LTS';         Id='OpenJS.NodeJS.LTS';            Cat='Development'}
    @{N='Windows Terminal';    Id='Microsoft.WindowsTerminal';    Cat='Development'}
    @{N='Docker Desktop';      Id='Docker.DockerDesktop';         Cat='Development'}
    @{N='NVIDIA App';          Id='Nvidia.GeForceExperience';     Cat='Drivers'}
    @{N='AMD Software';        Id='AMD.RyzenMaster';              Cat='Drivers'}
    @{N='Intel DSA';           Id='Intel.IntelDriverAndSupportAssistant'; Cat='Drivers'}
    @{N='Razer Synapse';       Id='RazerInc.RazerInstaller';      Cat='Drivers'}
    @{N='MSI Afterburner';     Id='Guru3D.Afterburner';           Cat='Drivers'}
    @{N='HWiNFO';              Id='REALiX.HWiNFO';               Cat='Drivers'}
    @{N='Bitwarden';           Id='Bitwarden.Bitwarden';          Cat='Security'}
    @{N='Malwarebytes';        Id='Malwarebytes.Malwarebytes';    Cat='Security'}
)

$Categories = $AppCatalogue | ForEach-Object { $_.Cat } | Sort-Object -Unique

# ─── GLOBAL STATE ────────────────────────────────────────────────────────────────
$Script:RestoreCreated = $false
$Script:AutoBoosterRunning = $false
$Script:AutoBoosterJob = $null

# ─── HELPER FUNCTIONS ────────────────────────────────────────────────────────────

function Write-Log {
    param([string]$Msg, [string]$Type = "Info")
    $ts = Get-Date -Format "HH:mm:ss"
    $prefix = switch ($Type) {
        "OK"     { "[  OK  ]" }
        "Error"  { "[ FAIL ]" }
        "Action" { "[ >>>> ]" }
        "Warn"   { "[ WARN ]" }
        default  { "[ INFO ]" }
    }
    $color = switch ($Type) {
        "OK"     { $C.Green }
        "Error"  { $C.Red }
        "Action" { $C.Accent }
        "Warn"   { $C.Gold }
        default  { $C.TextDim }
    }
    $entry = "$ts $prefix $Msg"
    $run = [System.Windows.Documents.Run]::new($entry + "`n")
    $run.Foreground = $color
    $Ctrl['LogBox'].Inlines.Add($run)
    $Ctrl['LogScroll'].ScrollToEnd()
    [System.Windows.Threading.Dispatcher]::CurrentDispatcher.Invoke([Action]{}, [System.Windows.Threading.DispatcherPriority]::Background)
}

function Ensure-Path {
    param([string]$Path)
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
}

function Show-Warning {
    param([string]$TweakName, [string]$Risk)
    $msg = "WARNING: You are about to apply [$TweakName].`n`nRisk: $Risk`n`nDo you want to continue?"
    $result = [System.Windows.MessageBox]::Show($msg, "Ray's Chamber — Safety Check", "YesNo", "Warning")
    return ($result -eq "Yes")
}

function Play-SuccessTone {
    [console]::Beep(440,150); [console]::Beep(554,150); [console]::Beep(659,150); [console]::Beep(880,300)
}

function Restart-Shell {
    Write-Log "Restarting Explorer to apply changes..." Action
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Milliseconds 500
    Start-Process explorer.exe
    Write-Log "Explorer restarted." OK
}

# ─── TIERED OPTIMIZATION ENGINE ─────────────────────────────────────────────────

function Apply-LowEndTweaks {
    Write-Log "═══ LOW-END TIER: RAM Recovery + Visual Performance ═══" Action

    # Disable Animations & Transparency
    Write-Log "  Disabling animations and transparency..." Info
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'UserPreferencesMask' -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Value '0' -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 2 -ErrorAction SilentlyContinue

    # Disable Memory Compression (if 8GB+)
    if ($ramGB -ge 8) {
        Write-Log "  Disabling Memory Compression (${ramGB}GB RAM detected)..." Info
        Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
    }

    # Kill Heavy Background Services (Ghost Service Killer)
    Write-Log "  Nullifying heavy background services..." Info
    $services = @("SysMain","DiagTrack","WbioSrvc","MapsBroker","WMPNetworkSvc","RemoteRegistry")
    foreach ($svc in $services) {
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
        reg add "HKLM\SYSTEM\CurrentControlSet\Services\$svc" /v "Start" /t REG_DWORD /d 4 /f 2>$null | Out-Null
    }

    # Disable Game DVR
    Write-Log "  Disabling Game DVR and Game Bar..." Info
    Ensure-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -ErrorAction SilentlyContinue
    Ensure-Path "HKCU:\System\GameConfigStore"
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -ErrorAction SilentlyContinue

    # High Performance Power Plan
    Write-Log "  Activating High Performance power plan..." Info
    powercfg -setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null

    Write-Log "Low-End optimizations applied!" OK
    Play-SuccessTone
}

function Apply-MidRangeTweaks {
    Write-Log "═══ MID-RANGE TIER: OS Snappiness + Telemetry Block ═══" Action

    # Apply Low-End first
    Apply-LowEndTweaks

    # Telemetry Block
    Write-Log "  Blocking telemetry and data collection..." Info
    Ensure-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0 -ErrorAction SilentlyContinue
    Ensure-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -Value 1 -ErrorAction SilentlyContinue
    Set-Service -Name "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue

    # System Responsiveness
    Write-Log "  Setting SystemResponsiveness to 10..." Info
    Ensure-Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 10 -ErrorAction SilentlyContinue

    # Network Throttling
    Write-Log "  Disabling network throttling..." Info
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -ErrorAction SilentlyContinue

    # Priority Separation
    Write-Log "  Setting Win32PrioritySeparation to 0x26..." Info
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 0x26 -ErrorAction SilentlyContinue

    # Disable Fullscreen Optimizations globally
    Write-Log "  Disabling Fullscreen Optimizations..." Info
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2 -ErrorAction SilentlyContinue

    Write-Log "Mid-Range optimizations applied!" OK
    Play-SuccessTone
}

function Apply-HighEndTweaks {
    Write-Log "═══ HIGH-END (NUCLEAR) TIER: Maximum Performance ═══" Action

    if ($isLaptop) {
        $proceed = Show-Warning "High-End Nuclear Tweaks" "These tweaks will increase heat and power usage. PLUG IN YOUR CHARGER."
        if (-not $proceed) { Write-Log "Cancelled by user." Warn; return }
    }

    # Apply Mid-Range first (includes Low-End)
    Apply-MidRangeTweaks

    # BCD Extreme Latency
    Write-Log "  Applying BCD extreme latency tweaks..." Info
    bcdedit /set useplatformtick yes 2>$null
    bcdedit /set disabledynamictick yes 2>$null
    bcdedit /set useplatformclock yes 2>$null

    # Ultimate Performance Power Plan
    Write-Log "  Unlocking Ultimate Performance power plan..." Info
    $planOutput = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
    if ($planOutput -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') {
        powercfg -setactive $Matches[1]
        Write-Log "  Ultimate Performance plan activated: $($Matches[1])" OK
    }

    # Unpark All CPU Cores
    Write-Log "  Unparking all CPU cores..." Info
    $corePath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
    Ensure-Path $corePath
    Set-ItemProperty -Path $corePath -Name "Attributes" -Value 0 -ErrorAction SilentlyContinue
    powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 2>$null
    powercfg -setactive scheme_current 2>$null

    # GPU Priority & MSI Mode
    Write-Log "  Setting GPU priority and MSI mode..." Info
    $gpuTaskPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    Ensure-Path $gpuTaskPath
    Set-ItemProperty -Path $gpuTaskPath -Name "GPU Priority" -Value 8 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gpuTaskPath -Name "Priority" -Value 6 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gpuTaskPath -Name "Scheduling Category" -Value "High" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gpuTaskPath -Name "SFIO Priority" -Value "High" -ErrorAction SilentlyContinue

    # GPU MSI Mode
    try {
        $gpuDevice = Get-PnpDevice -Class Display -Status OK -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($gpuDevice) {
            $msiPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($gpuDevice.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
            Ensure-Path $msiPath
            Set-ItemProperty -Path $msiPath -Name "MSISupported" -Value 1 -ErrorAction SilentlyContinue
            Write-Log "  GPU MSI Mode enabled for $($gpuDevice.FriendlyName)" OK
        }
    } catch { Write-Log "  Could not enable GPU MSI Mode: $_" Warn }

    # Silicon Lottery GPU Optimizer
    Write-Log "  Applying Silicon Lottery GPU tweaks..." Info
    $gpuRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
    if (Test-Path $gpuRegPath) {
        Set-ItemProperty -Path $gpuRegPath -Name "PowerMizerEnable" -Value 0 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $gpuRegPath -Name "PerfLevelSrc" -Value 0x2222 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $gpuRegPath -Name "PowerMizerLevel" -Value 0x1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $gpuRegPath -Name "PowerMizerLevelAC" -Value 0x1 -ErrorAction SilentlyContinue
    }

    # Disable Spectre/Meltdown Mitigations
    Write-Log "  ⚠ Disabling CPU security mitigations for +15% performance..." Warn
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /t REG_DWORD /d 3 /f 2>$null | Out-Null
    reg add "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /t REG_DWORD /d 3 /f 2>$null | Out-Null

    # Disable VBS / Memory Integrity
    Write-Log "  Disabling Virtualization Based Security..." Info
    Ensure-Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -Value 0 -ErrorAction SilentlyContinue

    # DWM Priority Lower
    Write-Log "  Lowering DWM priority for game focus..." Info
    $dwmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager"
    Ensure-Path $dwmPath
    Set-ItemProperty -Path $dwmPath -Name "Priority" -Value 3 -ErrorAction SilentlyContinue

    # Disable Nagle's Algorithm (TCP)
    Write-Log "  Disabling Nagle's Algorithm for zero-latency networking..." Info
    $nics = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
    foreach ($nic in $nics) {
        Set-ItemProperty -Path $nic.PSPath -Name "TcpAckFrequency" -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $nic.PSPath -Name "TCPNoDelay" -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $nic.PSPath -Name "TcpDelAckTicks" -Value 0 -ErrorAction SilentlyContinue
    }

    Write-Log "HIGH-END NUCLEAR optimizations applied!" OK
    Play-SuccessTone
}

# ─── LAPTOP GOD MODE ────────────────────────────────────────────────────────────

function Apply-LaptopGodMode {
    if (-not $isLaptop) {
        Write-Log "This device is a desktop. Laptop God Mode not applicable." Warn
        return
    }
    $proceed = Show-Warning "Laptop God Mode" "Disables thermal throttling & efficiency mode. ENSURE CHARGER IS PLUGGED IN. May increase temperatures."
    if (-not $proceed) { Write-Log "Cancelled by user." Warn; return }

    Write-Log "═══ LAPTOP GOD MODE: Thermal Bypass + Full Power ═══" Action

    # Disable Power Throttling
    Write-Log "  Disabling Power Throttling globally..." Info
    Ensure-Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PowerThrottlingOff" -Value 1 -ErrorAction SilentlyContinue

    # Disable Efficiency Mode
    Write-Log "  Disabling Efficiency Mode for all apps..." Info
    $effPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
    Ensure-Path $effPath
    Set-ItemProperty -Path $effPath -Name "Attributes" -Value 0 -ErrorAction SilentlyContinue

    # Unlock Processor Boost Mode
    Write-Log "  Unlocking Processor Performance Boost Mode..." Info
    $boostPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7"
    Ensure-Path $boostPath
    Set-ItemProperty -Path $boostPath -Name "Attributes" -Value 0 -ErrorAction SilentlyContinue

    # 99% CPU Cap (prevent turbo overheat crash loop)
    Write-Log "  Setting 99% CPU cap to prevent thermal crash..." Info
    powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 99 2>$null
    powercfg -setactive scheme_current 2>$null

    # Disable DPTF thermal throttling
    Write-Log "  Bypassing DPTF thermal framework gate..." Info
    $dptfServices = @("dptf_helper","DTSApo4Service","IntelDalService")
    foreach ($svc in $dptfServices) {
        Set-Service -Name $svc -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $svc -Force -ErrorAction SilentlyContinue
    }

    Write-Log "Laptop God Mode ACTIVE! Monitor temps carefully." OK
    Play-SuccessTone
}

# ─── GAMING SPECIFIC FUNCTIONS ──────────────────────────────────────────────────

function Apply-GameBooster {
    Write-Log "═══ GAME BOOSTER: Zero Latency Mode ═══" Action

    # Network Throttling OFF
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 10 -ErrorAction SilentlyContinue

    # GPU Priority
    $gpuTaskPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    Ensure-Path $gpuTaskPath
    Set-ItemProperty -Path $gpuTaskPath -Name "GPU Priority" -Value 8 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gpuTaskPath -Name "Priority" -Value 6 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gpuTaskPath -Name "Scheduling Category" -Value "High" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $gpuTaskPath -Name "SFIO Priority" -Value "High" -ErrorAction SilentlyContinue

    # Win32 Priority Separation
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 0x26 -ErrorAction SilentlyContinue

    # Game DVR OFF
    Ensure-Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -ErrorAction SilentlyContinue
    Ensure-Path "HKCU:\System\GameConfigStore"
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2 -ErrorAction SilentlyContinue

    # Mouse Acceleration OFF
    Write-Log "  Disabling mouse acceleration..." Info
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -ErrorAction SilentlyContinue

    # Keyboard Response
    Write-Log "  Optimizing keyboard response..." Info
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "0" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value "31" -ErrorAction SilentlyContinue

    Write-Log "Game Booster activated!" OK
    Play-SuccessTone
}

function Start-AutoBooster {
    if ($Script:AutoBoosterRunning) {
        Write-Log "Auto-Booster is already running." Warn
        return
    }
    Write-Log "🚀 Auto-Booster Active: Watching for games..." Action
    $Script:AutoBoosterRunning = $true

    $Script:AutoBoosterJob = Start-Job -ScriptBlock {
        $GameList = @("cs2","csgo","valorant","VALORANT-Win64-Shipping","FortniteClient-Win64-Shipping",
                      "r5apex","LeagueClient","RiotClientServices","javaw","minecraft",
                      "GTA5","FiveM","RocketLeague","Overwatch","eldenring","cyberpunk2077")
        $Demote = @("chrome","msedge","firefox","discord","Spotify","Teams","Slack","OneDrive")

        while ($true) {
            $procs = Get-Process -ErrorAction SilentlyContinue
            $gameFound = $false
            foreach ($p in $procs) {
                if ($GameList -contains $p.Name) {
                    try { $p.PriorityClass = 'High' } catch {}
                    $gameFound = $true
                }
            }
            if ($gameFound) {
                foreach ($p in $procs) {
                    if ($Demote -contains $p.Name) {
                        try { $p.PriorityClass = 'BelowNormal' } catch {}
                    }
                }
            }
            Start-Sleep -Seconds 15
        }
    }
    Write-Log "Auto-Booster running in background (checks every 15s)." OK
}

function Stop-AutoBooster {
    if ($Script:AutoBoosterJob) {
        Stop-Job -Job $Script:AutoBoosterJob -ErrorAction SilentlyContinue
        Remove-Job -Job $Script:AutoBoosterJob -Force -ErrorAction SilentlyContinue
        $Script:AutoBoosterJob = $null
        $Script:AutoBoosterRunning = $false
        Write-Log "Auto-Booster stopped." OK
    } else {
        Write-Log "Auto-Booster was not running." Info
    }
}

# ─── RAM / MEMORY FUNCTIONS ─────────────────────────────────────────────────────

function Clear-RAMStandby {
    Write-Log "Purging RAM standby list..." Action
    try {
        Get-Process | ForEach-Object {
            try { [MemHelper]::EmptyWorkingSet($_.Handle) } catch {}
        }
        [System.GC]::Collect()
        [System.GC]::WaitForPendingFinalizers()
        Write-Log "RAM standby list purged." OK
    } catch { Write-Log "RAM purge error: $_" Error }
}

function Optimize-RAM {
    Write-Log "═══ RAM OPTIMIZATION ═══" Action

    # LargeSystemCache
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 0 -ErrorAction SilentlyContinue
    Write-Log "  LargeSystemCache set to 0 (app priority)." Info

    # Disable Memory Compression (8GB+)
    if ($ramGB -ge 8) {
        Disable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
        Write-Log "  Memory Compression disabled." Info
    }

    # Disable Prefetch for SSD users
    $sysDrive = Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' } | Select-Object -First 1
    if ($sysDrive) {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 0 -ErrorAction SilentlyContinue
        Write-Log "  Prefetch disabled (SSD detected)." Info
    }

    Clear-RAMStandby
    Write-Log "RAM optimization complete!" OK
    Play-SuccessTone
}

# ─── USB / HARDWARE TWEAKS ──────────────────────────────────────────────────────

function Apply-USBTweaks {
    Write-Log "═══ USB / HARDWARE TWEAKS ═══" Action

    # Disable USB Selective Suspend
    Write-Log "  Disabling USB Selective Suspend..." Info
    powercfg -SETACVALUEINDEX SCHEME_CURRENT 2a033b03-2eef-4ce0-bd58-3e193014470b 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
    powercfg -SETDCVALUEINDEX SCHEME_CURRENT 2a033b03-2eef-4ce0-bd58-3e193014470b 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
    powercfg -setactive SCHEME_CURRENT 2>$null

    # Mouse acceleration OFF
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0" -ErrorAction SilentlyContinue
    Write-Log "  Mouse acceleration disabled (1:1 raw input)." Info

    # Keyboard speed
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "0" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value "31" -ErrorAction SilentlyContinue
    Write-Log "  Keyboard repeat rate maximized." Info

    Write-Log "USB/Hardware tweaks applied!" OK
    Play-SuccessTone
}

# ─── NETWORK / INTERNET ─────────────────────────────────────────────────────────

function Apply-NetworkTweaks {
    Write-Log "═══ NETWORK OPTIMIZATION ═══" Action

    # Disable Nagle's Algorithm
    $nics = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
    foreach ($nic in $nics) {
        Set-ItemProperty -Path $nic.PSPath -Name "TcpAckFrequency" -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $nic.PSPath -Name "TCPNoDelay" -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $nic.PSPath -Name "TcpDelAckTicks" -Value 0 -ErrorAction SilentlyContinue
    }
    Write-Log "  Nagle's Algorithm disabled (instant packet send)." Info

    # Network Throttling OFF
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff -ErrorAction SilentlyContinue
    Write-Log "  Network throttling disabled." Info

    # Optimize TCP
    netsh int tcp set global autotuninglevel=normal 2>$null
    netsh int tcp set global congestionprovider=ctcp 2>$null
    netsh int tcp set global ecncapability=enabled 2>$null
    Write-Log "  TCP stack optimized (CTCP + ECN)." Info

    Write-Log "Network optimization complete!" OK
    Play-SuccessTone
}

function Refresh-Internet {
    Write-Log "═══ INTERNET REFRESHER ═══" Action
    ipconfig /flushdns 2>$null
    netsh winsock reset 2>$null
    netsh int ip reset 2>$null
    ipconfig /release 2>$null
    ipconfig /renew 2>$null
    Write-Log "Internet refreshed (DNS flushed, Winsock reset, IP renewed)." OK
    Play-SuccessTone
}

# ─── SYSTEM CLEANUP ─────────────────────────────────────────────────────────────

function Invoke-SystemCleanup {
    Write-Log "═══ SYSTEM CLEANUP ═══" Action

    # Temp files
    $tempPaths = @($env:TEMP, "$env:windir\Temp", "$env:LOCALAPPDATA\Microsoft\Windows\INetCache")
    foreach ($tp in $tempPaths) {
        if (Test-Path $tp) {
            $count = (Get-ChildItem $tp -Recurse -ErrorAction SilentlyContinue | Measure-Object).Count
            Remove-Item "$tp\*" -Recurse -Force -ErrorAction SilentlyContinue
            Write-Log "  Cleaned $count items from $tp" Info
        }
    }

    # Recycle Bin
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Log "  Recycle Bin emptied." Info

    # Windows Update Cache
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:windir\SoftwareDistribution\Download\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Write-Log "  Windows Update cache cleared." Info

    Write-Log "System cleanup complete!" OK
    Play-SuccessTone
}

# ─── DISK / STORAGE ─────────────────────────────────────────────────────────────

function Optimize-Storage {
    Write-Log "═══ STORAGE OPTIMIZATION ═══" Action

    # SSD TRIM
    $ssd = Get-PhysicalDisk | Where-Object { $_.MediaType -eq 'SSD' } | Select-Object -First 1
    if ($ssd) {
        Write-Log "  Running TRIM on SSD..." Info
        Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue
        Write-Log "  SSD TRIM complete." OK
    }

    # Disable last access timestamp (reduces disk writes)
    fsutil behavior set disablelastaccess 1 2>$null
    Write-Log "  Last access timestamps disabled." Info

    # Disk I/O Priority for Games
    $ioPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    Ensure-Path $ioPath
    Set-ItemProperty -Path $ioPath -Name "Scheduling Category" -Value "High" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path $ioPath -Name "SFIO Priority" -Value "High" -ErrorAction SilentlyContinue
    Write-Log "  Disk I/O priority for games set to High." Info

    Write-Log "Storage optimization complete!" OK
    Play-SuccessTone
}

# ─── DEBLOAT ─────────────────────────────────────────────────────────────────────

function Invoke-Debloat {
    Write-Log "═══ WINDOWS DEBLOAT ═══" Action
    $bloatApps = @(
        "Microsoft.BingNews","Microsoft.BingWeather","Microsoft.GetHelp","Microsoft.Getstarted",
        "Microsoft.MicrosoftOfficeHub","Microsoft.MicrosoftSolitaireCollection","Microsoft.People",
        "Microsoft.WindowsFeedbackHub","Microsoft.WindowsMaps","Microsoft.ZuneMusic",
        "Microsoft.ZuneVideo","Microsoft.SkypeApp","Microsoft.MixedReality.Portal",
        "Microsoft.Xbox.TCUI","Microsoft.XboxGameOverlay","Microsoft.XboxGamingOverlay",
        "Microsoft.XboxSpeechToTextOverlay","Microsoft.YourPhone","Clipchamp.Clipchamp",
        "Microsoft.Todos","Microsoft.PowerAutomateDesktop","MicrosoftCorporationII.QuickAssist",
        "MicrosoftTeams","Microsoft.549981C3F5F10"
    )
    foreach ($app in $bloatApps) {
        Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like "*$app*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
    Write-Log "Removed $($bloatApps.Count) bloatware packages!" OK
    Play-SuccessTone
}

# ─── CONTEXT MENU SHORTCUT ──────────────────────────────────────────────────────

function Add-ContextMenu {
    Write-Log "Adding desktop context menu shortcut..." Action
    $RegPath = "Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\RaysChamber"
    New-Item -Path $RegPath -Force | Out-Null
    Set-ItemProperty -Path $RegPath -Name "MUIVerb" -Value "⚡ Open Ray's Chamber"
    Set-ItemProperty -Path $RegPath -Name "Icon" -Value "powershell.exe"
    Set-ItemProperty -Path $RegPath -Name "Position" -Value "Top"
    New-Item -Path "$RegPath\command" -Force | Out-Null
    Set-ItemProperty -Path "$RegPath\command" -Name "(Default)" -Value 'powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -Command "irm is.gd/RaysUtil | iex"'
    Write-Log "Context menu shortcut added! Right-click desktop to find it." OK
}

function Remove-ContextMenu {
    $RegPath = "Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\RaysChamber"
    if (Test-Path $RegPath) {
        Remove-Item -Path $RegPath -Recurse -Force -ErrorAction SilentlyContinue
        Write-Log "Context menu shortcut removed." OK
    }
}

# ─── SELF-HEAL / MAINTENANCE ────────────────────────────────────────────────────

function Register-MaintenanceTask {
    Write-Log "Creating 3-day maintenance scheduled task..." Action
    $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-WindowStyle Hidden -Command "Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue; Remove-Item $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue; [System.GC]::Collect()"'
    $trigger = New-ScheduledTaskTrigger -Daily -DaysInterval 3 -At 3am
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -StartWhenAvailable
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName "RaysChamber_Maintenance" -Description "Ray's Optimization Chamber: SSD Trim + Temp Cleanup" -Settings $settings -Force
    Write-Log "Maintenance task registered (runs every 3 days at 3AM)." OK
}

function Invoke-SystemHealthScan {
    Write-Log "═══ SYSTEM HEALTH SCAN ═══" Action

    Write-Log "  Running SFC /scannow (this may take a while)..." Info
    $sfcResult = sfc /scannow 2>&1
    if ($sfcResult -match "did not find any integrity violations") {
        Write-Log "  SFC: No integrity violations found." OK
    } else {
        Write-Log "  SFC: Scan complete. Check results above." Info
    }

    Write-Log "  Running DISM /RestoreHealth..." Info
    DISM /Online /Cleanup-Image /RestoreHealth 2>$null
    Write-Log "  DISM repair complete." OK

    Write-Log "  Resetting Windows Update components..." Info
    Stop-Service -Name wuauserv,cryptSvc,bits,msiserver -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:windir\SoftwareDistribution" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:windir\System32\catroot2" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv,cryptSvc,bits,msiserver -ErrorAction SilentlyContinue
    Write-Log "  Windows Update cache purged." OK

    Write-Log "System Health Scan complete!" OK
    Play-SuccessTone
}

function Run-WinSATBenchmark {
    Write-Log "Running WinSAT benchmark (takes 1-2 minutes)..." Action
    winsat formal 2>$null
    Write-Log "WinSAT benchmark complete! Restart to see updated scores." OK
    Play-SuccessTone
}

# ─── RAM SPEED CHECK ─────────────────────────────────────────────────────────────

function Check-RAMSpeed {
    Write-Log "═══ RAM SPEED ANALYSIS ═══" Action
    $sticks = Get-CimInstance Win32_PhysicalMemory
    foreach ($stick in $sticks) {
        $cap = [math]::Round($stick.Capacity / 1GB)
        $spd = $stick.Speed
        $cfgSpd = $stick.ConfiguredClockSpeed
        Write-Log "  Stick: ${cap}GB | Rated: ${spd}MHz | Running: ${cfgSpd}MHz" Info
        if ($cfgSpd -lt $spd) {
            Write-Log "  ⚠ RAM running BELOW rated speed! Enable XMP/DOCP in BIOS!" Warn
        } else {
            Write-Log "  ✓ RAM running at rated speed." OK
        }
    }
    Play-SuccessTone
}

# ─── FRAME RATE CAP INFO ────────────────────────────────────────────────────────

function Show-FrameCapAdvice {
    Write-Log "═══ FRAME RATE CAP ADVISOR ═══" Action
    try {
        $monitors = Get-CimInstance -Namespace root\wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction SilentlyContinue
        Write-Log "  Monitor Refresh Rate: ~${monitorHz}Hz detected" Info
    } catch {}
    Write-Log "  Recommended Cap: ${monitorHz} FPS (match your monitor)" Info
    Write-Log "  For NVIDIA: Open NVIDIA Control Panel > Manage 3D > Max Frame Rate > $monitorHz" Info
    Write-Log "  For AMD: Open Radeon Software > Gaming > Frame Rate Target > $monitorHz" Info
    Write-Log "  For RTSS: Set Framerate Limit to $monitorHz in RivaTuner" Info
    Write-Log "  Tip: Capping at $(($monitorHz - 3)) can reduce input lag with V-Sync OFF." OK
}

# ─── MICROWIN ISO DEBLOAT ────────────────────────────────────────────────────────

function Start-MicroWin {
    Write-Log "═══ MICROWIN ISO DEBLOATER ═══" Action
    $ofd = New-Object System.Windows.Forms.OpenFileDialog
    $ofd.Filter = "ISO Files (*.iso)|*.iso"
    $ofd.Title = "Select Windows ISO"
    if ($ofd.ShowDialog() -ne 'OK') { Write-Log "Cancelled." Warn; return }

    $isoPath = $ofd.FileName
    Write-Log "  Mounting ISO: $isoPath" Info
    $mount = Mount-DiskImage -ImagePath $isoPath -PassThru
    $driveLetter = ($mount | Get-Volume).DriveLetter
    $workDir = "$env:TEMP\MicroWin"
    $wimPath = "${driveLetter}:\sources\install.wim"

    if (-not (Test-Path $wimPath)) {
        $wimPath = "${driveLetter}:\sources\install.esd"
    }
    if (-not (Test-Path $wimPath)) {
        Write-Log "  Cannot find install.wim or install.esd!" Error
        Dismount-DiskImage -ImagePath $isoPath
        return
    }

    Ensure-Path $workDir
    Write-Log "  Copying WIM to work directory..." Info
    Copy-Item $wimPath "$workDir\install.wim" -Force

    Write-Log "  Removing bloatware from image..." Info
    $mountDir = "$workDir\mount"
    Ensure-Path $mountDir
    dism /mount-wim /wimfile:"$workDir\install.wim" /index:1 /mountdir:$mountDir 2>$null

    $bloatPackages = dism /image:$mountDir /get-provisionedappxpackages 2>$null | Select-String "PackageName" | ForEach-Object {
        ($_ -split ":")[1].Trim()
    } | Where-Object { $_ -match "Bing|Zune|Solitaire|People|Maps|Feedback|SkypeApp|Xbox" }

    foreach ($pkg in $bloatPackages) {
        dism /image:$mountDir /remove-provisionedappxpackage /packagename:$pkg 2>$null
        Write-Log "  Removed: $pkg" Info
    }

    dism /unmount-wim /mountdir:$mountDir /commit 2>$null
    Dismount-DiskImage -ImagePath $isoPath
    Write-Log "MicroWin ISO debloat complete! Clean WIM at: $workDir\install.wim" OK
    Play-SuccessTone
}

# ─── COMPLETE REVERT FUNCTION ────────────────────────────────────────────────────

function Revert-AllChanges {
    Write-Log "═══ REVERTING ALL OPTIMIZATIONS TO WINDOWS DEFAULTS ═══" Action

    # Visuals
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'UserPreferencesMask' -Value ([byte[]](0x9E,0x3E,0x07,0x80,0x12,0x00,0x00,0x00)) -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'MenuShowDelay' -Value '400' -ErrorAction SilentlyContinue
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 0 -ErrorAction SilentlyContinue
    Write-Log "  Visuals restored." Info

    # Memory
    Enable-MMAgent -MemoryCompression -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 3 -ErrorAction SilentlyContinue
    Write-Log "  Memory settings restored." Info

    # Priority
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 20 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 2 -ErrorAction SilentlyContinue
    Write-Log "  Priority settings restored." Info

    # GPU Priority
    $gpuTaskPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    if (Test-Path $gpuTaskPath) {
        Set-ItemProperty -Path $gpuTaskPath -Name "GPU Priority" -Value 2 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $gpuTaskPath -Name "Priority" -Value 2 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $gpuTaskPath -Name "Scheduling Category" -Value "Medium" -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $gpuTaskPath -Name "SFIO Priority" -Value "Normal" -ErrorAction SilentlyContinue
    }

    # DWM Priority
    $dwmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager"
    if (Test-Path $dwmPath) {
        Set-ItemProperty -Path $dwmPath -Name "Priority" -Value 5 -ErrorAction SilentlyContinue
    }
    Write-Log "  GPU/DWM priority restored." Info

    # BCD
    bcdedit /deletevalue useplatformtick 2>$null
    bcdedit /deletevalue disabledynamictick 2>$null
    bcdedit /deletevalue useplatformclock 2>$null
    Write-Log "  BCD settings restored." Info

    # Network (Nagle re-enable)
    $nics = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
    foreach ($nic in $nics) {
        Remove-ItemProperty -Path $nic.PSPath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $nic.PSPath -Name "TCPNoDelay" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $nic.PSPath -Name "TcpDelAckTicks" -ErrorAction SilentlyContinue
    }
    netsh int tcp set global autotuninglevel=normal 2>$null
    Write-Log "  Network settings restored." Info

    # Services
    $services = @("SysMain","DiagTrack","WbioSrvc","MapsBroker","WMPNetworkSvc","RemoteRegistry","dmwappushservice")
    foreach ($svc in $services) {
        Set-Service -Name $svc -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $svc -ErrorAction SilentlyContinue
    }
    Write-Log "  Services restored." Info

    # Telemetry
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 3 -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\AdvertisingInfo" -Name "DisabledByGroupPolicy" -ErrorAction SilentlyContinue
    Write-Log "  Telemetry settings restored." Info

    # Power
    powercfg -setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PowerThrottlingOff" -Value 0 -ErrorAction SilentlyContinue
    powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 5 2>$null
    powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 100 2>$null
    powercfg -setactive scheme_current 2>$null
    Write-Log "  Power settings restored (Balanced plan)." Info

    # USB
    powercfg -SETACVALUEINDEX SCHEME_CURRENT 2a033b03-2eef-4ce0-bd58-3e193014470b 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 2>$null
    powercfg -setactive SCHEME_CURRENT 2>$null
    Write-Log "  USB selective suspend re-enabled." Info

    # Mouse
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "1" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "6" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "10" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "1" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value "12" -ErrorAction SilentlyContinue
    Write-Log "  Mouse/Keyboard settings restored." Info

    # Game DVR
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 0 -ErrorAction SilentlyContinue
    Write-Log "  Game DVR/FSO restored." Info

    # Security mitigations
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverride" /f 2>$null | Out-Null
    reg delete "HKLM\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" /v "FeatureSettingsOverrideMask" /f 2>$null | Out-Null
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard" -Name "EnableVirtualizationBasedSecurity" -Value 1 -ErrorAction SilentlyContinue
    Write-Log "  CPU mitigations and VBS re-enabled." Info

    # GPU
    $gpuRegPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000"
    if (Test-Path $gpuRegPath) {
        Remove-ItemProperty -Path $gpuRegPath -Name "PowerMizerEnable" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $gpuRegPath -Name "PerfLevelSrc" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $gpuRegPath -Name "PowerMizerLevel" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $gpuRegPath -Name "PowerMizerLevelAC" -ErrorAction SilentlyContinue
    }
    Write-Log "  GPU power settings restored." Info

    # Context Menu
    Remove-ContextMenu

    # Scheduled Task
    Unregister-ScheduledTask -TaskName "RaysChamber_Maintenance" -Confirm:$false -ErrorAction SilentlyContinue
    Write-Log "  Maintenance task removed." Info

    # Stop Auto-Booster
    Stop-AutoBooster

    # Restart Explorer
    Restart-Shell

    Write-Log "ALL OPTIMIZATIONS REVERTED TO WINDOWS DEFAULTS!" OK
    Play-SuccessTone
}

# ═══════════════════════════════════════════════════════════════════════════════
# WPF XAML GUI
# ═══════════════════════════════════════════════════════════════════════════════

[xml]$XAML = @"
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Ray's Optimization Chamber v5.0"
    Width="980" Height="720" MinWidth="800" MinHeight="600"
    WindowStartupLocation="CenterScreen"
    Background="$($C.BG)" Foreground="$($C.Text)"
    FontFamily="Segoe UI">
    <Window.Resources>
        <Style x:Key="NavBtn" TargetType="Button">
            <Setter Property="Background" Value="Transparent"/>
            <Setter Property="Foreground" Value="$($C.TextDim)"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="6,6,0,0" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="$($C.Surface)"/>
                                <Setter Property="Foreground" Value="$($C.Text)"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="ActionBtn" TargetType="Button">
            <Setter Property="Background" Value="$($C.Surface2)"/>
            <Setter Property="Foreground" Value="$($C.Text)"/>
            <Setter Property="BorderBrush" Value="$($C.Border)"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="14,8"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="SemiBold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="$($C.Accent)"/>
                                <Setter Property="Foreground" Value="$($C.BG)"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="AccentBtn" TargetType="Button">
            <Setter Property="Background" Value="$($C.Accent)"/>
            <Setter Property="Foreground" Value="$($C.BG)"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="16,10"/>
            <Setter Property="FontSize" Value="13"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="$($C.Green)"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="DangerBtn" TargetType="Button">
            <Setter Property="Background" Value="$($C.Red)"/>
            <Setter Property="Foreground" Value="White"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="14,8"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#FF6680"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style x:Key="GoldBtn" TargetType="Button">
            <Setter Property="Background" Value="$($C.Gold)"/>
            <Setter Property="Foreground" Value="$($C.BG)"/>
            <Setter Property="BorderThickness" Value="0"/>
            <Setter Property="Padding" Value="14,8"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="FontWeight" Value="Bold"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="5" Padding="{TemplateBinding Padding}">
                            <ContentPresenter HorizontalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter TargetName="bd" Property="Background" Value="#FFE44D"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
    </Window.Resources>
    <Grid>
        <Grid.RowDefinitions>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="Auto"/>
            <RowDefinition Height="*"/>
            <RowDefinition Height="160"/>
        </Grid.RowDefinitions>

        <!-- TITLE BAR -->
        <Border Grid.Row="0" Background="$($C.NavBG)" Padding="16,10">
            <DockPanel>
                <TextBlock DockPanel.Dock="Left" FontSize="16" FontWeight="Bold" Foreground="$($C.Accent)">
                    ⚡ Ray's Optimization Chamber v5.0
                </TextBlock>
                <TextBlock DockPanel.Dock="Right" FontSize="11" Foreground="$($C.TextDim)" VerticalAlignment="Center" x:Name="TxtHWInfo">
                    Loading hardware info...
                </TextBlock>
            </DockPanel>
        </Border>

        <!-- NAVIGATION -->
        <Border Grid.Row="1" Background="$($C.NavBG)" Padding="8,0,8,0">
            <StackPanel Orientation="Horizontal">
                <Button x:Name="NavInstall"  Content="📦 Install"  Style="{StaticResource NavBtn}"/>
                <Button x:Name="NavTweaks"   Content="🔧 Tweaks"   Style="{StaticResource NavBtn}"/>
                <Button x:Name="NavGaming"   Content="🎮 Gaming"   Style="{StaticResource NavBtn}"/>
                <Button x:Name="NavHardware" Content="🔩 Hardware" Style="{StaticResource NavBtn}"/>
                <Button x:Name="NavConfig"   Content="⚙ Config"    Style="{StaticResource NavBtn}"/>
                <Button x:Name="NavUpdates"  Content="🔄 Updates"  Style="{StaticResource NavBtn}"/>
                <Button x:Name="NavHealth"   Content="🩺 Health"   Style="{StaticResource NavBtn}"/>
            </StackPanel>
        </Border>

        <!-- MAIN CONTENT AREA -->
        <Border Grid.Row="2" Background="$($C.Surface)" BorderBrush="$($C.Border)" BorderThickness="0,1" Margin="0">
            <ScrollViewer VerticalScrollBarVisibility="Auto" Padding="16">
                <Grid>
                    <!-- INSTALL TAB -->
                    <StackPanel x:Name="PanelInstall" Visibility="Visible">
                        <TextBlock Text="📦 Application Installer (WinGet)" FontSize="18" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,0,0,4"/>
                        <TextBlock Text="Select apps and click Install. Powered by winget." Foreground="$($C.TextDim)" Margin="0,0,0,8"/>
                        <DockPanel Margin="0,0,0,8">
                            <Button x:Name="BtnInstallSelected" Content="⬇ Install Selected" Style="{StaticResource AccentBtn}" DockPanel.Dock="Right"/>
                            <Button x:Name="BtnSelectAll" Content="Select All" Style="{StaticResource ActionBtn}" DockPanel.Dock="Right"/>
                            <Button x:Name="BtnDeselectAll" Content="Deselect All" Style="{StaticResource ActionBtn}" DockPanel.Dock="Right"/>
                            <TextBox x:Name="TxtSearch" Background="$($C.BG)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" Padding="8,6" FontSize="13" VerticalContentAlignment="Center">
                                <TextBox.Style>
                                    <Style TargetType="TextBox">
                                        <Setter Property="Tag" Value="🔍 Search apps..."/>
                                    </Style>
                                </TextBox.Style>
                            </TextBox>
                        </DockPanel>
                        <WrapPanel x:Name="AppPanel" Orientation="Horizontal"/>
                    </StackPanel>

                    <!-- TWEAKS TAB -->
                    <StackPanel x:Name="PanelTweaks" Visibility="Collapsed">
                        <TextBlock Text="🔧 System Tweaks — Tiered Optimization" FontSize="18" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,0,0,4"/>
                        <TextBlock Text="Hardware-aware optimization. Creates restore point before applying." Foreground="$($C.TextDim)" Margin="0,0,0,12"/>

                        <Border Background="$($C.BG)" CornerRadius="6" Padding="12" Margin="0,0,0,12" BorderBrush="$($C.Border)" BorderThickness="1">
                            <StackPanel>
                                <TextBlock Text="⚠ SAFETY FIRST" FontSize="14" FontWeight="Bold" Foreground="$($C.Gold)" Margin="0,0,0,6"/>
                                <Button x:Name="BtnRestore" Content="🛡 Create System Restore Point" Style="{StaticResource GoldBtn}" HorizontalAlignment="Left"/>
                                <TextBlock x:Name="TxtRestoreStatus" Text="Status: No restore point created" Foreground="$($C.Red)" Margin="0,6,0,0" FontSize="11"/>
                            </StackPanel>
                        </Border>

                        <TextBlock Text="TIER-BASED OPTIMIZATION" FontSize="13" FontWeight="Bold" Foreground="$($C.TextDim)" Margin="0,0,0,8"/>
                        <WrapPanel Margin="0,0,0,12">
                            <Button x:Name="BtnLowEnd"  Content="🟢 Low-End (RAM + Visual)" Style="{StaticResource ActionBtn}" ToolTip="Disables animations, memory compression, heavy services. Safe for all PCs."/>
                            <Button x:Name="BtnMidEnd"  Content="🔵 Mid-Range (Snappy + Telemetry)" Style="{StaticResource ActionBtn}" ToolTip="Adds telemetry block, priority boost, network throttling disable. Recommended for most users."/>
                            <Button x:Name="BtnHighEnd" Content="🔴 High-End Nuclear (Max Power)" Style="{StaticResource DangerBtn}" ToolTip="BCD tweaks, Spectre/Meltdown disable, VBS off, GPU MSI mode. For enthusiasts only!"/>
                        </WrapPanel>

                        <TextBlock Text="INDIVIDUAL TWEAKS" FontSize="13" FontWeight="Bold" Foreground="$($C.TextDim)" Margin="0,0,0,8"/>
                        <WrapPanel>
                            <Button x:Name="BtnDebloat"   Content="🗑 Debloat Windows" Style="{StaticResource ActionBtn}" ToolTip="Removes 25+ pre-installed bloatware apps like Bing, Solitaire, Xbox overlays."/>
                            <Button x:Name="BtnCleanup"   Content="🧹 System Cleanup" Style="{StaticResource ActionBtn}" ToolTip="Clears temp files, Windows Update cache, and Recycle Bin. Safe — never touches user docs."/>
                            <Button x:Name="BtnOptRAM"    Content="💾 Optimize RAM" Style="{StaticResource ActionBtn}" ToolTip="Disables memory compression, clears standby list, optimizes cache priority."/>
                            <Button x:Name="BtnOptStore"  Content="💿 Optimize Storage" Style="{StaticResource ActionBtn}" ToolTip="Runs SSD TRIM, sets game I/O priority to High, disables last-access timestamps."/>
                            <Button x:Name="BtnOptNet"    Content="🌐 Optimize Network" Style="{StaticResource ActionBtn}" ToolTip="Disables Nagle's algorithm, network throttling. Enables CTCP + ECN."/>
                            <Button x:Name="BtnUSB"       Content="🔌 USB/Input Tweaks" Style="{StaticResource ActionBtn}" ToolTip="Disables USB selective suspend, mouse acceleration, maximizes keyboard repeat rate."/>
                            <Button x:Name="BtnRefreshNet" Content="📡 Internet Refresher" Style="{StaticResource ActionBtn}" ToolTip="Flushes DNS, resets Winsock, renews IP. Fixes connection drops without changing ISP settings."/>
                        </WrapPanel>

                        <Border Background="$($C.BG)" CornerRadius="6" Padding="12" Margin="0,12,0,0" BorderBrush="$($C.Red)" BorderThickness="1">
                            <StackPanel>
                                <TextBlock Text="↩ REVERT ALL CHANGES" FontSize="13" FontWeight="Bold" Foreground="$($C.Red)" Margin="0,0,0,6"/>
                                <Button x:Name="BtnRevert" Content="⏪ Revert Everything to Windows Defaults" Style="{StaticResource DangerBtn}" HorizontalAlignment="Left" ToolTip="Restores ALL registry, BCD, services, power plans, visuals, and network to factory defaults."/>
                            </StackPanel>
                        </Border>
                    </StackPanel>

                    <!-- GAMING TAB -->
                    <StackPanel x:Name="PanelGaming" Visibility="Collapsed">
                        <TextBlock Text="🎮 Gaming Optimization — Zero Latency" FontSize="18" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,0,0,4"/>
                        <TextBlock Text="Process Lasso + MSI Afterburner + ExitLag combined." Foreground="$($C.TextDim)" Margin="0,0,0,12"/>

                        <WrapPanel Margin="0,0,0,12">
                            <Button x:Name="BtnGameBoost" Content="🚀 Game Booster (All-in-One)" Style="{StaticResource AccentBtn}" ToolTip="GPU Priority 8, Win32PrioritySeparation 0x26, Network Throttle OFF, Game DVR OFF, Mouse Accel OFF, Max Keyboard Speed."/>
                            <Button x:Name="BtnAutoBoost" Content="🤖 Start Auto-Booster" Style="{StaticResource ActionBtn}" ToolTip="Background loop: detects CS2/Valorant/Fortnite and auto-boosts to High priority, demotes Chrome/Discord."/>
                            <Button x:Name="BtnStopBoost" Content="⏹ Stop Auto-Booster" Style="{StaticResource ActionBtn}" ToolTip="Stops the background game detection loop."/>
                            <Button x:Name="BtnRAMPurge"  Content="🧠 Purge RAM Now" Style="{StaticResource ActionBtn}" ToolTip="Instantly clears the RAM standby list. Use when games start stuttering after long sessions."/>
                            <Button x:Name="BtnFrameCap"  Content="🖥 Frame Cap Advisor" Style="{StaticResource ActionBtn}" ToolTip="Detects your monitor refresh rate and tells you the optimal FPS cap for NVIDIA/AMD/RTSS."/>
                        </WrapPanel>

                        <TextBlock Text="LAPTOP SPECIAL" FontSize="13" FontWeight="Bold" Foreground="$($C.Gold)" Margin="0,0,0,8"/>
                        <WrapPanel>
                            <Button x:Name="BtnLaptopGod" Content="💻 Laptop God Mode" Style="{StaticResource GoldBtn}" ToolTip="99% CPU cap (prevents turbo overheat crash), disables DPTF thermal throttling, Efficiency Mode OFF. PLUG IN CHARGER!"/>
                        </WrapPanel>
                    </StackPanel>

                    <!-- HARDWARE TAB -->
                    <StackPanel x:Name="PanelHardware" Visibility="Collapsed">
                        <TextBlock Text="🔩 Hardware Info &amp; Deep Tweaks" FontSize="18" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,0,0,4"/>
                        <Border Background="$($C.BG)" CornerRadius="6" Padding="12" Margin="0,8,0,12" BorderBrush="$($C.Border)" BorderThickness="1">
                            <StackPanel>
                                <TextBlock x:Name="TxtHWDetail" Text="Loading..." Foreground="$($C.Text)" FontFamily="Cascadia Code,Consolas" FontSize="12" TextWrapping="Wrap"/>
                            </StackPanel>
                        </Border>
                        <WrapPanel>
                            <Button x:Name="BtnCheckRAM"   Content="💾 Check RAM Speed (XMP)" Style="{StaticResource ActionBtn}" ToolTip="Checks if your RAM is running at its advertised speed. Warns if XMP/DOCP needs enabling in BIOS."/>
                            <Button x:Name="BtnContextMenu" Content="📌 Add Desktop Context Menu" Style="{StaticResource ActionBtn}" ToolTip="Adds 'Open Ray's Chamber' to your desktop right-click menu for instant access."/>
                            <Button x:Name="BtnRmContext"  Content="❌ Remove Context Menu" Style="{StaticResource ActionBtn}" ToolTip="Removes the desktop right-click shortcut."/>
                            <Button x:Name="BtnMaintTask"  Content="📅 Setup Auto-Maintenance" Style="{StaticResource ActionBtn}" ToolTip="Creates a scheduled task that runs SSD TRIM + Temp Cleanup every 3 days at 3AM."/>
                        </WrapPanel>
                    </StackPanel>

                    <!-- CONFIG TAB -->
                    <StackPanel x:Name="PanelConfig" Visibility="Collapsed">
                        <TextBlock Text="⚙ Configuration &amp; Features" FontSize="18" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,0,0,4"/>
                        <TextBlock Text="Windows Optional Features and ISO tools." Foreground="$($C.TextDim)" Margin="0,0,0,12"/>

                        <TextBlock Text="OPTIONAL FEATURES" FontSize="13" FontWeight="Bold" Foreground="$($C.TextDim)" Margin="0,0,0,8"/>
                        <WrapPanel Margin="0,0,0,12">
                            <Button x:Name="BtnWSL"      Content="🐧 Enable WSL2" Style="{StaticResource ActionBtn}" ToolTip="Enables Windows Subsystem for Linux 2. Requires reboot."/>
                            <Button x:Name="BtnSandbox"  Content="📦 Enable Sandbox" Style="{StaticResource ActionBtn}" ToolTip="Enables Windows Sandbox for testing apps safely."/>
                            <Button x:Name="BtnHyperV"   Content="🖥 Enable Hyper-V" Style="{StaticResource ActionBtn}" ToolTip="Enables Hyper-V virtualization. Note: May conflict with some anti-cheat."/>
                            <Button x:Name="BtnDotNet"   Content="🔧 Enable .NET 3.5" Style="{StaticResource ActionBtn}" ToolTip="Installs .NET Framework 3.5 for legacy application support."/>
                        </WrapPanel>

                        <TextBlock Text="DNS CONFIGURATION" FontSize="13" FontWeight="Bold" Foreground="$($C.TextDim)" Margin="0,0,0,8"/>
                        <WrapPanel Margin="0,0,0,12">
                            <Button x:Name="BtnDNSGoogle" Content="🌐 Google DNS" Style="{StaticResource ActionBtn}" ToolTip="Sets DNS to 8.8.8.8 / 8.8.4.4"/>
                            <Button x:Name="BtnDNSCF"     Content="☁ Cloudflare DNS" Style="{StaticResource ActionBtn}" ToolTip="Sets DNS to 1.1.1.1 / 1.0.0.1"/>
                            <Button x:Name="BtnDNSAuto"   Content="🔄 Auto (DHCP)" Style="{StaticResource ActionBtn}" ToolTip="Resets DNS to automatic (DHCP) mode."/>
                        </WrapPanel>

                        <TextBlock Text="MICROWIN" FontSize="13" FontWeight="Bold" Foreground="$($C.TextDim)" Margin="0,0,0,8"/>
                        <Button x:Name="BtnMicroWin" Content="💿 MicroWin ISO Debloater" Style="{StaticResource AccentBtn}" HorizontalAlignment="Left" ToolTip="Select a Windows ISO file and strip bloatware from it using DISM. Creates a clean install image."/>
                    </StackPanel>

                    <!-- UPDATES TAB -->
                    <StackPanel x:Name="PanelUpdates" Visibility="Collapsed">
                        <TextBlock Text="🔄 Windows Update Control" FontSize="18" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,0,0,12"/>
                        <WrapPanel>
                            <Button x:Name="BtnUpdDefault" Content="✅ Default (Auto)" Style="{StaticResource ActionBtn}" ToolTip="Restores Windows Update to default automatic behavior."/>
                            <Button x:Name="BtnUpdSec"     Content="🔒 Security Only" Style="{StaticResource ActionBtn}" ToolTip="Only installs critical security updates. Blocks feature updates."/>
                            <Button x:Name="BtnUpdOff"     Content="⛔ Disable Updates" Style="{StaticResource DangerBtn}" ToolTip="Completely disables Windows Update service. Not recommended long-term."/>
                        </WrapPanel>
                    </StackPanel>

                    <!-- HEALTH TAB -->
                    <StackPanel x:Name="PanelHealth" Visibility="Collapsed">
                        <TextBlock Text="🩺 System Health &amp; Diagnostics" FontSize="18" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,0,0,4"/>
                        <TextBlock Text="Self-healing tools to fix corrupted files and stuck updates." Foreground="$($C.TextDim)" Margin="0,0,0,12"/>
                        <WrapPanel>
                            <Button x:Name="BtnFullScan"   Content="🔬 Full Health Scan (SFC+DISM+WU)" Style="{StaticResource AccentBtn}" ToolTip="Runs SFC /scannow, DISM /RestoreHealth, and resets Windows Update. Takes 5-15 minutes."/>
                            <Button x:Name="BtnSFC"        Content="🔍 SFC Only" Style="{StaticResource ActionBtn}" ToolTip="System File Checker — scans and repairs corrupted Windows files."/>
                            <Button x:Name="BtnDISM"       Content="🏥 DISM Only" Style="{StaticResource ActionBtn}" ToolTip="Downloads fresh system components from Microsoft servers."/>
                            <Button x:Name="BtnWinSAT"     Content="📊 Run WinSAT Benchmark" Style="{StaticResource ActionBtn}" ToolTip="Runs the official Windows System Assessment Tool. Takes 1-2 minutes. Updates your hardware scores."/>
                            <Button x:Name="BtnRestartShell" Content="🔄 Restart Explorer" Style="{StaticResource ActionBtn}" ToolTip="Restarts Windows Explorer to apply registry changes without logging out."/>
                        </WrapPanel>
                    </StackPanel>
                </Grid>
            </ScrollViewer>
        </Border>

        <!-- LOG WINDOW -->
        <Border Grid.Row="3" Background="$($C.LogBG)" BorderBrush="$($C.Border)" BorderThickness="0,1,0,0">
            <DockPanel>
                <Border DockPanel.Dock="Top" Background="$($C.NavBG)" Padding="12,6">
                    <TextBlock Text="📋 Activity Log" FontSize="12" FontWeight="SemiBold" Foreground="$($C.TextDim)"/>
                </Border>
                <ScrollViewer x:Name="LogScroll" VerticalScrollBarVisibility="Auto" Padding="12,6">
                    <TextBlock x:Name="LogBox" TextWrapping="Wrap" FontFamily="Cascadia Code,Consolas" FontSize="11"/>
                </ScrollViewer>
            </DockPanel>
        </Border>
    </Grid>
</Window>
"@

# ─── BUILD WINDOW ────────────────────────────────────────────────────────────────
$Reader = New-Object System.Xml.XmlNodeReader $XAML
$Window = [Windows.Markup.XamlReader]::Load($Reader)

$Ctrl = @{}
$XAML.SelectNodes("//*[@*[contains(translate(name(),'X','x'),'name')]]") | ForEach-Object {
    $name = $_.Name
    if (-not $name) { $name = $_.'x:Name' }
    if ($name) { $Ctrl[$name] = $Window.FindName($name) }
}

# ─── DWM EFFECTS ─────────────────────────────────────────────────────────────────
$Window.Add_Loaded({
    try {
        $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper($Window)).Handle
        [DwmHelper]::EnableDarkTitle($hwnd)
        [DwmHelper]::EnableMica($hwnd)
    } catch {}

    # Hardware info in title bar
    $Ctrl['TxtHWInfo'].Text = "$HardwareType | $cpuName | ${ramGB}GB | $gpuName | Tier: $SuggestedTier"

    # Hardware detail panel
    $hwDetail = @"
DEVICE TYPE:    $HardwareType
CPU:            $cpuName
CORES/THREADS:  $cpuCores C / $cpuThreads T
RAM:            ${ramGB}GB @ ${ramSpeed}MHz (Max: ${ramMax}GB)
GPU:            $gpuName $(if($isIGPU){"(Integrated)"}else{"(Dedicated)"})
MONITOR:        ~${monitorHz}Hz
OS:             $osVersion
WINSAT SCORES:  CPU=$cpuScore  MEM=$memScore  DISK=$diskScore  GPU=$gpuScore  AVG=$totalScore
SUGGESTED TIER: $SuggestedTier
"@
    $Ctrl['TxtHWDetail'].Text = $hwDetail

    Write-Log "Ray's Optimization Chamber v5.0 initialized." OK
    Write-Log "Hardware: $HardwareType | $cpuName | ${ramGB}GB RAM | $gpuName" Info
    Write-Log "Suggested tier: $SuggestedTier | WinSAT: $totalScore/10" Info
    if ($isLaptop) { Write-Log "Laptop detected — Gold accent mode active." Warn }
    if ($isIGPU) { Write-Log "Integrated GPU detected — iGPU tweaks available." Warn }
})

# ─── NAVIGATION ──────────────────────────────────────────────────────────────────
$Panels = @('PanelInstall','PanelTweaks','PanelGaming','PanelHardware','PanelConfig','PanelUpdates','PanelHealth')
$NavBtns = @('NavInstall','NavTweaks','NavGaming','NavHardware','NavConfig','NavUpdates','NavHealth')

function Switch-Tab {
    param([int]$Index)
    for ($i = 0; $i -lt $Panels.Count; $i++) {
        $Ctrl[$Panels[$i]].Visibility = if ($i -eq $Index) { 'Visible' } else { 'Collapsed' }
        $Ctrl[$NavBtns[$i]].Background = if ($i -eq $Index) { $C.Surface } else { 'Transparent' }
        $Ctrl[$NavBtns[$i]].Foreground = if ($i -eq $Index) { $C.Accent } else { $C.TextDim }
    }
}

$Ctrl['NavInstall'].Add_Click({ Switch-Tab 0 })
$Ctrl['NavTweaks'].Add_Click({ Switch-Tab 1 })
$Ctrl['NavGaming'].Add_Click({ Switch-Tab 2 })
$Ctrl['NavHardware'].Add_Click({ Switch-Tab 3 })
$Ctrl['NavConfig'].Add_Click({ Switch-Tab 4 })
$Ctrl['NavUpdates'].Add_Click({ Switch-Tab 5 })
$Ctrl['NavHealth'].Add_Click({ Switch-Tab 6 })

# ─── BUILD APP CHECKBOXES ────────────────────────────────────────────────────────
$AppCheckboxes = @{}
foreach ($app in $AppCatalogue) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $app.N
    $cb.Foreground = $C.Text
    $cb.Margin = [System.Windows.Thickness]::new(4)
    $cb.Width = 200
    $cb.FontSize = 12
    $cb.ToolTip = "winget install $($app.Id)"
    $cb.Tag = $app.Id
    $Ctrl['AppPanel'].Children.Add($cb)
    $AppCheckboxes[$app.Id] = $cb
}

$Ctrl['BtnSelectAll'].Add_Click({
    foreach ($cb in $AppCheckboxes.Values) { $cb.IsChecked = $true }
})
$Ctrl['BtnDeselectAll'].Add_Click({
    foreach ($cb in $AppCheckboxes.Values) { $cb.IsChecked = $false }
})

$Ctrl['BtnInstallSelected'].Add_Click({
    $selected = $AppCheckboxes.GetEnumerator() | Where-Object { $_.Value.IsChecked } | ForEach-Object { $_.Key }
    if (-not $selected) { Write-Log "No apps selected!" Warn; return }
    Write-Log "Installing $($selected.Count) applications..." Action
    foreach ($id in $selected) {
        Write-Log "  Installing $id..." Info
        $result = winget install --id $id --accept-source-agreements --accept-package-agreements -e 2>&1
        if ($LASTEXITCODE -eq 0) { Write-Log "  $id installed successfully." OK }
        else { Write-Log "  $id may have failed: $LASTEXITCODE" Warn }
    }
    Write-Log "Installation batch complete!" OK
    Play-SuccessTone
})

# ─── TWEAKS TAB BUTTONS ─────────────────────────────────────────────────────────
$Ctrl['BtnRestore'].Add_Click({
    Write-Log "Creating System Restore Point..." Action
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Ray's Chamber v5.0 Backup" -RestorePointType "MODIFY_SETTINGS"
        $Script:RestoreCreated = $true
        $Ctrl['TxtRestoreStatus'].Text = "Status: ✅ Restore point created at $(Get-Date -Format 'HH:mm:ss')"
        $Ctrl['TxtRestoreStatus'].Foreground = $C.Green
        Write-Log "Restore point created successfully." OK
    } catch { Write-Log "Restore point error: $_" Error }
})

function Guard-Restore {
    if (-not $Script:RestoreCreated) {
        [System.Windows.MessageBox]::Show("Please create a System Restore Point first!", "Safety Guard", "OK", "Warning")
        Write-Log "Blocked: Create a restore point first!" Warn
        return $false
    }
    return $true
}

$Ctrl['BtnLowEnd'].Add_Click({  if (Guard-Restore) { Apply-LowEndTweaks } })
$Ctrl['BtnMidEnd'].Add_Click({  if (Guard-Restore) { Apply-MidRangeTweaks } })
$Ctrl['BtnHighEnd'].Add_Click({ if (Guard-Restore) { Apply-HighEndTweaks } })
$Ctrl['BtnDebloat'].Add_Click({ if (Guard-Restore) { Invoke-Debloat } })
$Ctrl['BtnCleanup'].Add_Click({ Invoke-SystemCleanup })
$Ctrl['BtnOptRAM'].Add_Click({  if (Guard-Restore) { Optimize-RAM } })
$Ctrl['BtnOptStore'].Add_Click({ if (Guard-Restore) { Optimize-Storage } })
$Ctrl['BtnOptNet'].Add_Click({  if (Guard-Restore) { Apply-NetworkTweaks } })
$Ctrl['BtnUSB'].Add_Click({     if (Guard-Restore) { Apply-USBTweaks } })
$Ctrl['BtnRefreshNet'].Add_Click({ Refresh-Internet })
$Ctrl['BtnRevert'].Add_Click({
    $confirm = [System.Windows.MessageBox]::Show("This will revert ALL optimizations to Windows defaults. Continue?", "Confirm Revert", "YesNo", "Warning")
    if ($confirm -eq "Yes") { Revert-AllChanges }
})

# ─── GAMING TAB BUTTONS ─────────────────────────────────────────────────────────
$Ctrl['BtnGameBoost'].Add_Click({ if (Guard-Restore) { Apply-GameBooster } })
$Ctrl['BtnAutoBoost'].Add_Click({ Start-AutoBooster })
$Ctrl['BtnStopBoost'].Add_Click({ Stop-AutoBooster })
$Ctrl['BtnRAMPurge'].Add_Click({  Clear-RAMStandby })
$Ctrl['BtnFrameCap'].Add_Click({  Show-FrameCapAdvice })
$Ctrl['BtnLaptopGod'].Add_Click({ if (Guard-Restore) { Apply-LaptopGodMode } })

# ─── HARDWARE TAB BUTTONS ───────────────────────────────────────────────────────
$Ctrl['BtnCheckRAM'].Add_Click({    Check-RAMSpeed })
$Ctrl['BtnContextMenu'].Add_Click({ Add-ContextMenu })
$Ctrl['BtnRmContext'].Add_Click({   Remove-ContextMenu })
$Ctrl['BtnMaintTask'].Add_Click({   Register-MaintenanceTask })

# ─── CONFIG TAB BUTTONS ─────────────────────────────────────────────────────────
$Ctrl['BtnWSL'].Add_Click({
    Write-Log "Enabling WSL2..." Action
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 2>$null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart 2>$null
    Write-Log "WSL2 enabled. Reboot required." OK
})
$Ctrl['BtnSandbox'].Add_Click({
    Write-Log "Enabling Windows Sandbox..." Action
    Enable-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -All -NoRestart -ErrorAction SilentlyContinue
    Write-Log "Windows Sandbox enabled. Reboot required." OK
})
$Ctrl['BtnHyperV'].Add_Click({
    Write-Log "Enabling Hyper-V..." Action
    Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-All" -All -NoRestart -ErrorAction SilentlyContinue
    Write-Log "Hyper-V enabled. Reboot required." OK
})
$Ctrl['BtnDotNet'].Add_Click({
    Write-Log "Enabling .NET Framework 3.5..." Action
    Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" -All -NoRestart -ErrorAction SilentlyContinue
    Write-Log ".NET 3.5 enabled." OK
})

# DNS
$Ctrl['BtnDNSGoogle'].Add_Click({
    Write-Log "Setting DNS to Google (8.8.8.8)..." Action
    Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses @("8.8.8.8","8.8.4.4") }
    Write-Log "DNS set to Google." OK
})
$Ctrl['BtnDNSCF'].Add_Click({
    Write-Log "Setting DNS to Cloudflare (1.1.1.1)..." Action
    Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses @("1.1.1.1","1.0.0.1") }
    Write-Log "DNS set to Cloudflare." OK
})
$Ctrl['BtnDNSAuto'].Add_Click({
    Write-Log "Resetting DNS to Auto (DHCP)..." Action
    Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses }
    Write-Log "DNS reset to DHCP." OK
})

$Ctrl['BtnMicroWin'].Add_Click({ Start-MicroWin })

# ─── UPDATES TAB BUTTONS ────────────────────────────────────────────────────────
$Ctrl['BtnUpdDefault'].Add_Click({
    Write-Log "Restoring default Windows Update policy..." Action
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Set-Service -Name wuauserv -StartupType Automatic -ErrorAction SilentlyContinue
    Write-Log "Windows Update restored to default." OK
})
$Ctrl['BtnUpdSec'].Add_Click({
    Write-Log "Setting Security Only update policy..." Action
    Ensure-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -Value 0 -ErrorAction SilentlyContinue
    Ensure-Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferFeatureUpdates" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferFeatureUpdatesPeriodInDays" -Value 365 -ErrorAction SilentlyContinue
    Write-Log "Security Only update policy set." OK
})
$Ctrl['BtnUpdOff'].Add_Click({
    $confirm = Show-Warning "Disable Windows Update" "You will stop receiving security patches. Only recommended temporarily."
    if (-not $confirm) { return }
    Write-Log "Disabling Windows Update..." Action
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Log "Windows Update disabled." Warn
})

# ─── HEALTH TAB BUTTONS ─────────────────────────────────────────────────────────
$Ctrl['BtnFullScan'].Add_Click({ Invoke-SystemHealthScan })
$Ctrl['BtnSFC'].Add_Click({
    Write-Log "Running SFC /scannow..." Action
    sfc /scannow 2>&1 | Out-Null
    Write-Log "SFC scan complete." OK
})
$Ctrl['BtnDISM'].Add_Click({
    Write-Log "Running DISM /RestoreHealth..." Action
    DISM /Online /Cleanup-Image /RestoreHealth 2>$null
    Write-Log "DISM repair complete." OK
})
$Ctrl['BtnWinSAT'].Add_Click({ Run-WinSATBenchmark })
$Ctrl['BtnRestartShell'].Add_Click({ Restart-Shell })

# ─── INITIAL TAB ─────────────────────────────────────────────────────────────────
Switch-Tab 0

# ─── SHOW WINDOW ─────────────────────────────────────────────────────────────────
$Window.ShowDialog() | Out-Null

# Cleanup
if ($Script:AutoBoosterJob) {
    Stop-Job -Job $Script:AutoBoosterJob -ErrorAction SilentlyContinue
    Remove-Job -Job $Script:AutoBoosterJob -Force -ErrorAction SilentlyContinue
}
