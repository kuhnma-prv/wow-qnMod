-- qnSkins: options in the Blizzard settings window (Settings API).
-- The settings belong to the active profile (qnCore); after a profile switch
-- qnCore reloads the controls.

local _, ns = ...
local L = ns.L
local S = qnCore.Settings

local function MonitorEntries()
	local list = { { 0, L["Automatic (monitor with the 3D view)"] } }
	for i in ipairs(ns.Layout.Monitors()) do
		list[#list + 1] = { i, L["Monitor %d"]:format(i) }
	end
	return list
end

local function Build(cat, layout)
	local B = S.New({ store = ns.store, prefix = "QNSKINS_", apply = function() ns.Refresh() end })

	S.Header(layout, L["Skin"])
	B:Dropdown(cat, "skin", L["Skin"], ns.SkinEntries,
		L["Artwork around the action bars, status bars and micro menu. It lies below the elements, so bars shown later (pet bar, vehicle button) cover it."])
	local position = B:Checkbox(cat, "position", L["Position elements"],
		L["Moves and scales the elements to the skin's positions and keeps them there, also after the Edit Mode. Without this option the artwork follows the elements wherever they are. Switching it off keeps the current positions until /reload."],
		function(_, value)
			if not value then
				ns.Print(L["The elements keep their positions until /reload."])
			end
			ns.Refresh()
		end)
	-- only used while the elements are positioned
	local function Positioned()
		return ns.db.position
	end
	S.Depends(B:Dropdown(cat, "monitor", PRIMARY_MONITOR, MonitorEntries,
		L["Monitor the skin is placed on. Automatic: the monitor with the 3D view (qnViewPort), otherwise the largest."]), position, Positioned)
	S.Depends(B:Slider(cat, "offsetX", L["Horizontal offset"], -800, 800, 5), position, Positioned)
	S.Depends(B:Slider(cat, "offsetY", L["Vertical offset"], -400, 400, 5), position, Positioned)
	B:Slider(cat, "scale", L["Scale"], 0.5, 2, 0.05, S.DecimalFormatter,
		L["Scale of the artwork and - with 'Position elements' - of the elements."])
	B:Checkbox(cat, "pauseInCombat", L["Pause figures in combat"],
		L["The 3D figures of the skin stand still while you are in combat."],
		function() ns.Art.UpdatePaused() end)
	S.Button(layout, L["Apply again"], L["Apply"], function() ns.Layout.Refresh() end,
		L["Places the elements and the artwork again now (/qnskins apply)."])
end

-- Page "Figures": zoom, sideways, height, rotation, animation and area of every 3D figure of every skin.
-- The values act at once (no reload) and are stored per profile.
local function FiguresPage(B, category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Figures"])
	for _, entry in ipairs(ns.SkinEntries()) do
		local skin = ns.skins[entry[1]]
		for _, spec in ipairs(skin and skin.art or {}) do
			if spec.kind == "model" then
				local function Key(prop)
					return ns.FigureKey(entry[1], spec.key, prop)
				end
				S.Header(layout, ("%s – %s"):format(skin.name, spec.name or spec.key))   -- do not translate: two names
				B:Slider(cat, Key("zoom"), L["Zoom"], 0.2, 4, 0.05, S.DecimalFormatter,
					L["Distance of the camera: larger values show the figure smaller."])
				B:Slider(cat, Key("side"), L["Sideways"], -10, 10, 0.1, S.DecimalFormatter)
				B:Slider(cat, Key("height"), L["Height"], -10, 10, 0.1, S.DecimalFormatter,
					L["Moves the figure up or down within its area. Parts outside the area are cut off."])
				B:Slider(cat, Key("rotation"), L["Rotation"], -3.15, 3.15, 0.05, S.DecimalFormatter)
				B:Slider(cat, Key("animation"), ANIMATION, 0, 250, 1, nil,
					L["Number of the animation (0 = standing). Which number lets a figure lie or sleep depends on the model - try it out."])
				B:Slider(cat, Key("areaBottom"), L["Area below"], -100, 400, 5, nil,
					L["Extends the area of the figure downwards (UI units). The figure is cut off at its area; a larger area usually shows it larger - correct with Zoom."])
				B:Slider(cat, Key("areaTop"), L["Area above"], -100, 400, 5, nil,
					L["Extends the area of the figure upwards (UI units). The figure is cut off at its area; a larger area usually shows it larger - correct with Zoom."])
			end
		end
	end
end

-- sets ns.category and ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnSkins", function(cat, layout)
		Build(cat, layout)
		FiguresPage(S.New({ store = ns.store, prefix = "QNSKINS_", apply = function() ns.Refresh() end }), cat)
	end)
end
