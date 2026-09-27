-- qnUnitFrames: Optionen im Blizzard-Einstellungsfenster (Settings-API).
-- Hauptseite: Schalter und Auswahl der Rahmen; die Klickbelegung selbst baut ClicksPage.lua.
-- Die Einstellungen gehören zum aktiven Profil (qnCore); nach einem Profilwechsel liest qnCore die
-- Steuerelemente neu ein.

local _, ns = ...
local L = ns.L
local S = qnCore.Settings

local function Build(category, layout)
	local B = S.New({ store = ns.store, prefix = "QNUF_", apply = ns.ApplyChange })

	S.Header(layout, GENERAL)
	B:Checkbox(category, "enabled", L["Klickzauber aktiv"],
		L["Aus: alle Belegungen von qnUnitFrames aufgehoben; die Rahmen verhalten sich wie ohne Addon."])
	S.Button(layout, L["Klickbelegung"], L["Bearbeiten …"], function() ns.OpenClicksPage() end,
		L["Legt fest, was ein Klick mit welcher Maustaste und Zusatztaste auf einem Gruppen- oder Schlachtzugsrahmen bewirkt (/qnuf clicks)."])
	B:Checkbox(category, "tooltip", L["Belegung im Tooltip zeigen"],
		L["Zeigt unter dem Tooltip eines belegten Rahmens, welcher Klick was bewirkt."])

	S.Header(layout, HUD_EDIT_MODE_SETTINGS_CATEGORY_TITLE_FRAMES)
	B:Checkbox(category, "raidStyle", L["Rahmen im Schlachtzugsstil"],
		L["Blizzards Schlachtzugsfenster und die Gruppenrahmen mit der Einstellung 'Gruppen wie Schlachtzüge anzeigen'."])
	B:Checkbox(category, "party", L["Klassische Gruppenrahmen"],
		L["Die Gruppenrahmen ohne die Einstellung 'Gruppen wie Schlachtzüge anzeigen'."])
	B:Checkbox(category, "pets", L["Begleiterrahmen"],
		L["Auch die Rahmen der Begleiter von Gruppenmitgliedern belegen."])

	ns.InitClicksPage(category)
end

-- setzt ns.category und ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnUnitFrames", Build)
end
