-- qnCore: own addon - defaults, startup, slash commands.
-- The qnCore options for bags and tracking always apply account-wide: they live in
-- qnCoreDB.global and are tied neither to a profile nor to a character. The font of the
-- Objective Tracker applies per profile (qnCoreDB.profiles).

local ADDON, ns = ...
local lib = qnCore

lib.NewAddon(ns, ADDON)
local L = ns.L

ns.defaults = {
	bags = ns.Bags.defaults,       -- Bags.lua
	tracking = true,               -- remember Minimap tracking (Tracking.lua)
}

-- Settings per profile (qnCoreDB.profiles, qnCore's own profile)
ns.profileDefaults = {
	questTextSize = 0,             -- Objective Tracker font size, 0 = as in Edit Mode (QuestTracker.lua)
}

-- Obsolete keys in qnCoreDB.global
local OBSOLETE = {
	"chatTimestamps",   -- timestamp option removed (the game has it)
}

-- An earlier version stored the bags per profile (qnCoreDB.profiles): copy them once into the
-- account-wide settings - from this character's last active profile.
-- Since ownProfiles is set, qnCoreDB.profiles holds qnCore's own profiles.
local function MigrateProfiles(db)
	local profiles = db.profiles
	if type(profiles) ~= "table" or db.ownProfiles then
		return
	end
	local last = qnCoreCharDB and qnCoreCharDB.layout
	local src = last and profiles[last]
	if not src then
		local _, first = next(profiles)
		src = first
	end
	if type(src) == "table" then
		if not db.global.bagsShared and type(src.bags) == "table" then
			db.global.bags = CopyTable(src.bags)
		end
	end
	db.global.bagsShared = nil
	db.profiles, db.version = nil, nil
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

lib.RegisterSlash("QNCORE", { "/qncore", "/qnc" }, function(cmd)
	if cmd == "" or cmd == "config" then
		ns.OpenOptions()
	elseif cmd == "profile" then
		ns.OpenProfiles()
	elseif cmd == "status" then
		ns.Print(L["Version %s, active profile: %s"], lib.version, lib.Profiles.GetLabel(lib.Profiles.GetActiveKey()))
		for _, store in ipairs(lib.Profiles.stores) do
			ns.Print(L["  %s – %d profile(s)"], store.name, #store:ProfileKeys())
		end
	elseif cmd == "locale" then
		-- texts shown without translation in this session (only German clients translate)
		if not lib.GERMAN then
			ns.Print(L["Non-German client: all texts are shown in the original (English)."])
			return
		end
		local any = false
		for addon, keys in pairs(lib.missing) do
			for key in pairs(keys) do
				any = true
				ns.Print("%s: %s", addon, tostring(key))
			end
		end
		if not any then
			ns.Print(L["No untranslated text has been shown so far."])
		end
	else
		ns.Print(L["/qncore – options   |   /qncore profile – profiles   |   /qncore status – show active profile   |   /qncore locale – missing translations"])
	end
end)

---------------------------------------------------------------------------
-- Start
---------------------------------------------------------------------------

ns.OnLoad(function()
	qnCoreDB = qnCoreDB or {}
	qnCoreDB.global = qnCoreDB.global or {}
	lib.Profiles.Init()
	MigrateProfiles(qnCoreDB)
	lib.RemoveKeys(qnCoreDB.global, OBSOLETE)
	if not qnCoreDB.ownProfiles then
		qnCoreDB.profiles = {}   -- otherwise Profiles.Register would take the whole table for the old format
		qnCoreDB.ownProfiles = true
	end

	ns.global = lib.MergeDefaults(qnCoreDB.global, ns.defaults)
	ns.store = lib.Profiles.Register({
		ns = ns,
		sv = "qnCoreDB",
		defaults = ns.profileDefaults,
		onSwitch = function() ns.QuestTracker.Apply() end,
	})

	ns.Bags.Init()
	ns.Tracking.Init()
	ns.QuestTracker.Init()
	ns.InitOptions()
	ns.InitProfilesPage()
end)

lib.Profiles.OnChange(function(key, old)
	if old then
		ns.Print(L["Profile changed: %s"], lib.Profiles.GetLabel(key))
	end
end)
