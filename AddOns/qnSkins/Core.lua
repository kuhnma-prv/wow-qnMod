-- qnSkins: decorative artwork around UI elements (Blizzard's or other addons'),
-- optionally with a predefined position and scale of the elements themselves.
-- Core: namespace, saved settings, slash commands.

local ADDON, ns = ...
_G.qnSkins = ns

local lib = qnCore
lib.NewAddon(ns, ADDON)
local L = ns.L

---------------------------------------------------------------------------
-- Defaults (per profile = Edit Mode layout: positions belong to the layout)
---------------------------------------------------------------------------

ns.NONE = "none"

ns.defaults = {
	skin = ns.NONE,       -- key in ns.skins
	position = false,     -- opt-in: move and scale the elements to the skin's positions and keep them there
	monitor = 0,          -- 0 = automatic (monitor with the 3D view), otherwise number of the monitor from the left
	scale = 1,            -- scale of the whole skin (elements and artwork)
	offsetX = 0,          -- shift of the whole skin in UI units
	offsetY = 0,
	pauseInCombat = true, -- 3D figures stand still in combat
}

---------------------------------------------------------------------------
-- Loading
---------------------------------------------------------------------------

-- Version of the settings (see qnCore.Migrate)
local SETTINGS_VERSION = "1.4"   -- 1.1: pauseInCombat, 1.2: figure settings (fig_*), 1.3: figure areas, 1.4: dragon dropped

-- Keys of a profile dropped without replacement
local OBSOLETE = {}
for _, prop in ipairs({ "zoom", "side", "height", "rotation", "animation", "areaBottom", "areaTop" }) do
	OBSOLETE[#OBSOLETE + 1] = "fig_dragonlair_dragon_" .. prop   -- the dragon of the skin Dragon's Lair
end

-- repairs invalid values (nil brings back the default)
local function Sanitize(db)
	if db.skin ~= ns.NONE and not (ns.skins and ns.skins[db.skin]) then
		db.skin = nil
	end
	if type(db.scale) ~= "number" or db.scale < 0.5 or db.scale > 2 then
		db.scale = nil
	end
end

-- Apply the settings (debounced: several changes in a row are merged)
ns.Refresh = lib.Debounce(function()
	ns.Layout.Refresh()
end)

ns.OnLoad(function()
	ns.store = lib.Profiles.Register({
		ns = ns,
		sv = "qnSkinsDB",
		settingsVersion = SETTINGS_VERSION,
		defaults = ns.defaults,
		obsolete = OBSOLETE,
		sanitize = Sanitize,
		onSwitch = function()
			ns.Refresh()
			ns.Art.UpdatePaused()
		end,
	})
	ns.Art.Init()
	ns.Layout.Init()
	ns.InitOptions()
end)

-- Skins for the dropdown: { key, name } sorted by order, "none" first
function ns.SkinEntries()
	local list = {}
	for key, skin in pairs(ns.skins) do
		list[#list + 1] = { key, skin.name, skin.order or 99 }
	end
	table.sort(list, function(a, b)
		if a[3] ~= b[3] then
			return a[3] < b[3]
		end
		return a[1] < b[1]
	end)
	table.insert(list, 1, { ns.NONE, L["None"] })
	return list
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

lib.RegisterSlash("QNSKINS", { "/qnskins" }, function(cmd, rest)
	if cmd == "" or cmd == "config" or cmd == "options" then
		ns.OpenOptions()
	elseif cmd == "apply" then
		ns.Layout.Refresh()
		ns.Print(L["Skin applied."])
	elseif cmd == "list" then
		for _, entry in ipairs(ns.SkinEntries()) do
			ns.Print("%s%s – %s", entry[1] == ns.db.skin and "> " or "  ", entry[1], entry[2])   -- do not translate
		end
	elseif cmd == "frames" then
		ns.Layout.Report()
		ns.Art.Report()
	elseif cmd == "camera" then
		-- tuning figures: /qnskins camera <art> <zoom> [sideways] [height]
		local key, zoom, side, height = rest:match("^(%S+)%s+(%S+)%s*(%S*)%s*(%S*)")
		if not key or not ns.Art.TryCamera(key, tonumber(zoom), tonumber(side), tonumber(height)) then
			ns.Print(L["Usage: /qnskins camera <artwork> <zoom> [sideways] [height]"])
		end
	elseif cmd == "model" then
		-- trying out figures: /qnskins model <art> <creatureID | d:displayID> [animation] [rotation]
		local key, id, anim, rot = rest:match("^(%S+)%s+(%S+)%s*(%S*)%s*(%S*)")
		if not key or not ns.Art.TryModel(key, id, tonumber(anim), tonumber(rot)) then
			ns.Print(L["Usage: /qnskins model <artwork> <creature ID | d:display ID> [animation] [rotation]"])
		end
	else
		ns.Print(L["Commands: /qnskins [config | apply | list | frames | model | camera]\n  config – open options    apply – apply the skin again\n  list – list the skins    frames – list elements and figures\n  model <artwork> <creature ID | d:display ID> [animation] [rotation] – try out a figure until the next reload\n  camera <artwork> <zoom> [sideways] [height] – zoom and move a figure (also on the page Figures)"])
	end
end)
