#Requires -Version 7
# Prints position, size and border state of the WoW window (read-only).
param([string]$ProcessName = 'WowB')
Add-Type -Namespace W2 -Name N -MemberDefinition @'
[DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr c);
[DllImport("user32.dll")] public static extern bool GetWindowRect(IntPtr h, out RECT r);
[DllImport("user32.dll", EntryPoint = "GetWindowLongPtrW")] public static extern IntPtr GetWindowLongPtr(IntPtr h, int i);
[StructLayout(LayoutKind.Sequential)] public struct RECT { public int Left, Top, Right, Bottom; }
'@
[void][W2.N]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))
$p = Get-Process $ProcessName -ErrorAction Stop | Where-Object MainWindowHandle -ne 0 | Select-Object -First 1
$r = New-Object W2.N+RECT
[void][W2.N]::GetWindowRect($p.MainWindowHandle, [ref]$r)
$style = [W2.N]::GetWindowLongPtr($p.MainWindowHandle, -16).ToInt64()
"{0},{1} {2}x{3} caption={4}" -f $r.Left, $r.Top, ($r.Right - $r.Left), ($r.Bottom - $r.Top), [bool]($style -band 0x00C00000)
