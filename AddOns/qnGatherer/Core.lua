-- qnGatherer: gathering database (herbs, ore, fishing, treasure).
-- Core: namespace, saved variable, profile store.

local ADDON, ns = ...

-- Version, Print, events and the secret helpers come from qnCore.
qnCore.NewAddon(ns, ADDON)
_G.qnGatherer = ns   -- API for other addons (do not translate)

---------------------------------------------------------------------------
-- Saved variable qnGathererDB
--   profiles  display settings per Edit Mode layout (qnCore.Profiles; ns.db = active profile)
--   global    gathered data and the options of data, import and sync (account-wide, see DB.lua)
---------------------------------------------------------------------------

local SETTINGS_VERSION = "1.0"

-- Defaults of a profile. show[kind]: "always", "profession", "tracking" or "never"
ns.defaults = {
	show = {
		herb = "profession", mine = "profession", fish = "profession", treasure = "always",
		gas = "profession", archaeology = "profession", logging = "tracking",
	},
	soundBoost = false,   -- effect sound on and at full volume while fishing (opt-in)
}

-- "Name-Realm" of the logged-in character
function ns.CharKey()
	return UnitName("player") .. "-" .. GetRealmName()
end

ns.OnLoad(function()
	ns.store = qnCore.Profiles.Register({
		ns = ns,
		sv = "qnGathererDB",
		settingsVersion = SETTINGS_VERSION,
		defaults = ns.defaults,
	})
	ns.DB.Init(ns.store.global)
	ns.Fishing.SoundOff()   -- sound values left over from a crash while fishing
end)
