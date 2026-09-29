-- qnBuffMod: read the auras of the watched units.
-- Per unit the four filters (debuffs, cancelable, uncancelable, all
-- buffs) are read; one record per aura and filter. The state of an aura
-- (warning, renewal, range) is tied to the aura's key and is the same for all filters.
--
-- Record: { key, name, icon, count, duration, expiration, dispel, caster, spellId, index, filter,
--           group, kind, placeholder, outOfRange, state }

local _, ns = ...
local lib = qnCore
local L = ns.L
local E = ns.enum
local K = ns.kind
local IsSecret = lib.IsSecret

local Auras = {}
ns.Auras = Auras

local MAX_AURAS = 100       -- guard against endless loops per filter
local MAX_ERRORS = 5        -- this many consecutive failures stop reading a filter
local READ_ORDER = { E.group.ALLBUFFS, E.group.CANCELABLE, E.group.UNCANCELABLE, E.group.DEBUFF }
local EMPTY = {}

-- units[unit] = { lists = { [group] = { records } }, states = { [key] = state } }
local units = {}
Auras.units = units
local watched = { player = true }

local stale = false          -- not read during the global restriction
local notedField, notedLock = false, false

---------------------------------------------------------------------------
-- Restrictions and messages
---------------------------------------------------------------------------

-- Global restriction of aura data (e.g. in combat, in encounters)
function Auras.Restricted()
	return C_Secrets.ShouldAurasBeSecret() and true or false
end

-- Lists frozen: restriction active or not yet re-read after it ended
function Auras.Frozen()
	return stale or Auras.Restricted()
end

local function NoteField()
	if not notedField then
		notedField = true
		ns.Print(L["The client is currently withholding aura data (secret). Affected auras are shown without time remaining or with a question mark."])
	end
end

local function NoteLock()
	if not notedLock then
		notedLock = true
		ns.Print(L["In combat the client withholds aura data. Until then the windows show the last known state."])
	end
end

---------------------------------------------------------------------------
-- Read one aura
---------------------------------------------------------------------------

local function Placeholder(index, filter, group)
	return {
		key = "?" .. filter .. ":" .. index,
		name = "?",
		icon = ns.QUESTION_MARK,
		count = 0,
		duration = 0,
		expiration = 0,
		index = index,
		filter = filter,
		group = group,
		kind = group == E.group.DEBUFF and K.DEBUFF or K.AURA,
		placeholder = true,
	}
end

-- Field of an aura; secret = nil and notes it in secret (ReadAura resets secret beforehand)
local secret = false
local function Get(data, field)
	local v = data[field]
	if IsSecret(v) then
		secret = true
		return nil
	end
	return v
end

-- Returns a record, false (aura counts as absent) or nil (no further aura)
local function ReadAura(unit, index, filter, group)
	local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
	if not ok then
		-- query of exactly this aura failed: placeholder
		NoteField()
		return Placeholder(index, filter, group), true
	end
	if data == nil then
		return nil
	end
	if IsSecret(data) then
		return false
	end

	secret = false
	local name, icon, count = Get(data, "name"), Get(data, "icon"), Get(data, "applications")
	local duration, expiration = Get(data, "duration"), Get(data, "expirationTime")
	local dispel, caster = Get(data, "dispelName"), Get(data, "sourceUnit")
	local spellId, instance = Get(data, "spellId"), Get(data, "auraInstanceID")

	local rec
	if secret then
		-- individual fields secret: placeholder with the readable fields
		NoteField()
		rec = Placeholder(index, filter, group)
		if type(name) == "string" then
			rec.name = name
		end
		if icon ~= nil then
			rec.icon = icon
		end
	else
		rec = {
			name = type(name) == "string" and name or "?",
			icon = icon or ns.QUESTION_MARK,
			count = type(count) == "number" and count or 0,
			duration = type(duration) == "number" and duration or 0,
			expiration = type(expiration) == "number" and expiration or 0,
			index = index,
			filter = filter,
			group = group,
		}
		if group == E.group.DEBUFF then
			rec.kind = K.DEBUFF
		elseif rec.duration > 0 then
			rec.kind = K.BUFF
		else
			rec.kind = K.AURA
		end
		rec.key = rec.name .. "|" .. tostring(spellId) .. "|" .. tostring(caster)
	end
	rec.dispel = type(dispel) == "string" and dispel or nil
	rec.caster = type(caster) == "string" and caster or nil
	rec.spellId = type(spellId) == "number" and spellId or nil
	if type(instance) == "number" then
		rec.key = "#" .. instance
	end
	return rec, false
end

local function ReadFilter(unit, group)
	local filter = ns.FILTERS[group]
	local list, keys, errors = {}, {}, 0
	for i = 1, MAX_AURAS do
		local rec, failed = ReadAura(unit, i, filter, group)
		if rec == nil then
			break
		end
		errors = failed and errors + 1 or 0
		if rec then
			-- same key twice in the same filter (e.g. stacked multiple times): make it unique
			local n = keys[rec.key]
			keys[rec.key] = (n or 0) + 1
			if n then
				rec.key = rec.key .. "/" .. n
			end
			list[#list + 1] = rec
		end
		if errors >= MAX_ERRORS then
			break
		end
	end
	return list
end

---------------------------------------------------------------------------
-- State of an aura (per unit and key)
---------------------------------------------------------------------------

function Auras.HasExpiry(rec)
	return rec.duration > 0 and rec.expiration > 0
end

-- Warned applications across units: [GUID .. "|" .. key] = expiration time at the
-- warning. The state is tied to the token (e.g. target) and is lost on target change; if the
-- unit returns, the same application still counts as warned.
local warnedApps = {}

-- A changed expiration only counts as renewal if the new time remaining is at most 60 s below the full
-- duration (or duration 0 and expiration ≠ 0)
local function Renewed(rec, oldExpiration, now)
	if rec.expiration == oldExpiration then
		return false
	end
	if rec.duration > 0 then
		return rec.expiration - now >= rec.duration - 60
	end
	return rec.expiration ~= 0
end

-- Record the warning for the application of rec (on the state and across units)
function Auras.SetWarned(rec)
	local st = rec.state
	st.warned = true
	if st.app then
		warnedApps[st.app] = rec.expiration
	end
end

-- Forget expired applications
local function PruneWarned(now)
	for app, expiration in pairs(warnedApps) do
		if expiration <= now then
			warnedApps[app] = nil
		end
	end
end

-- Compares with the previous state: new aura, renewal, out of range.
local function Track(unit, data, rec, now, seen)
	local st = data.states[rec.key]
	if seen[rec.key] then
		-- same aura in another filter: take over the result
		rec.state = st
		rec.outOfRange = st.outOfRange
		if st.outOfRange then
			rec.kind = st.kind
		end
		return
	end
	seen[rec.key] = true
	if not st then
		st = { expiration = rec.expiration, duration = rec.duration, kind = rec.kind }
		data.states[rec.key] = st
		if data.guid and not rec.placeholder then
			st.app = data.guid .. "|" .. rec.key
			local warnedAt = warnedApps[st.app]
			if warnedAt then
				if Renewed(rec, warnedAt, now) then
					warnedApps[st.app] = nil
				else
					st.warned = true   -- the same application was already warned
				end
			end
		end
		if unit == "player" and not rec.placeholder then
			ns.Recast.Forget(rec.name)   -- newly appeared
		end
	elseif not rec.placeholder and rec.duration == 0 and rec.expiration == 0 and st.duration > 0 then
		-- out of range the game reports duration and expiration 0: treated as non-expiring, type stays
		rec.outOfRange = true
		rec.kind = st.kind
	else
		if Renewed(rec, st.expiration, now) then
			st.warned = nil
			if st.app then
				warnedApps[st.app] = nil
			end
			if unit == "player" then
				ns.Recast.Forget(rec.name)
			end
		end
		st.expiration = rec.expiration
		st.duration = rec.duration
		st.kind = rec.kind
	end
	st.outOfRange = rec.outOfRange
	rec.state = st
end

---------------------------------------------------------------------------
-- Units
---------------------------------------------------------------------------

-- Reads all filters of the unit (without checking the restriction)
function Auras.Read(unit)
	local data = units[unit]
	if not data then
		data = { states = {} }
		units[unit] = data
	end
	-- different unit behind the token (target change): the states no longer belong to it.
	-- Unreadable (secret) GUID: no cross-unit warning record for new states.
	local guid = lib.Plain(UnitGUID(unit), nil)
	if type(guid) ~= "string" then
		guid = nil
	end
	if guid ~= data.guid then
		if guid and data.guid then
			wipe(data.states)
		end
		data.guid = guid
	end
	local lists, seen, now = {}, {}, GetTime()
	PruneWarned(now)
	for _, group in ipairs(READ_ORDER) do
		lists[group] = ReadFilter(unit, group)
	end
	for _, group in ipairs(READ_ORDER) do
		for _, rec in ipairs(lists[group]) do
			Track(unit, data, rec, now, seen)
		end
	end
	for key in pairs(data.states) do
		if not seen[key] then
			data.states[key] = nil
		end
	end
	data.lists = lists
end

-- Re-read if the unit is watched and the data is readable. true = read.
function Auras.Update(unit)
	if not watched[unit] then
		return false
	end
	if Auras.Restricted() then
		stale = true
		NoteLock()
		return false
	end
	Auras.Read(unit)
	return true
end

-- List of the records of a group (empty until something has been read)
function Auras.List(unit, group)
	local data = units[unit]
	return data and data.lists and data.lists[group] or EMPTY
end

function Auras.IsWatched(unit)
	return watched[unit] or false
end

-- Set the watched units (always the player). Units no longer watched lose their
-- data, newly watched ones are read immediately.
function Auras.SetWatched(set)
	set.player = true
	local added = {}
	for unit in pairs(set) do
		if not watched[unit] then
			added[#added + 1] = unit
		end
	end
	for unit in pairs(watched) do
		if not set[unit] then
			units[unit] = nil
		end
	end
	watched = set
	for _, unit in ipairs(added) do
		Auras.Update(unit)
	end
end

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local dirty = {}

-- Read changed units in the next frame (several UNIT_AURA combined)
local Flush = lib.Debounce(function()
	local list = dirty
	dirty = {}
	for unit in pairs(list) do
		if Auras.Update(unit) then
			ns.UnitChanged(unit)
		end
	end
end)

function Auras.MarkDirty(unit)
	if watched[unit] then
		dirty[unit] = true
		Flush()
	end
end

-- After leaving a vehicle the game no longer sends UNIT_AURA for vehicle/pet:
-- re-read every 2 s for 20 s.
local pollLeft = 0

function Auras.StartPoll()
	pollLeft = 20
end

-- One-second tick (Core)
function Auras.Tick()
	if pollLeft <= 0 then
		return
	end
	pollLeft = pollLeft - 1
	if pollLeft % 2 == 0 then
		for _, unit in ipairs({ "vehicle", "pet" }) do
			if Auras.Update(unit) then
				ns.UnitChanged(unit)
			end
		end
	end
end

-- After the restriction ends (checked only in the next frame): re-read and arrange everything
local function CheckUnlock()
	if not stale or Auras.Restricted() then
		return
	end
	stale = false
	for unit in pairs(watched) do
		Auras.Read(unit)
	end
	ns.UnitChanged(nil)
end

-- in the next frame; several events in the same frame count once
local Later = lib.Debounce(CheckUnlock)

function Auras.Init()
	local ev = ns.events
	ev.Register("UNIT_AURA", function(_, unit)
		Auras.MarkDirty(unit)
	end)
	ev.Register("PLAYER_TARGET_CHANGED", function()
		Auras.MarkDirty("target")
	end)
	ev.Register("PLAYER_FOCUS_CHANGED", function()
		Auras.MarkDirty("focus")
	end)
	ev.Register("UNIT_PET", function(_, unit)
		if unit == "player" then
			Auras.MarkDirty("pet")
		end
	end)
	ev.Register("UNIT_ENTERED_VEHICLE", function(_, unit)
		if unit == "player" then
			ns.SetVehicle(true)
		end
	end)
	ev.Register("UNIT_EXITED_VEHICLE", function(_, unit)
		if unit == "player" then
			ns.SetVehicle(false)
			Auras.StartPoll()
		end
	end)
	ev.Register("ADDON_RESTRICTION_STATE_CHANGED", Later)
	ev.Register("PLAYER_REGEN_ENABLED", Later)
end
