-- Scenario 4: qnViewPort with Titan – full-width Titan bars on a selected monitor,
-- tooltips at the monitor edge. Titan itself is emulated (only what qnViewPort touches):
-- TitanBarData, TitanBarDataVars, Titan_G.bars.Show/Hide/ShowPlugins as in (Titan 9.3)
-- Titan.lua (SetBar, _Hide). Without Titan: scenario 5.

qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { global = {}, profiles = {
	["account:Raid"] = { titan = { AuxBar = 2 } },
	["preset:1"] = { titan = { AuxBar = 0 } },
} }

---------------------------------------------------------------------------
-- Titan emulation
---------------------------------------------------------------------------
Titan_G = { InitializedPEW = false, bars = { PRE_STR = "Titan_Bar__Display_", HEIGHT = 24 }, plugins = {} }
TITAN_PANEL_MOVING = 0
local P = Titan_G.bars.PRE_STR
local DEF = {
	Bar = { "Oben", "TOPLEFT", "TOPLEFT", "BOTTOMRIGHT", "TOPRIGHT", 0, 72 },
	Bar2 = { "Oben 2", "TOPLEFT", "TOPLEFT", "BOTTOMRIGHT", "TOPRIGHT", -24, 240 },
	AuxBar2 = { "Unten 2", "TOPLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", 48, -48 },
	AuxBar = { "Unten", "TOPLEFT", "BOTTOMLEFT", "BOTTOMRIGHT", "BOTTOMRIGHT", 24, -72 },
}
TitanBarData = {}
TitanBarDataVars = {}   -- Titan fills it only when entering the world
local vars = {}
for name, d in pairs(DEF) do
	TitanBarData[P .. name] = {
		name = name, locale_name = d[1], hider = "Titan_Bar__Hider_" .. name, hide_y = d[7],
		show = { pt = d[2], rel_fr = "UIParent", rel_pt = d[3] },
		bott = { pt = d[4], rel_fr = "UIParent", rel_pt = d[5] },
	}
	vars[P .. name] = { off_x = 0, off_y = d[6], show = false, auto_hide = false }
end
-- Titan creates the bar and auto-hide bar only when entering the world (SetupTitan)
function Titan_G.bars.CreateBar(frame_str)
	CreateFrame("Button", frame_str, UIParent)
	CreateFrame("Button", TitanBarData[frame_str].hider, UIParent)._w = 1920
end
function Titan_G.bars.Show(frame)
	local data, v = TitanBarData[frame], TitanBarDataVars[frame]
	local display = _G[frame]
	display:ClearAllPoints()
	display:SetPoint(data.show.pt, data.show.rel_fr, data.show.rel_pt, v.off_x, v.off_y)
	display:SetPoint(data.bott.pt, data.bott.rel_fr, data.bott.rel_pt, v.off_x, v.off_y - Titan_G.bars.HEIGHT)
	_G[data.hider]:Hide()
end
function Titan_G.bars.Hide(frame)
	if TITAN_PANEL_MOVING == 1 then return end
	local data, v = TitanBarData[frame], TitanBarDataVars[frame]
	local display = _G[frame]
	display:ClearAllPoints()
	display:SetPoint(data.show.pt, data.show.rel_fr, data.show.rel_pt, v.off_x, data.hide_y)
	local hider = _G[data.hider]
	if v.show and v.auto_hide then
		hider:ClearAllPoints()
		hider:SetPoint(data.show.pt, data.show.rel_fr, data.show.rel_pt, v.off_x, v.off_y)
		hider:Show()
	else
		hider:Hide()
	end
end
local shows = 0
function Titan_G.bars.DisplayBarsWanted(reason)
	shows = shows + 1
	for frame, v in pairs(TitanBarDataVars) do
		if v.show and not v.auto_hide then
			Titan_G.bars.Show(frame)
		else
			Titan_G.bars.Hide(frame)
		end
	end
end

-- plugins and tooltips (TitanTemplate.lua): only the global functions qnViewPort hooks into
TitanPanelTooltip = CreateFrame("GameTooltip", "TitanPanelTooltip", UIParent)
local plugins, controls = {}, {}
function TitanUtils_GetPlugin(id) return plugins[id] end
function TitanUtils_ButtonName(id) return "TitanPanel" .. id .. "Button" end
function TitanUtils_GetControlFrame(id) return controls[id] end
function Titan_G.plugins.OnEnter(self) end
function Titan_G.plugins.UpdateTooltip(self) end
function Titan_G.plugins.OnUpdate(t, oldarg) end
function Titan_G.plugins.OnClick(self, button) end

-- scaling (Titan.lua, TitanTemplate.lua): Titan calls SetScale on bars and text plugins
local TITAN_VARS = { Scale = 1, TooltipFont = 1 }
function TitanPanelGetVar(k) return TITAN_VARS[k] end
local pluginBar = {}   -- [id] = short name of the bar
function TitanUtils_GetButton(id) return _G["TitanPanel" .. id .. "Button"], id end
function TitanUtils_GetButtonID(name) return name and name:match("^TitanPanel(.*)Button$") end
function TitanUtils_GetWhichBar(id) return pluginBar[id] end
function Titan_G.plugins.UpdateButton(id)
	local b = TitanUtils_GetButton(id)
	if b and b.textPlugin then
		b:SetScale(TitanPanelGetVar("Scale"))
	end
end
function Titan_G.bars.ShowPlugins(reason)
	for frame in pairs(TitanBarData) do
		_G[frame]:SetScale(TitanPanelGetVar("Scale"))
	end
	Titan_G.bars.DisplayBarsWanted(reason)
	for id in pairs(pluginBar) do
		Titan_G.plugins.UpdateButton(id)
	end
end

---------------------------------------------------------------------------
-- loading; monitors like qnViewPort (5760 × 2160, 2nd monitor 1920 × 1200 at y 377)
---------------------------------------------------------------------------
local isLoaded = C_AddOns.IsAddOnLoaded
C_AddOns.IsAddOnLoaded = function(name) return name == "Titan" or isLoaded(name) end
LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
local tt, L = vp.Titan, vp.L
-- monitors like Monitors.lua; 1 unit = 1 pixel (abs = pixels, origin bottom left)
local M1 = { l = 0, r = 3840, t = 2160, b = 0 }
local M2 = { l = 3840, r = 5760, t = 2160 - 377, b = 2160 - 377 - 1200 }
local PX = { { x = 0, y = 0, w = 3840, h = 2160 }, { x = 3840, y = 377, w = 1920, h = 1200 } }
local function SetMonitors(n)
	vp.Layout.GetVisibleAbs = function() return n == 1 and { M1 } or { M1, M2 } end
	vp.Layout.GetVisible = function() return n == 1 and { PX[1] } or PX end
end
SetMonitors(2)
local screen = vp.screenRef

Check(tt.active and tt.category ~= nil, "with Titan: active, subpage 'Titan Panel' created")
for name in pairs(DEF) do
	Check(TitanBarData[P .. name].show.rel_fr == _G["qnViewPortTitanAnchor" .. name]
		and TitanBarData[P .. name].bott.rel_fr == _G["qnViewPortTitanAnchor" .. name], "reference frame replaced: " .. name)
end
-- like SetupTitan when entering the world, i.e. after qnViewPort
for frame in pairs(TitanBarData) do
	Titan_G.bars.CreateBar(frame)
end
local wrapped = true
for frame in pairs(TitanBarData) do
	wrapped = wrapped and _G[frame].qnViewPortSetScale ~= nil
end
Check(wrapped, "bars created only after qnViewPort get the monitor's factor")
local function Set(bar, v)
	vp.db.titan[bar] = v
	tt.Apply()
end

FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
Check(shows == 0, "no display via Titan before Titan starts")
TitanBarDataVars = vars
Titan_G.InitializedPEW = true
vars[P .. "Bar"].show = true
vars[P .. "AuxBar"].show = true

local function Anchor(name)
	return _G["qnViewPortTitanAnchor" .. name]._points
end
local function OnMonitor(name, r, dy)
	local p = Anchor(name)
	local a = _G["qnViewPortTitanAnchor" .. name]
	return #p == 1 and p[1][1] == "BOTTOMLEFT" and p[1][2] == screen and p[1][4] == r.l and p[1][5] == r.b + (dy or 0)
		and a._w == r.r - r.l and a._h == r.t - r.b
end
local function Whole(name)
	local p = Anchor(name)
	return #p == 1 and p[1][1] == "ALL" and p[1][2] == UIParent
end

---------------------------------------------------------------------------
-- profile "account:Raid": bottom bar on monitor 2
---------------------------------------------------------------------------
tt.Apply()
Check(shows == 1, "Apply makes Titan show the bars again")
Check(OnMonitor("AuxBar", M2), "Bottom on monitor 2")
Check(Whole("Bar") and Whole("Bar2"), "without selection like Titan (anchor = UIParent)")
local d = _G[P .. "AuxBar"]._points
Check(d[1][2] == qnViewPortTitanAnchorAuxBar and d[2][2] == qnViewPortTitanAnchorAuxBar and d[1][5] == 24,
	"Titan places the bar at the anchor (Titan's offset)")
Check(_G["Titan_Bar__Hider_AuxBar"]._w == 1920, "auto-hide bar at monitor width")

-- top bars
Set("Bar", 2)
Check(OnMonitor("Bar", M2), "Top on monitor 2")
vars[P .. "Bar2"].show = true
Set("Bar2", 1)
Check(OnMonitor("Bar2", M1, 24), "Top 2 alone on monitor 1: moved to the edge")
Set("Bar2", 2)
Check(OnMonitor("Bar2", M2), "Top 2 below Top on the same monitor: Titan's offset stays")
vars[P .. "Bar"].show = false
tt.Apply()
Check(OnMonitor("Bar2", M2, 24), "Top switched off: Top 2 to the edge")
local bar = _G[P .. "Bar"]._points
Check(bar[1][1] == "BOTTOMLEFT" and bar[1][2] == screen and bar[1][3] == "TOPLEFT",
	"hidden bar parked above the game window")
vars[P .. "Bar"].show = true

-- bottom bar 2
vars[P .. "AuxBar2"].show = true
Set("AuxBar2", 1)
Check(OnMonitor("AuxBar2", M1, -24), "Bottom 2 alone on monitor 1: moved down")
Set("AuxBar2", 0)
Check(Whole("AuxBar2"), "Bottom 2 back to like Titan")

-- Auto-Hide
vars[P .. "AuxBar"].auto_hide = true
tt.Apply()
local h = _G["Titan_Bar__Hider_AuxBar"]
Check(h._points[1][2] == qnViewPortTitanAnchorAuxBar and h._w == 1920, "auto-hide bar on the monitor and at its width")
Check(_G[P .. "AuxBar"]._points[1][2] == screen, "auto-hidden bar parked")

-- Titan is currently moving: touch nothing
TITAN_PANEL_MOVING = 1
_G[P .. "AuxBar"]:ClearAllPoints()
Titan_G.bars.Hide(P .. "AuxBar")
Check(#_G[P .. "AuxBar"]._points == 0, "TITAN_PANEL_MOVING: no parking")
TITAN_PANEL_MOVING = 0
vars[P .. "AuxBar"].auto_hide = false

---------------------------------------------------------------------------
-- dropdown: entries, missing monitor
---------------------------------------------------------------------------
-- entries as when opening the dropdown
local function Labels(key)
	local list = {}
	for _, e in ipairs(tt.Entries(key)) do
		list[#list + 1] = e[2]
	end
	return list
end
local labels = Labels("Bar")
Check(#labels == 3 and labels[1] == L["As Titan (entire UI)"]
	and labels[2] == L["Monitor %d (%d × %d)"]:format(1, 3840, 2160)
	and labels[3] == L["Monitor %d (%d × %d)"]:format(2, 1920, 1200), "dropdown: like Titan + monitors with pixel size")
SetMonitors(1)
tt.Apply()
Check(Whole("Bar") and Whole("AuxBar"), "monitor 2 missing: bars like Titan")
labels = Labels("Bar")
Check(#labels == 3 and labels[3] == L["Monitor %d (not present)"]:format(2), "saved monitor stays visible in the dropdown")
Check(qnViewPortDB.profiles["account:Raid"].titan.Bar == 2, "selection stays saved")
SetMonitors(2)

---------------------------------------------------------------------------
-- profile switch (Edit Mode layout)
---------------------------------------------------------------------------
SetEditModeLayout(1)
Check(Whole("AuxBar") and Whole("Bar"), "profile preset:1: bars like Titan")
SetEditModeLayout(3)
Check(OnMonitor("AuxBar", M2) and OnMonitor("Bar", M2), "back to Raid: monitor 2 again")

---------------------------------------------------------------------------
-- tooltips at the edge of the monitor
---------------------------------------------------------------------------
local btn = CreateFrame("Button", "TitanPanelClockButton", UIParent)
btn.registry = { id = "Clock" }
local function Place(f, l, b, w, h)
	f.GetLeft = function() return l end
	f.GetBottom = function() return b end
	f._w, f._h = w, h
end
-- emulate Titan's anchor: GetPoint returns the last set point
local function Anchored(f, point)
	f:ClearAllPoints()
	f:SetPoint(point, btn, "BOTTOMLEFT", 0, 0)
	f.GetPoint = function(self) local p = self._points[1] return p[1], p[2], p[3], p[4], p[5] end
	f:Show()
end
local function Last(f)
	local p = f._points[#f._points]
	return p[1], p[2], p[3], p[4], p[5]
end

-- top right on monitor 1: Titan attaches it to the right, there is no monitor there anymore
Place(btn, 3800, 2136, 30, 24)
Place(TitanPanelTooltip, 0, 0, 200, 100)
Anchored(TitanPanelTooltip, "TOPLEFT")
Titan_G.plugins.OnEnter(btn)
local p, rel, rp, x, y = Last(TitanPanelTooltip)
Check(p == "TOPRIGHT" and rel == btn and rp == "BOTTOMRIGHT" and x == 0 and y == 0,
	("tooltip at the right edge of the monitor flipped to the left: %s %s %s %s"):format(p, rp, x, y))
-- if it fits, Titan's side stays
Place(btn, 1000, 2136, 30, 24)
Anchored(TitanPanelTooltip, "TOPLEFT")
Titan_G.plugins.UpdateTooltip(btn)
p, rel, rp = Last(TitanPanelTooltip)
Check(p == "TOPLEFT" and rp == "BOTTOMLEFT", "tooltip with room: Titan's side stays")
-- wider than the room on both sides: pushed inside
Place(btn, 1000, 2136, 30, 24)
Place(TitanPanelTooltip, 0, 0, 3000, 100)
Anchored(TitanPanelTooltip, "TOPLEFT")
Titan_G.plugins.OnUpdate({ "Clock", 2 })
p, rel, rp, x = Last(TitanPanelTooltip)
Check(p == "TOPLEFT" and x == 3840 - 4000, ("too wide tooltip pushed into the monitor: %s %s"):format(p, x))
-- wider than the monitor: left edge stays visible
Place(btn, 50, 2136, 30, 24)
Place(TitanPanelTooltip, 0, 0, 3900, 100)
Anchored(TitanPanelTooltip, "TOPLEFT")
Titan_G.plugins.UpdateTooltip(btn)
p, rel, rp, x = Last(TitanPanelTooltip)
Check(p == "TOPLEFT" and x == -50, ("wider than the monitor: at its left edge: %s %s"):format(p, x))
-- bottom bar on monitor 2: no monitor below, so above
Place(btn, 4000, M2.b, 30, 24)
Place(TitanPanelTooltip, 0, 0, 200, 100)
Anchored(TitanPanelTooltip, "TOPLEFT")
Titan_G.plugins.OnEnter(btn)
p, rel, rp = Last(TitanPanelTooltip)
Check(p == "BOTTOMLEFT" and rp == "TOPLEFT", "tooltip at the bottom edge of monitor 2 flipped upwards")
-- foreign anchor (not on the plugin): do not touch
GameTooltip:ClearAllPoints()
GameTooltip:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 5, 5)
GameTooltip.GetPoint = function(self) local q = self._points[1] return q[1], q[2], q[3], q[4], q[5] end
Titan_G.plugins.OnEnter(btn)
Check(#GameTooltip._points == 1 and GameTooltip._points[1][2] == UIParent, "GameTooltip of another frame stays untouched")
-- control frame
local ctrl = CreateFrame("Frame", "TitanPanelClockControlFrame", UIParent)
controls.Clock = ctrl
Place(btn, 3800, 2136, 30, 24)
Place(ctrl, 0, 0, 150, 150)
Anchored(ctrl, "TOPLEFT")
Titan_G.plugins.OnClick(btn, "LeftButton")
p = Last(ctrl)
Check(p == "TOPRIGHT", "control frame at the right monitor edge to the left")
RunTimers()
-- control frame with room: Titan's anchor (center of the plugin's bottom edge) stays, no jump
Place(btn, 1000, 2136, 30, 24)
ctrl:ClearAllPoints()
ctrl:SetPoint("TOPLEFT", btn, "BOTTOM", 0, 0)
Titan_G.plugins.OnClick(btn, "LeftButton")
p, rel, rp = Last(ctrl)
Check(#ctrl._points == 1 and p == "TOPLEFT" and rp == "BOTTOM", ("control frame with room: Titan's anchor stays: %s %s"):format(p, tostring(rp)))

---------------------------------------------------------------------------
-- scale per monitor (in addition to Titan's scale)
---------------------------------------------------------------------------
local function Near(a, b) return math.abs((a or 0) - b) < 1e-6 end
btn.textPlugin = true
pluginBar.Clock = "Bar"
local bag = CreateFrame("Button", "TitanPanelBagButton", UIParent)   -- icon only: Titan does not scale it
pluginBar.Bag = "Bar"
local xp = CreateFrame("Button", "TitanPanelXPButton", UIParent)
xp.textPlugin = true
pluginBar.XP = "Short01"
vp.db.titan.Bar, vp.db.titan.AuxBar = 2, 1
tt.Apply()
Check(Near(_G[P .. "Bar"]._scale, 1) and Near(btn._scale, 1) and bag._scale == nil,
	"without factor: Titan's scale unchanged, icon plugin not touched")
vp.db.titan.scale = { [2] = 0.65 }
tt.Apply()
Check(Near(_G[P .. "Bar"]._scale, 0.65) and Near(_G[P .. "AuxBar"]._scale, 1),
	("bar on monitor 2 at 65 %%, on monitor 1 unchanged: %s / %s"):format(_G[P .. "Bar"]._scale, _G[P .. "AuxBar"]._scale))
Check(Near(btn._scale, 0.65) and Near(bag._scale, 0.65) and Near(xp._scale, 1),
	"plugins of the bar with factor (icons too), plugin on a short bar not")
TITAN_VARS.Scale = 1.2
tt.Apply()
Check(Near(_G[P .. "Bar"]._scale, 0.78) and Near(btn._scale, 0.78) and Near(_G[P .. "AuxBar"]._scale, 1.2),
	"factor applies in addition to Titan's scale")
-- Titan's tooltip on the plugin on monitor 2
Place(btn, 4000, M2.t - 24, 30, 24)
Place(TitanPanelTooltip, 0, 0, 200, 100)
Anchored(TitanPanelTooltip, "TOPLEFT")
Titan_G.plugins.OnEnter(btn)
Check(Near(TitanPanelTooltip._scale, 0.65), ("Titan's tooltip with the monitor's factor: %s"):format(tostring(TitanPanelTooltip._scale)))
-- factor back to 100 %
vp.db.titan.scale = {}
tt.Apply()
Check(Near(_G[P .. "Bar"]._scale, 1.2) and Near(btn._scale, 1.2) and Near(bag._scale, 1.2),
	"factor removed: Titan's scale again")
tt.RefreshOptions()
Check(true, "options page with sliders per monitor refreshed")
TITAN_VARS.Scale = 1

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
