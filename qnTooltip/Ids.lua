-- qnTooltip: Gegenstände, Zauber, Auren und Quests: Rahmen nach Qualität bzw. Schwierigkeit,
-- Symbol vor dem Namen und IDs (Gegenstand, Symbol, Stapelgröße, Zauber, Quest).

local _, ns = ...
local L = ns.L
local IsSecret = ns.IsSecret

local Ids = {}
ns.Ids = Ids

local ICON = "|T%s:16:16:0:0:32:32:2:30:2:30|t %s"

local function Plain(v)
	if IsSecret(v) then
		return nil
	end
	return v
end

local function LineIndex(data, lineType)
	for _, line in ipairs(data.lines or {}) do
		if line.type == lineType then
			return line.lineIndex
		end
	end
	return 1
end

-- Symbol vor den Text einer Zeile (der Text darf secret sein)
local function PrefixIcon(tip, index, icon)
	local left = ns.Left(tip, index)
	local text = left and left:GetText()
	if icon and ns.UnitData.Has(text) then
		left:SetFormattedText(ICON, icon, text)
	end
end

local function IdsAllowed()
	return not ns.db.idsWithModifier or ns.AnyModifier()
end

-- Zeilen { Beschriftung, Wert } unter einer Leerzeile anhängen
local function AddIds(tip, list)
	if #list == 0 then
		return
	end
	tip:AddLine(" ")
	for _, e in ipairs(list) do
		tip:AddLine(("%s: |cffffffff%s|r"):format(e[1], tostring(e[2])), 0, 1, 0.8)
	end
end

---------------------------------------------------------------------------
-- Gegenstände
---------------------------------------------------------------------------

local function OnItem(tip, data)
	if not ns.IsStyled(tip) or not data then
		return
	end
	local db = ns.db
	local id = Plain(data.id)
	if not id then
		return
	end
	if db.itemBorder then
		local quality = C_Item.GetItemQualityByID(id)
		if quality then
			local r, g, b = C_Item.GetItemQualityColor(quality)
			ns.Style.SetBorder(tip, r, g, b)
		end
	end
	local icon = C_Item.GetItemIconByID(id)
	if db.itemIcon then
		PrefixIcon(tip, LineIndex(data, Enum.TooltipDataLineType.ItemName), icon)
	end
	if IdsAllowed() then
		local list = {}
		if db.itemId then
			list[#list + 1] = { L["Gegenstands-ID"], id }
		end
		if db.itemIconId and icon then
			list[#list + 1] = { L["Symbol-ID"], icon }
		end
		local stack = db.itemMaxStack and select(8, C_Item.GetItemInfo(id))
		if stack and stack > 1 then
			list[#list + 1] = { AUCTION_STACK_SIZE, stack }
		end
		AddIds(tip, list)
	end
end

---------------------------------------------------------------------------
-- Zauber und Auren
---------------------------------------------------------------------------

local function SpellIds(tip, id, icon)
	local db = ns.db
	if not IdsAllowed() then
		return
	end
	local list = {}
	if db.spellId then
		list[#list + 1] = { L["Zauber-ID"], id }
	end
	if db.spellIconId and icon then
		list[#list + 1] = { L["Symbol-ID"], icon }
	end
	AddIds(tip, list)
end

local function OnSpell(tip, data)
	if not ns.IsStyled(tip) or not data then
		return
	end
	local db = ns.db
	ns.Style.SetColors(tip, db.spellBgColor, db.spellBorderColor)
	local id = Plain(data.id)
	if not id then
		return
	end
	local icon = C_Spell.GetSpellTexture(id)
	if db.spellIcon then
		PrefixIcon(tip, LineIndex(data, Enum.TooltipDataLineType.SpellName), icon)
	end
	SpellIds(tip, id, icon)
end

local function OnAura(tip, data)
	if not ns.IsStyled(tip) or not data then
		return
	end
	local id = Plain(data.id)
	if id then
		SpellIds(tip, id, C_Spell.GetSpellTexture(id))
	end
end

---------------------------------------------------------------------------
-- Quests
---------------------------------------------------------------------------

local function OnQuest(tip, data)
	if not ns.IsStyled(tip) or not data then
		return
	end
	local db = ns.db
	local id = Plain(data.id)
	if not id then
		return
	end
	if db.questBorder then
		local level = C_QuestLog.GetQuestDifficultyLevel(id)
		if level then
			local c = GetQuestDifficultyColor(level < 0 and UnitLevel("player") or level)
			ns.Style.SetBorder(tip, c.r, c.g, c.b)
		end
	end
	if db.questId and IdsAllowed() then
		AddIds(tip, { { L["Quest-ID"], id } })
	end
end

function Ids.Init()
	local T = Enum.TooltipDataType
	TooltipDataProcessor.AddTooltipPostCall(T.Item, OnItem)
	TooltipDataProcessor.AddTooltipPostCall(T.Spell, OnSpell)
	TooltipDataProcessor.AddTooltipPostCall(T.UnitAura, OnAura)
	TooltipDataProcessor.AddTooltipPostCall(T.Quest, OnQuest)
end
