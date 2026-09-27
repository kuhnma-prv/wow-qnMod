-- Szenario 7: qnCore merkt sich die Verfolgung an der Minikarte (Kräutersuche usw.)
-- und stellt sie nach Tod, /reload und Kampf wieder her.
local core = LoadAddon("qnCore")
FireEvent("PLAYER_LOGIN")
LOG = {}
FireEvent("PLAYER_ENTERING_WORLD", true, false) RunTimers()
Check(#LOG == 0, "nichts gemerkt: kein SetTracking beim Einloggen: " .. table.concat(LOG, ";"))
Check(qnCoreDB.global.tracking == true, "Option standardmäßig an, kontoweit")

-- Auswahl im Menü der Minikarte
C_Minimap.SetTracking(2, true)      -- Kräutersuche an
C_Minimap.SetTracking(1, false)     -- Briefkasten aus
local saved = qnCoreCharDB.tracking
Check(saved["spell:2383"] == true and saved["filter:12"] == false and saved["spell:2580"] == nil,
	"je Charakter gemerkt: nur angefasste Einträge")

-- Tod: WoW verliert den Verfolgungszauber (ohne SetTracking)
QN_DEAD = true
QN_TRACKING[2].active = false
LOG = {}
FireEvent("PLAYER_ALIVE") RunTimers()   -- Geist freigelassen
Check(#LOG == 0, "als Geist nichts wirken")
Check(saved["spell:2383"] == true, "Verlust beim Tod wird nicht gemerkt")
QN_DEAD = false
FireEvent("PLAYER_UNGHOST") RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)", "nach Wiederbelebung wiederhergestellt: " .. table.concat(LOG, ";"))
Check(QN_TRACKING[2].active and saved["spell:2383"] == true, "Zustand stimmt, Auswahl unverändert")

-- /reload bzw. Neustart: Spiel hat alles vergessen
QN_TRACKING[1].active, QN_TRACKING[2].active = true, false
LOG = {}
FireEvent("PLAYER_ENTERING_WORLD", false, true) RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(1,false);SetTracking(2,true)", "nach /reload einzeln wiederhergestellt: " .. table.concat(LOG, ";"))

-- Im Kampf nicht, danach nachholen
QN_TRACKING[2].active = false
QN_COMBAT = true
LOG = {}
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(#LOG == 0, "im Kampf nichts")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)", "nach dem Kampf nachgeholt: " .. table.concat(LOG, ";"))

-- Zauber scheitert: höchstens 3 Versuche je Durchlauf
QN_TRACKING[2].active = false
QN_TRACKING_BLOCKED = true
LOG = {}
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(#LOG == 3, "3 Versuche, dann Schluss: " .. table.concat(LOG, ";"))
QN_TRACKING_BLOCKED = false

-- Unbekannter Zauber (anderer Beruf verlernt) wird ignoriert und behalten
saved["spell:9999"] = true
LOG = {}
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)" and saved["spell:9999"] == true, "unbekannter Eintrag bleibt gemerkt: " .. table.concat(LOG, ";"))

-- "Alle abwählen" im Menü
C_Minimap.ClearAllTracking()
Check(saved["spell:2383"] == false and saved["spell:2580"] == false and saved["filter:12"] == false, "Alle abwählen gemerkt")

-- Option aus: nichts wiederherstellen, nichts merken
SETTINGS.QNCORE_TRACKING:SetValue(false)
Check(qnCoreDB.global.tracking == false and type(qnCoreCharDB.tracking) == "table", "Schalter kontoweit, Auswahl je Charakter")
QN_TRACKING[3].active = true
C_Minimap.SetTracking(2, true)
LOG = {}
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(#LOG == 0 and saved["spell:2383"] == false, "aus: weder merken noch wiederherstellen")
-- Wieder an: aktueller Zustand wird übernommen
SETTINGS.QNCORE_TRACKING:SetValue(true)
Check(saved["spell:2383"] == true and saved["spell:2580"] == true and saved["filter:12"] == false, "beim Einschalten aktuellen Zustand übernommen")
LOG = {}
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(#LOG == 0, "danach nichts zu tun")

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
