#Requires -Version 7
<#
.SYNOPSIS
    Puts the WoW window over the monitors selected with Initialize-WowMonitors.ps1 (monitors.json in
    the WoW root folder, shared by all clients) and optionally removes the window border (like "Borderless Gaming").
    Afterwards qnViewPort\Monitors.lua of the running client is updated with the exact client area.

.EXAMPLE
    ./Set-WowWindow.ps1                          # WoW Beta (WowB), monitors from monitors.json, borderless
    ./Set-WowWindow.ps1 -ProcessName Wow         # Retail/other client
    ./Set-WowWindow.ps1 -Select 1,2 -Main 1      # other selection for this run only
    ./Set-WowWindow.ps1 -X 0 -Y 0 -Width 5760 -Height 2160   # fixed rectangle, no monitor logic
    ./Set-WowWindow.ps1 -KeepBorder              # keep title bar and frame
#>
param(
    [int]$X, [int]$Y, [int]$Width, [int]$Height,
    [int[]]$Select,
    [int]$Main,
    [string]$ProcessName = 'WowB',
    [switch]$KeepBorder,
    [int]$TimeoutSec = 180,
    # WoW root folder (contains _retail_, _classic_beta_ …); default: see Get-QnWowRoot in qnMonitors.ps1
    [string]$WowRoot,
    [string]$ConfigPath
)

. (Join-Path $PSScriptRoot 'qnMonitors.ps1')

if (-not $ConfigPath) {
    if (-not $WowRoot) { $WowRoot = Get-QnWowRoot }
    $ConfigPath = if ($WowRoot) { Join-Path $WowRoot 'monitors.json' } else { '' }
}

$all = @(Get-QnMonitors)
$fixed = $PSBoundParameters.ContainsKey('Width') -or $PSBoundParameters.ContainsKey('Height')

# --- Which monitors? -------------------------------------------------------------------------
$sel = @(); $mainMon = $null
if ($Select) {
    $sel = @($all | Where-Object Index -in $Select)
} elseif (-not $fixed -and $ConfigPath -and (Test-Path $ConfigPath)) {
    $cfg = Get-Content $ConfigPath -Raw | ConvertFrom-Json
    foreach ($c in $cfg.selected) {
        $m = $all | Where-Object Device -eq $c.device
        if (-not $m) { Write-Warning "Monitor $($c.device) from monitors.json is not connected - skipped."; continue }
        if ($m.X -ne $c.x -or $m.Y -ne $c.y -or $m.Width -ne $c.width -or $m.Height -ne $c.height) {
            Write-Warning ("Monitor {0} changed since setup: was {1},{2} {3}x{4}, now {5}. Using the current values; run Initialize-WowMonitors.ps1 again to confirm." -f
                $c.device, $c.x, $c.y, $c.width, $c.height, (Format-QnRect $m))
        }
        $sel += $m
    }
    $mainMon = $sel | Where-Object Device -eq $cfg.main
} elseif (-not $fixed) {
    Write-Warning "No monitors.json ($(if ($ConfigPath) { $ConfigPath } else { 'WoW folder not found' })) - using all monitors. Run Initialize-WowMonitors.ps1 to choose."
    $sel = $all
}
if ($Main) { $mainMon = $sel | Where-Object Index -eq $Main }
if ($sel -and -not $mainMon) { $mainMon = ($sel | Where-Object Primary | Select-Object -First 1) ?? $sel[0] }

if ($fixed) {
    $target = [pscustomobject]@{ X = $X; Y = $Y; Width = $Width; Height = $Height }
} elseif ($sel) {
    $target = Get-QnUnion $sel
    "Selected monitors: {0}  (main: {1} {2})" -f (($sel | ForEach-Object { "$($_.Index)=$($_.Device)" }) -join ', '), $mainMon.Index, $mainMon.Device
} else {
    Write-Error 'No usable monitor selection.'; exit 1
}

# --- Wait for the WoW window -----------------------------------------------------------------
$deadline = (Get-Date).AddSeconds($TimeoutSec)
do {
    $proc = Get-Process -Name $ProcessName -ErrorAction SilentlyContinue |
        Where-Object MainWindowHandle -ne 0 | Select-Object -First 1
    if (-not $proc) { Start-Sleep -Seconds 2 }
} until ($proc -or (Get-Date) -gt $deadline)

if (-not $proc) {
    Write-Error "No window of process '$ProcessName' found within $TimeoutSec s."
    exit 1
}
$hWnd = $proc.MainWindowHandle
$N = [QnTools.Monitors]
$N::DpiAware()

if (-not $KeepBorder) {
    $GWL_STYLE = -16
    $remove = 0x00C00000 -bor 0x00040000 -bor 0x00080000 -bor 0x00020000 -bor 0x00010000  # CAPTION, THICKFRAME, SYSMENU, MIN/MAXBOX
    $style = $N::GetWindowLongPtr($hWnd, $GWL_STYLE).ToInt64()
    [void]$N::SetWindowLongPtr($hWnd, $GWL_STYLE, [IntPtr]::new($style -band (-bnot $remove)))
}

$SWP_NOZORDER = 0x0004; $SWP_FRAMECHANGED = 0x0020; $SWP_SHOWWINDOW = 0x0040
[void]$N::SetWindowPos($hWnd, [IntPtr]::Zero, $target.X, $target.Y, $target.Width, $target.Height,
    $SWP_NOZORDER -bor $SWP_FRAMECHANGED -bor $SWP_SHOWWINDOW)

Start-Sleep -Milliseconds 500
$r = New-Object QnTools.Monitors+RECT
[void]$N::GetWindowRect($hWnd, [ref]$r)
"Window of {0} (PID {1}): {2},{3}  {4} x {5}" -f $ProcessName, $proc.Id, $r.Left, $r.Top, ($r.Right - $r.Left), ($r.Bottom - $r.Top)

# --- Client area and monitor data for qnViewPort --------------------------------------------
$cr = New-Object QnTools.Monitors+RECT
[void]$N::GetClientRect($hWnd, [ref]$cr)
$p = New-Object QnTools.Monitors+POINT
[void]$N::ClientToScreen($hWnd, [ref]$p)
$client = [pscustomobject]@{ X = $p.X; Y = $p.Y; Width = $cr.Right - $cr.Left; Height = $cr.Bottom - $cr.Top }
"Client area: {0}" -f (Format-QnRect $client)

foreach ($h in @(Get-QnHidden $client $all)) {
    "  not visible: {0} (window coordinates)" -f (Format-QnRect ([pscustomobject]@{ X = $h.X - $client.X; Y = $h.Y - $client.Y; Width = $h.Width; Height = $h.Height }))
}

if ($fixed -or -not $mainMon) { exit 0 }
$exe = $proc.Path
if (-not $exe) { Write-Warning 'Client folder unknown (no access to the process path) - Monitors.lua not updated.'; exit 0 }
$addon = Join-Path (Split-Path $exe -Parent) 'Interface\AddOns\qnViewPort'
if (-not (Test-Path (Join-Path $addon 'qnViewPort.toc'))) { exit 0 }
$file = Join-Path $addon 'Monitors.lua'
if (Write-QnMonitorLua $file $client $all @($sel.Device) $mainMon.Device) {
    "Updated $file - in game: /reload"
} else {
    "$file is up to date."
}
