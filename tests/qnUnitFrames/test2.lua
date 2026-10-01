-- Scenario 2: qnUnitFrames - range icon at the target and focus frame: farthest usable ranged
-- spell, melee icon, no icon out of range / friendly unit, size and position per frame, profiles,
-- settings version 1.1 (sanitize of the new values)

-- Profile of the last session (settings version 1.0) with broken range values
qnCoreCharDB = { layout = "preset:1" }
qnUnitFramesDB = { global = {}, settingsVersion = "1.0", profiles = {
	["preset:1"] = { rangeFocusSize = 500, rangeFocusX = "x", rangeTarget = "yes" },
} }

local targetFrame = CreateFrame("Button", "TargetFrame", UIParent)
local focusFrame = CreateFrame("Button", "FocusFrame", UIParent)

-- Spell book: auto attack, melee spell, two ranged spells (40 yd one is off-spec, 36 yd needs
-- a form), 30 yd spell, passive 45 yd spell, helpful 40 yd spell
QN_SPELLBOOK = {
	{ items = {
		{ name = "Angreifen", spellID = 6603, isAutoAttack = true },
		{ name = "Heldenhafter Stoß", spellID = 100 },
		{ name = "Zorn", spellID = 200 },
		{ name = "Mondfeuer", spellID = 300 },
		{ name = "Passiv", spellID = 400, isPassive = true },
		{ name = "Heilen", spellID = 500 },
	} },
	{ items = { { name = "Nebenspezialisierung", spellID = 600, isOffSpec = true } } },
}
QN_SPELLINFO = {
	[6603] = { maxRange = 5, harmful = true, icon = 1001 },
	[100] = { maxRange = 5, harmful = true, icon = 1100 },
	[200] = { maxRange = 30, harmful = true, icon = 1200 },
	[300] = { maxRange = 36, harmful = true, icon = 1300 },
	[400] = { maxRange = 45, harmful = true, icon = 1400 },
	[500] = { maxRange = 40, harmful = false, icon = 1500 },
	[600] = { maxRange = 40, harmful = true, icon = 1600 },
}
function UnitExists(u) return QN_DISTANCE[u] ~= nil end

LoadAddon("qnCore")
local uf = LoadAddon("qnUnitFrames")
local S = qnCore.Settings

---------------------------------------------------------------------------
-- Settings version and sanitize
---------------------------------------------------------------------------
local db = qnUnitFramesDB.profiles["preset:1"]
Check(qnUnitFramesDB.settingsVersion == "1.1", "settings version 1.1")
Check(db.rangeFocusSize == uf.RANGE_SIZE[2], "too large size limited")
Check(db.rangeFocusX == 0 and db.rangeTarget == false, "invalid values back to default")
Check(db.rangeTargetSize == 24 and db.rangeFocusY == 0, "defaults added")

SetEditModeLayout(1)
FireEvent("PLAYER_LOGIN")
RunTimers()
Check(uf.rangeIcons.target == nil and uf.rangeIcons.focus == nil, "off: no icons created")

---------------------------------------------------------------------------
-- Target
---------------------------------------------------------------------------
Check(S.SetIn(uf.store.builders, "rangeTarget", true), "option for the target frame exists")
local icon = uf.rangeIcons.target
Check(icon and icon:GetParent() == targetFrame and uf.rangeIcons.focus == nil, "icon at the target frame only")
Check(not icon:IsShown(), "no target: hidden")

QN_DISTANCE.target = 3
FireEvent("PLAYER_TARGET_CHANGED")
Check(icon:IsShown() and icon.tex:GetTexture() == 1001, "melee range: auto attack icon")
-- auto attack reports "out of range": one melee spell out of range is enough against melee
QN_SPELLINFO[6603].maxRange = 0
RunTickers()
Check(icon:IsShown() and icon.tex:GetTexture() == 1300, "auto attack says false: no melee icon")
QN_SPELLINFO[6603].maxRange = 5
-- as in the game: auto attack cannot be checked (nil)
QN_SPELLINFO[6603].unchecked = true
QN_DISTANCE.target = 8
RunTickers()
Check(icon.tex:GetTexture() == 1300, "checkable melee spell out of range: no duel distance fallback")
-- a melee spell that reports true far away (Heroic Strike in the game) does not win against one out of range
QN_SPELLBOOK[1].items[#QN_SPELLBOOK[1].items + 1] = { name = "Heldenhafter Stoß", spellID = 284 }
QN_SPELLINFO[284] = { maxRange = 0, harmful = true, alwaysInRange = true, icon = 1284 }
FireEvent("SPELLS_CHANGED")
RunTimers()
Check(icon.tex:GetTexture() == 1300, "one melee spell out of range: no melee icon")
QN_DISTANCE.target = 3
RunTickers()
Check(icon.tex:GetTexture() == 1001, "all checkable melee spells in range: melee icon")
QN_DISTANCE.target = 8
-- no checkable melee spell (druid in caster form): duel distance decides
QN_SPELLINFO[100].unchecked, QN_SPELLINFO[284].unchecked = true, true
RunTickers()
Check(icon:IsShown() and icon.tex:GetTexture() == 1001, "within duel distance: melee icon")
QN_DISTANCE.target = 12
RunTickers()
Check(icon.tex:GetTexture() == 1300, "beyond duel distance: ranged icon")
QN_SPELLINFO[6603].unchecked, QN_SPELLINFO[100].unchecked, QN_SPELLINFO[284].unchecked = nil, nil, nil
QN_DISTANCE.target = 3

QN_DISTANCE.target = 34
RunTickers()
Check(icon:IsShown() and icon.tex:GetTexture() == 1300, "farthest ranged spell (36 yd, not off-spec/passive/helpful)")

QN_DISTANCE.target = 38
RunTickers()
Check(not icon:IsShown(), "beyond the farthest range: hidden")

-- 36 yd spell not usable (e.g. wrong form) → 30 yd spell counts
QN_SPELLINFO[300].usable = false
QN_DISTANCE.target = 34
RunTickers()
Check(not icon:IsShown(), "farthest usable spell 30 yd: 34 yd out of range")
QN_DISTANCE.target = 25
RunTickers()
Check(icon:IsShown() and icon.tex:GetTexture() == 1200, "icon of the 30 yd spell")
-- missing power only: still available
QN_SPELLINFO[300].noPower = true
RunTickers()
Check(icon.tex:GetTexture() == 1300, "missing power does not count as unavailable")
QN_SPELLINFO[300].usable, QN_SPELLINFO[300].noPower = nil, nil

-- friendly target: harmful spells cannot be checked
QN_FRIENDLY.target = true
RunTickers()
Check(not icon:IsShown(), "friendly target: no icon")
QN_FRIENDLY.target = nil

-- new spell learned: rescan
QN_SPELLBOOK[1].items[#QN_SPELLBOOK[1].items + 1] = { name = "Fernschuss", spellID = 700 }
QN_SPELLINFO[700] = { maxRange = 41, harmful = true, icon = 1700 }
QN_DISTANCE.target = 39
FireEvent("SPELLS_CHANGED")
RunTimers()
Check(icon:IsShown() and icon.tex:GetTexture() == 1700, "new spell after SPELLS_CHANGED")

---------------------------------------------------------------------------
-- Size and position
---------------------------------------------------------------------------
S.SetIn(uf.store.builders, "rangeTargetSize", 40)
S.SetIn(uf.store.builders, "rangeTargetX", -20)
S.SetIn(uf.store.builders, "rangeTargetY", 8)
local w, h = icon:GetSize()
local p = icon._points[#icon._points]
Check(w == 40 and h == 40, "size")
Check(p[1] == "LEFT" and p[2] == targetFrame and p[3] == "RIGHT" and p[4] == -20 and p[5] == 8, "position relative to the target frame")

---------------------------------------------------------------------------
-- Focus: separate settings
---------------------------------------------------------------------------
S.SetIn(uf.store.builders, "rangeFocus", true)
S.SetIn(uf.store.builders, "rangeFocusSize", 16)
local focusIcon = uf.rangeIcons.focus
Check(focusIcon and focusIcon:GetParent() == focusFrame and focusIcon:GetSize() == 16, "focus icon with its own size")
Check(icon:GetSize() == 40, "target size unchanged")
Check(not focusIcon:IsShown(), "no focus: hidden")
QN_DISTANCE.focus = 2
FireEvent("PLAYER_FOCUS_CHANGED")
Check(focusIcon:IsShown() and focusIcon.tex:GetTexture() == 1001, "focus in melee range")

---------------------------------------------------------------------------
-- Off, profile switch
---------------------------------------------------------------------------
S.SetIn(uf.store.builders, "rangeTarget", false)
Check(not icon:IsShown() and focusIcon:IsShown(), "target off, focus stays")

SetEditModeLayout(2)
RunTimers()
Check(uf.db ~= db and focusIcon:IsShown() and not icon:IsShown(), "new profile = copy of the previous one")
S.SetIn(uf.store.builders, "rangeFocus", false)
Check(not focusIcon:IsShown() and db.rangeFocus == true, "focus off only in the new profile")
SetEditModeLayout(1)
RunTimers()
Check(uf.db == db and focusIcon:IsShown() and focusIcon:GetSize() == 16, "back to profile 1: focus icon again")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
