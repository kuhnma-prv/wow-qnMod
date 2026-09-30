-- qnNumKeyPad: action bar in the shape of a numeric keypad.
-- Core: namespace, saved settings, events, slash commands.

local ADDON, ns = ...

-- Version, Print and events (ns.events) come from qnCore.
local lib = qnCore
lib.NewAddon(ns, ADDON)
local L = ns.L

-- global API for other qn addons (qnLoadout): SlotOfBinding, SlotContent, SetSlotSpell, SetSlotMacro, ClearSlot
_G.qnNumKeyPad = ns

---------------------------------------------------------------------------
-- Defaults
---------------------------------------------------------------------------

ns.defaults = {
	enabled = true,
	locked = false,          -- position locked
	lockActions = false,     -- always lock actions against dragging out
	lockInCombat = true,     -- lock actions against dragging out in combat

	-- Keyboard
	layout = "Windows",
	showEnter = false,
	showNav = false,
	showArrow = false,
	bindShift = true,        -- also bind Shift+key
	stance = false,          -- keys 1-12 follow the stance/form bar

	-- Action slots: page (12 slots each) for keys 1-12, 13-24, 25-28
	page1 = 13,
	page2 = 14,
	page3 = 15,
	-- Modifier sets: while Ctrl or Alt is held, keys 1-12 show and trigger this page
	ctrlSet = true,
	ctrlPage = 15,
	altSet = false,          -- switched off for now (Sanitize)
	altPage = 2,

	-- Appearance
	scale = 1,
	padH = 1,                -- horizontal spacing between keys
	padV = 1,                -- vertical spacing between keys
	blockGap = 0,            -- additional gap to the navigation/arrow block
	alpha = 1,
	bgAlpha = 0,
	labels = 1,              -- 1 = short label, 2 = key name, 3 = none
	fontSize = 0,            -- 0 = default size
	hideMacro = false,
	hideBorder = false,
	zoom = false,
	showGrid = true,         -- show empty buttons
	clickThrough = false,
	flyout = "UP",

	-- Visibility
	fade = false,
	fadeAlpha = 0.25,
	fadeDelay = 0.2,
	hideCombat = false,
	hideNoCombat = false,
	hideVehicle = true,
	hidePet = false,
	hideNoPet = false,
	hideStealth = false,
	hideForm = false,
	useCustom = false,
	custom = "[combat] show; [mod:alt] show; hide",

	-- Position (UIParent units, independent of the scale)
	autoVisible = false,     -- keep in the visible area automatically (with qnViewPort: on one monitor)
	point = "CENTER",
	x = 300,
	y = -100,
}

-- Version of the settings (see qnCore.Migrate)
-- 1.1: account-wide mouse button assignment (global.mouse, global.mice; Mice.lua)
-- 1.2: modifier sets (ctrlSet, ctrlPage, altSet, altPage)
local SETTINGS_VERSION = "1.2"

-- Check of a profile on every load: an unknown key layout falls back to the default.
-- Switched off for now: the arrow keys (page 15 belongs to the Ctrl set) and the Alt set.
local function Sanitize(db)
	if db.layout ~= nil and not ns.GetLayout(db.layout) then
		db.layout = nil
	end
	db.showArrow = nil
	db.altSet = nil
end

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

-- Changes to protected frames are blocked in combat.
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

-- After changes that affect the pages in use (pages, layout, extra keys, profile).
function ns.ApplyAndCheck()
	ns.Apply()
	ns.CheckPages()
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

lib.RegisterSlash("QNNUMKEYPAD", { "/qnnumkeypad", "/qnnkp", "/numpad" }, function(cmd)
	if cmd == "" or cmd == "config" or cmd == "options" then
		ns.OpenOptions()
	elseif cmd == "lock" then
		ns.store:Set("locked", true)
		ns.Print(L["Position locked."])
	elseif cmd == "unlock" then
		ns.store:Set("locked", false)
		ns.Print(L["Position unlocked. Left-click to drag, right-click to open the options."])
	elseif cmd == "on" or cmd == "show" then
		ns.store:Set("enabled", true)
	elseif cmd == "off" or cmd == "hide" then
		ns.store:Set("enabled", false)
		ns.Print(L["Disabled. To enable it, type /qnnkp on"])
	elseif cmd == "reset" then
		ns.ResetPosition()
	elseif cmd == "visible" then
		ns.MoveIntoVisible()
	else
		-- one key; Print outputs each line as a separate chat line
		ns.Print(L["Commands:\n  /qnnkp – open options\n  /qnnkp lock | unlock – lock/unlock position\n  /qnnkp on | off – enable/disable numpad\n  /qnnkp reset – reset position\n  /qnnkp visible – move bar into the visible area"])
	end
end)

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

local events = ns.events

ns.OnLoad(function()
	-- Settings per profile (= Edit Mode layout, qnCore); ns.db is always the active profile.
	ns.store = lib.Profiles.Register({
		ns = ns,
		sv = "qnNumKeyPadProfiles",
		settingsVersion = SETTINGS_VERSION,
		defaults = ns.defaults,
		sanitize = Sanitize,
		onSwitch = ns.ApplyAndCheck,
	})
	ns.SanitizeMice(ns.store.global)
	ns.CreateBar()
	ns.InitOptions()
end)

events.Register("PLAYER_LOGIN", function()
	ns.ApplyAndCheck()
	local global = ns.store.global
	if not ns.db.locked and not global.hintShown then
		global.hintShown = true
		ns.Print(L["Left-click to drag the bar, right-click to open the options. Lock it with /qnnkp lock."])
	end
end)

-- After combat, refresh the display (the drag area was hidden in combat); deferred work is
-- applied by qnCore.DeferInCombat.
events.Register("PLAYER_REGEN_ENABLED", function()
	ns.ApplyCosmetic()   -- Bar.lua
end)
