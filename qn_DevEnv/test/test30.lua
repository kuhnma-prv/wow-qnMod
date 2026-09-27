-- Szenario 30: qnBuffMod – Umrechnung des alten Datenformats, Bereinigung beim Laden, Fensterverwaltung,
-- Position, abgeschaltete Fenster, keine doppelte Anzeige
local clicks = {}
local orig = CreateSettingsButtonInitializer
function CreateSettingsButtonInitializer(n, bt, click, ...) clicks[bt] = click return orig(n, bt, click, ...) end

-- Profile im alten, verschachtelten Format bzw. schon im neuen
qnCoreCharDB = { layout = "preset:1" }
qnBuffModDB = { global = {}, profiles = {
	["preset:1"] = {
		bgColorBUFF = "rot", flashTime = 500, enableExpiration = 1, expirationTime2 = -5,
		windowOptionsList = {
			[1] = { primaryOptionsList = { [1] = {
				lockWindow = 1, clampWindow = 0, sortSeq1 = 3, sortSeq2 = 3, sortSeq3 = 6, buffSize1 = 99, buffSize2 = 3,
				windowBackgroundColor = { 1, 2 }, unitType = 9, layoutType = 1.5, detailWidth1 = 600,
				position = { "TOPLEFT", "UIParent", "BOTTOMLEFT", 100, 200, 265, 80 },
			} } },
			[3] = { primaryOptionsList = { [1] = { disableWindow = 1, unitType = 4 } } },
			[4] = {},
		},
	},
	["account:Raid"] = { windows = { [2] = { buffSize1 = 25 } } },
} }

local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
local E, L = bm.enum, bm.L
local printed = {}
local oldPrint = bm.Print
bm.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end

---------------------------------------------------------------------------
-- Umrechnung (Entscheidung 6) und Bereinigung (Kriterium 59)
---------------------------------------------------------------------------
local db = qnBuffModDB.profiles["preset:1"]
Check(bm.db == db, "letztes Profil des Charakters aktiv")
Check(db.windowOptionsList == nil and type(db.windows) == "table", "alter Schlüssel gelöscht, flaches Format")
local w1 = db.windows[1]
Check(w1 and w1.lockWindow == true and w1.clampWindow == false, "Booleans 1/0 als true/false übernommen")
Check(w1.sortSeq1 == 3 and w1.sortSeq2 == E.group.NONE and w1.sortSeq3 == 6, "doppelte Gruppe: der spätere Platz wird keine")
Check(w1.buffSize1 == 45 and w1.buffSize2 == 15 and w1.detailWidth1 == 400, "Symbolgröße und Leistenbreite begrenzt")
Check(w1.windowBackgroundColor == nil and w1.unitType == nil and w1.layoutType == nil, "ungültige Farbe und Auswahlwerte → Vorgabe")
Check(w1.position and w1.position[4] == 100 and w1.position[5] == 200, "Position übernommen")
Check(db.windows[3].disableWindow == true and db.windows[3].unitType == 4 and type(db.windows[4]) == "table", "weitere Fenster übernommen (auch leere)")
Check(type(db.bgColorBUFF) == "table" and db.bgColorBUFF[3] == bm.defaults.bgColorBUFF[3], "ungültige allgemeine Farbe → Vorgabe")
Check(db.flashTime == 60 and db.expirationTime2 == 0 and db.enableExpiration == true, "allgemeine Werte begrenzt, Booleans übernommen")
Check(qnBuffModDB.profiles["account:Raid"].windows[2].buffSize1 == 25 and qnBuffModDB.profiles["account:Raid"].windowOptionsList == nil, "Profil im neuen Format unverändert")
Check(bm.store.seed == nil and bm.store.migrating == nil, "keine Übernahme fremder Einstellungen (kein legacy)")
-- einmalig: ein zweiter Durchlauf ändert nichts mehr
bm.store:Prepare(db)
Check(db.windows[1].buffSize1 == 45 and db.windows[1].sortSeq2 == E.group.NONE, "Umrechnung wiederholbar ohne Wirkung")

-- Lage vor der ersten Anordnung: gespeicherte Position
local points = {}
local origOffset = qnCore.PointOffset
qnCore.PointOffset = function(frame, point, rel, ...)
	local p = frame._points and frame._points[#frame._points]
	points[#points + 1] = p and { unpack(p) }
	return origOffset(frame, point, rel, ...)
end
AURAS.player = {
	{ name = "Arkane Intelligenz", icon = 1, applications = 0, duration = 1800, expirationTime = 2800, sourceUnit = "player", spellId = 1, cancelable = true },
	{ name = "Bärenform", icon = 2, applications = 0, duration = 0, expirationTime = 0, sourceUnit = "player", spellId = 2 },
}
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
Check(points[1] and points[1][1] == "TOPLEFT" and points[1][3] == "BOTTOMLEFT" and points[1][4] == 100 and points[1][5] == 200, "gespeicherte Position wiederhergestellt")

---------------------------------------------------------------------------
-- Abgeschaltetes Fenster (Kriterium 62)
---------------------------------------------------------------------------
local ids = bm.WindowIDs()
Check(#ids == 3 and ids[1] == 1 and ids[2] == 3 and ids[3] == 4, "Fenster 1, 3, 4 (IDs nicht lückenlos)")
local w3 = bm.GetWindow(3)
Check(w3.frame == nil and not bm.Auras.IsWatched("target"), "abgeschaltet: keine Rahmen, Einheit nicht beobachtet")
AURAS.target = { { name = "Zielsegen", icon = 5, applications = 0, duration = 300, expirationTime = 1200, spellId = 9 } }
FireEvent("PLAYER_TARGET_CHANGED") RunTimers()
FireEvent("UNIT_AURA", "target") RunTimers()
RunTickers()
Check(w3.frame == nil and #bm.GetEntries(3) == 0 and bm.Auras.units.target == nil, "abgeschaltet: reagiert auf keine Ereignisse und Takte")
SETTINGS.QNBUFFMOD_EDITWINDOW:SetValue(3)
Check(SETTINGS.QNBUFFMOD_W_UNITTYPE:GetValue() == E.unit.TARGET, "abgeschaltet: Einstellungen bleiben, Fenster auswählbar")
SETTINGS.QNBUFFMOD_W_DISABLEWINDOW:SetValue(false)
Check(w3.frame ~= nil and bm.Auras.IsWatched("target") and #bm.GetEntries(3) == 1, "wieder an: Anzeige mit Einträgen")
SETTINGS.QNBUFFMOD_W_DISABLEWINDOW:SetValue(true)

---------------------------------------------------------------------------
-- Keine doppelte Anzeige (Entscheidung 1)
---------------------------------------------------------------------------
SETTINGS.QNBUFFMOD_EDITWINDOW:SetValue(1)
SETTINGS.QNBUFFMOD_G_SORTSEQ1:SetValue(E.group.ALLBUFFS)
SETTINGS.QNBUFFMOD_G_SORTSEQ2:SetValue(E.group.CANCELABLE)
local names = {}
for _, e in ipairs(bm.GetEntries(1)) do names[#names + 1] = e.name .. "@" .. e.rec.filter end
Check(table.concat(names, ",") == "Arkane Intelligenz@HELPFUL,Bärenform@HELPFUL", "jeder Zauber einmal, im ersten passenden Platz: " .. table.concat(names, ","))
SETTINGS.QNBUFFMOD_G_SORTSEQ1:SetValue(E.group.CANCELABLE)
SETTINGS.QNBUFFMOD_G_SORTSEQ2:SetValue(E.group.ALLBUFFS)
names = {}
for _, e in ipairs(bm.GetEntries(1)) do names[#names + 1] = e.name .. "@" .. e.rec.filter end
Check(table.concat(names, ",") == "Arkane Intelligenz@HELPFUL|CANCELABLE,Bärenform@HELPFUL", "Reihenfolge der Plätze entscheidet: " .. table.concat(names, ","))

---------------------------------------------------------------------------
-- Fensterverwaltung (Kriterien 56, 57)
---------------------------------------------------------------------------
points = {}
clicks[ADD]()
Check(bm.SelectedID() == 2 and printed[#printed] == L["Fenster %d angelegt."]:format(2), "kleinste freie ID, Meldung, ausgewählt")
Check(points[1] and points[1][1] == "CENTER" and points[1][2] == UIParent and points[1][3] == "CENTER", "neues Fenster in der Bildschirmmitte")
Check(bm.db.windows[2].position ~= nil, "Position des neuen Fensters gespeichert")
SETTINGS.QNBUFFMOD_B_BUFFSIZE1:SetValue(33)
points = {}
clicks[L["Duplizieren"]]()
Check(bm.SelectedID() == 5 and bm.db.windows[5].buffSize1 == 33 and printed[#printed] == L["Fenster %d mit den Einstellungen von Fenster %d angelegt."]:format(5, 2), "Kopie mit Einstellungen")
Check(points[1] and points[1][1] == "CENTER", "Kopie in der Bildschirmmitte")
-- Zurücksetzen
bm.GetWindow(5).frame.GetLeft = function() return 1500 end
points = {}
clicks[RESET]()
Check(points[1] and points[1][1] == "CENTER" and points[1][3] == "CENTER", "Zurücksetzen: Bildschirmmitte")
-- im Kampf abgelehnt
QN_COMBAT = true
printed = {}
clicks[ADD]()
clicks[L["Duplizieren"]]()
StaticPopupDialogs.QNBUFFMOD_DELETE_WINDOW.OnAccept()
QN_COMBAT = false
Check(#printed == 3 and printed[1] == L["Im Kampf nicht möglich."] and printed[3] == L["Im Kampf nicht möglich."] and #bm.WindowIDs() == 5, "Anlegen, Kopieren, Löschen im Kampf abgelehnt")
-- höchstens 10 Fenster
for _ = 1, 5 do clicks[ADD]() end
Check(#bm.WindowIDs() == 10, "zehn Fenster")
printed = {}
clicks[ADD]()
Check(#bm.WindowIDs() == 10 and printed[1] == L["Mehr als %d Fenster sind nicht möglich."]:format(10), "elftes abgelehnt")
-- Löschen: Auswahl an derselben Listenposition
SETTINGS.QNBUFFMOD_EDITWINDOW:SetValue(4)
clicks[L["Löschen …"]]()
Check(LAST_POPUP.which == "QNBUFFMOD_DELETE_WINDOW" and LAST_POPUP.a1 == L["Fenster %d"]:format(4), "Rückfrage mit Fensternamen")
StaticPopupDialogs.QNBUFFMOD_DELETE_WINDOW.OnAccept()
Check(bm.db.windows[4] == nil and bm.SelectedID() == 5 and printed[#printed] == L["Fenster %d gelöscht."]:format(4), "gelöscht, nächstes an derselben Position gewählt")
-- alle löschen: das letzte legt sofort ein neues an
for _ = 1, 20 do
	if #bm.WindowIDs() == 1 then break end
	StaticPopupDialogs.QNBUFFMOD_DELETE_WINDOW.OnAccept()
end
local last = bm.WindowIDs()[1]
StaticPopupDialogs.QNBUFFMOD_DELETE_WINDOW.OnAccept()
ids = bm.WindowIDs()
Check(#ids == 1 and printed[#printed] == L["Kein Fenster übrig – Fenster %d angelegt."]:format(ids[1]) and bm.GetWindow(ids[1]).o.buffSize1 == bm.windowDefaults.buffSize1,
	"letztes gelöscht: neues mit Vorgaben (" .. tostring(last) .. " → " .. tostring(ids[1]) .. ")")

-- Position nach dem Ziehen gespeichert und beim Wiederaufbau (Profilwechsel) wiederhergestellt
local win = bm.GetWindow(ids[1])
win.frame.GetLeft = function() return 400 end
win.frame.GetBottom = function() return 300 end
win.bg._scripts.OnMouseDown(win.bg, "LeftButton")
win.bg._scripts.OnMouseUp(win.bg, "LeftButton")
local pos = CopyTable(bm.db.windows[ids[1]].position)
SetEditModeLayout(3)
SetEditModeLayout(1)
points = {}
SETTINGS.QNBUFFMOD_EDITWINDOW:SetValue(ids[1])
SETTINGS.QNBUFFMOD_W_DISABLEWINDOW:SetValue(true)
SETTINGS.QNBUFFMOD_W_DISABLEWINDOW:SetValue(false)
local p = points[1]
Check(p and p[1] == pos[1] and p[3] == pos[3] and p[4] == pos[4] and p[5] == pos[5], "Position nach dem Ziehen gespeichert und wiederhergestellt")
-- Profilwechsel im Kampf: erst danach; das alte Profil bleibt unverändert (Kriterium 58)
local function Same(a, b)
	if type(a) ~= type(b) then return false end
	if type(a) ~= "table" then return a == b end
	for k, v in pairs(a) do if not Same(v, b[k]) then return false end end
	for k in pairs(b) do if a[k] == nil then return false end end
	return true
end
local before = CopyTable(bm.db)
local oldDB = bm.db
QN_COMBAT = true
SetEditModeLayout(3)
Check(bm.db == oldDB, "im Kampf: noch das alte Profil")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(bm.db == qnBuffModDB.profiles["account:Raid"] and bm.WindowIDs()[1] == 2 and bm.GetWindow(2).o.buffSize1 == 25, "nach dem Kampf gewechselt, Fenster des neuen Profils")
Check(Same(before, oldDB), "Abbau ändert das alte Profil nicht")
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
