-- Scenario 19: qnCore - window helpers: UI.Movable (canMove, onStop, handle, escape),
-- SavePoint/RestorePoint relative to a shifted UIParent, B:KeepVisible
LoadAddon("qnCore")
local lib, UI = qnCore, qnCore.UI

-- UI.Movable
local f = CreateFrame("Frame", "QnTestWindow", UIParent)
local handle = CreateFrame("Frame", nil, f)
local locked, stopped = true, 0
UI.Movable(f, { handle = handle, canMove = function() return not locked end, onStop = function(fr) stopped = stopped + (fr == f and 1 or 0) end, escape = true })
handle:GetScript("OnDragStart")(handle)
Check(not f._moving, "locked: dragging does not start")
locked = false
handle:GetScript("OnDragStart")(handle)
Check(f._moving, "unlocked: dragging starts on the frame")
handle:GetScript("OnDragStop")(handle)
Check(stopped == 1, "onStop with the frame")
local found = false
for _, name in ipairs(UISpecialFrames) do found = found or name == "QnTestWindow" end
Check(found, "escape: registered in UISpecialFrames")

-- SavePoint / RestorePoint with shifted UIParent and frame scale 2
UIParent.GetLeft = function() return 100 end
UIParent.GetBottom = function() return 50 end
f.GetLeft = function() return 150 end
f.GetBottom = function() return 300 end
f.GetWidth = function() return 40 end
f.GetHeight = function() return 20 end
f.GetEffectiveScale = function() return 2 end
local p = lib.SavePoint(f, "TOPLEFT", "BOTTOMLEFT")
-- frame top left at (300, 640) in screen units, UIParent bottom left at (100, 50)
Check(p and p[1] == "TOPLEFT" and p[2] == "BOTTOMLEFT" and p[3] == 200 and p[4] == 590,
	("SavePoint in UIParent units: %s, %s"):format(tostring(p and p[3]), tostring(p and p[4])))
lib.RestorePoint(f, p, 2)
local sp = f._points[#f._points]
Check(sp[1] == "TOPLEFT" and sp[2] == UIParent and sp[3] == "BOTTOMLEFT" and sp[4] == 100 and sp[5] == 295, "RestorePoint divides by the scale")

-- B:KeepVisible
local store = { db = { autoVisible = true }, defaults = { autoVisible = true }, builders = {} }
local B = lib.Settings.New({ store = store, prefix = "QNTEST_" })
local cat, layout = Settings.RegisterVerticalLayoutCategory("Test")
local moved = 0
local init = B:KeepVisible(cat, layout, { bar = true, move = function() moved = moved + 1 end, slash = "/qntest visible" })
Check(init ~= nil and B.settings.autoVisible ~= nil, "checkbox for autoVisible")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
