-- Szenario 3: qnBuffMod "In sichtbaren Bereich holen"
local clicks = {}
local orig = CreateSettingsButtonInitializer
function CreateSettingsButtonInitializer(n, bt, click, ...) clicks[bt] = click return orig(n, bt, click, ...) end
local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
Check(clicks[bm.L["Move into visible area"]], "Knopf vorhanden")
local win = bm.GetWindow(1)
local f = win.frame
-- Symbolfläche 200x50 ragt rechts 150 und unten 30 aus dem Bildschirm (1920x1080), Rand 5 rundum
local L, B = 1870, -30
f.GetLeft = function() return L end
f.GetRight = function() return L + 200 end
f.GetBottom = function() return B end
f.GetTop = function() return B + 50 end
f.GetWidth = function() return 200 end
f.GetHeight = function() return 50 end
f.GetClampRectInsets = function() return -5, 5, 5, -5 end
f.ClearAllPoints = function() end
-- Rahmenpunkt immer TOPLEFT (Layout 5); Bezugspunkt beliebige Ecke von UIParent
f.SetPoint = function(_, a, r, rp, x, y)
	L = (rp:find("RIGHT") and 1920 or 0) + x
	B = (rp:find("TOP") and 1080 or 0) + y - 50
end
local printed = {}
local oldPrint = bm.Print
bm.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end
clicks[bm.L["Move into visible area"]]()
Check(L == 1920 - 205 and B == 5, ("rechts/unten ins Bild samt Rand: L=%s B=%s"):format(L, B))
local saved = bm.db.windows[1].position
Check(saved and saved[1] == "TOPLEFT" and saved[2] == "UIParent" and saved[3] == "BOTTOMRIGHT" and saved[4] == 1715 - 1920 and saved[5] == 55,
	("Position gespeichert: %s %s %s %s"):format(tostring(saved and saved[3]), tostring(saved and saved[4]), tostring(saved and saved[5]), tostring(saved and saved[6])))
Check(printed[#printed] == core.L["%s moved into the visible area."]:format(bm.L["Window %d"]:format(1)), "Meldung von qnCore")
clicks[bm.L["Move into visible area"]]()
Check(L == 1715 and B == 5, "bereits sichtbar: unverändert")
Check(printed[#printed] == core.L["%s is already in the visible area."]:format(bm.L["Window %d"]:format(1)), "Meldung: bereits sichtbar")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
