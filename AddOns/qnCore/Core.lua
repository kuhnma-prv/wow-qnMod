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

-- Version of qnCore's settings (see qnCore.Migrate)
local SETTINGS_VERSION = "1.0"

-- Keys of qnCoreDB dropped without replacement
local OBSOLETE = {
	"ownProfiles",   -- marker of the move to qnCore's own profiles (before settings 1.0)
}

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
	lib.RemoveKeys(qnCoreDB, OBSOLETE)

	ns.global = lib.MergeDefaults(qnCoreDB.global, ns.defaults)
	ns.store = lib.Profiles.Register({
		ns = ns,
		sv = "qnCoreDB",
		settingsVersion = SETTINGS_VERSION,
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
