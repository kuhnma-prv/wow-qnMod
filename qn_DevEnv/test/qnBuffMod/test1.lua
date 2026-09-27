-- Szenario 1: qnBuffMod laden, einloggen, Optionen, Profilwechsel
local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
AURAS.player = {
	{ name = "Machtwort: Seelenstärke", icon = 135987, applications = 0, duration = 1800, expirationTime = 2500, sourceUnit = "player", spellId = 1243, isHelpful = true, auraInstanceID = 1 },
}
-- vor dem Einloggen: keine Fenster, Optionsseiten zeigen Fenster 1 mit Vorgaben
Check(bm.GetWindow(1) == nil and SETTINGS.QNBUFFMOD_EDITWINDOW:GetValue() == 1 and SETTINGS.QNBUFFMOD_B_BUFFSIZE1:GetValue() == bm.windowDefaults.buffSize1
	and SETTINGS.QNBUFFMOD_W_LOCKWINDOW:GetValue() == false, "vor PLAYER_LOGIN: Fenster 1 mit Vorgaben")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local ids = bm.WindowIDs()
Check(#ids == 1 and ids[1] == 1 and bm.GetWindow(1):IsEnabled(), "ein Fenster nach dem Einloggen")
Check(type(bm.db.windows) == "table" and type(bm.db.windows[1]) == "table", "Fenster 1 im Profil (windows[1])")
Check(#bm.GetEntries(1) == 1, "Aura angezeigt")
SetEditModeLayout(3)
Check(qnBuffModDB.profiles["account:Raid"] == bm.db, "Profil account:Raid = ns.db")
-- Fensteroption über das Einstellungsfenster (flaches Format)
SETTINGS.QNBUFFMOD_W_LOCKWINDOW:SetValue(true)
Check(bm.db.windows[1].lockWindow == true, "lockWindow im Fenster 1 gespeichert")
SETTINGS.QNBUFFMOD_L_LAYOUTTYPE:SetValue(1)
SETTINGS.QNBUFFMOD_B_BUFFSIZE1:SetValue(30)
SETTINGS.QNBUFFMOD_G_SORTSEQ2:SetValue(2)
local w = bm.db.windows[1]
Check(w.layoutType == 1 and w.buffSize1 == 30, "Darstellung und Knöpfe gespeichert")
Check(w.sortSeq2 == 2 and w.sortSeq1 == 1, "Gruppe gespeichert, doppelte Zauberart im anderen Platz aufgelöst")
-- dünn besetzt: Vorgabewert wird nicht gespeichert
SETTINGS.QNBUFFMOD_B_BUFFSIZE1:SetValue(bm.windowDefaults.buffSize1)
Check(w.buffSize1 == nil, "Vorgabewert entfällt")
SETTINGS.QNBUFFMOD_B_BUFFSIZE1:SetValue(30)
-- Farbfeld behält die Deckkraft, Deckkraftregler ändert nur a
SETTINGS.QNBUFFMOD_BGCOLORBUFF:SetValue("ff00ff00")
local c = bm.db.bgColorBUFF
Check(c[1] == 0 and c[2] == 1 and c[3] == 0 and c[4] == 0.5, "Farbe gesetzt, Deckkraft behalten")
SETTINGS.QNBUFFMOD_BGCOLORBUFF_ALPHA:SetValue(0.3)
c = bm.db.bgColorBUFF
Check(c[1] == 0 and c[2] == 1 and c[4] == 0.3, "Deckkraft gesetzt, Farbe behalten")
SETTINGS.QNBUFFMOD_HIDEBLIZZARDBUFFS:SetValue(false)
-- Fensterauswahl und Alt-Klick-Verhalten
SETTINGS.QNBUFFMOD_EDITWINDOW:SetValue(1)
bm.EditWindow(1)
Check(bm.SelectedID() == 1, "Fenster 1 gewählt")
-- Profilwechsel: neues Layout -> Kopie, Fenster neu aufgebaut
SetEditModeLayout(4)
local raid = qnBuffModDB.profiles["account:Raid"]
Check(bm.db ~= raid and bm.db.windows[1].buffSize1 == 30 and bm.db.windows[1].position ~= nil, "Kopie mit Fenstereinstellungen und Position")
SETTINGS.QNBUFFMOD_B_BUFFSIZE1:SetValue(40)
Check(raid.windows[1].buffSize1 == 30, "altes Profil unverändert")
SetEditModeLayout(3)
Check(SETTINGS.QNBUFFMOD_B_BUFFSIZE1:GetValue() == 30, "zurück: Fenster zeigt Wert des Raid-Profils")
Check(#bm.WindowIDs() == 1 and bm.GetWindow(1):IsEnabled(), "nach Wechsel wieder ein Fenster")
Check(bm.GetWindow(1).o.buffSize1 == 30, "Fenster mit den Werten des Raid-Profils aufgebaut")
LOG = {}
SlashCmdList.QNBUFFMOD("")
local opened = false
for _, l in ipairs(LOG) do if l == "Öffne qnBuffMod" then opened = true end end
Check(opened, "/qnbuff öffnet die Optionen")
Check(SLASH_QNBUFFMOD1 == "/qnbuff" and SLASH_QNBUFFMOD2 == "/qnbuffmod" and SLASH_QNBUFFMOD3 == "/qnaura", "Slash-Befehle")
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
