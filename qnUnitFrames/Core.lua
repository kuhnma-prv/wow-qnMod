-- qnUnitFrames: Klickzauber auf Blizzards Gruppen- und Schlachtzugsrahmen (wie HealBot).
-- Core: Namensraum, gespeicherte Einstellungen, Belegungsdaten, Slash-Befehle, Ereignisse.
--
-- Eine Belegung ist Zusatztaste + Maustaste, z. B. "shift-1" (Umschalt + Linksklick). Die Schlüssel
-- folgen Blizzards Attributnamen (SecureTemplates.lua: Präfix "alt-ctrl-shift-", Tasten 1–5), so dass
-- Clicks.lua sie direkt als Attribute setzen kann ("shift-type1", "shift-spell1").
-- Die Belegungen liegen im Profil (= Layout des Bearbeitungsmodus) und darin je Klasse:
--   db.bindings[Klasse][Schlüssel] = { type = "spell", value = "Blitzheilung" }

local ADDON, ns = ...

local lib = qnCore
lib.NewAddon(ns, ADDON)
local L = ns.L

---------------------------------------------------------------------------
-- Standardwerte
---------------------------------------------------------------------------

ns.defaults = {
	enabled = true,
	raidStyle = true,     -- Rahmen im Schlachtzugsstil (Gruppe und Schlachtzug, CompactUnitFrame)
	party = true,         -- klassische Gruppenrahmen (PartyFrame)
	pets = true,          -- Begleiterrahmen der Gruppe
	tooltip = true,       -- Belegung im Tooltip der Rahmen zeigen
	bindings = {},        -- [Klasse] = { [Schlüssel] = { type, value } }
}

---------------------------------------------------------------------------
-- Tasten und Aktionen
---------------------------------------------------------------------------

-- Maustasten: Nummer wie in SecureButton_GetButtonSuffix
ns.BUTTONS = {
	{ "1", KEY_BUTTON1 },
	{ "2", KEY_BUTTON2 },
	{ "3", KEY_BUTTON3 },
	{ "4", KEY_BUTTON4 },
	{ "5", KEY_BUTTON5 },
}

-- Zusatztasten in der Reihenfolge von SecureButton_GetModifierPrefix (alt vor ctrl vor shift)
ns.MODIFIERS = { "", "shift-", "ctrl-", "alt-", "ctrl-shift-", "alt-shift-", "alt-ctrl-", "alt-ctrl-shift-" }

local MODIFIER_TEXT = { alt = ALT_KEY_TEXT, ctrl = CTRL_KEY_TEXT, shift = SHIFT_KEY_TEXT }

-- "alt-shift-" → "ALT+UMSCHALT"; ohne Zusatztaste ein eigener Text
function ns.ModifierText(prefix)
	if prefix == "" then
		return L["Ohne Zusatztaste"]
	end
	local parts = {}
	for mod in prefix:gmatch("(%a+)%-") do
		parts[#parts + 1] = MODIFIER_TEXT[mod] or mod
	end
	return table.concat(parts, "+")
end

-- Kurzform für Tooltips: "UMSCHALT+Linke Maustaste"
function ns.BindingText(key)
	local prefix, button = key:match("^(.-)(%d)$")
	local buttonText = KEY_BUTTON1
	for _, b in ipairs(ns.BUTTONS) do
		if b[1] == button then
			buttonText = b[2]
		end
	end
	if prefix == "" then
		return buttonText
	end
	return ns.ModifierText(prefix) .. "+" .. buttonText
end

-- Aktionen; "" = nichts setzen, Blizzards Verhalten bleibt (Linksklick: Ziel, Rechtsklick: Menü).
-- value: "spell" = Zaubername, "macro" = Makrotext
ns.TYPES = {
	{ "", L["Blizzard-Standard"] },
	{ "spell", L["Zauber"] },
	{ "macro", MACRO },
	{ "target", TARGET },
	{ "menu", FRAME_ACTION_MENU },
	{ "focus", SET_FOCUS },
	{ "assist", L["Assistieren"] },
}
local KNOWN_TYPE = {}
for _, t in ipairs(ns.TYPES) do
	KNOWN_TYPE[t[1]] = t[2]
end

function ns.TypeText(kind)
	return KNOWN_TYPE[kind] or kind
end

-- gültige Schlüssel: jede Zusatztaste mit jeder Maustaste ("", "shift-" … × "1" … "5")
local VALID_KEY = {}
for _, prefix in ipairs(ns.MODIFIERS) do
	for _, b in ipairs(ns.BUTTONS) do
		VALID_KEY[prefix .. b[1]] = true
	end
end

-- Klasse des Spielers ("PRIEST"); die Belegungen gelten je Klasse. Erst bei Bedarf gelesen und nur
-- ein lesbarer Wert gemerkt (UnitClass ist SecretWhenUnitIdentityRestricted).
local function ClassKey()
	if not ns.class then
		ns.class = lib.Plain(select(2, UnitClass("player")), nil)
	end
	return ns.class or "?"
end

-- Belegungen der eigenen Klasse im aktiven Profil
function ns.Bindings()
	local all = ns.db.bindings
	local class = ClassKey()
	local list = all[class]
	if not list then
		list = {}
		all[class] = list
	end
	return list
end

-- Setzt oder löscht (kind "" oder nil) eine Belegung der eigenen Klasse und wendet sie an.
function ns.SetBinding(key, kind, value)
	local list = ns.Bindings()
	if not kind or kind == "" then
		list[key] = nil
	else
		list[key] = { type = kind, value = value }
	end
	ns.ApplyChange()   -- Clicks.lua
end

-- Entfernt kaputte Einträge (unbekannte Aktion, falscher Schlüssel).
local function Upgrade(db)
	if type(db.bindings) ~= "table" then
		db.bindings = nil
		return
	end
	for class, list in pairs(db.bindings) do
		if type(list) ~= "table" then
			db.bindings[class] = nil
		else
			for key, entry in pairs(list) do
				local valid = VALID_KEY[key] and type(entry) == "table"
					and type(entry.type) == "string" and entry.type ~= "" and KNOWN_TYPE[entry.type]
				if not valid then
					list[key] = nil
				elseif entry.value ~= nil and type(entry.value) ~= "string" then
					entry.value = tostring(entry.value)
				end
			end
		end
	end
end

---------------------------------------------------------------------------
-- Slash-Befehle
---------------------------------------------------------------------------

lib.RegisterSlash("QNUNITFRAMES", { "/qnunitframes", "/qnuf" }, function(cmd)
	if cmd == "" or cmd == "config" or cmd == "optionen" then
		ns.OpenOptions()
	elseif cmd == "clicks" or cmd == "klicks" then
		ns.OpenClicksPage()
	elseif cmd == "on" then
		ns.store:Set("enabled", true)
	elseif cmd == "off" then
		ns.store:Set("enabled", false)
		ns.Print(L["Klickzauber ausgeschaltet. Einschalten mit /qnuf on"])
	else
		ns.Print(L["Befehle:\n  /qnuf – Optionen öffnen\n  /qnuf clicks – Klickbelegung bearbeiten\n  /qnuf on | off – Klickzauber ein-/ausschalten"])
	end
end)

---------------------------------------------------------------------------
-- Ereignisse
---------------------------------------------------------------------------

ns.OnLoad(function()
	ns.store = lib.Profiles.Register({
		ns = ns,
		sv = "qnUnitFramesDB",
		defaults = ns.defaults,
		upgrade = Upgrade,
		onSwitch = function()
			ns.Apply()
			ns.RefreshClicksPage()
		end,
	})
	ns.InitClicks()
	ns.InitOptions()
end)

ns.events.Register("PLAYER_LOGIN", function()
	ns.Apply()
end)
