-- qnCore: Bausteine für frei gestaltete Optionsseiten (Canvas-Layout) und Rückfragen (Popup).
-- Auswahl aus mehreren Möglichkeiten immer über UI.Dropdown: ein Knopf mit
-- Aufklappliste, der die aktive Auswahl anzeigt.

local _, ns = ...
local lib = qnCore

local UI = {}
lib.UI = UI

function UI.Text(parent, template, text)
	local fs = parent:CreateFontString(nil, "ARTWORK", template or "GameFontHighlight")
	fs:SetJustifyH("LEFT")
	if text then
		fs:SetText(text)
	end
	return fs
end

-- Vorhandene OnEnter/OnLeave (z. B. Hervorhebung des Dropdown-Knopfs) bleiben erhalten.
local function SetOrHook(widget, script, fn)
	if widget:GetScript(script) then
		widget:HookScript(script, fn)
	else
		widget:SetScript(script, fn)
	end
end

-- title und text: Text oder function(widget), die ihn beim Zeigen liefert
function UI.Tooltip(widget, title, text, anchor)
	local function Value(v, self)
		if type(v) == "function" then
			return v(self)
		end
		return v
	end
	SetOrHook(widget, "OnEnter", function(self)
		GameTooltip:SetOwner(self, anchor or "ANCHOR_RIGHT")
		GameTooltip:AddLine(Value(title, self))
		if text then
			GameTooltip:AddLine(Value(text, self), 1, 1, 1, true)
		end
		GameTooltip:Show()
	end)
	SetOrHook(widget, "OnLeave", GameTooltip_Hide)
end

function UI.Button(parent, text, width, onClick, tooltip)
	local b = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
	b:SetSize(width, 26)
	b:SetText(text)
	b:SetScript("OnClick", onClick)
	if tooltip then
		UI.Tooltip(b, text, tooltip, "ANCHOR_TOP")
	end
	return b
end

-- Knopf mit Aufklappliste.
--   entries  { { Wert, Text }, … } oder Funktion, die diese Liste liefert (bei jedem Öffnen neu)
--   get()    aktueller Wert
--   set(v)   neuen Wert übernehmen
--   defaultText  Text ohne passende Auswahl (optional)
--   maxHeight    lange Listen ab dieser Höhe mit Bildlauf (optional)
-- dd:Refresh() zeigt nach einer Änderung von außen wieder die aktive Auswahl.
function UI.Dropdown(parent, width, entries, get, set, defaultText, maxHeight)
	local dd = CreateFrame("DropdownButton", nil, parent, "WowStyle1DropdownTemplate")
	dd:SetWidth(width)
	if defaultText then
		dd:SetDefaultText(defaultText)
	end
	dd:SetupMenu(function(_, root)
		if maxHeight then
			root:SetScrollMode(maxHeight)
		end
		for _, entry in ipairs(type(entries) == "function" and entries() or entries) do
			local value, text = entry[1], entry[2]
			root:CreateRadio(text, function()
				return get() == value
			end, function()
				set(value)
			end)
		end
	end)
	function dd:Refresh()
		self:GenerateMenu()
	end
	return dd
end

-- Beschriftung links neben einem Steuerelement
function UI.Label(parent, widget, text, gap)
	local fs = UI.Text(parent, "GameFontHighlight", text)
	fs:SetPoint("RIGHT", widget, "LEFT", -(gap or 10), 0)
	return fs
end

---------------------------------------------------------------------------
-- Optionsseite (Canvas) im Aussehen von Blizzards senkrechten Seiten (SettingsListTemplate in
-- Blizzard_Settings_Shared): Überschrift, optional Knopf „Standard“, Trennlinie, darunter der
-- Inhalt mit Scrollbar (MinimalScrollBar, nur sichtbar, wenn der Inhalt nicht passt).
-- Canvas-Seiten liegen in derselben Fläche wie Blizzards Liste, daher dieselben Abstände.
--   title          Überschrift (Name der Seite wie in der Liste links)
--   opts.desc      Beschreibung oben im Inhalt (optional), opts.descWidth ihre Breite
--   opts.defaults  function(): Knopf „Standard“ rechts neben der Überschrift (optional)
-- Liefert eine Tabelle:
--   panel    Rahmen für Settings.RegisterCanvasLayout…; OnShow usw. hier setzen
--   content  Eltern der Steuerelemente
--   top      Anker für das erste Element (Beschreibung bzw. oberer Rand des Inhalts)
--   Fit()    Höhe des Inhalts neu messen (nach dem Ein-/Ausblenden von Elementen)
--   padLeft, padTop  Lage von top im Inhalt (für Elemente, die am Inhalt selbst hängen)
---------------------------------------------------------------------------

local PAGE_PAD_LEFT, PAGE_PAD_TOP = 40, 10   -- Inhalt bündig mit Blizzards Abschnittsüberschriften

function UI.Page(title, opts)
	opts = opts or {}
	local page = { padLeft = PAGE_PAD_LEFT, padTop = PAGE_PAD_TOP }
	local panel = CreateFrame("Frame")
	panel:Hide()
	page.panel = panel

	local header = CreateFrame("Frame", nil, panel)
	header:SetHeight(50)
	header:SetPoint("TOPLEFT")
	header:SetPoint("TOPRIGHT")
	page.title = UI.Text(header, "GameFontHighlightHuge", title)
	page.title:SetPoint("TOPLEFT", 7, -22)
	local line = header:CreateTexture(nil, "ARTWORK")
	line:SetAtlas("Options_HorizontalDivider", true)
	line:SetPoint("TOP", 0, -50)
	if opts.defaults then
		page.defaults = CreateFrame("Button", nil, header, "UIPanelButtonTemplate")
		page.defaults:SetSize(96, 22)
		page.defaults:SetPoint("TOPRIGHT", -36, -16)
		page.defaults:SetText(SETTINGS_DEFAULTS)
		page.defaults:SetScript("OnClick", opts.defaults)
	end

	-- ScrollFrameTemplate (Blizzard_SharedXML) legt die Scrollbar samt Mausrad an
	local scroll = CreateFrame("ScrollFrame", nil, panel, "ScrollFrameTemplate")
	scroll:SetPoint("TOPLEFT", header, "BOTTOMLEFT", -15, -2)
	scroll:SetPoint("BOTTOMRIGHT", -20, -2)
	scroll.ScrollBar:ClearAllPoints()
	scroll.ScrollBar:SetPoint("TOPLEFT", scroll, "TOPRIGHT", 0, -4)
	scroll.ScrollBar:SetPoint("BOTTOMLEFT", scroll, "BOTTOMRIGHT", -1, 7)
	scroll.ScrollBar:SetHideIfUnscrollable(true)
	local content = CreateFrame("Frame", nil, scroll)
	content:SetSize(640, 1)
	scroll:SetScrollChild(content)
	page.scroll, page.content = scroll, content

	if opts.desc then
		page.top = UI.Text(content, "GameFontHighlightSmall", opts.desc)
		page.top:SetWidth(opts.descWidth or 620)
	else
		page.top = CreateFrame("Frame", nil, content)
		page.top:SetSize(1, 1)
	end
	page.top:SetPoint("TOPLEFT", PAGE_PAD_LEFT, -PAGE_PAD_TOP)

	-- Unterste Kante aller sichtbaren Kinder und Texte des Inhalts
	local function Lowest(bottom, ...)
		for i = 1, select("#", ...) do
			local obj = select(i, ...)
			local b = obj:IsShown() and obj:GetBottom()
			if b and (not bottom or b < bottom) then
				bottom = b
			end
		end
		return bottom
	end
	local function Measure()
		local top = content:GetTop()
		local bottom = Lowest(Lowest(nil, content:GetChildren()), content:GetRegions())
		if top and bottom then
			content:SetHeight(math.max(1, top - bottom + PAGE_PAD_TOP))
		end
	end
	-- sofort und im nächsten Frame (dann stehen Lage und Textgrößen nach dem Auffrischen fest)
	function page.Fit()
		Measure()
		C_Timer.After(0, Measure)
	end
	scroll:SetScript("OnSizeChanged", function(_, w)
		content:SetWidth(w)
		page.Fit()
	end)
	content:SetScript("OnShow", page.Fit)
	return page
end

---------------------------------------------------------------------------
-- Rückfragen (StaticPopupDialogs); angezeigt mit StaticPopup_Show(name, a1, a2, data),
-- a1/a2 füllen %s im Text.
---------------------------------------------------------------------------

local Popup = {}
lib.Popup = Popup

local function Dialog(t)
	t.timeout = 0
	t.whileDead = 1
	t.hideOnEscape = 1
	return t
end

-- Rückfrage mit button1 und Abbrechen; onAccept(data) beim Bestätigen.
function Popup.Confirm(name, text, button1, onAccept)
	StaticPopupDialogs[name] = Dialog({
		text = text,
		button1 = button1,
		button2 = CANCEL,
		OnAccept = function(_, data)
			onAccept(data)
		end,
	})
end

-- Eingabe eines Textes: get() liefert den bisherigen Text, set(text) übernimmt ihn (Annehmen oder
-- Enter). Escape schließt ohne Übernahme.
function Popup.EditText(name, text, get, set, maxLetters)
	StaticPopupDialogs[name] = Dialog({
		text = text,
		button1 = ACCEPT,
		button2 = CANCEL,
		hasEditBox = 1,
		editBoxWidth = 350,
		maxLetters = maxLetters or 500,
		OnShow = function(dialog)
			local editBox = dialog:GetEditBox()
			editBox:SetText(get() or "")
			editBox:SetFocus()
		end,
		OnAccept = function(dialog)
			set(dialog:GetEditBox():GetText())
		end,
		EditBoxOnEnterPressed = function(editBox)
			set(editBox:GetText())
			editBox:GetParent():Hide()
		end,
		EditBoxOnEscapePressed = StaticPopup_StandardEditBoxOnEscapePressed,
	})
end
