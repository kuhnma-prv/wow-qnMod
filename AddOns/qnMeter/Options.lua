-- qnMeter: Optionen im Blizzard-Einstellungsfenster (Settings-API).
-- Die Einstellungen gehören zum aktiven Profil (qnCore); nach einem Profilwechsel
-- liest qnCore die Steuerelemente neu ein.

local _, ns = ...
local L = ns.L
local S = qnCore.Settings

-- Werte aus Menü und Slash-Befehlen setzt ns.store:Set (qnCore): so zeigt auch das
-- Einstellungsfenster sie an.

local function TextureEntries()
	local list = {}
	for _, name in ipairs(ns.GetTextureNames()) do
		list[#list + 1] = { name, ns.textureLabels[name] or name }
	end
	return list
end

local function Build(cat, layout)
	local B = S.New({ store = ns.store, prefix = "QNMETER_", apply = function() ns.Threat.ApplySettings() end })

	S.Header(layout, L["Window"])
	B:Checkbox(cat, "shown", L["Show window"])
	B:Checkbox(cat, "locked", LOCK_FRAME, L["Prevents moving and resizing."])
	B:Dropdown(cat, "showMode", HUD_EDIT_MODE_SETTING_DAMAGE_METER_VISIBILITY, {
		{ 1, ALWAYS },
		{ 2, L["In combat only"] },
		{ 3, L["In group or raid only"] },
	})
	B:Checkbox(cat, "showTitle", L["Show title bar"])
	B:Slider(cat, "scale", L["Scale"], 0.5, 2, 0.05, S.DecimalFormatter)
	B:Checkbox(cat, "autoVisible", L["Keep in visible area automatically"],
		L["Moves the window back onto a monitor after dragging, on login and when the monitor arrangement changes. With qnViewPort and monitor data, only areas actually visible on a monitor count."])
	S.Button(layout, L["Find window"], L["Move into visible area"],
		function() ns.Threat.MoveIntoVisible() end, L["Moves the window onto the nearest visible monitor now (/qnm visible)."])

	S.Header(layout, L["Bars"])
	local link = B:Checkbox(cat, "linkDamageMeter", L["Use Damage Meter settings"],
		L["Takes style, bar height, spacing, text size, icons, class colors and transparency from the Edit Mode settings of the built-in Damage Meter."])
	-- Nur bedienbar, solange die Werte nicht von der Schadensanzeige kommen.
	local function NotLinked()
		return not ns.db.linkDamageMeter
	end
	S.Depends(B:Dropdown(cat, "style", HUD_EDIT_MODE_SETTING_DAMAGE_METER_STYLE, {
		{ 0, HUD_EDIT_MODE_SETTING_DAMAGE_METER_STYLE_DEFAULT },
		{ 1, HUD_EDIT_MODE_SETTING_DAMAGE_METER_STYLE_THIN },
		{ 2, HUD_EDIT_MODE_SETTING_DAMAGE_METER_STYLE_BORDERED },
		{ 3, HUD_EDIT_MODE_SETTING_DAMAGE_METER_STYLE_FULL_BACKGROUND },
	}), link, NotLinked)
	S.Depends(B:Slider(cat, "barHeight", L["Bar height"], 8, 40, 1), link, NotLinked)
	S.Depends(B:Slider(cat, "barSpacing", L["Bar spacing"], 0, 10, 1), link, NotLinked)
	S.Depends(B:Slider(cat, "fontSize", FONT_SIZE, 0, 24, 1, S.FontSizeFormatter, L["0 = default size of the Damage Meter."]), link, NotLinked)
	S.Depends(B:Checkbox(cat, "showIcons", L["Show class icons"]), link, NotLinked)
	S.Depends(B:Checkbox(cat, "classColors", CLASS_COLORS), link, NotLinked)
	S.Depends(B:Slider(cat, "bgAlpha", L["Background opacity"], 0, 1, 0.05, S.FractionFormatter), link, NotLinked)
	B:Dropdown(cat, "texture", L["Bar texture"], TextureEntries)
	B:Checkbox(cat, "showRank", L["Rank before the name"])
	B:Checkbox(cat, "useMyColor", L["Color your own bar red"])
	B:Checkbox(cat, "useTankColor", L["Color the tank bar dark red"])

	S.Header(layout, L["Content"])
	B:Checkbox(cat, "showValue", L["Show threat values"])
	B:Checkbox(cat, "showPercent", L["Show threat %"])
	B:Checkbox(cat, "showTPS", L["Show threat per second (TPS)"],
		L["Threat gained per second over the TPS window. Only possible while the client provides readable values."])
	B:Slider(cat, "tpsWindow", L["TPS window (seconds)"], 3, 30, 1)
	B:Dropdown(cat, "percentMode", L["Percent basis"], {
		{ 1, L["Relative to the tank (100 % = tank)"] },
		{ 2, L["Scaled (100 % = aggro)"] },
	}, L["In restricted mode (secret) only 'scaled' is available."])
	B:Checkbox(cat, "showAggroBar", L["Show pull aggro bar"])
	B:Dropdown(cat, "aggroMode", L["Aggro threshold"], {
		{ 1, L["Automatic (range, otherwise class)"] },
		{ 2, L["Melee (110 %)"] },
		{ 3, L["Ranged (130 %)"] },
	}, L["Automatic: out of combat by range to the target, in combat by class. In combat only warriors, rogues and paladins count as melee; druids in Cat or Bear Form and Enhancement shamans then get 130 %. Choose 'Melee' for them."])
	B:Checkbox(cat, "alwaysShowSelf", L["Always show self"])
	B:Checkbox(cat, "showPets", DISPLAY_RAID_PETS)
	B:Checkbox(cat, "useFocus", L["Use focus target"])
	B:Checkbox(cat, "ignorePlayerPets", L["Ignore player pets"])
	B:Slider(cat, "updateInterval", L["Update interval (seconds)"], 0.05, 1, 0.05, S.DecimalFormatter)

	S.Header(layout, L["Warnings"])
	B:Checkbox(cat, "warnEnabled", L["Warn on high threat"],
		L["Only possible while the client provides readable values."])
	B:Slider(cat, "warnThreshold", L["Warning threshold"], 50, 130, 5, S.PercentFormatter)
	B:Checkbox(cat, "warnSound", L["Play sound"])
	B:Checkbox(cat, "warnFlash", L["Flash the screen"])
	B:Checkbox(cat, "warnMessage", L["Show message"])
	B:Checkbox(cat, "warnSolo", L["Warn when solo too"])
end

-- setzt ns.category und ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnMeter", Build)
end
