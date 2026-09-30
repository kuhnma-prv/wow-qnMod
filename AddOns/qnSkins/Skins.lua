-- qnSkins: skin definitions.
--
-- Elements (ns.targets): key -> global name of the frame. Skins may also use any global
-- frame name directly (frames of other addons); missing frames are skipped.
--
-- A skin:
--   frames  positions of the elements, in this order (later ones may refer to earlier ones):
--           { key, point, rel, relPoint, x, y, scale }   scale = false: keep the element's own scale
--           rel = "screen" (the chosen monitor) or the key of an element; x/y in UI units.
--           Only applied with the option "Position elements" (opt-in).
--   art     artwork, drawn in this order:
--           { key, kind = "panel", around = { element keys }, pad = { l, r, t, b }, bg, bgColor, edge, edgeColor, ... }
--               a panel around the elements (their bounding box plus pad)
--           { key, kind = "band", bg, bgColor, tileSize, lineColor, rope, ropeThickness, grade, corner,
--             inner = { gap, grade }, upper = { group, reachLeft, reachRight },
--             base = { rel = { element keys }, pad, drop, left = { element keys }, leftPad },
--             raise = { { key, around, pad, rise, edge }, ... } }
--               background over the full width of the monitor below a line: lowest at the top of
--               base.rel plus pad, at the left edge drop higher (and clear of base.left), raised with
--               the gradient grade around every group (bounding box plus pad, at least rise above the
--               base; edge = "left"/"right": continues to that edge of the monitor); straight lines with
--               round bends of radius corner; inner = second line gap below at the sides with a
--               steeper gradient, running into the main line on the raised parts; upper = the upper
--               line only around one raised part, reaching straight to the lower lines; see Art.lua
--           { key, kind = "model", name, creature | display, animation, rotation, zoom, position = { x, y, z },
--             creature/display may be a table by faction: { Alliance = id, Horde = id },
--             point, rel, relPoint, x, y, w, h  or  from = { rel, point, x, y }, to = { rel, point, x, y } }
--               a 3D figure; rel = key of an element or of earlier artwork
--           { key, kind = "texture", file | atlas, point, rel, relPoint, x, y, w, h }
--   Artwork is drawn in the BACKGROUND strata: below the action bars (MEDIUM) and the
--   status bars (LOW), so elements shown later (pet bar, vehicle button) lie on top of it.

local _, ns = ...
local L = ns.L

-- Blizzard elements (Blizzard_ActionBar, Blizzard_MicroMenu, Blizzard_StatusTrackingBar)
ns.targets = {
	bar1 = "MainActionBar",
	bar2 = "MultiBarBottomLeft",
	bar3 = "MultiBarBottomRight",
	bar4 = "MultiBarRight",
	bar5 = "MultiBarLeft",
	bar6 = "MultiBar5",
	bar7 = "MultiBar6",
	bar8 = "MultiBar7",
	pet = "PetActionBar",
	stance = "StanceBar",
	menu = "MicroMenuContainer",
	vehicle = "MainMenuBarVehicleLeaveButton",
	status1 = "MainStatusTrackingBarContainer",
	status2 = "SecondaryStatusTrackingBarContainer",
	possess = "PossessActionBar",           -- Edit Mode "Possess Bar", only shown while possessing
	extra = "ExtraAbilityContainer",        -- Edit Mode "Extra Abilities" (Blizzard_UIPanels_Game)
	-- other addons
	threat = "qnThreatMeterFrame",
	numpad = "qnNumKeyPadBar",
	zonemap = "BattlefieldMapFrame",        -- Blizzard_BattlefieldMap (load on demand)
}

-- Blizzard textures (file paths from Blizzard's source)
local ROCK = "Interface\\FrameGeneral\\UI-Background-Rock"
local MARBLE = "Interface\\FrameGeneral\\UI-Background-Marble"
local BOX_BG = "Interface\\Tooltips\\UI-Tooltip-Background"
local BOX_EDGE = "Interface\\Tooltips\\UI-Tooltip-Border"
-- own texture (tools\New-QnSkinArt.ps1): red and gold cord
local ROPE = "Interface\\AddOns\\qnSkins\\Media\\Rope"

-- Arrangement at the bottom of the monitor (screenshot of the user):
--   pet bar and vehicle button on top, below them action bars 1 and 2, then the micro menu
--   and right of it the row arranged by the user, below everything status bars 2 and 1.
--   Action bars 4 and 5 (right bars) are left alone: Blizzard places bar 5 by the width of
--   bar 4, so moving bar 4 would drag bar 5 along.
local BOTTOM_CLUSTER = {
	{ "status1", "BOTTOM", "screen", "BOTTOM", 0, 2 },
	{ "status2", "BOTTOMLEFT", "status1", "TOPLEFT", 0, 0 },
	{ "menu", "BOTTOMLEFT", "status2", "TOPLEFT", 0, 2 },
	{ "bar2", "BOTTOMLEFT", "menu", "TOPRIGHT", 4, 2 },
	{ "bar1", "BOTTOMLEFT", "bar2", "TOPLEFT", 0, 2 },
	{ "pet", "BOTTOMRIGHT", "bar1", "TOPRIGHT", 0, 4 },
	{ "vehicle", "BOTTOMLEFT", "bar1", "TOPLEFT", 0, 4 },
	-- qnThreatMeter left of qnNumKeyPad with a gap for both boxes; keeps its own scale
	{ "threat", "BOTTOMRIGHT", "numpad", "BOTTOMLEFT", -14, 0, false },
}

-- Panel around the cluster; the space above action bar 1 (pad.t) is for the pet bar and
-- the vehicle button, which are not always shown.
local CLUSTER = { "status1", "status2", "menu", "bar2", "bar1" }

-- All elements at the bottom of the monitor: the line of the band runs just above them
local BOTTOM = { "zonemap", "possess", "extra", "status1", "status2", "menu", "bar1", "bar2", "pet", "vehicle",
	"threat", "numpad" }

ns.skins = {
	dragonlair = {
		name = L["Dragon's Lair"],
		order = 1,
		frames = BOTTOM_CLUSTER,
		art = {
			-- dark band over the full width of the monitor below a straight horizontal line (a red and
			-- gold cord) just above all elements at the bottom (also the hidden ones)
			{ key = "band", kind = "band", bg = ROCK, bgColor = { 0.16, 0.15, 0.14, 0.97 }, tileSize = 256,
				lineColor = { 1, 0.45, 0.12 }, rope = ROPE, ropeThickness = 4,
				base = { rel = BOTTOM, pad = 4 } },			-- boxes with a thin border inside the band
			{ key = "boxBars", kind = "panel", around = CLUSTER, pad = { 6, 6, 6, 4 }, bg = BOX_BG, edge = BOX_EDGE,
				edgeSize = 12, inset = 3, bgColor = { 0, 0, 0, 0.35 }, edgeColor = { 0.55, 0.5, 0.45, 1 } },
			{ key = "boxThreat", kind = "panel", around = { "threat" }, pad = { 4, 4, 4, 4 }, bg = BOX_BG, edge = BOX_EDGE,
				edgeSize = 12, inset = 3, bgColor = { 0, 0, 0, 0.35 }, edgeColor = { 0.55, 0.5, 0.45, 1 } },
			{ key = "boxNumpad", kind = "panel", around = { "numpad" }, pad = { 4, 4, 4, 4 }, bg = BOX_BG, edge = BOX_EDGE,
				edgeSize = 12, inset = 3, bgColor = { 0, 0, 0, 0.35 }, edgeColor = { 0.55, 0.5, 0.45, 1 } },
			-- standing warrior at the right end of the status bars, which (LOW) cover the legs; a city guard
			-- of the player's faction: 68 = Stormwind City Guard, 3296 = Orgrimmar Grunt (Wowhead Classic)
			{ key = "warrior", kind = "model", name = L["Warrior"], creature = { Alliance = 68, Horde = 3296 }, animation = 0, rotation = -0.4, zoom = 1,
				point = "BOTTOM", rel = "status1", relPoint = "BOTTOMRIGHT", x = 10, y = -40, w = 100, h = 240 },
		},
	},
	stoneframe = {
		name = L["Stone Frame"],
		order = 2,
		frames = BOTTOM_CLUSTER,
		art = {
			{ key = "backdrop", kind = "panel", around = CLUSTER, pad = { 14, 14, 48, 8 },
				bg = MARBLE, bgColor = { 1, 1, 1, 0.95 } },
		},
	},
}

---------------------------------------------------------------------------
-- Figure settings (options page "Figures", per profile): zoom, sideways, height, rotation,
-- animation and the extension of the area (areaBottom/areaTop, UI units) of every 3D figure;
-- key "fig_<skin>_<art>_<prop>", defaults from the skin.
---------------------------------------------------------------------------

function ns.FigureKey(skinKey, artKey, prop)
	return ("fig_%s_%s_%s"):format(skinKey, artKey, prop)
end

for skinKey, skin in pairs(ns.skins) do
	for _, spec in ipairs(skin.art) do
		if spec.kind == "model" then
			local p = spec.position or {}
			ns.defaults[ns.FigureKey(skinKey, spec.key, "zoom")] = spec.zoom or 1
			ns.defaults[ns.FigureKey(skinKey, spec.key, "side")] = p[2] or 0
			ns.defaults[ns.FigureKey(skinKey, spec.key, "height")] = p[3] or 0
			ns.defaults[ns.FigureKey(skinKey, spec.key, "rotation")] = spec.rotation or 0
			ns.defaults[ns.FigureKey(skinKey, spec.key, "animation")] = spec.animation or 0
			ns.defaults[ns.FigureKey(skinKey, spec.key, "areaBottom")] = 0
			ns.defaults[ns.FigureKey(skinKey, spec.key, "areaTop")] = 0
		end
	end
end
