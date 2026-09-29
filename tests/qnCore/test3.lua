-- Szenario 3: Migration nur in ein noch fehlendes Profil; ein bestehendes bleibt erhalten.
-- qnNumKeyPad: ein anderer Charakter hat schon migriert (Profil account:Raid existiert),
-- dieser Charakter hat noch eigene alte Werte.
qnNumKeyPadProfiles = { version = 1, global = {}, profiles = { ["account:Raid"] = { scale = 0.7 } }, migrated = { scale = 0.7 } }
qnNumKeyPadDB = { scale = 1.9, locked = true }
-- qnMeter: altes Flachformat
qnMeterDB = { scale = 1.4, styleVersion = 2 }
-- qnCoreCharDB mit Layout der letzten Sitzung darf die Migration nicht verhindern
qnCoreCharDB = { layout = "account:Raid" }

local core = LoadAddon("qnCore")
local meter = LoadAddon("qnMeter")
local nkp = LoadAddon("qnNumKeyPad")
FireEvent("PLAYER_LOGIN")
RunTimers()
Check(nkp.db.scale == 1.9, "vor dem Layout: bisherige Werte aktiv")
SETTINGS.QNNKP_ALPHA:SetValue(0.5)   -- Änderung vor dem Erkennen des Layouts
SetEditModeLayout(3)
Check(qnNumKeyPadProfiles.profiles["account:Raid"].scale == 0.7, "bestehendes Profil bleibt erhalten")
Check(nkp.db == qnNumKeyPadProfiles.profiles["account:Raid"] and nkp.db.scale == 0.7, "bestehendes Profil aktiv")
Check(qnMeterDB.profiles["account:Raid"].scale == 1.4 and qnMeterDB.migrated.scale == 1.4, "qnMeter migriert, Vorlage gespeichert")
Check(qnNumKeyPadDB == nil, "alte Char-Tabelle gelöscht")
SetEditModeLayout(4)
Check(meter.db.scale == 1.4, "weiteres Layout: Kopie des aktiven Profils")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
