-- qnMarkers: raid marker bar (world markers, target markers, ready check, pull timer).
-- Core: namespace, saved settings, applying, slash commands.

local ADDON, ns = ...

-- Version, Print and events (ns.events) come from qnCore.
local lib = qnCore
lib.NewAddon(ns, ADDON)
local L = ns.L

---------------------------------------------------------------------------
-- Defaults
---------------------------------------------------------------------------

ns.defaults = {
	shown = true,
	visibility = "always",     -- "always", "group" (party or raid), "raid"
	leaderOnly = false,        -- only as group leader or raid assistant
	locked = false,
	minimized = false,
	leftClick = "target",      -- left-click on a marker: "target" (target marker) or "world" (world marker)

	-- Buttons
	showReady = true,
	showPull5 = true,
	showPull10 = true,
	showClearWorld = true,
	showClearTarget = true,
	showLeave = false,
	tooltips = true,

	-- Appearance
	orientation = "horizontal",   -- "horizontal", "vertical"
	floating = false,             -- without background and border
	scale = 1,
	size = 28,                    -- button size
	gap = 2,                      -- spacing between buttons
	borderColor = { 0.22, 0.31, 0.40, 1 },
	bgColor = { 0.025, 0.033, 0.043, 0.92 },

	-- Position: TOPLEFT of the bar relative to TOPLEFT of UIParent, in UIParent units (independent
	-- of the scale); the grip stays in place when the bar is minimized
	autoVisible = false,          -- keep in the visible area automatically (with qnViewPort: on one monitor)
	x = 600,
	y = -150,

	hideRaidManager = false,      -- hide Blizzard's raid manager (RaidManager.lua)

	-- Markers above nameplates (Plates.lua)
	plates = {
		enabled = false,
		-- which units get a marker
		allies = true,             -- friendly players
		group = true,              -- group members
		enemies = false,           -- enemy players
		pvp = false,               -- players flagged for PvP
		npcs = false,
		pets = false,              -- pets of other players
		ownPet = false,
		arenaOnly = false,
		-- roles (only known for group members)
		tank = true,
		healer = true,
		dps = true,
		-- special icons
		friends = true,
		guild = true,
		-- look
		classColors = true,        -- role and texture icons in class color
		desaturate = true,
		enemyRed = true,           -- role and texture icons of enemies red
		distanceFade = false,      -- fade with the nameplate
		targetGlow = false,
		glowColor = { 1, 1, 1, 1 },
		texture = "arrow",         -- key in ns.TEXTURES
		customTexture = "",        -- file or atlas for texture = "custom"
		rotation = 0,
		petScale = 0.5,            -- size of other players' pets
		friendly = { icon = "class", fallback = "texture", size = 40, offsetX = 0, offsetY = 10,
			background = true, shape = "square", padding = 1, border = true },
		enemy = { icon = "class", fallback = "texture", size = 40, offsetX = 0, offsetY = 10,
			background = true, shape = "square", padding = 1, border = true },
	},
}

ns.VISIBILITY = { always = true, group = true, raid = true }
ns.LEFT_CLICK = { target = true, world = true }
ns.ORIENTATION = { horizontal = true, vertical = true }

-- Version of the settings (see qnCore.Migrate)
-- 1.1: markers above nameplates (plates)
-- 1.2: hide Blizzard's raid manager (hideRaidManager)
-- 1.3: mouse buttons of the markers (leftClick)
local SETTINGS_VERSION = "1.3"

-- Values of the wrong type fall back to their default (nil); tables with keys are checked inside,
-- color lists must be complete.
local function SanitizeTypes(t, defaults)
	for key, default in pairs(defaults) do
		local v = t[key]
		if v ~= nil then
			if type(v) ~= type(default) then
				t[key] = nil
			elseif type(default) == "table" then
				if default[1] ~= nil then
					if not lib.ValidColor(v) then
						t[key] = nil
					end
				else
					SanitizeTypes(v, default)
				end
			end
		end
	end
end

-- ns.TEXTURES and the choices come from Plates.lua (loaded before ADDON_LOADED)
local function SanitizePlates(p)
	local known = false
	for _, t in ipairs(ns.TEXTURES) do
		if t[1] == p.texture then
			known = true
		end
	end
	if p.texture ~= nil and not known then
		p.texture = nil
	end
	if p.rotation ~= nil then p.rotation = lib.Clamp(p.rotation, 0, 360) end
	if p.petScale ~= nil then p.petScale = lib.Clamp(p.petScale, 0.25, 1) end
	for _, side in ipairs({ p.friendly, p.enemy }) do
		if type(side) == "table" then
			if side.icon ~= nil and not ns.ICON_TYPES[side.icon] then side.icon = nil end
			if side.fallback ~= nil and not ns.FALLBACK_TYPES[side.fallback] then side.fallback = nil end
			if side.shape ~= nil and not ns.SHAPES[side.shape] then side.shape = nil end
			if side.size ~= nil then side.size = lib.Clamp(side.size, 16, 100) end
			if side.padding ~= nil then side.padding = lib.Clamp(side.padding, 0, 10) end
			if side.offsetX ~= nil then side.offsetX = lib.Clamp(side.offsetX, -100, 100) end
			if side.offsetY ~= nil then side.offsetY = lib.Clamp(side.offsetY, -100, 100) end
		end
	end
end

-- Check of a profile on every load: invalid values fall back to their default (nil).
local function Sanitize(db)
	SanitizeTypes(db, ns.defaults)
	if type(db.plates) == "table" then
		SanitizePlates(db.plates)
	end
	if db.visibility ~= nil and not ns.VISIBILITY[db.visibility] then
		db.visibility = nil
	end
	if db.leftClick ~= nil and not ns.LEFT_CLICK[db.leftClick] then
		db.leftClick = nil
	end
	if db.orientation ~= nil and not ns.ORIENTATION[db.orientation] then
		db.orientation = nil
	end
	if db.scale ~= nil then db.scale = lib.Clamp(db.scale, 0.5, 2) end
	if db.size ~= nil then db.size = lib.Clamp(db.size, 20, 42) end
	if db.gap ~= nil then db.gap = lib.Clamp(db.gap, 0, 8) end
end
ns.Sanitize = Sanitize

---------------------------------------------------------------------------
-- Applying
---------------------------------------------------------------------------

-- The bar holds secure buttons: layout, attributes and visibility can only change out of combat.
-- ns.Apply() therefore remembers the request and applies it after combat (qnCore.DeferInCombat).
local warned = false

local function ApplyAfterCombat()
	ns.Apply()
end

function ns.Apply()
	if not ns.bar then
		return
	end
	if lib.DeferInCombat(ApplyAfterCombat) then
		if not warned then
			warned = true
			ns.Print(L["The change will be applied after combat."])
		end
		ns.ApplyCosmetic()
		return
	end
	warned = false
	ns.ApplyAll()
	ns.ApplyRaidManager()
	ns.QueueVisibleCheck()
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

local function Show()
	ns.store:Set("shown", true)
end

local function Hide()
	ns.store:Set("shown", false)
	ns.Print(L["Bar hidden. To show it, type /qnmarkers show"])
end

lib.RegisterCommands(ns, "QNMARKERS", { "/qnmarkers", "/qnmk" }, {
	show = Show,
	hide = Hide,
	toggle = function()
		if ns.db.shown then Hide() else Show() end
	end,
	lock = function()
		ns.store:Set("locked", true)
		ns.Print(L["Position locked."])
	end,
	unlock = function()
		ns.store:Set("locked", false)
		ns.Print(L["Position unlocked. Drag the bar by its grip."])
	end,
	reset = function() ns.ResetPosition() end,
	visible = function() ns.MoveIntoVisible() end,
}, L["Commands:\n  /qnmarkers – open options\n  /qnmarkers show | hide | toggle – show/hide the bar\n  /qnmarkers lock | unlock – lock/unlock position\n  /qnmarkers reset – reset position\n  /qnmarkers visible – move bar into the visible area"])

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local events = ns.events

ns.OnLoad(function()
	-- Settings per profile (= Edit Mode layout, qnCore); ns.db is always the active profile.
	ns.store = lib.Profiles.Register({
		ns = ns,
		sv = "qnMarkersDB",
		settingsVersion = SETTINGS_VERSION,
		sanitize = Sanitize,
		onSwitch = function()
			ns.Apply()
			ns.ApplyPlates()
		end,
	})
	ns.CreateBar()
	ns.InitOptions()
end)

events.Register("PLAYER_LOGIN", function()
	ns.Apply()
end)

-- Group, leader or assistant changed: the option "only as leader or assistant" decides anew, and
-- world markers may have become available (out of combat only and without a message; the
-- visibility driver handles group and raid in combat too).
local GroupChanged
function GroupChanged()
	if not ns.bar or lib.DeferInCombat(GroupChanged) then
		return
	end
	ns.ApplyAll()
end
events.Register("GROUP_ROSTER_UPDATE", GroupChanged)
events.Register("PARTY_LEADER_CHANGED", GroupChanged)
