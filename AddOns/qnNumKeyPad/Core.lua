-- qnNumKeyPad: Aktionsleiste in Form eines Ziffernblocks.
-- Core: Namensraum, gespeicherte Einstellungen, Ereignisse, Slash-Befehle.

local ADDON, ns = ...

-- Version, Print und Ereignisse (ns.events) kommen aus qnCore.
local lib = qnCore
lib.NewAddon(ns, ADDON)
local L = ns.L

---------------------------------------------------------------------------
-- Standardwerte
---------------------------------------------------------------------------

ns.defaults = {
	enabled = true,
	locked = false,          -- Position gesperrt
	lockActions = false,     -- Aktionen immer gegen Herausziehen sperren
	lockInCombat = true,     -- Aktionen im Kampf gegen Herausziehen sperren

	-- Tastatur
	layout = "Windows",
	showEnter = false,
	showNav = false,
	showArrow = false,
	bindShift = true,        -- Umschalt+Taste ebenfalls belegen
	stance = false,          -- Tasten 1-12 folgen der Haltungs-/Gestaltleiste

	-- Aktionsplätze: Seite (je 12 Plätze) für Taste 1-12, 13-24, 25-28
	page1 = 13,
	page2 = 14,
	page3 = 15,

	-- Aussehen
	scale = 1,
	padH = 1,                -- Abstand waagerecht zwischen Tasten
	padV = 1,                -- Abstand senkrecht zwischen Tasten
	blockGap = 0,            -- zusätzlicher Abstand zum Navigations-/Pfeilblock
	alpha = 1,
	bgAlpha = 0,
	labels = 1,              -- 1 = Kurzlabel, 2 = Tastenname, 3 = keine
	fontSize = 0,            -- 0 = Standardgröße
	hideMacro = false,
	hideBorder = false,
	zoom = false,
	showGrid = true,         -- leere Tasten anzeigen
	clickThrough = false,
	flyout = "UP",

	-- Sichtbarkeit
	fade = false,
	fadeAlpha = 0.25,
	fadeDelay = 0.2,
	hideCombat = false,
	hideNoCombat = false,
	hideVehicle = true,
	hidePet = false,
	hideNoPet = false,
	hideStealth = false,
	hideForm = false,
	useCustom = false,
	custom = "[combat] show; [mod:alt] show; hide",

	-- Position (Einheiten von UIParent, unabhängig von der Skalierung)
	autoVisible = false,     -- automatisch im sichtbaren Bereich halten (mit qnViewPort: auf einem Monitor)
	point = "CENTER",
	x = 300,
	y = -100,
}

local hintSeen = false   -- ein Profil hatte den Hinweis schon gezeigt (hintShown bis 1.1.0)

-- Passt ein Profil aus älteren Versionen an (vor dem Ergänzen der Vorgaben).
local function Upgrade(db)
	if db.layout ~= nil and not ns.GetLayout(db.layout) then
		db.layout = nil
	end
	-- Hinweis beim ersten Einloggen gilt jetzt kontoweit (store.global.hintShown)
	if db.hintShown then
		hintSeen = true
	end
end

-- Veraltete Schlüssel (qnCore löscht sie nach Upgrade)
local OBSOLETE = {
	"keepVisible",   -- Vorgänger von autoVisible (war ungefragt an)
	"hintShown",     -- je Profil bis 1.1.0, jetzt kontoweit
}

---------------------------------------------------------------------------
-- Hilfsfunktionen
---------------------------------------------------------------------------

-- Änderungen an geschützten Rahmen sind im Kampf gesperrt.
-- ns.Apply() merkt sich deshalb den Wunsch und holt ihn nach dem Kampf nach (qnCore.DeferInCombat).
local warned = false

local function ApplyAfterCombat()
	ns.Apply()
end

function ns.Apply()
	if not ns.bar then
		return
	end
	if lib.DeferInCombat(ApplyAfterCombat) then
		if not warned then
			warned = true
			ns.Print(L["Änderung wird nach dem Kampf übernommen."])
		end
		ns.ApplyCosmetic()
		return
	end
	warned = false
	ns.ApplyAll()
	ns.QueueVisibleCheck()
end

-- Nach Änderungen, die die benutzten Seiten betreffen (Seiten, Layout, Zusatztasten, Profil).
function ns.ApplyAndCheck()
	ns.Apply()
	ns.CheckPages()
end

---------------------------------------------------------------------------
-- Slash-Befehle
---------------------------------------------------------------------------

lib.RegisterSlash("QNNUMKEYPAD", { "/qnnumkeypad", "/qnnkp", "/numpad" }, function(cmd)
	if cmd == "" or cmd == "config" or cmd == "optionen" then
		ns.OpenOptions()
	elseif cmd == "lock" then
		ns.store:Set("locked", true)
		ns.Print(L["Position gesperrt."])
	elseif cmd == "unlock" then
		ns.store:Set("locked", false)
		ns.Print(L["Position entsperrt. Ziehen mit der linken Maustaste, Rechtsklick öffnet die Optionen."])
	elseif cmd == "on" or cmd == "show" then
		ns.store:Set("enabled", true)
	elseif cmd == "off" or cmd == "hide" then
		ns.store:Set("enabled", false)
		ns.Print(L["Ausgeschaltet. Einschalten mit /qnnkp on"])
	elseif cmd == "reset" then
		ns.ResetPosition()
	elseif cmd == "visible" then
		ns.MoveIntoVisible()
	else
		-- ein Schlüssel; Print gibt jede Zeile als eigene Chatzeile aus
		ns.Print(L["Befehle:\n  /qnnkp – Optionen öffnen\n  /qnnkp lock | unlock – Position sperren/entsperren\n  /qnnkp on | off – Ziffernblock ein-/ausschalten\n  /qnnkp reset – Position zurücksetzen\n  /qnnkp visible – Leiste in den sichtbaren Bereich holen"])
	end
end)

---------------------------------------------------------------------------
-- Ereignisse
---------------------------------------------------------------------------

local events = ns.events

ns.OnLoad(function()
	-- Einstellungen je Profil (= Layout des Bearbeitungsmodus, qnCore); ns.db ist immer
	-- das aktive Profil. Bis Version 1.0 lagen sie je Charakter in qnNumKeyPadDB –
	-- diese Tabelle dient einmalig als Vorlage und wird nach dem ersten Profilwechsel gelöscht.
	ns.store = lib.Profiles.Register({
		ns = ns,
		sv = "qnNumKeyPadProfiles",
		defaults = ns.defaults,
		upgrade = Upgrade,
		obsolete = OBSOLETE,
		legacy = qnNumKeyPadDB,
		onSwitch = ns.ApplyAndCheck,
	})
	if hintSeen then
		ns.store.global.hintShown = true
	end
	lib.Profiles.OnChange(function()
		qnNumKeyPadDB = nil
	end)
	ns.CreateBar()
	ns.InitOptions()
end)

events.Register("PLAYER_LOGIN", function()
	ns.ApplyAndCheck()
	local global = ns.store.global
	if not ns.db.locked and not global.hintShown then
		global.hintShown = true
		ns.Print(L["Leiste mit der linken Maustaste verschieben, Rechtsklick öffnet die Optionen. Sperren mit /qnnkp lock."])
	end
end)

-- Nach dem Kampf die Darstellung (die Zieh-Fläche war im Kampf verborgen); Aufgeschobenes holt
-- qnCore.DeferInCombat nach.
events.Register("PLAYER_REGEN_ENABLED", function()
	ns.ApplyCosmetic()   -- Bar.lua
end)
