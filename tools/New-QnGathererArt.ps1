<#
.SYNOPSIS
	Generates the textures of qnGatherer (qnGatherer\Media\*.tga).
.DESCRIPTION
	Area.tga: white disk with a soft edge, 64x64. qnGatherer stretches it to the ellipse of an area
	on the world map and tints it with the color of the kind.
	Ring.tga: white ring, 32x32. The tracking circle on the minimap (tinted with the color of the kind).
	Both written as uncompressed 32-bit TGA (BGRA, origin bottom left), smoothed with 4x4 samples
	per pixel.
.EXAMPLE
	pwsh tools\New-QnGathererArt.ps1
#>
param(
	[string]$OutDir = (Join-Path $PSScriptRoot '..\AddOns\qnGatherer\Media')
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

# White image of size x size; alpha from $Shape (distance from the center in pixels -> 0..1)
function New-WhiteTga([string]$Name, [int]$Size, [scriptblock]$Shape) {
	$n = 4
	$c = $Size / 2.0
	$pixels = [byte[]]::new($Size * $Size * 4)
	for ($y = 0; $y -lt $Size; $y++) {
		for ($x = 0; $x -lt $Size; $x++) {
			$sum = 0.0
			for ($sy = 0; $sy -lt $n; $sy++) {
				for ($sx = 0; $sx -lt $n; $sx++) {
					$dx = $x + ($sx + 0.5) / $n - $c
					$dy = $y + ($sy + 0.5) / $n - $c
					$sum += & $Shape ([math]::Sqrt($dx * $dx + $dy * $dy))
				}
			}
			$i = ($y * $Size + $x) * 4
			$pixels[$i] = 255; $pixels[$i + 1] = 255; $pixels[$i + 2] = 255
			$pixels[$i + 3] = [byte][math]::Round(255 * $sum / ($n * $n))
		}
	}
	Write-Tga (Join-Path $OutDir $Name) $Size $Size $pixels
}

New-Item -ItemType Directory -Force $OutDir | Out-Null

# Area: full alpha inside, soft fade over the outer quarter of the radius
New-WhiteTga 'Area.tga' 64 {
	param($d)
	$r = 31.0
	if ($d -ge $r) { return 0.0 }
	[math]::Min(1.0, ($r - $d) / ($r * 0.25))
}

# Ring: 3 px wide at radius 13 (of 16), anti-aliased edges
New-WhiteTga 'Ring.tga' 32 {
	param($d)
	[math]::Max(0.0, [math]::Min(1.0, 2.0 - [math]::Abs($d - 13.0)))
}

Write-Host "Written: Area.tga, Ring.tga to $OutDir"
