-- Scenario 11: qnGatherer - import from GatherTogether: catalog, areas (not merged by distance),
-- zone ranges and fish lists, own spots and catches, overlays, skinning, modes, kinds, lock,
-- auto import, journal use
C_Map.GetMapWorldSize = function() return 2000, 1000 end
C_Map.GetBestMapForUnit = function() return 1429 end
QN_MAPINFO = { [1429] = { name = "Elwynn" } }
local gtVersion = "0.5.1"
C_AddOns.GetAddOnMetadata = function(a, f) if a == "GatherTogether" and f == "Version" then return gtVersion end return "test" end

GatherTogetherGathering = {
	resources = { [1618] = { kind = "herb", item = 2447, skill = 1, en = "peacebloom" }, [1731] = { kind = "ore", item = 2770, skill = 1 } },
	areas = {
		herb = { [1429] = { { x = 0.4, y = 0.4, rx = 0.08, ry = 0.1, fish = { 1618 }, reported = true },
			{ x = 0.43, y = 0.42, rx = 0.06, ry = 0.06, fish = { 1618 }, reported = true } } },
		ore = { [1429] = { { x = 0.5, y = 0.5, rx = 0.1, ry = 0.1, fish = { 1731 }, reported = true } } },
	},
}
GatherTogetherFishNames = { [6291] = "Raw Brilliant Smallfish", [6289] = "Raw Longjaw Mud Snapper" }
GatherTogetherReportedAreas = { [1429] = { { x = 0.3, y = 0.3, rx = 0.055, ry = 0.08, fish = { 6291 }, reported = true } } }
GatherTogetherFishingAreas = { [1429] = { { x = 0.2, y = 0.2, rx = 0.065, ry = 0.08, fish = { 6289 } } } }
GatherTogetherZones = {
	{ en = "Elwynn Forest", minimum = 1, sure = 25, mapID = 1429 },
	{ en = "The Deadmines", minimum = 1, sure = 75, mapID = 1436, mapFrom = "Westfall" },
}
GatherTogetherAllZones = { GatherTogetherZones[1], GatherTogetherZones[2], { en = "Westfall", mapID = 1436 } }
GatherTogetherFishData = { ["Elwynn Forest"] = { 6291, 6289 } }
GatherTogetherMapOverlays = { [1429] = { ["445:160:244:0"] = "271435, 271442", ["bad"] = "1" } }
GatherTogetherSkinningBands = { { low = 1, high = 10, skill = 1, skillHigh = 1, item = 2318, zones = { "Elwynn Forest", "Mulgore" } } }
GatherTogetherDB = {
	spots = { ["Elwynn Forest"] = { { x = 0.6, y = 0.6, rx = 0.055, ry = 0.075, fish = { 6291 }, learned = true } } },
	catches = { ["Elwynn Forest"] = { [6291] = 7 } },
}

LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local DB, I, J = gt.DB, gt.Import, gt.Journal
local MAP = 1429

Check(I.Get("gt") and I.Get("gm2"), "adapters registered")
local available = I.Available()
Check(#available == 1 and available[1].key == "gt", "GatherTogether available, GatherMate2 not")
Check(gt.builders.importOptions ~= nil, "import page built")

local counts = I.Run("gt", { quiet = true })
Check(counts and counts.added > 0 and counts.rejected == 0, "imported without rejected records")
local herb, ore = DB.GetResource("o:1618"), DB.GetResource("o:1731")
Check(herb and herb.kind == "herb" and herb.item == 2447 and herb.skill == 1 and ore.kind == "mine", "catalog with object keys, kind ore -> mine")
local herbAreas = DB.GetAreas("herb", MAP)
Check(#herbAreas == 2 and herbAreas[1].class == "reported" and herbAreas[1].res[1] == "o:1618", "reported areas kept apart")
Check(DB.OriginName(herbAreas[1].o) == "import:gt", "origin import:gt")
Check(#DB.GetAreas("mine", MAP) == 1, "ore areas")
local classes = {}
for _, a in ipairs(DB.GetAreas("fish", MAP)) do classes[a.class] = (classes[a.class] or 0) + 1 end
Check(classes.reported == 1 and classes.school == 1 and classes.learned == 1, "fish areas: reported, school, learned spot")
local zone = DB.GetZone("fish", MAP)
Check(zone and zone.min == 1 and zone.max == 25 and zone.res[1] == "i:6289" and zone.res[2] == "i:6291", "zone: skill range and fish list")
Check(DB.GetZone("fish", 1436) == nil, "sub-zone with a parent map not imported as zone")
Check(DB.GetCatches("GatherTogether", MAP)[6291] == 7, "catches of GatherTogether")
local fish
for _, e in ipairs(DB.ZoneResources("fish", MAP, gt.CharKey())) do
	if e.res == "i:6291" then fish = e end
end
Check(fish and fish.catches == 0 and fish.catchesAll == 7 and fish.listed, "zone resources: listed, catches of all characters")
local overlays = DB.GetOverlays(MAP)
Check(#overlays == 1 and overlays[1].textureWidth == 445 and overlays[1].offsetX == 244 and overlays[1].fileDataIDs[2] == 271442, "overlay imported")
Check(#J.ExtraOverlays(MAP) == 1, "journal uses the overlays")
local band = DB.GetSkinning()[1]
Check(band and band.item == 2318 and #band.maps == 1 and band.maps[1] == MAP, "skinning band with known zones")
Check(qnGathererDB.global.imports.gt == "0.5.1", "data version remembered")

-- journal: skinning view
local zones = J.Zones("skinning", "")
Check(#zones == 1 and zones[1].map == MAP, "skinning zones")
local rows = J.Resources("skinning", MAP)
Check(#rows == 1 and rows[1].name == gt.L["Level %d – %d"]:format(1, 10) and rows[1].item == 2318, "skinning rows")

-- again: nothing new; replace mode removes and imports again
counts = I.Run("gt", { quiet = true })
Check(counts.added == 0, "second import: nothing new")
I.Run("gt", { mode = "replace", quiet = true })
Check(#DB.GetAreas("herb", MAP) == 2 and #DB.GetOverlays(MAP) == 1 and #DB.GetSkinning() == 1, "replace mode")

-- kinds and lock
DB.DeleteOrigin("import:gt")
Check(#DB.GetAreas("herb", MAP) == 0 and #DB.GetOverlays(MAP) == 0 and #DB.GetSkinning() == 0 and DB.GetZone("fish", MAP) == nil,
	"removing the origin removes areas, overlays, skinning and zones")
I.Run("gt", { kinds = { mine = true }, quiet = true })
Check(#DB.GetAreas("herb", MAP) == 0 and #DB.GetAreas("mine", MAP) == 1, "only the chosen kinds")
DB.SetLock("herb", true)
counts = I.Run("gt", { quiet = true })
Check(counts.reasons.locked == 2 and #DB.GetAreas("herb", MAP) == 0, "locked kind: rejected")
DB.SetLock("herb", false)

-- auto import when the version rises
qnGathererDB.global.importOptions.auto = true
gtVersion = "0.6.0"
I.AutoImport()
Check(qnGathererDB.global.imports.gt == "0.6.0" and #DB.GetAreas("herb", MAP) == 2, "auto import on a new version")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
