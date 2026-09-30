-- qnNumKeyPad: bar, buttons, key bindings, visibility, stance switching.
--
-- Structure: a secure header frame
-- (SecureHandlerStateTemplate) with Blizzard's ActionBarButtonTemplate buttons.
-- Visibility and stance switching run through state drivers so that they
-- also work in combat; likewise key bindings and the drag lock (secure
-- snippets on the header frame). Everything that changes protected frames
-- goes through ns.Apply() and is deferred in combat.

local _, ns = ...
local L = ns.L

local BUTTON_SIZE = 45
local INSET = 4

local bar, overlay, fader
local buttons = {}
local keys = {}             -- button index -> invisible proxy for the key binding
local visibleKeys = {}      -- button index -> key of the current layout
local cursorGrid = false    -- player is currently holding an action on the cursor
local keepPending = false   -- anchor change in combat: offsets not yet converted

-- Offsets are stored rounded to whole UIParent units.
local function Round(v)
	return math.floor(v + 0.5)
end

---------------------------------------------------------------------------
-- Action slots
---------------------------------------------------------------------------

-- Key group: keys 1-12 are on page1, 13-24 on page2, 25-28 on page3.
local function Group(i)
	return (i <= 12 and 1) or (i <= 24 and 2) or 3
end

local function Slot(i)
	local page = ns.db["page" .. Group(i)]
	return (page - 1) * NUM_ACTIONBAR_BUTTONS + (i - 1) % NUM_ACTIONBAR_BUTTONS + 1
end

-- Page of a modifier set ("ctrl", "alt"); nil if the set is switched off.
function ns.SetPage(set)
	local db = ns.db
	if db[set .. "Set"] then
		return db[set .. "Page"]
	end
end

-- Action slot of the key with this binding in the configured layout (from the settings, not from
-- the applied bar): its own slot, or with set ("ctrl", "alt") the slot of the modifier set.
-- Otherwise nil and the reason: "layout" (no such key or hidden), "off" (set switched off),
-- "fixed" (keys 13 and higher do not switch).
function ns.SlotOfBinding(binding, set)
	for i, key in ipairs(ns.GetLayout(ns.db.layout).keys) do
		if key.binding == binding and ns.IsKeyShown(key) then
			if not set then
				return Slot(i)
			end
			local page = ns.SetPage(set)
			if not page then
				return nil, "off"
			elseif i > NUM_ACTIONBAR_BUTTONS then
				return nil, "fixed"
			end
			return (page - 1) * NUM_ACTIONBAR_BUTTONS + i
		end
	end
	return nil, "layout"
end

-- In the secure environment: keys 1-12 show the page of the state "page" (modifier set while Ctrl
-- or Alt is held, otherwise with stance switching the stance page 7-11 of the main action bar);
-- state 0 = their own slot.
local CHILD_PAGE = [[
	local page = tonumber(message) or 0
	local index = self:GetAttribute("qn-index")
	if page > 0 and index <= 12 then
		self:SetAttribute("action", (page - 1) * 12 + index)
	else
		self:SetAttribute("action", self:GetAttribute("qn-own"))
	end
]]

-- In the secure environment (OnDragStart of each button, control = bar): additional lock against
-- accidental dragging out. false aborts; otherwise Blizzard's handler runs unchanged
-- (where the Blizzard option "Lock Action Bars" still applies).
local DRAG_LOCK = [[
	if (control:GetAttribute("qn-lockall") or (control:GetAttribute("qn-lockcombat") and PlayerInCombat()))
		and not IsModifiedClick("PICKUPACTION") then
		return false
	end
]]

-- In the secure environment (self = bar): key bindings only while the numpad is enabled and the
-- bar is not hidden by the visibility driver (statehidden; independent of UIParent, so
-- also with the UI hidden). qn-bound prevents rebinding on every driver pass.
local BIND = [[
	local want = self:GetAttribute("qn-enabled") and not self:GetAttribute("statehidden") and true or false
	if want == self:GetAttribute("qn-bound") then
		return
	end
	self:SetAttribute("qn-bound", want)
	self:ClearBindings()
	if want then
		local shift = self:GetAttribute("qn-shift")
		for n = 1, self:GetAttribute("qn-count") or 0 do
			local key, target = self:GetAttribute("qn-key" .. n), self:GetAttribute("qn-target" .. n)
			self:SetBindingClick(false, key, target, "LeftButton")
			if shift then
				self:SetBindingClick(false, "SHIFT-" .. key, target, "LeftButton")
			end
			-- modifier sets: only keys 1-12 switch pages
			if self:GetAttribute("qn-mod" .. n) then
				if self:GetAttribute("qn-ctrl") then
					self:SetBindingClick(false, "CTRL-" .. key, target, "LeftButton")
				end
				if self:GetAttribute("qn-alt") then
					self:SetBindingClick(false, "ALT-" .. key, target, "LeftButton")
				end
			end
		end
	end
]]

-- OnAttributeChanged of the bar: the visibility driver sets statehidden on every show/hide
local ON_HIDDEN = [[
	if name == "statehidden" then
]] .. BIND .. [[
	end
]]

---------------------------------------------------------------------------
-- Button display (allowed in combat too)
---------------------------------------------------------------------------

local function UpdateHotkey(button)
	local db = ns.db
	local hotkey = button.HotKey
	local key = visibleKeys[button.qnIndex]
	local text
	if key then
		if db.labels == 1 then
			text = key.label
		elseif db.labels == 2 then
			text = GetBindingText(key.binding, true)
		end
	end
	local size = db.fontSize > 0 and db.fontSize or button.qnFontSize
	hotkey:SetFont(button.qnFont, size, button.qnFontFlags)
	hotkey:SetHeight(db.fontSize > 0 and size + 2 or 10)
	if text and text ~= "" then
		hotkey:SetText(text)
		hotkey:Show()
	else
		hotkey:SetText(RANGE_INDICATOR)
		hotkey:Hide()
	end
end

local function UpdateLook(button)
	local db = ns.db
	button.Name:SetShown(not db.hideMacro)
	-- green border for equipped items (like ActionButton:Update)
	-- Blizzard sets button.action already on creation (UpdateAction, CalculateAction always returns a slot)
	button.Border:SetShown(not db.hideBorder and C_ActionBar.IsEquippedAction(button.action))
	if db.zoom then
		button.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
	else
		button.icon:SetTexCoord(0, 1, 0, 1)
	end
	local showEmpty = db.showGrid or not db.locked or cursorGrid
	local hasAction = C_ActionBar.HasAction(button.action)
	button:SetAlpha((showEmpty or hasAction) and 1 or 0)
end

---------------------------------------------------------------------------
-- Setup
---------------------------------------------------------------------------

local function CreateButton(i)
	local button = CreateFrame("CheckButton", "qnNumKeyPadButton" .. i, bar, "ActionBarButtonTemplate")
	button.qnIndex = i
	button.qnFont, button.qnFontSize, button.qnFontFlags = button.HotKey:GetFont()
	button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
	button:SetAttribute("qn-index", i)
	button:SetAttribute("qn-own", Slot(i))
	button:SetAttribute("action", Slot(i))
	button:SetAttribute("_childupdate-page", CHILD_PAGE)

	hooksecurefunc(button, "UpdateHotkeys", UpdateHotkey)
	hooksecurefunc(button, "Update", UpdateLook)

	-- additional lock against accidental dragging out: securely wrapped so that Blizzard's
	-- handler (PickupAction, SpellFlyout:Hide) runs untainted in combat too
	SecureHandlerWrapScript(button, "OnDragStart", bar, DRAG_LOCK)

	-- Key binding via a proxy: its template (SecureActionButton_OnClick) respects
	-- "cast on key down" (CVar ActionButtonUseKeyDown); the button itself treats every click
	-- as a mouse click and acts only on release. type=click then clicks the button (once).
	local key = CreateFrame("Button", "qnNumKeyPadKey" .. i, button, "SecureActionButtonTemplate")
	key:EnableMouse(false)
	key:RegisterForClicks("AnyDown", "AnyUp")
	key:SetAttribute("type", "click")
	key:SetAttribute("clickbutton", button)
	keys[i] = key

	buttons[i] = button
	return button
end

-- Save the position at the configured anchor: relative to UIParent (with qnViewPort possibly not
-- at 0,0), in UIParent units
local function SavePosition()
	local point = ns.db.point
	local x, y = qnCore.PointOffset(bar, point, point, true)
	if x then
		ns.store:SetValues({ x = Round(x), y = Round(y) })
	end
end

local function CreateOverlay()
	overlay = CreateFrame("Frame", nil, bar)
	overlay:SetAllPoints()
	overlay:SetFrameLevel(bar:GetFrameLevel() + 50)
	overlay:EnableMouse(true)
	overlay:RegisterForDrag("LeftButton")

	local tex = overlay:CreateTexture(nil, "BACKGROUND")
	tex:SetAllPoints()
	tex:SetColorTexture(0, 1, 0, 0.3)

	local text = overlay:CreateFontString(nil, "OVERLAY", "GameFontNormal")
	text:SetPoint("TOP", 0, -INSET - 2)
	text:SetText("qnNumKeyPad")

	overlay:SetScript("OnDragStart", function()
		if InCombatLockdown() then
			return
		end
		bar:StartMoving()
	end)
	overlay:SetScript("OnDragStop", function()
		bar:StopMovingOrSizing()
		if not InCombatLockdown() then
			SavePosition()   -- ns.Apply then triggers the visible-area check
		end
	end)
	overlay:SetScript("OnMouseUp", function(_, mouse)
		if mouse == "RightButton" then
			ns.OpenOptions()
		end
	end)
	overlay:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine("qnNumKeyPad")
		GameTooltip:AddLine(L["Left-click and drag: move"], 1, 1, 1)
		GameTooltip:AddLine(L["Right-click: options"], 1, 1, 1)
		GameTooltip:AddLine(L["/qnnkp lock: lock position"], 1, 1, 1)
		GameTooltip:Show()
	end)
	overlay:SetScript("OnLeave", GameTooltip_Hide)
	overlay:Hide()
end

local function CreateFader()
	fader = CreateFrame("Frame")
	local elapsed, lastOver = 0, 0
	local lastAlpha   -- last opacity set; nil = set on the next pass
	fader:SetScript("OnShow", function()
		lastAlpha = nil   -- without fading, ApplyCosmetic sets the opacity itself
	end)
	fader:SetScript("OnUpdate", function(_, e)
		elapsed = elapsed + e
		if elapsed < 0.05 then
			return
		end
		elapsed = 0
		local db = ns.db
		local now = GetTime()
		local over = bar:IsVisible() and (bar:IsMouseOver()
			or (SpellFlyout:IsShown() and SpellFlyout:IsMouseOver()))
		if over or cursorGrid or not db.locked then
			lastOver = now
		end
		local alpha = now - lastOver > db.fadeDelay and db.fadeAlpha or db.alpha
		if alpha ~= lastAlpha then
			lastAlpha = alpha
			bar:SetAlpha(alpha)
		end
	end)
	fader:Hide()
end

function ns.CreateBar()
	bar = CreateFrame("Frame", "qnNumKeyPadBar", UIParent, "SecureHandlerStateTemplate")
	ns.bar = bar
	bar:SetFrameStrata("MEDIUM")
	bar:SetClampedToScreen(true)
	bar:SetMovable(true)
	bar:SetDontSavePosition(true)
	bar:SetSize(BUTTON_SIZE * 4, BUTTON_SIZE * 5)
	bar:SetPoint("CENTER")
	bar:SetAttribute("_onstate-page", [[ self:ChildUpdate("page", newstate) ]])
	-- key bindings follow visibility, in combat too (vehicle, custom condition)
	SecureHandlerWrapScript(bar, "OnAttributeChanged", bar, ON_HIDDEN)

	bar.bg = bar:CreateTexture(nil, "BACKGROUND")
	bar.bg:SetAllPoints()
	bar.bg:SetColorTexture(0, 0, 0, 0)

	for i = 1, ns.MAX_BUTTONS do
		CreateButton(i)
	end
	CreateOverlay()
	CreateFader()

	-- Option autoVisible (qnCore): after loading, on a new window size and monitor arrangement;
	-- ns.Apply additionally checks after every change. If it moves the bar, SavePosition and
	-- ns.Apply trigger one more (then empty) check.
	ns.QueueVisibleCheck = qnCore.Visible.Keep(bar, function() return ns.db.autoVisible end, SavePosition)

	ns.events.Register("ACTIONBAR_SHOWGRID", function()
		cursorGrid = true
		ns.ApplyCosmetic()
	end)
	ns.events.Register("ACTIONBAR_HIDEGRID", function()
		cursorGrid = false
		ns.ApplyCosmetic()
	end)
	-- Hide the drag area in combat (no ApplyCosmetic here: InCombatLockdown() may still be false
	-- at PLAYER_REGEN_DISABLED); after combat Core shows it again.
	ns.events.Register("PLAYER_REGEN_DISABLED", function()
		overlay:Hide()
	end)
end

---------------------------------------------------------------------------
-- Apply
---------------------------------------------------------------------------

local function IsKeyShown(key)
	local db = ns.db
	return key.type == "Numeric"
		or (key.type == "Enter" and db.showEnter)
		or (key.type == "Nav" and db.showNav)
		or (key.type == "Arrow" and db.showArrow)
end
ns.IsKeyShown = IsKeyShown

local function ApplyLayout()
	local db = ns.db
	local layout = ns.GetLayout(db.layout)
	wipe(visibleKeys)

	local stepX, stepY = BUTTON_SIZE + db.padH, BUTTON_SIZE + db.padV
	local pos = {}
	local minX, minY, maxX, maxY = math.huge, math.huge, -math.huge, -math.huge
	for i, key in ipairs(layout.keys) do
		if IsKeyShown(key) then
			local x = (key.col - 1) * stepX
			if key.col < 1 then
				x = x - db.blockGap
			end
			local y = (key.row - 1) * stepY
			visibleKeys[i] = key
			pos[i] = { x, y }
			minX, minY = math.min(minX, x), math.min(minY, y)
			maxX, maxY = math.max(maxX, x + BUTTON_SIZE), math.max(maxY, y + BUTTON_SIZE)
		end
	end

	bar:SetSize(maxX - minX + 2 * INSET, maxY - minY + 2 * INSET)
	for i, button in ipairs(buttons) do
		button:SetAttribute("qn-own", Slot(i))
		local p = pos[i]
		if p then
			button:ClearAllPoints()
			button:SetPoint("TOPLEFT", bar, "TOPLEFT", INSET + p[1] - minX, -(INSET + p[2] - minY))
			button:Show()
		else
			button:Hide()
		end
	end
end

local function ApplyPosition()
	if keepPending then
		return   -- ns.KeepPosition converts the offsets first, after combat
	end
	local db = ns.db
	bar:SetScale(db.scale)
	local s = bar:GetScale()
	bar:ClearAllPoints()
	bar:SetPoint(db.point, UIParent, db.point, db.x / s, db.y / s)
end

-- Page for keys 1-12: modifier set (Ctrl and Alt together: neither), then the stance; nil = always 0.
local function PageDriver()
	local parts = {}
	local ctrl, alt = ns.SetPage("ctrl"), ns.SetPage("alt")
	if ctrl then
		parts[#parts + 1] = "[mod:ctrl,nomod:alt] " .. ctrl
	end
	if alt then
		parts[#parts + 1] = "[mod:alt,nomod:ctrl] " .. alt
	end
	if ns.db.stance then
		parts[#parts + 1] = "[bonusbar:1] 7; [bonusbar:2] 8; [bonusbar:3] 9; [bonusbar:4] 10; [bonusbar:5] 11"
	end
	if #parts == 0 then
		return nil
	end
	parts[#parts + 1] = "0"
	return table.concat(parts, "; ")
end

local function ApplyPaging()
	local driver = PageDriver()
	if driver then
		RegisterStateDriver(bar, "page", driver)
	else
		UnregisterStateDriver(bar, "page")
		bar:SetAttribute("state-page", "0")
	end
	-- own slots may have changed without the state changing
	SecureHandlerExecute(bar, [[ self:ChildUpdate("page", self:GetAttribute("state-page")) ]])
end

-- Stores the bindings as attributes of the bar; they are set in the secure environment (BIND) so
-- that the visibility driver can clear and restore them in combat too.
local function ApplyBindings()
	local db = ns.db
	local n = 0
	for i, key in pairs(visibleKeys) do
		n = n + 1
		bar:SetAttribute("qn-key" .. n, key.binding)
		bar:SetAttribute("qn-target" .. n, keys[i]:GetName())
		bar:SetAttribute("qn-mod" .. n, i <= NUM_ACTIONBAR_BUTTONS)
	end
	bar:SetAttribute("qn-count", n)
	bar:SetAttribute("qn-shift", db.bindShift)
	bar:SetAttribute("qn-ctrl", ns.SetPage("ctrl") ~= nil)
	bar:SetAttribute("qn-alt", ns.SetPage("alt") ~= nil)
	bar:SetAttribute("qn-enabled", db.enabled)
	bar:SetAttribute("qn-bound", nil)   -- rebind even if visibility does not change
	SecureHandlerExecute(bar, BIND)
end

local function VisibilityDriver()
	local db = ns.db
	if not db.locked then
		return "show"
	end
	if db.useCustom and strtrim(db.custom) ~= "" then
		return db.custom
	end
	local parts = {}
	local function Add(cond)
		parts[#parts + 1] = cond .. " hide"
	end
	if db.hideVehicle then Add("[vehicleui][overridebar][possessbar]") end
	if db.hideCombat then Add("[combat]") end
	if db.hideNoCombat then Add("[nocombat]") end
	if db.hidePet then Add("[pet]") end
	if db.hideNoPet then Add("[nopet]") end
	if db.hideStealth then Add("[stealth]") end
	if db.hideForm then Add("[form]") end
	parts[#parts + 1] = "show"
	return table.concat(parts, "; ")
end

local function ApplyVisibility()
	if ns.db.enabled then
		RegisterStateDriver(bar, "visibility", VisibilityDriver())
	else
		UnregisterStateDriver(bar, "visibility")
		bar:Hide()
	end
end

local function ApplyButtons()
	local db = ns.db
	-- for DRAG_LOCK (reads the bar as control)
	bar:SetAttribute("qn-lockall", db.lockActions)
	bar:SetAttribute("qn-lockcombat", db.lockInCombat)
	for _, button in ipairs(buttons) do
		button:EnableMouse(not db.clickThrough)
		-- the template's OnAttributeChanged calls UpdateFlyout
		button:SetAttribute("flyoutDirection", db.flyout)
	end
end

-- Unprotected display only; may run in combat too.
function ns.ApplyCosmetic()
	if not bar then
		return
	end
	local db = ns.db
	bar.bg:SetColorTexture(0, 0, 0, db.bgAlpha)
	fader:SetShown(db.fade)
	if not db.fade then
		bar:SetAlpha(db.alpha)
	end
	overlay:SetShown(db.enabled and not db.locked and not InCombatLockdown())
	for _, button in ipairs(buttons) do
		UpdateHotkey(button)
		UpdateLook(button)
	end
end

function ns.ApplyAll()
	ApplyLayout()
	ApplyPosition()
	ApplyPaging()
	ApplyBindings()
	ApplyButtons()
	ApplyVisibility()
	ns.ApplyCosmetic()
end

-- After an anchor change, convert the offsets so that the bar stays where it is.
-- In combat: after combat; until then ApplyPosition does not reposition the bar (otherwise it would
-- end up elsewhere with the new anchor and old offsets if an ns.Apply was already pending).
function ns.KeepPosition()
	if qnCore.DeferInCombat(ns.KeepPosition) then
		keepPending = true
		return
	end
	keepPending = false
	if bar:GetLeft() then
		SavePosition()
	else
		ns.Apply()
	end
end

-- page -> Blizzard action bar that uses the same slots
local PAGE_BARS = {
	[3] = "MultiBarRight", [4] = "MultiBarLeft", [5] = "MultiBarBottomRight",
	[6] = "MultiBarBottomLeft", [13] = "MultiBar5", [14] = "MultiBar6", [15] = "MultiBar7",
}

local lastWarning = ""   -- last warnings printed

-- Warns when used pages are assigned twice or occupied by a visible Blizzard action bar.
-- Reads the settings directly (not the applied bar) so that it is correct in combat too.
-- The same warnings appear only once in a row (e.g. login and profile switch).
function ns.CheckPages()
	local db = ns.db
	local used = {}   -- key group -> page; 4 and 5 = Ctrl and Alt set (keys 1-12)
	for i, key in ipairs(ns.GetLayout(db.layout).keys) do
		if IsKeyShown(key) then
			used[Group(i)] = db["page" .. Group(i)]
		end
	end
	used[4], used[5] = ns.SetPage("ctrl"), ns.SetPage("alt")
	local lines, seen = {}, {}
	for n = 1, 5 do
		local page = used[n]
		if page and not seen[page] then
			seen[page] = true
			for m = n + 1, 5 do
				if used[m] == page then
					lines[#lines + 1] = L["Warning: page %d is assigned to more than one key group."]:format(page)
					break
				end
			end
			local blizz = _G[PAGE_BARS[page] or ""]
			if page == 1 or (blizz and blizz:IsShown()) then
				lines[#lines + 1] = L["Warning: page %d is also used by a visible Blizzard action bar."]:format(page)
			end
		end
	end
	local text = table.concat(lines, "\n")
	if text ~= lastWarning then
		lastWarning = text
		for _, line in ipairs(lines) do
			ns.Print(line)
		end
	end
end

-- Button and slash command: move the bar into the visible area (with qnViewPort onto one
-- monitor), with feedback. Not in combat (protected).
function ns.MoveIntoVisible()
	if bar and qnCore.Visible.MoveAndReport(bar, L["Bar"], ns.Print) then
		SavePosition()   -- converts to the configured anchor
	end
end

function ns.ResetPosition()
	local d = ns.defaults
	ns.store:SetValues({ point = d.point, x = d.x, y = d.y })
end

-- Centers the bar horizontally or vertically, independent of the anchor.
function ns.CenterBar(horizontal)
	-- when centered, the bar's anchor point lies (0.5 - fraction) x (space beside the bar) away from the anchor
	local fx, fy = qnCore.AnchorFactors(ns.db.point)
	local s = bar:GetScale()
	local pw, ph = UIParent:GetSize()
	if horizontal then
		ns.store:Set("x", Round((0.5 - fx) * (pw - bar:GetWidth() * s)))
	else
		ns.store:Set("y", Round((0.5 - fy) * (ph - bar:GetHeight() * s)))
	end
end
