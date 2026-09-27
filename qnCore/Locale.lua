-- qnCore: englische Texte (alle Clients außer deDE). Schlüssel = deutscher Text im Code.

local ADDON, ns = ...
local L = qnCore.NewLocale(ns, ADDON)
if qnCore.GERMAN then return end

-- Core.lua
L["Version %s, aktives Profil: %s"] = "Version %s, active profile: %s"
L["  %s – %d Profil(e)"] = "  %s – %d profile(s)"
L["Deutscher Client: alle Texte erscheinen im Original."] = "German client: all texts are shown in the original."
L["Bisher wurde kein Text ohne Übersetzung angezeigt."] = "No untranslated text has been shown so far."
L["/qncore – Optionen   |   /qncore profile – Profile   |   /qncore status – aktives Profil anzeigen   |   /qncore locale – fehlende Übersetzungen"] = "/qncore – options   |   /qncore profile – profiles   |   /qncore status – show active profile   |   /qncore locale – missing translations"
L["Profil gewechselt: %s"] = "Profile changed: %s"

-- Profiles.lua
L["Bisherige Einstellungen in das Profil %s übernommen."] = "Previous settings moved into profile %s."
L["noch nicht ermittelt"] = "not yet determined"
L["%s (Blizzard-Vorgabe)"] = "%s (Blizzard preset)"
L["%s (charakterspezifisch, %s)"] = "%s (character-specific, %s)"
L["%s (Konto)"] = "%s (account)"

-- Visible.lua (übernommen aus qnViewPort)
L["%s in den sichtbaren Bereich verschoben."] = "%s moved into the visible area."
L["%s ist geschützt – im Kampf nicht verschiebbar."] = "%s is protected – cannot be moved in combat."
L["%s liegt bereits im sichtbaren Bereich."] = "%s is already in the visible area."
L["%s kann nicht verschoben werden."] = "%s cannot be moved."

-- Bags.lua
L["Nichts tun"] = "Do nothing"
L["Nur den Rucksack öffnen"] = "Backpack only"
L["Alle Taschen schließen"] = "Close all bags"
L["Handel mit Spielern"] = "Player Trading Frame"

-- Options.lua
L["Profil"] = "Profile"
L["Einstellungsprofile"] = "Settings profiles"
L["Profile …"] = "Profiles …"
L["Verfolgung merken"] = "Remember tracking"
L["Merkt sich je Charakter, was im Verfolgungsmenü der Minikarte an- oder abgewählt ist (z. B. Kräutersuche, Mineraliensuche, Schatzsucher), und stellt es nach dem Einloggen, /reload, Zonenwechsel und der Wiederbelebung wieder her. Der Schalter gilt für alle Charaktere."] = "Remembers per character what is checked or unchecked in the Minimap tracking menu (e.g. Find Herbs, Find Minerals, Find Treasure) and restores it after logging in, /reload, changing zones and resurrection. This switch applies to all characters."
L["Alle qn-Addons speichern ihre Einstellungen je Layout des Bearbeitungsmodus. Das aktive Profil wechselt mit dem Layout – auch bei charakterspezifischen Layouts."] = "All qn addons store their settings per Edit Mode layout. The active profile changes with the layout – character-specific layouts included."
L["Taschen-Automatik"] = "Bag Automation"
L["Taschen-Automatik aktiv"] = "Bag automation enabled"
L["Aus, wenn ein anderes Taschen-Addon das Öffnen und Schließen übernimmt."] = "Turn off if another bag addon handles opening and closing."
L["Berufstaschen mit öffnen"] = "Also open profession bags"
L["Beim Öffnen aller eigenen Taschen (Taste B, Händler, Bank …) auch Berufstaschen wie Kräuter- oder Verzauberertasche und die Reagenzientasche öffnen. Aus: sie bleiben zu; einzeln angeklickt öffnen sie sich weiterhin. Bei zusammengefassten Taschen wirkt das nur auf die Reagenzientasche."] = "When all your bags open (B key, merchant, bank …), also open profession bags such as herb or enchanting bags and the reagent bag. Off: they stay closed; clicking one still opens it. With combined bags this only affects the reagent bag."
L["An allen Orten gleich"] = "Same at every location"
L["An: Eine Einstellung gilt für jeden Ort (Auktionshaus, Bank, Händler …). Aus: Jeder Ort wird einzeln eingestellt."] = "On: one setting applies to every location (auction house, bank, merchant …). Off: each location is set up separately."
L["Überall: beim Öffnen"] = "Everywhere: on open"
L["Was mit den Taschen passiert, wenn einer der Orte geöffnet wird."] = "What happens to your bags when one of the locations opens."
L["Überall: beim Schließen alle Taschen schließen"] = "Everywhere: close all bags on close"
L["%s: beim Öffnen"] = "%s: on open"
L["Was mit den Taschen passiert, wenn dieser Ort geöffnet wird: %s."] = "What happens to your bags when this location opens: %s."
L["%s: beim Schließen alle Taschen schließen"] = "%s: close all bags on close"

-- ProfilesPage.lua
L["alle qn-Addons"] = "all qn addons"
L["Alle qn-Addons"] = "All qn addons"
L["%d Addon(s) übernommen aus %s."] = "%d addon(s) copied from %s."
L["Profil %s bei %d Addon(s) gelöscht."] = "Profile %s deleted for %d addon(s)."
L["Aktives Profil zurückgesetzt (%s)."] = "Active profile reset (%s)."
L["Im Kampf: wird nach dem Kampf angewendet."] = "In combat: will be applied after combat."
L["Profil %s löschen (%s)?"] = "Delete profile %s (%s)?"
L["In aktives Profil kopieren"] = "Copy into active profile"
L["Einstellungen aus %s in das aktive Profil %s übernehmen (%s)?\nDie bisherigen Einstellungen des aktiven Profils gehen verloren."] = "Copy the settings of %s into the active profile %s (%s)?\nThe current settings of the active profile will be lost."
L["Vorhanden bei: %s"] = "Used by: %s"
L["Aktives Profil:"] = "Active profile:"
L["(aktiv)"] = "(active)"
L["qnCore – Profile"] = "qnCore – Profiles"
L["Alle qn-Addons speichern ihre Einstellungen je Layout des Bearbeitungsmodus (Esc → Bearbeitungsmodus). Wechselst du dort das Layout, wechselt auch das Profil. Charakterspezifische Layouts haben eigene Profile, die nur dieser Charakter benutzt. Ein neues Layout startet mit einer Kopie des bisher aktiven Profils."] = "All qn addons store their settings per Edit Mode layout (Esc → Edit Mode). Switching the layout there switches the profile as well. Character-specific layouts have their own profiles, used only by that character. A new layout starts with a copy of the previously active profile."
L["Gilt für:"] = "Applies to:"
L["Aktives Profil zurücksetzen"] = "Reset active profile"
L["Aktives Profil %s auf die Standardwerte zurücksetzen (%s)?"] = "Reset active profile %s to default values (%s)?"
L["Setzt die Einstellungen des aktiven Profils auf die Standardwerte (für die unter 'Gilt für' gewählten Addons)."] = "Resets the settings of the active profile to default values (for the addons selected under 'Applies to')."
L["Gespeicherte Profile"] = "Saved profiles"
L["Noch keine Profile – das Layout ist noch nicht ermittelt."] = "No profiles yet – the layout has not been determined."
L["Profile"] = "Profiles"
