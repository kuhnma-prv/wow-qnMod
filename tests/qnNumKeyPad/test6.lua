-- Scenario 6: qnNumKeyPad - modifier sets: while Ctrl or Alt is held, keys 1-12 show the page of the
-- set (state driver, also in combat), CTRL-/ALT- bindings only for keys 1-12, Ctrl+Alt = normal
-- actions, priority over the stance, page warnings, arrow keys switched off, "Mouse Buttons" page per set.

EnableRestrictedEnvironment()
SpellFlyout = CreateFrame("Frame", "SpellFlyout")
SpellFlyout:Hide()
-- keys like ActionBarButtonTemplate: protected (as in scenario 3)
local create = CreateFrame
CreateFrame = function(kind, name, parent, template, ...)
	local f = create(kind, name, parent, template, ...)
	if template == "ActionBarButtonTemplate" then
		f._protected = true
		f._clicks = { "AnyUp", "LeftButtonDown", "RightButtonDown" }
	end
	return f
end
function UnitAffectingCombat(unit) return unit == "player" and QN_COMBAT or false end

-- saved data of settings 1.1 with arrow keys and Alt set switched on
qnNumKeyPadProfiles = { settingsVersion = "1.1", global = { mouse = "G502" },
	profiles = { ["account:Raid"] = { showArrow = true, altSet = true } } }
QN_SPELLBOOK = { { items = { { name = "Heilen", spellID = 100 }, { name = "Blitzheilung", spellID = 101 } } } }
QN_SPELLS = { [100] = "Heilen", [101] = "Blitzheilung" }

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
local bar = nkp.bar
local db = nkp.db
local function Set(key, value)
	SETTINGS["QNNKP_" .. key:upper()]:SetValue(value)
end
local function Action(i)
	return _G["qnNumKeyPadButton" .. i]:GetAttribute("action")
end
local function Mods(ctrl, alt)
	QN_CONDITIONS["mod:ctrl"], QN_CONDITIONS["mod:alt"] = ctrl or nil, alt or nil
	UpdateStateDrivers()
end

---------------------------------------------------------------------------
-- Defaults, arrow keys and Alt set switched off
---------------------------------------------------------------------------
Check(qnNumKeyPadProfiles.settingsVersion == "1.2", "settingsVersion 1.2")
Check(db.ctrlSet == true and db.ctrlPage == 15 and db.altPage == 2, "defaults: Ctrl set page 15, Alt page 2")
Check(db.showArrow == false and db.altSet == false, "arrow keys and Alt set switched off on load")
Check(not INITIALIZERS.QNNKP_ALTSET:IsModifiable() and not INITIALIZERS.QNNKP_ALTPAGE:IsModifiable(), "Alt set disabled in the options")
Check(BINDINGS[bar]["ALT-NUMPAD1"] == nil, "no Alt bindings")
-- the code of the Alt set stays: switch it on directly for the following checks
Set("altSet", true)
Check(not INITIALIZERS.QNNKP_SHOWARROW:IsModifiable() and not INITIALIZERS.QNNKP_PAGE3:IsModifiable(),
	"checkbox arrow keys and page of keys 25-28 disabled")
Check(INITIALIZERS.QNNKP_CTRLPAGE:IsModifiable(), "Ctrl page usable")

---------------------------------------------------------------------------
-- Paging
---------------------------------------------------------------------------
Check(Action(1) == 145 and Action(12) == 156 and Action(13) == 157, "normal: own slots")
Mods(true, false)
Check(Action(1) == 169 and Action(12) == 180 and Action(13) == 157, "Ctrl: keys 1-12 on page 15, key 13 unchanged")
Mods(false, true)
Check(Action(1) == 13 and Action(9) == 21, "Alt: keys 1-12 on page 2")
Mods(true, true)
Check(Action(1) == 145, "Ctrl+Alt: normal actions")
Mods(false, false)
Check(Action(1) == 145, "released: own slots")

-- in combat as well (state driver), with priority over the stance
Set("stance", true)
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
QN_CONDITIONS["bonusbar:1"] = true
UpdateStateDrivers()
Check(Action(1) == 73, "stance 1: page 7")
Mods(true, false)
Check(Action(1) == 169, "stance 1 + Ctrl in combat: Ctrl set wins")
Mods(false, false)
Check(Action(1) == 73, "Ctrl released: stance again")
QN_CONDITIONS["bonusbar:1"] = nil
UpdateStateDrivers()
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Set("stance", false)

---------------------------------------------------------------------------
-- Bindings
---------------------------------------------------------------------------
local binds = BINDINGS[bar]
Check(binds["CTRL-NUMPAD1"] == "qnNumKeyPadKey1:LeftButton" and binds["ALT-NUMPAD1"] == "qnNumKeyPadKey1:LeftButton",
	"Ctrl/Alt + numpad 1 bound to the same key")
Check(binds["CTRL-NUMPADPLUS"] ~= nil and binds["CTRL-NUMPADMINUS"] == nil and binds["ALT-NUMPADDIVIDE"] == nil,
	"only keys 1-12 (+ is key 12, - is key 13)")
Check(binds["SHIFT-NUMPAD1"] ~= nil and binds["CTRL-SHIFT-NUMPAD1"] == nil, "Shift unchanged, no combinations")
Set("altSet", false)
binds = BINDINGS[bar]
Check(binds["ALT-NUMPAD1"] == nil and binds["CTRL-NUMPAD1"] ~= nil, "Alt set off: Alt bindings removed")
Mods(false, true)
Check(Action(1) == 145, "Alt set off: Alt does not switch")
Mods(false, false)
Set("altSet", true)

---------------------------------------------------------------------------
-- Page warnings
---------------------------------------------------------------------------
local chat = {}
local print0 = nkp.Print
nkp.Print = function(msg) chat[#chat + 1] = msg end
local WARN_MULTI = L["Warning: page %d is assigned to more than one key group."]
local WARN_BLIZZ = L["Warning: page %d is also used by a visible Blizzard action bar."]
local function Count(text)
	local n = 0
	for _, line in ipairs(chat) do if line == text then n = n + 1 end end
	return n
end
Set("altPage", 13)
Check(Count(WARN_MULTI:format(13)) == 1, "Alt set on page 13 of keys 1-12: warning")
local mb7 = CreateFrame("Frame", "MultiBar7")   -- Blizzard Action Bar 8 = page 15
chat = {}
Set("altPage", 2)
Check(Count(WARN_BLIZZ:format(15)) == 1, "Ctrl set page 15 while Action Bar 8 is visible: warning")
mb7:Hide()
nkp.Print = print0

---------------------------------------------------------------------------
-- "Mouse Buttons" page per set
---------------------------------------------------------------------------
Check(nkp.SlotOfBinding("NUMPAD3", "ctrl") == 171 and nkp.SlotOfBinding("NUMPAD3", "alt") == 15, "slots of the sets")
local slot, why = nkp.SlotOfBinding("NUMPADMINUS", "ctrl")
Check(slot == nil and why == "fixed", "key 13 has no slot in a set")

local page = pages[L["Mouse Buttons"]]
local rows, setDD = nkp.mouseUI.rows, nkp.mouseUI.set
page:Show()
Check(setDD:IsShown() and #setDD._radios == 3 and setDD._text == L["Normal actions"], "set dropdown: normal, Ctrl, Alt")
local g3 = rows[1]   -- G3 = NUMPAD3
setDD:PickRadio(2)
Check(setDD._text == L["Ctrl set"] and g3.kind._text == EMPTY, "Ctrl set selected, G3 empty")
g3.kind:PickRadio(2)
g3.spell:PickRadio(2)
Check(QN_ACTIONS[171] and QN_ACTIONS[171].id == 100 and QN_ACTIONS[147] == nil, "G3 Ctrl: spell in slot 171 (page 15), normal slot untouched")
setDD:PickRadio(3)
g3.kind:PickRadio(2)
g3.spell:PickRadio(1)
Check(QN_ACTIONS[15] and QN_ACTIONS[15].id == 101, "G3 Alt: spell in slot 15 (page 2)")
setDD:PickRadio(1)
Check(g3.kind._text == EMPTY, "normal actions: G3 still empty")

-- G6 on key 13: no slot in the sets
SETTINGS.QNNKP_G502_G6:SetValue("NUMPADMINUS")
setDD:PickRadio(2)
local g6 = rows[4]
Check(not g6.kind:IsEnabled() and g6.note:GetText() == L["Keys 13 and higher do not switch with Ctrl or Alt."], "G6 on key 13: note in the Ctrl set")

-- set switched off: page falls back to the normal actions
Set("ctrlSet", false)
page:Hide()
page:Show()
Check(setDD._text == L["Normal actions"] and #setDD._radios == 2, "Ctrl set off: back to normal actions, only Alt offered")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
