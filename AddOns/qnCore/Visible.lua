-- qnCore: bring frames into the visible area.
-- Visible area: list of rectangles in units at effective scale 1, origin bottom
-- left ({ l, r, t, b }, like GetLeft() * GetEffectiveScale()). Without a provider it is UIParent; qnViewPort
-- registers with SetAreaProvider (parts of the game window that are visible on a monitor)
-- and calls Notify after every change of the arrangement.
--
--   qnCore.Visible.Move(frame, opts)                    -> true | false, "combat"/"visible"/"forbidden"
--   qnCore.Visible.MoveAndReport(frame, label, print, opts)  the same with chat message
--   check = qnCore.Visible.Keep(frame, enabledFn, onMoved, opts)   for "Keep in visible area automatically"
-- opts.insets = true: include the frame's ClampRectInsets (margin outside the frame).

local _, ns = ...
local lib = qnCore
local L = ns.L

local Visible = {}
lib.Visible = Visible

local TOLERANCE = 2   -- units a frame may stick out (shadows, borders)
local KEEP_DELAY = 1.5   -- after loading or a new window size (qnViewPort arranges first)

---------------------------------------------------------------------------
-- Area
---------------------------------------------------------------------------

local provider
local listeners = {}

-- Rectangle of a frame { l, r, t, b } or nil as long as it has no position.
-- insets = true: include ClampRectInsets; a table { left, right, top, bottom } likewise.
function Visible.FrameAbs(frame, insets)
	local l, b = frame:GetLeft(), frame:GetBottom()
	if not (l and b) then
		return nil
	end
	local w, h = frame:GetWidth(), frame:GetHeight()
	local il, ir, it, ib = 0, 0, 0, 0
	if insets == true then
		il, ir, it, ib = frame:GetClampRectInsets()
	elseif type(insets) == "table" then
		il, ir, it, ib = insets[1], insets[2], insets[3], insets[4]
	end
	local s = frame:GetEffectiveScale()
	return { l = (l + (il or 0)) * s, r = (l + w + (ir or 0)) * s, t = (b + h + (it or 0)) * s, b = (b + (ib or 0)) * s }
end

-- fn() returns the rectangles of the visible area (qnViewPort); nil = back to UIParent.
function Visible.SetAreaProvider(fn)
	provider = fn
end

function Visible.Area()
	if provider then
		return provider()
	end
	return { Visible.FrameAbs(UIParent) }
end

-- fn() after every change of the area
function Visible.OnAreaChanged(fn)
	listeners[#listeners + 1] = fn
end

-- The provider reports a changed area; an error does not stop the others.
function Visible.Notify()
	for _, fn in ipairs(listeners) do
		local ok, err = pcall(fn)
		if not ok then
			geterrorhandler()(err)
		end
	end
end

---------------------------------------------------------------------------
-- Calculation
---------------------------------------------------------------------------

local function Inside(x, y, rects)
	for _, r in ipairs(rects) do
		if x >= r.l and x <= r.r and y >= r.b and y <= r.t then
			return true
		end
	end
	return false
end

-- Share (0..1) of the area of a that lies within rects (decomposition at all edges).
function Visible.VisibleFraction(a, rects)
	a = { l = a.l + TOLERANCE, r = a.r - TOLERANCE, b = a.b + TOLERANCE, t = a.t - TOLERANCE }
	if a.r <= a.l or a.t <= a.b then
		return 1
	end
	local xs, ys = { a.l, a.r }, { a.b, a.t }
	for _, r in ipairs(rects) do
		for _, x in ipairs({ r.l, r.r }) do
			if x > a.l and x < a.r then xs[#xs + 1] = x end
		end
		for _, y in ipairs({ r.b, r.t }) do
			if y > a.b and y < a.t then ys[#ys + 1] = y end
		end
	end
	table.sort(xs)
	table.sort(ys)
	local shown = 0
	for i = 1, #xs - 1 do
		for j = 1, #ys - 1 do
			local w, h = xs[i + 1] - xs[i], ys[j + 1] - ys[j]
			if w > 0 and h > 0 and Inside((xs[i] + xs[i + 1]) / 2, (ys[j] + ys[j + 1]) / 2, rects) then
				shown = shown + w * h
			end
		end
	end
	return shown / ((a.r - a.l) * (a.t - a.b))
end

-- Is a completely covered by the union of rects?
local function Covered(a, rects)
	return Visible.VisibleFraction(a, rects) > 0.9999
end

-- Shortest shift (dx, dy) with which a fits entirely into one of the rects.
-- If a fits nowhere, it is placed at the top left corner of the largest rectangle.
local function Target(a, rects)
	local w, h = a.r - a.l, a.t - a.b
	local bestX, bestY, bestCost
	for _, r in ipairs(rects) do
		local fits = w <= r.r - r.l and h <= r.t - r.b
		local nl, nt
		if fits then
			nl = math.max(r.l, math.min(a.l, r.r - w))
			nt = math.min(r.t, math.max(a.t, r.b + h))
		else
			nl, nt = r.l, r.t
		end
		local cost = math.abs(nl - a.l) + math.abs(nt - a.t)
		if not fits then
			cost = 1e9 - (r.r - r.l) * (r.t - r.b)
		end
		if not bestCost or cost < bestCost then
			bestX, bestY, bestCost = nl - a.l, nt - a.t, cost
		end
	end
	return bestX or 0, bestY or 0
end

---------------------------------------------------------------------------
-- Moving
---------------------------------------------------------------------------

-- Moves frame the shortest way into the visible area, re-anchored with TOPLEFT to
-- UIParent BOTTOMLEFT. Returns true if moved; otherwise false and the reason.
function Visible.Move(frame, opts)
	if not frame or frame:IsForbidden() then
		return false, "forbidden"
	end
	if frame:IsProtected() and InCombatLockdown() then
		return false, "combat"
	end
	local a = Visible.FrameAbs(frame, opts and opts.insets)
	local rects = Visible.Area()
	if not a or Covered(a, rects) then
		return false, "visible"
	end
	local dx, dy = Target(a, rects)
	if math.abs(dx) < 0.5 and math.abs(dy) < 0.5 then
		return false, "visible"
	end
	local x, y = lib.PointOffset(frame, "TOPLEFT", "BOTTOMLEFT")
	local s = frame:GetEffectiveScale()
	frame:ClearAllPoints()
	frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", x + dx / s, y + dy / s)
	return true
end

-- Like Move, reports the result via printFn (e.g. ns.Print); label names the frame in the text.
function Visible.MoveAndReport(frame, label, printFn, opts)
	local moved, why = Visible.Move(frame, opts)
	if moved then
		printFn(L["%s moved into the visible area."]:format(label))
	elseif why == "combat" then
		printFn(L["%s is protected – cannot be moved in combat."]:format(label))
	elseif why == "visible" then
		printFn(L["%s is already in the visible area."]:format(label))
	else
		printFn(L["%s cannot be moved."]:format(label))
	end
	return moved, why
end

---------------------------------------------------------------------------
-- Keep in the visible area
---------------------------------------------------------------------------

local kept = {}

local function CheckKept()
	for _, check in ipairs(kept) do
		check()
	end
end

-- Keeps frame in the visible area as long as enabledFn() is true: after the UI has loaded and
-- after a new window size (each with a delay) and on every change of the area. onMoved()
-- after a move (e.g. save position). Returns check(): checks in the next frame, several
-- calls merged (after dragging, after applying the settings). If a protected
-- frame cannot be moved in combat, the check is repeated after combat.
function Visible.Keep(frame, enabledFn, onMoved, opts)
	local check
	check = lib.Debounce(function()
		if not enabledFn() then
			return
		end
		local moved, why = Visible.Move(frame, opts)
		if moved then
			if onMoved then
				onMoved()
			end
		elseif why == "combat" then
			lib.DeferInCombat(check)
		end
	end)
	kept[#kept + 1] = check
	return check
end

local events = lib.NewEventHub()
events.Register("PLAYER_ENTERING_WORLD", function()
	C_Timer.After(KEEP_DELAY, CheckKept)
end)
events.Register("DISPLAY_SIZE_CHANGED", function()
	C_Timer.After(KEEP_DELAY, CheckKept)
end)
Visible.OnAreaChanged(CheckKept)
