-- qnMeter: Bedrohungsfenster (Datensammlung, Berechnung, Anzeige, Warnungen).
--
-- Zwei Betriebsarten, abhängig davon, was der Client gerade herausgibt:
--   * normal:        Werte sind lesbar. Sortierung, Ränge, Prozent nach Option
--                    (relativ zum Tank oder skaliert), TPS, "Aggro ziehen"-Balken
--                    und Warnungen.
--   * eingeschränkt: Werte sind secret. Balken und Texte werden trotzdem
--                    gefüllt (die Widgets nehmen secret-Werte an), aber es
--                    wird nicht sortiert und nicht gerechnet. Prozent ist
--                    dann immer der skalierte Wert des Clients, Ränge gibt es nicht.

local _, ns = ...

local L = ns.L
local IsSecret = ns.IsSecret
local Plain = ns.Plain
local Window = ns.Window

local T = {}
ns.Threat = T

local db, frame
local playerGUID

local TITLE = L["Bedrohung"]
local AGGRO_MELEE = 1.1
local AGGRO_RANGED = 1.3
local RANGE_ITEM = 8149 -- Voodoo-Talisman, 5 Meter (Nahkampfentfernung)
local MELEE_CLASSES = { WARRIOR = true, ROGUE = true, PALADIN = true }

local Interp = Enum.StatusBarInterpolation.ExponentialEaseOut

---------------------------------------------------------------------------
-- Zielauswahl
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
-- Datensammlung
---------------------------------------------------------------------------

local entries, numEntries = {}, 0
local order = {}
local seen = {}
local secretMode = false
local me, meIndex   -- eigener Eintrag und seine Stelle in entries

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
		-- Ohne lesbare GUID lässt sich ein Zusatz-Unit nicht gegen die
		-- Gruppe abgleichen; lieber weglassen als doppelt anzeigen.
		return
	end

	local isTanking, _, scaled, _, value = UnitDetailedThreatSituation(unit, mob)
	local secret = ns.AnySecret(value, scaled, isTanking)
	if not secret and value == nil then
		return -- nicht auf der Bedrohungsliste
	end

	local e = NewEntry()
	e.unit = unit
	e.key = guid or unit
	e.secret = secret
	-- Im Raid heißt man selbst raidN; ohne lesbare GUID hilft UnitIsUnit.
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
	-- Tank außerhalb der Gruppe (z. B. NPC) sowie eigenes Ziel und dessen Ziel.
	Collect(mob .. "target", mob, true)
	Collect("target", mob, true)
	Collect("targettarget", mob, true)
end

local testData = {
	{ name = "Tankrok", class = "WARRIOR", value = 52000, isTanking = true }, -- nicht übersetzen (Fantasiename)
	{ name = "Du", class = nil, value = 47000, isMe = true }, -- nicht übersetzen (wird durch den eigenen Namen ersetzt)
	{ name = L["Schurkine"], class = "ROGUE", value = 43500 },
	{ name = L["Feuerfunke"], class = "MAGE", value = 39000 },
	{ name = L["Pfeilwind"], class = "HUNTER", value = 30500 },
	{ name = "Wolf", class = nil, value = 12000, isPet = true }, -- nicht übersetzen (in beiden Sprachen gleich)
	{ name = L["Heilhand"], class = "PRIEST", value = 21000 },
	{ name = L["Blattgrün"], class = "DRUID", value = 16500 },
	{ name = L["Schattenkuss"], class = "WARLOCK", value = 26000 },
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
-- Bedrohung pro Sekunde: Zuwachs über ein gleitendes Zeitfenster.
-- Nur im normalen Modus; mit secret-Werten lässt sich nicht rechnen.
---------------------------------------------------------------------------

-- Verlauf je Gegner, damit ein Zielwechsel (z. B. kurz auf einen anderen Gegner) ihn nicht löscht.
-- Gegner ohne lesbare GUID teilen sich einen Verlauf. Nach dem Kampf wird alles geleert.
local MAX_MOBS = 5
local history = {}    -- Gegner -> Einheit (e.key) -> { t = { Zeitpunkte }, v = { Werte } }
local mobOrder = {}   -- Gegner nach letzter Verwendung, der neueste zuletzt

local function ResetTPS()
	wipe(history)
	wipe(mobOrder)
end

-- Verlauf des Gegners; der am längsten nicht verwendete fällt über MAX_MOBS heraus.
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

	-- Bedrohung gesunken (Wegstoßen, Unsichtbarkeit): neu beginnen.
	if n > 0 and e.value < v[n] then
		wipe(t)
		wipe(v)
		n = 0
	end
	n = n + 1
	t[n], v[n] = now, e.value

	-- Werte außerhalb des Zeitfensters verwerfen; der letzte davor bleibt
	-- als Bezugspunkt erhalten.
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
-- Aggro-Schwelle
---------------------------------------------------------------------------

local function IsMelee(mob)
	if db.aggroMode == 2 then
		return true
	elseif db.aggroMode == 3 then
		return false
	end
	-- Entfernung nur außerhalb des Kampfes: im Kampf ist die Abfrage auf Gegner
	-- für Addons gesperrt; dann entscheidet die Klasse.
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
-- Warnungen (nur im normalen Modus möglich)
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
		local text = L["Bedrohung: %d%%"]:format(pct)
		RaidWarningFrame:AddMessage(text, ChatTypeInfo["RAID_WARNING"])
	end
end

local function InCombat()
	return InCombatLockdown() or UnitAffectingCombat("player")
end

-- Warnungen möglich (Option an, kein Testmodus, in Gruppe oder auch allein erlaubt)
local function WarnActive()
	return db.warnEnabled and not T.testMode and (db.warnSolo or IsInGroup())
end

-- Daten nur sammeln, wenn das Fenster sie zeigt oder eine Warnung sie braucht. Verborgen nur im
-- Kampf: außerhalb steht man auf keiner Bedrohungsliste.
local function NeedsData()
	return frame:IsShown() or (WarnActive() and InCombat()) or false
end

-- Nur im normalen Modus aufgerufen: me ist dann nie secret. Ohne echten Tank-Eintrag keine Warnung:
-- der Ersatzbezug (höchster Wert) wäre sonst oft man selbst mit 100 %.
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
-- Anzeige
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

-- Name wie beim Damage Meter mit vorangestelltem Rang ("1. Name"); ohne Rang nur der Name.
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

local FormatValue = AbbreviateLargeNumbers   -- auch für secret-Werte

-- Normaler Modus: lesbare Zahlen.
local function ShowPlainBar(bar, e, top, tankValue)
	bar:SetMinMaxValues(0, top)
	bar:SetValue(e.value, Interp)

	local pct
	if db.percentMode == 2 then
		pct = e.isAggro and 100 or (e.scaled or 0)
	else
		pct = tankValue > 0 and (e.value / tankValue * 100) or 0
	end

	-- Wie das Damage Meter: "Wert (pro Sekunde) Prozent".
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

-- Eingeschränkter Modus: Werte nur durchreichen, nie anfassen.
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

-- Zeichnet die ersten count Einträge aus order. top/tankValue nur im normalen Modus;
-- im eingeschränkten Modus laufen auch lesbare Einträge über den skalierten Wert,
-- damit alle Balken dieselbe Skala haben.
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

-- Einträge neu sammeln (Testgegner bzw. Gruppe gegen das Ziel) und den Info-Text setzen.
-- TPS nur, wenn das Fenster sichtbar ist. Liefert den Gegner (nil im Testmodus und ohne Ziel).
local function CollectEntries(visible)
	numEntries = 0
	secretMode = false
	me, meIndex = nil, nil
	wipe(seen)
	playerGUID = Plain(UnitGUID("player"), nil)

	local mob
	if T.testMode then
		CollectTest()
		frame.infoText:SetText(L["Testgegner"])
	else
		mob = T.FindMob()
		if mob then
			CollectGroup(mob)
			if visible and not secretMode then
				UpdateAllTPS(mob)
			end
			-- Rechts wie der Sitzungsname beim Damage Meter: das Ziel.
			-- Orange = eingeschränkter Modus (secret-Werte).
			frame.infoText:SetFormattedText(secretMode and "|cffffaa00%s|r" or "%s", UnitName(mob))
		else
			frame.infoText:SetText("")
		end
	end
	return mob
end

-- Eingeschränkter Modus: keine Vergleiche möglich, Gruppenreihenfolge ohne Ränge, eigener Balken
-- zuerst. Liefert die Zahl der Zeilen.
local function RankSecret(capacity)
	if me and db.alwaysShowSelf then
		table.remove(order, meIndex)
		table.insert(order, 1, me)
	end
	return math.min(capacity, #order)
end

-- Normaler Modus: Bezugswert für Prozent und Aggro-Balken = Tank, ohne Tank-Eintrag der höchste Wert.
-- Liefert Bezugswert und ob ein echter Tank-Eintrag dabei ist.
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

-- Normaler Modus: Aggro-Balken, Ränge, eigener Balken notfalls in der letzten Zeile.
-- Liefert Zeilen und Skala.
local function RankNormal(mob, capacity, tankValue)
	if db.showAggroBar and tankValue > 0 then
		local e = NewEntry()
		e.isAggro = true
		e.name = L["Aggro ziehen"]
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

	-- Eigenen Balken notfalls in die letzte Zeile ziehen.
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

-- Verborgenes Fenster: nur sammeln und warnen, nicht zeichnen.
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
-- Sichtbarkeit, Menü, Testmodus
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

-- Taktgeber läuft unabhängig vom Fenster (Warnung auch bei verborgenem Fenster), aber nur, solange
-- Daten gebraucht werden. Alle Bedingungen von NeedsData ändern sich nur über Ereignisse und
-- Einstellungen, die hier ankommen.
function T.UpdateVisibility()
	frame:SetShown(ShouldShow())
	T.driver:SetShown(NeedsData())
	T.Refresh()
end

function T.Toggle()
	ns.store:Set("shown", not db.shown)
	if db.shown and not frame:IsShown() then
		ns.Print(L["Fenster ist aktiviert, wird aber wegen der Sichtbarkeitsoption gerade nicht gezeigt."])
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

-- Fenster in den sichtbaren Bereich holen (Slash-Befehl, Knopf); mit qnViewPort auf einen Monitor.
function T.MoveIntoVisible()
	if qnCore.Visible.MoveAndReport(frame, L["Fenster"], ns.Print) then
		Window.SavePosition(frame)
	end
end

-- Umschalter über ns.store:Set, damit das Einstellungsfenster den Wert mitbekommt.
local function OpenMenu(owner)
	MenuUtil.CreateContextMenu(owner, function(_, root)
		root:CreateTitle("qnMeter")
		root:CreateCheckbox(LOCK_FRAME, function() return db.locked end, function()
			ns.store:Set("locked", not db.locked)
		end)
		root:CreateCheckbox(L["Testmodus"], function() return T.testMode end, function()
			T.SetTestMode(not T.testMode)
		end)
		root:CreateCheckbox(L["Fokusziel bevorzugen"], function() return db.useFocus end, function()
			ns.store:Set("useFocus", not db.useFocus)
		end)
		root:CreateDivider()
		root:CreateButton(L["Optionen …"], ns.OpenOptions)
		root:CreateButton(HIDE, function()
			ns.store:Set("shown", false)
			ns.Print(L["Mit /qnm wieder einblenden."])
		end)
	end)
end

---------------------------------------------------------------------------
-- Kopplung an den eingebauten Damage Meter (Blizzard_DamageMeter, für camelot
-- beim Start geladen). Die Setter werden vom Bearbeitungsmodus aufgerufen.
-- hooksecurefunc hängt sich nur hinten an und verändert Blizzards Code nicht (kein Taint).
---------------------------------------------------------------------------

local DM_SETTERS = {
	"SetBarHeight", "SetBarSpacing", "SetStyle", "SetShowBarIcons",
	"SetUseClassColor", "SetTextScale", "SetBackgroundAlpha", "SetWindowAlpha",
}

-- Mehrere Setter hintereinander nur einmal anwenden.
local applyLater = qnCore.Debounce(function()
	T.ApplySettings()
end)

local function OnDamageMeterChanged()
	if db.linkDamageMeter then
		applyLater()
	end
end

---------------------------------------------------------------------------
-- Initialisierung
---------------------------------------------------------------------------

function T.Init()
	db = ns.db
	frame = Window.Create("qnMeterThreatFrame", db)
	T.frame = frame
	frame.titleText:SetText(TITLE)
	frame.OnMenu = function(_, owner) OpenMenu(owner) end
	-- Option autoVisible: nach dem Laden, bei neuer Fenstergröße und Monitoranordnung (qnCore)
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
