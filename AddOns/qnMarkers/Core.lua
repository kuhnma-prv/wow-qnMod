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
}

ns.VISIBILITY = { always = true, group = true, raid = true }
ns.ORIENTATION = { horizontal = true, vertical = true }

-- Version of the settings (see qnCore.Migrate)
local SETTINGS_VERSION = "1.0"

-- Check of a profile on every load: invalid values fall back to their default (nil).
local function Sanitize(db)
	for key, default in pairs(ns.defaults) do
		local v = db[key]
		if v ~= nil and type(v) ~= type(default) then
			db[key] = nil
		end
	end
	if db.visibility ~= nil and not ns.VISIBILITY[db.visibility] then
		db.visibility = nil
	end
	if db.orientation ~= nil and not ns.ORIENTATION[db.orientation] then
		db.orientation = nil
	end
	if db.scale ~= nil then db.scale = lib.Clamp(db.scale, 0.5, 2) end
	if db.size ~= nil then db.size = lib.Clamp(db.size, 20, 42) end
	if db.gap ~= nil then db.gap = lib.Clamp(db.gap, 0, 8) end
	for _, key in ipairs({ "borderColor", "bgColor" }) do
		if db[key] ~= nil and not lib.ValidColor(db[key]) then
			db[key] = nil
		end
	end
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
		onSwitch = ns.Apply,
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
