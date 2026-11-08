-- qnGatherer: import adapter for the databases of GatherMate2 (read from its saved variables while
-- it is loaded; the offline tool loads them from the WTF folder). Nothing of it is part of qnGatherer.
--   GatherMate2HerbDB/MineDB/FishDB/TreasureDB/GasDB/ArchaeologyDB/LoggingDB[uiMapID][coord] = nodeID
--   coord = floor(x * 10000 + 0.5) * 1000000 + floor(y * 10000 + 0.5) * 100
-- GatherMate2's node IDs are its own; the resource is found by the node name in the client language
-- (GatherMate2:GetNameForNode, or the table QNGATHERER_GM2_NAMES[type][nodeID] of the offline tool)
-- and matched against the catalog. Unknown names become name keys ("n:<kind>:<name>"), which own
-- gathering later upgrades to object keys.

local ADDON, ns = ...
local DB = ns.DB

-- kind -> saved variable and GatherMate2's node type
local SOURCES = {
	herb = { "GatherMate2HerbDB", "Herb Gathering" },
	mine = { "GatherMate2MineDB", "Mining" },
	fish = { "GatherMate2FishDB", "Fishing" },
	treasure = { "GatherMate2TreasureDB", "Treasure" },
	gas = { "GatherMate2GasDB", "Extract Gas" },
	archaeology = { "GatherMate2ArchaeologyDB", "Archaeology" },
	logging = { "GatherMate2LoggingDB", "Logging" },
}

local function Available()
	for _, s in pairs(SOURCES) do
		if type(_G[s[1]]) == "table" and next(_G[s[1]]) ~= nil then
			return true
		end
	end
	return false
end

local function Version()
	return C_AddOns.GetAddOnMetadata("GatherMate2", "Version")
end

function ns.DecodeGatherMate2(coord)
	return math.floor(coord / 1000000) / 10000, math.floor(coord % 1000000 / 100) / 10000
end

-- Name of a GatherMate2 node in the client language, or nil
local function NodeName(nodeType, id)
	local names = _G.QNGATHERER_GM2_NAMES   -- offline tool (do not translate)
	if type(names) == "table" and names[nodeType] then
		return names[nodeType][id]
	end
	local gm = _G.GatherMate2
	if type(gm) == "table" and type(gm.GetNameForNode) == "function" then
		return gm:GetNameForNode(nodeType, id)
	end
end

local function Read(emit, kinds)
	local locale = GetLocale()
	for kind, s in pairs(SOURCES) do
		local data = _G[s[1]]
		if type(data) == "table" and (not kinds or kinds[kind]) then
			local resOf = {}
			for map, nodes in pairs(data) do
				if type(nodes) == "table" then
					for coord, id in pairs(nodes) do
						local res = resOf[id]
						if not res then
							local name = NodeName(s[2], id)
							if name then
								res = DB.FindRes(kind, name, locale) or ("n:" .. kind .. ":" .. name)
								if res:sub(1, 2) == "n:" then
									emit({ t = "res", res = res, kind = kind, names = { [locale] = name } })
								end
							else
								res = "n:" .. kind .. ":#" .. tostring(id)   -- name unknown: GatherMate2's ID
							end
							resOf[id] = res
						end
						local x, y = ns.DecodeGatherMate2(tonumber(coord) or 0)
						emit({ t = "node", kind = kind, map = tonumber(map), x = x, y = y, res = res })
					end
				end
			end
		end
	end
end

ns.Import.Register({
	key = "gm2",
	name = "GatherMate2",   -- do not translate
	Available = Available,
	Version = Version,
	Read = Read,
})
