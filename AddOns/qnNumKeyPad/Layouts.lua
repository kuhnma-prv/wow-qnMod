-- qnNumKeyPad: keyboard layouts.
--
-- row/col: key position in key widths, 1/1 = top left of the numeric keypad.
-- Negative columns lie to the left of it (navigation and arrow block).
-- type: Numeric = always visible, Enter/Nav/Arrow = optional.
-- A key's position in the list determines its action slot;
-- therefore the order must not change (scenario qnNumKeyPad/test1 compares against the old state).

local _, ns = ...

-- Keys of one type from { row, col, label, binding }; shift moves the block that many
-- key widths to the left (extra blocks left of the numeric keypad).
local function Keys(kind, shift, list)
	local keys = {}
	for i, k in ipairs(list) do
		keys[i] = { row = k[1], col = k[2] - shift, type = kind, label = k[3], binding = k[4] }
	end
	return keys
end

-- Concatenates several key lists.
local function Join(...)
	local list = {}
	for i = 1, select("#", ...) do
		for _, key in ipairs((select(i, ...))) do
			list[#list + 1] = key
		end
	end
	return list
end

-- Digits 1-9, 0 and decimal point in the usual arrangement (1 bottom left)
local function Digits()
	return Keys("Numeric", 0, {
		{ 4, 1, "1", "NUMPAD1" }, { 4, 2, "2", "NUMPAD2" }, { 4, 3, "3", "NUMPAD3" },
		{ 3, 1, "4", "NUMPAD4" }, { 3, 2, "5", "NUMPAD5" }, { 3, 3, "6", "NUMPAD6" },
		{ 2, 1, "7", "NUMPAD7" }, { 2, 2, "8", "NUMPAD8" }, { 2, 3, "9", "NUMPAD9" },
		{ 5, 1.5, "0", "NUMPAD0" }, { 5, 3, ".", "NUMPADDECIMAL" },
	})
end

-- Operators (Windows arrangement: tall + in the right column)
local function Operators()
	return Keys("Numeric", 0, {
		{ 2.5, 4, "+", "NUMPADPLUS" }, { 1, 4, "-", "NUMPADMINUS" },
		{ 1, 3, "*", "NUMPADMULTIPLY" }, { 1, 2, "/", "NUMPADDIVIDE" },
	})
end

local function Enter()
	return Keys("Enter", 0, { { 4.5, 4, "E", "ENTER" } })
end

-- Six-key block above the arrow keys (Insert, Home, Page Up / Delete, End, Page Down)
local function Nav6(insertLabel)
	return Keys("Nav", 3.3, {
		{ 1, 1, insertLabel, "INSERT" }, { 1, 2, "H", "HOME" }, { 1, 3, "P^", "PAGEUP" },
		{ 2, 1, "D", "DELETE" }, { 2, 2, "E", "END" }, { 2, 3, "Pv", "PAGEDOWN" },
	})
end

-- Five-key block of Microsoft keyboards
local function Nav5()
	return Keys("Nav", 3.3, {
		{ 1, 2, "H", "HOME" }, { 1, 3, "E", "END" }, { 2, 3, "P^", "PAGEUP" },
		{ 2.5, 2, "D", "DELETE" }, { 3, 3, "Pv", "PAGEDOWN" },
	})
end

-- Arrow keys as an inverted T; top/bottom: row of the upper and lower keys
local function Arrows(top, bottom)
	return Keys("Arrow", 3.3, {
		{ top, 2, "^", "UP" }, { bottom, 1, "<", "LEFT" }, { bottom, 2, "v", "DOWN" }, { bottom, 3, ">", "RIGHT" },
	})
end

ns.LAYOUTS = {
	{
		id = "Windows", name = "Windows",
		keys = Join(Digits(), Operators(), Enter(), Nav6("I"), Arrows(4, 5)),
	},
	{
		id = "MicrosoftOffice", name = "Microsoft Office",
		keys = Join(Digits(), Operators(), Enter(), Nav5(),
			-- Extra key of the Office keyboard, located in the numeric keypad
			Keys("Nav", 0, { { 1, 1, "T", "TAB" } }),
			Arrows(4.3, 5.3)),
	},
	{
		id = "NaturalMultimedia", name = "Natural Multimedia",
		keys = Join(Digits(), Operators(), Enter(), Nav5(), Arrows(4.3, 5.3)),
	},
	{
		id = "NaturalElite", name = "Natural Elite",
		keys = Join(Digits(), Operators(), Enter(),
			Keys("Nav", 2.6, {
				{ 1, 1, "H", "HOME" }, { 1, 2, "P^", "PAGEUP" },
				{ 2, 1, "E", "END" }, { 2, 2, "Pv", "PAGEDOWN" },
				{ 3, 1, "D", "DELETE" }, { 3, 2, "I", "INSERT" },
			}),
			-- Arrow keys as a diamond
			Keys("Arrow", 3.1, {
				{ 4.3, 2, "^", "UP" }, { 4.8, 1, "<", "LEFT" }, { 5.3, 2, "v", "DOWN" }, { 4.8, 3, ">", "RIGHT" },
			})),
	},
	{
		id = "Macintosh", name = "Macintosh",
		keys = Join(Digits(),
			-- Operators one column further right, plus the extra keys of the Mac keyboard
			Keys("Numeric", 0, {
				{ 3, 4, "+", "NUMPADPLUS" }, { 2, 4, "-", "NUMPADMINUS" },
				{ 1, 4, "*", "NUMPADMULTIPLY" }, { 1, 3, "/", "NUMPADDIVIDE" },
				{ 1, 2, "=", "NUMPADEQUALS" }, { 1, 1, "C", "NUMLOCK" },
			}),
			Enter(), Nav6("H?"), Arrows(4, 5)),
	},
	{
		id = "Naga", name = "Razer Naga",
		-- Mouse side buttons 1-12 (1 top left), bound to numeric keypad 1-9, 0, -, +
		keys = Join(Keys("Numeric", 0, {
			{ 4, 1, "7", "NUMPAD7" }, { 4, 2, "8", "NUMPAD8" }, { 4, 3, "9", "NUMPAD9" },
			{ 3, 1, "4", "NUMPAD4" }, { 3, 2, "5", "NUMPAD5" }, { 3, 3, "6", "NUMPAD6" },
			{ 2, 1, "1", "NUMPAD1" }, { 2, 2, "2", "NUMPAD2" }, { 2, 3, "3", "NUMPAD3" },
			{ 5, 1, "10", "NUMPAD0" }, { 5, 2, "11", "NUMPADMINUS" }, { 5, 3, "12", "NUMPADPLUS" },
		}), Nav6("I"), Arrows(4, 5)),
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
