-- Scenario 3: qnBuffMod "Move into visible area"
local clicks = {}
local orig = CreateSettingsButtonInitializer
function CreateSettingsButtonInitializer(n, bt, click, ...) clicks[bt] = click return orig(n, bt, click, ...) end
local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
Check(clicks[bm.L["Move into visible area"]], "button present")
local win = bm.GetWindow(1)
local f = win.frame
-- icon area 200x50 sticks out 150 on the right and 30 at the bottom of the screen (1920x1080), border 5 all around
local L, B = 1870, -30
f.GetLeft = function() return L end
f.GetRight = function() return L + 200 end
f.GetBottom = function() return B end
f.GetTop = function() return B + 50 end
f.GetWidth = function() return 200 end
f.GetHeight = function() return 50 end
f.GetClampRectInsets = function() return -5, 5, 5, -5 end
f.ClearAllPoints = function() end
-- frame point always TOPLEFT (layout 5); relative point any corner of UIParent
f.SetPoint = function(_, a, r, rp, x, y)
	L = (rp:find("RIGHT") and 1920 or 0) + x
	B = (rp:find("TOP") and 1080 or 0) + y - 50
end
local printed = {}
local oldPrint = bm.Print
bm.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end
clicks[bm.L["Move into visible area"]]()
Check(L == 1920 - 205 and B == 5, ("right/bottom onto the screen including border: L=%s B=%s"):format(L, B))
local saved = bm.db.windows[1].position
Check(saved and saved[1] == "TOPLEFT" and saved[2] == "UIParent" and saved[3] == "BOTTOMRIGHT" and saved[4] == 1715 - 1920 and saved[5] == 55,
	("position saved: %s %s %s %s"):format(tostring(saved and saved[3]), tostring(saved and saved[4]), tostring(saved and saved[5]), tostring(saved and saved[6])))
Check(printed[#printed] == core.L["%s moved into the visible area."]:format(bm.L["Window %d"]:format(1)), "message from qnCore")
clicks[bm.L["Move into visible area"]]()
Check(L == 1715 and B == 5, "already visible: unchanged")
Check(printed[#printed] == core.L["%s is already in the visible area."]:format(bm.L["Window %d"]:format(1)), "message: already visible")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
