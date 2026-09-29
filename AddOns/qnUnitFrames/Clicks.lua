-- qnUnitFrames: Klickbelegung auf Blizzards Gruppen- und Schlachtzugsrahmen anwenden.
--
-- Die Rahmen sind sichere Einheitenknöpfe (SecureUnitButtonTemplate): ein Klick liest die Attribute
-- "<Zusatztaste>type<Taste>" usw. (SecureTemplates.lua). Wir setzen nur eigene, genau benannte
-- Attribute ("shift-type1", "shift-spell1"); Blizzards "*type1"/"*type2" (Ziel/Menü) bleiben
-- unberührt und gelten weiter, wo wir nichts belegen. Attribute geschützter Rahmen lassen sich nur
-- außerhalb des Kampfes ändern – im Kampf wird nachgeholt (qnCore.DeferInCombat).
--
-- Rahmen (Namen aus Blizzards Quelltext):
--   CompactPartyFrameMember1–5, CompactPartyFramePet1–5   Gruppe im Schlachtzugsstil
--   CompactRaidFrame<n>                                    Schlachtzug, Gruppen nicht getrennt
--                                                          (auch Begleiter: frame.frameType "pet")
--   CompactRaidGroup1–8Member1–5                           Schlachtzug nach Gruppen
--   PartyFrame.PartyMemberFramePool (+ .PetFrame)          klassische Gruppenrahmen
-- Neue Rahmen melden CompactUnitFrame_SetUpFrame und PartyFrame:InitializePartyMemberFrames.

local _, ns = ...
local lib = qnCore
local L = ns.L

local applied = {}   -- [Rahmen] = { [Attributname] = true }: von uns gesetzte Attribute
ns.applied = applied

---------------------------------------------------------------------------
-- Attribute aus den Belegungen
---------------------------------------------------------------------------

local VALUE_ATTRIBUTE = { spell = "spell", macro = "macrotext" }

-- { [Attributname] = Wert } für die Belegungen der eigenen Klasse
function ns.BuildAttributes()
	local attrs = {}
	for key, entry in pairs(ns.Bindings()) do
		local prefix, button = key:match("^(.-)(%d)$")
		local valueAttr = VALUE_ATTRIBUTE[entry.type]
		if valueAttr then
			-- Zauber/Makro ohne Inhalt: nichts belegen
			if entry.value and entry.value ~= "" then
				attrs[prefix .. "type" .. button] = entry.type
				attrs[prefix .. valueAttr .. button] = entry.value
			end
		else
			attrs[prefix .. "type" .. button] = entry.type
		end
	end
	return attrs
end

---------------------------------------------------------------------------
-- Rahmen suchen
---------------------------------------------------------------------------

local function Add(set, frame)
	if frame and not frame:IsForbidden() then
		set[frame] = true
	end
end

-- Menge der Rahmen, die laut Einstellungen belegt werden
function ns.CollectFrames()
	local set = {}
	local db = ns.db
	if db.raidStyle then
		for i = 1, 5 do
			Add(set, _G["CompactPartyFrameMember" .. i])
			if db.pets then
				Add(set, _G["CompactPartyFramePet" .. i])
			end
		end
		-- Blizzard_CompactRaidFrameContainer.lua GetUnitFrame: Mitglieder und Begleiter heißen
		-- gleich, frameType unterscheidet sie
		local i = 1
		local frame = _G["CompactRaidFrame1"]
		while frame do
			if db.pets or frame.frameType ~= "pet" then
				Add(set, frame)
			end
			i = i + 1
			frame = _G["CompactRaidFrame" .. i]
		end
		for group = 1, 8 do
			for member = 1, 5 do
				Add(set, _G["CompactRaidGroup" .. group .. "Member" .. member])
			end
		end
	end
	local pool = db.party and PartyFrame and PartyFrame.PartyMemberFramePool
	if pool then
		for frame in pool:EnumerateActive() do
			Add(set, frame)
			if db.pets then
				Add(set, frame.PetFrame)
			end
		end
	end
	return set
end

---------------------------------------------------------------------------
-- Anwenden
---------------------------------------------------------------------------

-- Setzt attrs auf frame und löscht, was wir früher gesetzt haben und nicht mehr gilt.
-- Unveränderte Werte werden nicht neu geschrieben (Apply läuft bei jedem Neuaufbau der Rahmen).
local function SetFrame(frame, attrs)
	local old = applied[frame]
	if old then
		for name in pairs(old) do
			if attrs[name] == nil and frame:GetAttribute(name) ~= nil then
				frame:SetAttribute(name, nil)
			end
		end
	end
	local names = {}
	for name, value in pairs(attrs) do
		if frame:GetAttribute(name) ~= value then
			frame:SetAttribute(name, value)
		end
		names[name] = true
	end
	applied[frame] = next(names) and names or nil
end

function ns.Apply()
	if not ns.db then
		return
	end
	if lib.DeferInCombat(ns.Apply) then
		return
	end
	local enabled = ns.db.enabled
	local attrs = enabled and ns.BuildAttributes() or {}
	local frames = enabled and ns.CollectFrames() or {}
	for frame in pairs(applied) do
		if not frames[frame] then
			SetFrame(frame, {})
		end
	end
	for frame in pairs(frames) do
		SetFrame(frame, attrs)
	end
end

-- Änderung durch den Spieler: im Kampf einen Hinweis, dass sie später wirkt
function ns.ApplyChange()
	if InCombatLockdown() then
		ns.Print(L["Änderung wird nach dem Kampf übernommen."])
	end
	ns.Apply()
end

---------------------------------------------------------------------------
-- Tooltip: Belegung unter dem Einheiten-Tooltip der Rahmen
---------------------------------------------------------------------------

local ORDER = {}
for i, prefix in ipairs(ns.MODIFIERS) do
	ORDER[prefix] = i
end

-- nach Maustaste, dann in der Reihenfolge der Zusatztasten
local function SortKeys(a, b)
	local pa, ba = a:match("^(.-)(%d)$")
	local pb, bb = b:match("^(.-)(%d)$")
	if ba ~= bb then
		return ba < bb
	end
	return (ORDER[pa] or 99) < (ORDER[pb] or 99)
end

local MACRO_PREVIEW = 32   -- Zeichen des Makrotexts im Tooltip
local UTF8_CHAR = "[\1-\127\194-\244][\128-\191]*"

-- erste Zeile, auf n Zeichen gekürzt (UTF-8: nie mitten im Zeichen)
local function FirstLine(text, n)
	local line = text:match("^[^\n]*")
	local short = line:match("^" .. UTF8_CHAR:rep(n))
	if short and #short < #text then
		return short .. "…"
	end
	return line ~= text and line .. "…" or line
end

-- Anzeigetext einer Belegung: Zaubername, bei Makros der Anfang des Makrotexts, sonst die Aktion
function ns.ActionText(entry)
	if entry.type == "spell" then
		return entry.value
	end
	if entry.type == "macro" and entry.value then
		return L["Makro: %s"]:format(FirstLine(entry.value, MACRO_PREVIEW))
	end
	return ns.TypeText(entry.type)
end

-- sortierte Schlüssel der wirksamen Belegungen (Zauber/Makro ohne Inhalt fehlen)
function ns.ActiveKeys()
	local keys = {}
	for key, entry in pairs(ns.Bindings()) do
		if not VALUE_ATTRIBUTE[entry.type] or (entry.value and entry.value ~= "") then
			keys[#keys + 1] = key
		end
	end
	table.sort(keys, SortKeys)
	return keys
end

local function AddTooltipLines(tooltip)
	if tooltip ~= GameTooltip or not (ns.db and ns.db.enabled and ns.db.tooltip) then
		return
	end
	local owner = tooltip:GetOwner()
	if not (owner and applied[owner]) then
		return
	end
	local list = ns.Bindings()
	local keys = ns.ActiveKeys()
	if #keys == 0 then
		return
	end
	tooltip:AddLine(" ")
	for _, key in ipairs(keys) do
		tooltip:AddDoubleLine(ns.BindingText(key), ns.ActionText(list[key]), 0.5, 0.8, 1, 1, 1, 1)
	end
end

---------------------------------------------------------------------------
-- Start
---------------------------------------------------------------------------

function ns.InitClicks()
	local Queue = lib.Debounce(ns.Apply)
	-- neue Rahmen im Schlachtzugsstil (CompactParty…/CompactRaid…); Namensplaketten und andere
	-- CompactUnitFrames nicht
	hooksecurefunc("CompactUnitFrame_SetUpFrame", function(frame)
		if frame:IsForbidden() then
			return
		end
		local name = frame:GetName()
		if name and (name:find("^CompactRaid") or name:find("^CompactParty")) then
			Queue()
		end
	end)
	-- klassische Gruppenrahmen entstehen beim ersten Zeigen aus einem Pool
	hooksecurefunc(PartyFrame, "InitializePartyMemberFrames", Queue)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, AddTooltipLines)
end
