-- Scenario 3: qnGatherer - database lock and cleanup
C_Map.GetMapWorldSize = function() return 2000, 1000 end   -- 0.001 x = 2 yd
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
local DB = gt.DB
local MAP = 1429
local function Node(kind, x, y, res)
	return { t = "node", kind = kind, map = MAP, x = x, y = y, res = res or "i:2770" }
end

DB.Ingest(Node("mine", 0.5, 0.5), "own")
DB.Ingest(Node("mine", 0.515, 0.5), "own")   -- 30 yd apart: two nodes
Check(DB.CountNodes("mine", MAP) == 2, "two nodes")
DB.SetLock("mine", true)
Check(DB.IsLocked("mine") and qnGathererDB.global.locks.mine == true, "lock stored")

local r, why = DB.Ingest(Node("mine", 0.2, 0.2), "own")
Check(r == nil and why == "locked", "locked: no new node")
r, why = DB.Ingest(Node("mine", 0.2, 0.2), "import:gm2")
Check(r == nil and why == "locked", "locked: no import")
r, why = DB.Ingest({ t = "area", kind = "mine", map = MAP, x = 0.2, y = 0.2, rx = 0.1, ry = 0.1, class = "reported", res = { "i:2770" } }, "import:gt")
Check(r == nil and why == "locked", "locked: no area")
Check(not DB.Delete("mine", MAP, DB.Encode(0.5, 0.5)), "locked: no delete")
Check(DB.DeleteZone("mine", MAP) == 0, "locked: no zone delete")
Check(not DB.ClearKind("mine"), "locked: clearing the whole kind refused as well")
Check(DB.DeleteOrigin("own") == 0, "locked: origin removal skips the kind")
qnGathererDB.global.radius.mine = 31
Check(DB.Cleanup("mine") == 0, "locked: no cleanup")
Check(DB.CountNodes("mine", MAP) == 2, "nodes unchanged while locked")
Check(DB.Ingest({ t = "res", res = "i:2770", kind = "mine", item = 2770 }, "own") == "added", "catalog not locked")
Check(DB.Ingest(Node("herb", 0.2, 0.2, "i:2447"), "own") == "added", "other kinds not locked")

-- unlocked: cleanup with the larger radius merges the two nodes
DB.SetLock("mine", false)
Check(not DB.IsLocked("mine") and qnGathererDB.global.locks.mine == nil, "lock removed")
Check(DB.Cleanup("mine") == 1 and DB.CountNodes("mine", MAP) == 1, "cleanup merges within the new radius")
local _, n = DB.Nodes("mine", MAP)()
Check(n.seen == 2, "cleanup adds up seen")

-- cleanup removes unreadable entries
qnGathererDB.global.nodes.mine[MAP][1234] = "garbage"
qnGathererDB.global.nodes.mine[MAP][1235] = "x:1|1|1|1|1"
Check(DB.CleanupMap("mine", MAP) == 2 and DB.CountNodes("mine", MAP) == 1, "unreadable entries removed")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
