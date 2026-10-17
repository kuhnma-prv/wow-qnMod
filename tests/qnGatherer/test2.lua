-- Scenario 2: qnGatherer - tombstones: deleted nodes do not come back through sync or import
C_Map.GetMapWorldSize = function() return 2000, 1000 end   -- 0.001 x = 2 yd
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
local DB = gt.DB
local MAP = 1429
local function Node(x, y, res)
	return { t = "node", kind = "herb", map = MAP, x = x, y = y, res = res or "i:2447" }
end

DB.Ingest(Node(0.5, 0.5), "own")
local coord = DB.Encode(0.5, 0.5)
Check(DB.Delete("herb", MAP, coord) and DB.CountNodes("herb", MAP) == 0, "single node deleted")
Check(not DB.Delete("herb", MAP, coord), "deleting a missing node fails")
local r, why = DB.Ingest(Node(0.502, 0.5), "guild:Other-Realm")
Check(r == nil and why == "tombstone", "guild sync blocked within the radius")
r, why = DB.Ingest(Node(0.5, 0.5), "import:gm2")
Check(r == nil and why == "tombstone", "import blocked")
Check(DB.Ingest(Node(0.6, 0.5), "guild:Other-Realm") == "added", "outside the radius: allowed")

-- own gathering brings it back and clears the tombstone
Check(DB.Ingest(Node(0.5, 0.5), "own") == "added", "own gathering allowed")
Check(DB.Ingest(Node(0.501, 0.5), "guild:Other-Realm") == "merged", "tombstone cleared by own gathering")

-- deleting a zone leaves tombstones for every node
Check(DB.DeleteZone("herb", MAP) == 2 and DB.CountNodes("herb", MAP) == 0, "zone deleted")
r, why = DB.Ingest(Node(0.6, 0.5), "guild:Other-Realm")
Check(r == nil and why == "tombstone", "zone nodes do not come back")

-- clearing a kind is a reset: no new tombstones
DB.Ingest(Node(0.8, 0.8), "own")
Check(DB.ClearKind("herb") and DB.CountNodes("herb") == 0, "kind cleared")
Check(DB.Ingest(Node(0.8, 0.8), "guild:Other-Realm") == "added", "after a reset sync may fill in again")

-- removing an origin
DB.Ingest(Node(0.1, 0.1, "i:765"), "guild:Third-Realm")
DB.Ingest(Node(0.2, 0.2, "i:765"), "import:gm2")
DB.Ingest({ t = "area", kind = "herb", map = MAP, x = 0.7, y = 0.7, rx = 0.1, ry = 0.1, class = "reported", res = { "i:765" } }, "import:gm2")
Check(DB.DeleteOrigin("guild:") == 2 and DB.CountNodes("herb") == 1, "all guild nodes removed")
Check(DB.DeleteOrigin("import:gm2") == 2 and DB.CountNodes("herb") == 0 and #DB.GetAreas("herb", MAP) == 0,
	"nodes and areas of one import removed")
Check(DB.Ingest(Node(0.1, 0.1, "i:765"), "guild:Third-Realm") == "added", "removing an origin leaves no tombstones")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
