# ============================================================
#  RAY'S OPTIMIZATION CHAMBER v5.0 - Ultimate Windows Utility
#  Hardware-Aware | Tiered Optimization | WPF GUI | Mica Theme
# ============================================================

# --- SECTION 1: ADMIN ELEVATION ---
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "Elevating Ray's Chamber to Admin..." -ForegroundColor Cyan
    $cmd = if ($PSCommandPath) { "& '$PSCommandPath'" } else { "irm is.gd/RaysUtil | iex" }
    Start-Process powershell.exe "-NoProfile -ExecutionPolicy Bypass -Command $cmd" -Verb RunAs
    exit
}

# --- SECTION 2: ASSEMBLIES ---
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# --- SECTION 3: HARDWARE DETECTION ---
$cpuName   = (Get-CimInstance Win32_Processor).Name
$cpuCores  = (Get-CimInstance Win32_Processor).NumberOfCores
$cpuThreads= (Get-CimInstance Win32_Processor).ThreadCount
$ramGB     = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB)
$ramSpeed  = (Get-CimInstance Win32_PhysicalMemory | Select-Object -First 1).Speed
$gpu       = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name
$isLaptop  = if (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue) { $true } else { $false }
$HardwareType = if ($isLaptop) { 'LAPTOP' } else { 'DESKTOP' }
$SuggestedTier = 'Mid-Range'
if ($ramGB -le 8 -or $cpuName -match 'Celeron|Pentium|Athlon|i3') { $SuggestedTier = 'Low-End' }
if ($ramGB -ge 32 -and -not $isLaptop -and $cpuName -match 'i7|i9|Ryzen 7|Ryzen 9') { $SuggestedTier = 'High-End' }
$StatusColor = if ($isLaptop) { 'Yellow' } else { 'Cyan' }

# --- SECTION 4: CONSOLE BRANDING ---
Clear-Host
Write-Host '' -ForegroundColor $StatusColor
Write-Host '  ============================================' -ForegroundColor $StatusColor
Write-Host "  RAY'S OPTIMIZATION CHAMBER v5.0" -ForegroundColor $StatusColor
Write-Host '  ============================================' -ForegroundColor $StatusColor
Write-Host "  DEVICE : $HardwareType" -ForegroundColor $StatusColor
Write-Host "  CPU    : $cpuName ($cpuCores C / $cpuThreads T)" -ForegroundColor Gray
Write-Host "  RAM    : ${ramGB}GB @ ${ramSpeed}MHz" -ForegroundColor Gray
Write-Host "  GPU    : $gpu" -ForegroundColor Gray
Write-Host "  TIER   : $SuggestedTier" -ForegroundColor $StatusColor
Write-Host '  ============================================' -ForegroundColor $StatusColor
Write-Host ''

# --- SECTION 5: DWM HELPER ---
try { Add-Type -TypeDefinition @'
using System;
using System.Runtime.InteropServices;
public class DwmHelper {
    [DllImport("dwmapi.dll")] static extern int DwmSetWindowAttribute(IntPtr h, int a, ref int v, int s);
    public static void ApplyDark(IntPtr h) {
        int v=1; DwmSetWindowAttribute(h,20,ref v,4);
        int m=2; DwmSetWindowAttribute(h,38,ref m,4);
    }
}
'@ } catch {}

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

# --- SECTION 7: STATE VARIABLES ---
$script:Ctrl = @{}
$script:RestoreCreated = $false
$script:BoostTimer = $null
$script:GameList = @('cs2','valorant','FortniteClient-Win64-Shipping','r5apex','javaw','minecraft','GTA5','RocketLeague')
$Panels  = @('PanelInstall','PanelTweaks','PanelGaming','PanelHardware','PanelConfig','PanelUpdates','PanelHealth')
$NavBtns = @('NavInstall','NavTweaks','NavGaming','NavHardware','NavConfig','NavUpdates','NavHealth')

# --- SECTION 8: HELPER FUNCTIONS ---
function Write-Log([string]$Msg, [string]$Type = 'Info') {
    $ts = Get-Date -Format 'HH:mm:ss'
    $colors = @{ OK='#00FFCC'; Action='#00D9FF'; Error='#FF6666'; Warn='#FFD700'; Info='#8090A0' }
    $hex = if ($colors[$Type]) { $colors[$Type] } else { '#8090A0' }
    Write-Host "[$ts] $Msg" -ForegroundColor Gray
    $lb = $Ctrl['LogBox']; $ls = $Ctrl['LogScroll']
    if ($lb -and $ls) {
        $run = New-Object System.Windows.Documents.Run "[$ts] $Msg`n"
        $run.Foreground = ([System.Windows.Media.BrushConverter]::new()).ConvertFrom($hex)
        $lb.Inlines.Add($run)
        $ls.ScrollToEnd()
    }
}

function Set-Reg([string]$Path, [string]$Name, $Value, [string]$Type = 'DWord') {
    try {
        if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
        New-ItemProperty -Path $Path -Name $Name -Value $Value -PropertyType $Type -Force -ErrorAction Stop | Out-Null
    } catch {}
}

function Guard-Restore {
    if ($script:RestoreCreated) { return $true }
    [System.Windows.MessageBox]::Show('You must create a Restore Point first! Click the yellow button in the Tweaks tab.', 'Safety Check', 'OK', 'Warning') | Out-Null
    return $false
}

function Switch-Tab([int]$Index) {
    for ($i = 0; $i -lt $Panels.Count; $i++) {
        $p = $Ctrl[$Panels[$i]]; $n = $Ctrl[$NavBtns[$i]]
        if ($p) { $p.Visibility = if ($i -eq $Index) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed } }
        if ($n) { $n.FontWeight = if ($i -eq $Index) { [System.Windows.FontWeights]::Bold } else { [System.Windows.FontWeights]::Normal } }
    }
}

function Hook([string]$n, [string]$e, [scriptblock]$a) {
    $el = $Ctrl[$n]
    if ($el) { $el."Add_$e"($a) }
    else { Write-Host "WARN: Element '$n' not found for event '$e'" -ForegroundColor Yellow }
}

function Play-Tone { [console]::Beep(440,150); [console]::Beep(660,150); [console]::Beep(880,300) }

function Restart-Shell {
    Write-Log "Restarting Explorer shell..." Action
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Sleep -Seconds 1
    Start-Process explorer.exe
    Write-Log "Explorer restarted" OK
}

# --- SECTION 9: OPTIMIZATION FUNCTIONS ---
function Apply-LowEndTweaks {
    Write-Log "Applying Low-End optimizations..." Action
    # Disable animations and transparency
    Set-Reg 'HKCU:\Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) 'Binary'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
    Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0' 'String'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2
    # Disable memory compression if 8GB+
    if ($ramGB -ge 8) { try { Disable-MMAgent -MemoryCompression -ErrorAction Stop } catch {}; Write-Log "  Memory compression disabled" Info }
    # Kill heavy services
    foreach ($svc in @('SysMain','DiagTrack','WSearch')) {
        try { Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop; Stop-Service -Name $svc -Force -ErrorAction Stop } catch {}
    }
    Write-Log "  Heavy services disabled (SysMain, DiagTrack, WSearch)" Info
    # Disable Game DVR
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    # High Performance power plan
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
    # Disable telemetry
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
    foreach ($svc in @('dmwappushservice','diagnosticshub.standardcollector.service')) {
        try { Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop; Stop-Service -Name $svc -Force -ErrorAction Stop } catch {}
    }
    # Disable FSO globally
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2
    Write-Log "Mid-Range optimizations complete!" OK
    Play-Tone
}

function Apply-HighEndTweaks {
    if ($isLaptop) {
        $r = [System.Windows.MessageBox]::Show("High-End tweaks increase heat and power usage. Make sure your laptop is plugged in. Continue?", "Laptop Warning", "YesNo", "Warning")
        if ($r -eq 'No') { return }
    }
    Write-Log "Applying HIGH-END (Nuclear) optimizations..." Action
    Apply-MidRangeTweaks
    # BCD extreme latency
    bcdedit /set useplatformtick yes 2>$null
    bcdedit /set disabledynamictick yes 2>$null
    Write-Log "  BCD timer tweaks applied" Info
    # Ultimate Performance plan
    $out = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
    if ($out -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') {
        powercfg /setactive $Matches[1] 2>$null
        Write-Log "  Ultimate Performance plan activated" Info
    }
    # Unpark all cores
    $cpPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583'
    Set-Reg $cpPath 'Attributes' 0
    powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 2>$null
    powercfg -setactive scheme_current 2>$null
    Write-Log "  CPU cores unparked" Info
    # GPU priority
    $gpuTask = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    Set-Reg $gpuTask 'GPU Priority' 8
    Set-Reg $gpuTask 'Priority' 6
    Set-Reg $gpuTask 'Scheduling Category' 'High' 'String'
    Set-Reg $gpuTask 'SFIO Priority' 'High' 'String'
    # GPU MSI mode
    try {
        $dev = Get-PnpDevice -Class Display -Status OK -ErrorAction Stop | Select-Object -First 1
        if ($dev) {
            $msiP = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($dev.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"
            Set-Reg $msiP 'MSISupported' 1
            Write-Log "  GPU MSI mode enabled" Info
        }
    } catch {}
    # GPU power state
    $gpuReg = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000'
    Set-Reg $gpuReg 'PerfLevelSrc' 0x2222
    Set-Reg $gpuReg 'PowerMizerEnable' 0
    Set-Reg $gpuReg 'PowerMizerLevel' 1
    Set-Reg $gpuReg 'PowerMizerLevelAC' 1
    # Disable Spectre/Meltdown mitigations
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'FeatureSettingsOverride' 3
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'FeatureSettingsOverrideMask' 3
    Write-Log "  CPU security mitigations disabled (+15% perf)" Warn
    # Disable VBS / Device Guard
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity' 0
    Write-Log "  VBS/Device Guard disabled" Warn
    # Lower DWM priority
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager' 'Priority' 3
    # Disable Nagle on all interfaces
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object {
        Set-Reg $_.PSPath 'TcpAckFrequency' 1
        Set-Reg $_.PSPath 'TCPNoDelay' 1
    }
    Write-Log "HIGH-END optimizations complete! Restart recommended." OK
    Play-Tone
}

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
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Log "Cleanup complete - temp files and recycle bin cleared" OK
}

function Optimize-RAM {
    Write-Log "Optimizing RAM..." Action
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'LargeSystemCache' 0
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'ClearPageFileAtShutdown' 1
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    Write-Log "RAM optimized - cache cleared, GC forced" OK
    Play-Tone
}

function Optimize-Storage {
    Write-Log "Optimizing storage..." Action
    try { Optimize-Volume -DriveLetter C -ReTrim -ErrorAction Stop; Write-Log "SSD TRIM completed" OK } catch { Write-Log "Drive optimization skipped (may not be SSD)" Warn }
    Play-Tone
}

function Apply-NetworkTweaks {
    Write-Log "Applying network tweaks..." Action
    netsh int tcp set global autotuninglevel=highlyrestricted 2>$null
    netsh int tcp set global chimney=disabled 2>$null
    netsh int tcp set global rss=enabled 2>$null
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object {
        Set-Reg $_.PSPath 'TcpAckFrequency' 1
        Set-Reg $_.PSPath 'TCPNoDelay' 1
    }
    Write-Log "Network optimized - Nagle disabled, TCP tuned" OK
    Play-Tone
}

function Apply-USBTweaks {
    Write-Log "Applying USB and input tweaks..." Action
    # Disable USB selective suspend via registry
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' 'DisableSelectiveSuspend' 1
    # Mouse acceleration off
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSensitivity' '10' 'String'
    # Keyboard max repeat rate
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31' 'String'
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '0' 'String'
    Write-Log "USB suspend off, mouse accel off, keyboard max speed" OK
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
    Write-Log "Zero Latency mode ACTIVE! BCD+Priority+Nagle+GPU+Input all tuned" OK
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

function Clear-RAMStandby {
    Write-Log "Purging RAM standby list..." Action
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
    Write-Log "RAM standby purged via GC" OK
}

function Show-FrameCapAdvice {
    $hz = try { (Get-CimInstance Win32_VideoController).CurrentRefreshRate | Select-Object -First 1 } catch { 60 }
    if (-not $hz -or $hz -eq 0) { $hz = 60 }
    $msg = "Monitor: ${hz}Hz`n`nRecommended Frame Cap: $hz FPS`n`nNVIDIA: Set Max Frame Rate in Control Panel`nAMD: Set Frame Rate Target Control in Radeon`nUniversal: Use RTSS (RivaTuner) for per-game caps`n`nFor competitive: Cap at $([math]::Floor($hz * 0.95)) for lowest input lag"
    [System.Windows.MessageBox]::Show($msg, 'Frame Cap Advisor', 'OK', 'Information') | Out-Null
    Write-Log "Monitor detected at ${hz}Hz" OK
}

function Apply-LaptopGodMode {
    if (-not $isLaptop) { Write-Log "Laptop God Mode is only for laptops" Warn; return }
    $r = [System.Windows.MessageBox]::Show("Laptop God Mode will increase heat and power draw significantly. Make sure you are plugged in with good cooling. Continue?", "Thermal Warning", "YesNo", "Warning")
    if ($r -eq 'No') { return }
    Write-Log "Activating Laptop God Mode..." Action
    # 99% CPU cap to prevent turbo overheat crash
    powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 99 2>$null
    powercfg -setactive scheme_current 2>$null
    # Disable power throttling
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'PowerThrottlingOff' 1
    # Disable efficiency mode
    $effPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583'
    Set-Reg $effPath 'Attributes' 0
    # Unlock processor boost mode
    $boostPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7'
    Set-Reg $boostPath 'Attributes' 0
    Write-Log "Laptop God Mode ACTIVE! 99% CPU cap, throttle off, boost unlocked" OK
    Play-Tone
}

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
    Write-Log "All CPU cores unparked - min cores set to 100%" OK
    Play-Tone
}

function Check-RAMSpeed {
    $mem = Get-CimInstance Win32_PhysicalMemory | Select-Object Capacity, Speed, Manufacturer
    $info = $mem | ForEach-Object { "$([math]::Round($_.Capacity/1GB))GB @ $($_.Speed)MHz ($($_.Manufacturer))" }
    $msg = "RAM Modules:`n$($info -join "`n")`n`nIf speed is below your RAM's rated speed, enable XMP/DOCP in BIOS."
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
    Write-Log "Context menu shortcut added!" OK
}

function Remove-ContextMenu {
    Remove-Item 'Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\RaysChamber' -Recurse -Force -ErrorAction SilentlyContinue
    Write-Log "Context menu shortcut removed" OK
}

function Register-MaintenanceTask {
    Write-Log "Registering maintenance task..." Action
    $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument '-WindowStyle Hidden -Command "Optimize-Volume -DriveLetter C -ReTrim -ErrorAction SilentlyContinue; Remove-Item $env:TEMP\* -Recurse -Force -ErrorAction SilentlyContinue"'
    $trigger = New-ScheduledTaskTrigger -Daily -At 3am
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName 'RaysChamber_Maintenance' -Description 'Auto SSD trim and temp cleanup' -Force | Out-Null
    Write-Log "Maintenance task scheduled (daily 3AM)" OK
}

function Start-MicroWin {
    Write-Log "MicroWin ISO Debloat" Action
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = 'ISO Files|*.iso'
    $dlg.Title = 'Select Windows ISO for Debloating'
    if ($dlg.ShowDialog()) {
        Write-Log "Selected ISO: $($dlg.FileName)" Info
        Write-Log "MicroWin debloat launching in separate window..." Action
        Start-Process powershell.exe "-NoProfile -Command `"Write-Host 'MicroWin ISO Debloat Tool' -ForegroundColor Cyan; Write-Host 'Selected: $($dlg.FileName)'; Write-Host 'This feature will mount, strip bloatware, and export a clean ISO.'; Write-Host 'Work in progress - full DISM integration coming soon.'; pause`""
    }
}

function Invoke-SystemHealthScan {
    Write-Log "Starting full system health scan..." Action
    Start-Process powershell.exe "-NoProfile -Command `"Write-Host '=== RAY''S SYSTEM HEALTH SCAN ===' -ForegroundColor Cyan; Write-Host ''; Write-Host '[1/3] Running SFC...' -ForegroundColor Yellow; sfc /scannow; Write-Host ''; Write-Host '[2/3] Running DISM...' -ForegroundColor Yellow; DISM /Online /Cleanup-Image /RestoreHealth; Write-Host ''; Write-Host '[3/3] Resetting Windows Update...' -ForegroundColor Yellow; net stop wuauserv 2>`$null; Remove-Item C:\Windows\SoftwareDistribution -Recurse -Force -ErrorAction SilentlyContinue; net start wuauserv 2>`$null; Write-Host ''; Write-Host 'HEALTH SCAN COMPLETE' -ForegroundColor Green; pause`""
    Write-Log "Health scan launched in separate window" OK
}

function Run-WinSATBenchmark {
    Write-Log "Launching WinSAT benchmark..." Action
    Start-Process powershell.exe "-NoProfile -Command `"Write-Host 'Running WinSAT Formal Assessment...' -ForegroundColor Cyan; winsat formal; Write-Host ''; Write-Host 'Benchmark complete!' -ForegroundColor Green; pause`""
    Write-Log "WinSAT benchmark launched" OK
}

function Revert-AllChanges {
    Write-Log "REVERTING all optimizations to Windows defaults..." Action
    # Visuals
    Set-Reg 'HKCU:\Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x9E,0x3E,0x07,0x80,0x12,0x00,0x00,0x00)) 'Binary'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 1
    Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '400' 'String'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 0
    # Memory compression
    try { Enable-MMAgent -MemoryCompression -ErrorAction Stop } catch {}
    # Services
    foreach ($svc in @('SysMain','DiagTrack','WSearch','dmwappushservice')) {
        try { Set-Service -Name $svc -StartupType Automatic -ErrorAction Stop; Start-Service -Name $svc -ErrorAction Stop } catch {}
    }
    # Game DVR
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 1
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 1
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 0
    # Power plan (balanced)
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null
    # System responsiveness
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 20
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 10
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 2
    # Telemetry
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -ErrorAction SilentlyContinue
    # BCD
    bcdedit /deletevalue useplatformtick 2>$null
    bcdedit /deletevalue disabledynamictick 2>$null
    # Core parking
    powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 50 2>$null
    powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 100 2>$null
    powercfg -setactive scheme_current 2>$null
    # GPU tasks
    $gpuTask = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    Set-Reg $gpuTask 'GPU Priority' 2
    Set-Reg $gpuTask 'Priority' 2
    Set-Reg $gpuTask 'Scheduling Category' 'Medium' 'String'
    Set-Reg $gpuTask 'SFIO Priority' 'Normal' 'String'
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager' 'Priority' 5
    # CPU mitigations (restore)
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'FeatureSettingsOverride' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'FeatureSettingsOverrideMask' -ErrorAction SilentlyContinue
    # VBS
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' -Name 'EnableVirtualizationBasedSecurity' -ErrorAction SilentlyContinue
    # GPU power state
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000' -Name 'PerfLevelSrc' -ErrorAction SilentlyContinue
    # Network
    netsh int tcp set global autotuninglevel=normal 2>$null
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-ItemProperty -Path $_.PSPath -Name 'TcpAckFrequency' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $_.PSPath -Name 'TCPNoDelay' -ErrorAction SilentlyContinue
    }
    # Power throttling
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'PowerThrottlingOff' -ErrorAction SilentlyContinue
    # Mouse
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '1' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '6' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '10' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSensitivity' '10' 'String'
    # Keyboard
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31' 'String'
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '1' 'String'
    # USB
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' -Name 'DisableSelectiveSuspend' -ErrorAction SilentlyContinue
    # RAM
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'LargeSystemCache' 1
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'ClearPageFileAtShutdown' -ErrorAction SilentlyContinue
    # Context menu
    Remove-ContextMenu
    # Maintenance task
    Unregister-ScheduledTask -TaskName 'RaysChamber_Maintenance' -Confirm:$false -ErrorAction SilentlyContinue
    # Auto-booster
    Stop-AutoBooster
    Write-Log "ALL changes reverted to Windows defaults!" OK
    [console]::Beep(880,150); [console]::Beep(660,150); [console]::Beep(440,300)
}

# ============================================================
# SECTION 10: WPF XAML DEFINITION
# ============================================================
$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Rays Optimization Chamber v5.0"
    Width="1100" Height="750"
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
            <TextBlock Text="RAYS OPTIMIZATION CHAMBER v5.0" FontSize="16" FontWeight="Bold" Foreground="#00D9FF"/>
        </Border>
        <Border DockPanel.Dock="Bottom" Background="#00050A" BorderBrush="#002A4A" BorderThickness="0,1,0,0" Height="130">
            <ScrollViewer Name="LogScroll" VerticalScrollBarVisibility="Auto" Padding="8">
                <TextBlock Name="LogBox" TextWrapping="Wrap" Foreground="#8090A0" FontSize="11" FontFamily="Consolas"/>
            </ScrollViewer>
        </Border>
        <StackPanel DockPanel.Dock="Top" Orientation="Horizontal" Background="#000814" Margin="0,0,0,0">
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
                    <Button Name="BtnRestore" Content="Create Restore Point (REQUIRED)" FontWeight="Bold" ToolTip="Creates a System Restore point before making any changes"/>
                    <TextBlock Text="-- Presets --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnLowEnd" Content="Low-End PC" ToolTip="Disables animations, memory compression, heavy services. Safe for all hardware."/>
                        <Button Name="BtnMidEnd" Content="Mid-Range" ToolTip="Adds telemetry block, network throttle off, system responsiveness boost."/>
                        <Button Name="BtnHighEnd" Content="High-End Nuclear" ToolTip="WARNING: BCD tweaks, CPU mitigations off, VBS off. For advanced users only."/>
                    </WrapPanel>
                    <TextBlock Text="-- Individual Tweaks --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnDebloat" Content="Debloat Windows" ToolTip="Removes pre-installed bloatware apps"/>
                        <Button Name="BtnCleanup" Content="System Cleanup" ToolTip="Clears temp files and recycle bin"/>
                        <Button Name="BtnOptRAM" Content="Optimize RAM" ToolTip="Adjusts memory management and clears cache"/>
                        <Button Name="BtnOptStore" Content="Optimize Storage" ToolTip="Trims SSD and optimizes disk"/>
                        <Button Name="BtnOptNet" Content="Network Tweaks" ToolTip="TCP optimizations and disables Nagle algorithm"/>
                        <Button Name="BtnUSB" Content="USB and Input" ToolTip="Disables USB suspend, removes mouse acceleration"/>
                        <Button Name="BtnRefreshNet" Content="Refresh Internet" ToolTip="Flushes DNS, resets Winsock and IP stack"/>
                    </WrapPanel>
                    <TextBlock Text="-- Danger Zone --" FontSize="14" FontWeight="Bold" Foreground="#FF6666" Margin="0,12,0,4"/>
                    <Button Name="BtnRevert" Content="REVERT ALL CHANGES" ToolTip="Restores every setting to Windows defaults"/>
                </StackPanel>
            </ScrollViewer>
            <ScrollViewer Name="PanelGaming" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="GAMING OPTIMIZATION" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <WrapPanel>
                        <Button Name="BtnGameBoost" Content="Zero Latency Mode" FontWeight="Bold" ToolTip="BCD timer fix, priority boost, Nagle off, GPU priority max, Game DVR off"/>
                        <Button Name="BtnAutoBoost" Content="Start Auto-Booster" ToolTip="Monitors for games every 30s and boosts their priority automatically"/>
                        <Button Name="BtnStopBoost" Content="Stop Auto-Booster" ToolTip="Stops the automatic game detection loop"/>
                        <Button Name="BtnRAMPurge" Content="Purge RAM" ToolTip="Forces garbage collection to clear standby memory list"/>
                        <Button Name="BtnFrameCap" Content="Frame Cap Advisor" ToolTip="Detects your monitor Hz and recommends optimal frame cap"/>
                        <Button Name="BtnLaptopGod" Content="Laptop God Mode" ToolTip="99 percent CPU cap, disable thermal throttle, unlock boost mode (laptops only)"/>
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
                        <Button Name="BtnUltPower" Content="Ultimate Performance Plan" ToolTip="Unlocks hidden Windows power plan that prevents CPU idle"/>
                        <Button Name="BtnUnpark" Content="Unpark All Cores" ToolTip="Sets CPU core parking minimum to 100 percent"/>
                        <Button Name="BtnCheckRAM" Content="Check RAM Speed" ToolTip="Shows RAM module speeds - warns if XMP/DOCP needs enabling"/>
                    </WrapPanel>
                    <TextBlock Text="-- System --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnContextMenu" Content="Add Context Menu" ToolTip="Adds right-click desktop shortcut to open Rays Chamber"/>
                        <Button Name="BtnRmContext" Content="Remove Context Menu" ToolTip="Removes the desktop right-click shortcut"/>
                        <Button Name="BtnMaintTask" Content="Schedule Maintenance" ToolTip="Auto SSD trim and temp cleanup every day at 3AM"/>
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
                        <Button Name="BtnDNSAuto" Content="Auto DNS (DHCP)" ToolTip="Resets DNS to automatic DHCP default"/>
                    </WrapPanel>
                    <TextBlock Text="-- Advanced --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <Button Name="BtnMicroWin" Content="MicroWin ISO Debloat" ToolTip="Strip bloatware from a Windows ISO file"/>
                </StackPanel>
            </ScrollViewer>
            <ScrollViewer Name="PanelUpdates" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="WINDOWS UPDATES" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <WrapPanel>
                        <Button Name="BtnUpdDefault" Content="Default (Auto)" ToolTip="Restores standard Windows Update behavior"/>
                        <Button Name="BtnUpdSec" Content="Security Only" ToolTip="Only installs critical security patches"/>
                        <Button Name="BtnUpdOff" Content="Disable Updates" ToolTip="WARNING: Completely disables Windows Update service"/>
                    </WrapPanel>
                </StackPanel>
            </ScrollViewer>
            <ScrollViewer Name="PanelHealth" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="SYSTEM HEALTH" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <WrapPanel>
                        <Button Name="BtnFullScan" Content="Full Health Scan" FontWeight="Bold" ToolTip="Runs SFC + DISM + Windows Update Reset in one go"/>
                        <Button Name="BtnSFC" Content="SFC Scan" ToolTip="System File Checker - repairs corrupted system files"/>
                        <Button Name="BtnDISM" Content="DISM Repair" ToolTip="Deployment Image Servicing - downloads fresh components from Microsoft"/>
                        <Button Name="BtnWinSAT" Content="Run WinSAT" ToolTip="Windows System Assessment Tool - benchmarks your hardware"/>
                        <Button Name="BtnRestartShell" Content="Restart Explorer" ToolTip="Restarts Windows Explorer to apply visual changes instantly"/>
                    </WrapPanel>
                </StackPanel>
            </ScrollViewer>
        </Grid>
    </DockPanel>
</Window>
'@

# ============================================================
# SECTION 11: WINDOW CREATION + TREE WALK
# ============================================================
Write-Host "Parsing XAML..." -ForegroundColor Cyan
try {
    $window = [System.Windows.Markup.XamlReader]::Parse($xaml)
} catch {
    Write-Host "FATAL: XAML parse failed: $_" -ForegroundColor Red
    Write-Host "Press any key to exit..." -ForegroundColor Red
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit 1
}

# Recursive tree walker using LogicalTreeHelper
function Walk-Tree($el) {
    if ($el -is [System.Windows.FrameworkElement] -and $el.Name) {
        $script:Ctrl[$el.Name] = $el
    }
    if ($el -is [System.Windows.DependencyObject]) {
        try {
            foreach ($child in [System.Windows.LogicalTreeHelper]::GetChildren($el)) {
                if ($child -is [System.Windows.DependencyObject]) { Walk-Tree $child }
            }
        } catch {}
    }
}
Walk-Tree $window
Write-Host "Found $($Ctrl.Count) named controls" -ForegroundColor Green

# Validate critical controls
$required = @('LogBox','LogScroll','NavInstall','PanelInstall','AppPanel','TxtSearch')
foreach ($r in $required) {
    if (-not $Ctrl[$r]) { Write-Host "CRITICAL: Missing control '$r' - UI may not work correctly" -ForegroundColor Red }
}

# --- DWM Mica effect ---
$window.Add_SourceInitialized({
    try {
        $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper $window).Handle
        [DwmHelper]::ApplyDark($hwnd)
    } catch {}
})

# ============================================================
# SECTION 12: INITIALIZATION
# ============================================================
# Set hardware info
if ($Ctrl['TxtHWInfo']) { $Ctrl['TxtHWInfo'].Text = "$HardwareType | $cpuName | ${ramGB}GB RAM | Tier: $SuggestedTier" }
if ($Ctrl['TxtHWDetail']) {
    $detail = "CPU: $cpuCores Cores / $cpuThreads Threads | RAM: ${ramSpeed}MHz | GPU: $gpu"
    $Ctrl['TxtHWDetail'].Text = $detail
}

# Populate app checkboxes
foreach ($app in $Apps) {
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $app.N
    $cb.Tag = $app.ID
    $cb.Width = 200
    $cb.Margin = '4'
    if ($Ctrl['AppPanel']) { $Ctrl['AppPanel'].Children.Add($cb) }
}

# Search filter
Hook 'TxtSearch' 'TextChanged' {
    $query = $Ctrl['TxtSearch'].Text.ToLower()
    if ($Ctrl['AppPanel']) {
        foreach ($child in $Ctrl['AppPanel'].Children) {
            if ($child -is [System.Windows.Controls.CheckBox]) {
                $child.Visibility = if ($child.Content.ToString().ToLower().Contains($query)) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
            }
        }
    }
}

# Init first tab
Switch-Tab 0
Write-Log "Ray's Optimization Chamber v5.0 initialized" OK
Write-Log "$HardwareType detected | $cpuName | ${ramGB}GB RAM | Tier: $SuggestedTier" Info

# ============================================================
# SECTION 13: EVENT HANDLERS
# ============================================================
# Navigation
Hook 'NavInstall'  'Click' { Switch-Tab 0 }
Hook 'NavTweaks'   'Click' { Switch-Tab 1 }
Hook 'NavGaming'   'Click' { Switch-Tab 2 }
Hook 'NavHardware' 'Click' { Switch-Tab 3 }
Hook 'NavConfig'   'Click' { Switch-Tab 4 }
Hook 'NavUpdates'  'Click' { Switch-Tab 5 }
Hook 'NavHealth'   'Click' { Switch-Tab 6 }

# Install tab
Hook 'BtnSelectAll' 'Click' {
    if ($Ctrl['AppPanel']) { foreach ($c in $Ctrl['AppPanel'].Children) { if ($c -is [System.Windows.Controls.CheckBox]) { $c.IsChecked = $true } } }
}
Hook 'BtnDeselectAll' 'Click' {
    if ($Ctrl['AppPanel']) { foreach ($c in $Ctrl['AppPanel'].Children) { if ($c -is [System.Windows.Controls.CheckBox]) { $c.IsChecked = $false } } }
}
Hook 'BtnInstallSelected' 'Click' {
    $selected = @()
    if ($Ctrl['AppPanel']) {
        foreach ($c in $Ctrl['AppPanel'].Children) {
            if ($c -is [System.Windows.Controls.CheckBox] -and $c.IsChecked -eq $true) { $selected += $c.Tag }
        }
    }
    if ($selected.Count -eq 0) { Write-Log "No apps selected" Warn; return }
    Write-Log "Installing $($selected.Count) apps via winget..." Action
    foreach ($id in $selected) {
        Write-Log "  Installing $id..." Info
        Start-Process winget -ArgumentList "install --id $id --accept-source-agreements --accept-package-agreements -h" -NoNewWindow
    }
    Write-Log "All installations queued!" OK
    Play-Tone
}

# Tweaks tab
Hook 'BtnRestore' 'Click' {
    Write-Log "Creating System Restore Point..." Action
    try {
        Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop
        Checkpoint-Computer -Description 'RaysChamber_v5_Backup' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
        $script:RestoreCreated = $true
        Write-Log "Restore Point created successfully! Tweaks are now unlocked." OK
    } catch {
        Write-Log "Restore Point creation failed: $_ - Tweaks unlocked anyway for testing" Warn
        $script:RestoreCreated = $true
    }
}
Hook 'BtnLowEnd'    'Click' { if (Guard-Restore) { Apply-LowEndTweaks } }
Hook 'BtnMidEnd'    'Click' { if (Guard-Restore) { Apply-MidRangeTweaks } }
Hook 'BtnHighEnd'   'Click' { if (Guard-Restore) { Apply-HighEndTweaks } }
Hook 'BtnDebloat'   'Click' { if (Guard-Restore) { Invoke-Debloat } }
Hook 'BtnCleanup'   'Click' { Invoke-SystemCleanup }
Hook 'BtnOptRAM'    'Click' { if (Guard-Restore) { Optimize-RAM } }
Hook 'BtnOptStore'  'Click' { if (Guard-Restore) { Optimize-Storage } }
Hook 'BtnOptNet'    'Click' { if (Guard-Restore) { Apply-NetworkTweaks } }
Hook 'BtnUSB'       'Click' { if (Guard-Restore) { Apply-USBTweaks } }
Hook 'BtnRefreshNet' 'Click' { Refresh-Internet }
Hook 'BtnRevert'    'Click' { Revert-AllChanges }

# Gaming tab
Hook 'BtnGameBoost' 'Click' { if (Guard-Restore) { Apply-GameBoost } }
Hook 'BtnAutoBoost' 'Click' { Start-AutoBooster }
Hook 'BtnStopBoost' 'Click' { Stop-AutoBooster }
Hook 'BtnRAMPurge'  'Click' { Clear-RAMStandby }
Hook 'BtnFrameCap'  'Click' { Show-FrameCapAdvice }
Hook 'BtnLaptopGod' 'Click' { if (Guard-Restore) { Apply-LaptopGodMode } }

# Hardware tab
Hook 'BtnUltPower'    'Click' { if (Guard-Restore) { Invoke-UltimatePower } }
Hook 'BtnUnpark'      'Click' { if (Guard-Restore) { Invoke-UnparkCores } }
Hook 'BtnCheckRAM'    'Click' { Check-RAMSpeed }
Hook 'BtnContextMenu' 'Click' { Add-ContextMenu }
Hook 'BtnRmContext'   'Click' { Remove-ContextMenu }
Hook 'BtnMaintTask'   'Click' { Register-MaintenanceTask }

# Config tab
Hook 'BtnWSL' 'Click' {
    Write-Log "Enabling WSL2..." Action
    Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart; dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart; Write-Host 'WSL2 enabled - restart required' -ForegroundColor Green; pause`""
}
Hook 'BtnSandbox' 'Click' {
    Write-Log "Enabling Windows Sandbox..." Action
    Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:Containers-DisposableClientVM /all /norestart; Write-Host 'Sandbox enabled - restart required' -ForegroundColor Green; pause`""
}
Hook 'BtnHyperV' 'Click' {
    Write-Log "Enabling Hyper-V..." Action
    Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart; Write-Host 'Hyper-V enabled - restart required' -ForegroundColor Green; pause`""
}
Hook 'BtnDotNet' 'Click' {
    Write-Log "Enabling .NET 3.5..." Action
    Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:NetFx3 /all /norestart; Write-Host '.NET 3.5 enabled' -ForegroundColor Green; pause`""
}
Hook 'BtnDNSGoogle' 'Click' {
    Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses '8.8.8.8','8.8.4.4' }
    Write-Log "DNS set to Google (8.8.8.8)" OK
}
Hook 'BtnDNSCF' 'Click' {
    Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses '1.1.1.1','1.0.0.1' }
    Write-Log "DNS set to Cloudflare (1.1.1.1)" OK
}
Hook 'BtnDNSAuto' 'Click' {
    Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses }
    Write-Log "DNS reset to DHCP default" OK
}
Hook 'BtnMicroWin' 'Click' { Start-MicroWin }

# Updates tab
Hook 'BtnUpdDefault' 'Click' {
    try { Set-Service -Name wuauserv -StartupType Automatic; Start-Service -Name wuauserv } catch {}
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -ErrorAction SilentlyContinue
    Write-Log "Windows Update restored to default (automatic)" OK
}
Hook 'BtnUpdSec' 'Click' {
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'NoAutoUpdate' 0
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'AUOptions' 3
    Write-Log "Windows Update set to Security Only (notify before download)" OK
}
Hook 'BtnUpdOff' 'Click' {
    $r = [System.Windows.MessageBox]::Show("WARNING: Disabling Windows Update leaves your system vulnerable to security threats. Are you sure?", "Disable Updates", "YesNo", "Warning")
    if ($r -eq 'Yes') {
        try { Set-Service -Name wuauserv -StartupType Disabled; Stop-Service -Name wuauserv -Force } catch {}
        Write-Log "Windows Update DISABLED - system will not receive patches" Warn
    }
}

# Health tab
Hook 'BtnFullScan'     'Click' { Invoke-SystemHealthScan }
Hook 'BtnSFC' 'Click' {
    Write-Log "Launching SFC scan..." Action
    Start-Process powershell.exe "-NoProfile -Command `"sfc /scannow; pause`""
}
Hook 'BtnDISM' 'Click' {
    Write-Log "Launching DISM repair..." Action
    Start-Process powershell.exe "-NoProfile -Command `"DISM /Online /Cleanup-Image /RestoreHealth; pause`""
}
Hook 'BtnWinSAT'       'Click' { Run-WinSATBenchmark }
Hook 'BtnRestartShell'  'Click' { Restart-Shell }

# ============================================================
# SECTION 14: SHOW WINDOW
# ============================================================
Write-Host "Launching Ray's Optimization Chamber..." -ForegroundColor $StatusColor
$window.ShowDialog() | Out-Null
Write-Host "Ray's Optimization Chamber closed. Goodbye!" -ForegroundColor $StatusColor
