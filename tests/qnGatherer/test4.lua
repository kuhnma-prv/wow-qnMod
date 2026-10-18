-- Scenario 4: qnGatherer - coordinates, distances, stored node fields, saved variable defaults
C_Map.GetMapWorldSize = function(map) if map == 1 then return 0, 0 end return 2000, 1000 end
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
local DB = gt.DB

-- encoding round trip: decoded value lies at most one cell below the original
local ok = true
for _, p in ipairs({ { 0, 0 }, { 0.5, 0.25 }, { 0.12345, 0.6789 }, { 0.99999, 0.99999 }, { 0.0001, 0.9999 } }) do
	local x, y = DB.Decode(DB.Encode(p[1], p[2]))
	if x > p[1] or x <= p[1] - 0.0001 - 1e-9 or y > p[2] or y <= p[2] - 0.0001 - 1e-9 then
		ok = false
		print("round trip off: " .. p[1] .. "," .. p[2] .. " -> " .. x .. "," .. y)
	end
end
Check(ok, "coordinate round trip within one cell")
Check(DB.Encode(0, 0) == 0 and DB.Encode(0.99995, 0.99995) == 99999999, "coordinate limits")

-- distances in yards from the map's world size; maps without size count as 1000 yd
Check(math.abs(DB.Yards(1429, 0, 0, 0.01, 0) - 20) < 1e-6, "x distance from world width")
Check(math.abs(DB.Yards(1429, 0, 0, 0, 0.01) - 10) < 1e-6, "y distance from world height")
Check(math.abs(DB.Yards(1, 0, 0, 0.01, 0) - 10) < 1e-6, "map without world size: 1000 yd")

-- position limits
local function Node(x, y, extra)
	local rec = { t = "node", kind = "treasure", map = 1429, x = x, y = y, res = "n:treasure:Battered Chest" }
	for k, v in pairs(extra or {}) do rec[k] = v end
	return rec
end
Check(DB.Ingest(Node(0, 0), "own") == "added", "x = 0, y = 0 accepted")
Check(DB.Ingest(Node(1, 0.5), "own") == nil, "x = 1 rejected")

-- stored fields: first/last/seen from the record, repaired if invalid
DB.Ingest(Node(0.4, 0.4, { first = 1000, last = 500, seen = 0 }), "import:gm2")
local n = DB.GetNode("treasure", 1429, DB.Encode(0.4, 0.4))
Check(n and n.res == "n:treasure:Battered Chest" and n.first == 1000 and n.last == 1000 and n.seen == 1
	and n.origin == "import:gm2", "node fields stored and repaired")
DB.Ingest(Node(0.6, 0.6, { first = 2000, last = 3000, seen = 4 }), "guild:A-Realm")
n = DB.GetNode("treasure", 1429, DB.Encode(0.6, 0.6))
Check(n.first == 2000 and n.last == 3000 and n.seen == 4, "valid fields kept")
local stored = qnGathererDB.global.nodes.treasure[1429][DB.Encode(0.6, 0.6)]
Check(type(stored) == "string" and stored:find("^n:treasure:Battered Chest|2000|3000|4|%d+$") ~= nil, "packed format: " .. tostring(stored))

-- saved variable layout and defaults
local g = qnGathererDB.global
Check(g.sync.enabled == true and g.sync.shareImports == false and g.sync.relayGuild == false, "sync defaults: on, imports not shared")
Check(g.radius.herb == 15 and g.radius.gas == 50 and g.radius.logging == 20, "radius defaults")
Check(qnGathererDB.settingsVersion == "1.0", "settings version")
Check(gt.db and gt.db.show and gt.db.show.treasure == "always" and gt.db.show.herb == "profession", "profile defaults")
Check(gt.KINDS.mine.name == MINING and gt.KINDS.treasure.name == gt.L["Treasure"], "kind names: Blizzard texts or localized")
Check(gt.KindAvailable("mine") == (C_Spell.GetSpellName(2575) ~= nil), "kind availability from the spell")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
