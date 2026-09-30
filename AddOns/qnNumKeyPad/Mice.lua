-- qnNumKeyPad: gaming mice whose buttons send numeric keypad keys.
--
-- The assignment mirrors the mouse software (e.g. Logitech G HUB) and therefore applies
-- account-wide (qnNumKeyPadProfiles.global), not per Edit Mode layout:
--   global.mouse        id of the selected mouse, "NONE" = no mouse
--   global.mice[id]     { [button] = binding } - "" = no key; a missing entry means the default

local _, ns = ...
local L = ns.L

ns.MOUSE_NONE = "NONE"

-- Keys of the numeric keypad a mouse button can send (binding names)
ns.NUMPAD_KEYS = {
	"NUMPAD1", "NUMPAD2", "NUMPAD3", "NUMPAD4", "NUMPAD5", "NUMPAD6", "NUMPAD7", "NUMPAD8", "NUMPAD9", "NUMPAD0",
	"NUMPADDECIMAL", "NUMPADPLUS", "NUMPADMINUS", "NUMPADMULTIPLY", "NUMPADDIVIDE",
}

-- buttons: { id, key = default binding } or { id, fixed = text } for buttons that cannot be reassigned
ns.MICE = {
	{
		id = "G502", name = "Logitech G502",
		buttons = {
			{ id = "G1", fixed = L["Left click"] },
			{ id = "G2", fixed = L["Right click"] },
			{ id = "G3", key = "NUMPAD3" },
			{ id = "G4", key = "NUMPAD7" },
			{ id = "G5", key = "NUMPAD8" },
			{ id = "G6", key = "NUMPAD9" },
			{ id = "G7", key = "NUMPAD5" },
			{ id = "G8", key = "NUMPAD4" },
			{ id = "G9", key = "NUMPAD6" },
			{ id = "G10", key = "NUMPAD2" },
			{ id = "G11", key = "NUMPAD1" },
		},
	},
}

function ns.GetMouse(id)
	for _, mouse in ipairs(ns.MICE) do
		if mouse.id == id then
			return mouse
		end
	end
end

-- Default assignment of a mouse: { [button] = binding } (without the fixed buttons)
function ns.MouseDefaults(mouse)
	local defaults = {}
	for _, button in ipairs(mouse.buttons) do
		if button.key then
			defaults[button.id] = button.key
		end
	end
	return defaults
end

-- Stored assignment of mouse id (created on demand)
function ns.MouseButtons(id)
	local global = ns.store.global
	global.mice = global.mice or {}
	global.mice[id] = global.mice[id] or {}
	return global.mice[id]
end

-- Binding of a button: the stored one, otherwise the default; nil for fixed buttons and "no key".
function ns.MouseBinding(mouse, button)
	for _, b in ipairs(mouse.buttons) do
		if b.id == button then
			if b.fixed then
				return nil
			end
			local key = ns.MouseButtons(mouse.id)[button]
			if key == nil then
				key = b.key
			end
			return key ~= "" and key or nil
		end
	end
end

local function IsNumpadKey(key)
	for _, k in ipairs(ns.NUMPAD_KEYS) do
		if k == key then
			return true
		end
	end
	return false
end

-- Check of the account-wide mouse settings on every load: unknown mouse -> none,
-- unknown buttons or keys are dropped (the default applies again).
function ns.SanitizeMice(global)
	if global.mouse ~= nil and not ns.GetMouse(global.mouse) then
		global.mouse = nil
	end
	global.mouse = global.mouse or ns.MOUSE_NONE
	if type(global.mice) ~= "table" then
		global.mice = nil
		return
	end
	for id, buttons in pairs(global.mice) do
		local mouse = ns.GetMouse(id)
		if not mouse or type(buttons) ~= "table" then
			global.mice[id] = nil
		else
			local defaults = ns.MouseDefaults(mouse)
			for button, key in pairs(buttons) do
				if not defaults[button] or (key ~= "" and not IsNumpadKey(key)) then
					buttons[button] = nil
				end
			end
		end
	end
end
