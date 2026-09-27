-- qnBuffMod: ein Eintrag eines Fensters (Symbol, bei Stil 1 mit Leiste, Name und Restzeit).
-- Aufbau (Setup) hängt nur an der Darstellung des Fensters (look), Zeichnen (Paint) am Record.

local _, ns = ...
local E = ns.enum
local K = ns.kind

local Entry = {}
ns.Entry = Entry

local BAR_TEXTURE = "Interface\\TargetingFrame\\UI-StatusBar"
local SPARK_TEXTURE = "Interface\\CastingBar\\UI-CastingBar-Spark"
local GOLD = { 1, 0.82, 0 }
local RED = { 1, 0, 0 }
local TRIM = 0.08   -- beschnittener Symbolrand je Seite

---------------------------------------------------------------------------
-- Schriften
---------------------------------------------------------------------------

local largeFonts

-- Schriftobjekte für Name und Zeit je Schriftgröße (3 = Grundschrift + 2 pt)
local function Fonts(size)
	if size == E.font.SMALL then
		return GameFontNormalSmall, ChatFontSmall
	elseif size == E.font.LARGE then
		if not largeFonts then
			largeFonts = {}
			for i, base in ipairs({ GameFontNormal, ChatFontNormal }) do
				local font = CreateFont(i == 1 and "qnBuffModFontNameLarge" or "qnBuffModFontTimeLarge")
				font:CopyFontObject(base)
				local path, height, flags = base:GetFont()
				font:SetFont(path, (height or 12) + 2, flags or "")
				largeFonts[i] = font
			end
		end
		return largeFonts[1], largeFonts[2]
	end
	return GameFontNormal, ChatFontNormal
end

---------------------------------------------------------------------------
-- Anlegen
---------------------------------------------------------------------------

function Entry.New(win, parent)
	local e = CreateFrame("Button", nil, parent)
	e.win = win
	e:EnableMouse(true)

	e.border = e:CreateTexture(nil, "BACKGROUND")
	e.icon = e:CreateTexture(nil, "ARTWORK")
	e.symbol = e:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	e.count = e:CreateFontString(nil, "OVERLAY", "NumberFontNormal")

	e.detail = CreateFrame("Frame", nil, e)
	e.barBG = e.detail:CreateTexture(nil, "BACKGROUND")
	e.barBG:SetTexture(BAR_TEXTURE)
	e.bar = e.detail:CreateTexture(nil, "BORDER")
	e.bar:SetTexture(BAR_TEXTURE)
	e.spark = e.detail:CreateTexture(nil, "ARTWORK")
	e.spark:SetTexture(SPARK_TEXTURE)
	e.spark:SetBlendMode("ADD")
	e.nameText = e.detail:CreateFontString(nil, "OVERLAY")
	e.timeText = e:CreateFontString(nil, "OVERLAY")
	for _, fs in ipairs({ e.nameText, e.timeText }) do
		fs:SetWordWrap(false)
	end
	return e
end

-- Aufbau nach der Darstellung des Fensters
function Entry.Setup(e, look)
	e.lookVersion = look.version
	local size = look.size
	e:SetSize(size + look.bar, size)

	e.icon:ClearAllPoints()
	e.icon:SetSize(size, size)
	e.icon:SetPoint(look.iconRight and "RIGHT" or "LEFT", e, look.iconRight and "RIGHT" or "LEFT", 0, 0)
	if look.fullIcon then
		e.icon:SetTexCoord(0, 1, 0, 1)
	else
		e.icon:SetTexCoord(TRIM, 1 - TRIM, TRIM, 1 - TRIM)
	end
	e.border:ClearAllPoints()
	e.border:SetPoint("TOPLEFT", e.icon, "TOPLEFT", -1, 1)
	e.border:SetPoint("BOTTOMRIGHT", e.icon, "BOTTOMRIGHT", 1, -1)
	e.symbol:ClearAllPoints()
	e.symbol:SetPoint("TOPLEFT", e.icon, "TOPLEFT", 1, -1)
	e.count:ClearAllPoints()
	e.count:SetPoint("BOTTOMRIGHT", e.icon, "BOTTOMRIGHT", 0, 1)

	local nameFont, timeFont = Fonts(look.font)
	e.nameText:SetFontObject(nameFont)
	e.timeText:SetFontObject(timeFont)

	e.detail:ClearAllPoints()
	e.timeText:ClearAllPoints()
	if look.bar > 0 then
		e.detail:SetSize(look.bar, size)
		e.detail:SetPoint(look.iconRight and "RIGHT" or "LEFT", e.icon, look.iconRight and "LEFT" or "RIGHT", 0, 0)
		e.detail:Show()
		e.timeText:SetParent(e.detail)
		e.barBG:ClearAllPoints()
		e.barBG:SetAllPoints(e.detail)
		e.bar:ClearAllPoints()
		e.bar:SetHeight(size)
		e.bar:SetPoint(look.iconRight and "RIGHT" or "LEFT", e.detail, look.iconRight and "RIGHT" or "LEFT", 0, 0)
		e.spark:SetSize(math.min(size * 2 / 3, 25), size * 1.9)
	else
		e.detail:SetSize(0, size)
		e.detail:Hide()
		e.timeText:SetParent(e)
		if look.style == E.style.ICON then
			-- Stil 2: Restzeit an einer Seite des Symbols
			local sp = look.dataSpacing
			local side = look.dataSide
			if side == E.dataSide.LEFT then
				e.timeText:SetPoint("RIGHT", e, "LEFT", -sp, 0)
			elseif side == E.dataSide.RIGHT then
				e.timeText:SetPoint("LEFT", e, "RIGHT", sp, 0)
			elseif side == E.dataSide.ABOVE then
				e.timeText:SetPoint("BOTTOM", e, "TOP", 0, sp)
			elseif side == E.dataSide.CENTER then
				e.timeText:SetPoint("CENTER", e, "CENTER", 0, 0)
			else
				e.timeText:SetPoint("TOP", e, "BOTTOM", 0, -sp)
			end
			e.timeText:SetJustifyH("CENTER")
		end
	end
	e.textLayout = nil
end

---------------------------------------------------------------------------
-- Name und Restzeit in der Leiste (Stil 1)
---------------------------------------------------------------------------

local function Justify(value, default)
	if value == E.justify.LEFT then
		return "LEFT"
	elseif value == E.justify.RIGHT then
		return "RIGHT"
	elseif value == E.justify.CENTER then
		return "CENTER"
	end
	return default
end

-- Über die ganze Leiste (mit Textabständen, außer bei "Mittig")
local function Full(fs, detail, look, justify)
	local l, r = look.padLeft, look.padRight
	if justify == "CENTER" then
		l, r = 0, 0
	end
	fs:SetPoint("LEFT", detail, "LEFT", l, 0)
	fs:SetPoint("RIGHT", detail, "RIGHT", -r, 0)
	fs:SetJustifyH(justify)
end

-- Anordnung der Texte; mode fasst zusammen, was sichtbar ist (neu nur bei Änderung)
local function LayoutTexts(e, look, showName, showTime)
	local name, time, detail = e.nameText, e.timeText, e.detail
	local towardIcon = look.iconRight and "RIGHT" or "LEFT"
	local loc = look.timeAt
	if loc == E.timeAt.DEFAULT then
		loc = look.iconRight and E.timeAt.LEFT or E.timeAt.RIGHT
	end
	local beside = showName and showTime and (loc == E.timeAt.LEFT or loc == E.timeAt.RIGHT)
	local fits = true
	if beside then
		fits = time:GetStringWidth() + look.padLeft + look.padRight <= look.bar
	end
	local mode = (showName and "n" or "") .. (showTime and "t" or "") .. (beside and (fits and "b" or "o") or "")
	if e.textLayout == mode then
		return
	end
	e.textLayout = mode
	name:ClearAllPoints()
	time:ClearAllPoints()
	e.besideName = false
	e.timeOnly = false

	if beside and not fits then
		-- nicht einmal die Zeit passt neben den Namen: nur die Zeit, bündig zur Symbolseite
		name:Hide()
		time:Show()
		e.timeOnly = true
		Full(time, detail, look, towardIcon)
		return
	end
	name:SetShown(showName)
	time:SetShown(showTime)
	if beside then
		e.besideName = true
		if loc == E.timeAt.LEFT then
			local just = Justify(look.nameJustWithTime, "RIGHT")
			time:SetPoint("LEFT", detail, "LEFT", look.padLeft, 0)
			name:SetPoint("RIGHT", detail, "RIGHT", just == "CENTER" and 0 or -look.padRight, 0)
			name:SetPoint("LEFT", time, "RIGHT", 0, 0)
			name:SetJustifyH(just)
		else
			local just = Justify(look.nameJustWithTime, "LEFT")
			time:SetPoint("RIGHT", detail, "RIGHT", -look.padRight, 0)
			name:SetPoint("LEFT", detail, "LEFT", just == "CENTER" and 0 or look.padLeft, 0)
			name:SetPoint("RIGHT", time, "LEFT", 0, 0)
			name:SetJustifyH(just)
		end
		time:SetJustifyH(loc == E.timeAt.LEFT and "LEFT" or "RIGHT")
	elseif showName and showTime then
		-- Zeit über bzw. unter dem Namen, beide über die ganze Leiste
		local nameJust = Justify(look.nameJustNoTime, towardIcon)
		local timeJust = Justify(look.timeJustNoName, towardIcon)
		local upper, lower = time, name
		local upperJust, lowerJust = timeJust, nameJust
		if loc == E.timeAt.BELOW then
			upper, lower, upperJust, lowerJust = name, time, nameJust, timeJust
		end
		local function Pad(just)
			if just == "CENTER" then
				return 0, 0
			end
			return look.padLeft, look.padRight
		end
		local l, r = Pad(upperJust)
		upper:SetPoint("BOTTOMLEFT", detail, "LEFT", l, 0)
		upper:SetPoint("BOTTOMRIGHT", detail, "RIGHT", -r, 0)
		upper:SetJustifyH(upperJust)
		l, r = Pad(lowerJust)
		lower:SetPoint("TOPLEFT", detail, "LEFT", l, 0)
		lower:SetPoint("TOPRIGHT", detail, "RIGHT", -r, 0)
		lower:SetJustifyH(lowerJust)
	elseif showName then
		Full(name, detail, look, Justify(look.nameJustNoTime, towardIcon))
	elseif showTime then
		Full(time, detail, look, Justify(look.timeJustNoName, towardIcon))
	end
end

---------------------------------------------------------------------------
-- Zeichnen
---------------------------------------------------------------------------

local function DispelColor(rec)
	local c = AuraUtil.GetAuraBorderColor(rec.dispel or "None")
	return c.r, c.g, c.b
end

-- Leistenfarbe eines Records (r, g, b, a)
local function BarColor(rec, look)
	if rec.kind == K.DEBUFF and look.colorBackground then
		local r, g, b = DispelColor(rec)
		return r, g, b, 1
	end
	local c = ns.db["bgColor" .. rec.kind]
	if not ns.ValidColor(c) then
		c = ns.defaults["bgColor" .. rec.kind]
	end
	return c[1], c[2], c[3], c[4]
end

local function NameColor(rec, look)
	if rec.kind == K.DEBUFF then
		if look.colorNames then
			if rec.dispel then
				return DispelColor(rec)
			end
			return GOLD[1], GOLD[2], GOLD[3]
		elseif not look.barShown then
			return RED[1], RED[2], RED[3]
		end
	end
	return GOLD[1], GOLD[2], GOLD[3]
end

local function InRange(unit)
	if unit == "player" then
		return true
	end
	return qnCore.Plain(UnitInRange(unit), false) == true
end

-- Restzeit, Leiste, Blinken; plant die nächste Aktualisierung (e.nextUpdate)
function Entry.UpdateTime(e, now)
	local rec, look = e.rec, e.look
	if not rec then
		return
	end
	local timed = ns.Auras.HasExpiry(rec) and not rec.outOfRange
	local remaining = timed and rec.expiration - now or 0

	-- Blinken: nur mit Ablauf, nicht außer Reichweite; flashTime 0 = nie
	local flash = ns.db.flashTime
	e.flashing = timed and flash > 0 and remaining <= flash and (remaining > 0 or InRange(e.win.unit)) or false
	e.icon:SetAlpha(e.flashing and ns.Pulse(now) or 1)

	local showTime = timed and look.showTimers
	if showTime then
		e.timeText:SetText(ns.FormatTime(remaining, look.timeFormat, look.showDays))
	else
		e.timeText:SetText("")
	end

	if look.bar > 0 then
		if look.barShown and look.timerBar and timed then
			local frac = math.max(0, math.min(1, remaining / rec.duration))
			local width = look.bar * frac
			if width < 0.5 then
				e.bar:Hide()
				e.spark:Hide()
			else
				e.bar:SetWidth(width)
				e.bar:Show()
				e.spark:ClearAllPoints()
				e.spark:SetPoint("CENTER", e.bar, look.iconRight and "LEFT" or "RIGHT", 0, 0)
				e.spark:Show()
			end
		elseif look.barShown then
			e.bar:SetWidth(look.bar)
			e.bar:Show()
			e.spark:Hide()
		end
		LayoutTexts(e, look, look.showNames, showTime and true or false)
	else
		e.timeText:SetShown(look.style == E.style.ICON and look.showTimers)
	end
	e.nextUpdate = timed and now + ns.UpdateInterval(remaining, e.flashing) or nil
end

-- Record zeichnen
function Entry.Paint(e, rec, look, now)
	e.rec, e.look = rec, look
	e.icon:SetTexture(rec.icon)
	e.count:SetText(rec.count and rec.count > 1 and rec.count or "")

	-- Rahmen und Farbenblind-Symbol für Schwächungszauber
	if rec.kind == K.DEBUFF and look.colorIcons then
		local c = AuraUtil.GetAuraBorderColor(rec.dispel or "None")
		e.border:SetColorTexture(c.r, c.g, c.b, 1)
		e.border:Show()
		AuraUtil.SetAuraSymbol(e.symbol, rec.dispel or "None")
	else
		e.border:Hide()
		e.symbol:Hide()
	end

	if look.bar > 0 then
		local r, g, b, a = BarColor(rec, look)
		if look.barShown then
			e.bar:SetVertexColor(r, g, b, a)
			e.bar:Show()
		else
			e.bar:Hide()
		end
		local bgShown = look.barShown and look.timerBar and look.timerBackground
		if bgShown then
			e.barBG:SetVertexColor(r / 1.35, g / 1.35, b / 1.35, a / 2)
		end
		e.barBG:SetShown(bgShown and true or false)
		e.spark:Hide()
		e.nameText:SetText(rec.name)
		e.nameText:SetTextColor(NameColor(rec, look))
	else
		e.nameText:Hide()
	end
	e.textLayout = nil
	Entry.UpdateTime(e, now)
end
