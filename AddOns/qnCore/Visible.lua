-- qnCore: Rahmen in den sichtbaren Bereich holen.
-- Sichtbarer Bereich: Liste von Rechtecken in Einheiten bei wirksamer Skalierung 1, Ursprung unten
-- links ({ l, r, t, b }, wie GetLeft() * GetEffectiveScale()). Ohne Anbieter ist es UIParent; qnViewPort
-- meldet sich mit SetAreaProvider an (Teile des Spielfensters, die auf einem Monitor zu sehen sind)
-- und ruft nach jeder Änderung der Anordnung Notify auf.
--
--   qnCore.Visible.Move(frame, opts)                    -> true | false, "combat"/"visible"/"forbidden"
--   qnCore.Visible.MoveAndReport(frame, label, print, opts)  dasselbe mit Chatmeldung
--   check = qnCore.Visible.Keep(frame, enabledFn, onMoved, opts)   für "Automatisch im sichtbaren Bereich halten"
-- opts.insets = true: ClampRectInsets des Rahmens einrechnen (Rand außerhalb des Rahmens).

local _, ns = ...
local lib = qnCore
local L = ns.L

local Visible = {}
lib.Visible = Visible

local TOLERANCE = 2   -- Einheiten, die ein Rahmen überstehen darf (Schatten, Ränder)
local KEEP_DELAY = 1.5   -- nach dem Laden bzw. einer neuen Fenstergröße (qnViewPort ordnet vorher an)

---------------------------------------------------------------------------
-- Bereich
---------------------------------------------------------------------------

local provider
local listeners = {}

-- Rechteck eines Rahmens { l, r, t, b } oder nil, solange er keine Lage hat.
-- insets = true: ClampRectInsets einrechnen; eine Tabelle { links, rechts, oben, unten } ebenso.
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

-- fn() liefert die Rechtecke des sichtbaren Bereichs (qnViewPort); nil = wieder UIParent.
function Visible.SetAreaProvider(fn)
	provider = fn
end

function Visible.Area()
	if provider then
		return provider()
	end
	return { Visible.FrameAbs(UIParent) }
end

-- fn() nach jeder Änderung des Bereichs
function Visible.OnAreaChanged(fn)
	listeners[#listeners + 1] = fn
end

-- Der Anbieter meldet einen geänderten Bereich; ein Fehler hält die übrigen nicht auf.
function Visible.Notify()
	for _, fn in ipairs(listeners) do
		local ok, err = pcall(fn)
		if not ok then
			geterrorhandler()(err)
		end
	end
end

---------------------------------------------------------------------------
-- Rechnen
---------------------------------------------------------------------------

local function Inside(x, y, rects)
	for _, r in ipairs(rects) do
		if x >= r.l and x <= r.r and y >= r.b and y <= r.t then
			return true
		end
	end
	return false
end

-- Anteil (0..1) der Fläche von a, der im Bereich rects liegt (Zerlegung an allen Kanten).
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

-- Ist a vollständig von der Vereinigung der rects bedeckt?
local function Covered(a, rects)
	return Visible.VisibleFraction(a, rects) > 0.9999
end

-- Kürzeste Verschiebung (dx, dy), mit der a ganz in eines der rects passt.
-- Passt a nirgends, wird es an die obere linke Ecke des größten Rechtecks gelegt.
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
-- Verschieben
---------------------------------------------------------------------------

-- Verschiebt frame auf dem kürzesten Weg in den sichtbaren Bereich, neu verankert mit TOPLEFT an
-- UIParent BOTTOMLEFT. Rückgabe: true, wenn verschoben; sonst false und der Grund.
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

-- Wie Move, meldet das Ergebnis über printFn (z. B. ns.Print); label benennt den Rahmen im Text.
function Visible.MoveAndReport(frame, label, printFn, opts)
	local moved, why = Visible.Move(frame, opts)
	if moved then
		printFn(L["%s in den sichtbaren Bereich verschoben."]:format(label))
	elseif why == "combat" then
		printFn(L["%s ist geschützt – im Kampf nicht verschiebbar."]:format(label))
	elseif why == "visible" then
		printFn(L["%s liegt bereits im sichtbaren Bereich."]:format(label))
	else
		printFn(L["%s kann nicht verschoben werden."]:format(label))
	end
	return moved, why
end

---------------------------------------------------------------------------
-- Im sichtbaren Bereich halten
---------------------------------------------------------------------------

local kept = {}

local function CheckKept()
	for _, check in ipairs(kept) do
		check()
	end
end

-- Hält frame im sichtbaren Bereich, solange enabledFn() wahr ist: nach dem Laden der Oberfläche und
-- einer neuen Fenstergröße (je mit Verzögerung) sowie bei jeder Änderung des Bereichs. onMoved()
-- nach einer Verschiebung (z. B. Lage speichern). Liefert check(): prüft im nächsten Frame, mehrere
-- Aufrufe zusammengefasst (nach dem Ziehen, nach dem Anwenden der Einstellungen). Ist ein geschützter
-- Rahmen im Kampf nicht verschiebbar, wird die Prüfung nach dem Kampf nachgeholt.
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
