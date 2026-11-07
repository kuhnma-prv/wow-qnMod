-- qnCore: smaller header font in Blizzard's Damage Meter windows, per profile (= Edit Mode layout).
--
-- The header texts of a window (timer, session, damage meter type, "not active") are FontStrings
-- that inherit the shared font GameFontNormalMed1; Blizzard never sets their font again. qnCore
-- therefore sets the font of each of these FontStrings directly (never of the shared font object,
-- which would change half of the interface) and adapts the height of the header bar to it.
-- Blizzard's own text size (Edit Mode) only scales the bar entries and stays untouched.
-- New windows (secondary windows) are set up through a hook on DamageMeter:SetupSessionWindow.
-- Only raw widget methods and hooksecurefunc are used: nothing is written into Blizzard's tables
-- and no Blizzard code is run from here (taint).

local _, ns = ...

local DM = {}
ns.DamageMeter = DM

DM.SIZES = { 8, 9, 10, 11, 12 }   -- choices below the default of GameFontNormalMed1

local HEADER_HEIGHT = 32      -- height of the header bar in DamageMeterSessionWindowTemplate
local TIMER_OFFSET = -9       -- y offset of the timer below the top of the header (same template)
local MIN_HEIGHT = 22         -- the buttons of the header (18-19 high) still have to fit
local hooked = false

local function Wanted()
	return ns.db and ns.db.damageHeaderSize or 0
end

-- Texts of the header: { fontString, ... } of one window
local function HeaderTexts(window)
	return {
		window:GetSessionTimerFontString(),
		window:GetSessionName(),
		window:GetDamageMeterTypeName(),
		window:GetNotActiveFontString(),
	}
end

local function Style(window, size)
	local texts = HeaderTexts(window)
	local header = window:GetHeader()
	local timer = texts[1]
	if size > 0 then
		local base = select(2, GameFontNormalMed1:GetFont()) or 13
		local path, _, flags = GameFontNormalMed1:GetFont()
		for _, fs in ipairs(texts) do
			fs:SetFont(path, size, flags or "")
		end
		local height = math.max(MIN_HEIGHT, math.min(HEADER_HEIGHT, math.floor(HEADER_HEIGHT * size / base + 0.5)))
		header:SetHeight(height)
		timer:ClearAllPoints()
		timer:SetPoint("TOPLEFT", header, "TOPLEFT", 1, TIMER_OFFSET * height / HEADER_HEIGHT)
	else
		for _, fs in ipairs(texts) do
			fs:SetFontObject(GameFontNormalMed1)
		end
		header:SetHeight(HEADER_HEIGHT)
		timer:ClearAllPoints()
		timer:SetPoint("TOPLEFT", header, "TOPLEFT", 1, TIMER_OFFSET)
	end
end

local applied = 0   -- size set by qnCore, 0 = Blizzard's default

local function ApplyAll()
	local size = Wanted()
	local meter = DamageMeter
	if not meter or not meter.windowDataList then
		return
	end
	meter:ForEachSessionWindow(Style, size)
	applied = size
end

local function OnSetup(meter, _, windowData)
	local window = windowData and windowData.sessionWindow
	if window and (Wanted() > 0 or applied > 0) then
		Style(window, Wanted())
	end
end

local function Hook()
	if hooked or not DamageMeter then
		return false
	end
	hooked = true
	hooksecurefunc(DamageMeter, "SetupSessionWindow", OnSetup)
	return true
end

-- Apply the size of the active profile (option, profile switch, start). Font objects and
-- FontStrings are not protected: also works in combat.
function DM.Apply()
	if not hooked then
		return
	end
	if Wanted() ~= applied then
		ApplyAll()
	end
end

function DM.Init()
	if Hook() then
		ApplyAll()
		return
	end
	ns.events.Register("ADDON_LOADED", function(_, name)
		if name == "Blizzard_DamageMeter" and Hook() then
			ApplyAll()
		end
	end)
end
