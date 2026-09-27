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

	S.Header(layout, L["Fenster"])
	B:Checkbox(cat, "shown", L["Fenster anzeigen"])
	B:Checkbox(cat, "locked", LOCK_FRAME, L["Verhindert Verschieben und Größenänderung."])
	B:Dropdown(cat, "showMode", HUD_EDIT_MODE_SETTING_DAMAGE_METER_VISIBILITY, {
		{ 1, ALWAYS },
		{ 2, L["Nur im Kampf"] },
		{ 3, L["Nur in Gruppe oder Schlachtzug"] },
	})
	B:Checkbox(cat, "showTitle", L["Titelleiste anzeigen"])
	B:Slider(cat, "scale", L["Skalierung"], 0.5, 2, 0.05, S.DecimalFormatter)
	B:Checkbox(cat, "autoVisible", L["Automatisch im sichtbaren Bereich halten"],
		L["Holt das Fenster nach dem Verschieben, beim Einloggen und bei Änderungen der Monitoranordnung auf einen Monitor zurück. Mit qnViewPort und Monitordaten zählen nur Bereiche, die wirklich auf einem Monitor zu sehen sind."])
	S.Button(layout, L["Fenster suchen"], L["In sichtbaren Bereich holen"],
		function() ns.Threat.MoveIntoVisible() end, L["Verschiebt das Fenster jetzt auf den nächsten sichtbaren Monitor (/qnm visible)."])

	S.Header(layout, L["Balken"])
	local link = B:Checkbox(cat, "linkDamageMeter", L["Einstellungen der Schadensanzeige übernehmen"],
		L["Übernimmt Stil, Balkenhöhe, Abstand, Textgröße, Symbole, Klassenfarben und Transparenz aus dem Bearbeitungsmodus der eingebauten Schadensanzeige."])
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
	S.Depends(B:Slider(cat, "barHeight", L["Balkenhöhe"], 8, 40, 1), link, NotLinked)
	S.Depends(B:Slider(cat, "barSpacing", L["Balkenabstand"], 0, 10, 1), link, NotLinked)
	S.Depends(B:Slider(cat, "fontSize", FONT_SIZE, 0, 24, 1, S.FontSizeFormatter, L["0 = Standardgröße der Schadensanzeige."]), link, NotLinked)
	S.Depends(B:Checkbox(cat, "showIcons", L["Klassensymbole anzeigen"]), link, NotLinked)
	S.Depends(B:Checkbox(cat, "classColors", CLASS_COLORS), link, NotLinked)
	S.Depends(B:Slider(cat, "bgAlpha", L["Deckkraft des Hintergrunds"], 0, 1, 0.05, S.FractionFormatter), link, NotLinked)
	B:Dropdown(cat, "texture", L["Balkentextur"], TextureEntries)
	B:Checkbox(cat, "showRank", L["Rang vor dem Namen"])
	B:Checkbox(cat, "useMyColor", L["Eigenen Balken rot färben"])
	B:Checkbox(cat, "useTankColor", L["Tank-Balken dunkelrot färben"])

	S.Header(layout, L["Inhalt"])
	B:Checkbox(cat, "showValue", L["Bedrohungswert anzeigen"])
	B:Checkbox(cat, "showPercent", L["Prozent anzeigen"])
	B:Checkbox(cat, "showTPS", L["Bedrohung pro Sekunde (TPS) anzeigen"],
		L["Zuwachs der Bedrohung pro Sekunde im TPS-Zeitfenster. Nur möglich, solange der Client lesbare Werte liefert."])
	B:Slider(cat, "tpsWindow", L["TPS-Zeitfenster (Sekunden)"], 3, 30, 1)
	B:Dropdown(cat, "percentMode", L["Prozentbasis"], {
		{ 1, L["Relativ zum Tank (100 % = Tank)"] },
		{ 2, L["Skaliert (100 % = Aggro)"] },
	}, L["Im eingeschränkten Modus (secret) ist nur 'skaliert' verfügbar."])
	B:Checkbox(cat, "showAggroBar", L["Balken 'Aggro ziehen' anzeigen"])
	B:Dropdown(cat, "aggroMode", L["Aggro-Schwelle"], {
		{ 1, L["Automatisch (Entfernung, sonst Klasse)"] },
		{ 2, L["Nahkampf (110 %)"] },
		{ 3, L["Fernkampf (130 %)"] },
	}, L["Automatisch: außerhalb des Kampfes nach der Entfernung zum Ziel, im Kampf nach der Klasse. Im Kampf gelten nur Krieger, Schurken und Paladine als Nahkampf; Druiden in Katzen- oder Bärengestalt und Verstärkungsschamanen bekommen dann 130 %. Für sie 'Nahkampf' wählen."])
	B:Checkbox(cat, "alwaysShowSelf", L["Eigenen Balken immer anzeigen"])
	B:Checkbox(cat, "showPets", DISPLAY_RAID_PETS)
	B:Checkbox(cat, "useFocus", L["Fokusziel bevorzugen"])
	B:Checkbox(cat, "ignorePlayerPets", L["Spielerbegleiter als Ziel ignorieren"])
	B:Slider(cat, "updateInterval", L["Aktualisierung (Sekunden)"], 0.05, 1, 0.05, S.DecimalFormatter)

	S.Header(layout, L["Warnung"])
	B:Checkbox(cat, "warnEnabled", L["Warnung bei hoher Bedrohung"],
		L["Nur möglich, solange der Client lesbare Werte liefert."])
	B:Slider(cat, "warnThreshold", L["Warnschwelle"], 50, 130, 5, S.PercentFormatter)
	B:Checkbox(cat, "warnSound", L["Ton abspielen"])
	B:Checkbox(cat, "warnFlash", L["Bildschirm aufblitzen"])
	B:Checkbox(cat, "warnMessage", L["Meldung einblenden"])
	B:Checkbox(cat, "warnSolo", L["Auch ohne Gruppe warnen"])
end

-- setzt ns.category und ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnMeter", Build)
end
