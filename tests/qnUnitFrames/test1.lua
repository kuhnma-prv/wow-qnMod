-- Szenario 1: qnUnitFrames – Klickzauber auf Blizzards Gruppen- und Schlachtzugsrahmen:
-- Attribute je Belegung, Rahmenauswahl, Kampfsperre, neue Rahmen, Profile, Bereinigung, Tooltip,
-- Optionsseite "Klickbelegung"

-- Profil der letzten Sitzung mit kaputten Einträgen
qnCoreCharDB = { layout = "preset:1" }
qnUnitFramesDB = { global = {}, profiles = {
	["preset:1"] = { bindings = {
		WARRIOR = { ["shift-1"] = { type = "bogus" }, ["x"] = { type = "spell" }, ["foo-1"] = { type = "focus" }, ["shift-7"] = { type = "focus" },
			["ctrl-3"] = { type = "focus" }, ["alt-2"] = { type = "spell", value = 17 } },
		MAGE = 5,
	} },
} }

-- Rahmen, wie Blizzard sie anlegt (CompactUnitFrameTemplate erbt SecureUnitButtonTemplate)
local function UnitButton(name)
	local f = CreateFrame("Button", name, UIParent, "CompactUnitFrameTemplate")
	f._protected = true
	return f
end
local partyCUF = UnitButton("CompactPartyFrameMember1")
local partyPetCUF = UnitButton("CompactPartyFramePet1")
local raid1 = UnitButton("CompactRaidFrame1")
local raid2 = UnitButton("CompactRaidFrame2")
-- Begleiter im Schlachtzug (GetUnitFrame(unit, "pet")); erreichbar, sobald CompactRaidFrame3/4 unten entstehen
local raidPet = UnitButton("CompactRaidFrame5")
raidPet.frameType = "pet"
local group = UnitButton("CompactRaidGroup2Member3")
local plate = UnitButton("NamePlate1UnitFrame")
local party = UnitButton(nil)
party.PetFrame = UnitButton(nil)
QN_PARTY_FRAMES = { party }

-- Tooltip-Rückruf abfangen
local tooltipFn
TooltipDataProcessor.AddTooltipPostCall = function(kind, fn) if kind == Enum.TooltipDataType.Unit then tooltipFn = fn end end
-- Canvas-Seite abfangen
local pages = {}
local origCanvas = Settings.RegisterCanvasLayoutSubcategory
function Settings.RegisterCanvasLayoutSubcategory(p, f, n) pages[n] = f return origCanvas(p, f, n) end

QN_SPELLBOOK = {
	{ items = { { name = "Blitzheilung" }, { name = "Heilen" }, { name = "Heilen" }, { name = "Meditation", isPassive = true } } },
	{ info = { offSpecID = 7 }, items = { { name = "Nebenspezialisierung" } } },
	{ items = { { name = "Erneuerung" }, { name = "Zukunft", itemType = Enum.SpellBookItemType.FutureSpell } } },
}

LoadAddon("qnCore")
local uf = LoadAddon("qnUnitFrames")
local L = uf.L
local printed = {}
local oldPrint = uf.Print
uf.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end

local function A(f, name) return f._attr and f._attr[name] end

---------------------------------------------------------------------------
-- Bereinigung beim Laden
---------------------------------------------------------------------------
local list = qnUnitFramesDB.profiles["preset:1"].bindings.WARRIOR
Check(list["shift-1"] == nil and list["x"] == nil, "unbekannte Aktion und falscher Schlüssel entfernt")
Check(list["foo-1"] == nil and list["shift-7"] == nil, "unbekannte Zusatztaste und Maustaste entfernt")
Check(list["ctrl-3"] and list["ctrl-3"].type == "focus", "gültige Belegung bleibt")
Check(list["alt-2"] and list["alt-2"].value == "17", "Zahl als Wert wird Text (Zauber-ID)")
Check(qnUnitFramesDB.profiles["preset:1"].bindings.MAGE == nil, "kaputte Klassentabelle entfernt")
Check(uf.db.enabled == true and uf.db.raidStyle == true and uf.db.tooltip == true, "Vorgaben ergänzt")

SetEditModeLayout(1)
FireEvent("PLAYER_LOGIN")
RunTimers()
Check(uf.db == qnUnitFramesDB.profiles["preset:1"], "Profil preset:1 aktiv")

---------------------------------------------------------------------------
-- Attribute
---------------------------------------------------------------------------
Check(A(partyCUF, "ctrl-type3") == "focus" and A(partyCUF, "ctrl-spell3") == nil, "Fokus: nur type-Attribut")
Check(A(raid2, "alt-type2") == "spell" and A(raid2, "alt-spell2") == "17", "Zauber-ID als spell-Attribut")
Check(A(plate, "ctrl-type3") == nil, "Namensplakette unberührt")
Check(A(partyCUF, "*type1") == nil, "Blizzards eigene Attribute nicht gesetzt")

uf.SetBinding("shift-1", "spell", "Blitzheilung")
uf.SetBinding("ctrl-2", "macro", "/cast [@mouseover] Heilen")
uf.SetBinding("3", "target")
uf.SetBinding("alt-ctrl-shift-5", "spell", "")
for _, f in ipairs({ partyCUF, partyPetCUF, raid1, raid2, group, party, party.PetFrame }) do
	Check(A(f, "shift-type1") == "spell" and A(f, "shift-spell1") == "Blitzheilung", "Zauber auf " .. tostring(f:GetName() or "Gruppenrahmen"))
end
Check(A(raid1, "ctrl-type2") == "macro" and A(raid1, "ctrl-macrotext2") == "/cast [@mouseover] Heilen", "Makro: type und macrotext")
Check(A(raid1, "type3") == "target", "Ziel ohne Zusatztaste: type3")
Check(A(raid1, "alt-ctrl-shift-type5") == nil, "Zauber ohne Namen belegt nichts")
Check(A(plate, "shift-type1") == nil, "Namensplakette weiter unberührt")

uf.SetBinding("ctrl-2", nil)
Check(A(raid1, "ctrl-type2") == nil and A(raid1, "ctrl-macrotext2") == nil, "gelöschte Belegung: Attribute entfernt")
uf.SetBinding("shift-1", "focus")
Check(A(raid1, "shift-type1") == "focus" and A(raid1, "shift-spell1") == nil, "Zauber → Fokus: spell-Attribut entfernt")
uf.SetBinding("shift-1", "spell", "Blitzheilung")

---------------------------------------------------------------------------
-- Kampf
---------------------------------------------------------------------------
QN_COMBAT = true
printed = {}
uf.SetBinding("shift-2", "spell", "Erneuerung")
Check(A(raid1, "shift-type2") == nil, "im Kampf nichts geändert (sonst ADDON_ACTION_BLOCKED)")
Check(printed[1] == L["Änderung wird nach dem Kampf übernommen."], "Hinweis im Kampf")
-- neuer Rahmen im Kampf
local raid3 = UnitButton("CompactRaidFrame3")
CompactUnitFrame_SetUpFrame(raid3, nop)
RunTimers()
Check(A(raid3, "shift-type1") == nil, "neuer Rahmen im Kampf noch nicht belegt")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Check(A(raid1, "shift-type2") == "spell" and A(raid1, "shift-spell2") == "Erneuerung", "nach dem Kampf übernommen")
Check(A(raid3, "shift-spell1") == "Blitzheilung", "neuer Rahmen nach dem Kampf belegt")
-- neuer Rahmen außerhalb des Kampfes
local raid4 = UnitButton("CompactRaidFrame4")
CompactUnitFrame_SetUpFrame(raid4, nop)
RunTimers()
Check(A(raid4, "shift-spell1") == "Blitzheilung", "neuer Rahmen sofort belegt")
Check(A(raidPet, "shift-spell1") == "Blitzheilung", "Begleiter im Schlachtzug belegt")
-- unveränderte Attribute werden nicht neu geschrieben
local writes = 0
local origSet = raid1.SetAttribute
raid1.SetAttribute = function(self, ...) writes = writes + 1 return origSet(self, ...) end
uf.Apply()
Check(writes == 0, "erneutes Anwenden ohne Änderung schreibt nichts")
uf.SetBinding("shift-1", "spell", "Heilen")
Check(writes == 1 and A(raid1, "shift-spell1") == "Heilen", "nur das geänderte Attribut geschrieben")
uf.SetBinding("shift-1", "spell", "Blitzheilung")
raid1.SetAttribute = nil
-- klassische Gruppenrahmen aus dem Pool
local party2 = UnitButton(nil)
QN_PARTY_FRAMES = { party, party2 }
PartyFrame:InitializePartyMemberFrames()
RunTimers()
Check(A(party2, "shift-spell1") == "Blitzheilung", "neuer klassischer Gruppenrahmen belegt")

---------------------------------------------------------------------------
-- Rahmenauswahl und Ein/Aus
---------------------------------------------------------------------------
SETTINGS.QNUF_PETS:SetValue(false)
Check(A(partyPetCUF, "shift-type1") == nil and A(party.PetFrame, "shift-type1") == nil, "Begleiter aus: Begleiterrahmen frei")
Check(A(raidPet, "shift-type1") == nil and A(raid4, "shift-type1") == "spell", "Begleiter aus: auch im Schlachtzug frei, Mitglieder belegt")
Check(A(partyCUF, "shift-type1") == "spell", "Gruppenmitglieder weiter belegt")
SETTINGS.QNUF_RAIDSTYLE:SetValue(false)
Check(A(raid1, "shift-type1") == nil and A(group, "shift-type1") == nil and A(partyCUF, "shift-type1") == nil, "Schlachtzugsstil aus: Compact-Rahmen frei")
Check(A(party, "shift-type1") == "spell", "klassische Gruppenrahmen weiter belegt")
SETTINGS.QNUF_RAIDSTYLE:SetValue(true)
SETTINGS.QNUF_PETS:SetValue(true)
SlashCmdList.QNUNITFRAMES("off")
Check(uf.db.enabled == false and A(party, "shift-type1") == nil and A(raid1, "ctrl-type3") == nil, "/qnuf off: alles frei")
SlashCmdList.QNUNITFRAMES("on")
Check(A(raid1, "shift-type1") == "spell" and A(partyPetCUF, "shift-type1") == "spell", "/qnuf on: wieder belegt")

---------------------------------------------------------------------------
-- Tooltip
---------------------------------------------------------------------------
Check(type(tooltipFn) == "function", "Tooltip-Rückruf für Einheiten angemeldet")
GameTooltip:SetOwner(raid1, "ANCHOR_NONE")
tooltipFn(GameTooltip)
local texts = {}
for _, line in ipairs(TOOLTIP.lines) do texts[#texts + 1] = (line.text or "") .. "=" .. tostring(line.right) end
local joined = table.concat(texts, "|")
Check(joined:find(uf.BindingText("shift-1") .. "=Blitzheilung", 1, true) ~= nil, "Tooltip zeigt Zauber zur Belegung")
Check(joined:find(KEY_BUTTON3 .. "=" .. TARGET, 1, true) ~= nil, "Tooltip zeigt Aktion ohne Zusatztaste")
Check(joined:find(uf.BindingText("alt-ctrl-shift-5"), 1, true) == nil, "leerer Zauber nicht im Tooltip")
local first, second
for i, line in ipairs(TOOLTIP.lines) do
	if line.text == uf.BindingText("shift-1") then first = i end
	if line.text == uf.BindingText("shift-2") then second = i end
end
Check(first and second and first < second, "Tooltip nach Maustaste sortiert")
GameTooltip:SetOwner(plate, "ANCHOR_NONE")
tooltipFn(GameTooltip)
Check(#TOOLTIP.lines == 0, "fremder Rahmen: kein Zusatz")
SETTINGS.QNUF_TOOLTIP:SetValue(false)
GameTooltip:SetOwner(raid1, "ANCHOR_NONE")
tooltipFn(GameTooltip)
Check(#TOOLTIP.lines == 0, "Tooltip-Option aus: kein Zusatz")
SETTINGS.QNUF_TOOLTIP:SetValue(true)

---------------------------------------------------------------------------
-- Texte
---------------------------------------------------------------------------
Check(uf.ModifierText("") == L["Ohne Zusatztaste"], "ohne Zusatztaste")
Check(uf.ModifierText("alt-ctrl-shift-") == ALT_KEY_TEXT .. "+" .. CTRL_KEY_TEXT .. "+" .. SHIFT_KEY_TEXT, "Zusatztasten mit Blizzard-Namen")
Check(uf.BindingText("shift-4") == SHIFT_KEY_TEXT .. "+" .. KEY_BUTTON4, "Belegungstext")

---------------------------------------------------------------------------
-- Profile: Belegung je Profil, neues Layout = Kopie
---------------------------------------------------------------------------
SetEditModeLayout(3)
Check(uf.db == qnUnitFramesDB.profiles["account:Raid"], "Profil account:Raid aktiv")
Check(uf.Bindings()["shift-1"] and uf.Bindings()["shift-1"].value == "Blitzheilung", "neues Profil übernimmt die Belegung")
uf.SetBinding("shift-1", "spell", "Heilen")
Check(A(raid1, "shift-spell1") == "Heilen", "Änderung im neuen Profil wirkt")
Check(qnUnitFramesDB.profiles["preset:1"].bindings.WARRIOR["shift-1"].value == "Blitzheilung", "altes Profil unverändert")
SetEditModeLayout(1)
Check(A(raid1, "shift-spell1") == "Blitzheilung", "zurück: Belegung des alten Profils")

---------------------------------------------------------------------------
-- Optionsseite "Klickbelegung"
---------------------------------------------------------------------------
local page = pages[L["Klickbelegung"]]
Check(page ~= nil, "Seite Klickbelegung angemeldet")
local rows = uf.clicksUI.rows
Check(#rows == #uf.MODIFIERS, "eine Zeile je Zusatztaste")
page:Show()
local shiftRow = rows[2]
Check(shiftRow.kind._text == L["Zauber"] and shiftRow.spell:IsShown() and shiftRow.spell._text == "Blitzheilung", "Zeile Umschalt zeigt Zauber und Namen")
Check(rows[1].kind._text == L["Blizzard-Standard"] and not rows[1].spell:IsShown() and not rows[1].macro:IsShown(), "Zeile ohne Belegung: Blizzard-Standard")
Check(shiftRow.spell._scrollHeight == 400, "lange Zauberliste mit Bildlauf")

-- Zauberliste aus dem Zauberbuch
local names = {}
for _, r in ipairs(shiftRow.spell._radios) do names[#names + 1] = r.text end
Check(table.concat(names, ",") == "Blitzheilung,Erneuerung,Heilen," .. L["Anderer Zauber …"], "Zauberbuch: sortiert, ohne Doppelte, passive, Nebenspezialisierung und künftige Zauber")
shiftRow.spell:PickRadio(3)
Check(uf.Bindings()["shift-1"].value == "Heilen" and A(raid1, "shift-spell1") == "Heilen", "Zauber aus der Liste gewählt")

-- Anderer Zauber: Eingabefenster
LAST_POPUP = nil
shiftRow.spell:PickRadio(#shiftRow.spell._radios)
Check(LAST_POPUP and LAST_POPUP.which == "QNUNITFRAMES_SPELL" and LAST_POPUP.a1 == uf.BindingText("shift-1"), "Anderer Zauber öffnet Eingabe")
local function Dialog(text) return { GetEditBox = function() return { GetText = function() return text end } end } end
StaticPopupDialogs.QNUNITFRAMES_SPELL.OnAccept(Dialog("  Große Heilung  "))
Check(uf.Bindings()["shift-1"].value == "Große Heilung" and A(raid1, "shift-spell1") == "Große Heilung", "von Hand eingetragener Zauber")
Check(shiftRow.spell._text == "Große Heilung", "eigener Zauber als Auswahl angezeigt")

-- Makro in Zeile Strg
local ctrlRow = rows[3]
local macroIndex
for i, t in ipairs(uf.TYPES) do if t[1] == "macro" then macroIndex = i end end
local editor = uf.clicksUI.macro
Check(editor and not editor:IsShown(), "Makro-Editor zunächst verborgen")
ctrlRow.kind:PickRadio(macroIndex)
Check(uf.Bindings()["ctrl-1"] and uf.Bindings()["ctrl-1"].type == "macro", "Aktion Makro gesetzt")
Check(editor:IsShown() and editor.box:GetText() == "", "Makro öffnet den Editor")
Check(A(raid1, "ctrl-type1") == nil, "leeres Makro belegt nichts")
-- mehrzeilig, mit Leerzeilen und Windows-Zeilenenden
editor.box:SetText("  /stopcasting\r\n\n/cast [@mouseover] Heilen\n  ")
editor.accept:GetScript("OnClick")(editor.accept)
local MACRO_TEXT = "/stopcasting\n/cast [@mouseover] Heilen"
Check(A(raid1, "ctrl-type1") == "macro" and A(raid1, "ctrl-macrotext1") == MACRO_TEXT, "mehrzeiliger Makrotext übernommen")
Check(not editor:IsShown(), "Annehmen schließt den Editor")
Check(ctrlRow.macro:IsShown() and ctrlRow.macroText._text == "/stopcasting · /cast [@mouseover] Heilen" and not ctrlRow.spell:IsShown(), "Zeile zeigt Makro")
-- Bearbeiten und Abbrechen
ctrlRow.macro:GetScript("OnClick")(ctrlRow.macro)
Check(editor:IsShown() and editor.box:GetText() == MACRO_TEXT, "Bearbeiten zeigt den bisherigen Text")
editor.box:SetText("/cast Falsch")
editor.cancel:GetScript("OnClick")(editor.cancel)
Check(not editor:IsShown() and uf.Bindings()["ctrl-1"].value == MACRO_TEXT, "Abbrechen übernimmt nichts")
-- Tooltip: Anfang des Makrotexts
GameTooltip:SetOwner(raid1, "ANCHOR_NONE")
tooltipFn(GameTooltip)
local macroLine
for _, line in ipairs(TOOLTIP.lines) do if line.text == uf.BindingText("ctrl-1") then macroLine = line.right end end
Check(macroLine == L["Makro: %s"]:format("/stopcasting…"), "Tooltip zeigt Anfang des Makros")
Check(uf.ActionText({ type = "macro", value = ("ä"):rep(40) }) == L["Makro: %s"]:format(("ä"):rep(32) .. "…"), "langes Makro gekürzt (UTF-8)")
Check(uf.ActionText({ type = "macro", value = "/cast X" }) == L["Makro: %s"]:format("/cast X"), "kurzes Makro vollständig")
-- Editor schließt sich, wenn die Belegung wechselt
ctrlRow.macro:GetScript("OnClick")(ctrlRow.macro)

-- Aktion zurück auf Blizzard-Standard
ctrlRow.kind:PickRadio(1)
Check(uf.Bindings()["ctrl-1"] == nil and A(raid1, "ctrl-type1") == nil and not ctrlRow.macro:IsShown(), "Blizzard-Standard löscht die Belegung")
Check(not editor:IsShown(), "Editor zu, wenn die Belegung kein Makro mehr ist")

-- Maustaste wechseln: die Zeilen zeigen die Belegungen dieser Taste
local buttonDD = uf.clicksUI.button
Check(buttonDD._text == KEY_BUTTON1, "Maustaste: Linke Maustaste gewählt")
buttonDD:PickRadio(2)
Check(buttonDD._text == KEY_BUTTON2 and shiftRow.spell._text == "Erneuerung", "Rechte Maustaste: Umschalt-Zeile zeigt shift-2")
Check(rows[4].kind._text == L["Zauber"] and rows[4].spell._text == "17", "Alt-Zeile zeigt Zauber-ID aus dem alten Profil")
shiftRow.kind:PickRadio(1)
Check(uf.Bindings()["shift-2"] == nil and uf.Bindings()["shift-1"] ~= nil, "Löschen betrifft nur die gewählte Maustaste")

-- Alle löschen
Check(uf.Bindings()["3"] ~= nil, "vor dem Löschen belegt")
StaticPopupDialogs.QNUNITFRAMES_CLEAR.OnAccept(nil, nil)
Check(next(uf.Bindings()) == nil and A(raid1, "type3") == nil and A(raid1, "shift-type1") == nil, "Alle löschen: Belegung und Attribute weg")
Check(qnUnitFramesDB.profiles["account:Raid"].bindings.WARRIOR["shift-1"].value == "Heilen", "anderes Profil unberührt")

-- Optionen öffnen
SlashCmdList.QNUNITFRAMES("clicks")
SlashCmdList.QNUNITFRAMES("")
printed = {}
SlashCmdList.QNUNITFRAMES("hilfe")
Check(#printed == 1 and printed[1]:find("/qnuf clicks", 1, true) ~= nil, "Hilfe zu den Befehlen")
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
