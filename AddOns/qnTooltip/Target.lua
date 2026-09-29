-- qnTooltip: target of the unit ("Target: >>YOU<<", continuously updated) and "Targeted by"
-- (party or raid members targeting the unit).
-- Names may be secret: they are only passed to SetFormattedText; comparisons only with readable values.

local _, ns = ...
local L = ns.L
local IsSecret = ns.IsSecret

local Target = {}
ns.Target = Target

local UPDATE = 0.2   -- seconds between two updates of the target line

local function Plain(v)
	if IsSecret(v) then
		return nil
	end
	return v
end

-- format pattern and name for a unit (class color, otherwise selection color)
local function Colored(unit)
	local icon = ns.UnitData.VALUES.raidIcon({ unit = unit }) or ""
	if ns.IsUnit(unit, "player") then
		return "|cffff3333>>%s<<|r", strupper(YOU)
	end
	local name = UnitName(unit)
	local hex
	local isPlayer = Plain(UnitIsPlayer(unit))
	if isPlayer then
		local _, class = UnitClass(unit)
		local c = qnCore.ClassColor(class)
		if c then
			hex = ns.Hex(c.r, c.g, c.b)
		end
	end
	if not hex then
		local r, g, b = UnitSelectionColor(unit)
		if not ns.AnySecret(r, g, b) then
			hex = ns.Hex(r, g, b)
		end
	end
	local wrap = isPlayer and "%s" or (Plain(UnitIsOtherPlayersPet(unit)) and "<%s>" or "[%s]")
	local pattern = icon:gsub("%%", "%%%%") .. (hex and ("|cff" .. hex .. wrap .. "|r") or wrap)
	return pattern, name
end

---------------------------------------------------------------------------
-- Target line
---------------------------------------------------------------------------

local function Update(tip)
	local t = tip.qnTarget
	if not t then
		return
	end
	local left = ns.Left(tip, t.index)
	if not left or t.index > tip:NumLines() then
		tip.qnTarget = nil
		return
	end
	-- target identifier: GUID, "none" without a target, nil if secret (then rewrite every time)
	local exists = UnitExists(t.unit)
	local id = "none"
	if exists then
		id = Plain(UnitGUID(t.unit))
	end
	if id and id == t.id then
		return
	end
	t.id = id
	if not exists then
		left:SetText("")
	else
		local pattern, name = Colored(t.unit)
		left:SetFormattedText(TARGET:gsub("%%", "%%%%") .. ": " .. pattern, name)
	end
	tip:Show()
end

-- "Targeted by": list for players and in parties, only the count for NPCs in raids
local function TargetedBy(tip, unit, isPlayer)
	local num = GetNumGroupMembers()
	if num < 1 then
		return
	end
	local raid = IsInRaid()
	local prefix = raid and "raid" or "party"
	local last = raid and num or num - 1
	local list, count = {}, 0
	for i = 1, last do
		local member = prefix .. i
		if not ns.IsUnit(member, "player") and ns.IsUnit(member .. "target", unit) then
			count = count + 1
			list[#list + 1] = member
		end
	end
	if count == 0 then
		return
	end
	if isPlayer or not raid then
		tip:AddLine(L["Targeted by:"])
		for _, member in ipairs(list) do
			local pattern, name = Colored(member)
			local role = ns.UnitData.VALUES.roleIcon({ unit = member, role = UnitGroupRolesAssigned(member) }) or ""
			ns.NewLine(tip):SetFormattedText("   " .. role:gsub("%%", "%%%%") .. " " .. pattern, name)
		end
	else
		tip:AddLine(L["Targeted by: |cff33ffff%d|r"]:format(count))
	end
end

-- append lines (from Unit.lua after the header lines are built)
function Target.Add(tip, unit, cfg, isPlayer)
	tip.qnTarget = nil
	if cfg.showTarget then
		ns.NewLine(tip)
		tip.qnTarget = { index = tip:NumLines(), unit = unit .. "target" }
		Update(tip)
	end
	if cfg.showTargetBy then
		TargetedBy(tip, unit, isPlayer)
	end
end

function Target.Init()
	local elapsed = 0
	GameTooltip:HookScript("OnUpdate", function(tip, dt)
		elapsed = elapsed + dt
		if elapsed < UPDATE then
			return
		end
		elapsed = 0
		if tip.qnTarget then
			Update(tip)
		end
	end)
	GameTooltip:HookScript("OnTooltipCleared", function(tip)
		tip.qnTarget = nil
	end)
end
