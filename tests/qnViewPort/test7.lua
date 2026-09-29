-- Scenario 7: qnViewPort – account-wide values and profile switch
--   * layoutKey and mapFadeSaved moved from old profiles to qnViewPortDB.global
--   * an applied monitor arrangement counts once per arrangement, not once per profile
--   * without dual monitor mode, with monitor data: main monitor viewport not cut to half
--     the window width
--   * profile switch applies mapFade and releases a constrained UI

local KEY = "5760x2160;0,0,3840,2160*;3840,377,1920,1200"   -- arrangement from qnViewPort\Monitors.lua
qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { global = {}, profiles = {
	["account:Raid"] = { viewport = { 10, 1920, 0, 0 },
		dual = { enabled = true, mapNoFade = true, mapFadeSaved = "1", layoutKey = KEY } },
	["char:Tester-Realm:Solo"] = { viewport = { 5, 0, 0, 0 }, dual = { enabled = false, layoutKey = "" } },
} }
C_CVar._v.mapFade = "0"   -- set by mapNoFade (previously 1)
local CHAT = {}
function DEFAULT_CHAT_FRAME:AddMessage(msg) CHAT[#CHAT + 1] = tostring(msg) end

LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
local L = vp.L
-- messages "Monitor layout applied ..." (text up to the colon, in the client's language)
local TAKEN = L["Monitor layout applied: %d monitors, 3D world on the main monitor (%d × %d)."]:match("^[^:]+")
local function Taken()
	local n = 0
	for _, m in ipairs(CHAT) do if m:find(TAKEN, 1, true) then n = n + 1 end end
	return n
end
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(3)
RunTimers()
local raid, solo = qnViewPortDB.profiles["account:Raid"], qnViewPortDB.profiles["char:Tester-Realm:Solo"]
local g = qnViewPortDB.global

-- 1. migration
Check(g.layoutKey == KEY and raid.dual.layoutKey == nil and solo.dual.layoutKey == nil,
	"layoutKey moved to account-wide, removed from the profiles: " .. tostring(g.layoutKey))
Check(g.mapFadeSaved == "1" and raid.dual.mapFadeSaved == nil, "mapFadeSaved moved to account-wide")
Check(vp.global == g, "ns.global = qnViewPortDB.global")
Check(C_CVar._v.mapFade == "0", "Raid with mapNoFade: mapFade stays 0")
Check(Taken() == 0 and raid.viewport[1] == 10, "known arrangement: not applied again")

-- 2. profile switch: constrained UI released, mapFade back, arrangement not applied again
vp.Layout.ConstrainUI()
Check(vp.Layout.IsUIConstrained(), "Raid: UI on the main monitor")
SetEditModeLayout(4)
Check(vp.db == solo, "profile Solo active")
local pts = UIParent._points
Check(not vp.Layout.IsUIConstrained() and pts[#pts][1] == "BOTTOMRIGHT" and pts[#pts][2] == 0 and pts[#pts][3] == 0,
	"Solo without dual monitor mode: UI across the whole window again")
Check(C_CVar._v.mapFade == "1" and g.mapFadeSaved == nil, "Solo without mapNoFade: mapFade 1 restored")
Check(Taken() == 0 and solo.viewport[1] == 5, "Solo: arrangement not applied again, viewport stays")
SetEditModeLayout(3)
Check(C_CVar._v.mapFade == "0" and g.mapFadeSaved == "1", "back to Raid: mapFade 0, 1 remembered")
Check(not vp.Layout.IsUIConstrained(), "profile switch does not constrain the UI by itself")

-- 3. new arrangement without dual monitor mode: small main monitor left, large one right.
-- window 2880 × 1080 (same aspect ratio): main monitor 960 × 540, 1920 pixels free on the right.
SetEditModeLayout(4)
qnViewPortMonitors = { window = { x = 0, y = 0, width = 5760, height = 2160 }, monitors = {
	{ x = 0, y = 0, width = 1920, height = 1080, main = true },
	{ x = 1920, y = 0, width = 3840, height = 2160 },
} }
C_VideoOptions.GetCurrentGameWindowSize = function() return { x = 2880, y = 1080 } end
FireEvent("DISPLAY_SIZE_CHANGED") RunTimers()
local v = solo.viewport
Check(Taken() == 1 and v[1] == 0 and v[2] == 1920 and v[3] == 0 and v[4] == 540,
	("Solo: main monitor applied, not cut to half the width: %d %d %d %d"):format(v[1], v[2], v[3], v[4]))
Check(g.layoutKey ~= KEY, "new arrangement remembered account-wide")
SetEditModeLayout(3)
Check(Taken() == 1 and raid.viewport[1] == 10 and raid.viewport[2] == 1920,
	"Raid: the same arrangement not applied again, viewport stays")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
