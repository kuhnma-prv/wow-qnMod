-- qnCore: German texts (deDE clients only). Key = English text in the code.

local ADDON, ns = ...
local L = qnCore.NewLocale(ns, ADDON)
if not qnCore.GERMAN then return end

-- Core.lua
L["Version %s, active profile: %s"] = "Version %s, aktives Profil: %s"
L["  %s – %d profile(s)"] = "  %s – %d Profil(e)"
L["Non-German client: all texts are shown in the original (English)."] = "Nicht-deutscher Client: alle Texte erscheinen im Original (Englisch)."
L["No untranslated text has been shown so far."] = "Bisher wurde kein Text ohne Übersetzung angezeigt."
L["/qncore – options   |   /qncore profile – profiles   |   /qncore status – show active profile   |   /qncore locale – missing translations"] = "/qncore – Optionen   |   /qncore profile – Profile   |   /qncore status – aktives Profil anzeigen   |   /qncore locale – fehlende Übersetzungen"
L["Profile changed: %s"] = "Profil gewechselt: %s"

-- Options.lua: Questzielverfolgung
L["As in Edit Mode"] = "Wie im Bearbeitungsmodus"
L["Objective Tracker text size below Blizzard's minimum of 12 (headers 2 larger). \"As in Edit Mode\": Blizzard's slider applies. Saved per Edit Mode layout."] = "Schriftgröße der Questzielverfolgung unterhalb von Blizzards Minimum 12 (Überschriften 2 größer). „Wie im Bearbeitungsmodus“: es gilt Blizzards Regler. Gilt je Layout des Bearbeitungsmodus."

-- Profiles.lua
L["Previous settings moved into profile %s."] = "Bisherige Einstellungen in das Profil %s übernommen."
L["not yet determined"] = "noch nicht ermittelt"
L["%s (Blizzard preset)"] = "%s (Blizzard-Vorgabe)"
L["%s (character-specific, %s)"] = "%s (charakterspezifisch, %s)"
L["%s (account)"] = "%s (Konto)"

-- Library.lua: Ankerpunkte (qnCore.PointEntries)
L["Top left"] = "Oben links"
L["Top center"] = "Oben Mitte"
L["Top right"] = "Oben rechts"
L["Left center"] = "Links Mitte"
L["Center"] = "Mitte"
L["Right center"] = "Rechts Mitte"
L["Bottom left"] = "Unten links"
L["Bottom center"] = "Unten Mitte"
L["Bottom right"] = "Unten rechts"

-- Visible.lua (übernommen aus qnViewPort)
L["%s moved into the visible area."] = "%s in den sichtbaren Bereich verschoben."
L["%s is protected – cannot be moved in combat."] = "%s ist geschützt – im Kampf nicht verschiebbar."
L["%s is already in the visible area."] = "%s liegt bereits im sichtbaren Bereich."
L["%s cannot be moved."] = "%s kann nicht verschoben werden."

-- Bags.lua
L["Do nothing"] = "Nichts tun"
L["Backpack only"] = "Nur den Rucksack öffnen"
L["Close all bags"] = "Alle Taschen schließen"
L["Player Trading Frame"] = "Handel mit Spielern"

-- Options.lua
L["Profile"] = "Profil"
L["Settings profiles"] = "Einstellungsprofile"
L["Profiles …"] = "Profile …"
L["Remember tracking"] = "Verfolgung merken"
L["Remembers per character what is checked or unchecked in the Minimap tracking menu (e.g. Find Herbs, Find Minerals, Find Treasure) and restores it after logging in, /reload, changing zones and resurrection. This switch applies to all characters."] = "Merkt sich je Charakter, was im Verfolgungsmenü der Minikarte an- oder abgewählt ist (z. B. Kräutersuche, Mineraliensuche, Schatzsucher), und stellt es nach dem Einloggen, /reload, Zonenwechsel und der Wiederbelebung wieder her. Der Schalter gilt für alle Charaktere."
L["All qn addons store their settings per Edit Mode layout. The active profile changes with the layout – character-specific layouts included."] = "Alle qn-Addons speichern ihre Einstellungen je Layout des Bearbeitungsmodus. Das aktive Profil wechselt mit dem Layout – auch bei charakterspezifischen Layouts."
L["Bag Automation"] = "Taschen-Automatik"
L["Bag automation enabled"] = "Taschen-Automatik aktiv"
L["Turn off if another bag addon handles opening and closing."] = "Aus, wenn ein anderes Taschen-Addon das Öffnen und Schließen übernimmt."
L["Also open profession bags"] = "Berufstaschen mit öffnen"
L["When all your bags open (B key, merchant, bank …), also open profession bags such as herb or enchanting bags and the reagent bag. Off: they stay closed; clicking one still opens it. With combined bags this only affects the reagent bag."] = "Beim Öffnen aller eigenen Taschen (Taste B, Händler, Bank …) auch Berufstaschen wie Kräuter- oder Verzauberertasche und die Reagenzientasche öffnen. Aus: sie bleiben zu; einzeln angeklickt öffnen sie sich weiterhin. Bei zusammengefassten Taschen wirkt das nur auf die Reagenzientasche."
L["Same at every location"] = "An allen Orten gleich"
L["On: one setting applies to every location (auction house, bank, merchant …). Off: each location is set up separately."] = "An: Eine Einstellung gilt für jeden Ort (Auktionshaus, Bank, Händler …). Aus: Jeder Ort wird einzeln eingestellt."
L["Everywhere: on open"] = "Überall: beim Öffnen"
L["What happens to your bags when one of the locations opens."] = "Was mit den Taschen passiert, wenn einer der Orte geöffnet wird."
L["Everywhere: close all bags on close"] = "Überall: beim Schließen alle Taschen schließen"
L["%s: on open"] = "%s: beim Öffnen"
L["What happens to your bags when this location opens: %s."] = "Was mit den Taschen passiert, wenn dieser Ort geöffnet wird: %s."
L["%s: close all bags on close"] = "%s: beim Schließen alle Taschen schließen"

-- ProfilesPage.lua
L["all qn addons"] = "alle qn-Addons"
L["All qn addons"] = "Alle qn-Addons"
L["%d addon(s) copied from %s."] = "%d Addon(s) übernommen aus %s."
L["Profile %s deleted for %d addon(s)."] = "Profil %s bei %d Addon(s) gelöscht."
L["Active profile reset (%s)."] = "Aktives Profil zurückgesetzt (%s)."
L["In combat: will be applied after combat."] = "Im Kampf: wird nach dem Kampf angewendet."
L["Delete profile %s (%s)?"] = "Profil %s löschen (%s)?"
L["Copy into active profile"] = "In aktives Profil kopieren"
L["Copy the settings of %s into the active profile %s (%s)?\nThe current settings of the active profile will be lost."] = "Einstellungen aus %s in das aktive Profil %s übernehmen (%s)?\nDie bisherigen Einstellungen des aktiven Profils gehen verloren."
L["Used by: %s"] = "Vorhanden bei: %s"
L["Active profile:"] = "Aktives Profil:"
L["(active)"] = "(aktiv)"
L["All qn addons store their settings per Edit Mode layout (Esc → Edit Mode). Switching the layout there switches the profile as well. Character-specific layouts have their own profiles, used only by that character. A new layout starts with a copy of the previously active profile."] = "Alle qn-Addons speichern ihre Einstellungen je Layout des Bearbeitungsmodus (Esc → Bearbeitungsmodus). Wechselst du dort das Layout, wechselt auch das Profil. Charakterspezifische Layouts haben eigene Profile, die nur dieser Charakter benutzt. Ein neues Layout startet mit einer Kopie des bisher aktiven Profils."
L["Applies to:"] = "Gilt für:"
L["Reset active profile"] = "Aktives Profil zurücksetzen"
L["Reset active profile %s to default values (%s)?"] = "Aktives Profil %s auf die Standardwerte zurücksetzen (%s)?"
L["Resets the settings of the active profile to default values (for the addons selected under 'Applies to')."] = "Setzt die Einstellungen des aktiven Profils auf die Standardwerte (für die unter 'Gilt für' gewählten Addons)."
L["Saved profiles"] = "Gespeicherte Profile"
L["No profiles yet – the layout has not been determined."] = "Noch keine Profile – das Layout ist noch nicht ermittelt."
L["Profiles"] = "Profile"
-- Patterns.lua
L["Hatching"] = "Schraffur"
L["Crosshatch"] = "Kreuzschraffur"
L["Grid"] = "Gitter"
L["Dots"] = "Punkte"
L["Checkerboard"] = "Schachbrett"
L["Diamonds"] = "Rauten"
L["Bricks"] = "Ziegel"
L["Weave"] = "Geflecht"
L["Scanlines"] = "Scanlinien"
L["Grain"] = "Körnung"
