<#
.SYNOPSIS
	Generates the tileable background patterns of qnCore (qnCore\Media\Patterns\*.tga).
.DESCRIPTION
	Each pattern is a function (x, y) -> (gray value, opacity) with values 0-1. The tile is smoothed with
	4x4 samples per pixel and written as an uncompressed 32-bit TGA (BGRA, origin bottom left).
	Edge lengths are powers of two and the patterns are seamless so WoW can tile them.
	The patterns are mostly dark and translucent: the border color of qnViewPort stays visible
	underneath, the addon controls the opacity.
.EXAMPLE
	pwsh tools\New-QnPatterns.ps1
#>
param(
	[string]$OutDir = (Join-Path $PSScriptRoot '..\AddOns\qnCore\Media\Patterns')
)

$ErrorActionPreference = 'Stop'

function Wrap([double]$v, [double]$p) { $v - $p * [math]::Floor($v / $p) }

# Deterministic noise (same file on every run)
$rng = [System.Random]::new(4711)
$noise = [double[]]::new(128 * 128)
for ($i = 0; $i -lt $noise.Length; $i++) { $noise[$i] = $rng.NextDouble() }

# Name = file name; Size = edge length; Samples = smoothing (1 = pixel-exact); Fn = pattern
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
		# staggered rows: every second row shifted by half a cell
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
		if ($by -lt 2 -or $bx -lt 2) { 0, 0.85 }                  # joint
		elseif ($by -lt 3 -or $bx -lt 3) { 1, 0.2 }               # highlight edge top/left
		elseif ($by -ge 15 -or $bx -ge 31) { 0, 0.35 }            # shadow edge bottom/right
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
		# weave: 8px cells in a checkerboard, shaded alternately horizontally and vertically
		$cx = Wrap $x 8; $cy = Wrap $y 8
		$t = if (([math]::Floor($x / 8) + [math]::Floor($y / 8)) % 2 -eq 0) { $cy / 7 } else { $cx / 7 }
		$v = [math]::Sin($t * [math]::PI)
		$v, 0.55
	} }
)

function Write-Tga([string]$Path, [int]$Size, [byte[]]$Pixels) {
	$header = [byte[]]::new(18)
	$header[2] = 2                                      # uncompressed, true color
	$header[12] = $Size -band 0xFF; $header[13] = $Size -shr 8
	$header[14] = $Size -band 0xFF; $header[15] = $Size -shr 8
	$header[16] = 32                                    # bits per pixel
	$header[17] = 8                                     # 8 alpha bits, origin bottom left
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
			# row y (top = 0) is at size-1-y in a TGA with origin bottom left
			$i = (($size - 1 - $y) * $size + $x) * 4
			$pixels[$i] = $g; $pixels[$i + 1] = $g; $pixels[$i + 2] = $g
			$pixels[$i + 3] = [byte][math]::Round(255 * $a)
		}
	}
	$file = Join-Path $OutDir "$($p.Name).tga"
	Write-Tga $file $size $pixels
	Write-Host "$($p.Name).tga (${size}x$size)"
}
