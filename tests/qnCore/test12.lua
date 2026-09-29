-- Szenario 12: qnCore-Review – Übernahme alter Einstellungen bei vorhandenem Profil, Profilseite
-- im Kampf, Verfolgungszauber außerhalb des Menüs, Fehler in OnChange-Rückrufen, Keep nach dem
-- Kampf, MergeDefaults mit falschem Typ

local core = LoadAddon("qnCore")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false) RunTimers()
local P = qnCore.Profiles

-- Fehler in Rückrufen sammeln statt abbrechen (nur in diesem Szenario)
local ERRS = {}
geterrorhandler = function() return function(e) ERRS[#ERRS + 1] = tostring(e) end end

-- Testaddon mit Vorlage aus einer früheren SavedVariablesPerCharacter (wie qnNumKeyPad)
local switches = {}
local function Register(name, legacy)
	local ns = qnCore.NewAddon({}, name)
	switches[name] = 0
	local store = P.Register({ ns = ns, sv = "QN_TEST32_SV", defaults = { scale = 1, color = { r = 1, g = 1 } }, legacy = legacy,
		onSwitch = function() switches[name] = switches[name] + 1 end })
	return store, ns
end

---------------------------------------------------------------------------
-- 1. Altwerte überschreiben kein vorhandenes Profil
---------------------------------------------------------------------------
local a = Register("qnTestA", { scale = 2 })
local b = Register("qnTestB", { scale = 3 })   -- zweiter Charakter, Layout noch unbekannt
SetEditModeLayout(3)
local raid = QN_TEST32_SV.profiles["account:Raid"]
Check(raid ~= nil and raid.scale == 2 and a.db == raid, "erste Übernahme wird das Profil: " .. tostring(raid and raid.scale))
Check(b.db == raid and b.db.scale == 2, "zweite Übernahme überschreibt das vorhandene Profil nicht: " .. tostring(b.db.scale))
Check(switches.qnTestB == 1 and switches.qnTestA == 0, "verworfene Altwerte: normal umgeschaltet (onSwitch)")
local c = Register("qnTestC", { scale = 9 })   -- Layout schon bekannt
Check(c.db == raid and raid.scale == 2 and not c.migrating, "auch bei bekanntem Layout: Profil bleibt: " .. tostring(raid.scale))
Check(type(raid.color) == "table" and raid.color.r == 1, "Vorgaben ergänzt")

---------------------------------------------------------------------------
-- 2. Zurücksetzen / Kopieren im Kampf: erst nach dem Kampf
---------------------------------------------------------------------------
SetEditModeLayout(4)
local solo = "char:Tester-Realm:Solo"
a.db.scale = 5
SetEditModeLayout(3)
local before = switches.qnTestA
QN_COMBAT = true
local n, deferred = P.CopyToActive(solo, { a })
Check(n == 1 and deferred == true, "Kopieren im Kampf: gezählt und als verzögert gemeldet")
Check(a.db.scale == 2 and switches.qnTestA == before, "im Kampf nichts angewendet")
Check(P.ResetActive({ a }) == true, "Zurücksetzen im Kampf verzögert")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(a.db.scale == 1 and a.db == raid and switches.qnTestA == before + 1, "nach dem Kampf: nur der letzte Auftrag, einmal angewendet: " .. tostring(a.db.scale))

-- Profilwechsel vor dem Nachholen: vorgemerktes Ersetzen verfällt
raid.scale = 2
QN_COMBAT = true
P.CopyToActive(solo, { a })
QN_COMBAT = false
SetEditModeLayout(4)   -- Wechsel (im Szenario ohne Kampf) vor PLAYER_REGEN_ENABLED
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(raid.scale == 2 and a.db.scale == 5, "Wechsel dazwischen: Auftrag verfällt: " .. raid.scale .. "/" .. a.db.scale)

-- außerhalb des Kampfes sofort
SetEditModeLayout(3)
local n2, deferred2 = P.CopyToActive(solo, { a })
Check(n2 == 1 and deferred2 == false and a.db.scale == 5 and a.db == raid, "außerhalb des Kampfes sofort")

-- Profilseite: Meldung im Kampf
LOG = {}
local printed = {}
local AddMessage = DEFAULT_CHAT_FRAME.AddMessage
DEFAULT_CHAT_FRAME.AddMessage = function(self, msg) printed[#printed + 1] = msg AddMessage(self, msg) end
QN_COMBAT = true
StaticPopupDialogs.QNCORE_PROFILE_RESET.OnAccept(nil, { stores = { a }, scope = "qnTestA" })
local want = core.L["In combat: will be applied after combat."]
Check(#printed == 2 and printed[2]:find(want, 1, true), "Profilseite meldet die Verzögerung")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
DEFAULT_CHAT_FRAME.AddMessage = AddMessage
Check(a.db.scale == 1, "Zurücksetzen der Profilseite nachgeholt")

---------------------------------------------------------------------------
-- 4. Fehler in einem OnChange-Rückruf hält die übrigen nicht auf
---------------------------------------------------------------------------
local called = false
local failOnce = true
P.OnChange(function()
	if failOnce then
		failOnce = false
		error("absichtlich")
	end
end)
P.OnChange(function() called = true end)
SetEditModeLayout(4)
Check(called and #ERRS == 1 and ERRS[1]:find("absichtlich"), "OnChange mit pcall: " .. table.concat(ERRS, ";"))
ERRS = {}

---------------------------------------------------------------------------
-- 5. Spezialisierung: Blizzard ruft UpdateLayoutInfo, der Hook genügt
---------------------------------------------------------------------------
EditModeManagerFrame:UpdateLayoutInfo({ layouts = EDIT_LAYOUTS, activeLayout = 3 })
RunTimers()
Check(P.GetActiveKey() == "account:Raid", "Wechsel über UpdateLayoutInfo-Hook erkannt")

---------------------------------------------------------------------------
-- 6. Keep: geschützter Rahmen im Kampf wird danach geholt
---------------------------------------------------------------------------
local f = CreateFrame("Frame", nil, UIParent)
f._protected = true
function f:GetLeft() return -500 end
local moved = 0
local check = qnCore.Visible.Keep(f, function() return true end, function() moved = moved + 1 end)
QN_COMBAT = true
check() RunTimers()
Check(moved == 0, "Keep im Kampf: nicht verschoben")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(moved == 1, "Keep nach dem Kampf nachgeholt: " .. moved)

---------------------------------------------------------------------------
-- 7. MergeDefaults: Vorgabe Tabelle, gespeichert etwas anderes
---------------------------------------------------------------------------
local db = qnCore.MergeDefaults({ color = 5, list = "x", scale = 2 }, { color = { r = 1 }, list = { 1, 2 }, scale = 1 })
Check(type(db.color) == "table" and db.color.r == 1 and type(db.list) == "table" and db.list[2] == 2 and db.scale == 2,
	"falscher Typ durch Vorgabe ersetzt")

---------------------------------------------------------------------------
-- 3. Verfolgung: Zauber von der Aktionsleiste wird gemerkt, nicht zurückgedreht
---------------------------------------------------------------------------
local saved = qnCoreCharDB.tracking or {}
qnCoreCharDB.tracking = saved
QN_TRACKING[1].active, QN_TRACKING[2].active, QN_TRACKING[3].active = true, false, false
saved["filter:12"], saved["spell:2383"], saved["spell:2580"] = true, false, false
AdvanceTime(60)   -- Zeitfenster nach dem Einloggen vorbei
LOG = {}
QN_TRACKING[3].active = true   -- Mineraliensuche aus dem Zauberbuch
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
Check(#LOG == 0 and saved["spell:2580"] == true, "Zauber außerhalb des Menüs gemerkt, nicht zurückgedreht: " .. table.concat(LOG, ";"))
QN_TRACKING[2].active, QN_TRACKING[3].active = true, false   -- Kräutersuche ersetzt Mineraliensuche
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
Check(#LOG == 0 and saved["spell:2383"] == true and saved["spell:2580"] == false, "Wechsel des Suchzaubers gemerkt")

-- Tod: Verlust wird nicht gemerkt, nach der Wiederbelebung (auch späte Meldung) wiederhergestellt
QN_DEAD = true
QN_TRACKING[2].active = false
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
Check(saved["spell:2383"] == true, "Verlust beim Tod nicht gemerkt")
QN_DEAD = false
FireEvent("PLAYER_UNGHOST") RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)", "nach der Wiederbelebung wiederhergestellt: " .. table.concat(LOG, ";"))
AdvanceTime(5)
LOG = {}
QN_TRACKING[2].active = false   -- WoW meldet den Verlust erst jetzt
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)", "späte Meldung im Zeitfenster: wiederhergestellt: " .. table.concat(LOG, ";"))

-- Nach dem Zeitfenster: Abwählen über das Zauberbuch wird gemerkt
AdvanceTime(60)
LOG = {}
QN_TRACKING[2].active = false
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
Check(#LOG == 0 and saved["spell:2383"] == false, "nach dem Zeitfenster: Abwählen gemerkt: " .. table.concat(LOG, ";"))

-- Wiederherstellen im Kampf vorgemerkt: Meldungen bis dahin nicht als Auswahl merken
QN_TRACKING[2].active = true
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
QN_TRACKING[2].active = false   -- /reload im Kampf: Verfolgung verloren
QN_COMBAT = true
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
AdvanceTime(60)
FireEvent("MINIMAP_UPDATE_TRACKING") RunTimers()
Check(saved["spell:2383"] == true and #LOG == 0, "im Kampf vorgemerkt: Verlust nicht gemerkt")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(table.concat(LOG, ";") == "SetTracking(2,true)", "nach dem Kampf wiederhergestellt: " .. table.concat(LOG, ";"))

Check(#ERRS == 0, "keine Fehler: " .. table.concat(ERRS, ";"))
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
