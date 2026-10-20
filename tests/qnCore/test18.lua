-- Scenario 18: qnCore - Lua helpers: SortedKeys, Round, Hex/HexToRGB, NewSignal, Throttle, PlayerKey
LoadAddon("qnCore")
local lib = qnCore

-- SortedKeys
local keys = lib.SortedKeys({ c = 1, a = 2, b = 3 })
Check(table.concat(keys, ",") == "a,b,c", "SortedKeys ascending")
keys = lib.SortedKeys({ c = 1, a = 2, b = 3 }, function(x, y) return x > y end)
Check(table.concat(keys, ",") == "c,b,a", "SortedKeys with comparator")
Check(#lib.SortedKeys({}) == 0, "SortedKeys of an empty table")

-- Round
Check(lib.Round(1.5) == 2 and lib.Round(1.49) == 1 and lib.Round(-1.5) == -1, "Round halves upwards")

-- Hex
Check(lib.Hex(1, 0.5, 0) == "ff8000", "Hex")
local r, g, b = lib.HexToRGB("ff8000")
Check(r == 1 and math.abs(g - 128 / 255) < 1e-9 and b == 0, "HexToRGB")
Check(lib.HexToRGB("ff800") == nil and lib.HexToRGB("#ff8000") == nil and lib.HexToRGB(nil) == nil, "HexToRGB rejects other values")
Check(lib.ClassColoredName("Xlash", "WARRIOR"):match("^|cff%x%x%x%x%x%xXlash|r$") ~= nil, "ClassColoredName still colors")

-- NewSignal: order, arguments, an error does not stop the others
local signal = lib.NewSignal()
local calls = {}
signal.Add(function(a, b2) calls[#calls + 1] = "1:" .. a .. b2 end)
signal.Add(function() error("boom") end)
signal.Add(function(a) calls[#calls + 1] = "3:" .. a end)
local orig = geterrorhandler
local reported
geterrorhandler = function() return function(e) reported = e end end
signal.Fire("x", "y")
geterrorhandler = orig
Check(table.concat(calls, ",") == "1:xy,3:x" and tostring(reported):find("boom") ~= nil, "signal calls all in order, reports the error")

-- Throttle: per frame, interval as a function, reset
local count = {}
local interval = 0.2
local OnUpdate, Reset = lib.Throttle(function() return interval end, function(f) count[f] = (count[f] or 0) + 1 end)
local f1, f2 = {}, {}
OnUpdate(f1, 0.1)
OnUpdate(f2, 0.25)
Check(count[f1] == nil and count[f2] == 1, "counts per frame")
OnUpdate(f1, 0.1)
Check(count[f1] == 1, "called once the interval is reached")
OnUpdate(f1, 0.15)
Reset(f1)
OnUpdate(f1, 0.1)
Check(count[f1] == 1, "reset starts from 0 again")
interval = 0.05
OnUpdate(f1, 0.06)
Check(count[f1] == 2, "interval read on every frame")

-- PlayerKey
Check(lib.PlayerKey() == UnitName("player") .. "-" .. GetRealmName(), "PlayerKey Name-Realm")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
