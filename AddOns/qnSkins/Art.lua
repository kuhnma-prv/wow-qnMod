-- qnSkins: artwork of the skins (band, panels, 3D figures, textures).
-- Every piece is a frame of its own on UIParent in the BACKGROUND strata, placed by rectangles
-- (see Layout.lua) - never anchored to Blizzard's frames, so nothing becomes anchor-restricted.

local _, ns = ...
local L = ns.L
local Layout = ns.Layout

local Art = {}
ns.Art = Art

local pieces = {}   -- skin key -> art key -> frame

-- frame levels within the BACKGROUND strata: band below the panels below the figures
local LEVEL = { band = 1, panel = 2, texture = 3, model = 5 }

---------------------------------------------------------------------------
-- Creating the pieces
---------------------------------------------------------------------------

local function NewFrame(kind, template)
	local f = CreateFrame(kind == "model" and "PlayerModel" or "Frame", nil, UIParent, template)
	f:SetFrameStrata("BACKGROUND")
	f:EnableMouse(false)
	return f
end

-- Panel with a backdrop (background and/or border), e.g. a box around a group of elements
local function NewPanel(spec)
	local f = NewFrame("panel", "BackdropTemplate")
	local inset = spec.inset or 0
	f:SetBackdrop({
		bgFile = spec.bg,
		edgeFile = spec.edge,
		tile = true,
		tileSize = spec.tileSize or 128,
		edgeSize = spec.edgeSize or 16,
		insets = { left = inset, right = inset, top = inset, bottom = inset },
	})
	local c = spec.bgColor or {}
	f:SetBackdropColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
	c = spec.edgeColor or {}
	f:SetBackdropBorderColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
	return f
end

-- Camera, position in the frame (x = toward the camera, y = sideways, z = up), rotation, animation
local function ApplyCamera(f, s)
	f:SetPortraitZoom(0)
	f:SetCamDistanceScale(s.zoom or 1)
	local p = s.position or {}
	f:SetPosition(p[1] or 0, p[2] or 0, p[3] or 0)
	f:SetRotation(s.rotation or 0)
	if s.animation then
		f:SetAnimation(s.animation)
	end
	f:SetPaused(Art.paused or false)
end

-- SetCreature shows nothing as long as the client does not know the creature yet: ask again
-- every half second for a while (the data may still arrive from the server).
local RETRY_DELAY, RETRIES = 0.5, 20

local function RetryCreature(f, creature, tries)
	C_Timer.After(RETRY_DELAY, function()
		if f.spec.creature ~= creature or f.spec.display then
			return   -- another model meanwhile
		end
		local file = f:GetModelFileID()
		if file and file ~= 0 then
			return
		end
		f:SetCreature(creature)
		ApplyCamera(f, f.spec)
		if tries > 1 then
			RetryCreature(f, creature, tries - 1)
		end
	end)
end

-- Shows the model of spec (creature or display ID); the camera again after loading.
local function SetModel(f, spec)
	f.spec = spec
	f:ClearModel()
	if spec.display then
		f:SetDisplayInfo(spec.display)
	elseif spec.creature then
		f:SetCreature(spec.creature)
		RetryCreature(f, spec.creature, RETRIES)
	end
	ApplyCamera(f, spec)
end

local function NewModel(spec)
	local f = NewFrame("model")
	f:SetKeepModelOnHide(true)
	f:SetScript("OnModelLoaded", function(self)
		ApplyCamera(self, self.spec)
	end)
	SetModel(f, spec)
	return f
end

local function NewTexture(spec)
	local f = NewFrame("texture")
	local tex = f:CreateTexture(nil, "ARTWORK")
	tex:SetAllPoints(f)
	if spec.atlas then
		tex:SetAtlas(spec.atlas)
	else
		tex:SetTexture(spec.file)
	end
	if spec.alpha then
		tex:SetAlpha(spec.alpha)
	end
	f.tex = tex
	return f
end

-- Band: background over the full width of the monitor with a glowing line on top that rises in
-- soft curves around groups of elements. Textures and lines are pooled and placed on every refresh.
local function NewBand(spec)
	local f = NewFrame("band")
	f.textures, f.lines = { used = 0 }, { used = 0 }
	return f
end

local CREATE = { panel = NewPanel, model = NewModel, texture = NewTexture, band = NewBand }

-- Spec of a figure with the figure settings of the active profile (options page "Figures");
-- override = model tried out with /qnskins model (creature/display until the next reload).
local function FigureSpec(skinKey, spec, override)
	local db = ns.db
	local function V(prop, default)
		local v = db[ns.FigureKey(skinKey, spec.key, prop)]
		if v == nil then
			return default
		end
		return v
	end
	local s = CopyTable(spec)
	-- model by faction: { Alliance = id, Horde = id } (without a match the Alliance one)
	local faction = UnitFactionGroup("player")
	for _, k in ipairs({ "creature", "display" }) do
		if type(s[k]) == "table" then
			s[k] = s[k][faction] or s[k].Alliance
		end
	end
	s.zoom = V("zoom", spec.zoom or 1)
	s.position = { 0, V("side", 0), V("height", 0) }
	s.rotation = V("rotation", spec.rotation or 0)
	s.animation = V("animation", spec.animation or 0)
	if override then
		s.display, s.creature = override.display, override.creature
	end
	return s
end

local function Piece(skinKey, spec)
	pieces[skinKey] = pieces[skinKey] or {}
	local f = pieces[skinKey][spec.key]
	if not f then
		f = CREATE[spec.kind](spec.kind == "model" and FigureSpec(skinKey, spec) or spec)
		f.kind = spec.kind
		f:SetFrameLevel(spec.level or LEVEL[spec.kind])
		pieces[skinKey][spec.key] = f
	end
	return f
end

---------------------------------------------------------------------------
-- Rectangles
---------------------------------------------------------------------------

-- Rectangle of an element for the artwork. A hidden element counts where it would appear (its
-- Edit Mode position), but only if that lies plausibly in the lower part of the screen - hidden
-- frames may still carry the position of an earlier layout.
local function ElementRect(key, screen)
	local r = Layout.RectOf(key)
	if not r or Layout.Placed(key) then
		return r
	end
	local f = Layout.Frame(key)
	if f and not f:IsShown() then
		local lower = screen.b + (screen.t - screen.b) * 0.4
		if r.r <= r.l or r.l < screen.l or r.r > screen.r or r.t > lower or r.b < screen.b - 10 then
			return nil
		end
	end
	return r
end

-- Bounding box of the elements that have a position, plus pad (UI units) - nil if none has one.
local function Around(spec, unit, screen)
	local box
	for _, key in ipairs(spec.around) do
		local r = ElementRect(key, screen)
		if r then
			box = box and {
				l = math.min(box.l, r.l), r = math.max(box.r, r.r),
				t = math.max(box.t, r.t), b = math.min(box.b, r.b),
			} or { l = r.l, r = r.r, t = r.t, b = r.b }
		end
	end
	if not box then
		return nil
	end
	local pad = spec.pad or {}
	return {
		l = box.l - (pad[1] or 0) * unit, r = box.r + (pad[2] or 0) * unit,
		t = box.t + (pad[3] or 0) * unit, b = box.b - (pad[4] or 0) * unit,
	}
end

-- Point { rel, point, x, y } (rel = earlier artwork or element) as x, y - nil if rel is unknown
local function PointAt(p, unit, placed)
	local rel = placed[p[1]] or Layout.RectOf(p[1])
	if not rel then
		return nil
	end
	local x, y = Layout.PointOf(rel, p[2])
	return x + (p[3] or 0) * unit, y + (p[4] or 0) * unit
end

-- Rectangle between spec.from (bottom left) and spec.to (top right), or of size w x h
-- (UI units) at rel
local function Anchored(spec, unit, placed)
	if spec.from then
		local l, b = PointAt(spec.from, unit, placed)
		local r, t = PointAt(spec.to, unit, placed)
		if not (l and r) or r <= l or t <= b then
			return nil
		end
		return { l = l, r = r, b = b, t = t }
	end
	local rel = placed[spec.rel] or Layout.RectOf(spec.rel)
	if not rel then
		return nil
	end
	local x, y = Layout.PointOf(rel, spec.relPoint or spec.point)
	return Layout.Place(spec.point, x + (spec.x or 0) * unit, y + (spec.y or 0) * unit, spec.w * unit, spec.h * unit)
end

---------------------------------------------------------------------------
-- Band
---------------------------------------------------------------------------

-- Shape of the band as a line from the left to the right edge of the monitor (units at
-- effective scale 1, like all rectangles). The line is straight between its corners; every corner
-- gets a small round bend (radius spec.corner).
--   base      lowest height: top of the highest element of spec.base.rel plus pad
--   left      left of the first raised part both lines stay above the elements of base.left; at the
--             left edge base.drop higher, falling straight towards the first raised part
--   raised    every group of spec.raise is raised to its bounding box plus pad (at least rise above
--             the base); the line rises and falls with the gradient spec.grade (height per width);
--             between two raised parts it falls back to the base - if there is no room for that,
--             the two slopes meet in a V; overlapping raised parts become one
--   inner     second line (spec.inner = { gap, grade }): at the sides gap below the main line, with a
--             steeper gradient, so it rises later and runs into the main line on the raised parts
-- Returns the rectangle of the band with the points of both lines; the raised parts are also stored
-- in placed as "<band key>.<group key>".

-- Rectangle of the elements keys (bounding box) or nil
local function Box(keys, screen)
	return Around({ around = keys }, 0, screen)
end
-- Round bends: every inner corner is replaced by a short curve of radius r.
local BEND_STEPS = 10
local function RoundCorners(corners, r)
	if r <= 0 or #corners < 3 then
		return corners
	end
	local pts = { corners[1] }
	for i = 2, #corners - 1 do
		local a, p, b = corners[i - 1], corners[i], corners[i + 1]
		local l1 = math.sqrt((p[1] - a[1]) ^ 2 + (p[2] - a[2]) ^ 2)
		local l2 = math.sqrt((b[1] - p[1]) ^ 2 + (b[2] - p[2]) ^ 2)
		if l1 < 1e-6 or l2 < 1e-6 then
			pts[#pts + 1] = p
		else
			local u1x, u1y = (p[1] - a[1]) / l1, (p[2] - a[2]) / l1
			local u2x, u2y = (b[1] - p[1]) / l2, (b[2] - p[2]) / l2
			local cos = math.max(-1, math.min(1, u1x * u2x + u1y * u2y))
			local turn = math.acos(cos)
			if turn < 0.01 then
				pts[#pts + 1] = p
			else
				local d = math.min(r * math.tan(turn / 2), l1 / 2, l2 / 2)
				local t1x, t1y = p[1] - u1x * d, p[2] - u1y * d
				local t2x, t2y = p[1] + u2x * d, p[2] + u2y * d
				for k = 0, BEND_STEPS do
					local s = k / BEND_STEPS
					local w1, w2, w3 = (1 - s) * (1 - s), 2 * (1 - s) * s, s * s
					pts[#pts + 1] = { w1 * t1x + w2 * p[1] + w3 * t2x, w1 * t1y + w2 * p[2] + w3 * t2y }
				end
			end
		end
	end
	pts[#pts + 1] = corners[#corners]
	return pts
end

-- Height of a line (list of points from left to right) at x
local function YAt(pts, x)
	if x <= pts[1][1] then
		return pts[1][2]
	end
	for i = 1, #pts - 1 do
		local a, b = pts[i], pts[i + 1]
		if x <= b[1] then
			return a[2] + (b[2] - a[2]) * (x - a[1]) / math.max(b[1] - a[1], 1e-9)
		end
	end
	return pts[#pts][2]
end

local function Band(spec, unit, placed, screen)
	local base = spec.base or {}
	local ref = base.rel and Box(base.rel, screen)
	local low = (ref and ref.t or screen.b) + (base.pad or 0) * unit

	-- raised parts
	local raised = {}
	for _, group in ipairs(spec.raise or {}) do
		local box = Around(group, unit, screen)
		if box then
			local top = math.max(box.t, low + (group.rise or 0) * unit)
			if group.edge == "left" then box.l = screen.l end
			if group.edge == "right" then box.r = screen.r end
			if top > low + 0.5 then
				raised[#raised + 1] = { keys = { group.key }, l = math.max(box.l, screen.l), r = math.min(box.r, screen.r),
					b = low, t = top, toLeft = group.edge == "left", toRight = group.edge == "right" }
			end
		end
	end
	table.sort(raised, function(a, b) return a.l < b.l end)
	local merged = {}
	for _, g in ipairs(raised) do
		local last = merged[#merged]
		if last and g.l <= last.r then
			last.r = math.max(last.r, g.r)
			last.t = math.max(last.t, g.t)
			last.toRight = last.toRight or g.toRight
			tAppendAll(last.keys, g.keys)
		else
			merged[#merged + 1] = g
		end
	end
	for _, g in ipairs(merged) do
		for _, key in ipairs(g.keys) do
			placed[spec.key .. "." .. key] = g
		end
	end

	-- corners of a line with the base low (lowL left of the first raised part), the height left at
	-- the left edge and the gradient grade
	local first = merged[1]
	local function Corners(low, lowL, left, grade)
		local corners = {}
		local function Add(x, y)
			local last = corners[#corners]
			if not last or math.abs(last[1] - x) > 0.01 or math.abs(last[2] - y) > 0.01 then
				corners[#corners + 1] = { x, y }
			end
		end
		-- left edge: straight down to the foot of the first rise
		local foot = first and (first.toLeft and first.l or first.l - (first.t - lowL) / grade) or screen.r
		foot = math.max(foot, screen.l)
		if not (first and first.toLeft) then
			Add(screen.l, left)
			Add(foot, lowL)
		end
		for i, g in ipairs(merged) do
			Add(g.l, g.t)
			Add(g.r, g.t)
			if not g.toRight then
				local nextG = merged[i + 1]
				local fallEnd = g.r + (g.t - low) / grade
				if nextG then
					local riseStart = nextG.l - (nextG.t - low) / grade
					if fallEnd <= riseStart then
						Add(fallEnd, low)
						Add(riseStart, low)
					else
						-- no room for the base: the slopes meet in a V
						local x = (g.r + nextG.l) / 2 + (g.t - nextG.t) / (2 * grade)
						x = math.max(g.r, math.min(nextG.l, x))
						Add(x, g.t - (x - g.r) * grade)
					end
				else
					Add(math.min(fallEnd, screen.r), math.max(low, g.t - (screen.r - g.r) * grade))
					Add(screen.r, corners[#corners][2])
				end
			end
		end
		if not first then
			Add(screen.r, low)
		end
		return corners
	end

	-- left of the first raised part both lines stay above the elements of base.left (plus leftPad):
	-- the lowest height there (lowL) is raised accordingly; at the left edge base.drop higher
	local grade = spec.grade or 0.4
	local gap = spec.inner and (spec.inner.gap or 12) * unit or 0
	local lowL = low
	for _, key in ipairs(base.left or {}) do
		local c = ElementRect(key, screen)
		if c and (not first or c.r <= first.l) then
			lowL = math.max(lowL, c.t + (base.leftPad or 0) * unit + gap)
		end
	end
	if first and not first.toLeft and first.t < lowL + unit then
		first.t = lowL + unit
	end
	local left = lowL + (base.drop or 0) * unit
	local radius = (spec.corner or 16) * unit
	local mainCorners = Corners(low, lowL, left, grade)
	local pts = RoundCorners(mainCorners, radius)

	-- inner line (spec.inner): gap lower at the sides, steeper, running into the main line on the raised parts
	local inner, innerCorners
	if spec.inner then
		innerCorners = Corners(low - gap, lowL - gap, left - gap, spec.inner.grade or grade * 2)
		inner = RoundCorners(innerCorners, radius)
	end

	-- upper line (spec.upper = { group, reachLeft, reachRight }): only around one raised part. From the
	-- left edge it follows the main line to reachLeft before the raised part, then rises straight to its
	-- left corner; from the right corner it falls straight until it meets the inner line reachRight
	-- further right (at the latest where the inner line rises to the next raised part) and ends there.
	local up = spec.upper
	if up and inner then
		local g = placed[spec.key .. "." .. up.group]
		local reachL = (up.reachLeft or up.reach or 280) * unit
		local reachR = (up.reachRight or up.reach or 280) * unit
		if g and not g.toLeft and not g.toRight then
			local corners = {}
			local px = math.max(screen.l, g.l - reachL)
			for _, c in ipairs(mainCorners) do
				if c[1] < px - 0.01 then
					corners[#corners + 1] = c
				end
			end
			corners[#corners + 1] = { px, YAt(mainCorners, px) }
			corners[#corners + 1] = { g.l, g.t }
			corners[#corners + 1] = { g.r, g.t }
			local qx = math.min(screen.r, g.r + reachR)
			-- next raised part: stay in the dip (before the inner line rises again)
			for _, h in ipairs(merged) do
				if h.l > g.r then
					local innerGrade = spec.inner.grade or grade * 2
					qx = math.min(qx, math.max(g.r + radius * 2, h.l - (h.t - (low - gap)) / innerGrade))
					break
				end
			end
			corners[#corners + 1] = { qx, YAt(inner, qx) }   -- on the drawn (rounded) inner line
			pts = RoundCorners(corners, radius)
		end
	end

	local t = low
	for _, line in ipairs({ pts, inner or {} }) do
		for _, p in ipairs(line) do
			t = math.max(t, p[2])
		end
	end
	return { l = screen.l, r = screen.r, b = screen.b, t = t, points = pts, inner = inner, raised = merged }
end

local function NextRegion(pool, create)
	pool.used = pool.used + 1
	local r = pool[pool.used]
	if not r then
		r = create()
		pool[pool.used] = r
	end
	r:ClearAllPoints()
	r:Show()
	return r
end

-- Background in the rectangle l, b, r, t (UI units relative to the band); the texture coordinates
-- follow the position, so neighbouring pieces continue the pattern seamlessly.
local function Fill(f, spec, l, b, r, t)
	if r <= l or t <= b then
		return
	end
	local tex = NextRegion(f.textures, function() return f:CreateTexture(nil, "BACKGROUND") end)
	local size = spec.tileSize or 256
	tex:SetTexture(spec.bg, "REPEAT", "REPEAT")
	tex:SetTexCoord(l / size, r / size, -t / size, -b / size)
	local c = spec.bgColor or {}
	tex:SetVertexColor(c[1] or 1, c[2] or 1, c[3] or 1, c[4] or 1)
	tex:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", l, b)
	tex:SetPoint("TOPRIGHT", f, "BOTTOMLEFT", r, t)
end

-- glow around the line (thickness as a multiple of the line): wide and faint outside, narrower and
-- brighter inside
local GLOW = { { 1.8, 0.10 }, { 1.15, 0.25 } }

-- Line from (x1, y1) to (x2, y2), extended by ext at both ends: lines are rectangles, so without
-- the overlap the outer side of every joint would show a notch.
local function NewLine(f, x1, y1, x2, y2, thickness, ext)
	local line = NextRegion(f.lines, function() return f:CreateLine(nil, "ARTWORK") end)
	local len = math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2)
	if ext and ext > 0 and len > 0 then
		local ex, ey = (x2 - x1) / len * ext, (y2 - y1) / len * ext
		x1, y1, x2, y2 = x1 - ex, y1 - ey, x2 + ex, y2 + ey
	end
	line:SetThickness(thickness)
	line:SetStartPoint("BOTTOMLEFT", f, x1, y1)
	line:SetEndPoint("BOTTOMLEFT", f, x2, y2)
	return line
end

-- One piece of the line: glow in lineColor, on top the cord (spec.rope, repeated along the line;
-- f.ropeU continues the pattern over the pieces) or a thin line in lineColor.
local function Segment(f, spec, x1, y1, x2, y2)
	local c = spec.lineColor or { 1, 0.55, 0.15 }
	local width = spec.rope and (spec.ropeThickness or 6) or 5
	for _, g in ipairs(GLOW) do
		local line = NewLine(f, x1, y1, x2, y2, width * g[1], 0.5)
		line:SetColorTexture(c[1], c[2], c[3], g[2])
		line:SetTexCoord(0, 1, 0, 1)
	end
	if spec.rope then
		local thickness = spec.ropeThickness or 6
		local line = NewLine(f, x1, y1, x2, y2, thickness, thickness / 2)
		line:SetTexture(spec.rope, "REPEAT", "REPEAT")
		line:SetVertexColor(1, 1, 1, 1)
		-- the texture is 4 times as long as thick
		local u = f.ropeU + math.sqrt((x2 - x1) ^ 2 + (y2 - y1) ^ 2) / (thickness * 4)
		line:SetTexCoord(f.ropeU, u, 0, 1)
		f.ropeU = u
	else
		local line = NewLine(f, x1, y1, x2, y2, 2, 1)
		line:SetColorTexture(c[1], c[2], c[3], 1)
		line:SetTexCoord(0, 1, 0, 1)
	end
end

local function HideRegions(pool)
	for i = 1, pool.used do
		pool[i]:Hide()
	end
	pool.used = 0
end

-- Draws the band into f (rect from Band; f's units are UI units): background below the main line,
-- then the lines.
local function DrawBand(f, spec, rect, ui)
	HideRegions(f.textures)
	HideRegions(f.lines)
	local function X(v) return (v - rect.l) / ui end
	local function Y(v) return (v - rect.b) / ui end
	-- background in strips of at most 2 units height difference below both lines (the upper line
	-- may end before the right edge; where both lie, the strips overlap)
	for _, top in ipairs({ rect.points, rect.inner }) do
		for i = 1, #top - 1 do
			local x1, y1, x2, y2 = X(top[i][1]), Y(top[i][2]), X(top[i + 1][1]), Y(top[i + 1][2])
			local n = math.max(1, math.ceil(math.abs(y2 - y1) / 2))
			for k = 0, n - 1 do
				local xa, xb = x1 + (x2 - x1) * k / n, x1 + (x2 - x1) * (k + 1) / n
				local ya, yb = y1 + (y2 - y1) * k / n, y1 + (y2 - y1) * (k + 1) / n
				Fill(f, spec, math.min(xa, xb), 0, math.max(xa, xb), (ya + yb) / 2)
			end
		end
	end
	for _, pts in ipairs({ rect.points, rect.inner }) do
		f.ropeU = 0
		for i = 1, #pts - 1 do
			Segment(f, spec, X(pts[i][1]), Y(pts[i][2]), X(pts[i + 1][1]), Y(pts[i + 1][2]))
		end
	end
end
---------------------------------------------------------------------------
-- Refresh
---------------------------------------------------------------------------

local function HideAll(except)
	for key, list in pairs(pieces) do
		if key ~= except then
			for _, f in pairs(list) do
				f:Hide()
			end
		end
	end
end

-- Shows the artwork of skin (nil = none) at the current rectangles.
function Art.Refresh(skin)
	local skinKey = skin and ns.db.skin
	HideAll(skinKey)
	if not skin then
		return
	end
	local ui = Layout.UIScale()
	local unit = ui * ns.db.scale
	local screen = Layout.Screen()
	local placed = {}
	for _, spec in ipairs(skin.art) do
		local f = Piece(skinKey, spec)
		local rect
		if spec.kind == "panel" then
			rect = Around(spec, unit, screen)
		elseif spec.kind == "band" then
			rect = Band(spec, unit, placed, screen)
		else
			rect = Anchored(spec, unit, placed)
			-- figures: area extended downwards/upwards (page "Figures"); a model is cut off at its area
			if rect and spec.kind == "model" then
				local down = ns.db[ns.FigureKey(skinKey, spec.key, "areaBottom")] or 0
				local up = ns.db[ns.FigureKey(skinKey, spec.key, "areaTop")] or 0
				rect = { l = rect.l, r = rect.r, b = rect.b - down * unit, t = rect.t + up * unit }
			end
		end
		if rect then
			placed[spec.key] = rect
			f:ClearAllPoints()
			f:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", Layout.Offsets(rect, ui))
			f:SetSize((rect.r - rect.l) / ui, (rect.t - rect.b) / ui)
			if spec.kind == "band" then
				f.shape = rect   -- for /qnskins frames and scenarios
				DrawBand(f, spec, rect, ui)
			elseif spec.kind == "model" then
				local s = FigureSpec(skinKey, spec, f.override)
				if s.creature ~= f.spec.creature or s.display ~= f.spec.display then
					SetModel(f, s)   -- other model (e.g. faction known only now)
				else
					f.spec = s
					ApplyCamera(f, s)
				end
			end
			f:Show()
		else
			f:Hide()
		end
	end
end

-- Figures stand still in combat (option "Pause figures in combat")
function Art.UpdatePaused()
	local paused = ns.db.pauseInCombat and (InCombatLockdown() or Art.inCombat) or false
	Art.paused = paused
	for _, list in pairs(pieces) do
		for _, f in pairs(list) do
			if f.kind == "model" then
				f:SetPaused(paused)
			end
		end
	end
end

function Art.Init()
	-- InCombatLockdown() is still false during PLAYER_REGEN_DISABLED
	ns.events.Register("PLAYER_REGEN_DISABLED", function()
		Art.inCombat = true
		Art.UpdatePaused()
	end)
	ns.events.Register("PLAYER_REGEN_ENABLED", function()
		Art.inCombat = false
		Art.UpdatePaused()
	end)
end

-- Frame of a piece of the active skin (for scenarios and /qnskins model)
function Art.Get(key)
	local list = pieces[ns.db.skin]
	return list and list[key]
end

-- /qnskins frames: pieces of the active skin; for figures whether a model file was loaded
function Art.Report()
	local list = pieces[ns.db.skin]
	if not list then
		return
	end
	for key, f in pairs(list) do
		local where = ("%dx%d"):format(f:GetWidth(), f:GetHeight())   -- do not translate
		if f.kind == "model" then
			local file = f:GetModelFileID()
			ns.Print(L["%s: figure, %s, %s, model file %s, display %s"], key, f:IsShown() and L["shown"] or L["hidden"],
				where, tostring(file), tostring(f:GetDisplayInfo()))
		else
			ns.Print("%s: %s, %s, %s", key, f.kind, f:IsShown() and L["shown"] or L["hidden"], where)   -- do not translate
		end
	end
end

-- /qnskins camera: zoom, sideways and height of a figure - stored like on the page "Figures"
function Art.TryCamera(key, zoom, side, height)
	local f = Art.Get(key)
	if not f or f.kind ~= "model" or not zoom then
		return false
	end
	local skinKey = ns.db.skin
	ns.store:Set(ns.FigureKey(skinKey, key, "zoom"), zoom)
	if side then ns.store:Set(ns.FigureKey(skinKey, key, "side"), side) end
	if height then ns.store:Set(ns.FigureKey(skinKey, key, "height"), height) end
	ns.Refresh()
	ns.Print(L["%s: zoom %s, sideways %s, height %s"], key, tostring(zoom), tostring(side or f.spec.position[2]), tostring(height or f.spec.position[3]))
	return true
end

-- /qnskins model: show another model in a figure until the next reload.
-- id = creature ID or "d:<display ID>"
function Art.TryModel(key, id, animation, rotation)
	local f = Art.Get(key)
	if not f or f.kind ~= "model" then
		return false
	end
	local display = id:match("^d:(%d+)$")
	local creature = tonumber(id)
	if not display and not creature then
		return false
	end
	-- the model only until the next reload, animation and rotation are stored
	f.override = { display = tonumber(display), creature = not display and creature or nil }
	local skinKey = ns.db.skin
	if animation then ns.store:Set(ns.FigureKey(skinKey, key, "animation"), animation) end
	if rotation then ns.store:Set(ns.FigureKey(skinKey, key, "rotation"), rotation) end
	local spec = CopyTable(f.spec)
	spec.display, spec.creature = f.override.display, f.override.creature
	spec.animation = animation or spec.animation
	spec.rotation = rotation or spec.rotation
	SetModel(f, spec)
	ns.Print(L["%s: model %s, animation %s, rotation %s"], key, id, tostring(spec.animation), tostring(spec.rotation))
	return true
end
