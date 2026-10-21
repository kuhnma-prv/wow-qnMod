-- Scenario 3: qnUnitFrames - range icon of a hunter: Hunter's Mark (by ID and by name of the
-- first rank) never chooses the icon, dead zone of spells with a minimum range shows no icon,
-- distance text inside the icon (exact / bracket / off), settings version 1.2

-- Profile of the last session (settings version 1.1) with a broken distance value
qnCoreCharDB = { layout = "preset:1" }
qnUnitFramesDB = { global = {}, settingsVersion = "1.1", profiles = {
	["preset:1"] = { rangeTarget = true, rangeTargetDistance = "x" },
} }

CreateFrame("Button", "TargetFrame", UIParent)
CreateFrame("Button", "FocusFrame", UIParent)

-- Spell book of a hunter: auto attack, Raptor Strike, Auto Shot and Arcane Shot (8-35 yd),
-- Hunter's Mark rank 4 (known ID) and a rank with an unknown ID (same name as rank 1)
QN_SPELLBOOK = {
	{ items = {
		{ name = "Angreifen", spellID = 6603, isAutoAttack = true },
		{ name = "Raptorstoß", spellID = 2973 },
		{ name = "Automatischer Schuss", spellID = 75 },
		{ name = "Arkaner Schuss", spellID = 3044 },
		{ name = "Mal des Jägers", spellID = 14325 },
	} },
}
QN_SPELLINFO = {
	[6603] = { maxRange = 5, harmful = true, icon = 1001 },
	[2973] = { maxRange = 5, harmful = true, icon = 2973 },
	[75] = { minRange = 8, maxRange = 35, harmful = true, icon = 1075 },
	[3044] = { minRange = 8, maxRange = 35, harmful = true, icon = 3044 },
	[14325] = { name = "Mal des Jägers", maxRange = 100, harmful = true, icon = 1130 },
	[1130] = { name = "Mal des Jägers", maxRange = 100, harmful = true, icon = 1130 },
	[99999] = { name = "Mal des Jägers", maxRange = 100, harmful = true, icon = 1130 },
}
function UnitExists(u) return QN_DISTANCE[u] ~= nil end
function UnitCanAttack(a, u) return UnitExists(u) and not QN_FRIENDLY[u] end

LoadAddon("qnCore")
local uf = LoadAddon("qnUnitFrames")
local S = qnCore.Settings

local db = qnUnitFramesDB.profiles["preset:1"]
Check(qnUnitFramesDB.settingsVersion == "1.2", "settings version 1.2")
Check(db.rangeTargetDistance == true and db.rangeFocusDistance == true, "distance text: broken value back to default, default on")

SetEditModeLayout(1)
FireEvent("PLAYER_LOGIN")
RunTimers()
local icon = uf.rangeIcons.target
Check(icon ~= nil, "target icon created")

---------------------------------------------------------------------------
-- Hunter's Mark
---------------------------------------------------------------------------
QN_DISTANCE.target = 50
FireEvent("PLAYER_TARGET_CHANGED")
Check(not icon:IsShown(), "50 yd: Hunter's Mark (ID) does not show an icon")

QN_SPELLBOOK[1].items[5] = { name = "Mal des Jägers", spellID = 99999 }
FireEvent("SPELLS_CHANGED")
RunTimers()
Check(not icon:IsShown(), "50 yd: Hunter's Mark (unknown rank, by name) does not show an icon")

QN_DISTANCE.target = 30
RunTickers()
Check(icon:IsShown() and icon.tex:GetTexture() == 1075, "30 yd: Auto Shot (first in the spell book of equal range)")
Check(icon.text:GetText() == "28-35", "30 yd: bracket between interact distance and shot range")

---------------------------------------------------------------------------
-- Minimum range (dead zone)
---------------------------------------------------------------------------
QN_DISTANCE.target = 6
RunTickers()
Check(not icon:IsShown(), "6 yd: too close for the shots, outside melee: no icon")
-- even if the game reported the shots in range within the minimum range
QN_SPELLINFO[75].closeInRange, QN_SPELLINFO[3044].closeInRange = true, true
RunTickers()
Check(not icon:IsShown(), "6 yd, shots report in range: still no icon (duel distance)")
QN_DISTANCE.target = 12
RunTickers()
Check(icon:IsShown() and icon.tex:GetTexture() == 1075, "12 yd: beyond duel distance, shot icon again")
Check(icon.text:GetText() == "11-28", "12 yd: bracket between trade and inspect distance")
QN_SPELLINFO[75].closeInRange, QN_SPELLINFO[3044].closeInRange = nil, nil

QN_DISTANCE.target = 3
RunTickers()
Check(icon:IsShown() and icon.tex:GetTexture() == 1001, "3 yd: melee icon")
Check(icon.text:GetText() == "<5", "3 yd: melee range text")

---------------------------------------------------------------------------
-- Exact distance, distance off
---------------------------------------------------------------------------
QN_DISTANCE.target = 30
QN_DISTANCE_CHECKED.target = true
RunTickers()
Check(icon.text:GetText() == "30", "exact distance where the game reports it")
QN_DISTANCE_CHECKED.target = nil

S.SetIn(uf.store.builders, "rangeTargetDistance", false)
Check(icon:IsShown() and icon.text:GetText() == "", "distance text off")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
