-- qnCore: eigene kachelbare Hintergrundmuster (Media\Patterns, erzeugt mit
-- tools\New-QnPatterns.ps1). Überwiegend dunkel und durchscheinend, damit eine Farbe darunter
-- sichtbar bleibt. Zusätzlich bei LibSharedMedia angemeldet, sobald ein Addon es mitbringt.

local ADDON, ns = ...
local lib = qnCore
local L = ns.L

local PATH = "Interface\\AddOns\\qnCore\\Media\\Patterns\\"

-- { Schlüssel, Anzeigename, Datei, LSM-Name }
-- LSM-Namen sind Schlüssel, die andere Addons speichern: deshalb in allen Sprachen gleich.
lib.Patterns = {
	{ "qnStripes", L["Schraffur"], PATH .. "Stripes", "qn Stripes" },
	{ "qnCrosshatch", L["Kreuzschraffur"], PATH .. "Crosshatch", "qn Crosshatch" },
	{ "qnGrid", L["Gitter"], PATH .. "Grid", "qn Grid" },
	{ "qnDots", L["Punkte"], PATH .. "Dots", "qn Dots" },
	{ "qnChecker", L["Schachbrett"], PATH .. "Checker", "qn Checker" },
	{ "qnDiamonds", L["Rauten"], PATH .. "Diamonds", "qn Diamonds" },
	{ "qnBricks", L["Ziegel"], PATH .. "Bricks", "qn Bricks" },
	{ "qnWeave", L["Geflecht"], PATH .. "Weave", "qn Weave" },
	{ "qnScanlines", L["Scanlinien"], PATH .. "Scanlines", "qn Scanlines" },
	{ "qnGrain", L["Körnung"], PATH .. "Grain", "qn Grain" },
}

-- LibSharedMedia kommt ggf. erst mit einem später geladenen Addon (z. B. Titan)
local registered = false
local function RegisterLSM()
	local lsm = not registered and LibStub and LibStub("LibSharedMedia-3.0", true)
	if lsm then
		for _, p in ipairs(lib.Patterns) do
			lsm:Register("background", p[4], p[3])
		end
		registered = true
	end
end

RegisterLSM()
lib.NewEventHub().Register("ADDON_LOADED", RegisterLSM)
