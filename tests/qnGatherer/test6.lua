-- Scenario 6: qnGatherer - fishing: catches per character, learned areas, fish schools, sound boost
C_Map.GetMapWorldSize = function() return 2000, 1000 end   -- 0.001 x = 2 yd
C_Map.GetBestMapForUnit = function() return 1429 end
QN_ITEMCLASS = { [6291] = { 7, 8 }, [6303] = { 7, 8 }, [118] = { 0, 1 } }
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
local DB = gt.DB
local MAP = 1429
local CHAR = gt.CharKey()
C_CVar._v.Sound_EnableSFX, C_CVar._v.Sound_SFXVolume = "0", "0.3"

local function Fish(loot, delay)
	FireEvent("UNIT_SPELLCAST_SENT", "player", "", "Cast-F", 7620)
	FireEvent("UNIT_SPELLCAST_CHANNEL_START", "player", "Cast-F", 7620)
	FireEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player", "Cast-F", 7620)
	if delay then SetTime(GetTime() + delay) end
	QN_LOOT = loot
	FireEvent("LOOT_OPENED", false, false)
	QN_LOOT = {}
end

-- catches and learned areas
QN_POS = { 0.3, 0.3 }
Fish({ { item = 6291, n = 1 }, { item = 118, n = 1 } })
local catches = DB.GetCatches(CHAR, MAP)
Check(catches[6291] == 1 and catches[118] == 1, "every looted item counted")
local areas = DB.GetAreas("fish", MAP)
Check(#areas == 1 and areas[1].class == "learned" and #areas[1].res == 1 and areas[1].res[1] == "i:6291",
	"learned area only with fish")
Check(areas[1].x == 0.3 and areas[1].rx == 0.055 and areas[1].ry == 0.075, "area around the cast position")
Check(DB.GetResource("i:6291").kind == "fish", "fish in the catalog")
Check(DB.CountNodes("fish") == 0, "no school without a loot source")

QN_POS = { 0.32, 0.33 }
Fish({ { item = 6303, n = 2 } })
areas = DB.GetAreas("fish", MAP)
Check(#areas == 1 and areas[1].res[1] == "i:6291" and areas[1].res[2] == "i:6303", "near cast merged into the area")
Check(DB.GetCatches(CHAR, MAP)[6303] == 2, "stack counted")

Fish({ { item = 6303, n = 1 } }, 6)
Check(DB.GetCatches(CHAR, MAP)[6303] == 2, "loot more than 5 s after the channel ignored")

-- fish schools: loot source = school, stored 15 yd ahead; the bobber is not a school
QN_POS, QN_FACING = { 0.3, 0.3 }, math.pi / 2   -- facing west
Fish({ { item = 6291, n = 1, source = "GameObject-0-1-2-3-180582-0" } })
local school
for coord, node in DB.Nodes("fish", MAP) do
	local x, y = DB.Decode(coord)
	school = node.res == "o:180582" and math.abs(x - 0.2925) < 0.0002 and math.abs(y - 0.3) < 0.0002
end
Check(school, "fish school stored 15 yd in front of the player")
Check(DB.GetResource("o:180582").item == 6291, "school catalog with its fish")
Check(DB.GetResource("i:6291") ~= nil and #DB.GetAreas("fish", MAP)[1].res == 2, "fish keys of the areas stay")
Fish({ { item = 6291, n = 1, source = "GameObject-0-1-2-3-35591-0" } })
Check(DB.CountNodes("fish") == 1, "bobber is no school")

-- sound boost: opt-in
Check(gt.db.soundBoost == false, "sound boost off by default")
FireEvent("UNIT_SPELLCAST_SENT", "player", "", "Cast-F", 7620)
Check(C_CVar._v.Sound_SFXVolume == "0.3", "off: volume unchanged")
FireEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player", "Cast-F", 7620)
gt.db.soundBoost = true
FireEvent("UNIT_SPELLCAST_SENT", "player", "", "Cast-F", 7620)
Check(C_CVar._v.Sound_EnableSFX == "1" and C_CVar._v.Sound_SFXVolume == "1", "on: sound raised while fishing")
Check(DB.global.soundRestore and DB.global.soundRestore.Sound_SFXVolume == "0.3", "previous values kept")
FireEvent("UNIT_SPELLCAST_SENT", "player", "", "Cast-F", 7620)
Check(DB.global.soundRestore.Sound_SFXVolume == "0.3", "second cast keeps the original values")
FireEvent("UNIT_SPELLCAST_CHANNEL_STOP", "player", "Cast-F", 7620)
Check(C_CVar._v.Sound_EnableSFX == "0" and C_CVar._v.Sound_SFXVolume == "0.3" and DB.global.soundRestore == nil,
	"values restored at the end of the cast")
FireEvent("UNIT_SPELLCAST_SENT", "player", "", "Cast-F", 7620)
FireEvent("UNIT_SPELLCAST_INTERRUPTED", "player", "Cast-F", 7620)
Check(C_CVar._v.Sound_SFXVolume == "0.3", "restored after an interrupted cast")
FireEvent("UNIT_SPELLCAST_SENT", "player", "", "Cast-F", 7620)
FireEvent("PLAYER_LOGOUT")
Check(C_CVar._v.Sound_SFXVolume == "0.3" and DB.global.soundRestore == nil, "restored on logout")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
