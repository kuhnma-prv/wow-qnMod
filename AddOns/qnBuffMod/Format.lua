-- qnBuffMod: Zeitformate, Sichtbarkeitsbedingungen, Blinktakt.

local _, ns = ...
local L = ns.L

local floor, ceil = math.floor, math.ceil

---------------------------------------------------------------------------
-- Restzeit als Text
-- t = Restzeit in Sekunden, aufgerundet. Ohne showDays gibt es keine Tage (Stunden auch über 24 h).
---------------------------------------------------------------------------

-- größte Einheit, aufgerundet (Formate 1–3)
local function Largest(t, showDays)
	if showDays and t > 86340 then
		return "d", ceil(t / 86400)
	elseif t > 3540 then
		return "h", ceil(t / 3600)
	elseif t > 60 then
		return "m", ceil(t / 60)
	end
	return "s", t
end

local LONG = {
	d = { L["1 Tag"], L["%d Tage"] }, h = { L["1 Stunde"], L["%d Stunden"] },
	m = { L["1 Minute"], L["%d Minuten"] }, s = { L["1 Sekunde"], L["%d Sekunden"] },
}
local SHORT = { d = L["%d Tag"], h = L["%d Std"], m = L["%d Min"], s = L["%d Sek"] }
local ABBREV = { d = "%dd", h = "%dh", m = "%dm", s = "%ds" }

local FORMATS = {}

-- 1: "1 Stunde / 22 Minuten"
FORMATS[1] = function(t, showDays)
	local unit, n = Largest(t, showDays)
	if n == 1 then
		return LONG[unit][1]
	end
	return LONG[unit][2]:format(n)
end

-- 2: "1 Stunde / 22 Min"
FORMATS[2] = function(t, showDays)
	local unit, n = Largest(t, showDays)
	return SHORT[unit]:format(n)
end

-- 3: "1h / 22m"
FORMATS[3] = function(t, showDays)
	local unit, n = Largest(t, showDays)
	return ABBREV[unit]:format(n)
end

-- 4: "1h 11m / 22m 22s"
FORMATS[4] = function(t, showDays)
	if showDays and t > 86400 then
		return ("%dd %dh"):format(floor(t / 86400), floor(t % 86400 / 3600))
	elseif t >= 3600 then
		return ("%dh %02dm"):format(floor(t / 3600), floor(t % 3600 / 60))
	elseif t > 60 then
		return ("%dm %02ds"):format(floor(t / 60), t % 60)
	end
	return ("%ds"):format(t)
end

-- 5: "1:11h / 22:22"
FORMATS[5] = function(t, showDays)
	if showDays and t > 86400 then
		return ("%dd, %d:%02dh"):format(floor(t / 86400), floor(t % 86400 / 3600), floor(t % 3600 / 60))
	elseif t >= 3600 then
		return ("%d:%02dh"):format(floor(t / 3600), floor(t % 3600 / 60))
	end
	return ("%d:%02d"):format(floor(t / 60), t % 60)
end

-- Restzeit sec (Sekunden, auch gebrochen) im Format fmt (1–5)
function ns.FormatTime(sec, fmt, showDays)
	local t = ceil(math.max(0, sec))
	return (FORMATS[fmt] or FORMATS[1])(t, showDays)
end

-- Format 4 mit Tagen (Regler der Warn- und Blinkzeiten)
function ns.humanizeTime(sec)
	return ns.FormatTime(sec, 4, true)
end

-- Beschriftung der Regler: 0 = Aus
function ns.SecondsLabel(v)
	if v == 0 then
		return OFF
	end
	return ns.humanizeTime(v)
end

-- Auswahltexte der Zeitformate
function ns.TimeFormatEntries()
	return {
		{ 1, L["1 Stunde / 22 Minuten"] },
		{ 2, L["1 Stunde / 22 Min"] },
		{ 3, "1h / 22m" },
		{ 4, "1h 11m / 22m 22s" },
		{ 5, "1:11h / 22:22" },
	}
end

---------------------------------------------------------------------------
-- Aktualisierung und Blinken
---------------------------------------------------------------------------

-- Abstand bis zur nächsten Aktualisierung einer Restzeit
function ns.UpdateInterval(remaining, flashing)
	if flashing or remaining <= 60 then
		return 0.05
	elseif remaining <= 240 then
		return 0.1
	elseif remaining <= 540 then
		return 0.5
	end
	return 1
end

-- Deckkraft blinkender Symbole zum Zeitpunkt t: linear 0 → 1 in 1 s, 1 → 0 in 1 s (für alle gleich)
function ns.Pulse(t)
	local phase = t % 2
	if phase < 1 then
		return phase
	end
	return 2 - phase
end

---------------------------------------------------------------------------
-- Sichtbarkeitsbedingungen (Makro-Syntax für den Zustandstreiber "visibility")
---------------------------------------------------------------------------

-- Erweiterte Bedingung aufbereiten: Zeilenumbrüche werden ";", mehrfache ";" eines,
-- abschließendes ";" entfällt; [bonusbar:5] heißt heute [possessbar].
function ns.buildCondition(text)
	local s = tostring(text or "")
	s = s:gsub("\r?\n", ";")
	s = s:gsub(";+", ";")
	s = s:gsub("^;", ""):gsub(";$", "")
	s = s:gsub("%[bonusbar:5%]", "[possessbar]")
	return s
end

-- Standardbedingungen aus den Schaltern eines Fensters (o = wirksame Einstellungen)
function ns.BasicCondition(o)
	local s = ""
	if o.visHideInVehicle then
		s = s .. "[vehicleui]hide; "
	end
	if o.visHideNotVehicle then
		s = s .. "[novehicleui]hide; "
	end
	if o.visHideInCombat then
		s = s .. "[combat]hide; "
	end
	if o.visHideNotCombat then
		s = s .. "[nocombat]hide; "
	end
	return s .. "show"
end

-- Bedingung des Fensters oder nil (Modus "Immer anzeigen")
function ns.WindowCondition(o)
	if o.visWindow == ns.enum.vis.BASIC then
		return ns.BasicCondition(o)
	elseif o.visWindow == ns.enum.vis.CUSTOM then
		local s = ns.buildCondition(o.visCondition)
		if s == "" then
			return "show"
		end
		return s
	end
	return nil
end
