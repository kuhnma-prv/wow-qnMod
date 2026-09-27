-- qnCore: Verfolgung an der Minikarte merken (Kräutersuche, Mineraliensuche, Schatzsucher,
-- Briefkasten …). WoW verliert besonders die Verfolgungszauber nach dem Tod, beim Neuladen
-- oder nach dem Neustart. qnCore merkt sich, was an- oder abgewählt wurde, und stellt es nach dem Einloggen, /reload, Zonenwechsel und der Wiederbelebung wieder her.
--
-- Gemerkt wird, was über C_Minimap.SetTracking / ClearAllTracking geht (Menü der Minikarte,
-- Optionen), und jede andere Änderung der Verfolgung (MINIMAP_UPDATE_TRACKING), z. B. ein
-- Verfolgungszauber von der Aktionsleiste oder aus dem Zauberbuch. Ausgenommen sind die Zeit
-- kurz nach dem Einloggen, /reload, Zonenwechsel und der Wiederbelebung (dann meldet WoW den
-- Verlust), solange der Charakter tot ist und solange qnCore selbst wiederherstellt: dann wird
-- gegen die gemerkte Auswahl geprüft. Der Schalter gilt kontoweit (qnCoreDB.global.tracking),
-- die gemerkte Auswahl je Charakter (qnCoreCharDB.tracking), weil jeder andere Zauber kennt.

local _, ns = ...
local lib = qnCore

local Tracking = {}
ns.Tracking = Tracking

local FIRST_DELAY = 3   -- Sekunden nach dem Ladebildschirm: vorher fehlen die Verfolgungsdaten
local STEP_DELAY = 2    -- zwischen zwei Zaubern (globale Abklingzeit, Wirken bis "aktiv")
local MAX_TRIES = 3     -- Versuche je Eintrag bis zum nächsten Einloggen bzw. Wiederbeleben
local DEAD_POLL = 2     -- solange tot: so oft erneut prüfen (Sekunden)
local RESTORE_WINDOW = 15   -- so lange nach Einloggen/Wiederbelebung gelten Änderungen als Verlust (Sekunden)
local OWN_WINDOW = STEP_DELAY + 2   -- so lange nach einem eigenen SetTracking kommt dessen Meldung

local restoring = false   -- eigene Aufrufe von SetTracking nicht als Auswahl merken
local running = false     -- Durchlauf läuft (Timer-Kette)
local waiting = false     -- tot: Prüfung läuft im Takt DEAD_POLL
local deferred = false    -- Kampf: Durchlauf nach dem Kampf vorgemerkt
local windowUntil = 0     -- bis GetTime() = windowUntil wird wiederhergestellt statt gemerkt
local tries = {}

local function OpenWindow(seconds)
	windowUntil = math.max(windowUntil, GetTime() + seconds)
end

-- Schlüssel eines Eintrags: Zauber über die Zauber-ID, alles andere über die Filter-ID.
-- Die Position im Menü (index) ändert sich, wenn Zauber hinzukommen.
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

-- Alle Einträge des Verfolgungsmenüs: index, Schlüssel (oder nil), aktiv (oder nil)
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

-- Auswahl des Spielers merken (nicht die eigenen Aufrufe beim Wiederherstellen)
local function CanRemember()
	return not restoring and Tracking.Enabled()
end

---------------------------------------------------------------------------
-- Auswahl merken
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
	-- "Alle abwählen": Blizzard wählt die immer aktiven Filter danach einzeln wieder an
	local saved = Saved()
	for _, key in Entries() do
		if key then
			saved[key] = false
		end
	end
end

---------------------------------------------------------------------------
-- Wiederherstellen
---------------------------------------------------------------------------

-- nach dem Kampf nachholen (Versuche nicht zurücksetzen)
local function RestoreAfterCombat()
	deferred = false
	Tracking.Restore(0, true)
end

-- Kampf: nach dem Kampf nachholen (qnCore.DeferInCombat). Tot: im Takt prüfen, bis der Charakter
-- lebt – beim Ereignis der Wiederbelebung gilt er mitunter noch als tot, und nicht jede
-- Wiederbelebung meldet sich zuverlässig.
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

-- Erster Eintrag, dessen Zustand nicht der gemerkten Auswahl entspricht
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
	OpenWindow(OWN_WINDOW)   -- die Meldung zum eigenen Zauber kommt mitunter erst später
	restoring = true
	local ok, err = pcall(C_Minimap.SetTracking, index, wanted)
	restoring = false
	if not ok then
		geterrorhandler()(err)
	end
	-- Zauber einzeln: der nächste erst nach der globalen Abklingzeit
	C_Timer.After(STEP_DELAY, Step)
end

-- keepTries: Versuche nicht zurücksetzen (Nachprüfungen), sonst beginnt die Zählung neu
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

-- Aktuellen Zustand als Auswahl übernehmen (beim Einschalten der Option)
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

-- Änderung der Verfolgung ohne C_Minimap.SetTracking (Zauber von der Aktionsleiste, Verlust):
-- kurz nach dem Einloggen bzw. der Wiederbelebung, solange tot und solange qnCore selbst
-- wiederherstellt, ist es ein Verlust (Tod-Verlust meldet WoW oft erst nach der Wiederbelebung)
-- → gegen die gemerkte Auswahl prüfen. Sonst hat der Spieler gewählt → als Auswahl merken.
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
	-- Einloggen, /reload, Zonenwechsel
	events.Register("PLAYER_ENTERING_WORLD", function()
		OpenWindow(FIRST_DELAY + RESTORE_WINDOW)
		Tracking.Restore(FIRST_DELAY)
	end)
	-- Wiederbelebung als Geist bzw. am Leichnam (auch Freilassen)
	for _, event in ipairs({ "PLAYER_UNGHOST", "PLAYER_ALIVE" }) do
		events.Register(event, function()
			OpenWindow(RESTORE_WINDOW)
			Tracking.Restore(1)
		end)
	end
	events.Register("MINIMAP_UPDATE_TRACKING", OnTrackingUpdate)
end
