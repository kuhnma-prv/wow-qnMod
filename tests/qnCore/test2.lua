-- Szenario 2: /reload mit Profilen im neuen Format; Layout der letzten Sitzung bekannt.
qnCoreCharDB = { layout = "account:Raid" }
qnCoreDB = { profiles = { ["account:Raid"] = { chatTimestamps = "%H:%M " } }, global = { chatTimestamps = "%H:%M " }, layouts = { ["account:Raid"] = { kind = "account", name = "Raid" } } }
qnMeterDB = { version = 1, global = {}, profiles = {
	["account:Raid"] = { scale = 1.7 },
	["char:Tester-Realm:Solo"] = { scale = 0.6 },
} }

local core = LoadAddon("qnCore")
local meter = LoadAddon("qnMeter")
local nkp = LoadAddon("qnNumKeyPad")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", false, true)
RunTimers()
local P = qnCore.Profiles
Check(meter.db == qnMeterDB.profiles["account:Raid"] and meter.db.scale == 1.7, "vorläufig: Profil der letzten Sitzung")
Check(meter.db.showTPS == true, "Vorgaben ergänzt")
Check(qnCoreDB.global.chatTimestamps == nil and C_CVar._v.showTimestamps == "none", "alte Zeitstempel-Einstellung entfernt, CVar unberührt")
local before = meter.db
SetEditModeLayout(3)
Check(P.GetActiveKey() == "account:Raid" and meter.db == before, "gleiches Layout: kein Wechsel")
SetEditModeLayout(4)
Check(meter.db.scale == 0.6, "vorhandenes Char-Profil geladen")
Check(nkp.db.scale == 1, "qnNumKeyPad ohne Altdaten: Vorgaben")
-- Profilseite: Dropdown und Liste
local found
for _, key in ipairs(P.GetKnownKeys()) do if key == "char:Tester-Realm:Solo" then found = true end end
Check(found, "GetKnownKeys enthält Char-Profil")
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
