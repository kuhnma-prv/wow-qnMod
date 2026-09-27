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
