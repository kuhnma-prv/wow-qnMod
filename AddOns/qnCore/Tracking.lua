-- qnCore: remember Minimap tracking (Find Herbs, Find Minerals, Find Treasure,
-- Mailbox ...). WoW loses especially the tracking spells after death, on reload
-- or after a restart. qnCore remembers what was checked or unchecked and restores it after logging in, /reload, changing zones and resurrection.
--
-- Remembered is what goes through C_Minimap.SetTracking / ClearAllTracking (Minimap menu,
-- options), and every other change of tracking (MINIMAP_UPDATE_TRACKING), e.g. a
-- tracking spell from the action bar or the spellbook. Excluded are the time
-- shortly after logging in, /reload, changing zones and resurrection (then WoW reports the
-- loss), while the character is dead and while qnCore itself is restoring: then it is
-- checked against the remembered selection. The switch applies account-wide (qnCoreDB.global.tracking),
-- the remembered selection per character (qnCoreCharDB.tracking), because each one knows different spells.

local _, ns = ...
local lib = qnCore

local Tracking = {}
ns.Tracking = Tracking

local FIRST_DELAY = 3   -- seconds after the loading screen: before that the tracking data is missing
local STEP_DELAY = 2    -- between two spells (global cooldown, cast until "active")
local MAX_TRIES = 3     -- attempts per entry until the next login or resurrection
local DEAD_POLL = 2     -- while dead: check again this often (seconds)
local RESTORE_WINDOW = 15   -- this long after login/resurrection, changes count as loss (seconds)
local OWN_WINDOW = STEP_DELAY + 2   -- this long after an own SetTracking its event arrives

local restoring = false   -- do not remember own SetTracking calls as selection
local running = false     -- pass is running (timer chain)
local waiting = false     -- dead: check runs every DEAD_POLL
local deferred = false    -- combat: pass queued for after combat
local windowUntil = 0     -- until GetTime() = windowUntil, restore instead of remember
local tries = {}

local function OpenWindow(seconds)
	windowUntil = math.max(windowUntil, GetTime() + seconds)
end

-- Key of an entry: spells by spell ID, everything else by filter ID.
-- The position in the menu (index) changes when spells are added.
local function Key(index)
	local filter = C_Minimap.GetTrackingFilter(index)
	if not filter then
		return nil
	end
	local spellID, filterID = lib.Plain(filter.spellID), lib.Plain(filter.filterID)
	if spellID then
		return "spell:" .. spellID
	elseif filterID then
		return "filter:" .. filterID
	end
end

local function Saved()
	qnCoreCharDB.tracking = qnCoreCharDB.tracking or {}
	return qnCoreCharDB.tracking
end

function Tracking.Enabled()
	return ns.global and ns.global.tracking
end

-- All entries of the tracking menu: index, key (or nil), active (or nil)
local function Entries()
	local index, count = 0, C_Minimap.GetNumTrackingTypes()
	return function()
		index = index + 1
		if index <= count then
			local info = C_Minimap.GetTrackingInfo(index)
			return index, Key(index), info and lib.Plain(info.active)
		end
	end
end

-- Remember the player's selection (not the own calls while restoring)
local function CanRemember()
	return not restoring and Tracking.Enabled()
end

---------------------------------------------------------------------------
-- Remember selection
---------------------------------------------------------------------------

local function Remember(index, on)
	if not CanRemember() then
		return
	end
	local key = Key(index)
	if key then
		Saved()[key] = on and true or false
	end
end

local function RememberClearAll()
	if not CanRemember() then
		return
	end
	-- "Uncheck all": Blizzard then re-checks the always-active filters one by one
	local saved = Saved()
	for _, key in Entries() do
		if key then
			saved[key] = false
		end
	end
end

---------------------------------------------------------------------------
-- Restore
---------------------------------------------------------------------------

-- catch up after combat (do not reset attempts)
local function RestoreAfterCombat()
	deferred = false
	Tracking.Restore(0, true)
end

-- Combat: catch up after combat (qnCore.DeferInCombat). Dead: check periodically until the character
-- is alive - at the resurrection event it sometimes still counts as dead, and not every
-- resurrection is reported reliably.
local function Blocked()
	if lib.DeferInCombat(RestoreAfterCombat) then
		deferred = true
		return true
	end
	if UnitIsDeadOrGhost("player") then
		if not waiting then
			waiting = true
			C_Timer.After(DEAD_POLL, function()
				waiting = false
				Tracking.Restore(0, true)
			end)
		end
		return true
	end
	return false
end

-- First entry whose state does not match the remembered selection
local function NextMismatch()
	local saved = Saved()
	for index, key, active in Entries() do
		local wanted = key and saved[key]
		if wanted ~= nil and active ~= nil and active ~= wanted and (tries[key] or 0) < MAX_TRIES then
			return index, key, wanted
		end
	end
end

local Step
Step = function()
	if not Tracking.Enabled() then
		running = false
		return
	end
	if Blocked() then
		running = false
		return
	end
	local index, key, wanted = NextMismatch()
	if not index then
		running = false
		return
	end
	tries[key] = (tries[key] or 0) + 1
	OpenWindow(OWN_WINDOW)   -- the event for the own spell sometimes arrives only later
	restoring = true
	local ok, err = pcall(C_Minimap.SetTracking, index, wanted)
	restoring = false
	if not ok then
		geterrorhandler()(err)
	end
	-- spells one at a time: the next only after the global cooldown
	C_Timer.After(STEP_DELAY, Step)
end

-- keepTries: do not reset attempts (re-checks), otherwise counting starts over
function Tracking.Restore(delay, keepTries)
	if not Tracking.Enabled() or running or Blocked() then
		return
	end
	running = true
	if not keepTries then
		wipe(tries)
	end
	C_Timer.After(delay or 0, Step)
end

-- Take the current state as selection (when the option is turned on)
function Tracking.Capture()
	local saved = Saved()
	for _, key, active in Entries() do
		if key and active ~= nil then
			saved[key] = active
		end
	end
end

function Tracking.OnOptionChanged(value)
	if value then
		Tracking.Capture()
	end
end

-- Tracking change without C_Minimap.SetTracking (spell from the action bar, loss):
-- shortly after logging in or resurrection, while dead and while qnCore itself is
-- restoring, it is a loss (WoW often reports the death loss only after resurrection)
-- -> check against the remembered selection. Otherwise the player chose -> remember as selection.
local function OnTrackingUpdate()
	if restoring or not Tracking.Enabled() then
		return
	end
	if running or waiting or deferred or GetTime() <= windowUntil or UnitIsDeadOrGhost("player") then
		Tracking.Restore(1, true)
	else
		Tracking.Capture()
	end
end

---------------------------------------------------------------------------
-- Start
---------------------------------------------------------------------------

function Tracking.Init()
	hooksecurefunc(C_Minimap, "SetTracking", Remember)
	hooksecurefunc(C_Minimap, "ClearAllTracking", RememberClearAll)

	local events = ns.events
	-- login, /reload, zone change
	events.Register("PLAYER_ENTERING_WORLD", function()
		OpenWindow(FIRST_DELAY + RESTORE_WINDOW)
		Tracking.Restore(FIRST_DELAY)
	end)
	-- resurrection as ghost or at the corpse (including release)
	for _, event in ipairs({ "PLAYER_UNGHOST", "PLAYER_ALIVE" }) do
		events.Register(event, function()
			OpenWindow(RESTORE_WINDOW)
			Tracking.Restore(1)
		end)
	end
	events.Register("MINIMAP_UPDATE_TRACKING", OnTrackingUpdate)
end
