-- Scenario 16: qnGatherer - window position (journal) relative to UIParent: after dragging the
-- anchor may be attached to the screen and UIParent may be shifted (qnViewPort), the saved
-- offsets refer to UIParent anyway and restore the window at the same place.
LoadAddon("qnCore")
local gt = LoadAddon("qnGatherer")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
local DB, J = gt.DB, gt.Journal

J.Show("mine")
local f = J.frame
Check(f and f:IsShown(), "journal opened")

-- shifted UIParent (left 100, bottom 50), window after dragging: TOPLEFT relative to the screen
UIParent.GetLeft = function() return 100 end
UIParent.GetBottom = function() return 50 end
f.GetPoint = function() return "TOPLEFT", nil, "TOPLEFT", 999, 999 end
f.GetLeft = function() return 300 end
f.GetBottom = function() return 200 end
f.GetWidth = function() return 400 end
f.GetHeight = function() return 300 end
f:GetScript("OnDragStop")(f)
local pos = DB.global.windows.journal.pos
-- window top left (300, 500) minus UIParent top left (100, 50 + UIParent height)
local uiTop = 50 + UIParent:GetHeight()
local ex, ey = 300 - 100, 500 - uiTop
Check(pos and pos[1] == "TOPLEFT" and pos[2] == "TOPLEFT" and pos[3] == ex and pos[4] == math.floor(ey + 0.5),
	("saved relative to UIParent, not the raw GetPoint offsets: %s, %s"):format(tostring(pos and pos[3]), tostring(pos and pos[4])))

-- restore: anchored to UIParent with the saved offsets
J.RestorePosition(f, "journal", { "CENTER", UIParent, "CENTER", 0, 40 })
local p = f._points[#f._points]
Check(p[1] == "TOPLEFT" and p[2] == UIParent and p[3] == "TOPLEFT" and p[4] == pos[3] and p[5] == pos[4], "restored at UIParent")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
