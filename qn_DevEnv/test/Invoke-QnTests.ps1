# Führt alle Testszenarien gegen die qn-Addons von WoW Classic Forever aus, je Szenario auf einem
# deutschen und einem englischen Client. Szenarien liegen je getestetem Addon in einem Ordner
# (qnCore\test1.lua, qnBuffMod\test3.lua …).
# Aufruf: pwsh Invoke-QnTests.ps1 [-Filter qnBuffMod] [-Filter qnCore/test3] [-Locale enUS] [-Detail]
#   -Filter  Addon-Ordner oder Addon/Szenario, Platzhalter erlaubt (qnCore/test1*, */test2)
# Auf dem englischen Client scheitert ein Szenario auch, wenn ein Text ohne Übersetzung erschien.
param(
	[string]$Filter = '*',
	[string[]]$Locale = @('deDE', 'enUS'),
	[switch]$Detail
)

$Locale = $Locale -split ',' | ForEach-Object { $_.Trim() } | Where-Object { $_ }   # auch "deDE,enUS" über pwsh -File
$here = $PSScriptRoot
if (-not (Test-Path "$here\node_modules\fengari")) {
	Write-Host 'fengari fehlt – installiere …'
	Push-Location $here
	npm install --no-fund --no-audit | Out-Null
	Pop-Location
}

# Reihenfolge wie in CLAUDE.md, weitere Addon-Ordner danach alphabetisch
$ORDER = @('qnCore', 'qnMeter', 'qnNumKeyPad', 'qnViewPort', 'qnInventory', 'qnBuffMod', 'qnUnitFrames')
$pattern = if ($Filter -match '/') { $Filter } else { "$Filter/*" }
$files = Get-ChildItem $here -Directory -Filter 'qn*' | ForEach-Object {
	$addon = $_.Name
	Get-ChildItem $_.FullName -Filter 'test*.lua' | ForEach-Object {
		[pscustomobject]@{ Addon = $addon; Number = [int]('0' + ($_.BaseName -replace '\D', '')); Name = "$addon/$($_.Name)" }
	}
} | Where-Object { $_.Name -like "$pattern.lua" -or $_.Name -like $pattern } |
	Sort-Object { $i = [array]::IndexOf($ORDER, $_.Addon); if ($i -lt 0) { 99 } else { $i } }, Addon, Number
if (-not $files) { Write-Host "Keine Szenarien für '$Filter'." -ForegroundColor Yellow; exit 1 }

$failed = 0
foreach ($loc in $Locale) {
	$env:QN_LOCALE = $loc
	foreach ($file in $files) {
		$out = node "$here\run.mjs" $file.Name 2>&1
		$ok = $LASTEXITCODE -eq 0 -and ($out -match 'alle Prüfungen bestanden')
		if ($ok) {
			Write-Host "OK      $loc $($file.Name)" -ForegroundColor Green
		} else {
			$failed++
			Write-Host "FEHLER  $loc $($file.Name)" -ForegroundColor Red
		}
		if ($Detail -or -not $ok) {
			$out | Where-Object { $_ -notmatch '^\s*\[Chat\]' -and $_ -notmatch '^OK ' } | ForEach-Object { "        $_" }
		}
	}
}
Remove-Item Env:QN_LOCALE -ErrorAction SilentlyContinue
if ($failed) { exit 1 }
