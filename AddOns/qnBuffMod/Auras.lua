-- qnBuffMod: Auren der beobachteten Einheiten lesen.
-- Je Einheit werden die vier Filter (Schwächungszauber, aufhebbare, nicht aufhebbare, alle
-- Stärkungszauber) gelesen; ein Eintrag (Record) je Aura und Filter. Der Zustand einer Aura
-- (Warnung, Erneuerung, Reichweite) hängt am Schlüssel der Aura und ist für alle Filter derselbe.
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

local MAX_AURAS = 100       -- Schutz gegen Endlosschleifen je Filter
local MAX_ERRORS = 5        -- so viele Abbrüche hintereinander beenden das Lesen eines Filters
local READ_ORDER = { E.group.ALLBUFFS, E.group.CANCELABLE, E.group.UNCANCELABLE, E.group.DEBUFF }
local EMPTY = {}

-- units[Einheit] = { lists = { [Gruppe] = { Records } }, states = { [Schlüssel] = Zustand } }
local units = {}
Auras.units = units
local watched = { player = true }

local stale = false          -- während der globalen Sperre wurde nicht gelesen
local notedField, notedLock = false, false

---------------------------------------------------------------------------
-- Sperren und Meldungen
---------------------------------------------------------------------------

-- Globale Sperre der Aurendaten (z. B. im Kampf, in Begegnungen)
function Auras.Restricted()
	return C_Secrets.ShouldAurasBeSecret() and true or false
end

-- Listen eingefroren: Sperre aktiv oder nach ihrem Ende noch nicht neu gelesen
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
-- Eine Aura lesen
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

-- Feld einer Aura; secret = nil und merkt es in secret (ReadAura setzt secret vorher zurück)
local secret = false
local function Get(data, field)
	local v = data[field]
	if IsSecret(v) then
		secret = true
		return nil
	end
	return v
end

-- Liefert einen Record, false (Aura gilt als nicht vorhanden) oder nil (keine weitere Aura)
local function ReadAura(unit, index, filter, group)
	local ok, data = pcall(C_UnitAuras.GetAuraDataByIndex, unit, index, filter)
	if not ok then
		-- Abfrage genau dieser Aura abgebrochen: Platzhalter
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
		-- einzelne Felder secret: Platzhalter mit den lesbaren Feldern
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
			-- gleicher Schlüssel zweimal im selben Filter (z. B. mehrfach gestapelt): eindeutig machen
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
-- Zustand einer Aura (je Einheit und Schlüssel)
---------------------------------------------------------------------------

function Auras.HasExpiry(rec)
	return rec.duration > 0 and rec.expiration > 0
end

-- Gewarnte Anwendungen einheitenübergreifend: [GUID .. "|" .. Schlüssel] = Ablaufzeitpunkt bei der
-- Warnung. Der Zustand hängt am Token (z. B. target) und geht beim Zielwechsel verloren; kehrt die
-- Einheit zurück, gilt dieselbe Anwendung weiter als gewarnt.
local warnedApps = {}

-- Geänderter Ablauf gilt nur als Erneuerung, wenn die neue Restzeit höchstens 60 s unter der vollen
-- Dauer liegt (bzw. Dauer 0 und Ablauf ≠ 0)
local function Renewed(rec, oldExpiration, now)
	if rec.expiration == oldExpiration then
		return false
	end
	if rec.duration > 0 then
		return rec.expiration - now >= rec.duration - 60
	end
	return rec.expiration ~= 0
end

-- Warnung für die Anwendung von rec vermerken (am Zustand und einheitenübergreifend)
function Auras.SetWarned(rec)
	local st = rec.state
	st.warned = true
	if st.app then
		warnedApps[st.app] = rec.expiration
	end
end

-- Abgelaufene Anwendungen vergessen
local function PruneWarned(now)
	for app, expiration in pairs(warnedApps) do
		if expiration <= now then
			warnedApps[app] = nil
		end
	end
end

-- Vergleicht mit dem bisherigen Stand: neue Aura, Erneuerung, außer Reichweite.
local function Track(unit, data, rec, now, seen)
	local st = data.states[rec.key]
	if seen[rec.key] then
		-- dieselbe Aura in einem weiteren Filter: Ergebnis übernehmen
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
					st.warned = true   -- dieselbe Anwendung wurde schon gewarnt
				end
			end
		end
		if unit == "player" and not rec.placeholder then
			ns.Recast.Forget(rec.name)   -- neu erschienen
		end
	elseif not rec.placeholder and rec.duration == 0 and rec.expiration == 0 and st.duration > 0 then
		-- außer Reichweite meldet das Spiel Dauer und Ablauf 0: wie ohne Ablauf, Typ bleibt
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
-- Einheiten
---------------------------------------------------------------------------

-- Liest alle Filter der Einheit (ohne Prüfung der Sperre)
function Auras.Read(unit)
	local data = units[unit]
	if not data then
		data = { states = {} }
		units[unit] = data
	end
	-- andere Einheit hinter dem Token (Zielwechsel): Zustände gehören nicht mehr zu ihr.
	-- Unlesbare (secret) GUID: keine einheitenübergreifende Warnmerkung für neue Zustände.
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

-- Neu lesen, wenn die Einheit beobachtet wird und die Daten lesbar sind. true = gelesen.
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

-- Liste der Records einer Gruppe (leer, solange nichts gelesen ist)
function Auras.List(unit, group)
	local data = units[unit]
	return data and data.lists and data.lists[group] or EMPTY
end

function Auras.IsWatched(unit)
	return watched[unit] or false
end

-- Beobachtete Einheiten festlegen (der Spieler immer). Nicht mehr beobachtete verlieren ihre
-- Daten, neu beobachtete werden sofort gelesen.
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
-- Ereignisse
---------------------------------------------------------------------------

local dirty = {}

-- Geänderte Einheiten im nächsten Frame lesen (mehrere UNIT_AURA zusammengefasst)
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

-- Nach dem Verlassen eines Fahrzeugs meldet das Spiel für vehicle/pet kein UNIT_AURA mehr:
-- 20 s lang alle 2 s neu lesen.
local pollLeft = 0

function Auras.StartPoll()
	pollLeft = 20
end

-- Sekundentakt (Core)
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

-- Nach Ende der Sperre (erst im nächsten Frame prüfen): alles neu lesen und anordnen
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

-- im nächsten Frame; mehrere Ereignisse im selben Frame zählen einmal
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
