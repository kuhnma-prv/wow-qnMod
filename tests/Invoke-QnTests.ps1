# Runs all test scenarios against the qn addons of WoW Classic Forever, each scenario on a
# German and an English client. Scenarios live in one folder per tested addon
# (qnCore\test1.lua, qnBuffMod\test3.lua …).
# Usage: pwsh Invoke-QnTests.ps1 [-Filter qnBuffMod] [-Filter qnCore/test3] [-Locale enUS] [-Detail]
#   -Filter  addon folder or addon/scenario, wildcards allowed (qnCore/test1*, */test2)
# On the German client a scenario also fails if a text was shown without translation.
param(
	[string]$Filter = '*',
	[string[]]$Locale = @('deDE', 'enUS'),
	[switch]$Detail
)

$Locale = $Locale -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }   # also "deDE,enUS" via pwsh -File
$here = $PSScriptRoot
if (-not (Test-Path "$here\node_modules\fengari")) {
	Write-Host 'fengari missing – installing …'
	Push-Location $here
	npm install --no-fund --no-audit | Out-Null
	Pop-Location
}

# order as in CLAUDE.md, further addon folders alphabetically afterwards
$ORDER = @('qnCore', 'qnMeter', 'qnNumKeyPad', 'qnViewPort', 'qnInventory', 'qnBuffMod', 'qnUnitFrames', 'qnTooltip')
$pattern = if ($Filter -match '/') { $Filter } else { "$Filter/*" }
$files = Get-ChildItem $here -Directory -Filter 'qn*' | ForEach-Object {
	$addon = $_.Name
	Get-ChildItem $_.FullName -Filter 'test*.lua' | ForEach-Object {
		[pscustomobject]@{ Addon = $addon; Number = [int]('0' + ($_.BaseName -replace '\D', '')); Name = "$addon/$($_.Name)" }
	}
} | Where-Object { $_.Name -like "$pattern.lua" -or $_.Name -like $pattern } |
	Sort-Object { $i = [array]::IndexOf($ORDER, $_.Addon); if ($i -lt 0) { 99 } else { $i } }, Addon, Number
if (-not $files) { Write-Host "No scenarios for '$Filter'." -ForegroundColor Yellow; exit 1 }

$failed = 0
foreach ($loc in $Locale) {
	$env:QN_LOCALE = $loc
	foreach ($file in $files) {
		$out = node "$here\run.mjs" $file.Name 2>&1
		$ok = $LASTEXITCODE -eq 0 -and ($out -match 'all checks passed')
		if ($ok) {
			Write-Host "OK      $loc $($file.Name)" -ForegroundColor Green
		} else {
			$failed++
			Write-Host "FAILED  $loc $($file.Name)" -ForegroundColor Red
		}
		if ($Detail -or -not $ok) {
			$out | Where-Object { $_ -notmatch '^\s*\[Chat\]' -and $_ -notmatch '^OK ' } | ForEach-Object { "        $_" }
		}
	}
}
Remove-Item Env:QN_LOCALE -ErrorAction SilentlyContinue
if ($failed) { exit 1 }
