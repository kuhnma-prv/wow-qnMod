-- Szenario 3: qnTooltip – Position nur auf Wunsch (Vorgabe: Blizzard), Mauszeiger/fester Punkt,
-- eigene Art je Einheitenart, im Kampf zurück an Blizzards Stelle, im Kampf ausblenden mit
-- Zusatztaste, IDs und Qualitätsrahmen, Zauber, Chat-Links, Seite "Zeilen", Profilwechsel.
EnableTooltips()
QN_UNITS.mouseover = { name = "Thrall", class = "SHAMAN", className = "Schamane", level = 60, isPlayer = true,
	guid = "Player-5", factionGroup = "Horde", factionName = FACTION_HORDE }
QN_GUIDS["Player-5"] = "mouseover"
QN_ITEMS = { [19019] = { name = "Donnerzorn", quality = 5, icon = 135349, stack = 1 }, [2589] = { name = "Leinenstoff", quality = 1, icon = 132889, stack = 20 } }

LoadAddon("qnCore")
local tt = LoadAddon("qnTooltip")
local L = tt.L
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(1)

local function Anchor()
	GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
	return GameTooltip._anchor[1], GameTooltip._points and GameTooltip._points[#GameTooltip._points]
end

---------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------
local anchor, point = Anchor()
Check(anchor == "ANCHOR_NONE" and point[1] == "BOTTOMRIGHT" and point[4] == -13, "Vorgabe: Blizzards Stelle unverändert")

SETTINGS.QNTOOLTIP_ANCHORMODE:SetValue("cursor")
anchor = Anchor()
Check(anchor == "ANCHOR_CURSOR", "am Mauszeiger")
QN_COMBAT = true
anchor = Anchor()
Check(anchor == "ANCHOR_NONE", "im Kampf an Blizzards Stelle")
QN_COMBAT = false

SETTINGS.QNTOOLTIP_ANCHORMODE:SetValue("static")
SETTINGS.QNTOOLTIP_ANCHORPOINT:SetValue("TOPLEFT")
SETTINGS.QNTOOLTIP_ANCHORX:SetValue(20)
SETTINGS.QNTOOLTIP_ANCHORY:SetValue(-30)
anchor, point = Anchor()
Check(point[1] == "TOPLEFT" and point[3] == "TOPLEFT" and point[4] == 20 and point[5] == -30, "fester Punkt")

SETTINGS.QNTOOLTIP_PLAYER_ANCHORMODE:SetValue("cursorRight")
anchor = Anchor()
Check(anchor == "ANCHOR_CURSOR_RIGHT" and GameTooltip._anchor[2] == 36, "eigene Art für Spieler")
SETTINGS.QNTOOLTIP_RETURNONUNITFRAME:SetValue(true)
QN_FOCUS = CreateFrame("Button")
QN_FOCUS.unit = "mouseover"
anchor = Anchor()
Check(anchor == "ANCHOR_NONE", "über Einheitenrahmen an Blizzards Stelle")
QN_FOCUS = nil

-- im Kampf ausblenden, mit Umschalt trotzdem zeigen
SETTINGS.QNTOOLTIP_RETURNINCOMBAT:SetValue(false)
SETTINGS.QNTOOLTIP_HIDEINCOMBAT:SetValue(true)
SETTINGS.QNTOOLTIP_COMBATMODIFIER:SetValue("shift")
QN_COMBAT = true
GameTooltip:Hide()
Anchor()
GameTooltip:SetUnit("mouseover")
Check(not GameTooltip:IsShown(), "im Kampf ausgeblendet")
IsShiftKeyDown = function() return true end
FireEvent("MODIFIER_STATE_CHANGED", "LSHIFT", 1)
Check(GameTooltip:IsShown() and GameTooltip:Texts()[1]:find("Thrall", 1, true), "Umschalt zeigt den Tooltip")
IsShiftKeyDown = function() return false end
FireEvent("MODIFIER_STATE_CHANGED", "LSHIFT", 0)
Check(not GameTooltip:IsShown(), "Loslassen blendet wieder aus")
-- nicht an der Standardstelle (eigener Besitzer): bleibt sichtbar
GameTooltip:SetOwner(UIParent, "ANCHOR_RIGHT")
GameTooltip:SetUnit("mouseover")
Check(GameTooltip:IsShown(), "eigener Anker bleibt im Kampf sichtbar")
QN_COMBAT = false
SETTINGS.QNTOOLTIP_HIDEINCOMBAT:SetValue(false)

---------------------------------------------------------------------------
-- Gegenstände und Zauber
---------------------------------------------------------------------------
local bd = GameTooltip.qnBackdrop
GameTooltip:SetOwner(UIParent, "ANCHOR_RIGHT")
ProcessTooltip(GameTooltip, { type = Enum.TooltipDataType.Item, id = 19019, lines = {
	{ type = Enum.TooltipDataLineType.ItemName, leftText = "Donnerzorn" }, { type = 0, leftText = "Einhand" } } })
local lines = GameTooltip:Texts()
Check(lines[1] == "|T135349:16:16:0:0:32:32:2:30:2:30|t Donnerzorn", "Symbol vor dem Namen: " .. lines[1])
Check(bd._bdBorder[1] == 0.64 and bd._bdBorder[4] == 0.8, "Rahmen in Qualitätsfarbe")
local text = table.concat(lines, "\n")
Check(text:find(L["Item ID"] .. ": |cffffffff19019|r", 1, true) and text:find(L["Icon ID"] .. ": |cffffffff135349|r", 1, true), "Gegenstands- und Symbol-ID")
Check(not text:find(AUCTION_STACK_SIZE, 1, true), "Stapelgröße nur bei stapelbaren Gegenständen")
ProcessTooltip(GameTooltip, { type = Enum.TooltipDataType.Item, id = 2589, lines = { { type = Enum.TooltipDataLineType.ItemName, leftText = "Leinenstoff" } } })
Check(table.concat(GameTooltip:Texts(), "\n"):find(AUCTION_STACK_SIZE .. ": |cffffffff20|r", 1, true), "Stapelgröße 20")

SETTINGS.QNTOOLTIP_IDSWITHMODIFIER:SetValue(true)
ProcessTooltip(GameTooltip, { type = Enum.TooltipDataType.Item, id = 2589, lines = { { type = Enum.TooltipDataLineType.ItemName, leftText = "Leinenstoff" } } })
Check(not table.concat(GameTooltip:Texts(), "\n"):find(L["Item ID"], 1, true), "IDs nur mit Zusatztaste")
SETTINGS.QNTOOLTIP_IDSWITHMODIFIER:SetValue(false)

ProcessTooltip(GameTooltip, { type = Enum.TooltipDataType.Spell, id = 133, lines = { { type = Enum.TooltipDataLineType.SpellName, leftText = "Feuerball" } } })
lines = GameTooltip:Texts()
Check(lines[1] == "|T136133:16:16:0:0:32:32:2:30:2:30|t Feuerball", "Zaubersymbol")
Check(table.concat(lines, "\n"):find(L["Spell ID"] .. ": |cffffffff133|r", 1, true), "Spell ID")
Check(bd._bdColor[4] == 0.8, "Zauber: eigener Hintergrund")

ProcessTooltip(ItemRefTooltip, { type = Enum.TooltipDataType.Quest, id = 783, lines = { { type = 0, leftText = "Eine Bedrohung" } } })
Check(table.concat(ItemRefTooltip:Texts(), "\n"):find(L["Quest ID"] .. ": |cffffffff783|r", 1, true), "Quest-ID im ItemRefTooltip")
Check(ItemRefTooltip.qnBackdrop._bdBorder[1] == 0.25, "Quest: Rahmen in Schwierigkeitsfarbe")

---------------------------------------------------------------------------
-- Chat-Links
---------------------------------------------------------------------------
ChatFrame1._scripts.OnHyperlinkEnter(ChatFrame1, "item:19019:0:0:0", "[Donnerzorn]")
Check(GameTooltip._link == "item:19019:0:0:0" and GameTooltip._anchor[1] == "ANCHOR_CURSOR", "Chat-Link: Tooltip am Mauszeiger")
ChatFrame1._scripts.OnHyperlinkLeave(ChatFrame1)
Check(not GameTooltip:IsShown(), "Chat-Link verlassen: ausgeblendet")
GameTooltip._link = nil
ChatFrame1._scripts.OnHyperlinkEnter(ChatFrame1, "player:Thrall", "[Thrall]")
Check(GameTooltip._link == nil, "Spieler-Link ohne Tooltip")

---------------------------------------------------------------------------
-- Seite "Zeilen"
---------------------------------------------------------------------------
local p = tt.elementsUI.player
p.page:Show()
Check(#p.rows == #tt.ELEMENTS.player, "eine Zeile je Baustein")
local ed = p.editor
-- Dialog erst über den Stift; Symbol: nur Filter
Check(not ed:IsShown() and not p.rows[1].sel:IsShown(), "Dialog anfangs geschlossen")
p.rows[1].edit._scripts.OnClick(p.rows[1].edit)
Check(ed:IsShown() and p.selected == "friendIcon" and p.rows[1].sel:IsShown(), "Stift öffnet den Dialog, Zeile markiert")
Check(not ed.color:IsShown() and not ed.format:IsShown() and ed.iconNote:IsShown() and ed.filter:IsShown(),
	"Symbol: nur Filter, Hinweis statt Farbe und Format")
Check(p.rows[1].preview._text and p.rows[1].preview._text:find("|A:", 1, true), "Symbol: Vorschau zeigt ein Beispielsymbol")
-- Pfeile: gesperrt am Anfang bzw. Ende einer Tooltip-Zeile
local r1, r2 = p.rows[1], p.rows[2]
Check(not r1.up:IsEnabled() and r1.down:IsEnabled() and r2.up:IsEnabled(), "Pfeile: erster Baustein nicht nach oben")
local lastOfLine1
for i, row in ipairs(p.rows) do
	if tt.db.player.elements[row.key] and tt.db.player.elements[row.key].line == 1 then lastOfLine1 = row end
end
Check(lastOfLine1 and not lastOfLine1.down:IsEnabled(), "Pfeile: letzter Baustein der Zeile nicht nach unten")
r1.down._scripts.OnClick(r1.down)
Check(p.rows[2].key == "friendIcon", "Pfeil ab verschiebt den Baustein")
p.rows[2].up._scripts.OnClick(p.rows[2].up)
Check(p.rows[1].key == "friendIcon", "Pfeil auf verschiebt zurück")
-- Stift einer anderen Zeile wechselt den Baustein im offenen Dialog
local nameRow
for _, row in ipairs(p.rows) do if row.key == "name" then nameRow = row end end
nameRow.edit._scripts.OnClick(nameRow.edit)
Check(p.selected == "name" and nameRow.sel:IsShown() and not p.rows[1].sel:IsShown(), "Stift wechselt den Baustein")
Check(ed.TitleContainer.TitleText._text == L["Element: %s"]:format(NAME) and ed.color:IsShown() and not ed.iconNote:IsShown(), "Dialog für Text")
Check(ed.color._text == L["Class Color"], "Farbauswahl zeigt Klassenfarbe")
-- eigene Farbe über den Farbwähler
for i, r in ipairs(ed.color._radios) do
	if r.text == L["Custom color …"] then ed.color:PickRadio(i) end
end
ColorPickerFrame._rgb = { 1, 0, 0 }
ColorPickerFrame._info.swatchFunc()
Check(tt.db.player.elements.name.color == "ff0000", "eigene Farbe gespeichert")
Check(ed.color._text == L["Custom color …"] and ed.swatch._color[1] == 1, "Anzeige der eigenen Farbe")
Check(nameRow.preview._text:find("|cffff0000", 1, true), "Vorschau der Zeile in der eigenen Farbe")
-- Abbrechen im Farbwähler: vorheriger Wert zurück, auch eine Farbfunktion
for i, r in ipairs(ed.color._radios) do
	if r.text == L["Class Color"] then ed.color:PickRadio(i) end
end
for i, r in ipairs(ed.color._radios) do
	if r.text == L["Custom color …"] then ed.color:PickRadio(i) end
end
ColorPickerFrame._rgb = { 0, 1, 0 }
ColorPickerFrame._info.swatchFunc()
Check(tt.db.player.elements.name.color == "00ff00", "Farbwähler: Farbe beim Ziehen übernommen")
ColorPickerFrame:Cancel()
Check(tt.db.player.elements.name.color == "class" and ed.color._text == L["Class Color"], "Abbrechen: Klassenfarbe zurück")
for i, r in ipairs(ed.color._radios) do
	if r.text == L["Custom color …"] then ed.color:PickRadio(i) end
end
ColorPickerFrame._rgb = { 1, 0, 0 }
ColorPickerFrame._info.swatchFunc()
-- Format im Bearbeiten-Bereich: Vorschau beim Tippen, Übernehmen mit Enter
ed.format:SetText("«%s»")
ed.format._scripts.OnTextChanged(ed.format)
Check(ed.result._text:find("«", 1, true) and tt.db.player.elements.name.format == "%s", "Vorschau beim Tippen, noch nicht gespeichert")
ed.format._scripts.OnEnterPressed(ed.format)
Check(tt.db.player.elements.name.format == "«%s»", "Format übernommen")
Check(nameRow.preview._text:find("«", 1, true), "Vorschau der Zeile mit neuem Format")
ed.format:SetText("%s%s")
ed.format._scripts.OnTextChanged(ed.format)
Check(ed.result._text:find("|cffff4040", 1, true), "ungültiges Format rot markiert")
ed.format._scripts.OnEnterPressed(ed.format)
Check(tt.db.player.elements.name.format == "«%s»" and ed.format:GetText() == "«%s»", "ungültiges Format abgelehnt, Eingabe zurückgesetzt")
-- Beispiel anklicken
Check(ed.examples[2].fmt == "<%s>" and ed.examples[2]._text == "<%s>" and ed.examples[2].result._text:find("<", 1, true),
	"Beispiel: Knopf mit Format, dahinter das Ergebnis")
ed.examples[2]._scripts.OnClick(ed.examples[2])
Check(tt.db.player.elements.name.format == "<%s>", "Beispiel übernommen")
-- Zahlenbaustein: eigene Hilfe und Beispiele mit %d
local speedRow
for _, row in ipairs(p.rows) do if row.key == "moveSpeed" then speedRow = row end end
speedRow.edit._scripts.OnClick(speedRow.edit)
Check(ed.examples[2].fmt == "%d%%" and ed.examples[2].result._text:find("100%", 1, true), "Zahl: Beispiel %d%% mit Beispielwert")
Check(ed.help._text:find("%d", 1, true), "Zahl: Hilfe nennt %d")
Check(tt.db.player.elements.name.format == "<%s>", "Wechsel auf anderen Baustein: bisheriger mit OK übernommen")
-- Abbrechen: offene Eingabe verworfen, Markierung weg
ed.format:SetText("%d km/h")
ed.cancel._scripts.OnClick(ed.cancel)
Check(not ed:IsShown() and tt.db.player.elements.moveSpeed.format == "%d%%" and not speedRow.sel:IsShown(), "Abbrechen: Eingabe verworfen, Dialog zu")
-- OK: offene Eingabe übernommen
speedRow.edit._scripts.OnClick(speedRow.edit)
ed.format:SetText("%d km/h")
ed.ok._scripts.OnClick(ed.ok)
Check(not ed:IsShown() and tt.db.player.elements.moveSpeed.format == "%d km/h", "OK: Eingabe übernommen")
-- Abbrechen stellt alles wieder her, auch schon übernommene Änderungen (Farbe, Format, Filter)
nameRow.edit._scripts.OnClick(nameRow.edit)
for i, r in ipairs(ed.color._radios) do
	if r.text == L["Faction Color"] then ed.color:PickRadio(i) end
end
ed.format:SetText("[%s]")
ed.format._scripts.OnEnterPressed(ed.format)
ed.filter:PickRadio(2)
Check(tt.db.player.elements.name.color == "faction" and tt.db.player.elements.name.format == "[%s]"
	and tt.db.player.elements.name.filter ~= "none" and nameRow.preview._text:find("[", 1, true), "Änderungen wirken schon auf die Vorschau")
ed.cancel._scripts.OnClick(ed.cancel)
local n = tt.db.player.elements.name
Check(n.color == "ff0000" and n.format == "<%s>" and n.filter == "none" and nameRow.preview._text:find("<", 1, true),
	"Abbrechen: Farbe, Format und Filter wie vor dem Öffnen")
-- Schließen auf anderem Weg (X, Einstellungsfenster zu) = Abbrechen
nameRow.edit._scripts.OnClick(nameRow.edit)
ed.format:SetText("[%s]")
ed.format._scripts.OnEnterPressed(ed.format)
ed:Hide()
Check(tt.db.player.elements.name.format == "<%s>", "Schließen ohne OK: wie Abbrechen")

-- dieselbe Seite für NSC
local pn = tt.elementsUI.npc
pn.page:Show()
local npcName
for _, row in ipairs(pn.rows) do if row.key == "name" then npcName = row end end
Check(npcName and npcName.edit and pn.editor ~= ed, "NSC: Zeilen mit Stift, eigener Dialog")
npcName.edit._scripts.OnClick(npcName.edit)
Check(pn.editor:IsShown() and pn.editor.ok and pn.editor.cancel, "NSC: Dialog mit OK und Abbrechen")
pn.editor.format:SetText("«%s»")
pn.editor.ok._scripts.OnClick(pn.editor.ok)
Check(tt.db.npc.elements.name.format == "«%s»" and tt.db.player.elements.name.format == "<%s>", "NSC: OK übernimmt nur für NSC")
npcName.edit._scripts.OnClick(npcName.edit)
pn.editor.format:SetText("%s!")
pn.editor.cancel._scripts.OnClick(pn.editor.cancel)
Check(tt.db.npc.elements.name.format == "«%s»", "NSC: Abbrechen verwirft")
pn.page:Hide()
-- Zeile über das Dropdown
nameRow.line:PickRadio(3)
Check(tt.db.player.elements.name.line == 3, "Zeile gewechselt")
-- zurücksetzen
StaticPopupDialogs.QNTOOLTIP_ELEMENTS_RESET.OnAccept(nil, "player")
Check(tt.db.player.elements.name.line == 1 and tt.db.player.elements.name.color == "class", "Bausteine zurückgesetzt")

---------------------------------------------------------------------------
-- Profilwechsel
---------------------------------------------------------------------------
SETTINGS.QNTOOLTIP_BGFILE:SetValue("marble")
Check(bd._backdrop.bgFile:find("Marble", 1, true), "Hintergrund Marmor")
SetEditModeLayout(3)
Check(tt.db.bgFile == "marble", "neues Layout: Kopie des bisherigen Profils")
SETTINGS.QNTOOLTIP_BGFILE:SetValue("dark")
SetEditModeLayout(1)
Check(bd._backdrop.bgFile:find("Marble", 1, true), "zurück: Profil 1 angewendet")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
