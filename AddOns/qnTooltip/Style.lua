-- qnTooltip: Aussehen der Tooltips (Hintergrund, Rahmen, Verlauf oben, Schriften, Skalierung).
-- Jeder gestaltete Tooltip bekommt einen eigenen Rahmen mit BackdropTemplate, der die Ebene des
-- Tooltips teilt (SetUsingParentLevel, wie Blizzards AuraContainerUtil.SetTooltipBackdrop); Blizzards
-- NineSlice wird dafür ausgeblendet. Farben je Tooltip (Klasse, Qualität …) setzen die übrigen Dateien
-- über Style.SetColors; beim Leeren des Tooltips gelten wieder die allgemeinen Farben.

local _, ns = ...
local lib = qnCore
local L = ns.L

local Style = {}
ns.Style = Style

local MASK_HEIGHT = 32

---------------------------------------------------------------------------
-- Hintergründe und Rahmen
---------------------------------------------------------------------------

-- { Schlüssel, Anzeigename, Datei, kacheln }
Style.BACKGROUNDS = {
	{ "rock", L["Rock"], "Interface\\FrameGeneral\\UI-Background-Rock" },
	{ "marble", L["Marble"], "Interface\\FrameGeneral\\UI-Background-Marble" },
	{ "dark", L["Dark"], "Interface\\DialogFrame\\UI-DialogBox-Background-Dark" },
	{ "alpha", L["Translucent"], "Interface\\Tooltips\\UI-Tooltip-Background" },
	{ "flat", L["Flat"], "Interface\\Buttons\\WHITE8X8" },
}

function Style.BackgroundEntries()
	local list, skip = {}, {}
	for _, b in ipairs(Style.BACKGROUNDS) do
		list[#list + 1] = { b[1], b[2] }
	end
	for _, p in ipairs(lib.Patterns) do
		list[#list + 1] = { p[1], p[2] }
		skip[p[4]] = true   -- bei LSM angemeldete eigene Muster nicht doppelt
	end
	for _, e in ipairs(ns.LSMEntries("background", skip)) do
		list[#list + 1] = e
	end
	return list
end

-- Datei und Kacheln zu einem gespeicherten Hintergrund
local function Background(key)
	for _, b in ipairs(Style.BACKGROUNDS) do
		if b[1] == key then
			return b[3], false
		end
	end
	for _, p in ipairs(lib.Patterns) do
		if p[1] == key then
			return p[3], true
		end
	end
	local file = ns.LSMFetch("background", key)
	if file then
		return file, false
	end
	return Style.BACKGROUNDS[1][3], false
end

-- Randbreite innen (Einrückung von Hintergrund, Verlauf und Lebensbalken)
function Style.Inset()
	local db = ns.db
	if db.borderStyle == "angular" then
		return db.borderSize
	elseif db.borderStyle == "none" then
		return 0
	end
	return 3
end

-- Backdrop-Tabelle zu den Einstellungen; neue Tabelle je Änderung, denn SetBackdrop übergeht
-- eine Tabelle, die schon gesetzt ist.
local backdrop, backdropKey
local function Backdrop()
	local db = ns.db
	local key = table.concat({ db.bgFile, db.borderStyle, db.borderSize }, "|")
	if backdrop and key == backdropKey then
		return backdrop
	end
	local file, tile = Background(db.bgFile)
	local inset = Style.Inset()
	backdrop = {
		bgFile = file,
		tile = tile,
		tileSize = tile and 64 or nil,
		insets = { left = inset, right = inset, top = inset, bottom = inset },
	}
	if db.borderStyle == "angular" then
		backdrop.edgeFile = "Interface\\Buttons\\WHITE8X8"
		backdrop.edgeSize = db.borderSize
	elseif db.borderStyle ~= "none" then
		backdrop.edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border"
		backdrop.edgeSize = 14
	end
	backdropKey = key
	return backdrop
end

---------------------------------------------------------------------------
-- Farben je Tooltip
---------------------------------------------------------------------------

local function Unpack(c)
	return c[1], c[2], c[3], c[4] or 1
end

local function ApplyColors(tip)
	local frame = tip.qnBackdrop
	if not frame then
		return
	end
	local bg = tip.qnBg or ns.db.bgColor
	local border = tip.qnBorder or ns.db.borderColor
	frame:SetBackdropColor(Unpack(bg))
	if ns.db.borderStyle ~= "none" then
		frame:SetBackdropBorderColor(Unpack(border))
	end
	-- Verlauf nur auf sichtbarem Hintergrund
	local alpha = bg[4] or 1
	frame.mask:SetShown(ns.db.mask and alpha > 0.01)
	frame.mask:SetAlpha(math.min(1, alpha))
end

-- bg, border: { r, g, b, a } oder nil (= allgemeine Farbe)
function Style.SetColors(tip, bg, border)
	if not tip.qnBackdrop then
		return
	end
	tip.qnBg, tip.qnBorder = bg, border
	ApplyColors(tip)
end

-- nur den Rahmen umfärben (Hintergrund bleibt)
function Style.SetBorder(tip, r, g, b)
	if not tip.qnBackdrop then
		return
	end
	local a = ns.db.borderColor[4] or 1
	tip.qnBorder = { r, g, b, a }
	ApplyColors(tip)
end

function Style.Reset(tip)
	Style.SetColors(tip, nil, nil)
end

---------------------------------------------------------------------------
-- Aufbau
---------------------------------------------------------------------------

local function HideNineSlice(tip)
	if tip.NineSlice then
		tip.NineSlice:Hide()
	end
end

-- Aussehen eines Tooltips vollständig anwenden
local function Apply(tip)
	local frame = tip.qnBackdrop
	if not frame then
		return
	end
	HideNineSlice(tip)
	frame:SetBackdrop(Backdrop())
	local inset = Style.Inset()
	frame.mask:ClearAllPoints()
	frame.mask:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
	frame.mask:SetPoint("BOTTOMRIGHT", frame, "TOPRIGHT", -inset, -MASK_HEIGHT)
	ApplyColors(tip)
	tip:SetScale(ns.db.scale)
end

-- Tooltip einmalig vorbereiten
function Style.Setup(tip)
	if tip.qnStyled or tip:IsForbidden() then
		return
	end
	tip.qnStyled = true

	local frame = CreateFrame("Frame", nil, tip, "BackdropTemplate")
	frame:SetUsingParentLevel(true)
	frame:SetAllPoints(tip)
	tip.qnBackdrop = frame

	-- heller Verlauf über der Kopfzeile
	local mask = frame:CreateTexture(nil, "BORDER", nil, -1)
	mask:SetTexture("Interface\\Tooltips\\UI-Tooltip-Background")
	mask:SetBlendMode("ADD")
	mask:SetGradient("VERTICAL", CreateColor(0, 0, 0, 0), CreateColor(0.9, 0.9, 0.9, 0.4))
	frame.mask = mask

	tip:HookScript("OnShow", function(self)
		HideNineSlice(self)
	end)
	-- GameTooltip und Verwandte; FriendsTooltip ist ein einfacher Rahmen ohne dieses Skript
	if tip:HasScript("OnTooltipCleared") then
		tip:HookScript("OnTooltipCleared", Style.Reset)
	end
	Apply(tip)
end

function Style.ApplyAll()
	for _, tip in ipairs(ns.Tooltips()) do
		Apply(tip)
	end
	Style.ApplyFonts()
end

---------------------------------------------------------------------------
-- Schriften (Font-Objekte, gelten für alle Tooltips)
---------------------------------------------------------------------------

local FLAGS = { default = true, NONE = "", OUTLINE = "OUTLINE", THINOUTLINE = "THINOUTLINE", THICKOUTLINE = "THICKOUTLINE" }

function Style.FlagEntries()
	return {
		{ "default", DEFAULT },
		{ "NONE", L["No Outline"] },
		{ "THINOUTLINE", L["Thin Outline"] },
		{ "OUTLINE", SELF_HIGHLIGHT_OUTLINE },
		{ "THICKOUTLINE", L["Thick Outline"] },
	}
end

function Style.FontEntries()
	local list = { { "default", DEFAULT } }
	for _, e in ipairs(ns.LSMEntries("font")) do
		list[#list + 1] = e
	end
	return list
end

-- Schrift zu Einstellungen: font (LSM-Name oder "default"), size (0 = Vorgabe), flag
function Style.Font(defaultFont, defaultSize, defaultFlag, font, size, flag)
	local file = font ~= "default" and ns.LSMFetch("font", font) or defaultFont
	local s = (size and size > 0) and size or defaultSize
	local f = FLAGS[flag]
	if f == nil or f == true then
		f = defaultFlag
	end
	return file, s, f
end

local defaults   -- Blizzard-Schriften beim ersten Anwenden

function Style.ApplyFonts()
	local db = ns.db
	if not defaults then
		defaults = { header = { GameTooltipHeaderText:GetFont() }, body = { GameTooltipText:GetFont() } }
		-- Schatten wie bei vielen Tooltip-Addons, etwas kräftiger als Blizzards Vorgabe
		for _, font in ipairs({ GameTooltipHeaderText, GameTooltipText, Tooltip_Small }) do
			font:SetShadowOffset(1, -1)
			font:SetShadowColor(0, 0, 0, 0.9)
		end
	end
	local h, b = defaults.header, defaults.body
	GameTooltipHeaderText:SetFont(Style.Font(h[1], h[2], h[3], db.headerFont, db.headerSize, db.headerFlag))
	GameTooltipText:SetFont(Style.Font(b[1], b[2], b[3], db.bodyFont, db.bodySize, db.bodyFlag))
end

---------------------------------------------------------------------------
-- Blizzard stellt das Aussehen bei jedem neuen Inhalt wieder her (TooltipDataHandler,
-- GameTooltip_OnHide): danach NineSlice wieder ausblenden.
---------------------------------------------------------------------------

function Style.Init()
	hooksecurefunc("SharedTooltip_SetBackdropStyle", function(tip)
		if tip.qnStyled then
			HideNineSlice(tip)
		end
	end)
end
