#Requires -Version 7
<#
.SYNOPSIS
    One-time setup: detects all monitors (resolution, position, scaling), lets you select the
    monitors the WoW window should span and the main monitor for the 3D world.
    Saves the selection to monitors.json in the WoW root folder (shared by all installed clients,
    used by Set-WowWindow.ps1) and writes qnViewPort\Monitors.lua for every installed client.

.EXAMPLE
    ./Initialize-WowMonitors.ps1                     # show monitors, ask for the selection
    ./Initialize-WowMonitors.ps1 -List               # only show monitors, change nothing
    ./Initialize-WowMonitors.ps1 -Select 1,2 -Main 1 # without questions
#>
param(
    [int[]]$Select,
    [int]$Main,
    [switch]$List,
    # scripts -> qnViewPort -> AddOns -> Interface -> <Client> -> WoW root
    [string]$WowRoot = [IO.Path]::GetFullPath((Join-Path $PSScriptRoot '..\..\..\..\..')),
    [string]$ConfigPath = (Join-Path $WowRoot 'monitors.json')
)

. (Join-Path $PSScriptRoot 'qnMonitors.ps1')

$all = @(Get-QnMonitors)
if (-not $all) { Write-Error 'No monitors found.'; exit 1 }

"Monitors (physical pixels, origin = top left of the Windows primary monitor):"
$all | Format-Table Index, Device, Name, @{ n = 'Position'; e = { '{0},{1}' -f $_.X, $_.Y } },
    @{ n = 'Resolution'; e = { '{0}x{1}' -f $_.Width, $_.Height } }, @{ n = 'Scale'; e = { "$($_.Scale) %" } }, Primary -AutoSize |
    Out-String -Width 200 | Write-Host

if ($List) { exit 0 }

if (-not $Select) {
    $answer = Read-Host "Monitors for the WoW window (e.g. 1,2) [all]"
    $Select = if ($answer) { $answer -split '[,; ]+' | Where-Object { $_ } | ForEach-Object { [int]$_ } } else { $all.Index }
}
$sel = @($all | Where-Object Index -in $Select)
if ($sel.Count -ne @($Select | Select-Object -Unique).Count) { Write-Error "Unknown monitor number in: $($Select -join ',')"; exit 1 }

if (-not $Main) {
    $default = ($sel | Where-Object Primary | Select-Object -First 1) ?? $sel[0]
    if ($sel.Count -gt 1) {
        $answer = Read-Host "Main monitor for the 3D world [$($default.Index)]"
        $Main = if ($answer) { [int]$answer } else { $default.Index }
    } else { $Main = $default.Index }
}
$mainMon = $sel | Where-Object Index -eq $Main
if (-not $mainMon) { Write-Error "Main monitor $Main is not among the selected monitors."; exit 1 }

$union = Get-QnUnion $sel
$shown = @($all | Where-Object { Get-QnIntersect $union $_ })
$extra = @($shown | Where-Object Index -notin $Select)
$hidden = @(Get-QnHidden $union $shown)

""
"WoW window:        {0}" -f (Format-QnRect $union)
"Main monitor:      {0} {1} -> 3D world {2}x{3} at {4},{5} in the window" -f $mainMon.Index, $mainMon.Device,
    $mainMon.Width, $mainMon.Height, ($mainMon.X - $union.X), ($mainMon.Y - $union.Y)
foreach ($m in $shown) {
    $c = Get-QnIntersect $union $m
    "Monitor {0} shows:  {1} (window coordinates){2}" -f $m.Index,
        (Format-QnRect ([pscustomobject]@{ X = $c.X - $union.X; Y = $c.Y - $union.Y; Width = $c.Width; Height = $c.Height })),
        ($(if ($m.Index -in $extra.Index) { '  <- not selected, but inside the window' } else { '' }))
}
if ($hidden) {
    "Not visible on any monitor (window coordinates):"
    foreach ($h in $hidden) { "  {0}" -f (Format-QnRect ([pscustomobject]@{ X = $h.X - $union.X; Y = $h.Y - $union.Y; Width = $h.Width; Height = $h.Height })) }
} else {
    "The whole window is visible."
}

$config = [ordered]@{
    selected = @($sel | ForEach-Object { [ordered]@{ device = $_.Device; x = $_.X; y = $_.Y; width = $_.Width; height = $_.Height } })
    main     = $mainMon.Device
    window   = [ordered]@{ x = $union.X; y = $union.Y; width = $union.Width; height = $union.Height }
}
$config | ConvertTo-Json -Depth 4 | Set-Content -Path $ConfigPath -Encoding utf8NoBOM
""
"Saved: $ConfigPath"

# The window will be the borderless union, so its client area equals $union.
foreach ($dir in Get-QnViewPortFolders $WowRoot) {
    $file = Join-Path $dir 'Monitors.lua'
    $changed = Write-QnMonitorLua $file $union $all @($sel.Device) $mainMon.Device
    "{0}: {1}" -f $file, ($(if ($changed) { 'written (in game: /reload)' } else { 'unchanged' }))
}
""
"Next: start WoW and run Set-WowWindow.ps1 (it uses this selection)."
