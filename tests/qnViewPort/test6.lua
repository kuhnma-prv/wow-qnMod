-- Scenario 6: qnViewPort – an explicitly chosen constraint of the UI to the main monitor
-- is kept: after Blizzard's UpdateUIParentPosition (PLAYER_ENTERING_WORLD), recalculated on new
-- UI scale or window size, in combat only afterwards, without recursion.
-- monitors from qnViewPort\Monitors.lua: 5760 × 2160, main monitor 3840 × 2160 on the left.

qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { profiles = { ["account:Raid"] = { dual = { enabled = true } } }, global = {} }
LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(3)
RunTimers()

-- count calls of Blizzard's function (hook after qnViewPort's)
local calls = 0
hooksecurefunc("UpdateUIParentPosition", function() calls = calls + 1 end)

local ux = vp.UnitsPerPixel()
local function Near(a, b) return math.abs(a - b) < 1e-6 end
-- UIParent with exactly the two own points on the main monitor (1920 pixels free on the right)
local function OnMain(scale)
	local p = UIParent._points
	return p and #p == 2 and p[1][1] == "TOPLEFT" and p[2][1] == "BOTTOMRIGHT"
		and Near(p[2][2], -1920 * ux / (scale or 1)) and Near(p[2][3], 0)
end

-- without button press: Blizzard's call stays untouched
UIParent._points = {}
UpdateUIParentPosition()
Check(#UIParent._points == 1 and not vp.Layout.IsUIConstrained(), "without constraint: only Blizzard's point")

-- button "UI onto the main monitor"
vp.Layout.ConstrainUI()
Check(vp.Layout.IsUIConstrained() and OnMain(), "button: UIParent on the main monitor")

-- Blizzard resets TOPLEFT (loading screen): constraint is re-applied immediately
UpdateUIParentPosition()
Check(OnMain() and vp.Layout.IsUIConstrained(), "after UpdateUIParentPosition: constraint re-applied")
FireEvent("PLAYER_ENTERING_WORLD", false, false) RunTimers()
UpdateUIParentPosition()
Check(OnMain(), "loading screen: constraint stays")
Check(calls == 3, "no recursion: Blizzard's function called only three times (" .. calls .. ")")

-- new UI scale: offsets recalculated in UIParent units
rawset(UIParent, "GetScale", function() return 2 end)
FireEvent("UI_SCALE_CHANGED") RunTimers()
Check(OnMain(2), "UI_SCALE_CHANGED: offsets recalculated with scale 2")
rawset(UIParent, "GetScale", nil)
FireEvent("DISPLAY_SIZE_CHANGED") RunTimers()
Check(OnMain(1), "DISPLAY_SIZE_CHANGED: with scale 1 again")

-- in combat: only after combat
QN_COMBAT = true
UIParent._points = {}
UpdateUIParentPosition()
Check(#UIParent._points == 1, "combat: nothing moved")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(OnMain(), "after combat: constraint re-applied")

-- reset: afterwards only Blizzard again
vp.Layout.ReleaseUI()
UIParent._points = {}
UpdateUIParentPosition()
Check(#UIParent._points == 1 and not vp.Layout.IsUIConstrained(), "after reset: Blizzard's point stays")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
