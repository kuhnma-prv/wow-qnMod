-- Scenario 10: qnViewPort – zone map size ("Maps" page, option zoneMapScale)
--   * 100 %: tab and map stay untouched
--   * slider: tab and map equally sized, tab keeps its center, Blizzard's remembered position follows
--   * with placement PlaceZoneMap positions the tab, ScaleZoneMap does not re-anchor it
--   * back to 100 %: own change reverted, untouched again afterwards
--   * loaded only after qnViewPort: size when Blizzard_BattlefieldMap loads

qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { global = {}, profiles = { ["account:Raid"] = { dual = { enabled = true } } } }

LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(3)
RunTimers()

local d = vp.db.dual
Check(d.zoneMapScale == 1, "default 100 %")

-- Blizzard_BattlefieldMap loads on demand (after qnViewPort)
local tab = CreateFrame("Button", "BattlefieldMapTab", UIParent)
tab:SetSize(64, 32)
local map = CreateFrame("Frame", "BattlefieldMapFrame", UIParent)
map:SetSize(300, 200)
BattlefieldMapOptions = { opacity = 0.7, locked = true }
FireEvent("ADDON_LOADED", "Blizzard_BattlefieldMap")
RunTimers()
Check(tab._scale == nil and map._scale == nil, "100 %: size untouched")
vp.Dual.ApplyAll()
Check(tab._scale == nil and map._scale == nil and tab._points == nil, "100 %: ApplyAll touches nothing")

-- slider at 150 %
vp.Dual.SetZoneMapScale(150)
local p = (tab._points or {})[1] or {}
Check(d.zoneMapScale == 1.5 and tab._scale == 1.5 and map._scale == 1.5, "150 %: tab and map enlarged")
Check(p[1] == "CENTER" and p[2] == UIParent and p[3] == "BOTTOMLEFT", "150 %: tab with its center on UIParent as with Blizzard")
Check(BattlefieldMapOptions.position and BattlefieldMapOptions.position.x ~= nil, "150 %: Blizzard's remembered position updated")
-- rounded to 5 %
vp.Dual.SetZoneMapScale(123)
Check(d.zoneMapScale == 1.25 and tab._scale == 1.25, "rounded to 5 %")

-- with placement: only PlaceZoneMap anchors (visible), not on UIParent
d.zoneMap = true
map:Show()
vp.Dual.SetZoneMapScale(80)
p = (tab._points or {})[#(tab._points or {})] or {}
Check(tab._scale == 0.8 and p[1] == "BOTTOMLEFT" and p[2] ~= UIParent, "placement: tab on the area, not re-anchored to UIParent")
d.zoneMap = false

-- back to 100 %, untouched again afterwards
vp.Dual.SetZoneMapScale(100)
Check(tab._scale == 1 and map._scale == 1, "100 %: own change reverted")
tab._scale, map._scale = 0.9, 0.9   -- e.g. another addon
vp.Dual.ApplyAll()
Check(tab._scale == 0.9 and map._scale == 0.9, "100 %: foreign size stays")

-- profile value out of range: clamped
d.zoneMapScale = 5
vp.Dual.ApplyAll()
Check(tab._scale == 2 and map._scale == 2, "value above 200 % clamped")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
