-- Szenario 8: qnCore-Verfolgung nach dem Tod, wenn die Ereignisse ungünstig liegen
local core = LoadAddon("qnCore")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false) RunTimers()
C_Minimap.SetTracking(2, true)      -- Kräutersuche an (gemerkt)

-- 1. Beim Ereignis der Wiederbelebung gilt der Charakter noch als tot
QN_DEAD = true
QN_TRACKING[2].active = false
LOG = {}
FireEvent("PLAYER_UNGHOST")
QN_DEAD = false                      -- kurz darauf lebt er
RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)", "tot beim Ereignis: später nachgeholt: " .. table.concat(LOG, ";"))

-- 2. Die Minikarte meldet den Verlust erst nach der Wiederbelebung
FireEvent("PLAYER_UNGHOST") RunTimers()   -- nichts zu tun, Verfolgung noch aktiv
QN_TRACKING[2].active = false
LOG = {}
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)", "späte Meldung: wiederhergestellt: " .. table.concat(LOG, ";"))

-- 3. Zauber scheitert: Meldungen lösen keine Endlosschleife aus
QN_TRACKING[2].active = false
QN_TRACKING_BLOCKED = true
FireEvent("PLAYER_UNGHOST") RunTimers()
LOG = {}
for _ = 1, 5 do FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers() end
Check(#LOG == 0, "nach 3 Versuchen Ruhe: " .. table.concat(LOG, ";"))
QN_TRACKING_BLOCKED = false

-- 4. Eigene Auswahl im Menü wird nicht zurückgedreht
LOG = {}
C_Minimap.SetTracking(2, false)
RunTimers()
Check(qnCoreCharDB.tracking["spell:2383"] == false and not table.concat(LOG, ";"):find("true"), "Abwählen bleibt: " .. table.concat(LOG, ";"))
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
