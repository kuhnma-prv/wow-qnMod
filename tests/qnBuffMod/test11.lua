-- Szenario 11: qnBuffMod – Fenster im Kampf abschalten (Sichtbarkeitstreiber, Rahmenpool) und
-- Ablaufwarnungen während der Aurensperre (eingefrorene Listen)
-- Der Treiber-Verwalter ist geschützt: im Kampf scheitern Register-/UnregisterStateDriver.
local drivers = {}
function RegisterStateDriver(f, state, cond)
	if InCombatLockdown() then error("ADDON_ACTION_BLOCKED: RegisterStateDriver im Kampf") end
	drivers[f] = cond
end
function UnregisterStateDriver(f, state)
	if InCombatLockdown() then error("ADDON_ACTION_BLOCKED: UnregisterStateDriver im Kampf") end
	drivers[f] = nil
end

local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
local E, L = bm.enum, bm.L
local printed = {}
local oldPrint = bm.Print
bm.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end
local function Count(pattern)
	local n = 0
	for _, m in ipairs(printed) do if m:find(pattern, 1, true) then n = n + 1 end end
	return n
end

-- GetTime() = 1000
local function Buff(name, dur, exp)
	return { name = name, icon = 1, applications = 0, duration = dur, expirationTime = exp, sourceUnit = "player", spellId = #name, cancelable = true }
end
AURAS.player = { Buff("Arkane Intelligenz", 600, 1100), Buff("Segen der Macht", 600, 1100) }
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

---------------------------------------------------------------------------
-- Befund 1: Abschalten im Kampf
---------------------------------------------------------------------------
local win = bm.GetWindow(1)
bm.db.windows[1].visWindow = E.vis.CUSTOM
bm.db.windows[1].visCondition = "[combat] hide;show"
win:Apply()
local f, bg = win.frame, win.bg
Check(drivers[f] == "[combat] hide;show", "Sichtbarkeitstreiber gesetzt: " .. tostring(drivers[f]))
Check(#bm.GetEntries(1) == 2, "zwei Einträge")
local entries = win.entries

QN_COMBAT = true
local ok, err = pcall(win.Disable, win)
Check(ok, "Abschalten im Kampf ohne geschützten Aufruf: " .. tostring(err))
Check(win.frame == nil and drivers[f] ~= nil, "im Kampf: Treiber bleibt bis nach dem Kampf")
Check(f:GetAlpha() == 0 and bg._mouse == false, "bis dahin unsichtbar und ohne Maus")
f:Show()   -- der Treiber blendet den Rahmen wieder ein
local shown = 0
for _, e in ipairs(entries) do if e:IsShown() then shown = shown + 1 end end
Check(shown == 0 and f._scripts.OnShow == nil and f._scripts.OnUpdate == nil, "eingeblendet: keine Einträge, keine Skripte")
-- im Kampf wieder einschalten: der Rahmensatz mit Treiber kommt nicht aus dem Pool
ok, err = pcall(win.Enable, win)
Check(ok and win.frame ~= nil and win.frame ~= f and drivers[win.frame] == nil, "im Kampf: neuer Rahmensatz ohne alten Treiber: " .. tostring(err))
local f2 = win.frame
ok, err = pcall(win.Disable, win)
Check(ok, "neuer Rahmensatz ohne Treiber: sofort freigegeben: " .. tostring(err))
QN_COMBAT = false
ok, err = pcall(FireEvent, "PLAYER_REGEN_ENABLED")
RunTimers()
Check(ok, "nach dem Kampf fehlerfrei: " .. tostring(err))
Check(drivers[f] == nil and not f:IsShown(), "nach dem Kampf: Treiber abgebaut, Rahmen verborgen")
-- wieder einschalten: Rahmensatz aus dem Pool, sichtbar, eigener neuer Treiber
win:Enable()
Check(win.frame == f or win.frame == f2, "Rahmensatz aus dem Pool wiederverwendet")
Check(win.frame:GetAlpha() == 1 and drivers[win.frame] == "[combat] hide;show" and #bm.GetEntries(1) == 2, "wieder an: sichtbar, Treiber, Einträge")
win.bg._mouse = nil
win:ApplyMouse()
Check(win.bg._mouse == true, "Maus am Hintergrund wieder an")
-- außerhalb des Kampfes: Treiber sofort abgebaut
local f3 = win.frame
win:Disable()
Check(drivers[f3] == nil, "außerhalb des Kampfes: Treiber sofort abgebaut")
win:Enable()
bm.db.windows[1].visWindow = nil
bm.db.windows[1].visCondition = nil
win:Apply()

---------------------------------------------------------------------------
-- Befund 3: Aurensperre – eingefrorene Listen warnen nicht, Waffen schon
---------------------------------------------------------------------------
ENCHANTS[16] = { remainingTimeMs = 600000, chargesRemaining = 0 }
QN_TOOLTIP[16] = { "Klinge", "Sofortgift (10 Min)" }
FireEvent("WEAPON_ENCHANT_CHANGED")
QN_AURAS_SECRET = true
FireEvent("UNIT_AURA", "player") RunTimers()
-- während der Sperre gebannt; Restzeiten laufen unter die Schwelle (15 s)
table.remove(AURAS.player, 1)
SetTime(1090)
ENCHANTS[16] = { remainingTimeMs = 10000, chargesRemaining = 0 }
FireEvent("WEAPON_ENCHANT_CHANGED")
printed = {}
RunTickers()
Check(Count("Arkane Intelligenz") == 0 and Count("Segen der Macht") == 0, "Sperre: keine Warnung aus eingefrorenen Listen")
Check(#bm.Recast.list == 0 or (#bm.Recast.list == 1 and bm.Recast.list[1] == "Sofortgift"), "Sperre: keine Aura in der Erneuerungsliste")
Check(Count("Sofortgift") == 1, "Sperre: Waffenverzauberung warnt weiter")
-- Sperre vorbei, aber noch nicht neu gelesen: weiterhin keine Aurenwarnung
QN_AURAS_SECRET = false
RunTickers()
Check(Count("Segen der Macht") == 0, "nach der Sperre vor dem Neulesen: keine Warnung")
FireEvent("ADDON_RESTRICTION_STATE_CHANGED") RunTimers()
RunTickers()
Check(Count("Arkane Intelligenz") == 0, "gebannter Zauber: nie gewarnt")
Check(Count("Segen der Macht") == 1, "noch vorhandener Zauber: nach dem Neulesen gewarnt")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
