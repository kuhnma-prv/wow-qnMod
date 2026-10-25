<#
.SYNOPSIS
	Generates the textures of qnMarkers (qnMarkers\Media\*.tga).
.DESCRIPTION
	All white with alpha, 64x64, so that qnMarkers can tint them:
	Circle.tga  disk: mask for round icons, round background and border
	Glow.tga    soft ring around the marker of the target
	Arrow.tga   arrow pointing down (marker texture "Arrow")
	Heart.tga   heart (marker of friends)
	Shield.tga  shield (marker of guild members)
	Written as uncompressed 32-bit TGA (BGRA, origin bottom left), smoothed with 4x4 samples
	per pixel.
.EXAMPLE
	pwsh tools\New-QnMarkersArt.ps1
#>
param(
	[string]$OutDir = (Join-Path $PSScriptRoot '..\AddOns\qnMarkers\Media')
)

$ErrorActionPreference = 'Stop'
# note: [math]::Min/Max with an integer literal pick the Int32 overload - always write 0.0/1.0

function Write-Tga([string]$Path, [int]$Width, [int]$Height, [byte[]]$Pixels) {
	$header = [byte[]]::new(18)
	$header[2] = 2                                      # uncompressed, true color
	$header[12] = $Width -band 0xFF; $header[13] = $Width -shr 8
	$header[14] = $Height -band 0xFF; $header[15] = $Height -shr 8
	$header[16] = 32                                    # bits per pixel
	$header[17] = 8                                     # 8 alpha bits, origin bottom left
	[System.IO.File]::WriteAllBytes($Path, $header + $Pixels)
}

# White image of size x size; alpha from $Shape (x, y from -1 to 1, y upwards -> 0..1)
function New-WhiteTga([string]$Name, [int]$Size, [scriptblock]$Shape) {
	$n = 4
	$pixels = [byte[]]::new($Size * $Size * 4)
	for ($y = 0; $y -lt $Size; $y++) {
		for ($x = 0; $x -lt $Size; $x++) {
			$sum = 0.0
			for ($sy = 0; $sy -lt $n; $sy++) {
				for ($sx = 0; $sx -lt $n; $sx++) {
					$u = ($x + ($sx + 0.5) / $n) / $Size * 2 - 1
					$v = ($y + ($sy + 0.5) / $n) / $Size * 2 - 1
					$sum += & $Shape $u $v
				}
			}
			$i = ($y * $Size + $x) * 4
			$pixels[$i] = 255; $pixels[$i + 1] = 255; $pixels[$i + 2] = 255
			$pixels[$i + 3] = [byte][math]::Round(255 * $sum / ($n * $n))
		}
	}
	Write-Tga (Join-Path $OutDir $Name) $Size $Size $pixels
}

function Inside([bool]$on) { if ($on) { 1.0 } else { 0.0 } }

New-Item -ItemType Directory -Force $OutDir | Out-Null

New-WhiteTga 'Circle.tga' 64 {
	param($x, $y)
	Inside ($x * $x + $y * $y -le 0.97 * 0.97)
}

# soft ring: brightest at 80 % of the radius, fading inwards and outwards
New-WhiteTga 'Glow.tga' 64 {
	param($x, $y)
	$r = [math]::Sqrt($x * $x + $y * $y)
	$a = [math]::Max(0.0, 1.0 - [math]::Abs($r - 0.8) / 0.2)
	$a * $a
}

# arrow down: triangle (tip at the bottom) and stem
New-WhiteTga 'Arrow.tga' 64 {
	param($x, $y)
	$head = ($y -le 0.05) -and ($y -ge -0.9) -and ([math]::Abs($x) -le 0.85 * ($y + 0.9) / 0.95)
	$stem = ([math]::Abs($x) -le 0.3) -and ($y -ge 0.0) -and ($y -le 0.9)
	Inside ($head -or $stem)
}

# heart: (X^2 + Y^2 - 1)^3 - X^2 Y^3 <= 0
New-WhiteTga 'Heart.tga' 64 {
	param($x, $y)
	$X = $x * 1.3
	$Y = $y * 1.3 + 0.2
	$q = $X * $X + $Y * $Y - 1
	Inside ($q * $q * $q - $X * $X * $Y * $Y * $Y -le 0)
}

# shield: straight top and sides, rounded tip at the bottom
New-WhiteTga 'Shield.tga' 64 {
	param($x, $y)
	if ($y -gt 0.85 -or $y -lt -0.95) { return 0.0 }
	if ($y -ge 0.0) { return Inside ([math]::Abs($x) -le 0.75) }
	Inside ([math]::Abs($x) -le 0.75 * [math]::Sqrt(($y + 0.95) / 0.95))
}

Write-Host "Written: Circle.tga, Glow.tga, Arrow.tga, Heart.tga, Shield.tga to $OutDir"
