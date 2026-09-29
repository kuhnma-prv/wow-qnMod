-- qnBuffMod: tooltips of the entries and of the window background.

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

-- Tooltip to the right of the entry if the cursor is in the left half of the screen, otherwise to the left
function Tooltip.Anchor()
	local x = GetCursorPosition() / UIParent:GetEffectiveScale()
	local middle = (UIParent:GetLeft() or 0) + UIParent:GetWidth() / 2
	return x < middle and "ANCHOR_RIGHT" or "ANCHOR_LEFT"
end

-- Owner of a companion/vehicle: pet/vehicle → player, partypetN → partyN, raidpetN → raidN
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

-- Caster in class color, for companions/vehicles additionally "<owner>"
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

-- Only the window tooltip (with disableTooltips while a window page is open, on the background)
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
			-- tooltip now belongs to someone else: do not leave the minimum width in place
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
		GameTooltip:SetText(rec.name)   -- during the restriction only the last known name
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

-- Background while a window page is open: window tooltip at the cursor
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
