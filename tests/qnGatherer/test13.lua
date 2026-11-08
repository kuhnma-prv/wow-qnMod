-- Scenario 13: qnGatherer - nodes of a character without the profession: skill/lock error without a
-- gathering cast, name from the world tooltip, position of the player
C_Map.GetMapWorldSize = function() return 2000, 1000 end
C_Map.GetBestMapForUnit = function() return 1429 end
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local DB = gt.DB
local MAP = 1429

local tipName
GameTooltipTextLeft1 = { GetText = function() return tipName end }
local function MouseOver(name, owner)
	tipName = name
	GameTooltip:SetOwner(owner or UIParent, "ANCHOR_CURSOR")
	GameTooltip:Show()
end
local function Format(fmt, s, d)
	local text = fmt:gsub("%%%d?%$?s", s, 1)
	if d then text = text:gsub("%%%d?%$?d", tostring(d), 1) end
	return text
end
local function NodeAt(kind, x, y) return DB.GetNode(kind, MAP, DB.Encode(x, y)) end

-- herb without Herbalism
QN_POS = { 0.4, 0.4 }
MouseOver("Friedensblume")
FireEvent("UI_ERROR_MESSAGE", 1, Format(ERR_USE_LOCKED_WITH_SPELL_S, HERBALISM))
local n = NodeAt("herb", 0.4, 0.4)
Check(n and n.res == "n:herb:Friedensblume" and n.origin == "own", "herb recorded without the profession")
FireEvent("UI_ERROR_MESSAGE", 1, Format(ERR_USE_LOCKED_WITH_SPELL_S, HERBALISM))
Check(NodeAt("herb", 0.4, 0.4).seen == 1, "clicking again: recorded once")

-- the name is already known from another character: object key
DB.Ingest({ t = "res", res = "o:1617", kind = "herb", names = { [GetLocale()] = "Silberblatt" } }, "own")
QN_POS = { 0.6, 0.6 }
MouseOver("Silberblatt")
FireEvent("UI_ERROR_MESSAGE", 1, Format(ERR_USE_LOCKED_WITH_SPELL_S, HERBALISM))
Check(NodeAt("herb", 0.6, 0.6) and NodeAt("herb", 0.6, 0.6).res == "o:1617", "known name gives the object key")

-- ore with required skill
QN_POS = { 0.2, 0.8 }
MouseOver("Mithrilablagerung")
FireEvent("UI_ERROR_MESSAGE", 1, Format(ERR_USE_LOCKED_WITH_SPELL_KNOWN_SI, MINING, 175))
Check(NodeAt("mine", 0.2, 0.8) and DB.GetResource("n:mine:Mithrilablagerung").skill == 175, "ore with required skill")

-- locked chest
QN_POS = { 0.7, 0.2 }
MouseOver("Verbeulte Truhe")
FireEvent("UI_ERROR_MESSAGE", 1, Format(ERR_USE_LOCKED_WITH_SPELL_S, C_Spell.GetSpellName(1804)))
Check(NodeAt("treasure", 0.7, 0.2) ~= nil, "locked chest recorded")

-- ignored: bag item tooltip, hidden tooltip, other errors, no position
local before = DB.CountNodes("herb") + DB.CountNodes("mine") + DB.CountNodes("treasure")
QN_POS = { 0.9, 0.9 }
MouseOver("Verschlossene Kassette", CreateFrame("Button"))
FireEvent("UI_ERROR_MESSAGE", 1, Format(ERR_USE_LOCKED_WITH_SPELL_S, C_Spell.GetSpellName(1804)))
MouseOver("Friedensblume")
GameTooltip:Hide()
FireEvent("UI_ERROR_MESSAGE", 1, Format(ERR_USE_LOCKED_WITH_SPELL_S, HERBALISM))
MouseOver("Friedensblume")
FireEvent("UI_ERROR_MESSAGE", 1, "Out of range.")
QN_POS = nil
FireEvent("UI_ERROR_MESSAGE", 1, Format(ERR_USE_LOCKED_WITH_SPELL_S, HERBALISM))
Check(DB.CountNodes("herb") + DB.CountNodes("mine") + DB.CountNodes("treasure") == before, "nothing recorded from ignored errors")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
