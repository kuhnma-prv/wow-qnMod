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

-- Checkbox with label to the right. get() returns the state, set(on) takes it over (true/false).
-- cb:Refresh() shows get() (call it when showing the page); cb.label is the text.
function UI.Checkbox(parent, label, get, set, tooltip)
	local cb = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
	cb.label = UI.Text(parent, "GameFontHighlight", label)
	cb.label:SetPoint("LEFT", cb, "RIGHT", 2, 0)
	cb:SetScript("OnClick", function(self)
		set(self:GetChecked() and true or false)
	end)
	if tooltip then
		UI.Tooltip(cb, label, tooltip)
	end
	function cb:Refresh()
		self:SetChecked(get() and true or false)
	end
	return cb
end

-- Single-line text field. Enter and leaving the field take the text over with set(text) (numbers
-- with opts.numeric: set(number or nil)), then it shows get() again; Escape restores get().
--   opts.numeric     digits only      opts.maxLetters  default 60
--   opts.center      centered text    opts.enterOnly   only Enter takes it over
-- get may be nil (the field keeps its text).
function UI.EditBox(parent, width, get, set, opts)
	opts = opts or {}
	local box = CreateFrame("EditBox", nil, parent, "InputBoxTemplate")
	box:SetSize(width, 22)
	box:SetAutoFocus(false)
	box:SetMaxLetters(opts.maxLetters or 60)
	if opts.numeric then
		box:SetNumeric(true)
	end
	if opts.center then
		box:SetJustifyH("CENTER")
	end
	local function Show(self)
		if get then
			self:SetText(get() or "")
		end
	end
	local function Commit(self)
		local value = self:GetText()
		if opts.numeric then
			value = tonumber(value)
		end
		set(value)
		Show(self)
	end
	box:SetScript("OnEnterPressed", function(self)
		Commit(self)
		self:ClearFocus()
	end)
	if not opts.enterOnly then
		box:SetScript("OnEditFocusLost", function(self)
			self:HighlightText(0, 0)
			Commit(self)
		end)
		box:SetScript("OnEditFocusGained", function(self) self:HighlightText() end)
	end
	box:SetScript("OnEscapePressed", function(self)
		Show(self)
		self:ClearFocus()
	end)
	return box
end

-- "50 %" for slider values in percent
function UI.PercentLabel(v)
	return ("%d %%"):format(lib.Round(v))
end

-- Slider with steppers (Blizzard's MinimalSliderWithSteppersTemplate) from minV to maxV in steps
-- steps. get() returns the value, set(v) takes a change by the player over; s:Refresh() shows
-- get() again without calling set. format(v) = text on the right (default UI.PercentLabel).
function UI.Slider(parent, width, minV, maxV, steps, get, set, format)
	local s = CreateFrame("Frame", nil, parent, "MinimalSliderWithSteppersTemplate")
	s:SetSize(width, 20)
	s:Init(get() or minV, minV, maxV, steps, {
		[MinimalSliderWithSteppersMixin.Label.Right] = format or UI.PercentLabel,
	})
	s:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
		if not s.quiet then
			set(value)
		end
	end, s)
	function s:Refresh()
		self.quiet = true
		self:SetValue(get() or minV)
		self.quiet = false
	end
	return s
end

-- Every second row of a list slightly lighter (like Blizzard's lists)
function UI.Stripe(row, i)
	if i % 2 == 0 then
		local bg = row:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(1, 1, 1, 0.04)
	end
end

-- Frame movable by dragging with the left mouse button.
--   opts.handle    frame that receives the drag (default: frame itself)
--   opts.canMove() false: dragging does not start (e.g. locked, in combat)
--   opts.onStop(frame)  after dropping (save the position)
--   opts.toplevel  raise above other windows on click
--   opts.escape    Escape closes the window (frame needs a name, UISpecialFrames)
-- The frame always stays on the screen (SetClampedToScreen).
function UI.Movable(frame, opts)
	opts = opts or {}
	local handle = opts.handle or frame
	frame:SetMovable(true)
	frame:SetClampedToScreen(true)
	if opts.toplevel then
		frame:SetToplevel(true)
	end
	handle:EnableMouse(true)
	handle:RegisterForDrag("LeftButton")
	handle:SetScript("OnDragStart", function()
		if not opts.canMove or opts.canMove() then
			frame:StartMoving()
		end
	end)
	handle:SetScript("OnDragStop", function()
		frame:StopMovingOrSizing()
		if opts.onStop then
			opts.onStop(frame)
		end
	end)
	if opts.escape then
		tinsert(UISpecialFrames, frame:GetName())
	end
end

---------------------------------------------------------------------------
-- Options page (canvas) looking like Blizzard's vertical pages (SettingsListTemplate in
-- Blizzard_Settings_Shared): heading, optional "Defaults" button, divider, below it the
-- content with scroll bar (MinimalScrollBar, only visible if the content does not fit).
-- Canvas pages sit in the same area as Blizzard's list, hence the same spacing.
--   title          heading (page name as in the list on the left)
--   opts.desc      description at the top of the content (optional), opts.descWidth its width
--   opts.defaults  function(): "Defaults" button to the right of the heading (optional)
--   opts.refresh   function(): fills the page; called on showing and by page.Refresh() (optional)
--   opts.parent    category: registers the page as its subpage under title (optional)
-- Returns a table:
--   panel    frame for Settings.RegisterCanvasLayout...; set OnShow etc. here
--   content  parent of the controls
--   top      anchor for the first element (description or top edge of the content)
--   Fit()    re-measure the content height (after showing/hiding elements)
--   padLeft, padTop  position of top in the content (for elements attached to the content itself)
--   Refresh()  opts.refresh, but only while the page is visible
--   category, Open()  with opts.parent: the subpage and opening it in the settings window
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

	if opts.refresh then
		function page.Refresh()
			if panel:IsVisible() then
				opts.refresh()
			end
		end
		panel:SetScript("OnShow", page.Refresh)
	end
	if opts.parent then
		page.category = Settings.RegisterCanvasLayoutSubcategory(opts.parent, panel, title)
		function page.Open()
			lib.OpenCategory(page.category)
		end
	end
	return page
end

-- Head of a page with a list: a line of text below the description and a dropdown with label
-- below it (like Blizzard's filter lines). Returns the text and the dropdown (UI.Dropdown).
function UI.PageHeader(page, label, width, entries, get, set)
	local info = UI.Text(page.content, "GameFontNormal")
	info:SetPoint("TOPLEFT", page.top, "BOTTOMLEFT", 0, -14)
	local dd = UI.Dropdown(page.content, width, entries, get, set)
	dd:SetPoint("TOPLEFT", info, "BOTTOMLEFT", 110, -12)
	UI.Label(page.content, dd, label)
	return info, dd
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
