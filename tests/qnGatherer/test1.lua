-- Scenario 1: qnGatherer - Ingest: validation, merging within the radius, rare variants, areas, zones, catches
C_Map.GetMapWorldSize = function() return 2000, 1000 end   -- 0.001 x = 2 yd, 0.001 y = 1 yd
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
local DB = gt.DB
local MAP = 1429
local function Node(x, y, res, extra)
	local rec = { t = "node", kind = "mine", map = MAP, x = x, y = y, res = res }
	for k, v in pairs(extra or {}) do rec[k] = v end
	return rec
end

Check(qnGatherer == gt, "global API qnGatherer")
Check(qnGathererDB.global.origins[1] == "own", "origin own has id 1")
Check(DB.Radius("mine") == 15 and DB.Radius("gas") == 50, "default radii")
Check(gt.KindForSpell(2575) == "mine" and gt.KindForSpell(1) == nil, "kind of a gathering spell")

-- invalid records
local bad = {
	Node(1.2, 0.5, "i:2770"),
	Node(0.5, -0.1, "i:2770"),
	{ t = "node", kind = "nope", map = MAP, x = 0.5, y = 0.5, res = "i:2770" },
	{ t = "node", kind = "mine", map = 1.5, x = 0.5, y = 0.5, res = "i:2770" },
	Node(0.5, 0.5, "x:1"),
	Node(0.5, 0.5, "n:mine:a|b"),
	{ t = "what" },
	{ t = "area", kind = "fish", map = MAP, x = 0.3, y = 0.3, rx = 0, ry = 0.1, class = "learned", res = { "i:1" } },
	{ t = "area", kind = "fish", map = MAP, x = 0.3, y = 0.3, rx = 0.1, ry = 0.1, class = "guess", res = { "i:1" } },
	{ t = "zone", kind = "fish", map = MAP, min = 30, max = 10 },
	{ t = "catch", char = "", map = MAP, item = 1, n = 1 },
	{ t = "res", res = "i:1", kind = "fish", rareOf = "bad" },
}
for i, rec in ipairs(bad) do
	local r, why = DB.Ingest(rec, "own")
	Check(r == nil and why == "invalid", "invalid record " .. i .. " rejected")
end
Check(DB.Ingest(Node(0.5, 0.5, "i:2770"), "") == nil, "empty origin rejected")
Check(DB.CountNodes("mine") == 0, "nothing stored from invalid records")

-- add and merge
Check(DB.Ingest(Node(0.5, 0.5, "i:2770"), "own") == "added", "node added")
Check(DB.Ingest(Node(0.505, 0.5, "i:2770"), "guild:Other-Realm") == "merged" and DB.CountNodes("mine", MAP) == 1,
	"same resource 10 yd away merged")
local coord, node = DB.Nodes("mine", MAP)()
Check(node.seen == 2 and node.origin == "own", "seen added up, own origin kept")
Check(math.abs(DB.Decode(coord) - 0.5025) < 0.0002, "position weighted by seen")
Check(DB.Ingest(Node(0.52, 0.5, "i:2770"), "own") == "added" and DB.CountNodes("mine", MAP) == 2,
	"same resource 35 yd away: new node")
Check(DB.Ingest(Node(0.5, 0.505, "i:2771"), "own") == "added" and DB.CountNodes("mine", MAP) == 3,
	"other resource nearby stays separate")

-- rare variants (from the catalog)
Check(DB.Ingest({ t = "res", res = "i:2775", kind = "mine", item = 2775, rareOf = "i:2770" }, "own") == "added",
	"catalog entry added")
Check(DB.GetResource("i:2775").rareOf == "i:2770", "catalog knows the rare variant")
Check(DB.Ingest(Node(0.52, 0.502, "i:2775"), "own") == "replaced" and DB.CountNodes("mine", MAP) == 3,
	"rare variant replaces the normal node")
Check(DB.Ingest(Node(0.52, 0.503, "i:2770"), "own") == "kept" and DB.CountNodes("mine", MAP) == 3,
	"normal node next to the rare variant dropped")

-- a node found by others becomes own when gathered ourselves
DB.Ingest(Node(0.3, 0.3, "o:1731"), "guild:Other-Realm")
local c = DB.Encode(0.3, 0.3)
Check(DB.GetNode("mine", MAP, c).origin == "guild:Other-Realm", "guild origin stored")
DB.Ingest(Node(0.3, 0.3, "o:1731"), "own")
local own
for _, n in DB.Nodes("mine", MAP) do
	if n.res == "o:1731" then own = n end
end
Check(own and own.origin == "own" and own.seen == 2, "own gathering takes over the guild node")

-- catalog: imports do not overwrite own values, names are merged
DB.Ingest({ t = "res", res = "i:2775", kind = "mine", skill = 75, names = { deDE = "Silberader" } }, "own")
DB.Ingest({ t = "res", res = "i:2775", kind = "mine", skill = 80, names = { deDE = "X", enUS = "Silver Vein" } }, "import:gt")
local entry = DB.GetResource("i:2775")
Check(entry.skill == 75 and entry.names.deDE == "Silberader" and entry.names.enUS == "Silver Vein", "catalog merge")

-- areas
local function Area(x, y, res, class)
	return { t = "area", kind = "fish", map = MAP, x = x, y = y, rx = 0.055, ry = 0.075, class = class or "learned", res = res }
end
Check(DB.Ingest(Area(0.3, 0.3, { "i:6303" }), "own") == "added", "area added")
Check(DB.Ingest(Area(0.32, 0.33, { "i:6291", "i:6303" }), "own") == "merged", "near area merged")
local areas = DB.GetAreas("fish", MAP)
Check(#areas == 1 and areas[1].res[1] == "i:6291" and areas[1].res[2] == "i:6303", "fish list sorted without duplicates")
Check(DB.Ingest(Area(0.31, 0.31, { "i:6303" }), "own") == "kept", "nothing new: kept")
Check(DB.Ingest(Area(0.3, 0.3, { "i:6303" }, "reported"), "import:gt") == "added", "other class is a separate area")
for i = 1, 29 do
	DB.Ingest(Area((i % 10) / 10 + 0.01, math.floor(i / 10) / 10 + 0.5, { "i:6303" }), "own")
end
local r, why = DB.Ingest(Area(0.05, 0.95, { "i:6303" }), "own")
Check(r == nil and why == "full", "at most 30 learned areas per map")

-- zones
Check(DB.Ingest({ t = "zone", kind = "fish", map = MAP, min = 1, max = 25 }, "own") == "added", "zone added")
Check(DB.Ingest({ t = "zone", kind = "fish", map = MAP, min = 5, max = 30 }, "import:gt") == "kept"
	and DB.GetZone("fish", MAP).max == 25, "import does not overwrite own zone info")

-- catches
DB.Ingest({ t = "catch", char = "Tester-Realm", map = MAP, item = 6303, n = 2 }, "own")
DB.Ingest({ t = "catch", char = "Tester-Realm", map = MAP, item = 6303, n = 3 }, "import:gt")
Check(DB.GetCatches("Tester-Realm", MAP)[6303] == 5, "catches added up per character")
Check(gt.CharKey() == "Tester-Realm", "character key")

-- change listener
local fired
DB.OnChange(function(kind, map) fired = kind .. ":" .. tostring(map) end)
DB.Ingest(Node(0.9, 0.9, "i:2770"), "own")
Check(fired == "mine:" .. MAP, "listener informed")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
