-- qnBuffMod: time formats, visibility conditions, flash timing.

local _, ns = ...
local L = ns.L

local floor, ceil = math.floor, math.ceil

---------------------------------------------------------------------------
-- Time remaining as text
-- t = time remaining in seconds, rounded up. Without showDays there are no days (hours even beyond 24 h).
---------------------------------------------------------------------------

-- largest unit, rounded up (formats 1–3)
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
	d = { L["1 day"], L["%d days"] }, h = { L["1 hour"], L["%d hours"] },
	m = { L["1 minute"], L["%d minutes"] }, s = { L["1 second"], L["%d seconds"] },
}
local SHORT = { d = L["%d day"], h = L["%d hour"], m = L["%d min"], s = L["%d sec"] }
local ABBREV = { d = "%dd", h = "%dh", m = "%dm", s = "%ds" }

local FORMATS = {}

-- 1: "1 hour / 22 minutes"
FORMATS[1] = function(t, showDays)
	local unit, n = Largest(t, showDays)
	if n == 1 then
		return LONG[unit][1]
	end
	return LONG[unit][2]:format(n)
end

-- 2: "1 hour / 22 min"
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

-- Time remaining sec (seconds, may be fractional) in format fmt (1–5)
function ns.FormatTime(sec, fmt, showDays)
	local t = ceil(math.max(0, sec))
	return (FORMATS[fmt] or FORMATS[1])(t, showDays)
end

-- Format 4 with days (sliders of the warning and flash times)
function ns.humanizeTime(sec)
	return ns.FormatTime(sec, 4, true)
end

-- Slider labels: 0 = Off
function ns.SecondsLabel(v)
	if v == 0 then
		return OFF
	end
	return ns.humanizeTime(v)
end

-- Dropdown texts of the time formats
function ns.TimeFormatEntries()
	return {
		{ 1, L["1 hour / 22 minutes"] },
		{ 2, L["1 hour / 22 min"] },
		{ 3, "1h / 22m" },
		{ 4, "1h 11m / 22m 22s" },
		{ 5, "1:11h / 22:22" },
	}
end

---------------------------------------------------------------------------
-- Updating and flashing
---------------------------------------------------------------------------

-- Interval until the next update of a time remaining
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

-- Opacity of flashing icons at time t: linear 0 → 1 in 1 s, 1 → 0 in 1 s (the same for all)
function ns.Pulse(t)
	local phase = t % 2
	if phase < 1 then
		return phase
	end
	return 2 - phase
end

---------------------------------------------------------------------------
-- Visibility conditions (macro syntax for the "visibility" state driver)
---------------------------------------------------------------------------

-- Prepare the extended condition: line breaks become ";", multiple ";" become one,
-- a trailing ";" is dropped; [bonusbar:5] is now called [possessbar].
function ns.buildCondition(text)
	local s = tostring(text or "")
	s = s:gsub("\r?\n", ";")
	s = s:gsub(";+", ";")
	s = s:gsub("^;", ""):gsub(";$", "")
	s = s:gsub("%[bonusbar:5%]", "[possessbar]")
	return s
end

-- Basic conditions from the toggles of a window (o = effective settings)
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

-- Condition of the window or nil ("Always show" mode)
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
