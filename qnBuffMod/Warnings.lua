-- qnBuffMod: Ablaufwarnungen im Chat und die Taste "Stärkungszauber erneuern".
-- Gewarnte, selbst wirkbare Zauber des Spielers kommen in die Erneuerungsliste. Ein sicherer
-- Aktionsknopf (QNBUFFMOD_RECASTBUFFFRAME) wirkt den zuletzt eingereihten; ohne Eintrag die eigene
-- Aura mit der kürzesten Restzeit, die der Spieler selbst wirken kann. Die Taste liegt per
-- Override-Belegung auf dem Knopf.

local _, ns = ...
local lib = qnCore
local L = ns.L
local E = ns.enum
local Plain = lib.Plain

BINDING_HEADER_QNBUFFMOD = "qnBuffMod"
BINDING_NAME_QNBUFFMOD_RECASTBUFFS = L["Stärkungszauber erneuern"]

local BINDING = "QNBUFFMOD_RECASTBUFFS"
local BUTTON = "QNBUFFMOD_RECASTBUFFFRAME"

---------------------------------------------------------------------------
-- Erneuerungsliste
---------------------------------------------------------------------------

local Recast = { list = {} }
ns.Recast = Recast

local button

-- Zauber per Name wirkbar (nutzbar oder nur zu wenig Ressource)?
function Recast.IsCastable(name)
	if type(name) ~= "string" or name == "?" then
		return false
	end
	local usable, noPower = C_Spell.IsSpellUsable(name)
	return Plain(usable, false) == true or Plain(noPower, false) == true
end

-- Zauber für den Knopf: der zuletzt eingereihte, sonst die eigene Aura mit der kürzesten Restzeit
function Recast.Next()
	local list = Recast.list
	if #list > 0 then
		return list[#list]
	end
	local best, bestExp
	for _, rec in ipairs(ns.Auras.List("player", E.group.ALLBUFFS)) do
		if rec.caster == "player" and not rec.placeholder and not rec.outOfRange and ns.Auras.HasExpiry(rec)
			and (not bestExp or rec.expiration < bestExp) and Recast.IsCastable(rec.name) then
			best, bestExp = rec.name, rec.expiration
		end
	end
	return best
end

-- Zauber am Knopf neu setzen (geschützt: erst nach dem Kampf)
function Recast.UpdateButton()
	if not button or lib.DeferInCombat(Recast.UpdateButton) then
		return
	end
	button:SetAttribute("spell", Recast.Next())
end

-- true, wenn der Zauber neu eingereiht wurde
function Recast.Add(name)
	for _, v in ipairs(Recast.list) do
		if v == name then
			return false
		end
	end
	Recast.list[#Recast.list + 1] = name
	Recast.UpdateButton()
	return true
end

function Recast.Forget(name)
	local list, changed = Recast.list, false
	for i = #list, 1, -1 do
		if list[i] == name then
			table.remove(list, i)
			changed = true
		end
	end
	if changed then
		Recast.UpdateButton()
	end
end

-- Text der belegten Taste oder nil
function Recast.BoundKey()
	local key = GetBindingKey(BINDING)
	if not key then
		return nil
	end
	return GetBindingText(key)
end

---------------------------------------------------------------------------
-- Knopf und Tastenbelegung
---------------------------------------------------------------------------

local appliedKeys

-- Taste per Override auf den Knopf legen (nur außerhalb des Kampfes); nur bei geänderter Belegung,
-- damit das dadurch ausgelöste UPDATE_BINDINGS nichts wiederholt.
function Recast.ApplyBindings()
	if lib.DeferInCombat(Recast.ApplyBindings) then
		return
	end
	local keys = { GetBindingKey(BINDING) }
	local joined = table.concat(keys, "\n")
	if joined == appliedKeys then
		return
	end
	appliedKeys = joined
	ClearOverrideBindings(button)
	for _, key in ipairs(keys) do
		SetOverrideBindingClick(button, false, key, BUTTON)
	end
end

local function PostClick(self, _, down)
	-- im Kampf ändert die Taste die Liste nicht; nur die auslösende Hälfte des Tastendrucks zählt
	if InCombatLockdown() or (down and true or false) ~= GetCVarBool("ActionButtonUseKeyDown") then
		return
	end
	local spell = self:GetAttribute("spell")
	if spell then
		Recast.Forget(spell)
	end
	Recast.UpdateButton()
end

function Recast.Init()
	button = CreateFrame("Button", BUTTON, UIParent, "SecureActionButtonTemplate")
	button:SetAttribute("type", "spell")
	button:SetAttribute("unit", "player")
	button:RegisterForClicks("AnyUp", "AnyDown")
	button:SetScript("PostClick", PostClick)
	button:Hide()
	Recast.button = button
	ns.events.Register("UPDATE_BINDINGS", Recast.ApplyBindings)
	ns.events.Register("PLAYER_ENTERING_WORLD", Recast.ApplyBindings)
end

---------------------------------------------------------------------------
-- Ablaufwarnungen (Sekundentakt)
---------------------------------------------------------------------------

local Warnings = {}
ns.Warnings = Warnings

-- Schwelle nach (abgerundeter) Dauer; nil = keine Warnung
local function Threshold(duration)
	local d, db = math.floor(duration), ns.db
	if d < 120 then
		return nil
	elseif d <= 600 then
		return db.expirationTime1
	elseif d <= 1800 then
		return db.expirationTime2
	end
	return db.expirationTime3
end

local function UnitLabel(unit)
	local name = Plain(UnitName(unit), nil)
	if type(name) ~= "string" or name == "" then
		return UNKNOWN
	end
	return name
end

local function Consider(unit, rec, now)
	local st = rec.state
	if not st or st.warned or rec.placeholder or rec.outOfRange or rec.duration <= 0 or rec.expiration <= 0 then
		return
	end
	local remaining = rec.expiration - now
	local threshold = Threshold(rec.duration)
	if remaining <= 0 or not threshold or threshold <= 0 or remaining > threshold then
		return
	end
	-- je Anwendung höchstens eine Warnung (Auren: auch über einen Zielwechsel hinweg)
	if rec.weapon then
		st.warned = true
	else
		ns.Auras.SetWarned(rec)
	end
	local castable = Recast.IsCastable(rec.name)
	if ns.db.expirationCastOnly and not castable then
		return
	end
	local timeText = ns.FormatTime(remaining, 1, true)
	if unit == "player" then
		local queued = castable and Recast.Add(rec.name)
		local key = queued and Recast.BoundKey()
		if key then
			ns.Print(L["Der Zauber |cFFFFFFFF%s|r läuft in |cFFFFFFFF%s|r ab. Außerhalb des Kampfes |cFFFFFFFF%s|r drücken zum Erneuern."], rec.name, timeText, key)
		else
			ns.Print(L["Der Zauber |cFFFFFFFF%s|r läuft in |cFFFFFFFF%s|r ab."], rec.name, timeText)
		end
	else
		ns.Print(L["Der Zauber |cFFFFFFFF%s|r auf |cFFFFFFFF%s|r läuft in |cFFFFFFFF%s|r ab."], rec.name, UnitLabel(unit), timeText)
	end
	if ns.db.expirationSound then
		PlaySoundFile(ns.WARN_SOUND)
	end
end

-- Stärkungszauber und Auren mit Dauer aller beobachteten Einheiten sowie Waffenverzauberungen.
-- Während der Aurensperre sind die Listen eingefroren (evtl. längst entfernte Zauber): nur Waffen.
function Warnings.Check()
	if not ns.db.enableExpiration then
		return
	end
	local now = GetTime()
	if not ns.Auras.Frozen() then
		for unit in pairs(ns.Auras.units) do
			for _, rec in ipairs(ns.Auras.List(unit, E.group.ALLBUFFS)) do
				Consider(unit, rec, now)
			end
		end
	end
	for _, rec in ipairs(ns.Weapons.List()) do
		Consider("player", rec, now)
	end
end
