-- Szenario 4: zweiter Charakter nach der Migration, erstes Einloggen, Layout ohne Profil
-- -> bekommt die gespeicherte Vorlage (bisherige Einstellungen), nicht die Standardwerte.
qnMeterDB = { version = 1, global = {}, profiles = { ["account:Raid"] = { scale = 1.4 } }, migrated = { scale = 1.4 } }

local core = LoadAddon("qnCore")
local meter = LoadAddon("qnMeter")
FireEvent("PLAYER_LOGIN")
RunTimers()
SetEditModeLayout(4)
Check(meter.db.scale == 1.4, "Char-Layout ohne Profil: Vorlage aus der Migration")
Check(qnMeterDB.profiles["char:Tester-Realm:Solo"] == meter.db, "als Profil gespeichert")
Check(qnMeterDB.version == nil, "alte Versionsnummer entfernt")

-- Anmeldung erst nach dem Erkennen des Layouts (Addon lädt später)
local P = qnCore.Profiles
local key = P.GetActiveKey()
local function Late(name, sv, defaults)
	local lns = {}
	qnCore.NewAddon(lns, name)
	return P.Register({ ns = lns, sv = sv, defaults = defaults }), lns
end
-- altes Flachformat: wird sofort das aktive Profil, Kopie als Vorlage
qnLateOldDB = { a = 5 }
local s1, ns1 = Late("qnLateOld", "qnLateOldDB", { a = 1, b = 2 })
Check(s1.key == key and not s1.migrating and qnLateOldDB.profiles[key] == ns1.db and ns1.db.a == 5 and ns1.db.b == 2
	and qnLateOldDB.migrated.a == 5 and qnLateOldDB.migrated ~= ns1.db, "spät, altes Format: aktives Profil, Vorlage kopiert")
-- neues Format ohne Profil für das Layout: Kopie der Vorlage aus der Migration
qnLateNewDB = { profiles = { ["account:Raid"] = { a = 3 } }, global = {}, migrated = { a = 7 } }
local s2, ns2 = Late("qnLateNew", "qnLateNewDB", { a = 1, b = 2 })
Check(s2.key == key and qnLateNewDB.profiles[key] == ns2.db and ns2.db.a == 7 and ns2.db.b == 2, "spät, ohne Profil: Vorlage")
-- neues Format mit Profil für das Layout
qnLateHasDB = { profiles = { [key] = { a = 9 } }, global = { g = 1 } }
local s3, ns3 = Late("qnLateHas", "qnLateHasDB", { a = 1 })
Check(s3.key == key and ns3.db == qnLateHasDB.profiles[key] and ns3.db.a == 9 and s3.global.g == 1, "spät, mit Profil: dieses Profil")

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
