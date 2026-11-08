-- qnGatherer: world map. An own data provider on Blizzard's WorldMapFrame (MapCanvas) acquires
-- node pins (item icon) and optional area pins (ellipse in the color of the kind). Pin templates
-- in WorldMapPins.xml. Right click on a node: delete, waypoint, TomTom waypoint.

local ADDON, ns = ...
local DB, D = ns.DB, ns.Display
local L = ns.L

local W = {}
ns.WorldMap = W

local NODE_TEMPLATE = "qnGathererNodePinTemplate"
local AREA_TEMPLATE = "qnGathererAreaPinTemplate"
local AREA_ALPHA = 0.35

---------------------------------------------------------------------------
-- Content of a map (also used by the tests)
---------------------------------------------------------------------------

-- Nodes { kind, coord, x, y, res, origin } and areas { kind, area, origin } of map that the profile shows
function W.Collect(map)
	local nodes, areas = {}, {}
	local opts = ns.db.worldMap
	if not opts.show or not map then
		return nodes, areas
	end
	for _, key in ipairs(ns.KIND_ORDER) do
		if D.KindShown(key) then
			for coord, n in DB.Nodes(key, map) do
				if D.NodeShown(key, n.res, n.origin) then
					local x, y = DB.Decode(coord)
					nodes[#nodes + 1] = { kind = key, coord = coord, x = x, y = y, res = n.res, origin = n.origin }
				end
			end
			if opts.areas then
				for _, a in ipairs(DB.GetAreas(key, map)) do
					local origin = DB.OriginName(a.o)
					for _, res in ipairs(a.res) do
						if D.NodeShown(key, res, origin) then
							areas[#areas + 1] = { kind = key, area = a, origin = origin }
							break
						end
					end
				end
			end
		end
	end
	return nodes, areas
end

---------------------------------------------------------------------------
-- Waypoints
---------------------------------------------------------------------------

function W.SetWaypoint(map, x, y)
	-- UiMapPoint is not in the documented API: only used if present
	if not (UiMapPoint and UiMapPoint.CreateFromCoordinates) or not C_Map.CanSetUserWaypointOnMap(map) then
		ns.Print(L["A waypoint cannot be set on this map."])
		return
	end
	C_Map.SetUserWaypoint(UiMapPoint.CreateFromCoordinates(map, x, y))
	C_SuperTrack.SetSuperTrackedUserWaypoint(true)
end

local function TomTomAvailable()
	return type(TomTom) == "table" and type(TomTom.AddWaypoint) == "function"
end

---------------------------------------------------------------------------
-- Node pins
---------------------------------------------------------------------------

qnGathererNodePinMixin = CreateFromMixins(MapCanvasPinMixin)
local NodePin = qnGathererNodePinMixin

function NodePin:OnLoad()
	self:UseFrameLevelType("PIN_FRAME_LEVEL_AREA_POI")
	self:SetScalingLimits(1, 1.0, 1.2)
end

function NodePin:OnAcquired(entry, map)
	self.entry, self.mapID = entry, map
	local opts = ns.db.worldMap
	local size = 12 * opts.scale
	self:SetSize(size, size)
	self.Icon:SetTexture(D.ResourceIcon(entry.kind, entry.res))
	self:SetAlpha(opts.alpha)
	self:SetMouseMotionEnabled(opts.clickable)
	self:SetMouseClickEnabled(opts.clickable)
	self:SetPosition(entry.x, entry.y)
end

-- Right click opens the menu instead of zooming out (only if clickable)
function NodePin:ShouldMouseButtonBePassthrough(button)
	return button == "RightButton" and not ns.db.worldMap.clickable
end

-- This pin and all other node pins under the mouse
function NodePin:PinsUnderMouse()
	local pins = { self }
	for pin in self:GetMap():EnumeratePinsByTemplate(NODE_TEMPLATE) do
		if pin ~= self and pin:IsMouseOver() then
			pins[#pins + 1] = pin
		end
	end
	return pins
end

function NodePin:OnMouseEnter()
	GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
	for _, pin in ipairs(self:PinsUnderMouse()) do
		D.AddTooltipLines(GameTooltip, pin.entry)
	end
	GameTooltip:Show()
end

function NodePin:OnMouseLeave()
	GameTooltip:Hide()
end

function NodePin:OnMouseUpAction(button, upInside)
	if button == "RightButton" and upInside then
		W.ShowMenu(self)
	end
end

-- Context menu of the node pins under the mouse
function W.ShowMenu(owner)
	local pins = owner:PinsUnderMouse()
	MenuUtil.CreateContextMenu(owner, function(_, root)
		root:CreateTitle(ADDON)
		for _, pin in ipairs(pins) do
			local e, map = pin.entry, pin.mapID
			root:CreateButton(L["Delete: %s"]:format(D.ResourceName(e.res)), function()
				if not DB.Delete(e.kind, map, e.coord) then
					ns.Print(L["The database of %s is locked."]:format(ns.KINDS[e.kind].name))
				end
			end)
		end
		local e, map = owner.entry, owner.mapID
		root:CreateButton(L["Set waypoint"], function()
			W.SetWaypoint(map, e.x, e.y)
		end)
		if TomTomAvailable() then
			root:CreateButton(L["Add TomTom waypoint"], function()
				TomTom:AddWaypoint(map, e.x, e.y, { title = D.ResourceName(e.res) })
			end)
		end
	end)
end

---------------------------------------------------------------------------
-- Area pins (ellipse scaled with the map)
---------------------------------------------------------------------------

qnGathererAreaPinMixin = CreateFromMixins(MapCanvasPinMixin)
local AreaPin = qnGathererAreaPinMixin

function AreaPin:OnLoad()
	self:UseFrameLevelType("PIN_FRAME_LEVEL_DIG_SITE")
	self:SetIgnoreGlobalPinScale(true)
	self:SetScaleStyle(AM_PIN_SCALE_STYLE_WITH_TERRAIN)
end

function AreaPin:OnAcquired(entry)
	local a = entry.area
	local canvas = self:GetMap():GetCanvas()
	self:SetSize(a.rx * 2 * canvas:GetWidth(), a.ry * 2 * canvas:GetHeight())
	local c = D.Color(entry.kind)
	self.Area:SetVertexColor(c[1], c[2], c[3], AREA_ALPHA)
	self:SetPosition(a.x, a.y)
end

---------------------------------------------------------------------------
-- Data provider
---------------------------------------------------------------------------

local provider = CreateFromMixins(MapCanvasDataProviderMixin)
W.provider = provider

function provider:RemoveAllData()
	local map = self:GetMap()
	map:RemoveAllPinsByTemplate(NODE_TEMPLATE)
	map:RemoveAllPinsByTemplate(AREA_TEMPLATE)
end

function provider:RefreshAllData()
	self:RemoveAllData()
	local map = self:GetMap()
	local mapID = map:GetMapID()
	local nodes, areas = W.Collect(mapID)
	for _, entry in ipairs(areas) do
		map:AcquirePin(AREA_TEMPLATE, entry)
	end
	for _, entry in ipairs(nodes) do
		map:AcquirePin(NODE_TEMPLATE, entry, mapID)
	end
end

function W.Refresh()
	if provider:GetMap() and WorldMapFrame:IsShown() then
		provider:RefreshAllData()
	end
end

function W.Init()
	WorldMapFrame:AddDataProvider(provider)
	D.OnRefresh(W.Refresh)
end
