-- Szenario 3: qnViewPort – Blizzard-Oberfläche nur auf Knopfdruck auf den Hauptmonitor
-- Altes Profil mit gesetztem Haken constrainUI: darf beim Einloggen nichts mehr verschieben.
qnViewPortDB = { profiles = { ["account:Raid"] = { dual = { enabled = true, constrainUI = true } } }, global = {} }
LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
UIParent._points = nil
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(3)
RunTimers()
Check(vp.db.dual.constrainUI == nil, "alte Einstellung entfernt")
Check(UIParent._points == nil and not vp.Layout.IsUIConstrained(), "Einloggen: UIParent unberührt")

-- Knopf: auf den Hauptmonitor (3840 von 5760 Pixeln Breite)
vp.Layout.ConstrainUI()
local pts = UIParent._points
Check(vp.Layout.IsUIConstrained() and pts and pts[1][1] == "TOPLEFT" and pts[2][1] == "BOTTOMRIGHT" and pts[2][2] < 0,
	"Knopf: UIParent auf den Hauptmonitor")
-- Fenstergröße: die ausdrücklich gewählte Begrenzung bleibt (neu gerechnet, siehe Szenario 6)
UIParent._points = {}
FireEvent("DISPLAY_SIZE_CHANGED") RunTimers()
pts = UIParent._points
Check(vp.Layout.IsUIConstrained() and #pts == 2 and pts[2][1] == "BOTTOMRIGHT" and pts[2][2] < 0,
	"Fenstergröße: gewählte Begrenzung bleibt erhalten")
-- Zurücksetzen
vp.Layout.ReleaseUI()
pts = UIParent._points
Check(not vp.Layout.IsUIConstrained() and pts[#pts][2] == 0 and pts[#pts][3] == 0, "Zurücksetzen: ganzes Fenster")
-- Im Kampf nicht
QN_COMBAT = true
vp.Layout.ConstrainUI()
QN_COMBAT = false
Check(not vp.Layout.IsUIConstrained(), "im Kampf nichts verschoben")
-- Zwei-Monitor-Modus aus setzt zurück
vp.Layout.ConstrainUI()
SlashCmdList.QNVIEWPORT("dual off") RunTimers()
Check(not vp.Layout.IsUIConstrained(), "Modus aus: Oberfläche wieder über das ganze Fenster")
print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
