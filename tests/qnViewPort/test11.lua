-- Scenario 11: qnViewPort – Minimap tooltips and tracking menu fully on the minimap's monitor
--   * tracking tooltip (ANCHOR_LEFT) at the left edge of monitor 2: to the right instead of onto monitor 1
--   * fits: Blizzard's anchor stays
--   * tracking menu (TOPRIGHT to BOTTOMLEFT of the button): flipped to the right on monitor 2
--   * tooltip of another owner and minimap on no monitor: untouched
--   * calendar and clock tooltips (refilled in OnUpdate): fitted on every OnUpdate
--   * clock window (opt-in "clock"): below the clock on its monitor, turned off: Blizzard's anchor again

qnCoreCharDB = { layout = "account:Raid" }
qnViewPortDB = { global = {}, profiles = { ["account:Raid"] = { dual = { enabled = true } } } }

-- Blizzard_Minimap (loaded before the addons): MinimapCluster.Tracking.Button, ZoneTextButton, IndicatorFrame.MailFrame
MinimapCluster = CreateFrame("Frame", "MinimapCluster", UIParent)
MinimapCluster.Tracking = CreateFrame("Frame", nil, MinimapCluster)
local button = CreateFrame("Button", nil, MinimapCluster.Tracking)
MinimapCluster.Tracking.Button = button
function button:OnMenuOpened(menu) end   -- DropdownButtonMixin:OnMenuOpened
button:SetScript("OnEnter", function(self)   -- MiniMapTrackingButtonMixin:OnEnter
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint("BOTTOMRIGHT", self, "TOPLEFT")
	GameTooltip:Show()
end)
local zone = CreateFrame("Button", nil, MinimapCluster)
MinimapCluster.ZoneTextButton = zone
zone:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")   -- as in the client: no points set by addon code
	GameTooltip:ClearAllPoints()
	GameTooltip:Show()
end)
-- GameTime.lua: calendar button, OnEnter only SetOwner, OnUpdate fills the tooltip and shows it
local calendar = CreateFrame("Button", "GameTimeFrame", MinimapCluster)
calendar:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_BOTTOMLEFT")
	GameTooltip:ClearAllPoints()
end)
calendar:SetScript("OnUpdate", function(self)
	if GameTooltip:IsOwned(self) then
		GameTooltip:Show()
	end
end)

LoadAddon("qnCore")
local vp = LoadAddon("qnViewPort")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

-- monitors like test9; 1 unit = 1 pixel (abs = pixels, origin bottom left)
local M1 = { l = 0, r = 3840, t = 2160, b = 0 }
local M2 = { l = 3840, r = 5760, t = 2160 - 377, b = 2160 - 377 - 1200 }
vp.Layout.GetVisibleAbs = function() return { M1, M2 } end

local function Place(f, l, b, w, h)
	f.GetLeft = function() return l end
	f.GetBottom = function() return b end
	f._w, f._h = w, h
end
local function Pt(f)
	local p = f._points[#f._points]
	return p[1], p[2], p[3], p[4], p[5]
end
GameTooltip.GetPoint = function(self)
	if not self._points or #self._points == 0 then return nil end
	return Pt(self)
end

-- 1. tracking button at the left edge of monitor 2, tooltip 300 wide to the left: onto monitor 1 -> right
Place(button, 3880, 1700, 13, 14)
Place(GameTooltip, 0, 0, 300, 60)
button._scripts.OnEnter(button)
local p, rel, rp = Pt(GameTooltip)
Check(p == "BOTTOMLEFT" and rel == button and rp == "TOPLEFT",
	("tracking tooltip at the left edge of monitor 2: to the right (%s %s)"):format(tostring(p), tostring(rp)))

-- 2. fits: anchor stays
Place(button, 5000, 1000, 13, 14)
button._scripts.OnEnter(button)
Check(#GameTooltip._points == 1 and Pt(GameTooltip) == "BOTTOMRIGHT", "tracking tooltip with room: Blizzard's anchor stays")

-- 3. next frame with final size: grew wider, no longer fits to the left
Place(button, 4200, 1000, 13, 14)
button._scripts.OnEnter(button)
Check(#GameTooltip._points == 1, "immediately: fits")
GameTooltip._w = 500
RunTimers()
p, rel, rp = Pt(GameTooltip)
Check(p == "BOTTOMLEFT" and rp == "TOPLEFT", ("next frame with final width: to the right (%s %s)"):format(tostring(p), tostring(rp)))
GameTooltip._w = 300

-- 4. zone text: anchor type without points -> set as points and fitted (no room above: below, to the right)
Place(zone, 3860, 1760, 140, 12)
zone._scripts.OnEnter(zone)
p, rel, rp = Pt(GameTooltip)
Check(rel == zone and p == "TOPLEFT" and rp == "BOTTOMLEFT",
	("zone text tooltip without points: on monitor 2 (%s %s)"):format(tostring(p), tostring(rp)))

-- 5. tracking menu: Blizzard anchors TOPRIGHT to BOTTOMLEFT (reaches onto monitor 1) -> TOPLEFT
local menu = CreateFrame("Frame", nil, UIParent)
menu.GetPoint = function(self) return Pt(self) end
Place(button, 3880, 1700, 13, 14)
Place(menu, 0, 0, 140, 160)
menu:SetPoint("TOPRIGHT", button, "BOTTOMLEFT")
menu:Show()
button.menu = menu
button:OnMenuOpened(menu)
p, rel, rp = Pt(menu)
Check(p == "TOPLEFT" and rel == button and rp == "BOTTOMLEFT",
	("tracking menu at the left edge of monitor 2: to the right (%s %s)"):format(tostring(p), tostring(rp)))
RunTimers()

-- 6. menu with room: anchor stays
Place(button, 5000, 1000, 13, 14)
menu._points = nil
menu:SetPoint("TOPRIGHT", button, "BOTTOMLEFT")
button:OnMenuOpened(menu)
RunTimers()
Check(#menu._points == 1 and Pt(menu) == "TOPRIGHT", "tracking menu with room: Blizzard's anchor stays")

-- 7. tooltip owned by another frame: untouched
local other = CreateFrame("Button", nil, UIParent)
Place(button, 3880, 1700, 13, 14)
button._scripts.OnEnter(button)
GameTooltip:SetOwner(other, "ANCHOR_NONE")
GameTooltip:ClearAllPoints()
GameTooltip:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 5, 5)
RunTimers()
Check(#GameTooltip._points == 1 and select(2, Pt(GameTooltip)) == UIParent, "tooltip of another owner: untouched")

-- 8. button on no monitor (invisible strip above monitor 2): untouched
Place(button, 4500, M2.t + 100, 13, 14)
button._scripts.OnEnter(button)
RunTimers()
Check(#GameTooltip._points == 1 and Pt(GameTooltip) == "BOTTOMRIGHT", "button on no monitor: anchor stays")

-- 9. calendar button at the left edge of monitor 2 (ANCHOR_BOTTOMLEFT): filled in OnUpdate -> to the right
Place(calendar, 3870, 1740, 24, 24)
calendar._scripts.OnEnter(calendar)
calendar._scripts.OnUpdate(calendar, 0.01)
p, rel, rp = Pt(GameTooltip)
Check(rel == calendar and p == "TOPLEFT" and rp == "BOTTOMLEFT",
	("calendar tooltip at the left edge of monitor 2: to the right (%s %s)"):format(tostring(p), tostring(rp)))
-- on every OnUpdate: stays on the monitor (e.g. Blizzard's anchor type applied again)
GameTooltip:ClearAllPoints()
GameTooltip:SetPoint("TOPRIGHT", calendar, "BOTTOMLEFT")
calendar._scripts.OnUpdate(calendar, 0.01)
p = Pt(GameTooltip)
Check(p == "TOPLEFT", "calendar tooltip: fitted again on the next OnUpdate")

-- 10. Blizzard_TimeManager loads later: clock button tooltip and clock window
local clock = CreateFrame("Button", "TimeManagerClockButton", MinimapCluster)
clock:SetScript("OnEnter", function(self)
	GameTooltip:SetOwner(self, "ANCHOR_LEFT")
	GameTooltip:ClearAllPoints()
	GameTooltip:SetPoint("BOTTOMRIGHT", self, "TOPLEFT")
end)
clock:SetScript("OnUpdate", function(self)
	if GameTooltip:IsOwned(self) then
		GameTooltip:Show()
	end
end)
local tm = CreateFrame("Frame", "TimeManagerFrame", UIParent)
tm.GetPoint = function(self) return Pt(self) end
tm:Hide()
tm:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, -190)
FireEvent("ADDON_LOADED", "Blizzard_TimeManager")
Place(clock, 3900, 1700, 40, 16)
clock._scripts.OnEnter(clock)
clock._scripts.OnUpdate(clock, 0.01)
p, rel, rp = Pt(GameTooltip)
Check(rel == clock and p == "BOTTOMLEFT" and rp == "TOPLEFT",
	("clock tooltip at the left edge of monitor 2: to the right (%s %s)"):format(tostring(p), tostring(rp)))

-- clock window: option off -> Blizzard's anchor stays
Place(tm, 5500, 2000, 220, 240)
tm:Show()
p, rel = Pt(tm)
Check(#tm._points == 1 and rel == UIParent, "clock window, option off: untouched")
tm:Hide()
-- option on: below the clock, on monitor 2 (to the right: no room to the left)
vp.db.dual.clock = true
tm:Show()
p, rel, rp = Pt(tm)
Check(rel == clock and p == "TOPLEFT" and rp == "BOTTOMLEFT",
	("clock window, option on: below the clock on monitor 2 (%s %s)"):format(tostring(p), tostring(rp)))
-- turned off again: Blizzard's anchor restored
vp.db.dual.clock = false
vp.Dual.PlaceClock()
p, rel, rp = Pt(tm)
Check(p == "TOPRIGHT" and rel == UIParent and rp == "TOPRIGHT", "clock window, turned off: Blizzard's anchor restored")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
