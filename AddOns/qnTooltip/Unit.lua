-- qnTooltip: Einheiten-Tooltips. Nach Blizzards Aufbau (TooltipDataProcessor, Typ Unit) werden die
-- Kopfzeilen durch die Zeilen aus den Bausteinen ersetzt:
--   Spieler: Zeile 1 bis zur Stufenzeile (Name, Gilde, Stufe) und direkt folgende Fraktions-/PvP-Zeilen
--   NSC:     Zeile 1 und die Stufenzeile; die Titelzeile dazwischen bleibt und wird nur umformatiert
-- Welche Zeile die Stufenzeile ist, steht in den Tooltipdaten (Zeilentyp UnitLevel, lineIndex).
-- Übrige Zeilen (Quest-Ziele, Hinweise) bleiben. Dazu Rahmen-/Hintergrundfarbe und Fraktionswappen.

local _, ns = ...
local IsSecret = ns.IsSecret
local UD = ns.UnitData

local Unit = {}
ns.Unit = Unit

local function Plain(v)
	if IsSecret(v) then
		return nil
	end
	return v
end

local function TextIs(text, ...)
	if IsSecret(text) or text == nil then
		return false
	end
	for i = 1, select("#", ...) do
		if text == select(i, ...) then
			return true
		end
	end
	return false
end

-- Einheit des Tooltips. Ist die GUID secret, ist es bei Weltobjekten die Einheit unter der Maus.
local function ResolveUnit(data)
	local guid = data.guid
	if not IsSecret(guid) and guid then
		local unit = UnitTokenFromGUID(guid)
		if not IsSecret(unit) and unit then
			return unit
		end
	end
	if UnitExists("mouseover") then
		return "mouseover"
	end
end
Unit.ResolveUnit = ResolveUnit

local function LineIndex(data, lineType)
	for _, line in ipairs(data.lines or {}) do
		if line.type == lineType then
			return line.lineIndex
		end
	end
end

-- Anfang der Stufenzeile ("Stufe ", aus TOOLTIP_UNIT_LEVEL = "Stufe %s") als Muster
local LEVEL_PREFIX = "^" .. (TOOLTIP_UNIT_LEVEL:match("^(.-)%%") or ""):gsub("%p", "%%%0")

-- Stufenzeile: Zeilentyp UnitLevel, sonst (Forever setzt ihn nicht immer) am Text erkennen
local function LevelLine(data)
	local index = LineIndex(data, Enum.TooltipDataLineType.UnitLevel)
	if index then
		return index
	end
	for _, line in ipairs(data.lines or {}) do
		local text = line.leftText
		if line.lineIndex and line.lineIndex > 1 and not IsSecret(text) and text and text:find(LEVEL_PREFIX) then
			return line.lineIndex
		end
	end
end

-- Zeilen, die die Bausteine ersetzen, und die Titelzeile eines NSC
local function Slots(data, isPlayer, raw)
	local level = LevelLine(data)
	local slots = { 1 }
	if isPlayer then
		local last = level or 1
		if not level then
			-- Texte secret (Instanzen): feste Folge in Forever – Name, [Gilde], Stufe, Klasse, Fraktion
			last = math.min(#(data.lines or {}), (UD.Has(raw.guildName) and 3 or 2) + 2)
		end
		for i = 2, last do
			slots[#slots + 1] = i
		end
		-- direkt folgende Zeilen mit Klasse (Forever: eigene Zeile), Fraktion oder PvP; secret-Texte
		-- dort sind ebenfalls Klasse bzw. Fraktion
		local className, factionName = Plain(raw.className), Plain(raw.factionName)
		for _, line in ipairs(data.lines or {}) do
			if level and line.lineIndex == last + 1 and last < level + 3 and (IsSecret(line.leftText)
				or TextIs(line.leftText, FACTION_ALLIANCE, FACTION_HORDE, PVP, className, factionName)) then
				slots[#slots + 1] = line.lineIndex
				last = line.lineIndex
			end
		end
		return slots
	end
	local title
	if level and level > 1 then
		if level > 2 then
			title = 2
		end
		slots[#slots + 1] = level
	end
	return slots, title
end

local function Write(tip, slots, rows)
	for i, row in ipairs(rows) do
		local index = slots[i]
		local left
		if index then
			left = ns.Left(tip, index)
			local right = ns.Right(tip, index)
			if right then
				right:SetText("")
			end
		else
			left = ns.NewLine(tip)
		end
		left:SetFormattedText(row.pattern, unpack(row.args))
		if i > 1 then
			left:SetTextColor(1, 1, 1)
		end
	end
	for i = #rows + 1, #slots do
		ns.Blank(tip, slots[i])
	end
end

-- NSC-Titel ("<Gastwirt>") nach dem Baustein npcTitle formatieren
local function NpcTitle(tip, index, cfg, raw, gray)
	local e = ns.Element("npc", "npcTitle")
	local c = cfg.elements.npcTitle or e[4]
	if not c.enable then
		return
	end
	local left = ns.Left(tip, index)
	local text = left and left:GetText()
	if not UD.Has(text) then
		return
	end
	if not IsSecret(text) then
		text = text:match("^<(.*)>$") or text
	end
	local fmt = UD.ValidFormat(c.format, "text") and c.format or e[4].format
	local r, g, b
	if gray then
		r, g, b = 0.67, 0.67, 0.67
	else
		r, g, b = UD.Color(c.color, raw)
	end
	if r then
		fmt = "|cff" .. ns.Hex(r, g, b) .. fmt .. "|r"
	end
	left:SetFormattedText(fmt, text)
end

-- Rahmen- und Hintergrundfarbe nach den Einstellungen der Einheitenart
local function Colors(tip, cfg, raw, gray)
	local db = ns.db
	local borderAlpha = db.borderColor[4] or 1
	if gray then
		ns.Style.SetColors(tip, { 0.1, 0.1, 0.1, cfg.bgAlpha }, { 0.6, 0.6, 0.6, borderAlpha })
		return
	end
	local r, g, b
	if cfg.bgColor ~= "default" then
		r, g, b = UD.Color(cfg.bgColor, raw)
	end
	if not r then
		r, g, b = db.bgColor[1], db.bgColor[2], db.bgColor[3]
	end
	local border
	if cfg.borderColor ~= "default" then
		local br, bg, bb = UD.Color(cfg.borderColor, raw)
		if br then
			border = { br, bg, bb, borderAlpha }
		end
	end
	ns.Style.SetColors(tip, { r, g, b, cfg.bgAlpha }, border)
end

-- großes Fraktionswappen oben rechts
local function BigFaction(tip, cfg, raw)
	local file = cfg.bigFaction and UD.BIG_FACTION[Plain(raw.factionGroup) or ""]
	if not file then
		if tip.qnFaction then
			tip.qnFaction:Hide()
		end
		return
	end
	local tex = tip.qnFaction
	if not tex then
		tex = tip.qnBackdrop:CreateTexture(nil, "ARTWORK")
		tex:SetSize(62, 62)
		tex:SetPoint("TOPRIGHT", tip, "TOPRIGHT", 4, 0)
		tex:SetBlendMode("ADD")
		tex:SetAlpha(0.4)
		tip.qnFaction = tex
	end
	tex:SetTexture(file)
	tex:Show()
end

local function OnUnit(tip, data)
	if tip ~= GameTooltip or not data then
		return
	end
	local unit = ResolveUnit(data)
	tip.qnUnit = unit
	if not unit then
		return
	end
	local isPlayer = Plain(UnitIsPlayer(unit)) and true or false
	local kind = isPlayer and "player" or "npc"
	local cfg = ns.db[kind]
	local raw = UD.Collect(unit)
	local gray = cfg.grayDead and Plain(UnitIsDeadOrGhost(unit)) and true or false

	local slots, title = Slots(data, isPlayer, raw)
	Write(tip, slots, UD.Rows(kind, cfg.elements, raw, { gray = gray }))
	if title then
		NpcTitle(tip, title, cfg, raw, gray)
	end
	-- PvP-Zeile eines NSC
	for _, line in ipairs(data.lines or {}) do
		if not isPlayer and line.lineIndex and TextIs(line.leftText, PVP) then
			ns.Blank(tip, line.lineIndex)
		end
	end
	Colors(tip, cfg, raw, gray)
	BigFaction(tip, cfg, raw)
	ns.Target.Add(tip, unit, cfg, isPlayer)
	ns.Model.Show(tip, unit, cfg)
	ns.StatusBar.Update()
end

-- "<Mit Rechtsklick die Rahmen-Einstellungen aufrufen>" samt Leerzeile davor (UnitFrame_UpdateTooltip)
local function OnInstruction(tip, text)
	if tip ~= GameTooltip or not ns.db.hideUnitFrameHint or text ~= UNIT_POPUP_RIGHT_CLICK then
		return
	end
	local n = tip:NumLines()
	ns.Blank(tip, n)
	local before = ns.Left(tip, n - 1)
	local t = before and before:GetText()
	if not IsSecret(t) and t == " " then
		ns.Blank(tip, n - 1)
	end
end

function Unit.Init()
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, OnUnit)
	hooksecurefunc("GameTooltip_AddInstructionLine", OnInstruction)
	GameTooltip:HookScript("OnTooltipCleared", function(tip)
		tip.qnUnit = nil
		if tip.qnFaction then
			tip.qnFaction:Hide()
		end
	end)
end
