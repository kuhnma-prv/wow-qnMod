-- qnLoadout: sets of qn macros and qnNumKeyPad assignments per class.
-- Core: namespace, saved variable, sets of the player's class, slash commands.
--
-- The sets are written as JSON in AddOns\qnLoadout\Sets and converted by tools\Convert-QnLoadout.ps1
-- into Data.lua (ns.SETS) – WoW cannot read JSON files. Exports from the game are stored in
-- qnLoadoutDB.exports; Convert-QnLoadout.ps1 -Import turns them into JSON files.

local ADDON, ns = ...

local lib = qnCore
lib.NewAddon(ns, ADDON)
local L = ns.L

-- Name prefix of the macros this addon may create and change; other macros are never touched.
ns.PREFIX = "qn"

-- Version of the settings (see qnCore.Migrate)
local SETTINGS_VERSION = "1.0"

function ns.IsQnMacro(name)
	return type(name) == "string" and name:sub(1, #ns.PREFIX) == ns.PREFIX
end

function ns.PlayerClass()
	local _, classFile = UnitClass("player")
	return classFile
end

-- Sets of a class, sorted by name
function ns.SetsForClass(classFile)
	local list = {}
	for _, set in ipairs(ns.SETS or {}) do
		if set.class == classFile then
			list[#list + 1] = set
		end
	end
	table.sort(list, function(a, b) return a.name < b.name end)
	return list
end

function ns.FindSet(classFile, name)
	for _, set in ipairs(ns.SetsForClass(classFile)) do
		if set.name == name then
			return set
		end
	end
end

---------------------------------------------------------------------------
-- Slash commands
---------------------------------------------------------------------------

lib.RegisterSlash("QNLOADOUT", { "/qnloadout" }, function(cmd)
	if cmd == "" or cmd == "config" or cmd == "options" then
		ns.OpenOptions()
	elseif cmd == "list" then
		local sets = ns.SetsForClass(ns.PlayerClass())
		if #sets == 0 then
			ns.Print(L["No sets for your class."])
		end
		for _, set in ipairs(sets) do
			ns.Print(set.name)
		end
	else
		-- one key; Print outputs each line as a separate chat line
		ns.Print(L["Commands:\n  /qnloadout – open options\n  /qnloadout list – sets for your class"])
	end
end)

---------------------------------------------------------------------------
-- Events
---------------------------------------------------------------------------

ns.OnLoad(function()
	qnLoadoutDB = type(qnLoadoutDB) == "table" and qnLoadoutDB or {}
	lib.Migrate(qnLoadoutDB, { name = ADDON, settingsVersion = SETTINGS_VERSION, print = ns.Print })
	-- exports[name] = { class, time, json }; lastSet[class] = name of the set chosen last
	qnLoadoutDB.exports = type(qnLoadoutDB.exports) == "table" and qnLoadoutDB.exports or {}
	qnLoadoutDB.lastSet = type(qnLoadoutDB.lastSet) == "table" and qnLoadoutDB.lastSet or {}
	ns.db = qnLoadoutDB
	ns.InitOptions()
end)
