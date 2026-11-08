-- qnCore: own tileable background patterns (Media\Patterns, generated with
-- tools\New-QnPatterns.ps1). Mostly dark and translucent so that a color underneath
-- stays visible. Also registered with LibSharedMedia as soon as an addon brings it along.
-- qnCore.Media: shared files and lists of media (own + LibSharedMedia).

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

-- LibSharedMedia-3.0 or nil; it may only arrive with a later loaded addon (e.g. Titan),
-- therefore look it up on every use
function lib.LSM()
	return LibStub and LibStub("LibSharedMedia-3.0", true)
end

---------------------------------------------------------------------------
-- Media shared by the addons: Blizzard files, own lists + LibSharedMedia for dropdowns
---------------------------------------------------------------------------

local Media = {}
lib.Media = Media

-- Blizzard files (paths from Blizzard's source)
Media.ROCK = "Interface\\FrameGeneral\\UI-Background-Rock"
Media.MARBLE = "Interface\\FrameGeneral\\UI-Background-Marble"
Media.WHITE = "Interface\\Buttons\\WHITE8X8"
Media.TOOLTIP_BG = "Interface\\Tooltips\\UI-Tooltip-Background"
Media.TOOLTIP_BORDER = "Interface\\Tooltips\\UI-Tooltip-Border"
Media.STATUSBAR = "Interface\\TargetingFrame\\UI-StatusBar"

-- Status bar textures { key, display name, file }; the keys are stored values
Media.STATUSBARS = {
	{ "Blizzard", "Blizzard", Media.STATUSBAR },
	{ "Flat", L["Flat"], Media.WHITE },
	{ "Raid", RAID, "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" },
}

-- Entries of an LSM media type as { name, name } (for dropdowns), without the names in skip
function Media.LSMEntries(kind, skip)
	local list = {}
	local lsm = lib.LSM()
	if lsm then
		for _, name in ipairs(lsm:List(kind)) do
			if not (skip and skip[name]) then
				list[#list + 1] = { name, name }
			end
		end
	end
	return list
end

-- Path of an LSM file or nil
function Media.LSMFetch(kind, name)
	local lsm = lib.LSM()
	return lsm and lsm:IsValid(kind, name) and lsm:Fetch(kind, name) or nil
end

-- Dropdown entries { key, text }: first own ({ key, text, file }, ...), then LSM's of kind
-- without the own keys
function Media.Entries(own, kind)
	local list, skip = {}, {}
	for _, m in ipairs(own) do
		list[#list + 1] = { m[1], m[2] }
		skip[m[1]] = true
	end
	for _, e in ipairs(Media.LSMEntries(kind, skip)) do
		list[#list + 1] = e
	end
	return list
end

-- File of key: from own ({ key, text, file }, ...), otherwise from LSM's kind; nil if unknown
function Media.File(own, kind, key)
	for _, m in ipairs(own) do
		if m[1] == key then
			return m[3]
		end
	end
	return Media.LSMFetch(kind, key)
end

local registered = false
local function RegisterLSM()
	local lsm = not registered and lib.LSM()
	if lsm then
		for _, p in ipairs(lib.Patterns) do
			lsm:Register("background", p[4], p[3])
		end
		registered = true
	end
end

RegisterLSM()
lib.NewEventHub().Register("ADDON_LOADED", RegisterLSM)
