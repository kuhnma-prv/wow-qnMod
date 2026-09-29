-- qnMeter: Bedrohungsanzeige für die Gruppe gegen das aktuelle Ziel.
-- Core: Namensraum, gespeicherte Einstellungen, Hilfsfunktionen, Slash-Befehle.

local ADDON, ns = ...
_G.qnMeter = ns

-- Version, Print, Ereignisse und die Secret-Helfer (IsSecret, Plain, AnySecret) kommen aus qnCore.
local lib = qnCore
lib.NewAddon(ns, ADDON)
local L = ns.L

---------------------------------------------------------------------------
-- Standardwerte
---------------------------------------------------------------------------

ns.defaults = {
	shown = true,
	locked = false,
	point = { "CENTER", "CENTER", 300, 0 },
	width = 220,
	height = 150,
	scale = 1,
	autoVisible = false,    -- Fenster automatisch im sichtbaren Bereich halten (mit qnViewPort: auf einem Monitor)

	-- Darstellung (Werte wie beim eingebauten Damage Meter)
	styleVersion = 2,
	linkDamageMeter = true, -- Balkenwerte vom eingebauten Damage Meter übernehmen
	style = 0,              -- Enum.DamageMeterStyle: 0 Standard, 1 Dünn, 2 Umrandet, 3 Voller Hintergrund
	barHeight = 24,
	barSpacing = 2,
	fontSize = 0,           -- 0 = Größe des Font-Objekts NumberFontNormal
	texture = "Damage Meter",
	bgAlpha = 0.5,
	showTitle = true,
	showIcons = true,
	showRank = true,
	classColors = true,
	useMyColor = false,
	myColor = { r = 1, g = 0, b = 0 },
	useTankColor = false,
	tankColor = { r = 0.6, g = 0.1, b = 0.1 },
	aggroColor = { r = 1, g = 0.3, b = 0 },
	petColor = { r = 0.6, g = 0.6, b = 1 },
	barColor = { r = 0.5, g = 0.5, b = 0.5 },

	-- Inhalt
	showValue = true,
	showPercent = true,
	showTPS = true,
	tpsWindow = 10,         -- Sekunden für die TPS-Berechnung
	percentMode = 1,        -- 1 = relativ zum Tank (100 % = Tank), 2 = skaliert (100 % = Aggro)
	showAggroBar = true,
	aggroMode = 1,          -- 1 = automatisch, 2 = immer Nahkampf (110 %), 3 = immer Fernkampf (130 %)
	alwaysShowSelf = true,
	useFocus = false,
	ignorePlayerPets = true,
	showPets = true,

	-- Sichtbarkeit
	showMode = 1,           -- 1 = immer, 2 = nur im Kampf, 3 = nur in Gruppe
	updateInterval = 0.2,

	-- Warnungen
	warnEnabled = true,
	warnThreshold = 90,
	warnSound = true,
	warnFlash = true,
	warnMessage = true,
	warnSolo = false,
}

---------------------------------------------------------------------------
-- Medien
---------------------------------------------------------------------------

-- Atlas oder Dateipfad; gespeichert wird der Schlüssel, nicht der Wert.
ns.textures = {
	["Damage Meter"] = "UI-HUD-CoolDownManager-Bar",
	["Blizzard"] = "Interface\\TargetingFrame\\UI-StatusBar",
	["Flat"] = "Interface\\Buttons\\WHITE8X8",
	["Raid"] = "Interface\\RaidFrame\\Raid-Bar-Hp-Fill",
	["Fertigkeit"] = "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar",
}

-- Anzeigenamen der eigenen Texturen; die Schlüssel oben sind gespeicherte Werte.
ns.textureLabels = {
	["Damage Meter"] = DAMAGE_METER_LABEL,
	["Flat"] = L["Flat"],
	["Fertigkeit"] = SKILL,
}

local function GetLSM()
	return LibStub and LibStub("LibSharedMedia-3.0", true)
end

function ns.GetTexturePath(name)
	local LSM = GetLSM()
	if LSM then
		local path = LSM:Fetch("statusbar", name, true)
		if path then
			return path
		end
	end
	return ns.textures[name] or ns.textures["Damage Meter"]
end

function ns.GetTextureNames()
	local names, seen = {}, {}
	for name in pairs(ns.textures) do
		names[#names + 1] = name
		seen[name] = true
	end
	local LSM = GetLSM()
	if LSM then
		for _, name in ipairs(LSM:List("statusbar")) do
			if not seen[name] then
				names[#names + 1] = name
			end
		end
	end
	table.sort(names)
	return names
end


---------------------------------------------------------------------------
-- Diagnose: prüft zur Laufzeit, welche Funktionen tatsächlich da sind.
---------------------------------------------------------------------------

local function Yes(v)
	return v and ("|cff00ff00%s|r"):format(YES) or ("|cffff4040%s|r"):format(NO)
end

function ns.Diagnose()
	local _, build, _, toc = GetBuildInfo()
	ns.Print(L["Version %s, client build %s, interface %s"], ns.version, tostring(build), tostring(toc))

	local mob = ns.Threat.FindMob()
	if not mob then
		ns.Print(L["No attackable target – target an enemy for the secret check."])
		return
	end

	ns.Print(L["Threat values on %s secret: %s"], mob, Yes(C_Secrets.ShouldUnitThreatValuesBeSecret("player", mob)))
	ns.Print(L["Threat status on %s secret: %s"], mob, Yes(C_Secrets.ShouldUnitThreatStateBeSecret("player", mob)))

	local isTanking, status, scaled, raw, value = UnitDetailedThreatSituation("player", mob)
	if ns.AnySecret(isTanking, status, scaled, raw, value) then
		ns.Print(L["Own values: secret (display runs in restricted mode)."])
	elseif value == nil then
		ns.Print(L["You are not on the threat list of %s."], mob)
	else
		ns.Print(L["Own values: tank=%s status=%s scaled=%.1f%% raw=%.1f%% value=%s"],
			tostring(isTanking), tostring(status), scaled or 0, raw or 0, tostring(value))
	end
end

---------------------------------------------------------------------------
-- Laden
---------------------------------------------------------------------------

-- Passt ein Profil aus älteren Versionen an (vor dem Ergänzen der Vorgaben).
local function Upgrade(db)
	-- Umstieg auf die Damage-Meter-Optik: alte Darstellungswerte ersetzen.
	if next(db) and (db.styleVersion or 1) < 2 then
		for _, key in ipairs({ "barHeight", "barSpacing", "fontSize", "texture", "bgAlpha", "useMyColor", "useTankColor" }) do
			db[key] = ns.defaults[key]
		end
		db.styleVersion = 2
	end
	-- Lage bis 0.2.0 in Einheiten des Fensters (hing von der Skalierung ab), jetzt in Einheiten von
	-- UIParent: einmal mit der gespeicherten Skalierung umrechnen.
	if not db.pointInParentUnits then
		local p, s = db.point, tonumber(db.scale)
		if type(p) == "table" and s and s ~= 1 then
			p[3] = p[3] and math.floor(p[3] * s + 0.5)
			p[4] = p[4] and math.floor(p[4] * s + 0.5)
		end
		db.pointInParentUnits = true
	end
end

-- Veraltete Schlüssel (qnCore löscht sie nach Upgrade)
local OBSOLETE = {
	"fontOutline",   -- vor der Damage-Meter-Optik
	"keepVisible",   -- Vorgänger von autoVisible (war ungefragt an)
}

ns.OnLoad(function()
	-- Einstellungen je Profil (= Layout des Bearbeitungsmodus); ns.db ist immer das aktive Profil.
	ns.store = lib.Profiles.Register({
		ns = ns,
		sv = "qnMeterDB",
		defaults = ns.defaults,
		upgrade = Upgrade,
		obsolete = OBSOLETE,
		onSwitch = function()
			ns.Threat.ApplySettings()
		end,
	})
	ns.Threat.Init()
	ns.InitOptions()
end)

---------------------------------------------------------------------------
-- Slash-Befehle
---------------------------------------------------------------------------

lib.RegisterSlash("QNMETER", { "/qnm", "/qnmeter" }, function(cmd)
	local T = ns.Threat
	if cmd == "" or cmd == "toggle" then
		T.Toggle()
	elseif cmd == "lock" then
		ns.store:Set("locked", not ns.db.locked)
		ns.Print(ns.db.locked and L["Window locked."] or L["Window unlocked."])
	elseif cmd == "test" then
		T.SetTestMode(not T.testMode)
		ns.Print(T.testMode and L["Test mode on."] or L["Test mode off."])
	elseif cmd == "config" or cmd == "options" then
		ns.OpenOptions()
	elseif cmd == "check" then
		ns.Diagnose()
	elseif cmd == "visible" then
		T.MoveIntoVisible()
	elseif cmd == "reset" then
		-- wendet über onSwitch auch die Einstellungen an; im Kampf erst danach (deferred)
		if ns.store:ResetActive() then
			ns.Print(L["In combat: settings will be reset after combat."])
		else
			ns.Print(L["Settings reset."])
		end
	else
		-- ein Schlüssel für die ganze Hilfe; Print gibt jede Zeile als eigene Chatzeile aus
		ns.Print(L["Commands: /qnm [toggle | lock | test | config | check | visible | reset]\n  toggle – show/hide window    lock – lock/unlock window\n  test – test mode             config – open options\n  check – API check            visible – move window into the visible area\n  reset – reset all settings"])
	end
end)
