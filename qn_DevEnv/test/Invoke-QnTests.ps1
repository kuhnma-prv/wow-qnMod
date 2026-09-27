# Führt alle Testszenarien (test*.lua) gegen die qn-Addons von WoW Classic Forever aus,
# je Szenario auf einem deutschen und einem englischen Client.
# Aufruf: pwsh Invoke-QnTests.ps1 [-Filter test9] [-Locale enUS] [-Detail]
# Auf dem englischen Client scheitert ein Szenario auch, wenn ein Text ohne Übersetzung erschien.
param(
	[string]$Filter = 'test*',
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

$failed = 0
$files = Get-ChildItem $here -Filter "$Filter.lua" |
	Sort-Object { [int]('0' + ($_.BaseName -replace '\D', '')) }
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
