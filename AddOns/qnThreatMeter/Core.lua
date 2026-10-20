-- qnThreatMeter: threat meter for the group against the current target.
-- Core: namespace, saved settings, helper functions, slash commands.

local ADDON, ns = ...
_G.qnThreatMeter = ns

-- Version, Print, events and the secret helpers (IsSecret, Plain, AnySecret) come from qnCore.
local lib = qnCore
lib.NewAddon(ns, ADDON)
local L = ns.L

---------------------------------------------------------------------------
-- Defaults
---------------------------------------------------------------------------

ns.defaults = {
	shown = true,
	locked = false,
	point = { "CENTER", "CENTER", 300, 0 },
	width = 220,
	height = 150,
	scale = 1,
	autoVisible = false,    -- keep the window in the visible area automatically (with qnViewPort: on a monitor)

	-- Appearance (values as in the built-in Damage Meter)
	linkDamageMeter = true, -- take bar values from the built-in Damage Meter
	style = 0,              -- Enum.DamageMeterStyle: 0 Default, 1 Thin, 2 Bordered, 3 Full Background
	barHeight = 24,
	barSpacing = 2,
	fontSize = 0,           -- 0 = size of the font object NumberFontNormal
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

	-- Content
	showValue = true,
	showPercent = true,
	showTPS = true,
	tpsWindow = 10,         -- seconds for the TPS calculation
	percentMode = 1,        -- 1 = relative to the tank (100 % = tank), 2 = scaled (100 % = aggro)
	showAggroBar = true,
	aggroMode = 1,          -- 1 = automatic, 2 = always melee (110 %), 3 = always ranged (130 %)
	alwaysShowSelf = true,
	useFocus = false,
	ignorePlayerPets = true,
	showPets = true,

	-- Visibility
	showMode = 1,           -- 1 = always, 2 = in combat only, 3 = in group only
	updateInterval = 0.2,

	-- Warnings
	warnEnabled = true,
	warnThreshold = 90,
	warnSound = true,
	warnFlash = true,
	warnMessage = true,
	warnSolo = false,
}

---------------------------------------------------------------------------
-- Media
---------------------------------------------------------------------------

-- { key, display name, atlas or file path }; the key is stored, not the value.
ns.TEXTURES = {
	{ "Damage Meter", DAMAGE_METER_LABEL, "UI-HUD-CoolDownManager-Bar" },
}
for _, t in ipairs(lib.Media.STATUSBARS) do
	ns.TEXTURES[#ns.TEXTURES + 1] = t
end
ns.TEXTURES[#ns.TEXTURES + 1] = { "Fertigkeit", SKILL, "Interface\\PaperDollInfoFrame\\UI-Character-Skills-Bar" }   -- do not translate: stored key

-- Dropdown entries: own textures, then those of LibSharedMedia
function ns.TextureEntries()
	return lib.Media.Entries(ns.TEXTURES, "statusbar")
end

function ns.GetTexturePath(name)
	return lib.Media.File(ns.TEXTURES, "statusbar", name) or ns.TEXTURES[1][3]
end


---------------------------------------------------------------------------
-- Diagnostics: checks at runtime which functions actually exist.
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
-- Loading
---------------------------------------------------------------------------

-- Version of the settings (see qnCore.Migrate)
local SETTINGS_VERSION = "1.0"

-- Keys of a profile dropped without replacement
local OBSOLETE = {
	"styleVersion",         -- markers of conversions before settings 1.0
	"pointInParentUnits",
}

ns.OnLoad(function()
	-- Settings per profile (= Edit Mode layout); ns.db is always the active profile.
	ns.store = lib.Profiles.Register({
		ns = ns,
		sv = "qnThreatMeterDB",
		settingsVersion = SETTINGS_VERSION,
		obsolete = OBSOLETE,
		onSwitch = function()
			ns.Threat.ApplySettings()
		end,
	})
	ns.Threat.Init()
	ns.InitOptions()
end)

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

local function Toggle()
	ns.Threat.Toggle()
end

-- reset also applies the settings via onSwitch; in combat only afterwards (deferred)
lib.RegisterCommands(ns, "QNTHREATMETER", { "/qnm", "/qnthreatmeter" }, {
	[""] = Toggle,
	toggle = Toggle,
	lock = function()
		ns.Print(ns.store:Toggle("locked") and L["Window locked."] or L["Window unlocked."])
	end,
	test = function()
		local T = ns.Threat
		T.SetTestMode(not T.testMode)
		ns.Print(T.testMode and L["Test mode on."] or L["Test mode off."])
	end,
	check = function() ns.Diagnose() end,
	visible = function() ns.Threat.MoveIntoVisible() end,
	reset = "reset",
}, L["Commands: /qnm [toggle | lock | test | config | check | visible | reset]\n  toggle – show/hide window    lock – lock/unlock window\n  test – test mode             config – open options\n  check – API check            visible – move window into the visible area\n  reset – reset all settings"])
