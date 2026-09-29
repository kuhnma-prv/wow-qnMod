-- Szenario 1: Umstieg aus dem alten Format, Profilwechsel, Taschen, Profilseite.

-- alte Daten (vor qnCore)
qnViewPortDB = { viewport = { 10, 0, 0, 0 }, color = { 0, 0, 0, 1 }, dual = { enabled = false, bagsOnMain = true } }
qnMeterDB = { scale = 1.2, styleVersion = 2, keepVisible = true }
qnNumKeyPadDB = { scale = 1.5, layout = "Windows" }

local core = LoadAddon("qnCore")
local meter = LoadAddon("qnMeter")
local nkp = LoadAddon("qnNumKeyPad")
local vp = LoadAddon("qnViewPort")
local inv = LoadAddon("qnInventory")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

local P = qnCore.Profiles
Check(P.GetActiveKey() == nil, "vor EDIT_MODE_LAYOUTS_UPDATED kein aktives Profil")
Check(meter.db.scale == 1.2 and meter.db.keepVisible == nil, "qnMeter: vorläufige Tabelle aus altem Format, Upgrade gelaufen")
Check(nkp.db.scale == 1.5, "qnNumKeyPad: Vorlage aus SavedVariablesPerCharacter")
Check(vp.db.suppressMessage == false and vp.db.dual.bagsMonitor == 0 and vp.db.dual.bagsOnMain == nil, "qnViewPort: altes Format + Upgrade (Viewport setzt Layout.Refresh wegen neuer Monitoranordnung)")

SetEditModeLayout(3)
Check(P.GetActiveKey() == "account:Raid", "aktives Profil = Kontolayout Raid: " .. tostring(P.GetActiveKey()))
Check(qnMeterDB.profiles["account:Raid"] == meter.db, "qnMeter: vorläufige Tabelle wurde Profil account:Raid")
Check(qnMeterDB.profiles["account:Raid"].scale == 1.2, "qnMeter: Wert übernommen")
Check(qnNumKeyPadDB == nil, "qnNumKeyPad: alte Char-Tabelle nach erstem Wechsel gelöscht")
Check(qnNumKeyPadProfiles.profiles["account:Raid"].scale == 1.5, "qnNumKeyPad: Wert im Profil")
Check(qnCoreCharDB.layout == "account:Raid", "qnCoreCharDB merkt sich das Layout")

-- Einstellung über das Einstellungsfenster ändern
SETTINGS.QNMETER_SCALE:SetValue(1.3)
Check(meter.db.scale == 1.3, "qnMeter: Proxy schreibt ins aktive Profil")

-- Wechsel auf charakterspezifisches Layout über Blizzards SelectLayout (Hook)
SetEditModeLayout(4, true)
local charKey = "char:Tester-Realm:Solo"
Check(P.GetActiveKey() == charKey, "Wechsel per SelectLayout erkannt: " .. tostring(P.GetActiveKey()))
Check(meter.db.scale == 1.3 and meter.db ~= qnMeterDB.profiles["account:Raid"], "neues Profil = Kopie des bisherigen")
SETTINGS.QNMETER_SCALE:SetValue(0.8)
Check(SETTINGS.QNMETER_SCALE:GetValue() == 0.8, "Proxy liest neues Profil")
SetEditModeLayout(3, true)
Check(meter.db.scale == 1.3 and SETTINGS.QNMETER_SCALE:GetValue() == 1.3, "zurück auf Raid: alter Wert")
Check(P.GetLabel(charKey):find(qnCore.GERMAN and "charakterspezifisch" or "character%-specific"), "Anzeigename: " .. P.GetLabel(charKey))
Check(P.GetLabel("preset:1") == "preset:1", "unbekanntes Profil ohne Beschreibung zeigt Schlüssel")

-- qnViewPort: Profilwechsel wendet Viewport an
vp.db.viewport = { 0, 0, 0, 0 }
SetEditModeLayout(1)
Check(P.GetActiveKey() == "preset:1", "Vorgabe-Layout 1")
Check(vp.db.viewport[1] == 0, "qnViewPort: neues Profil übernimmt den aktuellen Viewport")

-- Taschen
SetEditModeLayout(3, true)
local Bags = core.Bags
LOG = {}
FireEvent("MERCHANT_SHOW") RunTimers()
Check(table.concat(LOG, ";") == "CloseAllBags(nil);OpenAllBags(nil)", "Händler: alle Taschen öffnen: " .. table.concat(LOG, ";"))
SETTINGS.QNCORE_BAGS_MERCHANTOPEN:SetValue("backpack")
LOG = {}
FireEvent("MERCHANT_SHOW") RunTimers()
Check(table.concat(LOG, ";") == "CloseAllBags(nil);OpenBackpack(nil)", "Händler: nur Rucksack")
SETTINGS.QNCORE_BAGS_SAMEEVERYWHERE:SetValue(true)
SETTINGS.QNCORE_BAGS_ALLOPEN:SetValue("none")
LOG = {}
FireEvent("MERCHANT_SHOW") RunTimers()
FireEvent("MERCHANT_CLOSED") RunTimers()
Check(table.concat(LOG, ";") == "CloseAllBags(nil)", "überall gleich: nichts beim Öffnen, schließen beim Schließen: " .. table.concat(LOG, ";"))
Check(qnCoreDB.global.bags.sameEverywhere == true and qnCoreDB.profiles["account:Raid"].bags == nil, "Taschen kontoweit, nicht im Profil von qnCore")
SetEditModeLayout(4, true)
Check(Bags.Config().allOpen == "none" and Bags.Config().sameEverywhere, "Taschen gelten auch im anderen Profil")
Check(qnCoreCharDB.bags == nil and qnCoreCharDB.chatTimestamps == nil, "nichts charakterbezogen gespeichert")
Check(SETTINGS.QNCORE_G_BAGSSHARED == nil, "Schalter 'In allen Profilen gleich' entfernt")local venues = {}
for _, v in ipairs(Bags.VENUES) do venues[#venues + 1] = v.key end
Check(table.concat(venues, ",") == "auction,bank,gbank,merchant,trade,mail", "Orte des Forever-Clients: " .. table.concat(venues, ","))
Check(SETTINGS.QNCORE_BAGS_BANKBAGS == nil and SETTINGS.QNCORE_BAGS_VOIDOPEN == nil, "keine Bankfächer-/Leerenlager-Option")

-- Zeitstempel-Option entfernt (gibt es im Spiel)
Check(SETTINGS.QNCORE_CHATTIMESTAMPS == nil and core.Chat == nil, "keine Zeitstempel-Option mehr")
SetEditModeLayout(3, true)
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(C_CVar._v.showTimestamps == "none", "CVar showTimestamps unberührt")
-- Profilseite
local n = P.CopyToActive(charKey)
Check(n == 4 and meter.db.scale == 0.8, "Kopieren aus char-Profil in aktives (alle Addons samt qnCore): " .. n)
Check(meter.db == qnMeterDB.profiles["account:Raid"], "Kopieren behält die Tabelle")
n = P.Delete("preset:1")
Check(n == 4 and qnMeterDB.profiles["preset:1"] == nil and qnCoreDB.layouts["preset:1"] == nil, "Löschen preset:1")
Check(P.Delete("account:Raid") == 0, "aktives Profil nicht löschbar")
P.ResetActive({ P.stores.qnMeter })
Check(meter.db.scale == 1 and nkp.db.scale == 1.5, "Zurücksetzen nur für qnMeter: " .. meter.db.scale .. " / " .. nkp.db.scale)

-- Kampf: Wechsel wird verschoben
QN_COMBAT = true
SetEditModeLayout(4, true)
Check(P.GetActiveKey() == "account:Raid", "im Kampf kein Wechsel")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(P.GetActiveKey() == charKey, "nach dem Kampf nachgeholt")

-- Dropdowns in qnViewPort
local found = 0
for _, s in pairs(SETTINGS) do found = found + 1 end
print("Einstellungen registriert: " .. found)
for _, cmd in ipairs({ "", "status", "x" }) do SlashCmdList.QNCORE(cmd) end
SlashCmdList.QNMETER("lock")
Check(meter.db.locked == true, "/qnm lock über Settings")
SlashCmdList.QNNUMKEYPAD("lock")
Check(nkp.db.locked == true, "/qnnkp lock")
SlashCmdList.QNINVENTORY("gold")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
