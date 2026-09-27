<#
.SYNOPSIS
	Erzeugt die kachelbaren Hintergrundmuster von qnCore (qnCore\Media\Patterns\*.tga).
.DESCRIPTION
	Jedes Muster ist eine Funktion (x, y) -> (Grauwert, Deckkraft) mit Werten 0–1. Die Kachel wird mit
	4×4 Abtastpunkten je Pixel geglättet und als unkomprimiertes 32-Bit-TGA (BGRA, Ursprung unten links)
	geschrieben. Kantenlängen sind Zweierpotenzen und die Muster nahtlos, damit WoW sie kacheln kann.
	Die Muster sind überwiegend dunkel und durchscheinend: die Randfarbe von qnViewPort bleibt darunter
	sichtbar, die Deckkraft regelt das Addon.
.EXAMPLE
	pwsh qn_DevEnv\New-QnPatterns.ps1
#>
param(
	[string]$OutDir = (Join-Path $PSScriptRoot '..\qnCore\Media\Patterns')
)

$ErrorActionPreference = 'Stop'

function Wrap([double]$v, [double]$p) { $v - $p * [math]::Floor($v / $p) }

# Deterministisches Rauschen (gleiche Datei bei jedem Lauf)
$rng = [System.Random]::new(4711)
$noise = [double[]]::new(128 * 128)
for ($i = 0; $i -lt $noise.Length; $i++) { $noise[$i] = $rng.NextDouble() }

# Name = Dateiname; Size = Kantenlänge; Samples = Glättung (1 = pixelgenau); Fn = Muster
$patterns = @(
	@{ Name = 'Stripes'; Size = 64; Samples = 4; Fn = {
		param($x, $y)
		if ((Wrap ($x + $y) 16) -lt 6) { 0, 0.85 } else { 0, 0 }
	} }
	@{ Name = 'Crosshatch'; Size = 64; Samples = 4; Fn = {
		param($x, $y)
		if ((Wrap ($x + $y) 16) -lt 2 -or (Wrap ($x - $y) 16) -lt 2) { 0, 0.9 } else { 0, 0 }
	} }
	@{ Name = 'Grid'; Size = 64; Samples = 4; Fn = {
		param($x, $y)
		if ((Wrap $x 16) -lt 1.5 -or (Wrap $y 16) -lt 1.5) { 0, 0.9 } else { 0, 0 }
	} }
	@{ Name = 'Dots'; Size = 64; Samples = 4; Fn = {
		param($x, $y)
		# versetzte Reihen: jede zweite Reihe um eine halbe Zelle verschoben
		$row = [math]::Floor($y / 16)
		$dx = (Wrap ($x + ($row % 2) * 8) 16) - 8
		$dy = (Wrap $y 16) - 8
		if ($dx * $dx + $dy * $dy -lt 3.5 * 3.5) { 0, 0.9 } else { 0, 0 }
	} }
	@{ Name = 'Checker'; Size = 64; Samples = 1; Fn = {
		param($x, $y)
		if (([math]::Floor($x / 16) + [math]::Floor($y / 16)) % 2 -eq 1) { 0, 0.6 } else { 1, 0.1 }
	} }
	@{ Name = 'Diamonds'; Size = 64; Samples = 4; Fn = {
		param($x, $y)
		$d = [math]::Abs((Wrap $x 32) - 16) + [math]::Abs((Wrap $y 32) - 16)
		if ([math]::Abs($d - 15) -lt 1.2) { 0, 0.9 } elseif ($d -lt 14) { 1, 0.08 } else { 0, 0 }
	} }
	@{ Name = 'Bricks'; Size = 64; Samples = 1; Fn = {
		param($x, $y)
		$row = [math]::Floor($y / 16)
		$bx = Wrap ($x + ($row % 2) * 16) 32
		$by = Wrap $y 16
		if ($by -lt 2 -or $bx -lt 2) { 0, 0.85 }                  # Fuge
		elseif ($by -lt 3 -or $bx -lt 3) { 1, 0.2 }               # Lichtkante oben/links
		elseif ($by -ge 15 -or $bx -ge 31) { 0, 0.35 }            # Schattenkante unten/rechts
		else { 0, 0 }
	} }
	@{ Name = 'Scanlines'; Size = 64; Samples = 1; Fn = {
		param($x, $y)
		if ((Wrap $y 4) -lt 2) { 0, 0.7 } else { 0, 0 }
	} }
	@{ Name = 'Grain'; Size = 128; Samples = 1; Fn = {
		param($x, $y)
		$n = $noise[[int]$y * 128 + [int]$x]
		$n, 0.5
	} }
	@{ Name = 'Weave'; Size = 64; Samples = 1; Fn = {
		param($x, $y)
		# Geflecht: 8er-Zellen im Schachbrett, abwechselnd waagrecht und senkrecht schattiert
		$cx = Wrap $x 8; $cy = Wrap $y 8
		$t = if (([math]::Floor($x / 8) + [math]::Floor($y / 8)) % 2 -eq 0) { $cy / 7 } else { $cx / 7 }
		$v = [math]::Sin($t * [math]::PI)
		$v, 0.55
	} }
)

function Write-Tga([string]$Path, [int]$Size, [byte[]]$Pixels) {
	$header = [byte[]]::new(18)
	$header[2] = 2                                      # unkomprimiert, Echtfarben
	$header[12] = $Size -band 0xFF; $header[13] = $Size -shr 8
	$header[14] = $Size -band 0xFF; $header[15] = $Size -shr 8
	$header[16] = 32                                    # Bit je Pixel
	$header[17] = 8                                     # 8 Alpha-Bits, Ursprung unten links
	[System.IO.File]::WriteAllBytes($Path, $header + $Pixels)
}

New-Item -ItemType Directory -Force $OutDir | Out-Null
foreach ($p in $patterns) {
	$size, $n, $fn = $p.Size, $p.Samples, $p.Fn
	$pixels = [byte[]]::new($size * $size * 4)
	for ($y = 0; $y -lt $size; $y++) {
		for ($x = 0; $x -lt $size; $x++) {
			$sumA = 0.0; $sumVA = 0.0
			for ($sy = 0; $sy -lt $n; $sy++) {
				for ($sx = 0; $sx -lt $n; $sx++) {
					$v, $a = & $fn ($x + ($sx + 0.5) / $n) ($y + ($sy + 0.5) / $n)
					$sumA += $a; $sumVA += $v * $a
				}
			}
			$a = $sumA / ($n * $n)
			$v = if ($sumA -gt 0) { $sumVA / $sumA } else { 0 }
			$g = [byte][math]::Round(255 * [math]::Min(1, [math]::Max(0, $v)))
			# Zeile y (oben = 0) liegt im TGA mit Ursprung unten links bei size-1-y
			$i = (($size - 1 - $y) * $size + $x) * 4
			$pixels[$i] = $g; $pixels[$i + 1] = $g; $pixels[$i + 2] = $g
			$pixels[$i + 3] = [byte][math]::Round(255 * $a)
		}
	}
	$file = Join-Path $OutDir "$($p.Name).tga"
	Write-Tga $file $size $pixels
	Write-Host "$($p.Name).tga ($size×$size)"
}
