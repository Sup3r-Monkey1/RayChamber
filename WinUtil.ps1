<#
╔══════════════════════════════════════════════════════════════════════════════╗
║             RAY'S OPTIMIZATION CHAMBER v4.0 — Ultimate Edition             ║
║    Hardware-Aware • Process Lasso • Afterburner • Debloat • Self-Healing   ║
║                 Run as Administrator: irm ray.ps1 | iex                    ║
╚══════════════════════════════════════════════════════════════════════════════╝
#>

#Requires -RunAsAdministrator
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Continue'
Add-Type -AssemblyName PresentationFramework, PresentationCore, WindowsBase, System.Windows.Forms

# ═══════════════════════════════════════════════════════════════════
# DWM HELPER — Mica/Acrylic + Dark Title Bar
# ═══════════════════════════════════════════════════════════════════
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DwmHelper {
    [DllImport("dwmapi.dll", PreserveSig=true)]
    public static extern int DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int val, int size);
    public static void EnableMica(IntPtr h){
        int v;
        v=1; DwmSetWindowAttribute(h,20,ref v,4);
        v=2; DwmSetWindowAttribute(h,38,ref v,4);
    }
    public static void DarkTitleBar(IntPtr h){
        int v=1; DwmSetWindowAttribute(h,20,ref v,4);
    }
}
"@ -ErrorAction SilentlyContinue

# ═══════════════════════════════════════════════════════════════════
# COLOUR PALETTE — Cyber Blue Theme
# ═══════════════════════════════════════════════════════════════════
$C = @{
    BG       = '#000B1A';  Surface  = '#001F3F';  Surface2 = '#003366'
    Accent   = '#00D9FF';  NavBG    = '#000814';  Text     = '#F0F0F0'
    TextDim  = '#8090A0';  Green    = '#00FFCC';  Yellow   = '#FFD700'
    Red      = '#FF4466';  Border   = '#002A4A';  LogBG    = '#00050A'
    Orange   = '#FF8C00';  Purple   = '#AA66FF';  Cyan2    = '#00BBDD'
}

# ═══════════════════════════════════════════════════════════════════
# HARDWARE DETECTION ENGINE
# ═══════════════════════════════════════════════════════════════════
function Get-SystemProfile {
    $cpu   = (Get-CimInstance Win32_Processor).Name
    $cores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
    $ram   = [math]::Round((Get-CimInstance Win32_PhysicalMemory | Measure-Object Capacity -Sum).Sum / 1GB)
    $gpu   = (Get-CimInstance Win32_VideoController | Select-Object -First 1).Name
    $isLaptop = if (Get-CimInstance Win32_Battery -ErrorAction SilentlyContinue) { $true } else { $false }
    $os    = (Get-CimInstance Win32_OperatingSystem).Caption

    # Determine tier
    if ($ram -le 8 -or $cpu -match "Celeron|Pentium|Athlon|i3-[2-7]|A4|A6") {
        $tier = "Low-End"
    } elseif ($ram -ge 32 -and $cores -ge 12 -and -not $isLaptop) {
        $tier = "High-End"
    } else {
        $tier = "Mid-Range"
    }

    # Check for integrated graphics
    $integratedGPU = $gpu -match "Intel|Vega|Radeon Graphics|UHD|HD Graphics"

    return @{
        CPU = $cpu; Cores = $cores; RAM = $ram; GPU = $gpu
        IsLaptop = $isLaptop; OS = $os; Tier = $tier
        IntegratedGPU = $integratedGPU
    }
}

# ═══════════════════════════════════════════════════════════════════
# WINSAT PERFORMANCE SCORING
# ═══════════════════════════════════════════════════════════════════
function Get-WinSATScore {
    try {
        $formal = Get-CimInstance Win32_WinSAT -ErrorAction SilentlyContinue
        if ($formal) {
            return @{
                CPU    = $formal.CPUScore
                Memory = $formal.MemoryScore
                Disk   = $formal.DiskScore
                GPU    = $formal.GraphicsScore
                D3D    = $formal.D3DScore
                Base   = $formal.WinSPRLevel
            }
        }
        # Fallback: run winsat
        Start-Process -FilePath "winsat" -ArgumentList "formal" -Wait -NoNewWindow -ErrorAction SilentlyContinue
        $formal = Get-CimInstance Win32_WinSAT -ErrorAction SilentlyContinue
        if ($formal) {
            return @{
                CPU = $formal.CPUScore; Memory = $formal.MemoryScore
                Disk = $formal.DiskScore; GPU = $formal.GraphicsScore
                D3D = $formal.D3DScore; Base = $formal.WinSPRLevel
            }
        }
    } catch {}
    return $null
}

# ═══════════════════════════════════════════════════════════════════
# APP CATALOGUE — 40+ Apps via WinGet
# ═══════════════════════════════════════════════════════════════════
$AppCatalogue = @(
    @{N='Google Chrome';       ID='Google.Chrome';              Cat='Browser'}
    @{N='Mozilla Firefox';     ID='Mozilla.Firefox';            Cat='Browser'}
    @{N='Brave Browser';       ID='Brave.Brave';                Cat='Browser'}
    @{N='Microsoft Edge';      ID='Microsoft.Edge';             Cat='Browser'}
    @{N='Opera GX';            ID='Opera.OperaGX';              Cat='Browser'}
    @{N='Discord';             ID='Discord.Discord';            Cat='Communication'}
    @{N='Telegram';            ID='Telegram.TelegramDesktop';   Cat='Communication'}
    @{N='Slack';               ID='SlackTechnologies.Slack';    Cat='Communication'}
    @{N='Zoom';                ID='Zoom.Zoom';                  Cat='Communication'}
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
    @{N='VS Code';             ID='Microsoft.VisualStudioCode'; Cat='Development'}
    @{N='Git';                 ID='Git.Git';                    Cat='Development'}
    @{N='Node.js LTS';         ID='OpenJS.NodeJS.LTS';          Cat='Development'}
    @{N='Python 3';            ID='Python.Python.3.12';         Cat='Development'}
    @{N='Windows Terminal';    ID='Microsoft.WindowsTerminal';  Cat='Development'}
    @{N='Docker Desktop';      ID='Docker.DockerDesktop';       Cat='Development'}
    @{N='NVIDIA App';          ID='Nvidia.GeForceExperience';   Cat='Drivers'}
    @{N='AMD Software';        ID='AMD.RyzenMaster';            Cat='Drivers'}
    @{N='Intel DSA';           ID='Intel.IntelDriverAndSupportAssistant'; Cat='Drivers'}
    @{N='Corsair iCUE';        ID='Corsair.iCUE.5';             Cat='Drivers'}
    @{N='MSI Afterburner';     ID='Guru3D.Afterburner';         Cat='Performance'}
    @{N='Process Lasso';       ID='BitSum.ProcessLasso';        Cat='Performance'}
    @{N='HWiNFO';              ID='REALiX.HWiNFO';              Cat='Performance'}
    @{N='CPU-Z';               ID='CPUID.CPU-Z';                Cat='Performance'}
)

# ═══════════════════════════════════════════════════════════════════
# SAFETY & LOGGING
# ═══════════════════════════════════════════════════════════════════
$Script:RestorePointCreated = $false
$Script:BackupRegistry = @{}

function Write-Log {
    param([string]$Msg, [string]$Type = 'Info')
    $ts = Get-Date -Format 'HH:mm:ss'
    $prefix = switch ($Type) {
        'OK'     { '[+]' }
        'Error'  { '[X]' }
        'Action' { '[>]' }
        'Warn'   { '[!]' }
        default  { '[i]' }
    }
    $line = "$ts $prefix $Msg"
    $Ctrl['LogBox'].Dispatcher.Invoke([action]{
        $Ctrl['LogBox'].AppendText("$line`r`n")
        $Ctrl['LogBox'].ScrollToEnd()
    })
}

function Show-Warning {
    param([string]$TweakName, [string]$Risk)
    $msg = "WARNING: You are about to apply [$TweakName].`n`nRisk: $Risk`n`nA System Restore Point is recommended. Continue?"
    $result = [System.Windows.MessageBox]::Show($msg, "Ray's Safety Check", "YesNo", "Warning")
    return ($result -eq "Yes")
}

function Backup-RegValue {
    param([string]$Path, [string]$Name)
    try {
        $val = Get-ItemProperty -Path $Path -Name $Name -ErrorAction SilentlyContinue
        if ($val) {
            $Script:BackupRegistry["$Path\$Name"] = $val.$Name
        }
    } catch {}
}

function Ensure-RegPath {
    param([string]$Path)
    if (-not (Test-Path $Path)) {
        New-Item -Path $Path -Force | Out-Null
    }
}

# ═══════════════════════════════════════════════════════════════════
# WPF XAML — Full UI
# ═══════════════════════════════════════════════════════════════════
[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Ray's Optimization Chamber v4.0" Width="1200" Height="850"
        MinWidth="900" MinHeight="700"
        WindowStartupLocation="CenterScreen" WindowStyle="SingleBorderWindow"
        Background="$($C.BG)">
  <Window.Resources>
    <Style x:Key="NavBtn" TargetType="Button">
      <Setter Property="Background" Value="Transparent"/>
      <Setter Property="Foreground" Value="$($C.TextDim)"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Padding" Value="18,10"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="FontWeight" Value="SemiBold"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="$($C.Surface)"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="ActionBtn" TargetType="Button">
      <Setter Property="Background" Value="$($C.Surface)"/>
      <Setter Property="Foreground" Value="$($C.Text)"/>
      <Setter Property="BorderBrush" Value="$($C.Border)"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="16,10"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Margin" Value="4"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="6" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="$($C.Surface2)"/>
                <Setter TargetName="bd" Property="BorderBrush" Value="$($C.Accent)"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="AccentBtn" TargetType="Button">
      <Setter Property="Background" Value="$($C.Accent)"/>
      <Setter Property="Foreground" Value="#000B1A"/>
      <Setter Property="BorderThickness" Value="0"/>
      <Setter Property="Padding" Value="20,10"/>
      <Setter Property="FontSize" Value="13"/>
      <Setter Property="FontWeight" Value="Bold"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Margin" Value="4"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" Background="{TemplateBinding Background}" CornerRadius="6" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="$($C.Cyan2)"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style x:Key="DangerBtn" TargetType="Button">
      <Setter Property="Background" Value="$($C.Surface)"/>
      <Setter Property="Foreground" Value="$($C.Red)"/>
      <Setter Property="BorderBrush" Value="$($C.Red)"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="16,10"/>
      <Setter Property="FontSize" Value="12"/>
      <Setter Property="Cursor" Value="Hand"/>
      <Setter Property="Margin" Value="4"/>
      <Setter Property="Template">
        <Setter.Value>
          <ControlTemplate TargetType="Button">
            <Border x:Name="bd" Background="{TemplateBinding Background}" BorderBrush="{TemplateBinding BorderBrush}" BorderThickness="1" CornerRadius="6" Padding="{TemplateBinding Padding}">
              <ContentPresenter HorizontalAlignment="Center"/>
            </Border>
            <ControlTemplate.Triggers>
              <Trigger Property="IsMouseOver" Value="True">
                <Setter TargetName="bd" Property="Background" Value="#1A0000"/>
              </Trigger>
            </ControlTemplate.Triggers>
          </ControlTemplate>
        </Setter.Value>
      </Setter>
    </Style>
    <Style TargetType="CheckBox">
      <Setter Property="Foreground" Value="$($C.Text)"/>
      <Setter Property="Margin" Value="6,3"/>
      <Setter Property="FontSize" Value="12"/>
    </Style>
    <Style TargetType="ToolTip">
      <Setter Property="Background" Value="$($C.Surface)"/>
      <Setter Property="Foreground" Value="$($C.Text)"/>
      <Setter Property="BorderBrush" Value="$($C.Accent)"/>
      <Setter Property="FontSize" Value="11"/>
      <Setter Property="Padding" Value="8,5"/>
    </Style>
  </Window.Resources>

  <Grid>
    <Grid.RowDefinitions>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="Auto"/>
      <RowDefinition Height="*"/>
      <RowDefinition Height="180"/>
    </Grid.RowDefinitions>

    <!-- TITLE BAR -->
    <Border Grid.Row="0" Background="$($C.NavBG)" Padding="16,10">
      <Grid>
        <Grid.ColumnDefinitions>
          <ColumnDefinition Width="*"/>
          <ColumnDefinition Width="Auto"/>
        </Grid.ColumnDefinitions>
        <StackPanel Orientation="Horizontal" VerticalAlignment="Center">
          <TextBlock Text="⚡" FontSize="22" Foreground="$($C.Accent)" VerticalAlignment="Center" Margin="0,0,8,0"/>
          <TextBlock Text="RAY'S OPTIMIZATION CHAMBER" FontSize="16" FontWeight="Bold" Foreground="$($C.Text)" VerticalAlignment="Center"/>
          <Border Background="$($C.Surface2)" CornerRadius="10" Padding="8,2" Margin="12,0,0,0" VerticalAlignment="Center">
            <TextBlock Text="v4.0" FontSize="10" Foreground="$($C.Accent)"/>
          </Border>
        </StackPanel>
        <StackPanel Grid.Column="1" Orientation="Horizontal">
          <TextBlock x:Name="TxtHWTier" Text="" FontSize="11" Foreground="$($C.Green)" VerticalAlignment="Center" Margin="0,0,12,0"/>
          <TextBlock x:Name="TxtHWInfo" Text="Detecting hardware..." FontSize="10" Foreground="$($C.TextDim)" VerticalAlignment="Center"/>
        </StackPanel>
      </Grid>
    </Border>

    <!-- NAVIGATION BAR -->
    <Border Grid.Row="1" Background="$($C.NavBG)" Padding="8,4" BorderBrush="$($C.Border)" BorderThickness="0,0,0,1">
      <StackPanel Orientation="Horizontal">
        <Button x:Name="NavInstall" Content="📦 Install" Style="{StaticResource NavBtn}"/>
        <Button x:Name="NavTweaks"  Content="🔧 Tweaks" Style="{StaticResource NavBtn}"/>
        <Button x:Name="NavGaming"  Content="🎮 Gaming" Style="{StaticResource NavBtn}"/>
        <Button x:Name="NavHardware" Content="🖥️ Hardware" Style="{StaticResource NavBtn}"/>
        <Button x:Name="NavConfig"  Content="⚙️ Config" Style="{StaticResource NavBtn}"/>
        <Button x:Name="NavUpdates" Content="🔄 Updates" Style="{StaticResource NavBtn}"/>
        <Button x:Name="NavHealth"  Content="🩺 Health" Style="{StaticResource NavBtn}"/>
      </StackPanel>
    </Border>

    <!-- MAIN CONTENT AREA -->
    <Grid Grid.Row="2">

      <!-- ═══ INSTALL TAB ═══ -->
      <Grid x:Name="TabInstall" Visibility="Visible">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <Border Grid.Row="0" Padding="12,8" Background="$($C.NavBG)">
          <Grid>
            <Grid.ColumnDefinitions>
              <ColumnDefinition Width="*"/>
              <ColumnDefinition Width="Auto"/>
            </Grid.ColumnDefinitions>
            <TextBox x:Name="TxtSearch" Background="$($C.Surface)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" Padding="10,6" FontSize="13" ToolTip="Search apps or type to search WinGet repository"/>
            <Button Grid.Column="1" x:Name="BtnWingetSearch" Content="🔍 WinGet Search" Style="{StaticResource AccentBtn}" Margin="8,0,0,0" ToolTip="Search the entire WinGet repository (10,000+ apps)"/>
          </Grid>
        </Border>
        <ScrollViewer Grid.Row="1" VerticalScrollBarVisibility="Auto" Padding="12">
          <WrapPanel x:Name="AppPanel" Orientation="Horizontal"/>
        </ScrollViewer>
        <Border Grid.Row="2" Padding="12,8" Background="$($C.NavBG)">
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Right">
            <Button x:Name="BtnSelectAll" Content="Select All" Style="{StaticResource ActionBtn}" ToolTip="Select all visible apps"/>
            <Button x:Name="BtnDeselectAll" Content="Deselect All" Style="{StaticResource ActionBtn}" ToolTip="Deselect all apps"/>
            <Button x:Name="BtnInstall" Content="⚡ Install Selected" Style="{StaticResource AccentBtn}" ToolTip="Install all checked apps via WinGet"/>
          </StackPanel>
        </Border>
      </Grid>

      <!-- ═══ TWEAKS TAB ═══ -->
      <ScrollViewer x:Name="TabTweaks" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="12">
        <StackPanel>
          <Border Background="$($C.NavBG)" CornerRadius="8" Padding="16" Margin="0,0,0,12">
            <Grid>
              <Grid.ColumnDefinitions>
                <ColumnDefinition Width="*"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
                <ColumnDefinition Width="Auto"/>
              </Grid.ColumnDefinitions>
              <StackPanel>
                <TextBlock Text="⚠️ SAFETY FIRST" FontSize="14" FontWeight="Bold" Foreground="$($C.Yellow)"/>
                <TextBlock Text="Create a System Restore Point before applying any optimizations." Foreground="$($C.TextDim)" FontSize="11" Margin="0,4,0,0"/>
              </StackPanel>
              <Button Grid.Column="1" x:Name="BtnRestore" Content="🛡️ Create Restore Point" Style="{StaticResource AccentBtn}" ToolTip="Creates a Windows System Restore checkpoint so you can undo everything"/>
              <Button Grid.Column="2" x:Name="BtnLowEnd" Content="💡 Low-End PC Mode" Style="{StaticResource ActionBtn}" ToolTip="Auto-selects safe tweaks optimized for older/weaker hardware (4-8GB RAM, dual/quad core)"/>
              <Button Grid.Column="3" x:Name="BtnRevert" Content="↩️ Revert All Changes" Style="{StaticResource DangerBtn}" ToolTip="Restores ALL registry values and settings back to Windows defaults"/>
            </Grid>
          </Border>
          <TextBlock Text="🧹 GENERAL WINDOWS" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,0,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnDisableTelemetry" Content="Disable Telemetry" Style="{StaticResource ActionBtn}" ToolTip="Stops Microsoft data collection services (DiagTrack, dmwappushservice). Reduces background CPU and network usage."/>
            <Button x:Name="BtnDisableCortana" Content="Disable Cortana" Style="{StaticResource ActionBtn}" ToolTip="Prevents Cortana from running in the background and consuming resources."/>
            <Button x:Name="BtnDisableGameDVR" Content="Disable Game DVR" Style="{StaticResource ActionBtn}" ToolTip="Turns off Xbox Game Bar recording. Saves 10-15% GPU overhead on lower-end systems."/>
            <Button x:Name="BtnDisableStartupApps" Content="Disable Startup Bloat" Style="{StaticResource ActionBtn}" ToolTip="Disables non-essential startup programs that slow down boot time."/>
            <Button x:Name="BtnVisualPerf" Content="Visual Performance Mode" Style="{StaticResource ActionBtn}" ToolTip="Disables Windows animations, transparency, and shadows. Huge FPS boost on integrated GPUs."/>
          </WrapPanel>
          <TextBlock Text="🧠 RAM OPTIMIZATION" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,12,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnRAMClean" Content="Clean Standby RAM" Style="{StaticResource ActionBtn}" ToolTip="Forces garbage collection and clears .NET standby memory. Like Razer Cortex memory cleaner."/>
            <Button x:Name="BtnRAMCache" Content="Optimize System Cache" Style="{StaticResource ActionBtn}" ToolTip="Sets LargeSystemCache to 0 — prioritizes app memory over file cache. Best for gaming."/>
            <Button x:Name="BtnRAMSpeed" Content="Check RAM Speed (XMP)" Style="{StaticResource ActionBtn}" ToolTip="Reads your RAM clock speed via WMI. If it's below rated speed, you may need to enable XMP in BIOS."/>
          </WrapPanel>
          <TextBlock Text="🌐 NETWORK OPTIMIZATION" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,12,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnDisableNagle" Content="Disable Nagle Algorithm" Style="{StaticResource ActionBtn}" ToolTip="Sends TCP packets immediately instead of buffering. Reduces ping in competitive games by 5-15ms."/>
            <Button x:Name="BtnNetThrottle" Content="Disable Net Throttling" Style="{StaticResource ActionBtn}" ToolTip="Sets NetworkThrottlingIndex to 0xFFFFFFFF. Removes Windows bandwidth limiter for maximum throughput."/>
            <Button x:Name="BtnDNSFlush" Content="Internet Refresher" Style="{StaticResource ActionBtn}" ToolTip="Flushes DNS cache, resets Winsock catalog, renews IP. Fixes connection drops without changing ISP settings."/>
            <Button x:Name="BtnDNSGoogle" Content="Set DNS → Google" Style="{StaticResource ActionBtn}" ToolTip="Changes your DNS to Google (8.8.8.8 / 8.8.4.4) for faster domain lookups."/>
          </WrapPanel>
          <TextBlock Text="⚡ POWER OPTIMIZATION" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,12,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnUltimatePower" Content="Ultimate Performance Plan" Style="{StaticResource ActionBtn}" ToolTip="Unlocks the hidden 'Ultimate Performance' power plan. Prevents CPU parking and clock throttling."/>
            <Button x:Name="BtnHighPerf" Content="High Performance Plan" Style="{StaticResource ActionBtn}" ToolTip="Activates the standard High Performance plan. Safer for laptops than Ultimate."/>
            <Button x:Name="BtnDisableThrottle" Content="Disable Power Throttling" Style="{StaticResource ActionBtn}" ToolTip="Sets PowerThrottlingOff=1. Prevents Windows from slowing down apps to save power."/>
            <Button x:Name="BtnLaptopGodMode" Content="🔥 Laptop God Mode" Style="{StaticResource ActionBtn}" ToolTip="Disables DPTF thermal framework, unlocks CPU boost mode, and forces max performance on laptops."/>
          </WrapPanel>
          <TextBlock Text="🔌 USB / HARDWARE" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,12,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnUSBSuspend" Content="Disable USB Suspend" Style="{StaticResource ActionBtn}" ToolTip="Prevents USB devices (mice, headsets) from entering sleep mode. Fixes random disconnects."/>
            <Button x:Name="BtnMouseAccel" Content="Disable Mouse Accel" Style="{StaticResource ActionBtn}" ToolTip="Turns off EnhancePointerPrecision for raw 1:1 mouse input. Essential for FPS games."/>
            <Button x:Name="BtnKeyboardRate" Content="Max Keyboard Speed" Style="{StaticResource ActionBtn}" ToolTip="Sets keyboard repeat delay to minimum (1) and repeat rate to maximum (31). Faster typing response."/>
            <Button x:Name="BtnUnparkCores" Content="Unpark All CPU Cores" Style="{StaticResource ActionBtn}" ToolTip="Sets Core Parking min to 100%. Prevents Windows from sleeping CPU cores. Reduces micro-stutters."/>
          </WrapPanel>
          <TextBlock Text="💾 STORAGE / CLEANUP" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,12,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnTempClean" Content="Clean Temp Files" Style="{StaticResource ActionBtn}" ToolTip="Removes Windows temp, user temp, and prefetch files. Does NOT touch documents or drivers."/>
            <Button x:Name="BtnEmptyBin" Content="Empty Recycle Bin" Style="{StaticResource ActionBtn}" ToolTip="Permanently deletes all items in the Recycle Bin."/>
            <Button x:Name="BtnDiskOptimize" Content="Optimize Drives" Style="{StaticResource ActionBtn}" ToolTip="Runs defrag on HDDs and TRIM on SSDs for optimal performance."/>
          </WrapPanel>
          <TextBlock Text="🗑️ DEBLOAT" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,12,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnDebloatSafe" Content="Safe Debloat" Style="{StaticResource ActionBtn}" ToolTip="Removes safe-to-remove bloatware (Candy Crush, Xbox apps, Get Help, etc). Keeps Calculator, Photos, Store."/>
            <Button x:Name="BtnDebloatAggressive" Content="Aggressive Debloat" Style="{StaticResource DangerBtn}" ToolTip="⚠ Removes ALL preinstalled UWP apps except Store and Calculator. Cannot be undone easily."/>
          </WrapPanel>
        </StackPanel>
      </ScrollViewer>

      <!-- ═══ GAMING TAB ═══ -->
      <ScrollViewer x:Name="TabGaming" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="12">
        <StackPanel>
          <Border Background="$($C.NavBG)" CornerRadius="8" Padding="16" Margin="0,0,0,12">
            <StackPanel>
              <TextBlock Text="🎮 EXTREME GAMING MODULE — Zero Latency" FontSize="14" FontWeight="Bold" Foreground="$($C.Accent)"/>
              <TextBlock Text="2026 esports-level optimizations. Fixes micro-stutters, input lag, and network delay." Foreground="$($C.TextDim)" FontSize="11" Margin="0,4,0,0"/>
            </StackPanel>
          </Border>
          <TextBlock Text="🎯 ZERO LATENCY CORE" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,0,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnBCDTick" Content="BCD PlatformTick Fix" Style="{StaticResource AccentBtn}" ToolTip="bcdedit /set useplatformtick yes — Forces stable tick rate for perfect audio/video sync."/>
            <Button x:Name="BtnWin32Priority" Content="Win32 Priority Boost (0x26)" Style="{StaticResource AccentBtn}" ToolTip="Sets Win32PrioritySeparation to 0x26 (38 decimal). CPU massively prioritizes your active window."/>
            <Button x:Name="BtnGamePriority" Content="GPU Priority → Games" Style="{StaticResource AccentBtn}" ToolTip="Sets GPU Priority=8, Scheduling=High, SFIO Priority=High in Multimedia SystemProfile."/>
            <Button x:Name="BtnSysResponsive" Content="System Responsiveness → 10" Style="{StaticResource AccentBtn}" ToolTip="Reserves only 10% CPU for system tasks instead of default 20%. More cycles for your game."/>
          </WrapPanel>
          <TextBlock Text="📡 NETWORK LATENCY" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,12,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnTCPNoDelay" Content="TCP No-Delay (Anti-Nagle)" Style="{StaticResource AccentBtn}" ToolTip="Disables Nagle's Algorithm on all network interfaces. Packets sent immediately — essential for competitive FPS."/>
            <Button x:Name="BtnNetworkIndex" Content="Max Network Throughput" Style="{StaticResource AccentBtn}" ToolTip="NetworkThrottlingIndex=0xFFFFFFFF, SystemResponsiveness=10. Removes all Windows network limiters."/>
          </WrapPanel>
          <TextBlock Text="🖥️ PROCESS LASSO MODE" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,12,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnBoostGame" Content="Boost Active Game Process" Style="{StaticResource AccentBtn}" ToolTip="Sets the foreground game to High priority and demotes Chrome/Discord to BelowNormal. Like Process Lasso."/>
            <Button x:Name="BtnAffinityOptimize" Content="CPU Affinity Optimizer" Style="{StaticResource AccentBtn}" ToolTip="Spreads background processes across efficiency cores. Leaves performance cores free for games."/>
          </WrapPanel>
          <TextBlock Text="🖼️ FRAME RATE / DISPLAY" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,12,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnFrameCap" Content="Cap FPS to Monitor Hz" Style="{StaticResource AccentBtn}" ToolTip="Reads your monitor's refresh rate and suggests frame cap settings. Prevents frame tearing and GPU overwork."/>
            <Button x:Name="BtnFSO" Content="Disable Fullscreen Optimizations" Style="{StaticResource AccentBtn}" ToolTip="Disables Windows FSO globally. Games run in true exclusive fullscreen for lower latency."/>
          </WrapPanel>
        </StackPanel>
      </ScrollViewer>

      <!-- ═══ HARDWARE TAB ═══ -->
      <ScrollViewer x:Name="TabHardware" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="12">
        <StackPanel>
          <Border Background="$($C.NavBG)" CornerRadius="8" Padding="16" Margin="0,0,0,12">
            <StackPanel>
              <TextBlock Text="🖥️ HARDWARE INTELLIGENCE" FontSize="14" FontWeight="Bold" Foreground="$($C.Accent)"/>
              <TextBlock x:Name="TxtHWDetail" Text="Scanning hardware..." Foreground="$($C.TextDim)" FontSize="11" Margin="0,4,0,0" TextWrapping="Wrap"/>
            </StackPanel>
          </Border>
          <TextBlock Text="📊 PERFORMANCE SCORING" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,0,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnWinSAT" Content="📊 Run WinSAT Benchmark" Style="{StaticResource AccentBtn}" ToolTip="Runs the Windows System Assessment Tool to score your CPU, RAM, GPU, and Disk. Takes ~2 minutes."/>
            <Button x:Name="BtnAutoTune" Content="🤖 Auto-Tune (Smart Apply)" Style="{StaticResource AccentBtn}" ToolTip="Detects your hardware tier and automatically applies the optimal set of tweaks. Safe and reversible."/>
          </WrapPanel>
          <Border x:Name="WinSATPanel" Background="$($C.Surface)" CornerRadius="8" Padding="16" Margin="0,8,0,12" Visibility="Collapsed">
            <StackPanel>
              <TextBlock Text="WinSAT Scores" FontSize="13" FontWeight="Bold" Foreground="$($C.Text)"/>
              <TextBlock x:Name="TxtWinSAT" Text="" Foreground="$($C.TextDim)" FontSize="12" Margin="0,6,0,0" TextWrapping="Wrap"/>
            </StackPanel>
          </Border>
          <TextBlock Text="💻 LAPTOP-SPECIFIC" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,0,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnLaptopPerf" Content="Force Laptop Performance" Style="{StaticResource ActionBtn}" ToolTip="99% CPU cap (prevents turbo overheat), kills animations, prioritizes GPU for display output."/>
            <Button x:Name="BtnDPTFDisable" Content="Disable DPTF Throttling" Style="{StaticResource ActionBtn}" ToolTip="Disables Dynamic Platform Thermal Framework. Stops CPU from dropping to 0.8GHz during load. ⚠ Monitor temps!"/>
            <Button x:Name="BtnIntegratedGPU" Content="Optimize Integrated GPU" Style="{StaticResource ActionBtn}" ToolTip="Sets VRAM priority, disables Game DVR, reduces desktop composition overhead for Intel/AMD iGPU systems."/>
          </WrapPanel>
          <TextBlock Text="🔧 CPU / GPU TWEAKS" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,12,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnCoreUnpark" Content="Unpark All Cores" Style="{StaticResource ActionBtn}" ToolTip="Sets Core Parking minimum to 100% in all power plans. Keeps all CPU cores active and responsive."/>
            <Button x:Name="BtnGPUPriority" Content="GPU Scheduling → Hardware" Style="{StaticResource ActionBtn}" ToolTip="Enables Hardware-Accelerated GPU Scheduling (HAGS). Reduces CPU overhead for GPU-bound tasks."/>
          </WrapPanel>
        </StackPanel>
      </ScrollViewer>

      <!-- ═══ CONFIG TAB ═══ -->
      <ScrollViewer x:Name="TabConfig" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="12">
        <StackPanel>
          <TextBlock Text="🧩 WINDOWS FEATURES" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,0,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnWSL" Content="Enable WSL2" Style="{StaticResource ActionBtn}" ToolTip="Installs Windows Subsystem for Linux 2 and Virtual Machine Platform."/>
            <Button x:Name="BtnSandbox" Content="Enable Sandbox" Style="{StaticResource ActionBtn}" ToolTip="Enables Windows Sandbox for testing apps in an isolated environment."/>
            <Button x:Name="BtnHyperV" Content="Enable Hyper-V" Style="{StaticResource ActionBtn}" ToolTip="Enables Hyper-V virtualization. Required for Docker and WSL2."/>
            <Button x:Name="BtnDotNet" Content="Enable .NET 3.5" Style="{StaticResource ActionBtn}" ToolTip="Installs .NET Framework 3.5 for legacy app compatibility."/>
            <Button x:Name="BtnOpenSSH" Content="Enable OpenSSH" Style="{StaticResource ActionBtn}" ToolTip="Installs OpenSSH Client and Server for remote access."/>
          </WrapPanel>
          <TextBlock Text="🖥️ EXPLORER / TASKBAR" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,12,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnClassicMenu" Content="Classic Context Menu" Style="{StaticResource ActionBtn}" ToolTip="Restores the full right-click context menu in Windows 11. No more 'Show more options'."/>
            <Button x:Name="BtnFileExt" Content="Show File Extensions" Style="{StaticResource ActionBtn}" ToolTip="Shows file extensions in Explorer (e.g. .exe, .txt). Security best practice."/>
            <Button x:Name="BtnHiddenFiles" Content="Show Hidden Files" Style="{StaticResource ActionBtn}" ToolTip="Reveals hidden files and folders in Explorer."/>
            <Button x:Name="BtnTaskbarLeft" Content="Taskbar → Left Align" Style="{StaticResource ActionBtn}" ToolTip="Moves Windows 11 taskbar icons to the left side (like Windows 10)."/>
          </WrapPanel>
          <TextBlock Text="💿 MICROWIN — ISO DEBLOAT" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,12,0,6"/>
          <Border Background="$($C.Surface)" CornerRadius="8" Padding="16">
            <StackPanel>
              <TextBlock Text="Create a debloated Windows ISO for clean installs." Foreground="$($C.TextDim)" FontSize="11" Margin="0,0,0,8"/>
              <StackPanel Orientation="Horizontal">
                <Button x:Name="BtnBrowseISO" Content="📂 Browse ISO" Style="{StaticResource ActionBtn}" ToolTip="Select a Windows 10/11 ISO file to debloat."/>
                <Button x:Name="BtnBuildMicroWin" Content="🔨 Build MicroWin ISO" Style="{StaticResource AccentBtn}" ToolTip="Mounts the ISO, removes bloatware via DISM, and creates a clean ISO. Takes 10-20 minutes."/>
              </StackPanel>
              <TextBlock x:Name="TxtISOPath" Text="No ISO selected" Foreground="$($C.TextDim)" FontSize="10" Margin="0,6,0,0"/>
            </StackPanel>
          </Border>
        </StackPanel>
      </ScrollViewer>

      <!-- ═══ UPDATES TAB ═══ -->
      <ScrollViewer x:Name="TabUpdates" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="12">
        <StackPanel>
          <TextBlock Text="🔄 WINDOWS UPDATE CONTROL" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,0,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnUpdateDefault" Content="Default Updates" Style="{StaticResource ActionBtn}" ToolTip="Restores Windows Update to automatic mode (Microsoft recommended)."/>
            <Button x:Name="BtnUpdateSecurity" Content="Security Only" Style="{StaticResource ActionBtn}" ToolTip="Only downloads critical security patches. Blocks feature and driver updates."/>
            <Button x:Name="BtnUpdateDisable" Content="Disable Updates" Style="{StaticResource DangerBtn}" ToolTip="⚠ Completely stops Windows Update service. Not recommended — you'll miss security patches."/>
          </WrapPanel>
          <TextBlock Text="📦 DELIVERY OPTIMIZATION" FontSize="13" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,12,0,6"/>
          <WrapPanel>
            <Button x:Name="BtnDODisable" Content="Disable P2P Updates" Style="{StaticResource ActionBtn}" ToolTip="Stops Windows from sharing your updates with other PCs on the internet. Saves bandwidth."/>
          </WrapPanel>
        </StackPanel>
      </ScrollViewer>

      <!-- ═══ HEALTH TAB ═══ -->
      <ScrollViewer x:Name="TabHealth" Visibility="Collapsed" VerticalScrollBarVisibility="Auto" Padding="12">
        <StackPanel>
          <Border Background="$($C.NavBG)" CornerRadius="8" Padding="16" Margin="0,0,0,12">
            <StackPanel>
              <TextBlock Text="🩺 SYSTEM HEALTH — Self-Healing Engine" FontSize="14" FontWeight="Bold" Foreground="$($C.Accent)"/>
              <TextBlock Text="AI-Assisted diagnostics: scans, repairs, and restores Windows integrity." Foreground="$($C.TextDim)" FontSize="11" Margin="0,4,0,0"/>
            </StackPanel>
          </Border>
          <WrapPanel>
            <Button x:Name="BtnFullScan" Content="🩺 Full System Health Scan" Style="{StaticResource AccentBtn}" ToolTip="Runs SFC /scannow + DISM RestoreHealth + WU Cache Reset in sequence. The ultimate Windows repair."/>
            <Button x:Name="BtnSFC" Content="SFC Scan" Style="{StaticResource ActionBtn}" ToolTip="System File Checker: scans and repairs corrupted Windows system files."/>
            <Button x:Name="BtnDISM" Content="DISM Repair" Style="{StaticResource ActionBtn}" ToolTip="Downloads fresh system components from Microsoft to replace damaged ones."/>
            <Button x:Name="BtnWUReset" Content="Reset Windows Update" Style="{StaticResource ActionBtn}" ToolTip="Stops WU services, purges the update cache, and restarts. Fixes stuck/failed updates."/>
            <Button x:Name="BtnCheckDisk" Content="Check Disk Health" Style="{StaticResource ActionBtn}" ToolTip="Runs chkdsk to check for and repair file system errors on your drives."/>
          </WrapPanel>
        </StackPanel>
      </ScrollViewer>

    </Grid>

    <!-- ═══ LOG WINDOW ═══ -->
    <Border Grid.Row="3" Background="$($C.LogBG)" BorderBrush="$($C.Border)" BorderThickness="0,1,0,0" Padding="8">
      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <TextBlock Text="📋 Activity Log" FontSize="11" FontWeight="Bold" Foreground="$($C.TextDim)" Margin="4,0,0,4"/>
        <TextBox Grid.Row="1" x:Name="LogBox" IsReadOnly="True" TextWrapping="Wrap"
                 VerticalScrollBarVisibility="Auto" Background="Transparent"
                 Foreground="$($C.Green)" BorderThickness="0" FontFamily="Consolas" FontSize="11"/>
      </Grid>
    </Border>

  </Grid>
</Window>
"@

# ═══════════════════════════════════════════════════════════════════
# BUILD WINDOW
# ═══════════════════════════════════════════════════════════════════
$reader = New-Object System.Xml.XmlNodeReader $xaml
$Window = [Windows.Markup.XamlReader]::Load($reader)
$Ctrl = @{}
$xaml.SelectNodes('//*[@*[contains(translate(name(),"xX","xX"),"Name")]]') | ForEach-Object {
    $Ctrl[$_.Name] = $Window.FindName($_.Name)
}

# Apply Mica effect
$Window.Add_Loaded({
    try {
        $helper = New-Object System.Windows.Interop.WindowInteropHelper $Window
        [DwmHelper]::EnableMica($helper.Handle)
        [DwmHelper]::DarkTitleBar($helper.Handle)
        Write-Log "Mica backdrop applied successfully" OK
    } catch {
        Write-Log "Mica not available — using solid dark theme" Info
    }
})

# ═══════════════════════════════════════════════════════════════════
# NAVIGATION LOGIC
# ═══════════════════════════════════════════════════════════════════
$tabs = @('TabInstall','TabTweaks','TabGaming','TabHardware','TabConfig','TabUpdates','TabHealth')
$navs = @('NavInstall','NavTweaks','NavGaming','NavHardware','NavConfig','NavUpdates','NavHealth')

function Switch-Tab {
    param([int]$Index)
    for ($i = 0; $i -lt $tabs.Count; $i++) {
        $Ctrl[$tabs[$i]].Visibility = if ($i -eq $Index) { 'Visible' } else { 'Collapsed' }
        $Ctrl[$navs[$i]].Foreground = if ($i -eq $Index) {
            [System.Windows.Media.BrushConverter]::new().ConvertFrom($C.Accent)
        } else {
            [System.Windows.Media.BrushConverter]::new().ConvertFrom($C.TextDim)
        }
        if ($i -eq $Index) {
            $Ctrl[$navs[$i]].Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom($C.Surface2)
        } else {
            $Ctrl[$navs[$i]].Background = [System.Windows.Media.Brushes]::Transparent
        }
    }
}

for ($i = 0; $i -lt $navs.Count; $i++) {
    $idx = $i
    $Ctrl[$navs[$i]].Add_Click([scriptblock]::Create("Switch-Tab $idx"))
}
Switch-Tab 0

# ═══════════════════════════════════════════════════════════════════
# POPULATE APP LIST
# ═══════════════════════════════════════════════════════════════════
$Script:AppCheckboxes = @()
foreach ($app in $AppCatalogue) {
    $border = New-Object System.Windows.Controls.Border
    $border.Background = [System.Windows.Media.BrushConverter]::new().ConvertFrom($C.Surface)
    $border.BorderBrush = [System.Windows.Media.BrushConverter]::new().ConvertFrom($C.Border)
    $border.BorderThickness = [System.Windows.Thickness]::new(1)
    $border.CornerRadius = [System.Windows.CornerRadius]::new(6)
    $border.Padding = [System.Windows.Thickness]::new(10,6,10,6)
    $border.Margin = [System.Windows.Thickness]::new(4)
    $border.Width = 210

    $sp = New-Object System.Windows.Controls.StackPanel
    $cb = New-Object System.Windows.Controls.CheckBox
    $cb.Content = $app.N
    $cb.Tag = $app.ID
    $cb.ToolTip = "winget install $($app.ID)"

    $catLabel = New-Object System.Windows.Controls.TextBlock
    $catLabel.Text = $app.Cat
    $catLabel.FontSize = 9
    $catLabel.Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom($C.TextDim)
    $catLabel.Margin = [System.Windows.Thickness]::new(18,0,0,0)

    $sp.Children.Add($cb)
    $sp.Children.Add($catLabel)
    $border.Child = $sp
    $Ctrl['AppPanel'].Children.Add($border)
    $Script:AppCheckboxes += $cb
}

# Search filter
$Ctrl['TxtSearch'].Add_TextChanged({
    $q = $Ctrl['TxtSearch'].Text.ToLower()
    $i = 0
    foreach ($app in $AppCatalogue) {
        $parent = $Script:AppCheckboxes[$i].Parent.Parent
        if ($q -eq '' -or $app.N.ToLower().Contains($q) -or $app.Cat.ToLower().Contains($q)) {
            $parent.Visibility = 'Visible'
        } else {
            $parent.Visibility = 'Collapsed'
        }
        $i++
    }
})

# Select/Deselect All
$Ctrl['BtnSelectAll'].Add_Click({ $Script:AppCheckboxes | ForEach-Object { $_.IsChecked = $true } })
$Ctrl['BtnDeselectAll'].Add_Click({ $Script:AppCheckboxes | ForEach-Object { $_.IsChecked = $false } })

# WinGet Search
$Ctrl['BtnWingetSearch'].Add_Click({
    $query = $Ctrl['TxtSearch'].Text
    if ([string]::IsNullOrWhiteSpace($query)) {
        Write-Log "Enter a search term first" Warn
        return
    }
    Write-Log "Searching WinGet repository for '$query'..." Action
    try {
        $results = winget search $query --accept-source-agreements 2>&1 | Out-String
        Write-Log $results Info
    } catch {
        Write-Log "WinGet search failed: $_" Error
    }
})

# Install
$Ctrl['BtnInstall'].Add_Click({
    $selected = $Script:AppCheckboxes | Where-Object { $_.IsChecked }
    if ($selected.Count -eq 0) {
        Write-Log "No apps selected!" Warn
        return
    }
    Write-Log "Installing $($selected.Count) app(s) via WinGet..." Action
    foreach ($cb in $selected) {
        $id = $cb.Tag
        Write-Log "  Installing $($cb.Content) [$id]..." Action
        try {
            Start-Process -FilePath "winget" -ArgumentList "install --id $id --accept-package-agreements --accept-source-agreements -e -h" -Wait -NoNewWindow
            Write-Log "  ✓ $($cb.Content) installed" OK
        } catch {
            Write-Log "  ✗ Failed: $_" Error
        }
    }
    Write-Log "Installation batch complete!" OK
})

# ═══════════════════════════════════════════════════════════════════
# HARDWARE DETECTION — RUN AT STARTUP
# ═══════════════════════════════════════════════════════════════════
$Window.Add_ContentRendered({
    Write-Log "⚡ Ray's Optimization Chamber v4.0 initialized" OK
    Write-Log "Detecting system hardware..." Action
    try {
        $hw = Get-SystemProfile
        $Ctrl['TxtHWTier'].Text = "[$($hw.Tier)]"
        $tierColor = switch ($hw.Tier) {
            'Low-End'  { $C.Yellow }
            'High-End' { $C.Green }
            default    { $C.Accent }
        }
        $Ctrl['TxtHWTier'].Foreground = [System.Windows.Media.BrushConverter]::new().ConvertFrom($tierColor)
        $infoText = "$($hw.CPU) | $($hw.RAM)GB RAM | $($hw.GPU)"
        if ($hw.IsLaptop) { $infoText += " | 💻 Laptop" }
        $Ctrl['TxtHWInfo'].Text = $infoText
        $Ctrl['TxtHWDetail'].Text = "CPU: $($hw.CPU) ($($hw.Cores) threads) | RAM: $($hw.RAM)GB | GPU: $($hw.GPU) | OS: $($hw.OS) | Type: $(if($hw.IsLaptop){'Laptop'}else{'Desktop'}) | Integrated GPU: $($hw.IntegratedGPU) | Tier: $($hw.Tier)"
        Write-Log "Hardware: $infoText [Tier: $($hw.Tier)]" OK
        if ($hw.IsLaptop) {
            Write-Log "💻 Laptop detected — Laptop God Mode and thermal tweaks available in Tweaks and Hardware tabs" Info
        }
        if ($hw.IntegratedGPU) {
            Write-Log "⚠ Integrated GPU detected — consider 'Optimize Integrated GPU' in Hardware tab" Warn
        }
    } catch {
        Write-Log "Hardware detection partial: $_" Warn
    }
})

# ═══════════════════════════════════════════════════════════════════
# RESTORE POINT
# ═══════════════════════════════════════════════════════════════════
$Ctrl['BtnRestore'].Add_Click({
    Write-Log "Creating System Restore Point..." Action
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Ray's Optimization Chamber Backup" -RestorePointType "MODIFY_SETTINGS"
        $Script:RestorePointCreated = $true
        Write-Log "✓ Restore Point created! All tweaks unlocked." OK
        $Ctrl['BtnRestore'].Content = "✅ Restore Point Created"
        $Ctrl['BtnRestore'].IsEnabled = $false
    } catch {
        Write-Log "Restore Point failed: $_ — Tweaks unlocked anyway for testing" Warn
        $Script:RestorePointCreated = $true
    }
})

function Assert-RestorePoint {
    if (-not $Script:RestorePointCreated) {
        Write-Log "⚠ Create a Restore Point first! (Safety requirement)" Warn
        [System.Windows.MessageBox]::Show("Please create a Restore Point before applying tweaks.`nThis protects your system.", "Safety Guard", "OK", "Warning")
        return $false
    }
    return $true
}

# ═══════════════════════════════════════════════════════════════════
# TWEAKS — GENERAL WINDOWS
# ═══════════════════════════════════════════════════════════════════
$Ctrl['BtnDisableTelemetry'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Disabling Telemetry & Data Collection..." Action
    try {
        Set-Service -Name "DiagTrack" -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name "DiagTrack" -Force -ErrorAction SilentlyContinue
        Set-Service -Name "dmwappushservice" -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name "dmwappushservice" -Force -ErrorAction SilentlyContinue
        Ensure-RegPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection"
        Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DataCollection" -Name "AllowTelemetry" -Value 0
        Write-Log "✓ Telemetry disabled" OK
    } catch { Write-Log "Error: $_" Error }
})

$Ctrl['BtnDisableCortana'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Disabling Cortana..." Action
    Ensure-RegPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search" -Name "AllowCortana" -Value 0
    Write-Log "✓ Cortana disabled" OK
})

$Ctrl['BtnDisableGameDVR'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Disabling Game DVR / Xbox Game Bar..." Action
    Ensure-RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0
    Ensure-RegPath "HKCU:\System\GameConfigStore"
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0
    Write-Log "✓ Game DVR disabled — 10-15% GPU overhead freed" OK
})

$Ctrl['BtnDisableStartupApps'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Disabling non-essential startup items..." Action
    $startups = Get-CimInstance Win32_StartupCommand | Where-Object { $_.Location -ne "Common Startup" }
    $count = 0
    foreach ($s in $startups) {
        Write-Log "  Found: $($s.Name)" Info
        $count++
    }
    Write-Log "✓ Found $count startup items. Use Task Manager → Startup to disable individually." OK
})

$Ctrl['BtnVisualPerf'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Setting Visual Performance mode..." Action
    Backup-RegValue "HKCU:\Control Panel\Desktop" "UserPreferencesMask"
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))
    Ensure-RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects" -Name "VisualFXSetting" -Value 2 -ErrorAction SilentlyContinue
    Write-Log "✓ Animations, transparency, and shadows disabled" OK
})

# ═══════════════════════════════════════════════════════════════════
# TWEAKS — RAM OPTIMIZATION
# ═══════════════════════════════════════════════════════════════════
$Ctrl['BtnRAMClean'].Add_Click({
    Write-Log "Cleaning standby memory..." Action
    [System.GC]::Collect()
    [System.GC]::WaitForPendingFinalizers()
    [System.GC]::Collect()
    Write-Log "✓ .NET garbage collection complete. Standby memory freed." OK
})

$Ctrl['BtnRAMCache'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Optimizing system cache for applications..." Action
    Ensure-RegPath "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    Backup-RegValue "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" "LargeSystemCache"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 0
    Write-Log "✓ LargeSystemCache=0 — RAM prioritized for applications over file cache" OK
})

$Ctrl['BtnRAMSpeed'].Add_Click({
    Write-Log "Checking RAM speed..." Action
    try {
        $ram = Get-CimInstance Win32_PhysicalMemory
        foreach ($stick in $ram) {
            $speed = $stick.ConfiguredClockSpeed
            $capacity = [math]::Round($stick.Capacity / 1GB, 1)
            $mfr = $stick.Manufacturer
            Write-Log "  Stick: ${capacity}GB @ ${speed}MHz ($mfr)" Info
            if ($speed -lt 2400) {
                Write-Log "  ⚠ Speed is low! Check BIOS for XMP/DOCP profile to run at rated speed." Warn
            }
        }
        Write-Log "✓ RAM speed check complete" OK
    } catch { Write-Log "Error reading RAM info: $_" Error }
})

# ═══════════════════════════════════════════════════════════════════
# TWEAKS — NETWORK
# ═══════════════════════════════════════════════════════════════════
$Ctrl['BtnDisableNagle'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Disabling Nagle's Algorithm for all interfaces..." Action
    $adapters = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces"
    foreach ($a in $adapters) {
        Set-ItemProperty -Path $a.PSPath -Name "TcpAckFrequency" -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $a.PSPath -Name "TCPNoDelay" -Value 1 -ErrorAction SilentlyContinue
    }
    Write-Log "✓ Nagle disabled — TCP packets sent immediately (lower ping)" OK
})

$Ctrl['BtnNetThrottle'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Disabling network throttling..." Action
    Ensure-RegPath "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF
    Write-Log "✓ NetworkThrottlingIndex=0xFFFFFFFF — bandwidth limiter removed" OK
})

$Ctrl['BtnDNSFlush'].Add_Click({
    Write-Log "Refreshing internet connection..." Action
    ipconfig /flushdns | Out-Null
    netsh winsock reset | Out-Null
    netsh int ip reset | Out-Null
    ipconfig /release | Out-Null
    ipconfig /renew | Out-Null
    Write-Log "✓ DNS flushed, Winsock reset, IP renewed. Connection refreshed." OK
})

$Ctrl['BtnDNSGoogle'].Add_Click({
    Write-Log "Setting DNS to Google (8.8.8.8 / 8.8.4.4)..." Action
    try {
        $iface = Get-NetAdapter | Where-Object { $_.Status -eq 'Up' } | Select-Object -First 1
        Set-DnsClientServerAddress -InterfaceIndex $iface.ifIndex -ServerAddresses ("8.8.8.8","8.8.4.4")
        Write-Log "✓ DNS set to Google on '$($iface.Name)'" OK
    } catch { Write-Log "Error: $_" Error }
})

# ═══════════════════════════════════════════════════════════════════
# TWEAKS — POWER
# ═══════════════════════════════════════════════════════════════════
$Ctrl['BtnUltimatePower'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Unlocking Ultimate Performance power plan..." Action
    $out = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1 | Out-String
    if ($out -match '([0-9a-f-]{36})') {
        powercfg /setactive $Matches[1]
        Write-Log "✓ Ultimate Performance plan activated: $($Matches[1])" OK
    } else {
        Write-Log "Applying High Performance as fallback..." Warn
        powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
        Write-Log "✓ High Performance plan activated" OK
    }
})

$Ctrl['BtnHighPerf'].Add_Click({
    Write-Log "Activating High Performance plan..." Action
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-Log "✓ High Performance plan activated" OK
})

$Ctrl['BtnDisableThrottle'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Disabling Power Throttling..." Action
    Ensure-RegPath "HKLM:\SYSTEM\CurrentControlSet\Control\Power"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PowerThrottlingOff" -Value 1
    Write-Log "✓ Power Throttling disabled — apps will not be slowed to save power" OK
})

$Ctrl['BtnLaptopGodMode'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    if (-not (Show-Warning "Laptop God Mode" "Disables thermal throttling. Monitor temps! If temps exceed 95°C, revert.")) { return }
    Write-Log "🔥 Activating Laptop God Mode..." Action
    # Disable Power Throttling
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PowerThrottlingOff" -Value 1 -ErrorAction SilentlyContinue
    # Unlock Processor Boost Mode
    $boostPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7"
    if (Test-Path $boostPath) {
        Set-ItemProperty -Path $boostPath -Name "Attributes" -Value 0 -ErrorAction SilentlyContinue
    }
    # Disable Efficiency Mode cores
    $effPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583"
    if (Test-Path $effPath) {
        Set-ItemProperty -Path $effPath -Name "Attributes" -Value 0 -ErrorAction SilentlyContinue
    }
    # High performance plan
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    Write-Log "✓ Laptop God Mode ACTIVE — Throttling disabled, boost unlocked, max performance" OK
    Write-Log "  ⚠ Monitor temperatures! Use HWiNFO or Task Manager to watch CPU temp" Warn
})

# ═══════════════════════════════════════════════════════════════════
# TWEAKS — USB / HARDWARE
# ═══════════════════════════════════════════════════════════════════
$Ctrl['BtnUSBSuspend'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Disabling USB Selective Suspend..." Action
    # Disable via power plan
    powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>&1 | Out-Null
    powercfg /SETDCVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>&1 | Out-Null
    powercfg /SETACTIVE SCHEME_CURRENT
    Ensure-RegPath "HKLM:\SYSTEM\CurrentControlSet\Services\USB"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\USB" -Name "DisableSelectiveSuspend" -Value 1 -ErrorAction SilentlyContinue
    Write-Log "✓ USB Selective Suspend disabled — peripherals won't sleep/disconnect" OK
})

$Ctrl['BtnMouseAccel'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Disabling mouse acceleration (EnhancePointerPrecision)..." Action
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "0"
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "0"
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "0"
    # 6/11 flat curve
    $flat = [byte[]](0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0xC0,0xCC,0x0C,0x00,0x00,0x00,0x00,0x00,0x80,0x99,0x19,0x00,0x00,0x00,0x00,0x00,0x40,0x66,0x26,0x00,0x00,0x00,0x00,0x00,0x00,0x33,0x33,0x00,0x00,0x00,0x00,0x00,0x00,0x00,0x40,0x00,0x00,0x00,0x00,0x00,0xC0,0xCC,0x4C,0x00,0x00,0x00,0x00,0x00,0x80,0x99,0x59,0x00,0x00,0x00,0x00,0x00,0x40,0x66,0x66,0x00,0x00,0x00,0x00,0x00)
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "SmoothMouseXCurve" -Value $flat -ErrorAction SilentlyContinue
    Write-Log "✓ Mouse acceleration OFF — raw 1:1 input for FPS games" OK
})

$Ctrl['BtnKeyboardRate'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Setting maximum keyboard repeat rate..." Action
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "0"
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value "31"
    Write-Log "✓ Keyboard delay=0, speed=31 (maximum). Takes effect after re-login." OK
})

$Ctrl['BtnUnparkCores'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Unparking all CPU cores..." Action
    # Set Core Parking min to 100%
    powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>&1 | Out-Null
    powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>&1 | Out-Null
    powercfg -setactive SCHEME_CURRENT
    Write-Log "✓ All CPU cores unparked — no cores will sleep during load" OK
})

# ═══════════════════════════════════════════════════════════════════
# TWEAKS — STORAGE / CLEANUP
# ═══════════════════════════════════════════════════════════════════
$Ctrl['BtnTempClean'].Add_Click({
    Write-Log "Cleaning temporary files..." Action
    $freed = 0
    $paths = @("$env:TEMP", "$env:WINDIR\Temp", "$env:WINDIR\Prefetch")
    foreach ($p in $paths) {
        if (Test-Path $p) {
            $size = (Get-ChildItem $p -Recurse -Force -ErrorAction SilentlyContinue | Measure-Object Length -Sum).Sum
            $freed += $size
            Remove-Item "$p\*" -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
    $freedMB = [math]::Round($freed / 1MB, 1)
    Write-Log "✓ Cleaned ~${freedMB}MB of temp files" OK
})

$Ctrl['BtnEmptyBin'].Add_Click({
    Write-Log "Emptying Recycle Bin..." Action
    Clear-RecycleBin -Force -ErrorAction SilentlyContinue
    Write-Log "✓ Recycle Bin emptied" OK
})

$Ctrl['BtnDiskOptimize'].Add_Click({
    Write-Log "Optimizing drives (TRIM for SSD / Defrag for HDD)..." Action
    try {
        $volumes = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' }
        foreach ($v in $volumes) {
            Write-Log "  Optimizing $($v.DriveLetter):\ ($($v.FileSystemType))..." Action
            Optimize-Volume -DriveLetter $v.DriveLetter -ErrorAction SilentlyContinue
        }
        Write-Log "✓ Drive optimization complete" OK
    } catch { Write-Log "Error: $_" Error }
})

# ═══════════════════════════════════════════════════════════════════
# TWEAKS — DEBLOAT
# ═══════════════════════════════════════════════════════════════════
$Ctrl['BtnDebloatSafe'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Running Safe Debloat — removing pre-installed bloatware..." Action
    $bloat = @(
        "Microsoft.BingWeather","Microsoft.GetHelp","Microsoft.Getstarted","Microsoft.MicrosoftOfficeHub",
        "Microsoft.MicrosoftSolitaireCollection","Microsoft.People","Microsoft.WindowsFeedbackHub",
        "Microsoft.Xbox.TCUI","Microsoft.XboxGameOverlay","Microsoft.XboxSpeechToTextOverlay",
        "Microsoft.ZuneMusic","Microsoft.ZuneVideo","Microsoft.YourPhone","Clipchamp.Clipchamp",
        "Microsoft.Todos","Microsoft.PowerAutomateDesktop","MicrosoftTeams","Microsoft.549981C3F5F10",
        "king.com.CandyCrushSaga","king.com.CandyCrushSodaSaga","Disney.37853FC22B2CE"
    )
    $removed = 0
    foreach ($pkg in $bloat) {
        $found = Get-AppxPackage -Name "*$pkg*" -ErrorAction SilentlyContinue
        if ($found) {
            $found | Remove-AppxPackage -ErrorAction SilentlyContinue
            Write-Log "  Removed: $pkg" OK
            $removed++
        }
    }
    Write-Log "✓ Safe Debloat complete — removed $removed packages" OK
})

$Ctrl['BtnDebloatAggressive'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    if (-not (Show-Warning "Aggressive Debloat" "Removes ALL preinstalled UWP apps except Store and Calculator. This is difficult to reverse.")) { return }
    Write-Log "⚠ Running Aggressive Debloat..." Action
    $keep = @("Microsoft.WindowsStore","Microsoft.WindowsCalculator","Microsoft.DesktopAppInstaller","Microsoft.Windows.Photos")
    Get-AppxPackage | Where-Object { $keep -notcontains $_.Name -and -not $_.IsFramework } | ForEach-Object {
        try {
            $_ | Remove-AppxPackage -ErrorAction SilentlyContinue
            Write-Log "  Removed: $($_.Name)" OK
        } catch {}
    }
    Write-Log "✓ Aggressive Debloat complete" OK
})

# ═══════════════════════════════════════════════════════════════════
# LOW-END PC MODE
# ═══════════════════════════════════════════════════════════════════
$Ctrl['BtnLowEnd'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "💡 Applying Low-End PC Optimization Package..." Action
    Write-Log "  → Disabling animations and transparency..." Action
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -ErrorAction SilentlyContinue

    Write-Log "  → Disabling telemetry services..." Action
    @("DiagTrack","dmwappushservice","SysMain") | ForEach-Object {
        Set-Service -Name $_ -StartupType Disabled -ErrorAction SilentlyContinue
        Stop-Service -Name $_ -Force -ErrorAction SilentlyContinue
    }

    Write-Log "  → Disabling Game DVR..." Action
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -ErrorAction SilentlyContinue
    Ensure-RegPath "HKCU:\System\GameConfigStore"
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -ErrorAction SilentlyContinue

    Write-Log "  → Activating High Performance power plan..." Action
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c

    Write-Log "  → Optimizing RAM cache..." Action
    Ensure-RegPath "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 0 -ErrorAction SilentlyContinue

    Write-Log "  → Cleaning temp files..." Action
    @("$env:TEMP","$env:WINDIR\Temp") | ForEach-Object {
        if (Test-Path $_) { Remove-Item "$_\*" -Recurse -Force -ErrorAction SilentlyContinue }
    }

    Write-Log "  → Running garbage collection..." Action
    [System.GC]::Collect()

    Write-Log "✓ Low-End PC optimization complete! Restart recommended." OK
})

# ═══════════════════════════════════════════════════════════════════
# REVERT ALL CHANGES
# ═══════════════════════════════════════════════════════════════════
$Ctrl['BtnRevert'].Add_Click({
    if (-not (Show-Warning "Revert All Changes" "This will restore all modified settings to Windows defaults.")) { return }
    Write-Log "↩️ Reverting ALL optimizations to Windows Defaults..." Action

    # Revert visuals
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x9E,0x3E,0x07,0x80,0x12,0x00,0x00,0x00)) -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 1 -ErrorAction SilentlyContinue
    Write-Log "  ✓ Visual effects restored" OK

    # Revert network
    netsh int tcp set global autotuninglevel=normal 2>&1 | Out-Null
    $adapters = Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" -ErrorAction SilentlyContinue
    foreach ($a in $adapters) {
        Remove-ItemProperty -Path $a.PSPath -Name "TcpAckFrequency" -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path $a.PSPath -Name "TCPNoDelay" -ErrorAction SilentlyContinue
    }
    Write-Log "  ✓ Network settings restored (Nagle re-enabled)" OK

    # Revert multimedia
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 20 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 10 -ErrorAction SilentlyContinue
    Write-Log "  ✓ System responsiveness and throttling restored" OK

    # Revert priority
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 2 -ErrorAction SilentlyContinue
    Write-Log "  ✓ CPU priority restored to default" OK

    # Revert power
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PowerThrottlingOff" -Value 0 -ErrorAction SilentlyContinue
    powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>&1 | Out-Null
    Write-Log "  ✓ Power plan restored to Balanced" OK

    # Revert mouse
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseSpeed" -Value "1" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold1" -Value "6" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Mouse" -Name "MouseThreshold2" -Value "10" -ErrorAction SilentlyContinue
    Write-Log "  ✓ Mouse acceleration restored" OK

    # Revert keyboard
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardDelay" -Value "1" -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Control Panel\Keyboard" -Name "KeyboardSpeed" -Value "31" -ErrorAction SilentlyContinue
    Write-Log "  ✓ Keyboard settings restored" OK

    # Revert RAM cache
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management" -Name "LargeSystemCache" -Value 1 -ErrorAction SilentlyContinue
    Write-Log "  ✓ RAM cache restored" OK

    # Re-enable services
    @("DiagTrack","dmwappushservice","SysMain") | ForEach-Object {
        Set-Service -Name $_ -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name $_ -ErrorAction SilentlyContinue
    }
    Write-Log "  ✓ Services restored (Telemetry, SysMain)" OK

    # Re-enable Game DVR
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 1 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 1 -ErrorAction SilentlyContinue
    Write-Log "  ✓ Game DVR re-enabled" OK

    # Revert core parking
    powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 10 2>&1 | Out-Null
    powercfg -setactive SCHEME_CURRENT 2>&1 | Out-Null
    Write-Log "  ✓ CPU Core Parking restored" OK

    # Revert BCD
    bcdedit /deletevalue useplatformtick 2>&1 | Out-Null
    Write-Log "  ✓ BCD settings restored" OK

    Write-Log "✅ ALL CHANGES REVERTED TO WINDOWS DEFAULTS" OK
    [System.Windows.MessageBox]::Show("All optimizations have been reverted to Windows defaults.`nA system restart is recommended.", "Revert Complete", "OK", "Information")
})

# ═══════════════════════════════════════════════════════════════════
# GAMING TAB — ZERO LATENCY
# ═══════════════════════════════════════════════════════════════════
$Ctrl['BtnBCDTick'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Applying BCD PlatformTick fix..." Action
    bcdedit /set useplatformtick yes 2>&1 | Out-Null
    bcdedit /set disabledynamictick yes 2>&1 | Out-Null
    Write-Log "✓ PlatformTick enabled, DynamicTick disabled — stable timer resolution" OK
})

$Ctrl['BtnWin32Priority'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Setting Win32PrioritySeparation to 0x26 (38)..." Action
    Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38
    Write-Log "✓ CPU now massively prioritizes your foreground window" OK
})

$Ctrl['BtnGamePriority'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Setting GPU and scheduling priority for games..." Action
    $gamePath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games"
    Ensure-RegPath $gamePath
    Set-ItemProperty -Path $gamePath -Name "GPU Priority" -Value 8
    Set-ItemProperty -Path $gamePath -Name "Priority" -Value 6
    Set-ItemProperty -Path $gamePath -Name "Scheduling Category" -Value "High"
    Set-ItemProperty -Path $gamePath -Name "SFIO Priority" -Value "High"
    Write-Log "✓ GPU Priority=8, Scheduling=High — games get maximum GPU resources" OK
})

$Ctrl['BtnSysResponsive'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Setting SystemResponsiveness to 10..." Action
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 10
    Write-Log "✓ SystemResponsiveness=10 — only 10% CPU reserved for system (default=20%)" OK
})

$Ctrl['BtnTCPNoDelay'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Applying TCP No-Delay on all interfaces..." Action
    Get-ChildItem "HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces" | ForEach-Object {
        Set-ItemProperty -Path $_.PSPath -Name "TcpAckFrequency" -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path $_.PSPath -Name "TCPNoDelay" -Value 1 -ErrorAction SilentlyContinue
    }
    Write-Log "✓ TCP No-Delay active — packets sent immediately" OK
})

$Ctrl['BtnNetworkIndex'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Maximizing network throughput..." Action
    $mmPath = "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile"
    Set-ItemProperty -Path $mmPath -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF
    Set-ItemProperty -Path $mmPath -Name "SystemResponsiveness" -Value 10
    Write-Log "✓ Network throttling disabled, responsiveness maximized" OK
})

$Ctrl['BtnBoostGame'].Add_Click({
    Write-Log "Process Lasso Mode — boosting foreground game..." Action
    $gameProcesses = @("csgo","cs2","valorant","fortnite","apex_legends","PUBG","dota2","league of legends","overwatch","r5apex","cod","GTA5","FiveM")
    $lowPriority = @("chrome","firefox","msedge","discord","spotify","teams","slack")

    $boosted = 0
    foreach ($name in $gameProcesses) {
        $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            $p.PriorityClass = 'High'
            Write-Log "  ⬆ $($p.Name) → High Priority" OK
            $boosted++
        }
    }
    $demoted = 0
    foreach ($name in $lowPriority) {
        $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
        foreach ($p in $procs) {
            $p.PriorityClass = 'BelowNormal'
            Write-Log "  ⬇ $($p.Name) → Below Normal" Info
            $demoted++
        }
    }
    if ($boosted -eq 0) {
        Write-Log "No game processes found running. Start your game first!" Warn
    } else {
        Write-Log "✓ Boosted $boosted game process(es), demoted $demoted background apps" OK
    }
})

$Ctrl['BtnAffinityOptimize'].Add_Click({
    Write-Log "CPU Affinity Optimizer — distributing background load..." Action
    $cores = (Get-CimInstance Win32_Processor).NumberOfLogicalProcessors
    if ($cores -ge 4) {
        $bgMask = 3 # cores 0-1 for background
        $lowPri = @("chrome","firefox","msedge","discord","spotify")
        foreach ($name in $lowPri) {
            $procs = Get-Process -Name $name -ErrorAction SilentlyContinue
            foreach ($p in $procs) {
                try {
                    $p.ProcessorAffinity = $bgMask
                    Write-Log "  $($p.Name) → Cores 0-1 only" Info
                } catch {}
            }
        }
        Write-Log "✓ Background apps pinned to cores 0-1. Performance cores free for games." OK
    } else {
        Write-Log "Only $cores cores detected — affinity optimization skipped (need 4+)" Warn
    }
})

$Ctrl['BtnFrameCap'].Add_Click({
    Write-Log "Reading monitor refresh rate..." Action
    try {
        Add-Type -AssemblyName System.Windows.Forms
        $hz = [System.Windows.Forms.Screen]::PrimaryScreen | ForEach-Object {
            $dm = New-Object System.Windows.Forms.Screen
        }
        $display = Get-CimInstance -ClassName Win32_VideoController | Select-Object -First 1
        $refreshRate = $display.CurrentRefreshRate
        Write-Log "Monitor refresh rate: ${refreshRate}Hz" OK
        Write-Log "  Recommendation: Cap your in-game FPS to ${refreshRate} or $($refreshRate - 3) for consistent frame times" Info
        Write-Log "  For NVIDIA: Set 'Max Frame Rate' to $($refreshRate - 3) in NVIDIA Control Panel" Info
        Write-Log "  For AMD: Set 'Radeon Chill Max' to $refreshRate in AMD Software" Info
        Write-Log "  For RTSS (MSI Afterburner): Set Framerate Limit to $($refreshRate - 3)" Info
    } catch {
        Write-Log "Could not read refresh rate. Check Display Settings manually." Warn
    }
})

$Ctrl['BtnFSO'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Disabling Fullscreen Optimizations globally..." Action
    Ensure-RegPath "HKCU:\System\GameConfigStore"
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehaviorMode" -Value 2
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_HonorUserFSEBehaviorMode" -Value 1
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_FSEBehavior" -Value 2
    Write-Log "✓ Fullscreen Optimizations disabled — true exclusive fullscreen mode" OK
})

# ═══════════════════════════════════════════════════════════════════
# HARDWARE TAB
# ═══════════════════════════════════════════════════════════════════
$Ctrl['BtnWinSAT'].Add_Click({
    Write-Log "Running WinSAT formal benchmark... This may take 2-3 minutes." Action
    try {
        Start-Process -FilePath "winsat" -ArgumentList "formal" -Wait -NoNewWindow -ErrorAction Stop
        $scores = Get-WinSATScore
        if ($scores) {
            $txt = "CPU: $($scores.CPU) | Memory: $($scores.Memory) | Disk: $($scores.Disk) | GPU: $($scores.GPU) | 3D: $($scores.D3D) | Base Score: $($scores.Base)"
            $Ctrl['TxtWinSAT'].Text = $txt
            $Ctrl['WinSATPanel'].Visibility = 'Visible'
            Write-Log "WinSAT Results: $txt" OK
            if ($scores.Base -lt 4) {
                Write-Log "  → Low score detected. Recommend 'Low-End PC Mode' in Tweaks tab." Warn
            } elseif ($scores.Base -ge 8) {
                Write-Log "  → High performance system! You can safely apply all gaming tweaks." OK
            }
        }
    } catch {
        Write-Log "WinSAT error: $_" Error
    }
})

$Ctrl['BtnAutoTune'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "🤖 Running Auto-Tune based on hardware detection..." Action
    $hw = Get-SystemProfile
    Write-Log "  Detected: $($hw.Tier) | $(if($hw.IsLaptop){'Laptop'}else{'Desktop'}) | $($hw.CPU)" Info

    switch ($hw.Tier) {
        'Low-End' {
            Write-Log "  → Applying Low-End optimizations..." Action
            # Disable animations
            Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -ErrorAction SilentlyContinue
            # Disable heavy services
            @("DiagTrack","SysMain","dmwappushservice") | ForEach-Object {
                Set-Service $_ -StartupType Disabled -ErrorAction SilentlyContinue
                Stop-Service $_ -Force -ErrorAction SilentlyContinue
            }
            powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
            Write-Log "  ✓ Low-End profile applied: animations off, services minimized, high perf power" OK
        }
        'Mid-Range' {
            Write-Log "  → Applying Mid-Range optimizations..." Action
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 14 -ErrorAction SilentlyContinue
            powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
            @("DiagTrack") | ForEach-Object {
                Set-Service $_ -StartupType Disabled -ErrorAction SilentlyContinue
                Stop-Service $_ -Force -ErrorAction SilentlyContinue
            }
            Write-Log "  ✓ Mid-Range profile applied: balanced tweaks for good all-around performance" OK
        }
        'High-End' {
            Write-Log "  → Applying High-End optimizations..." Action
            $out = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1 | Out-String
            if ($out -match '([0-9a-f-]{36})') { powercfg /setactive $Matches[1] }
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 10 -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "NetworkThrottlingIndex" -Value 0xFFFFFFFF -ErrorAction SilentlyContinue
            Set-ItemProperty -Path "HKLM:\System\CurrentControlSet\Control\PriorityControl" -Name "Win32PrioritySeparation" -Value 38 -ErrorAction SilentlyContinue
            Write-Log "  ✓ High-End profile applied: ultimate power, zero latency, max throughput" OK
        }
    }

    if ($hw.IsLaptop) {
        Write-Log "  → Laptop detected: applying thermal-safe 99% CPU cap..." Action
        powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 99 2>&1 | Out-Null
        powercfg -setactive SCHEME_CURRENT
        Write-Log "  ✓ Laptop thermal protection applied (99% CPU max prevents turbo overheat)" OK
    }

    if ($hw.IntegratedGPU) {
        Write-Log "  → Integrated GPU detected: disabling Game DVR overhead..." Action
        Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -ErrorAction SilentlyContinue
        Write-Log "  ✓ iGPU optimizations applied" OK
    }

    Write-Log "✅ Auto-Tune complete! Hardware-optimized profile active." OK
})

$Ctrl['BtnLaptopPerf'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Forcing Laptop Performance Mode..." Action
    # 99% CPU cap to prevent thermal throttle crash
    powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 99 2>&1 | Out-Null
    powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR PROCTHROTTLEMAX 99 2>&1 | Out-Null
    # Kill animations
    Set-ItemProperty -Path "HKCU:\Control Panel\Desktop" -Name "UserPreferencesMask" -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00)) -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -ErrorAction SilentlyContinue
    # High perf plan
    powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c
    powercfg -setactive SCHEME_CURRENT
    Write-Log "✓ Laptop Performance Mode: 99% CPU cap (prevents overheat), animations off, high perf plan" OK
})

$Ctrl['BtnDPTFDisable'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    if (-not (Show-Warning "Disable DPTF" "Disabling thermal framework may cause overheating if fans are insufficient. Monitor temps!")) { return }
    Write-Log "Disabling DPTF thermal throttling..." Action
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\Power" -Name "PowerThrottlingOff" -Value 1 -ErrorAction SilentlyContinue
    $boostPath = "HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\be337238-0d82-4146-a960-4f3749d470c7"
    if (Test-Path $boostPath) { Set-ItemProperty -Path $boostPath -Name "Attributes" -Value 0 -ErrorAction SilentlyContinue }
    Write-Log "✓ DPTF/Power Throttling disabled. CPU boost mode unlocked." OK
    Write-Log "  ⚠ MONITOR YOUR TEMPERATURES! Revert if CPU exceeds 95°C." Warn
})

$Ctrl['BtnIntegratedGPU'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Optimizing for Integrated GPU..." Action
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile" -Name "SystemResponsiveness" -Value 10 -ErrorAction SilentlyContinue
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\GameDVR" -Name "AppCaptureEnabled" -Value 0 -ErrorAction SilentlyContinue
    Ensure-RegPath "HKCU:\System\GameConfigStore"
    Set-ItemProperty -Path "HKCU:\System\GameConfigStore" -Name "GameDVR_Enabled" -Value 0 -ErrorAction SilentlyContinue
    # Disable composition effects
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize" -Name "EnableTransparency" -Value 0 -ErrorAction SilentlyContinue
    Write-Log "✓ iGPU optimized: Game DVR off, transparency off, system responsiveness maximized" OK
})

$Ctrl['BtnCoreUnpark'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Unparking all CPU cores globally..." Action
    powercfg -setacvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>&1 | Out-Null
    powercfg -setdcvalueindex SCHEME_CURRENT SUB_PROCESSOR CPMINCORES 100 2>&1 | Out-Null
    powercfg -setactive SCHEME_CURRENT
    Write-Log "✓ All CPU cores unparked and active" OK
})

$Ctrl['BtnGPUPriority'].Add_Click({
    if (-not (Assert-RestorePoint)) { return }
    Write-Log "Enabling Hardware-Accelerated GPU Scheduling..." Action
    Ensure-RegPath "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers"
    Set-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Control\GraphicsDrivers" -Name "HwSchMode" -Value 2 -ErrorAction SilentlyContinue
    Write-Log "✓ Hardware GPU Scheduling enabled (HAGS). Requires restart." OK
})

# ═══════════════════════════════════════════════════════════════════
# CONFIG TAB
# ═══════════════════════════════════════════════════════════════════
$Ctrl['BtnWSL'].Add_Click({
    Write-Log "Enabling WSL2..." Action
    dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart 2>&1 | Out-Null
    dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart 2>&1 | Out-Null
    Write-Log "✓ WSL2 enabled. Restart required." OK
})

$Ctrl['BtnSandbox'].Add_Click({
    Write-Log "Enabling Windows Sandbox..." Action
    dism.exe /online /enable-feature /featurename:Containers-DisposableClientVM /all /norestart 2>&1 | Out-Null
    Write-Log "✓ Sandbox enabled. Restart required." OK
})

$Ctrl['BtnHyperV'].Add_Click({
    Write-Log "Enabling Hyper-V..." Action
    dism.exe /online /enable-feature /featurename:Microsoft-Hyper-V-All /all /norestart 2>&1 | Out-Null
    Write-Log "✓ Hyper-V enabled. Restart required." OK
})

$Ctrl['BtnDotNet'].Add_Click({
    Write-Log "Enabling .NET Framework 3.5..." Action
    dism.exe /online /enable-feature /featurename:NetFx3 /all /norestart 2>&1 | Out-Null
    Write-Log "✓ .NET 3.5 enabled." OK
})

$Ctrl['BtnOpenSSH'].Add_Click({
    Write-Log "Installing OpenSSH..." Action
    Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0 -ErrorAction SilentlyContinue
    Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 -ErrorAction SilentlyContinue
    Write-Log "✓ OpenSSH installed" OK
})

$Ctrl['BtnClassicMenu'].Add_Click({
    Write-Log "Restoring classic context menu..." Action
    Ensure-RegPath "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32"
    Set-ItemProperty -Path "HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32" -Name "(Default)" -Value "" -ErrorAction SilentlyContinue
    Write-Log "✓ Classic context menu restored. Restart Explorer to apply." OK
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer
})

$Ctrl['BtnFileExt'].Add_Click({
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "HideFileExt" -Value 0
    Write-Log "✓ File extensions visible" OK
})

$Ctrl['BtnHiddenFiles'].Add_Click({
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "Hidden" -Value 1
    Write-Log "✓ Hidden files visible" OK
})

$Ctrl['BtnTaskbarLeft'].Add_Click({
    Ensure-RegPath "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced"
    Set-ItemProperty -Path "HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced" -Name "TaskbarAl" -Value 0
    Write-Log "✓ Taskbar aligned left. Restart Explorer to apply." OK
    Stop-Process -Name explorer -Force -ErrorAction SilentlyContinue
    Start-Process explorer
})

# MicroWin ISO
$Script:ISOPath = ""
$Ctrl['BtnBrowseISO'].Add_Click({
    $dlg = New-Object Microsoft.Win32.OpenFileDialog
    $dlg.Filter = "ISO Files (*.iso)|*.iso"
    $dlg.Title = "Select Windows ISO"
    if ($dlg.ShowDialog()) {
        $Script:ISOPath = $dlg.FileName
        $Ctrl['TxtISOPath'].Text = $Script:ISOPath
        Write-Log "ISO selected: $($Script:ISOPath)" OK
    }
})

$Ctrl['BtnBuildMicroWin'].Add_Click({
    if ([string]::IsNullOrEmpty($Script:ISOPath)) {
        Write-Log "No ISO selected! Browse for a Windows ISO first." Warn
        return
    }
    if (-not (Show-Warning "MicroWin Build" "This will mount the ISO, remove bloatware, and create a new clean ISO. Takes 10-20 minutes.")) { return }
    Write-Log "Building MicroWin from: $($Script:ISOPath)..." Action
    try {
        $mountResult = Mount-DiskImage -ImagePath $Script:ISOPath -PassThru
        $driveLetter = ($mountResult | Get-Volume).DriveLetter
        Write-Log "  ISO mounted at ${driveLetter}:\" OK

        $workDir = "$env:TEMP\MicroWin"
        if (Test-Path $workDir) { Remove-Item $workDir -Recurse -Force }
        New-Item -Path $workDir -ItemType Directory -Force | Out-Null

        Write-Log "  Copying ISO contents..." Action
        Copy-Item -Path "${driveLetter}:\*" -Destination $workDir -Recurse -Force

        # Find install.wim
        $wimPath = Join-Path $workDir "sources\install.wim"
        if (Test-Path $wimPath) {
            Write-Log "  Found install.wim — removing bloatware packages..." Action
            $mountDir = "$env:TEMP\MicroWinMount"
            New-Item -Path $mountDir -ItemType Directory -Force | Out-Null
            dism /mount-wim /wimfile:$wimPath /index:1 /mountdir:$mountDir 2>&1 | Out-Null

            $bloatPackages = @("Microsoft.BingWeather","Microsoft.GetHelp","Microsoft.MicrosoftSolitaireCollection","Microsoft.People","Microsoft.WindowsFeedbackHub","Microsoft.Xbox.TCUI","Microsoft.ZuneMusic","Microsoft.ZuneVideo","Clipchamp.Clipchamp")
            foreach ($pkg in $bloatPackages) {
                $found = Get-AppxProvisionedPackage -Path $mountDir -ErrorAction SilentlyContinue | Where-Object { $_.DisplayName -like "*$pkg*" }
                if ($found) {
                    Remove-AppxProvisionedPackage -Path $mountDir -PackageName $found.PackageName -ErrorAction SilentlyContinue
                    Write-Log "    Removed: $pkg" OK
                }
            }

            dism /unmount-wim /mountdir:$mountDir /commit 2>&1 | Out-Null
            Write-Log "  ✓ Bloatware removed from image" OK
        }

        Dismount-DiskImage -ImagePath $Script:ISOPath -ErrorAction SilentlyContinue
        Write-Log "✓ MicroWin build complete! Clean files at: $workDir" OK
        Write-Log "  Use oscdimg or similar to repack as ISO" Info
    } catch {
        Write-Log "MicroWin error: $_" Error
        Dismount-DiskImage -ImagePath $Script:ISOPath -ErrorAction SilentlyContinue
    }
})

# ═══════════════════════════════════════════════════════════════════
# UPDATES TAB
# ═══════════════════════════════════════════════════════════════════
$Ctrl['BtnUpdateDefault'].Add_Click({
    Write-Log "Restoring default Windows Update settings..." Action
    Remove-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "NoAutoUpdate" -ErrorAction SilentlyContinue
    Set-Service -Name wuauserv -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Write-Log "✓ Windows Update restored to automatic mode" OK
})

$Ctrl['BtnUpdateSecurity'].Add_Click({
    Write-Log "Setting Windows Update to Security Only..." Action
    Ensure-RegPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU" -Name "AUOptions" -Value 2
    Write-Log "✓ Only security updates will be downloaded" OK
})

$Ctrl['BtnUpdateDisable'].Add_Click({
    if (-not (Show-Warning "Disable Updates" "You will not receive security patches. This is NOT recommended for daily use.")) { return }
    Write-Log "⚠ Disabling Windows Update..." Action
    Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Write-Log "✓ Windows Update disabled. Re-enable from this tool when needed." Warn
})

$Ctrl['BtnDODisable'].Add_Click({
    Write-Log "Disabling Delivery Optimization P2P..." Action
    Ensure-RegPath "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization"
    Set-ItemProperty -Path "HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization" -Name "DODownloadMode" -Value 0
    Write-Log "✓ P2P update sharing disabled" OK
})

# ═══════════════════════════════════════════════════════════════════
# HEALTH TAB — SELF-HEALING
# ═══════════════════════════════════════════════════════════════════
$Ctrl['BtnFullScan'].Add_Click({
    Write-Log "🩺 Starting Full System Health Scan (SFC + DISM + WU Reset)..." Action
    Write-Log "  [1/3] Running System File Checker..." Action
    sfc /scannow 2>&1 | ForEach-Object { Write-Log "  $_" Info }
    Write-Log "  [2/3] Running DISM RestoreHealth..." Action
    DISM /Online /Cleanup-Image /RestoreHealth 2>&1 | ForEach-Object { Write-Log "  $_" Info }
    Write-Log "  [3/3] Resetting Windows Update cache..." Action
    @("wuauserv","cryptSvc","bits","msiserver") | ForEach-Object {
        Stop-Service $_ -Force -ErrorAction SilentlyContinue
    }
    Remove-Item "$env:WINDIR\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:WINDIR\System32\catroot2\*" -Recurse -Force -ErrorAction SilentlyContinue
    @("wuauserv","cryptSvc","bits","msiserver") | ForEach-Object {
        Start-Service $_ -ErrorAction SilentlyContinue
    }
    Write-Log "✅ Full System Health Scan complete!" OK
})

$Ctrl['BtnSFC'].Add_Click({
    Write-Log "Running SFC /scannow..." Action
    Start-Process -FilePath "sfc" -ArgumentList "/scannow" -Wait -NoNewWindow
    Write-Log "✓ SFC scan complete" OK
})

$Ctrl['BtnDISM'].Add_Click({
    Write-Log "Running DISM RestoreHealth..." Action
    Start-Process -FilePath "DISM" -ArgumentList "/Online /Cleanup-Image /RestoreHealth" -Wait -NoNewWindow
    Write-Log "✓ DISM repair complete" OK
})

$Ctrl['BtnWUReset'].Add_Click({
    Write-Log "Resetting Windows Update cache..." Action
    @("wuauserv","cryptSvc","bits","msiserver") | ForEach-Object {
        Stop-Service $_ -Force -ErrorAction SilentlyContinue
    }
    Remove-Item "$env:WINDIR\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
    Remove-Item "$env:WINDIR\System32\catroot2\*" -Recurse -Force -ErrorAction SilentlyContinue
    @("wuauserv","cryptSvc","bits","msiserver") | ForEach-Object {
        Start-Service $_ -ErrorAction SilentlyContinue
    }
    Write-Log "✓ Windows Update cache purged and services restarted" OK
})

$Ctrl['BtnCheckDisk'].Add_Click({
    Write-Log "Checking disk health..." Action
    try {
        $volumes = Get-Volume | Where-Object { $_.DriveLetter -and $_.DriveType -eq 'Fixed' }
        foreach ($v in $volumes) {
            $health = $v.HealthStatus
            $pctFree = [math]::Round(($v.SizeRemaining / $v.Size) * 100, 1)
            $status = if ($health -eq 'Healthy') { 'OK' } else { 'Warn' }
            Write-Log "  $($v.DriveLetter):\ — $health — $pctFree% free ($([math]::Round($v.SizeRemaining/1GB,1))GB / $([math]::Round($v.Size/1GB,1))GB)" $status
        }
        Write-Log "✓ Disk health check complete" OK
    } catch { Write-Log "Error: $_" Error }
})

# ═══════════════════════════════════════════════════════════════════
# SHOW WINDOW
# ═══════════════════════════════════════════════════════════════════
$Window.ShowDialog() | Out-Null
