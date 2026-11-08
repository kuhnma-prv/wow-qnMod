-- qnMarkers: raid markers and the secure actions of the bar buttons.
--
-- Forever (SecureTemplates.lua): SECURE_ACTIONS.worldmarker (attributes marker, action = set,
-- clear, toggle; clear without marker clears all) and SECURE_ACTIONS.raidtarget (marker, action =
-- set, clear, toggle; unit default "target"). World markers only exist while
-- IsRaidMarkerSystemEnabled() is true; otherwise the right button sets the target marker too.

local _, ns = ...

-- Bar order. world = index for PlaceRaidMarker (/wm), target = index for SetRaidTarget (/tm);
-- the pairs show the same symbol (WORLD_MARKER1-8 of the GlobalStrings).
ns.MARKERS = {
	{ world = 8, target = 8 },   -- Skull
	{ world = 7, target = 5 },   -- Moon
	{ world = 6, target = 2 },   -- Circle
	{ world = 5, target = 1 },   -- Star
	{ world = 4, target = 7 },   -- Cross
	{ world = 3, target = 3 },   -- Diamond
	{ world = 2, target = 4 },   -- Triangle
	{ world = 1, target = 6 },   -- Square
}

function ns.MarkerIcon(target)
	return "Interface\\TargetingFrame\\UI-RaidTargetingIcon_" .. target
end

function ns.WorldMarkersEnabled()
	return IsRaidMarkerSystemEnabled()
end

-- One mouse button sets the target marker on the current target (player or NPC), the other places
-- the world marker (or sets the target marker too without world markers).
-- leftClick: "target" = left button target marker, right button world marker; "world" = the other way.
function ns.ConfigureMarker(button, marker, leftClick)
	local world = ns.WorldMarkersEnabled()
	local worldButton, targetButton = 2, 1
	if leftClick == "world" then
		worldButton, targetButton = 1, 2
	end
	button:SetAttribute("type" .. targetButton, "raidtarget")
	button:SetAttribute("marker" .. targetButton, marker.target)
	button:SetAttribute("action" .. targetButton, "set")
	button:SetAttribute("type" .. worldButton, world and "worldmarker" or "raidtarget")
	button:SetAttribute("marker" .. worldButton, world and marker.world or marker.target)
	button:SetAttribute("action" .. worldButton, "set")
end

-- Clear all world markers (left button)
function ns.ConfigureClearWorld(button)
	button:SetAttribute("type1", "worldmarker")
	button:SetAttribute("action1", "clear")
end

-- Clear the target marker of the current target (any button)
function ns.ConfigureClearTarget(button)
	button:SetAttribute("type", "raidtarget")
	button:SetAttribute("action", "clear")
end

-- Macro for "clear everything": two secure actions in one click are only possible as a macro.
-- /cwm compares its argument with the localized ALL (SlashCommands.lua); /tm 0 clears the
-- target marker.
function ns.ClearAllMacro()
	local target = SLASH_TARGET_MARKER1 .. " 0"
	if not ns.WorldMarkersEnabled() then
		return target
	end
	return SLASH_CLEAR_WORLD_MARKER1 .. " " .. ALL .. "\n" .. target
end

-- Right button of the grip: clear all world markers and the marker of the current target
function ns.ConfigureClearAll(button)
	button:SetAttribute("type2", "macro")
	button:SetAttribute("macrotext2", ns.ClearAllMacro())
end
