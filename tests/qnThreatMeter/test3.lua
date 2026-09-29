-- Scenario 3: qnThreatMeter - warning with hidden window (ticker independent of the window, no
-- collecting without need), no warning without a real tank entry, TPS history per enemy (target switch,
-- limit, clearing after combat), fading of the resize handle only after enter/leave.

SOUNDKIT = SOUNDKIT or { RAID_WARNING = 8959 }

-- Units: token -> { id, name, class, guid, player, hostile }
QN_UNITS = {}
QN_THREAT = {}      -- enemy GUID -> id -> { value, isTanking }
QN_PARTY = 0
QN_THREAT_CALLS = 0
local function Units(mobGUID)
	QN_UNITS = {
		player = { id = "player", name = "Tester", class = "WARRIOR", guid = "Player-1", player = true },
		party1 = { id = "party1", name = "Tanko", class = "WARRIOR", guid = "Party-1", player = true },
		target = { id = "mob", name = "Eber", guid = mobGUID, hostile = true },
	}
end
function UnitExists(u) return QN_UNITS[u] ~= nil end
function UnitName(u) local d = QN_UNITS[u] return d and d.name or "Tester" end
function UnitClass(u) local d = QN_UNITS[u] return "x", d and d.class or "WARRIOR" end
function UnitGUID(u) local d = QN_UNITS[u] return d and d.guid or (u == "player" and "Player-1" or nil) end
function UnitIsPlayer(u) local d = QN_UNITS[u] return d and d.player or false end
function UnitPlayerControlled(u) return UnitIsPlayer(u) end
function UnitCanAttack(_, u) local d = QN_UNITS[u] return d and d.hostile or false end
function UnitIsUnit(a, b) return a == b end
function IsInGroup() return QN_PARTY > 0 end
function IsInRaid() return false end
function GetNumSubgroupMembers() return QN_PARTY end
function UnitDetailedThreatSituation(u, mob)
	QN_THREAT_CALLS = QN_THREAT_CALLS + 1
	local d, m = QN_UNITS[u], QN_UNITS[mob]
	local list = m and QN_THREAT[m.guid]
	local t = d and list and list[d.id]
	if not t then return nil end
	return t.isTanking or false, t.isTanking and 3 or 0, t.value / 10, t.value / 10, t.value
end
C_Item.IsItemInRange = function() return true end

Units("Mob-A")
QN_PARTY = 1
QN_THREAT = { ["Mob-A"] = { party1 = { value = 1000, isTanking = true }, player = { value = 500 } } }

LoadAddon("qnCore")
local meter = LoadAddon("qnThreatMeter")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)
local L = meter.L
local T = meter.Threat
local f = T.frame
local db = meter.db

local warn
rawset(RaidWarningFrame, "AddMessage", function(_, text) warn = text end)
local function Tick() T.driver._scripts.OnUpdate(T.driver, 1) end
local function Right(i) return f.bars[i] and f.bars[i]._shown and f.bars[i].right._text end
local function Left(i) return f.bars[i] and f.bars[i]._shown and f.bars[i].left._text end
local function MyRow()
	for i = 1, #f.bars do
		local text = Left(i)
		if text and text:find("Tester", 1, true) then return i end
	end
end

---------------------------------------------------------------------------
-- Finding 1: warning even with hidden window
---------------------------------------------------------------------------
Check(f:IsShown() and T.driver:IsShown(), "visible window: ticker running")

-- Visibility "only in group", alone, warning also when alone
QN_PARTY = 0
meter.store:Set("warnSolo", true)
meter.store:Set("showMode", 3)
Check(not f:IsShown(), "alone with 'only in group': window hidden")
Check(not T.driver:IsShown(), "hidden out of combat: ticker off")
QN_THREAT_CALLS = 0
T.Refresh()
Check(QN_THREAT_CALLS == 0, "hidden without need: nothing collected")

-- Combat: ticker on, warning despite hidden window (tank = NPC as the enemy's target)
QN_UNITS.targettarget = { id = "party1", name = "Tanko", class = "WARRIOR", guid = "Party-1", player = true }
QN_UNITS.party1 = nil
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
Check(not f:IsShown() and T.driver:IsShown(), "in combat, window hidden: ticker running")
QN_THREAT["Mob-A"].player.value = 950
warn = nil
Tick()
Check(warn == L["Threat: %d%%"]:format(95), "hidden window: warning triggered: " .. tostring(warn))

-- Re-arm (end of combat) with a low value so that only the tick warns
local function Rearm()
	QN_THREAT["Mob-A"].player.value = 500
	FireEvent("PLAYER_REGEN_ENABLED")
	QN_COMBAT = true
	FireEvent("PLAYER_REGEN_DISABLED")
end

-- Window turned off via "shown", in group
QN_PARTY = 1
Units("Mob-A")
meter.store:Set("showMode", 1)
meter.store:Set("warnSolo", false)
meter.store:Set("shown", false)
Check(not f:IsShown() and T.driver:IsShown(), "shown=false in combat: ticker running")
Rearm()
QN_THREAT["Mob-A"].player.value = 950
warn = nil
Tick()
Check(warn ~= nil, "shown=false: warning anyway: " .. tostring(warn))

-- Warning off and window off: collect nothing
meter.store:Set("warnEnabled", false)
Check(not T.driver:IsShown(), "warning off, window off: ticker off")
QN_THREAT_CALLS = 0
T.Refresh()
Check(QN_THREAT_CALLS == 0, "warning off, window off: nothing collected")
meter.store:Set("warnEnabled", true)
meter.store:Set("shown", true)
Check(f:IsShown(), "window back")

---------------------------------------------------------------------------
-- Finding 2: no warning without a real tank entry
---------------------------------------------------------------------------
Rearm()
QN_THREAT["Mob-A"].party1.isTanking = nil
QN_THREAT["Mob-A"].party1.value = 400
QN_THREAT["Mob-A"].player.value = 950
warn = nil
T.Refresh()
Check(warn == nil, "no tank entry, own value highest: no warning: " .. tostring(warn))
Check(Right(MyRow()) ~= nil and Right(MyRow()):find("100%", 1, true), "display stays: reference = highest value: " .. tostring(Right(MyRow())))
QN_THREAT["Mob-A"].party1.isTanking = true
QN_THREAT["Mob-A"].party1.value = 1000
T.Refresh()
Check(warn == L["Threat: %d%%"]:format(95), "with tank entry: warning: " .. tostring(warn))

---------------------------------------------------------------------------
-- Finding 4: TPS history per enemy
---------------------------------------------------------------------------
SetTime(2000)
meter.store:Set("warnEnabled", false)
QN_THREAT["Mob-A"].player.value = 1000
FireEvent("PLAYER_REGEN_ENABLED")
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
T.Refresh()
SetTime(2005)
QN_THREAT["Mob-A"].player.value = 1500
T.Refresh()
Check(Right(MyRow()):find("(100)", 1, true), "TPS on A: " .. tostring(Right(MyRow())))

-- briefly on enemy B
QN_THREAT["Mob-B"] = { party1 = { value = 300, isTanking = true }, player = { value = 200 } }
QN_UNITS.target.guid = "Mob-B"
SetTime(2006)
T.Refresh()
Check(Right(MyRow()):find("(0)", 1, true), "B: own history starts anew: " .. tostring(Right(MyRow())))

-- back to A: history of A still there (10 s: 1000 -> 2000)
QN_UNITS.target.guid = "Mob-A"
SetTime(2010)
QN_THREAT["Mob-A"].player.value = 2000
T.Refresh()
Check(Right(MyRow()):find("(100)", 1, true), "back to A: history kept: " .. tostring(Right(MyRow())))

-- Limit: five more enemies push out A
for i = 1, 5 do
	local guid = "Mob-X" .. i
	QN_THREAT[guid] = { party1 = { value = 300, isTanking = true }, player = { value = 100 } }
	QN_UNITS.target.guid = guid
	T.Refresh()
end
QN_UNITS.target.guid = "Mob-A"
SetTime(2011)
QN_THREAT["Mob-A"].player.value = 2100
T.Refresh()
Check(Right(MyRow()):find("(0)", 1, true), "more than 5 enemies: oldest history discarded: " .. tostring(Right(MyRow())))

-- cleared after combat
SetTime(2015)
QN_THREAT["Mob-A"].player.value = 2500
T.Refresh()
Check(Right(MyRow()):find("(100)", 1, true), "A with history again: " .. tostring(Right(MyRow())))
QN_COMBAT = nil
FireEvent("PLAYER_REGEN_ENABLED")
SetTime(2015.5)   -- less than 1 s after the new start: TPS 0
QN_THREAT["Mob-A"].player.value = 2600
T.Refresh()
Check(Right(MyRow()):find("(0)", 1, true), "after combat: history cleared: " .. tostring(Right(MyRow())))

---------------------------------------------------------------------------
-- Finding 7: fade the resize handle only after enter/leave
---------------------------------------------------------------------------
local fade = f.hoverFade
for _, region in ipairs({ f, f.settingsButton, f.resizeButton }) do
	Check(region._scripts.OnEnter and region._scripts.OnLeave, "enter/leave registered")
end
Check(not fade:IsShown(), "without mouse movement: no fading per frame")
local mouseOver = false
f.IsMouseOver = function() return mouseOver end
f.resizeButton:SetAlpha(0)
mouseOver = true
f._scripts.OnEnter(f)
Check(fade:IsShown(), "enter: fader running")
fade._scripts.OnUpdate(fade, 0.1)
Check(f.resizeButton:GetAlpha() > 0 and f.resizeButton:GetAlpha() < 1 and fade:IsShown(), "fades in smoothly")
fade._scripts.OnUpdate(fade, 0.3)
Check(f.resizeButton:GetAlpha() == 1 and not fade:IsShown(), "faded in, fader stops")
-- Mouse onto the button (window reports leave, but is still over it): stays visible
f._scripts.OnLeave(f)
fade._scripts.OnUpdate(fade, 0.1)
Check(f.resizeButton:GetAlpha() == 1 and not fade:IsShown(), "on the button: stays faded in")
-- from the button to outside
mouseOver = false
f.settingsButton._scripts.OnLeave(f.settingsButton)
Check(fade:IsShown(), "leave via the button: fader running")
fade._scripts.OnUpdate(fade, 0.3)
Check(f.resizeButton:GetAlpha() == 0 and not fade:IsShown(), "faded out, fader stops")
-- Resize and release outside
f.resizeButton._scripts.OnMouseDown(f.resizeButton)
f.resizeButton._scripts.OnMouseUp(f.resizeButton)
Check(fade:IsShown(), "after dragging: fader checks again")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
