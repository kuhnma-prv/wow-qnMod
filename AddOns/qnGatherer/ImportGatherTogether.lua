-- qnGatherer: import adapter for the data of GatherTogether (read from its globals while it is
-- loaded; the offline tool loads the same globals from GatherTogether's files). Nothing of it is
-- part of qnGatherer.
--   GatherTogetherGathering.resources[objectID] = { kind = "herb"/"ore", item, skill }   -> catalog "o:<id>"
--   GatherTogetherGathering.areas.ore/herb[map] = { { x, y, rx, ry, fish = { objectID } } } -> reported areas
--   GatherTogetherReportedAreas[map], GatherTogetherFishingAreas[map]  (fish = item IDs) -> reported / school areas
--   GatherTogetherZones { en, minimum, sure, mapID, mapFrom, fishFrom }, GatherTogetherFishData[en] = { item }
--                                                      -> zone skill range and fish list
--   GatherTogetherMapOverlays[artID]["w:h:x:y"] = "file, file"  -> exploration overlays
--   GatherTogetherSkinningBands { low, high, skill, skillHigh, item, zones = { en } }  -> skinning bands
--   GatherTogetherDB.spots[en] (learned areas), .catches[en][item] (catches)

local ADDON, ns = ...

local KIND = { herb = "herb", ore = "mine" }

local function Available()
	return type(GatherTogetherGathering) == "table" or type(GatherTogetherReportedAreas) == "table"
end

local function Version()
	return C_AddOns.GetAddOnMetadata("GatherTogether", "Version")
end

-- English zone name -> uiMapID (zones with their own map)
local function ZoneMaps()
	local maps = {}
	for _, z in ipairs(type(GatherTogetherAllZones) == "table" and GatherTogetherAllZones or GatherTogetherZones or {}) do
		if z.en and z.mapID and not z.mapFrom then
			maps[z.en] = z.mapID
		end
	end
	return maps
end

local function Ids(list, prefix)
	local out = {}
	for _, id in ipairs(list or {}) do
		out[#out + 1] = prefix .. id
	end
	return out
end

local function Areas(emit, kind, byMap, prefix, class)
	for map, list in pairs(byMap or {}) do
		for _, a in ipairs(list) do
			emit({ t = "area", kind = kind, map = map, x = a.x, y = a.y, rx = a.rx, ry = a.ry, class = class,
				res = Ids(a.fish, prefix) })
		end
	end
end

local function Read(emit, kinds)
	local function Wanted(kind)
		return not kinds or kinds[kind]
	end
	local gathering = type(GatherTogetherGathering) == "table" and GatherTogetherGathering or {}

	-- herbs and ore: resources (object IDs) and reported areas
	for id, r in pairs(gathering.resources or {}) do
		local kind = KIND[r.kind]
		if kind and Wanted(kind) then
			emit({ t = "res", res = "o:" .. id, kind = kind, item = r.item, skill = r.skill })
		end
	end
	for gtKind, kind in pairs(KIND) do
		if Wanted(kind) then
			Areas(emit, kind, (gathering.areas or {})[gtKind], "o:", "reported")
		end
	end

	if Wanted("fish") then
		-- fish: catalog, reported areas, school areas
		for id in pairs(type(GatherTogetherFishNames) == "table" and GatherTogetherFishNames or {}) do
			emit({ t = "res", res = "i:" .. id, kind = "fish", item = id })
		end
		Areas(emit, "fish", GatherTogetherReportedAreas, "i:", "reported")
		Areas(emit, "fish", GatherTogetherFishingAreas, "i:", "school")

		-- zones: skill range and fish list (sub-zones without an own map take the list of their parent)
		local fishData = type(GatherTogetherFishData) == "table" and GatherTogetherFishData or {}
		for _, z in ipairs(type(GatherTogetherZones) == "table" and GatherTogetherZones or {}) do
			if z.mapID and not z.mapFrom then
				local fish = fishData[z.en] or (z.fishFrom and fishData[z.fishFrom])
				emit({ t = "zone", kind = "fish", map = z.mapID, min = z.minimum, max = z.sure, res = Ids(fish, "i:") })
			end
		end

		-- own data of GatherTogether: learned areas and catches
		local db = type(GatherTogetherDB) == "table" and GatherTogetherDB or {}
		local maps = ZoneMaps()
		for en, spots in pairs(db.spots or {}) do
			if maps[en] then
				Areas(emit, "fish", { [maps[en]] = spots }, "i:", "learned")
			end
		end
		for en, items in pairs(db.catches or {}) do
			if maps[en] then
				for item, n in pairs(items) do
					emit({ t = "catch", char = "GatherTogether", map = maps[en], item = item, n = n })
				end
			end
		end
	end

	-- exploration overlays (whole zone visible in the journal)
	for art, list in pairs(type(GatherTogetherMapOverlays) == "table" and GatherTogetherMapOverlays or {}) do
		for key, files in pairs(list) do
			local w, h, x, y = key:match("^(%d+):(%d+):(%d+):(%d+)$")
			if w then
				local ids = {}
				for file in tostring(files):gmatch("%d+") do
					ids[#ids + 1] = tonumber(file)
				end
				emit({ t = "overlay", art = art, w = tonumber(w), h = tonumber(h), x = tonumber(x), y = tonumber(y), files = ids })
			end
		end
	end

	-- skinning bands with their suggested zones
	local maps = ZoneMaps()
	for _, b in ipairs(type(GatherTogetherSkinningBands) == "table" and GatherTogetherSkinningBands or {}) do
		local bandMaps = {}
		for _, en in ipairs(b.zones or {}) do
			bandMaps[#bandMaps + 1] = maps[en]
		end
		emit({ t = "skinning", low = b.low, high = b.high, skill = b.skill, skillHigh = b.skillHigh, item = b.item, maps = bandMaps })
	end
end

ns.Import.Register({
	key = "gt",
	name = "GatherTogether",   -- do not translate
	Available = Available,
	Version = Version,
	Read = Read,
})
