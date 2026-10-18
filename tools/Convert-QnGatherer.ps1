#Requires -Version 7
<#
.SYNOPSIS
    Offline import into qnGatherer from GatherMate2 and/or GatherTogether.

.DESCRIPTION
    For addons that do not load on WoW Classic Forever (or are not installed there), qnGatherer cannot
    read their data in the game. This tool runs qnGatherer's own import adapters on the files of the
    other addon and writes the records into qnGathererDB.global.pendingImport in
    WTF\Account\<account>\SavedVariables\qnGatherer.lua (a backup qnGatherer.lua.bak is kept).
    qnGatherer takes them over on the next login and reports the result in the chat.

    The game must be closed: WoW overwrites the SavedVariables when logging out.
    Uses fengari (Lua VM in Node) from tests\node_modules; it is installed with npm if missing.

.PARAMETER SavedVariables
    Folder WTF\Account\<account>\SavedVariables of the Forever client. Contains GatherMate2.lua and
    GatherTogether.lua (data of those addons, if they were used) and qnGatherer.lua.

.PARAMETER GatherMate2
    Addon folder of GatherMate2 (optional): the node names (Constants.lua, Locales) are needed to match
    GatherMate2's nodes with the resources of qnGatherer.

.PARAMETER GatherTogether
    Addon folder of GatherTogether (optional): its data files (areas, zones, fish lists, overlays,
    skinning).

.PARAMETER Locale
    Client language (names of GatherMate2's nodes). Default: deDE.

.EXAMPLE
    pwsh tools\Convert-QnGatherer.ps1 -SavedVariables 'C:\Games\World of Warcraft\_classic_beta_\WTF\Account\NAME\SavedVariables' -GatherTogether 'D:\Downloads\GatherTogether'
#>
[CmdletBinding()]
param(
    [Parameter(Mandatory)][string]$SavedVariables,
    [string]$GatherMate2,
    [string]$GatherTogether,
    [string]$Locale = 'deDE'
)
$ErrorActionPreference = 'Stop'

$repo = Split-Path $PSScriptRoot -Parent
if (-not (Test-Path $SavedVariables -PathType Container)) { throw "Folder not found: $SavedVariables" }
foreach ($p in $GatherMate2, $GatherTogether) {
    if ($p -and -not (Test-Path $p -PathType Container)) { throw "Folder not found: $p" }
}
if (Get-Process -Name 'Wow*' -ErrorAction SilentlyContinue) {
    throw 'WoW is running. Close the game first: it overwrites the SavedVariables when logging out.'
}

# fengari as for the tests
$tests = Join-Path $repo 'tests'
if (-not (Test-Path (Join-Path $tests 'node_modules\fengari'))) {
    Push-Location $tests
    try { npm install --no-fund --no-audit | Out-Null } finally { Pop-Location }
}

$options = @{
    repo = $repo
    savedVariables = (Resolve-Path $SavedVariables).Path
    gatherMate2 = if ($GatherMate2) { (Resolve-Path $GatherMate2).Path } else { $null }
    gatherTogether = if ($GatherTogether) { (Resolve-Path $GatherTogether).Path } else { $null }
    locale = $Locale
} | ConvertTo-Json -Compress
node (Join-Path $PSScriptRoot 'Convert-QnGatherer.mjs') $options
if ($LASTEXITCODE -ne 0) { throw 'Conversion failed.' }
Write-Host 'Start the game: qnGatherer imports the records on login.'
