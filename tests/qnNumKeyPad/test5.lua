-- Scenario 5: qnNumKeyPad - "Mouse Buttons" page: rows per G502 button with the numpad key,
-- spell/macro placed into the bar's own action slot of that key (PlaceAction), clear, other content,
-- blocked in combat and with something on the cursor, button without key, key not in the layout.

qnNumKeyPadProfiles = { global = {}, profiles = { ["account:Raid"] = {} } }
QN_SPELLBOOK = { { items = {
	{ name = "Heilen", spellID = 100 }, { name = "Blitzheilung", spellID = 101 },
	{ name = "Meditation", spellID = 102, isPassive = true },
} } }
QN_SPELLS = { [100] = "Heilen", [101] = "Blitzheilung", [102] = "Meditation" }
QN_MACROS = { [1] = "Angriff", [121] = "Mein Makro" }
QN_NUM_MACROS = { 1, 1 }

local pages = {}
local origCanvas = Settings.RegisterCanvasLayoutSubcategory
function Settings.RegisterCanvasLayoutSubcategory(p, f, n) pages[n] = f return origCanvas(p, f, n) end

local core = LoadAddon("qnCore")
local nkp = LoadAddon("qnNumKeyPad")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)
local L = nkp.L

-- Windows layout, keys 1-12 on page 13: NUMPAD1 = slot 145, NUMPAD3 = 147, NUMPAD7 = 151
Check(nkp.SlotOfBinding("NUMPAD1") == 145 and nkp.SlotOfBinding("NUMPAD3") == 147 and nkp.SlotOfBinding("NUMPAD7") == 151,
	"slots of the numpad keys: " .. tostring(nkp.SlotOfBinding("NUMPAD3")))
Check(nkp.SlotOfBinding("ENTER") == nil, "hidden key has no slot")

local page = pages[L["Mouse Buttons"]]
Check(page ~= nil, "page \"Mouse Buttons\" registered")
local rows = nkp.mouseUI.rows

---------------------------------------------------------------------------
-- Without mouse
---------------------------------------------------------------------------
page:Show()
local shown = 0
for _, row in ipairs(rows) do if row:IsShown() then shown = shown + 1 end end
Check(shown == 0, "no mouse: no rows")
page:Hide()

---------------------------------------------------------------------------
-- G502: rows G3-G11
---------------------------------------------------------------------------
QN_ACTIONS[147] = { type = "spell", id = 100 }
QN_ACTIONS[145] = { type = "item", id = 5, text = "Trank" }
SETTINGS.QNNKP_MOUSE:SetValue("G502")
page:Show()
Check(#rows == 9, "one row per assignable button: " .. #rows)
local g3, g4, g11 = rows[1], rows[2], rows[9]
Check(g3.label:GetText() == "G3 (NUMPAD3)" and g11.label:GetText() == "G11 (NUMPAD1)", "button with numpad key in parentheses: " .. tostring(g3.label:GetText()))
Check(g3.kind._text == L["Spell"] and g3.spell:IsShown() and g3.spell._text == "Heilen" and not g3.macro:IsShown(),
	"G3: spell in the slot shown")
Check(g4.kind._text == EMPTY and not g4.spell:IsShown() and not g4.macro:IsShown(), "G4: empty slot")
Check(g11.kind._text == OTHER and g11.note:IsShown() and g11.note:GetText() == "Trank", "G11: other content with its name")

-- spell list: sorted, without passives
local names = {}
for _, r in ipairs(g3.spell._radios) do names[#names + 1] = r.text end
Check(table.concat(names, ",") == "Blitzheilung,Heilen", "spellbook without passives, sorted: " .. table.concat(names, ","))

-- choose another spell: replaces the slot, the previous spell does not stay on the cursor
g3.spell:PickRadio(1)
Check(QN_ACTIONS[147] and QN_ACTIONS[147].type == "spell" and QN_ACTIONS[147].id == 101 and QN_CURSOR == nil,
	"G3: Blitzheilung placed into slot 147, cursor empty")
Check(g3.spell._text == "Blitzheilung", "G3 shows the new spell")

-- macro for G4: choosing the kind alone changes nothing
g4.kind:PickRadio(3)
Check(QN_ACTIONS[151] == nil and g4.macro:IsShown() and g4.macro._text == nil, "G4: kind macro chosen, slot still empty")
local macros = {}
for _, r in ipairs(g4.macro._radios) do macros[#macros + 1] = r.text end
Check(table.concat(macros, ",") == "Angriff,Mein Makro", "account and character macros")
g4.macro:PickRadio(2)
Check(QN_ACTIONS[151] and QN_ACTIONS[151].type == "macro" and QN_ACTIONS[151].id == 121, "G4: character macro placed into slot 151")
FireEvent("ACTIONBAR_SLOT_CHANGED", 151)
Check(g4.kind._text == MACRO and g4.macro._text == "Mein Makro", "G4 shows the macro by its name")

-- clear
g3.kind:PickRadio(1)
Check(QN_ACTIONS[147] == nil and QN_CURSOR == nil and g3.kind._text == EMPTY, "G3 cleared")

---------------------------------------------------------------------------
-- Blocked: combat, cursor
---------------------------------------------------------------------------
QN_COMBAT = true
g3.kind:PickRadio(2)
g3.spell:PickRadio(2)
Check(QN_ACTIONS[147] == nil, "no change in combat")
QN_COMBAT = false
QN_CURSOR = { type = "item", id = 7 }
g3.spell:PickRadio(2)
Check(QN_ACTIONS[147] == nil and QN_CURSOR.id == 7, "no change with something on the cursor, cursor kept")
QN_CURSOR = nil
g3.spell:PickRadio(2)
Check(QN_ACTIONS[147] and QN_ACTIONS[147].id == 100, "afterwards it works")

---------------------------------------------------------------------------
-- Button without key, key not in the layout
---------------------------------------------------------------------------
SETTINGS.QNNKP_G502_G5:SetValue("")
SETTINGS.QNNKP_G502_G6:SetValue("NUMPADDECIMAL")
page:Hide()
page:Show()
local g5, g6 = rows[3], rows[4]
Check(g5.label:GetText() == "G5 (" .. NONE_KEY .. ")" and not g5.kind:IsEnabled() and g5.note:IsShown(), "G5 without key: disabled with note")
Check(g6.kind:IsEnabled(), "G6 on NUMPADDECIMAL: usable with the Windows layout")
SETTINGS.QNNKP_LAYOUT:SetValue("Naga")
FireEvent("ACTIONBAR_SLOT_CHANGED", 0)
Check(not g6.kind:IsEnabled() and g6.note:GetText() == L["This key is not on the bar with the current keyboard layout."],
	"G6: Razer Naga has no decimal key")
Check(nkp.SlotOfBinding("NUMPAD1") == 151, "Naga: NUMPAD1 is the seventh key (slot 151)")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
