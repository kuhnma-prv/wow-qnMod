-- qnUnitFrames: click casting on Blizzard's party and raid frames (like HealBot).
-- Core: namespace, saved settings, binding data, slash commands, events.
--
-- A binding is modifier + mouse button, e.g. "shift-1" (Shift + left click). The keys
-- follow Blizzard's attribute names (SecureTemplates.lua: prefix "alt-ctrl-shift-", buttons 1–5), so that
-- Clicks.lua can set them directly as attributes ("shift-type1", "shift-spell1").
-- The bindings are stored in the profile (= Edit Mode layout) and within it per class:
--   db.bindings[class][key] = { type = "spell", value = "Flash Heal" }

local ADDON, ns = ...

local lib = qnCore
lib.NewAddon(ns, ADDON)
local L = ns.L

---------------------------------------------------------------------------
-- Defaults
---------------------------------------------------------------------------

ns.defaults = {
	enabled = true,
	raidStyle = true,     -- raid-style frames (party and raid, CompactUnitFrame)
	party = true,         -- classic party frames (PartyFrame)
	pets = true,          -- party pet frames
	tooltip = true,       -- show bindings in the frames' tooltip
	bindings = {},        -- [class] = { [key] = { type, value } }
}

---------------------------------------------------------------------------
-- Buttons and actions
---------------------------------------------------------------------------

-- Mouse buttons: number as in SecureButton_GetButtonSuffix
ns.BUTTONS = {
	{ "1", KEY_BUTTON1 },
	{ "2", KEY_BUTTON2 },
	{ "3", KEY_BUTTON3 },
	{ "4", KEY_BUTTON4 },
	{ "5", KEY_BUTTON5 },
}

-- Modifiers in the order of SecureButton_GetModifierPrefix (alt before ctrl before shift)
ns.MODIFIERS = { "", "shift-", "ctrl-", "alt-", "ctrl-shift-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }

local MODIFIER_TEXT = { alt = ALT_KEY_TEXT, ctrl = CTRL_KEY_TEXT, shift = SHIFT_KEY_TEXT }

-- "alt-shift-" → "ALT+SHIFT"; without modifier a text of its own
function ns.ModifierText(prefix)
	if prefix == "" then
		return L["No modifier"]
	end
	local parts = {}
	for mod in prefix:gmatch("(%a+)%-") do
		parts[#parts + 1] = MODIFIER_TEXT[mod] or mod
	end
	return table.concat(parts, "+")
end

-- Short form for tooltips: "SHIFT+Left Mouse Button"
function ns.BindingText(key)
	local prefix, button = key:match("^(.-)(%d)$")
	local buttonText = KEY_BUTTON1
	for _, b in ipairs(ns.BUTTONS) do
		if b[1] == button then
			buttonText = b[2]
		end
	end
	if prefix == "" then
		return buttonText
	end
	return ns.ModifierText(prefix) .. "+" .. buttonText
end

-- Actions; "" = set nothing, Blizzard's behavior stays (left click: target, right click: menu).
-- value: "spell" = spell name, "macro" = macro text
ns.TYPES = {
	{ "", L["Blizzard default"] },
	{ "spell", L["Spell"] },
	{ "macro", MACRO },
	{ "target", TARGET },
	{ "menu", FRAME_ACTION_MENU },
	{ "focus", SET_FOCUS },
	{ "assist", L["Assist"] },
}
local KNOWN_TYPE = {}
for _, t in ipairs(ns.TYPES) do
	KNOWN_TYPE[t[1]] = t[2]
end

function ns.TypeText(kind)
	return KNOWN_TYPE[kind] or kind
end

-- valid keys: every modifier with every mouse button ("", "shift-" … × "1" … "5")
local VALID_KEY = {}
for _, prefix in ipairs(ns.MODIFIERS) do
	for _, b in ipairs(ns.BUTTONS) do
		VALID_KEY[prefix .. b[1]] = true
	end
end

-- Class of the player ("PRIEST"); the bindings apply per class. Read only when needed and only
-- a readable value is remembered (UnitClass is SecretWhenUnitIdentityRestricted).
local function ClassKey()
	if not ns.class then
		ns.class = lib.Plain(select(2, UnitClass("player")), nil)
	end
	return ns.class or "?"
end

-- Bindings of the player's class in the active profile
function ns.Bindings()
	local all = ns.db.bindings
	local class = ClassKey()
	local list = all[class]
	if not list then
		list = {}
		all[class] = list
	end
	return list
end

-- Sets or clears (kind "" or nil) a binding of the player's class and applies it.
function ns.SetBinding(key, kind, value)
	local list = ns.Bindings()
	if not kind or kind == "" then
		list[key] = nil
	else
		list[key] = { type = kind, value = value }
	end
	ns.ApplyChange()   -- Clicks.lua
end

-- Version of the settings (see qnCore.Migrate)
local SETTINGS_VERSION = "1.0"

-- Check of a profile on every load: removes broken entries (unknown action, wrong key).
local function Sanitize(db)
	if type(db.bindings) ~= "table" then
		db.bindings = nil
		return
	end
	for class, list in pairs(db.bindings) do
		if type(list) ~= "table" then
			db.bindings[class] = nil
		else
			for key, entry in pairs(list) do
				local valid = VALID_KEY[key] and type(entry) == "table"
					and type(entry.type) == "string" and entry.type ~= "" and KNOWN_TYPE[entry.type]
				if not valid then
					list[key] = nil
				elseif entry.value ~= nil and type(entry.value) ~= "string" then
					entry.value = tostring(entry.value)
				end
			end
		end
	end
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

lib.RegisterSlash("QNUNITFRAMES", { "/qnunitframes", "/qnuf" }, function(cmd)
	if cmd == "" or cmd == "config" or cmd == "options" then
		ns.OpenOptions()
	elseif cmd == "clicks" then
		ns.OpenClicksPage()
	elseif cmd == "on" then
		ns.store:Set("enabled", true)
	elseif cmd == "off" then
		ns.store:Set("enabled", false)
		ns.Print(L["Click casting turned off. Turn it on with /qnuf on"])
	else
		ns.Print(L["Commands:\n  /qnuf – open options\n  /qnuf clicks – edit click bindings\n  /qnuf on | off – turn click casting on/off"])
	end
end)

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

ns.OnLoad(function()
	ns.store = lib.Profiles.Register({
		ns = ns,
		sv = "qnUnitFramesDB",
		settingsVersion = SETTINGS_VERSION,
		defaults = ns.defaults,
		sanitize = Sanitize,
		onSwitch = function()
			ns.Apply()
			ns.RefreshClicksPage()
		end,
	})
	ns.InitClicks()
	ns.InitOptions()
end)

ns.events.Register("PLAYER_LOGIN", function()
	ns.Apply()
end)
