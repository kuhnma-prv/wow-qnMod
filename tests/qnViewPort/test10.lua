-- Szenario 10: qnViewPort – Größe der Zonenkarte (Seite „Platzierung“, Option zoneMapScale)
--   * 100 %: Reiter und Karte bleiben unberührt
--   * Regler: Reiter und Karte gleich groß, Reiter behält seine Mitte, Blizzards gemerkte Lage folgt
--   * mit Platzierung legt PlaceZoneMap den Reiter, ScaleZoneMap verankert ihn nicht neu
--   * zurück auf 100 %: eigene Änderung zurückgenommen, danach wieder unberührt
--   * geladen erst nach qnViewPort: Größe beim Laden von Blizzard_BattlefieldMap

qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { global = {}, profiles = { ["account:Raid"] = { dual = { enabled = true } } } }

LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(3)
RunTimers()

local d = vp.db.dual
Check(d.zoneMapScale == 1, "Vorgabe 100 %")

-- Blizzard_BattlefieldMap lädt bei Bedarf (nach qnViewPort)
local tab = CreateFrame("Button", "BattlefieldMapTab", UIParent)
tab:SetSize(64, 32)
local map = CreateFrame("Frame", "BattlefieldMapFrame", UIParent)
map:SetSize(300, 200)
BattlefieldMapOptions = { opacity = 0.7, locked = true }
FireEvent("ADDON_LOADED", "Blizzard_BattlefieldMap")
RunTimers()
Check(tab._scale == nil and map._scale == nil, "100 %: Größe unberührt")
vp.Dual.ApplyAll()
Check(tab._scale == nil and map._scale == nil and tab._points == nil, "100 %: ApplyAll fasst nichts an")

-- Regler auf 150 %
vp.Dual.SetZoneMapScale(150)
local p = (tab._points or {})[1] or {}
Check(d.zoneMapScale == 1.5 and tab._scale == 1.5 and map._scale == 1.5, "150 %: Reiter und Karte vergrößert")
Check(p[1] == "CENTER" and p[2] == UIParent and p[3] == "BOTTOMLEFT", "150 %: Reiter mit der Mitte an UIParent wie bei Blizzard")
Check(BattlefieldMapOptions.position and BattlefieldMapOptions.position.x ~= nil, "150 %: Blizzards gemerkte Lage nachgeführt")
-- auf 5 % gerundet
vp.Dual.SetZoneMapScale(123)
Check(d.zoneMapScale == 1.25 and tab._scale == 1.25, "auf 5 % gerundet")

-- mit Platzierung: nur PlaceZoneMap verankert (sichtbar), nicht an UIParent
d.zoneMap = true
map:Show()
vp.Dual.SetZoneMapScale(80)
p = (tab._points or {})[#(tab._points or {})] or {}
Check(tab._scale == 0.8 and p[1] == "BOTTOMLEFT" and p[2] ~= UIParent, "Platzierung: Reiter am Bereich, nicht neu an UIParent")
d.zoneMap = false

-- zurück auf 100 %, danach wieder unberührt
vp.Dual.SetZoneMapScale(100)
Check(tab._scale == 1 and map._scale == 1, "100 %: eigene Änderung zurückgenommen")
tab._scale, map._scale = 0.9, 0.9   -- z. B. ein anderes Addon
vp.Dual.ApplyAll()
Check(tab._scale == 0.9 and map._scale == 0.9, "100 %: fremde Größe bleibt")

-- Profilwert außerhalb des Bereichs: begrenzt
d.zoneMapScale = 5
vp.Dual.ApplyAll()
Check(tab._scale == 2 and map._scale == 2, "Wert über 200 % begrenzt")

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
