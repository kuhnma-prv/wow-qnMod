-- qnGatherer: minimap. Own pins on a frame over the minimap: item icon, within the tracking
-- distance a ring in the color of the kind. Nodes outside the view slide along the edge and fade
-- out (up to twice the view radius). Supports the rotating minimap and the minimap shapes of other
-- addons (GetMinimapShape). Left click on a pin pings the minimap there.

local ADDON, ns = ...
local DB, D = ns.DB, ns.Display

local M = {}
ns.Minimap = M

local UPDATE_INTERVAL = 0.05   -- seconds between position updates
local REBUILD_INTERVAL = 2     -- seconds between rebuilding the candidate list
local PIN_SIZE = 12
local RING = "Interface\\AddOns\\qnGatherer\\Media\\Ring"

-- Minimap shapes: per quadrant whether it is round (true) or square. Quadrants with x to the
-- right and y up: 1 = bottom right, 2 = bottom left, 3 = top right, 4 = top left.
local SHAPES = {
	ROUND = { true, true, true, true },
	SQUARE = { false, false, false, false },
	["CORNER-TOPLEFT"] = { false, false, false, true },
	["CORNER-TOPRIGHT"] = { false, false, true, false },
	["CORNER-BOTTOMLEFT"] = { false, true, false, false },
	["CORNER-BOTTOMRIGHT"] = { true, false, false, false },
	["SIDE-LEFT"] = { false, true, false, true },
	["SIDE-RIGHT"] = { true, false, true, false },
	["SIDE-TOP"] = { false, false, true, true },
	["SIDE-BOTTOM"] = { true, true, false, false },
	["TRICORNER-TOPLEFT"] = { false, true, true, true },
	["TRICORNER-TOPRIGHT"] = { true, false, true, true },
	["TRICORNER-BOTTOMLEFT"] = { true, true, false, true },
	["TRICORNER-BOTTOMRIGHT"] = { true, true, true, false },
}

local frame
local pins = {}
local candidates = {}   -- { kind, res, origin, x, y, circle } of the current map
local builtMap, builtAt
local elapsedSince = 0

---------------------------------------------------------------------------
-- Geometry
---------------------------------------------------------------------------

-- Position of a node on the minimap. dx, dy: offset from the player in yards on the map (x east,
-- y south); facing: player facing for a rotating minimap (nil = north up); radius: view radius in
-- yards; shape: minimap shape. Returns sx, sy (yards, x right, y up; moved onto the edge if
-- outside) and d (distance relative to the edge: <= 1 inside).
function M.Project(dx, dy, facing, radius, shape)
	local sx, sy = dx, -dy
	if facing then
		local c, s = math.cos(facing), math.sin(facing)
		sx, sy = dx * c - dy * s, -dx * s - dy * c
	end
	local q = 1
	if sx < 0 then q = q + 1 end
	if sy > 0 then q = q + 2 end
	local round = (SHAPES[shape] or SHAPES.ROUND)[q]
	local d
	if round then
		d = math.sqrt(sx * sx + sy * sy) / radius
	else
		d = math.max(math.abs(sx), math.abs(sy)) / radius
	end
	if d > 1 then
		sx, sy = sx / d, sy / d
	end
	return sx, sy, d
end

---------------------------------------------------------------------------
-- Pins
---------------------------------------------------------------------------

local function PinsUnderMouse(self)
	local list = { self }
	for _, pin in ipairs(pins) do
		if pin ~= self and pin:IsShown() and pin:IsMouseOver() then
			list[#list + 1] = pin
		end
	end
	return list
end

local function PinEnter(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	for _, pin in ipairs(PinsUnderMouse(self)) do
		D.AddTooltipLines(GameTooltip, pin.entry)
	end
	GameTooltip:Show()
end

local function PinLeave()
	GameTooltip:Hide()
end

local function PinClick(self)
	Minimap:PingLocation(self.ox, self.oy)
end

local function AcquirePin(i)
	local pin = pins[i]
	if not pin then
		pin = CreateFrame("Button", nil, frame)
		pin.Icon = pin:CreateTexture(nil, "ARTWORK")
		pin.Icon:SetAllPoints()
		pin:RegisterForClicks("LeftButtonUp")
		pin:SetScript("OnEnter", PinEnter)
		pin:SetScript("OnLeave", PinLeave)
		pin:SetScript("OnClick", PinClick)
		pins[i] = pin
	end
	return pin
end

local function SetPin(pin, entry, ring, ox, oy, alpha)
	local opts = ns.db.minimap
	pin.entry, pin.ox, pin.oy, pin.ring = entry, ox, oy, ring
	local size = PIN_SIZE * opts.scale
	pin:SetSize(size, size)
	if ring then
		local c = D.Color(entry.kind)
		pin.Icon:SetTexture(RING)
		pin.Icon:SetVertexColor(c[1], c[2], c[3], c[4] or 1)
	else
		pin.Icon:SetTexture(D.ResourceIcon(entry.kind, entry.res))
		pin.Icon:SetVertexColor(1, 1, 1, 1)
	end
	pin:EnableMouse(opts.tooltips)
	pin:ClearAllPoints()
	pin:SetPoint("CENTER", frame, "CENTER", ox, oy)
	pin:SetAlpha(alpha)
	pin:Show()
end

---------------------------------------------------------------------------
-- Update
---------------------------------------------------------------------------

-- Candidate list of map: shown kinds, filtered nodes
function M.Rebuild(map)
	wipe(candidates)
	builtMap, builtAt = map, GetTime()
	if not map or not ns.db.minimap.show then
		return
	end
	for _, key in ipairs(ns.KIND_ORDER) do
		if D.KindShown(key) then
			local circle = D.KindShown(key, ns.db.circle.show)
			for coord, n in DB.Nodes(key, map) do
				if D.NodeShown(key, n.res, n.origin) then
					local x, y = DB.Decode(coord)
					candidates[#candidates + 1] = { kind = key, res = n.res, origin = n.origin, x = x, y = y, circle = circle }
				end
			end
		end
	end
end

-- Places the pins for the player at px, py on map; returns the number of shown pins.
function M.Update()
	local map, px, py = ns.Collector.PlayerPosition()
	local count = 0
	if map and ns.db.minimap.show then
		if map ~= builtMap or GetTime() - builtAt >= REBUILD_INTERVAL then
			M.Rebuild(map)
		end
		local opts = ns.db.minimap
		local w, h = DB.MapSize(map)
		local radius = C_Minimap.GetViewRadius()
		local facing = C_CVar.GetCVarBool("rotateMinimap") and GetPlayerFacing() or nil
		if facing and ns.IsSecret(facing) then
			facing = nil
		end
		local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
		local scale = (Minimap:GetWidth() / 2) / radius
		local ringDistance = ns.db.circle.distance
		for _, c in ipairs(candidates) do
			local dx, dy = (c.x - px) * w, (c.y - py) * h
			if math.abs(dx) <= 2 * radius and math.abs(dy) <= 2 * radius then
				local sx, sy, d = M.Project(dx, dy, facing, radius, shape)
				local alpha
				if d <= 1 then
					alpha = opts.alpha
				elseif opts.edge then
					alpha = math.min(opts.alpha, 2 - d)
				end
				if alpha and alpha > 0 then
					count = count + 1
					local ring = c.circle and math.sqrt(dx * dx + dy * dy) <= ringDistance
					SetPin(AcquirePin(count), c, ring, sx * scale, sy * scale, alpha)
				end
			end
		end
	end
	for i = count + 1, #pins do
		pins[i]:Hide()
	end
	return count
end

local function OnUpdate(_, elapsed)
	elapsedSince = elapsedSince + elapsed
	if elapsedSince >= UPDATE_INTERVAL then
		elapsedSince = 0
		M.Update()
	end
end

-- Puts the pins onto another minimap frame (for minimap addons that replace Blizzard's)
function M.SetParent(parent)
	frame:SetParent(parent)
	frame:ClearAllPoints()
	frame:SetAllPoints(parent)
	frame:SetFrameLevel(parent:GetFrameLevel() + 5)
end

M.Pins = pins

function M.Init()
	frame = CreateFrame("Frame", nil, Minimap)
	M.SetParent(Minimap)
	frame:SetScript("OnUpdate", OnUpdate)
	D.OnRefresh(function()
		builtMap = nil   -- rebuild on the next update
	end)
	ns.events.Register("ZONE_CHANGED_NEW_AREA", function()
		builtMap = nil
	end)
end
