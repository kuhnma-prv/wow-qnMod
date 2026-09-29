-- Szenario 9: gemeinsame Bausteine der qnCore-Bibliothek (NewAddon mit events/OnLoad, RegisterSlash,
-- NewPrinter mehrzeilig, Settings.NewCategory).

-- Chatausgabe mitschreiben
local chat = {}
local oldAdd = DEFAULT_CHAT_FRAME.AddMessage
function DEFAULT_CHAT_FRAME:AddMessage(msg)
	chat[#chat + 1] = tostring(msg)
	oldAdd(self, msg)
end

-- Secret-Values: Tabellen, bei denen Rechnen, Vergleichen und Verketten einen Fehler werfen.
-- issecretvalue muss vor qnCore stehen (qnCore merkt es sich beim Laden).
local function Forbidden() error("Operation mit secret-Wert", 2) end
local SecretMT = { __add = Forbidden, __sub = Forbidden, __mul = Forbidden, __div = Forbidden, __lt = Forbidden,
	__le = Forbidden, __eq = Forbidden, __concat = Forbidden, __len = Forbidden, __index = Forbidden }
local function Secret() return setmetatable({}, SecretMT) end
issecretvalue = function(v) return getmetatable(v) == SecretMT end

local core = LoadAddon("qnCore")
local lib = qnCore

---------------------------------------------------------------------------
-- NewAddon: Ereignisverteiler und OnLoad
---------------------------------------------------------------------------
local ns = {}
lib.NewAddon(ns, "qnTest")
Check(type(ns.events) == "table" and type(ns.events.Register) == "function" and ns.events.frame ~= nil, "NewAddon: ns.events")
local loads = 0
ns.OnLoad(function() loads = loads + 1 end)
FireEvent("ADDON_LOADED", "qnAnderes")
Check(loads == 0, "OnLoad: fremdes Addon ignoriert")
FireEvent("ADDON_LOADED", "qnTest")
FireEvent("ADDON_LOADED", "qnTest")
Check(loads == 1, "OnLoad: genau einmal beim eigenen Namen (" .. loads .. ")")
Check(ns.name == nil and ns.lib == nil and ns.version ~= nil and ns.Print and ns.L, "NewAddon: kein ns.name/ns.lib mehr")
Check(lib.ICON == nil and lib.addons == nil and lib.name == nil and lib.Print == nil and lib.LOCALE == nil and lib.GERMAN ~= nil,
	"ungenutzte API entfernt (ICON, addons, name, Print, LOCALE)")
local got
ns.events.Register("PLAYER_MONEY", function(event, a) got = event .. ":" .. tostring(a) end)
FireEvent("PLAYER_MONEY", 5)
Check(got == "PLAYER_MONEY:5", "ns.events.Register: fn(event, ...)")

---------------------------------------------------------------------------
-- NewPrinter: mehrzeilig, jede Zeile mit Präfix
---------------------------------------------------------------------------
chat = {}
ns.Print("eins\nzwei\n\ndrei")
Check(#chat == 3 and chat[1]:find("qnTest", 1, true) and chat[3]:find("qnTest", 1, true) and chat[3]:find("drei", 1, true),
	"mehrzeilig: 3 Zeilen je mit Präfix (" .. #chat .. ")")
chat = {}
ns.Print("%d von %s", 2, "x")
Check(#chat == 1 and chat[1]:find("2 von x", 1, true), "Format mit Argumenten: " .. tostring(chat[1]))

---------------------------------------------------------------------------
-- RegisterSlash
---------------------------------------------------------------------------
local calls = {}
lib.RegisterSlash("QNTEST", { "/qntest", "/qnt" }, function(cmd, rest, msg)
	calls[#calls + 1] = { cmd, rest, msg }
end)
Check(SLASH_QNTEST1 == "/qntest" and SLASH_QNTEST2 == "/qnt" and SlashCmdList.QNTEST, "Slash-Befehle angemeldet")
SlashCmdList.QNTEST("  Delete   Ärger Müller  ")
local c = calls[1]
Check(c[1] == "delete" and c[2] == "Ärger Müller" and c[3] == "Delete   Ärger Müller", "cmd klein, rest in Schreibweise, msg ohne Rand: "
	.. tostring(c[1]) .. "|" .. tostring(c[2]) .. "|" .. tostring(c[3]))
SlashCmdList.QNTEST(nil)
Check(calls[2][1] == "" and calls[2][2] == "" and calls[2][3] == "", "ohne Eingabe: alles leer")
SlashCmdList.QNTEST("100 0 0 0")
Check(calls[3][1] == "100" and calls[3][2] == "0 0 0" and calls[3][3] == "100 0 0 0", "Zahlen roh in msg")

---------------------------------------------------------------------------
-- Settings.NewCategory
---------------------------------------------------------------------------
LOG = {}
local built
local cat = lib.Settings.NewCategory(ns, "qnTest", function(category, layout)
	built = { category, layout }
	Check(#LOG == 0, "build läuft vor der Anmeldung")
end)
Check(built and built[1] == cat and ns.category == cat and built[2] and built[2].AddInitializer, "senkrechte Seite: category und layout")
Check(table.concat(LOG, ";") == "Kategorie qnTest", "danach angemeldet: " .. table.concat(LOG, ";"))
LOG = {}
ns.OpenOptions()
Check(table.concat(LOG, ";") == "Öffne qnTest", "ns.OpenOptions öffnet die Seite: " .. table.concat(LOG, ";"))
local ns2 = {}
lib.NewAddon(ns2, "qnTest2")
local panel = CreateFrame("Frame")
local got2
lib.Settings.NewCategory(ns2, "qnTest2", function(category, canvas) got2 = canvas end, panel)
Check(got2 == panel and ns2.category and ns2.category.name == "qnTest2", "Canvas-Seite: build bekommt den Rahmen")

---------------------------------------------------------------------------
-- Settings-Baukasten: Rückgaben, Set ohne Steuerelement, eine Form für Header/Button/Depends
---------------------------------------------------------------------------
local tbl = { flag = false, size = 1, mode = "a", col = { 1, 0, 0, 0.5 }, plain = 1 }
local applied = {}
local B = lib.Settings.New({ prefix = "QNTEST_", source = function() return tbl end,
	defaults = { flag = false, size = 1, mode = "a", col = { 1, 0, 0, 0.5 }, col2 = { 0, 1, 0, 1 }, plain = 1 },
	apply = function(s, v) applied[#applied + 1] = { s, v } end })
local tc = lib.Settings.NewCategory(ns2, "qnTest3", function() end)
local n1 = select("#", B:Checkbox(tc, "flag", "Flag"))
local n2 = select("#", B:Slider(tc, "size", "Size", 1, 5, 1))
local n3 = select("#", B:Dropdown(tc, "mode", "Mode", { { "a", "A" }, { "b", "B" } }))
Check(n1 == 1 and n2 == 1 and n3 == 1, ("Checkbox/Slider/Dropdown liefern nur den Initializer (%d/%d/%d)"):format(n1, n2, n3))
Check(B.settings.flag and B.settings.size and B.settings.mode, "Einstellungen in B.settings[key]")
local swatch, alphaInit = B:Color(tc, "col", "Col", nil, nil, "Alpha")
Check(swatch and swatch.setting == B.settings.col and alphaInit and alphaInit.setting == B.settings.col_alpha, "Color: Farbfeld und Deckkraft-Regler")
Check(select("#", B:Color(tc, "col2", "Col2")) == 1, "Color ohne Deckkraft: nur das Farbfeld")
B:Set("plain", 7)
Check(tbl.plain == 7 and #applied == 1 and applied[1][1] == nil and applied[1][2] == 7, "Set ohne Steuerelement: apply(nil, value)")
B:Set("flag", true)
Check(tbl.flag == true and applied[2][1] == B.settings.flag and applied[2][2] == true, "Set mit Steuerelement: über die Einstellung")
Check(B.Header == nil and B.Button == nil and B.Depends == nil and lib.Settings.Header and lib.Settings.Depends, "nur S.Header/S.Button/S.Depends")

---------------------------------------------------------------------------
-- DeferInCombat, Debounce
---------------------------------------------------------------------------
local runs = { a = 0, b = 0 }
local function A() runs.a = runs.a + 1 end
local function B2() runs.b = runs.b + 1 error("Absicht") end
Check(lib.DeferInCombat(A) == false and runs.a == 0, "außerhalb des Kampfes: false, nichts vorgemerkt")
QN_COMBAT = true
Check(lib.DeferInCombat(B2) == true and lib.DeferInCombat(A) == true and lib.DeferInCombat(A) == true, "im Kampf: true")
QN_COMBAT = false
local errors = {}
local oldHandler = geterrorhandler
geterrorhandler = function() return function(e) errors[#errors + 1] = tostring(e) end end
FireEvent("PLAYER_REGEN_ENABLED")
geterrorhandler = oldHandler
Check(runs.a == 1 and runs.b == 1, "nach dem Kampf jede Funktion genau einmal (a=" .. runs.a .. ", b=" .. runs.b .. ")")
Check(#errors == 1 and errors[1]:find("Absicht", 1, true), "Fehler über geterrorhandler, die übrigen laufen weiter")
FireEvent("PLAYER_REGEN_ENABLED")
Check(runs.a == 1, "Liste danach leer")

local count = 0
local later = lib.Debounce(function() count = count + 1 end)
later() later() later()
Check(count == 0, "Debounce: erst im nächsten Frame")
RunTimers()
Check(count == 1, "Debounce: mehrere Aufrufe einmal ausgeführt (" .. count .. ")")
later()
RunTimers()
Check(count == 2, "Debounce: danach wieder bereit")

---------------------------------------------------------------------------
-- Secret-Helfer, Klassenfarben, RemoveKeys
---------------------------------------------------------------------------
Check(ns.AnySecret == lib.AnySecret, "ns.AnySecret aus NewAddon")
Check(lib.AnySecret(1, nil, "x") == false and lib.AnySecret(nil, Secret()) == true and lib.AnySecret() == false,
	"AnySecret: auch mit nil dazwischen")
Check(lib.AnySecretIn({ a = 1, b = "x" }) == false and lib.AnySecretIn({ a = 1, b = Secret() }) == true, "AnySecretIn")
local oldColors = RAID_CLASS_COLORS
RAID_CLASS_COLORS = { MAGE = { r = 0.25, g = 0.78, b = 0.92 } }
Check(lib.ClassColor("MAGE") == RAID_CLASS_COLORS.MAGE and lib.ClassColor("NOPE") == nil and lib.ClassColor(nil) == nil
	and lib.ClassColor(Secret()) == nil, "ClassColor: bekannt, unbekannt, nil, secret")
Check(lib.ClassColoredName("Ada", "MAGE") == "|cff40c7ebAda|r", "ClassColoredName: " .. lib.ClassColoredName("Ada", "MAGE"))
Check(lib.ClassColoredName("Bob", "NOPE") == "Bob", "ClassColoredName ohne Farbe: ungefärbt")
Check(lib.ClassColoredName("Bob", Secret(), { r = 1, g = 0.82, b = 0 }) == "|cffffd100Bob|r", "ClassColoredName: Ersatzfarbe")
local sName = Secret()
Check(lib.ClassColoredName(sName, "MAGE") == sName, "ClassColoredName: secret-Name unverändert")
RAID_CLASS_COLORS = oldColors
local t = { a = 1, keep = 2, dual = { x = 1, y = 2, deep = { z = 3 } } }
lib.RemoveKeys(t, { "a", "dual.x", "dual.deep.z", "missing.path", "dual.none" })
Check(t.a == nil and t.keep == 2 and t.dual.x == nil and t.dual.y == 2 and t.dual.deep.z == nil, "RemoveKeys mit Pfaden")

---------------------------------------------------------------------------
-- Popup.Confirm, Popup.EditText
---------------------------------------------------------------------------
local accepted
lib.Popup.Confirm("QNTEST_CONFIRM", "Really %s?", DELETE, function(data) accepted = data end)   -- do not translate
local d = StaticPopupDialogs.QNTEST_CONFIRM
Check(d.button1 == DELETE and d.button2 == CANCEL and d.timeout == 0 and d.hideOnEscape == 1, "Confirm: Knöpfe und Verhalten")
d.OnAccept(nil, { key = 5 })
Check(accepted and accepted.key == 5, "Confirm: onAccept(data)")
local stored = "alt"
lib.Popup.EditText("QNTEST_EDIT", "Text:", function() return stored end, function(v) stored = v end, 42)
d = StaticPopupDialogs.QNTEST_EDIT
Check(d.hasEditBox == 1 and d.maxLetters == 42 and d.button1 == ACCEPT and d.EditBoxOnEscapePressed == StaticPopup_StandardEditBoxOnEscapePressed,
	"EditText: Eingabefeld, Länge, Escape wie Blizzard")
local box = CreateFrame("EditBox")
local dialog = CreateFrame("Frame")
box._parent = dialog
dialog.GetEditBox = function() return box end
d.OnShow(dialog)
Check(box:GetText() == "alt", "EditText: bisheriger Text beim Öffnen")
box:SetText("neu")
d.OnAccept(dialog)
Check(stored == "neu", "EditText: Annehmen übernimmt")
box:SetText("enter")
d.EditBoxOnEnterPressed(box)
Check(stored == "enter" and not dialog:IsShown(), "EditText: Enter übernimmt und schließt")

---------------------------------------------------------------------------
-- Profiles.Register (Name aus NewAddon, obsolete), store:Set, store:SetValues, S.SetIn
---------------------------------------------------------------------------
qnTestDB = { profiles = { ["account:Raid"] = { old = 1, keep = 2, dual = { uiOnMain = true, side = "LEFT" } } }, global = {} }
local pns = {}
lib.NewAddon(pns, "qnTestProfil")
local upgraded
local applies = 0
local store = lib.Profiles.Register({
	ns = pns, sv = "qnTestDB", defaults = { a = 1, b = 2, keep = 0, dual = { side = "RIGHT" } },
	obsolete = { "old", "dual.uiOnMain" },
	upgrade = function(db) if db.old then upgraded = db.old end end,
})
local prof = qnTestDB.profiles["account:Raid"]
Check(store.name == "qnTestProfil" and lib.Profiles.stores.qnTestProfil == store, "Register: Name aus NewAddon")
Check(upgraded == 1 and prof.old == nil and prof.dual.uiOnMain == nil and prof.keep == 2 and prof.dual.side == "LEFT",
	"obsolete: nach upgrade gelöscht, übrige Werte bleiben")
local PB = lib.Settings.New({ store = store, prefix = "QNTESTP_", apply = function() applies = applies + 1 end })
local pc = lib.Settings.NewCategory(pns, "qnTestProfil", function() end)
PB:Slider(pc, "a", "A", 0, 10, 1)
local seen = {}
SETTINGS.QNTESTP_A:SetValueChangedCallback(function(_, v) seen[#seen + 1] = v end)
store:Set("a", 5)
Check(pns.db.a == 5 and seen[#seen] == 5 and applies == 1, "store:Set über die Einstellung (Rückruf, apply)")
store:Set("b", 7)
Check(pns.db.b == 7 and applies == 2, "store:Set ohne Steuerelement: schreiben und apply")
applies = 0
seen = {}
store:SetValues({ a = 3, b = 4 })
Check(pns.db.a == 3 and pns.db.b == 4 and applies == 1 and seen[#seen] == 3 and SETTINGS.QNTESTP_A:GetValue() == 3,
	"store:SetValues: ein apply, Einstellungsfenster neu eingelesen (Rückruf des Baukastens stumm)")
Check(lib.Settings.SetIn({ PB }, "a", 9) == true and pns.db.a == 9 and lib.Settings.SetIn({ PB }, "zzz", 1) == false and pns.db.zzz == nil,
	"S.SetIn: nur mit Steuerelement")

---------------------------------------------------------------------------
-- Lage: AnchorFactors, PointOffset, NearestCorner (verschobenes UIParent, Skalierungen)
---------------------------------------------------------------------------
local function Fake(l, b, w, h, eff, scale)
	return { GetLeft = function() return l end, GetBottom = function() return b end,
		GetWidth = function() return w end, GetHeight = function() return h end,
		GetEffectiveScale = function() return eff end, GetScale = function() return scale or 1 end }
end
local fx, fy = lib.AnchorFactors("TOPLEFT")
local cx, cy = lib.AnchorFactors("CENTER")
local rx, ry = lib.AnchorFactors("BOTTOMRIGHT")
local lx, ly = lib.AnchorFactors("LEFT")
Check(fx == 0 and fy == 1 and cx == 0.5 and cy == 0.5 and rx == 1 and ry == 0 and lx == 0 and ly == 0.5, "AnchorFactors")
local realUI = UIParent
UIParent = Fake(100, 50, 1000, 800, 0.8)   -- verschoben und verkleinert
local fr = Fake(300, 200, 100, 50, 1.6, 2)
local x, y = lib.PointOffset(fr, "TOPLEFT", "BOTTOMLEFT")
Check(math.abs(x - 250) < 1e-9 and math.abs(y - 225) < 1e-9, ("PointOffset in Einheiten des Rahmens: %s, %s"):format(x, y))
x, y = lib.PointOffset(fr, "TOPLEFT", "BOTTOMLEFT", true)
Check(math.abs(x - 500) < 1e-9 and math.abs(y - 450) < 1e-9, ("PointOffset in Einheiten von UIParent: %s, %s"):format(x, y))
x, y = lib.PointOffset(fr, "CENTER", "CENTER", true)
Check(math.abs(x - 100) < 1e-9 and math.abs(y - 0) < 1e-9, ("PointOffset Mitte zu Mitte: %s, %s"):format(x, y))
Check(lib.NearestCorner(fr) == "BOTTOMRIGHT" and lib.NearestCorner(fr, "TOPLEFT") == "TOPLEFT"
	and lib.NearestCorner(Fake(100, 500, 10, 10, 0.8)) == "TOPLEFT", "NearestCorner")
Check(lib.PointOffset(Fake(nil, nil, 10, 10, 1), "CENTER", "CENTER") == nil, "PointOffset ohne Lage: nil")
UIParent = realUI

---------------------------------------------------------------------------
-- Visible: Bereich, Anbieter, Move, MoveAndReport, Keep
---------------------------------------------------------------------------
local V = lib.Visible
local CL = core.L
-- Rahmen mit Lage l, b, w, h (UIParent bei 0,0, Skalierung 1); SetPoint verschiebt ihn
local function Place(f, l, b, w, h)
	f.GetLeft = function() return l end
	f.GetBottom = function() return b end
	f.GetWidth = function() return w end
	f.GetHeight = function() return h end
	f.SetPoint = function(self, p, rel, rp, px, py)
		self._points = self._points or {}
		self._points[#self._points + 1] = { p, rel, rp, px, py }
		local fx2, fy2 = lib.AnchorFactors(p)
		local rx2, ry2 = lib.AnchorFactors(rp)
		l, b = rx2 * 1920 + px - fx2 * w, ry2 * 1080 + py - fy2 * h
	end
	return function() return l, b end
end
local area = V.Area()
Check(#area == 1 and area[1].l == 0 and area[1].r == 1920 and area[1].b == 0 and area[1].t == 1080, "ohne Anbieter: Bereich = UIParent")
local frac = V.VisibleFraction({ l = 0, r = 100, b = 0, t = 100 }, { { l = 0, r = 52, b = 0, t = 100 } })
Check(math.abs(frac - 50 / 96) < 1e-9, "VisibleFraction mit Toleranz 2: " .. frac)
Check(V.VisibleFraction({ l = -1, r = 1921, b = -1, t = 1081 }, area) > 0.9999, "Überstand bis 2 Einheiten zählt als sichtbar")

local mf = CreateFrame("Frame")
local pos = Place(mf, 1850, 500, 100, 50)
local moved, why = V.Move(mf)
local ml, mb = pos()
Check(moved == true and ml == 1820 and mb == 500, ("Move: auf dem kürzesten Weg zurück (%s, %s)"):format(ml, mb))
Check(mf._points[#mf._points][1] == "TOPLEFT" and mf._points[#mf._points][3] == "BOTTOMLEFT", "Move: neu verankert TOPLEFT an BOTTOMLEFT")
moved, why = V.Move(mf)
Check(moved == false and why == "visible", "Move: schon sichtbar")
Place(mf, 1850, 500, 100, 50)
mf.IsProtected = function() return true end
QN_COMBAT = true
moved, why = V.Move(mf)
QN_COMBAT = false
Check(moved == false and why == "combat", "Move: geschützt im Kampf")
mf.IsProtected = nil
mf.IsForbidden = function() return true end
Check(select(2, V.Move(mf)) == "forbidden" and select(2, V.Move(nil)) == "forbidden", "Move: verboten bzw. kein Rahmen")
mf.IsForbidden = nil
-- Rand außerhalb des Rahmens (ClampRectInsets)
pos = Place(mf, 1810, 500, 100, 50)
mf.GetClampRectInsets = function() return -5, 15, 5, -5 end
Check(V.Move(mf) == false, "ohne insets: Rahmen selbst sichtbar")
moved = V.Move(mf, { insets = true })
ml = pos()
Check(moved and ml == 1805, "mit insets: Rand ins Bild geholt: " .. tostring(ml))
-- Anbieter: zwei Monitore mit Lücke dazwischen
V.SetAreaProvider(function() return { { l = 0, r = 1000, b = 0, t = 1080 }, { l = 1500, r = 2500, b = 0, t = 1080 } } end)
pos = Place(mf, 1100, 500, 100, 50)
mf.GetClampRectInsets = nil
V.Move(mf)
ml = pos()
Check(ml == 900, "Anbieter: in den nächsten Bereich (900): " .. tostring(ml))
pos = Place(mf, 1600, 500, 100, 50)
Check(V.Move(mf) == false, "Anbieter: auf dem 2. Bereich sichtbar")
V.SetAreaProvider(nil)
Check(#V.Area() == 1 and V.Area()[1].r == 1920, "Anbieter entfernt: wieder UIParent")
-- Meldungen
chat = {}
Place(mf, 1850, 500, 100, 50)
local m1 = V.MoveAndReport(mf, "Test frame", ns.Print)   -- do not translate
local m2, w2 = V.MoveAndReport(mf, "Test frame", ns.Print)   -- do not translate
mf.IsForbidden = function() return true end
V.MoveAndReport(mf, "Test frame", ns.Print)   -- do not translate
mf.IsForbidden = nil
Check(m1 == true and m2 == false and w2 == "visible", "MoveAndReport: Rückgabe wie Move")
Check(#chat == 3 and chat[1]:find(CL["%s moved into the visible area."]:format("Test frame"), 1, true)
	and chat[2]:find(CL["%s is already in the visible area."]:format("Test frame"), 1, true)
	and chat[3]:find(CL["%s cannot be moved."]:format("Test frame"), 1, true), "MoveAndReport: Meldungen")
chat = {}
Place(mf, 1850, 500, 100, 50)
mf.IsProtected = function() return true end
QN_COMBAT = true
V.MoveAndReport(mf, "Test frame", ns.Print)   -- do not translate
QN_COMBAT = false
mf.IsProtected = nil
Check(chat[1] and chat[1]:find(CL["%s is protected – cannot be moved in combat."]:format("Test frame"), 1, true), "MoveAndReport: Kampf")
-- Notify / OnAreaChanged: ein Fehler hält die übrigen nicht auf
local heard = 0
local thrown = false
V.OnAreaChanged(function() if not thrown then thrown = true error("Absicht") end end)
V.OnAreaChanged(function() heard = heard + 1 end)
errors = {}
geterrorhandler = function() return function(e) errors[#errors + 1] = tostring(e) end end
V.Notify()
geterrorhandler = oldHandler
Check(heard == 1 and #errors == 1, "Notify: alle Zuhörer, Fehler über geterrorhandler")
-- Keep: nach dem Laden, neuer Fenstergröße und Änderung des Bereichs, nur wenn eingeschaltet
local kf = CreateFrame("Frame")
local kpos = Place(kf, 1850, 500, 100, 50)
local on, movedCalls = false, 0
local check = V.Keep(kf, function() return on end, function() movedCalls = movedCalls + 1 end)
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(kpos() == 1850 and movedCalls == 0, "Keep: ausgeschaltet nichts")
on = true
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(kpos() == 1820 and movedCalls == 1, "Keep: nach dem Laden verschoben, onMoved")
kpos = Place(kf, 1850, 500, 100, 50)
FireEvent("DISPLAY_SIZE_CHANGED") RunTimers()
Check(kpos() == 1820 and movedCalls == 2, "Keep: nach neuer Fenstergröße")
kpos = Place(kf, 1850, 500, 100, 50)
V.Notify() RunTimers()
Check(kpos() == 1820 and movedCalls == 3, "Keep: nach Änderung des Bereichs")
kpos = Place(kf, 1850, 500, 100, 50)
check() check()
Check(kpos() == 1850, "check(): erst im nächsten Frame")
RunTimers()
Check(kpos() == 1820 and movedCalls == 4, "check(): einmal geprüft")
FireEvent("PLAYER_ENTERING_WORLD") RunTimers()
Check(movedCalls == 4, "Keep: schon sichtbar – kein onMoved")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
