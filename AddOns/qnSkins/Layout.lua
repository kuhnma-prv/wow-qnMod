-- qnSkins: position and scale of the elements (opt-in) and their rectangles for the artwork.
--
-- All rectangles are { l, r, t, b } in units at effective scale 1 (like qnCore.Visible), so they
-- are independent of the UI scale and of how qnViewPort spreads UIParent over the monitors.
--
-- Taint: the Edit Mode systems (action bars, micro menu, status bars) override SetPoint,
-- ClearAllPoints and SetScale with Blizzard code (EditModeSystemMixin:SetPointOverride calls
-- EditModeManagerFrame:OnEditModeSystemAnchorChanged). Calling them from addon code would run that
-- code tainted. Therefore the raw widget methods are used; they run no Blizzard Lua code.
-- Blizzard moving an element again is noticed via hooksecurefunc and answered in the next frame.

local _, ns = ...
local lib = qnCore
local Visible = lib.Visible

local Layout = {}
ns.Layout = Layout

-- raw widget methods (bypass the Lua overrides of the Edit Mode systems)
local proto = CreateFrame("Frame")
local RawSetPoint, RawClearAllPoints, RawSetScale = proto.SetPoint, proto.ClearAllPoints, proto.SetScale

local targets = {}   -- key -> rectangle the element was placed at (only with "Position elements")
local watched = {}   -- frame -> true (hooks installed)

---------------------------------------------------------------------------
-- Helpers
---------------------------------------------------------------------------

-- Frame of an element: key in ns.targets or a global frame name; nil if missing.
function Layout.Frame(key)
	local f = _G[ns.targets[key] or key]
	if type(f) == "table" and f.GetObjectType and not f:IsForbidden() then
		return f
	end
	return nil
end

-- Position of point in rect (x, y)
function Layout.PointOf(rect, point)
	local fx, fy = lib.AnchorFactors(point)
	return rect.l + fx * (rect.r - rect.l), rect.b + fy * (rect.t - rect.b)
end

-- Rectangle of size w x h whose point sits at x, y
function Layout.Place(point, x, y, w, h)
	local fx, fy = lib.AnchorFactors(point)
	local l, b = x - fx * w, y - fy * h
	return { l = l, r = l + w, b = b, t = b + h }
end

-- Effective scale of UIParent: one UI unit in units at effective scale 1
function Layout.UIScale()
	return UIParent:GetEffectiveScale()
end

-- Offsets for SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", x, y) of a frame with effective scale eff
function Layout.Offsets(rect, eff)
	local ui = Visible.FrameAbs(UIParent)
	return (rect.l - ui.l) / eff, (rect.b - ui.b) / eff
end

---------------------------------------------------------------------------
-- Monitor
---------------------------------------------------------------------------

-- Visible monitor areas sorted from left to right (without qnViewPort: UIParent)
function Layout.Monitors()
	local list = {}
	for _, r in ipairs(Visible.Area()) do
		list[#list + 1] = r
	end
	table.sort(list, function(a, b)
		if a.l ~= b.l then
			return a.l < b.l
		end
		return a.t > b.t
	end)
	return list
end

-- Rectangle of the chosen monitor; automatic: the one with the center of the 3D view
-- (qnViewPort shrinks WorldFrame to the main monitor), otherwise the largest.
function Layout.Screen()
	local list = Layout.Monitors()
	local chosen = list[ns.db.monitor]
	if chosen then
		return chosen
	end
	local cx, cy = WorldFrame:GetCenter()
	if cx then
		local s = WorldFrame:GetEffectiveScale()
		cx, cy = cx * s, cy * s
		for _, r in ipairs(list) do
			if cx >= r.l and cx <= r.r and cy >= r.b and cy <= r.t then
				return r
			end
		end
	end
	local best, size
	for _, r in ipairs(list) do
		local a = (r.r - r.l) * (r.t - r.b)
		if not size or a > size then
			best, size = r, a
		end
	end
	return best or Visible.FrameAbs(UIParent)
end

---------------------------------------------------------------------------
-- Rectangles of the elements
---------------------------------------------------------------------------

-- Rectangle of an element: where it was placed, otherwise where it is; nil if unknown.
function Layout.RectOf(key)
	if targets[key] then
		return targets[key]
	end
	local f = Layout.Frame(key)
	return f and Visible.FrameAbs(f) or nil
end

-- Was the element placed by the skin (with "Position elements")?
function Layout.Placed(key)
	return targets[key] ~= nil
end

---------------------------------------------------------------------------
-- Watching the elements
---------------------------------------------------------------------------

-- Blizzard (or another addon) moved, scaled or resized an element: apply again in the next frame.
local function Changed()
	if ns.skins[ns.db.skin] then
		ns.Refresh()
	end
end

local function Watch(frame)
	if watched[frame] then
		return
	end
	watched[frame] = true
	hooksecurefunc(frame, "SetPoint", Changed)
	hooksecurefunc(frame, "SetScale", Changed)
	frame:HookScript("OnSizeChanged", Changed)
	frame:HookScript("OnShow", Changed)
end

---------------------------------------------------------------------------
-- Positioning
---------------------------------------------------------------------------

local function EditModeActive()
	return EditModeManagerFrame and EditModeManagerFrame:IsEditModeActive()
end

-- Is positioning wanted right now?
function Layout.Positioning()
	return ns.db.position and ns.skins[ns.db.skin] ~= nil and not EditModeActive()
end

-- Places the elements of skin in order; returns false if combat prevented it.
local function Apply(skin)
	local db = ns.db
	local ui = Layout.UIScale()
	local screen = Layout.Screen()
	for _, spec in ipairs(skin.frames) do
		local key, point, rel, relPoint, x, y, scale = unpack(spec)
		local frame = Layout.Frame(key)
		local relRect = rel == "screen" and screen or Layout.RectOf(rel)
		if frame and relRect then
			if frame:IsProtected() and InCombatLockdown() then
				return false
			end
			-- scale = false: the element keeps its own scale (e.g. set in its addon's options)
			local keepScale = scale == false
			scale = keepScale and frame:GetScale() or (scale or 1) * db.scale
			local parent = frame:GetParent() or UIParent
			local eff = parent:GetEffectiveScale() * scale
			local ax, ay = Layout.PointOf(relRect, relPoint)
			ax = ax + (x or 0) * ui * db.scale
			ay = ay + (y or 0) * ui * db.scale
			if rel == "screen" then
				ax = ax + db.offsetX * ui
				ay = ay + db.offsetY * ui
			end
			local rect = Layout.Place(point, ax, ay, frame:GetWidth() * eff, frame:GetHeight() * eff)
			if not keepScale then
				RawSetScale(frame, scale)
			end
			RawClearAllPoints(frame)
			RawSetPoint(frame, "BOTTOMLEFT", UIParent, "BOTTOMLEFT", Layout.Offsets(rect, eff))
			targets[key] = rect
		end
	end
	return true
end

-- Applies the active skin: elements (if wanted) and artwork.
function Layout.Refresh()
	local skin = ns.skins[ns.db.skin]
	wipe(targets)
	if skin then
		for _, spec in ipairs(skin.frames) do
			local frame = Layout.Frame(spec[1])
			if frame then
				Watch(frame)
			end
		end
		if Layout.Positioning() and not Apply(skin) then
			wipe(targets)
			lib.DeferInCombat(ns.Refresh)
		end
	end
	ns.Art.Refresh(skin)
end

-- Edit Mode name of an element (fields of EditModeSystemMixin, read only)
local function SystemName(f)
	local name = f.systemNameString
	if type(name) ~= "string" then
		return "-"
	end
	if f.addSystemIndexToName and f.systemIndex then
		return name:format(f.systemIndex)
	end
	return name
end

-- /qnskins frames: every element with its Edit Mode name, visibility, size and position
function Layout.Report()
	local keys = {}
	for key in pairs(ns.targets) do
		keys[#keys + 1] = key
	end
	table.sort(keys)
	local ui = Layout.UIScale()
	for _, key in ipairs(keys) do
		local f = Layout.Frame(key)
		if f then
			local r = Visible.FrameAbs(f)
			local where = r and ("%dx%d @ %d,%d"):format((r.r - r.l) / ui, (r.t - r.b) / ui, r.l / ui, r.b / ui) or "-"   -- do not translate
			ns.Print("%s = %s: %s, %s, %s", key, ns.targets[key], SystemName(f), f:IsShown() and ns.L["shown"] or ns.L["hidden"], where)   -- do not translate
		else
			ns.Print(ns.L["%s = %s: not found"], key, ns.targets[key])
		end
	end
end

function Layout.Init()
	local events = ns.events
	events.Register("PLAYER_ENTERING_WORLD", ns.Refresh)
	events.Register("DISPLAY_SIZE_CHANGED", ns.Refresh)
	events.Register("UI_SCALE_CHANGED", ns.Refresh)
	-- frames of addons loaded later
	events.Register("ADDON_LOADED", Changed)
	-- qnViewPort changed the monitor arrangement
	Visible.OnAreaChanged(ns.Refresh)
	-- after the Edit Mode Blizzard applies the layout again
	EventRegistry:RegisterCallback("EditMode.Exit", Changed, ns)
	EventRegistry:RegisterCallback("EditMode.Enter", Changed, ns)
	ns.Refresh()
end
