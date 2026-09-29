-- qnThreatMeter: threat window (data collection, calculation, display, warnings).
--
-- Two operating modes, depending on what the client currently provides:
--   * normal:        values are readable. Sorting, ranks, percent per option
--                    (relative to the tank or scaled), TPS, "Pull Aggro" bar
--                    and warnings.
--   * restricted:    values are secret. Bars and texts are still
--                    filled (the widgets accept secret values), but there
--                    is no sorting and no calculation. Percent is then
--                    always the client's scaled value, there are no ranks.

local _, ns = ...

local L = ns.L
local IsSecret = ns.IsSecret
local Plain = ns.Plain
local Window = ns.Window

local T = {}
ns.Threat = T

local db, frame
local playerGUID

local TITLE = L["Threat"]
local AGGRO_MELEE = 1.1
local AGGRO_RANGED = 1.3
local RANGE_ITEM = 8149 -- Voodoo Charm, 5 yards (melee range)
local MELEE_CLASSES = { WARRIOR = true, ROGUE = true, PALADIN = true }

local Interp = Enum.StatusBarInterpolation.ExponentialEaseOut

---------------------------------------------------------------------------
-- Target selection
---------------------------------------------------------------------------

local function IsValidMob(unit)
	if not UnitExists(unit) or UnitIsPlayer(unit) or not UnitCanAttack("player", unit) or UnitIsDeadOrGhost(unit) then
		return false
	end
	return not (db.ignorePlayerPets and UnitPlayerControlled(unit))
end

local MOBS = { "target", "targettarget" }
local MOBS_FOCUS = { "focus", "focustarget", "target", "targettarget" }

function T.FindMob()
	for _, unit in ipairs(db.useFocus and MOBS_FOCUS or MOBS) do
		if IsValidMob(unit) then
			return unit
		end
	end
end

---------------------------------------------------------------------------
-- Data collection
---------------------------------------------------------------------------

local entries, numEntries = {}, 0
local order = {}
local seen = {}
local secretMode = false
local me, meIndex   -- own entry and its position in entries

local function NewEntry()
	numEntries = numEntries + 1
	local e = entries[numEntries]
	if e then
		wipe(e)
	else
		e = {}
		entries[numEntries] = e
	end
	return e
end

local function Collect(unit, mob, isExtra)
	if not UnitExists(unit) then
		return
	end

	local guid = Plain(UnitGUID(unit), nil)
	if guid then
		if seen[guid] then
			return
		end
		seen[guid] = true
	elseif isExtra then
		-- Without a readable GUID an extra unit cannot be matched against the
		-- group; better to leave it out than to show it twice.
		return
	end

	local isTanking, _, scaled, _, value = UnitDetailedThreatSituation(unit, mob)
	local secret = ns.AnySecret(value, scaled, isTanking)
	if not secret and value == nil then
		return -- not on the threat list
	end

	local e = NewEntry()
	e.unit = unit
	e.key = guid or unit
	e.secret = secret
	-- In a raid you yourself are raidN; without a readable GUID UnitIsUnit helps.
	e.isMe = unit == "player" or (guid ~= nil and guid == playerGUID) or Plain(UnitIsUnit(unit, "player"), false)
	e.isPet = unit:find("pet", 1, true) ~= nil
	e.name = UnitName(unit)
	local _, class = UnitClass(unit)
	e.class = Plain(class, nil)
	e.scaled = scaled
	e.value = value
	if secret then
		secretMode = true
	else
		e.isTanking = isTanking
	end
	if e.isMe and not me then
		me, meIndex = e, numEntries
	end
end

local function CollectGroup(mob)
	local pets = db.showPets
	if IsInRaid() then
		for i = 1, GetNumGroupMembers() do
			Collect("raid" .. i, mob)
			if pets then
				Collect("raidpet" .. i, mob)
			end
		end
	else
		Collect("player", mob)
		if pets then
			Collect("pet", mob)
		end
		if IsInGroup() then
			for i = 1, GetNumSubgroupMembers() do
				Collect("party" .. i, mob)
				if pets then
					Collect("partypet" .. i, mob)
				end
			end
		end
	end
	-- tank outside the group (e.g. NPC) as well as own target and its target.
	Collect(mob .. "target", mob, true)
	Collect("target", mob, true)
	Collect("targettarget", mob, true)
end

local testData = {
	{ name = "Tankrok", class = "WARRIOR", value = 52000, isTanking = true }, -- do not translate (fantasy name)
	{ name = "You", class = nil, value = 47000, isMe = true }, -- do not translate (replaced by the own name)
	{ name = L["Stabbina"], class = "ROGUE", value = 43500 },
	{ name = L["Firespark"], class = "MAGE", value = 39000 },
	{ name = L["Arrowwind"], class = "HUNTER", value = 30500 },
	{ name = "Wolf", class = nil, value = 12000, isPet = true }, -- do not translate (same in both languages)
	{ name = L["Healhand"], class = "PRIEST", value = 21000 },
	{ name = L["Leafgreen"], class = "DRUID", value = 16500 },
	{ name = L["Shadowkiss"], class = "WARLOCK", value = 26000 },
}

local function CollectTest()
	for _, d in ipairs(testData) do
		local e = NewEntry()
		for k, v in pairs(d) do
			e[k] = v
		end
		if d.isMe then
			local _, class = UnitClass("player")
			e.name = UnitName("player")
			e.class = Plain(class, nil)
			me, meIndex = e, numEntries
		end
		e.secret = false
		e.scaled = d.value / 52000 * 100
		e.tps = d.value / 20
	end
end

---------------------------------------------------------------------------
-- Threat per second: gain over a sliding time window.
-- Only in normal mode; secret values cannot be calculated with.
---------------------------------------------------------------------------

-- History per enemy, so that a target switch (e.g. briefly to another enemy) does not clear it.
-- Enemies without a readable GUID share one history. Everything is cleared after combat.
local MAX_MOBS = 5
local history = {}    -- enemy -> unit (e.key) -> { t = { timestamps }, v = { values } }
local mobOrder = {}   -- enemies by last use, the newest last

local function ResetTPS()
	wipe(history)
	wipe(mobOrder)
end

-- History of the enemy; beyond MAX_MOBS the least recently used one drops out.
local function MobHistory(mob)
	local key = Plain(UnitGUID(mob), nil) or "?"
	local h = history[key]
	if not h then
		h = {}
		history[key] = h
		mobOrder[#mobOrder + 1] = key
		if #mobOrder > MAX_MOBS then
			history[table.remove(mobOrder, 1)] = nil
		end
	elseif mobOrder[#mobOrder] ~= key then
		for i = 1, #mobOrder do
			if mobOrder[i] == key then
				table.remove(mobOrder, i)
				break
			end
		end
		mobOrder[#mobOrder + 1] = key
	end
	return h
end

local function UpdateTPS(mobHistory, e, now)
	local h = mobHistory[e.key]
	if not h then
		h = { t = {}, v = {} }
		mobHistory[e.key] = h
	end
	local t, v = h.t, h.v
	local n = #t

	-- threat dropped (knockback, invisibility): start over.
	if n > 0 and e.value < v[n] then
		wipe(t)
		wipe(v)
		n = 0
	end
	n = n + 1
	t[n], v[n] = now, e.value

	-- discard values outside the time window; the last one before it is kept
	-- as a reference point.
	local cutoff = now - db.tpsWindow
	local first = 1
	while first < n - 1 and t[first + 1] <= cutoff do
		first = first + 1
	end
	if first > 1 then
		local j = 0
		for i = first, n do
			j = j + 1
			t[j], v[j] = t[i], v[i]
		end
		for i = n, j + 1, -1 do
			t[i], v[i] = nil, nil
		end
	end

	local dt = now - t[1]
	e.tps = dt >= 1 and (e.value - v[1]) / dt or 0
end

local function UpdateAllTPS(mob)
	local h = MobHistory(mob)
	local now = GetTime()
	for i = 1, numEntries do
		UpdateTPS(h, entries[i], now)
	end
end

---------------------------------------------------------------------------
-- Aggro threshold
---------------------------------------------------------------------------

local function IsMelee(mob)
	if db.aggroMode == 2 then
		return true
	elseif db.aggroMode == 3 then
		return false
	end
	-- range only out of combat: in combat the query on enemies is
	-- blocked for addons; then the class decides.
	if mob and not InCombatLockdown() then
		local ok, inRange = pcall(C_Item.IsItemInRange, RANGE_ITEM, mob)
		if ok then
			inRange = Plain(inRange, nil)
			if inRange ~= nil then
				return inRange
			end
		end
	end
	local _, class = UnitClass("player")
	return MELEE_CLASSES[Plain(class, "")] or false
end

---------------------------------------------------------------------------
-- Warnings (only possible in normal mode)
---------------------------------------------------------------------------

local warnArmed = true
local flash

local function Flash()
	if not flash then
		flash = CreateFrame("Frame", nil, UIParent)
		flash:SetAllPoints()
		flash:SetFrameStrata("FULLSCREEN_DIALOG")
		flash:EnableMouse(false)
		flash.tex = flash:CreateTexture(nil, "BACKGROUND")
		flash.tex:SetAllPoints()
		flash.tex:SetColorTexture(1, 0, 0, 0.25)
		flash:SetAlpha(0)
		local ag = flash:CreateAnimationGroup()
		local a1 = ag:CreateAnimation("Alpha")
		a1:SetFromAlpha(0)
		a1:SetToAlpha(1)
		a1:SetDuration(0.15)
		a1:SetOrder(1)
		local a2 = ag:CreateAnimation("Alpha")
		a2:SetFromAlpha(1)
		a2:SetToAlpha(0)
		a2:SetDuration(0.6)
		a2:SetOrder(2)
		flash.anim = ag
	end
	flash.anim:Stop()
	flash.anim:Play()
end

local function Warn(pct)
	if db.warnSound then
		PlaySound(SOUNDKIT.RAID_WARNING)
	end
	if db.warnFlash then
		Flash()
	end
	if db.warnMessage then
		local text = L["Threat: %d%%"]:format(pct)
		RaidWarningFrame:AddMessage(text, ChatTypeInfo["RAID_WARNING"])
	end
end

local function InCombat()
	return InCombatLockdown() or UnitAffectingCombat("player")
end

-- Warnings possible (option on, no test mode, in a group or allowed solo too)
local function WarnActive()
	return db.warnEnabled and not T.testMode and (db.warnSolo or IsInGroup())
end

-- Collect data only if the window shows it or a warning needs it. When hidden only in
-- combat: out of combat you are on no threat list.
local function NeedsData()
	return frame:IsShown() or (WarnActive() and InCombat()) or false
end

-- Only called in normal mode: me is then never secret. No warning without a real tank entry:
-- the fallback reference (highest value) would otherwise often be yourself at 100 %.
local function CheckWarning(tankValue, hasTank)
	if not WarnActive() or not me then
		return
	end
	if me.isTanking then
		warnArmed = true
		return
	end
	if not hasTank or tankValue <= 0 then
		return
	end
	local pct = me.value / tankValue * 100
	if warnArmed and pct >= db.warnThreshold then
		warnArmed = false
		Warn(pct)
	elseif pct < db.warnThreshold - 10 then
		warnArmed = true
	end
end

---------------------------------------------------------------------------
-- Display
---------------------------------------------------------------------------

local function SetBarColor(bar, e)
	local c
	if e.isAggro then
		c = db.aggroColor
	elseif e.isMe and db.useMyColor then
		c = db.myColor
	elseif e.isTanking and db.useTankColor then
		c = db.tankColor
	elseif e.isPet then
		c = db.petColor
	else
		c = frame.eff.classColors and qnCore.ClassColor(e.class) or db.barColor
	end
	bar:SetBarColor(c.r, c.g, c.b)
	bar:SetClassIcon(not e.isPet and not e.isAggro and e.class or nil)
end

-- Name as in the Damage Meter with the rank in front ("1. Name"); without rank only the name.
local function SetName(bar, e, rank)
	local name = e.name
	if not IsSecret(name) and name == nil then
		name = UNKNOWNOBJECT
	end
	if rank and db.showRank then
		bar.left:SetFormattedText("%d. %s", rank, name)
	else
		bar.left:SetText(name)
	end
end

local FormatValue = AbbreviateLargeNumbers   -- also for secret values

-- Normal mode: readable numbers.
local function ShowPlainBar(bar, e, top, tankValue)
	bar:SetMinMaxValues(0, top)
	bar:SetValue(e.value, Interp)

	local pct
	if db.percentMode == 2 then
		pct = e.isAggro and 100 or (e.scaled or 0)
	else
		pct = tankValue > 0 and (e.value / tankValue * 100) or 0
	end

	-- like the Damage Meter: "value (per second) percent".
	local showTPS = db.showTPS and e.tps ~= nil
	local text = db.showValue and FormatValue(e.value) or ""
	if showTPS then
		local tps = FormatValue(math.floor(e.tps * 10 + 0.5) / 10)
		text = text ~= "" and ("%s (%s)"):format(text, tps) or tps
	end
	if db.showPercent then
		if text == "" then
			text = ("%.0f%%"):format(pct)
		elseif showTPS then
			text = ("%s %.0f%%"):format(text, pct)
		else
			text = ("%s (%.0f%%)"):format(text, pct)
		end
	end
	bar.right:SetText(text)
end

-- Restricted mode: only pass values through, never touch them.
local function ShowSecretBar(bar, e)
	bar:SetMinMaxValues(0, 100)
	bar:SetValue(e.scaled, Interp)

	if db.showValue and db.showPercent then
		bar.right:SetFormattedText("%s (%.0f%%)", FormatValue(e.value), e.scaled)
	elseif db.showValue then
		bar.right:SetText(FormatValue(e.value))
	elseif db.showPercent then
		bar.right:SetFormattedText("%.0f%%", e.scaled)
	else
		bar.right:SetText("")
	end
end

local function SortByValue(a, b)
	return a.value > b.value
end

-- Draws the first count entries from order. top/tankValue only in normal mode;
-- in restricted mode readable entries also use the scaled value,
-- so that all bars have the same scale.
local function Draw(count, top, tankValue)
	for i = 1, count do
		local bar = Window.GetBar(frame, i)
		local e = order[i]
		SetName(bar, e, e.rank)
		if secretMode then
			ShowSecretBar(bar, e)
		else
			ShowPlainBar(bar, e, top, tankValue)
		end
		SetBarColor(bar, e)
		bar:Show()
	end
	Window.HideBarsFrom(frame, count + 1)
end

-- Collect entries anew (test enemy or group against the target) and set the info text.
-- TPS only if the window is visible. Returns the enemy (nil in test mode and without a target).
local function CollectEntries(visible)
	numEntries = 0
	secretMode = false
	me, meIndex = nil, nil
	wipe(seen)
	playerGUID = Plain(UnitGUID("player"), nil)

	local mob
	if T.testMode then
		CollectTest()
		frame.infoText:SetText(L["Test enemy"])
	else
		mob = T.FindMob()
		if mob then
			CollectGroup(mob)
			if visible and not secretMode then
				UpdateAllTPS(mob)
			end
			-- on the right like the session name in the Damage Meter: the target.
			-- Orange = restricted mode (secret values).
			frame.infoText:SetFormattedText(secretMode and "|cffffaa00%s|r" or "%s", UnitName(mob))
		else
			frame.infoText:SetText("")
		end
	end
	return mob
end

-- Restricted mode: no comparisons possible, group order without ranks, own bar
-- first. Returns the number of rows.
local function RankSecret(capacity)
	if me and db.alwaysShowSelf then
		table.remove(order, meIndex)
		table.insert(order, 1, me)
	end
	return math.min(capacity, #order)
end

-- Normal mode: reference value for percent and aggro bar = tank, without a tank entry the highest value.
-- Returns the reference value and whether a real tank entry is present.
local function TankValue()
	local tankValue, topValue, hasTank = 0, 0, false
	for i = 1, numEntries do
		local e = entries[i]
		if e.isTanking then
			tankValue, hasTank = e.value, true
		end
		if e.value > topValue then
			topValue = e.value
		end
	end
	if tankValue <= 0 then
		tankValue = topValue
	end
	return tankValue, hasTank
end

-- Normal mode: aggro bar, ranks, own bar in the last row if necessary.
-- Returns rows and scale.
local function RankNormal(mob, capacity, tankValue)
	if db.showAggroBar and tankValue > 0 then
		local e = NewEntry()
		e.isAggro = true
		e.name = L["Pull Aggro"]
		e.value = math.floor(tankValue * (IsMelee(mob) and AGGRO_MELEE or AGGRO_RANGED) + 0.5)
		order[#order + 1] = e
	end

	table.sort(order, SortByValue)
	local rank, myIndex = 0, nil
	for i = 1, #order do
		local e = order[i]
		if not e.isAggro then
			rank = rank + 1
			e.rank = rank
		end
		if e == me then
			myIndex = i
		end
	end
	local top = order[1].value
	if top <= 0 then
		top = 1
	end

	-- pull own bar into the last row if necessary.
	local shown = math.min(capacity, #order)
	if db.alwaysShowSelf and myIndex and shown > 0 and myIndex > shown then
		order[shown] = me
	end
	return shown, top
end

local function FillOrder()
	wipe(order)
	for i = 1, numEntries do
		order[i] = entries[i]
	end
end

-- Hidden window: only collect and warn, do not draw.
function T.Refresh()
	if not NeedsData() then
		return
	end
	local visible = frame:IsShown()

	local mob = CollectEntries(visible)
	if numEntries == 0 then
		Window.HideBarsFrom(frame, 1)
		return
	end

	if secretMode then
		if visible then
			FillOrder()
			Draw(RankSecret(Window.GetCapacity(frame)))
		end
		return
	end

	local tankValue, hasTank = TankValue()
	if visible then
		FillOrder()
		local shown, top = RankNormal(mob, Window.GetCapacity(frame), tankValue)
		Draw(shown, top, tankValue)
	end
	CheckWarning(tankValue, hasTank)
end

---------------------------------------------------------------------------
-- Visibility, menu, test mode
---------------------------------------------------------------------------

local function ShouldShow()
	if not db.shown then
		return false
	end
	if T.testMode then
		return true
	end
	if db.showMode == 2 then
		return InCombat()
	elseif db.showMode == 3 then
		return IsInGroup()
	end
	return true
end

-- The ticker runs independently of the window (warning even with a hidden window), but only as long
-- as data is needed. All conditions of NeedsData change only through events and
-- settings that arrive here.
function T.UpdateVisibility()
	frame:SetShown(ShouldShow())
	T.driver:SetShown(NeedsData())
	T.Refresh()
end

function T.Toggle()
	ns.store:Set("shown", not db.shown)
	if db.shown and not frame:IsShown() then
		ns.Print(L["Window is enabled but currently hidden because of the visibility option."])
	end
end

function T.SetTestMode(on)
	T.testMode = on and true or false
	T.UpdateVisibility()
end

function T.ApplySettings()
	db = ns.db
	frame.db = db
	Window.RestorePosition(frame)
	Window.ApplyStyle(frame)
	frame.checkVisible()
	T.UpdateVisibility()
end

-- Move the window into the visible area (slash command, button); with qnViewPort onto a monitor.
function T.MoveIntoVisible()
	if qnCore.Visible.MoveAndReport(frame, L["Window"], ns.Print) then
		Window.SavePosition(frame)
	end
end

-- Toggles via ns.store:Set so that the settings window picks up the value.
local function OpenMenu(owner)
	MenuUtil.CreateContextMenu(owner, function(_, root)
		root:CreateTitle("qnThreatMeter")
		root:CreateCheckbox(LOCK_FRAME, function() return db.locked end, function()
			ns.store:Set("locked", not db.locked)
		end)
		root:CreateCheckbox(L["Test Mode"], function() return T.testMode end, function()
			T.SetTestMode(not T.testMode)
		end)
		root:CreateCheckbox(L["Use focus target"], function() return db.useFocus end, function()
			ns.store:Set("useFocus", not db.useFocus)
		end)
		root:CreateDivider()
		root:CreateButton(L["Options …"], ns.OpenOptions)
		root:CreateButton(HIDE, function()
			ns.store:Set("shown", false)
			ns.Print(L["Type /qnm to show it again."])
		end)
	end)
end

---------------------------------------------------------------------------
-- Coupling to the built-in Damage Meter (Blizzard_DamageMeter, loaded at startup
-- for camelot). The setters are called by Edit Mode.
-- hooksecurefunc only appends itself and does not change Blizzard's code (no taint).
---------------------------------------------------------------------------

local DM_SETTERS = {
	"SetBarHeight", "SetBarSpacing", "SetStyle", "SetShowBarIcons",
	"SetUseClassColor", "SetTextScale", "SetBackgroundAlpha", "SetWindowAlpha",
}

-- Apply several setters in a row only once.
local applyLater = qnCore.Debounce(function()
	T.ApplySettings()
end)

local function OnDamageMeterChanged()
	if db.linkDamageMeter then
		applyLater()
	end
end

---------------------------------------------------------------------------
-- Initialization
---------------------------------------------------------------------------

function T.Init()
	db = ns.db
	frame = Window.Create("qnThreatMeterFrame", db)
	T.frame = frame
	frame.titleText:SetText(TITLE)
	frame.OnMenu = function(_, owner) OpenMenu(owner) end
	-- option autoVisible: after loading, on new window size and monitor arrangement (qnCore)
	frame.checkVisible = qnCore.Visible.Keep(frame, function() return db.autoVisible end, function()
		Window.SavePosition(frame)
	end)

	local elapsed = 0
	T.driver = CreateFrame("Frame")
	T.driver:SetScript("OnUpdate", function(_, dt)
		elapsed = elapsed + dt
		if elapsed >= db.updateInterval then
			elapsed = 0
			T.Refresh()
		end
	end)

	for _, name in ipairs(DM_SETTERS) do
		hooksecurefunc(DamageMeter, name, OnDamageMeterChanged)
	end
	T.ApplySettings()

	local function Vis() T.UpdateVisibility() end
	ns.events.Register("PLAYER_REGEN_DISABLED", Vis)
	ns.events.Register("PLAYER_REGEN_ENABLED", function()
		warnArmed = true
		ResetTPS()
		Vis()
	end)
	ns.events.Register("GROUP_ROSTER_UPDATE", Vis)
	ns.events.Register("PLAYER_ENTERING_WORLD", Vis)
end
