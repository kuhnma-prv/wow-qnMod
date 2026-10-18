-- qnGatherer: minimap button (account-wide, qnGathererDB.global.launcher = { show, angle }).
-- Left-click: minimap icons on/off, Shift-left-click: world map icons on/off, right-click: options.
-- Dragging moves it along the edge of the minimap (also square minimap shapes of other addons).

local ADDON, ns = ...
local L = ns.L
local DB = ns.DB

local Launcher = {}
ns.Launcher = Launcher

local ICON = "Interface\\AddOns\\qnCore\\Media\\qnIcon"
local OFFSET = 10   -- distance of the button center outside the minimap edge

local button

-- Offset of the button from the minimap center for angle (degrees, 0 = right, counterclockwise);
-- quadrants and shapes as in Minimap.lua
function Launcher.Offset(angle, radius, shape)
	local a = math.rad(angle)
	local x, y = math.cos(a), math.sin(a)
	local q = 1
	if x < 0 then q = q + 1 end
	if y > 0 then q = q + 2 end
	local shapes = ns.Minimap.SHAPES
	if not (shapes[shape] or shapes.ROUND)[q] then
		local diag = math.sqrt(2) * radius
		return math.max(-radius, math.min(x * diag, radius)), math.max(-radius, math.min(y * diag, radius))
	end
	return x * radius, y * radius
end

local function Place()
	local radius = Minimap:GetWidth() / 2 + OFFSET
	local shape = GetMinimapShape and GetMinimapShape() or "ROUND"
	local x, y = Launcher.Offset(DB.global.launcher.angle, radius, shape)
	button:ClearAllPoints()
	button:SetPoint("CENTER", Minimap, "CENTER", x, y)
end

-- Angle of the cursor around the minimap center
local function CursorAngle()
	local mx, my = Minimap:GetCenter()
	local scale = Minimap:GetEffectiveScale()
	local cx, cy = GetCursorPosition()
	cx, cy = cx / scale, cy / scale
	local atan2 = math.atan2 or math.atan
	return math.deg(atan2(cy - my, cx - mx)) % 360
end

function Launcher.Click(mouse)
	if mouse == "RightButton" then
		ns.OpenOptions()
	elseif IsShiftKeyDown() then
		ns.ToggleWorldMap()
	else
		ns.ToggleMinimap()
	end
end

local function OnOff(on)
	return on and L["on"] or L["off"]
end

function Launcher.Tooltip(tip)
	tip:AddLine(ADDON)
	tip:AddDoubleLine(L["Minimap icons"], OnOff(ns.db.minimap.show), 1, 1, 1, 1, 1, 1)
	tip:AddDoubleLine(L["World map icons"], OnOff(ns.db.worldMap.show), 1, 1, 1, 1, 1, 1)
	tip:AddLine(L["Left-click: minimap icons on/off\nShift-left-click: world map icons on/off\nRight-click: options"], 0, 1, 0)
end

function Launcher.Update()
	if not button then
		return
	end
	button:SetShown(DB.global.launcher.show)
	Place()
end

function Launcher.Init()
	button = CreateFrame("Button", "qnGathererMinimapButton", Minimap)
	button:SetSize(31, 31)
	button:SetFrameStrata("MEDIUM")
	button:SetFrameLevel(Minimap:GetFrameLevel() + 8)
	button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
	button:RegisterForDrag("LeftButton")
	button:SetHighlightTexture("Interface\\Minimap\\UI-Minimap-ZoomButton-Highlight")
	local background = button:CreateTexture(nil, "BACKGROUND")
	background:SetTexture("Interface\\Minimap\\UI-Minimap-Background")
	background:SetSize(20, 20)
	background:SetPoint("CENTER")
	local icon = button:CreateTexture(nil, "ARTWORK")
	icon:SetTexture(ICON)
	icon:SetSize(18, 18)
	icon:SetPoint("CENTER")
	local border = button:CreateTexture(nil, "OVERLAY")
	border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
	border:SetSize(53, 53)
	border:SetPoint("TOPLEFT")
	button:SetScript("OnClick", function(_, mouse)
		Launcher.Click(mouse)
	end)
	button:SetScript("OnEnter", function(self)
		GameTooltip:SetOwner(self, "ANCHOR_LEFT")
		Launcher.Tooltip(GameTooltip)
		GameTooltip:Show()
	end)
	button:SetScript("OnLeave", function()
		GameTooltip:Hide()
	end)
	button:SetScript("OnDragStart", function(self)
		self:SetScript("OnUpdate", function()
			DB.global.launcher.angle = CursorAngle()
			Place()
		end)
	end)
	button:SetScript("OnDragStop", function(self)
		self:SetScript("OnUpdate", nil)
	end)
	Launcher.button = button
	Launcher.Update()
end
