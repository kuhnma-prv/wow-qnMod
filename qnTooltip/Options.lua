-- qnTooltip: Optionen im Blizzard-Einstellungsfenster (Settings-API).
-- Hauptseite: Aussehen und Schriften; Unterseiten: Position, Lebensbalken, Spieler, NSC,
-- Gegenstände & Zauber sowie die Zeilen-Bausteine (ElementsPage.lua).
-- Die Einstellungen gehören zum aktiven Profil (qnCore); die Werte von Spielern und NSC liegen in
-- ns.db.player bzw. ns.db.npc.

local _, ns = ...
local L = ns.L
local S = qnCore.Settings

local function Apply()
	ns.Apply()
end

local function Builders()
	local B = S.New({ store = ns.store, prefix = "QNTOOLTIP_", apply = Apply })
	local function Unit(kind)
		return S.New({
			store = ns.store,
			prefix = "QNTOOLTIP_" .. kind:upper() .. "_",
			source = function() return ns.db[kind] end,
			defaults = ns.defaults[kind],
		})
	end
	return B, Unit("player"), Unit("npc")
end

local function FontOptions(B, cat, prefix, title)
	B:Dropdown(cat, prefix .. "Font", L["Schriftart: %s"]:format(title), ns.Style.FontEntries)
	B:Slider(cat, prefix .. "Size", L["Schriftgröße: %s"]:format(title), 0, 24, 1, S.FontSizeFormatter,
		L["0 = Blizzards Größe."])
	B:Dropdown(cat, prefix .. "Flag", L["Umriss: %s"]:format(title), ns.Style.FlagEntries)
end

local function MainPage(B, cat, layout)
	S.Header(layout, L["Aussehen"])
	B:Slider(cat, "scale", L["Skalierung"], 0.5, 2, 0.05, S.DecimalFormatter)
	B:Dropdown(cat, "bgFile", BACKGROUND, ns.Style.BackgroundEntries)
	B:Color(cat, "bgColor", L["Hintergrundfarbe"], nil, nil, L["Deckkraft des Hintergrunds"])
	B:Dropdown(cat, "borderStyle", L["Rahmen"], {
		{ "default", DEFAULT },
		{ "angular", L["Eckig"] },
		{ "none", NONE },
	})
	B:Slider(cat, "borderSize", L["Rahmenbreite (eckig)"], 1, 8, 1)
	B:Color(cat, "borderColor", L["Rahmenfarbe"], nil, nil, L["Deckkraft des Rahmens"])
	B:Checkbox(cat, "mask", L["Heller Verlauf über der Kopfzeile"])

	S.Header(layout, L["Schriften"])
	FontOptions(B, cat, "header", L["Kopfzeile"])
	FontOptions(B, cat, "body", L["Textzeilen"])

	S.Header(layout, L["Weiteres"])
	B:Checkbox(cat, "moreTooltips", L["Auch Link-, Vergleichs- und Freundes-Tooltips gestalten"],
		L["Beim Abschalten behalten diese Tooltips ihr Aussehen bis zum nächsten /reload."])
	B:Checkbox(cat, "hideUnitFrameHint", L["Hinweis zum Rechtsklick an Einheitenrahmen entfernen"])
	B:Checkbox(cat, "chatHover", L["Tooltip beim Überfahren von Chat-Links"])
	B:Checkbox(cat, "modifierShowsAll", L["Mit Alt oder Strg alle Bausteine zeigen"],
		L["Solange Alt oder Strg gedrückt ist, zeigen Einheiten-Tooltips auch abgeschaltete und gefilterte Bausteine."])
end

local function PositionPage(B, BP, BN, category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Position"])
	S.Header(layout, L["Position"])
	B:Dropdown(cat, "anchorMode", L["Position"], ns.Anchor.ModeEntries(false),
		L["Nur wenn hier nicht 'Blizzard-Standard' gewählt ist, setzt qnTooltip den Tooltip an eine andere Stelle."])
	B:Dropdown(cat, "anchorPoint", L["Fester Punkt: Ecke"], ns.Anchor.PointEntries)
	B:Slider(cat, "anchorX", L["Fester Punkt: Abstand X"], -1000, 1000, 1)
	B:Slider(cat, "anchorY", L["Fester Punkt: Abstand Y"], -1000, 1000, 1)
	BP:Dropdown(cat, "anchorMode", L["Position für Spieler"], ns.Anchor.ModeEntries(true))
	BN:Dropdown(cat, "anchorMode", L["Position für NSC"], ns.Anchor.ModeEntries(true))
	B:Checkbox(cat, "returnInCombat", L["Im Kampf an Blizzards Stelle"])
	B:Checkbox(cat, "returnOnUnitFrame", L["Über Einheitenrahmen an Blizzards Stelle"])

	S.Header(layout, COMBAT)
	B:Checkbox(cat, "hideInCombat", L["Tooltip im Kampf ausblenden"],
		L["Gilt für Tooltips an Blizzards Standardstelle (Einheiten in der Welt, Einheitenrahmen, Aktionsleisten)."])
	B:Dropdown(cat, "combatModifier", L["Mit dieser Taste trotzdem zeigen"], ns.Anchor.ModifierEntries)
end

local function BarPage(B, category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Lebensbalken"])
	S.Header(layout, L["Lebensbalken"])
	B:Checkbox(cat, "barHide", L["Lebensbalken ausblenden"])
	B:Slider(cat, "barHeight", L["Höhe"], 1, 20, 1)
	B:Dropdown(cat, "barPosition", L["Lage"], {
		{ "bottom", L["Auf dem unteren Rand"] },
		{ "top", L["Auf dem oberen Rand"] },
		{ "default", L["Unter dem Tooltip (Blizzard)"] },
	})
	B:Slider(cat, "barOffsetX", L["Seitlicher Abstand"], 0, 30, 1, S.FontSizeFormatter,
		L["0 = passend zum Rahmen."])
	B:Dropdown(cat, "barTexture", L["Textur"], ns.StatusBar.TextureEntries)
	B:Dropdown(cat, "barColor", COLOR, {
		{ "default", L["Blizzard (grün)"] },
		{ "auto", L["Klassen- bzw. Auswahlfarbe"] },
		{ "smooth", L["Nach Gesundheit (grün – gelb – rot)"] },
	})
	S.Header(layout, L["Text"])
	B:Checkbox(cat, "barText", L["Lebenspunkte anzeigen"])
	B:Checkbox(cat, "barPercent", L["Prozent anzeigen"])
	FontOptions(B, cat, "bar", L["Lebensbalken"])
end

local function UnitPage(BU, category, kind, title)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, title)
	S.Header(layout, title)
	BU:Dropdown(cat, "borderColor", L["Rahmenfarbe"], ns.UnitData.ColorEntries)
	BU:Dropdown(cat, "bgColor", L["Hintergrundfarbe"], ns.UnitData.ColorEntries,
		L["'Standard' nimmt die allgemeine Hintergrundfarbe."])
	BU:Slider(cat, "bgAlpha", L["Deckkraft des Hintergrunds"], 0, 1, 0.05, S.FractionFormatter)
	BU:Checkbox(cat, "showTarget", L["Ziel anzeigen"])
	BU:Checkbox(cat, "showTargetBy", L["'Anvisiert von' anzeigen"],
		L["Gruppen- und Schlachtzugsmitglieder, die die Einheit anvisieren."])
	BU:Checkbox(cat, "showModel", L["3D-Modell anzeigen"], L["Mit gedrückter Strg- oder Alt-Taste dreht sich das Modell."])
	BU:Checkbox(cat, "grayDead", L["Tote grau darstellen"])
	BU:Checkbox(cat, "bigFaction", L["Großes Fraktionswappen"])
	S.Button(layout, L["Zeilen"], L["Zeilen bearbeiten …"], function()
		ns.OpenElementsPage(kind)
	end, L["Bausteine der Kopfzeilen: an/aus, Zeile, Reihenfolge, Farbe, Format und Filter."])
	ns.InitElementsPage(category, kind, L["Zeilen: %s"]:format(title))
end

local function ItemsPage(B, category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Gegenstände & Zauber"])
	S.Header(layout, ITEMS)
	B:Checkbox(cat, "itemBorder", L["Rahmen in der Farbe der Qualität"])
	B:Checkbox(cat, "itemIcon", L["Symbol vor dem Namen"])
	B:Checkbox(cat, "itemId", L["Gegenstands-ID"])
	B:Checkbox(cat, "itemIconId", L["Symbol-ID"])
	B:Checkbox(cat, "itemMaxStack", AUCTION_STACK_SIZE)
	S.Header(layout, SPELLS)
	B:Checkbox(cat, "spellIcon", L["Symbol vor dem Namen"])
	B:Checkbox(cat, "spellId", L["Zauber-ID"])
	B:Checkbox(cat, "spellIconId", L["Symbol-ID"])
	B:Color(cat, "spellBgColor", L["Hintergrundfarbe"], nil, nil, L["Deckkraft des Hintergrunds"])
	B:Color(cat, "spellBorderColor", L["Rahmenfarbe"], nil, nil, L["Deckkraft des Rahmens"])
	S.Header(layout, L["Quests"])
	B:Checkbox(cat, "questBorder", L["Rahmen in der Farbe der Schwierigkeit"])
	B:Checkbox(cat, "questId", L["Quest-ID"])
	S.Header(layout, L["IDs"])
	B:Checkbox(cat, "idsWithModifier", L["IDs nur mit gedrückter Umschalt-, Strg- oder Alt-Taste"])
end

local function Build(category, layout)
	local B, BP, BN = Builders()
	MainPage(B, category, layout)
	PositionPage(B, BP, BN, category)
	BarPage(B, category)
	UnitPage(BP, category, "player", PLAYER)
	UnitPage(BN, category, "npc", L["NSC"])
	ItemsPage(B, category)
end

-- setzt ns.category und ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnTooltip", Build)
end
