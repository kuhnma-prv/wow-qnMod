-- qnViewPort: Titan Panel on the monitors (only if Titan is loaded, ## OptionalDeps: Titan).
--   * The full-width Titan bars (top: Bar, Bar2; bottom: AuxBar, AuxBar2) lie on a
--     selectable monitor instead of across the whole game window.
--   * Tooltips and control frames of Titan plugins stay on the plugin's monitor.
--   * A scale factor per monitor for bars, plugins and Titan's tooltip (in addition to Titan's
--     own scale), e.g. for monitors with different pixel density.
-- Titan attaches the bars to UIParent with two anchors. Here, in Titan's static table
-- TitanBarData, the reference frame (show.rel_fr, bott.rel_fr) is replaced by an anchor frame of our own
-- per bar. It lies over the chosen monitor or – without a selection – exactly over UIParent, then
-- everything stays as with Titan. Titan itself is not modified; only the width of the
-- auto-hide bar, the position of hidden bars, and tooltips and control frames are adjusted.
-- Settings: ns.db.titan (per profile), monitor numbers as on the "Monitors" page.

local _, ns = ...
local L = ns.L
local UI = qnCore.UI

local Titan = {}
ns.Titan = Titan

-- In Titan the second bar lies one bar height further inside than the first (Titan default
-- off_y). If the first is not at the same edge, the second moves to the edge
-- (dir: +1 upward, -1 downward).
Titan.BARS = {
	{ name = "Bar" },
	{ name = "Bar2", partner = "Bar", dir = 1 },
	{ name = "AuxBar" },
	{ name = "AuxBar2", partner = "AuxBar", dir = -1 },
}

local byFrame = {}
local anchors = {}
Titan.anchors = anchors

local function DB()
	return ns.db.titan
end

local function FrameName(bar)
	return TITAN_PANEL_DISPLAY_PREFIX .. bar
end

---------------------------------------------------------------------------
-- Monitors (same numbers as ns.Layout.GetVisible)
---------------------------------------------------------------------------

-- Rectangles { l, r, t, b } at scale 1, origin bottom left
function Titan.Monitors()
	return ns.Layout.GetVisibleAbs()
end

-- chosen monitor of a bar: rectangle, number; nil = as Titan (also if the monitor is missing)
local function MonitorOf(bar)
	local i = tonumber(DB()[bar]) or 0
	local r = i > 0 and Titan.Monitors()[i]
	if r then
		return r, i
	end
end

---------------------------------------------------------------------------
-- Bar anchors
---------------------------------------------------------------------------

-- bar turned on by the player (Titan setting, also with auto-hide)
local function BarShown(bar)
	local vars = TitanBarDataVars and TitanBarDataVars[FrameName(bar)]
	return vars and vars.show
end

-- Area a bar is aligned to
local function AreaOf(bar)
	return MonitorOf(bar) or qnCore.Visible.FrameAbs(UIParent)
end

-- Offset of the second bar (units at scale 1): 0 if the first bar is turned on
-- and lies at the same edge of the same area, otherwise one bar height towards the edge.
local function Shift(b, r)
	if not b.partner then
		return 0
	end
	local p = BarShown(b.partner) and AreaOf(b.partner)
	if p and p.l < r.r and p.r > r.l then
		local edge = b.dir > 0 and math.abs(p.t - r.t) or math.abs(p.b - r.b)
		if edge < 1 then
			return 0
		end
	end
	local f = _G[FrameName(b.name)]
	return b.dir * TITAN_PANEL_BAR_HEIGHT * (f and f:GetEffectiveScale() or 1)
end

local function UpdateAnchor(b)
	local a = anchors[b.name]
	local r = MonitorOf(b.name)
	a:ClearAllPoints()
	if not r then
		a:SetAllPoints(UIParent)
		return
	end
	a:SetPoint("BOTTOMLEFT", ns.screenRef, "BOTTOMLEFT", r.l, r.b + Shift(b, r))
	a:SetSize(r.r - r.l, r.t - r.b)
end

function Titan.UpdateAnchors()
	for _, b in ipairs(Titan.BARS) do
		UpdateAnchor(b)
	end
end

-- Auto-hide bar: Titan sets it once to the width of UIParent and the height of a bar
-- without scaling. Here: width of the area, height of the (scaled) bar.
local function FixHider(b)
	local data = TitanBarData[FrameName(b.name)]
	local hider = data and data.hider and _G[data.hider]
	local w = anchors[b.name]:GetWidth()
	if hider and w and w > 0 then
		local s = hider:GetEffectiveScale()
		local display = _G[FrameName(b.name)]
		hider:SetSize(w / s, TITAN_PANEL_BAR_HEIGHT * (display and display:GetEffectiveScale() or s) / s)
	end
end

-- Hidden bar: Titan moves it by hide_y above or below its reference frame. With a
-- monitor, another monitor may be there – hence beyond the game window.
local function ParkHidden(b)
	local display = _G[FrameName(b.name)]
	if not display then
		return
	end
	local s = display:GetEffectiveScale()
	display:ClearAllPoints()
	display:SetPoint("BOTTOMLEFT", ns.screenRef, "TOPLEFT", 0, TITAN_PANEL_BAR_HEIGHT * 4)
	display:SetSize(anchors[b.name]:GetWidth() / s, TITAN_PANEL_BAR_HEIGHT)
end

local function TitanReady()
	return Titan__InitializedPEW and TitanBarDataVars and TitanBarDataVars[FrameName("Bar")] ~= nil
end

---------------------------------------------------------------------------
-- Scale per monitor
-- Titan sets the scale of each bar and each plugin itself (SetScale with its value
-- "Scale"; plugins are not children of the bars). The method of these frames is therefore
-- replaced so that the monitor's factor is added.
---------------------------------------------------------------------------

local fullBars = {}
for _, b in ipairs(Titan.BARS) do
	fullBars[b.name] = true
end

-- Factor of a monitor (number as on the "Monitors" page); without a monitor 1
function Titan.MonitorScale(i)
	local t = DB().scale
	local v = i and type(t) == "table" and tonumber(t[i])
	return v and v > 0 and v or 1
end

local function BarFactor(bar)
	local _, i = MonitorOf(bar)
	return Titan.MonitorScale(i)
end

-- Factor of a plugin: that of its bar if it lies on a full-width bar
local function PluginFactor(button)
	local id = button and TitanUtils_GetButtonID(button:GetName())
	local bar = id and TitanUtils_GetWhichBar(id)
	return fullBars[bar] and BarFactor(bar) or 1
end

local function WrapScale(frame, factor)
	if not frame or frame.qnViewPortSetScale then
		return
	end
	local orig = frame.SetScale
	frame.qnViewPortSetScale = orig
	frame.SetScale = function(self, s)
		orig(self, s * factor(self))
	end
end

-- After Titan refreshes a plugin. Titan itself only scales plugins with text; with factor 1
-- that is left alone, otherwise (or after the factor changed) it is set here.
local function ScalePlugin(id)
	local button = TitanUtils_GetButton(id)
	if not button then
		return
	end
	WrapScale(button, PluginFactor)
	local f = PluginFactor(button)
	if f ~= 1 or (button.qnViewPortFactor or 1) ~= 1 then
		button.qnViewPortFactor = f
		button.qnViewPortSetScale(button, (TitanPanelGetVar("Scale") or 1) * f)
	end
end

-- Titan's own tooltip on the plugin: Titan's size times the plugin's factor
local function ScaleTooltip(button)
	local _, rel = TitanPanelTooltip:GetPoint(1)
	if rel ~= button then
		return
	end
	local base = TitanPanelGetVar("DisableTooltipFont") and 1 or (TitanPanelGetVar("TooltipFont") or 1)
	TitanPanelTooltip:SetScale(base * PluginFactor(button))
end

-- Set the anchors and let Titan re-arrange and rescale bars and plugins
-- (profile switch, new layout, options)
function Titan.Apply()
	if not Titan.active then
		return
	end
	Titan.UpdateAnchors()
	if TitanReady() then
		TitanPanel_InitPanelButtons("qnViewPort")
	end
	Titan.RefreshOptions()
end

local ApplySoon = qnCore.Debounce(function()
	Titan.Apply()
end, 0.1)

---------------------------------------------------------------------------
-- Tooltips and control frames
-- Titan chooses a tooltip's side by GetScreenWidth() or UIParent (TitanTemplate.lua,
-- SetPanelTooltip; TitanUtils_GetOffscreen), i.e. by the whole game window. At the edge of a
-- monitor the tooltip then reaches into a part of the window that is not visible on any monitor.
---------------------------------------------------------------------------

-- Re-anchors tip to the plugin button if Titan anchored it there and it extends beyond the monitor
-- (shared with the bag slots: ns.Layout.FitToMonitor).
function Titan.FitToMonitor(tip, button)
	ns.Layout.FitToMonitor(tip, button)
end

-- Frames Titan attaches to a plugin: its own tooltip, GameTooltip (older plugins),
-- tooltip frame of an LDB object (.tooltip)
local function Fit(button)
	if not button then
		return
	end
	ScaleTooltip(button)
	Titan.FitToMonitor(TitanPanelTooltip, button)
	Titan.FitToMonitor(GameTooltip, button)
	local id = button.registry and button.registry.id
	local plugin = id and TitanUtils_GetPlugin(id)
	if plugin and plugin.tooltipDisplayFrame then
		Titan.FitToMonitor(plugin.tooltipDisplayFrame, button)
	end
end

-- immediately and once more in the next frame (then the tooltip has its final size)
local function FitNowAndLater(button)
	Fit(button)
	C_Timer.After(0, function()
		Fit(button)
	end)
end

---------------------------------------------------------------------------
-- Options page (subcategory "Titan Panel", only with Titan)
---------------------------------------------------------------------------

local ui, page   -- qnCore.UI.Page and its content (parent of the controls)
local dropdowns = {}

-- Entries of a dropdown; a saved monitor that no longer exists stays visible.
function Titan.Entries(bar)
	local list = { { 0, L["As Titan (entire UI)"] } }
	local monitors = ns.Layout.GetVisible()
	for i, r in ipairs(monitors) do
		list[#list + 1] = { i, L["Monitor %d (%d × %d)"]:format(i, r.w, r.h) }
	end
	local saved = tonumber(DB()[bar]) or 0
	if saved > #monitors then
		list[#list + 1] = { saved, L["Monitor %d (not present)"]:format(saved) }
	end
	return list
end

-- "Scale" slider per monitor; created as soon as the monitor is present for the first time
local sliders = {}
local scaleText

local function SetMonitorScale(i, percent)
	local t = DB().scale
	if type(t) ~= "table" then
		t = {}
		DB().scale = t
	end
	local v = math.floor(percent / 5 + 0.5) * 5 / 100
	if v ~= Titan.MonitorScale(i) then
		t[i] = v
		ApplySoon()
	end
end

local function ScaleSlider(i)
	local s = sliders[i]
	if s then
		return s
	end
	s = CreateFrame("Frame", nil, page, "MinimalSliderWithSteppersTemplate")
	s:SetSize(220, 20)
	if i == 1 then
		s:SetPoint("TOPLEFT", scaleText, "BOTTOMLEFT", 164, -14)
	else
		s:SetPoint("TOPLEFT", sliders[i - 1], "BOTTOMLEFT", 0, -10)
	end
	s.label = UI.Label(page, s, "")
	s:Init(100, 50, 200, 30, {
		[MinimalSliderWithSteppersMixin.Label.Right] = function(v)
			return ("%d %%"):format(v + 0.5)
		end,
	})
	s:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
		if not s.quiet then
			SetMonitorScale(i, value)
		end
	end, s)
	sliders[i] = s
	return s
end

function Titan.RefreshOptions()
	for _, dd in ipairs(dropdowns) do
		dd:Refresh()
	end
	if not scaleText then
		return
	end
	local monitors = ns.Layout.GetVisible()
	for i, r in ipairs(monitors) do
		local s = ScaleSlider(i)
		s.label:SetText(L["Monitor %d (%d × %d)"]:format(i, r.w, r.h))
		s.quiet = true
		s:SetValue(Titan.MonitorScale(i) * 100)
		s.quiet = false
		s:Show()
		s.label:Show()
	end
	for i = #monitors + 1, #sliders do
		sliders[i]:Hide()
		sliders[i].label:Hide()
	end
	ui.Fit()
end

local function BuildPage()
	local anchor = ui.top
	for i, b in ipairs(Titan.BARS) do
		local data = TitanBarData[FrameName(b.name)]
		local dd = UI.Dropdown(page, 240, function() return Titan.Entries(b.name) end,
			function() return tonumber(DB()[b.name]) or 0 end,
			function(v)
				DB()[b.name] = v
				Titan.Apply()
			end)
		dd:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", i == 1 and 164 or 0, i == 1 and -16 or -10)
		UI.Label(page, dd, data and data.locale_name or b.name)
		UI.Tooltip(dd, data and data.locale_name or b.name, L["Numbers as on the \"Monitors\" page."])
		dropdowns[#dropdowns + 1] = dd
		anchor = dd
	end

	local apply = UI.Button(page, APPLY, 160, Titan.Apply,
		L["Places the bars on their monitors again, e.g. after the monitor arrangement has changed."])
	apply:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", -160, -16)

	local scaleHead = UI.Text(page, "GameFontNormal", L["Scale per monitor"])
	scaleHead:SetPoint("TOPLEFT", apply, "BOTTOMLEFT", -4, -22)
	scaleText = UI.Text(page, "GameFontHighlightSmall",
		L["Size of Titan's bars, plugins and tooltips on this monitor, in addition to Titan's own scale. For monitors with different pixel density, e.g. about 65 % for a monitor at 100 % Windows scaling next to a main monitor at 150 %."])
	scaleText:SetPoint("TOPLEFT", scaleHead, "BOTTOMLEFT", 0, -6)
	scaleText:SetWidth(600)
end

---------------------------------------------------------------------------
-- Start (from Core.lua after ADDON_LOADED)
---------------------------------------------------------------------------

-- Without Titan: no anchors, no hooks, no options page.
function ns.InitTitan()
	if not (C_AddOns.IsAddOnLoaded("Titan") and TitanBarData and TITAN_PANEL_DISPLAY_PREFIX) then
		return
	end
	Titan.active = true

	for _, b in ipairs(Titan.BARS) do
		local a = CreateFrame("Frame", "qnViewPortTitanAnchor" .. b.name)
		a:SetAllPoints(UIParent)
		anchors[b.name] = a
		byFrame[FrameName(b.name)] = b
		local data = TitanBarData[FrameName(b.name)]
		if data then
			data.show.rel_fr = a
			data.bott.rel_fr = a
		end
	end
	-- Titan creates the bars only when entering the world (SetupTitan → TitanPanelButton_CreateBar)
	local function WrapBar(frame)
		local b = byFrame[frame]
		if b then
			WrapScale(_G[frame], function()
				return BarFactor(b.name)
			end)
		end
	end
	for frame in pairs(byFrame) do
		WrapBar(frame)
	end
	hooksecurefunc("TitanPanelButton_CreateBar", WrapBar)
	Titan.UpdateAnchors()
	hooksecurefunc("TitanPanelButton_UpdateButton", ScalePlugin)

	-- After Titan shows a bar: update the anchors (the second bar depends on the state of the first).
	hooksecurefunc("TitanPanelBarButton_Show", function(frame)
		local b = byFrame[frame]
		if b then
			Titan.UpdateAnchors()
			FixHider(b)
		end
	end)
	hooksecurefunc("TitanPanelBarButton_Hide", function(frame)
		local b = byFrame[frame]
		if not b or TITAN_PANEL_MOVING == 1 then
			return
		end
		Titan.UpdateAnchors()
		FixHider(b)
		if MonitorOf(b.name) then
			ParkHidden(b)
		end
	end)

	hooksecurefunc("TitanPanelButton_OnEnter", FitNowAndLater)
	-- Titan recreates the tooltip on refresh (e.g. the clock every second)
	hooksecurefunc("TitanPanelButton_UpdateTooltip", Fit)
	hooksecurefunc("TitanPanelPluginHandle_OnUpdate", function(t)
		local id = type(t) == "table" and t[1] or t
		Fit(type(id) == "string" and _G[TitanUtils_ButtonName(id)] or nil)
	end)
	-- Control frames (left click, e.g. volume, clock offset): Titan only checks against UIParent.
	hooksecurefunc("TitanPanelButton_OnClick", function(button)
		local id = button and button.registry and button.registry.id
		local frame = id and TitanUtils_GetControlFrame(id)
		if frame and frame:IsShown() then
			Titan.FitToMonitor(frame, button)
		end
	end)

	qnCore.Visible.OnAreaChanged(ApplySoon)
	for _, event in ipairs({ "PLAYER_ENTERING_WORLD", "UI_SCALE_CHANGED", "DISPLAY_SIZE_CHANGED" }) do
		ns.events.Register(event, ApplySoon)
	end

	ui = UI.Page("Titan Panel", { desc =
		L["Places the full-width Titan bars on the top or bottom edge of a monitor. They are still turned on and off in Titan. Tooltips of Titan plugins stay on the plugin's monitor."] })
	page = ui.content
	ui.panel:SetScript("OnShow", Titan.RefreshOptions)
	BuildPage()
	Titan.category = Settings.RegisterCanvasLayoutSubcategory(ns.category, ui.panel, "Titan Panel")
end
