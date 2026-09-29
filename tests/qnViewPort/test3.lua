-- Scenario 3: qnViewPort – Blizzard UI onto the main monitor only at the push of a button
-- profile with dual monitor mode on: must not move anything at login.
qnViewPortDB = { settingsVersion = "1.0", profiles = { ["account:Raid"] = { dual = { enabled = true } } }, global = {} }
LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
UIParent._points = nil
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(3)
RunTimers()
Check(UIParent._points == nil and not vp.Layout.IsUIConstrained(), "login: UIParent untouched")

-- button: onto the main monitor (3840 of 5760 pixels width)
vp.Layout.ConstrainUI()
local pts = UIParent._points
Check(vp.Layout.IsUIConstrained() and pts and pts[1][1] == "TOPLEFT" and pts[2][1] == "BOTTOMRIGHT" and pts[2][2] < 0,
	"button: UIParent onto the main monitor")
-- window size: the explicitly chosen constraint stays (recalculated, see scenario 6)
UIParent._points = {}
FireEvent("DISPLAY_SIZE_CHANGED") RunTimers()
pts = UIParent._points
Check(vp.Layout.IsUIConstrained() and #pts == 2 and pts[2][1] == "BOTTOMRIGHT" and pts[2][2] < 0,
	"window size: chosen constraint is kept")
-- reset
vp.Layout.ReleaseUI()
pts = UIParent._points
Check(not vp.Layout.IsUIConstrained() and pts[#pts][2] == 0 and pts[#pts][3] == 0, "reset: whole window")
-- not in combat
QN_COMBAT = true
vp.Layout.ConstrainUI()
QN_COMBAT = false
Check(not vp.Layout.IsUIConstrained(), "nothing moved in combat")
-- dual monitor mode off resets
vp.Layout.ConstrainUI()
SlashCmdList.QNVIEWPORT("dual off") RunTimers()
Check(not vp.Layout.IsUIConstrained(), "mode off: UI across the whole window again")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
