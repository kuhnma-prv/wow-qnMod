-- qnBuffMod: Fensterverwaltung, allgemeine Einstellungen, Blizzards Aurenfenster, Ereignisse,
-- Profilwechsel, Slash-Befehle und die schmale Abfrage-API für Tests.

local _, ns = ...
local lib = qnCore
local L = ns.L

local windows = {}     -- [Fenster-ID] = Window (auch abgeschaltete)
ns.windows = windows
local selected = 1     -- in den Optionen gewähltes Fenster
local scratch = {}     -- Einstellungsquelle, solange es das gewählte Fenster nicht gibt

---------------------------------------------------------------------------
-- Fensterliste
---------------------------------------------------------------------------

-- Fenster-IDs des aktiven Profils, aufsteigend
function ns.WindowIDs()
	local ids = {}
	for id in pairs(ns.db and ns.db.windows or {}) do
		ids[#ids + 1] = id
	end
	table.sort(ids)
	return ids
end

function ns.GetWindow(id)
	return windows[id]
end

function ns.SelectedID()
	return selected
end

-- Einstellungstabelle des gewählten Fensters (vor dem Einloggen: Vorgaben)
function ns.SelectedSettings()
	local t = ns.db and ns.db.windows and ns.db.windows[selected]
	if type(t) == "table" then
		return t
	end
	return scratch
end

-- Auswahl auf ein vorhandenes Fenster korrigieren
local function FixSelection()
	local ids = ns.WindowIDs()
	if #ids > 0 and not (ns.db.windows[selected]) then
		selected = ids[1]
	end
end

function ns.SelectWindow(id, fromSetting)
	selected = id
	FixSelection()
	ns.RefreshWindowPages(fromSetting)
	for _, win in pairs(windows) do
		win:ApplyMouse()
	end
end

-- Alt-Klick: Fenster wählen und die Seite "Fenster" öffnen
function ns.EditWindow(id)
	if not windows[id] then
		return
	end
	ns.SelectWindow(id)
	ns.Print(L["%s ausgewählt."], windows[id]:Label())
	ns.OpenWindowPage()
end

-- Beobachtete Einheiten aus den angezeigten Fenstern (der Spieler immer)
function ns.UpdateWatched()
	local set = { player = true }
	for _, win in pairs(windows) do
		if win.frame and win.unit then
			set[win.unit] = true
		end
	end
	ns.Auras.SetWatched(set)
end

local function FreeID()
	local id = 1
	while ns.db.windows[id] do
		id = id + 1
	end
	return id
end

local function Count()
	return #ns.WindowIDs()
end

-- Fenster zur ID aufbauen (Rahmen nur, wenn es nicht abgeschaltet ist)
local function Build(id)
	local win = ns.Window.New(id)
	windows[id] = win
	if not ns.WindowValue(ns.db.windows[id], "disableWindow") then
		win:Enable()
	end
	return win
end

-- Neues Fenster mit der Einstellungstabelle settings unter der kleinsten freien ID
local function Create(settings)
	local id = FreeID()
	ns.db.windows[id] = settings
	Build(id)
	return id
end

local function CombatBlocked()
	if InCombatLockdown() then
		ns.Print(L["Im Kampf nicht möglich."])
		return true
	end
	return false
end

-- Neues Fenster mit Vorgaben bzw. mit den Einstellungen von copyFrom; erscheint in der Bildschirmmitte
function ns.AddWindow(copyFrom)
	if CombatBlocked() then
		return nil
	end
	if Count() >= ns.WINDOW_LIMIT then
		ns.Print(L["Mehr als %d Fenster sind nicht möglich."], ns.WINDOW_LIMIT)
		return nil
	end
	local settings = {}
	local src = copyFrom and ns.db.windows[copyFrom]
	if type(src) == "table" then
		settings = CopyTable(src)
		settings.position = nil
	end
	local id = Create(settings)
	if src then
		ns.Print(L["Fenster %d mit den Einstellungen von Fenster %d angelegt."], id, copyFrom)
	else
		ns.Print(L["Fenster %d angelegt."], id)
	end
	ns.SelectWindow(id)
	return id
end

function ns.DeleteWindow(id)
	if CombatBlocked() or not ns.db.windows[id] then
		return
	end
	local ids = ns.WindowIDs()
	local pos = 1
	for i, v in ipairs(ids) do
		if v == id then
			pos = i
		end
	end
	local win = windows[id]
	if win then
		win:Disable()
	end
	windows[id] = nil
	ns.db.windows[id] = nil
	ns.Print(L["Fenster %d gelöscht."], id)
	ids = ns.WindowIDs()
	if #ids == 0 then
		local new = Create({})
		ns.Print(L["Kein Fenster übrig – Fenster %d angelegt."], new)
		ids = { new }
	end
	ns.UpdateWatched()
	ns.SelectWindow(ids[math.min(pos, #ids)])
end

---------------------------------------------------------------------------
-- Änderungen an Einheiten und Einstellungen
---------------------------------------------------------------------------

-- Auren einer Einheit wurden neu gelesen (nil = alle)
function ns.UnitChanged(unit)
	for _, win in pairs(windows) do
		if win.frame and (unit == nil or win.unit == unit) then
			win:Arrange()
		end
	end
	if unit == nil or unit == "player" then
		ns.Recast.UpdateButton()
	end
end

-- Waffenverzauberungen gelesen; slotsChanged = andere Plätze verzaubert als vorher
function ns.WeaponsChanged(slotsChanged)
	for _, win in pairs(windows) do
		if win.frame and win.unit == "player" then
			if slotsChanged then
				win:Arrange()
			else
				win:Refresh()
			end
		end
	end
end

-- Fenster eingeblendet (Sichtbarkeitstreiber): Einheit neu lesen und anordnen
function ns.RefreshWindowUnit(win)
	if not win.frame or not win.o then
		return
	end
	ns.Auras.Update(win.unit)
	win:Arrange()
end

-- Fahrzeug betreten/verlassen: Spielerfenster mit vehicleBuffs zeigen dessen Auren
function ns.SetVehicle(inside)
	ns.inVehicle = inside
	local changed = {}
	for _, win in pairs(windows) do
		if win:UpdateUnit() then
			changed[#changed + 1] = win
		end
	end
	ns.UpdateWatched()
	for _, win in ipairs(changed) do
		ns.Auras.Update(win.unit)
		win:Arrange()
	end
end

-- Eine Fenstereinstellung des gewählten Fensters wurde geändert (Optionen)
function ns.ApplyWindowSetting(key, value)
	local t = ns.SelectedSettings()
	if t == scratch then
		return
	end
	-- dünn speichern: Vorgabewerte entfallen
	local default = ns.windowDefaults[key]
	if type(default) ~= "table" and value == default then
		t[key] = nil
	end
	local win = windows[selected]
	if not win then
		return
	end
	if key == "disableWindow" then
		if lib.DeferInCombat(ns.ApplyAllWindows) then
			return
		end
		if value then
			win:Disable()
		else
			win:Enable()
		end
		ns.UpdateWatched()
		return
	end
	win:Apply()
end

-- Alle Fenster nach ihrer Einstellung disableWindow auf- bzw. abbauen und anwenden
function ns.ApplyAllWindows()
	for id, win in pairs(windows) do
		local off = ns.WindowValue(ns.db.windows[id], "disableWindow")
		if off then
			win:Disable()
		elseif win.frame then
			win:Apply()
		else
			win:Enable()
		end
	end
	ns.UpdateWatched()
end

---------------------------------------------------------------------------
-- Blizzards Aurenfenster
---------------------------------------------------------------------------

local hiddenByUs, hooked = {}, {}

-- Ausblenden, auch wenn Hide des Rahmens überschrieben wurde: die Methode des Widgets aufrufen
local function RawHide(frame)
	local mt = getmetatable(frame)
	local index = mt and mt.__index
	local hide
	if type(index) == "table" then
		hide = index.Hide
	elseif type(index) == "function" then
		hide = index(frame, "Hide")
	end
	(hide or frame.Hide)(frame)
end

local function Suppress(frame)
	if frame:IsShown() then
		hiddenByUs[frame] = true
		RawHide(frame)
	end
end

local function ApplyBlizzardFrames()
	for _, frame in ipairs({ BuffFrame, DebuffFrame }) do
		if not hooked[frame] then
			hooked[frame] = true
			-- blendet Blizzard sie wieder ein (z. B. nach dem Edit Mode), sofort wieder ausblenden
			frame:HookScript("OnShow", function(self)
				if ns.db and ns.db.hideBlizzardBuffs then
					Suppress(self)
				end
			end)
		end
		if ns.db.hideBlizzardBuffs then
			Suppress(frame)
		elseif hiddenByUs[frame] then
			hiddenByUs[frame] = nil
			frame:Show()
		end
	end
end

-- Allgemeine Einstellungen anwenden (Hauptseite)
function ns.ApplyGeneral()
	ApplyBlizzardFrames()
	for _, win in pairs(windows) do
		if win.frame then
			win:ApplyBackground()
			win:Refresh()
		end
	end
end

---------------------------------------------------------------------------
-- Aufbau und Profilwechsel
---------------------------------------------------------------------------

local function BuildAll()
	if not next(ns.db.windows) then
		ns.db.windows[1] = {}
	end
	for _, id in ipairs(ns.WindowIDs()) do
		Build(id)
	end
	FixSelection()
	ns.UpdateWatched()
end

-- Alle Fenster abbauen, ohne die Daten des Profils zu verändern
local function TearDown()
	for id, win in pairs(windows) do
		win:Disable()
		windows[id] = nil
	end
end

local function OnSwitch()
	TearDown()
	ns.ApplyGeneral()
	if ns.loggedIn then
		BuildAll()
		ns.Weapons.Update()
	end
	FixSelection()
	ns.RefreshWindowPages()
end

local function Tick()
	ns.Weapons.Tick()
	ns.Auras.Tick()
	ns.Warnings.Check()
end

ns.OnLoad(function()
	ns.RegisterStore(OnSwitch)
	ns.Auras.Init()
	ns.Weapons.Init()
	ns.Recast.Init()
	ns.InitOptions()
	ApplyBlizzardFrames()
end)

ns.events.Register("PLAYER_LOGIN", function()
	ns.loggedIn = true
	ns.inVehicle = UnitHasVehicleUI("player") and true or false
	BuildAll()
	ns.Weapons.Update()
	ns.Recast.UpdateButton()
	ns.ticker = C_Timer.NewTicker(1, Tick)
	ns.RefreshWindowPages()
end)

ns.events.Register("PLAYER_ENTERING_WORLD", function()
	if not ns.loggedIn then
		return
	end
	for _, unit in ipairs(ns.UNITS) do
		ns.Auras.Update(unit)
	end
	ns.Weapons.Update()
	ns.UnitChanged(nil)
end)

---------------------------------------------------------------------------
-- Slash-Befehle (ohne Argumente: Optionen öffnen)
---------------------------------------------------------------------------

lib.RegisterSlash("QNBUFFMOD", { "/qnbuff", "/qnbuffmod", "/qnaura" }, function()
	ns.OpenOptions()
end)

---------------------------------------------------------------------------
-- Abfrage für Tests: angezeigte Einträge eines Fensters
---------------------------------------------------------------------------

-- { kind, name, count, time, nameText, flashing, weapon, slot, x, y, entry } je Eintrag in Reihenfolge
function ns.GetEntries(id)
	local win = windows[id]
	local out = {}
	if not win or not win.frame then
		return out
	end
	for i, rec in ipairs(win.items) do
		local e = win.entries[i]
		local timeText = e.timeText:IsShown() and e.timeText:GetText() or nil
		if timeText == "" then
			timeText = nil
		end
		out[i] = {
			kind = rec.kind,
			name = rec.name,
			count = rec.count,
			countText = e.count:GetText(),
			time = timeText,
			nameText = e.nameText:IsShown() and e.nameText:GetText() or nil,
			flashing = e.flashing,
			weapon = rec.weapon or false,
			slot = rec.slot,
			x = e.x,
			y = e.y,
			entry = e,
			rec = rec,
		}
	end
	return out
end
