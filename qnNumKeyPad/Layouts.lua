-- qnNumKeyPad: Tastaturlayouts.
--
-- row/col: Lage der Taste in Tastenbreiten, 1/1 = oben links im Ziffernblock.
-- Negative Spalten liegen links davon (Navigations- und Pfeilblock).
-- type: Numeric = immer sichtbar, Enter/Nav/Arrow = zuschaltbar.
-- Die Position einer Taste in der Liste bestimmt ihren Aktionsplatz;
-- deshalb darf die Reihenfolge nicht geändert werden (Szenario qnNumKeyPad/test1 vergleicht mit dem alten Stand).

local _, ns = ...

-- Tasten eines Typs aus { row, col, label, binding }; shift rückt den Block um so viele
-- Tastenbreiten nach links (Zusatzblöcke links vom Ziffernblock).
local function Keys(kind, shift, list)
	local keys = {}
	for i, k in ipairs(list) do
		keys[i] = { row = k[1], col = k[2] - shift, type = kind, label = k[3], binding = k[4] }
	end
	return keys
end

-- Hängt mehrere Tastenlisten aneinander.
local function Join(...)
	local list = {}
	for i = 1, select("#", ...) do
		for _, key in ipairs((select(i, ...))) do
			list[#list + 1] = key
		end
	end
	return list
end

-- Ziffern 1-9, 0 und Komma in der üblichen Anordnung (1 unten links)
local function Digits()
	return Keys("Numeric", 0, {
		{ 4, 1, "1", "NUMPAD1" }, { 4, 2, "2", "NUMPAD2" }, { 4, 3, "3", "NUMPAD3" },
		{ 3, 1, "4", "NUMPAD4" }, { 3, 2, "5", "NUMPAD5" }, { 3, 3, "6", "NUMPAD6" },
		{ 2, 1, "7", "NUMPAD7" }, { 2, 2, "8", "NUMPAD8" }, { 2, 3, "9", "NUMPAD9" },
		{ 5, 1.5, "0", "NUMPAD0" }, { 5, 3, ".", "NUMPADDECIMAL" },
	})
end

-- Rechenzeichen (Windows-Anordnung: + hoch in der rechten Spalte)
local function Operators()
	return Keys("Numeric", 0, {
		{ 2.5, 4, "+", "NUMPADPLUS" }, { 1, 4, "-", "NUMPADMINUS" },
		{ 1, 3, "*", "NUMPADMULTIPLY" }, { 1, 2, "/", "NUMPADDIVIDE" },
	})
end

local function Enter()
	return Keys("Enter", 0, { { 4.5, 4, "E", "ENTER" } })
end

-- Sechserblock über den Pfeiltasten (Einfg, Pos1, Bild auf / Entf, Ende, Bild ab)
local function Nav6(insertLabel)
	return Keys("Nav", 3.3, {
		{ 1, 1, insertLabel, "INSERT" }, { 1, 2, "H", "HOME" }, { 1, 3, "P^", "PAGEUP" },
		{ 2, 1, "D", "DELETE" }, { 2, 2, "E", "END" }, { 2, 3, "Pv", "PAGEDOWN" },
	})
end

-- Fünferblock der Microsoft-Tastaturen
local function Nav5()
	return Keys("Nav", 3.3, {
		{ 1, 2, "H", "HOME" }, { 1, 3, "E", "END" }, { 2, 3, "P^", "PAGEUP" },
		{ 2.5, 2, "D", "DELETE" }, { 3, 3, "Pv", "PAGEDOWN" },
	})
end

-- Pfeiltasten als umgedrehtes T; top/bottom: Zeile der oberen bzw. unteren Tasten
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
			-- Zusatztaste der Office-Tastatur, liegt im Ziffernblock
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
			-- Pfeiltasten als Raute
			Keys("Arrow", 3.1, {
				{ 4.3, 2, "^", "UP" }, { 4.8, 1, "<", "LEFT" }, { 5.3, 2, "v", "DOWN" }, { 4.8, 3, ">", "RIGHT" },
			})),
	},
	{
		id = "Macintosh", name = "Macintosh",
		keys = Join(Digits(),
			-- Rechenzeichen eine Spalte weiter rechts, dazu die Zusatztasten der Mac-Tastatur
			Keys("Numeric", 0, {
				{ 3, 4, "+", "NUMPADPLUS" }, { 2, 4, "-", "NUMPADMINUS" },
				{ 1, 4, "*", "NUMPADMULTIPLY" }, { 1, 3, "/", "NUMPADDIVIDE" },
				{ 1, 2, "=", "NUMPADEQUALS" }, { 1, 1, "C", "NUMLOCK" },
			}),
			Enter(), Nav6("H?"), Arrows(4, 5)),
	},
	{
		id = "Naga", name = "Razer Naga",
		-- Seitentasten der Maus 1-12 (1 oben links), belegt mit Ziffernblock 1-9, 0, -, +
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
