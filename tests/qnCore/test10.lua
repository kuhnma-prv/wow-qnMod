-- Scenario 10: position relative to UIParent in the addons (qnCore.PointOffset/NearestCorner):
-- qnThreatMeter stores in UIParent units (no jump when changing the scale, markers of the
-- conversions before settings 1.0 are deleted), qnBuffMod anchors correctly with a shifted UIParent.

qnCoreCharDB = { layout = "account:Raid" }
qnThreatMeterDB = { settingsVersion = "1.0", global = {}, profiles = {
	["account:Raid"] = { scale = 1.5, point = { "TOPLEFT", "BOTTOMLEFT", 150, 900 }, pointInParentUnits = true, styleVersion = 2 },
} }

LoadAddon("qnCore")
local meter = LoadAddon("qnThreatMeter")
local bm = LoadAddon("qnBuffMod")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
SetEditModeLayout(3)

---------------------------------------------------------------------------
-- qnThreatMeter
---------------------------------------------------------------------------
local raid = qnThreatMeterDB.profiles["account:Raid"]
Check(raid.pointInParentUnits == nil and raid.styleVersion == nil, "obsolete conversion markers deleted")
Check(raid.point[3] == 150 and raid.point[4] == 900,
	("position in UIParent units unchanged: %s, %s"):format(raid.point[3], raid.point[4]))
local f = meter.Threat.frame
local function LastPoint()
	return f._points[#f._points]
end
local p = LastPoint()
Check(p[1] == "TOPLEFT" and p[2] == UIParent and p[3] == "BOTTOMLEFT" and math.abs(p[4] - 100) < 1e-9 and math.abs(p[5] - 600) < 1e-9,
	("position in window units (÷ 1.5 = 100, 600): %s, %s"):format(p[4], p[5]))
SETTINGS.QNTHREATMETER_SCALE:SetValue(2)
p = LastPoint()
Check(math.abs(p[4] - 75) < 1e-9 and math.abs(p[5] - 450) < 1e-9 and raid.point[3] == 150,
	("scale 2: corner stays (75, 450 in window units): %s, %s"):format(p[4], p[5]))
-- saving after dragging: UIParent units
f.GetLeft = function() return 50 end
f.GetBottom = function() return 100 end
f.GetHeight = function() return 100 end
f.GetEffectiveScale = function() return 2 end
meter.Window.SavePosition(f)
Check(raid.point[3] == 100 and raid.point[4] == 400, ("SavePosition in UIParent units: %s, %s"):format(raid.point[3], raid.point[4]))

---------------------------------------------------------------------------
-- qnBuffMod: shifted UIParent (qnViewPort: UI on the main monitor)
---------------------------------------------------------------------------
local win = bm.GetWindow(1)
local af = win.frame
af.GetLeft = function() return 150 end
af.GetBottom = function() return 110 end
af.GetWidth = function() return 40 end
af.GetHeight = function() return 40 end
UIParent.GetLeft = function() return 100 end
UIParent.GetBottom = function() return 50 end
win:Reanchor(false)
local ap = af._points[#af._points]
Check(ap[1] == "TOPLEFT" and ap[2] == UIParent and ap[3] == "BOTTOMLEFT" and ap[4] == 50 and ap[5] == 100,
	("anchor relative to the shifted UIParent: %s %s %s"):format(tostring(ap[3]), tostring(ap[4]), tostring(ap[5])))
-- top right: offset to UIParent's TOPRIGHT corner (100 + 1920, 50 + 1080)
af.GetLeft = function() return 1900 end
af.GetBottom = function() return 1000 end
win:Reanchor(false)
ap = af._points[#af._points]
Check(ap[3] == "TOPRIGHT" and ap[4] == 1900 - 2020 and ap[5] == 1040 - 1130,
	("top right corner: %s %s %s"):format(tostring(ap[3]), tostring(ap[4]), tostring(ap[5])))
win:Reanchor(true)
ap = af._points[#af._points]
Check(ap[4] == -120 and ap[5] == -90, "on screen: stays if the anchor point is already inside")
-- anchor point right outside UIParent: pulled to the edge with keep-on-screen
af.GetLeft = function() return 2100 end
win:Reanchor(true)
ap = af._points[#af._points]
Check(ap[3] == "TOPRIGHT" and ap[4] == 0 and ap[5] == -90, ("outside: anchor point to the edge: %s %s"):format(tostring(ap[4]), tostring(ap[5])))
win:SavePosition()
local pos = bm.db.windows[1].position
Check(pos[1] == "TOPLEFT" and pos[2] == "UIParent" and pos[3] == "TOPRIGHT" and pos[4] == 0 and pos[5] == -90 and pos[6] == 40, "position saved")
UIParent.GetLeft, UIParent.GetBottom = nil, nil

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
