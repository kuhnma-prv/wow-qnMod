-- qnTooltip: Lebensbalken des GameTooltip (GameTooltip.StatusBar, Blizzard setzt Wert 0–1 über
-- UnitPercentHealthFromGUID). Lage, Höhe, Textur, Text (Wert/Prozent/Tot) und Farbe.
-- Lebenswerte können secret sein: sie gehen nur an SetFormattedText bzw. AbbreviateLargeNumbers.

local _, ns = ...
local L = ns.L
local IsSecret = ns.IsSecret

local SB = {}
ns.StatusBar = SB

-- { Schlüssel, Anzeigename, Datei }
SB.TEXTURES = {
	{ "Blizzard", "Blizzard", "Interface\\TargetingFrame\\UI-StatusBar" },
	{ "Flat", L["Flat"], "Interface\\Buttons\\WHITE8X8" },
	{ "Raid", RAID, "Interface\\RaidFrame\\Raid-Bar-Hp-Fill" },
}

function SB.TextureEntries()
	local list, skip = {}, {}
	for _, t in ipairs(SB.TEXTURES) do
		list[#list + 1] = { t[1], t[2] }
		skip[t[1]] = true
	end
	for _, e in ipairs(ns.LSMEntries("statusbar", skip)) do
		list[#list + 1] = e
	end
	return list
end

local function TexturePath(key)
	for _, t in ipairs(SB.TEXTURES) do
		if t[1] == key then
			return t[3]
		end
	end
	return ns.LSMFetch("statusbar", key) or SB.TEXTURES[1][3]
end

local function Bar()
	return GameTooltip.StatusBar
end

-- soll der Balken sichtbar sein dürfen?
local function Allowed()
	return not ns.db.barHide and ns.db.barHeight > 0
end

---------------------------------------------------------------------------
-- Text und Farbe
---------------------------------------------------------------------------

local function UpdateText(bar)
	local db = ns.db
	local text = bar.qnText
	local unit = GameTooltip.qnUnit
	if not unit or not (db.barText or db.barPercent) then
		text:SetText("")
		return
	end
	local dead = UnitIsDeadOrGhost(unit)
	if not IsSecret(dead) and dead then
		if db.barText then
			text:SetFormattedText("|cff999999%s|r |cffffcc33<%s>|r", AbbreviateLargeNumbers(UnitHealthMax(unit)), DEAD)
		else
			text:SetFormattedText("|cffffcc33<%s>|r", DEAD)
		end
		return
	end
	if db.barText and db.barPercent then
		text:SetFormattedText("%s / %s (%.0f%%)", AbbreviateLargeNumbers(UnitHealth(unit)),
			AbbreviateLargeNumbers(UnitHealthMax(unit)), UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
	elseif db.barText then
		text:SetFormattedText("%s / %s", AbbreviateLargeNumbers(UnitHealth(unit)), AbbreviateLargeNumbers(UnitHealthMax(unit)))
	else
		text:SetFormattedText("%.0f%%", UnitHealthPercent(unit, true, CurveConstants.ScaleTo100))
	end
end

local function UpdateColor(bar, value)
	local mode = ns.db.barColor
	local unit = GameTooltip.qnUnit
	if mode == "auto" and unit then
		local r, g, b
		local isPlayer = UnitIsPlayer(unit)
		if not IsSecret(isPlayer) and isPlayer then
			local _, class = UnitClass(unit)
			local c = qnCore.ClassColor(class)
			if c then
				r, g, b = c.r, c.g, c.b
			end
		end
		if not r then
			r, g, b = UnitSelectionColor(unit)
			if ns.AnySecret(r, g, b) then
				return
			end
		end
		bar:SetStatusBarColor(r, g, b)
	elseif mode == "smooth" and value and not IsSecret(value) then
		HealthBar_OnValueChanged(bar, value, true)
	end
end

local function Update(bar, value)
	UpdateText(bar)
	UpdateColor(bar, value)
end
SB.Update = function()
	local bar = Bar()
	if bar and bar.qnText and bar:IsShown() then
		Update(bar, bar:GetValue())
	end
end

---------------------------------------------------------------------------
-- Lage
---------------------------------------------------------------------------

local function Place(bar)
	local db = ns.db
	bar:ClearAllPoints()
	local default = db.borderStyle == "default"
	local edge = db.borderStyle == "angular" and db.borderSize or 0
	if db.barPosition == "bottom" then
		-- auf dem unteren Rand, seitlich innerhalb des Rahmens
		local x = db.barOffsetX ~= 0 and db.barOffsetX or (default and 5 or edge + 1)
		bar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", x, 2)
		bar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -x, 2)
	elseif db.barPosition == "top" then
		-- auf dem oberen Rand
		local x = db.barOffsetX ~= 0 and db.barOffsetX or (default and 4 or edge)
		bar:SetPoint("BOTTOMLEFT", GameTooltip, "TOPLEFT", x, -4)
		bar:SetPoint("BOTTOMRIGHT", GameTooltip, "TOPRIGHT", -x, -4)
	else
		-- unter dem Tooltip (wie Blizzard)
		local x = db.barOffsetX ~= 0 and db.barOffsetX or (default and 2 or 0)
		bar:SetPoint("TOPLEFT", GameTooltip, "BOTTOMLEFT", x, -1)
		bar:SetPoint("TOPRIGHT", GameTooltip, "BOTTOMRIGHT", -x, -1)
	end
end

function SB.Apply()
	local bar = Bar()
	if not (bar and bar.qnText) then
		return
	end
	local db = ns.db
	bar:SetHeight(math.max(1, db.barHeight))
	bar:SetStatusBarTexture(TexturePath(db.barTexture))
	local file, size, flag = ns.Style.Font(bar.qnDefaultFont, 10, "THINOUTLINE", db.barFont, db.barSize, db.barFlag)
	bar.qnText:SetFont(file, size, flag)
	Place(bar)
	if not Allowed() then
		bar:Hide()
	end
	SB.Update()
end

function SB.Init()
	local bar = Bar()
	if not bar then
		return
	end
	local bg = bar:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0.2, 0.2, 0.2, 0.8)
	bar.qnBg = bg
	local text = bar:CreateFontString(nil, "OVERLAY")
	text:SetPoint("CENTER")
	bar.qnDefaultFont = NumberFontNormal:GetFont()
	text:SetFont(bar.qnDefaultFont, 10, "THINOUTLINE")
	bar.qnText = text

	bar:HookScript("OnShow", function(self)
		if not Allowed() then
			self:Hide()
			return
		end
		Update(self, self:GetValue())
	end)
	bar:HookScript("OnValueChanged", function(self, value)
		Update(self, value)
	end)
end
