-- qnGatherer: data model. Every source (own gathering, guild sync, import adapters, offline tool)
-- hands the same records to DB.Ingest(rec, origin); validation, merging, locks and tombstones
-- happen only here.

local ADDON, ns = ...

local DB = {}
ns.DB = DB

local floor, sqrt, abs, min, max = math.floor, math.sqrt, math.abs, math.min, math.max

---------------------------------------------------------------------------
-- qnGathererDB.global
--   nodes[kind][map][coord]      = "res|first|last|seen|originId"   points
--   areas[kind][map]             = { { x, y, rx, ry, class, o = originId, res = { res, ... } }, ... }
--   zones[kind][map]             = { min, max, o = originId }       skill range of a zone
--   catalog[res]                 = { kind, item, skill, names = { [locale] = name }, rareOf, cond }
--   catches[charKey][map][item]  = count                            fishing loot per character
--   tombstones[kind][map][coord] = time()   deleted locally; blocks sync and import within the radius
--   origins                      = { "own", "guild:Name-Realm", "import:gm2", ... }  index = originId
--   locks[kind]                  = true     database lock: nothing is added, deleted or cleaned up
--   radius[kind]                 = yards    merge radius
--   imports[adapter]             = version  data version of the last import (auto import)
--   sync                         = options of the guild sync
--
-- Resource keys (res), independent of the client language:
--   "o:<objectID>"       game object of the loot source
--   "i:<itemID>"         main product of the node
--   "n:<kind>:<name>"    localized name (last resort)
-- Coordinates: x, y in [0, 1) of the uiMapID; coord = floor(x * 10000) * 10000 + floor(y * 10000).
--
-- Origins: "own", "guild:<Name-Realm>", "import:<adapter>". Own data wins over others:
-- own gathering clears a tombstone and takes over a node found by others.
---------------------------------------------------------------------------

local GLOBAL_DEFAULTS = {
	nodes = {}, areas = {}, zones = {}, catalog = {}, catches = {}, tombstones = {},
	origins = { "own" }, locks = {}, imports = {}, radius = {},
	sync = { enabled = true, showGuild = true, relayGuild = false, shareImports = false, ignore = {} },
}

local AREA_CLASSES = { learned = true, reported = true, school = true }
local LEARNED_MAX = 30              -- learned areas per kind and map
local NEAR_X, NEAR_Y = 0.05, 0.06   -- an area within this distance of another of the same class is merged
local DEFAULT_SIZE = 1000           -- yards of a map without world size (instances)

local g                 -- qnGathererDB.global
local originIndex = {}  -- origin -> originId
local sizes = {}        -- map -> { width, height } in yards
local listeners = {}

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local SCALE = 10000

function DB.Encode(x, y)
	return floor(x * SCALE) * SCALE + floor(y * SCALE)
end

function DB.Decode(coord)
	return floor(coord / SCALE) / SCALE, (coord % SCALE) / SCALE
end

-- t[a][b], created on request
local function Sub(t, a, b, create)
	local ta = t[a]
	if not ta then
		if not create then return nil end
		ta = {}
		t[a] = ta
	end
	local tb = ta[b]
	if not tb and create then
		tb = {}
		ta[b] = tb
	end
	return tb
end

local function MapSize(map)
	local size = sizes[map]
	if not size then
		local w, h = C_Map.GetMapWorldSize(map)
		if not w or w <= 0 or not h or h <= 0 then
			w, h = DEFAULT_SIZE, DEFAULT_SIZE
		end
		size = { w, h }
		sizes[map] = size
	end
	return size[1], size[2]
end

-- Distance in yards between two positions of the same map
function DB.Yards(map, x1, y1, x2, y2)
	local w, h = MapSize(map)
	local dx, dy = (x1 - x2) * w, (y1 - y2) * h
	return sqrt(dx * dx + dy * dy)
end
local Yards = DB.Yards

local function OriginId(origin)
	local id = originIndex[origin]
	if not id then
		id = #g.origins + 1
		g.origins[id] = origin
		originIndex[origin] = id
	end
	return id
end

function DB.OriginName(id)
	return g.origins[id]
end

local function Pack(n)
	return ("%s|%d|%d|%d|%d"):format(n.res, n.first, n.last, n.seen, n.oid)
end

local function Unpack(packed)
	local res, first, last, seen, oid = packed:match("^(.-)|(%d+)|(%d+)|(%d+)|(%d+)$")
	if not res then return nil end
	return { res = res, first = tonumber(first), last = tonumber(last), seen = tonumber(seen), oid = tonumber(oid) }
end

local function Fire(kind, map)
	for _, fn in ipairs(listeners) do
		fn(kind, map)
	end
end

-- fn(kind, map) after every change of the data of a map (map nil: the whole kind)
function DB.OnChange(fn)
	listeners[#listeners + 1] = fn
end

---------------------------------------------------------------------------
-- Validation
---------------------------------------------------------------------------

local RES_PATTERNS = { "^o:%d+$", "^i:%d+$", "^n:%l+:[^|]+$" }

function DB.ValidRes(res)
	if type(res) ~= "string" or #res > 100 then
		return false
	end
	for _, p in ipairs(RES_PATTERNS) do
		if res:find(p) then
			return true
		end
	end
	return false
end
local ValidRes = DB.ValidRes

local function ValidPos(x, y)
	return type(x) == "number" and type(y) == "number" and x >= 0 and x < 1 and y >= 0 and y < 1
end

local function ValidMap(map)
	return type(map) == "number" and map > 0 and map == floor(map)
end

local function PositiveInt(v, fallback)
	v = tonumber(v)
	if not v or v < 1 then return fallback end
	return floor(v)
end

---------------------------------------------------------------------------
-- Options of the data
---------------------------------------------------------------------------

function DB.Radius(kind)
	return g.radius[kind] or ns.KINDS[kind].radius
end

function DB.IsLocked(kind)
	return g.locks[kind] == true
end

function DB.SetLock(kind, on)
	g.locks[kind] = on and true or nil
end

-- Resource of which res is the rare variant (e.g. a rich vein), or nil
local function RareOf(res)
	local entry = g.catalog[res]
	return entry and entry.rareOf
end

---------------------------------------------------------------------------
-- Points
---------------------------------------------------------------------------

-- Tombstone of kind/map within the merge radius around x, y: its coord, or nil
local function Tombstone(kind, map, x, y)
	local stones = Sub(g.tombstones, kind, map)
	if not stones then return nil end
	local r = DB.Radius(kind)
	for coord in pairs(stones) do
		local tx, ty = DB.Decode(coord)
		if Yards(map, x, y, tx, ty) <= r then
			return coord
		end
	end
end

-- Places node n ({ res, first, last, seen, oid }) at x, y into nodes (one map):
--   same resource within the radius   -> merged (seen added up, position weighted by seen)
--   rare variant of n within it       -> n is dropped ("kept")
--   n is the rare variant of a node   -> that node is replaced
-- Returns "added", "merged", "replaced" or "kept".
local function Place(nodes, kind, map, x, y, n)
	local r = DB.Radius(kind)
	local ownId = originIndex.own
	local replaced = false
	for coord, packed in pairs(nodes) do
		local other = Unpack(packed)
		local ox, oy = DB.Decode(coord)
		if other and Yards(map, x, y, ox, oy) <= r then
			if other.res == n.res then
				local total = other.seen + n.seen
				local mx = (ox * other.seen + x * n.seen) / total
				local my = (oy * other.seen + y * n.seen) / total
				other.first = min(other.first, n.first)
				other.last = max(other.last, n.last)
				other.seen = total
				if n.oid == ownId then
					other.oid = ownId
				end
				nodes[coord] = nil
				nodes[DB.Encode(mx, my)] = Pack(other)   -- returns right away: no further traversal
				return "merged"
			elseif RareOf(other.res) == n.res then
				return "kept"
			elseif RareOf(n.res) == other.res then
				nodes[coord] = nil
				replaced = true
			end
		end
	end
	local coord = DB.Encode(x, y)
	-- another resource in the same cell: move by one cell
	for _ = 1, 5 do
		if not nodes[coord] then break end
		coord = coord + 1
	end
	if nodes[coord] then
		return "kept"
	end
	nodes[coord] = Pack(n)
	return replaced and "replaced" or "added"
end

local function IngestNode(rec, origin)
	local kind, map, x, y, res = rec.kind, rec.map, rec.x, rec.y, rec.res
	if not ValidRes(res) or not ValidPos(x, y) then
		return nil, "invalid"
	end
	local own = origin == "own"
	local stone = Tombstone(kind, map, x, y)
	if stone then
		if not own then
			return nil, "tombstone"
		end
		g.tombstones[kind][map][stone] = nil   -- gathered again: no longer deleted
	end
	local now = time()
	local first = PositiveInt(rec.first, now)
	local n = {
		res = res,
		first = first,
		last = max(first, PositiveInt(rec.last, first)),
		seen = PositiveInt(rec.seen, 1),
		oid = OriginId(origin),
	}
	local result = Place(Sub(g.nodes, kind, map, true), kind, map, x, y, n)
	if result ~= "kept" then
		Fire(kind, map)
	end
	return result
end

-- Node at coord: { res, first, last, seen, origin } or nil
function DB.GetNode(kind, map, coord)
	local nodes = Sub(g.nodes, kind, map)
	local n = nodes and nodes[coord] and Unpack(nodes[coord])
	if n then
		n.origin = g.origins[n.oid]
	end
	return n
end

-- Iterator over the nodes of a map: for coord, node in DB.Nodes(kind, map)
function DB.Nodes(kind, map)
	local nodes = Sub(g.nodes, kind, map) or {}
	local coord
	return function()
		local packed
		coord, packed = next(nodes, coord)
		if coord then
			local n = Unpack(packed)
			n.origin = g.origins[n.oid]
			return coord, n
		end
	end
end

function DB.CountNodes(kind, map)
	local count = 0
	local maps = g.nodes[kind]
	if not maps then return 0 end
	for m, nodes in pairs(maps) do
		if not map or m == map then
			for _ in pairs(nodes) do
				count = count + 1
			end
		end
	end
	return count
end

---------------------------------------------------------------------------
-- Areas, zones, catches, catalog
---------------------------------------------------------------------------

local function MergeRes(list, add)
	local have, changed = {}, false
	for _, res in ipairs(list) do
		have[res] = true
	end
	for _, res in ipairs(add) do
		if not have[res] then
			have[res] = true
			list[#list + 1] = res
			changed = true
		end
	end
	table.sort(list)
	return changed
end

local function IngestArea(rec, origin)
	local kind, map, x, y = rec.kind, rec.map, rec.x, rec.y
	local rx, ry, class, resList = rec.rx, rec.ry, rec.class, rec.res
	if not ValidPos(x, y) or type(rx) ~= "number" or type(ry) ~= "number" or rx <= 0 or rx > 1
		or ry <= 0 or ry > 1 or not AREA_CLASSES[class] or type(resList) ~= "table" or #resList == 0 then
		return nil, "invalid"
	end
	for _, res in ipairs(resList) do
		if not ValidRes(res) then
			return nil, "invalid"
		end
	end
	local list = Sub(g.areas, kind, map, true)
	local oid = OriginId(origin)
	local learned = 0
	for _, a in ipairs(list) do
		if a.class == class and abs(a.x - x) <= NEAR_X and abs(a.y - y) <= NEAR_Y then
			local changed = MergeRes(a.res, resList)
			if origin == "own" and a.o ~= oid then
				a.o = oid
				changed = true
			end
			if changed then
				Fire(kind, map)
			end
			return changed and "merged" or "kept"
		end
		if a.class == "learned" then
			learned = learned + 1
		end
	end
	if class == "learned" and learned >= LEARNED_MAX then
		return nil, "full"
	end
	local res = {}
	MergeRes(res, resList)
	list[#list + 1] = { x = x, y = y, rx = rx, ry = ry, class = class, o = oid, res = res }
	Fire(kind, map)
	return "added"
end

local function IngestZone(rec, origin)
	local lo, hi = tonumber(rec.min), tonumber(rec.max)
	if not lo or not hi or lo < 0 or hi < lo or hi > 1000 then
		return nil, "invalid"
	end
	local zones = g.zones[rec.kind] or {}
	g.zones[rec.kind] = zones
	local old = zones[rec.map]
	if old and origin ~= "own" and old.o == originIndex.own then
		return "kept"   -- learned ourselves: imports do not overwrite it
	end
	zones[rec.map] = { min = floor(lo), max = floor(hi), o = OriginId(origin) }
	return old and "merged" or "added"
end

local function IngestCatch(rec)
	local item, n = PositiveInt(rec.item), PositiveInt(rec.n)
	if type(rec.char) ~= "string" or rec.char == "" or not ValidMap(rec.map) or not item or not n then
		return nil, "invalid"
	end
	local items = Sub(g.catches, rec.char, rec.map, true)
	items[item] = (items[item] or 0) + n
	return "added"
end

local function IngestRes(rec, origin)
	local res = rec.res
	if not ValidRes(res) or not ns.KINDS[rec.kind] or (rec.rareOf ~= nil and not ValidRes(rec.rareOf)) then
		return nil, "invalid"
	end
	local entry = g.catalog[res]
	local result = entry and "merged" or "added"
	if not entry then
		entry = { kind = rec.kind, names = {} }
		g.catalog[res] = entry
	end
	local own = origin == "own"
	entry.item = entry.item or PositiveInt(rec.item)
	local skill = tonumber(rec.skill)
	if skill and skill >= 0 and (own or not entry.skill) then
		entry.skill = floor(skill)
	end
	entry.rareOf = entry.rareOf or rec.rareOf
	if type(rec.cond) == "string" then
		entry.cond = entry.cond or rec.cond
	end
	if type(rec.names) == "table" then
		for locale, name in pairs(rec.names) do
			if type(locale) == "string" and type(name) == "string" and (own or not entry.names[locale]) then
				entry.names[locale] = name
			end
		end
	end
	return result
end

---------------------------------------------------------------------------
-- Ingest
---------------------------------------------------------------------------

local INGEST = {
	node = IngestNode,
	area = IngestArea,
	zone = IngestZone,
	catch = IngestCatch,
	res = IngestRes,
}
-- records bound to a kind and a map; points and areas are subject to the database lock
local NEEDS_MAP = { node = true, area = true, zone = true }
local LOCKED = { node = true, area = true }

-- Takes over a record of origin ("own", "guild:<Name-Realm>", "import:<adapter>").
-- Returns "added", "merged", "replaced" or "kept", or nil and the reason
-- ("invalid", "locked", "tombstone", "full").
function DB.Ingest(rec, origin)
	if type(rec) ~= "table" or type(origin) ~= "string" or origin == "" then
		return nil, "invalid"
	end
	local fn = INGEST[rec.t]
	if not fn then
		return nil, "invalid"
	end
	if NEEDS_MAP[rec.t] then
		if not ns.KINDS[rec.kind] or not ValidMap(rec.map) then
			return nil, "invalid"
		end
		if LOCKED[rec.t] and DB.IsLocked(rec.kind) then
			return nil, "locked"
		end
	end
	return fn(rec, origin)
end

function DB.GetAreas(kind, map)
	return Sub(g.areas, kind, map) or {}
end

function DB.GetZone(kind, map)
	return g.zones[kind] and g.zones[kind][map]
end

function DB.GetResource(res)
	return g.catalog[res]
end

function DB.GetCatches(char, map)
	return Sub(g.catches, char, map) or {}
end

---------------------------------------------------------------------------
-- Deleting
-- Single nodes and the nodes of a zone leave tombstones (they do not come back through sync
-- or import). Clearing a whole kind and removing an origin do not: that is a reset.
---------------------------------------------------------------------------

function DB.Delete(kind, map, coord)
	if DB.IsLocked(kind) then return false end
	local nodes = Sub(g.nodes, kind, map)
	if not nodes or not nodes[coord] then return false end
	nodes[coord] = nil
	Sub(g.tombstones, kind, map, true)[coord] = time()
	Fire(kind, map)
	return true
end

-- Deletes all nodes of kind in map; returns their number (0 if locked).
function DB.DeleteZone(kind, map)
	if DB.IsLocked(kind) then return 0 end
	local nodes = Sub(g.nodes, kind, map)
	if not nodes then return 0 end
	local stones, now, count = Sub(g.tombstones, kind, map, true), time(), 0
	for coord in pairs(nodes) do
		stones[coord] = now
		count = count + 1
	end
	g.nodes[kind][map] = nil
	Fire(kind, map)
	return count
end

-- Deletes all nodes and areas of kind; false if locked.
function DB.ClearKind(kind)
	if DB.IsLocked(kind) then return false end
	g.nodes[kind] = nil
	g.areas[kind] = nil
	Fire(kind, nil)
	return true
end

-- Removes nodes and areas whose origin is origin or starts with it ("guild:" = all guild
-- members). Locked kinds stay untouched. Returns the number of removed entries.
function DB.DeleteOrigin(origin)
	local ids = {}
	for id, name in ipairs(g.origins) do
		if name == origin or (origin:sub(-1) == ":" and name:sub(1, #origin) == origin) then
			ids[id] = true
		end
	end
	local count = 0
	for _, kind in ipairs(ns.KIND_ORDER) do
		if not DB.IsLocked(kind) then
			for map, nodes in pairs(g.nodes[kind] or {}) do
				for coord, packed in pairs(nodes) do
					local n = Unpack(packed)
					if n and ids[n.oid] then
						nodes[coord] = nil
						count = count + 1
					end
				end
				Fire(kind, map)
			end
			for map, list in pairs(g.areas[kind] or {}) do
				for i = #list, 1, -1 do
					if ids[list[i].o] then
						table.remove(list, i)
						count = count + 1
					end
				end
				Fire(kind, map)
			end
		end
	end
	return count
end

---------------------------------------------------------------------------
-- Cleanup: merges duplicates within the radius again (after changing the radius or
-- the catalog) and removes unreadable entries. Returns the number of removed nodes.
---------------------------------------------------------------------------

function DB.CleanupMap(kind, map)
	if DB.IsLocked(kind) then return 0 end
	local nodes = Sub(g.nodes, kind, map)
	if not nodes then return 0 end
	local list, before = {}, 0
	for coord, packed in pairs(nodes) do
		before = before + 1
		local n = Unpack(packed)
		if n and ValidRes(n.res) then
			n.x, n.y = DB.Decode(coord)
			n.coord = coord
			list[#list + 1] = n
		end
	end
	-- most seen first, so that merging keeps the well-known positions; coord as tie-breaker
	table.sort(list, function(a, b)
		if a.seen ~= b.seen then return a.seen > b.seen end
		return a.coord < b.coord
	end)
	wipe(nodes)
	for _, n in ipairs(list) do
		Place(nodes, kind, map, n.x, n.y, n)
	end
	local after = 0
	for _ in pairs(nodes) do
		after = after + 1
	end
	if after ~= before then
		Fire(kind, map)
	end
	return before - after
end

function DB.Cleanup(kind)
	local maps = {}
	for map in pairs(g.nodes[kind] or {}) do
		maps[#maps + 1] = map
	end
	local removed = 0
	for _, map in ipairs(maps) do
		removed = removed + DB.CleanupMap(kind, map)
	end
	return removed
end

---------------------------------------------------------------------------
-- Init
---------------------------------------------------------------------------

function DB.Init(global)
	for key, kind in pairs(ns.KINDS) do
		GLOBAL_DEFAULTS.radius[key] = kind.radius
	end
	g = qnCore.MergeDefaults(global, GLOBAL_DEFAULTS)
	wipe(originIndex)
	for id, name in ipairs(g.origins) do
		originIndex[name] = originIndex[name] or id
	end
	OriginId("own")   -- normally originId 1; a damaged list gets it appended (stored ids stay valid)
	DB.global = g
end
