-- qnGatherer: Titan plugin (only if Titan is loaded, ## OptionalDeps: Titan).
--   qnGatherer  [icon] Nodes: 12   shown nodes of the current zone. Tooltip: nodes per kind in this
--               zone and in total, state of the icons. Left-click: minimap icons on/off,
--               Shift-left-click: world map icons on/off. Right-click: Titan menu with options.
-- Titan registers plugins on entering the world; the button is therefore created at load time.

local ADDON, ns = ...
local L = ns.L
local DB, D = ns.DB, ns.Display

local Titan = {}
ns.Titan = Titan

local ID = "qnGatherer"   -- do not translate
local ICON = "Interface\\AddOns\\qnCore\\Media\\qnIcon"

-- Shown nodes of kind on map (visibility and filters of the profile)
local function ShownNodes(kind, map)
	local count = 0
	if map and D.KindShown(kind) then
		for _, n in DB.Nodes(kind, map) do
			if D.NodeShown(kind, n.res, n.origin) then
				count = count + 1
			end
		end
	end
	return count
end

function Titan.ZoneCount()
	local map = C_Map.GetBestMapForUnit("player")
	local count = 0
	for _, kind in ipairs(ns.KIND_ORDER) do
		count = count + ShownNodes(kind, map)
	end
	return count
end

local function ButtonText()
	return L["Nodes:"], TitanUtils_GetHighlightText(tostring(Titan.ZoneCount()))
end

local function Tooltip()
	local tip = GameTooltip
	local map = C_Map.GetBestMapForUnit("player")
	tip:AddDoubleLine(L["Kind"], L["Zone / total"])
	for _, kind in ipairs(ns.OptionKinds()) do
		tip:AddDoubleLine(ns.KINDS[kind].name, ("%d / %d"):format(map and DB.CountNodes(kind, map) or 0, DB.CountNodes(kind)), 1, 1, 1, 1, 1, 1)
	end
	tip:AddLine(" ")
	ns.Launcher.Tooltip(tip)
end

local function Menu(_, root)
	Titan_Menu.AddCommand(root, ID, L["Minimap icons on/off"], ns.ToggleMinimap)
	Titan_Menu.AddCommand(root, ID, L["World map icons on/off"], ns.ToggleWorldMap)
	Titan_Menu.AddDivider(root)
	Titan_Menu.AddCommand(root, ID, OPTIONS, function() ns.OpenOptions() end)
end

function Titan.Update()
	if Titan.active then
		TitanPanelButton_UpdateButton(ID)
	end
end

-- Without Titan: no plugin
Titan.active = C_AddOns.IsAddOnLoaded("Titan") and Titan_G and type(Titan_G.plugins.ToRegister) == "function"
if Titan.active then
	local button = CreateFrame("Button", "TitanPanel" .. ID .. "Button", CreateFrame("Frame", nil, UIParent),
		"TitanPanelComboTemplate")
	button:SetFrameStrata("FULLSCREEN")
	button.registry = {
		id = ID,
		category = "Information",
		version = ns.version,
		menuText = ADDON,
		buttonTextFunction = ButtonText,
		tooltipTemplateFunction = Tooltip,
		menuContextFunction = Menu,
		icon = ICON,
		iconWidth = 16,
		notes = L["Shown gathering nodes of the current zone; left-click: minimap icons on/off, Shift-left-click: world map icons on/off."],
		controlVariables = { ShowIcon = true, ShowLabelText = true, DisplayOnRightSide = true },
		savedVariables = { ShowIcon = true, ShowLabelText = true, DisplayOnRightSide = false },
	}
	button:SetScript("OnClick", function(self, mouse)
		if mouse == "LeftButton" then
			ns.Launcher.Click(mouse)
		end
		TitanPanelButton_OnClick(self, mouse)
	end)
end

function Titan.Init()
	if not Titan.active then return end
	D.OnRefresh(Titan.Update)
	ns.events.Register("ZONE_CHANGED_NEW_AREA", Titan.Update)
end
