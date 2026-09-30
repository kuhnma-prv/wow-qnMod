-- Scenario 2: qnLoadout - item names: English (Items.json) <-> client language in macro texts; names not in
-- the cache are requested after login and before loading, loading waits for ITEM_DATA_LOAD_RESULT
-- (or the timeout, then the English name stays and is reported); export translates back.

function UnitClass() return "Priester", "PRIEST" end
QN_SPELLS = { [100] = "Heilen" }
QN_ITEM_NAMES = { [5509] = "Gesundheitsstein" }   -- only the healthstone is cached

local core = LoadAddon("qnCore")
local nkp = LoadAddon("qnNumKeyPad")
local lo = LoadAddon("qnLoadout")
local L = lo.L
lo.SPELLS = { ["Heal"] = 100 }
lo.ITEMS = { ["Healthstone"] = 5509, ["Minor Healing Potion"] = 118, ["Linen Bandage"] = 1251 }
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(3)

Check(QN_ITEM_REQUESTS[118] and QN_ITEM_REQUESTS[1251] and not QN_ITEM_REQUESTS[5509], "after login: missing item names requested")
local missing = lo.MissingItems()
Check(#missing == 2 and missing[1] == "Linen Bandage" and missing[2] == "Minor Healing Potion", "missing items (sorted)")

local SET = {
	name = "Items", class = "PRIEST",
	macros = { { name = "qnHealItems", scope = "char", body = "#showtooltip\n/use Healthstone\n/use Minor Healing Potion\n/cast Heal" } },
	numpad = { { key = "NUMPAD2", macro = "qnHealItems" } },
}
local function Macro(name)
	for index, m in pairs(QN_MACROS) do
		if type(m) == "table" and m[1] == name then return index, m end
	end
end

---------------------------------------------------------------------------
-- Loading waits for the item names
---------------------------------------------------------------------------
Check(lo.LoadSet(SET) == nil and Macro("qnHealItems") == nil, "item names missing: loading waits")
QN_ITEM_NAMES[118] = "Schwacher Heiltrank"
FireEvent("ITEM_DATA_LOAD_RESULT", 118, true)
Check(Macro("qnHealItems") == nil, "one item still missing: still waiting")
QN_ITEM_NAMES[1251] = "Leinenverband"
FireEvent("ITEM_DATA_LOAD_RESULT", 1251, true)
local _, macro = Macro("qnHealItems")
Check(macro and macro[3] == "#showtooltip\n/use Gesundheitsstein\n/use Schwacher Heiltrank\n/cast Heilen",
	"all loaded: macro created with item and spell names of the client: " .. tostring(macro and macro[3]))
Check(QN_ACTIONS[146] and QN_ACTIONS[146].text == "qnHealItems", "numpad key assigned after waiting")

-- all names known: loading happens right away
local report = lo.LoadSet(SET)
Check(report and report.updated == 1 and #report.skipped == 0, "names known: loaded right away")

---------------------------------------------------------------------------
-- Timeout: the name stays English and is reported
---------------------------------------------------------------------------
lo.ITEMS["Wool Bandage"] = 3530
local OTHER = {
	name = "Wool", class = "PRIEST",
	macros = { { name = "qnBandage", scope = "char", body = "/use Wool Bandage" } },
	numpad = {},
}
Check(lo.LoadSet(OTHER) == nil and Macro("qnBandage") == nil and QN_ITEM_REQUESTS[3530], "unknown item requested, waiting")
local chat = {}
local print0 = lo.Print
lo.Print = function(msg) chat[#chat + 1] = msg end
RunTimers()
lo.Print = print0
local _, bandage = Macro("qnBandage")
Check(bandage and bandage[3] == "/use Wool Bandage", "after the timeout: loaded, English name kept")
local reported = false
for _, line in ipairs(chat) do
	if line == L["Skipped: %s"]:format(L["Item %s: name not loaded, stays in English in the macros."]:format("Wool Bandage")) then reported = true end
end
Check(reported, "missing item reported")
QN_ITEM_NAMES[3530] = "Wollverband"

---------------------------------------------------------------------------
-- Export: item names back into English
---------------------------------------------------------------------------
lo.ui.panel:Show()
lo.ui.name:SetText("Items Export")
lo.ui.export._scripts.OnClick()
local json = lo.ui.output.box:GetText()
Check(json:find('"body": "#showtooltip\\n/use Healthstone\\n/use Minor Healing Potion\\n/cast Heal"', 1, true),
	"export: macro text with English item and spell names")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
