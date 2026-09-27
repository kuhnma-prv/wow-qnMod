-- qnTooltip: Optionsseiten "Zeilen: Spieler" und "Zeilen: NSC" (Canvas-Layout).
-- Je Baustein eine Zeile: an/aus, Zeile im Tooltip (Dropdown), Reihenfolge (Auf/Ab),
-- Farbe (Dropdown mit Farbfunktionen oder eigener Farbe), Format und Filter (Dropdown).
-- Die Liste zeigt die Bausteine in der Reihenfolge, in der sie im Tooltip stehen.

local _, ns = ...
local lib = qnCore
local L = ns.L
local UI = lib.UI
local UD = ns.UnitData

local ROW_HEIGHT = 30
local MAX_LINES = 8
local CUSTOM = "custom"

local pages = {}   -- [kind] = { page, sub, rows, content, … }
ns.elementsUI = pages   -- für die Tests

local function Elements(kind)
	return ns.db[kind].elements
end

local function Config(kind, key)
	local elements = Elements(kind)
	if not elements[key] then
		elements[key] = CopyTable(ns.Element(kind, key)[4])
	end
	return elements[key]
end

-- Bausteine in Tooltip-Reihenfolge; "fixed" am Ende
local function Sorted(kind)
	local list = {}
	for index, e in ipairs(ns.ELEMENTS[kind]) do
		local c = Config(kind, e[1])
		list[#list + 1] = { e = e, c = c, index = index }
	end
	table.sort(list, function(a, b)
		local fa, fb = a.e[3] == "fixed", b.e[3] == "fixed"
		if fa ~= fb then
			return fb
		elseif a.c.line ~= b.c.line then
			return a.c.line < b.c.line
		elseif a.c.order ~= b.c.order then
			return a.c.order < b.c.order
		end
		return a.index < b.index
	end)
	return list
end

-- Reihenfolge einer Zeile lückenlos 1, 2, 3 … nummerieren
local function Renumber(kind, line)
	local n = 0
	for _, item in ipairs(Sorted(kind)) do
		if item.e[3] ~= "fixed" and item.c.line == line then
			n = n + 1
			item.c.order = n
		end
	end
	return n
end

-- Baustein in seiner Zeile um dir (-1 auf, +1 ab) verschieben
function ns.MoveElement(kind, key, dir)
	local c = Config(kind, key)
	Renumber(kind, c.line)
	local target = c.order + dir
	for _, item in ipairs(Sorted(kind)) do
		if item.e[1] ~= key and item.e[3] ~= "fixed" and item.c.line == c.line and item.c.order == target then
			item.c.order, c.order = c.order, target
			return true
		end
	end
	return false
end

-- Baustein ans Ende einer anderen Zeile setzen
function ns.SetElementLine(kind, key, line)
	local c = Config(kind, key)
	if c.line == line then
		return
	end
	local old = c.line
	c.line = line
	c.order = 1000
	Renumber(kind, line)
	Renumber(kind, old)
end

---------------------------------------------------------------------------
-- Eingaben
---------------------------------------------------------------------------

local editing   -- { kind, key } des Formats im Eingabefenster

local function FormatKind(kind, key)
	return ns.Element(kind, key)[3]
end

lib.Popup.EditText("QNTOOLTIP_FORMAT", L["Format für %s (genau ein %%s, bei Zahlen auch %%d; %%%% für ein Prozentzeichen):"], function()
	return editing and Config(editing.kind, editing.key).format or ""
end, function(text)
	if not editing then
		return
	end
	local kind, key = editing.kind, editing.key
	if UD.ValidFormat(text, FormatKind(kind, key)) then
		Config(kind, key).format = text
	else
		ns.Print(L["Ungültiges Format: %s"], text)
	end
	ns.RefreshElementsPages()
end, 60)

local function EditFormat(kind, key)
	editing = { kind = kind, key = key }
	StaticPopup_Show("QNTOOLTIP_FORMAT", ns.Element(kind, key)[2])
end

local function PickColor(kind, key)
	local c = Config(kind, key)
	local r, g, b = ns.RGB(c.color)
	if not r then
		r, g, b = 1, 1, 1
	end
	local function Set(nr, ng, nb)
		Config(kind, key).color = ns.Hex(nr, ng, nb)
		ns.RefreshElementsPages()
	end
	ColorPickerFrame:SetupColorPickerAndShow({
		r = r, g = g, b = b,
		swatchFunc = function()
			Set(ColorPickerFrame:GetColorRGB())
		end,
		cancelFunc = function()
			local prev = ColorPickerFrame:GetPreviousValues()
			Set(prev.r, prev.g, prev.b)
		end,
	})
end

local function ColorEntries()
	local list = UD.ColorEntries()
	list[#list + 1] = { CUSTOM, L["Eigene Farbe …"] }
	return list
end

local function LineEntries()
	local list = {}
	for i = 1, MAX_LINES do
		list[#list + 1] = { i, tostring(i) }
	end
	return list
end

---------------------------------------------------------------------------
-- Zeilen der Liste
---------------------------------------------------------------------------

local function CreateRow(p, i)
	local kind = p.kind
	local row = CreateFrame("Frame", nil, p.content)
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
	row:SetPoint("RIGHT", p.content, "RIGHT", 0, 0)
	if i % 2 == 0 then
		local bg = row:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(1, 1, 1, 0.04)
	end

	row.enable = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
	row.enable:SetSize(26, 26)
	row.enable:SetPoint("LEFT", 2, 0)
	row.enable:SetScript("OnClick", function(self)
		Config(kind, row.key).enable = self:GetChecked() and true or false
	end)

	row.label = UI.Text(row, "GameFontHighlight")
	row.label:SetPoint("LEFT", row.enable, "RIGHT", 2, 0)
	row.label:SetWidth(150)
	row.label:SetWordWrap(false)

	row.line = UI.Dropdown(row, 56, LineEntries, function()
		return row.key and Config(kind, row.key).line
	end, function(v)
		ns.SetElementLine(kind, row.key, v)
		ns.RefreshElementsPages()
	end)
	row.line:SetPoint("LEFT", row.label, "RIGHT", 4, 0)

	row.up = UI.Button(row, L["Auf"], 44, function()
		if ns.MoveElement(kind, row.key, -1) then
			ns.RefreshElementsPages()
		end
	end)
	row.up:SetHeight(22)
	row.up:SetPoint("LEFT", row.line, "RIGHT", 6, 0)
	row.down = UI.Button(row, L["Ab"], 44, function()
		if ns.MoveElement(kind, row.key, 1) then
			ns.RefreshElementsPages()
		end
	end)
	row.down:SetHeight(22)
	row.down:SetPoint("LEFT", row.up, "RIGHT", 2, 0)

	row.color = UI.Dropdown(row, 140, ColorEntries, function()
		if not row.key then return nil end
		local color = Config(kind, row.key).color
		return UD.COLORS[color] and color or (color == "default" and "default" or CUSTOM)
	end, function(v)
		if v == CUSTOM then
			PickColor(kind, row.key)
		else
			Config(kind, row.key).color = v
			ns.RefreshElementsPages()
		end
	end)
	row.color:SetPoint("LEFT", row.down, "RIGHT", 8, 0)
	row.swatch = row:CreateTexture(nil, "ARTWORK")
	row.swatch:SetSize(14, 14)
	row.swatch:SetPoint("LEFT", row.color, "RIGHT", 4, 0)

	row.format = UI.Button(row, "", 70, function()
		EditFormat(kind, row.key)
	end)
	row.format:SetHeight(22)
	row.format:SetPoint("LEFT", row.swatch, "RIGHT", 6, 0)

	row.filter = UI.Dropdown(row, 170, UD.FilterEntries, function()
		return row.key and Config(kind, row.key).filter or "none"
	end, function(v)
		Config(kind, row.key).filter = v
		ns.RefreshElementsPages()
	end)
	row.filter:SetPoint("LEFT", row.format, "RIGHT", 6, 0)

	p.rows[i] = row
	return row
end

local function RefreshRow(row, item)
	local e, c = item.e, item.c
	local ekind = e[3]
	row.key = e[1]
	row.enable:SetChecked(c.enable)
	row.label:SetText(e[2])
	local placed = ekind ~= "fixed"
	row.line:SetShown(placed)
	row.up:SetShown(placed)
	row.down:SetShown(placed)
	if placed then
		row.line:Refresh()
	end
	local text = ekind ~= "icon"
	row.color:SetShown(text)
	row.swatch:SetShown(text)
	row.format:SetShown(text)
	if text then
		row.color:Refresh()
		local r, g, b = ns.RGB(c.color)
		if r then
			row.swatch:SetColorTexture(r, g, b)
		else
			row.swatch:SetColorTexture(0, 0, 0, 0)
		end
		row.format:SetText(c.format or "")
	end
	row.filter:Refresh()
end

function ns.RefreshElementsPage(kind)
	local p = pages[kind]
	if not (p and p.page:IsVisible()) then
		return
	end
	for i, item in ipairs(Sorted(kind)) do
		RefreshRow(p.rows[i] or CreateRow(p, i), item)
	end
	p.content:SetHeight(#ns.ELEMENTS[kind] * ROW_HEIGHT)
end

function ns.RefreshElementsPages()
	for kind in pairs(pages) do
		ns.RefreshElementsPage(kind)
	end
end

---------------------------------------------------------------------------
-- Aufbau
---------------------------------------------------------------------------

local function Preview(kind)
	local unit = kind == "player" and "player" or "target"
	if kind == "npc" and not (UnitExists("target") and not UnitIsPlayer("target")) then
		ns.Print(L["Für die Vorschau einen NSC anvisieren."])
		return
	end
	local p = pages[kind]
	GameTooltip:SetOwner(p.preview, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:SetUnit(unit)
	GameTooltip:Show()
end

local function Build(p, title)
	local page, kind = p.page, p.kind
	local head = UI.Text(page, "GameFontNormalLarge", "qnTooltip – " .. title)
	head:SetPoint("TOPLEFT", 16, -16)
	local desc = UI.Text(page, "GameFontHighlightSmall",
		L["Die Kopfzeilen des Tooltips bestehen aus diesen Bausteinen. Zeile und Reihenfolge bestimmen ihre Lage; Farbe, Format und Filter gelten je Baustein. Symbole haben weder Farbe noch Format. Die Werte liegen im aktiven Profil."])
	desc:SetPoint("TOPLEFT", head, "BOTTOMLEFT", 0, -6)
	desc:SetWidth(640)

	p.preview = UI.Button(page, PREVIEW, 120, function() Preview(kind) end,
		kind == "player" and L["Zeigt den Tooltip des eigenen Charakters."] or L["Zeigt den Tooltip des anvisierten NSC."])
	p.preview:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -10)
	p.preview:SetScript("OnLeave", GameTooltip_Hide)
	local reset = UI.Button(page, L["Standard wiederherstellen"], 200, function()
		StaticPopup_Show("QNTOOLTIP_ELEMENTS_RESET", title, nil, kind)
	end)
	reset:SetPoint("LEFT", p.preview, "RIGHT", 10, 0)

	local header = CreateFrame("Frame", nil, page)
	header:SetHeight(18)
	header:SetPoint("TOPLEFT", p.preview, "BOTTOMLEFT", 0, -12)
	header:SetPoint("RIGHT", page, "RIGHT", -16, 0)
	local x = 30
	for _, h in ipairs({ { L["Baustein"], 154 }, { L["Zeile"], 62 }, { L["Reihenfolge"], 104 }, { COLOR, 164 }, { L["Format"], 76 }, { FILTER, 170 } }) do
		local fs = UI.Text(header, "GameFontNormalSmall", h[1])
		fs:SetPoint("LEFT", x, 0)
		x = x + h[2]
	end

	local scroll = CreateFrame("ScrollFrame", nil, page)
	scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
	scroll:SetPoint("BOTTOMRIGHT", page, "BOTTOMRIGHT", -16, 12)
	scroll:EnableMouseWheel(true)
	scroll:SetScript("OnMouseWheel", function(self, delta)
		local v = self:GetVerticalScroll() - delta * ROW_HEIGHT * 2
		self:SetVerticalScroll(math.max(0, math.min(self:GetVerticalScrollRange(), v)))
	end)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(760, 1)
	scroll:SetScrollChild(content)
	scroll:SetScript("OnSizeChanged", function(_, w)
		content:SetWidth(w)
	end)
	p.content = content

	page:SetScript("OnShow", function()
		ns.RefreshElementsPage(kind)
	end)
end

lib.Popup.Confirm("QNTOOLTIP_ELEMENTS_RESET", L["Bausteine für %s auf die Vorgaben zurücksetzen?"], RESET, function(kind)
	ns.db[kind].elements = CopyTable(ns.defaults[kind].elements)
	ns.RefreshElementsPages()
end)

function ns.InitElementsPage(category, kind, title)
	local p = { kind = kind, rows = {} }
	p.page = CreateFrame("Frame")
	p.page:Hide()
	pages[kind] = p
	Build(p, title)
	p.sub = Settings.RegisterCanvasLayoutSubcategory(category, p.page, title)
end

function ns.OpenElementsPage(kind)
	lib.OpenCategory(pages[kind].sub)
end
