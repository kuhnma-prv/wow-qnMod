-- Scenario 13: qnViewPort – submenus of Blizzard menus stay on the monitor of their parent entry
--   * fits on the right: untouched
--   * does not fit on the right: to the left of the parent entry
--   * too low: pushed up into the monitor
--   * the hook on "MenuProxy.OnShow" is registered

LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
RunTimers()

local area = { l = 3840, r = 5760, t = 1577, b = 377 }   -- 2nd monitor (abs, y upwards)
local function Fake(entry, w, h)
	local m = { _points = {}, _w = w, _h = h }
	function m:IsShown() return true end
	function m:GetEffectiveScale() return 1 end
	function m:GetWidth() return self._w end
	function m:GetHeight() return self._h end
	function m:GetPoint(i) local p = self._points[i or 1] if p then return p[1], p[2], p[3], p[4], p[5] end end
	function m:GetNumPoints() return #self._points end
	function m:ClearAllPoints() self._points = {} end
	function m:SetPoint(...) table.insert(self._points, { ... }) end
	m._points[1] = { "TOPLEFT", entry, "TOPRIGHT", 0, 0 }
	return m
end

vp.Layout.MonitorAt = function() return area end
local rect
qnCore.Visible.FrameAbs = function(f) return f.rect end

-- 1. fits
local entry = { rect = { l = 4000, r = 4200, t = 1000, b = 980 } }
local m = Fake(entry, 200, 300)
vp.Layout.FitMenu(m)
Check(m._points[1][1] == "TOPLEFT" and m._points[1][4] == 0 and m._points[1][5] == 0, "fits: untouched")

-- 2. right edge: to the left of the entry
entry = { rect = { l = 5500, r = 5700, t = 1000, b = 980 } }
m = Fake(entry, 200, 300)
vp.Layout.FitMenu(m)
local p = m._points[1]
Check(#m._points == 1 and p[1] == "TOPRIGHT" and p[2] == entry and p[3] == "TOPLEFT", "right edge: left of the entry")

-- 3. too low: pushed up
entry = { rect = { l = 4000, r = 4200, t = 500, b = 480 } }
m = Fake(entry, 200, 300)
vp.Layout.FitMenu(m)
p = m._points[1]
Check(p[1] == "TOPLEFT" and p[5] == 177, "too low: pushed into the monitor (dy " .. tostring(p[5]) .. ")")

-- 4. root menu (chat button) cut off at the lower right: pushed in
local root = Fake(UIParent, 200, 300)
root._points[1] = { "TOPLEFT", UIParent, "BOTTOMLEFT", 5700, 200 }
root.rect = { l = 5700, r = 5900, t = 400, b = 100 }
vp.Layout.FitMenu(root)
p = root._points[1]
Check(p[1] == "TOPLEFT" and p[2] == UIParent and p[4] == 5560 and p[5] == 477, "root menu: pushed into the monitor (" .. tostring(p[4]) .. "," .. tostring(p[5]) .. ")")

-- 5. hook registered
Check(#(EventRegistry.cbs["MenuProxy.OnShow"] or {}) >= 1, "MenuProxy.OnShow callback registered")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
