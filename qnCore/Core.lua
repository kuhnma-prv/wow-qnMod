-- qnCore: eigenes Addon – Vorgaben, Start, Slash-Befehle.
-- Die Optionen von qnCore (Taschen, Verfolgung) gelten immer kontoweit: sie liegen in
-- qnCoreDB.global und hängen weder an einem Profil noch an einem Charakter.

local ADDON, ns = ...
local lib = qnCore

lib.NewAddon(ns, ADDON)
local L = ns.L

ns.defaults = {
	bags = ns.Bags.defaults,       -- Bags.lua
	tracking = true,               -- Verfolgung an der Minikarte merken (Tracking.lua)
}

-- Veraltete Schlüssel in qnCoreDB.global
local OBSOLETE = {
	"chatTimestamps",   -- Zeitstempel-Option entfernt (gibt es im Spiel)
}

-- Frühere Fassung hatte die Taschen je Profil (qnCoreDB.profiles): einmalig in die
-- kontoweiten Einstellungen übernehmen – aus dem zuletzt aktiven Profil dieses Charakters.
local function MigrateProfiles(db)
	local profiles = db.profiles
	if type(profiles) ~= "table" then
		return
	end
	local last = qnCoreCharDB and qnCoreCharDB.layout
	local src = last and profiles[last]
	if not src then
		local _, first = next(profiles)
		src = first
	end
	if type(src) == "table" then
		if not db.global.bagsShared and type(src.bags) == "table" then
			db.global.bags = CopyTable(src.bags)
		end
	end
	db.global.bagsShared = nil
	db.profiles, db.version = nil, nil
end

---------------------------------------------------------------------------
-- Slash-Befehle
---------------------------------------------------------------------------

lib.RegisterSlash("QNCORE", { "/qncore", "/qnc" }, function(cmd)
	if cmd == "" or cmd == "config" then
		ns.OpenOptions()
	elseif cmd == "profile" or cmd == "profil" then
		ns.OpenProfiles()
	elseif cmd == "status" then
		ns.Print(L["Version %s, aktives Profil: %s"], lib.version, lib.Profiles.GetLabel(lib.Profiles.GetActiveKey()))
		for _, store in ipairs(lib.Profiles.stores) do
			ns.Print(L["  %s – %d Profil(e)"], store.name, #store:ProfileKeys())
		end
	elseif cmd == "locale" then
		-- Texte, die in dieser Sitzung ohne Übersetzung angezeigt wurden
		if lib.GERMAN then
			ns.Print(L["Deutscher Client: alle Texte erscheinen im Original."])
			return
		end
		local any = false
		for addon, keys in pairs(lib.missing) do
			for key in pairs(keys) do
				any = true
				ns.Print("%s: %s", addon, tostring(key))
			end
		end
		if not any then
			ns.Print(L["Bisher wurde kein Text ohne Übersetzung angezeigt."])
		end
	else
		ns.Print(L["/qncore – Optionen   |   /qncore profile – Profile   |   /qncore status – aktives Profil anzeigen   |   /qncore locale – fehlende Übersetzungen"])
	end
end)

---------------------------------------------------------------------------
-- Start
---------------------------------------------------------------------------

ns.OnLoad(function()
	qnCoreDB = qnCoreDB or {}
	qnCoreDB.global = qnCoreDB.global or {}
	lib.Profiles.Init()
	MigrateProfiles(qnCoreDB)
	lib.RemoveKeys(qnCoreDB.global, OBSOLETE)

	ns.global = lib.MergeDefaults(qnCoreDB.global, ns.defaults)

	ns.Bags.Init()
	ns.Tracking.Init()
	ns.InitOptions()
	ns.InitProfilesPage()
end)

lib.Profiles.OnChange(function(key, old)
	if old then
		ns.Print(L["Profil gewechselt: %s"], lib.Profiles.GetLabel(key))
	end
end)
