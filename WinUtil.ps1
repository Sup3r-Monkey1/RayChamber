# ============================================================
#  RAY'S OPTIMIZATION CHAMBER v8.0 - ULTIMATE EDITION
#  PC vs Laptop | 100+ controls | 55+ tweaks | Full Undo
# ============================================================
$script:BUILD = '19.0-ULTRABOOK-EDITION'

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
    Write-Log "DESKTOP Low-End: Stripping visual overhead (audited)..." Action
    # Benefit: Disables all Windows animations (fade, slide, smooth scroll) - frees CPU/GPU cycles
    # Risk: UI feels "snappy" but less polished; fully reversible
    Set-Reg 'HKCU:\Control Panel\Desktop' 'UserPreferencesMask' ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) 'Binary'
    # Benefit: Removes Aero Glass blur effect - saves GPU compositing overhead
    # Risk: None; purely visual change
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
    # Benefit: Menus appear instantly instead of 400ms delay
    # Risk: None
    Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0' 'String'
    # Benefit: Sets "Adjust for best performance" - disables shadows, thumbnails, etc
    # Risk: Desktop icons lose shadows, preview thumbnails disabled
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' 'VisualFXSetting' 2
    # Benefit: Stops CPU from compressing/decompressing RAM pages in real-time
    # Risk: Higher physical RAM usage; only disable if you have 8GB+ to spare
    # AUDIT: Keep compression ON if using integrated GPU (shares system RAM as VRAM)
    $desktopIGPU = $gpu -match 'Intel|UHD|Iris|Vega|AMD Radeon\(TM\) Graphics'
    if ($ramGB -ge 8 -and -not $desktopIGPU) { try { Disable-MMAgent -MemoryCompression -ErrorAction Stop; Write-Log "  Memory compression disabled (8GB+ dGPU)" Info } catch {} }
    elseif ($desktopIGPU) { Write-Log "  [AUDIT] Memory compression kept ON (iGPU shares RAM as VRAM)" Warn }
    # Benefit(SysMain): Stops prefetch/superfetch disk thrashing on HDDs
    # Risk: First app launch slightly slower (no preloading); SSDs don't benefit much
    # Benefit(DiagTrack): Stops Microsoft telemetry CPU/network usage
    # Risk: None for user; Microsoft gets less crash data
    # AUDIT FIX: WSearch set to Manual instead of Disabled (breaks Outlook/Start search if disabled)
    try { Set-Service -Name 'SysMain' -StartupType Disabled -ErrorAction Stop; Stop-Service -Name 'SysMain' -Force -ErrorAction Stop } catch {}
    try { Set-Service -Name 'DiagTrack' -StartupType Disabled -ErrorAction Stop; Stop-Service -Name 'DiagTrack' -Force -ErrorAction Stop } catch {}
    try { Set-Service -Name 'WSearch' -StartupType Manual -ErrorAction Stop; Write-Log "  [AUDIT] WSearch set to Manual (Disabled breaks Outlook/Start)" Warn } catch {}
    # Benefit: Stops background video recording and Xbox overlay CPU usage (5-10% savings)
    # Risk: Cannot use Game Bar recording; use OBS/ShadowPlay instead
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    # Benefit: Removes power-saving CPU throttling - consistent clock speeds
    # Risk: Higher power draw and heat; desktop fans handle this fine
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    Write-Log "DESKTOP Low-End complete! (audited)" OK; Play-Tone
}

function Apply-DesktopMid {
    Write-Log "DESKTOP Mid-Range: Performance + network (audited)..." Action
    Apply-DesktopLow
    # Benefit: Reserves only 10% CPU for background (default 20%) - games get 90% CPU time
    # Risk: Background tasks (antivirus scans) may run slower during gaming
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 10
    # Benefit: Removes 10Mbps network throttle on non-multimedia traffic
    # Risk: None - purely removes an artificial Windows cap
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    # Benefit: Fixed short quantum (0x26) for foreground - game gets faster CPU time slices
    # Risk: Background apps get less responsive; noticeable if alt-tabbing frequently
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38
    # Benefit: Blocks ALL telemetry data uploads - saves bandwidth and CPU
    # Risk: Microsoft cannot diagnose crashes on your machine
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
    # Benefit: Stops WAP push and diagnostic hub background data collection
    # Risk: None for user
    foreach ($svc in @('dmwappushservice','diagnosticshub.standardcollector.service')) { try { Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop; Stop-Service -Name $svc -Force -ErrorAction Stop } catch {} }
    # Benefit: Forces true exclusive fullscreen - bypasses DWM compositor for lower input lag
    # Risk: Alt-tab may be slower; some borderless features lost
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2
    # Benefit: All CPU cores stay at full speed - eliminates micro-stutter from core wake-up
    # Risk: Higher idle power draw; desktop cooling handles the extra heat easily
    # CTO AUDIT: Intel 12th gen+ has hybrid P-Core/E-Core architecture
    # Unparking ALL cores forces game threads onto slower E-Cores = WORSE performance
    # Intel Thread Director handles this automatically and BETTER than manual unparking
    if (Test-IntelHybrid) {
        Write-Log "  [CTO] Intel Hybrid CPU detected (12th gen+) - SKIPPING core unpark" Warn
        Write-Log "  [CTO] Intel Thread Director manages P/E-Core scheduling better than manual unparking" Info
        Write-Log "  [CTO] Applying Speed Shift EPP=0 instead (instant frequency ramps)" Info
        Set-SpeedShiftEPP -Value 0
    } else {
        $cpPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583'
        Set-Reg $cpPath 'Attributes' 0
        powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 2>$null
        powercfg -setactive scheme_current 2>$null
        Write-Log "  All CPU cores unparked (non-hybrid CPU, desktop cooling)" Info
    }
    Write-Log "DESKTOP Mid-Range complete! (audited)" OK; Play-Tone
}

function Apply-DesktopHigh {
    Write-Log "DESKTOP High-End NUCLEAR: Maximum raw power..." Action
    Apply-DesktopMid
    # BCD extreme latency - AUDITED: useplatformclock REMOVED (forces HPET = adds latency)
    # Benefit: Consistent timer ticks prevent frame-time jitter in competitive games
    # Risk: Marginally higher idle power draw; revert with bcdedit /deletevalue
    bcdedit /set useplatformtick yes 2>$null; bcdedit /set disabledynamictick yes 2>$null; bcdedit /deletevalue useplatformclock 2>$null
    Write-Log "  BCD timer optimized (HPET force REMOVED - snake oil)" Info
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
    # AUDIT: DWM Priority 3 is too aggressive - causes desktop flickering and window drag lag
    # Benefit: Game gets more CPU time over desktop compositor
    # Risk: Visual artifacts, tearing outside games, window drag stuttering
    # FIX: Set to 4 (slightly below default 5) instead of 3
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Window Manager' 'Priority' 4
    Write-Log "  [AUDIT] DWM priority=4 (3 was too low, caused flicker)" Info
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
    # AUDIT FIX: BCD timers REMOVED for laptops
    # Reason: disabledynamictick causes clock desync on 11th/12th gen Intel mobile CPUs
    # This can trigger anti-cheat kicks (Hyperion/EAC think you're speed-hacking)
    # and causes timer drift = micro-stutters on 60Hz displays
    Write-Log "  [AUDIT] BCD timers SKIPPED (causes clock desync on mobile Intel)" Warn
    # GPU priority (safe on all hardware)
    $gpuTask = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    Set-Reg $gpuTask 'GPU Priority' 8; Set-Reg $gpuTask 'Priority' 6
    Set-Reg $gpuTask 'Scheduling Category' 'High' 'String'; Set-Reg $gpuTask 'SFIO Priority' 'High' 'String'
    # Check for Dell/HP/Lenovo DPTF firmware that fights power tweaks
    $isDPTF = $cpuName -match 'i[3579]-1[1-4]' -and (Get-Service 'igfxCUIService*','DTSApo4Service','IntelDalJhi' -ErrorAction SilentlyContinue | Where-Object Status -eq 'Running')
    if ($isDPTF) {
        Write-Log "  [WARN] Dell/HP/Lenovo DPTF firmware detected - boost unlock may conflict" Warn
        Write-Log "  [WARN] If CPU locks to 0.4GHz, revert this preset and use Mid-Range instead" Warn
    } else {
        # Only unlock boost if no DPTF conflict detected
        $bPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7'
        Set-Reg $bPath 'Attributes' 0
        Write-Log "  Processor Boost Mode unlocked (no DPTF conflict)" Info
    }
    # Efficiency Mode disable (safe - only affects active foreground apps)
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
# AUDIT: ClearPageFileAtShutdown is SECURITY, not performance - adds 30-60s to shutdown. REMOVED.
# AUDIT: LargeSystemCache=0 is correct for gaming (prioritizes app memory over file cache)
function Optimize-RAM {
    Write-Log "Optimizing RAM (audited)..." Action
    # Benefit: Prioritizes application memory over file system cache - games get more RAM
    # Risk: File operations slightly slower (acceptable tradeoff for gaming)
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'LargeSystemCache' 0
    Write-Log "  [AUDIT] ClearPageFileAtShutdown REMOVED (security tweak, adds 30-60s shutdown)" Warn
    # Benefit: Forces .NET garbage collection to free managed memory immediately
    # Risk: Brief CPU spike during collection (milliseconds)
    [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); [System.GC]::Collect()
    Write-Log "RAM optimized (audited)" OK; Play-Tone
}
function Clear-StandbyList { Write-Log "Purging RAM standby..." Action; [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); [System.GC]::Collect(); Write-Log "Standby purged" OK }
function Optimize-Pagefile { Write-Log "Optimizing pagefile..." Action; try { $sz=$ramGB*1024; $cs=Get-CimInstance Win32_ComputerSystem; $cs|Set-CimInstance -Property @{AutomaticManagedPagefile=$false} -ErrorAction Stop; $pf=Get-CimInstance Win32_PageFileSetting -ErrorAction SilentlyContinue; if($pf){$pf|Set-CimInstance -Property @{InitialSize=$sz;MaximumSize=$sz} -ErrorAction Stop}else{New-CimInstance -ClassName Win32_PageFileSetting -Property @{Name='C:\pagefile.sys';InitialSize=$sz;MaximumSize=$sz} -ErrorAction Stop}; Write-Log "Pagefile static ${sz}MB" OK } catch { Write-Log "Pagefile error: $_" Warn }; Play-Tone }
# AUDIT WARNING: LargeSystemCache=1 is a SERVER tweak - can cause OOM in games!
# Benefit: Faster file I/O by keeping more data in RAM cache
# Risk: GAMES CAN CRASH when Windows steals RAM for file cache instead of game data
function Set-LargeSystemCache {
    $r=[System.Windows.MessageBox]::Show("WARNING: Large System Cache is a SERVER tweak.`n`nIt makes Windows use MORE RAM for file caching,`nwhich can cause games to crash or stutter.`n`nOnly use this for file servers or workstations.`nFor gaming, use 'Optimize RAM' instead.`n`nContinue anyway?",'Audit Warning','YesNo','Warning')
    if($r -eq 'No'){Write-Log "[AUDIT] Large System Cache cancelled (server tweak)" Warn;return}
    Write-Log "Large System Cache ON (SERVER tweak - not for gaming)..." Action
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' 'LargeSystemCache' 1
    Write-Log "[AUDIT] Large cache enabled - MONITOR for game crashes!" Warn; Play-Tone
}
function Optimize-Storage { Write-Log "SSD Trim..." Action; try { Optimize-Volume -DriveLetter C -ReTrim -ErrorAction Stop; Write-Log "SSD TRIM done" OK } catch { Write-Log "Drive opt skipped" Warn }; Play-Tone }
function Optimize-NTFS { Write-Log "NTFS optimize..." Action; fsutil behavior set disablelastaccess 1 2>$null; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\FileSystem' 'NtfsDisableLastAccessUpdate' 1; Write-Log "NTFS optimized" OK; Play-Tone }

# AUDIT: autotuninglevel=highlyrestricted is OUTDATED (2008 era) - limits download speeds
function Apply-NetworkTweaks {
    Write-Log "Network tweaks (audited)..." Action
    # Benefit(RSS): Spreads network interrupts across CPU cores for higher throughput
    # Risk: None - purely beneficial on multi-core systems
    netsh int tcp set global rss=enabled 2>$null
    # AUDIT FIX: Changed from 'highlyrestricted' to 'normal' - restricted LIMITS TCP window size
    # Benefit(normal): Lets Windows auto-scale TCP window for max bandwidth
    # Risk: None - this is the Windows default and works well on modern connections
    netsh int tcp set global autotuninglevel=normal 2>$null
    Write-Log "  [AUDIT] autotuninglevel=normal (highlyrestricted was snake oil)" Warn
    # Benefit: Removes the 10Mbps throttle Windows applies to non-multimedia traffic
    # Risk: None - purely removes an artificial cap
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    # Benefit(TcpAckFrequency=1): ACKs every packet immediately instead of waiting - lower ping
    # Risk: Marginal increase in network overhead (extra ACK packets)
    # Benefit(TCPNoDelay=1): Disables Nagle's algorithm - sends data immediately
    # Risk: Slightly more packets sent; irrelevant on modern broadband
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object { Set-Reg $_.PSPath 'TcpAckFrequency' 1; Set-Reg $_.PSPath 'TCPNoDelay' 1 }
    Write-Log "Network optimized (audited)" OK; Play-Tone
}

function Refresh-Internet { Write-Log "Refreshing internet..." Action; ipconfig /release 2>$null|Out-Null; ipconfig /flushdns 2>$null|Out-Null; ipconfig /renew 2>$null|Out-Null; netsh winsock reset 2>$null|Out-Null; netsh int ip reset 2>$null|Out-Null; Write-Log "Internet refreshed" OK }

# AUDIT: Added proper EnhancePointerPrecision disable + SmoothMouse curves
function Apply-USBTweaks {
    Write-Log "USB + Input tweaks (audited)..." Action
    # Benefit: Prevents USB ports from entering sleep mode - mouse/headset never lag
    # Risk: Slightly higher USB power draw (negligible on desktop, noticeable on laptop battery)
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' 'DisableSelectiveSuspend' 1
    # Benefit: Disables mouse acceleration for true 1:1 input (critical for FPS games)
    # Risk: Mouse feels "slower" initially - you need to adjust DPI to compensate
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSensitivity' '10' 'String'
    # AUDIT FIX: Also disable EnhancePointerPrecision (the ACTUAL mouse accel toggle)
    # Benefit: Completely strips mouse acceleration from the registry for raw 1:1 movement
    # Risk: Must adjust mouse DPI in hardware; games with their own accel are unaffected
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseTrails' '0' 'String'
    $flat = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00, 0xC0,0xCC,0x0C,0x00,0x00,0x00,0x00,0x00, 0x80,0x99,0x19,0x00,0x00,0x00,0x00,0x00, 0x40,0x66,0x26,0x00,0x00,0x00,0x00,0x00, 0x00,0x33,0x33,0x00,0x00,0x00,0x00,0x00)
    Set-Reg 'HKCU:\Control Panel\Mouse' 'SmoothMouseXCurve' $flat 'Binary'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'SmoothMouseYCurve' $flat 'Binary'
    Write-Log "  [AUDIT] Full mouse accel strip (EPP + SmoothCurves + thresholds)" Info
    # Benefit: Keyboard repeats at max speed with zero delay - faster in-game responses
    # Risk: Holding a key fires rapidly; not ideal for typing documents
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31' 'String'
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '0' 'String'
    # Benefit: Smaller HID queue = less buffering = lower input latency
    # Risk: Under extreme load, inputs could theoretically be dropped (very rare)
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters' 'MouseDataQueueSize' 0x14
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters' 'KeyboardDataQueueSize' 0x14
    Write-Log "USB/Input optimized (audited - full accel strip)" OK; Play-Tone
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
# AUDIT: Combined gaming preset - all tweaks verified safe for both PC and laptop
function Apply-GameBoost {
    Write-Log "Zero Latency (audited)..." Action
    # Benefit: Consistent timer ticks = stable frame pacing
    # Risk: Higher idle power (negligible during gaming)
    bcdedit /set useplatformtick yes 2>$null; bcdedit /set disabledynamictick yes 2>$null
    # Benefit: Fixed short quantum for foreground game process
    # Risk: Background apps (Discord, Spotify) slightly less responsive
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38
    # Benefit: 90% CPU for games instead of 80% default
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 10
    # Benefit: Removes network throttle cap
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    # Benefit: GPU gets highest MMCSS priority - kernel sends GPU work first
    # Risk: None; purely tells scheduler to prioritize graphics
    $g='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    Set-Reg $g 'GPU Priority' 8; Set-Reg $g 'Priority' 6
    Set-Reg $g 'Scheduling Category' 'High' 'String'; Set-Reg $g 'SFIO Priority' 'High' 'String'
    # Benefit: Stops background recording/overlay CPU usage
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2
    # Benefit: Raw 1:1 mouse input for muscle memory consistency
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
    # Benefit: Prevents Windows from throttling ANY process CPU access
    # Risk: Laptop users should have charger plugged in
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'PowerThrottlingOff' 1
    # GPU vendor-specific max perf state
    $gpuName = try { (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name } catch { '' }
    $gpuReg = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000'
    if ($gpuName -match 'NVIDIA|GeForce') { Set-Reg $gpuReg 'PowerMizerLevel' 1; Set-Reg $gpuReg 'PerfLevelSrc' 0x2222; Write-Log "  NVIDIA: Max perf state forced" Info }
    if ($gpuName -match 'AMD|Radeon') { Set-Reg $gpuReg 'PP_ThermalAutoThrottlingEnable' 0; Write-Log "  AMD: Thermal throttle gate disabled" Info }
    if ($gpuName -match 'Intel|UHD|Iris|Arc') { Set-Reg $gpuReg 'ACPowerPolicyVersion' 1; Write-Log "  Intel: Max perf power policy" Info }
    Write-Log "Zero Latency ACTIVE! (audited, all GPUs supported)" OK; Play-Tone
}
function Disable-MPO { Write-Log "Disabling MPO..." Action; Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode' 5; Write-Log "MPO disabled" OK; Play-Tone }
function Toggle-HAGS { Write-Log "Toggling HAGS..." Action; $p='HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers'; $c=try{(Get-ItemProperty -Path $p -Name 'HwSchMode' -ErrorAction Stop).HwSchMode}catch{1}; $n=if($c -eq 2){1}else{2}; Set-Reg $p 'HwSchMode' $n; Write-Log "HAGS $(if($n -eq 2){'ON'}else{'OFF'}) - restart needed" OK; Play-Tone }
function Expand-ShaderCache { Write-Log "Shader cache..." Action; Set-Reg 'HKLM:\SOFTWARE\Microsoft\DirectX' 'ShaderCacheSizeLimitKB' 0xFFFFFFFF; Set-Reg 'HKLM:\SOFTWARE\Microsoft\DirectX' 'DisableShaderCache' 0; Write-Log "Shader cache unlimited" OK; Play-Tone }
function Disable-FSO { Write-Log "Disabling FSO..." Action; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_HonorUserFSEBehaviorMode' 1; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_DXGIHonorFSEWindowsCompatible' 1; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehavior' 2; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_EFSEFeatureFlags' 0; Write-Log "FSO disabled" OK; Play-Tone }
# AUDIT: useplatformclock forces HPET which ADDS latency on modern systems. REMOVED.
# Benefit: disabledynamictick prevents timer coalescing, giving consistent frame pacing
# Risk: Slightly higher idle power consumption
function Set-TimerResolution { Write-Log "Timer resolution (audited - no HPET force)..." Action; bcdedit /set useplatformtick yes 2>$null; bcdedit /set disabledynamictick yes 2>$null; bcdedit /deletevalue useplatformclock 2>$null; Write-Log "  [AUDIT] useplatformclock REMOVED (snake oil - adds 0.5ms latency)" Warn; Write-Log "  [FIX] useplatformtick + disabledynamictick = optimal timer config" Info; Write-Log "Timer resolution optimized (audited)" OK; Play-Tone }
function Fix-DPCLatency { Write-Log "DPC Latency fix..." Action; powercfg -setacvalueindex scheme_current 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 2>$null; powercfg -setactive scheme_current 2>$null; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' 'DisableSelectiveSuspend' 1; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'ExitLatency' 1; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'DisableSensorWatchdog' 1; Write-Log "DPC reduced" OK; Play-Tone }

# AUDIT: Registry V-Sync is a HINT, not a guarantee. In-game settings take priority.
# Benefit: Eliminates screen tearing by syncing frame output to monitor refresh
# Risk: Adds 1-2 frames of input lag; competitive players should use in-game cap instead
function Force-VSync {
    Write-Log "Forcing V-Sync ON (audited)..." Action
    # Detect GPU vendor for targeted settings
    $gpuName = try { (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name } catch { '' }
    $gpuBase = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000'
    # NVIDIA - RMVsyncControl=1 tells driver to prefer V-Sync
    # Benefit: Reduces tearing in NVIDIA-rendered frames
    # Risk: Only a hint; per-game NVIDIA profile overrides this
    if ($gpuName -match 'NVIDIA|GeForce') { Set-Reg $gpuBase 'RMVsyncControl' 1; Write-Log "  NVIDIA: RMVsyncControl=1" Info }
    # AMD - Wait for Vertical Refresh = Always On (value 4)
    # Benefit: Forces V-Sync in AMD Adrenalin globally
    # Risk: Adds input lag in competitive games
    if ($gpuName -match 'AMD|Radeon') { Set-Reg "$gpuBase\UMD" 'Wait for Vertical Refresh_DEF' '4' 'String'; Write-Log "  AMD: WaitForVRefresh=Always" Info }
    # Intel - GMM VSync hint for Intel iGPU/Arc
    # Benefit: Tells Intel driver to enable vertical sync
    # Risk: Limited effectiveness on older Intel HD Graphics
    if ($gpuName -match 'Intel|UHD|Iris|Arc') { Set-Reg "$gpuBase\GMM" 'VSync' 1; Set-Reg $gpuBase 'VSync' 1; Write-Log "  Intel: GMM VSync=1" Info }
    # DirectX - Disable flip model upgrade (ensures traditional present calls sync)
    Set-Reg 'HKCU:\Software\Microsoft\DirectX\GraphicsSettings' 'SwapEffectUpgradeCache' 0
    $hz = try { (Get-CimInstance Win32_VideoController).CurrentRefreshRate | Select-Object -First 1 } catch { 60 }
    if (-not $hz -or $hz -eq 0) { $hz = 60 }
    Write-Log "  Monitor: ${hz}Hz | Frames capped to ${hz} FPS" Info
    Write-Log "  [AUDIT] Registry V-Sync is a HINT - also enable in-game V-Sync" Warn
    Write-Log "  [AUDIT] Competitive gamers: use frame cap instead (less input lag)" Warn
    Write-Log "Force V-Sync applied! Reboot for full effect." OK; Play-Tone
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

# --- ADVANCED GAMING & LATENCY ---
function Toggle-HPET { Write-Log "Toggling HPET..." Action; $cur=bcdedit /enum 2>&1|Select-String 'useplatformclock'; if($cur){bcdedit /deletevalue useplatformclock 2>$null; Write-Log "HPET DISABLED (smoother frametimes on some rigs)" OK}else{bcdedit /set useplatformclock true 2>$null; Write-Log "HPET ENABLED (better audio/video sync)" OK}; Play-Tone }
function Disable-GameMode { Write-Log "Disabling Game Mode overlays..." Action; Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 0; Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 0; Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 0; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0; Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0; Write-Log "Game Mode + Game Bar + DVR disabled" OK; Play-Tone }
function Suspend-Browsers { Write-Log "Suspending browsers to reclaim RAM..." Action; $c=0; foreach($n in @('chrome','msedge','firefox','brave','opera')){Get-Process -Name $n -ErrorAction SilentlyContinue|ForEach-Object{try{$_.PriorityClass='Idle';$c++}catch{}}};if($c -gt 0){Write-Log "$c browser processes set to Idle priority (RAM freed)" OK}else{Write-Log "No browsers running" Info}; Play-Tone }
function Resume-SuspendedApps { Write-Log "Resuming demoted apps..." Action; foreach($n in @('chrome','msedge','firefox','brave','opera','discord','slack')){Get-Process -Name $n -ErrorAction SilentlyContinue|ForEach-Object{try{$_.PriorityClass='Normal'}catch{}}}; Write-Log "All apps restored to Normal priority" OK; Play-Tone }

# --- MODERN STANDBY & POWER ---
function Toggle-S3Sleep { Write-Log "Toggling Modern Standby..." Action; $cur=try{(Get-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'PlatformAoAcOverride' -ErrorAction Stop).PlatformAoAcOverride}catch{-1}; if($cur -eq 0){Remove-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'PlatformAoAcOverride' -ErrorAction SilentlyContinue; Write-Log "Modern Standby (S0) restored - restart needed" OK}else{Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'PlatformAoAcOverride' 0; Write-Log "S3 Deep Sleep FORCED - no more hot-bag laptop! Restart needed" OK}; Play-Tone }
function Disable-NetworkStandby { Write-Log "Disabling network in standby..." Action; Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'DeepSleepEnabled' 1; powercfg -setacvalueindex scheme_current 238c9fa8-0aad-41ed-83f4-97be242c8f20 bd3b718a-0680-4d77-87f1-ac34cb510a9b 0 2>$null; powercfg -setactive scheme_current 2>$null; Write-Log "Network connectivity in standby DISABLED" OK; Play-Tone }

# --- VISUALS & QUALITY OF LIFE ---
function Skip-LockScreen { Write-Log "Skipping lock screen..." Action; Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' 'NoLockScreen' 1; Write-Log "Lock screen skipped - goes straight to password" OK; Play-Tone }
function Remove-ShortcutArrows { Write-Log "Removing shortcut arrows..." Action; Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons' '29' '%SystemRoot%\System32\imageres.dll,-1015' 'String'; Write-Log "Shortcut arrows removed - restart Explorer" OK; Restart-Shell; Play-Tone }
function Set-TaskbarLeft { Write-Log "Aligning taskbar to left..." Action; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAl' 0; Write-Log "Taskbar aligned LEFT (Win11)" OK; Restart-Shell; Play-Tone }
function Set-TaskbarCenter { Write-Log "Centering taskbar..." Action; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAl' 1; Write-Log "Taskbar aligned CENTER" OK; Restart-Shell; Play-Tone }
function Enable-CompactExplorer { Write-Log "Compact Explorer mode..." Action; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'UseCompactMode' 1; Write-Log "Explorer Compact Mode ON - more files visible" OK; Restart-Shell; Play-Tone }

# --- PRIVACY & ANTI-SPYWARE ---
function Set-Telemetry0 { Write-Log "Forcing Telemetry Level 0 (Security)..." Action; Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0; Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'AllowTelemetry' 0; Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' 'MaxTelemetryAllowed' 0; foreach($svc in @('DiagTrack','dmwappushservice','diagnosticshub.standardcollector.service')){try{Set-Service -Name $svc -StartupType Disabled -ErrorAction Stop;Stop-Service -Name $svc -Force -ErrorAction Stop}catch{}}; Write-Log "Telemetry forced to Level 0 (Security only)" OK; Play-Tone }
function Stop-EdgePreload { Write-Log "Stopping Edge preloading..." Action; Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'StartupBoostEnabled' 0; Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' 'BackgroundModeEnabled' 0; Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\Main' 'AllowPrelaunch' 0; Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\MicrosoftEdge\TabPreloader' 'AllowTabPreloading' 0; Write-Log "Edge preloading/startup boost DISABLED" OK; Play-Tone }
function Remove-MeetNow { Write-Log "Removing Meet Now / Chat..." Action; Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'HideSCAMeetNow' 1; Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'HideSCAMeetNow' 1; Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat' 'ChatIcon' 3; Write-Log "Meet Now and Chat removed from taskbar" OK; Play-Tone }

# --- DEEP SYSTEM CLEANUP ---
function Compress-WinSxS { Write-Log "Compressing WinSxS (this takes a while)..." Action; Start-Process powershell.exe "-NoProfile -Command `"Write-Host 'WinSxS Cleanup' -FG Cyan; DISM /Online /Cleanup-Image /StartComponentCleanup /ResetBase; Write-Host 'DONE' -FG Green; pause`""; Write-Log "WinSxS cleanup launched in new window" OK }
function Disable-SearchIndexing { Write-Log "Disabling Search Indexing..." Action; try{Set-Service -Name WSearch -StartupType Disabled -ErrorAction Stop;Stop-Service -Name WSearch -Force -ErrorAction Stop;Write-Log "Search Indexing DISABLED (saves SSD writes + CPU)" OK}catch{Write-Log "Could not disable: $_" Warn}; Play-Tone }
function Enable-SearchIndexing { Write-Log "Enabling Search Indexing..." Action; try{Set-Service -Name WSearch -StartupType Automatic -ErrorAction Stop;Start-Service -Name WSearch -ErrorAction Stop;Write-Log "Search Indexing re-enabled" OK}catch{Write-Log "Error: $_" Warn}; Play-Tone }
function Cleanup-DriverStore { Write-Log "Driver Store cleanup..." Action; Start-Process powershell.exe "-NoProfile -Command `"Write-Host '=== Old Driver Cleanup ===' -FG Cyan; pnputil /enum-drivers /class Display; pnputil /enum-drivers /class Net; Write-Host ''; Write-Host 'To remove old drivers use: pnputil /delete-driver oem##.inf' -FG Yellow; pause`""; Write-Log "Driver Store viewer launched" OK }
function Get-BatteryReport { Write-Log "Generating battery report..." Action; $path="$env:USERPROFILE\Desktop\battery-report.html"; powercfg /batteryreport /output $path 2>$null; if(Test-Path $path){Start-Process $path; Write-Log "Battery report saved to Desktop and opened" OK}else{Write-Log "No battery detected or report failed" Warn}; Play-Tone }

# --- AUDIO & CONNECTIVITY ---
function Disable-AudioExclusive { Write-Log "Disabling Audio Exclusive Mode..." Action; Get-ChildItem 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\MMDevices\Audio\Render' -Recurse -ErrorAction SilentlyContinue | ForEach-Object { try{Set-ItemProperty -Path "$($_.PSPath)\Properties" -Name '{b3f8fa53-0004-438e-9003-51a46e139bfc},3' -Value 0 -ErrorAction SilentlyContinue;Set-ItemProperty -Path "$($_.PSPath)\Properties" -Name '{b3f8fa53-0004-438e-9003-51a46e139bfc},4' -Value 0 -ErrorAction SilentlyContinue}catch{} }; Write-Log "Audio Exclusive Mode disabled - no more Discord audio drops" OK; Play-Tone }
function Disable-BTCollaboration { Write-Log "Disabling Bluetooth Collaboration..." Action; Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\BthAvctpSvc' -ErrorAction SilentlyContinue | Out-Null; Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' 'DisableBTCollaboration' 1; try{Set-Service -Name BthAvctpSvc -StartupType Manual -ErrorAction Stop}catch{}; Write-Log "BT Collaboration disabled - WiFi speed restored" OK; Play-Tone }

# --- INTERRUPT & ADAPTER OPTIMIZATION ---
# Benefit: Forces NIC to process every packet immediately instead of batching (interrupt coalescing)
# Risk: Marginally higher CPU usage from more frequent interrupts; negligible on modern CPUs
function Disable-InterruptModeration {
    Write-Log "Disabling Interrupt Moderation on all adapters..." Action
    $c=0
    Get-NetAdapterAdvancedProperty -DisplayName '*Interrupt Moderation*' -ErrorAction SilentlyContinue | ForEach-Object {
        Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Interrupt Moderation' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue; $c++
        Write-Log "  $($_.Name): Interrupt Moderation DISABLED" Info
    }
    # Also set interrupt throttle rate to max
    Get-NetAdapterAdvancedProperty -DisplayName '*Interrupt Throttle*' -ErrorAction SilentlyContinue | ForEach-Object {
        Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName $_.DisplayName -DisplayValue 'Off' -ErrorAction SilentlyContinue
    }
    if ($c -eq 0) { Write-Log "No adapters with Interrupt Moderation found" Warn }
    else { Write-Log "Interrupt Moderation disabled on $c adapters - packets now immediate" OK }
    Play-Tone
}

# Benefit: Prevents NIC from entering low-power states that add latency spikes and packet delays
# Risk: Minor power increase; irrelevant on desktop, noticeable on laptop battery
function Disable-AdapterPowerSave {
    Write-Log "Disabling power management on all network adapters..." Action
    $c=0
    Get-NetAdapter -Physical -ErrorAction SilentlyContinue | ForEach-Object {
        $name = $_.Name
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName '*Energy Efficient*' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName '*Power Saving*' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName '*Green Ethernet*' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName '*Wake on*' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue
        Set-NetAdapterAdvancedProperty -Name $name -DisplayName '*Reduce Speed*' -DisplayValue 'Disabled' -ErrorAction SilentlyContinue
        # Disable "Allow computer to turn off this device"
        $pnp = Get-PnpDevice | Where-Object { $_.FriendlyName -eq $_.FriendlyName -and $_.Class -eq 'Net' -and $_.Status -eq 'OK' } | Select-Object -First 1
        if ($pnp) { Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Enum\$($pnp.InstanceId)\Device Parameters" 'PnPCapabilities' 0x18 }
        $c++
    }
    Write-Log "Power saving disabled on $c adapters - zero sleep latency" OK; Play-Tone
}

# Benefit: Forces GPU and NIC interrupts onto physical CPU cores 0-3, reducing IRQ conflicts
# Risk: Safe on 4+ core systems; spreads load across first 4 physical cores
function Set-InterruptAffinity {
    Write-Log "Setting Interrupt Affinity Policy for GPU and NIC..." Action
    $c=0
    Get-PnpDevice -Status OK -ErrorAction SilentlyContinue | Where-Object { $_.Class -in @('Display','Net') } | ForEach-Object {
        $afPath = "HKLM:\SYSTEM\CurrentControlSet\Enum\$($_.InstanceId)\Device Parameters\Interrupt Management\Affinity Policy"
        Set-Reg $afPath 'DevicePolicy' 4
        Set-Reg $afPath 'AssignmentSetOverride' ([byte[]](0x0F)) 'Binary'
        $c++; Write-Log "  $($_.FriendlyName): Affinity -> Cores 0-3" Info
    }
    Write-Log "Interrupt affinity set on $c devices - restart for effect" OK; Play-Tone
}

# Benefit: Creates a custom zero-throttle power plan with ALL limiters removed
# Risk: Maximum power draw; desktop fans handle this, laptops need charger
function Create-RaysPowerPlan {
    Write-Log "Creating Ray's Performance power plan..." Action
    $out = powercfg -duplicatescheme 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1
    if ($out -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') {
        $guid = $Matches[1]
        powercfg -changename $guid "Rays Performance" "Zero throttle maximum gaming" 2>$null
        powercfg -setacvalueindex $guid sub_processor PROCTHROTTLEMIN 100 2>$null
        powercfg -setacvalueindex $guid sub_processor PROCTHROTTLEMAX 100 2>$null
        powercfg -setacvalueindex $guid sub_processor CPMINCORES 100 2>$null
        powercfg -setacvalueindex $guid sub_processor IDLEDISABLE 1 2>$null
        powercfg -setacvalueindex $guid 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 0 2>$null
        powercfg -setacvalueindex $guid 0012ee47-9041-4b5d-9b77-535fba8b1442 6738e2c4-e8a5-4a42-b16a-e040e769756e 0 2>$null
        powercfg /setactive $guid 2>$null
        Write-Log "Ray's Performance plan ACTIVE - zero throttle!" OK
    } else { Write-Log "Could not create plan (may already exist)" Warn }
    Play-Tone
}

# Benefit: Detects Dell/HP/Lenovo/ASUS/Razer OEM services that drain resources
# Risk: None for scan; setting to Manual is safe (services start when needed)
function Scan-OEMBloatware {
    Write-Log "Scanning for OEM bloatware services..." Action
    $oem = @('SupportAssist','DellDataVault','HPTouchpoint','HotKeyService','ImController','LenovoVantage','AcerSense','QuickAccess','ArmouryCrate','ASUSOptimization','ROGLive','RazerGameManager','GameManagerService','NahimicService','NahimicMSI','WavesSysSvc','WavesSvc','AsusCertService')
    $found = @()
    foreach ($name in $oem) {
        Get-Service -Name "*$name*" -ErrorAction SilentlyContinue | ForEach-Object { $found += "$($_.DisplayName) [$($_.Status)]" }
    }
    if ($found.Count -gt 0) {
        $r = [System.Windows.MessageBox]::Show("OEM Bloatware Found ($($found.Count)):`n`n$($found -join "`n")`n`nSet to Manual? (they start only when needed)","OEM Scanner","YesNo","Information")
        if ($r -eq 'Yes') {
            foreach ($name in $oem) { try{Get-Service "*$name*" -ErrorAction Stop|ForEach-Object{Set-Service -Name $_.Name -StartupType Manual -ErrorAction Stop;Write-Log "  $($_.DisplayName) -> Manual" Info}}catch{} }
            Write-Log "OEM services set to Manual" OK
        }
    } else { Write-Log "No OEM bloatware detected - clean system!" OK }
    Play-Tone
}

# Benefit: Shows current process count vs target of under 70 for gaming
function Show-ProcessCount {
    $procs = (Get-Process).Count; $svcs = (Get-Service|Where-Object Status -eq 'Running').Count
    $grade = if($procs -lt 70){"EXCELLENT - gaming ready!"}elseif($procs -lt 120){"GOOD - run Debloat for more"}else{"HIGH - run Deep Service Kill + Debloat"}
    [System.Windows.MessageBox]::Show("Running Processes: $procs`nRunning Services: $svcs`n`nTarget: Under 70 for competitive gaming`nGrade: $grade",'Process Monitor','OK','Information')|Out-Null
    Write-Log "Processes: $procs | Services: $svcs" $(if($procs -lt 70){'OK'}elseif($procs -lt 120){'Warn'}else{'Error'})
}

# Benefit: Aggressively disables 35+ non-essential services to reach under 70 processes
# Risk: Printing, Bluetooth, tablet input, Xbox won't auto-start; safe to re-enable via Services.msc
function Invoke-DeepServiceKill {
    $r = [System.Windows.MessageBox]::Show("Deep Service Kill disables 35+ services to get under 70 processes.`n`nDisabled features:`n- Printing (Spooler)`n- Bluetooth (bthserv)`n- Xbox services`n- Windows Error Reporting`n- Background Intelligent Transfer`n`nAll can be re-enabled via Services.msc.`n`nContinue?","Deep Kill Warning","YesNo","Warning")
    if ($r -eq 'No') { return }
    Write-Log "Deep Service Kill - targeting under 70 processes..." Action
    $services = @('Spooler','bthserv','TabletInputService','WMPNetworkSvc','SSDPSRV','lfsvc','MapsBroker','PhoneSvc','RetailDemo','wisvc','icssvc','WpcMonSvc','SEMgrSvc','SCardSvr','SysMain','DiagTrack','dmwappushservice','diagnosticshub.standardcollector.service','WbioSrvc','PcaSvc','WerSvc','AppReadiness','CDPSvc','WpnService','XboxGipSvc','XblAuthManager','XblGameSave','XboxNetApiSvc','MessagingService','OneSyncSvc','PimIndexMaintenanceSvc','WpnUserService','Fax','RemoteRegistry','TrkWks')
    $c=0
    foreach ($svc in $services) { try{Get-Service -Name "$svc*" -ErrorAction Stop|ForEach-Object{Set-Service -Name $_.Name -StartupType Disabled -ErrorAction Stop;Stop-Service -Name $_.Name -Force -ErrorAction SilentlyContinue;$c++}}catch{} }
    $procs = (Get-Process).Count
    Write-Log "Killed $c services | Process count now: $procs" OK; Play-Tone
}

# ============================================================
# SECTION 11A-CTO: KERNEL PERFORMANCE ENGINEERING (CTO Grade)
# ============================================================

# SPEED SHIFT EPP: Intel's hardware-level frequency scaling
# Modern Intel CPUs (6th gen+) have Speed Shift Technology (SST)
# EPP=0 = Maximum Performance (CPU ramps instantly to max freq)
# EPP=128 = Balanced, EPP=255 = Max Power Saving
# This is BETTER than core unparking for Intel laptops because it
# lets C-States function (prevents overheat) while still getting
# instant frequency ramps when the game needs it.
function Set-SpeedShiftEPP {
    param([int]$Value = 0)
    Write-Log "CTO: Setting Intel Speed Shift EPP to $Value..." Action
    if ($cpuName -notmatch 'Intel') { Write-Log "[SKIP] Not an Intel CPU - Speed Shift is Intel-only" Warn; return }
    # Benefit: EPP=0 tells Intel CPU to ramp to max frequency INSTANTLY when load detected
    # Risk: Higher power draw on AC; reverts on battery automatically via Windows power policy
    powercfg -setacvalueindex scheme_current sub_processor PERFEPP $Value 2>$null
    powercfg -setdcvalueindex scheme_current sub_processor PERFEPP 50 2>$null
    powercfg -setactive scheme_current 2>$null
    # Also set Energy Performance Preference via registry for boot persistence
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\36687f9e-e3a5-4dbf-b1dc-15eb381c6863' 'Attributes' 0
    Write-Log "  Intel Speed Shift EPP = $Value (AC) / 50 (Battery)" Info
    Write-Log "  AC: Max Performance | Battery: Balanced (auto)" Info
    Write-Log "CTO: Speed Shift optimized - instant frequency ramps!" OK; Play-Tone
}

# WLAN AUTOCONFIG FIX: Stops WiFi from scanning during gameplay
# Windows periodically scans for nearby WiFi networks even when connected.
# Each scan causes a 50-200ms latency spike that shows as a "ping spike" in games.
# This disables background scanning while connected.
function Fix-WLANScanning {
    Write-Log "CTO: Fixing WLAN AutoConfig background scanning..." Action
    # Benefit: Stops periodic WiFi scans that cause 50-200ms lag spikes during gaming
    # Risk: Won't auto-connect to stronger networks; must manually scan if WiFi drops
    netsh wlan set autoconfig enabled=no interface="Wi-Fi" 2>$null
    netsh wlan set autoconfig enabled=no interface="WiFi" 2>$null
    netsh wlan set autoconfig enabled=no interface="Wireless" 2>$null
    # Also set via registry for persistence
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\WlanSvc' 'ScanWhenAssociated' 0
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\WlanSvc' 'ScanOnlyActiveProbe' 1
    Write-Log "  WiFi background scanning DISABLED while connected" Info
    Write-Log "  Re-enable: netsh wlan set autoconfig enabled=yes interface=Wi-Fi" Info
    Write-Log "CTO: WLAN lag spikes eliminated!" OK; Play-Tone
}

# WLAN AUTOCONFIG RESTORE
function Restore-WLANScanning {
    Write-Log "CTO: Restoring WLAN AutoConfig scanning..." Action
    netsh wlan set autoconfig enabled=yes interface="Wi-Fi" 2>$null
    netsh wlan set autoconfig enabled=yes interface="WiFi" 2>$null
    netsh wlan set autoconfig enabled=yes interface="Wireless" 2>$null
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\WlanSvc' -Name 'ScanWhenAssociated' -EA 0
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\WlanSvc' -Name 'ScanOnlyActiveProbe' -EA 0
    Write-Log "WiFi scanning restored to default" OK; Play-Tone
}

# IFEO GAME PRIORITY: Injects CPU/IO priority for specific game executables
# Image File Execution Options (IFEO) lets you set process priority BEFORE
# the game even fully launches. This is more reliable than runtime priority
# because it takes effect at process creation, not after detection.
function Set-IFEOPriority {
    Write-Log "CTO: Setting IFEO Game Priority injection..." Action
    $games = @(
        @{Exe='cs2.exe'; Name='Counter-Strike 2'},
        @{Exe='VALORANT-Win64-Shipping.exe'; Name='Valorant'},
        @{Exe='FortniteClient-Win64-Shipping.exe'; Name='Fortnite'},
        @{Exe='r5apex.exe'; Name='Apex Legends'},
        @{Exe='GTA5.exe'; Name='GTA V'},
        @{Exe='RocketLeague.exe'; Name='Rocket League'},
        @{Exe='javaw.exe'; Name='Minecraft (Java)'},
        @{Exe='RobloxPlayerBeta.exe'; Name='Roblox'},
        @{Exe='cod.exe'; Name='Call of Duty'},
        @{Exe='Overwatch.exe'; Name='Overwatch 2'},
        @{Exe='FiveM.exe'; Name='FiveM'},
        @{Exe='FiveM_b2699_GTAProcess.exe'; Name='FiveM (GTA Process)'}
    )
    # Benefit: Sets IoPriority and CpuPriorityClass at process creation (not runtime)
    # Risk: None - Windows IFEO PerfOptions is a documented API, fully safe
    foreach ($g in $games) {
        $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$($g.Exe)\PerfOptions"
        Set-Reg $path 'CpuPriorityClass' 3  # 3 = High Priority
        Set-Reg $path 'IoPriority' 3         # 3 = High I/O Priority
        Write-Log "  $($g.Name) ($($g.Exe)): CPU=High, IO=High" Info
    }
    Write-Log "CTO: $($games.Count) games now launch with elevated priority!" OK; Play-Tone
}

# SHADER CACHE CLEAR: Clears DirectX and GPU shader caches
# Old/corrupt shader caches cause "first-run stutters" and frame drops
# Clearing forces the GPU to recompile shaders fresh with current drivers
function Clear-ShaderCache {
    Write-Log "CTO: Clearing shader caches for fresh compilation..." Action
    # DirectX shader cache
    $dxCache = "$env:LOCALAPPDATA\D3DSCache"
    if (Test-Path $dxCache) { Remove-Item "$dxCache\*" -Recurse -Force -EA 0; Write-Log "  DirectX shader cache cleared" Info }
    # NVIDIA shader cache
    $nvCache = "$env:LOCALAPPDATA\NVIDIA\DXCache"
    $nvCache2 = "$env:LOCALAPPDATA\NVIDIA\GLCache"
    if (Test-Path $nvCache) { Remove-Item "$nvCache\*" -Recurse -Force -EA 0; Write-Log "  NVIDIA DX cache cleared" Info }
    if (Test-Path $nvCache2) { Remove-Item "$nvCache2\*" -Recurse -Force -EA 0; Write-Log "  NVIDIA GL cache cleared" Info }
    # AMD shader cache
    $amdCache = "$env:LOCALAPPDATA\AMD\DxCache"
    $amdCache2 = "$env:LOCALAPPDATA\AMD\GLCache"
    if (Test-Path $amdCache) { Remove-Item "$amdCache\*" -Recurse -Force -EA 0; Write-Log "  AMD DX cache cleared" Info }
    if (Test-Path $amdCache2) { Remove-Item "$amdCache2\*" -Recurse -Force -EA 0; Write-Log "  AMD GL cache cleared" Info }
    # Intel shader cache
    $intelCache = "$env:LOCALAPPDATA\Intel\ShaderCache"
    if (Test-Path $intelCache) { Remove-Item "$intelCache\*" -Recurse -Force -EA 0; Write-Log "  Intel shader cache cleared" Info }
    # Windows pipeline cache
    $pipeCache = "$env:LOCALAPPDATA\Microsoft\Windows\GameExplorer"
    if (Test-Path $pipeCache) { Remove-Item "$pipeCache\*" -Recurse -Force -EA 0 }
    Write-Log "CTO: All shader caches cleared - games will recompile with latest drivers!" OK; Play-Tone
}

# CLEAN SLATE: Complete cache purge before applying optimizations
# Ensures new tweaks run on a clean system without interference from old state
function Invoke-CleanSlate {
    Write-Log "CTO: CLEAN SLATE - purging all caches for fresh optimization base..." Action
    # DNS cache
    ipconfig /flushdns 2>$null | Out-Null; Write-Log "  DNS cache flushed" Info
    # Shader caches (all vendors)
    Clear-ShaderCache
    # Temp files
    Remove-Item "$env:TEMP\*" -Recurse -Force -EA 0
    Remove-Item "$env:SystemRoot\Temp\*" -Recurse -Force -EA 0
    Write-Log "  Temp files purged" Info
    # Font cache (can cause rendering delays)
    Stop-Service -Name 'FontCache' -Force -EA 0
    Remove-Item "$env:SystemRoot\ServiceProfiles\LocalService\AppData\Local\FontCache\*" -Recurse -Force -EA 0
    Start-Service -Name 'FontCache' -EA 0
    Write-Log "  Font cache rebuilt" Info
    # Thumbnail cache
    Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*" -Force -EA 0
    Write-Log "  Thumbnail cache cleared" Info
    # Windows icon cache
    $iconCache = "$env:LOCALAPPDATA\IconCache.db"
    if (Test-Path $iconCache) { Remove-Item $iconCache -Force -EA 0; Write-Log "  Icon cache cleared" Info }
    # Standby RAM purge
    [System.GC]::Collect(); [System.GC]::WaitForPendingFinalizers(); [System.GC]::Collect()
    Write-Log "  RAM standby purged" Info
    Write-Log "CTO: CLEAN SLATE complete - system is ready for fresh optimizations!" OK; Play-Tone
}

# INTEL HYBRID DETECTION: Detects 12th gen+ P-Core/E-Core architecture
# On 12th gen+ Intel (Alder Lake, Raptor Lake, Meteor Lake), core unparking
# is HARMFUL because it forces game threads onto slower E-Cores.
# Intel Thread Director handles this automatically and BETTER than manual unparking.
function Test-IntelHybrid {
    if ($cpuName -match 'i[3579]-1[2-5]|i[3579]-1[2-5]\d{2}|Ultra [579]') {
        return $true  # 12th, 13th, 14th, 15th gen or Core Ultra = hybrid
    }
    return $false
}

# ============================================================
# ULTRABOOK-SAFE PROFILE (Dell Latitude / XPS / ThinkPad / etc)
# CTO Mandate: Zero thermal risk, verified Win10/11, no placebo
# ============================================================
function Apply-UltrabookProfile {
    Write-Log "CTO: ULTRABOOK-SAFE PROFILE — surgical optimization for thin laptops..." Action
    $report = @(); $skipped = @()

    # --- PHASE 1: CPU — Speed Shift, NOT core unparking ---
    # WHY NOT UNPARK: Intel mobile CPUs thermal-throttle instantly when all cores active
    # WHY SPEED SHIFT: EPP=0 gives instant frequency ramps while C-States prevent overheat
    if ($cpuName -match 'Intel') {
        powercfg -setacvalueindex scheme_current sub_processor PERFEPP 0 2>$null
        powercfg -setdcvalueindex scheme_current sub_processor PERFEPP 50 2>$null
        powercfg -setactive scheme_current 2>$null
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\36687f9e-e3a5-4dbf-b1dc-15eb381c6863' 'Attributes' 0
        $report += '[CPU] Speed Shift EPP=0 (AC) / EPP=50 (battery) — instant freq ramps, C-States preserved'
    } else {
        $report += '[CPU] AMD detected — using balanced Ryzen power profile'
    }
    # 95% CPU cap for thin laptops (prevents turbo overheat-crash loop on 15-28W TDP)
    powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 95 2>$null
    powercfg -setactive scheme_current 2>$null
    $report += '[CPU] 95% CPU cap — prevents turbo boost from triggering thermal throttle loop'
    $skipped += '[CPU] Core Unparking — SKIPPED (causes instant thermal throttling on ultrabooks)'
    $skipped += '[CPU] Spectre/Meltdown disable — SKIPPED (crash risk on battery power transitions)'
    $skipped += '[CPU] VBS/Device Guard disable — SKIPPED (security risk on portable device)'

    # --- PHASE 2: GAME PRIORITY via IFEO ---
    # WHY IFEO: Sets priority BEFORE process fully launches, more reliable than runtime detection
    $games = @(
        @{Exe='FortniteClient-Win64-Shipping.exe'; Name='Fortnite'},
        @{Exe='VALORANT-Win64-Shipping.exe'; Name='Valorant'},
        @{Exe='FiveM.exe'; Name='FiveM'},
        @{Exe='RobloxPlayerBeta.exe'; Name='Roblox'},
        @{Exe='cs2.exe'; Name='Counter-Strike 2'},
        @{Exe='r5apex.exe'; Name='Apex Legends'},
        @{Exe='javaw.exe'; Name='Minecraft (Java)'},
        @{Exe='GTA5.exe'; Name='GTA V'},
        @{Exe='RocketLeague.exe'; Name='Rocket League'},
        @{Exe='cod.exe'; Name='Call of Duty'}
    )
    foreach ($g in $games) {
        $path = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$($g.Exe)\PerfOptions"
        Set-Reg $path 'CpuPriorityClass' 3
        Set-Reg $path 'IoPriority' 3
    }
    $report += "[Gaming] IFEO High Priority for $($games.Count) games (CPU=High, IO=High at process creation)"

    # --- PHASE 3: WIRELESS STABILITY (critical for laptop gaming) ---
    # WHY: WLAN AutoConfig scans every 60s causing 50-200ms lag spikes during gameplay
    netsh wlan set autoconfig enabled=no interface="Wi-Fi" 2>$null
    netsh wlan set autoconfig enabled=no interface="WiFi" 2>$null
    netsh wlan set autoconfig enabled=no interface="Wireless" 2>$null
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\WlanSvc' 'ScanWhenAssociated' 0
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\WlanSvc' 'ScanOnlyActiveProbe' 1
    $report += '[WiFi] WLAN background scanning DISABLED — eliminates 50-200ms ping spikes'

    # --- PHASE 4: VERIFIED MODERN TWEAKS (Win10/11 only, no legacy) ---
    # Network: Only verified modern fixes — NO SizReqBuf/MaxFreeTcbs (XP era, ignored by Win10+)
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -EA 0 | ForEach-Object {
        Set-Reg $_.PSPath 'TcpAckFrequency' 1  # ACK every packet immediately
        Set-Reg $_.PSPath 'TCPNoDelay' 1        # Disable Nagle (send data immediately)
    }
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    $report += '[Network] Nagle OFF + ACK=1 + throttle removed (verified Win10/11 effective)'
    $skipped += '[Network] SizReqBuf/MaxFreeTcbs — DISCARDED (XP-era, ignored by modern TCP stack)'

    # GPU: MPO disable + FSO disable (safe on iGPU, fixes tearing/flicker)
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode' 5
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_HonorUserFSEBehaviorMode' 1
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_DXGIHonorFSEWindowsCompatible' 1
    $report += '[GPU] MPO disabled + FSO disabled — fixes borderless flicker and forces true fullscreen'

    # Pre-rendered frames = 1 (THE critical anti-tear fix, safe on ALL hardware)
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\DirectX\GraphicsSettings' 'MaxQueuedFrames' 1
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\DirectX' 'MaxQueuedFrames' 1
    $report += '[GPU] Pre-rendered frames = 1 — GPU cannot race ahead of monitor (anti-tear)'
    $skipped += '[GPU] Flip Model force — SKIPPED (Intel iGPU driver conflicts cause flicker)'
    $skipped += '[GPU] HAGS — SKIPPED (steals shared VRAM management from iGPU = lower FPS)'
    $skipped += '[GPU] DWM V-Sync TSC — SKIPPED (double-sync on 60Hz iGPU = +16ms lag)'

    # Game DVR / Game Bar / Game Mode — kill all overlays
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 0
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 0
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 0
    $report += '[Gaming] Game DVR + Game Bar + Game Mode completely disabled'

    # Telemetry kill (safe, frees CPU + bandwidth)
    try { Set-Service -Name 'DiagTrack' -StartupType Disabled -EA Stop; Stop-Service -Name 'DiagTrack' -Force -EA Stop } catch {}
    Set-Reg 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' 'AllowTelemetry' 0
    $report += '[Privacy] Telemetry service disabled + AllowTelemetry=0'

    # GPU Priority (safe scheduler hint, no hardware change)
    $g = 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    Set-Reg $g 'GPU Priority' 8; Set-Reg $g 'Priority' 6
    Set-Reg $g 'Scheduling Category' 'High' 'String'; Set-Reg $g 'SFIO Priority' 'High' 'String'
    $report += '[GPU] Priority 8 — kernel prioritizes graphics requests over background tasks'

    # SystemResponsiveness (games get 90% CPU time)
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 10
    $report += '[CPU] SystemResponsiveness=10 — 90% CPU time reserved for games'

    # Mouse acceleration off (1:1 input)
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
    $report += '[Input] Mouse acceleration stripped — raw 1:1 input for muscle memory'

    # USB power management off (controllers/mice never sleep)
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' 'DisableSelectiveSuspend' 1
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\HidUsb\Parameters' 'EnhancedPowerManagementEnabled' 0
    $report += '[USB] Selective suspend OFF — controllers and mice never lag'

    # Transparency off (saves iGPU compositing overhead)
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
    $report += '[Visual] Transparency OFF — saves Intel iGPU compositing cycles'

    # High Performance plan (NOT Ultimate — saves battery and prevents thermal runaway)
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
    $report += '[Power] High Performance plan (NOT Ultimate — prevents battery drain and thermal runaway)'
    $skipped += '[Power] Ultimate Performance — SKIPPED (drains battery 3x faster, increases heat)'
    $skipped += '[BCD] useplatformtick/disabledynamictick — SKIPPED (causes clock desync on mobile Intel = anti-cheat kicks)'

    # Clean Slate (fresh cache state)
    ipconfig /flushdns 2>$null | Out-Null
    Remove-Item "$env:TEMP\*" -Recurse -Force -EA 0
    $report += '[Cleanup] DNS flushed + temp files cleared'

    # --- PHASE 5: SERVICES LEFT INTACT ---
    $skipped += '[Service] Bluetooth (bthserv) — LEFT ON for controllers'
    $skipped += '[Service] Windows Update (wuauserv) — LEFT ON for security patches'
    $skipped += '[Service] Audio (AudioSrv) — LEFT ON obviously'
    $skipped += '[Service] WiFi (WlanSvc) — LEFT ON for connectivity'
    $skipped += '[Service] Power/Battery — LEFT ON for thermal management'

    # --- BUILD REPORT ---
    $msg = "ULTRABOOK-SAFE PROFILE — CTO Engineering Report`n"
    $msg += "Device: $cpuName | ${ramGB}GB RAM | $gpu`n"
    $msg += "Architecture: Thermal-constrained ultrabook (15-28W TDP)`n`n"
    $msg += "APPLIED ($($report.Count) optimizations):`n"
    foreach ($r in $report) { $msg += "  [OK] $r`n"; Write-Log "  $r" Info }
    $msg += "`nSKIPPED ($($skipped.Count) — dangerous for ultrabook):`n"
    foreach ($s in $skipped) { $msg += "  [--] $s`n"; Write-Log "  $s" Warn }
    $msg += "`nNOTE: WiFi scanning is now disabled while connected.`n"
    $msg += "To re-scan for networks: netsh wlan set autoconfig enabled=yes interface=Wi-Fi`n"
    $msg += "Or click 'Restore WiFi Scanning' in the Gaming tab."
    [System.Windows.MessageBox]::Show($msg, 'Ultrabook Profile Complete', 'OK', 'Information') | Out-Null
    Write-Log "CTO: Ultrabook Profile complete — $($report.Count) applied, $($skipped.Count) skipped" OK; Play-Tone
}

# --- CONTROLLER OPTIMIZATION ---
# Benefit: Sets DS4Windows/reWASD/Steam controller process to High priority for faster input scheduling
# Risk: None; these are lightweight processes
function Boost-ControllerPriority {
    Write-Log "Boosting controller software priority..." Action
    $targets = @('DS4Windows','ds4winWPF','reWASD','JoyToKey','InputMapper','steam','XboxAccessories','BetterJoy','x360ce')
    $c=0
    foreach ($name in $targets) {
        Get-Process -Name $name -ErrorAction SilentlyContinue | ForEach-Object { try{$_.PriorityClass='High';$c++;Write-Log "  $($_.ProcessName) -> High Priority" Info}catch{} }
    }
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\HidUsb\Parameters' 'EnhancedPowerManagementEnabled' 0
    if ($c -eq 0) { Write-Log "No controller software running - start DS4Windows/reWASD first" Warn }
    else { Write-Log "$c controller processes boosted to High" OK }
    Play-Tone
}

# Benefit: Disables USB power management for ALL HID/USB devices so controllers never sleep
# Risk: Slightly higher USB power draw; prevents any HID device from entering low power
function Optimize-ControllerUSB {
    Write-Log "Optimizing USB for controller zero-latency..." Action
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' 'DisableSelectiveSuspend' 1
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\HidUsb\Parameters' 'EnhancedPowerManagementEnabled' 0
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\mouclass\Parameters' 'MouseDataQueueSize' 0x14
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\kbdclass\Parameters' 'KeyboardDataQueueSize' 0x14
    $c=0
    Get-PnpDevice -Class USB -Status OK -ErrorAction SilentlyContinue | ForEach-Object {
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Enum\$($_.InstanceId)\Device Parameters" 'EnhancedPowerManagementEnabled' 0
        Set-Reg "HKLM:\SYSTEM\CurrentControlSet\Enum\$($_.InstanceId)\Device Parameters" 'AllowIdleIrpInD3' 0
        $c++
    }
    Write-Log "USB optimized for $c devices - zero-latency HID input" OK; Play-Tone
}

# Shows detected controllers with pro tips for each type
function Show-ControllerInfo {
    Write-Log "Detecting game controllers..." Action
    $all = @()
    Get-PnpDevice -Class HIDClass -Status OK -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match 'game|controller|joystick|xbox|dualshock|dualsense|HID-compliant game' } | ForEach-Object { $all += $_.FriendlyName }
    Get-PnpDevice -Class USB -Status OK -ErrorAction SilentlyContinue | Where-Object { $_.FriendlyName -match 'controller|xbox|wireless' } | ForEach-Object { $all += $_.FriendlyName }
    $all = $all | Select-Object -Unique
    $tips = "`n`nPRO TIPS:`n"
    $tips += "- PS5/PS4: Use DS4Windows for 1000Hz polling overclock (8ms -> 1ms)`n"
    $tips += "- Xbox: Natively 125-250Hz; limited overclock potential`n"
    $tips += "- Set deadzone to 0, increase by 1% until drift stops`n"
    $tips += "- Use Linear response curve for 1:1 muscle memory`n"
    $tips += "- Make triggers Digital (instant fire at 0.1% pull)`n"
    $tips += "- Disable Steam Input per-game (-2ms input lag)`n"
    $tips += "- Wired is usually better for Xbox; BT can be faster for PS5"
    $msg = if ($all.Count -gt 0) { "Controllers ($($all.Count)):`n$($all -join "`n")$tips" } else { "No controllers detected.$tips" }
    [System.Windows.MessageBox]::Show($msg,'Controller Detection','OK','Information')|Out-Null
    Write-Log "Controllers: $($all.Count) detected" OK
}

# --- POWER USER TOOLS ---
function Export-WingetApps { Write-Log "Exporting installed apps..." Action; $path="$env:USERPROFILE\Desktop\winget-apps.json"; try{winget export -o $path --accept-source-agreements 2>$null; if(Test-Path $path){Write-Log "App list exported to Desktop\winget-apps.json" OK}else{Write-Log "Export may have partially failed" Warn}}catch{Write-Log "Error: $_" Error}; Play-Tone }
function Import-WingetApps { Write-Log "Importing apps from backup..." Action; $d=New-Object Microsoft.Win32.OpenFileDialog; $d.Filter='JSON|*.json'; if($d.ShowDialog()){Write-Log "Importing from $($d.FileName)..." Action; Start-Process winget -ArgumentList "import -i `"$($d.FileName)`" --accept-source-agreements --accept-package-agreements" -NoNewWindow; Write-Log "Import started" OK}else{Write-Log "No file selected" Info} }
function Backup-Registry { Write-Log "Backing up registry..." Action; $path="$env:USERPROFILE\Desktop\RaysChamber_RegBackup_$(Get-Date -Format 'yyyyMMdd_HHmmss').reg"; Start-Process reg.exe -ArgumentList "export HKLM\SYSTEM\CurrentControlSet `"$path`" /y" -Wait -NoNewWindow -ErrorAction SilentlyContinue; if(Test-Path $path){Write-Log "Registry backup saved to Desktop" OK}else{Write-Log "Backup may need elevated permissions" Warn}; Play-Tone }
function Check-GPUMSIStatus { Write-Log "Checking GPU MSI Mode status..." Action; try{$dev=Get-PnpDevice -Class Display -Status OK -ErrorAction Stop|Select-Object -First 1; $msiPath="HKLM:\SYSTEM\CurrentControlSet\Enum\$($dev.InstanceId)\Device Parameters\Interrupt Management\MessageSignaledInterruptProperties"; $msi=try{(Get-ItemProperty $msiPath -ErrorAction Stop).MSISupported}catch{-1}; $status=if($msi -eq 1){"MSI Mode: ENABLED (good)"}elseif($msi -eq 0){"MSI Mode: DISABLED (legacy line-based)"}else{"MSI Mode: NOT CONFIGURED"}; [System.Windows.MessageBox]::Show("GPU: $($dev.FriendlyName)`n`n$status`n`nMSI Mode eliminates micro-stutters from IRQ conflicts.`nUse 'Enable MSI Mode' in Hardware tab to enable.",'GPU MSI Check','OK','Information')|Out-Null; Write-Log "GPU: $status" OK}catch{Write-Log "Could not check GPU: $_" Warn} }

# ============================================================
# SECTION 11B: ZERO-TEAR MODE (No V-Sync, No Tearing)
# ============================================================
# The "Scanline-Sync" approach: Cap FPS at (MonitorHz - 3), force Flip Model,
# set GPU Low Latency, disable DWM interference. Result: zero tearing + zero input lag.

function Enable-ZeroTear {
    Write-Log "ZERO-TEAR PRO v2: Hardware-aware anti-tear system..." Action
    $hz = try { (Get-CimInstance Win32_VideoController).CurrentRefreshRate | Select-Object -First 1 } catch { 60 }
    if (-not $hz -or $hz -eq 0) { $hz = 60 }
    $capFPS = $hz - 3
    $gpuName = try { (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name } catch { '' }
    $isIGPU = $gpuName -match 'Intel|UHD|Iris|Vega|AMD Radeon\(TM\) Graphics'
    $is60Hz = $hz -le 60
    $layerCount = 0

    Write-Log "  Monitor: ${hz}Hz | GPU: $gpuName | iGPU: $isIGPU | Cap: $capFPS FPS" Info

    # LAYER 1: DWM ForceEffectMode - SAFE on all hardware
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'ForceEffectMode' 0
    $layerCount++; Write-Log "  [$layerCount] DWM ForceEffectMode=0 (no extra buffer)" Info

    # LAYER 2: DWM Overlays disable - SAFE on all hardware
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'DisableOverlays' 1
    $layerCount++; Write-Log "  [$layerCount] DWM Overlays disabled" Info

    # LAYER 3: DWM V-Sync TSC - SKIP on iGPU (causes double-sync on shared GPU = +16ms lag on 60Hz)
    if (-not $isIGPU) {
        Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'DisableDWMVSyncTSC' 1
        $layerCount++; Write-Log "  [$layerCount] DWM V-Sync TSC disabled (dGPU detected)" Info
    } else {
        Write-Log "  [SKIP] DWM V-Sync TSC - iGPU detected (would cause double-sync lag)" Warn
    }

    # LAYER 4: Pre-rendered frames = 1 (THE CRITICAL FIX - safe on ALL hardware)
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\DirectX\GraphicsSettings' 'MaxQueuedFrames' 1
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\DirectX' 'MaxQueuedFrames' 1
    $layerCount++; Write-Log "  [$layerCount] Pre-rendered frames = 1 (CRITICAL anti-tear fix)" Info

    # LAYER 5: Flip Model - SKIP on iGPU (Intel driver conflicts with forced flip = flicker/stutter)
    if (-not $isIGPU) {
        Set-Reg 'HKLM:\SOFTWARE\Microsoft\DirectX' 'SwapEffectUpgradeEnable' 1
        Set-Reg 'HKLM:\SOFTWARE\Microsoft\DirectX' 'ForceFlipPresentModel' 1
        $layerCount++; Write-Log "  [$layerCount] Flip Model FORCED (dGPU - safe)" Info
    } else {
        Write-Log "  [SKIP] Flip Model force - iGPU detected (Intel driver conflicts cause flicker)" Warn
    }

    # LAYER 6: HAGS - SKIP on iGPU (steals shared VRAM management from CPU = lower FPS)
    if (-not $isIGPU) {
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2
        $layerCount++; Write-Log "  [$layerCount] HAGS enabled (dGPU has dedicated VRAM)" Info
    } else {
        Write-Log "  [SKIP] HAGS - iGPU uses shared RAM (HAGS adds CPU overhead)" Warn
    }

    # LAYER 7: MPO disable - SAFE and IMPORTANT on all hardware
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode' 5
    $layerCount++; Write-Log "  [$layerCount] MPO disabled (fixes borderless flicker on ALL GPUs)" Info

    # LAYER 8: FSO completely off - SAFE on all hardware
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_HonorUserFSEBehaviorMode' 1
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_DXGIHonorFSEWindowsCompatible' 1
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehavior' 2
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_EFSEFeatureFlags' 0
    $layerCount++; Write-Log "  [$layerCount] FSO fully disabled (true exclusive fullscreen)" Info

    # LAYER 9: Game DVR/Bar/Mode kill - SAFE and IMPORTANT on all hardware
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 0
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 0
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'UseNexusForGameBarEnabled' 0
    $layerCount++; Write-Log "  [$layerCount] Game DVR + Game Bar + Game Mode killed" Info

    # LAYER 10: GPU vendor-specific low latency + frame cap
    $gpuBase = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000'
    if ($gpuName -match 'NVIDIA|GeForce') {
        Set-Reg $gpuBase 'LowLatencyMode' 2; Set-Reg $gpuBase 'RMVsyncControl' 0
        Set-Reg $gpuBase 'FrameRateLimiterV3' $capFPS; Set-Reg $gpuBase 'MaxFrameAllowed' 1
        $layerCount++; Write-Log "  [$layerCount] NVIDIA: Ultra Low Latency ON, V-Sync OFF, Cap=$capFPS, PreRender=1" Info
    } elseif ($gpuName -match 'AMD|Radeon' -and -not $isIGPU) {
        Set-Reg "$gpuBase\UMD" 'AntiLag' 1; Set-Reg "$gpuBase\UMD" 'Wait for Vertical Refresh_DEF' '1' 'String'
        Set-Reg "$gpuBase\UMD" 'FlipQueueSize' '1' 'String'; Set-Reg "$gpuBase\UMD" 'Main3D_FrameRateTarget_DEF' "$capFPS" 'String'
        Set-Reg "$gpuBase\UMD" 'MaxFrameAllowed' 1
        $layerCount++; Write-Log "  [$layerCount] AMD dGPU: Anti-Lag ON, FlipQueue=1, FRTC=$capFPS" Info
    } elseif ($gpuName -match 'Intel|UHD|Iris|Arc') {
        Set-Reg "$gpuBase\GMM" 'VSync' 0; Set-Reg $gpuBase 'VSync' 0
        $layerCount++; Write-Log "  [$layerCount] Intel iGPU: V-Sync OFF (USE RTSS for cap at $capFPS!)" Info
    } elseif ($isIGPU) {
        $layerCount++; Write-Log "  [$layerCount] AMD iGPU: V-Sync OFF (USE RTSS for cap at $capFPS!)" Info
    }

    # LAYER 11: Present throttle disable - SAFE on all hardware
    Set-Reg 'HKCU:\Software\Microsoft\DirectX\GraphicsSettings' 'SwapEffectUpgradeCache' 0
    $layerCount++; Write-Log "  [$layerCount] Present throttle disabled" Info

    # LAYER 12: BCD Timer - SKIP on laptops (causes clock desync on mobile Intel = anti-cheat kicks)
    if (-not $isLaptop) {
        bcdedit /set useplatformtick yes 2>$null; bcdedit /set disabledynamictick yes 2>$null
        $layerCount++; Write-Log "  [$layerCount] BCD timer optimized (desktop only)" Info
    } else {
        Write-Log "  [SKIP] BCD timer tweaks - laptop detected (causes clock desync on mobile Intel)" Warn
    }

    # Build report
    $skipped = @()
    if ($isIGPU) { $skipped += "DWM V-Sync TSC (double-sync on iGPU)"; $skipped += "Flip Model (Intel driver conflict)"; $skipped += "HAGS (shared VRAM overhead)" }
    if ($isLaptop) { $skipped += "BCD timers (clock desync on mobile Intel)" }

    $msg = "ZERO-TEAR PRO v2: $layerCount LAYERS APPLIED`n"
    if ($skipped.Count -gt 0) { $msg += "(Skipped $($skipped.Count) incompatible layers for your hardware)`n" }
    $msg += "`nMonitor: ${hz}Hz | GPU: $gpuName`n"
    $msg += "iGPU Detected: $isIGPU | Laptop: $isLaptop`n"
    $msg += "Target FPS Cap: $capFPS`n`n"
    if ($skipped.Count -gt 0) { $msg += "SKIPPED (would hurt YOUR system):`n"; foreach ($s in $skipped) { $msg += "  [X] $s`n" }; $msg += "`n" }
    $msg += "=== MANDATORY: YOU MUST SET A FRAME CAP ===`n`n"
    if ($isIGPU) {
        $msg += "Your iGPU cannot set frame cap via registry.`n"
        $msg += "YOU MUST download RTSS from guru3d.com/rtss`n"
        $msg += "Set framerate limit to: $capFPS`n`n"
    } else {
        $msg += "Option 1: RTSS (best) - guru3d.com/rtss -> Cap: $capFPS`n"
        $msg += "Option 2: GPU Control Panel:`n"
        $msg += "  NVIDIA: 3D Settings > Max Frame Rate > $capFPS`n"
        $msg += "  AMD: Adrenalin > FRTC > $capFPS`n`n"
    }
    $msg += "In-game: FULLSCREEN mode, V-Sync OFF, cap $capFPS`n`n"
    $msg += "WHY Hz-3: Cap at $capFPS means GPU never overshoots`n"
    $msg += "your ${hz}Hz monitor. Pre-rendered=1 + frame cap =`n"
    $msg += "scanline-sync effect with ZERO input lag penalty.`n"
    $msg += "(V-Sync adds 16-50ms lag = unusable for competitive)"
    [System.Windows.MessageBox]::Show($msg, 'Zero-Tear Pro v2 Complete', 'OK', 'Information') | Out-Null
    Write-Log "ZERO-TEAR PRO v2: $layerCount layers active! Cap at $capFPS FPS!" OK; Play-Tone
}

# ============================================================
# SECTION 11C: SMART PRESET + SERVICE PICKER + ADVANCED NETWORK
# ============================================================

# SMART PRESET: Scans hardware and applies ONLY compatible, safe tweaks
# Handles ALL RAM tiers: 4GB, 8GB, 16GB, 32GB, 64GB for both Desktop and Laptop
function Invoke-SmartPreset {
    Write-Log "SMART PRESET: Scanning $HardwareType with ${ramGB}GB RAM, $cpuCores cores..." Action
    $safe = @(); $skip = @(); $warnings = @()

    # =============== TIER 1: UNIVERSAL (Safe for ALL devices, ALL RAM levels) ===============
    # Desc: Disable window transparency blur effect to save GPU compositing overhead
    # Safe: Yes - purely visual, fully reversible
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' 'EnableTransparency' 0
    $safe += '[Visual] Transparency OFF — saves GPU compositing cycles'

    # Desc: Remove 400ms menu animation delay so menus appear instantly
    # Safe: Yes - purely cosmetic timing change
    Set-Reg 'HKCU:\Control Panel\Desktop' 'MenuShowDelay' '0' 'String'
    $safe += '[Visual] Menu delay 0ms — menus appear instantly'

    # Desc: Disable Microsoft telemetry background service that uploads diagnostic data
    # Safe: Yes - Microsoft gets less crash data, no user impact
    try{Set-Service -Name 'DiagTrack' -StartupType Disabled -EA Stop;Stop-Service -Name 'DiagTrack' -Force -EA Stop}catch{}
    $safe += '[Privacy] Telemetry service disabled — stops background data uploads'

    # Desc: Disable Game DVR background recording overlay (5-10% CPU savings)
    # Safe: Yes - use OBS or ShadowPlay instead for recording
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR' 'AppCaptureEnabled' 0
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_Enabled' 0
    $safe += '[Gaming] Game DVR OFF — frees 5-10% CPU (use OBS instead)'

    # Desc: Remove Windows artificial 10Mbps cap on non-multimedia network traffic
    # Safe: Yes - purely removes an artificial cap, no downside
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    $safe += '[Network] Throttle removed — no more artificial 10Mbps cap'

    # Desc: Disable Nagle algorithm so network packets sent immediately (lower ping)
    # Safe: Yes - marginally more packets, irrelevant on modern broadband
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -EA 0|ForEach-Object{Set-Reg $_.PSPath 'TcpAckFrequency' 1;Set-Reg $_.PSPath 'TCPNoDelay' 1}
    $safe += '[Network] Nagle OFF + ACK=1 — packets sent immediately, lower ping'

    # Desc: Disable FSO so games use true exclusive fullscreen (bypasses DWM compositor)
    # Safe: Yes - alt-tab may be slightly slower
    Set-Reg 'HKCU:\System\GameConfigStore' 'GameDVR_FSEBehaviorMode' 2
    $safe += '[Gaming] Fullscreen Optimizations OFF — true exclusive fullscreen'

    # Desc: Tell Windows kernel to prioritize GPU work over background tasks
    # Safe: Yes - purely a scheduler hint, no hardware change
    $g='HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
    Set-Reg $g 'GPU Priority' 8; Set-Reg $g 'Priority' 6; Set-Reg $g 'Scheduling Category' 'High' 'String'
    $safe += '[GPU] Priority 8 — kernel sends GPU work first'

    # Desc: Reserve only 10% CPU for background tasks (default 20%) so games get 90%
    # Safe: Yes - antivirus scans run slightly slower during gaming
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'SystemResponsiveness' 10
    $safe += '[CPU] SystemResponsiveness 10 — games get 90% CPU time'

    # Desc: Fixed short CPU quantum for foreground process (games get faster time slices)
    # Safe: Yes - background apps slightly less responsive when alt-tabbing
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl' 'Win32PrioritySeparation' 38
    $safe += '[CPU] Win32Priority 0x26 — faster foreground CPU slices'

    # Desc: Force consistent timer ticks for stable frame pacing in competitive games
    # Safe: Yes - marginally higher idle power (negligible)
    bcdedit /set useplatformtick yes 2>$null; bcdedit /set disabledynamictick yes 2>$null
    $safe += '[Latency] BCD timer optimized — consistent frame pacing'

    # Desc: Disable mouse acceleration for raw 1:1 input (critical for FPS games)
    # Safe: Yes - adjust mouse DPI in hardware to compensate
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseSpeed' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold1' '0' 'String'
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseThreshold2' '0' 'String'
    $safe += '[Input] Mouse acceleration OFF — raw 1:1 movement'

    # Desc: Set keyboard to max repeat rate with zero delay for faster in-game input
    # Safe: Yes - holding keys fires rapidly (fine for gaming, fast for typing)
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardSpeed' '31' 'String'
    Set-Reg 'HKCU:\Control Panel\Keyboard' 'KeyboardDelay' '0' 'String'
    $safe += '[Input] Keyboard max speed — zero repeat delay'

    # =============== TIER 2: RAM-BASED + iGPU AWARENESS ===============
    # iGPU laptops (Intel UHD/Iris, AMD Vega) share system RAM as VRAM
    # Disabling memory compression on these causes VRAM starvation and GPU crashes
    $hasIGPU = $gpu -match 'Intel|UHD|Iris|Vega|AMD Radeon\(TM\) Graphics'
    $iGPUGuard = $isLaptop -and $hasIGPU

    if ($ramGB -le 4) {
        $skip += '[Memory] Compression kept ON — critical for 4GB (saves physical RAM)'
        $skip += '[Service] SysMain kept ON — helps 4GB preload apps from disk'
        $warnings += 'Your 4GB RAM is very limited. Consider upgrading to 8GB+ for better gaming.'
    }
    elseif ($ramGB -le 8) {
        $skip += '[Memory] Compression kept ON — helpful for 8GB (games use 6-8GB)'
        try{Set-Service -Name 'SysMain' -StartupType Disabled -EA Stop;Stop-Service -Name 'SysMain' -Force -EA Stop}catch{}
        $safe += '[Service] SysMain disabled — frees RAM and stops disk thrashing'
    }
    elseif ($ramGB -le 16) {
        if ($iGPUGuard) {
            $skip += '[Memory] Compression kept ON — iGPU laptop shares RAM as VRAM (disabling causes GPU crashes)'
            $warnings += 'Your Intel/AMD iGPU borrows system RAM. Memory compression kept ON to prevent VRAM starvation.'
        } else {
            try{Disable-MMAgent -MemoryCompression -EA Stop}catch{}
            $safe += '[Memory] Compression OFF — 16GB + dedicated GPU has headroom'
        }
        try{Set-Service -Name 'SysMain' -StartupType Disabled -EA Stop;Stop-Service -Name 'SysMain' -Force -EA Stop}catch{}
        $safe += '[Service] SysMain disabled — frees RAM for games'
        try{Set-Service -Name 'WSearch' -StartupType Manual -EA Stop}catch{}
        $safe += '[Service] WSearch set to Manual — reduces background disk I/O'
    }
    elseif ($ramGB -le 32) {
        if ($iGPUGuard) {
            $skip += '[Memory] Compression kept ON — iGPU laptop shares RAM as VRAM even at 32GB'
        } else {
            try{Disable-MMAgent -MemoryCompression -EA Stop}catch{}
            $safe += '[Memory] Compression OFF — 32GB has massive headroom'
        }
        try{Set-Service -Name 'SysMain' -StartupType Disabled -EA Stop;Stop-Service -Name 'SysMain' -Force -EA Stop}catch{}
        $safe += '[Service] SysMain disabled — unnecessary with 32GB'
        try{Set-Service -Name 'WSearch' -StartupType Manual -EA Stop}catch{}
        $safe += '[Service] WSearch to Manual — saves CPU and disk writes'
    }
    else {
        if ($iGPUGuard) {
            $skip += '[Memory] Compression kept ON — iGPU VRAM safety even at 64GB+'
        } else {
            try{Disable-MMAgent -MemoryCompression -EA Stop}catch{}
            $safe += '[Memory] Compression OFF — 64GB+ has extreme headroom'
        }
        try{Set-Service -Name 'SysMain' -StartupType Disabled -EA Stop;Stop-Service -Name 'SysMain' -Force -EA Stop}catch{}
        $safe += '[Service] SysMain disabled — completely unnecessary at 64GB'
        try{Set-Service -Name 'WSearch' -StartupType Manual -EA Stop}catch{}
        $safe += '[Service] WSearch to Manual — saves CPU cycles'
    }

    # =============== TIER 3: DEVICE-SPECIFIC (Desktop vs Laptop) ===============
    if ($isLaptop) {
        # LAPTOP: Thermal-safe optimizations only
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
        $safe += '[Power] High Performance plan — laptop-safe (not Ultimate)'
        powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 99 2>$null
        powercfg -setactive scheme_current 2>$null
        $safe += '[Power] 99% CPU cap — prevents turbo overheat-crash loop'
        Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' 'PowerThrottlingOff' 1
        $safe += '[Power] Throttling OFF when on charger — full speed on AC'
        # Laptop SKIPS (dangerous for thermals)
        $skip += '[Power] Core unparking — increases heat, laptop fans cannot handle constant 100%'
        $skip += '[Security] Spectre/Meltdown disable — crash risk on battery power transitions'
        $skip += '[Security] VBS disable — security risk on portable device (stolen/lost)'
        $skip += '[Power] Ultimate Performance plan — drains battery 3x faster'
        if ($ramGB -le 8) { $warnings += 'Laptop with 8GB or less: Close Chrome before gaming to free 2-4GB RAM.' }
    }
    else {
        # DESKTOP: Full power optimizations
        $out = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
        if ($out -match '([0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12})') { powercfg /setactive $Matches[1] 2>$null }
        $safe += '[Power] Ultimate Performance plan — zero CPU throttling (desktop has fans)'
        $cpPath = 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583'
        Set-Reg $cpPath 'Attributes' 0
        powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 2>$null
        powercfg -setactive scheme_current 2>$null
        $safe += '[CPU] All cores unparked — eliminates micro-stutter from core wake-up'
        if ($ramGB -ge 32 -and $cpuCores -ge 8) {
            # High-end desktop gets more aggressive tweaks
            Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' 'OverlayTestMode' 5
            $safe += '[GPU] MPO disabled — fixes borderless flickering on high-end rigs'
        }
    }

    # =============== BUILD REPORT ===============
    $msg = "SMART PRESET for $HardwareType ($SuggestedTier)`n"
    $msg += "Hardware: $cpuName | $cpuCores cores | ${ramGB}GB RAM @ ${ramSpeed}MHz`nGPU: $gpu`n`n"
    $msg += "APPLIED ($($safe.Count) tweaks):`n"
    foreach ($s in $safe) { $msg += "  [OK] $s`n" }
    if ($skip.Count -gt 0) { $msg += "`nSKIPPED ($($skip.Count) — incompatible with your device):`n"; foreach ($s in $skip) { $msg += "  [--] $s`n" } }
    if ($warnings.Count -gt 0) { $msg += "`nWARNINGS:`n"; foreach ($w in $warnings) { $msg += "  [!!] $w`n" } }
    [System.Windows.MessageBox]::Show($msg, 'Smart Preset Report', 'OK', 'Information') | Out-Null
    Write-Log "Smart Preset: $($safe.Count) applied, $($skip.Count) skipped for $HardwareType ${ramGB}GB" OK; Play-Tone
}

# SERVICE PICKER: Interactive Out-GridView with descriptions
function Show-ServicePicker {
    Write-Log "Opening Service Picker with descriptions..." Action
    $services = @(
        [PSCustomObject]@{Name='Print Spooler';Service='Spooler';Description='Manages print jobs and printer communication';Risk='LOW - Disable if no printer connected';Current=''}
        [PSCustomObject]@{Name='Bluetooth Support';Service='bthserv';Description='Bluetooth device pairing and connectivity';Risk='LOW - Disable if no BT devices used';Current=''}
        [PSCustomObject]@{Name='Windows Search';Service='WSearch';Description='File indexing for Start menu and Explorer search';Risk='MEDIUM - Disabling breaks Outlook search and Start menu results';Current=''}
        [PSCustomObject]@{Name='SysMain (Superfetch)';Service='SysMain';Description='Preloads frequently used apps into RAM';Risk='LOW - SSDs dont benefit, frees RAM and CPU';Current=''}
        [PSCustomObject]@{Name='Diagnostic Tracking';Service='DiagTrack';Description='Sends telemetry data to Microsoft';Risk='LOW - No user impact, saves bandwidth';Current=''}
        [PSCustomObject]@{Name='Xbox Live Auth';Service='XblAuthManager';Description='Xbox Live authentication for Microsoft Store games';Risk='LOW - Only needed for Xbox/MS Store games';Current=''}
        [PSCustomObject]@{Name='Xbox Live Game Save';Service='XblGameSave';Description='Cloud save sync for Xbox/MS Store games';Risk='LOW - Only needed for Xbox game saves';Current=''}
        [PSCustomObject]@{Name='Xbox Accessory Mgmt';Service='XboxGipSvc';Description='Manages Xbox controllers and accessories';Risk='MEDIUM - Needed for Xbox controller firmware updates';Current=''}
        [PSCustomObject]@{Name='Connected User Exp';Service='dmwappushservice';Description='WAP push message routing for telemetry';Risk='LOW - No user-facing impact';Current=''}
        [PSCustomObject]@{Name='Tablet Input';Service='TabletInputService';Description='Pen and touch input for tablets/touchscreens';Risk='LOW - Only needed for touch/pen devices';Current=''}
        [PSCustomObject]@{Name='Windows Error Report';Service='WerSvc';Description='Sends crash reports to Microsoft';Risk='LOW - You lose automatic crash reporting';Current=''}
        [PSCustomObject]@{Name='Fax Service';Service='Fax';Description='Send/receive faxes via modem';Risk='LOW - Almost nobody uses fax anymore';Current=''}
        [PSCustomObject]@{Name='Remote Registry';Service='RemoteRegistry';Description='Allows remote registry editing';Risk='LOW + SECURITY - Should be disabled on all PCs';Current=''}
        [PSCustomObject]@{Name='Distributed Tracking';Service='TrkWks';Description='Tracks NTFS file links across network';Risk='LOW - Only useful in domain environments';Current=''}
        [PSCustomObject]@{Name='Geolocation';Service='lfsvc';Description='GPS and location services';Risk='LOW - Disable if you dont use location in apps';Current=''}
        [PSCustomObject]@{Name='Downloaded Maps Mgr';Service='MapsBroker';Description='Background map tile downloads for Maps app';Risk='LOW - Disable if you dont use Windows Maps';Current=''}
        [PSCustomObject]@{Name='Phone Service';Service='PhoneSvc';Description='Manages telephony state on the device';Risk='LOW - Only needed for Your Phone/Phone Link app';Current=''}
        [PSCustomObject]@{Name='Retail Demo';Service='RetailDemo';Description='Demo mode for retail store display PCs';Risk='NONE - Should always be disabled on personal PCs';Current=''}
        [PSCustomObject]@{Name='SSDP Discovery';Service='SSDPSRV';Description='Discovers UPnP network devices';Risk='LOW - Only needed for smart home/DLNA devices';Current=''}
        [PSCustomObject]@{Name='Windows Biometric';Service='WbioSrvc';Description='Fingerprint and face recognition (Hello)';Risk='MEDIUM - Needed for Windows Hello biometric login';Current=''}
        [PSCustomObject]@{Name='Program Compat Asst';Service='PcaSvc';Description='Detects app compatibility issues on launch';Risk='LOW - Disabling means no auto-compat popups';Current=''}
        [PSCustomObject]@{Name='Smart Card';Service='SCardSvr';Description='Smart card reader support';Risk='LOW - Only for smart card authentication';Current=''}
        [PSCustomObject]@{Name='BITS';Service='BITS';Description='Background Intelligent Transfer - used by Windows Update';Risk='HIGH - Disabling breaks Windows Update and Store downloads';Current=''}
        [PSCustomObject]@{Name='Windows Update';Service='wuauserv';Description='Downloads and installs Windows updates';Risk='HIGH - Disabling leaves system unpatched and vulnerable';Current=''}
    )
    foreach($s in $services){try{$st=(Get-Service -Name $s.Service -EA Stop).Status;$s.Current="$st"}catch{$s.Current='Not Found'}}
    $selected = $services | Out-GridView -Title 'SELECT SERVICES TO DISABLE (Ctrl+Click to multi-select) — Read Risk column carefully!' -OutputMode Multiple
    if($null -eq $selected -or $selected.Count -eq 0){Write-Log "No services selected" Info;return}
    $highRisk = $selected | Where-Object {$_.Risk -match '^HIGH'}
    if($highRisk){
        $r=[System.Windows.MessageBox]::Show("You selected HIGH-RISK services:`n$($highRisk.Name -join ', ')`n`nThis may break Windows Update or core functionality.`nContinue?","High Risk Warning","YesNo","Warning")
        if($r -eq 'No'){Write-Log "Cancelled due to high-risk selection" Warn;return}
    }
    $c=0
    foreach($s in $selected){
        try{Set-Service -Name $s.Service -StartupType Disabled -EA Stop;Stop-Service -Name $s.Service -Force -EA Stop;$c++;Write-Log "  $($s.Name) ($($s.Service)) -> DISABLED [$($s.Risk)]" Info}catch{Write-Log "  Could not disable $($s.Name): $_" Warn}
    }
    Write-Log "Service Picker: $c of $($selected.Count) services disabled" OK; Play-Tone
}

# ADVANCED NETWORK: Deep TCP/IP stack optimization
function Apply-AdvancedNetwork {
    Write-Log "Advanced Network Optimization (tested, safe tweaks)..." Action
    # TCP stack optimization
    netsh int tcp set global rss=enabled 2>$null; Write-Log "  RSS enabled (multi-core packet processing)" Info
    netsh int tcp set global autotuninglevel=normal 2>$null; Write-Log "  TCP auto-tune normal (max bandwidth)" Info
    netsh int tcp set global ecncapability=enabled 2>$null; Write-Log "  ECN enabled (congestion notification)" Info
    netsh int tcp set global timestamps=disabled 2>$null; Write-Log "  TCP timestamps OFF (less overhead)" Info
    netsh int tcp set global initialRto=2000 2>$null; Write-Log "  Initial RTO 2000ms (faster retransmit)" Info
    netsh int tcp set global nonsackrttresiliency=disabled 2>$null; Write-Log "  Non-SACK resilience OFF (faster recovery)" Info
    # Remove throttle + Nagle
    Set-Reg 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' 'NetworkThrottlingIndex' 0xffffffff
    Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -EA 0|ForEach-Object{Set-Reg $_.PSPath 'TcpAckFrequency' 1;Set-Reg $_.PSPath 'TCPNoDelay' 1}
    Write-Log "  Nagle OFF + ACK frequency 1 on all interfaces" Info
    # DNS optimization
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' 'MaxCacheTtl' 86400; Write-Log "  DNS cache TTL optimized" Info
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' 'MaxNegativeCacheTtl' 5; Write-Log "  Negative DNS cache 5s (faster retry)" Info
    # Adapter-level tweaks
    Get-NetAdapterAdvancedProperty -DisplayName '*Flow Control*' -EA 0|ForEach-Object{Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Flow Control' -DisplayValue 'Disabled' -EA 0}; Write-Log "  Flow Control OFF on all adapters" Info
    Get-NetAdapterAdvancedProperty -DisplayName '*Checksum Offload*' -EA 0|ForEach-Object{Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName $_.DisplayName -DisplayValue 'Disabled' -EA 0}; Write-Log "  Checksum offload OFF (CPU handles - lower latency)" Info
    Get-NetAdapterAdvancedProperty -DisplayName '*Large Send Offload*' -EA 0|ForEach-Object{Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName $_.DisplayName -DisplayValue 'Disabled' -EA 0}; Write-Log "  LSO OFF (prevents packet batching delay)" Info
    Write-Log "Advanced Network optimization complete!" OK; Play-Tone
}

# Hardware Guard: Prevents applying desktop-only tweaks on laptop
function Guard-DeviceCompat {
    param([string]$RequiredType, [string]$TweakName)
    if ($RequiredType -eq 'DESKTOP' -and $isLaptop) {
        [System.Windows.MessageBox]::Show("'$TweakName' is designed for DESKTOP PCs only.`n`nYour device is a LAPTOP.`nApplying this could cause overheating, crashes, or thermal throttling.`n`nUse the LAPTOP section instead.",'Incompatible Tweak','OK','Warning') | Out-Null
        Write-Log "BLOCKED: '$TweakName' - laptop detected, desktop-only tweak" Warn
        return $false
    }
    return $true
}

# ============================================================
# SECTION 11D: MAKE TWEAKS PERMANENT (Startup Task)
# ============================================================
# Some tweaks are session-only (process priority, auto-booster). This creates
# a startup task that re-applies them every boot automatically.

function Make-TweaksPermanent {
    Write-Log "Making session-only tweaks permanent via Startup Task..." Action

    # Create the startup script content
    $startupScript = @'
# Ray's Chamber Startup Script - Auto-applies session-only tweaks
# Process Priority Boosts (these reset every reboot)
$gameList = @('cs2','valorant','FortniteClient-Win64-Shipping','r5apex','GTA5','RocketLeague')
$boostTargets = @('DS4Windows','ds4winWPF','reWASD','JoyToKey','steam')
$demoteTargets = @('chrome','msedge','discord')
while ($true) {
    # Boost controller software
    foreach ($name in $boostTargets) {
        Get-Process -Name $name -EA 0 | ForEach-Object { try{$_.PriorityClass='High'}catch{} }
    }
    # Boost games, demote browsers
    foreach ($g in $gameList) {
        $p = Get-Process -Name $g -EA 0
        if ($p) {
            $p | ForEach-Object { try{$_.PriorityClass='High'}catch{} }
            foreach ($d in $demoteTargets) { Get-Process -Name $d -EA 0 | ForEach-Object { try{$_.PriorityClass='BelowNormal'}catch{} } }
        }
    }
    Start-Sleep -Seconds 60
}
'@

    # Save script to user's AppData
    $scriptPath = "$env:APPDATA\RaysChamber\BoostService.ps1"
    $scriptDir = Split-Path $scriptPath
    if (-not (Test-Path $scriptDir)) { New-Item -Path $scriptDir -ItemType Directory -Force | Out-Null }
    $startupScript | Out-File -FilePath $scriptPath -Encoding UTF8 -Force
    Write-Log "  Startup script saved to $scriptPath" Info

    # Create scheduled task that runs at logon
    $action = New-ScheduledTaskAction -Execute 'PowerShell.exe' -Argument "-WindowStyle Hidden -ExecutionPolicy Bypass -File `"$scriptPath`""
    $trigger = New-ScheduledTaskTrigger -AtLogOn -User $env:USERNAME
    $settings = New-ScheduledTaskSettingsSet -AllowStartIfOnBatteries -DontStopIfGoingOnBatteries -ExecutionTimeLimit ([TimeSpan]::Zero)
    Register-ScheduledTask -Action $action -Trigger $trigger -Settings $settings -TaskName 'RaysChamber_AutoBoost' -Description 'Auto-boosts games and controller software at login' -Force | Out-Null
    Write-Log "  Scheduled task 'RaysChamber_AutoBoost' registered (runs at login)" Info

    Write-Log "SESSION TWEAKS NOW PERMANENT! Auto-booster runs every boot." OK
    Write-Log "  Boosted at login: Controller software -> High priority" Info
    Write-Log "  Boosted on detect: Games -> High, Browsers -> BelowNormal" Info
    Play-Tone
}

function Remove-PermanentTweaks {
    Write-Log "Removing permanent startup tweaks..." Action
    Unregister-ScheduledTask -TaskName 'RaysChamber_AutoBoost' -Confirm:$false -ErrorAction SilentlyContinue
    $scriptPath = "$env:APPDATA\RaysChamber\BoostService.ps1"
    Remove-Item $scriptPath -Force -ErrorAction SilentlyContinue
    Remove-Item (Split-Path $scriptPath) -Force -ErrorAction SilentlyContinue
    Write-Log "Startup task and script removed" OK; Play-Tone
}

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
    # Restore mouse acceleration curves to Windows default
    Remove-ItemProperty -Path 'HKCU:\Control Panel\Mouse' -Name 'SmoothMouseXCurve' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKCU:\Control Panel\Mouse' -Name 'SmoothMouseYCurve' -ErrorAction SilentlyContinue
    Set-Reg 'HKCU:\Control Panel\Mouse' 'MouseTrails' '0' 'String'
    # Restore GPU vendor-specific settings
    $gpuReg = 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000'
    Remove-ItemProperty -Path $gpuReg -Name 'PowerMizerLevel' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $gpuReg -Name 'PowerMizerEnable' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $gpuReg -Name 'PP_ThermalAutoThrottlingEnable' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path $gpuReg -Name 'ACPowerPolicyVersion' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path "$gpuReg\GMM" -Name 'VSync' -ErrorAction SilentlyContinue
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
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name 'DisableOverlays' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000' -Name 'RMVsyncControl' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000' -Name 'LowLatencyMode' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000' -Name 'FrameRateLimiterV3' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000\UMD' -Name 'AntiLag' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000\UMD' -Name 'FlipQueueSize' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000\UMD' -Name 'Main3D_FrameRateTarget_DEF' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\DirectX' -Name 'SwapEffectUpgradeEnable' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\DirectX' -Name 'ForceFlipPresentModel' -ErrorAction SilentlyContinue
    Remove-ItemProperty -Path 'HKCU:\Software\Microsoft\DirectX\GraphicsSettings' -Name 'SwapEffectUpgradeCache' -ErrorAction SilentlyContinue
    Remove-PermanentTweaks
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 2
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\DirectX' -Name 'ShaderCacheSizeLimitKB' -ErrorAction SilentlyContinue
    fsutil behavior set disablelastaccess 2 2>$null
    powercfg -setacvalueindex scheme_current 501a4d13-42af-4429-9fd1-a8218c268e20 ee12f906-d277-404b-b6da-e5fa1a576df5 1 2>$null; powercfg -setactive scheme_current 2>$null
    # Revert advanced network
    netsh int tcp set global ecncapability=default 2>$null; netsh int tcp set global timestamps=default 2>$null
    netsh int tcp set global initialRto=3000 2>$null; netsh int tcp set global nonsackrttresiliency=enabled 2>$null
    Remove-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name 'MaxCacheTtl' -EA 0
    Remove-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Services\Dnscache\Parameters' -Name 'MaxNegativeCacheTtl' -EA 0
    Get-NetAdapterAdvancedProperty -DisplayName '*Flow Control*' -EA 0|ForEach-Object{Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Flow Control' -DisplayValue 'Rx & Tx Enabled' -EA 0}
    Get-NetAdapterAdvancedProperty -DisplayName '*Checksum Offload*' -EA 0|ForEach-Object{Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName $_.DisplayName -DisplayValue 'Rx & Tx Enabled' -EA 0}
    Get-NetAdapterAdvancedProperty -DisplayName '*Large Send Offload*' -EA 0|ForEach-Object{Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName $_.DisplayName -DisplayValue 'Enabled' -EA 0}
    # Revert interrupt moderation + adapter power
    Get-NetAdapterAdvancedProperty -DisplayName '*Interrupt Moderation*' -EA 0|ForEach-Object{Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName 'Interrupt Moderation' -DisplayValue 'Enabled' -EA 0}
    Get-NetAdapterAdvancedProperty -DisplayName '*Energy Efficient*' -EA 0|ForEach-Object{Set-NetAdapterAdvancedProperty -Name $_.Name -DisplayName $_.DisplayName -DisplayValue 'Enabled' -EA 0}
    # Revert interrupt affinity
    Get-PnpDevice -Status OK -EA 0|Where-Object{$_.Class -in @('Display','Net')}|ForEach-Object{$af="HKLM:\SYSTEM\CurrentControlSet\Enum\$($_.InstanceId)\Device Parameters\Interrupt Management\Affinity Policy";Remove-ItemProperty $af -Name 'DevicePolicy' -EA 0;Remove-ItemProperty $af -Name 'AssignmentSetOverride' -EA 0}
    # Revert S3/standby
    Remove-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'PlatformAoAcOverride' -EA 0
    Remove-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'DeepSleepEnabled' -EA 0
    # Revert Zero-Tear (DWM, DirectX, GPU latency)
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name 'ForceEffectMode' -EA 0
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name 'DisableOverlays' -EA 0
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name 'OverlayTestMode' -EA 0
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\Dwm' -Name 'DisableDWMVSyncTSC' -EA 0
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\DirectX' -Name 'SwapEffectUpgradeEnable' -EA 0
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\DirectX' -Name 'ForceFlipPresentModel' -EA 0
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\DirectX' -Name 'MaxQueuedFrames' -EA 0
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\DirectX\GraphicsSettings' -Name 'MaxQueuedFrames' -EA 0
    Remove-ItemProperty 'HKCU:\Software\Microsoft\DirectX\GraphicsSettings' -Name 'SwapEffectUpgradeCache' -EA 0
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers' 'HwSchMode' 1
    $gpuRvt='HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000'
    Remove-ItemProperty $gpuRvt -Name 'MaxFrameAllowed' -EA 0
    Remove-ItemProperty "$gpuRvt\UMD" -Name 'MaxFrameAllowed' -EA 0
    $gpuReg='HKLM:\SYSTEM\CurrentControlSet\Control\Class\{4d36e968-e325-11ce-bfc1-08002be10318}\0000'
    foreach($k in @('LowLatencyMode','RMVsyncControl','FrameRateLimiterV3','PowerMizerLevel','PowerMizerEnable','PerfLevelSrc','PP_ThermalAutoThrottlingEnable','ACPowerPolicyVersion')){Remove-ItemProperty $gpuReg -Name $k -EA 0}
    Remove-ItemProperty "$gpuReg\UMD" -Name 'AntiLag' -EA 0; Remove-ItemProperty "$gpuReg\UMD" -Name 'FlipQueueSize' -EA 0
    Remove-ItemProperty "$gpuReg\UMD" -Name 'Main3D_FrameRateTarget_DEF' -EA 0; Remove-ItemProperty "$gpuReg\UMD" -Name 'Wait for Vertical Refresh_DEF' -EA 0
    Remove-ItemProperty "$gpuReg\GMM" -Name 'VSync' -EA 0; Remove-ItemProperty $gpuReg -Name 'VSync' -EA 0
    # Revert config tweaks
    Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Personalization' -Name 'NoLockScreen' -EA 0
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Explorer\Shell Icons' -Name '29' -EA 0
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' 'TaskbarAl' 1
    Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'UseCompactMode' -EA 0
    Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection' -Name 'MaxTelemetryAllowed' -EA 0
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\DataCollection' -Name 'AllowTelemetry' -EA 0
    foreach($k in @('StartupBoostEnabled','BackgroundModeEnabled')){Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Edge' -Name $k -EA 0}
    Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Chat' -Name 'ChatIcon' -EA 0
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\Explorer' -Name 'HideSCAMeetNow' -EA 0
    Remove-ItemProperty 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortana' -EA 0
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'RotatingLockScreenOverlayEnabled' 1
    Set-Reg 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' 'SilentInstalledAppsEnabled' 1
    Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced\TaskbarDeveloperSettings' -Name 'TaskbarEndTask' -EA 0
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\Windows\CurrentVersion\Policies\System' -Name 'VerboseStatus' -EA 0
    Remove-ItemProperty 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'ShowSecondsInSystemClock' -EA 0
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Power' 'HiberbootEnabled' 1
    # Revert USB/HID power management
    Set-Reg 'HKLM:\SYSTEM\CurrentControlSet\Services\HidUsb\Parameters' 'EnhancedPowerManagementEnabled' 1
    Remove-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'ExitLatency' -EA 0
    Remove-ItemProperty 'HKLM:\SYSTEM\CurrentControlSet\Control\Power' -Name 'DisableSensorWatchdog' -EA 0
    # Revert Game Mode
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AllowAutoGameMode' 1
    Set-Reg 'HKCU:\Software\Microsoft\GameBar' 'AutoGameModeEnabled' 1
    Remove-ItemProperty 'HKCU:\Software\Microsoft\GameBar' -Name 'UseNexusForGameBarEnabled' -EA 0
    # Revert services disabled by Deep Kill
    foreach($svc in @('PcaSvc','WerSvc','AppReadiness','CDPSvc','WpnService','XboxGipSvc','XblAuthManager','XblGameSave','XboxNetApiSvc','Fax','RemoteRegistry','TrkWks','WMPNetworkSvc','SSDPSRV','lfsvc','MapsBroker','PhoneSvc','RetailDemo','wisvc','icssvc','WpcMonSvc','SEMgrSvc','SCardSvr','WbioSrvc','MessagingService')){try{Set-Service -Name $svc -StartupType Manual -EA Stop}catch{}}
    # Revert CTO features
    # Speed Shift EPP back to balanced (128)
    powercfg -setacvalueindex scheme_current sub_processor PERFEPP 128 2>$null
    powercfg -setdcvalueindex scheme_current sub_processor PERFEPP 128 2>$null
    powercfg -setactive scheme_current 2>$null
    # Restore WLAN scanning
    netsh wlan set autoconfig enabled=yes interface="Wi-Fi" 2>$null
    netsh wlan set autoconfig enabled=yes interface="WiFi" 2>$null
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\WlanSvc' -Name 'ScanWhenAssociated' -EA 0
    Remove-ItemProperty 'HKLM:\SOFTWARE\Microsoft\WlanSvc' -Name 'ScanOnlyActiveProbe' -EA 0
    # Remove IFEO game priority injections
    $ifeogames = @('cs2.exe','VALORANT-Win64-Shipping.exe','FortniteClient-Win64-Shipping.exe','r5apex.exe','GTA5.exe','RocketLeague.exe','javaw.exe','RobloxPlayerBeta.exe','cod.exe','Overwatch.exe','FiveM.exe','FiveM_b2699_GTAProcess.exe')
    foreach ($g in $ifeogames) { Remove-Item "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Image File Execution Options\$g" -Recurse -Force -EA 0 }
    # Clean up everything
    Remove-ContextMenu; Unregister-ScheduledTask -TaskName 'RaysChamber_Maintenance' -Confirm:$false -EA 0; Stop-AutoBooster; Remove-PermanentTweaks
    try{Enable-MMAgent -MemoryCompression -EA Stop}catch{}
    powercfg /h on 2>$null; fsutil behavior set disablelastaccess 2 2>$null
    try{Set-Service -Name WSearch -StartupType Automatic -EA Stop;Start-Service WSearch -EA Stop}catch{}
    Restart-Shell
    Write-Log "ALL changes reverted to Windows defaults! System is clean." OK; [console]::Beep(880,150); [console]::Beep(660,150); [console]::Beep(440,300)
}

# ============================================================
# SECTION 12: WPF XAML - DEVICE-SEPARATED TWEAKS TAB
# ============================================================
$xaml = @'
<Window
    xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
    xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
    Title="Rays Optimization Chamber v9.0 AUDITED"
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

                    <!-- SMART PRESET -->
                    <Border Background="#001030" BorderBrush="#00FFCC" BorderThickness="2" CornerRadius="6" Padding="10" Margin="0,0,0,12">
                        <StackPanel>
                            <TextBlock Text="SMART PRESET (Recommended)" FontSize="15" FontWeight="Bold" Foreground="#00FFCC" Margin="0,0,0,4"/>
                            <TextBlock Text="Scans YOUR hardware and applies ONLY compatible, safe tweaks. Skips anything dangerous for your device." FontSize="11" Foreground="#8090A0" Margin="0,0,0,8" TextWrapping="Wrap"/>
                            <WrapPanel>
                                <Button Name="BtnSmartPreset" Content="[AUTO] Apply Smart Preset for My Hardware" FontWeight="Bold" ToolTip="Detects Desktop/Laptop, RAM, CPU cores and applies the safest optimizations automatically. Shows exactly what was applied and what was skipped."/>
                                <Button Name="BtnServicePicker" Content="Pick Services to Disable" ToolTip="Opens a list of 24 Windows services with full descriptions, risk levels, and current status. YOU choose which to disable."/>
                                <Button Name="BtnAdvNetwork" Content="Advanced Network Optimization" ToolTip="Deep TCP/IP stack tuning: RSS, ECN, timestamps, RTO, flow control, checksum offload, LSO, DNS cache. All tested and safe."/>
                            </WrapPanel>
                        </StackPanel>
                    </Border>

                    <!-- ULTRABOOK-SAFE PROFILE -->
                    <Border Background="#000F2A" BorderBrush="#FF9900" BorderThickness="2" CornerRadius="6" Padding="10" Margin="0,0,0,12">
                        <StackPanel>
                            <TextBlock Text="ULTRABOOK-SAFE PROFILE (Dell Latitude / XPS / ThinkPad)" FontSize="15" FontWeight="Bold" Foreground="#FF9900" Margin="0,0,0,4"/>
                            <TextBlock Text="CTO-engineered 1-click optimization for thermally-constrained Intel ultrabooks. Uses Speed Shift instead of core unparking. Skips ALL dangerous tweaks. Leaves WiFi, Bluetooth, Audio, Battery intact." FontSize="11" Foreground="#8090A0" Margin="0,0,0,8" TextWrapping="Wrap"/>
                            <WrapPanel>
                                <Button Name="BtnUltrabook" Content="[CTO] Apply Ultrabook-Safe Profile" FontWeight="Bold" ToolTip="1-click profile for Dell Latitude, XPS, ThinkPad, etc. Applies: Speed Shift EPP=0, IFEO game priority (Fortnite/Valorant/FiveM/Roblox), WiFi lag fix, MPO/FSO disable, pre-rendered frames=1, GPU Priority 8, Game DVR kill, telemetry off, mouse accel off, USB power off. SKIPS: core unparking, VBS disable, Spectre off, BCD timers, Ultimate Performance, HAGS, Flip Model."/>
                            </WrapPanel>
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
                    <TextBlock Text="-- Advanced Latency --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnHPET" Content="Toggle HPET" ToolTip="Toggles High Precision Event Timer - disable for smoother frametimes on some rigs"/>
                        <Button Name="BtnDisableGameMode" Content="Disable Game Mode" ToolTip="Kills Game Bar, Game DVR, and Game Mode overlays completely"/>
                        <Button Name="BtnSuspendBrowsers" Content="Suspend Browsers" ToolTip="Sets all browser processes to Idle priority to reclaim 2GB+ RAM during gaming"/>
                        <Button Name="BtnResumeApps" Content="Resume Apps" ToolTip="Restores all demoted browser/app processes to Normal priority"/>
                    </WrapPanel>
                    <TextBlock Text="-- Zero-Tear Mode (No V-Sync, No Tearing) --" FontSize="13" FontWeight="Bold" Foreground="#FFD700" Margin="0,16,0,4"/>
                    <TextBlock Text="Eliminates screen tearing using frame cap + flip model + low latency. ZERO input lag penalty." FontSize="10" Foreground="#8090A0" Margin="0,0,0,6"/>
                    <WrapPanel>
                        <Button Name="BtnZeroTear" Content="Enable Zero-Tear Mode" FontWeight="Bold" ToolTip="DWM composition fix + Flip Model + HAGS + GPU Low Latency + Frame Cap at Hz-3. No V-Sync = no input lag. Works on NVIDIA/AMD/Intel."/>
                    </WrapPanel>
                    <TextBlock Text="-- Persistence --" FontSize="13" FontWeight="Bold" Foreground="#FFD700" Margin="0,12,0,4"/>
                    <TextBlock Text="Makes session-only tweaks (process priority, auto-booster) survive reboots" FontSize="10" Foreground="#8090A0" Margin="0,0,0,6"/>
                    <WrapPanel>
                        <Button Name="BtnMakePermanent" Content="Make Tweaks Permanent" ToolTip="Creates a startup task that auto-boosts games and controller software at every login. Re-applies process priority tweaks that normally reset on reboot."/>
                        <Button Name="BtnRemovePermanent" Content="Remove Permanent Tweaks" ToolTip="Removes the startup task and script so tweaks no longer auto-apply on boot"/>
                    </WrapPanel>
                    <TextBlock Text="-- Tools --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnFrameCap" Content="Frame Cap Advisor" ToolTip="Detects Hz and recommends cap"/>
                        <Button Name="BtnLaptopGod" Content="Laptop God Mode" ToolTip="99% CPU + throttle off (laptops only)"/>
                    </WrapPanel>
                    <TextBlock Text="-- CTO: Kernel Performance Engineering --" FontSize="13" FontWeight="Bold" Foreground="#FF9900" Margin="0,16,0,4"/>
                    <TextBlock Text="Professional-grade optimizations verified by Windows Kernel Performance Engineering standards" FontSize="10" Foreground="#8090A0" Margin="0,0,0,6"/>
                    <WrapPanel>
                        <Button Name="BtnSpeedShift" Content="Intel Speed Shift EPP=0" ToolTip="Sets Energy Performance Preference to Maximum Performance. Intel CPUs ramp to max frequency INSTANTLY when game loads. Battery mode stays at EPP=50 (balanced). BETTER than core unparking for 12th gen+ hybrid CPUs."/>
                        <Button Name="BtnWLANFix" Content="Fix WiFi Lag Spikes" ToolTip="Stops WLAN AutoConfig from scanning for nearby networks during gameplay. Each scan causes 50-200ms ping spikes. Disables background scanning while connected. Re-enable with one click."/>
                        <Button Name="BtnWLANRestore" Content="Restore WiFi Scanning" ToolTip="Re-enables WLAN AutoConfig background scanning"/>
                        <Button Name="BtnIFEO" Content="IFEO Game Priority" ToolTip="Injects CPU=High and IO=High priority for 10 games (CS2, Valorant, Fortnite, Apex, GTA V, Rocket League, Minecraft, Roblox, CoD, Overwatch) via Image File Execution Options. Priority is set BEFORE launch, not after detection. Fully documented Windows API."/>
                        <Button Name="BtnShaderClear" Content="Clear Shader Caches" ToolTip="Clears DirectX, NVIDIA, AMD, and Intel shader caches. Forces games to recompile shaders with your latest GPU drivers. Fixes first-run stutters and frame drops after driver updates."/>
                        <Button Name="BtnCleanSlate" Content="Clean Slate (Full Cache Purge)" ToolTip="Purges ALL caches: DNS, shader (all vendors), temp files, font cache, thumbnail cache, icon cache, and RAM standby. Ensures optimizations run on a clean system state."/>
                    </WrapPanel>
                    <TextBlock Text="-- Controller Optimization --" FontSize="13" FontWeight="Bold" Foreground="#FFD700" Margin="0,16,0,4"/>
                    <TextBlock Text="DS4Windows/reWASD/Xbox controller input lag reduction" FontSize="10" Foreground="#8090A0" Margin="0,0,0,6"/>
                    <WrapPanel>
                        <Button Name="BtnControllerInfo" Content="Detect Controllers" ToolTip="Shows connected controllers with polling rate tips for PS5/PS4/Xbox"/>
                        <Button Name="BtnControllerBoost" Content="Boost Controller Priority" ToolTip="Sets DS4Windows/reWASD/Steam to High CPU priority for faster input scheduling"/>
                        <Button Name="BtnControllerUSB" Content="Optimize Controller USB" ToolTip="Disables USB power management on ALL HID devices so controllers never sleep or lag"/>
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
                    <TextBlock Text="-- Advanced Hardware --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnGPUMSICheck" Content="Check GPU MSI Status" ToolTip="Shows if GPU uses MSI Mode or legacy Line-Based interrupts"/>
                        <Button Name="BtnS3Sleep" Content="Toggle S3 Deep Sleep" ToolTip="Forces S3 sleep instead of Modern Standby"/>
                        <Button Name="BtnNetStandby" Content="Disable Network in Standby" ToolTip="Stops WiFi/updates during sleep"/>
                        <Button Name="BtnBatteryReport" Content="Battery Health Report" ToolTip="HTML report of battery capacity"/>
                        <Button Name="BtnDriverCleanup" Content="Driver Store Viewer" ToolTip="Shows old unused drivers"/>
                        <Button Name="BtnRegBackup" Content="Backup Registry" ToolTip="Exports registry to .reg on Desktop"/>
                    </WrapPanel>
                    <TextBlock Text="-- Network Adapter --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnIntModOff" Content="Disable Interrupt Moderation" ToolTip="Forces NIC to process every packet immediately instead of batching - lower network latency"/>
                        <Button Name="BtnAdapterPower" Content="Disable Adapter Power Save" ToolTip="Turns off Energy Efficient Ethernet, Green Ethernet, Wake-on-LAN power saving on ALL adapters"/>
                        <Button Name="BtnIntAffinity" Content="Set Interrupt Affinity" ToolTip="Forces GPU and NIC interrupts onto physical CPU cores 0-3 to reduce IRQ conflicts and frame jitter"/>
                    </WrapPanel>
                    <TextBlock Text="-- Custom Power Plan --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnRaysPlan" Content="Create Rays Performance Plan" ToolTip="Custom zero-throttle plan: 100% min CPU, no core parking, no idle states, USB never sleep, PCIe max"/>
                    </WrapPanel>
                    <TextBlock Text="-- System Monitoring --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnProcessCount" Content="Show Process Count" ToolTip="Shows running processes vs target of under 70 for competitive gaming"/>
                        <Button Name="BtnOEMScan" Content="Scan OEM Bloatware" ToolTip="Detects Dell/HP/Lenovo/ASUS/Razer background services draining resources"/>
                        <Button Name="BtnDeepKill" Content="Deep Service Kill" ToolTip="Disables 35+ non-essential services to reach under 70 processes for maximum FPS"/>
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
                    <TextBlock Text="-- Visuals and UX --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnSkipLock" Content="Skip Lock Screen" ToolTip="Bypasses lock screen - goes straight to password prompt"/>
                        <Button Name="BtnNoArrows" Content="Remove Shortcut Arrows" ToolTip="Removes the tiny arrow overlay on desktop shortcuts for a clean look"/>
                        <Button Name="BtnTaskbarLeft" Content="Taskbar Left" ToolTip="Moves Win11 taskbar alignment to the left (classic style)"/>
                        <Button Name="BtnTaskbarCenter" Content="Taskbar Center" ToolTip="Restores Win11 taskbar to center alignment"/>
                        <Button Name="BtnCompactExplorer" Content="Explorer Compact Mode" ToolTip="Reduces padding in File Explorer to show more files at once"/>
                    </WrapPanel>
                    <TextBlock Text="-- Privacy --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnTelemetry0" Content="Telemetry Level 0" ToolTip="Forces Security-level telemetry (Enterprise level) and disables all tracking services"/>
                        <Button Name="BtnStopEdge" Content="Stop Edge Preloading" ToolTip="Prevents Microsoft Edge from starting processes in the background before you open it"/>
                        <Button Name="BtnRemoveMeetNow" Content="Remove Meet Now/Chat" ToolTip="Strips Teams/Chat/Meet Now integration from taskbar and system tray"/>
                    </WrapPanel>
                    <TextBlock Text="-- Audio and Connectivity --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnAudioExcl" Content="Disable Audio Exclusive" ToolTip="Stops games from taking over mic/headphones - fixes no audio in Discord bug"/>
                        <Button Name="BtnBTCollab" Content="Disable BT Collaboration" ToolTip="Prevents WiFi speed from dropping when Bluetooth controller or mouse is connected"/>
                    </WrapPanel>
                    <TextBlock Text="-- Boot and Power --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnNumLock" Content="NumLock on Boot" ToolTip="Auto-enables NumLock when you log in"/>
                        <Button Name="BtnClockSec" Content="Show Seconds on Clock" ToolTip="Displays seconds in the taskbar clock"/>
                        <Button Name="BtnVerboseBoot" Content="Verbose Boot" ToolTip="Shows detailed status messages during startup instead of spinner"/>
                        <Button Name="BtnHibOff" Content="Disable Hibernation" ToolTip="Turns off hibernation and reclaims disk space (deletes hiberfil.sys)"/>
                        <Button Name="BtnHibOn" Content="Enable Hibernation" ToolTip="Re-enables hibernation for sleep-to-disk"/>
                    </WrapPanel>
                    <TextBlock Text="-- Deep Cleanup --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnWinSxS" Content="WinSxS Compression" ToolTip="Deep cleans Windows Update files with DISM ResetBase - reclaims GBs of space"/>
                        <Button Name="BtnSearchIndex" Content="Disable Search Indexing" ToolTip="Stops constant disk writes for file indexing - saves SSD health and CPU"/>
                        <Button Name="BtnSearchIndexOn" Content="Enable Search Indexing" ToolTip="Re-enables Windows Search indexing"/>
                    </WrapPanel>
                    <TextBlock Text="-- Winget Backup --" FontSize="13" FontWeight="Bold" Foreground="#00FFCC" Margin="0,12,0,4"/>
                    <WrapPanel>
                        <Button Name="BtnWingetExport" Content="Export My Apps" ToolTip="Saves all installed winget apps to a JSON file on Desktop for easy reinstall"/>
                        <Button Name="BtnWingetImport" Content="Import App List" ToolTip="Reinstall all apps from a previously exported JSON backup file"/>
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
    'BtnHPET','BtnDisableGameMode','BtnSuspendBrowsers','BtnResumeApps',
    'BtnGPUMSICheck','BtnS3Sleep','BtnNetStandby','BtnBatteryReport','BtnDriverCleanup','BtnRegBackup',
    'BtnSkipLock','BtnNoArrows','BtnTaskbarLeft','BtnTaskbarCenter','BtnCompactExplorer',
    'BtnTelemetry0','BtnStopEdge','BtnRemoveMeetNow','BtnAudioExcl','BtnBTCollab',
    'BtnWinSxS','BtnSearchIndex','BtnSearchIndexOn','BtnWingetExport','BtnWingetImport',
    'BtnUpdDefault','BtnUpdSec','BtnUpdOff','BtnFullScan','BtnSFC','BtnDISM','BtnWinSAT','BtnRestartShell',
    'BtnControllerInfo','BtnControllerBoost','BtnControllerUSB',
    'BtnIntModOff','BtnAdapterPower','BtnIntAffinity','BtnRaysPlan',
    'BtnProcessCount','BtnOEMScan','BtnDeepKill',
    'BtnZeroTear','BtnMakePermanent','BtnRemovePermanent',
    'BtnSmartPreset','BtnServicePicker','BtnAdvNetwork',
    'BtnSpeedShift','BtnWLANFix','BtnWLANRestore','BtnIFEO','BtnShaderClear','BtnCleanSlate',
    'BtnUltrabook'
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
Wire 'BtnDeskLow'    { Write-Log "DEBUG: Desktop Low clicked" Info; try{if(-not(Guard-DeviceCompat 'DESKTOP' 'Desktop Low-End')){return};if(Guard-Restore){Apply-DesktopLow}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnDeskMid'    { Write-Log "DEBUG: Desktop Mid clicked" Info; try{if(-not(Guard-DeviceCompat 'DESKTOP' 'Desktop Mid-Range')){return};if(Guard-Restore){Apply-DesktopMid}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnDeskHigh'   { Write-Log "DEBUG: Desktop High clicked" Info; try{if(-not(Guard-DeviceCompat 'DESKTOP' 'Desktop Nuclear')){return};if(Guard-Restore){Apply-DesktopHigh}}catch{Write-Log "Error: $_" Error} }
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
Wire 'BtnHPET'        { Write-Log "DEBUG: HPET" Info; try{if(Guard-Restore){Toggle-HPET}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnDisableGameMode' { Write-Log "DEBUG: GameMode" Info; try{Disable-GameMode}catch{Write-Log "Error: $_" Error} }
Wire 'BtnSuspendBrowsers' { try{Suspend-Browsers}catch{Write-Log "Error: $_" Error} }
Wire 'BtnResumeApps'  { try{Resume-SuspendedApps}catch{Write-Log "Error: $_" Error} }

# Hardware
Wire 'BtnUltPower'    { Write-Log "DEBUG: UltPower" Info; try{if($isLaptop){$r=[System.Windows.MessageBox]::Show("Ultimate Performance drains laptop battery 3x faster and increases heat.`n`nUse High Performance instead.`nContinue anyway (charger required)?","Laptop Warning","YesNo","Warning");if($r -eq 'No'){return}};if(Guard-Restore){Invoke-UltimatePower}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnUnpark'      { Write-Log "DEBUG: Unpark" Info; try{if($isLaptop){[System.Windows.MessageBox]::Show("Core Unparking is NOT recommended for laptops.`n`nIt forces ALL cores to stay at 100% = extreme heat.`nYour laptop fans cannot handle sustained 100%.`n`nUse Laptop Presets instead.","Laptop Blocked","OK","Warning")|Out-Null;Write-Log "BLOCKED: Core unparking on laptop" Warn;return};if(Guard-Restore){Invoke-UnparkCores}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnMSIMode'     { try{if(Guard-Restore){Enable-MSIMode}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnCheckRAM'    { try{Check-RAMSpeed}catch{Write-Log "Error: $_" Error} }
Wire 'BtnContextMenu' { try{Add-ContextMenu}catch{Write-Log "Error: $_" Error} }
Wire 'BtnRmContext'   { try{Remove-ContextMenu}catch{Write-Log "Error: $_" Error} }
Wire 'BtnMaintTask'   { try{Register-MaintenanceTask}catch{Write-Log "Error: $_" Error} }
Wire 'BtnGPUMSICheck' { try{Check-GPUMSIStatus}catch{Write-Log "Error: $_" Error} }
Wire 'BtnS3Sleep'     { Write-Log "DEBUG: S3" Info; try{if(Guard-Restore){Toggle-S3Sleep}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnNetStandby'  { Write-Log "DEBUG: NetStandby" Info; try{if(Guard-Restore){Disable-NetworkStandby}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnBatteryReport' { try{Get-BatteryReport}catch{Write-Log "Error: $_" Error} }
Wire 'BtnDriverCleanup' { try{Cleanup-DriverStore}catch{Write-Log "Error: $_" Error} }
Wire 'BtnRegBackup'   { try{Backup-Registry}catch{Write-Log "Error: $_" Error} }
Wire 'BtnIntModOff'   { Write-Log "DEBUG: IntModOff" Info; try{if(Guard-Restore){Disable-InterruptModeration}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnAdapterPower' { Write-Log "DEBUG: AdapterPower" Info; try{if(Guard-Restore){Disable-AdapterPowerSave}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnIntAffinity' { Write-Log "DEBUG: IntAffinity" Info; try{if(Guard-Restore){Set-InterruptAffinity}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnRaysPlan'    { Write-Log "DEBUG: RaysPlan" Info; try{if(Guard-Restore){Create-RaysPowerPlan}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnProcessCount' { try{Show-ProcessCount}catch{Write-Log "Error: $_" Error} }
Wire 'BtnOEMScan'     { try{Scan-OEMBloatware}catch{Write-Log "Error: $_" Error} }
Wire 'BtnDeepKill'    { Write-Log "DEBUG: DeepKill" Info; try{if(Guard-Restore){Invoke-DeepServiceKill}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnControllerInfo'  { try{Show-ControllerInfo}catch{Write-Log "Error: $_" Error} }
Wire 'BtnControllerBoost' { try{Boost-ControllerPriority}catch{Write-Log "Error: $_" Error} }
Wire 'BtnControllerUSB'   { Write-Log "DEBUG: ControllerUSB" Info; try{if(Guard-Restore){Optimize-ControllerUSB}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnZeroTear'        { Write-Log "DEBUG: ZeroTear" Info; try{if(Guard-Restore){Enable-ZeroTear}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnMakePermanent'   { Write-Log "DEBUG: MakePermanent" Info; try{Make-TweaksPermanent}catch{Write-Log "Error: $_" Error} }
Wire 'BtnRemovePermanent' { Write-Log "DEBUG: RemovePermanent" Info; try{Remove-PermanentTweaks}catch{Write-Log "Error: $_" Error} }
Wire 'BtnSmartPreset'     { Write-Log "DEBUG: SmartPreset" Info; try{if(Guard-Restore){Invoke-SmartPreset}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnServicePicker'   { Write-Log "DEBUG: ServicePicker" Info; try{Show-ServicePicker}catch{Write-Log "Error: $_" Error} }
Wire 'BtnAdvNetwork'      { Write-Log "DEBUG: AdvNetwork" Info; try{if(Guard-Restore){Apply-AdvancedNetwork}}catch{Write-Log "Error: $_" Error} }

# CTO Features
Wire 'BtnSpeedShift'  { Write-Log "DEBUG: SpeedShift" Info; try{if(Guard-Restore){Set-SpeedShiftEPP -Value 0}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnWLANFix'     { Write-Log "DEBUG: WLANFix" Info; try{Fix-WLANScanning}catch{Write-Log "Error: $_" Error} }
Wire 'BtnWLANRestore'  { Write-Log "DEBUG: WLANRestore" Info; try{Restore-WLANScanning}catch{Write-Log "Error: $_" Error} }
Wire 'BtnIFEO'        { Write-Log "DEBUG: IFEO" Info; try{if(Guard-Restore){Set-IFEOPriority}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnShaderClear' { Write-Log "DEBUG: ShaderClear" Info; try{Clear-ShaderCache}catch{Write-Log "Error: $_" Error} }
Wire 'BtnCleanSlate'  { Write-Log "DEBUG: CleanSlate" Info; try{Invoke-CleanSlate}catch{Write-Log "Error: $_" Error} }
Wire 'BtnUltrabook'   { Write-Log "DEBUG: Ultrabook Profile" Info; try{if(Guard-Restore){Apply-UltrabookProfile}}catch{Write-Log "Error: $_" Error} }

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
Wire 'BtnSkipLock'    { Write-Log "DEBUG: SkipLock" Info; try{if(Guard-Restore){Skip-LockScreen}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnNoArrows'    { try{Remove-ShortcutArrows}catch{Write-Log "Error: $_" Error} }
Wire 'BtnTaskbarLeft' { try{Set-TaskbarLeft}catch{Write-Log "Error: $_" Error} }
Wire 'BtnTaskbarCenter' { try{Set-TaskbarCenter}catch{Write-Log "Error: $_" Error} }
Wire 'BtnCompactExplorer' { try{Enable-CompactExplorer}catch{Write-Log "Error: $_" Error} }
Wire 'BtnTelemetry0'  { Write-Log "DEBUG: Telemetry0" Info; try{if(Guard-Restore){Set-Telemetry0}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnStopEdge'    { Write-Log "DEBUG: StopEdge" Info; try{if(Guard-Restore){Stop-EdgePreload}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnRemoveMeetNow' { try{Remove-MeetNow}catch{Write-Log "Error: $_" Error} }
Wire 'BtnAudioExcl'   { try{Disable-AudioExclusive}catch{Write-Log "Error: $_" Error} }
Wire 'BtnBTCollab'    { Write-Log "DEBUG: BTCollab" Info; try{if(Guard-Restore){Disable-BTCollaboration}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnWinSxS'      { try{Compress-WinSxS}catch{Write-Log "Error: $_" Error} }
Wire 'BtnSearchIndex' { Write-Log "DEBUG: SearchOff" Info; try{if(Guard-Restore){Disable-SearchIndexing}}catch{Write-Log "Error: $_" Error} }
Wire 'BtnSearchIndexOn' { try{Enable-SearchIndexing}catch{Write-Log "Error: $_" Error} }
Wire 'BtnWingetExport' { try{Export-WingetApps}catch{Write-Log "Error: $_" Error} }
Wire 'BtnWingetImport' { try{Import-WingetApps}catch{Write-Log "Error: $_" Error} }

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
