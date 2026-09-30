<#
.SYNOPSIS
	Generates the textures of qnSkins (qnSkins\Media\*.tga).
.DESCRIPTION
	Rope.tga: a twisted cord of a red and a gold strand, 64x16, seamless along its length (x), with a
	transparent margin above and below. qnSkins draws the line of its band with it (repeated along
	the line). Written as an uncompressed 32-bit TGA (BGRA, origin bottom left), smoothed with 4x4
	samples per pixel.
.EXAMPLE
	pwsh tools\New-QnSkinArt.ps1
#>
param(
	[string]$OutDir = (Join-Path $PSScriptRoot '..\AddOns\qnSkins\Media')
)

$ErrorActionPreference = 'Stop'
# note: [math]::Min/Max with an integer literal pick the Int32 overload - always write 0.0/1.0

function Wrap([double]$v, [double]$p) { $v - $p * [math]::Floor($v / $p) }

function Write-Tga([string]$Path, [int]$Width, [int]$Height, [byte[]]$Pixels) {
	$header = [byte[]]::new(18)
	$header[2] = 2                                      # uncompressed, true color
	$header[12] = $Width -band 0xFF; $header[13] = $Width -shr 8
	$header[14] = $Height -band 0xFF; $header[15] = $Height -shr 8
	$header[16] = 32                                    # bits per pixel
	$header[17] = 8                                     # 8 alpha bits, origin bottom left
	[System.IO.File]::WriteAllBytes($Path, $header + $Pixels)
}

# Rope: strands as diagonal bands (period 16 px along the rope = 4 twists per tile), each band shaded
# like a cylinder, the whole rope shaded across its thickness; dark grooves between the strands.
$RED = 0.78, 0.12, 0.08
$GOLD = 1.0, 0.78, 0.32
$W, $H = 64, 16
$center, $radius = 7.5, 6.5
function Rope([double]$x, [double]$y) {
	$d = $y - $center
	$a = [math]::Min(1.0, [math]::Max(0.0, $radius + 0.5 - [math]::Abs($d)))
	if ($a -le 0) { return 0, 0, 0, 0 }
	$phase = Wrap ($x + $d * 1.2) 16
	$color = if ($phase -lt 8) { $RED } else { $GOLD }
	$band = [math]::Sin([math]::PI * (Wrap $phase 8) / 8)                 # 0 at the grooves
	$round = [math]::Sqrt([math]::Max(0.0, 1 - ($d / ($radius + 0.5)) * ($d / ($radius + 0.5))))
	$light = (0.25 + 0.75 * $band) * (0.45 + 0.55 * $round) + 0.12 * [math]::Max(0.0, -$d / $radius)   # light from above
	return ($color[0] * $light), ($color[1] * $light), ($color[2] * $light), $a
}

New-Item -ItemType Directory -Force $OutDir | Out-Null
$n = 4
$pixels = [byte[]]::new($W * $H * 4)
for ($y = 0; $y -lt $H; $y++) {
	for ($x = 0; $x -lt $W; $x++) {
		$sr = 0.0; $sg = 0.0; $sb = 0.0; $sa = 0.0
		for ($sy = 0; $sy -lt $n; $sy++) {
			for ($sx = 0; $sx -lt $n; $sx++) {
				$r, $g, $b, $a = Rope ($x + ($sx + 0.5) / $n) ($y + ($sy + 0.5) / $n)
				$sr += $r * $a; $sg += $g * $a; $sb += $b * $a; $sa += $a
			}
		}
		# row y (top = 0) is at H-1-y in a TGA with origin bottom left
		$i = (($H - 1 - $y) * $W + $x) * 4
		if ($sa -gt 0) {
			$pixels[$i] = [byte][math]::Round(255 * [math]::Min(1.0, $sb / $sa))
			$pixels[$i + 1] = [byte][math]::Round(255 * [math]::Min(1.0, $sg / $sa))
			$pixels[$i + 2] = [byte][math]::Round(255 * [math]::Min(1.0, $sr / $sa))
		}
		$pixels[$i + 3] = [byte][math]::Round(255 * $sa / ($n * $n))
	}
}
$file = Join-Path $OutDir 'Rope.tga'
Write-Tga $file $W $H $pixels
Write-Host "Rope.tga (${W}x$H)"
