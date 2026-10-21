-- qnMarkers: options in the Blizzard settings window (Settings API).
-- The settings belong to the active profile (qnCore); after a profile switch
-- qnCore reloads the controls.

local _, ns = ...
local L = ns.L
local S = qnCore.Settings

-- Values from slash commands and the grip are set via ns.store:Set or ns.store:SetValues (qnCore):
-- that way the settings window shows them too.

local function Build(cat, layout)
	local B = S.New({ store = ns.store, prefix = "QNMARKERS_", apply = ns.Apply })

	S.Header(layout, L["Raid Marker Bar"])
	local shown = B:Checkbox(cat, "shown", L["Show bar"])
	local Shown = B:When("shown")
	S.Depends(B:Dropdown(cat, "visibility", HUD_EDIT_MODE_SETTING_DAMAGE_METER_VISIBILITY, {
		{ "always", ALWAYS },
		{ "group", L["In a group"] },
		{ "raid", L["In a raid"] },
	}, L["Also applies in combat."]), shown, Shown)
	S.Depends(B:Checkbox(cat, "leaderOnly", L["Only as leader or assistant"],
		L["Hides the bar unless you are the group leader or a raid assistant. Checked again after combat."]), shown, Shown)
	B:Checkbox(cat, "locked", L["Lock position"], L["Prevents moving the bar by its grip."])
	B:Checkbox(cat, "tooltips", HUD_EDIT_MODE_SETTING_COOLDOWN_VIEWER_SHOW_TOOLTIPS)

	S.Header(layout, L["Buttons"])
	B:Checkbox(cat, "showReady", READY_CHECK)
	B:Checkbox(cat, "showPull5", L["Pull timer: %d seconds"]:format(5))
	B:Checkbox(cat, "showPull10", L["Pull timer: %d seconds"]:format(10))
	B:Checkbox(cat, "showClearWorld", L["Clear world markers"])
	B:Checkbox(cat, "showClearTarget", L["Clear target marker"])
	B:Checkbox(cat, "showLeave", PARTY_LEAVE, L["Asks for confirmation first."])

	S.Header(layout, APPEARANCE_LABEL)
	B:Dropdown(cat, "orientation", HUD_EDIT_MODE_SETTING_ACTION_BAR_ORIENTATION, {
		{ "horizontal", HUD_EDIT_MODE_SETTING_ACTION_BAR_ORIENTATION_HORIZONTAL },
		{ "vertical", HUD_EDIT_MODE_SETTING_ACTION_BAR_ORIENTATION_VERTICAL },
	})
	local floating = B:Checkbox(cat, "floating", L["Floating"], L["Without background and border: only the buttons are visible."])
	B:Slider(cat, "scale", L["Scale"], 0.5, 2, 0.05, S.FractionFormatter)
	B:Slider(cat, "size", HUD_EDIT_MODE_SETTING_ACTION_BAR_ICON_SIZE, 20, 42, 1)
	B:Slider(cat, "gap", L["Button spacing"], 0, 8, 1)
	local NotFloating = B:When("floating", false)
	S.Depends(B:Color(cat, "borderColor", EMBLEM_BORDER_COLOR), floating, NotFloating)
	local color, alpha = B:Color(cat, "bgColor", COMPACT_UNIT_FRAME_PROFILE_HEALTH_BAR_COLOR_BG, nil, nil, L["Background opacity"])
	S.Depends(color, floating, NotFloating)
	S.Depends(alpha, floating, NotFloating)

	S.Header(layout, L["Position"])
	B:KeepVisible(cat, layout, { bar = true, move = function() ns.MoveIntoVisible() end, slash = "/qnmarkers visible" })
	S.Button(layout, L["Reset position"], RESET, function() ns.ResetPosition() end)
end

-- sets ns.category and ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnMarkers", Build)
end
