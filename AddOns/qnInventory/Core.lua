-- qnInventory: inventory and gold of all characters.
-- Core: namespace, saved data, helper functions, slash commands.

local ADDON, ns = ...

-- Version, Print, events and the secret helpers come from qnCore. Secret values are
-- not stored but skipped. Inventory data are not settings
-- and therefore are not tied to any profile.
qnCore.NewAddon(ns, ADDON)
local L = ns.L

---------------------------------------------------------------------------
-- Database
-- qnInventoryDB.options = { bothFactions, viewsBothFactions }   account-wide (Options.lua)
-- qnInventoryDB.account = { money, bank = { [itemID] = count }, bankTabs = { container with id, ... } }
--     account bank (since 0.3.0), shared by all characters; bank/bankTabs only after visiting the banker
-- qnInventoryDB.realms[realm][name] = {
--     class, money,
--     faction = "Alliance"/"Horde"/"Neutral" (since 0.3.0; missing until logged in again)
--     bags = { [itemID] = count },
--     bank = { [itemID] = count } or nil as long as the bank was never opened
--     mail = { [itemID] = count } or nil as long as nothing is known
--     mailMoney, mailIncomplete
--   Content per slot or letter for the views (since 0.2.0; missing until recorded again):
--     containers = { [container ID] = container }  bags including the keyring
--     bankTabs = { container with id, ... }        bank tabs in the order of the bank window
--     bankMaxTabs                                  number of possible bank tabs
--     bankTabCost                                  price of the next tab, nil if all are purchased
--     container = { size, link = link of the bag, items = { [slot] = { link, count } } }
--     mailList = { { sender, subject, money, cod, expires = time(), read, icon,
--                    items = { { link, count }, ... } }, ... }
-- }
---------------------------------------------------------------------------

-- Option defaults: other faction only on request (opt-in)
ns.OPTION_DEFAULTS = {
	bothFactions = false,        -- tooltips of the Titan plugins: Alliance and Horde
	viewsBothFactions = false,   -- character selection of the views: include the other faction
}

local function InitDB()
	qnInventoryDB = qnInventoryDB or {}
	qnInventoryDB.realms = qnInventoryDB.realms or {}
	qnInventoryDB.options = qnCore.MergeDefaults(qnInventoryDB.options or {}, ns.OPTION_DEFAULTS)
	ns.options = qnInventoryDB.options
	qnInventoryDB.account = qnInventoryDB.account or {}
	ns.account = qnInventoryDB.account

	ns.realm = GetRealmName()
	ns.player = UnitName("player")

	local realmDB = qnInventoryDB.realms[ns.realm] or {}
	qnInventoryDB.realms[ns.realm] = realmDB
	ns.realmDB = realmDB

	-- entry from version 0.1.0, when the name was queried too early
	realmDB[UNKNOWNOBJECT] = nil

	local char = realmDB[ns.player] or {}
	realmDB[ns.player] = char
	ns.char = char
	local _, class = UnitClass("player")
	char.class = qnCore.Plain(class, char.class)   -- secret: keep the previous class
	char.faction = qnCore.Plain(UnitFactionGroup("player"), char.faction)
	qnCore.RemoveKeys(char, { "updated" })   -- stored formerly, never read
end

-- Does a stored character belong to the selection? both = include the other faction.
-- Unknown faction (not logged in since 0.3.0) always counts.
function ns.FactionShown(char, both)
	return both or not char.faction or char.faction == ns.char.faction
end

---------------------------------------------------------------------------
-- Changes to the saved data
-- kind = "bags" (bags and gold), "bank", "mail", "account" (account bank) or "chars"
-- (character deleted, faction option changed)
---------------------------------------------------------------------------

local listeners = {}

function ns.OnDataChanged(fn)
	listeners[#listeners + 1] = fn
end

function ns.DataChanged(kind)
	for _, fn in ipairs(listeners) do
		fn(kind)
	end
end

-- Deletes a stored character (not the logged-in one); true on success
function ns.DeleteChar(realm, name)
	local realmDB = qnInventoryDB.realms[realm]
	if not (realmDB and realmDB[name]) or (realm == ns.realm and name == ns.player) then
		return false
	end
	realmDB[name] = nil
	if realm ~= ns.realm and not next(realmDB) then
		qnInventoryDB.realms[realm] = nil
	end
	ns.DataChanged("chars")
	return true
end

-- Counts n pieces (default 1) of id in t
function ns.AddCount(t, id, n)
	t[id] = (t[id] or 0) + (n or 1)
end

-- Stored character for the name (case-insensitive, umlauts too), default: this realm
function ns.FindChar(name, realmDB)
	for stored in pairs(realmDB or ns.realmDB) do
		if strcmputf8i(stored, name) == 0 then
			return stored
		end
	end
end

-- Realm name as in "Name-Realm" (without spaces and hyphens, lowercase)
local function RealmKey(realm)
	return (realm:gsub("[%s%-]", ""):lower())
end

-- Stored realms connected to this one (excluding our own): { { realm, db }, ... },
-- alphabetical. The client provides the list of connected realms (C_AutoComplete).
function ns.ConnectedRealms()
	local connected = {}
	for _, realm in ipairs(C_AutoComplete.GetAutoCompleteRealms()) do
		connected[RealmKey(realm)] = true
	end
	local list = {}
	for realm, realmDB in pairs(qnInventoryDB.realms) do
		if realm ~= ns.realm and connected[RealmKey(realm)] then
			list[#list + 1] = { realm = realm, db = realmDB }
		end
	end
	table.sort(list, function(a, b) return strcmputf8i(a.realm, b.realm) < 0 end)
	return list
end

-- Stored realm (name and data) for the realm part of "Name-Realm": this one or a
-- connected one, otherwise nil.
function ns.FindRealm(realm)
	local key = RealmKey(realm)
	if key == RealmKey(ns.realm) or key == RealmKey(GetNormalizedRealmName()) then
		return ns.realm, ns.realmDB
	end
	for _, r in ipairs(ns.ConnectedRealms()) do
		if RealmKey(r.realm) == key then
			return r.realm, r.db
		end
	end
end

function ns.MoneyText(copper)
	return GetMoneyString(copper or 0, true)
end

-- Characters of a realm (default: this one), alphabetical
function ns.SortedChars(realmDB)
	local list = {}
	for name in pairs(realmDB or ns.realmDB) do
		list[#list + 1] = name
	end
	table.sort(list, function(a, b) return strcmputf8i(a, b) < 0 end)
	return list
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

local function ShowGold()
	local total = 0
	ns.Print(L["Gold on %s:"], ns.realm)
	for _, name in ipairs(ns.SortedChars()) do
		local char = ns.realmDB[name]
		local money, mailMoney = char.money or 0, char.mailMoney or 0
		total = total + money + mailMoney
		local mailText = mailMoney > 0 and ("  (%s: %s)"):format(MAIL_LABEL, ns.MoneyText(mailMoney)) or ""
		print(("  %s  %s%s"):format(qnCore.ClassColoredName(name, char.class), ns.MoneyText(money), mailText))
	end
	print(("  %s  %s"):format(TOTAL, ns.MoneyText(total)))
end

local function DeleteChar(name)
	if not name or name == "" then
		ns.Print(L["Usage: /qninv delete <name>"])
		return
	end
	local stored = ns.FindChar(name)
	if not stored then
		ns.Print(L["%s is not stored on %s."], name, ns.realm)
	elseif stored == ns.player then
		ns.Print(L["The logged-in character cannot be deleted."])
	elseif ns.DeleteChar(ns.realm, stored) then
		ns.Print(L["%s deleted."], stored)
	end
end

-- View kind for the character name (this realm; default: the last selected one)
local function ShowView(kind, name)
	if not name or name == "" then
		ns.Toggle(kind)
		return
	end
	local stored = ns.FindChar(name)
	if stored then
		ns.Show(kind, ns.CharKey(ns.realm, stored))
	else
		ns.Print(L["%s is not stored on %s."], name, ns.realm)
	end
end

local VIEWS = { bags = true, bank = true, mail = true }

-- rest in the spelling as typed (character name)
qnCore.RegisterSlash("QNINVENTORY", { "/qninv", "/qninventory" }, function(cmd, rest)
	if cmd == "" or cmd == "gold" then
		ShowGold()
	elseif cmd == "delete" then
		DeleteChar(rest)
	elseif VIEWS[cmd] then
		ShowView(cmd, rest)
	else
		ns.Print(L["Commands: /qninv gold · /qninv bags|bank|mail [name] · /qninv delete <name>"])
	end
end)

---------------------------------------------------------------------------
-- Start
---------------------------------------------------------------------------

-- Only at PLAYER_LOGIN: at ADDON_LOADED UnitName("player") still returns UNKNOWNOBJECT
ns.events.Register("PLAYER_LOGIN", function()
	InitDB()
	ns.InitScan()
	ns.InitMail()
	ns.InitTooltip()
	ns.InitViews()
	ns.InitOptions()
	ns.InitTitan()
end)
