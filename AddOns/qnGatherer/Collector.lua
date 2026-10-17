-- qnGatherer: records gathering nodes. A gathering cast (UNIT_SPELLCAST_SENT, spell of a kind)
-- remembers kind, target name and position; the following loot window gives the resource
-- (game object of the loot source, otherwise the first looted item), a skill error gives the
-- node without loot and the required skill. Fishing is handled in Fishing.lua.

local ADDON, ns = ...
local DB = ns.DB

local C = {}
ns.Collector = C

local BOBBER = 35591        -- game object of the fishing bobber (never a fish school)
local CAST_TIMEOUT = 30     -- seconds from the cast to its loot (a fishing channel lasts up to ~20 s)
local ERROR_WINDOW = 2      -- seconds from the cast to a skill error

-- C.cast = { kind, spell, guid, target, time, map, x, y } of the last gathering cast, or nil
C.cast = nil

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

-- Position of the player: map, x, y or nil (instances without a map position, secret values)
function C.PlayerPosition()
	local map = C_Map.GetBestMapForUnit("player")
	if not map or ns.IsSecret(map) then
		return nil
	end
	local pos = C_Map.GetPlayerMapPosition(map, "player")
	if not pos then
		return nil
	end
	local x, y = pos:GetXY()
	if not x or ns.AnySecret(x, y) or (x == 0 and y == 0) then
		return nil
	end
	return map, x, y
end

-- Position yards in front of the player (fish schools and gas clouds are out of reach);
-- falls back to x, y without a facing or outside the map.
function C.Ahead(map, x, y, yards)
	local facing = GetPlayerFacing()
	if not facing or ns.IsSecret(facing) then
		return x, y
	end
	local w, h = DB.MapSize(map)
	-- facing 0 = north, counterclockwise; map x grows to the east, y to the south
	local nx, ny = x - math.sin(facing) * yards / w, y - math.cos(facing) * yards / h
	if nx < 0 or nx >= 1 or ny < 0 or ny >= 1 then
		return x, y
	end
	return nx, ny
end

-- Object ID of a game object GUID ("GameObject-0-<server>-<instance>-<zone>-<id>-<spawn>"), or nil
function C.ObjectID(guid)
	if type(guid) ~= "string" or ns.IsSecret(guid) then
		return nil
	end
	local unitType, _, _, _, _, id = strsplit("-", guid)
	if unitType ~= "GameObject" then
		return nil
	end
	return tonumber(id)
end

-- Content of the open loot window: { { item, n }, ... } and the object ID of the loot source
-- (nil if unknown). GetLootSourceInfo is not in the documented API: only used if present.
function C.ReadLoot()
	local items, object = {}, nil
	for slot = 1, GetNumLootItems() do
		if GetLootSlotType(slot) == Enum.LootSlotType.Item then
			local link = GetLootSlotLink(slot)
			local id = link and not ns.IsSecret(link) and tonumber(link:match("item:(%d+)"))
			if id then
				local _, _, quantity = GetLootSlotInfo(slot)
				items[#items + 1] = { item = id, n = ns.Plain(quantity, 1) or 1 }
			end
			if not object and GetLootSourceInfo then
				local id2 = C.ObjectID(GetLootSourceInfo(slot))
				if id2 and id2 ~= BOBBER then
					object = id2
				end
			end
		end
	end
	return items, object
end

-- Pattern of a GlobalString with %s/%d (also %1$s), captures in the order of the string
local function Pattern(fmt)
	if type(fmt) ~= "string" then
		return nil
	end
	-- placeholders first, then escape the rest, then the captures
	local p = fmt:gsub("%%%d%$s", "\1"):gsub("%%%d%$d", "\2"):gsub("%%s", "\1"):gsub("%%d", "\2")
	p = p:gsub("[%%%(%)%.%+%-%*%?%[%]%^%$]", "%%%0")
	return "^" .. p:gsub("\1", "(.+)"):gsub("\2", "(%%d+)") .. "$"
end
C.Pattern = Pattern

---------------------------------------------------------------------------
-- Recording
---------------------------------------------------------------------------

-- Resource key of the node: object of the loot source > resource known by name > resource
-- known by its item > first item > name
local function ResourceKey(kind, name, object, items)
	if object then
		return "o:" .. object
	end
	local known = name and DB.FindRes(kind, name, GetLocale())
	if known and known:sub(1, 2) ~= "n:" then
		return known
	end
	if items[1] then
		return DB.FindResByItem(kind, items[1].item) or ("i:" .. items[1].item)
	end
	if name then
		return known or ("n:" .. kind .. ":" .. name)
	end
end

-- Stores the node of cast with resource res; catalog entry with name, item and skill.
function C.Record(cast, res, item, skill)
	if not res or not cast.map then
		return
	end
	local x, y = cast.x, cast.y
	if cast.kind == "fish" or cast.kind == "gas" then
		x, y = C.Ahead(cast.map, x, y, 15)
	end
	local names = cast.target and { [GetLocale()] = cast.target } or nil
	DB.Ingest({ t = "res", res = res, kind = cast.kind, item = item, skill = skill, names = names }, "own")
	-- the node was known by its name only: from now on by its object or item
	if cast.target and res:sub(1, 2) ~= "n:" then
		local nameRes = "n:" .. cast.kind .. ":" .. cast.target
		if DB.GetResource(nameRes) then
			DB.ReplaceRes(cast.kind, nameRes, res)
		end
	end
	-- known by its item only so far: from now on by its object (not for fishing: there the item
	-- keys stand for the fish of the areas, the object for the school)
	if item and cast.kind ~= "fish" and res:sub(1, 2) == "o:" then
		local itemRes = "i:" .. item
		local entry = DB.GetResource(itemRes)
		if entry and entry.kind == cast.kind then
			DB.ReplaceRes(cast.kind, itemRes, res)
		end
	end
	DB.Ingest({ t = "node", kind = cast.kind, map = cast.map, x = x, y = y, res = res }, "own")
end

-- Loot of a gathering cast (not fishing): the node and its resource
function C.OnLoot(cast)
	local items, object = C.ReadLoot()
	local res = ResourceKey(cast.kind, cast.target, object, items)
	C.Record(cast, res, items[1] and items[1].item)
end

-- Skill or lock error right after a gathering cast: node by name, required skill if given
function C.OnError(cast, message)
	local skill
	local _, value = message:match(Pattern(ERR_USE_LOCKED_WITH_SPELL_KNOWN_SI) or "^$")
	if value then
		skill = tonumber(value)
	elseif not message:match(Pattern(ERR_USE_LOCKED_WITH_SPELL_S) or "^$") then
		return false
	end
	if not cast.target then
		return false
	end
	local res = DB.FindRes(cast.kind, cast.target, GetLocale()) or ("n:" .. cast.kind .. ":" .. cast.target)
	C.Record(cast, res, nil, skill)
	return true
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

ns.events.Register("UNIT_SPELLCAST_SENT", function(_, unit, target, castGUID, spellID)
	if unit ~= "player" or ns.AnySecret(spellID) then
		return
	end
	local kind = ns.KindForSpell(spellID)
	if not kind then
		return
	end
	local map, x, y = C.PlayerPosition()
	target = ns.Plain(target)
	C.cast = {
		kind = kind, spell = spellID, guid = ns.Plain(castGUID), time = GetTime(),
		target = target ~= "" and target or nil, map = map, x = x, y = y,
	}
	if kind == "fish" then
		ns.Fishing.OnCast(C.cast)
	end
end)

ns.events.Register("UI_ERROR_MESSAGE", function(_, _, message)
	local cast = C.cast
	if not cast or cast.kind == "fish" or type(message) ~= "string" or ns.IsSecret(message)
		or GetTime() - cast.time > ERROR_WINDOW then
		return
	end
	if C.OnError(cast, message) then
		C.cast = nil
	end
end)

ns.events.Register("LOOT_OPENED", function(_, _, isFromItem)
	local cast = C.cast
	if ns.Plain(isFromItem) or not cast or GetTime() - cast.time > CAST_TIMEOUT then
		return
	end
	C.cast = nil   -- one loot per cast
	if cast.kind == "fish" then
		ns.Fishing.OnLoot(cast)
	else
		C.OnLoot(cast)
	end
end)
