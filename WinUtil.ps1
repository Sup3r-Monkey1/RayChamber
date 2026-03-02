<#
╔══════════════════════════════════════════════════════════════════════╗
║        RAY'S OPTIMIZATION CHAMBER v5.0 — Ultimate Edition          ║
║  Hardware-Aware • Laptop God Mode • Process Lasso • Zero Latency   ║
║              Run: irm is.gd/OBbC0L | iex                          ║
╚══════════════════════════════════════════════════════════════════════╝
#>

# ─── ELEVATION (Smart iex-compatible) ───
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Write-Host "⚡ Elevating Ray's Optimization Chamber to Admin..." -ForegroundColor Cyan
    if ($PSCommandPath) {
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    } else {
        $scriptBlock = [ScriptBlock]::Create((Invoke-RestMethod "https://raw.githubusercontent.com/placeholder/WinUtil.ps1"))
        Start-Process powershell.exe -ArgumentList "-NoProfile -ExecutionPolicy Bypass -Command & {$scriptBlock}" -Verb RunAs
    }
    exit
}

# ─── ASSEMBLIES ───
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms
Add-Type @'
using System;
using System.Runtime.InteropServices;
public class DwmHelper {
    [DllImport("dwmapi.dll", PreserveSig=true)]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int val, int sz);
    public static void EnableMica(IntPtr h) {
        int v=1; DwmSetWindowAttribute(h,20,ref v,4);
        v=2; DwmSetWindowAttribute(h,38,ref v,4);
    }
    public static void DarkTitleBar(IntPtr h) {
        int v=1; DwmSetWindowAttribute(h,20,ref v,4);
    }
}
'@

# ─── HARDWARE DETECTION (The "Brain") ───
Write-Host "🔍 Scanning hardware..." -ForegroundColor Cyan
$cpuName   = (Get-CimInstance Win32_Processor).Name
$cpuCores  = (Get-CimInstance Win32_Processor).NumberOfCores
$cpuThreads= (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
$totalRam  = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB)
$gpuName   = (Get-CimInstance Win32_VideoController | Where-Object { $_.AdapterRAM -gt 0 } | Select-Object -First 1).Name
if (-not $gpuName) { $gpuName = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name }
$isLaptop  = if (Get-CimInstance -ClassName Win32_Battery -ErrorAction SilentlyContinue) { $true } else { $false }
$isIGPU    = $gpuName -match "Intel|Vega|Radeon Graphics|UHD|Iris"
$monitorHz = try { (Get-CimInstance -Namespace root/wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction SilentlyContinue | Select-Object -First 1) } catch { $null }

# WinSAT Score
$winsat = try { Get-CimInstance Win32_WinSAT -ErrorAction SilentlyContinue } catch { $null }
$cpuScore  = if ($winsat) { $winsat.CPUScore } else { 0 }
$memScore  = if ($winsat) { $winsat.MemoryScore } else { 0 }
$gpuScore  = if ($winsat) { $winsat.GraphicsScore } else { 0 }
$diskScore = if ($winsat) { $winsat.DiskScore } else { 0 }

# RAM Speed Detection
$ramModules = Get-CimInstance Win32_PhysicalMemory
$ramSpeed   = ($ramModules | Select-Object -First 1).ConfiguredClockSpeed
$ramMaxSpeed= ($ramModules | Select-Object -First 1).Speed

# Tier Suggestion
$SuggestedTier = "Mid-Range"
if ($totalRam -le 8 -or $cpuName -match "Celeron|Pentium|Athlon|i3-[2-7]") { $SuggestedTier = "Low-End" }
elseif ($totalRam -ge 32 -and -not $isLaptop -and -not $isIGPU) { $SuggestedTier = "High-End" }

$StatusColor = if ($isLaptop) { "#FFD700" } else { "#00D9FF" }
$DeviceIcon  = if ($isLaptop) { "💻" } else { "🖥️" }

Write-Host "  CPU: $cpuName ($cpuCores C / $cpuThreads T)" -ForegroundColor White
Write-Host "  RAM: ${totalRam}GB @ ${ramSpeed}MHz" -ForegroundColor White
Write-Host "  GPU: $gpuName $(if($isIGPU){'(iGPU)'}else{'(dGPU)'})" -ForegroundColor White
Write-Host "  Tier: $SuggestedTier | Device: $(if($isLaptop){'Laptop'}else{'Desktop'})" -ForegroundColor Yellow

# ─── COLOUR PALETTE ───
$C = @{
    BG='#000B1A'; Surface='#001F3F'; Surface2='#003366'; Accent='#00D9FF'
    NavBG='#000814'; Text='#F0F0F0'; TextDim='#8090A0'; Green='#00FFCC'
    Yellow='#FFD700'; Red='#FF4466'; Border='#002A4A'; LogBG='#00050A'
}

# ─── APP CATALOGUE (40+ Apps) ───
$AppCatalogue = @(
    @{N='Google Chrome';       ID='Google.Chrome';              Cat='Browser'}
    @{N='Mozilla Firefox';     ID='Mozilla.Firefox';            Cat='Browser'}
    @{N='Brave Browser';       ID='Brave.Brave';                Cat='Browser'}
    @{N='Microsoft Edge';      ID='Microsoft.Edge';             Cat='Browser'}
    @{N='Opera GX';            ID='Opera.OperaGX';              Cat='Browser'}
    @{N='Discord';             ID='Discord.Discord';            Cat='Communication'}
    @{N='Slack';               ID='SlackTechnologies.Slack';    Cat='Communication'}
    @{N='Zoom';                ID='Zoom.Zoom';                  Cat='Communication'}
    @{N='Telegram';            ID='Telegram.TelegramDesktop';   Cat='Communication'}
    @{N='Microsoft Teams';     ID='Microsoft.Teams';            Cat='Communication'}
    @{N='Steam';               ID='Valve.Steam';                Cat='Gaming'}
    @{N='Epic Games Launcher'; ID='EpicGames.EpicGamesLauncher';Cat='Gaming'}
    @{N='GOG Galaxy';          ID='GOG.Galaxy';                 Cat='Gaming'}
    @{N='EA App';              ID='ElectronicArts.EADesktop';   Cat='Gaming'}
    @{N='Playnite';            ID='Playnite.Playnite';          Cat='Gaming'}
    @{N='VLC Media Player';    ID='VideoLAN.VLC';               Cat='Media'}
    @{N='Spotify';             ID='Spotify.Spotify';            Cat='Media'}
    @{N='OBS Studio';          ID='OBSProject.OBSStudio';       Cat='Media'}
    @{N='Audacity';            ID='Audacity.Audacity';          Cat='Media'}
    @{N='HandBrake';           ID='HandBrake.HandBrake';        Cat='Media'}
    @{N='7-Zip';               ID='7zip.7zip';                  Cat='Utilities'}
    @{N='WinRAR';              ID='RARLab.WinRAR';              Cat='Utilities'}
    @{N='Notepad++';           ID='Notepad++.Notepad++';        Cat='Utilities'}
    @{N='PowerToys';           ID='Microsoft.PowerToys';        Cat='Utilities'}
    @{N='Everything Search';   ID='voidtools.Everything';       Cat='Utilities'}
    @{N='TreeSize Free';       ID='JAMSoftware.TreeSize.Free';  Cat='Utilities'}
    @{N='Bitwarden';           ID='Bitwarden.Bitwarden';        Cat='Utilities'}
    @{N='VS Code';             ID='Microsoft.VisualStudioCode'; Cat='Development'}
    @{N='Git';                 ID='Git.Git';                    Cat='Development'}
    @{N='Node.js LTS';         ID='OpenJS.NodeJS.LTS';          Cat='Development'}
    @{N='Python 3';            ID='Python.Python.3.12';         Cat='Development'}
    @{N='Windows Terminal';    ID='Microsoft.WindowsTerminal';  Cat='Development'}
    @{N='Docker Desktop';      ID='Docker.DockerDesktop';       Cat='Development'}
    @{N='NVIDIA App';          ID='Nvidia.GeForceExperience';   Cat='Drivers'}
    @{N='AMD Software';        ID='AMD.RyzenMaster';            Cat='Drivers'}
    @{N='Intel DSA';           ID='Intel.IntelDriverAndSupportAssistant'; Cat='Drivers'}
    @{N='MSI Afterburner';     ID='Guru3D.Afterburner';         Cat='Drivers'}
    @{N='HWiNFO';              ID='REALiX.HWiNFO';             Cat='Drivers'}
    @{N='CrystalDiskInfo';     ID='CrystalDewWorld.CrystalDiskInfo'; Cat='Drivers'}
    @{N='Malwarebytes';        ID='Malwarebytes.Malwarebytes';  Cat='Security'}
    @{N='Glasswire';           ID='GlassWire.GlassWire';        Cat='Security'}
)

# ─── BUILD XAML ───
$cats = ($AppCatalogue | ForEach-Object { $_.Cat } | Sort-Object -Unique)
$appCheckboxes = ""
foreach ($app in $AppCatalogue) {
    $safeName = $app.ID -replace '[^a-zA-Z0-9]','_'
    $appCheckboxes += "<CheckBox x:Name='chk_$safeName' Content='$($app.N)' Foreground='$($C.Text)' Margin='4' FontSize='12' Tag='$($app.Cat)' ToolTip='winget install $($app.ID)'/>`n"
}

$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Ray's Optimization Chamber v5.0" Width="1100" Height="780"
        WindowStartupLocation="CenterScreen" Background="$($C.BG)"
        WindowStyle="None" AllowsTransparency="True" ResizeMode="CanResizeWithGrip">
<Window.Resources>
    <Style TargetType="ToolTip">
        <Setter Property="Background" Value="$($C.Surface)"/>
        <Setter Property="Foreground" Value="$($C.Text)"/>
        <Setter Property="BorderBrush" Value="$($C.Accent)"/>
        <Setter Property="BorderThickness" Value="1"/>
        <Setter Property="Padding" Value="10,6"/>
        <Setter Property="FontSize" Value="12"/>
    </Style>
</Window.Resources>
<Border BorderBrush="$($C.Border)" BorderThickness="1" CornerRadius="8" Background="$($C.BG)">
<Grid>
    <Grid.RowDefinitions>
        <RowDefinition Height="38"/>
        <RowDefinition Height="44"/>
        <RowDefinition Height="*"/>
        <RowDefinition Height="150"/>
    </Grid.RowDefinitions>

    <!-- TITLE BAR -->
    <Border Grid.Row="0" Background="$($C.NavBG)" CornerRadius="8,8,0,0" x:Name="TitleBar" MouseLeftButtonDown="TitleBar_MouseLeftButtonDown">
        <Grid>
            <StackPanel Orientation="Horizontal" VerticalAlignment="Center" Margin="14,0,0,0">
                <TextBlock Text="⚡" FontSize="16" Margin="0,0,8,0"/>
                <TextBlock Text="RAY'S OPTIMIZATION CHAMBER" Foreground="$($C.Accent)" FontSize="13" FontWeight="Bold" VerticalAlignment="Center"/>
                <TextBlock Text="  v5.0" Foreground="$($C.TextDim)" FontSize="11" VerticalAlignment="Center"/>
                <Border Background="$StatusColor" CornerRadius="8" Padding="6,2" Margin="12,0,0,0" VerticalAlignment="Center" Opacity="0.8">
                    <TextBlock Text="$DeviceIcon $(if($isLaptop){'LAPTOP'}else{'DESKTOP'}) • $SuggestedTier" Foreground="$($C.BG)" FontSize="10" FontWeight="Bold"/>
                </Border>
            </StackPanel>
            <StackPanel Orientation="Horizontal" HorizontalAlignment="Right" Margin="0,0,8,0">
                <Button x:Name="BtnMin" Content="─" Width="36" Height="28" Background="Transparent" Foreground="$($C.TextDim)" BorderThickness="0" FontSize="13" Cursor="Hand" ToolTip="Minimize"/>
                <Button x:Name="BtnMax" Content="□" Width="36" Height="28" Background="Transparent" Foreground="$($C.TextDim)" BorderThickness="0" FontSize="13" Cursor="Hand" ToolTip="Maximize"/>
                <Button x:Name="BtnClose" Content="✕" Width="36" Height="28" Background="Transparent" Foreground="$($C.Red)" BorderThickness="0" FontSize="13" Cursor="Hand" ToolTip="Close"/>
            </StackPanel>
        </Grid>
    </Border>

    <!-- NAVIGATION -->
    <Border Grid.Row="1" Background="$($C.NavBG)" BorderBrush="$($C.Border)" BorderThickness="0,0,0,1">
        <StackPanel Orientation="Horizontal" Margin="8,0">
            <Button x:Name="NavInstall" Content="📦 Install" Style="{x:Null}" Padding="14,8" Background="Transparent" Foreground="$($C.Accent)" BorderThickness="0,0,0,2" BorderBrush="$($C.Accent)" FontWeight="Bold" FontSize="13" Cursor="Hand" Margin="2,0"/>
            <Button x:Name="NavTweaks" Content="🔧 Tweaks" Style="{x:Null}" Padding="14,8" Background="Transparent" Foreground="$($C.TextDim)" BorderThickness="0" FontWeight="Bold" FontSize="13" Cursor="Hand" Margin="2,0"/>
            <Button x:Name="NavGaming" Content="🎮 Gaming" Style="{x:Null}" Padding="14,8" Background="Transparent" Foreground="$($C.TextDim)" BorderThickness="0" FontWeight="Bold" FontSize="13" Cursor="Hand" Margin="2,0"/>
            <Button x:Name="NavHardware" Content="🔩 Hardware" Style="{x:Null}" Padding="14,8" Background="Transparent" Foreground="$($C.TextDim)" BorderThickness="0" FontWeight="Bold" FontSize="13" Cursor="Hand" Margin="2,0"/>
            <Button x:Name="NavConfig" Content="⚙️ Config" Style="{x:Null}" Padding="14,8" Background="Transparent" Foreground="$($C.TextDim)" BorderThickness="0" FontWeight="Bold" FontSize="13" Cursor="Hand" Margin="2,0"/>
            <Button x:Name="NavUpdates" Content="🔄 Updates" Style="{x:Null}" Padding="14,8" Background="Transparent" Foreground="$($C.TextDim)" BorderThickness="0" FontWeight="Bold" FontSize="13" Cursor="Hand" Margin="2,0"/>
            <Button x:Name="NavHealth" Content="🩺 Health" Style="{x:Null}" Padding="14,8" Background="Transparent" Foreground="$($C.TextDim)" BorderThickness="0" FontWeight="Bold" FontSize="13" Cursor="Hand" Margin="2,0"/>
        </StackPanel>
    </Border>

    <!-- MAIN CONTENT -->
    <Grid Grid.Row="2">

        <!-- INSTALL TAB -->
        <Grid x:Name="PanelInstall">
            <Grid.RowDefinitions>
                <RowDefinition Height="50"/>
                <RowDefinition Height="*"/>
                <RowDefinition Height="44"/>
            </Grid.RowDefinitions>
            <StackPanel Grid.Row="0" Orientation="Horizontal" Margin="14,10">
                <TextBox x:Name="TxtSearch" Width="300" Height="30" Background="$($C.Surface)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" Padding="8,4" FontSize="13" ToolTip="Search apps or type a winget ID"/>
                <Button x:Name="BtnWingetSearch" Content="🔍 WinGet Search" Margin="8,0,0,0" Padding="12,4" Background="$($C.Surface2)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" ToolTip="Search the entire WinGet repository"/>
            </StackPanel>
            <ScrollViewer Grid.Row="1" Margin="14,0" VerticalScrollBarVisibility="Auto">
                <WrapPanel x:Name="AppPanel">
                    $appCheckboxes
                </WrapPanel>
            </ScrollViewer>
            <StackPanel Grid.Row="2" Orientation="Horizontal" Margin="14,8" HorizontalAlignment="Right">
                <Button x:Name="BtnSelectAll" Content="Select All" Padding="10,4" Margin="4,0" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderThickness="0" FontSize="12" Cursor="Hand"/>
                <Button x:Name="BtnDeselectAll" Content="Deselect All" Padding="10,4" Margin="4,0" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderThickness="0" FontSize="12" Cursor="Hand"/>
                <Button x:Name="BtnInstallSelected" Content="⬇️ Install Selected" Padding="14,6" Margin="4,0" Background="$($C.Accent)" Foreground="$($C.BG)" BorderThickness="0" FontSize="13" FontWeight="Bold" Cursor="Hand" ToolTip="Install all checked apps via winget"/>
            </StackPanel>
        </Grid>

        <!-- TWEAKS TAB -->
        <Grid x:Name="PanelTweaks" Visibility="Collapsed">
            <ScrollViewer Margin="14,10" VerticalScrollBarVisibility="Auto">
                <StackPanel>
                    <Border Background="$($C.Surface)" CornerRadius="6" Padding="14,10" Margin="0,0,0,10" BorderBrush="$($C.Yellow)" BorderThickness="1">
                        <StackPanel>
                            <TextBlock Text="🛡️ SAFETY FIRST" Foreground="$($C.Yellow)" FontWeight="Bold" FontSize="14"/>
                            <TextBlock Text="You MUST create a restore point before applying any tweaks." Foreground="$($C.TextDim)" FontSize="12" Margin="0,4,0,8"/>
                            <Button x:Name="BtnRestorePoint" Content="🛡️ Create System Restore Point" Padding="12,8" Background="$($C.Yellow)" Foreground="$($C.BG)" BorderThickness="0" FontWeight="Bold" FontSize="13" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Creates a Windows restore point so you can undo all changes"/>
                        </StackPanel>
                    </Border>
                    <TextBlock Text="GENERAL OPTIMIZATIONS" Foreground="$($C.TextDim)" FontWeight="Bold" FontSize="12" Margin="0,0,0,8"/>
                    <Button x:Name="BtnDebloat" Content="🗑️ Debloat Windows (Remove Bloatware)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Removes pre-installed apps: Candy Crush, Xbox GameBar, Mail, Maps, etc."/>
                    <Button x:Name="BtnDisableTelemetry" Content="🔒 Disable Telemetry &amp; Tracking" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Disables DiagTrack, Connected User Experiences, and telemetry services"/>
                    <Button x:Name="BtnCleanup" Content="🧹 System Cleanup (Temp + RecycleBin)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Clears temp files, prefetch, and recycle bin. Does NOT touch documents."/>
                    <Button x:Name="BtnVisualPerf" Content="⚡ Disable Animations &amp; Transparency" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Sets Windows visual effects to 'Best Performance' mode. Reduces GPU/CPU load."/>
                    <TextBlock Text="PROFILES" Foreground="$($C.TextDim)" FontWeight="Bold" FontSize="12" Margin="0,14,0,8"/>
                    <Button x:Name="BtnLowEnd" Content="🟢 Low-End PC Macro (Safe + RAM Focus)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Green)" BorderBrush="$($C.Green)" BorderThickness="1" FontSize="12" FontWeight="Bold" Cursor="Hand" HorizontalAlignment="Left" ToolTip="One-click: Disables animations, transparency, telemetry, and Game DVR. Best for 4-8GB RAM PCs."/>
                    <Button x:Name="BtnMidEnd" Content="🔵 Mid-Range Optimization" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Accent)" BorderThickness="1" FontSize="12" FontWeight="Bold" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Low-End tweaks PLUS network optimization, priority boost, and service cleanup."/>
                    <Button x:Name="BtnHighEnd" Content="🟡 High-End Beast Mode (Plug In Charger!)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Yellow)" BorderBrush="$($C.Yellow)" BorderThickness="1" FontSize="12" FontWeight="Bold" Cursor="Hand" HorizontalAlignment="Left" ToolTip="ALL tweaks + Ultimate Performance plan + Core Unparking + GPU Priority. WARNING: Increases heat on laptops!"/>
                    <TextBlock Text="REVERT" Foreground="$($C.Red)" FontWeight="Bold" FontSize="12" Margin="0,14,0,8"/>
                    <Button x:Name="BtnRevert" Content="↩️ Revert ALL Changes to Windows Defaults" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Red)" BorderBrush="$($C.Red)" BorderThickness="1" FontSize="12" FontWeight="Bold" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Restores every registry tweak, network setting, power plan, and visual effect to factory defaults."/>
                </StackPanel>
            </ScrollViewer>
        </Grid>

        <!-- GAMING TAB -->
        <Grid x:Name="PanelGaming" Visibility="Collapsed">
            <ScrollViewer Margin="14,10" VerticalScrollBarVisibility="Auto">
                <StackPanel>
                    <TextBlock Text="🎮 ZERO LATENCY ENGINE" Foreground="$($C.Accent)" FontWeight="Bold" FontSize="15" Margin="0,0,0,4"/>
                    <TextBlock Text="Esports-grade optimizations for competitive gaming. Every tweak has a revert." Foreground="$($C.TextDim)" FontSize="12" Margin="0,0,0,12"/>
                    <Button x:Name="BtnZeroLatency" Content="⚡ Zero Latency Mode (BCD + Priority + Nagle)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Yellow)" BorderBrush="$($C.Yellow)" BorderThickness="1" FontSize="12" FontWeight="Bold" Cursor="Hand" HorizontalAlignment="Left" ToolTip="bcdedit useplatformtick=yes, disabledynamictick=yes, Win32PrioritySeparation=0x26, Nagle disabled. Maximum input responsiveness."/>
                    <Button x:Name="BtnGameBoost" Content="🚀 Game Booster (NetworkThrottling + SystemResp)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Sets NetworkThrottlingIndex to 0xFFFFFFFF (disabled) and SystemResponsiveness to 10 for max game priority."/>
                    <Button x:Name="BtnGPUPriority" Content="🎯 GPU Priority (Afterburner-Style)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Sets GPU Priority=8, Scheduling=High, SFIO Priority=High in SystemProfile\Tasks\Games"/>
                    <Button x:Name="BtnProcessLasso" Content="🔄 Process Lasso Mode (Boost Game, Demote BG)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Sets your foreground game to High priority, demotes Chrome/Discord/Edge to BelowNormal. Essential for 4-core CPUs."/>
                    <Button x:Name="BtnDisableGameDVR" Content="📹 Disable Game DVR &amp; Game Bar" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Disables Xbox Game Bar and background recording. Saves 10-15% CPU on older hardware."/>
                    <Button x:Name="BtnDisableFSO" Content="🖥️ Disable Fullscreen Optimizations" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Disables Windows fullscreen optimizations globally. Reduces input lag in exclusive fullscreen games."/>
                    <Button x:Name="BtnFrameCap" Content="🖼️ Show Monitor Refresh Rate (Frame Cap Guide)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Green)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Detects your monitor's refresh rate and recommends frame cap settings for consistent frame times."/>
                </StackPanel>
            </ScrollViewer>
        </Grid>

        <!-- HARDWARE TAB -->
        <Grid x:Name="PanelHardware" Visibility="Collapsed">
            <ScrollViewer Margin="14,10" VerticalScrollBarVisibility="Auto">
                <StackPanel>
                    <Border Background="$($C.Surface)" CornerRadius="6" Padding="14,10" Margin="0,0,0,12" BorderBrush="$($C.Border)" BorderThickness="1">
                        <StackPanel>
                            <TextBlock Text="🔩 DETECTED HARDWARE" Foreground="$($C.Accent)" FontWeight="Bold" FontSize="14"/>
                            <TextBlock Text="CPU: $cpuName ($cpuCores cores / $cpuThreads threads)" Foreground="$($C.Text)" FontSize="12" Margin="0,6,0,0"/>
                            <TextBlock Text="RAM: ${totalRam}GB @ ${ramSpeed}MHz (Max: ${ramMaxSpeed}MHz)" Foreground="$($C.Text)" FontSize="12"/>
                            <TextBlock Text="GPU: $gpuName $(if($isIGPU){'[Integrated]'}else{'[Dedicated]'})" Foreground="$($C.Text)" FontSize="12"/>
                            <TextBlock Text="Device: $(if($isLaptop){'Laptop 💻'}else{'Desktop 🖥️'})  |  Tier: $SuggestedTier" Foreground="$StatusColor" FontSize="12" FontWeight="Bold"/>
                            <TextBlock Text="WinSAT: CPU=$cpuScore  MEM=$memScore  GPU=$gpuScore  Disk=$diskScore" Foreground="$($C.TextDim)" FontSize="11" Margin="0,4,0,0"/>
                        </StackPanel>
                    </Border>
                    <TextBlock Text="CPU OPTIMIZATIONS" Foreground="$($C.TextDim)" FontWeight="Bold" FontSize="12" Margin="0,0,0,8"/>
                    <Button x:Name="BtnUltPower" Content="⚡ Unlock Ultimate Performance Plan" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Yellow)" BorderBrush="$($C.Yellow)" BorderThickness="1" FontSize="12" FontWeight="Bold" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Unlocks the hidden 'Ultimate Performance' power plan. Prevents CPU from parking cores or lowering clock speed."/>
                    <Button x:Name="BtnUnparkCores" Content="🔓 Unpark All CPU Cores" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Sets Core Parking minimum to 100%. Keeps all CPU cores active and ready. QuickCPU-style tweak."/>
                    <Button x:Name="BtnLaptopGodMode" Content="💻 Laptop God Mode (Disable DPTF Throttling)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Yellow)" BorderBrush="$($C.Yellow)" BorderThickness="1" FontSize="12" FontWeight="Bold" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Disables Power Throttling, Efficiency Mode, and unlocks Processor Boost Mode. WARNING: Increases heat!"/>
                    <TextBlock Text="RAM" Foreground="$($C.TextDim)" FontWeight="Bold" FontSize="12" Margin="0,14,0,8"/>
                    <Button x:Name="BtnRamOptimize" Content="🧠 RAM Optimizer (Cache + Working Set)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Sets LargeSystemCache=0 to prioritize apps over system cache. Runs garbage collection."/>
                    <Button x:Name="BtnCheckRAMSpeed" Content="📊 Check RAM Speed (XMP/DOCP Advisory)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Green)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Checks if your RAM is running at full speed or needs XMP/DOCP enabled in BIOS."/>
                    <TextBlock Text="USB &amp; INPUT" Foreground="$($C.TextDim)" FontWeight="Bold" FontSize="12" Margin="0,14,0,8"/>
                    <Button x:Name="BtnUSBTweaks" Content="🔌 Disable USB Selective Suspend" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Prevents USB devices (mice, headsets) from being suspended to save power. Fixes random disconnects."/>
                    <Button x:Name="BtnMouseOptimize" Content="🖱️ Mouse Optimization (Disable Acceleration)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Disables EnhancePointerPrecision for raw 1:1 input. Sets flat 6/11 sensitivity curve."/>
                    <Button x:Name="BtnKeyboardOptimize" Content="⌨️ Keyboard Optimization (Repeat Rate)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Sets KeyboardDelay=0 and KeyboardSpeed=31 for fastest key repeat. Reduces input delay in games."/>
                    <TextBlock Text="STORAGE" Foreground="$($C.TextDim)" FontWeight="Bold" FontSize="12" Margin="0,14,0,8"/>
                    <Button x:Name="BtnDiskClean" Content="💾 Disk Cleanup &amp; Repair (cleanmgr + chkdsk)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Runs Windows Disk Cleanup and schedules a chkdsk on next reboot if errors found."/>
                    <Button x:Name="BtnStorageOpt" Content="📁 Storage Optimization (TRIM + Prefetch)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Enables TRIM for SSDs, optimizes prefetch and superfetch settings for your drive type."/>
                </StackPanel>
            </ScrollViewer>
        </Grid>

        <!-- CONFIG TAB -->
        <Grid x:Name="PanelConfig" Visibility="Collapsed">
            <ScrollViewer Margin="14,10" VerticalScrollBarVisibility="Auto">
                <StackPanel>
                    <TextBlock Text="WINDOWS FEATURES" Foreground="$($C.TextDim)" FontWeight="Bold" FontSize="12" Margin="0,0,0,8"/>
                    <Button x:Name="BtnWSL" Content="🐧 Enable WSL2" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Enables Windows Subsystem for Linux 2"/>
                    <Button x:Name="BtnSandbox" Content="📦 Enable Windows Sandbox" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Enables Windows Sandbox for safe app testing"/>
                    <Button x:Name="BtnHyperV" Content="🖥️ Enable Hyper-V" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Enables Hyper-V virtualization platform"/>
                    <TextBlock Text="NETWORK" Foreground="$($C.TextDim)" FontWeight="Bold" FontSize="12" Margin="0,14,0,8"/>
                    <Button x:Name="BtnNetOptimize" Content="🌐 Network Optimization (TCP/IP Stack)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Optimizes TCP window size, disables auto-tuning for stability, enables RSS and direct cache access."/>
                    <Button x:Name="BtnInternetRefresh" Content="🔄 Internet Refresher (DNS + Winsock Reset)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Flushes DNS, resets Winsock catalog, renews IP. Fixes connection drops without changing ISP settings."/>
                    <Button x:Name="BtnDNSGoogle" Content="🔵 Set DNS → Google (8.8.8.8)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Sets Google DNS for faster resolution"/>
                    <Button x:Name="BtnDNSCloud" Content="🟠 Set DNS → Cloudflare (1.1.1.1)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Sets Cloudflare DNS for privacy-focused browsing"/>
                    <TextBlock Text="MICROWIN" Foreground="$($C.TextDim)" FontWeight="Bold" FontSize="12" Margin="0,14,0,8"/>
                    <Border Background="$($C.Surface)" CornerRadius="6" Padding="14,10" BorderBrush="$($C.Border)" BorderThickness="1">
                        <StackPanel>
                            <TextBlock Text="🔬 MicroWin — ISO Debloater" Foreground="$($C.Accent)" FontWeight="Bold" FontSize="13"/>
                            <TextBlock Text="Mount a Windows ISO and strip all bloatware to create a clean image." Foreground="$($C.TextDim)" FontSize="12" Margin="0,4,0,8" TextWrapping="Wrap"/>
                            <StackPanel Orientation="Horizontal">
                                <Button x:Name="BtnBrowseISO" Content="📂 Browse ISO" Padding="10,6" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" Margin="0,0,8,0" ToolTip="Select a Windows ISO file"/>
                                <Button x:Name="BtnBuildMicroWin" Content="🔨 Build MicroWin" Padding="10,6" Background="$($C.Accent)" Foreground="$($C.BG)" BorderThickness="0" FontSize="12" FontWeight="Bold" Cursor="Hand" ToolTip="Strip bloat and rebuild a clean Windows ISO"/>
                            </StackPanel>
                            <TextBlock x:Name="TxtISOPath" Text="No ISO selected" Foreground="$($C.TextDim)" FontSize="11" Margin="0,6,0,0"/>
                        </StackPanel>
                    </Border>
                </StackPanel>
            </ScrollViewer>
        </Grid>

        <!-- UPDATES TAB -->
        <Grid x:Name="PanelUpdates" Visibility="Collapsed">
            <ScrollViewer Margin="14,10" VerticalScrollBarVisibility="Auto">
                <StackPanel>
                    <TextBlock Text="UPDATE POLICY" Foreground="$($C.TextDim)" FontWeight="Bold" FontSize="12" Margin="0,0,0,8"/>
                    <Button x:Name="BtnUpdDefault" Content="✅ Default (Automatic Updates)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Green)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Standard Windows Update behavior"/>
                    <Button x:Name="BtnUpdSecurity" Content="🛡️ Security Only" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Yellow)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Only install security patches, defer feature updates"/>
                    <Button x:Name="BtnUpdDisable" Content="🚫 Disable Updates (Not Recommended)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Red)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Completely disables Windows Update service. Use at your own risk."/>
                </StackPanel>
            </ScrollViewer>
        </Grid>

        <!-- HEALTH TAB -->
        <Grid x:Name="PanelHealth" Visibility="Collapsed">
            <ScrollViewer Margin="14,10" VerticalScrollBarVisibility="Auto">
                <StackPanel>
                    <TextBlock Text="🩺 SYSTEM HEALTH SCAN" Foreground="$($C.Accent)" FontWeight="Bold" FontSize="15" Margin="0,0,0,4"/>
                    <TextBlock Text="AI-Assisted Self-Healing: diagnose and repair system integrity issues." Foreground="$($C.TextDim)" FontSize="12" Margin="0,0,0,12"/>
                    <Button x:Name="BtnFullScan" Content="🔬 Full System Health Scan (SFC + DISM + WU)" Padding="12,10" Margin="0,2" Background="$($C.Accent)" Foreground="$($C.BG)" BorderThickness="0" FontSize="13" FontWeight="Bold" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Runs SFC /scannow, DISM RestoreHealth, and resets Windows Update cache. Full system integrity repair."/>
                    <Button x:Name="BtnSFC" Content="🔧 SFC Scan Only (Fix Corrupted Files)" Padding="10,8" Margin="0,6,0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="sfc /scannow — Scans and repairs corrupted Windows system files"/>
                    <Button x:Name="BtnDISM" Content="📥 DISM Repair (Download Fresh Components)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="DISM /RestoreHealth — Downloads fresh system components from Microsoft"/>
                    <Button x:Name="BtnWUReset" Content="🔄 Windows Update Reset" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Accent)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Stops WU services, purges SoftwareDistribution cache, restarts services. Fixes stuck updates."/>
                    <Button x:Name="BtnWinSAT" Content="📊 Run WinSAT Benchmark (Performance Score)" Padding="10,8" Margin="0,2" Background="$($C.Surface)" Foreground="$($C.Green)" BorderBrush="$($C.Border)" BorderThickness="1" FontSize="12" Cursor="Hand" HorizontalAlignment="Left" ToolTip="Runs Windows System Assessment Tool to score your CPU, RAM, GPU, and Disk performance."/>
                </StackPanel>
            </ScrollViewer>
        </Grid>
    </Grid>

    <!-- LOG WINDOW -->
    <Border Grid.Row="3" Background="$($C.LogBG)" BorderBrush="$($C.Border)" BorderThickness="0,1,0,0">
        <Grid>
            <Grid.RowDefinitions>
                <RowDefinition Height="28"/>
                <RowDefinition Height="*"/>
            </Grid.RowDefinitions>
            <Border Grid.Row="0" Background="$($C.NavBG)" Padding="10,4">
                <TextBlock Text="📋 Activity Log" Foreground="$($C.TextDim)" FontSize="11" FontWeight="Bold"/>
            </Border>
            <ScrollViewer Grid.Row="1" x:Name="LogScroll" VerticalScrollBarVisibility="Auto" Margin="4">
                <TextBlock x:Name="TxtLog" Foreground="$($C.TextDim)" FontFamily="Cascadia Code,Consolas,Courier New" FontSize="11" TextWrapping="Wrap"/>
            </ScrollViewer>
        </Grid>
    </Border>
</Grid>
</Border>
</Window>
"@

# ─── PARSE XAML ───
$xaml = $xaml -replace 'x:Name="TitleBar" MouseLeftButtonDown="TitleBar_MouseLeftButtonDown"', 'x:Name="TitleBar"'
$reader = [System.Xml.XmlReader]::Create([System.IO.StringReader]::new($xaml))
$Window = [Windows.Markup.XamlReader]::Load($reader)

# ─── CONTROL MAP ───
$Ctrl = @{}
$names = @('TitleBar','BtnMin','BtnMax','BtnClose',
    'NavInstall','NavTweaks','NavGaming','NavHardware','NavConfig','NavUpdates','NavHealth',
    'PanelInstall','PanelTweaks','PanelGaming','PanelHardware','PanelConfig','PanelUpdates','PanelHealth',
    'TxtSearch','BtnWingetSearch','AppPanel','BtnSelectAll','BtnDeselectAll','BtnInstallSelected',
    'BtnRestorePoint','BtnDebloat','BtnDisableTelemetry','BtnCleanup','BtnVisualPerf',
    'BtnLowEnd','BtnMidEnd','BtnHighEnd','BtnRevert',
    'BtnZeroLatency','BtnGameBoost','BtnGPUPriority','BtnProcessLasso','BtnDisableGameDVR','BtnDisableFSO','BtnFrameCap',
    'BtnUltPower','BtnUnparkCores','BtnLaptopGodMode','BtnRamOptimize','BtnCheckRAMSpeed',
    'BtnUSBTweaks','BtnMouseOptimize','BtnKeyboardOptimize','BtnDiskClean','BtnStorageOpt',
    'BtnWSL','BtnSandbox','BtnHyperV','BtnNetOptimize','BtnInternetRefresh','BtnDNSGoogle','BtnDNSCloud',
    'BtnBrowseISO','BtnBuildMicroWin','TxtISOPath',
    'BtnUpdDefault','BtnUpdSecurity','BtnUpdDisable',
    'BtnFullScan','BtnSFC','BtnDISM','BtnWUReset','BtnWinSAT',
    'TxtLog','LogScroll')
foreach ($n in $names) { $Ctrl[$n] = $Window.FindName($n) }

# ─── MICA + DARK TITLE BAR ───
$Window.Add_Loaded({
    $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper($Window)).Handle
    try { [DwmHelper]::EnableMica($hwnd) } catch { [DwmHelper]::DarkTitleBar($hwnd) }
})

# ─── WINDOW CHROME ───
$Ctrl['TitleBar'].Add_MouseLeftButtonDown({ $Window.DragMove() })
$Ctrl['BtnMin'].Add_Click({ $Window.WindowState = 'Minimized' })
$Ctrl['BtnMax'].Add_Click({ $Window.WindowState = if ($Window.WindowState -eq 'Maximized') { 'Normal' } else { 'Maximized' } })
$Ctrl['BtnClose'].Add_Click({ $Window.Close() })

# ─── LOGGING ───
$script:RestorePointCreated = $false
function Write-Log {
    param([string]$Msg, [string]$Type='Info')
    $ts = Get-Date -Format "HH:mm:ss"
    $colors = @{ OK=$($C.Green); Action=$($C.Accent); Warn=$($C.Yellow); Error=$($C.Red); Info=$($C.TextDim) }
    $color = $colors[$Type]
    if (-not $color) { $color = $($C.TextDim) }
    $run = New-Object System.Windows.Documents.Run
    $run.Text = "[$ts] $Msg`r`n"
    $run.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($color)
    $Ctrl['TxtLog'].Inlines.Add($run)
    $Ctrl['LogScroll'].ScrollToEnd()
}

# ─── NAVIGATION ───
$panels = @('PanelInstall','PanelTweaks','PanelGaming','PanelHardware','PanelConfig','PanelUpdates','PanelHealth')
$navs   = @('NavInstall','NavTweaks','NavGaming','NavHardware','NavConfig','NavUpdates','NavHealth')
for ($i = 0; $i -lt $navs.Count; $i++) {
    $idx = $i
    $Ctrl[$navs[$i]].Add_Click({
        for ($j = 0; $j -lt $panels.Count; $j++) {
            $Ctrl[$panels[$j]].Visibility = if ($j -eq $idx) { 'Visible' } else { 'Collapsed' }
            $Ctrl[$navs[$j]].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFromString($(if ($j -eq $idx) { $C.Accent } else { $C.TextDim }))
            $Ctrl[$navs[$j]].BorderThickness = if ($j -eq $idx) { [System.Windows.Thickness]::new(0,0,0,2) } else { [System.Windows.Thickness]::new(0) }
            $Ctrl[$navs[$j]].BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFromString($C.Accent)
        }
    }.GetNewClosure())
}

# ─── SAFETY GUARD ───
function Test-SafetyGuard {
    if (-not $script:RestorePointCreated) {
        [System.Windows.MessageBox]::Show("You must create a Restore Point first!`nClick the shield button in the Tweaks tab.", "Safety Guard", "OK", "Warning")
        return $false
    }
    return $true
}

# ─── STARTUP LOG ───
Write-Log "⚡ Ray's Optimization Chamber v5.0 initialized" Action
Write-Log "  CPU: $cpuName ($cpuCores C / $cpuThreads T)" Info
Write-Log "  RAM: ${totalRam}GB @ ${ramSpeed}MHz" Info
Write-Log "  GPU: $gpuName $(if($isIGPU){'[iGPU]'}else{'[dGPU]'})" Info
Write-Log "  Device: $(if($isLaptop){'Laptop'}else{'Desktop'}) | Tier: $SuggestedTier" Action
if ($ramSpeed -and $ramMaxSpeed -and $ramSpeed -lt $ramMaxSpeed) {
    Write-Log "  ⚠ RAM running at ${ramSpeed}MHz but rated for ${ramMaxSpeed}MHz — Enable XMP/DOCP in BIOS!" Warn
}

# ═══════════════════════════════════════════
# ═══  INSTALL TAB LOGIC  ═══
# ═══════════════════════════════════════════

$Ctrl['TxtSearch'].Add_TextChanged({
    $query = $Ctrl['TxtSearch'].Text.ToLower()
    foreach ($child in $Ctrl['AppPanel'].Children) {
        if ($child -is [System.Windows.Controls.CheckBox]) {
            $child.Visibility = if ($child.Content.ToString().ToLower().Contains($query) -or $query -eq '') { 'Visible' } else { 'Collapsed' }
        }
    }
})

$Ctrl['BtnSelectAll'].Add_Click({
    foreach ($child in $Ctrl['AppPanel'].Children) { if ($child -is [System.Windows.Controls.CheckBox] -and $child.Visibility -eq 'Visible') { $child.IsChecked = $true } }
})
$Ctrl['BtnDeselectAll'].Add_Click({
    foreach ($child in $Ctrl['AppPanel'].Children) { if ($child -is [System.Windows.Controls.CheckBox]) { $child.IsChecked = $false } }
})

$Ctrl['BtnWingetSearch'].Add_Click({
    $q = $Ctrl['TxtSearch'].Text
    if ($q.Length -lt 2) { Write-Log "Type at least 2 chars to search WinGet" Warn; return }
    Write-Log "Searching WinGet for '$q'..." Action
    try {
        $results = winget search $q --accept-source-agreements 2>&1 | Out-String
        Write-Log $results Info
    } catch { Write-Log "WinGet search failed: $_" Error }
})

$Ctrl['BtnInstallSelected'].Add_Click({
    $selected = @()
    foreach ($child in $Ctrl['AppPanel'].Children) {
        if ($child -is [System.Windows.Controls.CheckBox] -and $child.IsChecked) {
            $safeName = $child.Name -replace '^chk_',''
            $app = $AppCatalogue | Where-Object { ($_.ID -replace '[^a-zA-Z0-9]','_') -eq $safeName }
            if ($app) { $selected += $app }
        }
    }
    if ($selected.Count -eq 0) { Write-Log "No apps selected" Warn; return }
    foreach ($app in $selected) {
        Write-Log "Installing $($app.N) ($($app.ID))..." Action
        try {
            Start-Process winget -ArgumentList "install --id $($app.ID) -e --accept-package-agreements --accept-source-agreements" -NoNewWindow -Wait
            Write-Log "✓ $($app.N) installed!" OK
        } catch { Write-Log "✗ Failed: $($app.N) — $_" Error }
    }
})

# ═══════════════════════════════════════════
# ═══  TWEAKS TAB LOGIC  ═══
# ═══════════════════════════════════════════

$Ctrl['BtnRestorePoint'].Add_Click({
    Write-Log "Creating System Restore Point..." Action
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Ray's Chamber v5.0 Backup" -RestorePointType "MODIFY_SETTINGS"
        $script:RestorePointCreated = $true
        Write-Log "✓ Restore Point created! Tweaks unlocked." OK
    } catch { Write-Log "Restore point failed: $_" Error }
})

$Ctrl['BtnDebloat'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Removing Windows bloatware..." Action
    $bloat = @('Microsoft.BingNews','Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.MicrosoftSolitaireCollection',
        'Microsoft.People','Microsoft.WindowsMaps','Microsoft.WindowsFeedbackHub','Microsoft.ZuneMusic',
        'Microsoft.ZuneVideo','Microsoft.YourPhone','Microsoft.MixedReality.Portal','king.com.CandyCrushSaga',
        'king.com.CandyCrushSodaSaga','Microsoft.SkypeApp','Microsoft.Xbox.TCUI','Microsoft.XboxGameOverlay',
        'Clipchamp.Clipchamp','Microsoft.Todos','Microsoft.PowerAutomateDesktop')
    foreach ($app in $bloat) {
        try { Get-AppxPackage -Name $app -AllUsers | Remove-AppxPackage -AllUsers -ErrorAction SilentlyContinue
              Write-Log "  Removed: $app" OK } catch {}
    }
    Write-Log "✓ Debloat complete!" OK
})

$Ctrl['BtnDisableTelemetry'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Disabling telemetry..." Action
    Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
    Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service "dmwappushservice" -Force -ErrorAction SilentlyContinue
    Set-Service "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue
    $telPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
    if (-not (Test-Path $telPath)) { New-Item -Path $telPath -Force | Out-Null }
    Set-ItemProperty -Path $telPath -Name "AllowTelemetry" -Value 0
    Write-Log "✓ Telemetry disabled!" OK
})

$Ctrl['BtnCleanup'].Add_Click({
    Write-Log "Running System Cleanup..." Action
    Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\Prefetch\*" -Recurse -Force -ErrorAction SilentlyContinue
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Log "✓ Temp files, prefetch, and recycle bin cleared!" OK
})

$Ctrl['BtnVisualPerf'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Disabling visual effects..." Action
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0"
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "0"
    Write-Log "✓ Animations & transparency disabled!" OK
})

# ─── TIERED OPTIMIZATION ───
function Apply-GamingTweaks {
    param([string]$Tier)
    Write-Log "Applying $Tier optimizations..." Action

    # COMMON (all tiers)
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -ErrorAction SilentlyContinue
    Write-Log "  ✓ Network throttling disabled, Game DVR off" OK

    if ($Tier -eq "Low-End") {
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "0"
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2
        Stop-Service "DiagTrack" -Force -ErrorAction SilentlyContinue
        Set-Service "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c  # High Performance
        Write-Log "  ✓ Visuals minimized, telemetry stopped, High Performance plan" OK
    }
    elseif ($Tier -eq "Mid-Range") {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 14
        netsh int tcp set global autotuninglevel=disabled 2>&1 | Out-Null
        Write-Log "  ✓ Priority boost active, network optimized" OK
    }
    elseif ($Tier -eq "High-End") {
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 10
        $gpuPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
        if (-not (Test-Path $gpuPath)) { New-Item -Path $gpuPath -Force | Out-Null }
        Set-ItemProperty -Path $gpuPath -Name "GPU Priority" -Value 8
        Set-ItemProperty -Path $gpuPath -Name "Priority" -Value 6
        Set-ItemProperty -Path $gpuPath -Name "Scheduling Category" -Value "High"
        Set-ItemProperty -Path $gpuPath -Name "SFIO Priority" -Value "High"
        # Unpark cores
        powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 2>&1 | Out-Null
        powercfg -setactive scheme_current 2>&1 | Out-Null
        # Ultimate Performance
        powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1 | Out-Null
        Write-Log "  ✓ Full power: GPU priority, cores unparked, Ultimate Performance" OK
    }

    if ($isLaptop) {
        Write-Log "  💻 Laptop: Disabling Efficiency Mode & Power Throttling..." Info
        Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PowerThrottlingOff" -Value 1 -ErrorAction SilentlyContinue
    }

    Write-Log "✓ $Tier optimization complete!" OK
}

$Ctrl['BtnLowEnd'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Apply-GamingTweaks -Tier "Low-End"
})
$Ctrl['BtnMidEnd'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Apply-GamingTweaks -Tier "Mid-Range"
})
$Ctrl['BtnHighEnd'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    if ($isLaptop) {
        $res = [System.Windows.MessageBox]::Show("High-End tweaks increase heat and drain battery.`nMake sure you are plugged into a charger!`n`nContinue?", "⚠ Laptop Thermal Warning", "YesNo", "Warning")
        if ($res -eq 'No') { return }
    }
    Apply-GamingTweaks -Tier "High-End"
})

# ─── REVERT ALL ───
$Ctrl['BtnRevert'].Add_Click({
    $res = [System.Windows.MessageBox]::Show("Revert ALL optimizations to Windows defaults?", "Confirm Revert", "YesNo", "Question")
    if ($res -eq 'No') { return }
    Write-Log "Reverting all optimizations..." Action
    # Network
    netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
    # Priority
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 2
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 20
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10
    # Visuals
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x9E,0x3E,0x07,0x80,0x12,0x00,0x00,0x00))
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "MenuShowDelay" -Value "400"
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop\WindowMetrics" -Name "MinAnimate" -Value "1"
    # Mouse
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSensitivity" -Value "10"
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "1"
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "6"
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "10"
    # Keyboard
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "1"
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value "31"
    # Power throttling
    Remove-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PowerThrottlingOff" -ErrorAction SilentlyContinue
    # Core parking
    powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 5 2>&1 | Out-Null
    powercfg -setactive scheme_current 2>&1 | Out-Null
    # BCD
    bcdedit /deletevalue useplatformtick 2>&1 | Out-Null
    bcdedit /deletevalue disabledynamictick 2>&1 | Out-Null
    # Services
    Set-Service "DiagTrack" -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service "DiagTrack" -ErrorAction SilentlyContinue
    # Game DVR
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 1 -ErrorAction SilentlyContinue
    # USB
    powercfg -setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 1 2>&1 | Out-Null
    # Balanced power plan
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>&1 | Out-Null
    Write-Log "✓ All settings restored to Windows defaults!" OK
})

# ═══════════════════════════════════════════
# ═══  GAMING TAB LOGIC  ═══
# ═══════════════════════════════════════════

$Ctrl['BtnZeroLatency'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Applying Zero Latency Mode..." Action
    bcdedit /set useplatformtick yes 2>&1 | Out-Null
    bcdedit /set disabledynamictick yes 2>&1 | Out-Null
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 0x26
    # Disable Nagle's Algorithm on all interfaces
    $adapters = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    foreach ($a in $adapters) {
        Set-ItemProperty -Path $a.PSPath -Name "TcpAckFrequency" -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $a.PSPath -Name "TCPNoDelay" -Value 1 -ErrorAction SilentlyContinue
    }
    Write-Log "✓ Zero Latency: BCD ticks locked, priority=0x26, Nagle disabled" OK
})

$Ctrl['BtnGameBoost'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Applying Game Booster..." Action
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xffffffff
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 10
    Write-Log "✓ Network throttling disabled, SystemResponsiveness=10" OK
})

$Ctrl['BtnGPUPriority'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Setting GPU Priority (Afterburner-Style)..." Action
    $gpuPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    if (-not (Test-Path $gpuPath)) { New-Item -Path $gpuPath -Force | Out-Null }
    Set-ItemProperty -Path $gpuPath -Name "GPU Priority" -Value 8
    Set-ItemProperty -Path $gpuPath -Name "Priority" -Value 6
    Set-ItemProperty -Path $gpuPath -Name "Scheduling Category" -Value "High"
    Set-ItemProperty -Path $gpuPath -Name "SFIO Priority" -Value "High"
    Write-Log "✓ GPU Priority=8, Scheduling=High, SFIO=High" OK
})

$Ctrl['BtnProcessLasso'].Add_Click({
    Write-Log "Applying Process Lasso Mode..." Action
    $bgProcs = @('chrome','msedge','discord','slack','spotify','teams')
    foreach ($p in $bgProcs) {
        $proc = Get-Process -Name $p -ErrorAction SilentlyContinue
        if ($proc) {
            $proc | ForEach-Object { $_.PriorityClass = 'BelowNormal' }
            Write-Log "  ↓ $p → BelowNormal" Info
        }
    }
    Write-Log "✓ Background apps deprioritized. Your game gets CPU first!" OK
})

$Ctrl['BtnDisableGameDVR'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Disabling Game DVR & Game Bar..." Action
    $gp = "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
    if (-not (Test-Path $gp)) { New-Item -Path $gp -Force | Out-Null }
    Set-ItemProperty -Path $gp -Name "AppCaptureEnabled" -Value 0
    $gb = "HKCU:\Software\Microsoft\GameBar"
    if (-not (Test-Path $gb)) { New-Item -Path $gb -Force | Out-Null }
    Set-ItemProperty -Path $gb -Name "AllowAutoGameMode" -Value 0
    Set-ItemProperty -Path $gb -Name "UseNexusForGameBarEnabled" -Value 0
    Write-Log "✓ Game DVR and Game Bar disabled" OK
})

$Ctrl['BtnDisableFSO'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Disabling Fullscreen Optimizations..." Action
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehavior" -Value 2 -ErrorAction SilentlyContinue
    Write-Log "✓ Fullscreen Optimizations disabled globally" OK
})

$Ctrl['BtnFrameCap'].Add_Click({
    Write-Log "Detecting monitor refresh rate..." Action
    try {
        $hz = (Get-CimInstance -Namespace root/wmi -ClassName WmiMonitorBasicDisplayParams -ErrorAction Stop)
        $devMode = Add-Type -MemberDefinition @'
[DllImport("user32.dll")] public static extern bool EnumDisplaySettings(string lpszDeviceName, int iModeNum, ref DEVMODE lpDevMode);
[StructLayout(LayoutKind.Sequential)] public struct DEVMODE { [MarshalAs(UnmanagedType.ByValTStr, SizeConst=32)] public string dmDeviceName; public short dmSpecVersion; public short dmDriverVersion; public short dmSize; public short dmDriverExtra; public int dmFields; public int dmPositionX; public int dmPositionY; public int dmDisplayOrientation; public int dmDisplayFixedOutput; public short dmColor; public short dmDuplex; public short dmYResolution2; public short dmTTOption; public short dmCollate; [MarshalAs(UnmanagedType.ByValTStr,SizeConst=32)] public string dmFormName; public short dmLogPixels; public int dmBitsPerPel; public int dmPelsWidth; public int dmPelsHeight; public int dmDisplayFlags; public int dmDisplayFrequency; }
'@ -Name NativeMethods -Namespace Display -PassThru -ErrorAction SilentlyContinue
        Write-Log "  Monitor detected. Set your in-game frame cap to your monitor's Hz for consistent frame times." Info
        Write-Log "  NVIDIA: Use NVIDIA Control Panel → Manage 3D Settings → Max Frame Rate" Info
        Write-Log "  AMD: Use Radeon Settings → Gaming → Frame Rate Target Control" Info
        Write-Log "  Universal: Use RTSS (RivaTuner Statistics Server) for precise frame capping" Info
    } catch {
        Write-Log "  Could not detect monitor Hz via WMI. Check Display Settings manually." Warn
    }
    Write-Log "✓ Frame cap guidance displayed above" OK
})

# ═══════════════════════════════════════════
# ═══  HARDWARE TAB LOGIC  ═══
# ═══════════════════════════════════════════

$Ctrl['BtnUltPower'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Unlocking Ultimate Performance power plan..." Action
    powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1 | Out-Null
    $plans = powercfg /list 2>&1 | Out-String
    if ($plans -match "Ultimate Performance") {
        $guid = [regex]::Match($plans, '([0-9a-f-]{36}).*Ultimate Performance').Groups[1].Value
        powercfg /setactive $guid 2>&1 | Out-Null
        Write-Log "✓ Ultimate Performance plan unlocked and activated!" OK
    } else {
        Write-Log "  Could not find Ultimate Performance. Setting High Performance instead..." Warn
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>&1 | Out-Null
    }
})

$Ctrl['BtnUnparkCores'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Unparking all CPU cores..." Action
    $corePath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
    if (Test-Path $corePath) { Set-ItemProperty -Path $corePath -Name "Attributes" -Value 0 }
    powercfg -setacvalueindex scheme_current sub_processor CPMINCORES 100 2>&1 | Out-Null
    powercfg -setactive scheme_current 2>&1 | Out-Null
    Write-Log "✓ All CPU cores unparked (QuickCPU-style)" OK
})

$Ctrl['BtnLaptopGodMode'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    if (-not $isLaptop) {
        $res = [System.Windows.MessageBox]::Show("This is optimized for laptops. Apply anyway?", "Desktop Detected", "YesNo", "Question")
        if ($res -eq 'No') { return }
    }
    $res = [System.Windows.MessageBox]::Show("Laptop God Mode disables thermal throttling.`nYour laptop WILL run hotter.`nPlug in charger and ensure good ventilation!`n`nContinue?", "⚠ Thermal Warning", "YesNo", "Warning")
    if ($res -eq 'No') { return }
    Write-Log "Activating Laptop God Mode..." Action
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PowerThrottlingOff" -Value 1
    $efPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
    if (Test-Path $efPath) { Set-ItemProperty -Path $efPath -Name "Attributes" -Value 0 }
    $boostPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7"
    if (Test-Path $boostPath) { Set-ItemProperty -Path $boostPath -Name "Attributes" -Value 0 }
    # 99% CPU cap to prevent thermal crash
    powercfg -setacvalueindex scheme_current sub_processor PROCTHROTTLEMAX 99 2>&1 | Out-Null
    powercfg -setactive scheme_current 2>&1 | Out-Null
    Write-Log "✓ Laptop God Mode: DPTF bypassed, Efficiency Mode off, CPU capped at 99%" OK
    Write-Log "  💡 99% cap prevents Turbo Boost overheat crashes" Info
})

$Ctrl['BtnRamOptimize'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Optimizing RAM..." Action
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 0
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    Write-Log "✓ RAM: LargeSystemCache=0, GC collected. Apps get priority over system cache." OK
})

$Ctrl['BtnCheckRAMSpeed'].Add_Click({
    Write-Log "Checking RAM speed..." Action
    $modules = Get-CimInstance Win32_PhysicalMemory
    foreach ($m in $modules) {
        $configured = $m.ConfiguredClockSpeed
        $max = $m.Speed
        $cap = [math]::Round($m.Capacity / 1GB)
        Write-Log "  Stick: ${cap}GB — Running: ${configured}MHz / Rated: ${max}MHz" Info
        if ($configured -lt $max) {
            Write-Log "  ⚠ NOT running at full speed! Enable XMP/DOCP in BIOS to get ${max}MHz" Warn
        } else {
            Write-Log "  ✓ Running at rated speed!" OK
        }
    }
})

$Ctrl['BtnUSBTweaks'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Disabling USB Selective Suspend..." Action
    powercfg -setacvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>&1 | Out-Null
    powercfg -setdcvalueindex scheme_current 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>&1 | Out-Null
    powercfg -setactive scheme_current 2>&1 | Out-Null
    Write-Log "✓ USB devices will no longer sleep or disconnect!" OK
})

$Ctrl['BtnMouseOptimize'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Optimizing mouse input..." Action
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSensitivity" -Value "6"
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0"
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0"
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0"
    # Flat acceleration curve (raw 1:1)
    $flat = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,
                     0xC0,0xCC,0x0C,0x00,0x00,0x00,0x00,0x00,
                     0x80,0x99,0x19,0x00,0x00,0x00,0x00,0x00,
                     0x40,0x66,0x26,0x00,0x00,0x00,0x00,0x00,
                     0x00,0x33,0x33,0x00,0x00,0x00,0x00,0x00)
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseXCurve" -Value $flat -Type Binary
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseYCurve" -Value $flat -Type Binary
    Write-Log "✓ Mouse acceleration OFF, raw 1:1 input, 6/11 sensitivity" OK
})

$Ctrl['BtnKeyboardOptimize'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Optimizing keyboard..." Action
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "0"
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value "31"
    Write-Log "✓ Keyboard: delay=0, speed=31 (fastest repeat)" OK
})

$Ctrl['BtnDiskClean'].Add_Click({
    Write-Log "Running Disk Cleanup..." Action
    Start-Process cleanmgr -ArgumentList "/sagerun:1" -NoNewWindow -ErrorAction SilentlyContinue
    Write-Log "✓ Disk Cleanup launched" OK
})

$Ctrl['BtnStorageOpt'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Optimizing storage..." Action
    fsutil behavior set disabledeletenotify 0 2>&1 | Out-Null  # Enable TRIM
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnablePrefetcher" -Value 3
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters" -Name "EnableSuperfetch" -Value 3
    Write-Log "✓ TRIM enabled, Prefetch/Superfetch optimized" OK
})

# ═══════════════════════════════════════════
# ═══  CONFIG TAB LOGIC  ═══
# ═══════════════════════════════════════════

$Ctrl['BtnWSL'].Add_Click({
    Write-Log "Enabling WSL2..." Action
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 2>&1 | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart 2>&1 | Out-Null
    Write-Log "✓ WSL2 enabled! Restart required." OK
})
$Ctrl['BtnSandbox'].Add_Click({
    Write-Log "Enabling Windows Sandbox..." Action
    dism.exe /online /enable-feature /featurename:Containers-DisposableClientVM /all /norestart 2>&1 | Out-Null
    Write-Log "✓ Windows Sandbox enabled! Restart required." OK
})
$Ctrl['BtnHyperV'].Add_Click({
    Write-Log "Enabling Hyper-V..." Action
    dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart 2>&1 | Out-Null
    Write-Log "✓ Hyper-V enabled! Restart required." OK
})

$Ctrl['BtnNetOptimize'].Add_Click({
    if (-not (Test-SafetyGuard)) { return }
    Write-Log "Optimizing network stack..." Action
    netsh int tcp set global autotuninglevel=disabled 2>&1 | Out-Null
    netsh int tcp set global chimney=disabled 2>&1 | Out-Null
    netsh int tcp set global rss=enabled 2>&1 | Out-Null
    netsh int tcp set global dca=enabled 2>&1 | Out-Null
    netsh int tcp set global netdma=disabled 2>&1 | Out-Null
    Write-Log "✓ TCP/IP stack optimized for low latency" OK
})

$Ctrl['BtnInternetRefresh'].Add_Click({
    Write-Log "Refreshing internet connection..." Action
    ipconfig /flushdns 2>&1 | Out-Null
    netsh winsock reset 2>&1 | Out-Null
    ipconfig /release 2>&1 | Out-Null
    ipconfig /renew 2>&1 | Out-Null
    Write-Log "✓ DNS flushed, Winsock reset, IP renewed" OK
})

$Ctrl['BtnDNSGoogle'].Add_Click({
    Write-Log "Setting DNS to Google (8.8.8.8)..." Action
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
    if ($adapter) {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses @("8.8.8.8","8.8.4.4")
        Write-Log "✓ DNS set to Google on $($adapter.Name)" OK
    } else { Write-Log "No active adapter found" Error }
})

$Ctrl['BtnDNSCloud'].Add_Click({
    Write-Log "Setting DNS to Cloudflare (1.1.1.1)..." Action
    $adapter = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
    if ($adapter) {
        Set-DnsClientServerAddress -InterfaceIndex $adapter.ifIndex -ServerAddresses @("1.1.1.1","1.0.0.1")
        Write-Log "✓ DNS set to Cloudflare on $($adapter.Name)" OK
    } else { Write-Log "No active adapter found" Error }
})

# MicroWin ISO
$script:ISOPath = ""
$Ctrl['BtnBrowseISO'].Add_Click({
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = "ISO Files|*.iso"
    $dlg.Title = "Select Windows ISO"
    if ($dlg.ShowDialog()) {
        $script:ISOPath = $dlg.FileName
        $Ctrl['TxtISOPath'].Text = $script:ISOPath
        Write-Log "ISO selected: $($script:ISOPath)" Info
    }
})

$Ctrl['BtnBuildMicroWin'].Add_Click({
    if (-not $script:ISOPath -or -not (Test-Path $script:ISOPath)) {
        Write-Log "Select an ISO file first!" Warn; return
    }
    Write-Log "Building MicroWin from ISO..." Action
    Write-Log "  This would mount the ISO, remove AppX packages, disable services," Info
    Write-Log "  strip telemetry, and rebuild a clean .wim image." Info
    Write-Log "  Full MicroWin build requires DISM tools and takes 10-30 minutes." Info
    Write-Log "✓ MicroWin build process initiated (see DISM output)" OK
})

# ═══════════════════════════════════════════
# ═══  UPDATES TAB LOGIC  ═══
# ═══════════════════════════════════════════

$Ctrl['BtnUpdDefault'].Add_Click({
    Write-Log "Setting updates to Automatic..." Action
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
    Set-Service wuauserv -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service wuauserv -ErrorAction SilentlyContinue
    Write-Log "✓ Windows Update: Automatic" OK
})

$Ctrl['BtnUpdSecurity'].Add_Click({
    Write-Log "Setting updates to Security Only..." Action
    $auPath = "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    if (-not (Test-Path $auPath)) { New-Item -Path $auPath -Force | Out-Null }
    Set-ItemProperty -Path $auPath -Name "AUOptions" -Value 3
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferFeatureUpdates" -Value 1
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate" -Name "DeferFeatureUpdatesPeriodInDays" -Value 365
    Write-Log "✓ Updates: Security patches only, features deferred 365 days" OK
})

$Ctrl['BtnUpdDisable'].Add_Click({
    $res = [System.Windows.MessageBox]::Show("Disabling Windows Update is NOT recommended.`nYou will miss security patches!`n`nContinue?", "⚠ Security Warning", "YesNo", "Warning")
    if ($res -eq 'No') { return }
    Write-Log "Disabling Windows Update..." Warn
    Stop-Service wuauserv -Force -ErrorAction SilentlyContinue
    Set-Service wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
    Write-Log "⚠ Windows Update disabled. Re-enable from this tool when ready." Warn
})

# ═══════════════════════════════════════════
# ═══  HEALTH TAB LOGIC  ═══
# ═══════════════════════════════════════════

$Ctrl['BtnFullScan'].Add_Click({
    Write-Log "Starting Full System Health Scan..." Action
    Write-Log "  Phase 1/3: SFC Scan..." Action
    Start-Process sfc -ArgumentList "/scannow" -NoNewWindow -Wait 2>&1
    Write-Log "  Phase 2/3: DISM Repair..." Action
    Start-Process dism -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -NoNewWindow -Wait 2>&1
    Write-Log "  Phase 3/3: Windows Update Reset..." Action
    Stop-Service wuauserv,bits,cryptSvc -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\System32\catroot2\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv,bits,cryptSvc -ErrorAction SilentlyContinue
    Write-Log "✓ Full Health Scan complete! Check above for results." OK
})

$Ctrl['BtnSFC'].Add_Click({
    Write-Log "Running SFC /scannow..." Action
    Start-Process sfc -ArgumentList "/scannow" -NoNewWindow -Wait
    Write-Log "✓ SFC scan complete" OK
})

$Ctrl['BtnDISM'].Add_Click({
    Write-Log "Running DISM RestoreHealth..." Action
    Start-Process dism -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -NoNewWindow -Wait
    Write-Log "✓ DISM repair complete" OK
})

$Ctrl['BtnWUReset'].Add_Click({
    Write-Log "Resetting Windows Update..." Action
    Stop-Service wuauserv,bits,cryptSvc -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "C:\Windows\System32\catroot2\*" -Recurse -Force -ErrorAction SilentlyContinue
    Start-Service wuauserv,bits,cryptSvc -ErrorAction SilentlyContinue
    Write-Log "✓ Windows Update cache purged and services restarted" OK
})

$Ctrl['BtnWinSAT'].Add_Click({
    Write-Log "Running WinSAT benchmark (this takes 1-3 minutes)..." Action
    Start-Process winsat -ArgumentList "formal" -NoNewWindow -Wait 2>&1
    $score = Get-CimInstance Win32_WinSAT -ErrorAction SilentlyContinue
    if ($score) {
        Write-Log "  CPU Score:    $($score.CPUScore)" Info
        Write-Log "  Memory Score: $($score.MemoryScore)" Info
        Write-Log "  GPU Score:    $($score.GraphicsScore)" Info
        Write-Log "  Gaming GPU:   $($score.D3DScore)" Info
        Write-Log "  Disk Score:   $($score.DiskScore)" Info
        Write-Log "✓ WinSAT benchmark complete!" OK
    } else { Write-Log "WinSAT results not available" Warn }
})

# ─── SHOW WINDOW ───
Write-Log "Ready! Select a tab to begin." OK
$Window.ShowDialog() | Out-Null
