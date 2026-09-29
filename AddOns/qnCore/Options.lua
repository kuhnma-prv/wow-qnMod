-- qnCore: Optionen im Blizzard-Einstellungsfenster (Settings-API).
-- Hauptseite "qnCore" (Profil, Minikarte, Questzielverfolgung) und Unterseite "Taschen-Automatik".
-- Taschen und der Schalter der Verfolgung gelten immer kontoweit (qnCoreDB.global), nie je Profil oder Charakter.
-- Die Schrift der Questzielverfolgung gilt je Profil (ns.store).
-- Die Seite "Profile" baut ProfilesPage.lua.

local _, ns = ...
local lib = qnCore
local L = ns.L
local S = lib.Settings

local function Build(category, layout)
	local Bags = ns.Bags

	-- Hauptseite ----------------------------------------------------------
	local B = S.New({ prefix = "QNCORE_", source = function() return ns.global end, defaults = ns.defaults })

	S.Header(layout, L["Profil"])
	S.Button(layout, L["Einstellungsprofile"], L["Profile …"], function() ns.OpenProfiles() end,
		L["Alle qn-Addons speichern ihre Einstellungen je Layout des Bearbeitungsmodus. Das aktive Profil wechselt mit dem Layout – auch bei charakterspezifischen Layouts."])

	S.Header(layout, MINIMAP_LABEL)
	B:Checkbox(category, "tracking", L["Verfolgung merken"],
		L["Merkt sich je Charakter, was im Verfolgungsmenü der Minikarte an- oder abgewählt ist (z. B. Kräutersuche, Mineraliensuche, Schatzsucher), und stellt es nach dem Einloggen, /reload, Zonenwechsel und der Wiederbelebung wieder her. Der Schalter gilt für alle Charaktere."],
		function(_, value) ns.Tracking.OnOptionChanged(value) end)

	-- Questzielverfolgung (je Profil) ----------------------------------------
	local QB = S.New({ store = ns.store, prefix = "QNCORE_", apply = function() ns.QuestTracker.Apply() end })
	local sizes = { { 0, L["Wie im Bearbeitungsmodus"] } }
	for _, size in ipairs(ns.QuestTracker.SIZES) do
		sizes[#sizes + 1] = { size, tostring(size) }
	end
	S.Header(layout, HUD_EDIT_MODE_OBJECTIVE_TRACKER_LABEL)
	QB:Dropdown(category, "questTextSize", HUD_EDIT_MODE_SETTING_OBJECTIVE_TRACKER_TEXT_SIZE, sizes,
		L["Schriftgröße der Questzielverfolgung unterhalb von Blizzards Minimum 12 (Überschriften 2 größer). „Wie im Bearbeitungsmodus“: es gilt Blizzards Regler. Gilt je Layout des Bearbeitungsmodus."],
		Settings.VarType.Number)

	-- Taschen-Automatik ---------------------------------------------------
	local bags, bagsLayout = Settings.RegisterVerticalLayoutSubcategory(category, L["Taschen-Automatik"])

	local BB = S.New({
		prefix = "QNCORE_BAGS_",
		source = Bags.Config,
		defaults = Bags.defaults,
	})

	S.Header(bagsLayout, GENERAL)
	BB:Checkbox(bags, "enabled", L["Taschen-Automatik aktiv"],
		L["Aus, wenn ein anderes Taschen-Addon das Öffnen und Schließen übernimmt."])
	BB:Checkbox(bags, "openProfessionBags", L["Berufstaschen mit öffnen"],
		L["Beim Öffnen aller eigenen Taschen (Taste B, Händler, Bank …) auch Berufstaschen wie Kräuter- oder Verzauberertasche und die Reagenzientasche öffnen. Aus: sie bleiben zu; einzeln angeklickt öffnen sie sich weiterhin. Bei zusammengefassten Taschen wirkt das nur auf die Reagenzientasche."])

	local same = BB:Checkbox(bags, "sameEverywhere", L["An allen Orten gleich"],
		L["An: Eine Einstellung gilt für jeden Ort (Auktionshaus, Bank, Händler …). Aus: Jeder Ort wird einzeln eingestellt."])

	local function Same() return Bags.Config().sameEverywhere end
	local function NotSame() return not Bags.Config().sameEverywhere end

	S.Depends(BB:Dropdown(bags, "allOpen", L["Überall: beim Öffnen"], Bags.OPEN_MODES,
		L["Was mit den Taschen passiert, wenn einer der Orte geöffnet wird."], Settings.VarType.String), same, Same)
	S.Depends(BB:Checkbox(bags, "allClose", L["Überall: beim Schließen alle Taschen schließen"]), same, Same)

	for _, v in ipairs(Bags.VENUES) do
		S.Header(bagsLayout, v.label)
		S.Depends(BB:Dropdown(bags, v.key .. "Open", L["%s: beim Öffnen"]:format(v.label), Bags.OPEN_MODES,
			L["Was mit den Taschen passiert, wenn dieser Ort geöffnet wird: %s."]:format(v.label), Settings.VarType.String), same, NotSame)
		S.Depends(BB:Checkbox(bags, v.key .. "Close", L["%s: beim Schließen alle Taschen schließen"]:format(v.label)), same, NotSame)
	end
end

-- setzt ns.category und ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnCore", Build)
end
