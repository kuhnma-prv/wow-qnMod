-- qnMarkers: options in the Blizzard settings window (Settings API).
-- The settings belong to the active profile (qnCore); after a profile switch
-- qnCore reloads the controls.

local _, ns = ...
local L = ns.L
local S = qnCore.Settings

-- Values from slash commands and the grip are set via ns.store:Set or ns.store:SetValues (qnCore):
-- that way the settings window shows them too.

local function BuildBar(cat, layout)
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

	S.Header(layout, L["Blizzard's raid manager"])
	B:Checkbox(cat, "hideRaidManager", L["Hide raid manager"],
		L["Makes Blizzard's raid manager at the left edge of the screen (panel and its tab) transparent and click-through. The raid frames themselves stay. Applied out of combat; switching it off restores the manager."])
end

---------------------------------------------------------------------------
-- Nameplate markers (Plates.lua)
---------------------------------------------------------------------------

qnCore.Popup.EditText("QNMARKERS_TEXTURE", L["Texture file or atlas name, e.g. Interface\\Icons\\INV_Misc_QuestionMark:"],
	function() return ns.db.plates.customTexture end,
	function(text)
		ns.PlatesBuilder:Set("customTexture", strtrim(text))
		ns.PlatesBuilder:Set("texture", "custom")
	end, 300)

local function TextureEntries()
	local list = {}
	for _, t in ipairs(ns.TEXTURES) do
		list[#list + 1] = { t[1], t[2] }
	end
	return list
end

local function BuildPlates(category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Nameplate Markers"])
	local P = S.New({ store = ns.store, prefix = "QNMARKERS_PLATES_", apply = ns.ApplyPlates,
		source = function() return ns.db.plates end, defaults = ns.defaults.plates })
	ns.PlatesBuilder = P

	local enabled = P:Checkbox(cat, "enabled", L["Show markers above nameplates"],
		L["An icon above the nameplate of the units chosen below. Nameplates must be switched on in the game."])
	local On = P:When("enabled")
	local function Sub(init)
		return S.Depends(init, enabled, On)
	end

	S.Header(layout, FILTERS)
	Sub(P:Checkbox(cat, "allies", UNIT_NAME_FRIENDLY))
	Sub(P:Checkbox(cat, "group", L["Group members"]))
	Sub(P:Checkbox(cat, "enemies", UNIT_NAME_ENEMY, L["Values of enemies can be hidden by the game in combat; then they get no marker."]))
	Sub(P:Checkbox(cat, "pvp", L["Players flagged for PvP"]))
	Sub(P:Checkbox(cat, "npcs", L["NPCs"]))
	Sub(P:Checkbox(cat, "pets", PETS, L["Pets of other players, smaller, with their portrait."]))
	Sub(P:Checkbox(cat, "ownPet", L["Your pet"], L["Also when the option for pets is off."]))
	Sub(P:Checkbox(cat, "arenaOnly", L["Only in arenas"]))

	S.Header(layout, L["Roles"])
	local roleTip = L["Only group members with an assigned role are filtered; all others are not affected."]
	Sub(P:Checkbox(cat, "tank", L["Tanks"], roleTip))
	Sub(P:Checkbox(cat, "healer", L["Healers"], roleTip))
	Sub(P:Checkbox(cat, "dps", L["Damage dealers"], roleTip))

	S.Header(layout, L["Special icons"])
	Sub(P:Checkbox(cat, "friends", FRIENDS, L["A heart for your friends (friend list and Battle.net)."]))
	Sub(P:Checkbox(cat, "guild", GUILD, L["A shield for members of your guild."]))

	S.Header(layout, APPEARANCE_LABEL)
	Sub(P:Checkbox(cat, "classColors", CLASS_COLORS, L["Role and texture icons in the class color of the unit."]))
	Sub(P:Checkbox(cat, "desaturate", L["Desaturate icons"], L["Role and texture icons in gray before coloring them."]))
	Sub(P:Checkbox(cat, "enemyRed", L["Enemies in red"], L["Role and texture icons of enemies in red."]))
	Sub(P:Checkbox(cat, "distanceFade", L["Fade with the nameplate"], L["The marker becomes as transparent as its nameplate (distance, not targeted)."]))
	local glow = Sub(P:Checkbox(cat, "targetGlow", L["Glow on the target"], L["A glow around the marker of your current target."]))
	S.Depends(P:Color(cat, "glowColor", COLOR), glow, P:When("targetGlow"))
	Sub(P:Dropdown(cat, "texture", L["Texture"], TextureEntries, L["Icon of the icon type \"Texture\"."]))
	Sub(S.Button(layout, L["Custom texture"], L["Edit …"], function() StaticPopup_Show("QNMARKERS_TEXTURE") end,
		L["Sets the file or atlas of the texture \"Custom texture\"."]))
	Sub(P:Slider(cat, "rotation", L["Rotation"], 0, 360, 15, function(v) return ("%d°"):format(v) end))
	Sub(P:Slider(cat, "petScale", L["Size of pets"], 0.25, 1, 0.05, S.FractionFormatter))
end

local ICON_ENTRIES = {
	{ "class", CLASS },
	{ "role", ROLE },
	{ "texture", L["Texture"] },
}

-- Page of the friendly or enemy markers; usable while the markers are switched on
local function BuildSide(category, title, key)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, title)
	local B = S.New({ store = ns.store, prefix = "QNMARKERS_" .. key:upper() .. "_", apply = ns.ApplyPlates,
		source = function() return ns.db.plates[key] end, defaults = ns.defaults.plates[key] })
	local function On()
		return ns.db.plates.enabled
	end
	local function Sub(init)
		init:AddModifyPredicate(On)
		return init
	end

	S.Header(layout, L["Icon"])
	Sub(B:Dropdown(cat, "icon", L["Icon type"], ICON_ENTRIES,
		L["Class: class icon of players. Role: role of group members. Texture: the texture chosen on the page \"Nameplate Markers\"."]))
	local fallback = { { "none", NONE } }
	for _, e in ipairs(ICON_ENTRIES) do
		fallback[#fallback + 1] = e
	end
	Sub(B:Dropdown(cat, "fallback", L["Otherwise"], fallback, L["Icon type when the first one is not available (e.g. no role or not a player)."]))

	S.Header(layout, L["Size and position"])
	Sub(B:Slider(cat, "size", HUD_EDIT_MODE_SETTING_ACTION_BAR_ICON_SIZE, 16, 100, 2))
	Sub(B:Slider(cat, "offsetX", L["Horizontal offset"], -100, 100, 1))
	Sub(B:Slider(cat, "offsetY", L["Vertical offset"], -100, 100, 1))

	S.Header(layout, L["Frame"])
	Sub(B:Dropdown(cat, "shape", L["Shape"], { { "square", L["Square"] }, { "circle", L["Round"] } }))
	local bg = Sub(B:Checkbox(cat, "background", BACKGROUND))
	S.Depends(Sub(B:Slider(cat, "padding", L["Padding"], 0, 10, 1)), bg, B:When("background"))
	Sub(B:Checkbox(cat, "border", L["Border"], L["Border in the class color of players."]))
end

local function Build(category, layout)
	BuildBar(category, layout)
	BuildPlates(category)
	BuildSide(category, L["Friendly Markers"], "friendly")
	BuildSide(category, L["Enemy Markers"], "enemy")
end

-- sets ns.category and ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnMarkers", Build)
end
