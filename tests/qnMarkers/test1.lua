-- Scenario 1: qnMarkers - raid marker bar: repair of saved values, layout (horizontal, vertical,
-- hidden buttons, floating, minimized), secure actions of the marker buttons with and without world
-- markers, clicks (markers, clear, grip, ready check, pull timer, leave), glow, tooltips,
-- visibility driver (group, raid, leader only), combat lock, profiles, position, slash commands,
-- options page.

-- Profile of the last session with broken values
qnCoreCharDB = { layout = "preset:1" }
qnMarkersDB = { profiles = { ["preset:1"] = {
	size = 99, visibility = "bogus", orientation = 5, borderColor = { 1 }, shown = "yes", gap = -3,
} } }

-- group membership as with EnableTooltips (QN_GROUP = list of group members)
function IsInGroup() return QN_GROUP ~= nil end

EnableRestrictedEnvironment()
LoadAddon("qnCore")
local mk = LoadAddon("qnMarkers")
local L = mk.L
local printed = {}
local oldPrint = mk.Print
mk.Print = function(fmt, ...) printed[#printed + 1] = select("#", ...) > 0 and tostring(fmt):format(...) or tostring(fmt) oldPrint(fmt, ...) end
FireEvent("PLAYER_LOGIN")
SetEditModeLayout(1)

local db = mk.db
local bar, grip = qnMarkersBar, qnMarkersBarGrip
local function A(f, name) return f:GetAttribute(name) end
local function Set(key, value) SETTINGS["QNMARKERS_" .. key:upper()]:SetValue(value) end

---------------------------------------------------------------------------
-- Repair on load
---------------------------------------------------------------------------
Check(db.size == 42 and db.gap == 0, "size and spacing clamped into their range")
Check(db.visibility == "always" and db.orientation == "horizontal", "invalid choices fall back to the default")
Check(db.shown == true and #db.borderColor == 4 and db.borderColor[1] == 0.22, "wrong types and broken colors fall back to the default")
Set("size", 28)
Set("gap", 2)

---------------------------------------------------------------------------
-- Layout
---------------------------------------------------------------------------
-- pad 4 + grip 28 + (gap 2 + separator 1) + 8 x (2 + 28) + (2 + 1) + 5 utility buttons x (2 + 28) + pad 4
Check(bar:GetWidth() == 432 and bar:GetHeight() == 36, "horizontal: width " .. tostring(bar:GetWidth()) .. ", height " .. tostring(bar:GetHeight()))
Check(qnMarkersBarLeave:IsShown() == false and qnMarkersBarReady:IsShown(), "leave button off by default, ready check on")
Set("orientation", "vertical")
Check(bar:GetWidth() == 36 and bar:GetHeight() == 432, "vertical: width and height swapped")
Set("orientation", "horizontal")
for _, key in ipairs({ "showReady", "showPull5", "showPull10", "showClearWorld", "showClearTarget" }) do Set(key, false) end
Check(bar:GetWidth() == 279, "without utility buttons also without the second separator: " .. tostring(bar:GetWidth()))
Set("floating", true)
Check(bar:GetWidth() == 276 and bar.bg._color[4] == 0, "floating: no separators, transparent background")
Set("floating", false)
for _, key in ipairs({ "showReady", "showPull5", "showPull10", "showClearWorld", "showClearTarget" }) do Set(key, true) end
Check(bar:GetWidth() == 432 and bar.bg._color[4] == 0.92, "buttons and background back")

---------------------------------------------------------------------------
-- Secure actions
---------------------------------------------------------------------------
local skull, moon = qnMarkersBarMarker1, qnMarkersBarMarker2
Check(A(skull, "type1") == "worldmarker" and A(skull, "marker1") == 8 and A(skull, "action1") == "set", "skull: left places world marker 8")
Check(A(skull, "type2") == "raidtarget" and A(skull, "marker2") == 8 and A(skull, "action2") == "set", "skull: right sets target marker 8")
Check(A(moon, "marker1") == 7 and A(moon, "marker2") == 5, "moon: world marker 7, target marker 5")
Check(A(grip, "type2") == "macro" and A(grip, "macrotext2") == SLASH_CLEAR_WORLD_MARKER1 .. " " .. ALL .. "\n" .. SLASH_TARGET_MARKER1 .. " 0",
	"grip right-click: macro clears world markers (localized ALL) and the target marker")

SecureClick(moon, "LeftButton")
RunTimers()
Check(QN_WORLD_ACTIVE[7] and moon.glow:IsShown() and not skull.glow:IsShown(), "left-click places the world marker, its button glows")
QN_WORLD_ACTIVE[8] = true   -- placed by another group member
mk.UpdateGlows()
Check(skull.glow:IsShown(), "glow also for markers of others")
SecureClick(skull, "RightButton")
Check(QN_RAID_TARGETS.target == 8, "right-click sets the target marker")
SecureClick(qnMarkersBarClearTarget, "LeftButton")
Check(QN_RAID_TARGETS.target == nil, "clear target marker")
SecureClick(qnMarkersBarClearWorld, "LeftButton")
RunTimers()
Check(next(QN_WORLD_ACTIVE) == nil and not moon.glow:IsShown() and not skull.glow:IsShown(), "clear world markers: all gone, no glow")
SecureClick(grip, "RightButton")
Check(QN_MACROS_RUN[#QN_MACROS_RUN] == A(grip, "macrotext2"), "grip right-click runs the clear macro")

-- Without world markers both buttons set the target marker
QN_WORLD_MARKERS = false
FireEvent("GROUP_ROSTER_UPDATE")
Check(A(skull, "type1") == "raidtarget" and A(skull, "marker1") == 8 and A(moon, "marker1") == 5, "without world markers: left sets the target marker")
Check(A(grip, "macrotext2") == SLASH_TARGET_MARKER1 .. " 0", "clear macro only clears the target marker")
Check(qnMarkersBarClearWorld:GetAlpha() < 1, "clear world markers dimmed")
QN_WORLD_MARKERS = nil
FireEvent("GROUP_ROSTER_UPDATE")
Check(A(skull, "type1") == "worldmarker" and qnMarkersBarClearWorld:GetAlpha() == 1, "world markers available again")

---------------------------------------------------------------------------
-- Normal buttons
---------------------------------------------------------------------------
qnMarkersBarReady:Click()
qnMarkersBarPull5:Click()
qnMarkersBarPull10:Click()
Check(table.concat(QN_PARTY_CALLS, ",") == "readycheck,countdown 5,countdown 10", "ready check and pull timers: " .. table.concat(QN_PARTY_CALLS, ","))
qnMarkersBarLeave:Click()
Check(LAST_POPUP == nil, "leave: nothing without a group")
QN_GROUP = { "party1" }
qnMarkersBarLeave:Click()
Check(LAST_POPUP and LAST_POPUP.which == "QNMARKERS_LEAVE", "leave asks first")
Check(#QN_PARTY_CALLS == 3, "no leaving before the confirmation")
StaticPopupDialogs.QNMARKERS_LEAVE.OnAccept(nil, nil)
Check(QN_PARTY_CALLS[4] == "leave", "leaves after the confirmation")

---------------------------------------------------------------------------
-- Grip: minimize, drag
---------------------------------------------------------------------------
SecureClick(grip, "LeftButton")
Check(db.minimized and bar:GetWidth() == 36 and bar:GetHeight() == 36 and not skull:IsShown(), "left-click on the grip minimizes")
Check(grip.label._text == "+", "grip shows +")
SecureClick(grip, "LeftButton")
Check(not db.minimized and bar:GetWidth() == 432 and skull:IsShown() and grip.label._text == "-", "left-click again expands")
grip._scripts.OnDragStart(grip)
Check(bar._moving, "dragging the grip moves the bar")
grip._scripts.OnDragStop(grip)
SecureClick(grip, "LeftButton")
Check(not db.minimized, "the click after dragging does not minimize")
Check(type(db.x) == "number" and type(db.y) == "number", "position saved after dragging")
SlashCmdList.QNMARKERS("lock")
Check(db.locked, "/qnmarkers lock")
bar._moving = false
grip._scripts.OnDragStart(grip)
Check(not bar._moving, "locked: no dragging")
SlashCmdList.QNMARKERS("unlock")
Check(not db.locked, "/qnmarkers unlock")
db.x, db.y = 5, -5
SlashCmdList.QNMARKERS("reset")
Check(db.x == mk.defaults.x and db.y == mk.defaults.y, "/qnmarkers reset: default position")

---------------------------------------------------------------------------
-- Tooltips
---------------------------------------------------------------------------
skull._scripts.OnEnter(skull)
Check(TOOLTIP.owner == skull and TOOLTIP.lines[1].text == RAID_TARGET_8 and TOOLTIP.lines[2].text == L["Left-click: place world marker\nRight-click: set target marker"],
	"marker tooltip: name and both clicks")
Set("tooltips", false)
TOOLTIP = { lines = {} }
skull._scripts.OnEnter(skull)
Check(TOOLTIP.owner == nil, "no tooltip with tooltips off")
Set("tooltips", true)

---------------------------------------------------------------------------
-- Visibility
---------------------------------------------------------------------------
QN_GROUP = nil
Check(mk.VisibilityDriver() == "show" and bar:IsShown(), "always: shown")
Set("visibility", "group")
Check(mk.VisibilityDriver() == "[group] show; hide" and not bar:IsShown(), "in a group: hidden while solo")
QN_CONDITIONS.group = true
UpdateStateDrivers()
Check(bar:IsShown(), "in a group: shown in a group")
Set("visibility", "raid")
Check(mk.VisibilityDriver() == "[group:raid] show; hide" and not bar:IsShown(), "in a raid: hidden in a party")
Set("visibility", "group")
QN_GROUP = { "party1" }
Set("leaderOnly", true)
Check(mk.VisibilityDriver() == "hide" and not bar:IsShown(), "leader only: hidden without lead")
QN_LEADER = true
FireEvent("PARTY_LEADER_CHANGED")
Check(mk.VisibilityDriver() == "[group] show; hide" and bar:IsShown(), "leader only: shown as leader")
QN_LEADER, QN_ASSIST = nil, true
FireEvent("GROUP_ROSTER_UPDATE")
Check(bar:IsShown(), "leader only: shown as assistant")
Set("leaderOnly", false)
QN_ASSIST = nil
SlashCmdList.QNMARKERS("hide")
Check(not db.shown and not bar:IsShown(), "/qnmarkers hide")
SlashCmdList.QNMARKERS("toggle")
Check(db.shown and bar:IsShown(), "/qnmarkers toggle shows it again")

---------------------------------------------------------------------------
-- Combat
---------------------------------------------------------------------------
QN_COMBAT = true
printed = {}
Set("size", 30)
Set("gap", 4)
Check(bar:GetHeight() == 36 and #printed == 1 and printed[1] == L["The change will be applied after combat."], "in combat: not applied, one message")
QN_LEADER = true
Set("leaderOnly", true)
QN_LEADER = nil
FireEvent("GROUP_ROSTER_UPDATE")   -- must not touch the protected bar
Check(bar:IsShown(), "in combat: group change waits")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Check(bar:GetHeight() == 30 + 2 * 8 and not bar:IsShown(), "after combat: size and visibility applied")
Set("leaderOnly", false)
Set("size", 28)
Set("gap", 2)

---------------------------------------------------------------------------
-- Profiles
---------------------------------------------------------------------------
SetEditModeLayout(3)
Check(mk.db ~= db and mk.db.size == 28, "new layout: copy of the previous profile")
Set("orientation", "vertical")
Check(bar:GetHeight() == 432, "vertical in the new profile")
SetEditModeLayout(1)
Check(mk.db == db and db.orientation == "horizontal" and bar:GetWidth() == 432, "back to the first profile: horizontal again")

---------------------------------------------------------------------------
-- Options and commands
---------------------------------------------------------------------------
local vis = INITIALIZERS.QNMARKERS_VISIBILITY
Check(vis and #vis.getOptions() == 3, "visibility as a dropdown with three choices")
Check(INITIALIZERS.QNMARKERS_ORIENTATION and #INITIALIZERS.QNMARKERS_ORIENTATION.getOptions() == 2, "orientation as a dropdown")
Check(INITIALIZERS.QNMARKERS_BORDERCOLOR and INITIALIZERS.QNMARKERS_BORDERCOLOR:IsModifiable(), "border color usable while not floating")
Set("floating", true)
Check(not INITIALIZERS.QNMARKERS_BORDERCOLOR:IsModifiable(), "border color disabled while floating")
Set("floating", false)
printed = {}
SlashCmdList.QNMARKERS("help")
Check(#printed == 1 and printed[1]:find("/qnmarkers visible", 1, true) ~= nil, "help for the commands")
SlashCmdList.QNMARKERS("")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
