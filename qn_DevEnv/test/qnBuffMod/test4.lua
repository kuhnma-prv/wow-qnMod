-- Szenario 4: qnBuffMod-Kern: Gruppen, Sortierung, Waffen, Anordnung, Stile, Fahrzeug, Warnung,
-- Rechtsklick, Fenster anlegen/kopieren/löschen
local clicks = {}
local orig = CreateSettingsButtonInitializer
function CreateSettingsButtonInitializer(n, bt, click, ...) clicks[bt] = click return orig(n, bt, click, ...) end
local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
local E, K, L = bm.enum, bm.kind, bm.L

-- GetTime() = 1000
AURAS.player = {
	{ name = "Arkane Intelligenz", icon = 1, applications = 0, duration = 1800, expirationTime = 2800, sourceUnit = "player", spellId = 1, cancelable = true },
	{ name = "Bärenform", icon = 2, applications = 0, duration = 0, expirationTime = 0, sourceUnit = "player", spellId = 2 },
	{ name = "Zorn", icon = 3, applications = 3, duration = 600, expirationTime = 1010, sourceUnit = "pet", spellId = 3, cancelable = true },
	{ name = "Fluch", icon = 4, applications = 0, duration = 30, expirationTime = 1020, sourceUnit = "target", spellId = 4, isHarmful = true, dispelName = "Magic" },
}
local printed = {}
local oldPrint = bm.Print
bm.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end

FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

local win = bm.GetWindow(1)
local function Names(id)
	local out = {}
	for _, e in ipairs(bm.GetEntries(id or 1)) do
		out[#out + 1] = e.weapon and ("W" .. e.slot) or e.name
	end
	return table.concat(out, ",")
end
local function Entry(name, id)
	for _, e in ipairs(bm.GetEntries(id or 1)) do
		if e.name == name then return e end
	end
end

-- Gruppen (Schwächungszauber, Waffen, aufhebbar, nicht aufhebbar), darin nach Name
Check(Names() == "Fluch,Arkane Intelligenz,Zorn,Bärenform", "Gruppen und Name: " .. Names())
Check(Entry("Bärenform").kind == K.AURA, "ohne Ablauf = Aura")
Check(Entry("Arkane Intelligenz").kind == K.BUFF and Entry("Fluch").kind == K.DEBUFF, "Stärkungs-/Schwächungszauber")
Check(Entry("Zorn").countText == 3, "Stapel angezeigt")
Check(Entry("Bärenform").time == nil, "Aura ohne Restzeit")
Check(Entry("Zorn").time == L["%d Sekunden"]:format(10), "Restzeit Format 1: " .. tostring(Entry("Zorn").time))
Check(Entry("Zorn").flashing, "blinkt vor Ablauf")
Check(Entry("Arkane Intelligenz").nameText == "Arkane Intelligenz", "Name angezeigt")

-- Raster: links nach rechts, 1 je Zeile -> untereinander, Größe = Symbole
local z = Entry("Zorn")
local pt = z.entry._points[1]
Check(z.x == 0 and z.y == -40 and pt[1] == "TOPLEFT" and pt[2] == win.frame and pt[4] == 0 and pt[5] == -40, "dritter Eintrag bei y=-40")
Check(win.frame._w == 265 and win.frame._h == 80, ("Symbolfläche 265x80: %sx%s"):format(win.frame._w, win.frame._h))

-- Ablaufwarnung (Dauer 10 min, noch 10 s) über den Sekundentakt
RunTickers()
local warned = false
for _, m in ipairs(printed) do if m:find("Zorn", 1, true) then warned = true end end
Check(warned, "Warnung für Zorn")

-- Sortierung
SETTINGS.QNBUFFMOD_G_SORTMETHOD:SetValue(E.sort.TIME)
Check(Names() == "Fluch,Zorn,Arkane Intelligenz,Bärenform", "nach Restzeit: " .. Names())
SETTINGS.QNBUFFMOD_G_SORTMETHOD:SetValue(E.sort.NAME)
SETTINGS.QNBUFFMOD_G_SORTDIRECTION:SetValue(true)
Check(Names() == "Fluch,Zorn,Arkane Intelligenz,Bärenform", "Name absteigend: " .. Names())
SETTINGS.QNBUFFMOD_G_SEPARATEOWN:SetValue(E.own.FIRST)
Check(Names() == "Fluch,Arkane Intelligenz,Zorn,Bärenform", "eigene zuerst: " .. Names())
SETTINGS.QNBUFFMOD_G_SEPARATEZERO:SetValue(E.zero.HIDE)
Check(Names() == "Fluch,Arkane Intelligenz,Zorn", "ohne Ablauf ausgeblendet: " .. Names())
SETTINGS.QNBUFFMOD_G_SEPARATEZERO:SetValue(E.zero.ONLY)
Check(Names() == "Bärenform", "nur ohne Ablauf: " .. Names())
SETTINGS.QNBUFFMOD_G_SEPARATEZERO:SetValue(E.zero.WITH)
SETTINGS.QNBUFFMOD_G_SEPARATEOWN:SetValue(E.own.WITH)
SETTINGS.QNBUFFMOD_G_SORTDIRECTION:SetValue(false)

-- Doppelte Gruppe: der andere Platz wird "keine", seine Anzeige folgt
SETTINGS.QNBUFFMOD_G_SORTSEQ3:SetValue(E.group.DEBUFF)
local o = bm.db.windows[1]
Check(o.sortSeq1 == E.group.NONE and o.sortSeq3 == E.group.DEBUFF and SETTINGS.QNBUFFMOD_G_SORTSEQ1:GetValue() == E.group.NONE, "doppelte Gruppe aufgelöst")
Check(Names() == "Fluch,Bärenform", "Gruppen: Schwächungszauber, nicht aufhebbar: " .. Names())
SETTINGS.QNBUFFMOD_G_SORTSEQ1:SetValue(E.group.DEBUFF)
SETTINGS.QNBUFFMOD_G_SORTSEQ3:SetValue(E.group.CANCELABLE)
Check(Names() == "Fluch,Arkane Intelligenz,Zorn,Bärenform", "Gruppen wiederhergestellt: " .. Names())

-- Waffenverzauberung an Stelle der Gruppe 2
ENCHANTS[16] = { remainingTimeMs = 1200000, chargesRemaining = 5 }
QN_TOOLTIP[16] = { "Schwert", "Sofortgift (20 Min)" }
FireEvent("WEAPON_ENCHANT_CHANGED")
Check(Names() == "Fluch,W16,Arkane Intelligenz,Zorn,Bärenform", "Waffe nach den Schwächungszaubern: " .. Names())
Check(Entry("Sofortgift").countText == 5 and Entry("Sofortgift").kind == K.ITEM, "Aufladungen der Waffe")
ENCHANTS[16] = nil
RunTickers() RunTickers()
Check(Names() == "Fluch,Arkane Intelligenz,Zorn,Bärenform", "Waffe abgelaufen (Takt): " .. Names())

-- Aussehen: geänderte Knopfeinstellung wird sofort gezeichnet
SETTINGS.QNBUFFMOD_B_DURATIONFORMAT1:SetValue(3)
Check(Entry("Arkane Intelligenz").time == "30m", "Format 3 sofort: " .. tostring(Entry("Arkane Intelligenz").time))
SETTINGS.QNBUFFMOD_B_BUTTONSTYLE:SetValue(E.style.ICON)
local ai = Entry("Arkane Intelligenz")
Check(ai.nameText == nil and ai.time == L["%d Minuten"]:format(30), "Stil 2: kein Name, Zeit im Format")
Check(ai.entry._w == 20 and ai.entry._h == 20, "Stil 2: Symbolgröße")
SETTINGS.QNBUFFMOD_B_BUFFSIZE2:SetValue(30)
Check(Entry("Arkane Intelligenz").entry._w == 30, "Stil 2: Symbolgröße nach buffSize2")
SETTINGS.QNBUFFMOD_B_BUFFSIZE2:SetValue(20)
SETTINGS.QNBUFFMOD_B_BUTTONSTYLE:SetValue(E.style.BAR)
SETTINGS.QNBUFFMOD_B_COLORCODEICONS1:SetValue(true)
SETTINGS.QNBUFFMOD_B_COLORCODEBACKGROUND1:SetValue(true)
SETTINGS.QNBUFFMOD_B_COLORCODEDEBUFFS1:SetValue(true)
local fl = Entry("Fluch").entry
Check(fl.border._shown and not Entry("Arkane Intelligenz").entry.border._shown, "Farbcodes: Rahmen nur am Schwächungszauber")

-- Stil 1: Platz der Restzeit (über/unter/neben dem Namen)
local function Pt(region, i) local q = region._points[i] return q and q[1] end
SETTINGS.QNBUFFMOD_B_DURATIONLOCATION1:SetValue(E.timeAt.ABOVE)
local b = Entry("Arkane Intelligenz").entry
Check(not b.besideName and Pt(b.timeText, 1) == "BOTTOMLEFT" and Pt(b.nameText, 1) == "TOPLEFT", "Zeit über dem Namen")
SETTINGS.QNBUFFMOD_B_DURATIONLOCATION1:SetValue(E.timeAt.BELOW)
b = Entry("Arkane Intelligenz").entry
Check(not b.besideName and Pt(b.timeText, 1) == "TOPLEFT" and Pt(b.nameText, 1) == "BOTTOMLEFT", "Zeit unter dem Namen")
SETTINGS.QNBUFFMOD_B_DURATIONLOCATION1:SetValue(E.timeAt.LEFT)
b = Entry("Arkane Intelligenz").entry
Check(b.besideName and Pt(b.timeText, 1) == "LEFT" and Pt(b.nameText, 1) == "RIGHT"
	and b.nameText._points[2][2] == b.timeText, "Zeit links neben dem Namen")
SETTINGS.QNBUFFMOD_B_DURATIONLOCATION1:SetValue(E.timeAt.RIGHT)
b = Entry("Arkane Intelligenz").entry
Check(b.besideName and Pt(b.timeText, 1) == "RIGHT" and Pt(b.nameText, 1) == "LEFT", "Zeit rechts neben dem Namen")
SETTINGS.QNBUFFMOD_B_SHOWNAMES1:SetValue(false)
local e = Entry("Arkane Intelligenz")
b = e.entry
Check(e.nameText == nil and not b.besideName and Pt(b.timeText, 1) == "LEFT" and Pt(b.timeText, 2) == "RIGHT", "nur Zeit über die ganze Leiste")
SETTINGS.QNBUFFMOD_B_SHOWNAMES1:SetValue(true)
SETTINGS.QNBUFFMOD_B_DURATIONLOCATION1:SetValue(E.timeAt.DEFAULT)

-- Stil 1: ohne Leistenfarbe keine Leiste, Name bleibt; Leistenbreite 0: weder Name noch Zeit
SETTINGS.QNBUFFMOD_B_COLORBUFFS1:SetValue(false)
e = Entry("Fluch")
b = e.entry
Check(not b.bar._shown and not b.spark._shown and not b.barBG._shown and e.nameText ~= nil and e.time ~= nil, "Leistenfarbe aus")
SETTINGS.QNBUFFMOD_B_COLORBUFFS1:SetValue(true)
b = Entry("Fluch").entry
Check(b.bar._shown and b.spark._shown and b.barBG._shown, "Leistenfarbe wieder an")
SETTINGS.QNBUFFMOD_B_DETAILWIDTH1:SetValue(0)
e = Entry("Arkane Intelligenz")
Check(e.nameText == nil and e.time == nil and not e.entry.detail._shown and e.entry.detail._w == 0 and e.entry._w == 20, "Leistenbreite 0")
SETTINGS.QNBUFFMOD_B_DETAILWIDTH1:SetValue(bm.windowDefaults.detailWidth1)
Check(Entry("Arkane Intelligenz").nameText ~= nil, "Leistenbreite wieder da")

-- Stil 2: Restzeit an jeder Seite des Symbols (Abstand 4)
SETTINGS.QNBUFFMOD_B_BUTTONSTYLE:SetValue(E.style.ICON)
SETTINGS.QNBUFFMOD_B_SPACINGFROMICON2:SetValue(4)
local SIDES = { { "RIGHT", "LEFT", -4, 0 }, { "LEFT", "RIGHT", 4, 0 }, { "BOTTOM", "TOP", 0, 4 }, { "TOP", "BOTTOM", 0, -4 }, { "CENTER", "CENTER", 0, 0 } }
for side, want in ipairs(SIDES) do
	SETTINGS.QNBUFFMOD_B_DATASIDE2:SetValue(side)
	b = Entry("Arkane Intelligenz").entry
	local q = b.timeText._points[1]
	Check(#b.timeText._points == 1 and q[1] == want[1] and q[2] == b and q[3] == want[2] and q[4] == want[3] and q[5] == want[4],
		("Stil 2, Seite %d: %s %s %s/%s"):format(side, tostring(q[1]), tostring(q[3]), tostring(q[4]), tostring(q[5])))
end
SETTINGS.QNBUFFMOD_B_DATASIDE2:SetValue(E.dataSide.BELOW)
SETTINGS.QNBUFFMOD_B_SPACINGFROMICON2:SetValue(0)
SETTINGS.QNBUFFMOD_B_BUTTONSTYLE:SetValue(E.style.BAR)

-- Anordnung: Spalten, 2 je Spalte
SETTINGS.QNBUFFMOD_L_LAYOUTTYPE:SetValue(1)
SETTINGS.QNBUFFMOD_L_WRAPAFTER:SetValue(2)
Check(win.edges.barRight == 245 and win.edges.right == 4 + 245, "Leiste neben variablen Spalten verbreitert den Hintergrund")
z = Entry("Zorn")
Check(z.x == 265 and z.y == 0, ("dritter Eintrag in Spalte 2: %s/%s"):format(z.x, z.y))
Check(win.frame._w == 285 and win.frame._h == 40, ("Symbolfläche 285x40: %sx%s"):format(win.frame._w, win.frame._h))
-- höchstens 1 Spalte: nur 2 Einträge, die übrigen ausgeblendet, Fläche nur so groß wie die Spalte
SETTINGS.QNBUFFMOD_L_MAXWRAPS:SetValue(1)
Check(Names() == "Fluch,Arkane Intelligenz" and win.entries[3]._shown == false and win.entries[4]._shown == false,
	"höchstens 1 Spalte: " .. Names())
Check(win.frame._w == 265 and win.frame._h == 40, ("Symbolfläche 265x40: %sx%s"):format(win.frame._w, win.frame._h))
SETTINGS.QNBUFFMOD_L_MAXWRAPS:SetValue(0)
Check(Names() == "Fluch,Arkane Intelligenz,Zorn,Bärenform" and win.frame._w == 285, "wieder automatisch: " .. Names())
SETTINGS.QNBUFFMOD_L_LAYOUTTYPE:SetValue(5)
SETTINGS.QNBUFFMOD_L_WRAPAFTER:SetValue(1)

-- Rechtsklick entfernt Stärkungszauber (nicht im Kampf, nicht Schwächungszauber)
local cancelled = {}
CancelUnitBuff = function(u, i, f) cancelled[#cancelled + 1] = u .. ":" .. i .. ":" .. f end
C_CVar._v.ActionButtonUseKeyDown = "1"
b = Entry("Zorn").entry
b._scripts.OnMouseDown(b, "RightButton")
Check(cancelled[1] == "player:2:HELPFUL|CANCELABLE", "Zorn entfernt: " .. tostring(cancelled[1]))
QN_COMBAT = true
b._scripts.OnMouseDown(b, "RightButton")
QN_COMBAT = false
b = Entry("Fluch").entry
b._scripts.OnMouseDown(b, "RightButton")
Check(#cancelled == 1, "nicht im Kampf, keine Schwächungszauber")
-- beim Loslassen (CVar aus) nur, wenn die Maus noch über dem Eintrag ist
C_CVar._v.ActionButtonUseKeyDown = "0"
b = Entry("Bärenform").entry
b._scripts.OnMouseDown(b, "RightButton")
b._scripts.OnMouseUp(b, "RightButton")
Check(#cancelled == 1, "Loslassen außerhalb: nichts")
b.IsMouseOver = function() return true end
b._scripts.OnMouseUp(b, "RightButton")
Check(cancelled[2] == "player:1:HELPFUL|!CANCELABLE", "Loslassen über dem Eintrag: " .. tostring(cancelled[2]))
b.IsMouseOver = nil

-- Fahrzeug
AURAS.vehicle = { { name = "Panzerung", icon = 8, applications = 0, duration = 0, expirationTime = 0, sourceUnit = "vehicle", spellId = 12 } }
FireEvent("UNIT_ENTERED_VEHICLE", "player")
Check(win.unit == "vehicle" and Names() == "Panzerung", "im Fahrzeug dessen Zauber: " .. Names())
FireEvent("UNIT_EXITED_VEHICLE", "player")
Check(win.unit == "player" and Names() == "Fluch,Arkane Intelligenz,Zorn,Bärenform", "zurück beim Spieler")

-- Zweites Fenster für das Ziel, dann kopieren und löschen
clicks[ADD]()
Check(#bm.WindowIDs() == 2 and bm.SelectedID() == 2, "zweites Fenster, ausgewählt")
local w2 = bm.GetWindow(2)
SETTINGS.QNBUFFMOD_W_UNITTYPE:SetValue(E.unit.TARGET)
AURAS.target = { { name = "Segen", icon = 5, applications = 0, duration = 300, expirationTime = 1200, sourceUnit = "player", spellId = 9, cancelable = true } }
FireEvent("PLAYER_TARGET_CHANGED") RunTimers()
Check(w2.unit == "target" and Names(2) == "Segen", "Zielfenster: " .. Names(2))
AURAS.target[2] = { name = "Gift", icon = 6, applications = 0, duration = 10, expirationTime = 1005, spellId = 10, isHarmful = true }
FireEvent("UNIT_AURA", "target") RunTimers()
Check(Names(2) == "Gift,Segen", "UNIT_AURA des Ziels: " .. Names(2))
SETTINGS.QNBUFFMOD_B_BUFFSIZE1:SetValue(30)
clicks[L["Duplizieren"]]()
local w3 = bm.GetWindow(3)
Check(w3 and w3.o.buffSize1 == 30 and w3.unit == "target" and bm.SelectedID() == 3, "Kopie übernimmt Einstellungen")
StaticPopupDialogs.QNBUFFMOD_DELETE_WINDOW.OnAccept()
Check(bm.SelectedID() == 2, "nach dem Löschen: Fenster an derselben Listenposition bzw. das letzte")
StaticPopupDialogs.QNBUFFMOD_DELETE_WINDOW.OnAccept()
Check(#bm.WindowIDs() == 1 and not bm.db.windows[2] and not bm.db.windows[3], "Fenster 2 und 3 gelöscht")
Check(not bm.Auras.IsWatched("target") and bm.Auras.units.target == nil, "Ziel nicht mehr beobachtet")
clicks[ADD]()
Check(bm.GetWindow(2).o.buffSize1 == bm.windowDefaults.buffSize1 and next(bm.db.windows[2]) == "position", "neues Fenster mit Vorgaben")

-- Fenster abschalten und wieder an
SETTINGS.QNBUFFMOD_EDITWINDOW:SetValue(1)
SETTINGS.QNBUFFMOD_W_DISABLEWINDOW:SetValue(true)
Check(win.frame == nil and #bm.GetEntries(1) == 0, "abgeschaltet: keine Rahmen")
SETTINGS.QNBUFFMOD_W_DISABLEWINDOW:SetValue(false)
Check(win.frame ~= nil and Names() ~= "", "wieder an")

-- Sperre der Aurendaten (Kampf): keine Abfrage, letzter Stand bleibt, danach neu lesen
local before = Names()
QN_AURAS_SECRET = true
AURAS.player[5] = { name = "Neu", icon = 7, applications = 0, duration = 60, expirationTime = 1060, sourceUnit = "player", spellId = 11, cancelable = true }
FireEvent("UNIT_AURA", "player") RunTimers()
FireEvent("PLAYER_TARGET_CHANGED") RunTimers()
b = Entry("Arkane Intelligenz").entry
b._scripts.OnEnter(b)
Check(Names() == before and TOOLTIP.aura == nil and TOOLTIP.lines[1].text == "Arkane Intelligenz", "gesperrt: letzter Stand, Tooltip nur mit Namen")
b._scripts.OnLeave(b)
QN_AURAS_SECRET = false
FireEvent("ADDON_RESTRICTION_STATE_CHANGED", 0, 0) RunTimers()
Check(Names():find("Neu", 1, true) ~= nil, "nach der Sperre neu gelesen: " .. Names())
-- einzeln gesperrte Aura: Platzhalter statt Abbruch
AURAS.player[5].locked = true
FireEvent("UNIT_AURA", "player") RunTimers()
Check(Names():find("?", 1, true) ~= nil and Names():find("Neu", 1, true) == nil and Names():find("Zorn", 1, true) ~= nil, "einzeln gesperrt: Platzhalter: " .. Names())
AURAS.player[5] = nil
FireEvent("UNIT_AURA", "player") RunTimers()

-- Hilfsfunktionen
Check(bm.buildCondition("[combat] hide\n\n;show;\n") == "[combat] hide;show", "Bedingung: " .. bm.buildCondition("[combat] hide\n\n;show;\n"))
Check(bm.humanizeTime(3700) == "1h 01m" and bm.humanizeTime(59) == "59s", "Zeitformat 4")
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
