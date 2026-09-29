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
local LEGEND = L["Farben: |cFF9600FFFluch|r, |cFF966400Krankheit|r, |cFF3296FFMagie|r, |cFF009600Gift|r, |cFFc80000andere (z. B. körperlich)|r."]

---------------------------------------------------------------------------
-- Popups
---------------------------------------------------------------------------

qnCore.Popup.Confirm("QNBUFFMOD_DELETE_WINDOW", L["%s löschen? Seine Einstellungen gehen verloren."], DELETE, function()
	ns.DeleteWindow(ns.SelectedID())
end)

qnCore.Popup.EditText("QNBUFFMOD_CONDITION", L["Sichtbarkeitsbedingung für %s (Makro-Syntax, Aktionen: show, hide):"],
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
		list[#list + 1] = { id, L["Fenster %d"]:format(id) }
	end
	if #list == 0 then
		list[1] = { 1, L["Fenster %d"]:format(1) }
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
	S.Header(layout, L["Fenster"])
	if not editSetting then
		editSetting = Settings.RegisterProxySetting(cat, "QNBUFFMOD_EDITWINDOW", Settings.VarType.Number, L["Fenster bearbeiten"], 1,
			function()
				return ns.SelectedID()
			end,
			function(value)
				ns.SelectWindow(value, true)
			end)
	end
	S.Dropdown(cat, editSetting, WindowEntries,
		L["Die Einstellungen auf dieser Seite gelten nur für das gewählte Fenster. Alt-Klick auf ein Fenster wählt es ebenfalls aus."])
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
	{ E.justify.CENTER, L["Mittig"] },
}

local GROUPS = {
	{ E.group.NONE, NONE_KEY },
	{ E.group.DEBUFF, L["Schwächungszauber"] },
	{ E.group.CANCELABLE, L["Aufhebbare Stärkungszauber"] },
	{ E.group.UNCANCELABLE, L["Nicht aufhebbare Stärkungszauber"] },
	{ E.group.ALLBUFFS, L["Alle Stärkungszauber"] },
	{ E.group.WEAPONS, L["Waffenverzauberungen"] },
}

local function WrapsLabel(v)
	if v == 0 then
		return L["automatisch"]
	end
	return ("%d"):format(v)
end

---------------------------------------------------------------------------
-- Seiten
---------------------------------------------------------------------------

local function BuildGeneral(category, layout)
	local G = S.New({ store = ns.store, prefix = "QNBUFFMOD_", apply = ns.ApplyGeneral })
	local cat = category

	S.Header(layout, L["Blizzard-Fenster"])
	G:Checkbox(cat, "hideBlizzardBuffs", L["Blizzards Zauberfenster verbergen"],
		L["Verbirgt Blizzards Fenster für Stärkungs- und Schwächungszauber."])

	S.Header(layout, COLORS)
	G:Color(cat, "backgroundColor", L["Fensterhintergrund"], L["Hintergrund aller Fenster ohne eigene Farbe."], nil, L["Fensterhintergrund: Deckkraft"])
	G:Color(cat, "bgColorBUFF", CONTEXT_ACTION_LABEL_BUFFS, nil, nil, L["Stärkungszauber: Deckkraft"])
	G:Color(cat, "bgColorAURA", AURAS, nil, nil, L["Auren: Deckkraft"])
	G:Color(cat, "bgColorDEBUFF", L["Schwächungszauber"], nil, nil, L["Schwächungszauber: Deckkraft"])
	G:Color(cat, "bgColorITEM", L["Waffenverzauberungen"], nil, nil, L["Waffenverzauberungen: Deckkraft"])

	S.Header(layout, PROFESSIONS_COLUMN_HEADER_EXPIRATION)
	G:Slider(cat, "flashTime", L["Symbol vor Ablauf blinken lassen"], 0, 60, 1, ns.SecondsLabel)
	local warn = G:Checkbox(cat, "enableExpiration", L["Warnung im Chat"], L["Meldet im Chat, dass ein Stärkungszauber bald abläuft."])
	local function Warn()
		return ns.db.enableExpiration
	end
	S.Depends(G:Checkbox(cat, "expirationCastOnly", L["Nur Zauber, die du selbst wirken kannst"]), warn, Warn)
	S.Depends(G:Checkbox(cat, "expirationSound", L["Ton abspielen"]), warn, Warn)
	S.Depends(G:Slider(cat, "expirationTime1", L["Warnen bei Dauer 2:00 – 10:00"], 0, 60, 5, ns.SecondsLabel), warn, Warn)
	S.Depends(G:Slider(cat, "expirationTime2", L["Warnen bei Dauer 10:01 – 30:00"], 0, 180, 5, ns.SecondsLabel), warn, Warn)
	S.Depends(G:Slider(cat, "expirationTime3", L["Warnen bei Dauer ab 30:01"], 0, 300, 5, ns.SecondsLabel), warn, Warn)
end

local function BuildWindowPage(category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Fenster"])
	windowPage = cat
	WindowHead(cat, layout)
	local W = WindowBuilder("QNBUFFMOD_W_")

	S.Button(layout, COMMUNITIES_ADD_TO_CHAT_DROP_DOWN_NEW_CHAT_WINDOW, ADD, function()
		ns.AddWindow()
	end, L["Neues Fenster mit Standardeinstellungen."])
	S.Button(layout, L["Fenster kopieren"], L["Duplizieren"], function()
		ns.AddWindow(ns.SelectedID())
	end, L["Neues Fenster mit den Einstellungen des gewählten Fensters."])
	S.Button(layout, L["Fenster löschen"], L["Löschen …"], function()
		StaticPopup_Show("QNBUFFMOD_DELETE_WINDOW", L["Fenster %d"]:format(ns.SelectedID()))
	end, L["Löscht das gewählte Fenster samt Einstellungen."])
	S.Button(layout, L["Position zurücksetzen"], RESET, function()
		local win = Window()
		if win then
			win:ResetPosition()
		end
	end, L["Verschiebt das Fenster in die Bildschirmmitte."])
	S.Button(layout, L["Fenster suchen"], L["In sichtbaren Bereich holen"], function()
		local win = Window()
		if win then
			win:BringIntoView()
		end
	end, L["Verschiebt das Fenster nur so weit, bis es vollständig im sichtbaren Bereich liegt. Die übrige Position bleibt erhalten."])

	S.Header(layout, GENERAL)
	W:Check(cat, "disableWindow", L["Fenster deaktivieren"])
	W:Check(cat, "disableTooltips", L["Keine Tooltips an den Symbolen"])
	W:Check(cat, "lockWindow", LOCK_FRAME, L["Verhindert das Verschieben."])
	W:Check(cat, "clampWindow", L["Im Bildschirm halten"])

	S.Header(layout, GROUPMANAGER_UNIT_MARKER)
	local unit = W:Choose(cat, "unitType", L["Zauber zeigen für"], {
		{ E.unit.PLAYER, PLAYER },
		{ E.unit.VEHICLE, L["Fahrzeug"] },
		{ E.unit.PET, PET },
		{ E.unit.TARGET, TARGET },
		{ E.unit.FOCUS, FOCUS },
	}, L["Rechtsklick auf einen eigenen Zauber entfernt ihn – nur außerhalb des Kampfes."])
	S.Depends(W:Check(cat, "vehicleBuffs", L["Im Fahrzeug dessen Zauber zeigen"]), unit, Is("unitType", E.unit.PLAYER))

	S.Header(layout, HUD_EDIT_MODE_SETTING_AURA_FRAME_VISIBLE_SETTING)
	local vis = W:Choose(cat, "visWindow", SHOW, {
		{ E.vis.ALWAYS, BATTLEFIELD_MINIMAP_SHOW_ALWAYS },
		{ E.vis.BASIC, L["Standardbedingungen"] },
		{ E.vis.CUSTOM, L["Eigene Bedingung"] },
	})
	local basic = Is("visWindow", E.vis.BASIC)
	S.Depends(W:Check(cat, "visHideInCombat", L["Im Kampf verbergen"]), vis, basic)
	S.Depends(W:Check(cat, "visHideNotCombat", L["Außerhalb des Kampfes verbergen"]), vis, basic)
	S.Depends(W:Check(cat, "visHideInVehicle", L["Im Fahrzeug verbergen"]), vis, basic)
	S.Depends(W:Check(cat, "visHideNotVehicle", L["Außerhalb von Fahrzeugen verbergen"]), vis, basic)
	-- der Text selbst hat kein eigenes Steuerelement (Dialog)
	W:Register(cat, "visCondition", L["Eigene Bedingung"], nil, On("visCondition"))
	local custom = Is("visWindow", E.vis.CUSTOM)
	S.Depends(S.Button(layout, L["Eigene Bedingung"], L["Bearbeiten …"], function()
		StaticPopup_Show("QNBUFFMOD_CONDITION", L["Fenster %d"]:format(ns.SelectedID()))
	end, L["Makrobedingung mit show/hide, z. B. '[vehicleui] hide; [combat] hide; show'."]), vis, custom)
	S.Depends(S.Button(layout, L["Bedingung prüfen"], L["Testen"], function()
		ns.TestCondition(ns.SelectedID())
	end, L["Zeigt im Chat, was die gespeicherte Bedingung gerade bewirkt."]), vis, custom)
end

local function BuildLayoutPage(category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, APPEARANCE_LABEL)
	WindowHead(cat, layout)
	local W = WindowBuilder("QNBUFFMOD_L_")

	S.Header(layout, BACKGROUND)
	W:Check(cat, "showBackground", HUD_EDIT_MODE_SETTING_UNIT_FRAME_SHOW_PARTY_FRAME_BACKGROUND)
	local own = W:Check(cat, "useCustomBackgroundColor", L["Eigene Farbe für dieses Fenster"])
	local color, alpha = W:Color(cat, "windowBackgroundColor", COMPACT_UNIT_FRAME_PROFILE_HEALTH_BAR_COLOR_BG, nil,
		On("windowBackgroundColor"), L["Deckkraft des Hintergrunds"])
	S.Depends(color, own, Is("useCustomBackgroundColor", true))
	S.Depends(alpha, own, Is("useCustomBackgroundColor", true))

	S.Header(layout, L["Rahmen"])
	W:Check(cat, "showBorder", HUD_EDIT_MODE_SETTING_UNIT_FRAME_DISPLAY_BORDER)
	W:Slide(cat, "userEdgeLeft", L["Rand links"], 0, 100)
	W:Slide(cat, "userEdgeRight", L["Rand rechts"], 0, 100)
	W:Slide(cat, "userEdgeTop", L["Rand oben"], 0, 100)
	W:Slide(cat, "userEdgeBottom", L["Rand unten"], 0, 100)

	S.Header(layout, L["Anordnung"])
	W:Choose(cat, "layoutType", HUD_EDIT_MODE_SETTING_BAGS_DIRECTION, {
		{ 1, L["Oben nach unten, Spalten nach rechts"] },
		{ 2, L["Oben nach unten, Spalten nach links"] },
		{ 3, L["Unten nach oben, Spalten nach rechts"] },
		{ 4, L["Unten nach oben, Spalten nach links"] },
		{ 5, L["Links nach rechts, Zeilen nach unten"] },
		{ 6, L["Links nach rechts, Zeilen nach oben"] },
		{ 7, L["Rechts nach links, Zeilen nach unten"] },
		{ 8, L["Rechts nach links, Zeilen nach oben"] },
	}, L["Oben/unten: Zauber in Spalten; links/rechts: Zauber in Zeilen. Standard: eine Spalte, die nach unten wächst (links nach rechts, Zeilen nach unten, 1 Zauber pro Zeile, Zeilen automatisch)."])
	W:Slide(cat, "wrapAfter", L["Zauber pro Zeile bzw. Spalte"], 1, 50)
	W:Slide(cat, "maxWraps", L["Anzahl Zeilen bzw. Spalten"], 0, 50, WrapsLabel, L["0 = wächst automatisch."])
	W:Slide(cat, "buffSpacing", L["Abstand zwischen Zaubern"], 0, 200)
	W:Slide(cat, "wrapSpacing", L["Abstand zwischen Zeilen bzw. Spalten"], 0, 200)

	S.Header(layout, L["Schrift"])
	W:Choose(cat, "fontSize", FONT_SIZE, {
		{ E.font.NORMAL, VOICE_CHAT_NORMAL },
		{ E.font.SMALL, L["Kleiner"] },
		{ E.font.LARGE, L["Größer"] },
	})
end

local function BuildButtonsPage(category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Knöpfe"])
	WindowHead(cat, layout)
	local W = WindowBuilder("QNBUFFMOD_B_")

	S.Header(layout, L["Knöpfe"])
	local style = W:Choose(cat, "buttonStyle", HUD_EDIT_MODE_SETTING_DAMAGE_METER_STYLE, {
		{ E.style.BAR, L["Stil 1 (Symbol und Balken)"] },
		{ E.style.ICON, L["Stil 2 (nur Symbol)"] },
	})
	local one, two = Is("buttonStyle", E.style.BAR), Is("buttonStyle", E.style.ICON)
	local function Dep(init, pred)
		return S.Depends(init, style, pred)
	end

	S.Header(layout, L["Stil 1 (Symbol und Balken)"])
	Dep(W:Slide(cat, "buffSize1", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_SIZE, 15, 45), one)
	Dep(W:Choose(cat, "rightAlign1", L["Symbolposition"], {
		{ E.side.DEFAULT, DEFAULT },
		{ E.side.LEFT, HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_LEFT },
		{ E.side.RIGHT, HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_RIGHT },
	}), one)
	Dep(W:Check(cat, "colorCodeIcons1", L["Rahmen von Schwächungszaubern einfärben"], LEGEND), one)
	Dep(W:Check(cat, "normalIconBorder1", L["Standard-Symbolrahmen"], L["Zeigt das ganze Symbol samt seinem eigenen Rand, statt es an den Kanten zu beschneiden."]), one)
	Dep(W:Slide(cat, "detailWidth1", L["Balkenbreite"], 0, 400), one)
	Dep(W:Check(cat, "colorBuffs1", L["Balkenhintergrund einfärben"]), one)
	Dep(W:Check(cat, "colorCodeBackground1", L["Balken von Schwächungszaubern einfärben"], LEGEND), one)
	Dep(W:Check(cat, "showNames1", PROFESSIONS_FLYOUT_SHOW_NAME), one)
	Dep(W:Check(cat, "colorCodeDebuffs1", L["Namen von Schwächungszaubern einfärben"], LEGEND), one)
	Dep(W:Choose(cat, "nameJustifyWithTime1", L["Name ausrichten (neben der Zeit)"], JUSTIFY), one)
	Dep(W:Choose(cat, "nameJustifyNoTime1", L["Name ausrichten (ohne Zeit)"], JUSTIFY), one)
	Dep(W:Check(cat, "showTimers1", L["Restzeit als Text"]), one)
	Dep(W:Choose(cat, "durationFormat1", L["Zeitformat"], ns.TimeFormatEntries()), one)
	Dep(W:Check(cat, "showDays1", L["Tage anzeigen, wenn über 24 Stunden"]), one)
	Dep(W:Choose(cat, "durationLocation1", L["Platz der Restzeit"], {
		{ E.timeAt.DEFAULT, DEFAULT },
		{ E.timeAt.LEFT, L["Links vom Namen"] },
		{ E.timeAt.RIGHT, L["Rechts vom Namen"] },
		{ E.timeAt.ABOVE, L["Über dem Namen"] },
		{ E.timeAt.BELOW, L["Unter dem Namen"] },
	}), one)
	Dep(W:Choose(cat, "timeJustifyNoName1", L["Zeit ausrichten (ohne Namen)"], JUSTIFY), one)
	Dep(W:Check(cat, "showBuffTimer1", L["Restzeit als Balken"]), one)
	Dep(W:Check(cat, "showTimerBackground1", L["Hintergrund des Balkens"]), one)
	Dep(W:Slide(cat, "spacingOnLeft1", L["Textabstand links"], 0, 50), one)
	Dep(W:Slide(cat, "spacingOnRight1", L["Textabstand rechts"], 0, 50), one)

	S.Header(layout, L["Stil 2 (nur Symbol)"])
	Dep(W:Slide(cat, "buffSize2", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_SIZE, 15, 45), two)
	Dep(W:Check(cat, "colorCodeIcons2", L["Rahmen von Schwächungszaubern einfärben"], LEGEND), two)
	Dep(W:Check(cat, "normalIconBorder2", L["Standard-Symbolrahmen"], L["Zeigt das ganze Symbol samt seinem eigenen Rand, statt es an den Kanten zu beschneiden."]), two)
	Dep(W:Check(cat, "showTimers2", L["Restzeit als Text"]), two)
	Dep(W:Choose(cat, "durationFormat2", L["Zeitformat"], ns.TimeFormatEntries()), two)
	Dep(W:Check(cat, "showDays2", L["Tage anzeigen, wenn über 24 Stunden"]), two)
	Dep(W:Choose(cat, "dataSide2", L["Platz der Restzeit"], {
		{ E.dataSide.LEFT, HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_LEFT },
		{ E.dataSide.RIGHT, HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_RIGHT },
		{ E.dataSide.ABOVE, L["Darüber"] },
		{ E.dataSide.BELOW, L["Darunter"] },
		{ E.dataSide.CENTER, L["Mittig"] },
	}), two)
	Dep(W:Slide(cat, "spacingFromIcon2", L["Abstand zum Symbol"], 0, 50, nil, L["Ohne Wirkung bei 'Mittig'."]), two)
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
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Gruppierung"])
	WindowHead(cat, layout)
	local W = WindowBuilder("QNBUFFMOD_G_")

	S.Header(layout, L["Gruppierung (vor der Sortierung)"])
	W:Choose(cat, "groupByPriority", L["Reihenfolge der Gruppierungen"], {
		{ 1, L["Filter > Eigene > Nicht ablaufende"] },
		{ 2, L["Filter > Nicht ablaufende > Eigene"] },
		{ 3, L["Eigene > Filter > Nicht ablaufende"] },
		{ 4, L["Eigene > Nicht ablaufende > Filter"] },
		{ 5, L["Nicht ablaufende > Filter > Eigene"] },
		{ 6, L["Nicht ablaufende > Eigene > Filter"] },
	}, L["Legt fest, in welcher Reihenfolge nach Filter, eigenen und nicht ablaufenden Zaubern gruppiert wird."])
	W:Choose(cat, "separateOwn", L["Eigene Zauber"], {
		{ E.own.FIRST, L["Vor denen anderer Spieler"] },
		{ E.own.LAST, L["Nach denen anderer Spieler"] },
		{ E.own.WITH, L["Zusammen mit denen anderer Spieler"] },
	})
	W:Choose(cat, "separateZero", L["Zauber ohne Ablaufzeit"], {
		{ E.zero.FIRST, L["Vor den anderen"] },
		{ E.zero.LAST, L["Nach den anderen"] },
		{ E.zero.WITH, L["Zusammen mit den anderen"] },
		{ E.zero.HIDE, HIDE },
		{ E.zero.ONLY, L["Nur diese anzeigen"] },
	})
	for i = 1, 5 do
		W:Choose(cat, "sortSeq" .. i, GROUP_NUMBER:format(i), GROUPS, nil, GroupSlotChanged(i))
	end

	S.Header(layout, L["Sortierung (nach der Gruppierung)"])
	W:Choose(cat, "sortMethod", RAID_FRAME_SORT_LABEL, {
		{ E.sort.NAME, NAME },
		{ E.sort.TIME, CLOSES_IN },
		{ E.sort.INDEX, L["Reihenfolge"] },
	})
	W:Check(cat, "sortDirection", L["Reihenfolge umkehren"])
end

---------------------------------------------------------------------------
-- Bedingung prüfen
---------------------------------------------------------------------------

function ns.TestCondition(id)
	local cond = ns.WindowCondition(ns.ResolveOptions(ns.db.windows[id])) or "show"
	ns.Print(L["Bedingung: %s"], cond)
	local result, target = SecureCmdOptionParse(cond)
	if target then
		ns.Print(L["Ziel: %s"], tostring(target))
	end
	if result == "show" or result == "hide" then
		ns.Print(L["Ergebnis: |cFF66FF66%s|r"], result)
	else
		ns.Print(L["Ungültiges Ergebnis: |cFFFF3333%s|r"], tostring(result))
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
