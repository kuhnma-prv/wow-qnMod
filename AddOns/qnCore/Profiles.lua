-- qnCore: settings profiles for all qn addons.
--
-- The active profile is always the layout that is active in WoW's
-- Edit Mode. Profile keys:
--   preset:<No>                Blizzard preset (Modern, Classic ...), by position
--   account:<Name>             account-wide layout
--   char:<Name-Realm>:<Name>   character-specific layout - exists only for this
--                              character, hence the character is part of the key
--
-- Each addon registers its saved variable in its ADDON_LOADED:
--   store = qnCore.Profiles.Register({ ns, sv, defaults, upgrade, obsolete, legacy, onSwitch })
-- and always finds the active profile's table in ns.db (= store.db). store:Set(key, value)
-- or store:SetValues(values) changes values so that the settings window shows them too.
-- Structure of the saved variable:
--   { profiles = { [key] = {...} }, global = {...} }
-- store.global is account-wide and not tied to any profile.
--
-- On the first start after the rework, the previous settings (old format without
-- profiles or opts.legacy) become the current profile. A layout that has no profile
-- yet starts with a copy of the profile active until then. Until the layout is known after
-- logging in, the profile of this character's last session applies (qnCoreCharDB.layout).

local _, ns = ...
local lib = qnCore
local L = ns.L

local P = {}
lib.Profiles = P

local stores = {}          -- registration order
P.stores = stores
local activeKey            -- nil as long as the layout is not known yet
local listeners = {}

local TYPE_PRESET = Enum.EditModeLayoutType.Preset
local TYPE_ACCOUNT = Enum.EditModeLayoutType.Account
local TYPE_CHARACTER = Enum.EditModeLayoutType.Character

---------------------------------------------------------------------------
-- Profile object per addon
---------------------------------------------------------------------------

local Store = {}
Store.__index = Store

-- Brings a profile table up to date: conversions (upgrade), delete obsolete
-- keys (obsolete, after upgrade - which can still read them), fill in defaults.
function Store:Prepare(db)
	if self.upgrade then
		self.upgrade(db)
	end
	lib.RemoveKeys(db, self.obsolete)
	lib.MergeDefaults(db, self.defaults)
	return db
end

-- Sets a value of the active profile so that the settings window shows it too (via
-- the setting including callback). Without a control, the first builder writes directly and calls
-- its apply; without a builder, the value is only written.
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

-- Several values at once: write, re-read the settings window (without callbacks) and
-- then call apply of the first builder only once - no intermediate state is applied
-- (e.g. new x with old y).
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

-- New profile table: copy of the active profile or of the template from the old format.
function Store:NewProfileTable()
	return self:Prepare(CopyTable(self.db or self.seed or {}))
end

-- Switches to profile key. Returns true if ns.db has changed.
function Store:Activate(key)
	local profiles = self.sv.profiles
	if self.migrating then
		-- First start after the rework: the previous settings (including changes since
		-- loading) become the current profile. If a profile already exists for it (e.g. taken over
		-- from another character with its own earlier SavedVariablesPerCharacter), it
		-- is kept and the previous values are discarded.
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
			db = self.db          -- take over the provisional table from before logging in
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

-- After a switch: re-read the settings window, then let the addon apply.
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

-- Replace the content of the active profile with src (same table, so references stay valid).
-- In combat only afterwards (the addons' onSwitch touches protected frames); a further call until
-- then replaces the queued one. Returns true if deferred.
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

-- After combat: carry out the queued replacement if the same profile is still active.
function Store:ApplyPending()
	local pending = self.pending
	self.pending = nil
	if pending and pending.key == self.key then
		self:Replace(pending.src)
	end
end

-- Reset the active profile to the defaults. Returns true if deferred until after combat.
function Store:ResetActive()
	return self:Replace({})
end

-- Copy the content of another profile into the active profile. Returns whether it is copied and
-- whether that is deferred until after combat.
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
-- Registration
---------------------------------------------------------------------------

-- Load saved variable opts.sv and bring it into profile format (also write it back to _G).
-- Returns sv and seed: the previous settings from the old format without profiles or from
-- opts.legacy, otherwise nil.
local function LoadSavedVariable(opts)
	local sv = _G[opts.sv]
	if type(sv) ~= "table" then
		sv = {}
	end
	local seed
	if sv.profiles == nil then
		-- old format without profiles: the whole table becomes the template for the first profile
		if next(sv) then
			seed = sv
		end
		sv = {}
	end
	sv.version = nil   -- saved in the past, never read
	sv.profiles = sv.profiles or {}
	sv.global = sv.global or {}
	_G[opts.sv] = sv

	if not seed and type(opts.legacy) == "table" and next(opts.legacy) then
		seed = CopyTable(opts.legacy)
	end
	return sv, seed
end

-- Choose the start profile of the newly registered store.
local function ChooseStartProfile(store, sv, seed)
	if seed then
		-- Previous settings: become the current profile at the first detected layout.
		-- A copy remains as template (sv.migrated) for characters that later log in for the first
		-- time with a layout without profile.
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
	-- Start profile: the known layout, otherwise that of the last session, otherwise a
	-- provisional table that becomes the profile of the first detected layout.
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

-- opts.ns        namespace; ns.db is set on every switch
-- opts.name      addon name (display, key in P.stores); default: name from qnCore.NewAddon
-- opts.sv        name of the saved variable (## SavedVariables)
-- opts.defaults  defaults
-- opts.upgrade   function(db) - converts older tables (optional)
-- opts.obsolete  list of obsolete keys to delete, also "dual.uiOnMain" (optional)
-- opts.legacy    table in the old format without profiles, e.g. from an earlier
--                SavedVariablesPerCharacter (optional)
-- opts.onSwitch  function(store) - after a profile switch (optional)
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
	-- one function per addon, so that DeferInCombat merges several calls
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
-- Active Edit Mode layout
---------------------------------------------------------------------------

local function CharName()
	local name = UnitName("player")
	local realm = GetRealmName()
	if not name or name == "" or name == UNKNOWNOBJECT then
		return nil
	end
	return realm ~= "" and (name .. "-" .. realm) or name
end

-- Returns key and description of the active layout, or nil as long as it is not known.
local function ReadActiveLayout()
	-- Blizzard's copy contains the presets at the front; overrideLayoutInfo (special cases) deliberately not.
	-- layoutInfo only exists after the first EDIT_MODE_LAYOUTS_UPDATED.
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
	return nil   -- special layouts (override) have no profile of their own
end

function P.GetActiveKey()
	return activeKey
end

-- Display name of a profile
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

-- All profile keys of the given addons (nil = all), sorted by display name
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

-- Callback on every profile switch: fn(newKey, oldKey)
function P.OnChange(fn)
	listeners[#listeners + 1] = fn
end

local Queue

local function Check()
	if lib.DeferInCombat(Queue) then
		return   -- touch protected frames only after combat
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
	-- an error does not stop the others
	for _, fn in ipairs(listeners) do
		local ok, err = pcall(fn, key, old)
		if not ok then
			geterrorhandler()(err)
		end
	end
end

-- Merge several triggers in the same frame; only afterwards has Blizzard
-- updated EditModeManagerFrame.layoutInfo.
Queue = lib.Debounce(Check)

---------------------------------------------------------------------------
-- Manage profiles ("Profiles" page)
---------------------------------------------------------------------------

-- In combat, it is applied only afterwards; the return value deferred says so.
function P.ResetActive(list)
	local deferred = false
	for _, store in ipairs(list or stores) do
		if store:ResetActive() then
			deferred = true
		end
	end
	return deferred
end

-- Returns the number of addons and deferred (in combat: applied only afterwards).
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
	-- keep the description as long as any addon still has the profile
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
-- Start (from Core.lua on qnCore's ADDON_LOADED)
---------------------------------------------------------------------------

function P.Init()
	qnCoreDB = qnCoreDB or {}
	qnCoreDB.layouts = qnCoreDB.layouts or {}
	qnCoreCharDB = qnCoreCharDB or {}

	local hub = lib.NewEventHub()
	hub.Register("PLAYER_ENTERING_WORLD", Queue)
	-- On PLAYER_SPECIALIZATION_CHANGED Blizzard itself calls UpdateLayoutInfo
	-- (EditModeManagerFrameMixin:OnEvent) - the hook is enough. EDIT_MODE_LAYOUTS_UPDATED stays
	-- registered: there UpdateLayoutInfo runs in a pcall (Blizzard: "BUILD FIXME"); if it
	-- fails, the hook does not run.
	hub.Register("EDIT_MODE_LAYOUTS_UPDATED", Queue)
	-- hooksecurefunc only appends itself and does not change Blizzard's code
	for _, method in ipairs({ "UpdateLayoutInfo", "SelectLayout", "SaveLayouts" }) do
		hooksecurefunc(EditModeManagerFrame, method, Queue)
	end
end
