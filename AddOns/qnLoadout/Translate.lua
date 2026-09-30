-- qnLoadout: spell and item names in the sets (English) <-> names of the client language.
--
-- The sets use English names (numpad spells, macro texts). WoW only knows the names of the client
-- language, therefore Sets\Spells.json and Sets\Items.json map every English name to an ID (ns.SPELLS,
-- ns.ITEMS); the client name comes from C_Spell.GetSpellName / C_Item.GetItemNameByID. Loading
-- translates English -> client, the export client -> English. Names that are not in the dictionaries
-- stay unchanged.
--
-- Item names may not be in the client's cache yet: ns.WhenItemsLoaded requests them
-- (C_Item.RequestLoadItemDataByID, event ITEM_DATA_LOAD_RESULT) and waits at most ITEM_TIMEOUT seconds.
-- All items are already requested after logging in, so they are usually there.

local _, ns = ...

local ITEM_TIMEOUT = 5

local function SpellName(id)
	local name = C_Spell.GetSpellName(id)
	if name and not ns.IsSecret(name) then
		return name
	end
end

local function ItemName(id)
	local name = C_Item.GetItemNameByID(id)
	if name and not ns.IsSecret(name) then
		return name
	end
end

-- { [English] = client name } and { [client name] = English } of one dictionary
local function Maps(dict, lookup, toClient, toEnglish)
	for english, id in pairs(dict or {}) do
		local name = lookup(id)
		if name and not toClient[english] then
			toClient[english] = name
			if not toEnglish[name] or english < toEnglish[name] then
				toEnglish[name] = english
			end
		end
	end
	return toClient, toEnglish
end

-- rebuilt on every use: names only need to be known at that moment
local function SpellMaps()
	return Maps(ns.SPELLS, SpellName, {}, {})
end

-- spells first: a name in both dictionaries (the tool refuses that) counts as a spell
local function AllMaps()
	local toClient, toEnglish = SpellMaps()
	return Maps(ns.ITEMS, ItemName, toClient, toEnglish)
end

function ns.ClientSpellName(english)
	local toClient = SpellMaps()
	return toClient[english]
end

function ns.EnglishSpellName(name)
	local _, toEnglish = SpellMaps()
	return toEnglish[name]
end

---------------------------------------------------------------------------
-- Macro texts
---------------------------------------------------------------------------

-- Letters, digits and bytes of UTF-8 characters count as part of a word.
local function IsWordByte(b)
	return b and (b >= 128 or string.char(b):match("[%w_]") ~= nil)
end

-- Replaces whole names in text according to map (longest name first, never inside a longer word or
-- in text that was already replaced).
local function Translate(text, map)
	local names = {}
	for from in pairs(map) do
		names[#names + 1] = from
	end
	table.sort(names, function(a, b) return #a > #b or (#a == #b and a < b) end)
	local found = {}
	for i, from in ipairs(names) do
		local pos = 1
		while true do
			local s, e = text:find(from, pos, true)
			if not s then
				break
			end
			if not IsWordByte(text:byte(s - 1)) and not IsWordByte(text:byte(e + 1)) then
				-- placeholder without letters, so shorter names cannot match inside it
				local mark = "\1" .. i .. "\2"
				text = text:sub(1, s - 1) .. mark .. text:sub(e + 1)
				found[i] = map[from]
				pos = s + #mark
			else
				pos = s + 1
			end
		end
	end
	return (text:gsub("\1(%d+)\2", function(i)
		return found[tonumber(i)]
	end))
end

function ns.MacroToClient(body)
	local toClient = AllMaps()
	return Translate(body, toClient)
end

function ns.MacroToEnglish(body)
	local _, toEnglish = AllMaps()
	return Translate(body, toEnglish)
end

---------------------------------------------------------------------------
-- Loading item names
---------------------------------------------------------------------------

local waiting = {}   -- { fn, ... } called once all items are there or after the timeout

-- English names of the items whose client name is not known yet (sorted)
function ns.MissingItems()
	local list = {}
	for english, id in pairs(ns.ITEMS or {}) do
		if not ItemName(id) then
			list[#list + 1] = english
		end
	end
	table.sort(list)
	return list
end

local function Flush()
	local list = waiting
	waiting = {}
	for _, fn in ipairs(list) do
		fn()
	end
end

-- Requests all item names that are not known yet.
function ns.RequestItems()
	for _, english in ipairs(ns.MissingItems()) do
		C_Item.RequestLoadItemDataByID(ns.ITEMS[english])
	end
end

-- fn() right away if all item names are known, otherwise once they are loaded or after ITEM_TIMEOUT seconds.
function ns.WhenItemsLoaded(fn)
	if #ns.MissingItems() == 0 then
		fn()
		return
	end
	waiting[#waiting + 1] = fn
	if #waiting == 1 then
		ns.RequestItems()
		C_Timer.After(ITEM_TIMEOUT, Flush)
	end
end

ns.events.Register("ITEM_DATA_LOAD_RESULT", function()
	if #waiting > 0 and #ns.MissingItems() == 0 then
		Flush()
	end
end)

ns.events.Register("PLAYER_LOGIN", ns.RequestItems)
