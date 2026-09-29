-- Szenario 1: qnTooltip – Laden, Optionsseiten, Aussehen (eigener Hintergrund statt NineSlice),
-- Kopfzeilen von Spielern und NSC aus den Bausteinen (Reihenfolge, Farben, Formate, Filter,
-- Titel), Rahmen-/Hintergrundfarben, Zielzeile, "Anvisiert von", Lebensbalken, Rechtsklick-Hinweis.
EnableTooltips()
local L_ = function(s) return s end

QN_UNITS.mouseover = {
	name = "Arthas", realm = nil, class = "PALADIN", className = "Paladin", level = 60, raceName = "Mensch",
	factionGroup = "Alliance", factionName = FACTION_ALLIANCE, reaction = 5, isPlayer = true, guid = "Player-2",
	guild = { "Silberne Hand", "Offizier", 2, nil }, pvpName = "Ritter Arthas", afk = true,
	health = 3000, maxHealth = 4000, target = "player", raidIcon = 8,
}
QN_GUIDS["Player-2"] = "mouseover"

LoadAddon("qnCore")
local tt = LoadAddon("qnTooltip")
local L = tt.L
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(1)

---------------------------------------------------------------------------
-- Laden und Optionen
---------------------------------------------------------------------------
Check(tt.db and tt.db.bgFile == "rock", "Profil mit Vorgaben")
local cats = table.concat(LOG, ";")
for _, name in ipairs({ "qnTooltip" }) do
	Check(cats:find("Kategorie " .. name, 1, true), "Kategorie " .. name)
end
Check(SETTINGS.QNTOOLTIP_PLAYER_BORDERCOLOR and SETTINGS.QNTOOLTIP_NPC_ANCHORMODE, "Einstellungen für Spieler und NSC")
Check(tt.elementsUI.player and tt.elementsUI.npc, "Zeilen-Seiten angelegt")

---------------------------------------------------------------------------
-- Aussehen
---------------------------------------------------------------------------
local bd = GameTooltip.qnBackdrop
Check(bd and bd._backdrop and bd._backdrop.bgFile == "Interface\\FrameGeneral\\UI-Background-Rock", "Hintergrund Fels")
Check(bd._backdrop.edgeFile == "Interface\\Tooltips\\UI-Tooltip-Border" and bd._backdrop.edgeSize == 14, "Standardrahmen")
Check(bd._bdColor[4] == 0.7 and bd._bdBorder[1] == 0.6, "allgemeine Farben")
Check(ItemRefTooltip.qnBackdrop ~= nil, "ItemRefTooltip gestaltet")

SETTINGS.QNTOOLTIP_BORDERSTYLE:SetValue("angular")
Check(bd._backdrop.edgeFile == "Interface\\Buttons\\WHITE8X8" and bd._backdrop.edgeSize == 1, "eckiger Rahmen")
SETTINGS.QNTOOLTIP_BORDERSIZE:SetValue(3)
Check(bd._backdrop.edgeSize == 3 and bd._backdrop.insets.left == 3, "Rahmenbreite 3")
SETTINGS.QNTOOLTIP_BORDERSTYLE:SetValue("default")
SETTINGS.QNTOOLTIP_SCALE:SetValue(1.2)
Check(GameTooltip._scale == 1.2, "Scale")

---------------------------------------------------------------------------
-- Spieler
---------------------------------------------------------------------------
GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
GameTooltip:SetUnit("mouseover")
local lines = GameTooltip:Texts()
Check(GameTooltip.NineSlice._shown == false, "NineSlice nach SetBackdropStyle ausgeblendet")
-- Zeile 1: Zielmarkierung, Fraktions- und Klassensymbol, Titel, Name, Realm, AFK
Check(lines[1]:find("RaidTargetingIcon_8", 1, true) and lines[1]:find("SmallCircle-Alliance", 1, true), "Zeile 1: Symbole: " .. lines[1])
Check(lines[1]:find("|cffccffffRitter|r |cff%x%x%x%x%x%xArthas|r |cff00eeeeRealm|r") ~= nil, "Zeile 1: Titel vor Name, Realm: " .. lines[1])
Check(lines[1]:find("(" .. AFK .. ")", 1, true), "Zeile 1: AFK")
Check(lines[2] == "|cffff00ff<Silberne Hand>|r |cffcc88ff(Offizier)|r", "Zeile 2: Gilde und Rang: " .. lines[2])
Check(lines[3]:find("|cffffff0060|r", 1, true) and lines[3]:find("Mensch", 1, true) and lines[3]:find("Paladin", 1, true), "Zeile 3: Stufe, Volk, Klasse: " .. lines[3])
Check(lines[4]:find(STAT_AVERAGE_ITEM_LEVEL, 1, true) and lines[4]:find("??", 1, true), "Zeile 4: Gegenstandsstufe unbekannt: " .. lines[4])
Check(#QN_INSPECT == 1 and QN_INSPECT[1] == "mouseover", "Betrachten angefordert")
local all = table.concat(lines, "\n")
Check(not all:find(FACTION_ALLIANCE .. "\n", 1, true) and lines[5] ~= FACTION_ALLIANCE, "Fraktionszeile ersetzt")
Check(all:find(TARGET .. ": |cffff3333>>" .. strupper(YOU) .. "<<|r", 1, true), "Zielzeile: >>DU<<")
-- Farben: Rahmen und Hintergrund in Klassenfarbe (Stub: weiß), Hintergrund-Alpha 0.9
Check(bd._bdColor[4] == 0.9, "Hintergrund-Deckkraft der Spieler")

-- Gegenstandsstufe kommt an
QN_UNITS.mouseover.itemLevel = 62.6
FireEvent("INSPECT_READY", "Player-2")
Check(QN_INSPECT.cleared, "ClearInspectPlayer nach dem Lesen")
Check(GameTooltip:Texts()[4]:find("63", 1, true), "Tooltip mit Gegenstandsstufe neu aufgebaut: " .. GameTooltip:Texts()[4])

-- Zielwechsel: Zeile wird im OnUpdate nachgeführt
QN_UNITS.mouseover.target = nil
GameTooltip._scripts.OnUpdate(GameTooltip, 0.3)
local targetLine = tt.Left(GameTooltip, GameTooltip.qnTarget.index)
Check(targetLine._text == "", "Zielzeile leer ohne Ziel")
QN_UNITS.mouseover.target = "player"

-- Lebensbalken
local bar = GameTooltip.StatusBar
bar:Show()
bar:SetValue(0.75)
Check(bar.qnText._text == "3000 / 4000 (75%)", "Lebensbalken: Text " .. tostring(bar.qnText._text))
Check(bar._barColor and bar._barColor[1] == 1, "Lebensbalken: Klassenfarbe")
QN_UNITS.mouseover.dead = true
bar:SetValue(0)
Check(bar.qnText._text:find(DEAD, 1, true), "Lebensbalken: tot")
QN_UNITS.mouseover.dead = nil

-- Bausteine umstellen: Realm aus, Rang vor Gildenname, Format der Gilde, Filter
local el = tt.db.player.elements
el.realm.enable = false
-- zwei Stellen: dazwischen steht die abgeschaltete Rang-Nummer
Check(tt.MoveElement("player", "guildRank", -1) and tt.MoveElement("player", "guildRank", -1), "Rang zwei Stellen auf")
Check(not tt.MoveElement("player", "guildRank", -1), "erste Stelle: nicht weiter auf")
el.guildName.format = "[%s]"
el.statusAFK.filter = "inraid"
GameTooltip:SetUnit("mouseover")
lines = GameTooltip:Texts()
Check(not lines[1]:find("Realm", 1, true), "Realm abgeschaltet")
Check(not lines[1]:find(AFK, 1, true), "AFK nur im Schlachtzug (Filter)")
Check(lines[2] == "|cffcc88ff(Offizier)|r |cffff00ff[Silberne Hand]|r", "Rang vor Gilde, eigenes Format: " .. lines[2])
tt.SetElementLine("player", "className", 1)
GameTooltip:SetUnit("mouseover")
Check(GameTooltip:Texts()[1]:find("Paladin", 1, true) and not GameTooltip:Texts()[3]:find("Paladin", 1, true), "Klasse in Zeile 1 verschoben")
Check(el.className.order > el.statusDC.order, "ans Ende der Zeile")
-- Alt: alle Bausteine
IsAltKeyDown = function() return true end
GameTooltip:SetUnit("mouseover")
Check(GameTooltip:Texts()[1]:find("Realm", 1, true) and GameTooltip:Texts()[1]:find(AFK, 1, true), "Alt zeigt alle Bausteine")
IsAltKeyDown = function() return false end
-- ungültige Formate werden nicht übernommen
Check(not tt.UnitData.ValidFormat("%s %s", "text") and not tt.UnitData.ValidFormat("%d", "text")
	and tt.UnitData.ValidFormat("%d%%", "number") and not tt.UnitData.ValidFormat("50%", "text"), "Formatprüfung")
el.guildName.format = "%d"
GameTooltip:SetUnit("mouseover")
Check(GameTooltip:Texts()[2]:find("<Silberne Hand>", 1, true), "ungültiges Format: Vorgabe")

---------------------------------------------------------------------------
-- NSC mit Titel
---------------------------------------------------------------------------
QN_UNITS.mouseover = {
	name = "Gastwirtin Allison", class = "WARRIOR", className = "Krieger", level = 30, isPlayer = false,
	guid = "Creature-1", title = "Gastwirtin", reaction = 5, classif = "elite", creature = "Humanoid",
	health = 100, maxHealth = 100, extra = { "Quest-Ziel 0/1" }, pvp = true,
}
QN_GUIDS["Creature-1"] = "mouseover"
GameTooltip:SetUnit("mouseover")
lines = GameTooltip:Texts()
Check(lines[1] == "Gastwirtin Allison", "NSC Zeile 1: Name ohne Farbe (Blizzards Zeilenfarbe): " .. lines[1])
Check(lines[2] == "|cff99e8e8<Gastwirtin>|r", "NSC-Titel umformatiert: " .. lines[2])
Check(lines[3]:find("(" .. ELITE .. ")", 1, true) and lines[3]:find("Humanoid", 1, true), "NSC Zeile 3: Elite, Kreaturtyp: " .. lines[3])
Check(not lines[3]:find(REPUTATION, 1, true) and not lines[3]:find(FACTION_STANDING_LABEL5, 1, true), "Ruf nur ab wohlwollend")
Check(lines[4] == "" and lines[5] == "Quest-Ziel 0/1", "PvP-Zeile geleert, Quest-Ziel bleibt")
Check(bd._bdColor[1] == 0 and bd._bdColor[4] == 0.9, "NSC: allgemeiner Hintergrund mit Deckkraft 0.9")
Check(bd._bdBorder[1] == FACTION_BAR_COLORS[5].r, "NSC: Rahmen in Reaktionsfarbe")

---------------------------------------------------------------------------
-- Anvisiert von (Gruppe)
---------------------------------------------------------------------------
QN_GROUP = { "player", "party1" }
QN_UNITS.party1 = { name = "Jaina", class = "MAGE", className = "Magier", isPlayer = true, guid = "Player-3", target = "mouseover", role = "DAMAGER" }
GameTooltip:SetUnit("mouseover")
all = table.concat(GameTooltip:Texts(), "\n")
Check(all:find(L["Targeted by:"], 1, true) and all:find("Jaina", 1, true), "Anvisiert von: Jaina")
QN_GROUP = nil

---------------------------------------------------------------------------
-- Rechtsklick-Hinweis an Einheitenrahmen
---------------------------------------------------------------------------
GameTooltip:SetUnit("mouseover")
GameTooltip_AddBlankLineToTooltip(GameTooltip)
GameTooltip_AddInstructionLine(GameTooltip, UNIT_POPUP_RIGHT_CLICK)
lines = GameTooltip:Texts()
Check(lines[#lines] == "" and lines[#lines - 1] == "", "Rechtsklick-Hinweis und Leerzeile entfernt")

---------------------------------------------------------------------------
-- Leeren setzt die Farben zurück
---------------------------------------------------------------------------
GameTooltip:ClearLines()
Check(bd._bdColor[4] == 0.7 and bd._bdBorder[1] == 0.6, "nach dem Leeren wieder allgemeine Farben")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
