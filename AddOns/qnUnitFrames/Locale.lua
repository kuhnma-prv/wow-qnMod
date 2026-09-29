-- qnUnitFrames: englische Texte (alle Clients außer deDE). Schlüssel = deutscher Text im Code.
-- Blizzard-Texte im Code: KEY_BUTTON1–5 (Maustasten), ALT_KEY_TEXT/CTRL_KEY_TEXT/SHIFT_KEY_TEXT,
-- MACRO (Makro), TARGET (Ziel), FRAME_ACTION_MENU (Menü), SET_FOCUS (Fokus setzen), GENERAL,
-- HUD_EDIT_MODE_SETTINGS_CATEGORY_TITLE_FRAMES (Rahmen), DELETE, ACCEPT, CANCEL.

local ADDON, ns = ...
local L = qnCore.NewLocale(ns, ADDON)
if qnCore.GERMAN then return end

-- Core.lua
L["Ohne Zusatztaste"] = "No modifier"
L["Blizzard-Standard"] = "Blizzard default"
L["Zauber"] = "Spell"
L["Assistieren"] = "Assist"
L["Klickzauber ausgeschaltet. Einschalten mit /qnuf on"] = "Click casting turned off. Turn it on with /qnuf on"
L["Befehle:\n  /qnuf – Optionen öffnen\n  /qnuf clicks – Klickbelegung bearbeiten\n  /qnuf on | off – Klickzauber ein-/ausschalten"] = "Commands:\n  /qnuf – open options\n  /qnuf clicks – edit click bindings\n  /qnuf on | off – turn click casting on/off"

-- Clicks.lua
L["Änderung wird nach dem Kampf übernommen."] = "The change will be applied after combat."
L["Makro: %s"] = "Macro: %s"

-- Options.lua
L["Klickzauber aktiv"] = "Click casting enabled"
L["Aus: alle Belegungen von qnUnitFrames aufgehoben; die Rahmen verhalten sich wie ohne Addon."] = "Off: all qnUnitFrames bindings are removed; the frames behave as without the addon."
L["Klickbelegung"] = "Click Bindings"
L["Bearbeiten …"] = "Edit …"
L["Legt fest, was ein Klick mit welcher Maustaste und Zusatztaste auf einem Gruppen- oder Schlachtzugsrahmen bewirkt (/qnuf clicks)."] = "Sets what a click with which mouse button and modifier key does on a party or raid frame (/qnuf clicks)."
L["Belegung im Tooltip zeigen"] = "Show bindings in tooltip"
L["Zeigt unter dem Tooltip eines belegten Rahmens, welcher Klick was bewirkt."] = "Shows below the tooltip of a bound frame which click does what."
L["Rahmen im Schlachtzugsstil"] = "Raid-style frames"
L["Blizzards Schlachtzugsfenster und die Gruppenrahmen mit der Einstellung 'Gruppen wie Schlachtzüge anzeigen'."] = "Blizzard's raid frames and the party frames with the option 'Use Raid-Style Party Frames'."
L["Klassische Gruppenrahmen"] = "Classic party frames"
L["Die Gruppenrahmen ohne die Einstellung 'Gruppen wie Schlachtzüge anzeigen'."] = "The party frames without the option 'Use Raid-Style Party Frames'."
L["Begleiterrahmen"] = "Pet frames"
L["Auch die Rahmen der Begleiter von Gruppenmitgliedern belegen."] = "Also bind the frames of party members' pets."

-- ClicksPage.lua
L["Anderer Zauber …"] = "Other spell …"
L["Name oder Zauber-ID für %s:"] = "Name or spell ID for %s:"
L["Makrotext für %s (für die angeklickte Einheit: [@mouseover], z. B. /cast [@mouseover] Heilen):"] = "Macro text for %s (for the clicked unit: [@mouseover], e.g. /cast [@mouseover] Heal):"
L["Alle Klickbelegungen für %s im aktiven Profil löschen?"] = "Delete all click bindings for %s in the active profile?"
L["Zauber wählen …"] = "Choose spell …"
L["(leer)"] = "(empty)"
L["Belegung für %s im Profil %s"] = "Bindings for %s in profile %s"
L["Klicks auf Blizzards Gruppen- und Schlachtzugsrahmen wirken Zauber oder Makros auf das angeklickte Mitglied. Die Belegung gilt je Klasse und liegt im aktiven Profil (Layout des Bearbeitungsmodus). Im Kampf lässt sie sich nicht ändern; Änderungen folgen nach dem Kampf."] = "Clicks on Blizzard's party and raid frames cast spells or macros on the clicked member. The bindings apply per class and are stored in the active profile (Edit Mode layout). They cannot change in combat; changes follow after combat."
L["Maustaste:"] = "Mouse button:"
L["Alle löschen"] = "Delete all"
L["Löscht alle Klickbelegungen der eigenen Klasse im aktiven Profil (alle Maustasten)."] = "Deletes all click bindings of your class in the active profile (all mouse buttons)."
L["'Blizzard-Standard' lässt den Klick unverändert (Linksklick: Ziel auswählen, Rechtsklick: Menü). Belegst du Linksklick ohne Zusatztaste mit einem Zauber, wählst du mit ihm kein Ziel mehr aus."] = "'Blizzard default' leaves the click unchanged (left click: select target, right click: menu). If you bind a spell to left click without modifier, it no longer selects a target."
