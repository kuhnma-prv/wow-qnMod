-- Scenario 1: qnNumKeyPad - layouts, size, action slots, page warnings, position,
-- drag area after combat, border of equipped items, hintShown account-wide.

-- State of Layouts.lua before the refactoring to shared building blocks (order = action slots).
local OLD_LAYOUTS = [==[
-- qnNumKeyPad: Tastaturlayouts.
--
-- row/col: Lage der Taste in Tastenbreiten, 1/1 = oben links im Ziffernblock.
-- Negative Spalten liegen links davon (Navigations- und Pfeilblock).
-- type: Numeric = immer sichtbar, Enter/Nav/Arrow = zuschaltbar.
-- Die Position einer Taste in der Liste bestimmt ihren Aktionsplatz;
-- deshalb darf die Reihenfolge nicht geändert werden.

local _, ns = ...

local function Numpad(extra)
	local keys = {
		{ row = 4, col = 1, type = "Numeric", label = "1", binding = "NUMPAD1" },
		{ row = 4, col = 2, type = "Numeric", label = "2", binding = "NUMPAD2" },
		{ row = 4, col = 3, type = "Numeric", label = "3", binding = "NUMPAD3" },
		{ row = 3, col = 1, type = "Numeric", label = "4", binding = "NUMPAD4" },
		{ row = 3, col = 2, type = "Numeric", label = "5", binding = "NUMPAD5" },
		{ row = 3, col = 3, type = "Numeric", label = "6", binding = "NUMPAD6" },
		{ row = 2, col = 1, type = "Numeric", label = "7", binding = "NUMPAD7" },
		{ row = 2, col = 2, type = "Numeric", label = "8", binding = "NUMPAD8" },
		{ row = 2, col = 3, type = "Numeric", label = "9", binding = "NUMPAD9" },
		{ row = 5, col = 1.5, type = "Numeric", label = "0", binding = "NUMPAD0" },
		{ row = 5, col = 3, type = "Numeric", label = ".", binding = "NUMPADDECIMAL" },
		{ row = 2.5, col = 4, type = "Numeric", label = "+", binding = "NUMPADPLUS" },
		{ row = 1, col = 4, type = "Numeric", label = "-", binding = "NUMPADMINUS" },
		{ row = 1, col = 3, type = "Numeric", label = "*", binding = "NUMPADMULTIPLY" },
		{ row = 1, col = 2, type = "Numeric", label = "/", binding = "NUMPADDIVIDE" },
		{ row = 4.5, col = 4, type = "Enter", label = "E", binding = "ENTER" },
	}
	for _, key in ipairs(extra) do
		keys[#keys + 1] = key
	end
	return keys
end

local ARROWS = {
	{ row = 4, col = 2 - 3.3, type = "Arrow", label = "^", binding = "UP" },
	{ row = 5, col = 1 - 3.3, type = "Arrow", label = "<", binding = "LEFT" },
	{ row = 5, col = 2 - 3.3, type = "Arrow", label = "v", binding = "DOWN" },
	{ row = 5, col = 3 - 3.3, type = "Arrow", label = ">", binding = "RIGHT" },
}

local ARROWS_LOW = {
	{ row = 4.3, col = 2 - 3.3, type = "Arrow", label = "^", binding = "UP" },
	{ row = 5.3, col = 1 - 3.3, type = "Arrow", label = "<", binding = "LEFT" },
	{ row = 5.3, col = 2 - 3.3, type = "Arrow", label = "v", binding = "DOWN" },
	{ row = 5.3, col = 3 - 3.3, type = "Arrow", label = ">", binding = "RIGHT" },
}

local function Join(...)
	local list = {}
	for i = 1, select("#", ...) do
		for _, key in ipairs((select(i, ...))) do
			list[#list + 1] = key
		end
	end
	return list
end

ns.LAYOUTS = {
	{
		id = "Windows", name = "Windows",
		keys = Numpad(Join({
			{ row = 1, col = 1 - 3.3, type = "Nav", label = "I", binding = "INSERT" },
			{ row = 1, col = 2 - 3.3, type = "Nav", label = "H", binding = "HOME" },
			{ row = 1, col = 3 - 3.3, type = "Nav", label = "P^", binding = "PAGEUP" },
			{ row = 2, col = 1 - 3.3, type = "Nav", label = "D", binding = "DELETE" },
			{ row = 2, col = 2 - 3.3, type = "Nav", label = "E", binding = "END" },
			{ row = 2, col = 3 - 3.3, type = "Nav", label = "Pv", binding = "PAGEDOWN" },
		}, ARROWS)),
	},
	{
		id = "MicrosoftOffice", name = "Microsoft Office",
		keys = Numpad(Join({
			{ row = 1, col = 2 - 3.3, type = "Nav", label = "H", binding = "HOME" },
			{ row = 1, col = 3 - 3.3, type = "Nav", label = "E", binding = "END" },
			{ row = 2, col = 3 - 3.3, type = "Nav", label = "P^", binding = "PAGEUP" },
			{ row = 2.5, col = 2 - 3.3, type = "Nav", label = "D", binding = "DELETE" },
			{ row = 3, col = 3 - 3.3, type = "Nav", label = "Pv", binding = "PAGEDOWN" },
			-- Zusatztaste der Office-Tastatur, liegt im Ziffernblock
			{ row = 1, col = 1, type = "Nav", label = "T", binding = "TAB" },
		}, ARROWS_LOW)),
	},
	{
		id = "NaturalMultimedia", name = "Natural Multimedia",
		keys = Numpad(Join({
			{ row = 1, col = 2 - 3.3, type = "Nav", label = "H", binding = "HOME" },
			{ row = 1, col = 3 - 3.3, type = "Nav", label = "E", binding = "END" },
			{ row = 2, col = 3 - 3.3, type = "Nav", label = "P^", binding = "PAGEUP" },
			{ row = 2.5, col = 2 - 3.3, type = "Nav", label = "D", binding = "DELETE" },
			{ row = 3, col = 3 - 3.3, type = "Nav", label = "Pv", binding = "PAGEDOWN" },
		}, ARROWS_LOW)),
	},
	{
		id = "NaturalElite", name = "Natural Elite",
		keys = Numpad({
			{ row = 1, col = 1 - 2.6, type = "Nav", label = "H", binding = "HOME" },
			{ row = 1, col = 2 - 2.6, type = "Nav", label = "P^", binding = "PAGEUP" },
			{ row = 2, col = 1 - 2.6, type = "Nav", label = "E", binding = "END" },
			{ row = 2, col = 2 - 2.6, type = "Nav", label = "Pv", binding = "PAGEDOWN" },
			{ row = 3, col = 1 - 2.6, type = "Nav", label = "D", binding = "DELETE" },
			{ row = 3, col = 2 - 2.6, type = "Nav", label = "I", binding = "INSERT" },
			{ row = 4.3, col = 2 - 3.1, type = "Arrow", label = "^", binding = "UP" },
			{ row = 4.8, col = 1 - 3.1, type = "Arrow", label = "<", binding = "LEFT" },
			{ row = 5.3, col = 2 - 3.1, type = "Arrow", label = "v", binding = "DOWN" },
			{ row = 4.8, col = 3 - 3.1, type = "Arrow", label = ">", binding = "RIGHT" },
		}),
	},
	{
		id = "Macintosh", name = "Macintosh",
		keys = Join({
			{ row = 4, col = 1, type = "Numeric", label = "1", binding = "NUMPAD1" },
			{ row = 4, col = 2, type = "Numeric", label = "2", binding = "NUMPAD2" },
			{ row = 4, col = 3, type = "Numeric", label = "3", binding = "NUMPAD3" },
			{ row = 3, col = 1, type = "Numeric", label = "4", binding = "NUMPAD4" },
			{ row = 3, col = 2, type = "Numeric", label = "5", binding = "NUMPAD5" },
			{ row = 3, col = 3, type = "Numeric", label = "6", binding = "NUMPAD6" },
			{ row = 2, col = 1, type = "Numeric", label = "7", binding = "NUMPAD7" },
			{ row = 2, col = 2, type = "Numeric", label = "8", binding = "NUMPAD8" },
			{ row = 2, col = 3, type = "Numeric", label = "9", binding = "NUMPAD9" },
			{ row = 5, col = 1.5, type = "Numeric", label = "0", binding = "NUMPAD0" },
			{ row = 5, col = 3, type = "Numeric", label = ".", binding = "NUMPADDECIMAL" },
			{ row = 3, col = 4, type = "Numeric", label = "+", binding = "NUMPADPLUS" },
			{ row = 2, col = 4, type = "Numeric", label = "-", binding = "NUMPADMINUS" },
			{ row = 1, col = 4, type = "Numeric", label = "*", binding = "NUMPADMULTIPLY" },
			{ row = 1, col = 3, type = "Numeric", label = "/", binding = "NUMPADDIVIDE" },
			-- Zusatztasten der Mac-Tastatur
			{ row = 1, col = 2, type = "Numeric", label = "=", binding = "NUMPADEQUALS" },
			{ row = 1, col = 1, type = "Numeric", label = "C", binding = "NUMLOCK" },
			{ row = 4.5, col = 4, type = "Enter", label = "E", binding = "ENTER" },
			{ row = 1, col = 1 - 3.3, type = "Nav", label = "H?", binding = "INSERT" },
			{ row = 1, col = 2 - 3.3, type = "Nav", label = "H", binding = "HOME" },
			{ row = 1, col = 3 - 3.3, type = "Nav", label = "P^", binding = "PAGEUP" },
			{ row = 2, col = 1 - 3.3, type = "Nav", label = "D", binding = "DELETE" },
			{ row = 2, col = 2 - 3.3, type = "Nav", label = "E", binding = "END" },
			{ row = 2, col = 3 - 3.3, type = "Nav", label = "Pv", binding = "PAGEDOWN" },
		}, ARROWS),
	},
	{
		id = "Naga", name = "Razer Naga",
		keys = Join({
			{ row = 4, col = 1, type = "Numeric", label = "7", binding = "NUMPAD7" },
			{ row = 4, col = 2, type = "Numeric", label = "8", binding = "NUMPAD8" },
			{ row = 4, col = 3, type = "Numeric", label = "9", binding = "NUMPAD9" },
			{ row = 3, col = 1, type = "Numeric", label = "4", binding = "NUMPAD4" },
			{ row = 3, col = 2, type = "Numeric", label = "5", binding = "NUMPAD5" },
			{ row = 3, col = 3, type = "Numeric", label = "6", binding = "NUMPAD6" },
			{ row = 2, col = 1, type = "Numeric", label = "1", binding = "NUMPAD1" },
			{ row = 2, col = 2, type = "Numeric", label = "2", binding = "NUMPAD2" },
			{ row = 2, col = 3, type = "Numeric", label = "3", binding = "NUMPAD3" },
			{ row = 5, col = 1, type = "Numeric", label = "10", binding = "NUMPAD0" },
			{ row = 5, col = 2, type = "Numeric", label = "11", binding = "NUMPADMINUS" },
			{ row = 5, col = 3, type = "Numeric", label = "12", binding = "NUMPADPLUS" },
			{ row = 1, col = 1 - 3.3, type = "Nav", label = "I", binding = "INSERT" },
			{ row = 1, col = 2 - 3.3, type = "Nav", label = "H", binding = "HOME" },
			{ row = 1, col = 3 - 3.3, type = "Nav", label = "P^", binding = "PAGEUP" },
			{ row = 2, col = 1 - 3.3, type = "Nav", label = "D", binding = "DELETE" },
			{ row = 2, col = 2 - 3.3, type = "Nav", label = "E", binding = "END" },
			{ row = 2, col = 3 - 3.3, type = "Nav", label = "Pv", binding = "PAGEDOWN" },
		}, ARROWS),
	},
}

ns.MAX_BUTTONS = 0
for _, layout in ipairs(ns.LAYOUTS) do
	ns.MAX_BUTTONS = math.max(ns.MAX_BUTTONS, #layout.keys)
end

function ns.GetLayout(id)
	for _, layout in ipairs(ns.LAYOUTS) do
		if layout.id == id then
			return layout
		end
	end
end
]==]

-- remember all frames (the drag area has no name)
local created = {}
local createFrame = CreateFrame
CreateFrame = function(...)
	local f = createFrame(...)
	created[#created + 1] = f
	return f
end
StaticPopup_StandardEditBoxOnEscapePressed = function(editBox) editBox:GetParent():Hide() end
SpellFlyout = CreateFrame("Frame", "SpellFlyout")
SpellFlyout:Hide()

-- Record chat output
local chat = {}
function DEFAULT_CHAT_FRAME:AddMessage(msg)
	chat[#chat + 1] = msg
	print("  [Chat] " .. tostring(msg):gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", ""))
end
local function Count(text)
	local n = 0
	for _, msg in ipairs(chat) do
		if msg:find(text, 1, true) then
			n = n + 1
		end
	end
	return n
end

-- Saved data in the current format: hint already shown (hintShown account-wide in global)
qnNumKeyPadProfiles = { settingsVersion = "1.0", global = { hintShown = true }, profiles = { ["account:Alt"] = { scale = 1 } } }

local core = LoadAddon("qnCore")
local nkp = LoadAddon("qnNumKeyPad")
local L = nkp.L

---------------------------------------------------------------------------
-- Layouts: new tables equal to the old ones field by field
---------------------------------------------------------------------------
local old = {}
assert(load(OLD_LAYOUTS, "=Layouts.old"))("qnNumKeyPad", old)
local same, why = #old.LAYOUTS == #nkp.LAYOUTS, "number of layouts"
for li, lay in ipairs(old.LAYOUTS) do
	local new = nkp.LAYOUTS[li]
	if not new or new.id ~= lay.id or new.name ~= lay.name or #new.keys ~= #lay.keys then
		same, why = false, "Layout " .. lay.id
	else
		for ki, key in ipairs(lay.keys) do
			local nk = new.keys[ki]
			for field, v in pairs(key) do
				if nk[field] ~= v then same, why = false, ("%s key %d field %s"):format(lay.id, ki, field) end
			end
			for field in pairs(nk) do
				if key[field] == nil then same, why = false, ("%s key %d extra field %s"):format(lay.id, ki, field) end
			end
		end
	end
end
Check(same, "layouts unchanged (order, position, type, label, binding): " .. why)
Check(nkp.MAX_BUTTONS == 28 and old.MAX_BUTTONS == 28, "28 keys at most")
Check(nkp.GetLayout("Macintosh").keys[19].label == "H?", "Mac label H? unchanged")

---------------------------------------------------------------------------
-- hintShown account-wide
---------------------------------------------------------------------------
Check(_G.qnNumKeyPad == nil and nkp.Slot == nil and nkp.settings == nil, "no global table, no ns.Slot, no ns.settings")
Check(StaticPopupDialogs.QNNUMKEYPAD_CUSTOM.EditBoxOnEscapePressed == StaticPopup_StandardEditBoxOnEscapePressed, "Escape in the edit box: Blizzard default")

-- Hint on login: once per account
local HINT = L["Left-click to drag the bar, right-click to open the options. Lock it with /qnnkp lock."]
local WARN_BLIZZ = L["Warning: page %d is also used by a visible Blizzard action bar."]
local WARN_MULTI = L["Warning: page %d is assigned to more than one key group."]
qnNumKeyPadProfiles.global.hintShown = nil
nkp.db.page1 = 1   -- page of the main bar: warning
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
Check(Count(HINT) == 1 and qnNumKeyPadProfiles.global.hintShown == true, "hint shown once, remembered account-wide")
Check(Count(WARN_BLIZZ:format(1)) == 1, "warning page 1 on login")
SetEditModeLayout(3)
SetEditModeLayout(4)
Check(nkp.db == qnNumKeyPadProfiles.profiles["char:Tester-Realm:Solo"], "profile switch to char layout")
Check(Count(WARN_BLIZZ:format(1)) == 1, "same warning not repeated after profile switch")
Check(Count(HINT) == 1, "hint not repeated")

---------------------------------------------------------------------------
-- Size by layout, action slots
---------------------------------------------------------------------------
local applies = 0
local applyAll = nkp.ApplyAll
nkp.ApplyAll = function(...)
	applies = applies + 1
	return applyAll(...)
end
local function Set(key, value)
	SETTINGS["QNNKP_" .. key:upper()]:SetValue(value)
end
local function Near(a, b)
	return math.abs(a - b) < 0.01
end

Set("page1", 13)
local bar = nkp.bar
local w, h = bar:GetSize()
Check(w == 191 and h == 237, ("Windows without extra keys: 4x5 keys (%s x %s)"):format(w, h))
Check(not qnNumKeyPadButton16:IsShown() and qnNumKeyPadButton15:IsShown(), "Enter key hidden, key 15 visible")
Set("showNav", true)
Set("showArrow", true)
w, h = bar:GetSize()
Check(Near(w, 342.8) and h == 237, ("wider with navigation and arrow keys (%s x %s)"):format(w, h))
Set("blockGap", 10)
Check(Near(bar:GetWidth(), 352.8), "gap to the extra block widened: " .. bar:GetWidth())
Set("blockGap", 0)
Set("padH", 5)
Check(Near(bar:GetWidth(), 342.8 + 3 * 4 + 3.3 * 4), "horizontal spacing: " .. bar:GetWidth())
Set("padH", 1)
Set("layout", "Macintosh")
Check(qnNumKeyPadButton28:IsShown() and not qnNumKeyPadButton18:IsShown(), "Mac: 28 keys, Enter hidden")

local function Own(i)
	return _G["qnNumKeyPadButton" .. i]:GetAttribute("qn-own")
end
Check(Own(1) == 145 and Own(12) == 156 and Own(13) == 157 and Own(24) == 168 and Own(25) == 169 and Own(28) == 172,
	"slots: pages 13/14/15 with 12 keys each")
Set("page1", 3)
Set("page3", 6)
Check(Own(1) == 25 and Own(12) == 36 and Own(13) == 157 and Own(25) == 61 and Own(28) == 64, "slots after page change")

---------------------------------------------------------------------------
-- Page warnings
---------------------------------------------------------------------------
-- without modifier sets (they would add pages 15 and 2; scenario 6 checks them)
Set("ctrlSet", false)
Set("altSet", false)
Set("page1", 13)
Set("page3", 15)
Set("layout", "Windows")
Set("showNav", false)
Set("showArrow", false)
chat = {}
local mb6 = CreateFrame("Frame", "MultiBar6")   -- Blizzard bar on page 14
Set("showEnter", true)
Check(Count(WARN_BLIZZ:format(14)) == 1, "Enter key on: pages checked again, Blizzard bar on page 14")
Set("showNav", true)
Check(Count(WARN_BLIZZ:format(14)) == 1, "same warning not repeated")
Set("page1", 14)
Check(Count(WARN_MULTI:format(14)) == 1 and Count(WARN_BLIZZ:format(14)) == 2, "two groups on page 14: one warning each")
chat = {}
Set("showArrow", true)   -- keys 25/26 now use page 3 (15)
Check(#chat == 0, "unchanged warnings not repeated")
mb6:Hide()
Set("page3", 14)
Check(Count(WARN_MULTI:format(14)) == 1 and Count(WARN_BLIZZ:format(14)) == 0, "three groups on page 14: only one warning")
mb6:Show()
Set("page1", 13)
Set("page3", 13)
Set("showArrow", false)
chat = {}
Set("showArrow", true)
Check(Count(WARN_MULTI:format(13)) == 1, "arrow keys on: group 3 shares page 13 with group 1")
chat = {}
Set("layout", "Naga")
Check(Count(WARN_MULTI:format(13)) == 0 and Count(WARN_BLIZZ:format(14)) == 1, "layout change checks again (Naga does not use group 3)")
chat = {}
QN_COMBAT = true
Set("layout", "Windows")
Check(Count(WARN_MULTI:format(13)) == 1, "check reads the settings, also in combat")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
mb6:Hide()
Set("page3", 15)
Set("showNav", false)
Set("showArrow", false)
Set("showEnter", false)

---------------------------------------------------------------------------
-- Position: SavePosition (anchor change), CenterBar, ResetPosition - one Apply each
---------------------------------------------------------------------------
bar.GetLeft = function() return 100 end
bar.GetBottom = function() return 200 end
applies = 0
Set("point", "TOPLEFT")
Check(nkp.db.x == 100 and nkp.db.y == -643 and applies == 1, ("TOPLEFT: x/y converted (%s, %s), %d Apply"):format(nkp.db.x, nkp.db.y, applies))
Check(SETTINGS.QNNKP_X:GetValue() == 100 and SETTINGS.QNNKP_Y:GetValue() == -643, "settings window shows new values")
Set("point", "BOTTOMRIGHT")
Check(nkp.db.x == -1629 and nkp.db.y == 200, ("BOTTOMRIGHT: (%s, %s)"):format(nkp.db.x, nkp.db.y))
Set("point", "TOPLEFT")
nkp.CenterBar(true)
Check(nkp.db.x == 865 and nkp.db.y == -643, "centered horizontally (TOPLEFT): " .. nkp.db.x)
Set("point", "CENTER")
nkp.CenterBar(false)
Check(nkp.db.y == 0, "centered vertically (CENTER): " .. nkp.db.y)
applies = 0
nkp.ResetPosition()
Check(nkp.db.point == "CENTER" and nkp.db.x == 300 and nkp.db.y == -100 and applies == 1, "reset with one Apply: " .. applies)
Check(SETTINGS.QNNKP_POINT:GetValue() == "CENTER" and SETTINGS.QNNKP_X:GetValue() == 300, "settings window after reset")

---------------------------------------------------------------------------
-- Drag area after combat
---------------------------------------------------------------------------
local overlay
for _, f in ipairs(created) do
	if f:GetParent() == bar and f:GetScript("OnDragStart") then
		overlay = f
	end
end
Check(overlay ~= nil, "drag area found")
Set("locked", false)
Check(overlay:IsShown(), "unlocked: drag area visible")
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
Check(not overlay:IsShown(), "hidden in combat")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Check(overlay:IsShown(), "visible again after combat (without deferred change)")
QN_COMBAT = true
FireEvent("PLAYER_REGEN_DISABLED")
Set("scale", 1.2)   -- deferred
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Check(overlay:IsShown(), "visible again after combat (with deferred change)")
-- Drag: save position
applies = 0
overlay:GetScript("OnDragStop")()
Check(nkp.db.x == math.floor(100 + 95.5 - 960 + 0.5) and applies == 1, "saved after dragging: " .. nkp.db.x)
Set("locked", true)
Check(not overlay:IsShown(), "locked: drag area hidden")

---------------------------------------------------------------------------
-- Border of equipped items
---------------------------------------------------------------------------
C_ActionBar.IsEquippedAction = function(action) return action == 145 end
local b1 = qnNumKeyPadButton1
b1.action = 145
nkp.ApplyCosmetic()
Check(b1.Border:IsShown(), "equipped: border visible")
Set("hideBorder", true)
Check(not b1.Border:IsShown(), "border hidden")
Set("hideBorder", false)
Check(b1.Border:IsShown(), "border visible again after switching back")
Check(not qnNumKeyPadButton2.Border:IsShown(), "not equipped: no border")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
