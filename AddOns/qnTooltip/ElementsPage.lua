-- qnTooltip: Optionsseiten "Zeilen: Spieler" und "Zeilen: NSC" (Canvas-Layout).
-- Je Baustein eine Zeile: an/aus, Zeile im Tooltip (Dropdown), Reihenfolge (Auf/Ab), eine Vorschau
-- mit Beispielwert und ein Stift, der den Bearbeiten-Dialog öffnet: Farbe, Filter, Format (mit Hilfe,
-- Beispielen und Vorschau).
-- Die Liste zeigt die Bausteine in der Reihenfolge, in der sie im Tooltip stehen.

local _, ns = ...
local lib = qnCore
local L = ns.L
local UI = lib.UI
local UD = ns.UnitData

local ROW_HEIGHT = 30
local MAX_LINES = 8
local CUSTOM = "custom"

local pages = {}   -- [kind] = { ui (qnCore.UI.Page), page (= ui.panel), sub, rows, content, … }
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
-- Vorschau mit Beispielwerten
---------------------------------------------------------------------------

-- Einheit für die Beispielwerte: eigener Charakter bzw. anvisierter NSC; sonst nil (nur Beispiele)
local function SampleRaw(kind)
	if kind == "player" then
		return UD.Collect("player")
	elseif ns.Plain(UnitExists("target"), false) and not ns.Plain(UnitIsPlayer("target"), true) then
		return UD.Collect("target")
	end
end

-- Beispielwert eines Bausteins mit Format (fmt, sonst das eingestellte) in seiner Farbe;
-- nil = ungültiges Format. Farbfunktionen brauchen eine Einheit, ohne raw nur feste Farben.
local function PreviewText(e, c, raw, fmt)
	local value = UD.Sample(e[1], raw, e[2])
	if e[3] == "icon" then
		return value
	end
	local text = UD.FormatValue(fmt or c.format, e[3], value)
	if not text then
		return nil
	end
	local r, g, b
	if raw or not UD.COLORS[c.color] then
		r, g, b = UD.Color(c.color, raw)
	end
	return r and ("|cff" .. ns.Hex(r, g, b) .. text .. "|r") or text
end

local INVALID = "|cffff4040%s|r"

-- Beispiele für den Format-Editor (anklickbar); der Name des Bausteins als vorangestellte Beschriftung
local function Examples(e)
	local label = e[2]:gsub("%%", "%%%%")
	if e[3] == "number" then
		return { "%d", "%d%%", "(%d%%)", label .. ": %d" }
	end
	return { "%s", "<%s>", "(%s)", label .. ": %s" }
end

---------------------------------------------------------------------------
-- Farbe
---------------------------------------------------------------------------

local function PickColor(kind, key)
	local c = Config(kind, key)
	local r, g, b = ns.RGB(c.color)
	if not r then
		r, g, b = 1, 1, 1
	end
	local old = c.color   -- Hexwert oder Farbfunktion („class“ …), beim Abbrechen unverändert zurück
	local function Set(color)
		Config(kind, key).color = color
		ns.RefreshElementsPages()
	end
	ColorPickerFrame:SetupColorPickerAndShow({
		r = r, g = g, b = b,
		swatchFunc = function()
			Set(ns.Hex(ColorPickerFrame:GetColorRGB()))
		end,
		-- Blizzard übergibt die vorherigen Werte als Tabelle (ColorPickerFrameMixin:OnCancel);
		-- gebraucht wird aber der gespeicherte Wert, der auch eine Farbfunktion sein kann
		cancelFunc = function()
			Set(old)
		end,
	})
end

local function ColorEntries()
	local list = UD.ColorEntries()
	list[#list + 1] = { CUSTOM, L["Custom color …"] }
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
-- Zeilen der Liste: an/aus, Name, Zeile, Auf/Ab, Vorschau, Stift (öffnet den Bearbeiten-Dialog)
---------------------------------------------------------------------------

local OpenEditor   -- unten (Dialog)

-- Knopf (UIPanelButtonTemplate) mit einem Symbol statt Text; gesperrt entsättigt.
-- atlas: z. B. minimal-scrollbar-arrow-top (Blizzards schmale Scrollbar), Pencil-Icon (Stift)
local function IconButton(parent, atlas, width, onClick, size)
	local b = UI.Button(parent, "", width, onClick)
	b:SetHeight(22)
	b.icon = b:CreateTexture(nil, "OVERLAY")
	b.icon:SetAtlas(atlas, not size)
	if size then
		b.icon:SetSize(size, size)
	end
	b.icon:SetPoint("CENTER")
	b:HookScript("OnEnable", function() b.icon:SetDesaturated(false) b.icon:SetAlpha(1) end)
	b:HookScript("OnDisable", function() b.icon:SetDesaturated(true) b.icon:SetAlpha(0.5) end)
	return b
end

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
	-- Baustein, der gerade im Dialog bearbeitet wird
	row.sel = row:CreateTexture(nil, "BORDER")
	row.sel:SetAllPoints()
	row.sel:SetColorTexture(1, 0.82, 0, 0.15)
	row.sel:Hide()

	row.enable = CreateFrame("CheckButton", nil, row, "UICheckButtonTemplate")
	row.enable:SetSize(26, 26)
	row.enable:SetPoint("LEFT", 2, 0)
	row.enable:SetScript("OnClick", function(self)
		Config(kind, row.key).enable = self:GetChecked() and true or false
		ns.RefreshElementsPages()
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

	row.up = IconButton(row, "minimal-scrollbar-arrow-top", 30, function()
		if ns.MoveElement(kind, row.key, -1) then
			ns.RefreshElementsPages()
		end
	end)
	row.up:SetPoint("LEFT", row.line, "RIGHT", 6, 0)
	row.down = IconButton(row, "minimal-scrollbar-arrow-bottom", 30, function()
		if ns.MoveElement(kind, row.key, 1) then
			ns.RefreshElementsPages()
		end
	end)
	row.down:SetPoint("LEFT", row.up, "RIGHT", 2, 0)

	row.edit = IconButton(row, "Pencil-Icon", 30, function()
		OpenEditor(p, row.key)
	end, 16)
	row.edit:SetPoint("RIGHT", -4, 0)
	UI.Tooltip(row.edit, EDIT)

	row.preview = UI.Text(row, "GameFontHighlight")
	row.preview:SetPoint("LEFT", row.down, "RIGHT", 12, 0)
	row.preview:SetPoint("RIGHT", row.edit, "LEFT", -6, 0)
	row.preview:SetWordWrap(false)

	p.rows[i] = row
	return row
end

-- before/after: Nachbarn in der Liste (für die Pfeile: nur innerhalb derselben Tooltip-Zeile)
local function RefreshRow(p, row, item, before, after)
	local e, c = item.e, item.c
	row.key = e[1]
	row.enable:SetChecked(c.enable)
	row.label:SetText(e[2])
	local placed = e[3] ~= "fixed"
	row.line:SetShown(placed)
	row.up:SetShown(placed)
	row.down:SetShown(placed)
	if placed then
		row.line:Refresh()
		row.up:SetEnabled(before ~= nil and before.e[3] ~= "fixed" and before.c.line == c.line)
		row.down:SetEnabled(after ~= nil and after.e[3] ~= "fixed" and after.c.line == c.line)
	end
	row.preview:SetText(PreviewText(e, c, p.raw) or INVALID:format(L["(invalid format)"]))
	row.preview:SetAlpha(c.enable and 1 or 0.4)
	row.sel:SetShown(p.editor:IsShown() and row.key == p.selected)
end

---------------------------------------------------------------------------
-- Bearbeiten-Dialog eines Bausteins (je Seite einer; DefaultPanelTemplate aus Blizzard_SharedXML):
-- Farbe, Filter, Format mit Vorschau, Hilfe und Beispielen (Knopf mit dem Format, dahinter das
-- Ergebnis). Hängt an der Seite, schließt also mit ihr.
---------------------------------------------------------------------------

local EDITOR_WIDTH, EDITOR_HEIGHT = 470, 380
local PAD = 18

local function Selected(p)
	return p.selected and ns.Element(p.kind, p.selected), p.selected and Config(p.kind, p.selected)
end

-- Vorschau zum Text im Formatfeld (auch während der Eingabe)
local function UpdateResult(p)
	local ed = p.editor
	local e, c = Selected(p)
	if not e or e[3] == "icon" then
		return
	end
	local text = PreviewText(e, c, p.raw, ed.format:GetText())
	ed.result:SetText(text and L["Preview: %s"]:format(text)
		or INVALID:format(L["Invalid – exactly one placeholder (%s, for numbers also %d), percent sign as %%."]))
end

-- Eingabe übernehmen, wenn gültig; sonst den gespeicherten Wert zurück
local function CommitFormat(p)
	local e, c = Selected(p)
	if not e or e[3] == "icon" then
		return
	end
	local text = p.editor.format:GetText()
	if text == (c.format or "") then
		return
	end
	if UD.ValidFormat(text, e[3]) then
		c.format = text
		ns.RefreshElementsPages()
	else
		ns.Print(L["Invalid format: %s"], text)
		p.editor.format:SetText(c.format or "")
		UpdateResult(p)
	end
end

local function CreateEditor(p)
	local kind = p.kind
	local ed = CreateFrame("Frame", nil, p.page, "DefaultPanelTemplate")
	ed:SetSize(EDITOR_WIDTH, EDITOR_HEIGHT)
	ed:SetPoint("CENTER", p.page, "CENTER", 0, 20)
	ed:SetFrameStrata("DIALOG")
	ed:SetToplevel(true)
	ed:EnableMouse(true)
	ed:SetMovable(true)
	ed:SetClampedToScreen(true)
	ed:RegisterForDrag("LeftButton")
	ed:SetScript("OnDragStart", ed.StartMoving)
	ed:SetScript("OnDragStop", ed.StopMovingOrSizing)
	ed:Hide()
	ed.text = {}   -- nur bei Text- und Zahlenbausteinen sichtbar
	p.editor = ed

	-- OK übernimmt (samt offener Eingabe), Abbrechen, das X und jedes andere Schließen (z. B. mit
	-- dem Einstellungsfenster) stellen die Werte beim Öffnen wieder her. Änderungen wirken bis dahin
	-- schon auf die Vorschau in der Liste.
	ed.cancel = UI.Button(ed, CANCEL, 110, function() ns.CloseElementEditor(p, false) end)
	ed.cancel:SetPoint("BOTTOMRIGHT", -PAD, 14)
	ed.ok = UI.Button(ed, OKAY, 110, function() ns.CloseElementEditor(p, true) end)
	ed.ok:SetPoint("RIGHT", ed.cancel, "LEFT", -8, 0)
	local close = CreateFrame("Button", nil, ed, "UIPanelCloseButtonDefaultAnchors")
	close:SetScript("OnClick", function() ns.CloseElementEditor(p, false) end)
	ed:SetScript("OnHide", function()
		ns.CloseElementEditor(p, false)
	end)

	ed.color = UI.Dropdown(ed, 180, ColorEntries, function()
		local _, c = Selected(p)
		if not c then return nil end
		return UD.COLORS[c.color] and c.color or (c.color == "default" and "default" or CUSTOM)
	end, function(v)
		if v == CUSTOM then
			PickColor(kind, p.selected)
		else
			Config(kind, p.selected).color = v
			ns.RefreshElementsPages()
		end
	end)
	ed.color:SetPoint("TOPLEFT", 90, -40)
	ed.colorLabel = UI.Label(ed, ed.color, COLOR)
	ed.swatch = ed:CreateTexture(nil, "ARTWORK")
	ed.swatch:SetSize(14, 14)
	ed.swatch:SetPoint("LEFT", ed.color, "RIGHT", 6, 0)

	ed.filter = UI.Dropdown(ed, 180, UD.FilterEntries, function()
		local _, c = Selected(p)
		return c and c.filter or "none"
	end, function(v)
		Config(kind, p.selected).filter = v
		ns.RefreshElementsPages()
	end)
	ed.filter:SetPoint("TOPLEFT", ed.color, "BOTTOMLEFT", 0, -10)
	UI.Label(ed, ed.filter, FILTER)

	ed.iconNote = UI.Text(ed, "GameFontHighlightSmall", L["Icons have neither color nor format – only the filter applies to them."])
	ed.iconNote:SetPoint("TOPLEFT", PAD, -116)
	ed.iconNote:SetWidth(EDITOR_WIDTH - 2 * PAD)

	ed.format = CreateFrame("EditBox", nil, ed, "InputBoxTemplate")
	ed.format:SetSize(174, 22)
	ed.format:SetAutoFocus(false)
	ed.format:SetMaxLetters(60)
	ed.format:SetPoint("TOPLEFT", ed.filter, "BOTTOMLEFT", 6, -12)
	ed.formatLabel = UI.Label(ed, ed.format, L["Format"], 16)
	ed.format:SetScript("OnTextChanged", function()
		UpdateResult(p)
	end)
	ed.format:SetScript("OnEnterPressed", function(self)
		CommitFormat(p)
		self:ClearFocus()
	end)
	ed.format:SetScript("OnEditFocusLost", function()
		CommitFormat(p)
	end)
	ed.format:SetScript("OnEscapePressed", function(self)
		local _, c = Selected(p)
		self:SetText(c and c.format or "")
		self:ClearFocus()
	end)
	ed.result = UI.Text(ed, "GameFontHighlight")
	ed.result:SetPoint("LEFT", ed.format, "RIGHT", 14, 0)
	ed.result:SetPoint("RIGHT", -PAD, 0)
	ed.result:SetWordWrap(false)

	-- Hilfe: Texte ohne Formatierung angezeigt (%s, %% stehen so da, || zeigt einen Strich)
	ed.help = UI.Text(ed, "GameFontHighlightSmall")
	ed.help:SetPoint("TOPLEFT", PAD, -150)
	ed.help:SetWidth(EDITOR_WIDTH - 2 * PAD)
	ed.exHead = UI.Text(ed, "GameFontNormalSmall", L["Examples – click to use:"])
	ed.exHead:SetPoint("TOPLEFT", ed.help, "BOTTOMLEFT", 0, -10)
	-- je Beispiel eine Zeile: Knopf mit dem Format, dahinter das Ergebnis
	ed.examples = {}
	for i = 1, 4 do
		local b = UI.Button(ed, "", 150, function(self)
			ed.format:SetText(self.fmt)
			CommitFormat(p)
		end)
		b:SetHeight(22)
		b:SetPoint("TOPLEFT", i == 1 and ed.exHead or ed.examples[i - 1], "BOTTOMLEFT", 0, i == 1 and -6 or -4)
		b.result = UI.Text(ed, "GameFontHighlight")
		b.result:SetPoint("LEFT", b, "RIGHT", 12, 0)
		b.result:SetPoint("RIGHT", -PAD, 0)
		b.result:SetWordWrap(false)
		ed.examples[i] = b
		ed.text[#ed.text + 1] = b
		ed.text[#ed.text + 1] = b.result
	end

	for _, w in ipairs({ ed.color, ed.colorLabel, ed.swatch, ed.format, ed.formatLabel, ed.result, ed.help, ed.exHead }) do
		ed.text[#ed.text + 1] = w
	end
end

local function RefreshEditor(p)
	local ed = p.editor
	local e, c = Selected(p)
	if not (e and ed:IsShown()) then
		return
	end
	ed.TitleContainer.TitleText:SetText(L["Element: %s"]:format(e[2]))
	local text = e[3] ~= "icon"
	for _, w in ipairs(ed.text) do
		w:SetShown(text)
	end
	ed.iconNote:SetShown(not text)
	ed.filter:Refresh()
	if not text then
		return
	end
	ed.color:Refresh()
	local r, g, b = ns.RGB(c.color)
	if r then
		ed.swatch:SetColorTexture(r, g, b)
	else
		ed.swatch:SetColorTexture(0, 0, 0, 0)
	end
	if not ed.format:HasFocus() then
		ed.format:SetText(c.format or "")
	end
	UpdateResult(p)
	ed.help:SetText(e[3] == "number"
		and L["%d or %s stands for the number, everything else appears as written. Exactly one placeholder is allowed. Write a percent sign as %%, e.g. %d%% for 120%. Color codes color a part: ||cffff0000red||r (the color above applies to the whole element)."]
		or L["%s stands for the value, everything else appears as written. Exactly one %s is allowed. Write a percent sign as %%. Color codes color a part: ||cffff0000red||r (the color above applies to the whole element)."])
	for i, fmt in ipairs(Examples(e)) do
		local b = ed.examples[i]
		b.fmt = fmt
		b:SetText(fmt)
		b.result:SetText(PreviewText(e, c, p.raw, fmt) or "?")
	end
end

local EDITED = { "color", "format", "filter" }   -- Werte, die der Dialog ändert

-- Dialog schließen: ok = übernehmen, sonst die Werte beim Öffnen zurück (p.saved)
function ns.CloseElementEditor(p, ok)
	local ed, saved = p.editor, p.saved
	if not saved then
		return   -- schon geschlossen (OnHide nach OK/Abbrechen)
	end
	p.saved = nil
	if ColorPickerFrame:IsShown() then
		ColorPickerFrame:Hide()   -- sonst änderte ein späteres OK im Farbwähler die Farbe noch
	end
	if ok then
		ed.format:ClearFocus()
		CommitFormat(p)
	else
		ed.format:SetText(saved.format or "")   -- ClearFocus übernimmt sonst die Eingabe
		ed.format:ClearFocus()
		local c = Config(p.kind, p.selected)
		for _, k in ipairs(EDITED) do
			c[k] = saved[k]
		end
	end
	ed:Hide()
	ns.RefreshElementsPages()
end

-- Dialog für einen Baustein öffnen und dessen Werte sichern; ein offener Dialog für einen anderen
-- Baustein wird vorher mit OK geschlossen.
function OpenEditor(p, key)
	local ed = p.editor
	if p.saved and p.selected ~= key then
		ns.CloseElementEditor(p, true)
	end
	if not p.saved then
		local c = Config(p.kind, key)
		p.saved = {}
		for _, k in ipairs(EDITED) do
			p.saved[k] = c[k]
		end
	end
	p.selected = key
	ed:Show()
	ed:Raise()
	ns.RefreshElementsPage(p.kind)
end

function ns.RefreshElementsPage(kind)
	local p = pages[kind]
	if not (p and p.page:IsVisible()) then
		return
	end
	p.raw = SampleRaw(kind)
	local sorted = Sorted(kind)
	for i, item in ipairs(sorted) do
		RefreshRow(p, p.rows[i] or CreateRow(p, i), item, sorted[i - 1], sorted[i + 1])
	end
	p.content:SetHeight(#ns.ELEMENTS[kind] * ROW_HEIGHT)
	RefreshEditor(p)
	p.ui.Fit()
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
		ns.Print(L["Target an NPC for the preview."])
		return
	end
	local p = pages[kind]
	GameTooltip:SetOwner(p.preview, "ANCHOR_BOTTOMRIGHT")
	GameTooltip:SetUnit(unit)
	GameTooltip:Show()
end

local function Build(p, title)
	local kind = p.kind
	p.ui = UI.Page(title, {
		desc = L["The header lines of the tooltip are built from these elements. Line and order set their placement; color, format and filter apply per element. Icons have neither color nor format. The values are stored in the active profile."],
		descWidth = 600,
		defaults = function()
			StaticPopup_Show("QNTOOLTIP_ELEMENTS_RESET", title, nil, kind)
		end,
	})
	p.page = p.ui.panel
	local parent = p.ui.content

	p.preview = UI.Button(parent, PREVIEW, 120, function() Preview(kind) end,
		kind == "player" and L["Shows the tooltip of your own character."] or L["Shows the tooltip of the targeted NPC."])
	p.preview:SetPoint("TOPLEFT", p.ui.top, "BOTTOMLEFT", 0, -10)
	p.preview:SetScript("OnLeave", GameTooltip_Hide)

	local header = CreateFrame("Frame", nil, parent)
	header:SetHeight(18)
	header:SetPoint("TOPLEFT", p.preview, "BOTTOMLEFT", 0, -12)
	header:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
	local x = 30
	for _, h in ipairs({ { L["Element"], 154 }, { L["Line"], 62 }, { L["Order"], 76 }, { PREVIEW, 0 } }) do
		local fs = UI.Text(header, "GameFontNormalSmall", h[1])
		fs:SetPoint("LEFT", x, 0)
		x = x + h[2]
	end

	-- Zeilen im Inhalt der Seite (blättern mit der Seite)
	local content = CreateFrame("Frame", nil, parent)
	content:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -4)
	content:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
	content:SetHeight(1)
	p.content = content

	CreateEditor(p)

	p.page:SetScript("OnShow", function()
		ns.RefreshElementsPage(kind)
	end)
end

lib.Popup.Confirm("QNTOOLTIP_ELEMENTS_RESET", L["Reset the elements for %s to the defaults?"], RESET, function(kind)
	ns.db[kind].elements = CopyTable(ns.defaults[kind].elements)
	ns.RefreshElementsPages()
end)

function ns.InitElementsPage(category, kind, title)
	local p = { kind = kind, rows = {} }
	pages[kind] = p
	Build(p, title)
	p.sub = Settings.RegisterCanvasLayoutSubcategory(category, p.page, title)
end

function ns.OpenElementsPage(kind)
	lib.OpenCategory(pages[kind].sub)
end
