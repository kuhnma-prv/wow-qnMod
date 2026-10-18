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

-- Defaults of a profile.
-- Visibility modes ("show", "circle.show"): "always", "profession", "tracking" or "never"
ns.defaults = {
	show = {
		herb = "profession", mine = "profession", fish = "profession", treasure = "always",
		gas = "profession", archaeology = "profession", logging = "tracking",
	},
	worldMap = { show = true, clickable = true, scale = 1, alpha = 1, areas = false },
	minimap = { show = true, tooltips = true, edge = true, scale = 0.75, alpha = 1 },
	circle = { show = "always", distance = 100, colors = {} },   -- tracking circle; colors[kind] = { r, g, b, a }
	filter = {},                                                 -- filter[kind][res] = false: hidden
	origins = { guild = true, import = true },                   -- show nodes found by the guild / imported
	soundBoost = false,   -- effect sound on and at full volume while fishing (opt-in)
}

-- "Name-Realm" of the logged-in character
function ns.CharKey()
	return UnitName("player") .. "-" .. GetRealmName()
end

ns.OnLoad(function()
	for key, kind in pairs(ns.KINDS) do   -- Kinds.lua is loaded after this file
		ns.defaults.circle.colors[key] = kind.color
	end
	ns.store = qnCore.Profiles.Register({
		ns = ns,
		sv = "qnGathererDB",
		settingsVersion = SETTINGS_VERSION,
		defaults = ns.defaults,
		onSwitch = function()
			ns.Display.Refresh()
		end,
	})
	ns.DB.Init(ns.store.global)
	ns.Fishing.SoundOff()   -- sound values left over from a crash while fishing
	ns.Display.Init()
	ns.Minimap.Init()
	-- the world map may be loaded on demand: add the pins as soon as it exists
	if WorldMapFrame then
		ns.WorldMap.Init()
	else
		ns.events.Register("ADDON_LOADED", function(_, name)
			if name == "Blizzard_WorldMap" and WorldMapFrame and not ns.WorldMap.provider:GetMap() then
				ns.WorldMap.Init()
			end
		end)
	end
end)
