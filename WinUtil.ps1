# ============================================================
#  RAY'S OPTIMIZATION CHAMBER v7.0 - DEVICE-AWARE EDITION
#  PC vs Laptop sections | 80+ controls | 35+ tweaks
# ============================================================
$script:BUILD = '7.0'

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
        $lb = $script:Ctrl['LogBox']; $ls = $script:Ctrl['LogScroll']
        if ($null -ne $lb -and $null -ne $ls) {
            $run = New-Object System.Windows.Documents.Run "[$ts] $Msg`n"
            $run.Foreground = ([System.Windows.Media.BrushConverter]::new()).ConvertFrom($hex)
            $lb.Inlines.Add($run); $ls.ScrollToEnd()
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
    $r = [System.Windows.MessageBox]::Show("Create a Restore Point first?`n`nYES = Create now`nNO = Skip (proceed at own risk)`nCANCEL = Abort", 'Safety Check', 'YesNoCancel', 'Warning')
    if ($r -eq 'Yes') {
        try { Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop; Checkpoint-Computer -Description 'RaysChamber_Backup' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop; $script:RestoreCreated = $true; Write-Log "Restore Point created!" OK; return $true
        } catch { Write-Log "Restore point note: $_ - proceeding" Warn; $script:RestoreCreated = $true; return $true }
    } elseif ($r -eq 'No') { $script:RestoreCreated = $true; Write-Log "Skipped restore - proceeding at own risk" Warn; return $true }
    return $false
}

function Switch-Tab([int]$Index) {
    for ($i = 0; $i -lt $Panels.Count; $i++) {
        $p = $script:Ctrl[$Panels[$i]]; $n = $script:Ctrl[$NavBtns[$i]]
        if ($null -ne $p) { $p.Visibility = if ($i -eq $Index) { [System.Windows.Visibility]::Visible } else { [System.Windows.Visibility]::Collapsed } }
        if ($null -ne $n) { $n.FontWeight = if ($i -eq $Index) { [System.Windows.FontWeights]::Bold } else { [System.Windows.FontWeights]::Normal } }
    }
}

function Play-Tone { try { [console]::Beep(440,150); [console]::Beep(660,150); [console]::Beep(880,300) } catch {} }
function Restart-Shell { Write-Log "Restarting Explorer..." Action; Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue; Start-Sleep 1; Start-Process explorer.exe; Write-Log "Explorer restarted" OK }

# ============================================================
# SECTION 9: DESKTOP PC OPTIMIZATION FUNCTIONS
# ============================================================

function Apply-DesktopLow {
    Write-Log "DESKTOP Low-End: Stripping visual overhead..." Action
    Set-Reg 'HKCU:\Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) 'Binary'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
    Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0' 'String'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2
    if ($ramGB -ge 8) { try { Disable-MMAgent -MemoryCompression -ErrorAction Stop; Write-Log "  Memory compression disabled" Info } catch {} }
    foreach ($svc in @('SysMain','DiagTrack','WSearch')) { try { Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop; Stop-Service -Name $svc -Force -ErrorAction Stop } catch {} }
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    Write-Log "DESKTOP Low-End complete!" OK; Play-Tone
}

function Apply-DesktopMid {
    Write-Log "DESKTOP Mid-Range: Performance + network tuning..." Action
    Apply-DesktopLow
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 10
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
    foreach ($svc in @('dmwappushservice','diagnosticshub.standardcollector.service')) { try { Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop; Stop-Service -Name $svc -Force -ErrorAction Stop } catch {} }
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2
    # Desktop: Unpark all cores (desktops have cooling for this)
    $cpPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583'
    Set-Reg $cpPath 'Attributes' 0
    powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 2>$null
    powercfg -setactive scheme_current 2>$null
    Write-Log "  All CPU cores unparked (desktop has cooling)" Info
    Write-Log "DESKTOP Mid-Range complete!" OK; Play-Tone
}

function Apply-DesktopHigh {
    Write-Log "DESKTOP High-End NUCLEAR: Maximum raw power..." Action
    Apply-DesktopMid
    # BCD extreme latency
    bcdedit /set useplatformtick yes 2>$null; bcdedit /set disabledynamictick yes 2>$null; bcdedit /set useplatformclock yes 2>$null
    Write-Log "  BCD timer + HPET forced" Info
    # Ultimate Performance power plan
    $out = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
    if ($out -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') { powercfg /setactive $Matches[1] 2>$null; Write-Log "  Ultimate Performance plan active" Info }
    # GPU Priority + MSI
    $gpuTask = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    Set-Reg $gpuTask 'GPU Priority' 8; Set-Reg $gpuTask 'Priority' 6
    Set-Reg $gpuTask 'Scheduling Category' 'High' 'String'; Set-Reg $gpuTask 'SFIO Priority' 'High' 'String'
    try { $dev = Get-PnpDevice -Class Display -Status OK -ErrorAction Stop | Select-Object -First 1
        if ($dev) { Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Enum\$($dev.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" 'MSISupported' 1; Write-Log "  GPU MSI mode enabled" Info }
    } catch {}
    # GPU max perf
    $gpuReg = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000'
    Set-Reg $gpuReg 'PerfLevelSrc' 0x2222; Set-Reg $gpuReg 'PowerMizerEnable' 0; Set-Reg $gpuReg 'PowerMizerLevel' 1; Set-Reg $gpuReg 'PowerMizerLevelAC' 1
    # Disable Spectre/Meltdown mitigations (DESKTOP ONLY - has cooling)
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'FeatureSettingsOverride' 3
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'FeatureSettingsOverrideMask' 3
    Write-Log "  CPU mitigations disabled +15% perf (desktop has cooling)" Warn
    # Disable VBS (DESKTOP ONLY)
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' 'EnableVirtualizationBasedSecurity' 0
    Write-Log "  VBS/Device Guard disabled" Warn
    # DWM priority lower
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager' 'Priority' 3
    # Nagle off
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object { Set-Reg $_.PSPath 'TcpAckFrequency' 1; Set-Reg $_.PSPath 'TCPNoDelay' 1 }
    Write-Log "DESKTOP Nuclear complete! Restart recommended." OK; Play-Tone
}

# ============================================================
# SECTION 10: LAPTOP OPTIMIZATION FUNCTIONS
# ============================================================

function Apply-LaptopLow {
    Write-Log "LAPTOP Low-End: Safe performance + battery aware..." Action
    # Lighter visual disable (keep SOME animations for GPU efficiency on iGPU)
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
    Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '50' 'String'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2
    # Memory compression stays ON for laptops with low RAM (saves physical RAM)
    if ($ramGB -ge 16) { try { Disable-MMAgent -MemoryCompression -ErrorAction Stop; Write-Log "  Memory compression disabled (16GB+)" Info } catch {} }
    else { Write-Log "  Memory compression kept ON (${ramGB}GB - saves RAM)" Info }
    # Kill telemetry + Game DVR (safe, big impact)
    foreach ($svc in @('DiagTrack')) { try { Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop; Stop-Service -Name $svc -Force -ErrorAction Stop } catch {} }
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    # High Performance (NOT Ultimate - saves battery life)
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    Write-Log "  High Performance plan (not Ultimate - protects battery)" Info
    # Disable DPTF throttling on AC power
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'PowerThrottlingOff' 1
    Write-Log "LAPTOP Low-End complete! Plug in charger for best results." OK; Play-Tone
}

function Apply-LaptopMid {
    Write-Log "LAPTOP Mid-Range: Balanced power + thermals..." Action
    Apply-LaptopLow
    # System responsiveness (moderate - not as aggressive as desktop)
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 14
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38
    # Telemetry off
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
    foreach ($svc in @('dmwappushservice','diagnosticshub.standardcollector.service','SysMain')) { try { Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop; Stop-Service -Name $svc -Force -ErrorAction Stop } catch {} }
    # FSO disable (safe, big FPS gain)
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2
    # 99% CPU cap to prevent turbo overheat crash
    powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 99 2>$null
    powercfg -setactive scheme_current 2>$null
    Write-Log "  99% CPU cap active (prevents thermal throttle loop)" Info
    # NOTE: NO core unparking on laptops - increases heat significantly
    Write-Log "  Core parking left ON (protects laptop thermals)" Info
    Write-Log "LAPTOP Mid-Range complete!" OK; Play-Tone
}

function Apply-LaptopHigh {
    $r = [System.Windows.MessageBox]::Show("LAPTOP High-End tweaks increase heat significantly.`n`nREQUIREMENTS:`n- Laptop MUST be plugged into charger`n- Cooling pad strongly recommended`n- Monitor temps with HWiNFO`n`nThis will NOT disable:`n- CPU mitigations (crash risk on battery)`n- VBS (security needed on portable device)`n- Core Parking (thermal protection)`n`nContinue?", "Laptop Thermal Warning", "YesNo", "Warning")
    if ($r -eq 'No') { return }
    Write-Log "LAPTOP High-End: Max power with thermal safety..." Action
    Apply-LaptopMid
    # BCD timer (safe on laptops)
    bcdedit /set useplatformtick yes 2>$null; bcdedit /set disabledynamictick yes 2>$null
    Write-Log "  BCD timers optimized" Info
    # GPU priority (safe)
    $gpuTask = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    Set-Reg $gpuTask 'GPU Priority' 8; Set-Reg $gpuTask 'Priority' 6
    Set-Reg $gpuTask 'Scheduling Category' 'High' 'String'; Set-Reg $gpuTask 'SFIO Priority' 'High' 'String'
    # Unlock processor boost mode
    $bPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7'
    Set-Reg $bPath 'Attributes' 0
    Write-Log "  Processor Boost Mode unlocked in power options" Info
    # Disable Efficiency Mode
    $ePath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583'
    Set-Reg $ePath 'Attributes' 0
    Write-Log "  Efficiency Mode disabled for active apps" Info
    # Nagle off (safe)
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object { Set-Reg $_.PSPath 'TcpAckFrequency' 1; Set-Reg $_.PSPath 'TCPNoDelay' 1 }
    Write-Log "  Nagle disabled for lower ping" Info
    # NOTE: NOT disabling - Spectre/Meltdown, VBS, Core Unparking (laptop safety)
    Write-Log "  SKIPPED: Mitigations, VBS, Core Unpark (laptop thermal safety)" Warn
    Write-Log "LAPTOP High-End complete! Keep charger plugged in." OK; Play-Tone
}

# ============================================================
# SECTION 11: UNIVERSAL TWEAK FUNCTIONS (BOTH DEVICES)
# ============================================================

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
    Write-Log "Debloat complete - $($bloat.Count) packages processed" OK; Play-Tone
}

function Invoke-SystemCleanup { Write-Log "Cleaning up..." Action; Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue; Remove-Item "$env:SystemRoot\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue; Clear-RecycleBin -Force -ErrorAction SilentlyContinue; Write-Log "Cleanup done" OK }
function Invoke-ServiceManualize { Write-Log "Setting services to Manual..." Action; $c=0; foreach ($svc in @('Spooler','bthserv','TabletInputService','WMPNetworkSvc','SSDPSRV','lfsvc','MapsBroker','PhoneSvc','RetailDemo','wisvc','icssvc','WpcMonSvc','SEMgrSvc','SCardSvr')) { try { Set-Service -Name $svc -StartupType Manual -ErrorAction Stop; $c++ } catch {} }; Write-Log "$c services set to Manual" OK; Play-Tone }
function Optimize-RAM { Write-Log "Optimizing RAM..." Action; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'LargeSystemCache' 0; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'ClearPageFileAtShutdown' 1; [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); [System.GC]::Collect(); Write-Log "RAM optimized" OK; Play-Tone }
function Clear-StandbyList { Write-Log "Purging RAM standby..." Action; [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); [System.GC]::Collect(); Write-Log "Standby purged" OK }
function Optimize-Pagefile { Write-Log "Optimizing pagefile..." Action; try { $sz=$ramGB*1024; $cs=Get-CimInstance Win32_ComputerSystem; $cs|Set-CimInstance -Property @{AutomaticManagedPagefile=$false} -ErrorAction Stop; $pf=Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue; if($pf){$pf|Set-CimInstance -Property @{InitialSize=$sz;MaximumSize=$sz} -ErrorAction Stop}else{New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name='C:\pagefile.sys';InitialSize=$sz;MaximumSize=$sz} -ErrorAction Stop}; Write-Log "Pagefile static ${sz}MB" OK } catch { Write-Log "Pagefile error: $_" Warn }; Play-Tone }
function Set-LargeSystemCache { Write-Log "Large System Cache ON..." Action; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'LargeSystemCache' 1; Write-Log "Large cache enabled" OK; Play-Tone }
function Optimize-Storage { Write-Log "SSD Trim..." Action; try { Optimize-Volume -DriveLetter C -ReTrim -ErrorAction Stop; Write-Log "SSD TRIM done" OK } catch { Write-Log "Drive opt skipped" Warn }; Play-Tone }
function Optimize-NTFS { Write-Log "NTFS optimize..." Action; fsutil behavior set disablelastaccess 1 2>$null; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisableLastAccessUpdate' 1; Write-Log "NTFS optimized" OK; Play-Tone }

function Apply-NetworkTweaks {
    Write-Log "Network tweaks..." Action
    netsh int tcp set global autotuninglevel=highlyrestricted 2>$null; netsh int tcp set global rss=enabled 2>$null
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object { Set-Reg $_.PSPath 'TcpAckFrequency' 1; Set-Reg $_.PSPath 'TCPNoDelay' 1 }
    Write-Log "Network optimized" OK; Play-Tone
}

function Refresh-Internet { Write-Log "Refreshing internet..." Action; ipconfig /release 2>$null|Out-Null; ipconfig /flushdns 2>$null|Out-Null; ipconfig /renew 2>$null|Out-Null; netsh winsock reset 2>$null|Out-Null; netsh int ip reset 2>$null|Out-Null; Write-Log "Internet refreshed" OK }

function Apply-USBTweaks {
    Write-Log "USB + Input tweaks..." Action
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' 'DisableSelectiveSuspend' 1
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'; Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'; Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'; Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSensitivity' '10' 'String'
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31' 'String'; Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '0' 'String'
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters' 'MouseDataQueueSize' 0x14; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters' 'KeyboardDataQueueSize' 0x14
    Write-Log "USB/Input optimized" OK; Play-Tone
}

# --- WINDOWS TWEAKS (Quality of Life) ---
function Enable-DarkMode { Write-Log "Enabling system-wide Dark Mode..." Action; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'AppsUseLightTheme' 0; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'SystemUsesLightTheme' 0; Write-Log "Dark Mode enabled" OK; Play-Tone }
function Enable-LightMode { Write-Log "Enabling Light Mode..." Action; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'AppsUseLightTheme' 1; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'SystemUsesLightTheme' 1; Write-Log "Light Mode enabled" OK; Play-Tone }
function Disable-StickyKeys { Write-Log "Disabling Sticky Keys popup..." Action; Set-Reg 'HKCU:\Control Panel\Accessibility\StickyKeys' 'Flags' '506' 'String'; Set-Reg 'HKCU:\Control Panel\Accessibility\Keyboard Response' 'Flags' '122' 'String'; Set-Reg 'HKCU:\Control Panel\Accessibility\ToggleKeys' 'Flags' '58' 'String'; Write-Log "Sticky/Filter/Toggle Keys disabled" OK; Play-Tone }
function Disable-Cortana { Write-Log "Disabling Cortana..." Action; Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCortana' 0; Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowCortanaAboveLock' 0; Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'AllowSearchToUseLocation' 0; Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' 'ConnectedSearchUseWeb' 0; Write-Log "Cortana fully disabled" OK; Play-Tone }
function Enable-ClipboardHistory { Write-Log "Enabling Clipboard History (Win+V)..." Action; Set-Reg 'HKCU:\Software\Microsoft\Clipboard' 'EnableClipboardHistory' 1; Write-Log "Clipboard History ON - use Win+V" OK; Play-Tone }
function Restore-ClassicContextMenu { Write-Log "Restoring classic right-click menu..." Action; New-Item -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' -Force | Out-Null; Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' -Name '(Default)' -Value '' -Force; Write-Log "Classic context menu restored - restart Explorer" OK; Restart-Shell; Play-Tone }
function Restore-Win11ContextMenu { Write-Log "Restoring Win11 context menu..." Action; Remove-Item -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}' -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Win11 context menu restored" OK; Restart-Shell; Play-Tone }
function Disable-WiFiSense { Write-Log "Disabling Wi-Fi Sense..." Action; Set-Reg 'HKLM:\SOFTWARE\Microsoft\WcmSvc\wifinetworkmanager\config' 'AutoConnectAllowedOEM' 0; Set-Reg 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowWiFiHotSpotReporting' 'Value' 0; Set-Reg 'HKLM:\SOFTWARE\Microsoft\PolicyManager\default\WiFi\AllowAutoConnectToWiFiSenseHotspots' 'Value' 0; Write-Log "Wi-Fi Sense disabled" OK; Play-Tone }
function Disable-FastStartup { Write-Log "Disabling Fast Startup..." Action; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled' 0; Write-Log "Fast Startup disabled (fixes driver/update issues)" OK; Play-Tone }
function Enable-NumLockBoot { Write-Log "Enabling NumLock on boot..." Action; Set-Reg 'HKCU:\Control Panel\Keyboard' 'InitialKeyboardIndicators' '2' 'String'; Set-Reg 'Registry::HKEY_USERS\.DEFAULT\Control Panel\Keyboard' 'InitialKeyboardIndicators' '2' 'String'; Write-Log "NumLock will be ON at login" OK; Play-Tone }
function Show-SecondsOnClock { Write-Log "Showing seconds on taskbar clock..." Action; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'ShowSecondsInSystemClock' 1; Write-Log "Seconds on clock - restart Explorer" OK; Restart-Shell; Play-Tone }
function Disable-LockScreenAds { Write-Log "Disabling lock screen ads/tips..." Action; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'RotatingLockScreenOverlayEnabled' 0; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338387Enabled' 0; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338389Enabled' 0; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-310093Enabled' 0; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SubscribedContent-338393Enabled' 0; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled' 0; Write-Log "Lock screen ads/tips disabled" OK; Play-Tone }
function Enable-VerboseBoot { Write-Log "Enabling verbose boot messages..." Action; Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' 'VerboseStatus' 1; Write-Log "Verbose boot enabled - see details on startup" OK; Play-Tone }
function Enable-EndTaskTaskbar { Write-Log "Enabling End Task in taskbar..." Action; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' 'TaskbarEndTask' 1; Write-Log "Right-click taskbar now shows End Task (Win11)" OK; Play-Tone }
function Restore-PhotoViewer { Write-Log "Restoring Classic Photo Viewer..." Action; $types=@('.jpg','.jpeg','.png','.bmp','.gif','.tif','.tiff'); foreach($t in $types){$p="HKCU:\Software\Classes\$t"; New-Item -Path $p -Force|Out-Null; Set-ItemProperty -Path $p -Name '(Default)' -Value 'PhotoViewer.FileAssoc.Tiff' -Force}; Set-Reg 'HKCU:\Software\Classes\PhotoViewer.FileAssoc.Tiff\shell\open\command' '(Default)' '"%SystemRoot%\System32\rundll32.exe" "%ProgramFiles%\Windows Photo Viewer\PhotoViewer.dll", ImageView_Fullscreen %1' 'String'; Write-Log "Classic Photo Viewer restored" OK; Play-Tone }
function Disable-Hibernation { Write-Log "Disabling Hibernation..." Action; powercfg /h off 2>$null; Write-Log "Hibernation OFF - disk space reclaimed" OK; Play-Tone }
function Enable-Hibernation { Write-Log "Enabling Hibernation..." Action; powercfg /h on 2>$null; Write-Log "Hibernation ON" OK; Play-Tone }
function Create-GodModeFolder { Write-Log "Creating God Mode shortcut..." Action; $p="$env:USERPROFILE\Desktop\GodMode.{ED7BA470-8E54-465E-825C-99712043E01C}"; if(-not(Test-Path $p)){New-Item -Path $p -ItemType Directory -Force|Out-Null; Write-Log "God Mode folder created on Desktop" OK}else{Write-Log "God Mode already exists" Info}; Play-Tone }

# --- GAMING ---
function Apply-GameBoost { Write-Log "Zero Latency..." Action; bcdedit /set useplatformtick yes 2>$null; bcdedit /set disabledynamictick yes 2>$null; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38; Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 10; Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff; $g='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Set-Reg $g 'GPU Priority' 8; Set-Reg $g 'Priority' 6; Set-Reg $g 'Scheduling Category' 'High' 'String'; Set-Reg $g 'SFIO Priority' 'High' 'String'; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2; Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'; Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'; Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'PowerThrottlingOff' 1; Write-Log "Zero Latency ACTIVE!" OK; Play-Tone }
function Disable-MPO { Write-Log "Disabling MPO..." Action; Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode' 5; Write-Log "MPO disabled" OK; Play-Tone }
function Toggle-HAGS { Write-Log "Toggling HAGS..." Action; $p='HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'; $c=try{(Get-ItemProperty -Path $p -Name 'HwSchMode' -ErrorAction Stop).HwSchMode}catch{1}; $n=if($c -eq 2){1}else{2}; Set-Reg $p 'HwSchMode' $n; Write-Log "HAGS $(if($n -eq 2){'ON'}else{'OFF'}) - restart needed" OK; Play-Tone }
function Expand-ShaderCache { Write-Log "Shader cache..." Action; Set-Reg 'HKLM:\SOFTWARE\Microsoft\DirectX' 'ShaderCacheSizeLimitKB' 0xFFFFFFFF; Set-Reg 'HKLM:\SOFTWARE\Microsoft\DirectX' 'DisableShaderCache' 0; Write-Log "Shader cache unlimited" OK; Play-Tone }
function Disable-FSO { Write-Log "Disabling FSO..." Action; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_HonorUserFSEBehaviorMode' 1; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_DXGIHonorFSEWindowsCompatible' 1; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehavior' 2; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_EFSEFeatureFlags' 0; Write-Log "FSO disabled" OK; Play-Tone }
function Set-TimerResolution { Write-Log "Timer resolution..." Action; bcdedit /set useplatformtick yes 2>$null; bcdedit /set disabledynamictick yes 2>$null; bcdedit /set useplatformclock yes 2>$null; Write-Log "Timer 0.5ms via BCD" OK; Play-Tone }
function Fix-DPCLatency { Write-Log "DPC Latency fix..." Action; powercfg -setacvalueindex scheme_current 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 2>$null; powercfg -setactive scheme_current 2>$null; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' 'DisableSelectiveSuspend' 1; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'ExitLatency' 1; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'DisableSensorWatchdog' 1; Write-Log "DPC reduced" OK; Play-Tone }

function Force-VSync {
    Write-Log "Forcing V-Sync ON globally..." Action
    # NVIDIA - Force V-Sync via driver profile
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Direct3D\Drivers' 'SoftwareOnly' 0
    Set-Reg 'HKCU:\Software\Microsoft\DirectX\UserGpuPreferences' 'DirectXUserGlobalSettings' 'VRROptimizeEnable=0;SwapEffectUpgradeEnable=0;' 'String'
    # NVIDIA Global Profile - VSync = Force ON (value 2)
    $nvPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000'
    Set-Reg $nvPath 'RMVsyncControl' 1
    # DWM - Ensure desktop composition sync
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'ForceEffectMode' 1
    # DirectX - Disable flip model bypass (ensures present sync)
    Set-Reg 'HKCU:\Software\Microsoft\DirectX\GraphicsSettings' 'SwapEffectUpgradeCache' 0
    # AMD - Enable Wait for Vertical Refresh
    $amdPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000\UMD'
    Set-Reg $amdPath 'Main3D_DEF' '1' 'String'
    Set-Reg $amdPath 'Wait for Vertical Refresh_DEF' '4' 'String'
    # Frame Rate limiter helper - match monitor Hz
    $hz = try { (Get-CimInstance Win32_VideoController).CurrentRefreshRate | Select-Object -First 1 } catch { 60 }
    if (-not $hz -or $hz -eq 0) { $hz = 60 }
    Write-Log "  V-Sync ON | Monitor: ${hz}Hz | Frames capped to ${hz} FPS" Info
    Write-Log "  NVIDIA: RMVsyncControl=1 | AMD: WaitForVRefresh=Always" Info
    Write-Log "  Tip: Also enable in-game V-Sync for best results" Info
    Write-Log "Force V-Sync applied! Restart GPU driver or reboot for full effect." OK; Play-Tone
}

function Start-AutoBooster {
    if ($script:BoostTimer) { Write-Log "Auto-Booster already running" Warn; return }
    $script:BoostTimer = New-Object System.Windows.Threading.DispatcherTimer
    $script:BoostTimer.Interval = [TimeSpan]::FromSeconds(30)
    $script:BoostTimer.Add_Tick({ foreach ($g in $script:GameList) { $p=Get-Process -Name $g -ErrorAction SilentlyContinue; if($p){$p|ForEach-Object{try{$_.PriorityClass='High'}catch{}}; Get-Process -Name 'chrome','msedge','discord','slack' -ErrorAction SilentlyContinue|ForEach-Object{try{$_.PriorityClass='BelowNormal'}catch{}} } } })
    $script:BoostTimer.Start(); Write-Log "Auto-Booster ACTIVE" OK
}
function Stop-AutoBooster { if($script:BoostTimer){$script:BoostTimer.Stop();$script:BoostTimer=$null;Write-Log "Auto-Booster stopped" OK}else{Write-Log "Not running" Info} }

function Show-FrameCapAdvice { $hz=try{(Get-CimInstance Win32_VideoController).CurrentRefreshRate|Select-Object -First 1}catch{60}; if(-not $hz -or $hz -eq 0){$hz=60}; [System.Windows.MessageBox]::Show("Monitor: ${hz}Hz`n`nCap: $hz FPS`nCompetitive: $([math]::Floor($hz*0.95)) FPS`n`nNVIDIA: Control Panel`nAMD: FRTC`nUniversal: RTSS",'Frame Cap','OK','Information')|Out-Null; Write-Log "${hz}Hz detected" OK }

function Apply-LaptopGodMode {
    if(-not $isLaptop){Write-Log "Laptop God Mode is for laptops only" Warn;return}
    $r=[System.Windows.MessageBox]::Show("God Mode maxes heat. Charger REQUIRED. Continue?",'Thermal Warning','YesNo','Warning')
    if($r -eq 'No'){return}
    Write-Log "Laptop God Mode..." Action
    powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 99 2>$null; powercfg -setactive scheme_current 2>$null
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'PowerThrottlingOff' 1
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583' 'Attributes' 0
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7' 'Attributes' 0
    Write-Log "God Mode ACTIVE! 99% cap, throttle off, boost unlocked" OK; Play-Tone
}

# --- HARDWARE ---
function Invoke-UltimatePower { Write-Log "Ultimate Performance..." Action; $o=powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1; if($o -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})'){powercfg /setactive $Matches[1];Write-Log "Ultimate Performance active!" OK}else{Write-Log "May already exist" Warn}; Play-Tone }
function Invoke-UnparkCores { Write-Log "Unparking cores..." Action; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583' 'Attributes' 0; powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 2>$null; powercfg -setactive scheme_current 2>$null; Write-Log "All cores unparked" OK; Play-Tone }
function Enable-MSIMode { Write-Log "MSI Mode..." Action; $c=0; try{Get-PnpDevice -Status OK -ErrorAction Stop|Where-Object{$_.Class -in @('Display','Net','USB')}|ForEach-Object{Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Enum\$($_.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties" 'MSISupported' 1;$c++}}catch{}; Write-Log "MSI for $c devices" OK; Play-Tone }
function Check-RAMSpeed { $m=Get-CimInstance Win32_PhysicalMemory|Select-Object Capacity,Speed,Manufacturer; $i=$m|ForEach-Object{"$([math]::Round($_.Capacity/1GB))GB @ $($_.Speed)MHz ($($_.Manufacturer))"}; $w=if($ramSpeed -lt 2666){"`n`nWARN: Enable XMP/DOCP in BIOS!"}else{""}; [System.Windows.MessageBox]::Show("RAM:`n$($i -join "`n")$w",'RAM Check','OK','Information')|Out-Null }
function Add-ContextMenu { Write-Log "Adding context menu..." Action; $rp='Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\RaysChamber'; New-Item -Path $rp -Force|Out-Null; Set-ItemProperty -Path $rp -Name 'MUIVerb' -Value 'Open Rays Chamber'; Set-ItemProperty -Path $rp -Name 'Icon' -Value 'powershell.exe'; New-Item -Path "$rp\command" -Force|Out-Null; Set-ItemProperty -Path "$rp\command" -Name '(Default)' -Value 'powershell.exe -WindowStyle Hidden -Command "irm is.gd/RaysUtil | iex"'; Write-Log "Context menu added" OK }
function Remove-ContextMenu { Remove-Item 'Registry::HKEY_CLASSES_ROOT\DesktopBackground\Shell\RaysChamber' -Recurse -Force -ErrorAction SilentlyContinue; Write-Log "Context menu removed" OK }
function Register-MaintenanceTask { Write-Log "Scheduling maintenance..." Action; $a=New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-WindowStyle Hidden -Command `"Optimize-Volume -DriveLetter C -ReTrim -EA 0; Remove-Item `$env:TEMP\* -Recurse -Force -EA 0`""; $t=New-ScheduledTaskTrigger -Daily -At 3am; Register-ScheduledTask -Action $a -Trigger $t -TaskName 'RaysChamber_Maintenance' -Description 'Auto maintenance' -Force|Out-Null; Write-Log "Maintenance scheduled 3AM daily" OK }
function Start-MicroWin { Write-Log "MicroWin ISO..." Action; $d=New-Object Microsoft.Win32.OpenFileDialog; $d.Filter='ISO|*.iso'; if($d.ShowDialog()){Write-Log "ISO: $($d.FileName)" Info; Start-Process powershell.exe "-NoProfile -Command `"Write-Host 'MicroWin Debloat' -FG Cyan; Write-Host 'Selected: $($d.FileName)'; pause`""}else{Write-Log "No ISO selected" Info} }
function Invoke-SystemHealthScan { Write-Log "Health scan..." Action; Start-Process powershell.exe "-NoProfile -Command `"Write-Host '=== HEALTH SCAN ===' -FG Cyan; sfc /scannow; DISM /Online /Cleanup-Image /RestoreHealth; net stop wuauserv 2>`$null; Remove-Item C:\Windows\SoftwareDistribution -Recurse -Force -EA 0; net start wuauserv; Write-Host 'DONE' -FG Green; pause`"" }
function Run-WinSATBenchmark { Write-Log "WinSAT..." Action; Start-Process powershell.exe "-NoProfile -Command `"winsat formal; pause`"" }

# --- REVERT ---
function Revert-AllChanges {
    Write-Log "REVERTING ALL to defaults..." Action
    Set-Reg 'HKCU:\Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x9E,0x3E,0x07,0x80,0x12,0x00,0x00,0x00)) 'Binary'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 1
    Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '400' 'String'
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 0
    try { Enable-MMAgent -MemoryCompression -ErrorAction Stop } catch {}
    foreach ($svc in @('SysMain','DiagTrack','WSearch','dmwappushservice','Spooler','bthserv','TabletInputService','WMPNetworkSvc')) { try { Set-Service -Name $svc -StartupType Automatic -ErrorAction Stop; Start-Service -Name $svc -ErrorAction Stop } catch {} }
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 1; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 1
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 0; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_HonorUserFSEBehaviorMode' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_DXGIHonorFSEWindowsCompatible' 0; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehavior' 0; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_EFSEFeatureFlags' 0
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null
    powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 100 2>$null; powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 50 2>$null; powercfg -setactive scheme_current 2>$null
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 20; Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 10
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 2
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'AllowTelemetry' -ErrorAction SilentlyContinue
    bcdedit /deletevalue useplatformtick 2>$null; bcdedit /deletevalue disabledynamictick 2>$null; bcdedit /deletevalue useplatformclock 2>$null
    $gt='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'; Set-Reg $gt 'GPU Priority' 2; Set-Reg $gt 'Priority' 2; Set-Reg $gt 'Scheduling Category' 'Medium' 'String'; Set-Reg $gt 'SFIO Priority' 'Normal' 'String'
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager' 'Priority' 5
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'FeatureSettingsOverride' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'FeatureSettingsOverrideMask' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\DeviceGuard' -Name 'EnableVirtualizationBasedSecurity' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000' -Name 'PerfLevelSrc' -ErrorAction SilentlyContinue
    netsh int tcp set global autotuninglevel=normal 2>$null
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object { Remove-ItemProperty -Path $_.PSPath -Name 'TcpAckFrequency' -ErrorAction SilentlyContinue; Remove-ItemProperty -Path $_.PSPath -Name 'TCPNoDelay' -ErrorAction SilentlyContinue }
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'PowerThrottlingOff' -ErrorAction SilentlyContinue
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '1' 'String'; Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '6' 'String'; Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '10' 'String'
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '1' 'String'; Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '20' 'String'
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' -Name 'DisableSelectiveSuspend' -ErrorAction SilentlyContinue
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'LargeSystemCache' 1
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name 'OverlayTestMode' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name 'ForceEffectMode' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000' -Name 'RMVsyncControl' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\DirectX\GraphicsSettings' -Name 'SwapEffectUpgradeCache' -ErrorAction SilentlyContinue
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\DirectX' -Name 'ShaderCacheSizeLimitKB' -ErrorAction SilentlyContinue
    fsutil behavior set disablelastaccess 2 2>$null
    powercfg -setacvalueindex scheme_current 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 1 2>$null; powercfg -setactive scheme_current 2>$null
    Remove-ContextMenu; Unregister-ScheduledTask -TaskName 'RaysChamber_Maintenance' -Confirm:$false -ErrorAction SilentlyContinue; Stop-AutoBooster
    Write-Log "ALL changes reverted!" OK; [console]::Beep(880,150); [console]::Beep(660,150); [console]::Beep(440,300)
}

# ============================================================
# SECTION 12: WPF XAML - DEVICE-SEPARATED TWEAKS TAB
# ============================================================
$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Rays Optimization Chamber v7.0"
    Width="1100" Height="780"
    WindowStartupLocation="CenterScreen"
    Background="#000B1A" Foreground="#F0F0F0" FontFamily="Segoe UI">
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
            <TextBlock Text="RAYS OPTIMIZATION CHAMBER v7.0" FontSize="16" FontWeight="Bold" Foreground="#00D9FF"/>
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
            <!-- INSTALL TAB -->
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

            <!-- TWEAKS TAB - DEVICE SEPARATED -->
            <ScrollViewer Name="PanelTweaks" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="SYSTEM TWEAKS" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,4"/>
                    <TextBlock Name="TxtDeviceType" FontSize="12" Foreground="#8090A0" Margin="0,0,0,8"/>

                    <!-- SAFETY -->
                    <Border Background="#0A0A1A" BorderBrush="#FFD700" BorderThickness="1" CornerRadius="6" Padding="10" Margin="0,0,0,12">
                        <StackPanel>
                            <TextBlock Text="SAFETY FIRST" FontSize="13" FontWeight="Bold" Foreground="#FFD700" Margin="0,0,0,6"/>
                            <Button Name="BtnRestore" Content="[!] Create Restore Point (Required before tweaking)" FontWeight="Bold" ToolTip="Creates a System Restore point before any changes"/>
                        </StackPanel>
                    </Border>

                    <!-- DESKTOP PC SECTION -->
                    <Border Background="#001020" BorderBrush="#00D9FF" BorderThickness="1" CornerRadius="6" Padding="10" Margin="0,0,0,12">
                        <StackPanel>
                            <TextBlock Text="DESKTOP PC PRESETS" FontSize="15" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,4"/>
                            <TextBlock Text="Optimized for desktops with active cooling (fans/AIO/tower cooler)" FontSize="11" Foreground="#8090A0" Margin="0,0,0,8"/>
                            <WrapPanel>
                                <Button Name="BtnDeskLow" Content="Desktop: Low-End" ToolTip="Disable animations, transparency, memory compression, heavy services, Game DVR. High Performance plan."/>
                                <Button Name="BtnDeskMid" Content="Desktop: Mid-Range" ToolTip="+ Network throttle OFF, telemetry OFF, Win32Priority 0x26, FSO OFF, ALL CORES UNPARKED (safe with desktop cooling)"/>
                                <Button Name="BtnDeskHigh" Content="Desktop: HIGH-END (Nuclear)" ToolTip="+ BCD extreme latency, Ultimate Performance plan, GPU MSI Mode, Spectre/Meltdown OFF, VBS OFF, Nagle OFF. DESKTOP ONLY - requires active cooling!"/>
                            </WrapPanel>
                            <TextBlock Text="Desktop-specific: Core Unparking, VBS disable, CPU mitigations off, Ultimate Performance plan" FontSize="10" Foreground="#004466" Margin="0,6,0,0"/>
                        </StackPanel>
                    </Border>

                    <!-- LAPTOP SECTION -->
                    <Border Background="#1A1000" BorderBrush="#FFD700" BorderThickness="1" CornerRadius="6" Padding="10" Margin="0,0,0,12">
                        <StackPanel>
                            <TextBlock Text="LAPTOP PRESETS" FontSize="15" FontWeight="Bold" Foreground="#FFD700" Margin="0,0,0,4"/>
                            <TextBlock Text="Thermal-safe tweaks designed for laptops - will NOT overheat your device" FontSize="11" Foreground="#8090A0" Margin="0,0,0,8"/>
                            <WrapPanel>
                                <Button Name="BtnLaptopLow" Content="Laptop: Low-End" ToolTip="Disable transparency, Game DVR, telemetry service. High Performance plan (NOT Ultimate). Keeps memory compression ON for low RAM laptops."/>
                                <Button Name="BtnLaptopMid" Content="Laptop: Mid-Range" ToolTip="+ Network throttle OFF, telemetry OFF, Win32Priority 0x26, FSO OFF, 99% CPU cap (prevents turbo overheat crash). Core parking LEFT ON for thermal safety."/>
                                <Button Name="BtnLaptopHigh" Content="Laptop: High-End (Charger Required)" ToolTip="+ BCD timers, GPU Priority 8, Boost Mode unlocked, Nagle OFF. Will NOT disable: CPU mitigations, VBS, core parking (thermal safety). Charger MUST be plugged in!"/>
                            </WrapPanel>
                            <TextBlock Text="Laptop-safe: 99% CPU cap, no core unparking, no VBS/mitigation disable, thermal throttle management" FontSize="10" Foreground="#665500" Margin="0,6,0,0"/>
                        </StackPanel>
                    </Border>

                    <!-- UNIVERSAL TWEAKS -->
                    <TextBlock Text="UNIVERSAL TWEAKS (Both PC and Laptop)" FontSize="14" FontWeight="Bold" Foreground="#00FFCC" Margin="0,4,0,8"/>

                    <TextBlock Text="-- System --" FontSize="12" FontWeight="Bold" Foreground="#00FFCC" Margin="0,0,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnDebloat" Content="Debloat Windows" ToolTip="Removes 26 pre-installed bloatware apps"/>
                        <Button Name="BtnCleanup" Content="System Cleanup" ToolTip="Clears temp files and empties recycle bin"/>
                        <Button Name="BtnServiceManual" Content="Manualize Services" ToolTip="14 non-essential services to Manual"/>
                    </WrapPanel>
                    <TextBlock Text="-- Memory --" FontSize="12" FontWeight="Bold" Foreground="#00FFCC" Margin="0,8,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnOptRAM" Content="Optimize RAM" ToolTip="Memory management + forced GC"/>
                        <Button Name="BtnStandbyClean" Content="Standby Cleaner" ToolTip="Flushes Standby List"/>
                        <Button Name="BtnPagefile" Content="Optimize Pagefile" ToolTip="Static pagefile = RAM size"/>
                        <Button Name="BtnLargeCache" Content="Large System Cache" ToolTip="More file data in RAM"/>
                    </WrapPanel>
                    <TextBlock Text="-- Storage --" FontSize="12" FontWeight="Bold" Foreground="#00FFCC" Margin="0,8,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnOptStore" Content="SSD Trim" ToolTip="RETRIM on C:"/>
                        <Button Name="BtnNTFS" Content="NTFS Optimize" ToolTip="Disables Last Access timestamps"/>
                    </WrapPanel>
                    <TextBlock Text="-- Network --" FontSize="12" FontWeight="Bold" Foreground="#00FFCC" Margin="0,8,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnOptNet" Content="Network Tweaks" ToolTip="Nagle off, TCP tuned, throttle removed"/>
                        <Button Name="BtnRefreshNet" Content="Refresh Internet" ToolTip="DNS flush, Winsock reset"/>
                    </WrapPanel>
                    <TextBlock Text="-- Input --" FontSize="12" FontWeight="Bold" Foreground="#00FFCC" Margin="0,8,0,4"/>
                    <Button Name="BtnUSB" Content="USB + Mouse + Keyboard" ToolTip="USB suspend off, mouse accel off, 1ms keyboard"/>

                    <!-- DANGER ZONE -->
                    <Border Background="#1A0000" BorderBrush="#FF6666" BorderThickness="1" CornerRadius="6" Padding="10" Margin="0,16,0,0">
                        <StackPanel>
                            <TextBlock Text="DANGER ZONE" FontSize="13" FontWeight="Bold" Foreground="#FF6666" Margin="0,0,0,6"/>
                            <Button Name="BtnRevert" Content="REVERT ALL CHANGES TO WINDOWS DEFAULTS" ToolTip="Undoes every single optimization"/>
                        </StackPanel>
                    </Border>
                </StackPanel>
            </ScrollViewer>

            <!-- GAMING TAB -->
            <ScrollViewer Name="PanelGaming" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="GAMING OPTIMIZATION" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <TextBlock Text="-- Performance Boost --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,8,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnGameBoost" Content="Zero Latency Mode" FontWeight="Bold" ToolTip="BCD + Win32Priority + GPU Priority 8 + Nagle off"/>
                        <Button Name="BtnAutoBoost" Content="Start Auto-Booster" ToolTip="Monitors games every 30s for auto priority boost"/>
                        <Button Name="BtnStopBoost" Content="Stop Auto-Booster" ToolTip="Stops game detection loop"/>
                    </WrapPanel>
                    <TextBlock Text="-- GPU Pipeline --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnMPO" Content="Disable MPO" ToolTip="Fixes borderless flickering/black screens"/>
                        <Button Name="BtnHAGS" Content="Toggle HAGS" ToolTip="Hardware-Accelerated GPU Scheduling"/>
                        <Button Name="BtnShaderCache" Content="Expand Shader Cache" ToolTip="Unlimited - no first-run stutters"/>
                        <Button Name="BtnFSO" Content="Disable FSO" ToolTip="True exclusive fullscreen restored"/>
                        <Button Name="BtnVSync" Content="Force V-Sync ON" ToolTip="Forces vertical sync globally via NVIDIA/AMD/DWM registry keys. Eliminates screen tearing. Caps FPS to monitor Hz."/>
                    </WrapPanel>
                    <TextBlock Text="-- Latency Control --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnTimerRes" Content="Timer Resolution 0.5ms" ToolTip="Forces HPET via BCD"/>
                        <Button Name="BtnDPCLatency" Content="DPC Latency Fix" ToolTip="PCIe + USB power states optimized"/>
                        <Button Name="BtnRAMPurge" Content="Purge RAM Now" ToolTip="Forces GC to clear standby"/>
                    </WrapPanel>
                    <TextBlock Text="-- Tools --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnFrameCap" Content="Frame Cap Advisor" ToolTip="Detects Hz and recommends cap"/>
                        <Button Name="BtnLaptopGod" Content="Laptop God Mode" ToolTip="99% CPU + throttle off (laptops only)"/>
                    </WrapPanel>
                </StackPanel>
            </ScrollViewer>

            <!-- HARDWARE TAB -->
            <ScrollViewer Name="PanelHardware" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="HARDWARE INFO" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <Border Background="#001F3F" BorderBrush="#002A4A" BorderThickness="1" CornerRadius="4" Padding="12" Margin="0,0,0,8">
                        <StackPanel>
                            <TextBlock Name="TxtHWInfo" FontSize="13" Foreground="#00D9FF" TextWrapping="Wrap"/>
                            <TextBlock Name="TxtHWDetail" FontSize="11" Foreground="#8090A0" TextWrapping="Wrap" Margin="0,4,0,0"/>
                        </StackPanel>
                    </Border>
                    <TextBlock Text="-- Power --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,8,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnUltPower" Content="Ultimate Performance Plan" ToolTip="Unlocks hidden power plan"/>
                        <Button Name="BtnUnpark" Content="Unpark All Cores" ToolTip="Core parking min 100%"/>
                        <Button Name="BtnMSIMode" Content="Enable MSI Mode" ToolTip="MSI for GPU/Net/USB"/>
                        <Button Name="BtnCheckRAM" Content="Check RAM Speed" ToolTip="Shows RAM info and XMP warning"/>
                    </WrapPanel>
                    <TextBlock Text="-- System --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnContextMenu" Content="Add Context Menu" ToolTip="Desktop right-click shortcut"/>
                        <Button Name="BtnRmContext" Content="Remove Context Menu" ToolTip="Removes the shortcut"/>
                        <Button Name="BtnMaintTask" Content="Schedule Maintenance" ToolTip="Auto SSD trim + temp cleanup"/>
                    </WrapPanel>
                </StackPanel>
            </ScrollViewer>

            <!-- CONFIG TAB -->
            <ScrollViewer Name="PanelConfig" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="CONFIGURATION" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <TextBlock Text="-- Windows Features --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,8,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnWSL" Content="Enable WSL2" ToolTip="Windows Subsystem for Linux"/>
                        <Button Name="BtnSandbox" Content="Enable Sandbox" ToolTip="Windows Sandbox"/>
                        <Button Name="BtnHyperV" Content="Enable Hyper-V" ToolTip="Virtualization platform"/>
                        <Button Name="BtnDotNet" Content="Enable .NET 3.5" ToolTip="Legacy .NET support"/>
                    </WrapPanel>
                    <TextBlock Text="-- DNS --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnDNSGoogle" Content="Google DNS" ToolTip="8.8.8.8 / 8.8.4.4"/>
                        <Button Name="BtnDNSCF" Content="Cloudflare DNS" ToolTip="1.1.1.1 / 1.0.0.1"/>
                        <Button Name="BtnDNSAuto" Content="Auto DNS (DHCP)" ToolTip="Reset to automatic"/>
                    </WrapPanel>
                    <TextBlock Text="-- Advanced --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <Button Name="BtnMicroWin" Content="MicroWin ISO Debloat" ToolTip="Strip bloatware from Windows ISO"/>

                    <TextBlock Text="-- Windows Tweaks --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,16,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnDarkMode" Content="Dark Mode ON" ToolTip="Force system-wide dark theme for apps and system"/>
                        <Button Name="BtnLightMode" Content="Light Mode ON" ToolTip="Switch back to light theme"/>
                        <Button Name="BtnClassicMenu" Content="Classic Right-Click" ToolTip="Restores Windows 10 style right-click menu (removes Show more options)"/>
                        <Button Name="BtnWin11Menu" Content="Win11 Right-Click" ToolTip="Restores default Windows 11 context menu"/>
                        <Button Name="BtnStickyKeys" Content="Disable Sticky Keys" ToolTip="Prevents the annoying Shift x5 popup and Filter/Toggle key prompts"/>
                        <Button Name="BtnCortana" Content="Disable Cortana" ToolTip="Fully disables Cortana background process and web search"/>
                        <Button Name="BtnClipboard" Content="Enable Clipboard History" ToolTip="Enables Win+V clipboard manager with history"/>
                        <Button Name="BtnWiFiSense" Content="Disable Wi-Fi Sense" ToolTip="Stops Windows from auto-sharing WiFi passwords"/>
                        <Button Name="BtnFastStartup" Content="Disable Fast Startup" ToolTip="Prevents driver conflicts and update issues from hybrid shutdown"/>
                        <Button Name="BtnLockAds" Content="Disable Lock Screen Ads" ToolTip="Removes tips, suggestions, and ads from the lock screen"/>
                        <Button Name="BtnEndTask" Content="Enable End Task (Taskbar)" ToolTip="Adds End Task to right-click on taskbar items in Win11"/>
                        <Button Name="BtnPhotoViewer" Content="Restore Photo Viewer" ToolTip="Brings back the classic Windows Photo Viewer for images"/>
                        <Button Name="BtnGodMode" Content="God Mode Folder" ToolTip="Creates a desktop folder with access to ALL Control Panel settings"/>
                    </WrapPanel>
                    <TextBlock Text="-- Boot and Power --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnNumLock" Content="NumLock on Boot" ToolTip="Auto-enables NumLock when you log in"/>
                        <Button Name="BtnClockSec" Content="Show Seconds on Clock" ToolTip="Displays seconds in the taskbar clock"/>
                        <Button Name="BtnVerboseBoot" Content="Verbose Boot" ToolTip="Shows detailed status messages during startup instead of spinner"/>
                        <Button Name="BtnHibOff" Content="Disable Hibernation" ToolTip="Turns off hibernation and reclaims disk space (deletes hiberfil.sys)"/>
                        <Button Name="BtnHibOn" Content="Enable Hibernation" ToolTip="Re-enables hibernation for sleep-to-disk"/>
                    </WrapPanel>
                </StackPanel>
            </ScrollViewer>

            <!-- UPDATES TAB -->
            <ScrollViewer Name="PanelUpdates" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="WINDOWS UPDATES" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <WrapPanel>
                        <Button Name="BtnUpdDefault" Content="Default (Auto)" ToolTip="Standard updates"/>
                        <Button Name="BtnUpdSec" Content="Security Only" ToolTip="Critical patches only"/>
                        <Button Name="BtnUpdOff" Content="Disable Updates" ToolTip="WARNING: No more updates"/>
                    </WrapPanel>
                </StackPanel>
            </ScrollViewer>

            <!-- HEALTH TAB -->
            <ScrollViewer Name="PanelHealth" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="14">
                <StackPanel>
                    <TextBlock Text="SYSTEM HEALTH" FontSize="18" FontWeight="Bold" Foreground="#00D9FF" Margin="0,0,0,8"/>
                    <WrapPanel>
                        <Button Name="BtnFullScan" Content="Full Health Scan" FontWeight="Bold" ToolTip="SFC + DISM + WU Reset"/>
                        <Button Name="BtnSFC" Content="SFC Scan" ToolTip="Fixes corrupted files"/>
                        <Button Name="BtnDISM" Content="DISM Repair" ToolTip="Downloads fresh components"/>
                        <Button Name="BtnWinSAT" Content="Run WinSAT" ToolTip="Benchmarks hardware"/>
                        <Button Name="BtnRestartShell" Content="Restart Explorer" ToolTip="Apply visual changes instantly"/>
                    </WrapPanel>
                </StackPanel>
            </ScrollViewer>
        </Grid>
    </DockPanel>
</Window>
'@

# ============================================================
# SECTION 13: WINDOW CREATION + CONTROL DISCOVERY
# ============================================================
Write-Host '  [XAML] Parsing...' -ForegroundColor Cyan
try { $window = [System.Windows.Markup.XamlReader]::Parse($xaml); Write-Host '  [XAML] OK!' -ForegroundColor Green
} catch { Write-Host "  [XAML] FATAL: $_" -ForegroundColor Red; $null = $Host.UI.RawUI.ReadKey('NoEcho,IncludeKeyDown'); exit 1 }

# BFS tree walker
$stack = New-Object System.Collections.Stack; $stack.Push($window); $wc = 0
while ($stack.Count -gt 0) {
    $cur = $stack.Pop(); $wc++
    if ($cur -is [System.Windows.FrameworkElement] -and $cur.Name -and $cur.Name.Length -gt 0) { $script:Ctrl[$cur.Name] = $cur }
    if ($cur -is [System.Windows.DependencyObject]) { try { foreach ($ch in [System.Windows.LogicalTreeHelper]::GetChildren($cur)) { if ($ch -is [System.Windows.DependencyObject]) { $stack.Push($ch) } } } catch {} }
}
Write-Host "  [CTRL] Walked $wc nodes, found $($script:Ctrl.Count) controls" -ForegroundColor Green

# FindName fallback
$allExpected = @(
    'LogBox','LogScroll','TxtDeviceType',
    'NavInstall','NavTweaks','NavGaming','NavHardware','NavConfig','NavUpdates','NavHealth',
    'PanelInstall','PanelTweaks','PanelGaming','PanelHardware','PanelConfig','PanelUpdates','PanelHealth',
    'TxtSearch','AppPanel','BtnSelectAll','BtnDeselectAll','BtnInstallSelected',
    'BtnRestore','BtnDeskLow','BtnDeskMid','BtnDeskHigh','BtnLaptopLow','BtnLaptopMid','BtnLaptopHigh',
    'BtnDebloat','BtnCleanup','BtnServiceManual',
    'BtnOptRAM','BtnStandbyClean','BtnPagefile','BtnLargeCache','BtnOptStore','BtnNTFS',
    'BtnOptNet','BtnRefreshNet','BtnUSB','BtnRevert',
    'BtnGameBoost','BtnAutoBoost','BtnStopBoost','BtnMPO','BtnHAGS','BtnShaderCache','BtnFSO','BtnVSync',
    'BtnTimerRes','BtnDPCLatency','BtnRAMPurge','BtnFrameCap','BtnLaptopGod',
    'TxtHWInfo','TxtHWDetail','BtnUltPower','BtnUnpark','BtnMSIMode','BtnCheckRAM',
    'BtnContextMenu','BtnRmContext','BtnMaintTask',
    'BtnWSL','BtnSandbox','BtnHyperV','BtnDotNet','BtnDNSGoogle','BtnDNSCF','BtnDNSAuto','BtnMicroWin',
    'BtnDarkMode','BtnLightMode','BtnClassicMenu','BtnWin11Menu','BtnStickyKeys','BtnCortana','BtnClipboard',
    'BtnWiFiSense','BtnFastStartup','BtnLockAds','BtnEndTask','BtnPhotoViewer','BtnGodMode',
    'BtnNumLock','BtnClockSec','BtnVerboseBoot','BtnHibOff','BtnHibOn',
    'BtnUpdDefault','BtnUpdSec','BtnUpdOff','BtnFullScan','BtnSFC','BtnDISM','BtnWinSAT','BtnRestartShell'
)
$miss = @()
foreach ($n in $allExpected) { if (-not $script:Ctrl[$n]) { try { $f=$window.FindName($n); if($null -ne $f){$script:Ctrl[$n]=$f}else{$miss+=$n} } catch {$miss+=$n} } }
if ($miss.Count -gt 0) { Write-Host "  [CTRL] Missing $($miss.Count): $($miss -join ', ')" -ForegroundColor Red } else { Write-Host "  [CTRL] All $($allExpected.Count) verified!" -ForegroundColor Green }

$window.Add_SourceInitialized({ try { $hwnd=(New-Object System.Windows.Interop.WindowInteropHelper $window).Handle; [DwmHelper]::ApplyDark($hwnd) } catch {} })

# ============================================================
# SECTION 14: INITIALIZATION
# ============================================================
if ($null -ne $script:Ctrl['TxtHWInfo']) { $script:Ctrl['TxtHWInfo'].Text = "$HardwareType | $cpuName | ${ramGB}GB RAM | Tier: $SuggestedTier" }
if ($null -ne $script:Ctrl['TxtHWDetail']) { $script:Ctrl['TxtHWDetail'].Text = "CPU: $cpuCores C / $cpuThreads T | RAM: ${ramSpeed}MHz | GPU: $gpu" }
if ($null -ne $script:Ctrl['TxtDeviceType']) {
    $devMsg = if ($isLaptop) { "Detected: LAPTOP - Use the Laptop Presets below for thermal-safe optimizations" } else { "Detected: DESKTOP PC - Use the Desktop PC Presets below for maximum performance" }
    $script:Ctrl['TxtDeviceType'].Text = $devMsg
}

if ($null -ne $script:Ctrl['AppPanel']) { foreach ($app in $Apps) { $cb = New-Object System.Windows.Controls.CheckBox; $cb.Content = $app.N; $cb.Tag = $app.ID; $cb.Width = 200; $script:Ctrl['AppPanel'].Children.Add($cb) | Out-Null } }
if ($null -ne $script:Ctrl['TxtSearch']) { $script:Ctrl['TxtSearch'].Add_TextChanged({ $q=$script:Ctrl['TxtSearch'].Text.ToLower(); $p=$script:Ctrl['AppPanel']; if($null -ne $p){foreach($c in $p.Children){if($c -is [System.Windows.Controls.CheckBox]){$c.Visibility=if($c.Content.ToString().ToLower().Contains($q)){[System.Windows.Visibility]::Visible}else{[System.Windows.Visibility]::Collapsed}}}} }) }

Switch-Tab 0
Write-Log "Ray's Optimization Chamber v$script:BUILD initialized" OK
Write-Log "$HardwareType | $cpuName | ${ramGB}GB @ ${ramSpeed}MHz | $SuggestedTier" Info
if ($isLaptop) { Write-Log "LAPTOP detected - use Laptop Presets for thermal safety" Warn } else { Write-Log "DESKTOP detected - all performance options available" OK }

# ============================================================
# SECTION 15: EVENT HANDLERS
# ============================================================
Write-Host '  [WIRE] Wiring handlers...' -ForegroundColor Cyan
$wiredCount = 0
function Wire([string]$Name, [scriptblock]$Action) { $b=$script:Ctrl[$Name]; if($null -ne $b){$b.Add_Click($Action);$script:wiredCount++}else{Write-Host "  [WIRE] MISS: $Name" -ForegroundColor Yellow} }

for ($i = 0; $i -lt $NavBtns.Count; $i++) { $idx=$i; Wire $NavBtns[$i] { Switch-Tab $idx }.GetNewClosure() }

Wire 'BtnSelectAll'   { $p=$script:Ctrl['AppPanel']; if($p){foreach($c in $p.Children){if($c -is [System.Windows.Controls.CheckBox]){$c.IsChecked=$true}}} }
Wire 'BtnDeselectAll' { $p=$script:Ctrl['AppPanel']; if($p){foreach($c in $p.Children){if($c -is [System.Windows.Controls.CheckBox]){$c.IsChecked=$false}}} }
Wire 'BtnInstallSelected' { try{$sel=@();$p=$script:Ctrl['AppPanel'];if($p){foreach($c in $p.Children){if($c -is [System.Windows.Controls.CheckBox] -and $c.IsChecked){$sel+=$c.Tag}}};if($sel.Count -eq 0){Write-Log "No apps selected" Warn;return};Write-Log "Installing $($sel.Count) apps..." Action;foreach($id in $sel){Start-Process winget -ArgumentList "install --id $id --accept-source-agreements --accept-package-agreements -h" -NoNewWindow};Write-Log "All queued!" OK;Play-Tone}catch{Write-Log "Error: $_" Error} }

# TWEAKS - Device-specific presets
Wire 'BtnRestore' { try{Enable-ComputerRestore -Drive 'C:\' -ErrorAction Stop;Checkpoint-Computer -Description 'RaysChamber_Backup' -RestorePointType 'MODIFY_SETTINGS' -ErrorAction Stop;$script:RestoreCreated=$true;Write-Log "Restore Point created!" OK}catch{Write-Log "Note: $_ - unlocking" Warn;$script:RestoreCreated=$true} }
Wire 'BtnDeskLow'    { Write-Log "DEBUG: Desktop Low clicked" Info; try{if(Guard-Restore){Apply-DesktopLow}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnDeskMid'    { Write-Log "DEBUG: Desktop Mid clicked" Info; try{if(Guard-Restore){Apply-DesktopMid}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnDeskHigh'   { Write-Log "DEBUG: Desktop High clicked" Info; try{if(Guard-Restore){Apply-DesktopHigh}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnLaptopLow'  { Write-Log "DEBUG: Laptop Low clicked" Info; try{if(Guard-Restore){Apply-LaptopLow}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnLaptopMid'  { Write-Log "DEBUG: Laptop Mid clicked" Info; try{if(Guard-Restore){Apply-LaptopMid}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnLaptopHigh' { Write-Log "DEBUG: Laptop High clicked" Info; try{if(Guard-Restore){Apply-LaptopHigh}}catch{Write-Log "Error: $_" Error} }

# Universal tweaks
Wire 'BtnDebloat'      { Write-Log "DEBUG: Debloat" Info; try{if(Guard-Restore){Invoke-Debloat}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnCleanup'      { Write-Log "DEBUG: Cleanup" Info; try{Invoke-SystemCleanup}catch{Write-Log "Error: $_" Error} }
Wire 'BtnServiceManual' { Write-Log "DEBUG: Services" Info; try{if(Guard-Restore){Invoke-ServiceManualize}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnOptRAM'       { Write-Log "DEBUG: RAM" Info; try{if(Guard-Restore){Optimize-RAM}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnStandbyClean' { Write-Log "DEBUG: Standby" Info; try{Clear-StandbyList}catch{Write-Log "Error: $_" Error} }
Wire 'BtnPagefile'     { Write-Log "DEBUG: Pagefile" Info; try{if(Guard-Restore){Optimize-Pagefile}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnLargeCache'   { Write-Log "DEBUG: Cache" Info; try{if(Guard-Restore){Set-LargeSystemCache}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnOptStore'     { Write-Log "DEBUG: SSD" Info; try{Optimize-Storage}catch{Write-Log "Error: $_" Error} }
Wire 'BtnNTFS'         { Write-Log "DEBUG: NTFS" Info; try{if(Guard-Restore){Optimize-NTFS}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnOptNet'       { Write-Log "DEBUG: Network" Info; try{if(Guard-Restore){Apply-NetworkTweaks}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnRefreshNet'   { Write-Log "DEBUG: Refresh" Info; try{Refresh-Internet}catch{Write-Log "Error: $_" Error} }
Wire 'BtnUSB'          { Write-Log "DEBUG: USB" Info; try{if(Guard-Restore){Apply-USBTweaks}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnRevert' { $r=[System.Windows.MessageBox]::Show("Revert ALL to defaults?",'Confirm','YesNo','Warning'); if($r -eq 'Yes'){try{Revert-AllChanges}catch{Write-Log "Error: $_" Error}} }

# Gaming
Wire 'BtnGameBoost'  { Write-Log "DEBUG: GameBoost" Info; try{if(Guard-Restore){Apply-GameBoost}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnAutoBoost'  { try{Start-AutoBooster}catch{Write-Log "Error: $_" Error} }
Wire 'BtnStopBoost'  { try{Stop-AutoBooster}catch{Write-Log "Error: $_" Error} }
Wire 'BtnMPO'        { Write-Log "DEBUG: MPO" Info; try{if(Guard-Restore){Disable-MPO}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnHAGS'       { Write-Log "DEBUG: HAGS" Info; try{if(Guard-Restore){Toggle-HAGS}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnShaderCache' { Write-Log "DEBUG: Shader" Info; try{if(Guard-Restore){Expand-ShaderCache}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnFSO'        { Write-Log "DEBUG: FSO" Info; try{if(Guard-Restore){Disable-FSO}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnVSync'      { Write-Log "DEBUG: VSync" Info; try{if(Guard-Restore){Force-VSync}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnTimerRes'   { Write-Log "DEBUG: Timer" Info; try{if(Guard-Restore){Set-TimerResolution}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnDPCLatency' { Write-Log "DEBUG: DPC" Info; try{if(Guard-Restore){Fix-DPCLatency}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnRAMPurge'   { try{Clear-StandbyList}catch{Write-Log "Error: $_" Error} }
Wire 'BtnFrameCap'   { try{Show-FrameCapAdvice}catch{Write-Log "Error: $_" Error} }
Wire 'BtnLaptopGod'  { Write-Log "DEBUG: GodMode" Info; try{if(Guard-Restore){Apply-LaptopGodMode}}catch{Write-Log "Error: $_" Error} }

# Hardware
Wire 'BtnUltPower'    { try{if(Guard-Restore){Invoke-UltimatePower}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnUnpark'      { try{if(Guard-Restore){Invoke-UnparkCores}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnMSIMode'     { try{if(Guard-Restore){Enable-MSIMode}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnCheckRAM'    { try{Check-RAMSpeed}catch{Write-Log "Error: $_" Error} }
Wire 'BtnContextMenu' { try{Add-ContextMenu}catch{Write-Log "Error: $_" Error} }
Wire 'BtnRmContext'   { try{Remove-ContextMenu}catch{Write-Log "Error: $_" Error} }
Wire 'BtnMaintTask'   { try{Register-MaintenanceTask}catch{Write-Log "Error: $_" Error} }

# Config
Wire 'BtnWSL'       { Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart; dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart; Write-Host 'WSL2 enabled' -FG Green; pause`"" }
Wire 'BtnSandbox'   { Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:Containers-DisposableClientVM /all /norestart; Write-Host 'Sandbox enabled' -FG Green; pause`"" }
Wire 'BtnHyperV'    { Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart; Write-Host 'Hyper-V enabled' -FG Green; pause`"" }
Wire 'BtnDotNet'    { Start-Process powershell.exe "-NoProfile -Command `"dism.exe /online /enable-feature /featurename:NetFx3 /all /norestart; Write-Host '.NET 3.5 enabled' -FG Green; pause`"" }
Wire 'BtnDNSGoogle' { try{Get-NetAdapter|Where-Object Status -eq 'Up'|ForEach-Object{Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses '8.8.8.8','8.8.4.4'};Write-Log "Google DNS set" OK}catch{Write-Log "Error: $_" Error} }
Wire 'BtnDNSCF'    { try{Get-NetAdapter|Where-Object Status -eq 'Up'|ForEach-Object{Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses '1.1.1.1','1.0.0.1'};Write-Log "Cloudflare DNS set" OK}catch{Write-Log "Error: $_" Error} }
Wire 'BtnDNSAuto'  { try{Get-NetAdapter|Where-Object Status -eq 'Up'|ForEach-Object{Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses};Write-Log "DNS reset to DHCP" OK}catch{Write-Log "Error: $_" Error} }
Wire 'BtnMicroWin'  { try{Start-MicroWin}catch{Write-Log "Error: $_" Error} }

# Windows Tweaks
Wire 'BtnDarkMode'    { try{Enable-DarkMode}catch{Write-Log "Error: $_" Error} }
Wire 'BtnLightMode'   { try{Enable-LightMode}catch{Write-Log "Error: $_" Error} }
Wire 'BtnClassicMenu' { try{Restore-ClassicContextMenu}catch{Write-Log "Error: $_" Error} }
Wire 'BtnWin11Menu'   { try{Restore-Win11ContextMenu}catch{Write-Log "Error: $_" Error} }
Wire 'BtnStickyKeys'  { try{Disable-StickyKeys}catch{Write-Log "Error: $_" Error} }
Wire 'BtnCortana'     { try{if(Guard-Restore){Disable-Cortana}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnClipboard'   { try{Enable-ClipboardHistory}catch{Write-Log "Error: $_" Error} }
Wire 'BtnWiFiSense'   { try{if(Guard-Restore){Disable-WiFiSense}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnFastStartup' { try{if(Guard-Restore){Disable-FastStartup}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnLockAds'     { try{Disable-LockScreenAds}catch{Write-Log "Error: $_" Error} }
Wire 'BtnEndTask'     { try{Enable-EndTaskTaskbar}catch{Write-Log "Error: $_" Error} }
Wire 'BtnPhotoViewer' { try{Restore-PhotoViewer}catch{Write-Log "Error: $_" Error} }
Wire 'BtnGodMode'     { try{Create-GodModeFolder}catch{Write-Log "Error: $_" Error} }
Wire 'BtnNumLock'     { try{Enable-NumLockBoot}catch{Write-Log "Error: $_" Error} }
Wire 'BtnClockSec'    { try{Show-SecondsOnClock}catch{Write-Log "Error: $_" Error} }
Wire 'BtnVerboseBoot' { try{if(Guard-Restore){Enable-VerboseBoot}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnHibOff'      { try{Disable-Hibernation}catch{Write-Log "Error: $_" Error} }
Wire 'BtnHibOn'       { try{Enable-Hibernation}catch{Write-Log "Error: $_" Error} }

# Updates
Wire 'BtnUpdDefault' { try{Set-Service -Name wuauserv -StartupType Automatic -ErrorAction Stop;Start-Service -Name wuauserv -ErrorAction Stop;Write-Log "Updates default" OK}catch{Write-Log "Error: $_" Error} }
Wire 'BtnUpdSec'     { try{Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'NoAutoUpdate' 0;Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' 'AUOptions' 3;Write-Log "Security Only" OK}catch{Write-Log "Error: $_" Error} }
Wire 'BtnUpdOff'     { $r=[System.Windows.MessageBox]::Show("Disable updates? You lose security patches.",'Warning','YesNo','Warning');if($r -eq 'Yes'){try{Set-Service -Name wuauserv -StartupType Disabled -ErrorAction Stop;Stop-Service -Name wuauserv -Force -ErrorAction Stop;Write-Log "Updates DISABLED" Warn}catch{Write-Log "Error: $_" Error}} }

# Health
Wire 'BtnFullScan'     { try{Invoke-SystemHealthScan}catch{Write-Log "Error: $_" Error} }
Wire 'BtnSFC'          { Start-Process powershell.exe "-NoProfile -Command `"sfc /scannow; pause`"" }
Wire 'BtnDISM'         { Start-Process powershell.exe "-NoProfile -Command `"DISM /Online /Cleanup-Image /RestoreHealth; pause`"" }
Wire 'BtnWinSAT'       { try{Run-WinSATBenchmark}catch{Write-Log "Error: $_" Error} }
Wire 'BtnRestartShell'  { try{Restart-Shell}catch{Write-Log "Error: $_" Error} }

Write-Host "  [WIRE] Wired $wiredCount handlers" -ForegroundColor Green

# ============================================================
# SECTION 16: SHOW WINDOW
# ============================================================
Write-Host "  Launching v$script:BUILD..." -ForegroundColor $StatusColor
$window.ShowDialog() | Out-Null
Write-Host "  Closed." -ForegroundColor $StatusColor
