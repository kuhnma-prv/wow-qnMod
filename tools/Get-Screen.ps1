#Requires -Version 7
# Screenshot of all monitors (physical pixels), saved at half size next to this script.
param([string]$Out = (Join-Path $PSScriptRoot 'screen.png'), [double]$Scale = 0.5)
Add-Type -AssemblyName System.Drawing, System.Windows.Forms
Add-Type -Namespace W -Name N -MemberDefinition '[DllImport("user32.dll")] public static extern IntPtr SetThreadDpiAwarenessContext(IntPtr c);'
[void][W.N]::SetThreadDpiAwarenessContext([IntPtr]::new(-4))
$r = [System.Windows.Forms.SystemInformation]::VirtualScreen
$bmp = [System.Drawing.Bitmap]::new($r.Width, $r.Height)
$g = [System.Drawing.Graphics]::FromImage($bmp)
$g.CopyFromScreen($r.Left, $r.Top, 0, 0, $bmp.Size)
$small = [System.Drawing.Bitmap]::new($bmp, [int]($r.Width * $Scale), [int]($r.Height * $Scale))
$small.Save($Out, [System.Drawing.Imaging.ImageFormat]::Png)
"{0},{1} {2}x{3} -> {4}" -f $r.Left, $r.Top, $r.Width, $r.Height, $Out
