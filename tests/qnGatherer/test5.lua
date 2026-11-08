-- Scenario 5: qnGatherer - collector: gathering cast + loot -> node; object, item and name keys;
-- skill error; upgrading name and item keys; ignored events
C_Map.GetMapWorldSize = function() return 2000, 1000 end   -- 0.001 x = 2 yd, 0.001 y = 1 yd
C_Map.GetBestMapForUnit = function() return 1429 end
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
local DB, C = gt.DB, gt.Collector
local MAP = 1429
local LOCALE = GetLocale()

local function Gather(spell, target, loot, unit)
	FireEvent("UNIT_SPELLCAST_SENT", unit or "player", target or "", "Cast-1", spell)
	QN_LOOT = loot or {}
	FireEvent("LOOT_OPENED", false, false)
	QN_LOOT = {}
end
local function NodeAt(kind, x, y)
	return DB.GetNode(kind, MAP, DB.Encode(x, y))
end
local function Obj(id) return "GameObject-0-1-2-3-" .. id .. "-0000ABCD" end

-- GlobalString patterns
Check(C.Pattern("Requires %s %d") == "^Requires (.+) (%d+)$", "pattern with %s/%d")
Check(C.Pattern("Benötigt %1$s %2$d") == "^Benötigt (.+) (%d+)$", "pattern with positional arguments")
Check(C.Pattern("100% (x)") == "^100%% %(x%)$", "magic characters escaped")
Check(C.ObjectID(Obj(1731)) == 1731 and C.ObjectID("Creature-0-1-2-3-99-0") == nil, "object ID only from game objects")

-- 1: mining with loot source: object key, catalog with item and name
QN_POS = { 0.4, 0.4 }
Gather(2575, "Kupferader", { { item = 2770, n = 3, source = Obj(1731) }, { item = 2835, n = 1, source = Obj(1731) } })
local n = NodeAt("mine", 0.4, 0.4)
Check(n and n.res == "o:1731" and n.origin == "own", "node stored with object key")
local entry = DB.GetResource("o:1731")
Check(entry and entry.kind == "mine" and entry.item == 2770 and entry.names[LOCALE] == "Kupferader", "catalog: item and name")
Check(C.cast == nil, "cast consumed by its loot")

-- 2: without loot source the name finds the object key
local LootSource = GetLootSourceInfo
GetLootSourceInfo = nil
QN_POS = { 0.6, 0.6 }
Gather(2575, "Kupferader", { { item = 2770, n = 2 } })
Check(NodeAt("mine", 0.6, 0.6).res == "o:1731", "known name gives the object key")
QN_POS = { 0.65, 0.65 }
Gather(2575, nil, { { item = 2770, n = 2 } })
Check(NodeAt("mine", 0.65, 0.65).res == "o:1731", "known item gives the object key")

-- 3: unknown herb without loot source: item key
QN_POS = { 0.2, 0.2 }
Gather(2366, "Friedensblume", { { item = 2447 } })
Check(NodeAt("herb", 0.2, 0.2).res == "i:2447", "item key without loot source")
GetLootSourceInfo = LootSource

-- 4: later with loot source: the item key is replaced by the object key
QN_POS = { 0.25, 0.25 }
Gather(2366, "Friedensblume", { { item = 2447, source = Obj(1617) } })
Check(NodeAt("herb", 0.2, 0.2).res == "o:1617" and NodeAt("herb", 0.25, 0.25).res == "o:1617",
	"item key upgraded to the object key")
Check(DB.GetResource("i:2447") == nil and DB.GetResource("o:1617").names[LOCALE] == "Friedensblume", "catalog moved")

-- 5: skill error: node by name with the required skill
local function Format(fmt, s, d)
	return (fmt:gsub("%%%d?%$?s", s, 1):gsub("%%%d?%$?d", tostring(d), 1))
end
QN_POS = { 0.7, 0.7 }
FireEvent("UNIT_SPELLCAST_SENT", "player", "Mithrilablagerung", "Cast-2", 2575)
FireEvent("UI_ERROR_MESSAGE", 1, Format(ERR_USE_LOCKED_WITH_SPELL_KNOWN_SI, "Bergbau", 175))
n = NodeAt("mine", 0.7, 0.7)
Check(n and n.res == "n:mine:Mithrilablagerung", "node without skill stored by name")
Check(DB.GetResource("n:mine:Mithrilablagerung").skill == 175, "required skill learned from the error")

-- 6: gathered later: name key upgraded, skill kept
Gather(2575, "Mithrilablagerung", { { item = 3858, source = Obj(2040) } })
n = NodeAt("mine", 0.7, 0.7)
Check(n and n.res == "o:2040" and n.seen == 2, "name key upgraded and merged")
Check(DB.GetResource("o:2040").skill == 175 and DB.GetResource("n:mine:Mithrilablagerung") == nil, "skill moved to the object key")

-- 7: locked chest ("Requires Lockpicking") stores the chest by name
QN_POS = { 0.1, 0.9 }
FireEvent("UNIT_SPELLCAST_SENT", "player", "Ramponierte Truhe", "Cast-3", 3365)
FireEvent("UI_ERROR_MESSAGE", 1, (ERR_USE_LOCKED_WITH_SPELL_S:gsub("%%%d?%$?s", "Schlossknacken", 1)))
Check(NodeAt("treasure", 0.1, 0.9) and NodeAt("treasure", 0.1, 0.9).res == "n:treasure:Ramponierte Truhe", "locked chest stored by name")

-- 8: ignored: other units, other spells, other errors, late errors, loot from items, late loot, no position
local before = DB.CountNodes("mine") + DB.CountNodes("herb")
QN_POS = { 0.9, 0.1 }
Gather(2575, "Kupferader", { { item = 2770, source = Obj(1731) } }, "party1")
Gather(133, "Kupferader", { { item = 2770, source = Obj(1731) } })
FireEvent("UNIT_SPELLCAST_SENT", "player", "Kupferader", "Cast-4", 2575)
FireEvent("UI_ERROR_MESSAGE", 1, "Something else")
SetTime(GetTime() + 3)
FireEvent("UI_ERROR_MESSAGE", 1, Format(ERR_USE_LOCKED_WITH_SPELL_KNOWN_SI, "Bergbau", 1))
QN_LOOT = { { item = 2770, source = Obj(1731) } }
FireEvent("LOOT_OPENED", false, true)
SetTime(GetTime() + 30)
FireEvent("LOOT_OPENED", false, false)
QN_LOOT = {}
QN_POS = nil
Gather(2575, "Kupferader", { { item = 2770, source = Obj(1731) } })
Check(DB.CountNodes("mine") + DB.CountNodes("herb") == before, "nothing stored from ignored events")

-- 9: gas clouds 15 yd ahead (facing north: y smaller)
QN_POS, QN_FACING = { 0.4, 0.4 }, 0
Gather(30427, "Gaswolke", { { item = 22572, source = Obj(181899) } })
local found
for coord, node in DB.Nodes("gas", MAP) do
	local x, y = DB.Decode(coord)
	found = node.res == "o:181899" and math.abs(x - 0.4) < 0.0002 and math.abs(y - 0.385) < 0.0002
end
Check(found, "gas cloud stored 15 yd in front of the player")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
