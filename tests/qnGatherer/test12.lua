-- Scenario 12: qnGatherer - import from GatherMate2 (names, coordinates, unknown IDs, offline names,
-- tombstones), text export and import, records of the offline tool
C_Map.GetMapWorldSize = function() return 2000, 1000 end
C_Map.GetBestMapForUnit = function() return 1429 end
-- floats: GatherMate2's coordinates exceed 32-bit integers (fengari) - in WoW all numbers are doubles
local function GM2Coord(x, y) return math.floor(x * 10000 + 0.5) * 1000000.0 + math.floor(y * 10000 + 0.5) * 100.0 end
GatherMate2HerbDB = { [1429] = { [GM2Coord(0.4, 0.5)] = 401 } }
GatherMate2MineDB = { [1429] = { [GM2Coord(0.6, 0.7)] = 201, [GM2Coord(0.2, 0.2)] = 202 } }
GatherMate2 = { GetNameForNode = function(_, nodeType, id)
	local names = { ["Herb Gathering"] = { [401] = "Friedensblume" }, Mining = { [201] = "Kupferader" } }
	return names[nodeType] and names[nodeType][id]
end }
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local DB, I = gt.DB, gt.Import
local MAP = 1429
local locale = GetLocale()

local x, y = gt.DecodeGatherMate2(GM2Coord(0.4, 0.5))
Check(math.abs(x - 0.4) < 1e-9 and math.abs(y - 0.5) < 1e-9, "GatherMate2 coordinates decoded")

-- the copper vein is known from own gathering
DB.Ingest({ t = "res", res = "o:1731", kind = "mine", item = 2770, names = { [locale] = "Kupferader" } }, "own")
local counts = I.Run("gm2", { quiet = true })
Check(counts and counts.rejected == 0, "imported")
local function NodeAt(kind, nx, ny) return DB.GetNode(kind, MAP, DB.Encode(nx, ny)) end
Check(NodeAt("mine", 0.6, 0.7) and NodeAt("mine", 0.6, 0.7).res == "o:1731", "known name gives the object key")
Check(NodeAt("herb", 0.4, 0.5) and NodeAt("herb", 0.4, 0.5).res == "n:herb:Friedensblume", "unknown name: name key")
Check(DB.GetResource("n:herb:Friedensblume").names[locale] == "Friedensblume", "name key in the catalog")
Check(NodeAt("mine", 0.2, 0.2).res == "n:mine:#202" and NodeAt("mine", 0.2, 0.2).origin == "import:gm2", "name unknown: GatherMate2 ID")

-- names of the offline tool take precedence
QNGATHERER_GM2_NAMES = { Mining = { [202] = "Zinnader" } }
I.Run("gm2", { mode = "replace", quiet = true })
Check(NodeAt("mine", 0.2, 0.2) and NodeAt("mine", 0.2, 0.2).res == "n:mine:Zinnader", "offline names used")
QNGATHERER_GM2_NAMES = nil

-- deleted nodes stay deleted
DB.Delete("herb", MAP, DB.Encode(0.4, 0.5))
counts = I.Run("gm2", { quiet = true })
Check(counts.reasons.tombstone == 1 and DB.CountNodes("herb", MAP) == 0, "tombstone blocks the import")

-- own gathering later upgrades the name key: covered by the collector (scenario 5)

-- text export and import
DB.Ingest({ t = "node", kind = "treasure", map = MAP, x = 0.3, y = 0.3, res = "n:treasure:Truhe", first = 100, last = 200, seen = 3 }, "own")
DB.Ingest({ t = "area", kind = "fish", map = MAP, x = 0.5, y = 0.5, rx = 0.055, ry = 0.075, class = "learned", res = { "i:6291" } }, "own")
DB.Ingest({ t = "res", res = "i:6291", kind = "fish", item = 6291 }, "own")
local text = I.Export()
Check(text:sub(1, 5) == "QNG|1" and text:find("N|treasure|" .. MAP .. "|", 1, true) and text:find("A|fish|" .. MAP .. "|", 1, true), "export text")
Check(not text:find("o:1731", 1, true) or text:find("R|o:1731", 1, true), "imported nodes are not exported")
local records = I.ParseText(text)
Check(records and #records >= 3 and records[1].t == "res", "export parsed, catalog first")
Check(I.ParseText("hello") == nil and select(2, I.ParseText("hello")) == "header", "other text rejected")
DB.ClearKind("treasure")
DB.ClearKind("fish")
counts = I.FromText(text)
local chest = NodeAt("treasure", 0.3, 0.3)
Check(counts.added >= 2 and chest and chest.origin == "import:text" and chest.seen == 3 and chest.first == 100, "text imported with its fields")
Check(#DB.GetAreas("fish", MAP) == 1, "areas imported")
Check(I.FromText("QNG|2") == nil, "wrong version rejected")

-- records of the offline tool
qnGathererDB.global.pendingImport = { { adapter = "gm2", version = "1.52", records = {
	{ t = "node", kind = "treasure", map = MAP, x = 0.8, y = 0.8, res = "n:treasure:Kiste" },
	{ t = "node", kind = "nope", map = MAP, x = 0.8, y = 0.8, res = "x" },
} } }
I.TakePending()
Check(NodeAt("treasure", 0.8, 0.8) and NodeAt("treasure", 0.8, 0.8).origin == "import:gm2", "offline records taken over")
Check(qnGathererDB.global.pendingImport == nil and qnGathererDB.global.imports.gm2 == "1.52", "pending import cleared, version remembered")

-- adapter without data
GatherMate2HerbDB, GatherMate2MineDB = nil, nil
Check(gt.Actions.Import("gm2", "merge") == nil, "no data: nothing imported")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
