-- qnBuffMod: Tooltips der Einträge und des Fensterhintergrunds.

local _, ns = ...
local lib = qnCore
local L = ns.L
local Plain = lib.Plain

local Tooltip = {}
ns.Tooltip = Tooltip

local REFRESH = 0.5
local MIN_WIDTH = 180
local CASTER_DEFAULT = { r = 0.82, g = 1, b = 0 }
local GREY = 0.5

-- Tooltip rechts vom Eintrag, wenn der Mauszeiger in der linken Bildschirmhälfte ist, sonst links
function Tooltip.Anchor()
	local x = GetCursorPosition() / UIParent:GetEffectiveScale()
	local middle = (UIParent:GetLeft() or 0) + UIParent:GetWidth() / 2
	return x < middle and "ANCHOR_RIGHT" or "ANCHOR_LEFT"
end

-- Besitzer eines Begleiters/Fahrzeugs: pet/vehicle → player, partypetN → partyN, raidpetN → raidN
function Tooltip.OwnerOf(unit)
	if unit == "pet" or unit == "vehicle" then
		return "player"
	end
	local n = unit:match("^partypet(%d+)$")
	if n then
		return "party" .. n
	end
	n = unit:match("^raidpet(%d+)$")
	if n then
		return "raid" .. n
	end
	return nil
end

local function NameAndColor(unit)
	local name = Plain(UnitName(unit), nil)
	if type(name) ~= "string" or name == "" then
		name = UNKNOWN
	end
	local _, classFile = UnitClass(unit)
	return name, lib.ClassColor(classFile) or CASTER_DEFAULT
end

-- Wirker in Klassenfarbe, bei Begleitern/Fahrzeugen zusätzlich "<Besitzer>"
local function CasterLines(caster)
	if type(caster) ~= "string" then
		return
	end
	local name, c = NameAndColor(caster)
	GameTooltip:AddLine(name, c.r, c.g, c.b)
	if Plain(UnitIsPlayer(caster), false) ~= true then
		local owner = Tooltip.OwnerOf(caster)
		if owner then
			local ownerName, oc = NameAndColor(owner)
			GameTooltip:AddLine(("<%s>"):format(ownerName), oc.r, oc.g, oc.b)
		end
	end
end

-- Nur der Fenstertooltip (mit disableTooltips bei offener Fensterseite, am Hintergrund)
local function WindowTip(owner, anchor, id)
	GameTooltip:SetOwner(owner, anchor)
	GameTooltip:AddLine(L["Window %d"]:format(id))
	GameTooltip:AddLine(L["Alt-click: select the window in the options."], 1, 1, 1)
	GameTooltip:Show()
end

local function OnUpdate(e, elapsed)
	e.tipElapsed = (e.tipElapsed or 0) + elapsed
	if e.tipElapsed >= REFRESH then
		e.tipElapsed = 0
		if GameTooltip:IsOwned(e) then
			Tooltip.ShowEntry(e)
		else
			-- Tooltip gehört inzwischen einem anderen: Mindestbreite nicht stehen lassen
			e:SetScript("OnUpdate", nil)
			GameTooltip:SetMinimumWidth(0)
		end
	end
end

function Tooltip.ShowEntry(e)
	local win, rec = e.win, e.rec
	if not rec then
		return
	end
	local pageOpen = ns.WindowPageOpen()
	if win.o.disableTooltips then
		if pageOpen then
			WindowTip(e, Tooltip.Anchor(), win.id)
		end
		return
	end
	GameTooltip:SetOwner(e, Tooltip.Anchor())
	if rec.weapon then
		GameTooltip:SetInventoryItem("player", rec.slot)
	elseif rec.placeholder or ns.Auras.Restricted() then
		GameTooltip:SetText(rec.name)   -- während der Sperre nur der zuletzt bekannte Name
	else
		GameTooltip:SetUnitAura(win.unit, rec.index, rec.filter)
	end
	if not rec.weapon then
		CasterLines(rec.caster)
	end
	if pageOpen then
		GameTooltip:AddLine(L["Window %d (Alt-click: select the window in the options.)"]:format(win.id), GREY, GREY, GREY)
	else
		local left = rec.spellId and L["Spell ID: %d"]:format(rec.spellId) or " "
		GameTooltip:AddDoubleLine(left, L["/qnbuff for options"], GREY, GREY, GREY, GREY, GREY, GREY)
	end
	GameTooltip:SetMinimumWidth(MIN_WIDTH)
	GameTooltip:Show()
	e.tipElapsed = 0
	e:SetScript("OnUpdate", OnUpdate)
end

function Tooltip.Hide(e)
	e:SetScript("OnUpdate", nil)
	if GameTooltip:IsOwned(e) then
		GameTooltip:SetMinimumWidth(0)
		GameTooltip:Hide()
	end
end

-- Hintergrund bei offener Fensterseite: Fenstertooltip am Mauszeiger
function Tooltip.ShowBackground(bg, id)
	if ns.WindowPageOpen() then
		WindowTip(bg, "ANCHOR_CURSOR", id)
	end
end

function Tooltip.HideBackground(bg)
	if GameTooltip:IsOwned(bg) then
		GameTooltip:Hide()
	end
end
