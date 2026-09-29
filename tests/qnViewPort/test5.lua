-- Szenario 5: qnViewPort ohne Titan – keine Unterseite „Titan Panel“, keine Hooks, Profilwechsel
-- und Anwenden laufen ohne Fehler.

qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { global = {}, profiles = {
	["account:Raid"] = { titan = { Bar = 2 } },
} }

LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

local tt = vp.Titan
Check(not tt.active and tt.category == nil, "ohne Titan: nicht aktiv, keine Unterseite")
Check(_G.qnViewPortTitanAnchorBar == nil, "ohne Titan: keine Anker")
Check(TitanPanelButton_OnEnter == nil and TitanPanelBarButton_Show == nil, "ohne Titan: keine Titan-Globals angelegt")
local ok, err = pcall(function()
	tt.Apply()
	SetEditModeLayout(1)
	SetEditModeLayout(3)
end)
Check(ok, "Anwenden und Profilwechsel ohne Titan: " .. tostring(err))
Check(qnViewPortDB.profiles["account:Raid"].titan.Bar == 2, "gespeicherte Titan-Auswahl bleibt erhalten")

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
