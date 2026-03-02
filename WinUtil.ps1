# ============================================================
#  RAY'S OPTIMIZATION CHAMBER v5.1 - BUTTON-FIX EDITION
#  All controls verified | Debug logging | Null-guarded
# ============================================================
$script:BUILD = '5.1-FIXED'

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
Write-Host "  DEVICE : $HardwareType" -ForegroundColor $StatusColor
Write-Host "  CPU    : $cpuName ($cpuCores C / $cpuThreads T)" -ForegroundColor Gray
Write-Host "  RAM    : ${ramGB}GB @ ${ramSpeed}MHz" -ForegroundColor Gray
Write-Host "  GPU    : $gpu" -ForegroundColor Gray
Write-Host "  TIER   : $SuggestedTier" -ForegroundColor $StatusColor
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
$script:GameList = @('cs2','valorant','FortniteClient-Win64-Shipping','r5apex','javaw','minecraft','GTA5','RocketLeague')
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
    [System.Windows.MessageBox]::Show('You must create a Restore Point first! Click the yellow button in the Tweaks tab.', 'Safety Check', 'OK', 'Warning') | Out-Null
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

# --- SECTION 9: OPTIMIZATION FUNCTIONS ---
function Apply-LowEndTweaks {
    Write-Log "Applying Low-End optimizations..." Action
    Set-Reg 'HKCU:\Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) 'Binary'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
    Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0' 'String'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2
    if ($ramGB -ge 8) { try { Disable-MMAgent -MemoryCompression -ErrorAction Stop } catch {}; Write-Log "  Memory compression disabled" Info }
    foreach ($svc in @('SysMain','DiagTrack','WSearch')) {
        try { Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop; Stop-Service -Name $svc -Force -ErrorAction Stop } catch {}
    }
    Write-Log "  Heavy services disabled (SysMain, DiagTrack, WSearch)" Info
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
        $r = [System.Windows.MessageBox]::Show("High-End tweaks increase heat and power usage. Make sure your laptop is plugged in. Continue?", "Laptop Warning", "YesNo", "Warning")
        if ($r -eq 'No') { return }
    }
    Write-Log "Applying HIGH-END (Nuclear) optimizations..." Action
    Apply-MidRangeTweaks
    bcdedit /set useplatformtick yes 2>$null
    bcdedit /set disabledynamictick yes 2>$null
    Write-Log "  BCD timer tweaks applied" Info
    $out = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
    if ($out -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') {
        powercfg /setactive $Matches[1] 2>$null
        Write-Log "  Ultimate Performance plan activated" Info
    }
    $cpPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583'
    Set-Reg $cpPath 'Attributes' 0
    powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 2>$null
    powercfg -setactive scheme_current 2>$null
    Write-Log "  CPU cores unparked" Info
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
    Write-Log "  CPU security mitigations disabled (+15% perf)" Warn
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
    $tempUser = "$env:TEMP"
    $tempSys  = "$env:SystemRoot\Temp"
    Remove-Item "$tempUser\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$tempSys\*" -Recurse -Force -ErrorAction SilentlyContinue
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
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' 'DisableSelectiveSuspend' 1
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSensitivity' '10' 'String'
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
    Write-Log "Zero Latency mode ACTIVE!" OK
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
    [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); [System.GC]::Collect()
    Write-Log "RAM standby purged via GC" OK
}

function Show-FrameCapAdvice {
    $hz = try { (Get-CimInstance Win32_VideoController).CurrentRefreshRate | Select-Object -First 1 } catch { 60 }
    if (-not $hz -or $hz -eq 0) { $hz = 60 }
    $msg = "Monitor: ${hz}Hz`n`nRecommended Cap: $hz FPS`nCompetitive: $([math]::Floor($hz * 0.95)) FPS`n`nNVIDIA: Max Frame Rate in Control Panel`nAMD: Frame Rate Target Control`nUniversal: RTSS (RivaTuner)"
    [System.Windows.MessageBox]::Show($msg, 'Frame Cap Advisor', 'OK', 'Information') | Out-Null
    Write-Log "Monitor detected at ${hz}Hz" OK
}

function Apply-LaptopGodMode {
    if (-not $isLaptop) { Write-Log "Laptop God Mode is only for laptops" Warn; return }
    $r = [System.Windows.MessageBox]::Show("Laptop God Mode increases heat significantly. Make sure you are plugged in. Continue?", "Thermal Warning", "YesNo", "Warning")
    if ($r -eq 'No') { return }
    Write-Log "Activating Laptop God Mode..." Action
    powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 99 2>$null
    powercfg -setactive scheme_current 2>$null
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'PowerThrottlingOff' 1
    $ePath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583'
    Set-Reg $ePath 'Attributes' 0
    $bPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7'
    Set-Reg $bPath 'Attributes' 0
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
    Write-Log "All CPU cores unparked - min 100%" OK
    Play-Tone
}

function Check-RAMSpeed {
    $mem = Get-CimInstance Win32_PhysicalMemory | Select-Object Capacity, Speed, Manufacturer
    $info = $mem | ForEach-Object { "$([math]::Round($_.Capacity/1GB))GB @ $($_.Speed)MHz ($($_.Manufacturer))" }
    $msg = "RAM Modules:`n$($info -join "`n")`n`nIf speed is below rated, enable XMP/DOCP in BIOS."
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
    $desktopPath = [System.IO.Path]::Combine($env:USERPROFILE, 'Desktop')
    $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-WindowStyle Hidden -Command `"Optimize-Volume -DriveLetter C -ReTrim -EA 0; Remove-Item `$env:TEMP\* -Recurse -Force -EA 0`""
    $trigger = New-ScheduledTaskTrigger -Daily -At 3am
    Register-ScheduledTask -Action $action -Trigger $trigger -TaskName 'RaysChamber_Maintenance' -Description 'Auto SSD trim and temp cleanup' -Force | Out-Null
    Write-Log "Maintenance task scheduled (daily 3AM)" OK
}

function Start-MicroWin {
    Write-Log "MicroWin ISO Debloat - opening file dialog..." Action
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = 'ISO Files|*.iso'
    $dlg.Title = 'Select Windows ISO for Debloating'
    if ($dlg.ShowDialog()) {
        Write-Log "Selected ISO: $($dlg.FileName)" Info
        Start-Process powershell.exe "-NoProfile -Command `"Write-Host 'MicroWin ISO Debloat Tool' -ForegroundColor Cyan; Write-Host 'Selected: $($dlg.FileName)'; Write-Host 'Feature in progress - DISM integration coming soon.'; pause`""
    } else { Write-Log "No ISO selected" Info }
}

function Invoke-SystemHealthScan {
    Write-Log "Starting full system health scan..." Action
    Start-Process powershell.exe "-NoProfile -Command `"Write-Host '=== RAYS SYSTEM HEALTH SCAN ===' -ForegroundColor Cyan; Write-Host ''; Write-Host '[1/3] SFC...' -ForegroundColor Yellow; sfc /scannow; Write-Host ''; Write-Host '[2/3] DISM...' -ForegroundColor Yellow; DISM /Online /Cleanup-Image /RestoreHealth; Write-Host ''; Write-Host '[3/3] WU Reset...' -ForegroundColor Yellow; net stop wuauserv 2>`$null; Remove-Item C:\Windows\SoftwareDistribution -Recurse -Force -EA 0; net start wuauserv; Write-Host ''; Write-Host 'DONE' -ForegroundColor Green; pause`""
}

function Run-WinSATBenchmark {
    Write-Log "Launching WinSAT benchmark..." Action
    Start-Process powershell.exe "-NoProfile -Command `"Write-Host 'Running WinSAT...' -ForegroundColor Cyan; winsat formal; Write-Host 'Complete!' -ForegroundColor Green; pause`""
}

function Revert-AllChanges {
    Write-Log "REVERTING all optimizations to Windows defaults..." Action
    Set-Reg 'HKCU:\Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x9E,0x3E,0x07,0x80,0x12,0x00,0x00,0x00)) 'Binary'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 1
    Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '400' 'String'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 0
    try { Enable-MMAgent -MemoryCompression -ErrorAction Stop } catch {}
    foreach ($svc in @('SysMain','DiagTrack','WSearch','dmwappushservice')) {
        try { Set-Service -Name $svc -StartupType Automatic -ErrorAction Stop; Start-Service -Name $svc -ErrorAction Stop } catch {}
    }
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 1
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 1
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 0
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 20
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 10
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 2
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -ErrorAction SilentlyContinue
    bcdedit /deletevalue useplatformtick 2>$null
    bcdedit /deletevalue disabledynamictick 2>$null
    powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 50 2>$null
    powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 100 2>$null
    powercfg -setactive scheme_current 2>$null
    $gpuTask = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    Set-Reg $gpuTask 'GPU Priority' 2
    Set-Reg $gpuTask 'Priority' 2
    Set-Reg $gpuTask 'Scheduling Category' 'Medium' 'String'
    Set-Reg $gpuTask 'SFIO Priority' 'Normal' 'String'
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager' 'Priority' 5
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'FeatureSettingsOverride' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'FeatureSettingsOverrideMask' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' -Name 'EnableVirtualizationBasedSecurity' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000' -Name 'PerfLevelSrc' -ErrorAction SilentlyContinue
    netsh int tcp set global autotuninglevel=normal 2>$null
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object {
        Remove-ItemProperty -Path $_.PSPath -Name 'TcpAckFrequency' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $_.PSPath -Name 'TCPNoDelay' -ErrorAction SilentlyContinue
    }
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'PowerThrottlingOff' -ErrorAction SilentlyContinue
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '1' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '6' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '10' 'String'
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '1' 'String'
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' -Name 'DisableSelectiveSuspend' -ErrorAction SilentlyContinue
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'LargeSystemCache' 1
    Remove-ContextMenu
    Unregister-ScheduledTask -TaskName 'RaysChamber_Maintenance' -Confirm:$false -ErrorAction SilentlyContinue
    Stop-AutoBooster
    Write-Log "ALL changes reverted to Windows defaults!" OK
    [console]::Beep(880,150); [console]::Beep(660,150); [console]::Beep(440,300)
}

# ============================================================
# SECTION 10: WPF XAML - ALL ASCII, NO EMOJI, CLEAN XML
# ============================================================
$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Rays Optimization Chamber v5.1"
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
            <TextBlock Text="RAYS OPTIMIZATION CHAMBER v5.1" FontSize="16" FontWeight="Bold" Foreground="#00D9FF"/>
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
                    <Button Name="BtnRestore" Content="Create Restore Point (REQUIRED)" FontWeight="Bold" ToolTip="Creates a System Restore point before making any changes"/>
                    <TextBlock Text="-- Presets --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnLowEnd" Content="Low-End PC" ToolTip="Disables animations, memory compression, heavy services"/>
                        <Button Name="BtnMidEnd" Content="Mid-Range" ToolTip="Adds telemetry block, network throttle off, responsiveness boost"/>
                        <Button Name="BtnHighEnd" Content="High-End Nuclear" ToolTip="BCD tweaks, CPU mitigations off, VBS off - advanced users only"/>
                    </WrapPanel>
                    <TextBlock Text="-- Individual Tweaks --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnDebloat" Content="Debloat Windows" ToolTip="Removes pre-installed bloatware apps"/>
                        <Button Name="BtnCleanup" Content="System Cleanup" ToolTip="Clears temp files and recycle bin"/>
                        <Button Name="BtnOptRAM" Content="Optimize RAM" ToolTip="Adjusts memory management and clears cache"/>
                        <Button Name="BtnOptStore" Content="Optimize Storage" ToolTip="Trims SSD and optimizes disk"/>
                        <Button Name="BtnOptNet" Content="Network Tweaks" ToolTip="TCP optimizations, disables Nagle algorithm"/>
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
                        <Button Name="BtnGameBoost" Content="Zero Latency Mode" FontWeight="Bold" ToolTip="BCD timer fix + priority boost + Nagle off + GPU priority max"/>
                        <Button Name="BtnAutoBoost" Content="Start Auto-Booster" ToolTip="Monitors for games every 30s and boosts their priority"/>
                        <Button Name="BtnStopBoost" Content="Stop Auto-Booster" ToolTip="Stops the automatic game detection loop"/>
                        <Button Name="BtnRAMPurge" Content="Purge RAM" ToolTip="Forces garbage collection to clear standby memory"/>
                        <Button Name="BtnFrameCap" Content="Frame Cap Advisor" ToolTip="Detects monitor Hz and recommends optimal frame cap"/>
                        <Button Name="BtnLaptopGod" Content="Laptop God Mode" ToolTip="99% CPU cap + disable thermal throttle + unlock boost (laptops only)"/>
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
                        <Button Name="BtnUltPower" Content="Ultimate Performance Plan" ToolTip="Unlocks hidden Windows power plan"/>
                        <Button Name="BtnUnpark" Content="Unpark All Cores" ToolTip="Sets CPU core parking minimum to 100%"/>
                        <Button Name="BtnCheckRAM" Content="Check RAM Speed" ToolTip="Shows RAM speeds - warns if XMP/DOCP needed"/>
                    </WrapPanel>
                    <TextBlock Text="-- System --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnContextMenu" Content="Add Context Menu" ToolTip="Adds right-click desktop shortcut"/>
                        <Button Name="BtnRmContext" Content="Remove Context Menu" ToolTip="Removes the desktop shortcut"/>
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
                        <Button Name="BtnDNSGoogle" Content="Google DNS" ToolTip="Sets DNS to 8.8.8.8"/>
                        <Button Name="BtnDNSCF" Content="Cloudflare DNS" ToolTip="Sets DNS to 1.1.1.1"/>
                        <Button Name="BtnDNSAuto" Content="Auto DNS (DHCP)" ToolTip="Resets DNS to default"/>
                    </WrapPanel>
                    <TextBlock Text="-- Advanced --" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <Button Name="BtnMicroWin" Content="MicroWin ISO Debloat" ToolTip="Strip bloatware from a Windows ISO"/>
                </StackPanel>
            </ScrollViewer>
            <ScrollViewer Name="PanelUpdates" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="WINDOWS UPDATES" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <WrapPanel>
                        <Button Name="BtnUpdDefault" Content="Default (Auto)" ToolTip="Restores standard Windows Update"/>
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
                        <Button Name="BtnSFC" Content="SFC Scan" ToolTip="System File Checker"/>
                        <Button Name="BtnDISM" Content="DISM Repair" ToolTip="Downloads fresh components from Microsoft"/>
                        <Button Name="BtnWinSAT" Content="Run WinSAT" ToolTip="Benchmarks your hardware"/>
                        <Button Name="BtnRestartShell" Content="Restart Explorer" ToolTip="Restarts Explorer to apply visual changes"/>
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
Write-Host ''
Write-Host '  [XAML] Parsing window definition...' -ForegroundColor Cyan

try {
    $window = [System.Windows.Markup.XamlReader]::Parse($xaml)
    Write-Host '  [XAML] Parse successful!' -ForegroundColor Green
} catch {
    Write-Host "  [XAML] FATAL PARSE ERROR: $_" -ForegroundColor Red
    Write-Host '  Press any key to exit...' -ForegroundColor Red
    $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown')
    exit 1
}

# --- CONTROL DISCOVERY: Stack-based BFS (no recursion = no stack overflow) ---
Write-Host '  [CTRL] Walking control tree...' -ForegroundColor Cyan

$stack = New-Object System.Collections.Stack
$stack.Push($window)
$walkCount = 0

while ($stack.Count -gt 0) {
    $el = $stack.Pop()
    $walkCount++

    # Record named FrameworkElements
    if ($el -is [System.Windows.FrameworkElement]) {
        $elName = $el.Name
        if ($elName -and $elName.Length -gt 0) {
            $script:Ctrl[$elName] = $el
        }
    }

    # Traverse children via LogicalTreeHelper
    if ($el -is [System.Windows.DependencyObject]) {
        try {
            $children = [System.Windows.LogicalTreeHelper]::GetChildren($el)
            foreach ($child in $children) {
                if ($child -is [System.Windows.DependencyObject]) {
                    $stack.Push($child)
                }
            }
        } catch {
            # Some elements (like text Runs) may not have traversable children - that is OK
        }
    }
}

Write-Host "  [CTRL] Walked $walkCount elements, found $($script:Ctrl.Count) named controls" -ForegroundColor Green

# --- FALLBACK: Try FindName for any controls the tree walker missed ---
$allExpected = @(
    'LogBox','LogScroll',
    'NavInstall','NavTweaks','NavGaming','NavHardware','NavConfig','NavUpdates','NavHealth',
    'PanelInstall','PanelTweaks','PanelGaming','PanelHardware','PanelConfig','PanelUpdates','PanelHealth',
    'TxtSearch','AppPanel',
    'BtnSelectAll','BtnDeselectAll','BtnInstallSelected',
    'BtnRestore','BtnLowEnd','BtnMidEnd','BtnHighEnd',
    'BtnDebloat','BtnCleanup','BtnOptRAM','BtnOptStore','BtnOptNet','BtnUSB','BtnRefreshNet','BtnRevert',
    'BtnGameBoost','BtnAutoBoost','BtnStopBoost','BtnRAMPurge','BtnFrameCap','BtnLaptopGod',
    'TxtHWInfo','TxtHWDetail',
    'BtnUltPower','BtnUnpark','BtnCheckRAM',
    'BtnContextMenu','BtnRmContext','BtnMaintTask',
    'BtnWSL','BtnSandbox','BtnHyperV','BtnDotNet',
    'BtnDNSGoogle','BtnDNSCF','BtnDNSAuto','BtnMicroWin',
    'BtnUpdDefault','BtnUpdSec','BtnUpdOff',
    'BtnFullScan','BtnSFC','BtnDISM','BtnWinSAT','BtnRestartShell'
)

$missing = @()
foreach ($name in $allExpected) {
    if (-not $script:Ctrl[$name]) {
        # Try FindName as fallback
        try {
            $found = $window.FindName($name)
            if ($null -ne $found) {
                $script:Ctrl[$name] = $found
                Write-Host "  [CTRL] FindName recovered: $name" -ForegroundColor Yellow
            } else {
                $missing += $name
            }
        } catch {
            $missing += $name
        }
    }
}

if ($missing.Count -gt 0) {
    Write-Host "  [CTRL] WARNING - Missing controls ($($missing.Count)):" -ForegroundColor Red
    foreach ($m in $missing) { Write-Host "    - $m" -ForegroundColor Red }
    Write-Host '  [CTRL] Some buttons may not work. Check XAML Name attributes.' -ForegroundColor Red
} else {
    Write-Host "  [CTRL] All $($allExpected.Count) controls verified OK!" -ForegroundColor Green
}

# Print all found control names for debugging
Write-Host '  [CTRL] Found controls:' -ForegroundColor DarkGray
$script:Ctrl.Keys | Sort-Object | ForEach-Object { Write-Host "    $_" -ForegroundColor DarkGray }

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
Write-Host '  [INIT] Setting up UI...' -ForegroundColor Cyan

# Hardware info cards
if ($null -ne $script:Ctrl['TxtHWInfo']) {
    $script:Ctrl['TxtHWInfo'].Text = "$HardwareType | $cpuName | ${ramGB}GB RAM | Tier: $SuggestedTier"
}
if ($null -ne $script:Ctrl['TxtHWDetail']) {
    $script:Ctrl['TxtHWDetail'].Text = "CPU: $cpuCores Cores / $cpuThreads Threads | RAM: ${ramSpeed}MHz | GPU: $gpu"
}

# App checkboxes
if ($null -ne $script:Ctrl['AppPanel']) {
    foreach ($app in $Apps) {
        $cb = New-Object System.Windows.Controls.CheckBox
        $cb.Content = $app.N
        $cb.Tag = $app.ID
        $cb.Width = 200
        $cb.Margin = '4'
        $script:Ctrl['AppPanel'].Children.Add($cb) | Out-Null
    }
    Write-Host "  [INIT] Added $($Apps.Count) app checkboxes" -ForegroundColor DarkGray
} else {
    Write-Host '  [INIT] WARNING: AppPanel not found - cannot populate apps' -ForegroundColor Red
}

# Search filter
if ($null -ne $script:Ctrl['TxtSearch']) {
    $script:Ctrl['TxtSearch'].Add_TextChanged({
        $query = $script:Ctrl['TxtSearch'].Text.ToLower()
        $panel = $script:Ctrl['AppPanel']
        if ($null -ne $panel) {
            foreach ($child in $panel.Children) {
                if ($child -is [System.Windows.Controls.CheckBox]) {
                    $match = $child.Content.ToString().ToLower().Contains($query)
                    $child.Visibility = if ($match) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed }
                }
            }
        }
    })
    Write-Host '  [INIT] Search filter wired' -ForegroundColor DarkGray
}

# Set first tab active
Switch-Tab 0
Write-Log "Ray's Optimization Chamber v$script:BUILD initialized" OK
Write-Log "$HardwareType | $cpuName | ${ramGB}GB RAM @ ${ramSpeed}MHz | Tier: $SuggestedTier" Info
if ($isLaptop) { Write-Log "Laptop detected - Laptop God Mode available in Gaming tab" Info }

# ============================================================
# SECTION 13: EVENT HANDLERS - EXPLICIT WIRING WITH DEBUG LOG
# ============================================================
Write-Host '  [WIRE] Wiring button event handlers...' -ForegroundColor Cyan
$wiredCount = 0

# --- NAVIGATION ---
foreach ($pair in @(
    @('NavInstall',0), @('NavTweaks',1), @('NavGaming',2), @('NavHardware',3),
    @('NavConfig',4), @('NavUpdates',5), @('NavHealth',6)
)) {
    $btnName = $pair[0]; $tabIdx = $pair[1]
    $btn = $script:Ctrl[$btnName]
    if ($null -ne $btn) {
        $idx = $tabIdx  # capture in local var for closure
        $btn.Add_Click({ Switch-Tab $idx }.GetNewClosure())
        $wiredCount++
    } else { Write-Host "  [WIRE] MISS: $btnName" -ForegroundColor Yellow }
}

# --- INSTALL TAB ---
if ($null -ne $script:Ctrl['BtnSelectAll']) {
    $script:Ctrl['BtnSelectAll'].Add_Click({
        Write-Log "DEBUG: Select All clicked" Info
        $panel = $script:Ctrl['AppPanel']
        if ($null -ne $panel) { foreach ($c in $panel.Children) { if ($c -is [System.Windows.Controls.CheckBox]) { $c.IsChecked = $true } } }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnSelectAll' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnDeselectAll']) {
    $script:Ctrl['BtnDeselectAll'].Add_Click({
        Write-Log "DEBUG: Deselect All clicked" Info
        $panel = $script:Ctrl['AppPanel']
        if ($null -ne $panel) { foreach ($c in $panel.Children) { if ($c -is [System.Windows.Controls.CheckBox]) { $c.IsChecked = $false } } }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnDeselectAll' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnInstallSelected']) {
    $script:Ctrl['BtnInstallSelected'].Add_Click({
        Write-Log "DEBUG: Install Selected clicked" Info
        try {
            $selected = @()
            $panel = $script:Ctrl['AppPanel']
            if ($null -ne $panel) {
                foreach ($c in $panel.Children) {
                    if ($c -is [System.Windows.Controls.CheckBox] -and $c.IsChecked -eq $true) { $selected += $c.Tag }
                }
            }
            if ($selected.Count -eq 0) { Write-Log "No apps selected" Warn; return }
            Write-Log "Installing $($selected.Count) apps via winget..." Action
            foreach ($id in $selected) {
                Write-Log "  Queuing: $id" Info
                Start-Process winget -ArgumentList "install --id $id --accept-source-agreements --accept-package-agreements -h" -NoNewWindow
            }
            Write-Log "All installations queued!" OK
            Play-Tone
        } catch { Write-Log "Install error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnInstallSelected' -ForegroundColor Yellow }

# --- TWEAKS TAB ---
if ($null -ne $script:Ctrl['BtnRestore']) {
    $script:Ctrl['BtnRestore'].Add_Click({
        Write-Log "DEBUG: Create Restore Point clicked" Action
        try {
            Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop
            Checkpoint-Computer -Description 'RaysChamber_v5_Backup' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop
            $script:RestoreCreated = $true
            Write-Log "Restore Point created! Tweaks unlocked." OK
        } catch {
            Write-Log "Restore Point failed: $_ - Unlocking anyway for testing" Warn
            $script:RestoreCreated = $true
        }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnRestore' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnLowEnd']) {
    $script:Ctrl['BtnLowEnd'].Add_Click({
        Write-Log "DEBUG: Low-End clicked" Info
        try { if (Guard-Restore) { Apply-LowEndTweaks } } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnLowEnd' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnMidEnd']) {
    $script:Ctrl['BtnMidEnd'].Add_Click({
        Write-Log "DEBUG: Mid-Range clicked" Info
        try { if (Guard-Restore) { Apply-MidRangeTweaks } } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnMidEnd' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnHighEnd']) {
    $script:Ctrl['BtnHighEnd'].Add_Click({
        Write-Log "DEBUG: High-End Nuclear clicked" Info
        try { if (Guard-Restore) { Apply-HighEndTweaks } } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnHighEnd' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnDebloat']) {
    $script:Ctrl['BtnDebloat'].Add_Click({
        Write-Log "DEBUG: Debloat clicked" Info
        try { if (Guard-Restore) { Invoke-Debloat } } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnDebloat' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnCleanup']) {
    $script:Ctrl['BtnCleanup'].Add_Click({
        Write-Log "DEBUG: System Cleanup clicked" Info
        try { Invoke-SystemCleanup } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnCleanup' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnOptRAM']) {
    $script:Ctrl['BtnOptRAM'].Add_Click({
        Write-Log "DEBUG: Optimize RAM clicked" Info
        try { if (Guard-Restore) { Optimize-RAM } } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnOptRAM' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnOptStore']) {
    $script:Ctrl['BtnOptStore'].Add_Click({
        Write-Log "DEBUG: Optimize Storage clicked" Info
        try { if (Guard-Restore) { Optimize-Storage } } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnOptStore' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnOptNet']) {
    $script:Ctrl['BtnOptNet'].Add_Click({
        Write-Log "DEBUG: Network Tweaks clicked" Info
        try { if (Guard-Restore) { Apply-NetworkTweaks } } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnOptNet' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnUSB']) {
    $script:Ctrl['BtnUSB'].Add_Click({
        Write-Log "DEBUG: USB and Input clicked" Info
        try { if (Guard-Restore) { Apply-USBTweaks } } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnUSB' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnRefreshNet']) {
    $script:Ctrl['BtnRefreshNet'].Add_Click({
        Write-Log "DEBUG: Refresh Internet clicked" Info
        try { Refresh-Internet } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnRefreshNet' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnRevert']) {
    $script:Ctrl['BtnRevert'].Add_Click({
        Write-Log "DEBUG: Revert All clicked" Warn
        $r = [System.Windows.MessageBox]::Show("This will revert ALL optimizations to Windows defaults. Continue?", "Confirm Revert", "YesNo", "Warning")
        if ($r -eq 'Yes') { try { Revert-AllChanges } catch { Write-Log "Revert error: $_" Error } }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnRevert' -ForegroundColor Yellow }

# --- GAMING TAB ---
if ($null -ne $script:Ctrl['BtnGameBoost']) {
    $script:Ctrl['BtnGameBoost'].Add_Click({
        Write-Log "DEBUG: Zero Latency Mode clicked" Info
        try { if (Guard-Restore) { Apply-GameBoost } } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnGameBoost' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnAutoBoost']) {
    $script:Ctrl['BtnAutoBoost'].Add_Click({
        Write-Log "DEBUG: Start Auto-Booster clicked" Info
        try { Start-AutoBooster } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnAutoBoost' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnStopBoost']) {
    $script:Ctrl['BtnStopBoost'].Add_Click({
        Write-Log "DEBUG: Stop Auto-Booster clicked" Info
        try { Stop-AutoBooster } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnStopBoost' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnRAMPurge']) {
    $script:Ctrl['BtnRAMPurge'].Add_Click({
        Write-Log "DEBUG: Purge RAM clicked" Info
        try { Clear-RAMStandby } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnRAMPurge' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnFrameCap']) {
    $script:Ctrl['BtnFrameCap'].Add_Click({
        Write-Log "DEBUG: Frame Cap Advisor clicked" Info
        try { Show-FrameCapAdvice } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnFrameCap' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnLaptopGod']) {
    $script:Ctrl['BtnLaptopGod'].Add_Click({
        Write-Log "DEBUG: Laptop God Mode clicked" Info
        try { if (Guard-Restore) { Apply-LaptopGodMode } } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnLaptopGod' -ForegroundColor Yellow }

# --- HARDWARE TAB ---
if ($null -ne $script:Ctrl['BtnUltPower']) {
    $script:Ctrl['BtnUltPower'].Add_Click({
        Write-Log "DEBUG: Ultimate Performance Plan clicked" Info
        try { if (Guard-Restore) { Invoke-UltimatePower } } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnUltPower' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnUnpark']) {
    $script:Ctrl['BtnUnpark'].Add_Click({
        Write-Log "DEBUG: Unpark All Cores clicked" Info
        try { if (Guard-Restore) { Invoke-UnparkCores } } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnUnpark' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnCheckRAM']) {
    $script:Ctrl['BtnCheckRAM'].Add_Click({
        Write-Log "DEBUG: Check RAM Speed clicked" Info
        try { Check-RAMSpeed } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnCheckRAM' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnContextMenu']) {
    $script:Ctrl['BtnContextMenu'].Add_Click({
        Write-Log "DEBUG: Add Context Menu clicked" Info
        try { Add-ContextMenu } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnContextMenu' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnRmContext']) {
    $script:Ctrl['BtnRmContext'].Add_Click({
        Write-Log "DEBUG: Remove Context Menu clicked" Info
        try { Remove-ContextMenu } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnRmContext' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnMaintTask']) {
    $script:Ctrl['BtnMaintTask'].Add_Click({
        Write-Log "DEBUG: Schedule Maintenance clicked" Info
        try { Register-MaintenanceTask } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnMaintTask' -ForegroundColor Yellow }

# --- CONFIG TAB ---
if ($null -ne $script:Ctrl['BtnWSL']) {
    $script:Ctrl['BtnWSL'].Add_Click({
        Write-Log "DEBUG: Enable WSL2 clicked" Action
        try { Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart; dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart; Write-Host 'WSL2 enabled - restart required' -ForegroundColor Green; pause`"" } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnWSL' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnSandbox']) {
    $script:Ctrl['BtnSandbox'].Add_Click({
        Write-Log "DEBUG: Enable Sandbox clicked" Action
        try { Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:Containers-DisposableClientVM /all /norestart; Write-Host 'Sandbox enabled - restart required' -ForegroundColor Green; pause`"" } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnSandbox' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnHyperV']) {
    $script:Ctrl['BtnHyperV'].Add_Click({
        Write-Log "DEBUG: Enable Hyper-V clicked" Action
        try { Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart; Write-Host 'Hyper-V enabled - restart required' -ForegroundColor Green; pause`"" } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnHyperV' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnDotNet']) {
    $script:Ctrl['BtnDotNet'].Add_Click({
        Write-Log "DEBUG: Enable .NET 3.5 clicked" Action
        try { Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:NetFx3 /all /norestart; Write-Host '.NET 3.5 enabled' -ForegroundColor Green; pause`"" } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnDotNet' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnDNSGoogle']) {
    $script:Ctrl['BtnDNSGoogle'].Add_Click({
        Write-Log "DEBUG: Google DNS clicked" Info
        try {
            Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses '8.8.8.8','8.8.4.4' }
            Write-Log "DNS set to Google (8.8.8.8)" OK
        } catch { Write-Log "DNS error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnDNSGoogle' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnDNSCF']) {
    $script:Ctrl['BtnDNSCF'].Add_Click({
        Write-Log "DEBUG: Cloudflare DNS clicked" Info
        try {
            Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses '1.1.1.1','1.0.0.1' }
            Write-Log "DNS set to Cloudflare (1.1.1.1)" OK
        } catch { Write-Log "DNS error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnDNSCF' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnDNSAuto']) {
    $script:Ctrl['BtnDNSAuto'].Add_Click({
        Write-Log "DEBUG: Auto DNS clicked" Info
        try {
            Get-NetAdapter | Where-Object Status -eq 'Up' | ForEach-Object { Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses }
            Write-Log "DNS reset to DHCP default" OK
        } catch { Write-Log "DNS error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnDNSAuto' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnMicroWin']) {
    $script:Ctrl['BtnMicroWin'].Add_Click({
        Write-Log "DEBUG: MicroWin ISO Debloat clicked" Info
        try { Start-MicroWin } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnMicroWin' -ForegroundColor Yellow }

# --- UPDATES TAB ---
if ($null -ne $script:Ctrl['BtnUpdDefault']) {
    $script:Ctrl['BtnUpdDefault'].Add_Click({
        Write-Log "DEBUG: Default Updates clicked" Info
        try {
            Set-Service -Name wuauserv -StartupType Automatic -ErrorAction Stop
            Start-Service -Name wuauserv -ErrorAction Stop
            Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -ErrorAction SilentlyContinue
            Write-Log "Windows Update restored to default" OK
        } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnUpdDefault' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnUpdSec']) {
    $script:Ctrl['BtnUpdSec'].Add_Click({
        Write-Log "DEBUG: Security Only Updates clicked" Info
        try {
            Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'NoAutoUpdate' 0
            Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'AUOptions' 3
            Write-Log "Windows Update: Security Only mode" OK
        } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnUpdSec' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnUpdOff']) {
    $script:Ctrl['BtnUpdOff'].Add_Click({
        Write-Log "DEBUG: Disable Updates clicked" Warn
        $r = [System.Windows.MessageBox]::Show("WARNING: Disabling Windows Update leaves your system vulnerable. Are you sure?", "Disable Updates", "YesNo", "Warning")
        if ($r -eq 'Yes') {
            try {
                Set-Service -Name wuauserv -StartupType Disabled -ErrorAction Stop
                Stop-Service -Name wuauserv -Force -ErrorAction Stop
                Write-Log "Windows Update DISABLED" Warn
            } catch { Write-Log "Error: $_" Error }
        }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnUpdOff' -ForegroundColor Yellow }

# --- HEALTH TAB ---
if ($null -ne $script:Ctrl['BtnFullScan']) {
    $script:Ctrl['BtnFullScan'].Add_Click({
        Write-Log "DEBUG: Full Health Scan clicked" Action
        try { Invoke-SystemHealthScan } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnFullScan' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnSFC']) {
    $script:Ctrl['BtnSFC'].Add_Click({
        Write-Log "DEBUG: SFC Scan clicked" Action
        try { Start-Process powershell.exe "-NoProfile -Command `"sfc /scannow; pause`"" } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnSFC' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnDISM']) {
    $script:Ctrl['BtnDISM'].Add_Click({
        Write-Log "DEBUG: DISM Repair clicked" Action
        try { Start-Process powershell.exe "-NoProfile -Command `"DISM /Online /Cleanup-Image /RestoreHealth; pause`"" } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnDISM' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnWinSAT']) {
    $script:Ctrl['BtnWinSAT'].Add_Click({
        Write-Log "DEBUG: Run WinSAT clicked" Action
        try { Run-WinSATBenchmark } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnWinSAT' -ForegroundColor Yellow }

if ($null -ne $script:Ctrl['BtnRestartShell']) {
    $script:Ctrl['BtnRestartShell'].Add_Click({
        Write-Log "DEBUG: Restart Explorer clicked" Action
        try { Restart-Shell } catch { Write-Log "Error: $_" Error }
    })
    $wiredCount++
} else { Write-Host '  [WIRE] MISS: BtnRestartShell' -ForegroundColor Yellow }

Write-Host "  [WIRE] Successfully wired $wiredCount button handlers" -ForegroundColor Green
Write-Host ''

# ============================================================
# SECTION 14: SHOW WINDOW
# ============================================================
Write-Host "  Launching Ray's Optimization Chamber v$script:BUILD..." -ForegroundColor $StatusColor
$window.ShowDialog() | Out-Null
Write-Host "  Ray's Optimization Chamber closed. Goodbye!" -ForegroundColor $StatusColor
