-- qnNumKeyPad: Optionen im Blizzard-Einstellungsfenster (Settings-API).
-- Die Einstellungen gehören zum aktiven Profil (qnCore); nach einem Profilwechsel
-- liest qnCore die Steuerelemente neu ein.

local _, ns = ...
local L = ns.L
local S = qnCore.Settings

-- Werte aus Slash-Befehlen und Knöpfen setzen ns.store:Set bzw. ns.store:SetValues (qnCore):
-- so zeigt auch das Einstellungsfenster sie an; SetValues wendet mehrere Werte mit nur einem
-- ns.Apply an (sonst stünde die Leiste zwischendurch an einem Zwischenort, z. B. neues x mit altem y).

---------------------------------------------------------------------------
-- Eigene Sichtbarkeitsbedingung (Makrobedingungen für den Zustandstreiber "visibility")
---------------------------------------------------------------------------

qnCore.Popup.EditText("QNNUMKEYPAD_CUSTOM", L["Eigene Sichtbarkeitsbedingung (Makro-Syntax, z. B. [combat] show; hide):"],
	function() return ns.db.custom end,
	function(text) ns.store:Set("custom", text) end, 500)

---------------------------------------------------------------------------
-- Aufbau
---------------------------------------------------------------------------

local PAGES = {
	{ 1, L["Seite 1 – Aktionsleiste 1"] },
	{ 2, L["Seite 2 – Aktionsleiste 1, zweite Seite"] },
	{ 3, L["Seite 3 – Aktionsleiste 4 (rechts)"] },
	{ 4, L["Seite 4 – Aktionsleiste 5 (rechts)"] },
	{ 5, L["Seite 5 – Aktionsleiste 3 (unten rechts)"] },
	{ 6, L["Seite 6 – Aktionsleiste 2 (unten links)"] },
	{ 7, L["Seite 7 – Haltung/Gestalt 1"] },
	{ 8, L["Seite 8 – Haltung/Gestalt 2"] },
	{ 9, L["Seite 9 – Haltung/Gestalt 3"] },
	{ 10, L["Seite 10 – Haltung/Gestalt 4"] },
	{ 13, L["Seite 13 – Aktionsleiste 6"] },
	{ 14, L["Seite 14 – Aktionsleiste 7"] },
	{ 15, L["Seite 15 – Aktionsleiste 8"] },
}

local function LayoutEntries()
	local list = {}
	for _, layout in ipairs(ns.LAYOUTS) do
		list[#list + 1] = { layout.id, layout.name }
	end
	return list
end

local function Build(category, layout)
	local B = S.New({ store = ns.store, prefix = "QNNKP_", apply = ns.Apply })
	-- Einstellungen, die bestimmen, welche Seiten benutzt werden: danach Seiten prüfen
	local check = ns.ApplyAndCheck

	-- Allgemein -----------------------------------------------------------
	local cat = category
	S.Header(layout, GENERAL)
	B:Checkbox(cat, "enabled", L["Ziffernblock aktiv"],
		L["Aus: Leiste ausgeblendet und alle Tastenbelegungen des Ziffernblocks aufgehoben."])
	B:Checkbox(cat, "locked", L["Position sperren"],
		L["Verhindert versehentliches Verschieben. Entsperrt zeigt die Leiste eine grüne Fläche zum Ziehen; Rechtsklick darauf öffnet diese Optionen."])
	B:Checkbox(cat, "lockActions", L["Aktionen immer sperren"],
		L["Aktionen lassen sich nur mit der Taste für 'Aktion aufnehmen' (Standard: Umschalt) herausziehen. Wirkt zusätzlich zur Blizzard-Einstellung 'Aktionsleisten sperren'."])
	B:Checkbox(cat, "lockInCombat", L["Aktionen im Kampf sperren"],
		L["Verhindert im Kampf das versehentliche Herausziehen von Aktionen."])

	S.Header(layout, L["Tastatur"])
	B:Dropdown(cat, "layout", L["Tastaturlayout"], LayoutEntries(), nil, nil, check)
	B:Checkbox(cat, "showEnter", L["Enter-Taste anzeigen"],
		L["Achtung: belegt Enter und hebt damit 'Chat öffnen' auf, solange der Ziffernblock aktiv ist."], check)
	B:Checkbox(cat, "showNav", L["Navigationstasten anzeigen"],
		L["Einfg, Pos1, Bild auf/ab, Entf, Ende. Überschreibt deren bisherige Belegung (Chat-Bildlauf, Kamera)."], check)
	B:Checkbox(cat, "showArrow", L["Pfeiltasten anzeigen"],
		L["Achtung: überschreibt die Bewegung mit den Pfeiltasten."], check)
	B:Checkbox(cat, "bindShift", L["Auch mit Umschalttaste belegen"],
		L["Umschalt+Taste löst dieselbe Aktion aus. Verhindert, dass Umschalt+Ziffernblock die Standardbelegung (z. B. Leistenwechsel) auslöst."])
	B:Checkbox(cat, "stance", L["Haltungswechsel"],
		L["Tasten 1–12 folgen der Haltungs-/Gestaltleiste, so wie die Hauptleiste (z. B. Kampfhaltung, Katzengestalt, Verstohlenheit). Ohne Haltung gelten die eigenen Plätze."])

	-- Darstellung ---------------------------------------------------------
	local look, lookLayout = Settings.RegisterVerticalLayoutSubcategory(category, APPEARANCE_LABEL)
	S.Header(lookLayout, L["Größe und Abstände"])
	B:Slider(look, "scale", L["Skalierung"], 0.3, 2, 0.05, S.DecimalFormatter)
	B:Slider(look, "padH", L["Abstand waagerecht"], 0, 30, 1)
	B:Slider(look, "padV", L["Abstand senkrecht"], 0, 30, 1)
	B:Slider(look, "blockGap", L["Abstand zum Zusatzblock"], 0, 80, 1, nil,
		L["Zusätzlicher Abstand zwischen Ziffernblock und Navigations-/Pfeiltasten."])

	-- eigene Kopfzeile statt APPEARANCE_LABEL: das hieße auf Englisch wie die Seite ("Appearance")
	S.Header(lookLayout, DISPLAY)
	B:Slider(look, "alpha", L["Deckkraft"], 0, 1, 0.05, S.FractionFormatter)
	B:Slider(look, "bgAlpha", L["Deckkraft des Hintergrunds"], 0, 1, 0.05, S.FractionFormatter)
	B:Checkbox(look, "showGrid", L["Leere Tasten anzeigen"])
	B:Dropdown(look, "labels", L["Tastenbeschriftung"], {
		{ 1, L["Kurz (1, 2, +, …)"] },
		{ 2, L["Tastenname (Num 1, …)"] },
		{ 3, NONE_KEY },
	})
	B:Slider(look, "fontSize", L["Schriftgröße der Beschriftung"], 0, 24, 1, S.FontSizeFormatter)
	B:Checkbox(look, "hideMacro", L["Makrotext ausblenden"])
	B:Checkbox(look, "hideBorder", L["Rahmen für ausgerüstete Gegenstände ausblenden"])
	B:Checkbox(look, "zoom", L["Symbole zoomen"], L["Schneidet den Rand der Symbole ab."])
	B:Dropdown(look, "flyout", L["Richtung von Aufklappmenüs"], {
		{ "UP", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_UP },
		{ "DOWN", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_DOWN },
		{ "LEFT", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_LEFT },
		{ "RIGHT", HUD_EDIT_MODE_SETTING_AURA_FRAME_ICON_DIRECTION_RIGHT },
	})
	B:Checkbox(look, "clickThrough", L["Mausklicks durchlassen"],
		L["Tasten reagieren nicht auf die Maus; nur die Tastatur löst sie aus."])

	-- Position ------------------------------------------------------------
	local pos, posLayout = Settings.RegisterVerticalLayoutSubcategory(category, L["Position"])
	S.Header(posLayout, L["Position"])
	-- dieselbe Einstellung wie unter "Allgemein", nur ein zweites Steuerelement
	Settings.CreateCheckbox(pos, B.settings.locked)
	B:Dropdown(pos, "point", L["Anker"], qnCore.PointEntries(), L["Bezugspunkt am Bildschirm und an der Leiste. Beim Wechsel bleibt die Leiste an ihrem Platz."],
		nil, ns.KeepPosition)
	B:Slider(pos, "x", L["X-Versatz"], -3000, 3000, 1)
	B:Slider(pos, "y", L["Y-Versatz"], -3000, 3000, 1)
	S.Button(posLayout, L["Waagerecht zentrieren"], L["Zentrieren"], function() ns.CenterBar(true) end)
	S.Button(posLayout, L["Senkrecht zentrieren"], L["Zentrieren"], function() ns.CenterBar(false) end)
	S.Button(posLayout, L["Position zurücksetzen"], RESET, ns.ResetPosition)
	B:Checkbox(pos, "autoVisible", L["Automatisch im sichtbaren Bereich halten"],
		L["Holt die Leiste nach dem Verschieben, beim Einloggen und bei Änderungen der Monitoranordnung auf einen Monitor zurück. Mit qnViewPort und Monitordaten zählen nur Bereiche, die wirklich auf einem Monitor zu sehen sind."])
	S.Button(posLayout, L["Leiste suchen"], L["In sichtbaren Bereich holen"], ns.MoveIntoVisible,
		L["Verschiebt die Leiste jetzt auf den nächsten sichtbaren Monitor (/qnnkp visible)."])

	-- Sichtbarkeit --------------------------------------------------------
	local vis, visLayout = Settings.RegisterVerticalLayoutSubcategory(category, HUD_EDIT_MODE_SETTING_AURA_FRAME_VISIBLE_SETTING)
	S.Header(visLayout, L["Ausblenden"])
	local fade = B:Checkbox(vis, "fade", L["Ausblenden ohne Maus"],
		L["Blendet die Leiste auf die unten eingestellte Deckkraft ab, solange die Maus nicht darüber ist."])
	local function Fading()
		return ns.db.fade
	end
	S.Depends(B:Slider(vis, "fadeAlpha", L["Deckkraft ausgeblendet"], 0, 1, 0.05, S.FractionFormatter), fade, Fading)
	S.Depends(B:Slider(vis, "fadeDelay", L["Verzögerung"], 0, 3, 0.1, S.SecondsFormatter), fade, Fading)

	S.Header(visLayout, L["Verbergen"])
	local custom = B:Checkbox(vis, "useCustom", L["Eigene Bedingung verwenden"],
		L["Ersetzt alle folgenden Schalter durch eine eigene Makrobedingung."])
	local function NotCustom()
		return not ns.db.useCustom
	end
	S.Depends(B:Checkbox(vis, "hideVehicle", L["Im Fahrzeug / bei Übernahme verbergen"]), custom, NotCustom)
	S.Depends(B:Checkbox(vis, "hideCombat", L["Im Kampf verbergen"]), custom, NotCustom)
	S.Depends(B:Checkbox(vis, "hideNoCombat", L["Außerhalb des Kampfes verbergen"]), custom, NotCustom)
	S.Depends(B:Checkbox(vis, "hidePet", L["Mit Begleiter verbergen"]), custom, NotCustom)
	S.Depends(B:Checkbox(vis, "hideNoPet", L["Ohne Begleiter verbergen"]), custom, NotCustom)
	S.Depends(B:Checkbox(vis, "hideStealth", L["In Verstohlenheit verbergen"]), custom, NotCustom)
	S.Depends(B:Checkbox(vis, "hideForm", L["In Haltung/Gestalt verbergen"]), custom, NotCustom)
	B:Register(vis, "custom", L["Eigene Bedingung"])
	S.Button(visLayout, L["Eigene Bedingung"], L["Bearbeiten …"], function()
		StaticPopup_Show("QNNUMKEYPAD_CUSTOM")
	end, L["Makrobedingung mit show/hide, z. B. '[combat] show; [mod:alt] show; hide'."])

	-- Aktionsplätze -------------------------------------------------------
	local slots, slotsLayout = Settings.RegisterVerticalLayoutSubcategory(category, L["Aktionsplätze"])
	S.Header(slotsLayout, L["Aktionsplätze"])
	local note = L["Die Aktionen liegen in den Plätzen dieser Seite. Eine Blizzard-Leiste, die dieselbe Seite benutzt, zeigt dieselben Aktionen – im Bearbeitungsmodus ausblenden."]
	B:Dropdown(slots, "page1", L["Tasten 1–12"], PAGES, note, nil, check)
	B:Dropdown(slots, "page2", L["Tasten 13–24"], PAGES, note, nil, check)
	B:Dropdown(slots, "page3", L["Tasten 25–28"], PAGES, L["Die Aktionen liegen in den Plätzen dieser Seite. Eine Blizzard-Leiste, die dieselbe Seite benutzt, zeigt dieselben Aktionen – im Bearbeitungsmodus ausblenden. Nur mit eingeblendeten Pfeiltasten benutzt: beim Macintosh-Layout für alle vier Pfeiltasten, bei Windows, Microsoft Office und Natural Elite für Pfeil nach unten und nach rechts, bei Natural Multimedia für Pfeil nach rechts, bei Razer Naga nie."], nil, check)
end

-- setzt ns.category und ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnNumKeyPad", Build)
end