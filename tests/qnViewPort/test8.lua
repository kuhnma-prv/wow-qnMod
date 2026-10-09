-- Scenario 8: qnViewPort – world map on a monitor ("Maps" page)
--   * maximized world map ("worldMap"): size as in Blizzard's UpdateMaximizedSize, but from the
--     selected monitor; top center on the monitor, black area only there
--   * minimized = "Map & Quest Log" ("questLog"): Blizzard's anchor (UIParent TOPLEFT) on the monitor
--   * repositioning by the panel manager (ShowUIPanel/UpdateUIPanelPositions) is followed up
--   * without the option qnViewPort does not touch the map; switching off restores Blizzard's position

qnViewPortMonitors = { window = { x = 0, y = 0, width = 5760, height = 2160 }, monitors = {
	{ x = 0, y = 0, width = 3840, height = 2160, main = true },
	{ x = 3840, y = 377, width = 1920, height = 1200 },
} }
C_VideoOptions.GetCurrentGameWindowSize = function() return { x = 5760, y = 2160 } end
qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { global = {}, profiles = { ["account:Raid"] = { dual = { enabled = true } } } }

LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(3)
RunTimers()

-- realistic area: 5760 × 2160 pixels at UI scale as in the client (1 unit ≈ 1.69 pixels)
vp.screenRef:SetSize(3413, 1280)
UIParent:SetSize(3413, 1280)
vp.Dual.ApplyAll()

local f = WorldMapFrame
local d = vp.db.dual
local function P(frame, i) return (frame._points or {})[i or 1] or {} end
-- number of the 2nd monitor in the selection (as on the "Monitors" page)
local second
for i, r in ipairs(vp.Layout.GetVisible()) do
	if r.x == 3840 then second = i end
end
Check(second ~= nil, "2nd monitor in the selection")
local ux = vp.UnitsPerPixel()
local function OnSecond(area)
	local p = P(area)
	return p[1] == "TOPLEFT" and p[2] == vp.screenRef and math.abs(p[4] - 3840 * ux) < 0.01
end

-- 1. without option: Blizzard's position stays
ShowUIPanel(f) f:Maximize() RunTimers()
Check(P(f)[1] == "TOP" and P(f)[2] == UIParent, "without option: maximized map on UIParent")
Check(P(f.BlackoutFrame)[2] == UIParent, "without option: black area over UIParent")
f:Minimize() RunTimers()
Check(P(f)[1] == "TOPLEFT" and P(f)[2] == UIParent and P(f)[4] == 16, "without option: minimized map on UIParent")

-- 2. maximized map onto the 2nd monitor
d.worldMap, d.worldMapMonitor = true, second
vp.Dual.ApplyAll()
f:Maximize() RunTimers()
local area = P(f)[2]
Check(P(f)[1] == "TOP" and area ~= UIParent and P(f)[3] == "TOP" and OnSecond(area), "maximized: top center on the 2nd monitor")
Check(P(f.BlackoutFrame)[1] == "ALL" and P(f.BlackoutFrame)[2] == area, "maximized: black area only on the monitor")
-- Blizzard's calculation with the monitor area: width from height, clamped by monitor width - 30
local aw, ah = area:GetWidth(), area:GetHeight()
local unclamped = (ah - 67) * 702 / (534 - 67)
local w = math.min(aw - 30, unclamped)
Check(math.abs(aw - 1920 * ux) < 0.01 and f._w == math.floor(w) and f._h == math.floor((ah - 67) * (w / unclamped) + 67)
	and f._w > 0 and f._w <= aw - 30,
	("maximized: size from the monitor (%s × %s in %s × %s)"):format(f._w, f._h, aw, ah))
-- panel manager repositions the map: followed up
UpdateUIPanelPositions(f)
Check(P(f)[2] == area, "back on the monitor after UpdateUIPanelPositions")

-- 3. minimized without questLog: Blizzard's position, black area back
f:Minimize() RunTimers()
Check(P(f)[2] == UIParent and P(f.BlackoutFrame)[2] == UIParent, "minimized without questLog: on UIParent, area back")

-- 4. "Map & Quest Log" onto the 2nd monitor: Blizzard's anchor on the monitor
d.questLog, d.questLogMonitor = true, second
vp.Dual.ApplyAll()
local p = P(f)
local qArea = p[2]
Check(p[1] == "TOPLEFT" and qArea ~= UIParent and p[3] == "TOPLEFT" and p[4] == 16 and p[5] == -116 and OnSecond(qArea),
	"Map & Quest Log: Blizzard's offset on the 2nd monitor")
ShowUIPanel(f) RunTimers()
Check(P(f)[2] == qArea and P(f)[4] == 16, "back on the monitor after ShowUIPanel, offset not doubled")

-- 5. switching off: back to Blizzard's position
d.questLog = false
vp.Dual.ApplyAll()
Check(P(f)[2] == UIParent and P(f)[4] == 16 and P(f)[5] == -116, "questLog off: on UIParent again")
f:Maximize() RunTimers()
Check(P(f)[2] ~= UIParent, "maximized with worldMap: on the monitor")
d.worldMap = false
vp.Dual.ApplyAll()
Check(P(f)[1] == "TOP" and P(f)[2] == UIParent and P(f.BlackoutFrame)[2] == UIParent, "worldMap off: on UIParent again")
f:Minimize() f:Maximize() RunTimers()
Check(P(f)[2] == UIParent, "afterwards qnViewPort no longer touches the map")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
