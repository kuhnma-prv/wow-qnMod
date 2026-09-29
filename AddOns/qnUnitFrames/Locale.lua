-- qnUnitFrames: German texts (deDE clients only). Key = English text in the code.
-- Blizzard-Texte im Code: KEY_BUTTON1–5 (Maustasten), ALT_KEY_TEXT/CTRL_KEY_TEXT/SHIFT_KEY_TEXT,
-- MACRO (Makro), TARGET (Ziel), FRAME_ACTION_MENU (Menü), SET_FOCUS (Fokus setzen), GENERAL,
-- HUD_EDIT_MODE_SETTINGS_CATEGORY_TITLE_FRAMES (Rahmen), DELETE, ACCEPT, CANCEL.

local ADDON, ns = ...
local L = qnCore.NewLocale(ns, ADDON)
if not qnCore.GERMAN then return end

-- Core.lua
L["No modifier"] = "Ohne Zusatztaste"
L["Blizzard default"] = "Blizzard-Standard"
L["Spell"] = "Zauber"
L["Assist"] = "Assistieren"
L["Click casting turned off. Turn it on with /qnuf on"] = "Klickzauber ausgeschaltet. Einschalten mit /qnuf on"
L["Commands:\n  /qnuf – open options\n  /qnuf clicks – edit click bindings\n  /qnuf on | off – turn click casting on/off"] = "Befehle:\n  /qnuf – Optionen öffnen\n  /qnuf clicks – Klickbelegung bearbeiten\n  /qnuf on | off – Klickzauber ein-/ausschalten"

-- Clicks.lua
L["The change will be applied after combat."] = "Änderung wird nach dem Kampf übernommen."
L["Macro: %s"] = "Makro: %s"

-- Options.lua
L["Click casting enabled"] = "Klickzauber aktiv"
L["Off: all qnUnitFrames bindings are removed; the frames behave as without the addon."] = "Aus: alle Belegungen von qnUnitFrames aufgehoben; die Rahmen verhalten sich wie ohne Addon."
L["Click Bindings"] = "Klickbelegung"
L["Edit …"] = "Bearbeiten …"
L["Sets what a click with which mouse button and modifier key does on a party or raid frame (/qnuf clicks)."] = "Legt fest, was ein Klick mit welcher Maustaste und Zusatztaste auf einem Gruppen- oder Schlachtzugsrahmen bewirkt (/qnuf clicks)."
L["Show bindings in tooltip"] = "Belegung im Tooltip zeigen"
L["Shows below the tooltip of a bound frame which click does what."] = "Zeigt unter dem Tooltip eines belegten Rahmens, welcher Klick was bewirkt."
L["Raid-style frames"] = "Rahmen im Schlachtzugsstil"
L["Blizzard's raid frames and the party frames with the option 'Use Raid-Style Party Frames'."] = "Blizzards Schlachtzugsfenster und die Gruppenrahmen mit der Einstellung 'Gruppen wie Schlachtzüge anzeigen'."
L["Classic party frames"] = "Klassische Gruppenrahmen"
L["The party frames without the option 'Use Raid-Style Party Frames'."] = "Die Gruppenrahmen ohne die Einstellung 'Gruppen wie Schlachtzüge anzeigen'."
L["Pet frames"] = "Begleiterrahmen"
L["Also bind the frames of party members' pets."] = "Auch die Rahmen der Begleiter von Gruppenmitgliedern belegen."

-- ClicksPage.lua
L["Other spell …"] = "Anderer Zauber …"
L["Name or spell ID for %s:"] = "Name oder Zauber-ID für %s:"
L["Macro text for %s (for the clicked unit: [@mouseover], e.g. /cast [@mouseover] Heal):"] = "Makrotext für %s (für die angeklickte Einheit: [@mouseover], z. B. /cast [@mouseover] Heilen):"
L["Delete all click bindings for %s in the active profile?"] = "Alle Klickbelegungen für %s im aktiven Profil löschen?"
L["Choose spell …"] = "Zauber wählen …"
L["(empty)"] = "(leer)"
L["Bindings for %s in profile %s"] = "Belegung für %s im Profil %s"
L["Clicks on Blizzard's party and raid frames cast spells or macros on the clicked member. The bindings apply per class and are stored in the active profile (Edit Mode layout). They cannot change in combat; changes follow after combat."] = "Klicks auf Blizzards Gruppen- und Schlachtzugsrahmen wirken Zauber oder Makros auf das angeklickte Mitglied. Die Belegung gilt je Klasse und liegt im aktiven Profil (Layout des Bearbeitungsmodus). Im Kampf lässt sie sich nicht ändern; Änderungen folgen nach dem Kampf."
L["Mouse button:"] = "Maustaste:"
L["Delete all"] = "Alle löschen"
L["Deletes all click bindings of your class in the active profile (all mouse buttons)."] = "Löscht alle Klickbelegungen der eigenen Klasse im aktiven Profil (alle Maustasten)."
L["'Blizzard default' leaves the click unchanged (left click: select target, right click: menu). If you bind a spell to left click without modifier, it no longer selects a target."] = "'Blizzard-Standard' lässt den Klick unverändert (Linksklick: Ziel auswählen, Rechtsklick: Menü). Belegst du Linksklick ohne Zusatztaste mit einem Zauber, wählst du mit ihm kein Ziel mehr aus."
