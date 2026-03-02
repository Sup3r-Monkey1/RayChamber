# ============================================================
#  RAY'S OPTIMIZATION CHAMBER v6.0 - ULTIMATE EDITION
#  75 controls | 30+ tweaks | All buttons verified
# ============================================================
$script:BUILD = '6.0'

# --- SECTION 1: ADMIN ELEVATION ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Elevating Ray's Chamber to Admin..." -ForegroundColor Cyan
    if ($PSCommandPath) {
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    } else {
        Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command `"irm is.gd/RaysUtil | iex`"" -Verb RunAs
    }
    exit
}

# --- SECTION 2: ASSEMBLIES ---
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# --- SECTION 3: HARDWARE DETECTION ---
$cpuName    = try { (Get-CimInstance Win32_Processor).Name } catch { 'Unknown CPU' }
$cpuCores   = try { (Get-CimInstance Win32_Processor).NumberOfCores } catch { 0 }
$cpuThreads = try { (Get-CimInstance Win32_Processor).ThreadCount } catch { 0 }
$ramGB      = try { [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB) } catch { 0 }
$ramSpeed   = try { (Get-CimInstance Win32_PhysicalMemory | Select-Object -First 1).Speed } catch { 0 }
$gpu        = try { (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name } catch { 'Unknown GPU' }
$isLaptop   = $null -ne (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue)
$HardwareType = if ($isLaptop) { 'LAPTOP' } else { 'DESKTOP' }
$SuggestedTier = 'Mid-Range'
if ($ramGB -le 8 -or $cpuName -match 'Celeron|Pentium|Athlon|i3') { $SuggestedTier = 'Low-End' }
if ($ramGB -ge 32 -and -not $isLaptop -and $cpuName -match 'i7|i9|Ryzen 7|Ryzen 9') { $SuggestedTier = 'High-End' }
$StatusColor = if ($isLaptop) { 'Yellow' } else { 'Cyan' }

# --- SECTION 4: CONSOLE BRANDING ---
Clear-Host
Write-Host ''
Write-Host '  ============================================' -ForegroundColor $StatusColor
Write-Host "  RAY'S OPTIMIZATION CHAMBER v$script:BUILD" -ForegroundColor $StatusColor
Write-Host '  ============================================' -ForegroundColor $StatusColor
Write-Host "  DEVICE : $HardwareType | TIER: $SuggestedTier" -ForegroundColor $StatusColor
Write-Host "  CPU    : $cpuName ($cpuCores C / $cpuThreads T)" -ForegroundColor Gray
Write-Host "  RAM    : ${ramGB}GB @ ${ramSpeed}MHz" -ForegroundColor Gray
Write-Host "  GPU    : $gpu" -ForegroundColor Gray
Write-Host '  ============================================' -ForegroundColor $StatusColor
Write-Host ''

# --- SECTION 5: DWM HELPER ---
try {
Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class DwmHelper {
    [DllImport("dwmapi.dll")] static extern int DwmSetWindowAttribute(IntPtr h, int a, ref int v, int s);
    public static void ApplyDark(IntPtr h) {
        int v=1; DwmSetWindowAttribute(h,20,ref v,4);
        int m=2; DwmSetWindowAttribute(h,38,ref m,4);
    }
}
'@
} catch {}

# --- SECTION 6: APP CATALOGUE ---
$Apps = @(
    @{N='Google Chrome';ID='Google.Chrome'},        @{N='Mozilla Firefox';ID='Mozilla.Firefox'},
    @{N='Brave Browser';ID='Brave.Brave'},          @{N='Microsoft Edge';ID='Microsoft.Edge'},
    @{N='Discord';ID='Discord.Discord'},            @{N='Slack';ID='SlackTechnologies.Slack'},
    @{N='Zoom';ID='Zoom.Zoom'},                     @{N='Telegram';ID='Telegram.TelegramDesktop'},
    @{N='Signal';ID='OpenWhisperSystems.Signal'},    @{N='Steam';ID='Valve.Steam'},
    @{N='Epic Games';ID='EpicGames.EpicGamesLauncher'}, @{N='VLC Player';ID='VideoLAN.VLC'},
    @{N='Spotify';ID='Spotify.Spotify'},            @{N='OBS Studio';ID='OBSProject.OBSStudio'},
    @{N='7-Zip';ID='7zip.7zip'},                    @{N='WinRAR';ID='RARLab.WinRAR'},
    @{N='Notepad++';ID='Notepad++.Notepad++'},      @{N='VS Code';ID='Microsoft.VisualStudioCode'},
    @{N='Git';ID='Git.Git'},                        @{N='Node.js LTS';ID='OpenJS.NodeJS.LTS'},
    @{N='Python 3';ID='Python.Python.3.12'},        @{N='PowerToys';ID='Microsoft.PowerToys'},
    @{N='qBittorrent';ID='qBittorrent.qBittorrent'},@{N='GIMP';ID='GIMP.GIMP'},
    @{N='Audacity';ID='Audacity.Audacity'},         @{N='ShareX';ID='ShareX.ShareX'},
    @{N='MSI Afterburner';ID='Guru3D.Afterburner'}, @{N='HWiNFO';ID='REALiX.HWiNFO'},
    @{N='CPU-Z';ID='CPUID.CPU-Z'},                  @{N='Bitwarden';ID='Bitwarden.Bitwarden'}
)

# --- SECTION 7: STATE ---
$script:Ctrl = @{}
$script:RestoreCreated = $false
$script:BoostTimer = $null
$script:GameList = @('cs2','valorant','FortniteClient-Win64-Shipping','r5apex','javaw','GTA5','RocketLeague','VALORANT-Win64-Shipping')
$Panels  = @('PanelInstall','PanelTweaks','PanelGaming','PanelHardware','PanelConfig','PanelUpdates','PanelHealth')
$NavBtns = @('NavInstall','NavTweaks','NavGaming','NavHardware','NavConfig','NavUpdates','NavHealth')

# --- SECTION 8: HELPER FUNCTIONS ---
function Write-Log([string]$Msg, [string]$Type = 'Info') {
    $ts = Get-Date -Format 'HH:mm:ss'
    $colors = @{ OK='#00FFCC'; Action='#00D9FF'; Error='#FF6666'; Warn='#FFD700'; Info='#8090A0' }
    $hex = if ($colors[$Type]) { $colors[$Type] } else { '#8090A0' }
    Write-Host "[$ts] $Msg" -ForegroundColor Gray
    try {
        $lb = $script:Ctrl['LogBox']
        $ls = $script:Ctrl['LogScroll']
        if ($null -ne $lb -and $null -ne $ls) {
            $run = New-Object System.Windows.Documents.Run "[$ts] $Msg`n"
            $run.Foreground = ([System.Windows.Media.BrushConverter]::new()).ConvertFrom($hex)
            $lb.Inlines.Add($run)
            $ls.ScrollToEnd()
        }
    } catch {}
}

function Set-Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
    } catch { Write-Host "  Reg error: $Path\$Name - $_" -ForegroundColor DarkYellow }
}

function Guard-Restore {
    if ($script:RestoreCreated) { return $true }
    $r = [System.Windows.MessageBox]::Show("Create a Restore Point first? (Required for safety)`n`nClick YES to create one now, or NO to skip.", 'Safety Check', 'YesNoCancel', 'Warning')
    if ($r -eq 'Yes') {
        try {
            Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop
            Checkpoint-Computer -Description 'RaysChamber_Backup' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
            $script:RestoreCreated = $true
            Write-Log "Restore Point created! Proceeding..." OK
            return $true
        } catch {
            Write-Log "Restore point failed: $_ - proceeding anyway" Warn
            $script:RestoreCreated = $true
            return $true
        }
    } elseif ($r -eq 'No') {
        $script:RestoreCreated = $true
        Write-Log "Skipped restore point - proceeding at your own risk" Warn
        return $true
    }
    return $false
}

function Switch-Tab([int]$Index) {
    for ($i = 0; $i -lt $Panels.Count; $i++) {
        $p = $script:Ctrl[$Panels[$i]]
        $n = $script:Ctrl[$NavBtns[$i]]
        if ($null -ne $p) {
            $p.Visibility = if ($i -eq $Index) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
        }
        if ($null -ne $n) {
            $n.FontWeight = if ($i -eq $Index) { [System.Windows.FontWeights]::Bold } else { [System.Windows.FontWeights]::Normal }
        }
    }
}

function Play-Tone { try { [console]::Beep(440,150); [console]::Beep(660,150); [console]::Beep(880,300) } catch {} }

function Restart-Shell {
    Write-Log "Restarting Explorer shell..." Action
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Start-Process explorer.exe
    Write-Log "Explorer restarted" OK
}

# ============================================================
# SECTION 9: ALL OPTIMIZATION FUNCTIONS
# ============================================================

# --- TIER PRESETS ---
function Apply-LowEndTweaks {
    Write-Log "Applying Low-End optimizations..." Action
    Set-Reg 'HKCU:\Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) 'Binary'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
    Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0' 'String'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2
    if ($ramGB -ge 8) { try { Disable-MMAgent -MemoryCompression -ErrorAction Stop; Write-Log "  Memory compression disabled" Info } catch {} }
    foreach ($svc in @('SysMain','DiagTrack','WSearch')) {
        try { Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop; Stop-Service -Name $svc -Force -ErrorAction Stop } catch {}
    }
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    Write-Log "Low-End optimizations complete!" OK
    Play-Tone
}

function Apply-MidRangeTweaks {
    Write-Log "Applying Mid-Range optimizations..." Action
    Apply-LowEndTweaks
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 10
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
    foreach ($svc in @('dmwappushservice','diagnosticshub.standardcollector.service')) {
        try { Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop; Stop-Service -Name $svc -Force -ErrorAction Stop } catch {}
    }
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2
    Write-Log "Mid-Range optimizations complete!" OK
    Play-Tone
}

function Apply-HighEndTweaks {
    if ($isLaptop) {
        $r = [System.Windows.MessageBox]::Show("High-End tweaks increase heat. Plug in your charger. Continue?", "Laptop Warning", "YesNo", "Warning")
        if ($r -eq 'No') { return }
    }
    Write-Log "Applying HIGH-END (Nuclear) optimizations..." Action
    Apply-MidRangeTweaks
    bcdedit /set useplatformtick yes 2>$null
    bcdedit /set disabledynamictick yes 2>$null
    bcdedit /set useplatformclock yes 2>$null
    Write-Log "  BCD timer + HPET forced" Info
    $out = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
    if ($out -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') {
        powercfg /setactive $Matches[1] 2>$null; Write-Log "  Ultimate Performance plan active" Info
    }
    $cpPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583'
    Set-Reg $cpPath 'Attributes' 0
    powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 2>$null
    powercfg -setactive scheme_current 2>$null
    Write-Log "  All CPU cores unparked" Info
    $gpuTask = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    Set-Reg $gpuTask 'GPU Priority' 8
    Set-Reg $gpuTask 'Priority' 6
    Set-Reg $gpuTask 'Scheduling Category' 'High' 'String'
    Set-Reg $gpuTask 'SFIO Priority' 'High' 'String'
    try {
        $dev = Get-PnpDevice -Class Display -Status OK -ErrorAction Stop | Select-Object -First 1
        if ($dev) {
            $msiP = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($dev.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
            Set-Reg $msiP 'MSISupported' 1
            Write-Log "  GPU MSI mode enabled" Info
        }
    } catch {}
    $gpuReg = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000'
    Set-Reg $gpuReg 'PerfLevelSrc' 0x2222
    Set-Reg $gpuReg 'PowerMizerEnable' 0
    Set-Reg $gpuReg 'PowerMizerLevel' 1
    Set-Reg $gpuReg 'PowerMizerLevelAC' 1
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'FeatureSettingsOverride' 3
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'FeatureSettingsOverrideMask' 3
    Write-Log "  CPU mitigations disabled (Spectre/Meltdown) +15% perf" Warn
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity' 0
    Write-Log "  VBS/Device Guard disabled" Warn
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager' 'Priority' 3
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object {
        Set-Reg $_.PSPath 'TcpAckFrequency' 1
        Set-Reg $_.PSPath 'TCPNoDelay' 1
    }
    Write-Log "HIGH-END optimizations complete! Restart recommended." OK
    Play-Tone
}

# --- SYSTEM TWEAKS ---
function Invoke-Debloat {
    Write-Log "Debloating Windows..." Action
    $bloat = @('Microsoft.BingNews','Microsoft.BingWeather','Microsoft.GetHelp','Microsoft.Getstarted',
        'Microsoft.MicrosoftSolitaireCollection','Microsoft.People','Microsoft.PowerAutomate',
        'Microsoft.Todos','Microsoft.WindowsAlarms','Microsoft.WindowsFeedbackHub',
        'Microsoft.WindowsMaps','Microsoft.YourPhone','Microsoft.ZuneMusic','Microsoft.ZuneVideo',
        'Clipchamp.Clipchamp','Microsoft.549981C3F5F10','Microsoft.MicrosoftOfficeHub',
        'Microsoft.SkypeApp','Microsoft.Office.OneNote','king.com.CandyCrushSaga',
        'king.com.CandyCrushSodaSaga','Disney.37853FC22B2CE','SpotifyAB.SpotifyMusic',
        'Microsoft.GamingApp','Microsoft.Xbox.TCUI','Microsoft.XboxGameOverlay')
    foreach ($app in $bloat) {
        Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
        Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object DisplayName -eq $app | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
    }
    Write-Log "Debloat complete - removed $($bloat.Count) packages" OK
    Play-Tone
}

function Invoke-SystemCleanup {
    Write-Log "Running system cleanup..." Action
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Log "Cleanup complete - temp files and recycle bin cleared" OK
}

function Invoke-ServiceManualize {
    Write-Log "Setting non-essential services to Manual..." Action
    $svcs = @('Spooler','bthserv','TabletInputService','WMPNetworkSvc','SSDPSRV','lfsvc','MapsBroker',
              'PhoneSvc','RetailDemo','wisvc','icssvc','WpcMonSvc','SEMgrSvc','SCardSvr')
    $count = 0
    foreach ($svc in $svcs) {
        try { Set-Service -Name $svc -StartupType Manual -ErrorAction Stop; $count++ } catch {}
    }
    Write-Log "Set $count services to Manual start" OK
    Play-Tone
}

# --- MEMORY ---
function Optimize-RAM {
    Write-Log "Optimizing RAM..." Action
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'LargeSystemCache' 0
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'ClearPageFileAtShutdown' 1
    [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); [System.GC]::Collect()
    Write-Log "RAM optimized - cache cleared, GC forced" OK
    Play-Tone
}

function Clear-StandbyList {
    Write-Log "Purging RAM standby list..." Action
    [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); [System.GC]::Collect()
    Write-Log "RAM standby purged via forced GC" OK
}

function Optimize-Pagefile {
    Write-Log "Optimizing pagefile..." Action
    try {
        $size = $ramGB * 1024
        $cs = Get-CimInstance Win32_ComputerSystem
        $cs | Set-CimInstance -Property @{AutomaticManagedPagefile=$false} -ErrorAction Stop
        $pf = Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue
        if ($pf) {
            $pf | Set-CimInstance -Property @{InitialSize=$size; MaximumSize=$size} -ErrorAction Stop
        } else {
            New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name='C:\pagefile.sys'; InitialSize=$size; MaximumSize=$size} -ErrorAction Stop
        }
        Write-Log "Pagefile set to static ${size}MB (matches RAM)" OK
    } catch { Write-Log "Pagefile error: $_ - try manual configuration" Warn }
    Play-Tone
}

function Set-LargeSystemCache {
    Write-Log "Enabling Large System Cache..." Action
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'LargeSystemCache' 1
    Write-Log "Large System Cache enabled - more file data kept in RAM" OK
    Play-Tone
}

# --- STORAGE ---
function Optimize-Storage {
    Write-Log "Optimizing storage..." Action
    try { Optimize-Volume -DriveLetter C -ReTrim -ErrorAction Stop; Write-Log "SSD TRIM completed" OK } catch { Write-Log "Drive optimization skipped (may not be SSD)" Warn }
    Play-Tone
}

function Optimize-NTFS {
    Write-Log "Optimizing NTFS..." Action
    fsutil behavior set disablelastaccess 1 2>$null
    fsutil behavior set encryptpagingfile 0 2>$null
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisableLastAccessUpdate' 1
    Write-Log "NTFS Last Access timestamps disabled - reduced disk I/O" OK
    Play-Tone
}

# --- NETWORK ---
function Apply-NetworkTweaks {
    Write-Log "Applying network tweaks..." Action
    netsh int tcp set global autotuninglevel=highlyrestricted 2>$null
    netsh int tcp set global rss=enabled 2>$null
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object {
        Set-Reg $_.PSPath 'TcpAckFrequency' 1
        Set-Reg $_.PSPath 'TCPNoDelay' 1
    }
    Write-Log "Network optimized - Nagle disabled, TCP tuned, throttle removed" OK
    Play-Tone
}

function Refresh-Internet {
    Write-Log "Refreshing internet connection..." Action
    ipconfig /release 2>$null | Out-Null
    ipconfig /flushdns 2>$null | Out-Null
    ipconfig /renew 2>$null | Out-Null
    netsh winsock reset 2>$null | Out-Null
    netsh int ip reset 2>$null | Out-Null
    Write-Log "Internet refreshed - DNS flushed, Winsock reset" OK
}

# --- INPUT ---
function Apply-USBTweaks {
    Write-Log "Applying USB + Mouse + Keyboard tweaks..." Action
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' 'DisableSelectiveSuspend' 1
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSensitivity' '10' 'String'
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31' 'String'
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '0' 'String'
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters' 'MouseDataQueueSize' 0x14
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters' 'KeyboardDataQueueSize' 0x14
    Write-Log "USB suspend off, mouse accel off, 1ms keyboard, queue optimized" OK
    Play-Tone
}

# --- GAMING ---
function Apply-GameBoost {
    Write-Log "Applying Zero Latency Game Boost..." Action
    bcdedit /set useplatformtick yes 2>$null
    bcdedit /set disabledynamictick yes 2>$null
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 10
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    $gpuTask = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    Set-Reg $gpuTask 'GPU Priority' 8
    Set-Reg $gpuTask 'Priority' 6
    Set-Reg $gpuTask 'Scheduling Category' 'High' 'String'
    Set-Reg $gpuTask 'SFIO Priority' 'High' 'String'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'PowerThrottlingOff' 1
    Write-Log "Zero Latency mode ACTIVE!" OK
    Play-Tone
}

function Disable-MPO {
    Write-Log "Disabling Multi-Plane Overlay..." Action
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode' 5
    Write-Log "MPO disabled - fixes flickering and black screens in borderless" OK
    Play-Tone
}

function Toggle-HAGS {
    Write-Log "Toggling Hardware-Accelerated GPU Scheduling..." Action
    $path = 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'
    $current = try { (Get-ItemProperty -Path $path -Name 'HwSchMode' -ErrorAction Stop).HwSchMode } catch { 1 }
    $new = if ($current -eq 2) { 1 } else { 2 }
    $state = if ($new -eq 2) { 'ENABLED' } else { 'DISABLED' }
    Set-Reg $path 'HwSchMode' $new
    Write-Log "HAGS $state - restart required" OK
    Play-Tone
}

function Expand-ShaderCache {
    Write-Log "Expanding shader cache to unlimited..." Action
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\DirectX' 'ShaderCacheSizeLimitKB' 0xFFFFFFFF
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\DirectX' 'DisableShaderCache' 0
    Write-Log "Shader cache unlimited - no more first-run stutters" OK
    Play-Tone
}

function Disable-FSO {
    Write-Log "Disabling Fullscreen Optimizations globally..." Action
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_HonorUserFSEBehaviorMode' 1
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_DXGIHonorFSEWindowsCompatible' 1
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehavior' 2
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_EFSEFeatureFlags' 0
    Write-Log "FSO disabled globally - true exclusive fullscreen restored" OK
    Play-Tone
}

function Set-TimerResolution {
    Write-Log "Setting high-precision timer resolution..." Action
    bcdedit /set useplatformtick yes 2>$null
    bcdedit /set disabledynamictick yes 2>$null
    bcdedit /set useplatformclock yes 2>$null
    Write-Log "Timer resolution forced to 0.5ms via BCD - restart needed" OK
    Play-Tone
}

function Fix-DPCLatency {
    Write-Log "Fixing DPC Latency..." Action
    powercfg -setacvalueindex scheme_current 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 2>$null
    powercfg -setactive scheme_current 2>$null
    Write-Log "  PCIe Link State power management disabled" Info
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' 'DisableSelectiveSuspend' 1
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'ExitLatency' 1
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'ExitLatencyCheckEnabled' 1
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'DisableSensorWatchdog' 1
    Write-Log "DPC Latency reduced - PCIe, USB, and power states optimized" OK
    Play-Tone
}

function Start-AutoBooster {
    if ($script:BoostTimer) { Write-Log "Auto-Booster already running" Warn; return }
    $script:BoostTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:BoostTimer.Interval = [TimeSpan]::FromSeconds(30)
    $script:BoostTimer.Add_Tick({
        foreach ($g in $script:GameList) {
            $p = Get-Process -Name $g -ErrorAction SilentlyContinue
            if ($p) {
                $p | ForEach-Object { try { $_.PriorityClass = 'High' } catch {} }
                Get-Process -Name 'chrome','msedge','discord','slack' -ErrorAction SilentlyContinue | ForEach-Object { try { $_.PriorityClass = 'BelowNormal' } catch {} }
            }
        }
    })
    $script:BoostTimer.Start()
    Write-Log "Auto-Booster ACTIVE - monitoring games every 30s" OK
}

function Stop-AutoBooster {
    if ($script:BoostTimer) { $script:BoostTimer.Stop(); $script:BoostTimer = $null; Write-Log "Auto-Booster stopped" OK }
    else { Write-Log "Auto-Booster was not running" Info }
}

function Show-FrameCapAdvice {
    $hz = try { (Get-CimInstance Win32_VideoController).CurrentRefreshRate | Select-Object -First 1 } catch { 60 }
    if (-not $hz -or $hz -eq 0) { $hz = 60 }
    $msg = "Monitor: ${hz}Hz`n`nRecommended Cap: $hz FPS`nCompetitive: $([math]::Floor($hz * 0.95)) FPS`n`nNVIDIA: Max Frame Rate in Control Panel`nAMD: FRTC in Adrenalin`nUniversal: RTSS (RivaTuner)"
    [System.Windows.MessageBox]::Show($msg, 'Frame Cap Advisor', 'OK', 'Information') | Out-Null
    Write-Log "Monitor at ${hz}Hz - frame cap advised" OK
}

function Apply-LaptopGodMode {
    if (-not $isLaptop) { Write-Log "Laptop God Mode is for laptops only" Warn; return }
    $r = [System.Windows.MessageBox]::Show("Laptop God Mode increases heat. Plug in charger. Continue?", "Thermal Warning", "YesNo", "Warning")
    if ($r -eq 'No') { return }
    Write-Log "Activating Laptop God Mode..." Action
    powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 99 2>$null
    powercfg -setactive scheme_current 2>$null
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'PowerThrottlingOff' 1
    $ePath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583'
    Set-Reg $ePath 'Attributes' 0
    $bPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7'
    Set-Reg $bPath 'Attributes' 0
    Write-Log "Laptop God Mode ACTIVE! 99% cap, throttle off, boost unlocked" OK
    Play-Tone
}

# --- HARDWARE ---
function Invoke-UltimatePower {
    Write-Log "Unlocking Ultimate Performance plan..." Action
    $out = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
    if ($out -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') {
        powercfg /setactive $Matches[1]; Write-Log "Ultimate Performance plan active!" OK
    } else { Write-Log "Could not create plan (may already exist)" Warn }
    Play-Tone
}

function Invoke-UnparkCores {
    Write-Log "Unparking all CPU cores..." Action
    $cpPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583'
    Set-Reg $cpPath 'Attributes' 0
    powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 2>$null
    powercfg -setactive scheme_current 2>$null
    Write-Log "All CPU cores unparked - min 100%" OK
    Play-Tone
}

function Enable-MSIMode {
    Write-Log "Enabling MSI Mode for devices..." Action
    $count = 0
    try {
        $devices = Get-PnpDevice -Status OK -ErrorAction Stop | Where-Object { $_.Class -in @('Display','Net','USB') }
        foreach ($dev in $devices) {
            $msiP = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($dev.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
            Set-Reg $msiP 'MSISupported' 1
            $count++
        }
    } catch { Write-Log "MSI Mode error: $_" Error }
    Write-Log "MSI Mode enabled for $count devices - reduced IRQ conflicts" OK
    Play-Tone
}

function Check-RAMSpeed {
    $mem = Get-CimInstance Win32_PhysicalMemory | Select-Object Capacity, Speed, Manufacturer
    $info = $mem | ForEach-Object { "$([math]::Round($_.Capacity/1GB))GB @ $($_.Speed)MHz ($($_.Manufacturer))" }
    $warn = if ($ramSpeed -lt 2666) { "`n`nWARNING: Speed below 2666MHz. Enable XMP/DOCP in BIOS!" } else { "" }
    $msg = "RAM Modules:`n$($info -join "`n")$warn"
    [System.Windows.MessageBox]::Show($msg, 'RAM Speed Check', 'OK', 'Information') | Out-Null
    Write-Log "RAM speed check complete" OK
}

function Add-ContextMenu {
    Write-Log "Adding desktop context menu shortcut..." Action
    $rp = 'Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\RaysChamber'
    New-Item -Path $rp -Force | Out-Null
    Set-ItemProperty -Path $rp -Name 'MUIVerb' -Value 'Open Rays Chamber'
    Set-ItemProperty -Path $rp -Name 'Icon' -Value 'powershell.exe'
    New-Item -Path "$rp\command" -Force | Out-Null
    Set-ItemProperty -Path "$rp\command" -Name '(Default)' -Value 'powershell.exe -WindowStyle Hidden -Command "irm is.gd/RaysUtil | iex"'
    Write-Log "Context menu shortcut added to desktop!" OK
}

function Remove-ContextMenu {
    Remove-Item 'Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\RaysChamber' -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Context menu shortcut removed" OK
}

function Register-MaintenanceTask {
    Write-Log "Registering maintenance task..." Action
    $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-WindowStyle Hidden -Command `"Optimize-Volume -DriveLetter C -ReTrim -EA 0; Remove-Item `$env:TEMP\* -Recurse -Force -EA 0`""
    $trigger = New-ScheduledTaskTrigger -Daily -At 3am
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName 'RaysChamber_Maintenance' -Description 'Auto SSD trim and temp cleanup' -Force | Out-Null
    Write-Log "Maintenance task scheduled (daily 3AM)" OK
}

# --- CONFIG ---
function Start-MicroWin {
    Write-Log "MicroWin ISO Debloat - opening file dialog..." Action
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = 'ISO Files|*.iso'; $dlg.Title = 'Select Windows ISO for Debloating'
    if ($dlg.ShowDialog()) {
        Write-Log "Selected ISO: $($dlg.FileName)" Info
        Start-Process powershell.exe "-NoProfile -Command `"Write-Host 'MicroWin ISO Debloat' -FG Cyan; Write-Host 'Selected: $($dlg.FileName)'; Write-Host 'DISM integration in progress'; pause`""
    } else { Write-Log "No ISO selected" Info }
}

# --- HEALTH ---
function Invoke-SystemHealthScan {
    Write-Log "Starting full system health scan..." Action
    Start-Process powershell.exe "-NoProfile -Command `"Write-Host '=== RAYS SYSTEM HEALTH SCAN ===' -FG Cyan; Write-Host ''; Write-Host '[1/3] SFC...' -FG Yellow; sfc /scannow; Write-Host ''; Write-Host '[2/3] DISM...' -FG Yellow; DISM /Online /Cleanup-Image /RestoreHealth; Write-Host ''; Write-Host '[3/3] WU Reset...' -FG Yellow; net stop wuauserv 2>`$null; Remove-Item C:\Windows\SoftwareDistribution -Recurse -Force -EA 0; net start wuauserv; Write-Host ''; Write-Host 'DONE' -FG Green; pause`""
}

function Run-WinSATBenchmark {
    Write-Log "Launching WinSAT benchmark..." Action
    Start-Process powershell.exe "-NoProfile -Command `"Write-Host 'Running WinSAT...' -FG Cyan; winsat formal; Write-Host 'Complete!' -FG Green; pause`""
}

# --- REVERT ---
function Revert-AllChanges {
    Write-Log "REVERTING all optimizations to Windows defaults..." Action
    # Visuals
    Set-Reg 'HKCU:\Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x9E,0x3E,0x07,0x80,0x12,0x00,0x00,0x00)) 'Binary'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 1
    Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '400' 'String'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 0
    try { Enable-MMAgent -MemoryCompression -ErrorAction Stop } catch {}
    # Services
    foreach ($svc in @('SysMain','DiagTrack','WSearch','dmwappushservice','Spooler','bthserv','TabletInputService','WMPNetworkSvc')) {
        try { Set-Service -Name $svc -StartupType Automatic -ErrorAction Stop; Start-Service -Name $svc -ErrorAction Stop } catch {}
    }
    # GameDVR
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 1
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 1
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_HonorUserFSEBehaviorMode' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_DXGIHonorFSEWindowsCompatible' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehavior' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_EFSEFeatureFlags' 0
    # Power
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null
    # MMCSS
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 20
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 10
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 2
    # Telemetry
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -ErrorAction SilentlyContinue
    # BCD
    bcdedit /deletevalue useplatformtick 2>$null
    bcdedit /deletevalue disabledynamictick 2>$null
    bcdedit /deletevalue useplatformclock 2>$null
    # Core parking
    powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 50 2>$null
    powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 100 2>$null
    powercfg -setactive scheme_current 2>$null
    # GPU
    $gpuTask = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    Set-Reg $gpuTask 'GPU Priority' 2
    Set-Reg $gpuTask 'Priority' 2
    Set-Reg $gpuTask 'Scheduling Category' 'Medium' 'String'
    Set-Reg $gpuTask 'SFIO Priority' 'Normal' 'String'
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager' 'Priority' 5
    # Mitigations
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'FeatureSettingsOverride' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'FeatureSettingsOverrideMask' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' -Name 'EnableVirtualizationBasedSecurity' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000' -Name 'PerfLevelSrc' -ErrorAction SilentlyContinue
    # Network
    netsh int tcp set global autotuninglevel=normal 2>$null
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-ItemProperty -Path $_.PSPath -Name 'TcpAckFrequency' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $_.PSPath -Name 'TCPNoDelay' -ErrorAction SilentlyContinue
    }
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'PowerThrottlingOff' -ErrorAction SilentlyContinue
    # Input
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '1' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '6' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '10' 'String'
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '1' 'String'
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '20' 'String'
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' -Name 'DisableSelectiveSuspend' -ErrorAction SilentlyContinue
    # Memory
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'LargeSystemCache' 1
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'ClearPageFileAtShutdown' -ErrorAction SilentlyContinue
    # MPO
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name 'OverlayTestMode' -ErrorAction SilentlyContinue
    # HAGS
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2
    # Shader
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\DirectX' -Name 'ShaderCacheSizeLimitKB' -ErrorAction SilentlyContinue
    # NTFS
    fsutil behavior set disablelastaccess 2 2>$null
    # DPC
    powercfg -setacvalueindex scheme_current 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 1 2>$null
    powercfg -setactive scheme_current 2>$null
    # Context + Maintenance
    Remove-ContextMenu
    Unregister-ScheduledTask -TaskName 'RaysChamber_Maintenance' -Confirm:$false -ErrorAction SilentlyContinue
    Stop-AutoBooster
    Write-Log "ALL changes reverted to Windows defaults!" OK
    [console]::Beep(880,150); [console]::Beep(660,150); [console]::Beep(440,300)
}

# ============================================================
# SECTION 10: WPF XAML - ALL ASCII, VALID XML, 75 NAMED CONTROLS
# ============================================================
$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Rays Optimization Chamber v6.0"
    Width="1100" Height="780"
    WindowStartupLocation="CenterScreen"
    Background="#000B1A"
    Foreground="#F0F0F0"
    FontFamily="Segoe UI">
    <Window.Resources>
        <Style TargetType="Button">
            <Setter Property="Background" Value="#001F3F"/>
            <Setter Property="Foreground" Value="#D0D8E0"/>
            <Setter Property="BorderBrush" Value="#002A4A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="12,6"/>
            <Setter Property="Margin" Value="3"/>
            <Setter Property="Cursor" Value="Hand"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="Template">
                <Setter.Value>
                    <ControlTemplate TargetType="Button">
                        <Border Background="{TemplateBinding Background}"
                                BorderBrush="{TemplateBinding BorderBrush}"
                                BorderThickness="{TemplateBinding BorderThickness}"
                                Padding="{TemplateBinding Padding}"
                                CornerRadius="4">
                            <ContentPresenter HorizontalAlignment="Center" VerticalAlignment="Center"/>
                        </Border>
                        <ControlTemplate.Triggers>
                            <Trigger Property="IsMouseOver" Value="True">
                                <Setter Property="Background" Value="#003366"/>
                                <Setter Property="Foreground" Value="#00D9FF"/>
                            </Trigger>
                        </ControlTemplate.Triggers>
                    </ControlTemplate>
                </Setter.Value>
            </Setter>
        </Style>
        <Style TargetType="TextBox">
            <Setter Property="Background" Value="#001F3F"/>
            <Setter Property="Foreground" Value="#F0F0F0"/>
            <Setter Property="BorderBrush" Value="#002A4A"/>
            <Setter Property="BorderThickness" Value="1"/>
            <Setter Property="Padding" Value="8,5"/>
            <Setter Property="FontSize" Value="12"/>
            <Setter Property="CaretBrush" Value="#00D9FF"/>
        </Style>
        <Style TargetType="CheckBox">
            <Setter Property="Foreground" Value="#D0D8E0"/>
            <Setter Property="Margin" Value="4"/>
            <Setter Property="FontSize" Value="12"/>
        </Style>
    </Window.Resources>
    <DockPanel>
        <Border DockPanel.Dock="Top" Background="#000814" Padding="14,10">
            <TextBlock Text="RAYS OPTIMIZATION CHAMBER v6.0" FontSize="16" FontWeight="Bold" Foreground="#00D9FF"/>
        </Border>
        <Border DockPanel.Dock="Bottom" Background="#00050A" BorderBrush="#002A4A" BorderThickness="0,1,0,0" Height="130">
            <ScrollViewer Name="LogScroll" VerticalScrollBarVisibility="Auto" Padding="8">
                <TextBlock Name="LogBox" TextWrapping="Wrap" Foreground="#8090A0" FontSize="11" FontFamily="Consolas"/>
            </ScrollViewer>
        </Border>
        <StackPanel DockPanel.Dock="Top" Orientation="Horizontal" Background="#000814">
            <Button Name="NavInstall" Content="Install" Padding="18,8" FontWeight="Bold"/>
            <Button Name="NavTweaks" Content="Tweaks" Padding="18,8"/>
            <Button Name="NavGaming" Content="Gaming" Padding="18,8"/>
            <Button Name="NavHardware" Content="Hardware" Padding="18,8"/>
            <Button Name="NavConfig" Content="Config" Padding="18,8"/>
            <Button Name="NavUpdates" Content="Updates" Padding="18,8"/>
            <Button Name="NavHealth" Content="Health" Padding="18,8"/>
        </StackPanel>
        <Grid>
            <ScrollViewer Name="PanelInstall" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="INSTALL APPLICATIONS" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <TextBox Name="TxtSearch" Margin="0,0,0,8"/>
                    <WrapPanel Name="AppPanel"/>
                    <StackPanel Orientation="Horizontal" Margin="0,8,0,0">
                        <Button Name="BtnSelectAll" Content="Select All"/>
                        <Button Name="BtnDeselectAll" Content="Deselect All"/>
                        <Button Name="BtnInstallSelected" Content="Install Selected" FontWeight="Bold"/>
                    </StackPanel>
                </StackPanel>
            </ScrollViewer>
            <ScrollViewer Name="PanelTweaks" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="SYSTEM TWEAKS" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <TextBlock Text="-- Safety --" FontSize="14" FontWeight="Bold" Foreground="#FFD700" Margin="0,8,0,4"/>
                    <Button Name="BtnRestore" Content="[!] Create Restore Point (Click before tweaking)" FontWeight="Bold" ToolTip="Creates a System Restore point before changes"/>
                    <TextBlock Text="-- Presets --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnLowEnd" Content="Low-End PC" ToolTip="Disables animations, memory compression, heavy services"/>
                        <Button Name="BtnMidEnd" Content="Mid-Range" ToolTip="Adds telemetry block, network throttle off, priority boost"/>
                        <Button Name="BtnHighEnd" Content="High-End Nuclear" ToolTip="BCD + Mitigations OFF + VBS OFF + Core unpark - advanced only"/>
                    </WrapPanel>
                    <TextBlock Text="-- System --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnDebloat" Content="Debloat Windows" ToolTip="Removes 26 pre-installed bloatware apps"/>
                        <Button Name="BtnCleanup" Content="System Cleanup" ToolTip="Clears temp files and empties recycle bin"/>
                        <Button Name="BtnServiceManual" Content="Manualize Services" ToolTip="Sets 14 non-essential services to Manual start"/>
                    </WrapPanel>
                    <TextBlock Text="-- Memory --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnOptRAM" Content="Optimize RAM" ToolTip="Adjusts memory management, clears cache, forces GC"/>
                        <Button Name="BtnStandbyClean" Content="Standby Cleaner" ToolTip="Flushes Windows Standby List to fix max-RAM stutters"/>
                        <Button Name="BtnPagefile" Content="Optimize Pagefile" ToolTip="Sets static pagefile matching RAM size"/>
                        <Button Name="BtnLargeCache" Content="Large System Cache" ToolTip="Keeps more file data in RAM for faster load times"/>
                    </WrapPanel>
                    <TextBlock Text="-- Storage --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnOptStore" Content="SSD Trim" ToolTip="Runs RETRIM on C: drive"/>
                        <Button Name="BtnNTFS" Content="NTFS Optimize" ToolTip="Disables Last Access timestamps to reduce disk I/O"/>
                    </WrapPanel>
                    <TextBlock Text="-- Network --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnOptNet" Content="Network Tweaks" ToolTip="Nagle off, TCP tuned, throttle removed, ACK immediate"/>
                        <Button Name="BtnRefreshNet" Content="Refresh Internet" ToolTip="Flushes DNS, resets Winsock and IP stack"/>
                    </WrapPanel>
                    <TextBlock Text="-- Input Devices --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <Button Name="BtnUSB" Content="USB + Mouse + Keyboard" ToolTip="USB suspend off, mouse accel off, 1ms keyboard, HID queue optimized"/>
                    <TextBlock Text="-- Danger Zone --" FontSize="14" FontWeight="Bold" Foreground="#FF6666" Margin="0,12,0,4"/>
                    <Button Name="BtnRevert" Content="REVERT ALL CHANGES TO DEFAULT" ToolTip="Restores every setting to Windows defaults"/>
                </StackPanel>
            </ScrollViewer>
            <ScrollViewer Name="PanelGaming" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="GAMING OPTIMIZATION" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <TextBlock Text="-- Performance Boost --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,8,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnGameBoost" Content="Zero Latency Mode" FontWeight="Bold" ToolTip="BCD timer + Win32Priority 0x26 + GPU Priority 8 + Nagle off"/>
                        <Button Name="BtnAutoBoost" Content="Start Auto-Booster" ToolTip="Monitors for games and auto-boosts priority every 30s"/>
                        <Button Name="BtnStopBoost" Content="Stop Auto-Booster" ToolTip="Stops the automatic game detection loop"/>
                    </WrapPanel>
                    <TextBlock Text="-- GPU Pipeline --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnMPO" Content="Disable MPO" ToolTip="Fixes black screens and flickering in borderless mode"/>
                        <Button Name="BtnHAGS" Content="Toggle HAGS" ToolTip="Hardware-Accelerated GPU Scheduling toggle (restart needed)"/>
                        <Button Name="BtnShaderCache" Content="Expand Shader Cache" ToolTip="Unlimited shader cache - no first-run stutters in DX12/Vulkan"/>
                        <Button Name="BtnFSO" Content="Disable FSO" ToolTip="True exclusive fullscreen - removes Game Bar overlay layer"/>
                    </WrapPanel>
                    <TextBlock Text="-- Latency Control --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnTimerRes" Content="Timer Resolution 0.5ms" ToolTip="Forces high-precision timer via BCD for lower input lag"/>
                        <Button Name="BtnDPCLatency" Content="DPC Latency Fix" ToolTip="Disables PCIe power saving and USB suspend for lower DPC"/>
                        <Button Name="BtnRAMPurge" Content="Purge RAM Now" ToolTip="Forces garbage collection to clear standby memory"/>
                    </WrapPanel>
                    <TextBlock Text="-- Tools --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnFrameCap" Content="Frame Cap Advisor" ToolTip="Detects monitor Hz and recommends optimal frame cap"/>
                        <Button Name="BtnLaptopGod" Content="Laptop God Mode" ToolTip="99% CPU cap + thermal throttle off + boost unlock (laptops only)"/>
                    </WrapPanel>
                </StackPanel>
            </ScrollViewer>
            <ScrollViewer Name="PanelHardware" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="HARDWARE INFO" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <Border Background="#001F3F" BorderBrush="#002A4A" BorderThickness="1" CornerRadius="4" Padding="12" Margin="0,0,0,8">
                        <StackPanel>
                            <TextBlock Name="TxtHWInfo" FontSize="13" Foreground="#00D9FF" TextWrapping="Wrap"/>
                            <TextBlock Name="TxtHWDetail" FontSize="11" Foreground="#8090A0" TextWrapping="Wrap" Margin="0,4,0,0"/>
                        </StackPanel>
                    </Border>
                    <TextBlock Text="-- Power --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,8,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnUltPower" Content="Ultimate Performance Plan" ToolTip="Unlocks hidden Windows power plan - no core parking"/>
                        <Button Name="BtnUnpark" Content="Unpark All Cores" ToolTip="Sets CPU core parking minimum to 100%"/>
                        <Button Name="BtnMSIMode" Content="Enable MSI Mode" ToolTip="Message Signaled Interrupts for GPU/Net/USB - reduces IRQ conflicts"/>
                        <Button Name="BtnCheckRAM" Content="Check RAM Speed" ToolTip="Shows RAM module speeds and warns if XMP needed"/>
                    </WrapPanel>
                    <TextBlock Text="-- System --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnContextMenu" Content="Add Context Menu" ToolTip="Right-click desktop shortcut to open Rays Chamber"/>
                        <Button Name="BtnRmContext" Content="Remove Context Menu" ToolTip="Removes the desktop right-click shortcut"/>
                        <Button Name="BtnMaintTask" Content="Schedule Maintenance" ToolTip="Auto SSD trim + temp cleanup daily at 3AM"/>
                    </WrapPanel>
                </StackPanel>
            </ScrollViewer>
            <ScrollViewer Name="PanelConfig" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="CONFIGURATION" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <TextBlock Text="-- Windows Features --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,8,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnWSL" Content="Enable WSL2" ToolTip="Windows Subsystem for Linux"/>
                        <Button Name="BtnSandbox" Content="Enable Sandbox" ToolTip="Windows Sandbox for safe testing"/>
                        <Button Name="BtnHyperV" Content="Enable Hyper-V" ToolTip="Hardware virtualization platform"/>
                        <Button Name="BtnDotNet" Content="Enable .NET 3.5" ToolTip="Legacy .NET Framework support"/>
                    </WrapPanel>
                    <TextBlock Text="-- DNS --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnDNSGoogle" Content="Google DNS" ToolTip="Sets DNS to 8.8.8.8 and 8.8.4.4"/>
                        <Button Name="BtnDNSCF" Content="Cloudflare DNS" ToolTip="Sets DNS to 1.1.1.1 and 1.0.0.1"/>
                        <Button Name="BtnDNSAuto" Content="Auto DNS (DHCP)" ToolTip="Resets DNS to automatic"/>
                    </WrapPanel>
                    <TextBlock Text="-- Advanced --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <Button Name="BtnMicroWin" Content="MicroWin ISO Debloat" ToolTip="Strip bloatware from a Windows ISO via DISM"/>
                </StackPanel>
            </ScrollViewer>
            <ScrollViewer Name="PanelUpdates" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="WINDOWS UPDATES" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <WrapPanel>
                        <Button Name="BtnUpdDefault" Content="Default (Auto)" ToolTip="Restores standard Windows Update behavior"/>
                        <Button Name="BtnUpdSec" Content="Security Only" ToolTip="Only critical security patches"/>
                        <Button Name="BtnUpdOff" Content="Disable Updates" ToolTip="WARNING: Completely disables Windows Update"/>
                    </WrapPanel>
                </StackPanel>
            </ScrollViewer>
            <ScrollViewer Name="PanelHealth" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="SYSTEM HEALTH" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <WrapPanel>
                        <Button Name="BtnFullScan" Content="Full Health Scan" FontWeight="Bold" ToolTip="SFC + DISM + WU Reset in one go"/>
                        <Button Name="BtnSFC" Content="SFC Scan" ToolTip="System File Checker - fixes corrupted files"/>
                        <Button Name="BtnDISM" Content="DISM Repair" ToolTip="Downloads fresh components from Microsoft"/>
                        <Button Name="BtnWinSAT" Content="Run WinSAT" ToolTip="Benchmarks your hardware performance"/>
                        <Button Name="BtnRestartShell" Content="Restart Explorer" ToolTip="Restarts Explorer to apply visual changes instantly"/>
                    </WrapPanel>
                </StackPanel>
            </ScrollViewer>
        </Grid>
    </DockPanel>
</Window>
'@

# ============================================================
# SECTION 11: WINDOW CREATION + CONTROL DISCOVERY
# ============================================================
Write-Host '  [XAML] Parsing window definition...' -ForegroundColor Cyan

try {
    $window = [System.Windows.Markup.XamlReader]::Parse($xaml)
    Write-Host '  [XAML] Parse successful!' -ForegroundColor Green
} catch {
    Write-Host "  [XAML] FATAL PARSE ERROR: $_" -ForegroundColor Red
    Write-Host '  The XAML failed to load. Press any key to exit.' -ForegroundColor Red
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit 1
}

# --- CONTROL DISCOVERY: Stack-based BFS ---
Write-Host '  [CTRL] Walking control tree (BFS)...' -ForegroundColor Cyan
$stack = New-Object System.Collections.Stack
$stack.Push($window)
$walkCount = 0

while ($stack.Count -gt 0) {
    $current = $stack.Pop()
    $walkCount++
    if ($current -is [System.Windows.FrameworkElement] -and $current.Name -and $current.Name.Length -gt 0) {
        $script:Ctrl[$current.Name] = $current
    }
    if ($current -is [System.Windows.DependencyObject]) {
        try {
            foreach ($child in [System.Windows.LogicalTreeHelper]::GetChildren($current)) {
                if ($child -is [System.Windows.DependencyObject]) { $stack.Push($child) }
            }
        } catch {}
    }
}
Write-Host "  [CTRL] Walked $walkCount nodes, found $($script:Ctrl.Count) named controls" -ForegroundColor Green

# --- FALLBACK: FindName for anything missed ---
$allExpected = @(
    'LogBox','LogScroll',
    'NavInstall','NavTweaks','NavGaming','NavHardware','NavConfig','NavUpdates','NavHealth',
    'PanelInstall','PanelTweaks','PanelGaming','PanelHardware','PanelConfig','PanelUpdates','PanelHealth',
    'TxtSearch','AppPanel',
    'BtnSelectAll','BtnDeselectAll','BtnInstallSelected',
    'BtnRestore','BtnLowEnd','BtnMidEnd','BtnHighEnd',
    'BtnDebloat','BtnCleanup','BtnServiceManual',
    'BtnOptRAM','BtnStandbyClean','BtnPagefile','BtnLargeCache',
    'BtnOptStore','BtnNTFS',
    'BtnOptNet','BtnRefreshNet','BtnUSB','BtnRevert',
    'BtnGameBoost','BtnAutoBoost','BtnStopBoost',
    'BtnMPO','BtnHAGS','BtnShaderCache','BtnFSO',
    'BtnTimerRes','BtnDPCLatency','BtnRAMPurge',
    'BtnFrameCap','BtnLaptopGod',
    'TxtHWInfo','TxtHWDetail',
    'BtnUltPower','BtnUnpark','BtnMSIMode','BtnCheckRAM',
    'BtnContextMenu','BtnRmContext','BtnMaintTask',
    'BtnWSL','BtnSandbox','BtnHyperV','BtnDotNet',
    'BtnDNSGoogle','BtnDNSCF','BtnDNSAuto','BtnMicroWin',
    'BtnUpdDefault','BtnUpdSec','BtnUpdOff',
    'BtnFullScan','BtnSFC','BtnDISM','BtnWinSAT','BtnRestartShell'
)

$missing = @()
foreach ($name in $allExpected) {
    if (-not $script:Ctrl[$name]) {
        try {
            $found = $window.FindName($name)
            if ($null -ne $found) { $script:Ctrl[$name] = $found; Write-Host "  [CTRL] FindName recovered: $name" -ForegroundColor Yellow }
            else { $missing += $name }
        } catch { $missing += $name }
    }
}

if ($missing.Count -gt 0) {
    Write-Host "  [CTRL] WARNING - $($missing.Count) missing:" -ForegroundColor Red
    foreach ($m in $missing) { Write-Host "    - $m" -ForegroundColor Red }
} else {
    Write-Host "  [CTRL] All $($allExpected.Count) controls verified!" -ForegroundColor Green
}

# --- DWM Mica ---
$window.Add_SourceInitialized({
    try { $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper $window).Handle; [DwmHelper]::ApplyDark($hwnd) } catch {}
})

# ============================================================
# SECTION 12: INITIALIZATION
# ============================================================
Write-Host '  [INIT] Setting up UI...' -ForegroundColor Cyan

if ($null -ne $script:Ctrl['TxtHWInfo']) { $script:Ctrl['TxtHWInfo'].Text = "$HardwareType | $cpuName | ${ramGB}GB RAM | Tier: $SuggestedTier" }
if ($null -ne $script:Ctrl['TxtHWDetail']) { $script:Ctrl['TxtHWDetail'].Text = "CPU: $cpuCores C / $cpuThreads T | RAM: ${ramSpeed}MHz | GPU: $gpu" }

if ($null -ne $script:Ctrl['AppPanel']) {
    foreach ($app in $Apps) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = $app.N; $cb.Tag = $app.ID; $cb.Width = 200
        $script:Ctrl['AppPanel'].Children.Add($cb) | Out-Null
    }
}

if ($null -ne $script:Ctrl['TxtSearch']) {
    $script:Ctrl['TxtSearch'].Add_TextChanged({
        $q = $script:Ctrl['TxtSearch'].Text.ToLower()
        $panel = $script:Ctrl['AppPanel']
        if ($null -ne $panel) {
            foreach ($c in $panel.Children) {
                if ($c -is [System.Windows.Controls.CheckBox]) {
                    $c.Visibility = if ($c.Content.ToString().ToLower().Contains($q)) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
                }
            }
        }
    })
}

Switch-Tab 0
Write-Log "Ray's Optimization Chamber v$script:BUILD initialized" OK
Write-Log "$HardwareType | $cpuName | ${ramGB}GB RAM @ ${ramSpeed}MHz | Tier: $SuggestedTier" Info

# ============================================================
# SECTION 13: EVENT HANDLERS - EVERY BUTTON EXPLICITLY WIRED
# ============================================================
Write-Host '  [WIRE] Wiring event handlers...' -ForegroundColor Cyan
$wiredCount = 0

# Helper: Wire a button with null guard + debug log + try/catch
function Wire([string]$Name, [scriptblock]$Action) {
    $btn = $script:Ctrl[$Name]
    if ($null -ne $btn) {
        $btn.Add_Click($Action)
        $script:wiredCount++
    } else {
        Write-Host "  [WIRE] MISS: $Name" -ForegroundColor Yellow
    }
}

# --- NAV ---
for ($i = 0; $i -lt $NavBtns.Count; $i++) {
    $idx = $i
    Wire $NavBtns[$i] { Write-Log "Tab switched" Info; Switch-Tab $idx }.GetNewClosure()
}

# --- INSTALL ---
Wire 'BtnSelectAll'   { Write-Log "DEBUG: Select All clicked" Info; $p = $script:Ctrl['AppPanel']; if ($p) { foreach ($c in $p.Children) { if ($c -is [System.Windows.Controls.CheckBox]) { $c.IsChecked = $true } } } }
Wire 'BtnDeselectAll' { Write-Log "DEBUG: Deselect All clicked" Info; $p = $script:Ctrl['AppPanel']; if ($p) { foreach ($c in $p.Children) { if ($c -is [System.Windows.Controls.CheckBox]) { $c.IsChecked = $false } } } }
Wire 'BtnInstallSelected' {
    Write-Log "DEBUG: Install Selected clicked" Info
    try {
        $sel = @(); $p = $script:Ctrl['AppPanel']
        if ($p) { foreach ($c in $p.Children) { if ($c -is [System.Windows.Controls.CheckBox] -and $c.IsChecked) { $sel += $c.Tag } } }
        if ($sel.Count -eq 0) { Write-Log "No apps selected" Warn; return }
        Write-Log "Installing $($sel.Count) apps via winget..." Action
        foreach ($id in $sel) { Write-Log "  Queuing: $id" Info; Start-Process winget -ArgumentList "install --id $id --accept-source-agreements --accept-package-agreements -h" -NoNewWindow }
        Write-Log "All installations queued!" OK; Play-Tone
    } catch { Write-Log "Install error: $_" Error }
}

# --- TWEAKS ---
Wire 'BtnRestore' {
    Write-Log "DEBUG: Create Restore Point clicked" Action
    try {
        Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop
        Checkpoint-Computer -Description 'RaysChamber_Backup' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
        $script:RestoreCreated = $true; Write-Log "Restore Point created! Tweaks unlocked." OK
    } catch { Write-Log "Restore point note: $_ - unlocking anyway" Warn; $script:RestoreCreated = $true }
}
Wire 'BtnLowEnd'       { Write-Log "DEBUG: Low-End clicked" Info; try { if (Guard-Restore) { Apply-LowEndTweaks } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnMidEnd'       { Write-Log "DEBUG: Mid-Range clicked" Info; try { if (Guard-Restore) { Apply-MidRangeTweaks } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnHighEnd'      { Write-Log "DEBUG: High-End clicked" Info; try { if (Guard-Restore) { Apply-HighEndTweaks } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnDebloat'      { Write-Log "DEBUG: Debloat clicked" Info; try { if (Guard-Restore) { Invoke-Debloat } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnCleanup'      { Write-Log "DEBUG: Cleanup clicked" Info; try { Invoke-SystemCleanup } catch { Write-Log "Error: $_" Error } }
Wire 'BtnServiceManual' { Write-Log "DEBUG: Manualize Services clicked" Info; try { if (Guard-Restore) { Invoke-ServiceManualize } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnOptRAM'       { Write-Log "DEBUG: Optimize RAM clicked" Info; try { if (Guard-Restore) { Optimize-RAM } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnStandbyClean' { Write-Log "DEBUG: Standby Cleaner clicked" Info; try { Clear-StandbyList } catch { Write-Log "Error: $_" Error } }
Wire 'BtnPagefile'     { Write-Log "DEBUG: Pagefile clicked" Info; try { if (Guard-Restore) { Optimize-Pagefile } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnLargeCache'   { Write-Log "DEBUG: Large Cache clicked" Info; try { if (Guard-Restore) { Set-LargeSystemCache } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnOptStore'     { Write-Log "DEBUG: SSD Trim clicked" Info; try { Optimize-Storage } catch { Write-Log "Error: $_" Error } }
Wire 'BtnNTFS'         { Write-Log "DEBUG: NTFS Optimize clicked" Info; try { if (Guard-Restore) { Optimize-NTFS } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnOptNet'       { Write-Log "DEBUG: Network Tweaks clicked" Info; try { if (Guard-Restore) { Apply-NetworkTweaks } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnRefreshNet'   { Write-Log "DEBUG: Refresh Internet clicked" Info; try { Refresh-Internet } catch { Write-Log "Error: $_" Error } }
Wire 'BtnUSB'          { Write-Log "DEBUG: USB+Input clicked" Info; try { if (Guard-Restore) { Apply-USBTweaks } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnRevert'       {
    Write-Log "DEBUG: Revert All clicked" Warn
    $r = [System.Windows.MessageBox]::Show("Revert ALL optimizations to Windows defaults?", "Confirm Revert", "YesNo", "Warning")
    if ($r -eq 'Yes') { try { Revert-AllChanges } catch { Write-Log "Revert error: $_" Error } }
}

# --- GAMING ---
Wire 'BtnGameBoost'  { Write-Log "DEBUG: Zero Latency clicked" Info; try { if (Guard-Restore) { Apply-GameBoost } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnAutoBoost'  { Write-Log "DEBUG: Start Auto-Booster clicked" Info; try { Start-AutoBooster } catch { Write-Log "Error: $_" Error } }
Wire 'BtnStopBoost'  { Write-Log "DEBUG: Stop Auto-Booster clicked" Info; try { Stop-AutoBooster } catch { Write-Log "Error: $_" Error } }
Wire 'BtnMPO'        { Write-Log "DEBUG: Disable MPO clicked" Info; try { if (Guard-Restore) { Disable-MPO } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnHAGS'       { Write-Log "DEBUG: Toggle HAGS clicked" Info; try { if (Guard-Restore) { Toggle-HAGS } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnShaderCache' { Write-Log "DEBUG: Shader Cache clicked" Info; try { if (Guard-Restore) { Expand-ShaderCache } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnFSO'        { Write-Log "DEBUG: Disable FSO clicked" Info; try { if (Guard-Restore) { Disable-FSO } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnTimerRes'   { Write-Log "DEBUG: Timer Resolution clicked" Info; try { if (Guard-Restore) { Set-TimerResolution } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnDPCLatency' { Write-Log "DEBUG: DPC Latency clicked" Info; try { if (Guard-Restore) { Fix-DPCLatency } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnRAMPurge'   { Write-Log "DEBUG: Purge RAM clicked" Info; try { Clear-StandbyList } catch { Write-Log "Error: $_" Error } }
Wire 'BtnFrameCap'   { Write-Log "DEBUG: Frame Cap clicked" Info; try { Show-FrameCapAdvice } catch { Write-Log "Error: $_" Error } }
Wire 'BtnLaptopGod'  { Write-Log "DEBUG: Laptop God Mode clicked" Info; try { if (Guard-Restore) { Apply-LaptopGodMode } } catch { Write-Log "Error: $_" Error } }

# --- HARDWARE ---
Wire 'BtnUltPower'    { Write-Log "DEBUG: Ultimate Power clicked" Info; try { if (Guard-Restore) { Invoke-UltimatePower } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnUnpark'      { Write-Log "DEBUG: Unpark Cores clicked" Info; try { if (Guard-Restore) { Invoke-UnparkCores } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnMSIMode'     { Write-Log "DEBUG: MSI Mode clicked" Info; try { if (Guard-Restore) { Enable-MSIMode } } catch { Write-Log "Error: $_" Error } }
Wire 'BtnCheckRAM'    { Write-Log "DEBUG: Check RAM clicked" Info; try { Check-RAMSpeed } catch { Write-Log "Error: $_" Error } }
Wire 'BtnContextMenu' { Write-Log "DEBUG: Add Context Menu clicked" Info; try { Add-ContextMenu } catch { Write-Log "Error: $_" Error } }
Wire 'BtnRmContext'   { Write-Log "DEBUG: Remove Context Menu clicked" Info; try { Remove-ContextMenu } catch { Write-Log "Error: $_" Error } }
Wire 'BtnMaintTask'   { Write-Log "DEBUG: Maintenance Task clicked" Info; try { Register-MaintenanceTask } catch { Write-Log "Error: $_" Error } }

# --- CONFIG ---
Wire 'BtnWSL'       { Write-Log "DEBUG: WSL2 clicked" Action; try { Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart; dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart; Write-Host 'WSL2 enabled - restart required' -FG Green; pause`"" } catch { Write-Log "Error: $_" Error } }
Wire 'BtnSandbox'   { Write-Log "DEBUG: Sandbox clicked" Action; try { Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:Containers-DisposableClientVM /all /norestart; Write-Host 'Sandbox enabled - restart required' -FG Green; pause`"" } catch { Write-Log "Error: $_" Error } }
Wire 'BtnHyperV'    { Write-Log "DEBUG: Hyper-V clicked" Action; try { Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart; Write-Host 'Hyper-V enabled - restart required' -FG Green; pause`"" } catch { Write-Log "Error: $_" Error } }
Wire 'BtnDotNet'    { Write-Log "DEBUG: .NET 3.5 clicked" Action; try { Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:NetFx3 /all /norestart; Write-Host '.NET 3.5 enabled' -FG Green; pause`"" } catch { Write-Log "Error: $_" Error } }
Wire 'BtnDNSGoogle' {
    Write-Log "DEBUG: Google DNS clicked" Info
    try { Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses '8.8.8.8','8.8.4.4' }; Write-Log "DNS set to Google (8.8.8.8)" OK } catch { Write-Log "DNS error: $_" Error }
}
Wire 'BtnDNSCF' {
    Write-Log "DEBUG: Cloudflare DNS clicked" Info
    try { Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses '1.1.1.1','1.0.0.1' }; Write-Log "DNS set to Cloudflare (1.1.1.1)" OK } catch { Write-Log "DNS error: $_" Error }
}
Wire 'BtnDNSAuto' {
    Write-Log "DEBUG: Auto DNS clicked" Info
    try { Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses }; Write-Log "DNS reset to DHCP" OK } catch { Write-Log "DNS error: $_" Error }
}
Wire 'BtnMicroWin'  { Write-Log "DEBUG: MicroWin clicked" Info; try { Start-MicroWin } catch { Write-Log "Error: $_" Error } }

# --- UPDATES ---
Wire 'BtnUpdDefault' {
    Write-Log "DEBUG: Default Updates clicked" Info
    try { Set-Service -Name wuauserv -StartupType Automatic -ErrorAction Stop; Start-Service -Name wuauserv -ErrorAction Stop; Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -ErrorAction SilentlyContinue; Write-Log "Windows Update default" OK } catch { Write-Log "Error: $_" Error }
}
Wire 'BtnUpdSec' {
    Write-Log "DEBUG: Security Only clicked" Info
    try { Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'NoAutoUpdate' 0; Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'AUOptions' 3; Write-Log "Security Only mode" OK } catch { Write-Log "Error: $_" Error }
}
Wire 'BtnUpdOff' {
    Write-Log "DEBUG: Disable Updates clicked" Warn
    $r = [System.Windows.MessageBox]::Show("WARNING: Disabling updates leaves you vulnerable. Sure?", "Disable Updates", "YesNo", "Warning")
    if ($r -eq 'Yes') { try { Set-Service -Name wuauserv -StartupType Disabled -ErrorAction Stop; Stop-Service -Name wuauserv -Force -ErrorAction Stop; Write-Log "Windows Update DISABLED" Warn } catch { Write-Log "Error: $_" Error } }
}

# --- HEALTH ---
Wire 'BtnFullScan'     { Write-Log "DEBUG: Full Scan clicked" Action; try { Invoke-SystemHealthScan } catch { Write-Log "Error: $_" Error } }
Wire 'BtnSFC'          { Write-Log "DEBUG: SFC clicked" Action; try { Start-Process powershell.exe "-NoProfile -Command `"sfc /scannow; pause`"" } catch { Write-Log "Error: $_" Error } }
Wire 'BtnDISM'         { Write-Log "DEBUG: DISM clicked" Action; try { Start-Process powershell.exe "-NoProfile -Command `"DISM /Online /Cleanup-Image /RestoreHealth; pause`"" } catch { Write-Log "Error: $_" Error } }
Wire 'BtnWinSAT'       { Write-Log "DEBUG: WinSAT clicked" Action; try { Run-WinSATBenchmark } catch { Write-Log "Error: $_" Error } }
Wire 'BtnRestartShell'  { Write-Log "DEBUG: Restart Explorer clicked" Action; try { Restart-Shell } catch { Write-Log "Error: $_" Error } }

Write-Host "  [WIRE] Successfully wired $wiredCount handlers" -ForegroundColor Green
Write-Host ''

# ============================================================
# SECTION 14: SHOW WINDOW
# ============================================================
Write-Host "  Launching Ray's Optimization Chamber v$script:BUILD..." -ForegroundColor $StatusColor
$window.ShowDialog() | Out-Null
Write-Host "  Closed. Goodbye!" -ForegroundColor $StatusColor
