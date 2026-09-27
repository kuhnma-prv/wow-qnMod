-- qnInventory: Bestand und Gold aller Charaktere.
-- Core: Namensraum, gespeicherte Daten, Hilfsfunktionen, Slash-Befehle.

local ADDON, ns = ...

-- Version, Print, Ereignisse und die Secret-Helfer kommen aus qnCore. Secret-Values werden
-- nicht gespeichert, sondern übersprungen. Bestandsdaten sind keine Einstellungen
-- und hängen deshalb an keinem Profil.
qnCore.NewAddon(ns, ADDON)
local L = ns.L

---------------------------------------------------------------------------
-- Datenbank
-- qnInventoryDB.realms[realm][name] = {
--     class, money,
--     bags = { [itemID] = Anzahl },
--     bank = { [itemID] = Anzahl } oder nil, solange die Bank nie offen war
--     mail = { [itemID] = Anzahl } oder nil, solange nichts bekannt ist
--     mailMoney, mailIncomplete
-- }
---------------------------------------------------------------------------

local function InitDB()
	qnInventoryDB = qnInventoryDB or {}
	qnInventoryDB.realms = qnInventoryDB.realms or {}

	ns.realm = GetRealmName()
	ns.player = UnitName("player")

	local realmDB = qnInventoryDB.realms[ns.realm] or {}
	qnInventoryDB.realms[ns.realm] = realmDB
	ns.realmDB = realmDB

	-- Eintrag aus Version 0.1.0, als der Name zu früh abgefragt wurde
	realmDB[UNKNOWNOBJECT] = nil

	local char = realmDB[ns.player] or {}
	realmDB[ns.player] = char
	ns.char = char
	local _, class = UnitClass("player")
	char.class = qnCore.Plain(class, char.class)   -- secret: bisherige Klasse behalten
	qnCore.RemoveKeys(char, { "faction", "updated" })   -- früher gespeichert, nie gelesen
end

-- Zählt n Stück (Vorgabe 1) von id in t
function ns.AddCount(t, id, n)
	t[id] = (t[id] or 0) + (n or 1)
end

-- Gespeicherter Charakter zum Namen (Groß-/Kleinschreibung egal, auch Umlaute), Vorgabe: dieser Realm
function ns.FindChar(name, realmDB)
	for stored in pairs(realmDB or ns.realmDB) do
		if strcmputf8i(stored, name) == 0 then
			return stored
		end
	end
end

-- Realmname wie in "Name-Realm" (ohne Leerzeichen und Bindestriche, klein)
local function RealmKey(realm)
	return (realm:gsub("[%s%-]", ""):lower())
end

-- Gespeicherte Realms, die mit diesem verbunden sind (ohne den eigenen): { { realm, db }, … },
-- alphabetisch. Die Liste der verbundenen Realms liefert der Client (C_AutoComplete).
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

-- Gespeicherter Realm (Name und Daten) zu einer Realm-Angabe aus "Name-Realm": dieser oder ein
-- verbundener, sonst nil.
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

-- Charaktere eines Realms (Vorgabe: dieser), alphabetisch
function ns.SortedChars(realmDB)
	local list = {}
	for name in pairs(realmDB or ns.realmDB) do
		list[#list + 1] = name
	end
	table.sort(list, function(a, b) return strcmputf8i(a, b) < 0 end)
	return list
end

---------------------------------------------------------------------------
-- Slash-Befehle
---------------------------------------------------------------------------

local function ShowGold()
	local total = 0
	ns.Print(L["Gold auf %s:"], ns.realm)
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
		ns.Print(L["Aufruf: /qninv delete <Name>"])
		return
	end
	local stored = ns.FindChar(name)
	if not stored then
		ns.Print(L["%s ist auf %s nicht gespeichert."], name, ns.realm)
	elseif stored == ns.player then
		ns.Print(L["Der eingeloggte Charakter kann nicht gelöscht werden."])
	else
		ns.realmDB[stored] = nil
		ns.Print(L["%s gelöscht."], stored)
	end
end

-- rest in der eingegebenen Schreibweise (Charaktername)
qnCore.RegisterSlash("QNINVENTORY", { "/qninv", "/qninventory" }, function(cmd, rest)
	if cmd == "" or cmd == "gold" then
		ShowGold()
	elseif cmd == "delete" then
		DeleteChar(rest)
	else
		ns.Print(L["Befehle: /qninv gold · /qninv delete <Name>"])
	end
end)

---------------------------------------------------------------------------
-- Start
---------------------------------------------------------------------------

-- Erst bei PLAYER_LOGIN: bei ADDON_LOADED liefert UnitName("player") noch UNKNOWNOBJECT
ns.events.Register("PLAYER_LOGIN", function()
	InitDB()
	ns.InitScan()
	ns.InitMail()
	ns.InitTooltip()
end)
