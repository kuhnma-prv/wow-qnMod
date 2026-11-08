-- qnGatherer: exchange of nodes with the guild (opt-out, qnGathererDB.global.sync.enabled).
-- Addon messages with the prefix "qnGather", fields separated by "~", at most 250 bytes:
--   H~1~<total>                       GUILD   hello with the digest of all shared nodes
--   L~1                               WHISPER request for the list of map digests (to a peer)
--   M~1~kind,map,digest;...           WHISPER map digests (in parts), then
--   ME~1~<total>                      WHISPER end of the list
--   R~1~kind~map                      WHISPER request for the nodes of a map
--   D~1~kind~map~coord,res;...        WHISPER nodes of a map (in parts), then
--   DE~1~kind~map~digest              WHISPER end of the map
--   B~1~kind~map~coord,res;...        GUILD   new own nodes (sent every few seconds)
-- Shared are own nodes; nodes found by the guild only with relayGuild, imported ones only with
-- shareImports. Nothing is deleted through the exchange; tombstones of the receiver block deleted
-- nodes. Whisper requests are only answered for members whose hello came through the guild channel.
-- Every map digest received from a member is remembered (sync.seen), so a map is only requested
-- again after it changed there. Own throttle (no ChatThrottleLib), paused in combat and while the
-- game blocks chat messages; per member at most MAX_RECORDS nodes per hour. A request of a member is
-- answered only once while the answer is still queued, and not at all while MAX_QUEUE messages wait.

local ADDON, ns = ...
local L = ns.L
local DB = ns.DB

local Sync = {}
ns.Sync = Sync

local PREFIX = "qnGather"   -- do not translate
local VERSION = "1"
local SEP = "~"
local MAX_LEN = 250
local SEND_INTERVAL = 0.3    -- seconds between two messages
local HELLO_DELAY = 60       -- seconds after login (plus up to HELLO_JITTER)
local HELLO_JITTER = 30
local HELLO_REPEAT = 900     -- hello again after this long if the own data changed
local LIVE_DELAY = 5         -- new own nodes are collected this long, then sent together
local MAX_RECORDS = 5000     -- nodes per member and hour
local BACKOFF = 5            -- ticks without sending after the server throttled
local REQUEST_TIMEOUT = 120  -- seconds after which an unanswered exchange may start again
local ANNOUNCE_DELAY = 3     -- seconds in which received nodes are collected for one chat line
local MAX_QUEUE = 2000       -- requests of members are not answered while this many messages wait

local queue = {}
local answering = {}         -- ["sender\trequest"] = true while the answer is queued
local backoff = 0
local peers = {}             -- [sender] = time of the last hello
local outstanding = {}       -- [sender] = { maps = count, total = digest }
local received = {}          -- [sender] = { start, count } rate limit
local live = {}              -- ["kind,map"] = { "coord,res", ... }
local digests                -- cache: { maps = { ["kind,map"] = digest }, total = digest }
local helloSent              -- digest and time of the last hello
Sync.stats = { sent = 0, received = 0, rejected = 0 }
Sync.maxRecords = MAX_RECORDS
Sync.queue = queue
Sync.peers = peers

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

local Split = ns.Split

-- own name as in CHAT_MSG_ADDON ("Name-Realm")
local function Self()
	return UnitName("player") .. "-" .. GetNormalizedRealmName()
end

function Sync.Enabled()
	return DB.global.sync.enabled and IsInGuild()
end

-- Is a node of origin shared with the guild?
function Sync.Shareable(origin)
	if origin == "own" then
		return true
	end
	local opts = DB.global.sync
	if origin:sub(1, 6) == "guild:" then
		return opts.relayGuild
	elseif origin:sub(1, 7) == "import:" then
		return opts.shareImports
	end
	return false
end

local function Ignored(sender)
	local name = sender:lower()
	for _, entry in ipairs(DB.global.sync.ignore) do
		local e = entry:lower()
		if e == name or e == (Ambiguate(sender, "none") or ""):lower() then
			return true
		end
	end
	return false
end

-- "coord,res" or nil if res cannot be sent (separators in the name)
local function Entry(coord, res)
	if res:find("[~;,]") then
		return nil
	end
	return coord .. "," .. res
end

-- 32-bit hash (djb2) of a list of strings (floats: no 32-bit integer overflow)
function Sync.Hash(list)
	local h = 5381.0
	for _, s in ipairs(list) do
		for i = 1, #s do
			h = (h * 33 + s:byte(i)) % 4294967296.0
		end
		h = (h * 33 + 59) % 4294967296.0   -- ";" between entries
	end
	return ("%04x%04x"):format(math.floor(h / 65536), h % 65536)   -- halves: also with 32-bit integers
end

-- Digests of the shared nodes per "kind,map" and over all maps (cached until the next data change)
function Sync.Digests()
	if digests then
		return digests
	end
	local maps, keys = {}, {}
	for _, kind in ipairs(ns.KIND_ORDER) do
		for map in pairs(DB.global.nodes[kind] or {}) do
			local list = {}
			for coord, n in DB.Nodes(kind, map) do
				if Sync.Shareable(n.origin) then
					list[#list + 1] = Entry(coord, n.res)
				end
			end
			if #list > 0 then
				table.sort(list)
				local key = kind .. "," .. map
				maps[key] = Sync.Hash(list)
				keys[#keys + 1] = key .. "," .. maps[key]
			end
		end
	end
	table.sort(keys)
	digests = { maps = maps, total = Sync.Hash(keys) }
	return digests
end

local function Seen(sender)
	local seen = DB.global.sync.seen
	local s = seen[sender]
	if not s then
		s = { maps = {} }
		seen[sender] = s
	end
	return s
end

---------------------------------------------------------------------------
-- Sending: queue with own throttle
---------------------------------------------------------------------------

-- answer = key of the request whose answer ends with this message (see Answer)
function Sync.Send(text, channel, target, answer)
	queue[#queue + 1] = { text, channel, target, answer }
end

-- Key for answering request of sender, nil if that answer is already queued or the queue is full
local function Answer(sender, request)
	local key = sender .. "\t" .. request
	if answering[key] or #queue >= MAX_QUEUE then
		return nil
	end
	answering[key] = true
	return key
end

-- Sends items (strings) in as few messages as possible: head .. SEP .. item;item;...
function Sync.SendList(head, items, channel, target)
	local part = {}
	local size = #head + 1
	for _, item in ipairs(items) do
		if size + #item + 1 > MAX_LEN and #part > 0 then
			Sync.Send(head .. SEP .. table.concat(part, ";"), channel, target)
			part, size = {}, #head + 1
		end
		part[#part + 1] = item
		size = size + #item + 1
	end
	if #part > 0 then
		Sync.Send(head .. SEP .. table.concat(part, ";"), channel, target)
	end
end

local RESULT = Enum.SendAddonMessageResult

-- One message from the queue (ticker)
function Sync.Pump()
	if #queue == 0 then
		return
	end
	if backoff > 0 then
		backoff = backoff - 1
		return
	end
	if InCombatLockdown() or C_ChatInfo.InChatMessagingLockdown() then
		return
	end
	local msg = table.remove(queue, 1)
	local result = C_ChatInfo.SendAddonMessage(PREFIX, msg[1], msg[2], msg[3])
	if result == RESULT.Success then
		Sync.stats.sent = Sync.stats.sent + 1
	elseif result == RESULT.AddonMessageThrottle or result == RESULT.ChannelThrottle or result == RESULT.AddOnMessageLockdown then
		table.insert(queue, 1, msg)   -- again later
		backoff = BACKOFF
		return
	end
	-- other results (not in a guild, member offline, ...): the message is dropped
	if msg[4] then
		answering[msg[4]] = nil
	end
end

---------------------------------------------------------------------------
-- Hello and live updates
---------------------------------------------------------------------------

function Sync.Hello(force)
	if not Sync.Enabled() then
		return
	end
	local total = Sync.Digests().total
	if not force and helloSent and helloSent.total == total and GetTime() - helloSent.time < HELLO_REPEAT then
		return
	end
	helloSent = { total = total, time = GetTime() }
	Sync.Send(table.concat({ "H", VERSION, total }, SEP), "GUILD")
end

local QueueLive = qnCore.Debounce(function()
	if not Sync.Enabled() then
		wipe(live)
		return
	end
	for key, items in pairs(live) do
		local kind, map = key:match("^(%l+),(%d+)$")
		Sync.SendList(table.concat({ "B", VERSION, kind, map }, SEP), items, "GUILD")
	end
	wipe(live)
end, LIVE_DELAY)

-- a new own node: send it to the guild soon
local function OnNodeAdded(kind, map, coord, res, origin)
	digests = nil
	if origin ~= "own" or not Sync.Enabled() then
		return
	end
	local entry = Entry(coord, res)
	if not entry then
		return
	end
	local key = kind .. "," .. map
	live[key] = live[key] or {}
	table.insert(live[key], entry)
	QueueLive()
end

---------------------------------------------------------------------------
-- Receiving
---------------------------------------------------------------------------

local function ValidKindMap(kind, map)
	return ns.KINDS[kind] and map and map > 0 and C_Map.GetMapInfo(map) ~= nil
end

-- Chat message about new nodes (option sync.announce): counted per member, kind and map and
-- reported together a moment later, so that a large exchange gives one line per zone
local announce = {}      -- ["sender\tkind\tmap"] = count

local QueueAnnounce = qnCore.Debounce(function()
	local keys = qnCore.SortedKeys(announce)
	for _, key in ipairs(keys) do
		local sender, kind, map = key:match("^(.-)\t(.-)\t(%d+)$")
		local info = C_Map.GetMapInfo(tonumber(map))
		ns.Print(L["Guild: %d new nodes (%s) in %s from %s."]:format(announce[key], ns.KINDS[kind].name,
			info and info.name or map, Ambiguate(sender, "none")))
	end
	wipe(announce)
end, ANNOUNCE_DELAY)

local function Announce(sender, kind, map, count)
	if count <= 0 or not DB.global.sync.announce then
		return
	end
	local key = sender .. "\t" .. kind .. "\t" .. map
	announce[key] = (announce[key] or 0) + count
	QueueAnnounce()
end

-- Takes over "coord,res;..." of sender; respects the rate limit
local function IngestEntries(sender, kind, map, list)
	local new = 0
	local r = received[sender]
	if not r or GetTime() - r.start > 3600 then
		r = { start = GetTime(), count = 0 }
		received[sender] = r
	end
	local origin = "guild:" .. sender
	for _, item in ipairs(Split(list, ";")) do
		local coord, res = item:match("^(%d+),(.+)$")
		coord = tonumber(coord)
		if r.count >= Sync.maxRecords then
			Sync.stats.rejected = Sync.stats.rejected + 1
		elseif coord and coord < 100000000 then
			r.count = r.count + 1
			local x, y = DB.Decode(coord)
			local result = DB.Ingest({ t = "node", kind = kind, map = map, x = x, y = y, res = res }, origin)
			if result then
				Sync.stats.received = Sync.stats.received + 1
				if result == "added" or result == "replaced" then
					new = new + 1
				end
			else
				Sync.stats.rejected = Sync.stats.rejected + 1
			end
		else
			Sync.stats.rejected = Sync.stats.rejected + 1
		end
	end
	Announce(sender, kind, map, new)
end

local function Finished(sender)
	local o = outstanding[sender]
	if o and o.maps <= 0 and o.total then
		Seen(sender).total = o.total
		outstanding[sender] = nil
	end
end

local HANDLERS = {}

-- hello: request the list if the data of the member changed since the last exchange
function HANDLERS.H(sender, f, channel)
	if channel ~= "GUILD" or not f[3] then return end
	peers[sender] = GetTime()
	local o = outstanding[sender]
	if Seen(sender).total ~= f[3] and (not o or GetTime() - o.started > REQUEST_TIMEOUT) then
		Sync.Hello()   -- our hello first: the member only answers known members
		outstanding[sender] = { maps = 0, started = GetTime() }
		Sync.Send(table.concat({ "L", VERSION }, SEP), "WHISPER", sender)
	end
end

-- request for the list of map digests
function HANDLERS.L(sender, f, channel)
	if channel ~= "WHISPER" or not peers[sender] then return end
	local answer = Answer(sender, "L")
	if not answer then return end
	local d = Sync.Digests()
	local items = {}
	for key, digest in pairs(d.maps) do
		items[#items + 1] = key .. "," .. digest
	end
	table.sort(items)
	Sync.SendList(table.concat({ "M", VERSION }, SEP), items, "WHISPER", sender)
	Sync.Send(table.concat({ "ME", VERSION, d.total }, SEP), "WHISPER", sender, answer)
end

-- map digests of a member: request the maps that changed
function HANDLERS.M(sender, f, channel)
	local o = outstanding[sender]
	if channel ~= "WHISPER" or not o or not f[3] then return end
	local seen = Seen(sender)
	for _, item in ipairs(Split(f[3], ";")) do
		local kind, map, digest = item:match("^(%l+),(%d+),(%x+)$")
		map = tonumber(map)
		if kind and ValidKindMap(kind, map) and seen.maps[kind .. "," .. map] ~= digest then
			o.maps = o.maps + 1
			Sync.Send(table.concat({ "R", VERSION, kind, map }, SEP), "WHISPER", sender)
		end
	end
end

function HANDLERS.ME(sender, f, channel)
	local o = outstanding[sender]
	if channel ~= "WHISPER" or not o or not f[3] then return end
	o.total = f[3]
	Finished(sender)
end

-- request for the nodes of a map
function HANDLERS.R(sender, f, channel)
	local kind, map = f[3], tonumber(f[4])
	if channel ~= "WHISPER" or not peers[sender] or not ns.KINDS[kind] or not map then return end
	local answer = Answer(sender, "R," .. kind .. "," .. map)
	if not answer then return end
	local items = {}
	for coord, n in DB.Nodes(kind, map) do
		if Sync.Shareable(n.origin) then
			items[#items + 1] = Entry(coord, n.res)
		end
	end
	table.sort(items)
	Sync.SendList(table.concat({ "D", VERSION, kind, map }, SEP), items, "WHISPER", sender)
	Sync.Send(table.concat({ "DE", VERSION, kind, map, Sync.Digests().maps[kind .. "," .. map] or "0" }, SEP), "WHISPER", sender, answer)
end

function HANDLERS.D(sender, f, channel)
	local kind, map = f[3], tonumber(f[4])
	if channel ~= "WHISPER" or not outstanding[sender] or not f[5] or not ValidKindMap(kind, map) then return end
	IngestEntries(sender, kind, map, f[5])
end

function HANDLERS.DE(sender, f, channel)
	local o = outstanding[sender]
	local kind, map = f[3], tonumber(f[4])
	if channel ~= "WHISPER" or not o or not f[5] or not ns.KINDS[kind] or not map then return end
	Seen(sender).maps[kind .. "," .. map] = f[5]
	o.maps = o.maps - 1
	Finished(sender)
end

-- new nodes of a member
function HANDLERS.B(sender, f, channel)
	local kind, map = f[3], tonumber(f[4])
	if channel ~= "GUILD" or not f[5] or not ValidKindMap(kind, map) then return end
	peers[sender] = peers[sender] or GetTime()
	IngestEntries(sender, kind, map, f[5])
end

function Sync.OnMessage(prefix, text, channel, sender)
	if prefix ~= PREFIX or not Sync.Enabled() or ns.AnySecret(text, sender, channel) then
		return
	end
	if type(text) ~= "string" or type(sender) ~= "string" or #text > 255 then
		return
	end
	if sender == Self() or Ambiguate(sender, "none") == UnitName("player") or Ignored(sender) then
		return
	end
	local f = Split(text, SEP)
	if f[2] ~= VERSION then
		return   -- other protocol version
	end
	local handler = HANDLERS[f[1]]
	if handler then
		handler(sender, f, channel)
	end
end

---------------------------------------------------------------------------
-- Status (slash command and options)
---------------------------------------------------------------------------

function Sync.Status()
	if not DB.global.sync.enabled then
		ns.Print(L["Guild exchange: off."])
		return
	end
	if not IsInGuild() then
		ns.Print(L["Guild exchange: on, but you are not in a guild."])
		return
	end
	local count = 0
	for _ in pairs(peers) do count = count + 1 end
	ns.Print(L["Guild exchange: on. Members with qnGatherer: %d. Messages sent: %d, nodes received: %d, rejected: %d, waiting: %d."]:format(
		count, Sync.stats.sent, Sync.stats.received, Sync.stats.rejected, #queue))
end

-- After switching the exchange on or changing what is shared
function Sync.OptionsChanged()
	digests = nil
	if Sync.Enabled() then
		Sync.Hello(true)
	else
		wipe(queue)
		wipe(answering)
	end
end

function Sync.Init()
	DB.global.sync.seen = DB.global.sync.seen or {}
	C_ChatInfo.RegisterAddonMessagePrefix(PREFIX)
	ns.events.Register("CHAT_MSG_ADDON", function(_, prefix, text, channel, sender)
		Sync.OnMessage(prefix, text, channel, sender)
	end)
	DB.OnNodeAdded(OnNodeAdded)
	DB.OnChange(function()
		digests = nil
	end)
	C_Timer.NewTicker(SEND_INTERVAL, Sync.Pump)
	C_Timer.After(HELLO_DELAY + math.random(0, HELLO_JITTER), function()
		Sync.Hello(true)
	end)
	C_Timer.NewTicker(HELLO_REPEAT, function()
		Sync.Hello()
	end)
end
