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
Check(text:find(L["Gegenstands-ID"] .. ": |cffffffff19019|r", 1, true) and text:find(L["Symbol-ID"] .. ": |cffffffff135349|r", 1, true), "Gegenstands- und Symbol-ID")
Check(not text:find(AUCTION_STACK_SIZE, 1, true), "Stapelgröße nur bei stapelbaren Gegenständen")
ProcessTooltip(GameTooltip, { type = Enum.TooltipDataType.Item, id = 2589, lines = { { type = Enum.TooltipDataLineType.ItemName, leftText = "Leinenstoff" } } })
Check(table.concat(GameTooltip:Texts(), "\n"):find(AUCTION_STACK_SIZE .. ": |cffffffff20|r", 1, true), "Stapelgröße 20")

SETTINGS.QNTOOLTIP_IDSWITHMODIFIER:SetValue(true)
ProcessTooltip(GameTooltip, { type = Enum.TooltipDataType.Item, id = 2589, lines = { { type = Enum.TooltipDataLineType.ItemName, leftText = "Leinenstoff" } } })
Check(not table.concat(GameTooltip:Texts(), "\n"):find(L["Gegenstands-ID"], 1, true), "IDs nur mit Zusatztaste")
SETTINGS.QNTOOLTIP_IDSWITHMODIFIER:SetValue(false)

ProcessTooltip(GameTooltip, { type = Enum.TooltipDataType.Spell, id = 133, lines = { { type = Enum.TooltipDataLineType.SpellName, leftText = "Feuerball" } } })
lines = GameTooltip:Texts()
Check(lines[1] == "|T136133:16:16:0:0:32:32:2:30:2:30|t Feuerball", "Zaubersymbol")
Check(table.concat(lines, "\n"):find(L["Zauber-ID"] .. ": |cffffffff133|r", 1, true), "Zauber-ID")
Check(bd._bdColor[4] == 0.8, "Zauber: eigener Hintergrund")

ProcessTooltip(ItemRefTooltip, { type = Enum.TooltipDataType.Quest, id = 783, lines = { { type = 0, leftText = "Eine Bedrohung" } } })
Check(table.concat(ItemRefTooltip:Texts(), "\n"):find(L["Quest-ID"] .. ": |cffffffff783|r", 1, true), "Quest-ID im ItemRefTooltip")
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
Check(p.rows[1].key == "friendIcon" and not p.rows[1].color:IsShown(), "Symbol ohne Farbauswahl")
local nameRow
for _, row in ipairs(p.rows) do if row.key == "name" then nameRow = row end end
Check(nameRow.color._text == L["Klassenfarbe"], "Farbauswahl zeigt Klassenfarbe")
-- eigene Farbe über den Farbwähler
for i, r in ipairs(nameRow.color._radios) do
	if r.text == L["Eigene Farbe …"] then nameRow.color:PickRadio(i) end
end
ColorPickerFrame._rgb = { 1, 0, 0 }
ColorPickerFrame._info.swatchFunc()
Check(tt.db.player.elements.name.color == "ff0000", "eigene Farbe gespeichert")
Check(nameRow.color._text == L["Eigene Farbe …"] and nameRow.swatch._color[1] == 1, "Anzeige der eigenen Farbe")
-- Format über das Eingabefenster
nameRow.format._scripts.OnClick(nameRow.format)
Check(LAST_POPUP.which == "QNTOOLTIP_FORMAT", "Formatfenster geöffnet")
StaticPopupDialogs.QNTOOLTIP_FORMAT.OnAccept({ GetEditBox = function() return { GetText = function() return "«%s»" end } end })
Check(tt.db.player.elements.name.format == "«%s»", "Format übernommen")
StaticPopupDialogs.QNTOOLTIP_FORMAT.OnAccept({ GetEditBox = function() return { GetText = function() return "%s%s" end } end })
Check(tt.db.player.elements.name.format == "«%s»", "ungültiges Format abgelehnt")
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

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
