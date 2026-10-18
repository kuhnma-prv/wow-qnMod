-- qnGatherer: import and export. Import adapters translate the data of other addons into records
-- for DB.Ingest (origin "import:<key>"); the adapters live in Import<Addon>.lua. The offline tool
-- (tools\Convert-QnGatherer.ps1) writes records into qnGathererDB.global.pendingImport; they are taken
-- over on the next load. Export: own nodes and areas as text that another qnGatherer imports again.
--
-- Adapter:
--   ns.Import.Register{
--     key = "gm2", name = "GatherMate2",
--     Available = function() return <data present> end,
--     Version = function() return <data version or nil> end,   -- auto import when it rises
--     Read = function(emit, kinds) ... emit(rec) ... end,       -- kinds = { [kind] = true } or nil = all
--   }

local ADDON, ns = ...
local L = ns.L
local DB, D = ns.DB, ns.Display

local Import = {}
ns.Import = Import

Import.adapters = {}   -- in registration order
local byKey = {}

function Import.Register(adapter)
	assert(type(adapter.key) == "string" and type(adapter.Read) == "function", "qnGatherer: invalid import adapter")   -- do not translate
	if not byKey[adapter.key] then
		Import.adapters[#Import.adapters + 1] = adapter
	end
	byKey[adapter.key] = adapter
end

function Import.Get(key)
	return byKey[key]
end

-- Adapters whose data is present
function Import.Available()
	local list = {}
	for _, a in ipairs(Import.adapters) do
		if a.Available() then
			list[#list + 1] = a
		end
	end
	return list
end

-- Takes over records; counts { added, merged, kept, rejected } and the reasons of the rejected ones
local function IngestAll(records, origin, kinds)
	local counts = { added = 0, merged = 0, kept = 0, rejected = 0, reasons = {} }
	for _, rec in ipairs(records) do
		if not (kinds and rec.kind and not kinds[rec.kind]) then
			local result, why = DB.Ingest(rec, origin)
			if result == "added" or result == "replaced" then
				counts.added = counts.added + 1
			elseif result == "merged" then
				counts.merged = counts.merged + 1
			elseif result == "kept" then
				counts.kept = counts.kept + 1
			else
				counts.rejected = counts.rejected + 1
				counts.reasons[why or "?"] = (counts.reasons[why or "?"] or 0) + 1
			end
		end
	end
	return counts
end
Import.IngestAll = IngestAll

local function Report(name, counts)
	ns.Print(L["Import from %s: %d new, %d merged, %d already known, %d rejected."]:format(name,
		counts.added, counts.merged, counts.kept, counts.rejected))
end

-- Imports adapter key. opts.mode = "merge" (default) or "replace" (first removes everything of
-- this origin), opts.kinds = { [kind] = true } (nil = all), opts.quiet = no chat message.
-- Returns the counts or nil if the adapter has no data.
function Import.Run(key, opts)
	opts = opts or {}
	local adapter = byKey[key]
	if not adapter or not adapter.Available() then
		return nil
	end
	local origin = "import:" .. key
	if opts.mode == "replace" then
		DB.DeleteOrigin(origin)
	end
	local records = {}
	adapter.Read(function(rec) records[#records + 1] = rec end, opts.kinds)
	local counts = IngestAll(records, origin, opts.kinds)
	DB.global.imports[key] = adapter.Version and adapter.Version() or DB.global.imports[key]
	if not opts.quiet then
		Report(adapter.name, counts)
	end
	D.Refresh()
	return counts
end

-- Auto import: adapters whose data version rose since the last import
function Import.AutoImport()
	if not DB.global.importOptions.auto then
		return
	end
	for _, a in ipairs(Import.Available()) do
		local version = a.Version and a.Version()
		if version and version ~= DB.global.imports[a.key] then
			Import.Run(a.key)
		end
	end
end

-- Records of the offline tool (qnGathererDB.global.pendingImport)
function Import.TakePending()
	local pending = DB.global.pendingImport
	if type(pending) ~= "table" then
		DB.global.pendingImport = nil
		return
	end
	DB.global.pendingImport = nil
	for _, p in ipairs(pending) do
		if type(p) == "table" and type(p.adapter) == "string" and type(p.records) == "table" then
			local counts = IngestAll(p.records, "import:" .. p.adapter)
			DB.global.imports[p.adapter] = p.version or DB.global.imports[p.adapter]
			Report(ns.IMPORT_NAMES[p.adapter] or p.adapter, counts)
		end
	end
	D.Refresh()
end

---------------------------------------------------------------------------
-- Export / import as text
-- Line format (version 1), one record per line:
--   QNG|1                                         header
--   N|kind|map|coord|res|first|last|seen          node
--   A|kind|map|x|y|rx|ry|class|res,res,...        area
--   R|res|kind|item|skill|rareOf                  catalog entry (names are not exported)
-- Only own data (origin "own"); imports and guild nodes stay with their origin.
---------------------------------------------------------------------------

local HEADER = "QNG|1"

function Import.Export()
	local lines, used = { HEADER }, {}
	local ownId = 1
	for id, name in ipairs(DB.global.origins) do
		if name == "own" then ownId = id end
	end
	for _, kind in ipairs(ns.KIND_ORDER) do
		for map, nodes in pairs(DB.global.nodes[kind] or {}) do
			for coord in pairs(nodes) do
				local n = DB.GetNode(kind, map, coord)
				if n and n.origin == "own" then
					lines[#lines + 1] = ("N|%s|%d|%d|%s|%d|%d|%d"):format(kind, map, coord, n.res, n.first, n.last, n.seen)
					used[n.res] = true
				end
			end
		end
		for map, list in pairs(DB.global.areas[kind] or {}) do
			for _, a in ipairs(list) do
				if a.o == ownId then
					lines[#lines + 1] = ("A|%s|%d|%.4f|%.4f|%.4f|%.4f|%s|%s"):format(kind, map, a.x, a.y, a.rx, a.ry, a.class, table.concat(a.res, ","))
					for _, res in ipairs(a.res) do used[res] = true end
				end
			end
		end
	end
	for res in pairs(used) do
		local e = DB.GetResource(res)
		if e then
			lines[#lines + 1] = ("R|%s|%s|%s|%s|%s"):format(res, e.kind, e.item or "", e.skill or "", e.rareOf or "")
		end
	end
	return table.concat(lines, "\n")
end

local function Split(s, sep)
	local out = {}
	for part in (s .. sep):gmatch("(.-)" .. sep:gsub("%p", "%%%0")) do
		out[#out + 1] = part
	end
	return out
end

-- Records of an export text; nil and the reason if it is not one
function Import.ParseText(text)
	if type(text) ~= "string" then
		return nil, "invalid"
	end
	local records, first = {}, true
	for line in text:gmatch("[^\r\n]+") do
		line = strtrim(line)
		if first then
			if line ~= HEADER then
				return nil, "header"
			end
			first = false
		elseif line ~= "" then
			local f = Split(line, "|")
			if f[1] == "N" and #f >= 8 then
				local x, y = DB.Decode(tonumber(f[4]) or -1)
				records[#records + 1] = { t = "node", kind = f[2], map = tonumber(f[3]), x = x, y = y, res = f[5],
					first = tonumber(f[6]), last = tonumber(f[7]), seen = tonumber(f[8]) }
			elseif f[1] == "A" and #f >= 9 then
				records[#records + 1] = { t = "area", kind = f[2], map = tonumber(f[3]), x = tonumber(f[4]), y = tonumber(f[5]),
					rx = tonumber(f[6]), ry = tonumber(f[7]), class = f[8], res = Split(f[9], ",") }
			elseif f[1] == "R" and #f >= 3 then
				records[#records + 1] = { t = "res", res = f[2], kind = f[3], item = tonumber(f[4] or ""),
					skill = tonumber(f[5] or ""), rareOf = (f[6] and f[6] ~= "") and f[6] or nil }
			end
		end
	end
	if first then
		return nil, "header"
	end
	-- catalog entries first, so that rare variants are known when the nodes arrive
	table.sort(records, function(a, b) return (a.t == "res" and 0 or 1) < (b.t == "res" and 0 or 1) end)
	return records
end

-- Imports an export text (origin "import:text"); returns the counts or nil and the reason
function Import.FromText(text)
	local records, why = Import.ParseText(text)
	if not records then
		ns.Print(L["This is not a qnGatherer export."])
		return nil, why
	end
	local counts = IngestAll(records, "import:text")
	Report(L["text"], counts)
	D.Refresh()
	return counts
end

function Import.Init()
	ns.IMPORT_NAMES.text = L["text"]
	Import.TakePending()
	Import.AutoImport()
end
