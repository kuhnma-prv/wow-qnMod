-- qnCore: Einstellungsprofile für alle qn-Addons.
--
-- Das aktive Profil ist immer das Layout, das im Bearbeitungsmodus von WoW
-- aktiv ist. Profilschlüssel:
--   preset:<Nr>                Blizzard-Vorgabe (Modern, Klassisch …), nach Position
--   account:<Name>             kontoweites Layout
--   char:<Name-Realm>:<Name>   charakterspezifisches Layout – gibt es nur für diesen
--                              Charakter, deshalb gehört der Charakter zum Schlüssel
--
-- Jedes Addon meldet in seinem ADDON_LOADED seine gespeicherte Variable an:
--   store = qnCore.Profiles.Register({ ns, sv, defaults, upgrade, obsolete, legacy, onSwitch })
-- und findet in ns.db (= store.db) immer die Tabelle des aktiven Profils. store:Set(key, value)
-- bzw. store:SetValues(values) ändert Werte so, dass auch das Einstellungsfenster sie zeigt.
-- Aufbau der gespeicherten Variable:
--   { profiles = { [Schlüssel] = {...} }, global = {...} }
-- store.global ist kontoweit und hängt an keinem Profil.
--
-- Beim ersten Start nach dem Umbau werden die bisherigen Einstellungen (altes Format ohne
-- Profile bzw. opts.legacy) das aktuelle Profil. Ein Layout, für das es noch kein Profil
-- gibt, startet mit einer Kopie des bis dahin aktiven Profils. Bis das Layout nach dem
-- Einloggen bekannt ist, gilt das Profil der letzten Sitzung dieses Charakters (qnCoreCharDB.layout).

local _, ns = ...
local lib = qnCore
local L = ns.L

local P = {}
lib.Profiles = P

local stores = {}          -- Anmeldereihenfolge
P.stores = stores
local activeKey            -- nil, solange das Layout noch nicht bekannt ist
local listeners = {}

local TYPE_PRESET = Enum.EditModeLayoutType.Preset
local TYPE_ACCOUNT = Enum.EditModeLayoutType.Account
local TYPE_CHARACTER = Enum.EditModeLayoutType.Character

---------------------------------------------------------------------------
-- Profilobjekt je Addon
---------------------------------------------------------------------------

local Store = {}
Store.__index = Store

-- Bringt eine Profiltabelle auf den aktuellen Stand: Umrechnungen (upgrade), veraltete
-- Schlüssel löschen (obsolete, nach upgrade – das kann sie noch lesen), Vorgaben ergänzen.
function Store:Prepare(db)
	if self.upgrade then
		self.upgrade(db)
	end
	lib.RemoveKeys(db, self.obsolete)
	lib.MergeDefaults(db, self.defaults)
	return db
end

-- Setzt einen Wert des aktiven Profils so, dass auch das Einstellungsfenster ihn anzeigt (über
-- die Einstellung samt Rückruf). Ohne Steuerelement schreibt der erste Baukasten direkt und ruft
-- sein apply; ohne Baukasten wird nur geschrieben.
function Store:Set(key, value)
	if lib.Settings.SetIn(self.builders, key, value) then
		return
	end
	local b = self.builders[1]
	if b then
		b:Set(key, value)
	else
		self.db[key] = value
	end
end

-- Mehrere Werte auf einmal: schreiben, das Einstellungsfenster neu einlesen (ohne Rückrufe) und
-- dann nur einmal apply des ersten Baukastens aufrufen – kein Zwischenstand wird angewendet
-- (z. B. neues x mit altem y).
function Store:SetValues(values)
	for key, value in pairs(values) do
		self.db[key] = value
	end
	for _, builder in ipairs(self.builders) do
		builder:Refresh()
	end
	local b = self.builders[1]
	if b and b.apply then
		b.apply()
	end
end

function Store:SetDB(db)
	self.db = db
	if self.ns then
		self.ns.db = db
	end
end

-- Neue Profiltabelle: Kopie des aktiven Profils bzw. der Vorlage aus dem alten Format.
function Store:NewProfileTable()
	return self:Prepare(CopyTable(self.db or self.seed or {}))
end

-- Schaltet auf das Profil key. Liefert true, wenn sich ns.db geändert hat.
function Store:Activate(key)
	local profiles = self.sv.profiles
	if self.migrating then
		-- Erster Start nach dem Umbau: die bisherigen Einstellungen (samt Änderungen seit dem
		-- Laden) werden das aktuelle Profil. Gibt es dafür schon ein Profil (z. B. von einem
		-- anderen Charakter mit eigener früherer SavedVariablesPerCharacter übernommen), bleibt
		-- es erhalten und die bisherigen Werte werden verworfen.
		self.migrating = nil
		if not profiles[key] then
			profiles[key] = self.db
			self.key = key
			if self.ns and self.ns.Print then
				self.ns.Print(L["Previous settings moved into profile %s."], P.GetLabel(key))
			end
			return false
		end
	end
	local db = profiles[key]
	if not db then
		if self.key == nil and self.db then
			db = self.db          -- vorläufige Tabelle aus der Zeit vor dem Einloggen übernehmen
		else
			db = self:NewProfileTable()
		end
		profiles[key] = db
	end
	self.key = key
	if db == self.db then
		return false
	end
	self:SetDB(db)
	return true
end

-- Nach einem Wechsel: Einstellungsfenster neu einlesen, dann das Addon anwenden lassen.
function Store:Switched()
	for _, builder in ipairs(self.builders) do
		builder:Refresh()
	end
	if self.onSwitch then
		local ok, err = pcall(self.onSwitch, self)
		if not ok then
			geterrorhandler()(err)
		end
	end
end

function Store:ProfileKeys()
	local list = {}
	for key in pairs(self.sv.profiles) do
		list[#list + 1] = key
	end
	return list
end

function Store:HasProfile(key)
	return self.sv.profiles[key] ~= nil
end

-- Inhalt des aktiven Profils durch src ersetzen (dieselbe Tabelle, damit Verweise gültig bleiben).
-- Im Kampf erst danach (onSwitch der Addons fasst geschützte Rahmen an); ein weiterer Aufruf bis
-- dahin ersetzt den vorgemerkten. Liefert true, wenn verzögert.
function Store:Replace(src)
	if InCombatLockdown() then
		self.pending = { key = self.key, src = src }
		lib.DeferInCombat(self.applyPending)
		return true
	end
	self.pending = nil
	wipe(self.db)
	for k, v in pairs(src) do
		self.db[k] = v
	end
	self:Prepare(self.db)
	self:Switched()
	return false
end

-- Nach dem Kampf: vorgemerktes Ersetzen ausführen, wenn noch dasselbe Profil aktiv ist.
function Store:ApplyPending()
	local pending = self.pending
	self.pending = nil
	if pending and pending.key == self.key then
		self:Replace(pending.src)
	end
end

-- Aktives Profil auf die Vorgaben zurücksetzen. Liefert true, wenn bis nach dem Kampf verzögert.
function Store:ResetActive()
	return self:Replace({})
end

-- Inhalt eines anderen Profils in das aktive Profil kopieren. Liefert, ob kopiert wird, und
-- ob das bis nach dem Kampf verzögert ist.
function Store:CopyToActive(fromKey)
	local src = self.sv.profiles[fromKey]
	if not src or src == self.db then
		return false, false
	end
	return true, self:Replace(CopyTable(src))
end

function Store:Delete(key)
	local db = self.sv.profiles[key]
	if not db or db == self.db then
		return false
	end
	self.sv.profiles[key] = nil
	return true
end

---------------------------------------------------------------------------
-- Anmeldung
---------------------------------------------------------------------------

-- Gespeicherte Variable opts.sv laden und in das Profilformat bringen (auch in _G zurückschreiben).
-- Liefert sv und seed: die bisherigen Einstellungen aus dem alten Format ohne Profile bzw. aus
-- opts.legacy, sonst nil.
local function LoadSavedVariable(opts)
	local sv = _G[opts.sv]
	if type(sv) ~= "table" then
		sv = {}
	end
	local seed
	if sv.profiles == nil then
		-- altes Format ohne Profile: die ganze Tabelle wird zur Vorlage für das erste Profil
		if next(sv) then
			seed = sv
		end
		sv = {}
	end
	sv.version = nil   -- früher gespeichert, nie gelesen
	sv.profiles = sv.profiles or {}
	sv.global = sv.global or {}
	_G[opts.sv] = sv

	if not seed and type(opts.legacy) == "table" and next(opts.legacy) then
		seed = CopyTable(opts.legacy)
	end
	return sv, seed
end

-- Startprofil des neu angemeldeten store wählen.
local function ChooseStartProfile(store, sv, seed)
	if seed then
		-- Bisherige Einstellungen: werden beim ersten erkannten Layout das aktuelle Profil.
		-- Eine Kopie bleibt als Vorlage (sv.migrated) für Charaktere, die später zum ersten
		-- Mal mit einem Layout ohne Profil einloggen.
		store:Prepare(seed)
		sv.migrated = sv.migrated or CopyTable(seed)
		store.migrating = true
		store:SetDB(seed)
		if activeKey then
			store:Activate(activeKey)
		end
		return
	end

	if type(sv.migrated) == "table" then
		store.seed = store:Prepare(sv.migrated)
	end
	-- Startprofil: das bekannte Layout, sonst das der letzten Sitzung, sonst eine
	-- vorläufige Tabelle, die beim ersten erkannten Layout dessen Profil wird.
	local key = activeKey or (qnCoreCharDB and qnCoreCharDB.layout)
	if activeKey then
		store:Activate(activeKey)
	elseif key and sv.profiles[key] then
		store.key = key
		store:SetDB(sv.profiles[key])
	else
		store:SetDB(store:NewProfileTable())
	end
end

-- opts.ns        Namensraum; ns.db wird bei jedem Wechsel gesetzt
-- opts.name      Addon-Name (Anzeige, Schlüssel in P.stores); Vorgabe: Name aus qnCore.NewAddon
-- opts.sv        Name der gespeicherten Variable (## SavedVariables)
-- opts.defaults  Vorgaben
-- opts.upgrade   function(db) – rechnet ältere Tabellen um (optional)
-- opts.obsolete  Liste veralteter Schlüssel, die gelöscht werden, auch "dual.uiOnMain" (optional)
-- opts.legacy    Tabelle im alten Format ohne Profile, z. B. aus einer früheren
--                SavedVariablesPerCharacter (optional)
-- opts.onSwitch  function(store) – nach einem Profilwechsel (optional)
function P.Register(opts)
	assert(qnCoreDB, "qnCore.Profiles.Register: call only in the addon's own ADDON_LOADED.")   -- do not translate: developer hint
	local sv, seed = LoadSavedVariable(opts)

	local name = opts.name or (opts.ns and ns.addonNames[opts.ns])
	assert(name, "qnCore.Profiles.Register: name missing (register ns with qnCore.NewAddon first).")   -- do not translate: developer hint
	local store = setmetatable({
		name = name,
		ns = opts.ns,
		sv = sv,
		global = sv.global,
		defaults = opts.defaults or {},
		upgrade = opts.upgrade,
		obsolete = opts.obsolete or {},
		onSwitch = opts.onSwitch,
		builders = {},
	}, Store)
	-- eine Funktion je Addon, damit DeferInCombat mehrere Aufrufe zusammenfasst
	store.applyPending = function()
		store:ApplyPending()
	end
	for _, db in pairs(sv.profiles) do
		store:Prepare(db)
	end
	ChooseStartProfile(store, sv, seed)

	stores[#stores + 1] = store
	stores[name] = store
	return store
end

---------------------------------------------------------------------------
-- Aktives Layout des Bearbeitungsmodus
---------------------------------------------------------------------------

local function CharName()
	local name = UnitName("player")
	local realm = GetRealmName()
	if not name or name == "" or name == UNKNOWNOBJECT then
		return nil
	end
	return realm ~= "" and (name .. "-" .. realm) or name
end

-- Liefert Schlüssel und Beschreibung des aktiven Layouts oder nil, solange es nicht bekannt ist.
local function ReadActiveLayout()
	-- Blizzards Kopie enthält vorne die Vorgaben; overrideLayoutInfo (Sonderfälle) bewusst nicht.
	-- layoutInfo gibt es erst nach dem ersten EDIT_MODE_LAYOUTS_UPDATED.
	local layoutInfo = EditModeManagerFrame.layoutInfo
	local index = layoutInfo and layoutInfo.activeLayout
	local info = index and layoutInfo.layouts[index]
	if not info then
		return nil
	end

	local name = info.layoutName or "?"
	if info.layoutType == TYPE_PRESET then
		return "preset:" .. index, { kind = "preset", name = name }
	elseif info.layoutType == TYPE_CHARACTER then
		local char = CharName()
		if not char then
			return nil
		end
		return "char:" .. char .. ":" .. name, { kind = "char", name = name, char = char }
	elseif info.layoutType == TYPE_ACCOUNT then
		return "account:" .. name, { kind = "account", name = name }
	end
	return nil   -- Sonderlayouts (Override) haben kein eigenes Profil
end

function P.GetActiveKey()
	return activeKey
end

-- Anzeigename eines Profils
function P.GetLabel(key)
	if not key then
		return L["not yet determined"]
	end
	local meta = qnCoreDB and qnCoreDB.layouts and qnCoreDB.layouts[key]
	if not meta then
		return key
	end
	if meta.kind == "preset" then
		return L["%s (Blizzard preset)"]:format(meta.name)
	elseif meta.kind == "char" then
		return L["%s (character-specific, %s)"]:format(meta.name, meta.char or "?")
	end
	return L["%s (account)"]:format(meta.name)
end

-- Alle Profilschlüssel der angegebenen Addons (nil = alle), sortiert nach Anzeigename
function P.GetKnownKeys(list)
	local seen, keys = {}, {}
	for _, store in ipairs(list or stores) do
		for key in pairs(store.sv.profiles) do
			if not seen[key] then
				seen[key] = true
				keys[#keys + 1] = key
			end
		end
	end
	table.sort(keys, function(a, b)
		return P.GetLabel(a) < P.GetLabel(b)
	end)
	return keys
end

-- Rückruf bei jedem Profilwechsel: fn(neuerSchlüssel, alterSchlüssel)
function P.OnChange(fn)
	listeners[#listeners + 1] = fn
end

local Queue

local function Check()
	if lib.DeferInCombat(Queue) then
		return   -- geschützte Rahmen erst nach dem Kampf anfassen
	end
	local key, meta = ReadActiveLayout()
	if not key then
		return
	end
	qnCoreDB.layouts[key] = meta
	qnCoreCharDB.layout = key
	if key == activeKey then
		return
	end
	local old = activeKey
	activeKey = key
	for _, store in ipairs(stores) do
		if store:Activate(key) then
			store:Switched()
		end
	end
	-- ein Fehler hält die übrigen nicht auf
	for _, fn in ipairs(listeners) do
		local ok, err = pcall(fn, key, old)
		if not ok then
			geterrorhandler()(err)
		end
	end
end

-- Mehrere Auslöser im selben Frame zusammenfassen; erst danach hat Blizzard
-- EditModeManagerFrame.layoutInfo aktualisiert.
Queue = lib.Debounce(Check)

---------------------------------------------------------------------------
-- Profile verwalten (Seite "Profile")
---------------------------------------------------------------------------

-- Im Kampf wird erst danach angewendet; der Rückgabewert deferred sagt das.
function P.ResetActive(list)
	local deferred = false
	for _, store in ipairs(list or stores) do
		if store:ResetActive() then
			deferred = true
		end
	end
	return deferred
end

-- Liefert die Zahl der Addons und deferred (im Kampf: erst danach angewendet).
function P.CopyToActive(fromKey, list)
	local n, deferred = 0, false
	for _, store in ipairs(list or stores) do
		local copied, later = store:CopyToActive(fromKey)
		if copied then
			n = n + 1
			deferred = deferred or later
		end
	end
	return n, deferred
end

function P.Delete(key, list)
	if key == activeKey then
		return 0
	end
	local n = 0
	for _, store in ipairs(list or stores) do
		if store:Delete(key) then
			n = n + 1
		end
	end
	-- Beschreibung behalten, solange noch irgendein Addon das Profil hat
	local used = false
	for _, store in ipairs(stores) do
		if store:HasProfile(key) then
			used = true
		end
	end
	if not used and qnCoreDB.layouts then
		qnCoreDB.layouts[key] = nil
	end
	return n
end

---------------------------------------------------------------------------
-- Start (aus Core.lua bei ADDON_LOADED von qnCore)
---------------------------------------------------------------------------

function P.Init()
	qnCoreDB = qnCoreDB or {}
	qnCoreDB.layouts = qnCoreDB.layouts or {}
	qnCoreCharDB = qnCoreCharDB or {}

	local hub = lib.NewEventHub()
	hub.Register("PLAYER_ENTERING_WORLD", Queue)
	-- Bei PLAYER_SPECIALIZATION_CHANGED ruft Blizzard selbst UpdateLayoutInfo auf
	-- (EditModeManagerFrameMixin:OnEvent) – der Hook genügt. EDIT_MODE_LAYOUTS_UPDATED bleibt
	-- angemeldet: dort läuft UpdateLayoutInfo in einem pcall (Blizzard: "BUILD FIXME"); scheitert
	-- es, läuft der Hook nicht.
	hub.Register("EDIT_MODE_LAYOUTS_UPDATED", Queue)
	-- hooksecurefunc hängt sich nur hinten an und verändert Blizzards Code nicht
	for _, method in ipairs({ "UpdateLayoutInfo", "SelectLayout", "SaveLayouts" }) do
		hooksecurefunc(EditModeManagerFrame, method, Queue)
	end
end
