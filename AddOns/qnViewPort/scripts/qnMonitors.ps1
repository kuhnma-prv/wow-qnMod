#Requires -Version 7
# Shared helpers for Initialize-WowMonitors.ps1 and Set-WowWindow.ps1 (dot-source this file).
# All coordinates are physical pixels (PER_MONITOR_AWARE_V2), origin = top left of the Windows primary monitor.

if (-not ('QnTools.Monitors' -as [type])) {
    Add-Type -TypeDefinition @'
using System;
using System.Collections.Generic;
using System.Runtime.InteropServices;

namespace QnTools {
    public class Monitor {
        public string Device;      // \\.\DISPLAY1
        public string Name;        // adapter/monitor description from EnumDisplayDevices
        public int X, Y, Width, Height;
        public int WorkX, WorkY, WorkWidth, WorkHeight;
        public bool Primary;
        public int Dpi;
    }

    public static class Monitors {
        [StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
        [StructLayout(LayoutKind.Sequential)] public struct POINT { public int X, Y; }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        struct MONITORINFOEX {
            public int cbSize; public RECT rcMonitor; public RECT rcWork; public uint dwFlags;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string szDevice;
        }

        [StructLayout(LayoutKind.Sequential, CharSet = CharSet.Unicode)]
        struct DISPLAY_DEVICE {
            public int cb;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 32)] public string DeviceName;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceString;
            public int StateFlags;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceID;
            [MarshalAs(UnmanagedType.ByValTStr, SizeConst = 128)] public string DeviceKey;
        }

        delegate bool EnumProc(IntPtr hMon, IntPtr hdc, ref RECT rc, IntPtr data);

        [DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr ctx);
        [DllImport("user32.dll")] static extern bool EnumDisplayMonitors(IntPtr hdc, IntPtr clip, EnumProc proc, IntPtr data);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern bool GetMonitorInfo(IntPtr hMon, ref MONITORINFOEX info);
        [DllImport("user32.dll", CharSet = CharSet.Unicode)] static extern bool EnumDisplayDevices(string device, uint index, ref DISPLAY_DEVICE dd, uint flags);
        [DllImport("shcore.dll")] static extern int GetDpiForMonitor(IntPtr hMon, int type, out uint dpiX, out uint dpiY);

        [DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr hWnd, out RECT rect);
        [DllImport("user32.dll")] public static extern bool GetClientRect(IntPtr hWnd, out RECT rect);
        [DllImport("user32.dll")] public static extern bool ClientToScreen(IntPtr hWnd, ref POINT p);
        [DllImport("user32.dll", EntryPoint = "GetWindowLongPtrW")] public static extern IntPtr GetWindowLongPtr(IntPtr hWnd, int index);
        [DllImport("user32.dll", EntryPoint = "SetWindowLongPtrW")] public static extern IntPtr SetWindowLongPtr(IntPtr hWnd, int index, IntPtr value);
        [DllImport("user32.dll")] public static extern bool SetWindowPos(IntPtr hWnd, IntPtr after, int x, int y, int cx, int cy, uint flags);

        public static void DpiAware() {
            SetThreadDpiAwarenessContext(new IntPtr(-4));   // PER_MONITOR_AWARE_V2
        }

        public static List<Monitor> Get() {
            DpiAware();
            var list = new List<Monitor>();
            EnumDisplayMonitors(IntPtr.Zero, IntPtr.Zero, (IntPtr h, IntPtr hdc, ref RECT rc, IntPtr d) => {
                var mi = new MONITORINFOEX();
                mi.cbSize = Marshal.SizeOf(typeof(MONITORINFOEX));
                if (!GetMonitorInfo(h, ref mi)) return true;
                var m = new Monitor {
                    Device = mi.szDevice,
                    X = mi.rcMonitor.Left, Y = mi.rcMonitor.Top,
                    Width = mi.rcMonitor.Right - mi.rcMonitor.Left, Height = mi.rcMonitor.Bottom - mi.rcMonitor.Top,
                    WorkX = mi.rcWork.Left, WorkY = mi.rcWork.Top,
                    WorkWidth = mi.rcWork.Right - mi.rcWork.Left, WorkHeight = mi.rcWork.Bottom - mi.rcWork.Top,
                    Primary = (mi.dwFlags & 1) != 0,
                };
                var dd = new DISPLAY_DEVICE();
                dd.cb = Marshal.SizeOf(typeof(DISPLAY_DEVICE));
                m.Name = EnumDisplayDevices(mi.szDevice, 0, ref dd, 0) ? dd.DeviceString : "";
                uint dx, dy;
                try { m.Dpi = GetDpiForMonitor(h, 0, out dx, out dy) == 0 ? (int)dx : 96; } catch { m.Dpi = 96; }
                list.Add(m);
                return true;
            }, IntPtr.Zero);
            return list;
        }
    }
}
'@
}

# All monitors, sorted left to right, then top to bottom, numbered from 1.
function Get-QnMonitors {
    $i = 0
    [QnTools.Monitors]::Get() | Sort-Object X, Y | ForEach-Object {
        $i++
        [pscustomobject]@{
            Index = $i; Device = $_.Device; Name = $_.Name
            X = $_.X; Y = $_.Y; Width = $_.Width; Height = $_.Height
            Primary = $_.Primary; Scale = [int][math]::Round($_.Dpi / 96 * 100)
        }
    }
}

# Bounding rectangle of the given monitors.
function Get-QnUnion($Monitors) {
    $l = ($Monitors | Measure-Object X -Minimum).Minimum
    $t = ($Monitors | Measure-Object Y -Minimum).Minimum
    $r = ($Monitors | ForEach-Object { $_.X + $_.Width } | Measure-Object -Maximum).Maximum
    $b = ($Monitors | ForEach-Object { $_.Y + $_.Height } | Measure-Object -Maximum).Maximum
    [pscustomobject]@{ X = [int]$l; Y = [int]$t; Width = [int]($r - $l); Height = [int]($b - $t) }
}

# Intersection of two rectangles, $null if empty.
function Get-QnIntersect($A, $B) {
    $l = [math]::Max($A.X, $B.X); $t = [math]::Max($A.Y, $B.Y)
    $r = [math]::Min($A.X + $A.Width, $B.X + $B.Width); $b = [math]::Min($A.Y + $A.Height, $B.Y + $B.Height)
    if ($r -le $l -or $b -le $t) { return $null }
    [pscustomobject]@{ X = $l; Y = $t; Width = $r - $l; Height = $b - $t }
}

# Parts of $Rect that are not shown on any of $Monitors (grid decomposition, rows merged).
function Get-QnHidden($Rect, $Monitors) {
    $xs = [Collections.Generic.SortedSet[int]]::new()
    $ys = [Collections.Generic.SortedSet[int]]::new()
    foreach ($v in $Rect.X, ($Rect.X + $Rect.Width)) { [void]$xs.Add($v) }
    foreach ($v in $Rect.Y, ($Rect.Y + $Rect.Height)) { [void]$ys.Add($v) }
    foreach ($m in $Monitors) {
        foreach ($v in $m.X, ($m.X + $m.Width)) { if ($v -gt $Rect.X -and $v -lt $Rect.X + $Rect.Width) { [void]$xs.Add($v) } }
        foreach ($v in $m.Y, ($m.Y + $m.Height)) { if ($v -gt $Rect.Y -and $v -lt $Rect.Y + $Rect.Height) { [void]$ys.Add($v) } }
    }
    $xa = @($xs); $ya = @($ys)
    $out = [Collections.Generic.List[object]]::new()
    for ($j = 0; $j -lt $ya.Count - 1; $j++) {
        $run = $null
        for ($i = 0; $i -lt $xa.Count - 1; $i++) {
            $cx = ($xa[$i] + $xa[$i + 1]) / 2; $cy = ($ya[$j] + $ya[$j + 1]) / 2
            $shown = $Monitors | Where-Object { $cx -gt $_.X -and $cx -lt $_.X + $_.Width -and $cy -gt $_.Y -and $cy -lt $_.Y + $_.Height }
            if (-not $shown) {
                if ($run) { $run.Width = $xa[$i + 1] - $run.X }
                else { $run = [pscustomobject]@{ X = $xa[$i]; Y = $ya[$j]; Width = $xa[$i + 1] - $xa[$i]; Height = $ya[$j + 1] - $ya[$j] } }
            } elseif ($run) { $out.Add($run); $run = $null }
        }
        if ($run) { $out.Add($run) }
    }
    # merge vertically adjacent strips with identical x range
    $merged = [Collections.Generic.List[object]]::new()
    foreach ($h in $out) {
        $prev = $merged | Where-Object { $_.X -eq $h.X -and $_.Width -eq $h.Width -and $_.Y + $_.Height -eq $h.Y } | Select-Object -First 1
        if ($prev) { $prev.Height += $h.Height } else { $merged.Add($h) }
    }
    $merged
}

function Format-QnRect($R) { '{0},{1} {2}x{3}' -f $R.X, $R.Y, $R.Width, $R.Height }

# Writes qnViewPort\Monitors.lua. $Client = client area of the WoW window (desktop pixels).
# Every monitor that shows part of the window is written (clipped, relative to the window),
# not only the selected ones: a monitor between two selected ones shows its part too.
# Returns $true if the file content changed.
function Write-QnMonitorLua([string]$Path, $Client, $AllMonitors, [string[]]$SelectedDevices, [string]$MainDevice) {
    $lines =[Collections.Generic.List[string]]::new()
    $lines.Add('-- Generated by qnViewPort\scripts (Initialize-WowMonitors.ps1 / Set-WowWindow.ps1). Do not edit by hand.')
    $lines.Add('-- Pixel rectangles relative to the top left corner of the WoW window (client area).')
    $lines.Add('qnViewPortMonitors = {')
    $lines.Add(('	window = {{ x = {0}, y = {1}, width = {2}, height = {3} }},' -f $Client.X, $Client.Y, $Client.Width, $Client.Height))
    $lines.Add('	monitors = {')
    foreach ($m in $AllMonitors) {
        $c = Get-QnIntersect $Client $m
        if (-not $c) { continue }
        $name = ($m.Name -replace '[\\"]', '')
        $lines.Add(('		{{ device = "{0}", name = "{1}", x = {2}, y = {3}, width = {4}, height = {5}, fullWidth = {6}, fullHeight = {7}, selected = {8}, main = {9}, primary = {10} }},' -f
            ($m.Device -replace '\\', '\\'), $name, ($c.X - $Client.X), ($c.Y - $Client.Y), $c.Width, $c.Height, $m.Width, $m.Height,
            ($SelectedDevices -contains $m.Device).ToString().ToLower(), ($m.Device -eq $MainDevice).ToString().ToLower(), $m.Primary.ToString().ToLower()))
    }
    $lines.Add('	},')
    $lines.Add('}')
    # CRLF like a git checkout (core.autocrlf), otherwise git reports the file as changed after every run
    $text = ($lines -join "`r`n") + "`r`n"
    $old = if (Test-Path $Path) { [IO.File]::ReadAllText($Path) } else { '' }
    if ($old -ne $text) {
        [IO.File]::WriteAllText($Path, $text, [Text.UTF8Encoding]::new($false))
        return $true
    }
    $false
}

# Does the folder contain WoW clients (_retail_, _classic_beta_ … with an Interface folder)?
function Test-QnWowRoot([string]$Path) {
    if (-not $Path -or -not (Test-Path $Path)) { return $false }
    [bool](Get-ChildItem $Path -Directory -Filter '_*_' -ErrorAction SilentlyContinue |
        Where-Object { Test-Path (Join-Path $_.FullName 'Interface') })
}

# WoW root folder, $null if not found:
#   1. environment variable QN_WOW_ROOT
#   2. five levels above the scripts (installed addon: <root>\<client>\Interface\AddOns\qnViewPort\scripts);
#      not when the AddOns folder is a junction to a repository - then the scripts live there
#   3. folder of a running WoW client (<root>\<client>\Wow*.exe)
function Get-QnWowRoot {
    if (Test-QnWowRoot $env:QN_WOW_ROOT) { return $env:QN_WOW_ROOT }
    $up = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\..'))
    if (Test-QnWowRoot $up) { return $up }
    $exe = Get-Process -Name 'Wow*' -ErrorAction SilentlyContinue | Where-Object Path |
        Select-Object -First 1 -ExpandProperty Path
    if ($exe) {
        $root = Split-Path (Split-Path $exe -Parent) -Parent
        if (Test-QnWowRoot $root) { return $root }
    }
    $null
}

# qnViewPort folders of all installed clients below the WoW root.
function Get-QnViewPortFolders([string]$WowRoot) {
    Get-ChildItem $WowRoot -Directory -Filter '_*_' -ErrorAction SilentlyContinue |
        ForEach-Object { Join-Path $_.FullName 'Interface\AddOns\qnViewPort' } |
        Where-Object { Test-Path (Join-Path $_ 'qnViewPort.toc') }
}
