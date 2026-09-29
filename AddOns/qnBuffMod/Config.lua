-- qnBuffMod: Optionen im Blizzard-Einstellungsfenster (Settings-API über qnCore).
-- Hauptseite "qnBuffMod" (allgemein, Profil) und vier Fensterseiten, die alle das in
-- QNBUFFMOD_EDITWINDOW gewählte Fenster zeigen (Quelle der Einstellungen: ns.SelectedSettings).

local _, ns = ...
local L = ns.L
local E = ns.enum
local S = qnCore.Settings

local windowBuilders = {}
local windowCategories = {}
local editSetting
local windowPage

-- Farblegende der Schwächungszauberarten (Tooltip)
local LEGEND = L["Colors: |cFF9600FFcurse|r, |cFF966400disease|r, |cFF3296FFmagic|r, |cFF009600poison|r, |cFFc80000others (e.g. physical)|r."]

---------------------------------------------------------------------------
-- Popups
---------------------------------------------------------------------------

qnCore.Popup.Confirm("QNBUFFMOD_DELETE_WINDOW", L["Delete %s? Its settings will be lost."], DELETE, function()
	ns.DeleteWindow(ns.SelectedID())
end)

qnCore.Popup.EditText("QNBUFFMOD_CONDITION", L["Visibility condition for %s (macro syntax, actions: show, hide):"],
	function()
		return ns.WindowValue(ns.SelectedSettings(), "visCondition")
	end,
	function(text)
		ns.store:Set("visCondition", text)
	end, 1000)

---------------------------------------------------------------------------
-- Fensterseiten: offen? neu einlesen?
---------------------------------------------------------------------------

-- Wird gerade eine Fensterseite im geöffneten Einstellungsfenster angezeigt?
function ns.WindowPageOpen()
	if not (SettingsPanel and SettingsPanel:IsShown()) then
		return false
	end
	local current = SettingsPanel:GetCurrentCategory()
	return current ~= nil and windowCategories[current] == true
end

local function PagesChanged()
	for _, win in pairs(ns.windows) do
		win:ApplyMouse()
	end
end

-- Alle Fensterseiten aus dem gewählten Fenster neu einlesen (ohne Rückrufe)
function ns.RefreshWindowPages(fromSetting)
	for _, b in ipairs(windowBuilders) do
		b:Refresh()
	end
	if editSetting and not fromSetting then
		editSetting:NotifyUpdate()
	end
end

function ns.OpenWindowPage()
	if windowPage then
		qnCore.OpenCategory(windowPage)
	end
end

local function WindowEntries()
	local list = {}
	for _, id in ipairs(ns.WindowIDs()) do
		list[#list + 1] = { id, L["Window %d"]:format(id) }
	end
	if #list == 0 then
		list[1] = { 1, L["Window %d"]:format(1) }
	end
	return list
end

---------------------------------------------------------------------------
-- Bausteine der Fensterseiten
---------------------------------------------------------------------------

-- Wert des gewählten Fensters (für Abhängigkeiten)
local function Value(key)
	return ns.WindowValue(ns.SelectedSettings(), key)
end

local function Is(key, v)
	return function()
		return Value(key) == v
	end
end

local function On(key)
	return function(_, value)
		ns.ApplyWindowSetting(key, value)
	end
end

-- Baukasten einer Fensterseite mit den Kurzformen Check/Slide/Choose/Color
local function WindowBuilder(prefix)
	local B = S.New({ store = ns.store, prefix = prefix, source = ns.SelectedSettings, defaults = ns.windowDefaults })
	windowBuilders[#windowBuilders + 1] = B
	function B:Check(cat, key, name, tooltip)
		return self:Checkbox(cat, key, name, tooltip, On(key))
	end
	function B:Slide(cat, key, name, minV, maxV, formatter, tooltip)
		return self:Slider(cat, key, name, minV, maxV, 1, formatter, tooltip, On(key))
	end
	function B:Choose(cat, key, name, entries, tooltip, callback)
		return self:Dropdown(cat, key, name, entries, tooltip, nil, callback or On(key))
	end
	return B
end

-- Kopf jeder Fensterseite: Auswahl des Fensters (eine Einstellung für alle Seiten)
local function WindowHead(cat, layout)
	windowCategories[cat] = true
	S.Header(layout, L["Window"])
	if not editSetting then
		editSetting = Settings.RegisterProxySetting(cat, "QNBUFFMOD_EDITWINDOW", Settings.VarType.Number, L["Edit window"], 1,
			function()
				return ns.SelectedID()
			end,
			function(value)
				ns.SelectWindow(value, true)
			end)
	end
	S.Dropdown(cat, editSetting, WindowEntries,
		L["The settings on this page only affect the selected window. Alt-clicking a window selects it as well."])
end

local function Window()
	return ns.GetWindow(ns.SelectedID())
end

---------------------------------------------------------------------------
-- Auswahllisten
---------------------------------------------------------------------------

local JUSTIFY = {
	{ E.justify.DEFAULT, DEFAULT },
	{ E.justify.LEFT, HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_LEFT },
	{ E.justify.RIGHT, HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_RIGHT },
	{ E.justify.CENTER, L["Center"] },
}

local GROUPS = {
	{ E.group.NONE, NONE_KEY },
	{ E.group.DEBUFF, L["Debuffs"] },
	{ E.group.CANCELABLE, L["Cancelable buffs"] },
	{ E.group.UNCANCELABLE, L["Uncancelable buffs"] },
	{ E.group.ALLBUFFS, L["All buffs"] },
	{ E.group.WEAPONS, L["Weapon enchants"] },
}

local function WrapsLabel(v)
	if v == 0 then
		return L["auto"]
	end
	return ("%d"):format(v)
end

---------------------------------------------------------------------------
-- Seiten
---------------------------------------------------------------------------

local function BuildGeneral(category, layout)
	local G = S.New({ store = ns.store, prefix = "QNBUFFMOD_", apply = ns.ApplyGeneral })
	local cat = category

	S.Header(layout, L["Blizzard Frames"])
	G:Checkbox(cat, "hideBlizzardBuffs", L["Hide Blizzard's buff frames"],
		L["Hides Blizzard's frames for buffs and debuffs."])

	S.Header(layout, COLORS)
	G:Color(cat, "backgroundColor", L["Window background"], L["Background of all windows without a color of their own."], nil, L["Window background: opacity"])
	G:Color(cat, "bgColorBUFF", CONTEXT_ACTION_LABEL_BUFFS, nil, nil, L["Buffs: opacity"])
	G:Color(cat, "bgColorAURA", AURAS, nil, nil, L["Auras: opacity"])
	G:Color(cat, "bgColorDEBUFF", L["Debuffs"], nil, nil, L["Debuffs: opacity"])
	G:Color(cat, "bgColorITEM", L["Weapon enchants"], nil, nil, L["Weapon enchants: opacity"])

	S.Header(layout, PROFESSIONS_COLUMN_HEADER_EXPIRATION)
	G:Slider(cat, "flashTime", L["Flash icon before expiry"], 0, 60, 1, ns.SecondsLabel)
	local warn = G:Checkbox(cat, "enableExpiration", L["Warn in chat"], L["Reports in chat that a buff is about to expire."])
	local function Warn()
		return ns.db.enableExpiration
	end
	S.Depends(G:Checkbox(cat, "expirationCastOnly", L["Only buffs you can cast"]), warn, Warn)
	S.Depends(G:Checkbox(cat, "expirationSound", L["Play sound"]), warn, Warn)
	S.Depends(G:Slider(cat, "expirationTime1", L["Warn for duration 2:00 – 10:00"], 0, 60, 5, ns.SecondsLabel), warn, Warn)
	S.Depends(G:Slider(cat, "expirationTime2", L["Warn for duration 10:01 – 30:00"], 0, 180, 5, ns.SecondsLabel), warn, Warn)
	S.Depends(G:Slider(cat, "expirationTime3", L["Warn for duration from 30:01"], 0, 300, 5, ns.SecondsLabel), warn, Warn)
end

local function BuildWindowPage(category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Window"])
	windowPage = cat
	WindowHead(cat, layout)
	local W = WindowBuilder("QNBUFFMOD_W_")

	S.Button(layout, COMMUNITIES_ADD_TO_CHAT_DROP_DOWN_NEW_CHAT_WINDOW, ADD, function()
		ns.AddWindow()
	end, L["New window with default settings."])
	S.Button(layout, L["Copy window"], L["Clone"], function()
		ns.AddWindow(ns.SelectedID())
	end, L["New window with the settings of the selected window."])
	S.Button(layout, L["Delete window"], L["Delete …"], function()
		StaticPopup_Show("QNBUFFMOD_DELETE_WINDOW", L["Window %d"]:format(ns.SelectedID()))
	end, L["Deletes the selected window together with its settings."])
	S.Button(layout, L["Reset position"], RESET, function()
		local win = Window()
		if win then
			win:ResetPosition()
		end
	end, L["Moves the window to the center of the screen."])
	S.Button(layout, L["Find window"], L["Move into visible area"], function()
		local win = Window()
		if win then
			win:BringIntoView()
		end
	end, L["Moves the window only as far as needed to be completely inside the visible area. The rest of its position is kept."])

	S.Header(layout, GENERAL)
	W:Check(cat, "disableWindow", L["Disable window"])
	W:Check(cat, "disableTooltips", L["Disable icon tooltips"])
	W:Check(cat, "lockWindow", LOCK_FRAME, L["Prevents moving the window."])
	W:Check(cat, "clampWindow", L["Keep on screen"])

	S.Header(layout, GROUPMANAGER_UNIT_MARKER)
	local unit = W:Choose(cat, "unitType", L["Show buffs for"], {
		{ E.unit.PLAYER, PLAYER },
		{ E.unit.VEHICLE, L["Vehicle"] },
		{ E.unit.PET, PET },
		{ E.unit.TARGET, TARGET },
		{ E.unit.FOCUS, FOCUS },
	}, L["Right-clicking one of your own buffs cancels it – only out of combat."])
	S.Depends(W:Check(cat, "vehicleBuffs", L["Show vehicle buffs when in a vehicle"]), unit, Is("unitType", E.unit.PLAYER))

	S.Header(layout, HUD_EDIT_MODE_SETTING_AURA_FRAME_VISIBLE_SETTING)
	local vis = W:Choose(cat, "visWindow", SHOW, {
		{ E.vis.ALWAYS, BATTLEFIELD_MINIMAP_SHOW_ALWAYS },
		{ E.vis.BASIC, L["Basic conditions"] },
		{ E.vis.CUSTOM, L["Custom condition"] },
	})
	local basic = Is("visWindow", E.vis.BASIC)
	S.Depends(W:Check(cat, "visHideInCombat", L["Hide in combat"]), vis, basic)
	S.Depends(W:Check(cat, "visHideNotCombat", L["Hide out of combat"]), vis, basic)
	S.Depends(W:Check(cat, "visHideInVehicle", L["Hide in vehicle"]), vis, basic)
	S.Depends(W:Check(cat, "visHideNotVehicle", L["Hide out of vehicle"]), vis, basic)
	-- der Text selbst hat kein eigenes Steuerelement (Dialog)
	W:Register(cat, "visCondition", L["Custom condition"], nil, On("visCondition"))
	local custom = Is("visWindow", E.vis.CUSTOM)
	S.Depends(S.Button(layout, L["Custom condition"], L["Edit …"], function()
		StaticPopup_Show("QNBUFFMOD_CONDITION", L["Window %d"]:format(ns.SelectedID()))
	end, L["Macro condition with show/hide, e.g. '[vehicleui] hide; [combat] hide; show'."]), vis, custom)
	S.Depends(S.Button(layout, L["Test condition"], L["Test"], function()
		ns.TestCondition(ns.SelectedID())
	end, L["Shows in chat what the saved condition currently does."]), vis, custom)
end

local function BuildLayoutPage(category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, APPEARANCE_LABEL)
	WindowHead(cat, layout)
	local W = WindowBuilder("QNBUFFMOD_L_")

	S.Header(layout, BACKGROUND)
	W:Check(cat, "showBackground", HUD_EDIT_MODE_SETTING_UNIT_FRAME_SHOW_PARTY_FRAME_BACKGROUND)
	local own = W:Check(cat, "useCustomBackgroundColor", L["Custom color for this window"])
	local color, alpha = W:Color(cat, "windowBackgroundColor", COMPACT_UNIT_FRAME_PROFILE_HEALTH_BAR_COLOR_BG, nil,
		On("windowBackgroundColor"), L["Background opacity"])
	S.Depends(color, own, Is("useCustomBackgroundColor", true))
	S.Depends(alpha, own, Is("useCustomBackgroundColor", true))

	S.Header(layout, L["Border"])
	W:Check(cat, "showBorder", HUD_EDIT_MODE_SETTING_UNIT_FRAME_DISPLAY_BORDER)
	W:Slide(cat, "userEdgeLeft", L["Left border"], 0, 100)
	W:Slide(cat, "userEdgeRight", L["Right border"], 0, 100)
	W:Slide(cat, "userEdgeTop", L["Top border"], 0, 100)
	W:Slide(cat, "userEdgeBottom", L["Bottom border"], 0, 100)

	S.Header(layout, L["Layout"])
	W:Choose(cat, "layoutType", HUD_EDIT_MODE_SETTING_BAGS_DIRECTION, {
		{ 1, L["Top to bottom, wrap right"] },
		{ 2, L["Top to bottom, wrap left"] },
		{ 3, L["Bottom to top, wrap right"] },
		{ 4, L["Bottom to top, wrap left"] },
		{ 5, L["Left to right, wrap down"] },
		{ 6, L["Left to right, wrap up"] },
		{ 7, L["Right to left, wrap down"] },
		{ 8, L["Right to left, wrap up"] },
	}, L["Top/bottom: buffs in columns; left/right: buffs in rows. Default: a single column that auto-expands downward (left to right, wrap down, 1 buff per row, rows automatic)."])
	W:Slide(cat, "wrapAfter", L["Buffs per row or column"], 1, 50)
	W:Slide(cat, "maxWraps", L["Number of rows or columns"], 0, 50, WrapsLabel, L["0 = auto-expand."])
	W:Slide(cat, "buffSpacing", L["Buff spacing"], 0, 200)
	W:Slide(cat, "wrapSpacing", L["Row or column spacing"], 0, 200)

	S.Header(layout, L["Font"])
	W:Choose(cat, "fontSize", FONT_SIZE, {
		{ E.font.NORMAL, VOICE_CHAT_NORMAL },
		{ E.font.SMALL, L["Smaller"] },
		{ E.font.LARGE, L["Larger"] },
	})
end

local function BuildButtonsPage(category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Buttons"])
	WindowHead(cat, layout)
	local W = WindowBuilder("QNBUFFMOD_B_")

	S.Header(layout, L["Buttons"])
	local style = W:Choose(cat, "buttonStyle", HUD_EDIT_MODE_SETTING_DAMAGE_METER_STYLE, {
		{ E.style.BAR, L["Style 1 (icon and bar)"] },
		{ E.style.ICON, L["Style 2 (icon only)"] },
	})
	local one, two = Is("buttonStyle", E.style.BAR), Is("buttonStyle", E.style.ICON)
	local function Dep(init, pred)
		return S.Depends(init, style, pred)
	end

	S.Header(layout, L["Style 1 (icon and bar)"])
	Dep(W:Slide(cat, "buffSize1", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_SIZE, 15, 45), one)
	Dep(W:Choose(cat, "rightAlign1", L["Icon position"], {
		{ E.side.DEFAULT, DEFAULT },
		{ E.side.LEFT, HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_LEFT },
		{ E.side.RIGHT, HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_RIGHT },
	}), one)
	Dep(W:Check(cat, "colorCodeIcons1", L["Color code the border of debuff icons"], LEGEND), one)
	Dep(W:Check(cat, "normalIconBorder1", L["Default icon border"], L["Shows the whole icon including its own border instead of trimming its edges."]), one)
	Dep(W:Slide(cat, "detailWidth1", L["Bar width"], 0, 400), one)
	Dep(W:Check(cat, "colorBuffs1", L["Color the bar background"]), one)
	Dep(W:Check(cat, "colorCodeBackground1", L["Color code debuff bars"], LEGEND), one)
	Dep(W:Check(cat, "showNames1", PROFESSIONS_FLYOUT_SHOW_NAME), one)
	Dep(W:Check(cat, "colorCodeDebuffs1", L["Color code debuff names"], LEGEND), one)
	Dep(W:Choose(cat, "nameJustifyWithTime1", L["Justify name (beside time)"], JUSTIFY), one)
	Dep(W:Choose(cat, "nameJustifyNoTime1", L["Justify name (when alone)"], JUSTIFY), one)
	Dep(W:Check(cat, "showTimers1", L["Time remaining as text"]), one)
	Dep(W:Choose(cat, "durationFormat1", L["Time format"], ns.TimeFormatEntries()), one)
	Dep(W:Check(cat, "showDays1", L["Show days if >24 hours"]), one)
	Dep(W:Choose(cat, "durationLocation1", L["Time remaining location"], {
		{ E.timeAt.DEFAULT, DEFAULT },
		{ E.timeAt.LEFT, L["Left of the name"] },
		{ E.timeAt.RIGHT, L["Right of the name"] },
		{ E.timeAt.ABOVE, L["Above the name"] },
		{ E.timeAt.BELOW, L["Below the name"] },
	}), one)
	Dep(W:Choose(cat, "timeJustifyNoName1", L["Justify time (when alone)"], JUSTIFY), one)
	Dep(W:Check(cat, "showBuffTimer1", L["Time remaining as bar"]), one)
	Dep(W:Check(cat, "showTimerBackground1", L["Bar background"]), one)
	Dep(W:Slide(cat, "spacingOnLeft1", L["Text offset (left side)"], 0, 50), one)
	Dep(W:Slide(cat, "spacingOnRight1", L["Text offset (right side)"], 0, 50), one)

	S.Header(layout, L["Style 2 (icon only)"])
	Dep(W:Slide(cat, "buffSize2", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_SIZE, 15, 45), two)
	Dep(W:Check(cat, "colorCodeIcons2", L["Color code the border of debuff icons"], LEGEND), two)
	Dep(W:Check(cat, "normalIconBorder2", L["Default icon border"], L["Shows the whole icon including its own border instead of trimming its edges."]), two)
	Dep(W:Check(cat, "showTimers2", L["Time remaining as text"]), two)
	Dep(W:Choose(cat, "durationFormat2", L["Time format"], ns.TimeFormatEntries()), two)
	Dep(W:Check(cat, "showDays2", L["Show days if >24 hours"]), two)
	Dep(W:Choose(cat, "dataSide2", L["Time remaining location"], {
		{ E.dataSide.LEFT, HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_LEFT },
		{ E.dataSide.RIGHT, HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_RIGHT },
		{ E.dataSide.ABOVE, L["Above"] },
		{ E.dataSide.BELOW, L["Below"] },
		{ E.dataSide.CENTER, L["Center"] },
	}), two)
	Dep(W:Slide(cat, "spacingFromIcon2", L["Offset from icon"], 0, 50, nil, L["No effect with 'Center'."]), two)
end

-- Doppelte Zauberart: der andere Platz wird "keine", seine Anzeige folgt sofort
local function GroupSlotChanged(slot)
	return function(_, value)
		local t = ns.SelectedSettings()
		if value ~= E.group.NONE then
			for i = 1, 5 do
				if i ~= slot and ns.WindowValue(t, "sortSeq" .. i) == value then
					t["sortSeq" .. i] = E.group.NONE
				end
			end
			ns.RefreshWindowPages()
		end
		ns.ApplyWindowSetting("sortSeq" .. slot, value)
	end
end

local function BuildGroupingPage(category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Grouping"])
	WindowHead(cat, layout)
	local W = WindowBuilder("QNBUFFMOD_G_")

	S.Header(layout, L["Grouping (before sorting)"])
	W:Choose(cat, "groupByPriority", L["Grouping order"], {
		{ 1, L["Filters > Own > Non-expiring"] },
		{ 2, L["Filters > Non-expiring > Own"] },
		{ 3, L["Own > Filters > Non-expiring"] },
		{ 4, L["Own > Non-expiring > Filters"] },
		{ 5, L["Non-expiring > Filters > Own"] },
		{ 6, L["Non-expiring > Own > Filters"] },
	}, L["Sets the order of precedence for grouping by filter, own and non-expiring buffs."])
	W:Choose(cat, "separateOwn", L["Buffs that you cast"], {
		{ E.own.FIRST, L["Before other players"] },
		{ E.own.LAST, L["After other players"] },
		{ E.own.WITH, L["With other players"] },
	})
	W:Choose(cat, "separateZero", L["Non-expiring buffs"], {
		{ E.zero.FIRST, L["Before other buffs"] },
		{ E.zero.LAST, L["After other buffs"] },
		{ E.zero.WITH, L["With other buffs"] },
		{ E.zero.HIDE, HIDE },
		{ E.zero.ONLY, L["Shown only"] },
	})
	for i = 1, 5 do
		W:Choose(cat, "sortSeq" .. i, GROUP_NUMBER:format(i), GROUPS, nil, GroupSlotChanged(i))
	end

	S.Header(layout, L["Sorting (after grouping)"])
	W:Choose(cat, "sortMethod", RAID_FRAME_SORT_LABEL, {
		{ E.sort.NAME, NAME },
		{ E.sort.TIME, CLOSES_IN },
		{ E.sort.INDEX, L["Order"] },
	})
	W:Check(cat, "sortDirection", L["Reverse order"])
end

---------------------------------------------------------------------------
-- Bedingung prüfen
---------------------------------------------------------------------------

function ns.TestCondition(id)
	local cond = ns.WindowCondition(ns.ResolveOptions(ns.db.windows[id])) or "show"
	ns.Print(L["Condition: %s"], cond)
	local result, target = SecureCmdOptionParse(cond)
	if target then
		ns.Print(L["Target: %s"], tostring(target))
	end
	if result == "show" or result == "hide" then
		ns.Print(L["Result: |cFF66FF66%s|r"], result)
	else
		ns.Print(L["Invalid result: |cFFFF3333%s|r"], tostring(result))
	end
end

---------------------------------------------------------------------------
-- Anmeldung
---------------------------------------------------------------------------

function ns.InitOptions()
	S.NewCategory(ns, "qnBuffMod", function(category, layout)
		BuildGeneral(category, layout)
		BuildWindowPage(category)
		BuildLayoutPage(category)
		BuildButtonsPage(category)
		BuildGroupingPage(category)
	end)
	-- Fenstertitel und Maus am Hintergrund hängen an der angezeigten Seite
	EventRegistry:RegisterCallback("Settings.CategoryChanged", PagesChanged, ns)
	SettingsPanel:HookScript("OnShow", PagesChanged)
	SettingsPanel:HookScript("OnHide", PagesChanged)
end
