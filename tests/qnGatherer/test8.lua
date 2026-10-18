-- Scenario 8: qnGatherer - minimap: projection (rotation, shapes, edge), pins, tracking ring
C_Map.GetMapWorldSize = function() return 1000, 1000 end   -- 0.1 map = 100 yd
C_Map.GetBestMapForUnit = function() return 1429 end
QN_SKILLS = { [186] = 1 }
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local DB, M = gt.DB, gt.Minimap
local MAP = 1429
local function Near(a, b) return math.abs(a - b) < 1e-6 end

-- projection
local sx, sy, d = M.Project(10, 0, nil, 100, "ROUND")
Check(Near(sx, 10) and Near(sy, 0) and Near(d, 0.1), "east is right")
sx, sy = M.Project(0, 10, nil, 100, "ROUND")
Check(Near(sx, 0) and Near(sy, -10), "south is down")
sx, sy = M.Project(-10, 0, math.pi / 2, 100, "ROUND")
Check(Near(sx, 0) and Near(sy, 10), "rotating minimap: facing west, west is up")
sx, sy = M.Project(0, -10, math.pi / 2, 100, "ROUND")
Check(Near(sx, 10) and Near(sy, 0), "rotating minimap: facing west, north is right")
sx, sy, d = M.Project(200, 0, nil, 100, "ROUND")
Check(Near(sx, 100) and Near(d, 2), "outside: moved onto the edge")
sx, sy, d = M.Project(90, -90, nil, 100, "ROUND")
Check(d > 1, "round: corner outside")
sx, sy, d = M.Project(90, -90, nil, 100, "SQUARE")
Check(Near(d, 0.9) and Near(sx, 90), "square: corner inside")
local _, _, dTop = M.Project(90, -90, nil, 100, "CORNER-TOPRIGHT")
local _, _, dBottom = M.Project(90, 90, nil, 100, "CORNER-TOPRIGHT")
Check(dTop > 1 and Near(dBottom, 0.9), "corner shape: one round quadrant")
_, _, d = M.Project(90, -90, nil, 100, "UNKNOWN")
Check(d > 1, "unknown shape counts as round")

-- pins: player in the middle, view radius 100 yd, minimap 100 px wide (0.5 px per yard)
QN_POS = { 0.5, 0.5 }
DB.Ingest({ t = "node", kind = "mine", map = MAP, x = 0.55, y = 0.5, res = "i:2770" }, "own")   -- 50 yd east
DB.Ingest({ t = "node", kind = "mine", map = MAP, x = 0.65, y = 0.5, res = "i:2770" }, "own")   -- 150 yd: edge
DB.Ingest({ t = "node", kind = "mine", map = MAP, x = 0.75, y = 0.5, res = "i:2770" }, "own")   -- 250 yd: hidden
DB.Ingest({ t = "node", kind = "herb", map = MAP, x = 0.5, y = 0.45, res = "i:2447" }, "own")   -- no Herbalism
RunTimers()
Check(M.Update() == 2, "pin inside and pin on the edge")
local inner, edge
for _, pin in ipairs(M.Pins) do
	if pin:IsShown() then
		if pin.entry.x < 0.6 then inner = pin else edge = pin end
	end
end
Check(inner and Near(inner.ox, 25) and Near(inner.oy, 0) and inner._alpha == 1, "inner pin position and alpha")
Check(inner.ring == true, "within the tracking distance: ring")
Check(edge and Near(edge.ox, 50) and Near(edge._alpha, 0.5) and not edge.ring, "edge pin: on the edge, faded, no ring")

gt.db.circle.show = "never"
gt.Display.Refresh()
RunTimers()
M.Update()
Check(not inner.ring, "ring switched off")
gt.db.minimap.edge = false
Check(M.Update() == 1, "edge switched off")
gt.db.minimap.edge = true

-- rotating minimap: facing west, the node in the east is behind (down)
C_CVar._v.rotateMinimap, QN_FACING = "1", math.pi / 2
M.Update()
Check(Near(inner.ox, 0) and Near(inner.oy, -25), "rotating minimap")
C_CVar._v.rotateMinimap = "0"

-- square minimap from another addon
DB.Ingest({ t = "node", kind = "mine", map = MAP, x = 0.58, y = 0.42, res = "i:2770" }, "own")   -- 80/80 yd north-east
RunTimers()
Check(M.Update() == 3, "new node after a data change")
GetMinimapShape = function() return "SQUARE" end
local corner
M.Update()
for _, pin in ipairs(M.Pins) do
	if pin:IsShown() and pin.entry.y < 0.45 then corner = pin end
end
Check(corner and corner._alpha == 1 and Near(corner.ox, 40) and Near(corner.oy, 40), "square minimap: corner inside")
GetMinimapShape = nil

-- switched off, no position
gt.db.minimap.show = false
gt.Display.Refresh()
RunTimers()
Check(M.Update() == 0 and not inner:IsShown(), "minimap icons switched off")
gt.db.minimap.show = true
QN_POS = nil
Check(M.Update() == 0, "no position (instance): no pins")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
