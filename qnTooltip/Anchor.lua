-- qnTooltip: Position des GameTooltip an Blizzards Standardstelle (GameTooltip_SetDefaultAnchor).
-- Nur auf Wunsch: in der Vorgabe "blizzard" bleibt die Stelle von Blizzard bzw. aus dem
-- Bearbeitungsmodus unverändert. Sonst am Mauszeiger, rechts davon oder an einem festen Punkt;
-- Spieler und NSC können eine eigene Art haben. Im Kampf ausblenden, mit Zusatztaste doch zeigen.

local _, ns = ...
local L = ns.L

local Anchor = {}
ns.Anchor = Anchor

local MODIFIER = {
	alt = { "IsAltKeyDown", LALT = true, RALT = true },
	ctrl = { "IsControlKeyDown", LCTRL = true, RCTRL = true },
	shift = { "IsShiftKeyDown", LSHIFT = true, RSHIFT = true },
}

function Anchor.ModeEntries(inherit)
	local list = {}
	if inherit then
		list[#list + 1] = { "inherit", L["Wie allgemein eingestellt"] }
	end
	list[#list + 1] = { "blizzard", L["Blizzard-Standard (Bearbeitungsmodus)"] }
	list[#list + 1] = { "cursor", L["Am Mauszeiger"] }
	list[#list + 1] = { "cursorRight", L["Rechts vom Mauszeiger"] }
	list[#list + 1] = { "static", L["Fester Punkt"] }
	return list
end

function Anchor.ModifierEntries()
	return {
		{ "none", NONE },
		{ "alt", ALT_KEY },
		{ "ctrl", CTRL_KEY },
		{ "shift", SHIFT_KEY },
	}
end

-- Rahmen unter der Maus und seine Einheit
local function Focus()
	local foci = GetMouseFoci()
	local focus = foci and foci[1]
	if not focus or focus:IsForbidden() then
		return nil, nil
	end
	return focus, focus.unit
end

-- Art für die Einheit unter der Maus
local function Mode(unit)
	local db = ns.db
	local mode = db.anchorMode
	unit = unit or "mouseover"
	if UnitExists(unit) then
		local isPlayer = UnitIsPlayer(unit)
		local own = (not ns.IsSecret(isPlayer) and isPlayer) and db.player.anchorMode or db.npc.anchorMode
		if own ~= "inherit" then
			mode = own
		end
	end
	return mode
end

local function ModifierDown()
	local m = MODIFIER[ns.db.combatModifier]
	return m and _G[m[1]]() or false
end

-- im Kampf ausblenden?
local function ShouldHide(tip)
	return tip.qnDefaultAnchor and ns.db.hideInCombat and InCombatLockdown() and not ModifierDown()
end

local function OnDefaultAnchor(tip, parent)
	if tip ~= GameTooltip then
		return
	end
	local db = ns.db
	local _, frameUnit = Focus()
	local mode = Mode(frameUnit)
	if (db.returnInCombat and InCombatLockdown()) or (db.returnOnUnitFrame and frameUnit) then
		mode = "blizzard"
	end
	if mode == "cursor" then
		tip:SetOwner(parent, "ANCHOR_CURSOR")
	elseif mode == "cursorRight" then
		tip:SetOwner(parent, "ANCHOR_CURSOR_RIGHT", 36, -12)
	elseif mode == "static" then
		tip:ClearAllPoints()
		tip:SetPoint(db.anchorPoint, UIParent, db.anchorPoint, db.anchorX, db.anchorY)
	end
	-- nach dem eigenen SetOwner setzen (SetOwner löscht die Markierung)
	tip.qnDefaultAnchor = true
end

function Anchor.PointEntries()
	return {
		{ "TOPLEFT", L["Oben links"] },
		{ "TOP", L["Oben Mitte"] },
		{ "TOPRIGHT", L["Oben rechts"] },
		{ "LEFT", L["Links Mitte"] },
		{ "CENTER", L["Mitte"] },
		{ "RIGHT", L["Rechts Mitte"] },
		{ "BOTTOMLEFT", L["Unten links"] },
		{ "BOTTOM", L["Unten Mitte"] },
		{ "BOTTOMRIGHT", L["Unten rechts"] },
	}
end

function Anchor.Init()
	hooksecurefunc("GameTooltip_SetDefaultAnchor", OnDefaultAnchor)
	hooksecurefunc(GameTooltip, "SetOwner", function(tip)
		tip.qnDefaultAnchor = nil
	end)
	GameTooltip:HookScript("OnShow", function(tip)
		if ShouldHide(tip) then
			tip:Hide()
		end
	end)
	-- Zusatztaste im Kampf: Tooltip der Einheit unter der Maus zeigen bzw. wieder ausblenden
	ns.events.Register("MODIFIER_STATE_CHANGED", function(_, key, down)
		local db = ns.db
		local m = MODIFIER[db.combatModifier]
		if not (m and m[key] and db.hideInCombat and InCombatLockdown()) then
			return
		end
		if down == 1 then
			if UnitExists("mouseover") and not GameTooltip:IsShown() then
				GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
				GameTooltip:SetUnit("mouseover")
			end
		elseif GameTooltip.qnDefaultAnchor then
			GameTooltip:Hide()
		end
	end)
end
