-- Szenario 9: qnBuffMod – Darstellung: Zeitformate, Blinken, Layouts, Hintergrund, Farben, Leiste,
-- Ausrichtung, Schrift, Symbolzuschnitt, Texturen
local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
local E, K, L = bm.enum, bm.kind, bm.L
local F = bm.FormatTime

---------------------------------------------------------------------------
-- Zeitformate (Kriterium 45)
---------------------------------------------------------------------------
Check(F(1, 1, true) == L["1 Sekunde"] and F(60, 1, true) == L["%d Sekunden"]:format(60) and F(61, 1, true) == L["%d Minuten"]:format(2), "Format 1: Sekunden bis 60, darüber Minuten")
Check(F(3540, 1, true) == L["%d Minuten"]:format(59) and F(3541, 1, true) == L["1 Stunde"] and F(120, 1, true) == L["%d Minuten"]:format(2), "Format 1: Grenze 3540")
Check(F(86340, 1, true) == L["%d Stunden"]:format(24) and F(86341, 1, true) == L["1 Tag"] and F(86341, 1, false) == L["%d Stunden"]:format(24), "Format 1: Grenze 86340, Tage nur mit showDays")
Check(F(200000, 1, true) == L["%d Tage"]:format(3) and F(200000, 1, false) == L["%d Stunden"]:format(56), "Format 1: Tage bzw. Stunden über 24 h")
Check(F(90, 1, true) == L["%d Minuten"]:format(2) and F(9.2, 1, true) == L["%d Sekunden"]:format(10), "Format 1: aufgerundet")
Check(F(3700, 2, true) == L["%d Std"]:format(2) and F(1, 2, true) == L["%d Sek"]:format(1) and F(1800, 2, true) == L["%d Min"]:format(30)
	and F(90000, 2, true) == L["%d Tag"]:format(2), "Format 2")
Check(F(1800, 3, true) == "30m" and F(59, 3, true) == "59s" and F(90000, 3, true) == "2d" and F(90000, 3, false) == "25h", "Format 3")
Check(F(3700, 4, true) == "1h 01m" and F(59, 4, true) == "59s" and F(61, 4, true) == "1m 01s" and F(90061, 4, true) == "1d 1h"
	and F(90061, 4, false) == "25h 01m", "Format 4")
Check(F(59, 5, true) == "0:59" and F(3700, 5, true) == "1:01h" and F(90000, 5, true) == "1d, 1:00h" and F(90000, 5, false) == "25:00h", "Format 5")
Check(bm.SecondsLabel(0) == OFF and bm.SecondsLabel(90) == "1m 30s", "Regler der Warn- und Blinkzeiten: Format 4, 0 = Aus")

---------------------------------------------------------------------------
-- Blinktakt (Kriterium 47)
---------------------------------------------------------------------------
Check(bm.Pulse(0) == 0 and bm.Pulse(0.5) == 0.5 and bm.Pulse(1) == 1 and bm.Pulse(1.5) == 0.5 and bm.Pulse(2) == 0 and bm.Pulse(1000.25) == 0.25, "Puls 0 → 1 in 1 s, 1 → 0 in 1 s")

Check(bm.UpdateInterval(30) == 0.05 and bm.UpdateInterval(200) == 0.1 and bm.UpdateInterval(500) == 0.5 and bm.UpdateInterval(900) == 1
	and bm.UpdateInterval(900, true) == 0.05, "Aktualisierung: 0,05 / 0,1 / 0,5 / 1 s, blinkend 0,05 s")
-- GetTime() = 1000
AURAS.player = {
	{ name = "Arkane Intelligenz", icon = 1, applications = 0, duration = 600, expirationTime = 1300, sourceUnit = "player", spellId = 1, cancelable = true },
	{ name = "Bärenform", icon = 2, applications = 0, duration = 0, expirationTime = 0, sourceUnit = "player", spellId = 2 },
	{ name = "Fluch", icon = 4, applications = 0, duration = 30, expirationTime = 1010, sourceUnit = "target", spellId = 4, isHarmful = true, dispelName = "Magic" },
	{ name = "Zorn", icon = 3, applications = 0, duration = 600, expirationTime = 1012, sourceUnit = "player", spellId = 3, cancelable = true },
}
ENCHANTS[16] = { remainingTimeMs = 600000, chargesRemaining = 0 }
QN_TOOLTIP[16] = { "Sofortgift (10 Min)" }
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local win = bm.GetWindow(1)
local function Get(name)
	for _, e in ipairs(bm.GetEntries(1)) do if e.name == name then return e end end
end
local function Same(c, r, g, b, a)
	local function eq(x, y) return math.abs(x - y) < 1e-6 end
	return c and eq(c[1], r) and eq(c[2], g) and eq(c[3], b) and (a == nil or eq(c[4], a))
end

Check(Get("Fluch").flashing and Get("Zorn").flashing and not Get("Arkane Intelligenz").flashing and not Get("Bärenform").flashing, "Blinken bis flashTime, nie ohne Ablauf")
SetTime(1000.25)
win.frame._scripts.OnUpdate(win.frame, 0.05)
Check(Get("Fluch").entry.icon._alpha == 0.25 and Get("Zorn").entry.icon._alpha == 0.25 and Get("Arkane Intelligenz").entry.icon._alpha == 1, "alle blinkenden Symbole synchron")
SETTINGS.QNBUFFMOD_FLASHTIME:SetValue(0)
Check(not Get("Fluch").flashing and Get("Fluch").entry.icon._alpha == 1, "flashTime 0: kein Blinken")
AURAS.player[3].expirationTime = 999
FireEvent("UNIT_AURA", "player") RunTimers()
Check(not Get("Fluch").flashing, "flashTime 0: auch bei Restzeit ≤ 0 kein Blinken")
SETTINGS.QNBUFFMOD_FLASHTIME:SetValue(15)
Check(Get("Fluch").flashing, "Restzeit ≤ 0 beim Spieler (in Reichweite): blinkt")
AURAS.player[3].expirationTime = 1010
FireEvent("UNIT_AURA", "player") RunTimers()
SetTime(1000)

---------------------------------------------------------------------------
-- Leistenfarben, Leistenhintergrund, Namensfarben (Kriterium 50)
---------------------------------------------------------------------------
local d = bm.db
Check(Same(Get("Arkane Intelligenz").entry.bar._color, unpack(d.bgColorBUFF)), "Leiste Stärkungszauber")
Check(Same(Get("Bärenform").entry.bar._color, unpack(d.bgColorAURA)), "Leiste Aura")
Check(Same(Get("Fluch").entry.bar._color, unpack(d.bgColorDEBUFF)), "Leiste Schwächungszauber")
Check(Same(Get("Sofortgift").entry.bar._color, unpack(d.bgColorITEM)), "Leiste Waffenverzauberung")
local c = d.bgColorBUFF
Check(Same(Get("Arkane Intelligenz").entry.barBG._color, c[1] / 1.35, c[2] / 1.35, c[3] / 1.35, c[4] / 2), "Leistenhintergrund abgedunkelt")
SETTINGS.QNBUFFMOD_BGCOLORBUFF:SetValue("ff00ff00")
Check(Same(Get("Arkane Intelligenz").entry.bar._color, 0, 1, 0, c[4]), "Leistenfarbe wirkt sofort")
local mc = AuraUtil.GetAuraBorderColor("Magic")
SETTINGS.QNBUFFMOD_B_COLORCODEBACKGROUND1:SetValue(true)
Check(Same(Get("Fluch").entry.bar._color, mc.r, mc.g, mc.b, 1), "Schwächungszauber nach Art, deckend")
Check(Same(Get("Arkane Intelligenz").entry.nameText._textColor, 1, 0.82, 0) and Same(Get("Fluch").entry.nameText._textColor, 1, 0.82, 0), "Namen gold")
SETTINGS.QNBUFFMOD_B_COLORCODEDEBUFFS1:SetValue(true)
Check(Same(Get("Fluch").entry.nameText._textColor, mc.r, mc.g, mc.b), "Name des Schwächungszaubers nach Art")
SETTINGS.QNBUFFMOD_B_COLORCODEDEBUFFS1:SetValue(false)
SETTINGS.QNBUFFMOD_B_COLORBUFFS1:SetValue(false)
Check(Same(Get("Fluch").entry.nameText._textColor, 1, 0, 0) and Same(Get("Zorn").entry.nameText._textColor, 1, 0.82, 0), "ohne Leiste: Schwächungszauber rot")
SETTINGS.QNBUFFMOD_B_COLORBUFFS1:SetValue(true)
SETTINGS.QNBUFFMOD_B_COLORCODEBACKGROUND1:SetValue(false)
SETTINGS.QNBUFFMOD_B_COLORCODEICONS1:SetValue(true)
local fl = Get("Fluch").entry
Check(fl.border._shown and Same(fl.border._color, mc.r, mc.g, mc.b, 1) and not Get("Zorn").entry.border._shown, "Rahmen nach Art nur am Schwächungszauber")
SETTINGS.QNBUFFMOD_B_COLORCODEICONS1:SetValue(false)
Check(not Get("Fluch").entry.border._shown, "ohne Farbcode kein Rahmen")

---------------------------------------------------------------------------
-- Restzeitleiste (Kriterium 51) und Texturen (Entscheidung 7)
---------------------------------------------------------------------------
local ai = Get("Arkane Intelligenz").entry
Check(ai.bar._w == 245 * 0.5 and ai.spark._shown and ai.spark._points[1][2] == ai.bar and ai.spark._points[1][3] == "RIGHT", "Leiste proportional (300/600), Funke am Ende")
Check(ai.spark._w == math.min(20 * 2 / 3, 25) and ai.spark._h == 20 * 1.9 and ai.spark._blend == "ADD", "Funke: Größe und additiv")
SetTime(1150)
win.frame._scripts.OnUpdate(win.frame, 1)
Check(ai.bar._w == 245 * 0.25, "Leiste schrumpft mit der Restzeit")
SetTime(1000)
win.frame._scripts.OnUpdate(win.frame, 1)
local bf = Get("Bärenform").entry
Check(bf.bar._w == 245 and not bf.spark._shown, "ohne Ablauf: volle Leiste, kein Funke")
Check(ai.bar._texture == "Interface\\TargetingFrame\\UI-StatusBar" and ai.barBG._texture == "Interface\\TargetingFrame\\UI-StatusBar"
	and ai.spark._texture == "Interface\\CastingBar\\UI-CastingBar-Spark", "Blizzard-Texturen für Leiste und Funke")
SETTINGS.QNBUFFMOD_B_SHOWBUFFTIMER1:SetValue(false)
ai = Get("Arkane Intelligenz").entry
Check(ai.bar._w == 245 and not ai.spark._shown and not ai.barBG._shown, "ohne Restzeitleiste: volle Leiste, ohne Hintergrund")
SETTINGS.QNBUFFMOD_B_SHOWBUFFTIMER1:SetValue(true)
SETTINGS.QNBUFFMOD_B_SHOWTIMERBACKGROUND1:SetValue(false)
Check(not Get("Arkane Intelligenz").entry.barBG._shown, "Hintergrund der Leiste abschaltbar")
SETTINGS.QNBUFFMOD_B_SHOWTIMERBACKGROUND1:SetValue(true)

---------------------------------------------------------------------------
-- Symbolzuschnitt (Entscheidung 2)
---------------------------------------------------------------------------
local tc = Get("Zorn").entry.icon._texCoord
Check(tc[1] == 0.08 and tc[2] == 0.92 and tc[3] == 0.08 and tc[4] == 0.92, "Vorgabe: Symbol um 8 % beschnitten")
SETTINGS.QNBUFFMOD_B_NORMALICONBORDER1:SetValue(true)
tc = Get("Zorn").entry.icon._texCoord
Check(tc[1] == 0 and tc[2] == 1 and tc[3] == 0 and tc[4] == 1 and not Get("Zorn").entry.border._shown, "Standard-Symbolrahmen: ganzes Symbol, kein zusätzlicher Rahmen")
SETTINGS.QNBUFFMOD_B_NORMALICONBORDER1:SetValue(false)

---------------------------------------------------------------------------
-- Ausrichtung und Textabstände (Kriterium 52)
---------------------------------------------------------------------------
local function P(fs, i) return fs._points[i] end
SETTINGS.QNBUFFMOD_B_SHOWTIMERS1:SetValue(false)
SETTINGS.QNBUFFMOD_B_SPACINGONLEFT1:SetValue(5)
SETTINGS.QNBUFFMOD_B_SPACINGONRIGHT1:SetValue(7)
local n = Get("Zorn").entry.nameText
Check(n._justifyH == "LEFT" and P(n, 1)[1] == "LEFT" and P(n, 1)[4] == 5 and P(n, 2)[1] == "RIGHT" and P(n, 2)[4] == -7, "nur Name: Standard zur Symbolseite, Textabstände")
SETTINGS.QNBUFFMOD_B_NAMEJUSTIFYNOTIME1:SetValue(E.justify.CENTER)
n = Get("Zorn").entry.nameText
Check(n._justifyH == "CENTER" and P(n, 1)[4] == 0 and P(n, 2)[4] == 0, "Mittig ignoriert die Textabstände")
SETTINGS.QNBUFFMOD_B_NAMEJUSTIFYNOTIME1:SetValue(E.justify.RIGHT)
Check(Get("Zorn").entry.nameText._justifyH == "RIGHT", "rechtsbündig")
SETTINGS.QNBUFFMOD_B_NAMEJUSTIFYNOTIME1:SetValue(E.justify.DEFAULT)
SETTINGS.QNBUFFMOD_B_RIGHTALIGN1:SetValue(E.side.RIGHT)
Check(Get("Zorn").entry.nameText._justifyH == "RIGHT", "Symbol rechts: Standard rechtsbündig")
SETTINGS.QNBUFFMOD_B_RIGHTALIGN1:SetValue(E.side.DEFAULT)
SETTINGS.QNBUFFMOD_B_SHOWTIMERS1:SetValue(true)
SETTINGS.QNBUFFMOD_B_SHOWNAMES1:SetValue(false)
SETTINGS.QNBUFFMOD_B_TIMEJUSTIFYNONAME1:SetValue(E.justify.CENTER)
local t = Get("Zorn").entry.timeText
Check(t._justifyH == "CENTER" and P(t, 1)[4] == 0, "nur Zeit: Ausrichtung nach timeJustifyNoName1")
SETTINGS.QNBUFFMOD_B_TIMEJUSTIFYNONAME1:SetValue(E.justify.DEFAULT)
SETTINGS.QNBUFFMOD_B_SHOWNAMES1:SetValue(true)
-- Zeit neben dem Namen: Standard = auf der Seite ohne Symbol; Name nach nameJustifyWithTime1
local z = Get("Zorn").entry
Check(z.besideName and P(z.timeText, 1)[1] == "RIGHT" and P(z.timeText, 1)[4] == -7 and z.nameText._justifyH == "LEFT", "Standard: Zeit rechts (Symbol links)")
SETTINGS.QNBUFFMOD_B_NAMEJUSTIFYWITHTIME1:SetValue(E.justify.CENTER)
Check(Get("Zorn").entry.nameText._justifyH == "CENTER", "Name neben der Zeit mittig")
SETTINGS.QNBUFFMOD_B_NAMEJUSTIFYWITHTIME1:SetValue(E.justify.DEFAULT)
-- passt nicht einmal die Zeit: nur die Zeit über die ganze Leiste, bündig zur Symbolseite
SETTINGS.QNBUFFMOD_B_DETAILWIDTH1:SetValue(40)
z = Get("Zorn").entry
Check(z.timeOnly and not z.nameText._shown and z.timeText._shown and z.timeText._justifyH == "LEFT" and P(z.timeText, 1)[1] == "LEFT" and P(z.timeText, 2)[1] == "RIGHT", "schmale Leiste: nur die Zeit")
SETTINGS.QNBUFFMOD_B_DETAILWIDTH1:SetValue(245)
SETTINGS.QNBUFFMOD_B_SPACINGONLEFT1:SetValue(0)
SETTINGS.QNBUFFMOD_B_SPACINGONRIGHT1:SetValue(0)

---------------------------------------------------------------------------
-- Schriftgrößen (Kriterium 53)
---------------------------------------------------------------------------
z = Get("Zorn").entry
Check(z.nameText._font == GameFontNormal and z.timeText._font == ChatFontNormal, "Normal: GameFontNormal / ChatFontNormal")
SETTINGS.QNBUFFMOD_L_FONTSIZE:SetValue(E.font.SMALL)
z = Get("Zorn").entry
Check(z.nameText._font == GameFontNormalSmall and z.timeText._font == ChatFontSmall, "Kleiner: GameFontNormalSmall / ChatFontSmall")
SETTINGS.QNBUFFMOD_L_FONTSIZE:SetValue(E.font.LARGE)
z = Get("Zorn").entry
Check(z.nameText._font == _G.qnBuffModFontNameLarge and z.timeText._font == _G.qnBuffModFontTimeLarge and z.nameText._font ~= nil, "Größer: eigene Schriften (+2 pt)")
SETTINGS.QNBUFFMOD_L_FONTSIZE:SetValue(E.font.NORMAL)

---------------------------------------------------------------------------
-- Hintergrund und Rand (Kriterium 49)
---------------------------------------------------------------------------
local bg = win.bg
Check(bg._backdrop.bgFile == "Interface\\Tooltips\\UI-Tooltip-Background" and bg._backdrop.edgeSize == 16 and bg._backdrop.insets.left == 4, "Tooltip-Hintergrund und -Rand")
Check(Same(bg._bdColor, unpack(d.backgroundColor)) and bg._bdBorder[4] == 0, "allgemeine Hintergrundfarbe, Rand aus")
SETTINGS.QNBUFFMOD_BACKGROUNDCOLOR:SetValue("ff0000ff")
Check(Same(bg._bdColor, 0, 0, 1, 0.25), "allgemeine Farbe wirkt sofort")
SETTINGS.QNBUFFMOD_L_USECUSTOMBACKGROUNDCOLOR:SetValue(true)
SETTINGS.QNBUFFMOD_L_WINDOWBACKGROUNDCOLOR:SetValue("ffff0000")
SETTINGS.QNBUFFMOD_L_WINDOWBACKGROUNDCOLOR_ALPHA:SetValue(0.6)
Check(Same(bg._bdColor, 1, 0, 0, 0.6), "eigene Farbe des Fensters")
SETTINGS.QNBUFFMOD_L_SHOWBACKGROUND:SetValue(false)
Check(bg._bdColor[4] == 0, "Hintergrund aus: unsichtbar")
SETTINGS.QNBUFFMOD_L_SHOWBACKGROUND:SetValue(true)
SETTINGS.QNBUFFMOD_L_SHOWBORDER:SetValue(true)
Check(Same(bg._bdBorder, 1, 1, 1, 1), "weißer Rand")
SETTINGS.QNBUFFMOD_L_USEREDGELEFT:SetValue(10)
SETTINGS.QNBUFFMOD_L_USEREDGETOP:SetValue(3)
SETTINGS.QNBUFFMOD_L_USEREDGERIGHT:SetValue(2)
SETTINGS.QNBUFFMOD_L_USEREDGEBOTTOM:SetValue(1)
local p1, p2 = bg._points[1], bg._points[2]
Check(p1[1] == "TOPLEFT" and p1[4] == -14 and p1[5] == 7 and p2[1] == "BOTTOMRIGHT" and p2[4] == 6 and p2[5] == -5, "Randabstände vergrößern den Hintergrund")
local ci = win.frame._clampInsets
Check(ci[1] == -14 and ci[2] == 6 and ci[3] == 7 and ci[4] == -5 and win.frame._clamped == true, "im Bildschirm halten samt Hintergrund und Rand")
SETTINGS.QNBUFFMOD_W_CLAMPWINDOW:SetValue(false)
Check(win.frame._clamped == false, "Bildschirmhaltung abschaltbar")

---------------------------------------------------------------------------
-- Layouts 1–8 (Kriterium 48): Stil 2, Symbol 20, 2 je Zeile/Spalte, 3 Einträge
---------------------------------------------------------------------------
AURAS.player = {
	{ name = "A", icon = 1, applications = 0, duration = 0, expirationTime = 0, spellId = 1 },
	{ name = "B", icon = 2, applications = 0, duration = 0, expirationTime = 0, spellId = 2 },
	{ name = "C", icon = 3, applications = 0, duration = 0, expirationTime = 0, spellId = 3 },
}
ENCHANTS[16] = nil
FireEvent("WEAPON_ENCHANT_CHANGED")
FireEvent("UNIT_AURA", "player") RunTimers()
SETTINGS.QNBUFFMOD_B_BUTTONSTYLE:SetValue(E.style.ICON)
SETTINGS.QNBUFFMOD_L_WRAPAFTER:SetValue(2)
local WANT = {
	{ "TOPLEFT", { 0, 0 }, { 0, -20 }, { 20, 0 } },
	{ "TOPRIGHT", { 20, 0 }, { 20, -20 }, { 0, 0 } },
	{ "BOTTOMLEFT", { 0, -20 }, { 0, 0 }, { 20, -20 } },
	{ "BOTTOMRIGHT", { 20, -20 }, { 20, 0 }, { 0, -20 } },
	{ "TOPLEFT", { 0, 0 }, { 20, 0 }, { 0, -20 } },
	{ "BOTTOMLEFT", { 0, -20 }, { 20, -20 }, { 0, 0 } },
	{ "TOPRIGHT", { 20, 0 }, { 0, 0 }, { 20, -20 } },
	{ "BOTTOMRIGHT", { 20, -20 }, { 0, -20 }, { 20, 0 } },
}
for layout, want in ipairs(WANT) do
	SETTINGS.QNBUFFMOD_L_LAYOUTTYPE:SetValue(layout)
	local list = bm.GetEntries(1)
	local ok = #list == 3 and win.look.point == want[1] and win.frame._points[#win.frame._points][1] == want[1]
	local got = {}
	for i = 1, 3 do
		ok = ok and list[i].x == want[i + 1][1] and list[i].y == want[i + 1][2]
		got[#got + 1] = ("%s/%s"):format(tostring(list[i] and list[i].x), tostring(list[i] and list[i].y))
	end
	Check(ok and win.frame._w == 40 and win.frame._h == 40, ("Layout %d: Ecke %s, %s"):format(layout, tostring(win.look.point), table.concat(got, " ")))
end
-- Symbolseite bei Stil 1
SETTINGS.QNBUFFMOD_B_BUTTONSTYLE:SetValue(E.style.BAR)
SETTINGS.QNBUFFMOD_L_WRAPAFTER:SetValue(1)
SETTINGS.QNBUFFMOD_L_LAYOUTTYPE:SetValue(7)
local e1 = bm.GetEntries(1)[1].entry
Check(e1.icon._points[1][1] == "RIGHT" and e1.detail._points[1][1] == "RIGHT" and e1.detail._points[1][3] == "LEFT" and win.edges.barLeft == 0, "Layout 7: Symbol standardmäßig rechts, Leiste links")
SETTINGS.QNBUFFMOD_L_LAYOUTTYPE:SetValue(5)
e1 = bm.GetEntries(1)[1].entry
Check(e1.icon._points[1][1] == "LEFT" and win.edges.barRight == 0 and win.frame._w == 265, "Layout 5: Symbol links, Leiste in der Fläche")
SETTINGS.QNBUFFMOD_B_RIGHTALIGN1:SetValue(E.side.RIGHT)
local first = bm.GetEntries(1)[1]
Check(first.entry.icon._points[1][1] == "RIGHT" and win.edges.barLeft == 245 and win.frame._w == 20 and first.x == -245,
	("Symbol auf der Nicht-Vorgabeseite: Leiste außerhalb, Hintergrund links verbreitert (%s, %s)"):format(tostring(win.frame._w), tostring(first.x)))
SETTINGS.QNBUFFMOD_B_RIGHTALIGN1:SetValue(E.side.LEFT)
Check(bm.GetEntries(1)[1].entry.icon._points[1][1] == "LEFT" and win.edges.barLeft == 0, "Symbol links")
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
