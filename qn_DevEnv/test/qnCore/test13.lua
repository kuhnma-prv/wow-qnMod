-- Szenario 13: Schrift der Questzielverfolgung unter Blizzards Minimum, je Profil (Layout)

-- früherer Stand: qnCoreDB ohne eigene Profile
qnCoreDB = { global = { tracking = true }, layouts = {} }

local core = LoadAddon("qnCore")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false) RunTimers()
SetEditModeLayout(3)

local line, header, M = ObjectiveTrackerLineFont, ObjectiveTrackerHeaderFont, ObjectiveTrackerManager
local raid = "account:Raid"
Check(qnCoreDB.ownProfiles == true and qnCoreDB.global.tracking == true, "qnCoreDB: eigene Profile angelegt, kontoweite Werte bleiben")
Check(core.store and core.db == qnCoreDB.profiles[raid] and core.db.questTextSize == 0, "qnCore hat ein Profil je Layout, Vorgabe 0")
Check(qnCore.Profiles.stores.qnCore == core.store, "qnCore erscheint unter den Profilen")
Check(M.updates == 0 and select(2, line:GetFont()) == 12, "Vorgabe: Blizzards Schrift unverändert, kein Neuaufbau")

-- Auswahl 10 über das Einstellungsfenster
SETTINGS.QNCORE_QUESTTEXTSIZE:SetValue(10)
Check(select(2, line:GetFont()) == 10 and select(2, header:GetFont()) == 12, "10: Zeilen 10, Überschrift 12: " .. select(2, line:GetFont()) .. "/" .. select(2, header:GetFont()))
Check(M.updates == 1, "Verfolgung neu aufgebaut: " .. M.updates)

-- Blizzard setzt die Schrift neu (Layout, Regler): eigene Größe bleibt, vor Blizzards Neuaufbau
M:SetTextSize(15)
Check(select(2, line:GetFont()) == 10 and select(2, header:GetFont()) == 12, "nach SetTextSize(15) wieder 10/12")

-- zweites Layout: Kopie (10), dann auf Blizzard zurück
SetEditModeLayout(4)
Check(core.db ~= qnCoreDB.profiles[raid] and core.db.questTextSize == 10, "neues Layout übernimmt 10")
local before = M.updates
SETTINGS.QNCORE_QUESTTEXTSIZE:SetValue(0)
Check(select(2, line:GetFont()) == 15 and select(2, header:GetFont()) == 17, "0: Blizzards zuletzt gesetzte Schrift (15/17): " .. select(2, line:GetFont()))
Check(M.updates == before + 1, "zurück auf Blizzard: neu aufgebaut")

-- Profilwechsel wendet an; gleiche Größe: kein Neuaufbau
SetEditModeLayout(3)
Check(select(2, line:GetFont()) == 10 and SETTINGS.QNCORE_QUESTTEXTSIZE:GetValue() == 10, "zurück auf Raid: 10")
before = M.updates
core.QuestTracker.Apply()
Check(M.updates == before, "unverändert: kein Neuaufbau")

-- im Kampf: Schrift sofort, Neuaufbau erst danach
QN_COMBAT = true
SETTINGS.QNCORE_QUESTTEXTSIZE:SetValue(8)
Check(select(2, line:GetFont()) == 8 and M.updates == before, "im Kampf: Schrift 8, noch kein Neuaufbau")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(M.updates == before + 1, "nach dem Kampf neu aufgebaut")

-- andere Alphabete: Höhe im Verhältnis der Vorlage (z. B. Chinesisch 15 bei 12)
ObjectiveTrackerFont12:SetFont("Fonts\\ARKai_T.ttf", 15, "")
SETTINGS.QNCORE_QUESTTEXTSIZE:SetValue(10)
local path, h = line:GetFont()
Check(path == "Fonts\\ARKai_T.ttf" and h == 12.5, "Datei und Verhältnis der Vorlage: " .. tostring(path) .. " " .. tostring(h))

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
