-- qnViewPort: dual monitor mode.
-- Prerequisite: the game window spans several monitors (e.g. 5760 × 2160
-- with 3840 × 2160 + 1920 × 1200). This module
--   * computes the viewport from it so that the 3D world lies only on the main monitor,
--   * optionally moves bags and the Zone Map to a corner of a selectable monitor
--     and shows/hides the Zone Map,
--   * optionally puts the maximized World Map on one monitor and offers a few
--     World Map settings.
-- The chat is not moved. All values in screen pixels of the game window.

local _, ns = ...
local L = ns.L
local UI = qnCore.UI

local Dual = {}
ns.Dual = Dual

local DB = ns.DualDB

---------------------------------------------------------------------------
-- Geometry
---------------------------------------------------------------------------

-- Viewport offsets { left, right, top, bottom }: 3D world only on the main monitor
function Dual.GetViewport()
	local r = ns.Layout.GetMainRect()
	return r and ns.Layout.ViewportFor(r) or { 0, 0, 0, 0 }
end

-- Conversion pixels -> UIParent units (regardless of whether UIParent is shrunk)
local function Scale()
	local ux, uy = ns.UnitsPerPixel()
	local s = UIParent:GetEffectiveScale()
	return ux / s, uy / s
end

-- Does the game window match the configured monitor layout?
function Dual.CheckWindow()
	if ns.Layout.Active() then
		return true
	end
	local W = ns.screen[1]
	local d = DB()
	local problem = d.useMonitorData and ns.Layout.GetProblem()
	-- Rough check: the main monitor is at least half as wide as the 2nd monitor.
	if W < d.width * 1.5 then
		return false, L["The game window is only %d × %d pixels. It must span both monitors (main monitor width + %d).%s"]:format(
			ns.screen[1], ns.screen[2], d.width, problem and ("\n" .. problem) or "")
	end
	return true
end

---------------------------------------------------------------------------
-- Placement areas: corner of a monitor, offset inward.
-- Same structure for bags ("bags") and Zone Map ("zoneMap"). Settings per prefix:
--   <p> (on/off), <p>Monitor (0 = main monitor), <p>Point (corner), <p>OffsetX, <p>OffsetY (pixels)
---------------------------------------------------------------------------

-- { corner, text } – also the entries of the dropdown button
local CORNERS = qnCore.PointEntries(true)

-- Chosen corner; unknown value: bottom right
local function Corner(prefix)
	local p = DB()[prefix .. "Point"]
	for _, c in ipairs(CORNERS) do
		if c[1] == p then
			return p
		end
	end
	return "BOTTOMRIGHT"
end

-- Is the corner on the right or at the top?
local function CornerDirs(p)
	local fx, fy = qnCore.AnchorFactors(p)
	return fx == 1, fy == 1
end

-- Selectable monitors: [0] = main monitor, then all monitors with a visible part in the window
local function Monitors()
	local list = { [0] = ns.Layout.GetMainRect() or ns.Layout.Full() }
	for i, r in ipairs(ns.Layout.GetVisible()) do
		list[i] = r
	end
	return list
end

local function MonitorIndex(prefix)
	local i = DB()[prefix .. "Monitor"] or 0
	return Monitors()[i] and i or 0   -- chosen monitor no longer present: main monitor
end

local placements = {}

local function NewPlacement(prefix, label, r, g, b)
	local area = CreateFrame("Frame", nil, UIParent)
	area:SetFrameStrata("BACKGROUND")
	area:SetFrameLevel(1)
	area:EnableMouse(false)
	area.qnViewPortIgnore = true
	local guide = CreateFrame("Frame", nil, area, "BackdropTemplate")
	guide:SetAllPoints()
	guide:SetFrameStrata("HIGH")
	guide:SetBackdrop({ edgeFile = "Interface\\ChatFrame\\ChatFrameBackground", edgeSize = 2 })
	guide:SetBackdropBorderColor(r, g, b, 0.9)
	local fs = guide:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
	fs:SetPoint("CENTER")
	fs:SetText("qnViewPort – " .. label)
	fs:SetTextColor(r, g, b)
	guide:Hide()
	local pl = { prefix = prefix, area = area, guide = guide }
	placements[#placements + 1] = pl
	return pl
end

local bagPlace = NewPlacement("bags", HUD_EDIT_MODE_BAGS_LABEL, 0, 0.8, 1)
local mapPlace = NewPlacement("zoneMap", L["Zone Map"], 1, 0.8, 0)
-- whole monitors (without …Point/…Offset: bottom right corner, offsets 0)
local worldPlace = NewPlacement("worldMap", WORLDMAP_BUTTON, 0.3, 1, 0.3)
local questPlace = NewPlacement("questLog", MAP_AND_QUEST_LOG, 1, 0.5, 1)

-- Defines an area: monitor, corner, offsets from the edges of that corner.
local function UpdatePlacement(pl)
	local d = DB()
	local prefix = pl.prefix
	local r = Monitors()[MonitorIndex(prefix)]
	local right, top = CornerDirs(Corner(prefix))
	local ox = math.max(0, math.min(tonumber(d[prefix .. "OffsetX"]) or 0, r.w - 50))
	local oy = math.max(0, math.min(tonumber(d[prefix .. "OffsetY"]) or 0, r.h - 50))
	local x, y = right and r.x or (r.x + ox), top and (r.y + oy) or r.y
	local w, h = r.w - ox, r.h - oy
	local sx, sy = Scale()
	pl.area:ClearAllPoints()
	-- anchored to the whole window, not to UIParent (it may only cover the main monitor)
	pl.area:SetPoint("TOPLEFT", ns.screenRef, "TOPLEFT", x * sx, -y * sy)
	pl.area:SetSize(w * sx, h * sy)
	pl.guide:SetShown(d[prefix] and d.guides)
end

function Dual.UpdateArea()
	for _, pl in ipairs(placements) do
		UpdatePlacement(pl)
	end
end

---------------------------------------------------------------------------
-- Place bags (only if "Place bags when opened" is checked)
---------------------------------------------------------------------------

local BAG_GAP = 6

local function ShownBags()
	local list = {}
	local combined = _G.ContainerFrameCombinedBags
	if combined and combined:IsShown() then
		list[#list + 1] = combined
	end
	for i = 1, NUM_CONTAINER_FRAMES do
		local f = _G["ContainerFrame" .. i]
		if f and f:IsShown() then
			list[#list + 1] = f
		end
	end
	return list
end

-- Stacks the open bags vertically from the chosen corner and then column by column
-- towards the center of the monitor.
function Dual.DockBags()
	if not DB().bags then
		return
	end
	local area = bagPlace.area
	local p = Corner("bags")
	local right, top = CornerDirs(p)
	local dirX, dirY = right and -1 or 1, top and -1 or 1
	local maxH = area:GetHeight()
	local x, y, colW = 0, 0, 0
	for _, f in ipairs(ShownBags()) do
		if f:IsProtected() and InCombatLockdown() then
			break
		end
		local k = f:GetEffectiveScale() / area:GetEffectiveScale()
		local fw, fh = f:GetWidth() * k, f:GetHeight() * k
		if y > 0 and y + fh > maxH then
			x, y, colW = x + colW + BAG_GAP, 0, 0
		end
		f:ClearAllPoints()
		f:SetPoint(p, area, p, dirX * x / k, dirY * y / k)
		y = y + fh + BAG_GAP
		colW = math.max(colW, fw)
	end
end

---------------------------------------------------------------------------
-- Tooltips on bag slots: always fully on the slot's monitor.
-- Blizzard attaches the tooltip with BOTTOMLEFT to TOPRIGHT or BOTTOMRIGHT to TOPLEFT of the slot,
-- depending on whether the slot lies left or right of the center of the whole window
-- (ContainerFrameItemButton_CalculateItemTooltipAnchors, GetScreenWidth), and then fills it
-- with GameTooltip:SetBagItem – both again on every refresh (UpdateTooltip).
-- Comparison tooltips: TooltipComparisonManager:AnchorShoppingTooltips, partly from within SetBagItem,
-- partly later via an event.
---------------------------------------------------------------------------

local bagTipOwner   -- bag slot GameTooltip was last attached to via SetBagItem

-- withCompare: also the comparison tooltips – only right after Blizzard creates them (AnchorShoppingTooltips).
-- Not on refresh (SetBagItem): Blizzard recreates them afterwards anyway, partly only via the
-- event TOOLTIP_SHOW_ITEM_COMPARISON; interfering in between made them flicker.
local function FitBagTooltip(tip, owner, withCompare)
	if tip:GetOwner() ~= owner then
		return
	end
	ns.Layout.FitToMonitor(tip, owner)
	if withCompare then
		ns.Layout.FitCompareToMonitor(tip)
	end
end

local function OnSetBagItem(tip)
	local owner = tip:GetOwner()
	bagTipOwner = owner
	if not owner then
		return
	end
	FitBagTooltip(tip, owner)
	-- once more in the next frame: then the tooltip has its final size
	C_Timer.After(0, function()
		FitBagTooltip(tip, owner)
	end)
end

-- Public for bag views of other addons (qnInventory) that do not fill their tooltips via
-- SetBagItem: call after filling; tip must be anchored to owner.
function ns.BagTooltip(tip, owner)
	bagTipOwner = owner
	if not owner then
		return
	end
	-- comparison tooltips right away as well: Blizzard already created them while filling
	FitBagTooltip(tip, owner, TooltipComparisonManager.tooltip == tip)
	C_Timer.After(0, function()
		FitBagTooltip(tip, owner)
	end)
end

-- Blizzard may shift the tooltip sideways when comparing (SetAnchorType with slide):
-- then fit both to the monitor again.
local function OnAnchorShoppingTooltips(manager)
	local tip = manager.tooltip
	if tip and manager.anchorFrame == tip
		and bagTipOwner and tip:GetOwner() == bagTipOwner then
		FitBagTooltip(tip, bagTipOwner, true)
	end
end

---------------------------------------------------------------------------
-- Zone Map (BattlefieldMapFrame from Blizzard_BattlefieldMap, loads on demand)
-- Blizzard attaches the map with TOPLEFT to BattlefieldMapTab BOTTOMLEFT (y -5) and only remembers
-- the position of the tab. Hence the tab is placed; the map follows.
---------------------------------------------------------------------------

local ZONEMAP_ADDON = "Blizzard_BattlefieldMap"
local TAB_GAP = 5   -- gap tab -> map in Blizzard's XML

local function ZoneMapLoaded()
	return _G.BattlefieldMapFrame ~= nil and _G.BattlefieldMapTab ~= nil
end

local function LoadZoneMap()
	if ZoneMapLoaded() then
		return true
	end
	BattlefieldMap_LoadUI()
	return ZoneMapLoaded()
end

-- Places tab + map as a block at the chosen corner (only with option "zoneMap").
function Dual.PlaceZoneMap()
	local f, tab = _G.BattlefieldMapFrame, _G.BattlefieldMapTab
	if not (DB().zoneMap and f and tab and f:IsShown()) then
		return
	end
	local area = mapPlace.area
	local fs, ts, as = f:GetEffectiveScale(), tab:GetEffectiveScale(), area:GetEffectiveScale()
	-- Block in abs units: tab on top, map below
	local bw = f:GetWidth() * fs
	local th = tab:GetHeight() * ts
	local bh = th + TAB_GAP * fs + f:GetHeight() * fs
	local al, ab, aw, ah = area:GetRect()
	if al and bw > 0 then
		al, ab, aw, ah = al * as, ab * as, aw * as, ah * as
		local right, top = CornerDirs(Corner("zoneMap"))
		local left = right and (al + aw - bw) or al
		local upper = top and (ab + ah) or (ab + bh)
		tab:ClearAllPoints()
		-- Offsets in the tab's units, relative to the bottom left corner of the area
		tab:SetPoint("BOTTOMLEFT", area, "BOTTOMLEFT", (left - al) / ts, (upper - th - ab) / ts)
	end
end

-- Chosen size, rounded to 5 % and clamped like the slider (50–200 %)
local function ZoneMapScale()
	local s = tonumber(DB().zoneMapScale) or 1
	return math.max(0.5, math.min(2, math.floor(s * 20 + 0.5) / 20))
end

-- Size of tab + map (Blizzard itself offers none). At 100 % qnViewPort does not touch the size,
-- except to undo its own change.
-- Blizzard anchors the tab with CENTER to UIParent BOTTOMLEFT and remembers the center in
-- the tab's units (BattlefieldMapOptions.position) – so on load it matches the same
-- size. keepCenter (slider, profile switch): the tab keeps its center on screen, the
-- remembered position is updated as after Blizzard's dragging. With placement, PlaceZoneMap positions it.
local zoneMapScaled = false
function Dual.ScaleZoneMap(keepCenter)
	local f, tab = _G.BattlefieldMapFrame, _G.BattlefieldMapTab
	local s = ZoneMapScale()
	if not (f and tab) or (s == 1 and not zoneMapScaled) or math.abs(tab:GetScale() - s) < 0.001 then
		return
	end
	zoneMapScaled = s ~= 1
	local cx, cy = tab:GetCenter()
	local es = tab:GetEffectiveScale()
	tab:SetScale(s)
	f:SetScale(s)
	if keepCenter and cx and not DB().zoneMap then
		local ts, us = tab:GetEffectiveScale(), UIParent:GetEffectiveScale()
		tab:ClearAllPoints()
		tab:SetPoint("CENTER", UIParent, "BOTTOMLEFT",
			(cx * es - UIParent:GetLeft() * us) / ts, (cy * es - UIParent:GetBottom() * us) / ts)
		if BattlefieldMapOptions then
			BattlefieldMapOptions.position = BattlefieldMapOptions.position or {}
			BattlefieldMapOptions.position.x, BattlefieldMapOptions.position.y = tab:GetCenter()
		end
	end
end

function Dual.SetZoneMapScale(percent)
	DB().zoneMapScale = math.floor(percent / 5 + 0.5) * 5 / 100
	Dual.ScaleZoneMap(true)
	Dual.PlaceZoneMap()
end

function Dual.IsZoneMapShown()
	return ZoneMapLoaded() and _G.BattlefieldMapFrame:IsShown() or false
end

-- Shows/hides the Zone Map via Blizzard's own toggle (also sets the CVar
-- showBattlefieldMinimap, which Blizzard uses to remember the state across logins).
function Dual.SetZoneMapShown(on)
	if InCombatLockdown() and not ZoneMapLoaded() then
		ns.Print(L["The Zone Map cannot be loaded in combat."])
		return
	end
	if not LoadZoneMap() then
		ns.Print(L["Zone Map (Blizzard_BattlefieldMap) could not be loaded."])
		return
	end
	local f = _G.BattlefieldMapFrame
	if (f:IsShown() and true or false) ~= (on and true or false) then
		f:Toggle()
	end
	if on and not f:IsShown() then
		ns.Print(L["The Zone Map is not available here (Blizzard does not show it in every instance, for example)."])
	end
end

local zoneMapHooked = false
local function HookZoneMap()
	if zoneMapHooked or not ZoneMapLoaded() then
		return
	end
	zoneMapHooked = true
	Dual.ScaleZoneMap()
	-- in the next frame (after Blizzard's own layout), show and hide combined
	local Changed = qnCore.Debounce(function()
		Dual.PlaceZoneMap()
		if Dual.IsOptionsShown() then
			Dual.RefreshOptions()
		end
	end)
	_G.BattlefieldMapFrame:HookScript("OnShow", Changed)
	_G.BattlefieldMapFrame:HookScript("OnHide", Changed)
	Changed()
end

---------------------------------------------------------------------------
-- World Map (does not move the map). On open, Blizzard itself shows the map
-- of the current zone (WorldMapMixin:OnShow); here only the zone change while the map is open.
---------------------------------------------------------------------------

local function MapToCurrentZone()
	local f = WorldMapFrame
	if not f:IsShown() then
		return
	end
	local mapID = C_Map.GetBestMapForUnit("player")
	if mapID then
		f:SetMapID(mapID)
	end
end

function Dual.OpenMap()
	if not WorldMapFrame:IsShown() and not InCombatLockdown() then
		ToggleWorldMap()
	end
end

-- mapNoFade on: remember the previous value of mapFade (mapFadeSaved) and set 0.
-- Off: write back the remembered value; if nothing was remembered, Blizzard's default when
-- turning it off (toggled), otherwise leave the CVar alone.
-- The remembered value is account-wide (ns.global): the CVar belongs to no profile, so when switching
-- to a profile without mapNoFade it is written back.
local function ApplyMapFade(toggled)
	local g = ns.global
	local value = C_CVar.GetCVar("mapFade")
	if DB().mapNoFade then
		if g.mapFadeSaved == nil and value ~= "0" then
			g.mapFadeSaved = value
		end
		C_CVar.SetCVar("mapFade", "0")
	elseif g.mapFadeSaved ~= nil or toggled then
		C_CVar.SetCVar("mapFade", g.mapFadeSaved or C_CVar.GetCVarDefault("mapFade"))
		g.mapFadeSaved = nil
	end
end
Dual.ApplyMapFade = ApplyMapFade

---------------------------------------------------------------------------
-- World Map on one monitor (only with its options)
-- Maximized ("worldMap"): Blizzard computes the size from the size of UIParent and puts the map
-- at the top center of UIParent (WorldMapMixin:UpdateMaximizedSize, maximizePoint "TOP"); the black
-- area (BlackoutFrame) covers all of UIParent. With a window across several monitors both reach
-- across all of them. Here the same computation with the monitor's area instead of UIParent.
-- Minimized = "Map & Quest Log" ("questLog"; ToggleQuestLog opens this view in Forever):
-- Blizzard's window management places it as the left window at UIParent TOPLEFT
-- (FramePositionDelegate:UpdateUIPanelPositions). Here the same anchor on the monitor's area.
---------------------------------------------------------------------------

local SPACER_HEIGHT = 67   -- TITLE_CANVAS_SPACER_FRAME_HEIGHT (local in Blizzard_WorldMap.lua)
local SCREEN_BORDER = 30   -- SCREEN_BORDER_PIXELS in UpdateMaximizedSize
local worldMapPlaced       -- "max" or "min" while the map is placed by us

local function SetBlackout(f, target)
	if f.BlackoutFrame then
		f.BlackoutFrame:ClearAllPoints()
		f.BlackoutFrame:SetAllPoints(target)
	end
end

-- Re-attach Blizzard's anchor (on UIParent) unchanged to target; do not touch unknown anchors
local function Reanchor(f, target)
	local point, rel, relPoint, x, y = f:GetPoint(1)
	rel = rel or UIParent
	if not point or rel == target or (rel ~= UIParent and rel ~= questPlace.area) then
		return
	end
	f:ClearAllPoints()
	f:SetPoint(point, target, relPoint, x, y)
end

-- Size and position like Blizzard's UpdateMaximizedSize, relative to area
local function FitWorldMap(f, area)
	local k = area:GetEffectiveScale() / f:GetEffectiveScale()
	local pw, ph = area:GetWidth() * k - SCREEN_BORDER, area:GetHeight() * k
	local unclamped = (ph - SPACER_HEIGHT) * f.minimizedWidth / (f.minimizedHeight - SPACER_HEIGHT)
	local w = math.min(pw, unclamped)
	local h = (ph - SPACER_HEIGHT) * (w / unclamped) + SPACER_HEIGHT
	f:SetSize(math.floor(w), math.floor(h))
	f:ClearAllPoints()
	f:SetPoint("TOP", area, "TOP")
	SetBlackout(f, area)
	f:OnFrameSizeChanged()
end

function Dual.PlaceWorldMap()
	local f = _G.WorldMapFrame
	if not (f and f.IsMaximized and f.minimizedWidth) then
		return
	end
	if f:IsProtected() and qnCore.DeferInCombat(Dual.PlaceWorldMap) then
		return
	end
	local d = DB()
	local shown = f:IsShown()
	local maximized = shown and f:IsMaximized()
	if maximized and d.worldMap then
		FitWorldMap(f, worldPlace.area)
		worldMapPlaced = "max"
	elseif shown and not maximized and d.questLog then
		Reanchor(f, questPlace.area)
		SetBlackout(f, UIParent)   -- possibly still on the monitor from the maximized state
		worldMapPlaced = "min"
	elseif worldMapPlaced then
		-- option off (or view switched): back to UIParent as in Blizzard's code
		if worldMapPlaced == "max" and maximized then
			FitWorldMap(f, UIParent)
		elseif worldMapPlaced == "min" and shown and not maximized then
			Reanchor(f, UIParent)
		end
		SetBlackout(f, UIParent)
		worldMapPlaced = nil
	end
end

-- After Blizzard's own layout: maximize/minimize, window size, opening and every
-- re-layout of the windows (ShowUIPanel/HideUIPanel/UpdateUIPanelPositions put the minimized
-- map back on UIParent). Immediately and once more in the next frame.
local worldMapHooked = false
local function HookWorldMap()
	local f = _G.WorldMapFrame
	if worldMapHooked or not (f and f.SynchronizeDisplayState and f.UpdateMaximizedSize) then
		return
	end
	worldMapHooked = true
	local later = qnCore.Debounce(Dual.PlaceWorldMap)
	local function Place()
		if worldMapPlaced or DB().worldMap or DB().questLog then
			Dual.PlaceWorldMap()
			later()
		end
	end
	hooksecurefunc(f, "SynchronizeDisplayState", Place)
	hooksecurefunc(f, "UpdateMaximizedSize", Place)
	for _, name in ipairs({ "ShowUIPanel", "HideUIPanel", "UpdateUIPanelPositions" }) do
		hooksecurefunc(name, Place)
	end
	EventRegistry:RegisterCallback("WorldMapOnShow", Place, Dual)
end

---------------------------------------------------------------------------
-- Apply
---------------------------------------------------------------------------

-- Own frames, bags, Zone Map and maximized World Map (each only with its option); chat
-- and other Blizzard windows stay where they are.
function Dual.ApplyAll()
	Dual.UpdateArea()
	Dual.DockBags()
	Dual.ScaleZoneMap(true)
	Dual.PlaceZoneMap()
	Dual.PlaceWorldMap()
end

-- Reapply everything after changed settings, without a chat message. With withViewport (and
-- the mode turned on) the viewport is also put on the main monitor and saved.
function Dual.Reapply(withViewport)
	ns.UpdateScreenSize()
	if withViewport and DB().enabled then
		-- without the 20 s confirmation: the way back is /qnvp dual off
		ns.EndKeep()
		ns.ApplyViewport(Dual.GetViewport())
	end
	qnCore.Visible.Notify()
	Dual.ApplyAll()
	Dual.RefreshOptions()
end

-- Turns the mode on/off and sets the matching viewport (the 3D world, not the interface).
-- Message only if the state actually changes.
function Dual.SetEnabled(on)
	on = on and true or false
	local d = DB()
	if d.enabled ~= on then
		d.enabled = on
		ns.UpdateScreenSize()
		if on then
			local ok, msg = Dual.CheckWindow()
			if not ok then
				ns.Print("|cffff8080" .. msg .. "|r")
			end
			ns.Print(L["Dual monitor mode on: 3D world on the main monitor."])
		else
			ns.EndKeep()
			ns.ApplyViewport({ 0, 0, 0, 0 })
			ns.Layout.ReleaseUI()
			ns.Print(L["Dual monitor mode off."])
		end
	end
	Dual.Reapply(true)
end

---------------------------------------------------------------------------
-- Slash: /qnvp dual ...
---------------------------------------------------------------------------

function Dual.Slash(msg)
	msg = (msg or ""):lower()
	local w, h, y = msg:match("^(%d+)%s+(%d+)%s*(%d*)$")
	if msg == "" then
		Dual.OpenOptions()
	elseif msg == "on" then
		Dual.SetEnabled(true)
	elseif msg == "off" then
		Dual.SetEnabled(false)
	elseif msg == "left" or msg == "right" then
		DB().side = msg:upper()
		Dual.Reapply(true)
	elseif msg == "guides" then
		DB().guides = not DB().guides
		Dual.UpdateArea()
	elseif msg == "map" then
		Dual.OpenMap()
	elseif msg == "zonemap" then
		Dual.SetZoneMapShown(not Dual.IsZoneMapShown())
	elseif w then
		DB().width, DB().height = tonumber(w), tonumber(h)
		if y ~= "" then DB().offsetY = tonumber(y) end
		Dual.Reapply(true)
		ns.Print((ns.Layout.Active() and L["Second monitor: %d × %d, top offset %d (only used without monitor data)"]
			or L["Second monitor: %d × %d, top offset %d"]):format(DB().width, DB().height, DB().offsetY))
	else
		-- one key; Print outputs each line as its own chat line
		ns.Print(L["/qnvp dual – options   |   on / off   |   left / right\n/qnvp dual W H [Y] – size of the second monitor in pixels, Y = distance from the top (only without monitor data)\n/qnvp dual guides – show placement areas   |   map – open the World Map   |   zonemap – toggle the Zone Map"])
	end
end

---------------------------------------------------------------------------
-- Building blocks of the options pages
---------------------------------------------------------------------------

local sub
local page           -- page that Check/NumBox/Choice are currently building on (NewPage)
local pages = {}
local widgets = {}

-- Commit the input fields before a button acts
local function ClearFocusAll()
	for _, wdg in ipairs(widgets) do
		if wdg.ClearFocus then wdg:ClearFocus() end
	end
end

-- Checkbox for DB()[key]; with getter/setter instead of a key (e.g. Blizzard state).
local function Check(label, key, tooltip, onChange, getter, setter)
	local cb = CreateFrame("CheckButton", nil, page, "UICheckButtonTemplate")
	local fs = UI.Text(page, "GameFontHighlight", label)
	fs:SetPoint("LEFT", cb, "RIGHT", 2, 0)
	cb:SetScript("OnClick", function(self)
		local on = self:GetChecked() and true or false
		if setter then
			setter(on)
		else
			DB()[key] = on
		end
		if onChange then onChange() end
	end)
	if tooltip then
		UI.Tooltip(cb, label, tooltip)
	end
	-- Refresh (Dual.RefreshOptions): check mark from getter or DB()[key]
	function cb:Refresh()
		if getter then
			self:SetChecked(getter())
		else
			self:SetChecked(DB()[key])
		end
	end
	widgets[#widgets + 1] = cb
	return cb
end

-- Manual values of the 2nd monitor; with monitor data the measured values instead (display only).
local MANUAL = { width = "w", height = "h", offsetY = "y" }

-- Refreshing a number field: DB()[key], except while typing
local function RefreshBox(box)
	if not box:HasFocus() then
		box:SetText(DB()[box.key])
	end
end

-- Refreshing a field of the 2nd monitor: with monitor data (ctx.data) the measured value, locked
local function RefreshManualBox(box, ctx)
	local data, second = ctx.data, ctx.second
	if data and second then
		box:SetText(second[MANUAL[box.key]])
	elseif not box:HasFocus() then
		box:SetText(DB()[box.key])
	end
	if box.SetEnabled then
		box:SetEnabled(not data)
	end
	box.label:SetFontObject(data and "GameFontDisable" or "GameFontHighlight")
end

-- Number field with a label on the left for DB()[key]
local function NumBox(label, key, onCommit)
	local box = ns.NumBox(page, 60, function() return DB()[key] end, function(v)
		if v and v ~= DB()[key] then
			DB()[key] = v
			if onCommit then onCommit() end
		end
	end)
	box.label = UI.Label(page, box, label)
	box.key = key
	box.Refresh = MANUAL[key] and RefreshManualBox or RefreshBox
	widgets[#widgets + 1] = box
	return box
end

-- Button with a dropdown list (qnCore), shows the active selection.
-- entries() returns { { value, text }, … }, get() the current value, set(v) applies it.
-- enabled() (optional): only usable then.
local function Choice(label, width, entries, get, set, onChange, enabled)
	local dd = UI.Dropdown(page, width, entries, get, function(v)
		set(v)
		if onChange then onChange() end
		Dual.RefreshOptions()
	end)
	dd.label = UI.Label(page, dd, label)
	-- Refresh: show the active selection (qnCore); with enabled() also disable or enable
	local showSelection = dd.Refresh
	function dd:Refresh()
		showSelection(self)
		if enabled then
			local on = enabled() and true or false
			self:SetEnabled(on)
			self.label:SetFontObject(on and "GameFontHighlight" or "GameFontDisable")
		end
	end
	widgets[#widgets + 1] = dd
	return dd
end

-- Apply button of a subpage below anchor
local function ApplyButton(anchor, withViewport)
	local b = UI.Button(page, APPLY, 160, function()
		ClearFocusAll()
		Dual.Reapply(withViewport)
	end)
	b:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 4, -14)
	return b
end

-- Create a subpage (qnCore.UI.Page: heading, divider, content with scroll bar):
-- build(top) builds on "page" (= content) below top (description), then it is registered in the
-- settings window. Returns category and page (for Fit after showing/hiding).
local function NewPage(name, desc, build)
	local ui = UI.Page(name, { desc = desc })
	ui.panel:SetScript("OnShow", Dual.RefreshOptions)
	pages[#pages + 1] = ui.panel
	page = ui.content
	build(ui.top, ui)
	return Settings.RegisterCanvasLayoutSubcategory(ns.category, ui.panel, name), ui
end

local info, monInfo

function Dual.IsOptionsShown()
	for _, p in ipairs(pages) do
		if p:IsVisible() then
			return true
		end
	end
	return false
end

-- Info text of the "Second Monitor" page: game window, 2nd monitor, world, monitor data, window check
local function RefreshInfoText(ctx)
	local data, main, second = ctx.data, ctx.main, ctx.second
	local ok, msg = Dual.CheckWindow()
	info:SetText(L["|cffccccccGame window:|r %d × %d     |cffccccccSecond monitor in the window:|r %s     |cffccccccWorld:|r %s%s%s"]:format(
		ns.screen[1], ns.screen[2],
		second and ("x %d, y %d, %d × %d"):format(second.x, second.y, second.w, second.h) or L["none"],
		main and ("%d × %d"):format(main.w, main.h) or L["whole window"],
		data and ("\n" .. L["|cff80ff80Monitor data active|r – position and size above are measured and cannot be changed (\"Monitors\" page)."]) or "",
		ok and "" or ("\n|cffff8080" .. msg .. "|r")))
end

-- Monitor list of the "Monitors" page including the position of the Blizzard interface
local function RefreshMonitorText()
	local lines = ns.Layout.Describe()
	lines[#lines + 1] = ""
	lines[#lines + 1] = ns.Layout.IsUIConstrained() and L["Blizzard interface: on the main monitor"]
		or L["Blizzard interface: across the whole window"]
	monInfo:SetText(table.concat(lines, "\n"))
end

-- Redisplay all controls and texts of the options pages.
-- ctx: data (monitor data, otherwise nil), main and second (rectangles of the main and 2nd monitor).
function Dual.RefreshOptions()
	ns.UpdateScreenSize()
	local data = ns.Layout.Active()
	local main, second = ns.Layout.GetMainRect(), ns.Layout.GetSecondRect()
	local ctx = { data = data, main = main, second = second }
	for _, wdg in ipairs(widgets) do
		wdg:Refresh(ctx)
	end
	RefreshInfoText(ctx)
	RefreshMonitorText()
end

---------------------------------------------------------------------------
-- Options page (subcategory "Second Monitor")
---------------------------------------------------------------------------

local function BuildPage(desc)
	local enable = Check(L["Dual monitor mode enabled (3D world on the main monitor only)"], nil, nil, nil,
		function() return DB().enabled end, Dual.SetEnabled)
	enable:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", -4, -14)

	-- Position of the 2nd monitor: manual values without monitor data, otherwise measured values (locked)
	local side = Choice(L["Position of the second monitor"], 220, {
		{ "RIGHT", L["Right of the main monitor"] },
		{ "LEFT", L["Left of the main monitor"] },
	}, function()
		local main, second = ns.Layout.GetMainRect(), ns.Layout.GetSecondRect()
		if ns.Layout.Active() and main and second then
			return second.x < main.x and "LEFT" or "RIGHT"
		end
		return DB().side == "LEFT" and "LEFT" or "RIGHT"
	end, function(v)
		if not ns.Layout.Active() then
			DB().side = v
		end
	end, nil, function() return not ns.Layout.Active() end)
	side:SetPoint("TOPLEFT", enable, "BOTTOMLEFT", 164, -14)
	UI.Tooltip(side, L["Position of the second monitor"], L["Only adjustable without monitor data. With monitor data, position, size and offset are measured (qnViewPort\\scripts)."])

	local wBox = NumBox(HUD_EDIT_MODE_SETTING_CHAT_FRAME_WIDTH, "width")
	wBox:SetPoint("TOPLEFT", side, "BOTTOMLEFT", -90, -18)
	local hBox = NumBox(HUD_EDIT_MODE_SETTING_CHAT_FRAME_HEIGHT, "height")
	hBox:SetPoint("LEFT", wBox, "RIGHT", 70, 0)
	local yBox = NumBox(L["Distance from top"], "offsetY")
	yBox:SetPoint("LEFT", hBox, "RIGHT", 150, 0)

	-- left-aligned with the checkbox above (wBox is 70 further to the right)
	local apply = ApplyButton(wBox, true)
	apply:ClearAllPoints()
	apply:SetPoint("TOPLEFT", wBox, "BOTTOMLEFT", -70, -22)

	info = UI.Text(page, "GameFontHighlight")
	info:SetPoint("TOPLEFT", apply, "BOTTOMLEFT", 0, -16)
	info:SetWidth(620)
end

---------------------------------------------------------------------------
-- Options page (subcategory "Placement"): bags and Zone Map
---------------------------------------------------------------------------

-- Monitors to choose from: 0 = main monitor, then the numbers as on the "Monitors" page
local function MonitorEntries()
	local list, main = {}, ns.Layout.GetMainRect()
	local monitors = Monitors()
	for i = 0, #monitors do
		local r = monitors[i]
		if i == 0 then
			list[#list + 1] = { 0, L["Main monitor (%d × %d)"]:format(r.w, r.h) }
		elseif r == main then
			list[#list + 1] = { i, L["Monitor %d (%d × %d), main"]:format(i, r.w, r.h) }
		else
			list[#list + 1] = { i, L["Monitor %d (%d × %d)"]:format(i, r.w, r.h) }
		end
	end
	return list
end

-- Section "monitor, corner, offsets" for a placement; returns the monitor button and the field
-- "Horizontal offset" (for anchoring).
-- monitorTitle/cornerTitle: tooltip headings of the two dropdown buttons.
local function PlacementControls(prefix, anchor, monitorTitle, cornerTitle)
	local monitor = Choice(PRIMARY_MONITOR, 240, MonitorEntries,
		function() return MonitorIndex(prefix) end,
		function(i) DB()[prefix .. "Monitor"] = i end, Dual.ApplyAll)
	monitor:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 94, -8)
	UI.Tooltip(monitor, monitorTitle, L["Numbers as on the \"Monitors\" page."])

	local corner = Choice(L["Corner"], 150, CORNERS,
		function() return Corner(prefix) end,
		function(p) DB()[prefix .. "Point"] = p end, Dual.ApplyAll)
	corner:SetPoint("LEFT", monitor, "RIGHT", 60, 0)
	UI.Tooltip(corner, cornerTitle)

	local offsetX = NumBox(L["Horizontal offset"], prefix .. "OffsetX", Dual.ApplyAll)
	offsetX:SetPoint("TOPLEFT", monitor, "BOTTOMLEFT", 80, -14)
	local offsetY = NumBox(L["vertical"], prefix .. "OffsetY", Dual.ApplyAll)
	offsetY:SetPoint("LEFT", offsetX, "RIGHT", 90, 0)
	return monitor, offsetX
end

-- Slider for the Zone Map size (50–200 % in 5 % steps, like the Titan scale)
local function ZoneMapScaleSlider()
	local s = CreateFrame("Frame", nil, page, "MinimalSliderWithSteppersTemplate")
	s:SetSize(220, 20)
	s.label = UI.Label(page, s, HUD_EDIT_MODE_SETTING_MINIMAP_SIZE)
	s:Init(ZoneMapScale() * 100, 50, 200, 30, {
		[MinimalSliderWithSteppersMixin.Label.Right] = function(v)
			return ("%d %%"):format(v + 0.5)
		end,
	})
	s:RegisterCallback(MinimalSliderWithSteppersMixin.Event.OnValueChanged, function(_, value)
		if not s.quiet then
			Dual.SetZoneMapScale(value)
		end
	end, s)
	function s:Refresh()
		self.quiet = true
		self:SetValue(ZoneMapScale() * 100)
		self.quiet = false
	end
	widgets[#widgets + 1] = s
	return s
end

local function BuildPlacementPage(desc)
	-- Bags
	local bagHead = UI.Text(page, "GameFontNormal", HUD_EDIT_MODE_BAGS_LABEL)
	bagHead:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", 0, -16)
	local cBags = Check(L["Place bags when opened"], "bags",
		L["Moves open bags to the chosen corner each time they open. They stack vertically from there, further columns towards the center of the monitor."],
		Dual.ApplyAll)
	cBags:SetPoint("TOPLEFT", bagHead, "BOTTOMLEFT", -4, -4)
	local bagMonitor = PlacementControls("bags", cBags, L["Monitor for the bags"], L["Corner for the bags"])

	-- Zone Map
	local mapHead = UI.Text(page, "GameFontNormal", L["Zone Map (Shift+M)"])
	mapHead:SetPoint("TOPLEFT", bagMonitor, "BOTTOMLEFT", -90, -52)
	local cShow = Check(L["Show Zone Map"], nil,
		L["Shows or hides Blizzard's Zone Map. Blizzard remembers the state itself (CVar showBattlefieldMinimap)."],
		nil, Dual.IsZoneMapShown, Dual.SetZoneMapShown)
	cShow:SetPoint("TOPLEFT", mapHead, "BOTTOMLEFT", -4, -4)
	local cPlace = Check(L["Place Zone Map when shown"], "zoneMap",
		L["Moves the Zone Map and its tab to the chosen corner each time it is shown. Dragging the tab then only lasts until it is shown again."],
		Dual.ApplyAll)
	cPlace:SetPoint("TOPLEFT", cShow, "BOTTOMLEFT", 0, -2)
	local mapMonitor, mapOffsetX = PlacementControls("zoneMap", cPlace, L["Monitor for the Zone Map"], L["Corner for the Zone Map"])
	-- The size also applies without placement; left-aligned with the monitor button
	local mapScale = ZoneMapScaleSlider()
	mapScale:SetPoint("TOPLEFT", mapOffsetX, "BOTTOMLEFT", -80, -14)

	-- World Map: maximized and minimized ("Map & Quest Log") each on a whole monitor
	local worldHead = UI.Text(page, "GameFontNormal", WORLDMAP_BUTTON)
	worldHead:SetPoint("TOPLEFT", mapScale, "BOTTOMLEFT", -90, -20)
	local cWorld = Check(L["Maximized World Map on"], "worldMap",
		L["Blizzard places the maximized World Map across the whole game window, i.e. across all monitors. On: map and black background only on the selected monitor."],
		Dual.ApplyAll)
	cWorld:SetPoint("TOPLEFT", worldHead, "BOTTOMLEFT", -4, -4)
	local worldMonitor = Choice("", 240, MonitorEntries,
		function() return MonitorIndex("worldMap") end,
		function(i) DB().worldMapMonitor = i end, Dual.ApplyAll)
	worldMonitor:SetPoint("LEFT", cWorld, "LEFT", 260, 0)
	UI.Tooltip(worldMonitor, L["Monitor for the maximized World Map"], L["Numbers as on the \"Monitors\" page."])
	local cQuest = Check(L["\"Map & Quest Log\" on"], "questLog",
		L["The minimized World Map with the quest log – opening the quest log shows this view. Blizzard places it at the left edge of the game window. On: at the left edge of the selected monitor."],
		Dual.ApplyAll)
	cQuest:SetPoint("TOPLEFT", cWorld, "BOTTOMLEFT", 0, -6)
	local questMonitor = Choice("", 240, MonitorEntries,
		function() return MonitorIndex("questLog") end,
		function(i) DB().questLogMonitor = i end, Dual.ApplyAll)
	questMonitor:SetPoint("LEFT", cQuest, "LEFT", 260, 0)
	UI.Tooltip(questMonitor, L["Monitor for \"Map & Quest Log\""], L["Numbers as on the \"Monitors\" page."])

	local cFollow = Check(L["Map follows the current zone"], "mapFollowZone",
		L["While the map is open, switches to the new zone's map when you enter it. Blizzard shows the current zone anyway when the map opens."])
	cFollow:SetPoint("TOPLEFT", cQuest, "BOTTOMLEFT", 0, -6)
	local cOpen = Check(L["Open the map on login"], "mapAutoOpen",
		L["Only on login and after /reload, not after loading screens."])
	cOpen:SetPoint("LEFT", cFollow, "LEFT", 300, 0)
	local cFade = Check(L["Do not fade the map while moving"], "mapNoFade",
		L["Sets the Blizzard option mapFade to 0. Turning this off restores the previous value. Blizzard only fades the map while the mouse is not over it – so hardly ever with the maximized map."],
		function() ApplyMapFade(true) end)
	cFade:SetPoint("TOPLEFT", cFollow, "BOTTOMLEFT", 0, -2)

	local cGuides = Check(L["Show areas"], "guides",
		L["Outlines the areas: blue bags, yellow Zone Map, green World Map, purple \"Map & Quest Log\" (only while placement is on)."], Dual.UpdateArea)
	cGuides:SetPoint("TOPLEFT", cFade, "BOTTOMLEFT", 0, -10)

	local apply = ApplyButton(cGuides, false)
	local openMap = UI.Button(page, L["Open map"], 160, Dual.OpenMap)
	openMap:SetPoint("LEFT", apply, "RIGHT", 10, 0)
end

---------------------------------------------------------------------------
-- List of elements outside the monitors, one button per element
---------------------------------------------------------------------------

local ROW_HEIGHT = 26
local listPage, listContent, listHeader, listChecked   -- listPage: UI.Page of the "Monitors" page
local rows = {}

-- Marks the element whose button the mouse is over
local marker = CreateFrame("Frame", nil, UIParent)
marker.qnViewPortIgnore = true
marker:SetFrameStrata("TOOLTIP")
marker:Hide()
do
	local tex = marker:CreateTexture(nil, "OVERLAY")
	tex:SetAllPoints()
	tex:SetColorTexture(1, 0, 0, 0.35)
end

local function RowEnter(button)
	local e = button:GetParent().entry
	if not e then
		return
	end
	marker:ClearAllPoints()
	marker:SetAllPoints(e.frame)
	marker:Show()
	GameTooltip:SetOwner(button, "ANCHOR_LEFT")
	GameTooltip:AddLine(e.name)
	GameTooltip:AddLine(L["Moves only this element onto a monitor by the shortest path. Marked in red: its current area."], 1, 1, 1, true)
	if e.editMode then
		GameTooltip:AddLine(L["Edit Mode frame: lasts until /reload or until the layout is reloaded. To keep it: move it in Edit Mode."], 1, 0.8, 0.3, true)
	end
	if e.protected then
		GameTooltip:AddLine(L["Protected frame: not in combat. Moving it from addon code can cause \"action blocked\" messages (taint)."], 1, 0.5, 0.5, true)
	end
	GameTooltip:Show()
end

local function RowLeave()
	marker:Hide()
	GameTooltip:Hide()
end

local function Row(i)
	local row = rows[i]
	if row then
		return row
	end
	row = CreateFrame("Frame", nil, listContent)
	row:SetHeight(ROW_HEIGHT)
	row:SetPoint("TOPLEFT", 0, -(i - 1) * ROW_HEIGHT)
	row:SetPoint("RIGHT", listContent, "RIGHT")
	if i % 2 == 0 then
		local bg = row:CreateTexture(nil, "BACKGROUND")
		bg:SetAllPoints()
		bg:SetColorTexture(1, 1, 1, 0.04)
	end
	row.name = UI.Text(row, "GameFontHighlight")
	row.name:SetPoint("LEFT", 4, 0)
	row.name:SetWidth(210)
	row.name:SetWordWrap(false)
	row.where = UI.Text(row, "GameFontHighlightSmall")
	row.where:SetPoint("LEFT", row.name, "RIGHT", 8, 0)
	row.where:SetWidth(170)
	row.notes = UI.Text(row, "GameFontDisableSmall")
	row.notes:SetPoint("LEFT", row.where, "RIGHT", 6, 0)
	row.notes:SetWidth(130)
	row.notes:SetWordWrap(false)
	row.button = UI.Button(row, L["Move into visible area"], 180, function(self)
		local e = self:GetParent().entry
		if e then
			marker:Hide()
			ns.Layout.MoveFrame(e.frame)
			Dual.CheckVisible()
		end
	end)
	row.button:SetHeight(22)
	row.button:SetPoint("RIGHT", -4, 0)
	row.button:SetScript("OnEnter", RowEnter)
	row.button:SetScript("OnLeave", RowLeave)
	rows[i] = row
	return row
end

-- Checks all interface elements and fills the list. Moves nothing.
function Dual.CheckVisible()
	listChecked = true
	local list = ns.Layout.CheckFrames()
	for i, e in ipairs(list) do
		local row = Row(i)
		row.entry = e
		local where, notes = ns.Layout.DescribeEntry(e)
		row.name:SetText(e.name)
		row.where:SetText(where)
		row.notes:SetText(notes)
		row:Show()
	end
	for i = #list + 1, #rows do
		rows[i].entry = nil
		rows[i]:Hide()
	end
	listContent:SetHeight(math.max(1, #list * ROW_HEIGHT))
	listContent:SetShown(#list > 0)
	if #list == 0 then
		listHeader:SetText("|cff80ff80" .. L["All shown interface elements are on a monitor."] .. "|r")
	else
		listHeader:SetText(L["%d element(s) fully or partly outside the monitors"]:format(#list))
	end
	listPage.Fit()
end

-- List in the page content (scrolls with the page)
local function BuildVisibleList(parent, anchor)
	listHeader = UI.Text(parent, "GameFontNormal", L["Not checked yet – press \"Check visibility\"."])
	listHeader:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -14)

	listContent = CreateFrame("Frame", nil, parent)
	listContent:SetPoint("TOPLEFT", listHeader, "BOTTOMLEFT", 0, -6)
	listContent:SetPoint("RIGHT", parent, "RIGHT", -16, 0)
	listContent:SetHeight(1)
	listContent:Hide()
	local bg = listContent:CreateTexture(nil, "BACKGROUND")
	bg:SetAllPoints()
	bg:SetColorTexture(0, 0, 0, 0.25)
	parent:HookScript("OnHide", RowLeave)
end

---------------------------------------------------------------------------
-- Options page (subcategory "Monitors")
---------------------------------------------------------------------------

local function BuildMonitorPage(desc, ui)
	listPage = ui
	local cData = Check(L["Use monitor data"], "useMonitorData",
		L["Off: position and size of the second monitor come from the \"Second Monitor\" page."], function()
			if DB().enabled then
				Dual.Reapply(true)
			else
				ns.Layout.Refresh()
				Dual.RefreshOptions()
			end
		end)
	cData:SetPoint("TOPLEFT", desc, "BOTTOMLEFT", -4, -14)

	local apply = ApplyButton(cData, true)

	-- Move the Blizzard interface only on button press (until reset or /reload)
	local uiMain = UI.Button(page, L["Interface to main monitor"], 220, function()
		ns.Layout.ConstrainUI()
		Dual.RefreshOptions()
	end, L["Places UIParent over the main monitor once. Caution: this moves ALL Blizzard windows attached to UIParent (action bars, minimap, objective tracker, chat …). Lasts until reset or /reload; dual monitor mode only."])
	uiMain:SetPoint("TOPLEFT", apply, "BOTTOMLEFT", 0, -10)
	local uiReset = UI.Button(page, RESET, 160, function()
		ns.Layout.ReleaseUI()
		Dual.RefreshOptions()
	end, L["Places the Blizzard interface across the whole game window again."])
	uiReset:SetPoint("LEFT", uiMain, "RIGHT", 10, 0)
	local check = UI.Button(page, L["Check visibility"], 160, Dual.CheckVisible,
		L["Finds all shown interface elements that are fully or partly outside every monitor and lists them below. Only what you click there, one at a time, is moved."])
	check:SetPoint("LEFT", apply, "RIGHT", 10, 0)

	monInfo = UI.Text(page, "GameFontHighlight")
	monInfo:SetPoint("TOPLEFT", uiMain, "BOTTOMLEFT", 0, -16)
	monInfo:SetWidth(620)

	BuildVisibleList(page, monInfo)

	ui.panel:HookScript("OnShow", function()
		if listChecked then
			Dual.CheckVisible()   -- the position may have changed since the last check
		end
	end)
end

function Dual.OpenOptions()
	qnCore.OpenCategory(sub)
end

---------------------------------------------------------------------------
-- Start (from Core.lua after ADDON_LOADED); applied afterwards via ns.ApplyGeometry.
---------------------------------------------------------------------------

function ns.InitSecondScreen()
	NewPage(L["Monitors"],
		L["The monitor data (Monitors.lua) is written by qnViewPort\\scripts\\Initialize-WowMonitors.ps1: select the monitors once and set the main monitor. Set-WowWindow.ps1 then stretches the game window across the selected monitors and updates the data. /reload after a change."],
		BuildMonitorPage)
	sub = NewPage(L["Second Monitor"],
		L["The game window must be stretched across several monitors (windowed mode, e.g. 5760 × 2160). The 3D world is then placed on the main monitor. Move interface elements with Blizzard's Edit Mode; elements outside the monitors are listed on the \"Monitors\" page, bags, Zone Map and World Map are on the \"Placement\" page."],
		BuildPage)
	NewPage(L["Placement"],
		L["Places bags and the Zone Map in a corner of a monitor and the World Map on a monitor. Offsets are counted in pixels inward from the edges of the corner. Unless checked, qnViewPort does not touch that window."],
		BuildPlacementPage)

	-- Bags: Blizzard sets the anchors in UpdateContainerFrameAnchors – on opening and closing
	-- each bag and the combined bag (ContainerFrame.lua). Our hook runs afterwards,
	-- docking in the next frame and only once for several calls.
	local dockLater = qnCore.Debounce(Dual.DockBags)
	hooksecurefunc("UpdateContainerFrameAnchors", function()
		if DB().bags then
			dockLater()
		end
	end)
	-- Tooltips on bag slots
	hooksecurefunc(GameTooltip, "SetBagItem", OnSetBagItem)
	hooksecurefunc(TooltipComparisonManager, "AnchorShoppingTooltips", OnAnchorShoppingTooltips)
	-- Zone Map and World Map: already loaded or later via ADDON_LOADED
	HookZoneMap()
	HookWorldMap()

	local events = ns.events
	events.Register("ADDON_LOADED", function(_, name)
		if name == ZONEMAP_ADDON then
			HookZoneMap()
		elseif name == "Blizzard_WorldMap" then
			HookWorldMap()
		end
	end)
	events.Register("PLAYER_ENTERING_WORLD", function(_, isInitialLogin, isReloadingUi)
		C_Timer.After(1, function()
			Dual.UpdateArea()
			Dual.PlaceZoneMap()
			ApplyMapFade()
			-- only on login or /reload, not after every loading screen
			if DB().mapAutoOpen and (isInitialLogin or isReloadingUi) then
				Dual.OpenMap()
			end
		end)
	end)
	events.Register("ZONE_CHANGED_NEW_AREA", function()
		if DB().mapFollowZone then
			MapToCurrentZone()
		end
	end)
end
