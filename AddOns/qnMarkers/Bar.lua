-- qnMarkers: the bar - grip, marker buttons, utility buttons, layout, visibility.
--
-- Structure: a protected frame (SecureHandlerStateTemplate) with secure action buttons for the
-- markers (Markers.lua) and normal buttons for ready check, pull timer and leaving the group.
-- Visibility runs through a state driver ([group], [group:raid]) so that it also works in combat;
-- everything else that changes the protected frames goes through ns.Apply() (deferred in combat).
-- The grip is the first button: dragging moves the bar, left-click minimizes it, right-click
-- clears all markers. The bar is anchored at its TOPLEFT, so the grip keeps its place.

local _, ns = ...
local L = ns.L
local lib = qnCore

local BUTTON_BG = { 0.055, 0.067, 0.082, 0.95 }
local GLOW_COLOR = { 1, 0.85, 0.1, 1 }
local LABEL_COLOR = { 0.88, 0.92, 0.96, 1 }
local UNAVAILABLE_ALPHA = 0.45
local GLOW_INTERVAL = 0.5     -- seconds between reading the active world markers

local DRIVERS = {
	always = "show",
	group = "[group] show; hide",
	raid = "[group:raid] show; hide",
}

local bar, grip, watcher
local items = {}       -- layout order: { kind = "button"/"sep", frame, key = setting that shows it, group }
local markers = {}     -- marker buttons in bar order
local dragged = false  -- the grip was dragged: the following click does not minimize

---------------------------------------------------------------------------
-- Look
---------------------------------------------------------------------------

-- Four 1-pixel edges around frame
local function Edges(frame, layer)
	local edges = {}
	local sides = { { "TOPLEFT", "TOPRIGHT" }, { "BOTTOMLEFT", "BOTTOMRIGHT" }, { "TOPLEFT", "BOTTOMLEFT" }, { "TOPRIGHT", "BOTTOMRIGHT" } }
	for i, side in ipairs(sides) do
		local t = frame:CreateTexture(nil, layer or "BORDER")
		t:SetPoint(side[1])
		t:SetPoint(side[2])
		if i <= 2 then
			t:SetHeight(1)
		else
			t:SetWidth(1)
		end
		edges[i] = t
	end
	return edges
end

local function ColorEdges(edges, r, g, b, a)
	for _, t in ipairs(edges) do
		t:SetColorTexture(r, g, b, a)
	end
end

local function Skin(button)
	button.bg = button:CreateTexture(nil, "BACKGROUND")
	button.bg:SetAllPoints()
	button.edges = Edges(button)
	local hl = button:CreateTexture(nil, "HIGHLIGHT")
	hl:SetAllPoints()
	hl:SetColorTexture(1, 1, 1, 0.15)
	button:SetHighlightTexture(hl)
end

local function Icon(button, file)
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(file)
	button.icon = icon
	return icon
end

-- Red cross over a dimmed icon: "clear"
local function ClearIcon(button, file)
	Icon(button, file):SetDesaturated(true)
	local cross = button:CreateTexture(nil, "OVERLAY")
	cross:SetTexture("Interface\\RaidFrame\\ReadyCheck-NotReady")
	cross:SetAllPoints(button.icon)
end

local function Label(button, text, color)
	local fs = button:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
	fs:SetAllPoints()
	fs:SetText(text)
	fs:SetTextColor(unpack(color or LABEL_COLOR))
	button.label = fs
	return fs
end

-- Tooltip with title and text (functions are read when shown); only with the option "Show Tooltips"
local function Tip(button, title, text)
	local function Value(v)
		if type(v) == "function" then
			return v()
		end
		return v
	end
	button:HookScript("OnEnter", function(self)
		if not ns.db.tooltips then
			return
		end
		GameTooltip:SetOwner(self, "ANCHOR_TOP")
		GameTooltip:AddLine(Value(title))
		local t = Value(text)
		if t then
			GameTooltip:AddLine(t, 1, 1, 1, true)
		end
		GameTooltip:Show()
	end)
	button:HookScript("OnLeave", GameTooltip_Hide)
end

---------------------------------------------------------------------------
-- World marker glow
---------------------------------------------------------------------------

-- Shows which world markers are placed (also those of other group members).
local function UpdateGlows()
	local world = ns.WorldMarkersEnabled()
	for _, button in ipairs(markers) do
		local active = world and ns.Plain(IsRaidMarkerActive(button.marker.world), false)
		button.glow:SetShown(active and true or false)
	end
end
ns.UpdateGlows = UpdateGlows

-- after a click the marker is placed only after targeting the ground: read again a bit later
local function UpdateGlowsSoon()
	C_Timer.After(0.2, UpdateGlows)
end

---------------------------------------------------------------------------
-- Creation (out of combat, on ADDON_LOADED)
---------------------------------------------------------------------------

local function AddItem(kind, frame, key, group)
	items[#items + 1] = { kind = kind, frame = frame, key = key, group = group }
end

local function AddSeparator(group)
	local t = bar:CreateTexture(nil, "ARTWORK")
	AddItem("sep", t, nil, group)
end

local function NewButton(name, secure, key, group)
	local button = CreateFrame("Button", name, bar, secure and "SecureActionButtonTemplate" or nil)
	Skin(button)
	AddItem("button", button, key, group)
	return button
end

local function CreateGrip()
	grip = CreateFrame("Button", "qnMarkersBarGrip", bar, "SecureActionButtonTemplate")
	Skin(grip)
	Label(grip, "-")
	-- secure actions of mouse clicks happen on release; down is registered for /click in key bindings
	grip:RegisterForClicks("AnyUp", "AnyDown")
	lib.UI.Movable(bar, {
		handle = grip,
		canMove = function() return not ns.db.locked and not InCombatLockdown() end,
		onStop = function()
			if not InCombatLockdown() then
				ns.SavePosition()
			end
		end,
	})
	grip:HookScript("OnDragStart", function()
		dragged = true
	end)
	grip:HookScript("PostClick", function(_, button, down)
		if down then
			return
		end
		if button == "LeftButton" then
			if not dragged then
				ns.store:Set("minimized", not ns.db.minimized)
			end
			dragged = false
		elseif button == "RightButton" then
			UpdateGlowsSoon()
		end
	end)
	Tip(grip, "qnMarkers", L["Drag: move bar\nLeft-click: minimize/expand\nRight-click: clear all world markers and the marker of your target"])
end

local function CreateMarkers()
	for i, marker in ipairs(ns.MARKERS) do
		local button = NewButton("qnMarkersBarMarker" .. i, true, nil, "markers")
		button.marker = marker
		button:RegisterForClicks("AnyUp", "AnyDown")
		Icon(button, ns.MarkerIcon(marker.target))
		local glow = button:CreateTexture(nil, "OVERLAY")
		glow:SetAllPoints()
		glow:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
		glow:SetBlendMode("ADD")
		glow:SetVertexColor(unpack(GLOW_COLOR))
		glow:Hide()
		button.glow = glow
		button:HookScript("PostClick", function(_, _, down)
			if not down then
				UpdateGlowsSoon()
			end
		end)
		Tip(button, _G["RAID_TARGET_" .. marker.target], function()
			if ns.WorldMarkersEnabled() then
				return L["Left-click: place world marker\nRight-click: set target marker"]
			end
			return L["Left- or right-click: set target marker\nWorld markers are not available."]
		end)
		markers[i] = button
	end
end

local function CreateUtility()
	local ready = NewButton("qnMarkersBarReady", false, "showReady", "utility")
	ready:RegisterForClicks("AnyUp")
	Icon(ready, "Interface\\RaidFrame\\ReadyCheck-Ready")
	ready:SetScript("OnClick", function()
		C_PartyInfo.DoReadyCheck()
	end)
	Tip(ready, READY_CHECK, L["Requires group leader or assistant."])

	for _, seconds in ipairs({ 5, 10 }) do
		local pull = NewButton("qnMarkersBarPull" .. seconds, false, "showPull" .. seconds, "utility")
		pull:RegisterForClicks("AnyUp")
		Label(pull, ("%d"):format(seconds))
		pull:SetScript("OnClick", function()
			C_PartyInfo.DoCountdown(seconds)
		end)
		Tip(pull, L["Pull timer: %d seconds"]:format(seconds), L["Requires group leader or assistant."])
	end

	local clearWorld = NewButton("qnMarkersBarClearWorld", true, "showClearWorld", "utility")
	clearWorld:RegisterForClicks("AnyUp", "AnyDown")
	ClearIcon(clearWorld, ns.MarkerIcon(6))
	ns.ConfigureClearWorld(clearWorld)
	clearWorld:HookScript("PostClick", function(_, _, down)
		if not down then
			UpdateGlowsSoon()
		end
	end)
	Tip(clearWorld, L["Clear world markers"], function()
		if ns.WorldMarkersEnabled() then
			return L["Removes all world markers."]
		end
		return L["World markers are not available."]
	end)
	bar.clearWorld = clearWorld

	local clearTarget = NewButton("qnMarkersBarClearTarget", true, "showClearTarget", "utility")
	clearTarget:RegisterForClicks("AnyUp", "AnyDown")
	ClearIcon(clearTarget, ns.MarkerIcon(8))
	ns.ConfigureClearTarget(clearTarget)
	Tip(clearTarget, L["Clear target marker"], L["Removes the marker from your current target."])

	local leave = NewButton("qnMarkersBarLeave", false, "showLeave", "utility")
	leave:RegisterForClicks("AnyUp")
	Label(leave, "X", { 1, 0.27, 0.27, 1 })   -- do not translate: symbol
	leave:SetScript("OnClick", function()
		if IsInGroup() then
			StaticPopup_Show("QNMARKERS_LEAVE")
		end
	end)
	Tip(leave, PARTY_LEAVE, L["Asks for confirmation first."])
	lib.Popup.Confirm("QNMARKERS_LEAVE", L["Leave the current group?"], PARTY_LEAVE, function()
		C_PartyInfo.LeaveParty()
	end)
end

function ns.CreateBar()
	bar = CreateFrame("Frame", "qnMarkersBar", UIParent, "SecureHandlerStateTemplate")
	ns.bar = bar
	bar:SetFrameStrata("MEDIUM")
	bar:SetDontSavePosition(true)
	bar:SetSize(100, 30)
	bar:SetPoint("TOPLEFT", UIParent, "TOPLEFT", ns.defaults.x, ns.defaults.y)
	bar.bg = bar:CreateTexture(nil, "BACKGROUND")
	bar.bg:SetAllPoints()
	bar.edges = Edges(bar)

	CreateGrip()
	AddSeparator("markers")
	CreateMarkers()
	AddSeparator("utility")
	CreateUtility()

	-- reads the placed world markers while the bar is visible (OnUpdate runs only then)
	watcher = CreateFrame("Frame", nil, bar)
	watcher:SetScript("OnUpdate", (lib.Throttle(GLOW_INTERVAL, UpdateGlows)))

	-- Option autoVisible (qnCore): after loading, on a new window size and monitor arrangement;
	-- ns.Apply additionally checks after every change.
	ns.QueueVisibleCheck = lib.Visible.Keep(bar, function() return ns.db.autoVisible end, ns.SavePosition)
end

---------------------------------------------------------------------------
-- Apply
---------------------------------------------------------------------------

-- Padding between the edge of the bar and the buttons
local function Pad()
	return math.max(2, ns.db.gap * 2)
end

-- Shown buttons of a group (separators only between non-empty groups)
local function GroupHasButtons(group)
	for _, item in ipairs(items) do
		if item.kind == "button" and item.group == group and (not item.key or ns.db[item.key]) then
			return true
		end
	end
	return false
end

local function ApplyLayout()
	local db = ns.db
	local vertical = db.orientation == "vertical"
	local size, gap, pad = db.size, db.gap, Pad()
	local inset = math.max(2, lib.Round(size * 0.08))

	local function Place(frame, cursor, length, thickness)
		frame:ClearAllPoints()
		if vertical then
			frame:SetSize(thickness, length)
			frame:SetPoint("TOP", bar, "TOP", 0, -cursor)
		else
			frame:SetSize(length, thickness)
			frame:SetPoint("LEFT", bar, "LEFT", cursor, 0)
		end
	end

	Place(grip, pad, size, size)
	local cursor = pad + size
	for _, item in ipairs(items) do
		local frame = item.frame
		local shown
		if item.kind == "sep" then
			shown = not db.floating and GroupHasButtons(item.group)
		else
			shown = not item.key or db[item.key]
		end
		shown = shown and not db.minimized
		if shown then
			cursor = cursor + gap
			if item.kind == "sep" then
				Place(frame, cursor, 1, size - 4)
				cursor = cursor + 1
			else
				Place(frame, cursor, size, size)
				if frame.icon then
					frame.icon:ClearAllPoints()
					frame.icon:SetPoint("TOPLEFT", frame, "TOPLEFT", inset, -inset)
					frame.icon:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -inset, inset)
				end
				cursor = cursor + size
			end
			frame:Show()
		else
			frame:Hide()
		end
	end

	local length, thickness = cursor + pad, size + 2 * pad
	if vertical then
		bar:SetSize(thickness, length)
	else
		bar:SetSize(length, thickness)
	end
end

local function ApplyAttributes()
	for _, button in ipairs(markers) do
		ns.ConfigureMarker(button, button.marker)
	end
	ns.ConfigureClearAll(grip)
end

local function ApplyPosition()
	local db = ns.db
	bar:SetScale(db.scale)
	lib.RestorePoint(bar, { "TOPLEFT", "TOPLEFT", db.x, db.y })
end

-- true if the player may use the leader functions (group leader or raid assistant)
function ns.IsLeaderOrAssistant()
	if not IsInGroup() then
		return false
	end
	return ns.Plain(UnitIsGroupLeader("player"), false) or ns.Plain(UnitIsGroupAssistant("player"), false) or false
end

-- Visibility driver text of the settings ("hide" = bar hidden)
function ns.VisibilityDriver()
	local db = ns.db
	if not db.shown or (db.leaderOnly and not ns.IsLeaderOrAssistant()) then
		return "hide"
	end
	return DRIVERS[db.visibility] or DRIVERS.always
end

function ns.ApplyVisibility()
	RegisterStateDriver(bar, "visibility", ns.VisibilityDriver())
end

-- Unprotected display only; may run in combat too.
function ns.ApplyCosmetic()
	if not bar then
		return
	end
	local db = ns.db
	local br, bg_, bb, ba = lib.UnpackColor(db.borderColor)
	local cr, cg, cb, ca = lib.UnpackColor(db.bgColor)
	bar.bg:SetColorTexture(cr, cg, cb, db.floating and 0 or ca)
	ColorEdges(bar.edges, br, bg_, bb, db.floating and 0 or ba)
	for _, item in ipairs(items) do
		local frame = item.frame
		if item.kind == "sep" then
			frame:SetColorTexture(br, bg_, bb, 0.6)
		else
			frame.bg:SetColorTexture(unpack(BUTTON_BG))
			ColorEdges(frame.edges, br, bg_, bb, 0.9)
		end
	end
	-- the grip is part of the bar: in floating mode without its own background
	grip.bg:SetColorTexture(BUTTON_BG[1], BUTTON_BG[2], BUTTON_BG[3], db.floating and 0 or BUTTON_BG[4])
	ColorEdges(grip.edges, br, bg_, bb, db.floating and 0 or 0.9)
	grip.label:SetText(db.minimized and "+" or "-")
	UpdateGlows()
end

function ns.ApplyAll()
	ApplyLayout()
	ApplyAttributes()
	bar.clearWorld:SetAlpha(ns.WorldMarkersEnabled() and 1 or UNAVAILABLE_ALPHA)
	ApplyPosition()
	ns.ApplyVisibility()
	ns.ApplyCosmetic()
end

---------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------

-- Save the position (TOPLEFT relative to UIParent, with qnViewPort possibly not at 0,0) in
-- UIParent units; ns.Apply then sets it again and triggers the visible-area check.
function ns.SavePosition()
	local p = lib.SavePoint(bar, "TOPLEFT", "TOPLEFT")
	if p then
		ns.store:SetValues({ x = p[3], y = p[4] })
	end
end

function ns.ResetPosition()
	ns.store:SetValues({ x = ns.defaults.x, y = ns.defaults.y })
end

-- Button and slash command: move the bar into the visible area (with qnViewPort onto one
-- monitor), with feedback. Not in combat (protected).
function ns.MoveIntoVisible()
	if bar and lib.Visible.MoveAndReport(bar, L["Bar"], ns.Print) then
		ns.SavePosition()
	end
end
