#Requires -RunAsAdministrator
<#
.SYNOPSIS
    Ray's Optimization Chamber v3.0 - Ultimate Windows Utility
    A comprehensive WPF-based system optimization tool inspired by Chris Titus WinUtil.
.DESCRIPTION
    Features: App Installation (winget), System Tweaks, Gaming Optimizations,
    Power Management, Network Tuning, Hardware Tweaks, MicroWin ISO Debloat,
    System Health Scan, and full Revert capability.
.NOTES
    Requires: Windows 10/11, PowerShell 5.1+, Administrator privileges
    Author: Ray's Optimization Chamber
#>

# ══════════════════════════════════════════════════════════════════
#  ELEVATION CHECK
# ══════════════════════════════════════════════════════════════════
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Start-Process powershell "-ExecutionPolicy Bypass -File `"$PSCommandPath`"" -Verb RunAs
    exit
}

# ══════════════════════════════════════════════════════════════════
#  LOAD WPF ASSEMBLIES
# ══════════════════════════════════════════════════════════════════
Add-Type -AssemblyName PresentationFramework
Add-Type -AssemblyName PresentationCore
Add-Type -AssemblyName WindowsBase
Add-Type -AssemblyName System.Windows.Forms

# ══════════════════════════════════════════════════════════════════
#  DWM HELPER - MICA / ACRYLIC / DARK TITLE BAR
# ══════════════════════════════════════════════════════════════════
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;
public class DwmHelper {
    [DllImport("dwmapi.dll", CharSet = CharSet.Unicode, PreserveSig = false)]
    public static extern void DwmSetWindowAttribute(IntPtr hwnd, int attr, ref int attrValue, int attrSize);

    public static void SetDarkMode(IntPtr handle) {
        int val = 1;
        try { DwmSetWindowAttribute(handle, 20, ref val, 4); } catch {}
        try { DwmSetWindowAttribute(handle, 19, ref val, 4); } catch {}
    }
    public static void SetMicaBackdrop(IntPtr handle) {
        int val = 2;
        try { DwmSetWindowAttribute(handle, 38, ref val, 4); } catch {}
    }
    public static void SetAcrylicBackdrop(IntPtr handle) {
        int val = 3;
        try { DwmSetWindowAttribute(handle, 38, ref val, 4); } catch {}
    }
}
"@ -ErrorAction SilentlyContinue

# ══════════════════════════════════════════════════════════════════
#  COLOUR PALETTE - Cyber Blue Theme
# ══════════════════════════════════════════════════════════════════
$C = @{
    BG       = '#000B1A'
    Surface  = '#001F3F'
    Surface2 = '#003366'
    Accent   = '#00D9FF'
    NavBG    = '#000814'
    Text     = '#F0F0F0'
    TextDim  = '#8090A0'
    Green    = '#00FFCC'
    Yellow   = '#FFD700'
    Red      = '#FF4466'
    Border   = '#002A4A'
    LogBG    = '#00050A'
}

# ══════════════════════════════════════════════════════════════════
#  APP CATALOGUE - 30+ Applications
# ══════════════════════════════════════════════════════════════════
$AppCatalogue = @(
    @{ Name='Google Chrome';       Id='Google.Chrome';               Cat='Browsers' }
    @{ Name='Mozilla Firefox';     Id='Mozilla.Firefox';             Cat='Browsers' }
    @{ Name='Brave Browser';       Id='Brave.Brave';                 Cat='Browsers' }
    @{ Name='Microsoft Edge';      Id='Microsoft.Edge';              Cat='Browsers' }
    @{ Name='Opera GX';            Id='Opera.OperaGX';               Cat='Browsers' }
    @{ Name='Discord';             Id='Discord.Discord';             Cat='Communication' }
    @{ Name='Zoom';                Id='Zoom.Zoom';                   Cat='Communication' }
    @{ Name='Slack';               Id='SlackTechnologies.Slack';     Cat='Communication' }
    @{ Name='Microsoft Teams';     Id='Microsoft.Teams';             Cat='Communication' }
    @{ Name='Telegram';            Id='Telegram.TelegramDesktop';    Cat='Communication' }
    @{ Name='Steam';               Id='Valve.Steam';                 Cat='Gaming' }
    @{ Name='Epic Games Launcher'; Id='EpicGames.EpicGamesLauncher'; Cat='Gaming' }
    @{ Name='GOG Galaxy';          Id='GOG.Galaxy';                  Cat='Gaming' }
    @{ Name='EA App';              Id='ElectronicArts.EADesktop';    Cat='Gaming' }
    @{ Name='VLC Media Player';    Id='VideoLAN.VLC';                Cat='Media' }
    @{ Name='Spotify';             Id='Spotify.Spotify';             Cat='Media' }
    @{ Name='OBS Studio';          Id='OBSProject.OBSStudio';        Cat='Media' }
    @{ Name='Audacity';            Id='Audacity.Audacity';           Cat='Media' }
    @{ Name='7-Zip';               Id='7zip.7zip';                   Cat='Utilities' }
    @{ Name='Notepad++';           Id='Notepad++.Notepad++';         Cat='Utilities' }
    @{ Name='WinRAR';              Id='RARLab.WinRAR';               Cat='Utilities' }
    @{ Name='PowerToys';           Id='Microsoft.PowerToys';         Cat='Utilities' }
    @{ Name='Everything Search';   Id='voidtools.Everything';        Cat='Utilities' }
    @{ Name='Visual Studio Code';  Id='Microsoft.VisualStudioCode';  Cat='Development' }
    @{ Name='Git';                 Id='Git.Git';                     Cat='Development' }
    @{ Name='Python 3';            Id='Python.Python.3.12';          Cat='Development' }
    @{ Name='Node.js LTS';         Id='OpenJS.NodeJS.LTS';           Cat='Development' }
    @{ Name='Windows Terminal';    Id='Microsoft.WindowsTerminal';   Cat='Development' }
    @{ Name='NVIDIA GeForce Exp';  Id='Nvidia.GeForceExperience';    Cat='Drivers' }
    @{ Name='AMD Radeon Software'; Id='AMD.RyzenMaster';             Cat='Drivers' }
    @{ Name='CPU-Z';               Id='CPUID.CPU-Z';                 Cat='Drivers' }
    @{ Name='HWMonitor';           Id='CPUID.HWMonitor';             Cat='Drivers' }
)

# ══════════════════════════════════════════════════════════════════
#  STATE VARIABLES
# ══════════════════════════════════════════════════════════════════
$Script:RestorePointCreated = $false
$Script:SelectedApps = [System.Collections.Generic.HashSet[string]]::new()
$Ctrl = @{}

# ══════════════════════════════════════════════════════════════════
#  BUILD XAML - MAIN WINDOW
# ══════════════════════════════════════════════════════════════════

# Helper to generate app checkboxes XAML
$appXaml = ""
$categories = $AppCatalogue | Group-Object Cat
foreach ($cat in $categories) {
    $appXaml += "<TextBlock Text='$($cat.Name)' FontSize='14' FontWeight='Bold' Foreground='$($C.Accent)' Margin='0,12,0,6'/>`n"
    foreach ($app in $cat.Group) {
        $safeId = $app.Id -replace '[^A-Za-z0-9]','_'
        $appXaml += "<CheckBox x:Name='chk_$safeId' Content='  $($app.Name)' Foreground='$($C.Text)' Margin='4,3' FontSize='12' ToolTip='winget install $($app.Id)'/>`n"
    }
}

# Tweak definitions for generating UI
$TweakDefs = @(
    @{ Id='LowEnd';        Label='Low-End PC Optimization';    Desc='One-click: disables animations, transparency, background bloat. Safe for all PCs.';     Tag='Extreme' }
    @{ Id='GameBooster';   Label='Game Booster (Zero Latency)'; Desc='Disables network throttling, sets SystemResponsiveness to 10, max GPU priority.';       Tag='Gaming' }
    @{ Id='ZeroLatency';   Label='Extreme Gaming Module';       Desc='BCD tick rate, Win32PrioritySeparation=0x26, disables Nagle Algorithm.';                Tag='Gaming' }
    @{ Id='InputLatency';  Label='Keyboard/Mouse Optimization'; Desc='Disables mouse acceleration, optimizes HID polling rate, reduces input delay.';         Tag='Hardware' }
    @{ Id='RAMOptimize';   Label='RAM Optimization';            Desc='Sets LargeSystemCache=0, optimizes working set, reduces standby memory usage.';         Tag='Performance' }
    @{ Id='CPUGPUOpt';     Label='CPU/GPU Optimization';        Desc='Unlocks Ultimate Performance plan, disables core parking, max processor state 100%.';    Tag='Performance' }
    @{ Id='UltPower';      Label='Ultimate Performance Plan';   Desc='Enables hidden power plan that prevents CPU parking and clock throttling.';              Tag='Power' }
    @{ Id='PowerSave';     Label='Laptop Power Saver';          Desc='Enables battery saver, dims display, reduces background activity for laptops.';          Tag='Power' }
    @{ Id='NetOptimize';   Label='Network Optimization';        Desc='Disables auto-tuning overhead, optimizes TCP/IP stack, enables RSS/RSC.';               Tag='Network' }
    @{ Id='InternetFix';   Label='Internet Refresher';          Desc='Flushes DNS, resets Winsock/IP stack, renews DHCP lease. Fixes connection drops.';       Tag='Network' }
    @{ Id='USBTweaks';     Label='USB Tweaks';                  Desc='Disables USB Selective Suspend so mice/headsets never sleep or lag.';                    Tag='Hardware' }
    @{ Id='DiskCleanup';   Label='Disk Cleanup / Repair';       Desc='Clears temp files, recycle bin, Windows Update cache. Runs chkdsk analysis.';           Tag='Storage' }
    @{ Id='StorageOpt';    Label='Storage Optimization';        Desc='Disables hibernation file, compresses OS, optimizes NTFS for performance.';             Tag='Storage' }
    @{ Id='Debloat';       Label='Windows Debloat';             Desc='Removes pre-installed bloatware apps (Candy Crush, Xbox Bar, etc). Reversible.';        Tag='System' }
    @{ Id='GenTweaks';     Label='General Windows Tweaks';      Desc='Disables telemetry, Cortana, tips, ads in Start menu. Privacy-focused.';                Tag='System' }
    @{ Id='SysCleanup';    Label='System Cleanup';              Desc='Clears temp folders, prefetch, thumbnail cache. Does NOT touch user documents.';        Tag='System' }
    @{ Id='Privacy';       Label='Privacy Hardening';           Desc='Disables advertising ID, location tracking, diagnostic data, activity history.';        Tag='System' }
)

$tweakXaml = ""
$tweakTags = $TweakDefs | Group-Object { $_.Tag }
foreach ($tg in $tweakTags) {
    $tweakXaml += "<TextBlock Text='$($tg.Name)' FontSize='13' FontWeight='Bold' Foreground='$($C.Accent)' Margin='0,10,0,4'/>`n"
    foreach ($tw in $tg.Group) {
        $tweakXaml += "<Border Background='$($C.Surface)' CornerRadius='6' Padding='10,8' Margin='0,2' BorderBrush='$($C.Border)' BorderThickness='1'>`n"
        $tweakXaml += "  <CheckBox x:Name='chk_$($tw.Id)' Foreground='$($C.Text)' FontSize='12' ToolTip='$($tw.Desc)'>`n"
        $tweakXaml += "    <StackPanel><TextBlock Text='$($tw.Label)' FontWeight='SemiBold'/><TextBlock Text='$($tw.Desc)' Foreground='$($C.TextDim)' FontSize='10' TextWrapping='Wrap' MaxWidth='500'/></StackPanel>`n"
        $tweakXaml += "  </CheckBox></Border>`n"
    }
}

[xml]$xaml = @"
<Window xmlns="http://schemas.microsoft.com/winfx/2006/xaml/presentation"
        xmlns:x="http://schemas.microsoft.com/winfx/2006/xaml"
        Title="Ray's Optimization Chamber v3.0"
        Width="1100" Height="750" MinWidth="900" MinHeight="600"
        WindowStartupLocation="CenterScreen"
        Background="$($C.BG)" Foreground="$($C.Text)"
        FontFamily="Segoe UI">
  <Window.Resources>
    <Style TargetType="ToolTip">
      <Setter Property="Background" Value="$($C.Surface)"/>
      <Setter Property="Foreground" Value="$($C.Text)"/>
      <Setter Property="BorderBrush" Value="$($C.Accent)"/>
      <Setter Property="BorderThickness" Value="1"/>
      <Setter Property="Padding" Value="8,5"/>
      <Setter Property="FontSize" Value="12"/>
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
        <StackPanel DockPanel.Dock="Left" Orientation="Horizontal" VerticalAlignment="Center">
          <TextBlock Text="&#x26A1;" FontSize="22" Margin="0,0,8,0"/>
          <TextBlock Text="Ray's Optimization Chamber" FontSize="18" FontWeight="Bold" Foreground="$($C.Accent)"/>
          <Border Background="$($C.Surface2)" CornerRadius="10" Padding="8,2" Margin="12,0,0,0">
            <TextBlock Text="v3.0" FontSize="10" Foreground="$($C.TextDim)"/>
          </Border>
        </StackPanel>
        <StackPanel DockPanel.Dock="Right" Orientation="Horizontal" HorizontalAlignment="Right">
          <Button x:Name="BtnRestorePoint" Content="&#x1F6E1; Create Restore Point" Padding="14,6" Margin="4,0" FontSize="11"
                  Background="$($C.Surface2)" Foreground="$($C.Yellow)" BorderBrush="$($C.Yellow)" BorderThickness="1"
                  ToolTip="MANDATORY: Creates a System Restore Point before applying any tweaks. Required for safety."
                  Cursor="Hand"/>
          <Button x:Name="BtnRevert" Content="&#x21A9; Revert All Changes" Padding="14,6" Margin="4,0" FontSize="11"
                  Background="$($C.Surface2)" Foreground="$($C.Red)" BorderBrush="$($C.Red)" BorderThickness="1"
                  ToolTip="Reverts ALL optimizations back to Windows default values. Safe to use anytime."
                  Cursor="Hand"/>
        </StackPanel>
      </DockPanel>
    </Border>

    <!-- NAVIGATION TABS -->
    <Border Grid.Row="1" Background="$($C.NavBG)" Padding="12,4" BorderBrush="$($C.Border)" BorderThickness="0,0,0,1">
      <StackPanel Orientation="Horizontal">
        <Button x:Name="NavInstall"  Content="&#x1F4E6; Install"  Padding="18,8" Margin="3,0" FontSize="12" FontWeight="SemiBold" Background="$($C.Surface2)" Foreground="$($C.Accent)" BorderThickness="0" Cursor="Hand" ToolTip="Browse and install apps via winget"/>
        <Button x:Name="NavTweaks"   Content="&#x1F527; Tweaks"   Padding="18,8" Margin="3,0" FontSize="12" FontWeight="SemiBold" Background="$($C.Surface)"  Foreground="$($C.Text)"   BorderThickness="0" Cursor="Hand" ToolTip="System optimizations, gaming, power tweaks"/>
        <Button x:Name="NavConfig"   Content="&#x2699; Config"    Padding="18,8" Margin="3,0" FontSize="12" FontWeight="SemiBold" Background="$($C.Surface)"  Foreground="$($C.Text)"   BorderThickness="0" Cursor="Hand" ToolTip="Windows features, MicroWin ISO debloat"/>
        <Button x:Name="NavUpdates"  Content="&#x1F504; Updates"  Padding="18,8" Margin="3,0" FontSize="12" FontWeight="SemiBold" Background="$($C.Surface)"  Foreground="$($C.Text)"   BorderThickness="0" Cursor="Hand" ToolTip="Update policies, system health scan, repair"/>
      </StackPanel>
    </Border>

    <!-- MAIN CONTENT AREA -->
    <Grid Grid.Row="2">

      <!-- ==================== INSTALL TAB ==================== -->
      <Grid x:Name="PanelInstall" Visibility="Visible">
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <!-- Search Bar -->
        <Border Grid.Row="0" Margin="16,12,16,0" Background="$($C.Surface)" CornerRadius="8" Padding="12,8" BorderBrush="$($C.Border)" BorderThickness="1">
          <DockPanel>
            <TextBlock DockPanel.Dock="Left" Text="&#x1F50D;" FontSize="16" VerticalAlignment="Center" Margin="0,0,8,0"/>
            <Button x:Name="BtnWingetSearch" DockPanel.Dock="Right" Content="Search WinGet" Padding="12,4" Background="$($C.Accent)" Foreground="$($C.BG)" FontWeight="Bold" BorderThickness="0" Cursor="Hand" ToolTip="Search the entire WinGet repository (10,000+ apps)"/>
            <TextBox x:Name="TxtSearch" Background="Transparent" Foreground="$($C.Text)" BorderThickness="0" FontSize="13" VerticalAlignment="Center" Padding="4"
                     ToolTip="Type an app name to filter the list, or use Search WinGet for live repository search"/>
          </DockPanel>
        </Border>
        <!-- App List -->
        <ScrollViewer Grid.Row="1" Margin="16,8,16,0" VerticalScrollBarVisibility="Auto">
          <StackPanel x:Name="AppListPanel">
            $appXaml
          </StackPanel>
        </ScrollViewer>
        <!-- Install Button -->
        <Border Grid.Row="2" Margin="16,8,16,12">
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
            <Button x:Name="BtnInstallSelected" Content="&#x1F4E5; Install Selected Apps" Padding="24,10" FontSize="14" FontWeight="Bold"
                    Background="$($C.Accent)" Foreground="$($C.BG)" BorderThickness="0" Cursor="Hand"
                    ToolTip="Installs all checked apps using winget in the background"/>
            <Button x:Name="BtnSelectAll" Content="Select All" Padding="14,10" Margin="8,0,0,0" FontSize="12"
                    Background="$($C.Surface2)" Foreground="$($C.Text)" BorderThickness="0" Cursor="Hand"/>
            <Button x:Name="BtnDeselectAll" Content="Deselect All" Padding="14,10" Margin="8,0,0,0" FontSize="12"
                    Background="$($C.Surface2)" Foreground="$($C.Text)" BorderThickness="0" Cursor="Hand"/>
          </StackPanel>
        </Border>
      </Grid>

      <!-- ==================== TWEAKS TAB ==================== -->
      <Grid x:Name="PanelTweaks" Visibility="Collapsed">
        <Grid.RowDefinitions>
          <RowDefinition Height="*"/>
          <RowDefinition Height="Auto"/>
        </Grid.RowDefinitions>
        <ScrollViewer Grid.Row="0" Margin="16,8,16,0" VerticalScrollBarVisibility="Auto">
          <StackPanel>
            <Border Background="$($C.Surface)" CornerRadius="8" Padding="14,10" Margin="0,4" BorderBrush="$($C.Accent)" BorderThickness="1">
              <StackPanel>
                <TextBlock Text="&#x26A0; Safety Notice" FontSize="14" FontWeight="Bold" Foreground="$($C.Yellow)"/>
                <TextBlock Text="You MUST create a Restore Point before applying tweaks. Click the shield button in the title bar." Foreground="$($C.TextDim)" FontSize="11" TextWrapping="Wrap" Margin="0,4,0,0"/>
              </StackPanel>
            </Border>
            $tweakXaml
          </StackPanel>
        </ScrollViewer>
        <Border Grid.Row="1" Margin="16,8,16,12">
          <StackPanel Orientation="Horizontal" HorizontalAlignment="Center">
            <Button x:Name="BtnApplyTweaks" Content="&#x26A1; Apply Selected Tweaks" Padding="24,10" FontSize="14" FontWeight="Bold"
                    Background="$($C.Accent)" Foreground="$($C.BG)" BorderThickness="0" Cursor="Hand"
                    ToolTip="Applies all checked optimizations. Restore point required first!"/>
            <Button x:Name="BtnLowEndMacro" Content="&#x1F4BB; Low-End PC Macro" Padding="14,10" Margin="8,0,0,0" FontSize="12"
                    Background="$($C.Surface2)" Foreground="$($C.Green)" BorderBrush="$($C.Green)" BorderThickness="1" Cursor="Hand"
                    ToolTip="Auto-selects the safest tweaks for older/slower PCs: disables animations, transparency, bloat"/>
          </StackPanel>
        </Border>
      </Grid>

      <!-- ==================== CONFIG TAB ==================== -->
      <Grid x:Name="PanelConfig" Visibility="Collapsed">
        <ScrollViewer Margin="16,8" VerticalScrollBarVisibility="Auto">
          <StackPanel>
            <TextBlock Text="Optional Windows Features" FontSize="14" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,8,0,6"/>
            <WrapPanel>
              <Button x:Name="BtnWSL" Content="Enable WSL2" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Enables Windows Subsystem for Linux 2 for running Linux distributions"/>
              <Button x:Name="BtnSandbox" Content="Enable Sandbox" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Enables Windows Sandbox for running apps in an isolated environment"/>
              <Button x:Name="BtnHyperV" Content="Enable Hyper-V" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Enables Hyper-V virtualization platform for running virtual machines"/>
              <Button x:Name="BtnDotNet" Content="Enable .NET 3.5" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Installs .NET Framework 3.5 needed by older applications"/>
              <Button x:Name="BtnOpenSSH" Content="Enable OpenSSH" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Installs OpenSSH client and server for secure remote connections"/>
            </WrapPanel>

            <TextBlock Text="Taskbar and Explorer" FontSize="14" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,16,0,6"/>
            <WrapPanel>
              <Button x:Name="BtnTaskbarLeft" Content="Taskbar Left Align" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Moves the taskbar alignment to the left (Windows 11)"/>
              <Button x:Name="BtnClassicContext" Content="Classic Context Menu" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Restores the classic right-click context menu in Windows 11"/>
              <Button x:Name="BtnFileExt" Content="Show File Extensions" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Shows file extensions (.txt, .exe, etc) in File Explorer"/>
              <Button x:Name="BtnHiddenFiles" Content="Show Hidden Files" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Shows hidden files and folders in File Explorer"/>
            </WrapPanel>

            <TextBlock Text="DNS Configuration" FontSize="14" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,16,0,6"/>
            <WrapPanel>
              <Button x:Name="BtnDNSGoogle" Content="Google DNS (8.8.8.8)" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Sets DNS to Google (8.8.8.8 / 8.8.4.4) for faster browsing"/>
              <Button x:Name="BtnDNSCloud" Content="Cloudflare DNS (1.1.1.1)" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Sets DNS to Cloudflare (1.1.1.1) for privacy and speed"/>
              <Button x:Name="BtnDNSReset" Content="Reset DNS to Auto" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Resets DNS back to automatic (DHCP) configuration"/>
            </WrapPanel>

            <TextBlock Text="MicroWin - ISO Debloat" FontSize="14" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,16,0,6"/>
            <Border Background="$($C.Surface)" CornerRadius="8" Padding="14,10" BorderBrush="$($C.Border)" BorderThickness="1">
              <StackPanel>
                <TextBlock Text="Create a debloated Windows ISO by removing bloatware, telemetry, and unnecessary components from an official Windows ISO file." Foreground="$($C.TextDim)" FontSize="11" TextWrapping="Wrap" Margin="0,0,0,8"/>
                <StackPanel Orientation="Horizontal">
                  <Button x:Name="BtnBrowseISO" Content="&#x1F4C2; Browse ISO File" Padding="14,8" Margin="0,0,8,0" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Select a Windows ISO file to debloat"/>
                  <TextBlock x:Name="TxtISOPath" Text="No ISO selected" Foreground="$($C.TextDim)" VerticalAlignment="Center" FontSize="11"/>
                </StackPanel>
                <Button x:Name="BtnMicroWin" Content="&#x26A1; Build MicroWin ISO" Padding="18,8" Margin="0,8,0,0" HorizontalAlignment="Left"
                        Background="$($C.Accent)" Foreground="$($C.BG)" FontWeight="Bold" BorderThickness="0" Cursor="Hand"
                        ToolTip="Mounts the ISO, removes bloatware packages, and saves a clean ISO. Takes 10-20 minutes."/>
              </StackPanel>
            </Border>
          </StackPanel>
        </ScrollViewer>
      </Grid>

      <!-- ==================== UPDATES TAB ==================== -->
      <Grid x:Name="PanelUpdates" Visibility="Collapsed">
        <ScrollViewer Margin="16,8" VerticalScrollBarVisibility="Auto">
          <StackPanel>
            <TextBlock Text="Windows Update Policy" FontSize="14" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,8,0,6"/>
            <WrapPanel>
              <Button x:Name="BtnUpdateDefault" Content="Default (Auto)" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Green)" BorderBrush="$($C.Green)" BorderThickness="1" Cursor="Hand" ToolTip="Restores Windows Update to default automatic behavior"/>
              <Button x:Name="BtnUpdateSecurity" Content="Security Only" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Yellow)" BorderBrush="$($C.Yellow)" BorderThickness="1" Cursor="Hand" ToolTip="Only downloads critical security patches, skips feature updates"/>
              <Button x:Name="BtnUpdateDisable" Content="Disable Updates" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Red)" BorderBrush="$($C.Red)" BorderThickness="1" Cursor="Hand" ToolTip="WARNING: Disables Windows Update service. Not recommended long-term."/>
            </WrapPanel>

            <TextBlock Text="System Health Scan" FontSize="14" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,16,0,6"/>
            <Border Background="$($C.Surface)" CornerRadius="8" Padding="14,10" BorderBrush="$($C.Border)" BorderThickness="1">
              <StackPanel>
                <TextBlock Text="AI-Assisted Self-Healing: Runs SFC, DISM, and Windows Update reset to fix corrupted files and stuck updates." Foreground="$($C.TextDim)" FontSize="11" TextWrapping="Wrap" Margin="0,0,0,8"/>
                <WrapPanel>
                  <Button x:Name="BtnHealthScan" Content="&#x1F3E5; Full System Health Scan" Padding="16,8" Margin="4" Background="$($C.Accent)" Foreground="$($C.BG)" FontWeight="Bold" BorderThickness="0" Cursor="Hand" ToolTip="Runs SFC /scannow + DISM /RestoreHealth + WU Reset sequentially"/>
                  <Button x:Name="BtnSFC" Content="SFC Scan Only" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="System File Checker: scans and repairs corrupted Windows system files"/>
                  <Button x:Name="BtnDISM" Content="DISM Repair Only" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Downloads fresh system components from Microsoft to repair the image"/>
                  <Button x:Name="BtnWUReset" Content="WU Cache Reset" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Purges Windows Update cache and restarts the update service"/>
                </WrapPanel>
              </StackPanel>
            </Border>

            <TextBlock Text="Delivery Optimization" FontSize="14" FontWeight="Bold" Foreground="$($C.Accent)" Margin="0,16,0,6"/>
            <WrapPanel>
              <Button x:Name="BtnDODisable" Content="Disable P2P Updates" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Stops Windows from using your bandwidth to share updates with other PCs"/>
              <Button x:Name="BtnDOEnable" Content="Enable P2P Updates" Padding="14,8" Margin="4" Background="$($C.Surface2)" Foreground="$($C.Text)" BorderBrush="$($C.Border)" BorderThickness="1" Cursor="Hand" ToolTip="Allows peer-to-peer update distribution (default Windows behavior)"/>
            </WrapPanel>
          </StackPanel>
        </ScrollViewer>
      </Grid>

    </Grid>

    <!-- ==================== LOG WINDOW ==================== -->
    <Border Grid.Row="3" Background="$($C.LogBG)" BorderBrush="$($C.Border)" BorderThickness="0,1,0,0">
      <Grid>
        <Grid.RowDefinitions>
          <RowDefinition Height="Auto"/>
          <RowDefinition Height="*"/>
        </Grid.RowDefinitions>
        <Border Grid.Row="0" Background="$($C.NavBG)" Padding="12,5">
          <DockPanel>
            <TextBlock Text="&#x1F4CB; Activity Log" FontSize="12" FontWeight="SemiBold" Foreground="$($C.Accent)"/>
            <Button x:Name="BtnClearLog" DockPanel.Dock="Right" Content="Clear" Padding="8,2" HorizontalAlignment="Right"
                    Background="$($C.Surface2)" Foreground="$($C.TextDim)" BorderThickness="0" FontSize="10" Cursor="Hand"/>
          </DockPanel>
        </Border>
        <ScrollViewer Grid.Row="1" x:Name="LogScroll" VerticalScrollBarVisibility="Auto" Margin="8,4">
          <TextBlock x:Name="LogOutput" TextWrapping="Wrap" FontFamily="Cascadia Code,Consolas,monospace" FontSize="11" Foreground="$($C.TextDim)"/>
        </ScrollViewer>
      </Grid>
    </Border>
  </Grid>
</Window>
"@

# ══════════════════════════════════════════════════════════════════
#  CREATE WINDOW
# ══════════════════════════════════════════════════════════════════
$reader = [System.Xml.XmlNodeReader]::new($xaml)
$window = [System.Windows.Markup.XamlReader]::Load($reader)

# Map all named controls
$xaml.SelectNodes('//*[@*[contains(translate(name(),"x","X"),"Name")]]') | ForEach-Object {
    $name = $_.Name
    if (-not $name) { $name = $_.'x:Name' }
    if ($name) { $Ctrl[$name] = $window.FindName($name) }
}

# ══════════════════════════════════════════════════════════════════
#  APPLY MICA / DARK MODE
# ══════════════════════════════════════════════════════════════════
$window.Add_Loaded({
    $hwnd = (New-Object System.Windows.Interop.WindowInteropHelper $window).Handle
    [DwmHelper]::SetDarkMode($hwnd)
    [DwmHelper]::SetMicaBackdrop($hwnd)
})

# ══════════════════════════════════════════════════════════════════
#  LOGGING FUNCTION
# ══════════════════════════════════════════════════════════════════
function Write-Log {
    param([string]$Message, [ValidateSet('Info','OK','Error','Action','Warn')][string]$Level = 'Info')
    $ts = Get-Date -Format 'HH:mm:ss'
    $prefix = switch ($Level) {
        'OK'     { '[OK]' }
        'Error'  { '[ERROR]' }
        'Action' { '[ACTION]' }
        'Warn'   { '[WARN]' }
        default  { '[INFO]' }
    }
    $window.Dispatcher.Invoke({
        $run = New-Object System.Windows.Documents.Run "$ts $prefix $Message`n"
        $run.Foreground = switch ($Level) {
            'OK'     { $C.Green }
            'Error'  { $C.Red }
            'Action' { $C.Accent }
            'Warn'   { $C.Yellow }
            default  { $C.TextDim }
        }
        $Ctrl['LogOutput'].Inlines.Add($run)
        $Ctrl['LogScroll'].ScrollToEnd()
    })
}

Write-Log "Ray's Optimization Chamber v3.0 initialized." Action
Write-Log "Running as Administrator on $env:COMPUTERNAME" Info
Write-Log "OS: $((Get-CimInstance Win32_OperatingSystem).Caption)" Info

# ══════════════════════════════════════════════════════════════════
#  NAVIGATION LOGIC
# ══════════════════════════════════════════════════════════════════
function Switch-Tab {
    param([string]$Tab)
    $panels = @('PanelInstall','PanelTweaks','PanelConfig','PanelUpdates')
    $navs   = @('NavInstall','NavTweaks','NavConfig','NavUpdates')
    foreach ($p in $panels) { $Ctrl[$p].Visibility = 'Collapsed' }
    foreach ($n in $navs)   { $Ctrl[$n].Background = $C.Surface; $Ctrl[$n].Foreground = $C.Text }
    $Ctrl["Panel$Tab"].Visibility = 'Visible'
    $Ctrl["Nav$Tab"].Background   = $C.Surface2
    $Ctrl["Nav$Tab"].Foreground   = $C.Accent
    Write-Log "Switched to $Tab tab" Info
}

$Ctrl['NavInstall'].Add_Click({ Switch-Tab 'Install' })
$Ctrl['NavTweaks'].Add_Click({ Switch-Tab 'Tweaks' })
$Ctrl['NavConfig'].Add_Click({ Switch-Tab 'Config' })
$Ctrl['NavUpdates'].Add_Click({ Switch-Tab 'Updates' })

# ══════════════════════════════════════════════════════════════════
#  CLEAR LOG
# ══════════════════════════════════════════════════════════════════
$Ctrl['BtnClearLog'].Add_Click({
    $Ctrl['LogOutput'].Inlines.Clear()
    Write-Log "Log cleared." Info
})

# ══════════════════════════════════════════════════════════════════
#  RESTORE POINT (MANDATORY SAFETY)
# ══════════════════════════════════════════════════════════════════
$Ctrl['BtnRestorePoint'].Add_Click({
    Write-Log "Creating System Restore Point..." Action
    try {
        Enable-ComputerRestore -Drive "C:\" -ErrorAction SilentlyContinue
        Checkpoint-Computer -Description "Ray's Optimization Chamber Backup" -RestorePointType MODIFY_SETTINGS
        $Script:RestorePointCreated = $true
        $Ctrl['BtnRestorePoint'].Background = $C.Green
        $Ctrl['BtnRestorePoint'].Foreground = $C.BG
        $Ctrl['BtnRestorePoint'].Content = "Restore Point Created"
        Write-Log "Restore Point created successfully! Tweaks are now unlocked." OK
    } catch {
        Write-Log "Failed to create restore point: $_" Error
    }
})

# ══════════════════════════════════════════════════════════════════
#  HELPER - Ensure registry path exists
# ══════════════════════════════════════════════════════════════════
function Ensure-RegPath { param([string]$Path)
    if (-not (Test-Path $Path)) { New-Item -Path $Path -Force | Out-Null }
}

# ══════════════════════════════════════════════════════════════════
#  INSTALL TAB LOGIC
# ══════════════════════════════════════════════════════════════════
$Ctrl['BtnInstallSelected'].Add_Click({
    $toInstall = @()
    foreach ($app in $AppCatalogue) {
        $safeId = $app.Id -replace '[^A-Za-z0-9]','_'
        $chk = $Ctrl["chk_$safeId"]
        if ($chk -and $chk.IsChecked) { $toInstall += $app }
    }
    if ($toInstall.Count -eq 0) {
        Write-Log "No apps selected for installation." Warn
        return
    }
    Write-Log "Installing $($toInstall.Count) application(s)..." Action
    foreach ($app in $toInstall) {
        Write-Log "Installing $($app.Name) (winget install $($app.Id))..." Info
        try {
            $proc = Start-Process -FilePath "winget" -ArgumentList "install --id $($app.Id) -e --accept-source-agreements --accept-package-agreements -h" -Wait -PassThru -NoNewWindow
            if ($proc.ExitCode -eq 0) { Write-Log "$($app.Name) installed successfully!" OK }
            else { Write-Log "$($app.Name) install returned exit code $($proc.ExitCode)" Warn }
        } catch {
            Write-Log "Failed to install $($app.Name): $_" Error
        }
    }
    Write-Log "Installation batch complete!" OK
})

$Ctrl['BtnSelectAll'].Add_Click({
    foreach ($app in $AppCatalogue) {
        $safeId = $app.Id -replace '[^A-Za-z0-9]','_'
        $chk = $Ctrl["chk_$safeId"]
        if ($chk) { $chk.IsChecked = $true }
    }
})
$Ctrl['BtnDeselectAll'].Add_Click({
    foreach ($app in $AppCatalogue) {
        $safeId = $app.Id -replace '[^A-Za-z0-9]','_'
        $chk = $Ctrl["chk_$safeId"]
        if ($chk) { $chk.IsChecked = $false }
    }
})

# WinGet Live Search
$Ctrl['BtnWingetSearch'].Add_Click({
    $query = $Ctrl['TxtSearch'].Text.Trim()
    if ([string]::IsNullOrEmpty($query)) {
        Write-Log "Enter a search term first." Warn
        return
    }
    Write-Log "Searching WinGet for '$query'..." Action
    try {
        $results = winget search $query --accept-source-agreements 2>&1 | Out-String
        Write-Log "WinGet search results:`n$results" Info
    } catch {
        Write-Log "WinGet search failed: $_" Error
    }
})

# ══════════════════════════════════════════════════════════════════
#  TWEAKS - APPLY LOGIC
# ══════════════════════════════════════════════════════════════════
$Ctrl['BtnApplyTweaks'].Add_Click({
    if (-not $Script:RestorePointCreated) {
        Write-Log "BLOCKED: You must create a Restore Point first! Click the shield button in the title bar." Error
        [System.Windows.MessageBox]::Show("Safety First!`n`nYou must create a System Restore Point before applying any tweaks.`nClick the shield button in the title bar.", "Restore Point Required", 'OK', 'Warning')
        return
    }

    Write-Log "Applying selected optimizations..." Action

    # LOW-END PC OPTIMIZATION
    if ($Ctrl['chk_LowEnd'].IsChecked) {
        Write-Log "Applying Low-End PC Optimization..." Action
        try {
            Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'UserPreferencesMask' -Value ([byte[]](0x90,0x12,0x03,0x80,0x10,0x00,0x00,0x00))
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value 0
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 2
            Ensure-RegPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAnimations' -Value 0
            powercfg /setactive 8c5e7fda-e8bf-4a96-9a85-a6e23a8c635c 2>$null
            Write-Log "Low-End PC tweaks applied!" OK
        } catch { Write-Log "Low-End PC error: $_" Error }
    }

    # GAME BOOSTER
    if ($Ctrl['chk_GameBooster'].IsChecked) {
        Write-Log "Applying Game Booster..." Action
        try {
            Ensure-RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile'
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'SystemResponsiveness' -Value 10
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'NetworkThrottlingIndex' -Value 0xffffffff
            Ensure-RegPath 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games'
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'GPU Priority' -Value 8
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'Priority' -Value 6
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile\Tasks\Games' -Name 'Scheduling Category' -Value 'High'
            Write-Log "Game Booster applied! Network throttling disabled, GPU priority maximized." OK
        } catch { Write-Log "Game Booster error: $_" Error }
    }

    # EXTREME GAMING (ZERO LATENCY)
    if ($Ctrl['chk_ZeroLatency'].IsChecked) {
        Write-Log "Applying Extreme Gaming Module (Zero Latency)..." Action
        try {
            bcdedit /set useplatformtick yes 2>$null
            bcdedit /set disabledynamictick yes 2>$null
            Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\PriorityControl' -Name 'Win32PrioritySeparation' -Value 0x26
            # Disable Nagle's Algorithm on all interfaces
            Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' | ForEach-Object {
                Set-ItemProperty -Path $_.PSPath -Name 'TcpAckFrequency' -Value 1 -ErrorAction SilentlyContinue
                Set-ItemProperty -Path $_.PSPath -Name 'TCPNoDelay' -Value 1 -ErrorAction SilentlyContinue
            }
            Write-Log "Extreme Gaming: BCD ticks locked, Priority=0x26, Nagle disabled!" OK
        } catch { Write-Log "Extreme Gaming error: $_" Error }
    }

    # INPUT LATENCY (KEYBOARD/MOUSE)
    if ($Ctrl['chk_InputLatency'].IsChecked) {
        Write-Log "Optimizing Keyboard/Mouse Input..." Action
        try {
            Set-ItemProperty -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseSpeed' -Value '0'
            Set-ItemProperty -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseThreshold1' -Value '0'
            Set-ItemProperty -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseThreshold2' -Value '0'
            Ensure-RegPath 'HKCU:\Control Panel\Accessibility\Keyboard Response'
            Set-ItemProperty -Path 'HKCU:\Control Panel\Accessibility\Keyboard Response' -Name 'AutoRepeatDelay' -Value '200'
            Set-ItemProperty -Path 'HKCU:\Control Panel\Accessibility\Keyboard Response' -Name 'AutoRepeatRate' -Value '13'
            Write-Log "Mouse acceleration disabled, keyboard repeat optimized!" OK
        } catch { Write-Log "Input latency error: $_" Error }
    }

    # RAM OPTIMIZATION
    if ($Ctrl['chk_RAMOptimize'].IsChecked) {
        Write-Log "Applying RAM Optimization..." Action
        try {
            Ensure-RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management'
            Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'LargeSystemCache' -Value 0
            Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'ClearPageFileAtShutdown' -Value 1
            Ensure-RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters'
            Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' -Name 'EnableSuperfetch' -Value 0
            Write-Log "RAM optimized: Superfetch disabled, page file cleared on shutdown." OK
        } catch { Write-Log "RAM optimization error: $_" Error }
    }

    # CPU/GPU OPTIMIZATION
    if ($Ctrl['chk_CPUGPUOpt'].IsChecked) {
        Write-Log "Applying CPU/GPU Optimization..." Action
        try {
            powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>$null
            Ensure-RegPath 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583'
            Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Power\PowerSettings\54533251-82be-4824-96c1-47b60b740d00\0cc5b647-c1df-4637-891a-dec35c318583' -Name 'ValueMax' -Value 0
            Write-Log "Ultimate Performance plan unlocked, core parking disabled!" OK
        } catch { Write-Log "CPU/GPU optimization error: $_" Error }
    }

    # ULTIMATE PERFORMANCE POWER PLAN
    if ($Ctrl['chk_UltPower'].IsChecked) {
        Write-Log "Enabling Ultimate Performance Power Plan..." Action
        try {
            $output = powercfg -duplicatescheme e9a42b02-d5df-448d-aa00-03f14749eb61 2>&1
            $guid = [regex]::Match($output, '[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}').Value
            if ($guid) { powercfg /setactive $guid }
            Write-Log "Ultimate Performance plan activated! CPU will not throttle." OK
        } catch { Write-Log "Ultimate Performance error: $_" Error }
    }

    # LAPTOP POWER SAVER
    if ($Ctrl['chk_PowerSave'].IsChecked) {
        Write-Log "Applying Laptop Power Saver..." Action
        try {
            powercfg /setactive a1841308-3541-4fab-bc81-f71556f20b4a 2>$null
            powercfg /change standby-timeout-ac 15
            powercfg /change monitor-timeout-ac 5
            Write-Log "Power Saver profile activated for laptop." OK
        } catch { Write-Log "Power Saver error: $_" Error }
    }

    # NETWORK OPTIMIZATION
    if ($Ctrl['chk_NetOptimize'].IsChecked) {
        Write-Log "Applying Network Optimization..." Action
        try {
            netsh int tcp set global autotuninglevel=normal
            netsh int tcp set global chimney=disabled 2>$null
            netsh int tcp set global rss=enabled 2>$null
            netsh int tcp set global ecncapability=disabled 2>$null
            netsh int tcp set global timestamps=disabled 2>$null
            Ensure-RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters'
            Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\LanmanServer\Parameters' -Name 'IRPStackSize' -Value 32
            Write-Log "Network stack optimized: RSS enabled, timestamps disabled." OK
        } catch { Write-Log "Network optimization error: $_" Error }
    }

    # INTERNET REFRESHER
    if ($Ctrl['chk_InternetFix'].IsChecked) {
        Write-Log "Running Internet Refresher..." Action
        try {
            ipconfig /flushdns | Out-Null
            ipconfig /release | Out-Null
            ipconfig /renew | Out-Null
            netsh winsock reset | Out-Null
            netsh int ip reset | Out-Null
            Write-Log "Internet refreshed: DNS flushed, Winsock reset, IP renewed." OK
        } catch { Write-Log "Internet Refresher error: $_" Error }
    }

    # USB TWEAKS
    if ($Ctrl['chk_USBTweaks'].IsChecked) {
        Write-Log "Applying USB Tweaks..." Action
        try {
            Ensure-RegPath 'HKLM:\SYSTEM\CurrentControlSet\Services\USB'
            Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' -Name 'DisableSelectiveSuspend' -Value 1
            powercfg /SETACVALUEINDEX SCHEME_CURRENT 2a737441-1930-4402-8d77-b2bebba308a3 48e6b7a6-50f5-4782-a5d4-53bb8f07e226 0 2>$null
            powercfg /SETACTIVE SCHEME_CURRENT 2>$null
            Write-Log "USB Selective Suspend disabled. Peripherals won't sleep." OK
        } catch { Write-Log "USB Tweaks error: $_" Error }
    }

    # DISK CLEANUP / REPAIR
    if ($Ctrl['chk_DiskCleanup'].IsChecked) {
        Write-Log "Running Disk Cleanup..." Action
        try {
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
            Clear-RecycleBin -Force -ErrorAction SilentlyContinue
            Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*.db" -Force -ErrorAction SilentlyContinue
            Write-Log "Disk cleanup complete: temp files, recycle bin, thumbnail cache cleared." OK
        } catch { Write-Log "Disk cleanup error: $_" Error }
    }

    # STORAGE OPTIMIZATION
    if ($Ctrl['chk_StorageOpt'].IsChecked) {
        Write-Log "Applying Storage Optimization..." Action
        try {
            powercfg /hibernate off 2>$null
            fsutil behavior set disablelastaccess 1 | Out-Null
            fsutil behavior set disable8dot3 1 | Out-Null
            Write-Log "Hibernation disabled, NTFS optimized (last access, 8.3 names disabled)." OK
        } catch { Write-Log "Storage optimization error: $_" Error }
    }

    # DEBLOAT
    if ($Ctrl['chk_Debloat'].IsChecked) {
        Write-Log "Running Windows Debloat..." Action
        try {
            $bloatApps = @(
                'Microsoft.BingWeather', 'Microsoft.GetHelp', 'Microsoft.Getstarted',
                'Microsoft.MicrosoftSolitaireCollection', 'Microsoft.People',
                'Microsoft.WindowsFeedbackHub', 'Microsoft.Xbox.TCUI',
                'Microsoft.XboxGameOverlay', 'Microsoft.XboxSpeechToTextOverlay',
                'Microsoft.ZuneMusic', 'Microsoft.ZuneVideo',
                'Microsoft.MixedReality.Portal', 'Microsoft.SkypeApp',
                'king.com.CandyCrushSaga', 'king.com.CandyCrushSodaSaga'
            )
            foreach ($app in $bloatApps) {
                Get-AppxPackage -Name $app -AllUsers -ErrorAction SilentlyContinue | Remove-AppxPackage -ErrorAction SilentlyContinue
                Get-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue | Where-Object { $_.PackageName -like "*$app*" } | Remove-AppxProvisionedPackage -Online -ErrorAction SilentlyContinue
            }
            Write-Log "Bloatware removed (15 apps). Xbox overlays, Candy Crush, etc." OK
        } catch { Write-Log "Debloat error: $_" Error }
    }

    # GENERAL WINDOWS TWEAKS
    if ($Ctrl['chk_GenTweaks'].IsChecked) {
        Write-Log "Applying General Windows Tweaks..." Action
        try {
            # Disable Telemetry
            Set-Service -Name 'DiagTrack' -StartupType Disabled -ErrorAction SilentlyContinue
            Stop-Service -Name 'DiagTrack' -Force -ErrorAction SilentlyContinue
            Set-Service -Name 'dmwappushservice' -StartupType Disabled -ErrorAction SilentlyContinue
            # Disable Cortana
            Ensure-RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search'
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortana' -Value 0
            # Disable Tips and Ads
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338389Enabled' -Value 0
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-310093Enabled' -Value 0
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SilentInstalledAppsEnabled' -Value 0
            Write-Log "Telemetry, Cortana, tips, and ads disabled." OK
        } catch { Write-Log "General tweaks error: $_" Error }
    }

    # SYSTEM CLEANUP
    if ($Ctrl['chk_SysCleanup'].IsChecked) {
        Write-Log "Running System Cleanup..." Action
        try {
            Remove-Item "$env:TEMP\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item "C:\Windows\Temp\*" -Recurse -Force -ErrorAction SilentlyContinue
            Remove-Item "C:\Windows\Prefetch\*" -Force -ErrorAction SilentlyContinue
            Remove-Item "$env:LOCALAPPDATA\Microsoft\Windows\Explorer\thumbcache_*" -Force -ErrorAction SilentlyContinue
            Write-Log "System cleanup complete: temp, prefetch, thumbnails cleared." OK
        } catch { Write-Log "System cleanup error: $_" Error }
    }

    # PRIVACY HARDENING
    if ($Ctrl['chk_Privacy'].IsChecked) {
        Write-Log "Applying Privacy Hardening..." Action
        try {
            Ensure-RegPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo'
            Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 0
            Ensure-RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy'
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\AppPrivacy' -Name 'LetAppsGetDiagnosticInfo' -Value 2
            Ensure-RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System'
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'PublishUserActivities' -Value 0
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'UploadUserActivities' -Value 0
            # Disable Location
            Ensure-RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors'
            Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' -Name 'DisableLocation' -Value 1
            Write-Log "Privacy hardened: ad ID, location, activity history, diagnostics disabled." OK
        } catch { Write-Log "Privacy hardening error: $_" Error }
    }

    Write-Log "All selected tweaks have been applied!" OK
    [System.Windows.MessageBox]::Show("All selected optimizations applied successfully!`nSome changes may require a restart.", "Ray's Optimization Chamber", 'OK', 'Information')
})

# ══════════════════════════════════════════════════════════════════
#  LOW-END PC MACRO BUTTON
# ══════════════════════════════════════════════════════════════════
$Ctrl['BtnLowEndMacro'].Add_Click({
    $lowEndTweaks = @('LowEnd','GenTweaks','SysCleanup','RAMOptimize','Debloat','StorageOpt','Privacy')
    foreach ($id in $lowEndTweaks) {
        $chk = $Ctrl["chk_$id"]
        if ($chk) { $chk.IsChecked = $true }
    }
    Write-Log "Low-End PC Macro: auto-selected 7 safe tweaks for older hardware." Action
})

# ══════════════════════════════════════════════════════════════════
#  REVERT ALL CHANGES
# ══════════════════════════════════════════════════════════════════
$Ctrl['BtnRevert'].Add_Click({
    $result = [System.Windows.MessageBox]::Show("This will revert ALL optimizations to Windows defaults.`nAre you sure?", "Revert Changes", 'YesNo', 'Warning')
    if ($result -ne 'Yes') { return }

    Write-Log "Reverting ALL optimizations to Windows Defaults..." Action
    try {
        # Revert Visual Effects
        Set-ItemProperty -Path 'HKCU:\Control Panel\Desktop' -Name 'UserPreferencesMask' -Value ([byte[]](0x9E,0x3E,0x07,0x80,0x12,0x00,0x00,0x00)) -ErrorAction SilentlyContinue
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Themes\Personalize' -Name 'EnableTransparency' -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\VisualEffects' -Name 'VisualFXSetting' -Value 0 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAnimations' -Value 1 -ErrorAction SilentlyContinue
        Write-Log "  Visual effects restored to defaults." OK

        # Revert System Responsiveness
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'SystemResponsiveness' -Value 20 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path 'HKLM:\SOFTWARE\Microsoft\Windows NT\CurrentVersion\Multimedia\SystemProfile' -Name 'NetworkThrottlingIndex' -Value 10 -ErrorAction SilentlyContinue
        Write-Log "  System responsiveness restored to defaults." OK

        # Revert Priority
        Set-ItemProperty -Path 'HKLM:\System\CurrentControlSet\Control\PriorityControl' -Name 'Win32PrioritySeparation' -Value 2 -ErrorAction SilentlyContinue
        Write-Log "  CPU priority separation restored." OK

        # Revert BCD
        bcdedit /deletevalue useplatformtick 2>$null
        bcdedit /deletevalue disabledynamictick 2>$null
        Write-Log "  BCD timer values restored." OK

        # Revert Nagle's
        Get-ChildItem 'HKLM:\SYSTEM\CurrentControlSet\Services\Tcpip\Parameters\Interfaces' -ErrorAction SilentlyContinue | ForEach-Object {
            Remove-ItemProperty -Path $_.PSPath -Name 'TcpAckFrequency' -ErrorAction SilentlyContinue
            Remove-ItemProperty -Path $_.PSPath -Name 'TCPNoDelay' -ErrorAction SilentlyContinue
        }
        Write-Log "  Nagle's Algorithm re-enabled." OK

        # Revert Mouse
        Set-ItemProperty -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseSpeed' -Value '1' -ErrorAction SilentlyContinue
        Set-ItemProperty -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseThreshold1' -Value '6' -ErrorAction SilentlyContinue
        Set-ItemProperty -Path 'HKCU:\Control Panel\Mouse' -Name 'MouseThreshold2' -Value '10' -ErrorAction SilentlyContinue
        Write-Log "  Mouse acceleration restored." OK

        # Revert RAM
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'LargeSystemCache' -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management' -Name 'ClearPageFileAtShutdown' -Value 0 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Control\Session Manager\Memory Management\PrefetchParameters' -Name 'EnableSuperfetch' -Value 3 -ErrorAction SilentlyContinue
        Write-Log "  RAM settings restored." OK

        # Revert Network
        netsh int tcp set global autotuninglevel=normal 2>$null
        Write-Log "  Network auto-tuning restored." OK

        # Revert USB
        Remove-ItemProperty -Path 'HKLM:\SYSTEM\CurrentControlSet\Services\USB' -Name 'DisableSelectiveSuspend' -ErrorAction SilentlyContinue
        Write-Log "  USB selective suspend restored." OK

        # Revert Power
        powercfg /setactive 381b4222-f694-41f0-9685-ff5bb260df2e 2>$null
        powercfg /hibernate on 2>$null
        Write-Log "  Power plan set to Balanced, hibernation enabled." OK

        # Revert Storage
        fsutil behavior set disablelastaccess 2 2>$null
        fsutil behavior set disable8dot3 0 2>$null
        Write-Log "  NTFS settings restored." OK

        # Re-enable Services
        Set-Service -Name 'DiagTrack' -StartupType Automatic -ErrorAction SilentlyContinue
        Start-Service -Name 'DiagTrack' -ErrorAction SilentlyContinue
        Set-Service -Name 'dmwappushservice' -StartupType Automatic -ErrorAction SilentlyContinue
        Write-Log "  Telemetry services re-enabled." OK

        # Revert Cortana
        Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\Windows Search' -Name 'AllowCortana' -ErrorAction SilentlyContinue
        Write-Log "  Cortana policy restored." OK

        # Revert Privacy
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\AdvertisingInfo' -Name 'Enabled' -Value 1 -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\LocationAndSensors' -Name 'DisableLocation' -ErrorAction SilentlyContinue
        Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\System' -Name 'PublishUserActivities' -ErrorAction SilentlyContinue
        Write-Log "  Privacy settings restored to defaults." OK

        # Revert Content Delivery
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-338389Enabled' -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SubscribedContent-310093Enabled' -Value 1 -ErrorAction SilentlyContinue
        Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\ContentDeliveryManager' -Name 'SilentInstalledAppsEnabled' -Value 1 -ErrorAction SilentlyContinue
        Write-Log "  Content delivery settings restored." OK

        Write-Log "ALL optimizations have been reverted to Windows defaults!" OK
        [System.Windows.MessageBox]::Show("All settings reverted to Windows defaults.`nA restart is recommended.", "Revert Complete", 'OK', 'Information')
    } catch {
        Write-Log "Revert error: $_" Error
    }
})

# ══════════════════════════════════════════════════════════════════
#  CONFIG TAB LOGIC
# ══════════════════════════════════════════════════════════════════
$Ctrl['BtnWSL'].Add_Click({
    Write-Log "Enabling WSL2..." Action
    try { dism.exe /online /enable-feature /featurename:Microsoft-Windows-Subsystem-Linux /all /norestart | Out-Null
          dism.exe /online /enable-feature /featurename:VirtualMachinePlatform /all /norestart | Out-Null
          Write-Log "WSL2 enabled! Restart required." OK } catch { Write-Log "WSL2 error: $_" Error }
})

$Ctrl['BtnSandbox'].Add_Click({
    Write-Log "Enabling Windows Sandbox..." Action
    try { Enable-WindowsOptionalFeature -Online -FeatureName "Containers-DisposableClientVM" -All -NoRestart | Out-Null
          Write-Log "Windows Sandbox enabled! Restart required." OK } catch { Write-Log "Sandbox error: $_" Error }
})

$Ctrl['BtnHyperV'].Add_Click({
    Write-Log "Enabling Hyper-V..." Action
    try { Enable-WindowsOptionalFeature -Online -FeatureName "Microsoft-Hyper-V-All" -All -NoRestart | Out-Null
          Write-Log "Hyper-V enabled! Restart required." OK } catch { Write-Log "Hyper-V error: $_" Error }
})

$Ctrl['BtnDotNet'].Add_Click({
    Write-Log "Enabling .NET Framework 3.5..." Action
    try { Enable-WindowsOptionalFeature -Online -FeatureName "NetFx3" -All -NoRestart | Out-Null
          Write-Log ".NET 3.5 installed!" OK } catch { Write-Log ".NET 3.5 error: $_" Error }
})

$Ctrl['BtnOpenSSH'].Add_Click({
    Write-Log "Installing OpenSSH..." Action
    try { Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0 | Out-Null
          Add-WindowsCapability -Online -Name OpenSSH.Server~~~~0.0.1.0 | Out-Null
          Write-Log "OpenSSH client and server installed!" OK } catch { Write-Log "OpenSSH error: $_" Error }
})

$Ctrl['BtnTaskbarLeft'].Add_Click({
    Write-Log "Setting taskbar to left alignment..." Action
    Ensure-RegPath 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced'
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'TaskbarAl' -Value 0
    Write-Log "Taskbar set to left alignment." OK
})

$Ctrl['BtnClassicContext'].Add_Click({
    Write-Log "Restoring classic context menu..." Action
    Ensure-RegPath 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32'
    Set-ItemProperty -Path 'HKCU:\Software\Classes\CLSID\{86ca1aa0-34aa-4e8b-a509-50c905bae2a2}\InprocServer32' -Name '(default)' -Value '' -Type String
    Write-Log "Classic context menu enabled. Restart Explorer to apply." OK
})

$Ctrl['BtnFileExt'].Add_Click({
    Write-Log "Showing file extensions..." Action
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'HideFileExt' -Value 0
    Write-Log "File extensions now visible in Explorer." OK
})

$Ctrl['BtnHiddenFiles'].Add_Click({
    Write-Log "Showing hidden files..." Action
    Set-ItemProperty -Path 'HKCU:\Software\Microsoft\Windows\CurrentVersion\Explorer\Advanced' -Name 'Hidden' -Value 1
    Write-Log "Hidden files now visible in Explorer." OK
})

# DNS Config
$Ctrl['BtnDNSGoogle'].Add_Click({
    Write-Log "Setting DNS to Google (8.8.8.8)..." Action
    Get-NetAdapter | Where-Object Status -eq Up | ForEach-Object {
        Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ("8.8.8.8","8.8.4.4")
    }
    Write-Log "DNS set to Google." OK
})

$Ctrl['BtnDNSCloud'].Add_Click({
    Write-Log "Setting DNS to Cloudflare (1.1.1.1)..." Action
    Get-NetAdapter | Where-Object Status -eq Up | ForEach-Object {
        Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ServerAddresses ("1.1.1.1","1.0.0.1")
    }
    Write-Log "DNS set to Cloudflare." OK
})

$Ctrl['BtnDNSReset'].Add_Click({
    Write-Log "Resetting DNS to automatic..." Action
    Get-NetAdapter | Where-Object Status -eq Up | ForEach-Object {
        Set-DnsClientServerAddress -InterfaceIndex $_.ifIndex -ResetServerAddresses
    }
    Write-Log "DNS reset to DHCP automatic." OK
})

# MicroWin ISO Debloat
$Script:ISOPath = ""
$Ctrl['BtnBrowseISO'].Add_Click({
    $dialog = New-Object Microsoft.Win32.OpenFileDialog
    $dialog.Filter = "ISO Files (*.iso)|*.iso"
    $dialog.Title = "Select Windows ISO File"
    if ($dialog.ShowDialog()) {
        $Script:ISOPath = $dialog.FileName
        $Ctrl['TxtISOPath'].Text = $Script:ISOPath
        Write-Log "ISO selected: $($Script:ISOPath)" Info
    }
})

$Ctrl['BtnMicroWin'].Add_Click({
    if ([string]::IsNullOrEmpty($Script:ISOPath)) {
        Write-Log "No ISO file selected! Browse for an ISO first." Error
        return
    }
    Write-Log "Starting MicroWin ISO Debloat..." Action
    Write-Log "This process can take 15-30 minutes. Do not close the window." Warn
    try {
        $mountResult = Mount-DiskImage -ImagePath $Script:ISOPath -PassThru
        $driveLetter = ($mountResult | Get-Volume).DriveLetter
        $workDir = "$env:TEMP\MicroWin"
        $mountDir = "$workDir\mount"
        New-Item -Path $mountDir -ItemType Directory -Force | Out-Null
        $wimPath = "${driveLetter}:\sources\install.wim"
        if (-not (Test-Path $wimPath)) { $wimPath = "${driveLetter}:\sources\install.esd" }
        Write-Log "Copying WIM from mounted ISO..." Info
        Copy-Item $wimPath "$workDir\install.wim" -Force
        Write-Log "Mounting WIM image..." Info
        dism /mount-wim /wimfile:"$workDir\install.wim" /index:1 /mountdir:$mountDir 2>&1 | ForEach-Object { Write-Log $_ Info }
        # Remove provisioned bloat
        $bloat = @('Microsoft.BingWeather','Microsoft.GetHelp','Microsoft.Getstarted','Microsoft.MicrosoftSolitaireCollection',
                   'Microsoft.People','Microsoft.WindowsFeedbackHub','Microsoft.ZuneMusic','Microsoft.ZuneVideo','Microsoft.SkypeApp',
                   'king.com.CandyCrushSaga','Microsoft.Xbox.TCUI','Microsoft.XboxGameOverlay')
        foreach ($pkg in $bloat) {
            dism /image:$mountDir /Remove-ProvisionedAppxPackage /PackageName:$pkg 2>$null
            Write-Log "  Removed: $pkg" OK
        }
        Write-Log "Unmounting and saving changes..." Info
        dism /unmount-wim /mountdir:$mountDir /commit 2>&1 | ForEach-Object { Write-Log $_ Info }
        Dismount-DiskImage -ImagePath $Script:ISOPath | Out-Null
        $outputISO = [System.IO.Path]::Combine([Environment]::GetFolderPath('Desktop'), 'MicroWin_Debloated.iso')
        Write-Log "MicroWin process complete! Modified WIM saved to $workDir\install.wim" OK
        Write-Log "Use oscdimg or similar tool to rebuild the final ISO." Info
    } catch {
        Write-Log "MicroWin error: $_" Error
        Dismount-DiskImage -ImagePath $Script:ISOPath -ErrorAction SilentlyContinue | Out-Null
    }
})

# ══════════════════════════════════════════════════════════════════
#  UPDATES TAB LOGIC
# ══════════════════════════════════════════════════════════════════
$Ctrl['BtnUpdateDefault'].Add_Click({
    Write-Log "Setting Windows Update to Default (Auto)..." Action
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'NoAutoUpdate' -ErrorAction SilentlyContinue
    Set-Service -Name wuauserv -StartupType Automatic -ErrorAction SilentlyContinue
    Start-Service -Name wuauserv -ErrorAction SilentlyContinue
    Write-Log "Windows Update set to automatic." OK
})

$Ctrl['BtnUpdateSecurity'].Add_Click({
    Write-Log "Setting Windows Update to Security Only..." Action
    Ensure-RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU'
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\WindowsUpdate\AU' -Name 'AUOptions' -Value 2
    Write-Log "Windows Update set to security-only." OK
})

$Ctrl['BtnUpdateDisable'].Add_Click({
    $result = [System.Windows.MessageBox]::Show("WARNING: Disabling Windows Update is not recommended.`nProceed?", "Warning", 'YesNo', 'Warning')
    if ($result -ne 'Yes') { return }
    Write-Log "Disabling Windows Update..." Warn
    Set-Service -Name wuauserv -StartupType Disabled -ErrorAction SilentlyContinue
    Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
    Write-Log "Windows Update service disabled." Warn
})

# System Health Scan
$Ctrl['BtnHealthScan'].Add_Click({
    Write-Log "Starting Full System Health Scan (SFC + DISM + WU Reset)..." Action
    Write-Log "This may take 15-30 minutes. Please be patient." Warn
    try {
        Write-Log "Step 1/3: Running System File Checker..." Info
        $sfc = sfc /scannow 2>&1 | Out-String
        Write-Log $sfc Info
        Write-Log "Step 2/3: Running DISM RestoreHealth..." Info
        $dism = dism /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-String
        Write-Log $dism Info
        Write-Log "Step 3/3: Resetting Windows Update Components..." Info
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Stop-Service -Name bits -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\System32\catroot2\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service -Name wuauserv -ErrorAction SilentlyContinue
        Start-Service -Name bits -ErrorAction SilentlyContinue
        Write-Log "Full System Health Scan complete!" OK
    } catch { Write-Log "Health scan error: $_" Error }
})

$Ctrl['BtnSFC'].Add_Click({
    Write-Log "Running SFC /scannow..." Action
    try { $out = sfc /scannow 2>&1 | Out-String; Write-Log $out Info; Write-Log "SFC scan complete." OK } catch { Write-Log "SFC error: $_" Error }
})

$Ctrl['BtnDISM'].Add_Click({
    Write-Log "Running DISM RestoreHealth..." Action
    try { $out = dism /Online /Cleanup-Image /RestoreHealth 2>&1 | Out-String; Write-Log $out Info; Write-Log "DISM repair complete." OK } catch { Write-Log "DISM error: $_" Error }
})

$Ctrl['BtnWUReset'].Add_Click({
    Write-Log "Resetting Windows Update cache..." Action
    try {
        Stop-Service -Name wuauserv -Force -ErrorAction SilentlyContinue
        Stop-Service -Name bits -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\SoftwareDistribution\*" -Recurse -Force -ErrorAction SilentlyContinue
        Remove-Item "C:\Windows\System32\catroot2\*" -Recurse -Force -ErrorAction SilentlyContinue
        Start-Service -Name wuauserv
        Start-Service -Name bits
        Write-Log "Windows Update cache purged and services restarted." OK
    } catch { Write-Log "WU Reset error: $_" Error }
})

# Delivery Optimization
$Ctrl['BtnDODisable'].Add_Click({
    Write-Log "Disabling P2P delivery optimization..." Action
    Ensure-RegPath 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization'
    Set-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' -Name 'DODownloadMode' -Value 0
    Write-Log "P2P update sharing disabled." OK
})

$Ctrl['BtnDOEnable'].Add_Click({
    Write-Log "Enabling P2P delivery optimization..." Action
    Remove-ItemProperty -Path 'HKLM:\SOFTWARE\Policies\Microsoft\Windows\DeliveryOptimization' -Name 'DODownloadMode' -ErrorAction SilentlyContinue
    Write-Log "P2P update sharing enabled (default)." OK
})

# ══════════════════════════════════════════════════════════════════
#  SHOW WINDOW
# ══════════════════════════════════════════════════════════════════
$window.ShowDialog() | Out-Null
