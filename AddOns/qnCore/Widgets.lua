-- qnCore: building blocks for freely designed options pages (canvas layout) and confirmations (popup).
-- A choice among several options always goes through UI.Dropdown: a button with
-- a drop-down list that shows the active choice.

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

-- Existing OnEnter/OnLeave (e.g. highlight of the dropdown button) are kept.
local function SetOrHook(widget, script, fn)
	if widget:GetScript(script) then
		widget:HookScript(script, fn)
	else
		widget:SetScript(script, fn)
	end
end

-- title and text: text or function(widget) that returns it when shown
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

-- Button with drop-down list.
--   entries  { { value, text }, ... } or function that returns this list (re-read on every open)
--   get()    current value
--   set(v)   take over new value
--   defaultText  text without a matching choice (optional)
--   maxHeight    long lists scroll from this height on (optional)
-- dd:Refresh() shows the active choice again after an outside change.
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

-- Label to the left of a control
function UI.Label(parent, widget, text, gap)
	local fs = UI.Text(parent, "GameFontHighlight", text)
	fs:SetPoint("RIGHT", widget, "LEFT", -(gap or 10), 0)
	return fs
end

---------------------------------------------------------------------------
-- Options page (canvas) looking like Blizzard's vertical pages (SettingsListTemplate in
-- Blizzard_Settings_Shared): heading, optional "Defaults" button, divider, below it the
-- content with scroll bar (MinimalScrollBar, only visible if the content does not fit).
-- Canvas pages sit in the same area as Blizzard's list, hence the same spacing.
--   title          heading (page name as in the list on the left)
--   opts.desc      description at the top of the content (optional), opts.descWidth its width
--   opts.defaults  function(): "Defaults" button to the right of the heading (optional)
-- Returns a table:
--   panel    frame for Settings.RegisterCanvasLayout...; set OnShow etc. here
--   content  parent of the controls
--   top      anchor for the first element (description or top edge of the content)
--   Fit()    re-measure the content height (after showing/hiding elements)
--   padLeft, padTop  position of top in the content (for elements attached to the content itself)
---------------------------------------------------------------------------

local PAGE_PAD_LEFT, PAGE_PAD_TOP = 40, 10   -- content aligned with Blizzard's section headers

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

	-- ScrollFrameTemplate (Blizzard_SharedXML) creates the scroll bar including mouse wheel
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

	-- Lowest edge of all visible children and texts of the content
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
	-- immediately and in the next frame (by then position and text sizes are settled after refreshing)
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
-- Confirmations (StaticPopupDialogs); shown with StaticPopup_Show(name, a1, a2, data),
-- a1/a2 fill %s in the text.
---------------------------------------------------------------------------

local Popup = {}
lib.Popup = Popup

local function Dialog(t)
	t.timeout = 0
	t.whileDead = 1
	t.hideOnEscape = 1
	return t
end

-- Confirmation with button1 and Cancel; onAccept(data) on confirm.
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

-- Text input: get() returns the previous text, set(text) takes it over (Accept or
-- Enter). Escape closes without taking it over.
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
