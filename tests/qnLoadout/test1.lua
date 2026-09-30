-- Scenario 1: qnLoadout - sets of the player's class, loading (qn macros created/changed, other macros
-- untouched, account/character conflict, numpad keys incl. Ctrl set, clear, skipped entries with reasons,
-- not in combat), English spell names <-> client language (Spells.json), options page (set choice remembered
-- per class), export (JSON with English names, stored in the saved variable).

function UnitClass() return "Priester", "PRIEST" end
QN_SPELLS = { [100] = "Heilen", [101] = "Blitzheilung", [102] = "Große Heilung", [103] = "Erneuerung" }
QN_MACROS = {
	[1] = { "Angriff", 1, "/startattack" },
	[2] = { "qnAll", 1, "old account" },
	[121] = { "qnHeal", 1, "old heal" },
}
QN_NUM_MACROS = { 2, 1 }

local core = LoadAddon("qnCore")
local nkp = LoadAddon("qnNumKeyPad")
local lo = LoadAddon("qnLoadout")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)
local L = lo.L

Check(qnNumKeyPad == nkp and qnNumKeyPad.SlotOfBinding and qnNumKeyPad.SetSlotSpell, "qnNumKeyPad: global API")
Check(qnLoadoutDB.settingsVersion == "1.0" and type(qnLoadoutDB.exports) == "table", "saved variable prepared")

-- generated Data.lua: loaded, every English spell name of the sets is in the dictionary
local consistent = type(lo.SETS) == "table" and type(lo.SPELLS) == "table"
for _, set in ipairs(lo.SETS or {}) do
	for _, e in ipairs(set.numpad or {}) do
		if type(e.spell) == "string" and not lo.SPELLS[e.spell] then consistent = false end
	end
end
Check(consistent, "Data.lua loaded and consistent (" .. #(lo.SETS or {}) .. " sets)")

local HEAL = {
	name = "Heilung", class = "PRIEST", desc = "Gruppe heilen",
	macros = {
		{ name = "qnHeal", scope = "char", body = "#showtooltip\n/cast Heal" },        -- exists: changed
		{ name = "qnShield", scope = "char", icon = 135940, body = "/cast Schild" }, -- new character macro
		{ name = "qnWave", scope = "account", body = "/wave" },                      -- new account macro
		{ name = "qnAll", scope = "char", body = "new" },                            -- exists as account macro
		{ name = "Heal", scope = "char", body = "x" },                               -- not a qn macro
	},
	numpad = {
		{ key = "NUMPAD1", spell = 100 },
		{ key = "NUMPAD2", macro = "qnShield" },
		{ key = "NUMPAD3", set = "ctrl", spell = "Flash Heal" },
		{ key = "NUMPAD4", empty = true },
		{ key = "NUMPAD5", spell = 999 },
		{ key = "NUMPADMINUS", set = "ctrl", spell = 100 },
		{ key = "NUMPAD6", set = "alt", spell = 100 },
		{ key = "ENTER", spell = 100 },
		{ key = "NUMPAD7", macro = "Angriff" },
		{ key = "NUMPAD8", macro = "qnMissing" },
		{ key = "NUMPAD9", spell = "Smite" },
	},
}
lo.SETS = {
	{ name = "Schatten", class = "PRIEST", macros = {}, numpad = { { key = "NUMPAD9", spell = 101 } } },
	HEAL,
	{ name = "Frost", class = "MAGE", macros = {}, numpad = {} },
}
lo.SPELLS = { ["Heal"] = 100, ["Flash Heal"] = 101, ["Greater Heal"] = 102 }
lo.ITEMS = {}   -- items: scenario 2

---------------------------------------------------------------------------
-- Spell names: English (sets) <-> client language
---------------------------------------------------------------------------
Check(lo.ClientSpellName("Flash Heal") == "Blitzheilung" and lo.EnglishSpellName("Heilen") == "Heal", "single names")
Check(lo.ClientSpellName("Smite") == nil and lo.EnglishSpellName("Erneuerung") == nil, "names outside Spells.json: nil")
local english = "#showtooltip Greater Heal\n/cast [@mouseover,help][] Heal; Flash Heal\n/say Healing Heal!"
local client = lo.MacroToClient(english)
Check(client == "#showtooltip Große Heilung\n/cast [@mouseover,help][] Heilen; Blitzheilung\n/say Healing Heilen!",
	"macro text into the client language (longest name first, whole words only): " .. client)
Check(lo.MacroToEnglish(client) == english, "and back into English")
Check(lo.MacroToClient("/cast Heal") == "/cast Heilen" and lo.MacroToClient("/cast Heals") == "/cast Heals", "word boundaries")

---------------------------------------------------------------------------
-- Sets of the class
---------------------------------------------------------------------------
local sets = lo.SetsForClass("PRIEST")
Check(#sets == 2 and sets[1].name == "Heilung" and sets[2].name == "Schatten", "only the priest sets, sorted by name")

---------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------
QN_ACTIONS[148] = { type = "spell", id = 100 }   -- NUMPAD4, cleared by the set
QN_COMBAT = true
Check(lo.LoadSet(HEAL) == nil and #QN_MACRO_CALLS == 0 and QN_ACTIONS[145] == nil, "not in combat")
QN_COMBAT = false
QN_CURSOR = { type = "item", id = 1 }
Check(lo.LoadSet(HEAL) == nil and #QN_MACRO_CALLS == 0, "not with something on the cursor")
QN_CURSOR = nil

local report = lo.LoadSet(HEAL)
Check(report ~= nil, "set loaded")
Check(report.created == 2 and report.updated == 1, ("macros: 2 created, 1 changed (%d/%d)"):format(report.created, report.updated))
local function Macro(name)
	for index, m in pairs(QN_MACROS) do
		if type(m) == "table" and m[1] == name then return index, m end
	end
end
local hi, heal = Macro("qnHeal")
Check(hi > 120 and heal[3] == "#showtooltip\n/cast Heilen", "qnHeal changed in place, text in the client language")
local si = Macro("qnShield")
local wi = Macro("qnWave")
Check(si and si > 120 and wi and wi <= 120, "qnShield as character macro, qnWave as account macro")
Check(QN_MACROS[si][2] == 135940 and QN_MACROS[wi][2] == 134400, "icon from the set, otherwise the question mark")
local _, all = Macro("qnAll")
local _, attack = Macro("Angriff")
Check(all[3] == "old account" and attack[3] == "/startattack", "account qnAll and the non-qn macro untouched")
Check(Macro("Heal") == nil, "macro without qn prefix not created")

Check(QN_ACTIONS[145] and QN_ACTIONS[145].id == 100, "NUMPAD1: spell in slot 145")
Check(QN_ACTIONS[146] and QN_ACTIONS[146].type == "macro" and QN_ACTIONS[146].text == "qnShield", "NUMPAD2: macro qnShield")
Check(QN_ACTIONS[171] and QN_ACTIONS[171].id == 101, "Ctrl + NUMPAD3: English name 'Flash Heal' placed as Blitzheilung in slot 171 (page 15)")
Check(QN_ACTIONS[148] == nil, "NUMPAD4 cleared")
Check(QN_ACTIONS[151] and QN_ACTIONS[151].text == "Angriff", "NUMPAD7: existing non-qn macro placed")
Check(report.set == 4 and report.cleared == 1, ("numpad: 4 set, 1 cleared (%d/%d)"):format(report.set, report.cleared))
Check(#report.skipped == 8, "8 entries skipped: " .. #report.skipped)
local skipped = table.concat(report.skipped, "|")
local function Has(text) return skipped:find(text, 1, true) ~= nil end
Check(Has(L["Macro %s: the name must start with \"qn\"."]:format("Heal")), "reason: name without qn")
Check(Has(L["Macro %s: exists as an account macro – the set wants a character macro."]:format("qnAll")), "reason: other kind")
Check(Has(L["%s: spell %s is not known."]:format("NUMPAD5", "999")), "reason: unknown spell")
Check(Has(L["%s: keys 13 and higher do not switch with Ctrl or Alt."]:format(CTRL_KEY_TEXT .. "-NUMPADMINUS")), "reason: key 13 in the Ctrl set")
Check(Has(L["%s: this set is switched off in qnNumKeyPad."]:format(ALT_KEY_TEXT .. "-NUMPAD6")), "reason: Alt set off")
Check(Has(L["%s: this key is not on the bar with the current keyboard layout."]:format("ENTER")), "reason: hidden key")
Check(Has(L["%s: macro %s not found."]:format("NUMPAD8", "qnMissing")), "reason: macro missing")
Check(Has(L["%s: spell %s is not in Spells.json."]:format("NUMPAD9", "Smite")), "reason: English name not in Spells.json")
Check(QN_CURSOR == nil, "cursor empty afterwards")

-- loading again only changes, creates nothing
local calls = #QN_MACRO_CALLS
report = lo.LoadSet(HEAL)
Check(report.created == 0 and report.updated == 3 and #QN_MACRO_CALLS == calls + 3, "second load: 3 macros changed, none created")

---------------------------------------------------------------------------
-- Options page
---------------------------------------------------------------------------
local ui = lo.ui
ui.panel:Show()
Check(ui.set._text == "Heilung" and #ui.set._radios == 2, "set dropdown: priest sets, first one chosen")
Check(ui.summary:GetText():find("Gruppe heilen", 1, true) and ui.summary:GetText():find(L["%d macros, %d numpad keys"]:format(5, 11), 1, true),
	"summary: description and counts")
ui.set:PickRadio(2)
Check(ui.set._text == "Schatten" and qnLoadoutDB.lastSet.PRIEST == "Schatten", "choice remembered per class")
Check(lo.SelectedSet().name == "Schatten", "selected set")
StaticPopupDialogs.QNLOADOUT_LOAD.OnAccept(nil, nil)
Check(QN_ACTIONS[153] and QN_ACTIONS[153].id == 101, "confirmation loads the chosen set (NUMPAD9)")

---------------------------------------------------------------------------
-- Export
---------------------------------------------------------------------------
QN_ACTIONS[147] = { type = "item", id = 5, text = "Trank" }   -- NUMPAD3: other content
QN_ACTIONS[149] = { type = "spell", id = 103 }                 -- NUMPAD5: spell outside Spells.json
ui.name:SetText("Priester Test")
ui.export._scripts.OnClick()
local json = ui.output.box:GetText()
Check(ui.output:IsShown() and json:find('"class": "PRIEST"', 1, true), "export shown")
Check(json:find('{ "key": "NUMPAD1", "spell": "Heal" }', 1, true), "spell by English name")
Check(json:find('{ "key": "NUMPAD5", "spell": 103, "name": "Erneuerung" }', 1, true), "spell outside Spells.json: ID with client name")
Check(json:find('{ "key": "NUMPAD2", "macro": "qnShield" }', 1, true), "macro by name")
Check(json:find('{ "key": "NUMPAD4", "empty": true }', 1, true), "empty key listed")
Check(json:find('{ "key": "NUMPAD3", "set": "ctrl", "spell": "Flash Heal" }', 1, true), "Ctrl set exported")
Check(not json:find('"key": "NUMPAD3", "spell"', 1, true) and not json:find('"key": "NUMPAD3", "empty"', 1, true), "other content (item) left out")
Check(not json:find('"set": "alt"', 1, true), "switched-off Alt set not exported")
Check(json:find('"name": "qnShield"', 1, true) and json:find('"name": "qnHeal"', 1, true), "qn character macros exported")
Check(json:find('"name": "qnShield",%s*"scope": "char",%s*"icon": 135940') ~= nil, "macro icon saved in the export")
Check(json:find('"scope": "char"', 1, true) and json:find('"body": "#showtooltip\\n/cast Heal"', 1, true), "macro with scope, text in English and escaped")
Check(not json:find('"name": "Angriff"', 1, true) and not json:find('"name": "qnWave"', 1, true), "no non-qn macros, no unused account macros")
local stored = qnLoadoutDB.exports["Priester Test"]
Check(stored and stored.class == "PRIEST" and stored.json:find('"class":"PRIEST"', 1, true) and not stored.json:find("\n", 1, true),
	"stored compactly in the saved variable")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
