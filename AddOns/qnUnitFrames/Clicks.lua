-- qnUnitFrames: apply click bindings to Blizzard's party and raid frames.
--
-- The frames are secure unit buttons (SecureUnitButtonTemplate): a click reads the attributes
-- "<modifier>type<button>" etc. (SecureTemplates.lua). We only set our own, exactly named
-- attributes ("shift-type1", "shift-spell1"); Blizzard's "*type1"/"*type2" (target/menu) stay
-- untouched and still apply where we bind nothing. Attributes of protected frames can only be
-- changed out of combat – in combat the change is deferred (qnCore.DeferInCombat).
--
-- Frames (names from Blizzard's source code):
--   CompactPartyFrameMember1–5, CompactPartyFramePet1–5   party in raid style
--   CompactRaidFrame<n>                                    raid, groups not separated
--                                                          (pets too: frame.frameType "pet")
--   CompactRaidGroup1–8Member1–5                           raid by groups
--   PartyFrame.PartyMemberFramePool (+ .PetFrame)          classic party frames
-- New frames are reported by CompactUnitFrame_SetUpFrame and PartyFrame:InitializePartyMemberFrames.

local _, ns = ...
local lib = qnCore
local L = ns.L

local applied = {}   -- [frame] = { [attribute name] = true }: attributes set by us
ns.applied = applied

---------------------------------------------------------------------------
-- Attributes from the bindings
---------------------------------------------------------------------------

local VALUE_ATTRIBUTE = { spell = "spell", macro = "macrotext" }

-- { [attribute name] = value } for the bindings of the player's class
function ns.BuildAttributes()
	local attrs = {}
	for key, entry in pairs(ns.Bindings()) do
		local prefix, button = key:match("^(.-)(%d)$")
		local valueAttr = VALUE_ATTRIBUTE[entry.type]
		if valueAttr then
			-- spell/macro without content: bind nothing
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
-- Find frames
---------------------------------------------------------------------------

local function Add(set, frame)
	if frame and not frame:IsForbidden() then
		set[frame] = true
	end
end

-- Set of frames that are bound according to the settings
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
		-- Blizzard_CompactRaidFrameContainer.lua GetUnitFrame: members and pets have the same
		-- names, frameType tells them apart
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
-- Apply
---------------------------------------------------------------------------

-- Sets attrs on frame and clears what we set earlier and no longer applies.
-- Unchanged values are not rewritten (Apply runs on every rebuild of the frames).
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

-- Change by the player: in combat a notice that it takes effect later
function ns.ApplyChange()
	if InCombatLockdown() then
		ns.Print(L["The change will be applied after combat."])
	end
	ns.Apply()
end

---------------------------------------------------------------------------
-- Tooltip: bindings below the unit tooltip of the frames
---------------------------------------------------------------------------

local ORDER = {}
for i, prefix in ipairs(ns.MODIFIERS) do
	ORDER[prefix] = i
end

-- by mouse button, then in the order of the modifiers
local function SortKeys(a, b)
	local pa, ba = a:match("^(.-)(%d)$")
	local pb, bb = b:match("^(.-)(%d)$")
	if ba ~= bb then
		return ba < bb
	end
	return (ORDER[pa] or 99) < (ORDER[pb] or 99)
end

local MACRO_PREVIEW = 32   -- characters of the macro text in the tooltip
local UTF8_CHAR = "[\1-\127\194-\244][\128-\191]*"

-- first line, shortened to n characters (UTF-8: never in the middle of a character)
local function FirstLine(text, n)
	local line = text:match("^[^\n]*")
	local short = line:match("^" .. UTF8_CHAR:rep(n))
	if short and #short < #text then
		return short .. "…"
	end
	return line ~= text and line .. "…" or line
end

-- Display text of a binding: spell name, for macros the start of the macro text, otherwise the action
function ns.ActionText(entry)
	if entry.type == "spell" then
		return entry.value
	end
	if entry.type == "macro" and entry.value then
		return L["Macro: %s"]:format(FirstLine(entry.value, MACRO_PREVIEW))
	end
	return ns.TypeText(entry.type)
end

-- sorted keys of the effective bindings (spell/macro without content are missing)
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
-- Startup
---------------------------------------------------------------------------

function ns.InitClicks()
	local Queue = lib.Debounce(ns.Apply)
	-- new raid-style frames (CompactParty…/CompactRaid…); not nameplates and other
	-- CompactUnitFrames
	hooksecurefunc("CompactUnitFrame_SetUpFrame", function(frame)
		if frame:IsForbidden() then
			return
		end
		local name = frame:GetName()
		if name and (name:find("^CompactRaid") or name:find("^CompactParty")) then
			Queue()
		end
	end)
	-- classic party frames are created from a pool when first shown
	hooksecurefunc(PartyFrame, "InitializePartyMemberFrames", Queue)
	TooltipDataProcessor.AddTooltipPostCall(Enum.TooltipDataType.Unit, AddTooltipLines)
end
