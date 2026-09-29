-- qnCore: own tileable background patterns (Media\Patterns, generated with
-- tools\New-QnPatterns.ps1). Mostly dark and translucent so that a color underneath
-- stays visible. Also registered with LibSharedMedia as soon as an addon brings it along.

local ADDON, ns = ...
local lib = qnCore
local L = ns.L

local PATH = "Interface\\AddOns\\qnCore\\Media\\Patterns\\"

-- { key, display name, file, LSM name }
-- LSM names are keys that other addons save: therefore the same in all languages.
lib.Patterns = {
	{ "qnStripes", L["Hatching"], PATH .. "Stripes", "qn Stripes" },
	{ "qnCrosshatch", L["Crosshatch"], PATH .. "Crosshatch", "qn Crosshatch" },
	{ "qnGrid", L["Grid"], PATH .. "Grid", "qn Grid" },
	{ "qnDots", L["Dots"], PATH .. "Dots", "qn Dots" },
	{ "qnChecker", L["Checkerboard"], PATH .. "Checker", "qn Checker" },
	{ "qnDiamonds", L["Diamonds"], PATH .. "Diamonds", "qn Diamonds" },
	{ "qnBricks", L["Bricks"], PATH .. "Bricks", "qn Bricks" },
	{ "qnWeave", L["Weave"], PATH .. "Weave", "qn Weave" },
	{ "qnScanlines", L["Scanlines"], PATH .. "Scanlines", "qn Scanlines" },
	{ "qnGrain", L["Grain"], PATH .. "Grain", "qn Grain" },
}

-- LibSharedMedia may only arrive with a later loaded addon (e.g. Titan)
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
