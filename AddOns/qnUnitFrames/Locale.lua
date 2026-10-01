-- qnUnitFrames: German texts (deDE clients only). Key = English text in the code.
-- Blizzard texts in the code: KEY_BUTTON1–5 (mouse buttons), ALT_KEY_TEXT/CTRL_KEY_TEXT/SHIFT_KEY_TEXT,
-- MACRO (Macro), TARGET (Target), FRAME_ACTION_MENU (Menu), SET_FOCUS (Set Focus), GENERAL,
-- HUD_EDIT_MODE_SETTINGS_CATEGORY_TITLE_FRAMES (Frames), DELETE, ACCEPT, CANCEL,
-- HUD_EDIT_MODE_SETTING_ACTION_BAR_ICON_SIZE (Icon Size).

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
L["Range Icon"] = "Reichweitensymbol"
L["At the target frame"] = "Am Zielrahmen"
L["At the focus frame"] = "Am Fokusrahmen"
L["Shows to the right of the target frame the icon of your farthest ranged action that can be used right now, as soon as the target is within its range. Within melee range the icon of the auto attack appears."] = "Zeigt rechts neben dem Zielrahmen das Symbol deiner gerade einsetzbaren Fernkampfaktion mit der größten Reichweite, sobald das Ziel in ihrer Reichweite ist. In Nahkampfreichweite erscheint das Symbol des automatischen Angriffs."
L["Shows to the right of the focus frame the icon of your farthest ranged action that can be used right now, as soon as the focus is within its range. Within melee range the icon of the auto attack appears."] = "Zeigt rechts neben dem Fokusrahmen das Symbol deiner gerade einsetzbaren Fernkampfaktion mit der größten Reichweite, sobald der Fokus in ihrer Reichweite ist. In Nahkampfreichweite erscheint das Symbol des automatischen Angriffs."
L["Horizontal offset"] = "Horizontaler Versatz"
L["Vertical offset"] = "Vertikaler Versatz"
L["Distance from the right edge of the frame; negative values move the icon to the left."] = "Abstand vom rechten Rand des Rahmens; negative Werte verschieben das Symbol nach links."
L["Distance from the vertical center of the frame; positive values move the icon up."] = "Abstand von der vertikalen Mitte des Rahmens; positive Werte verschieben das Symbol nach oben."

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
