-- qnGatherer: German texts (deDE clients only). Key = English text in the code.
-- Blizzard texts in the code: HERBALISM, MINING, FISHING, PROFESSIONS_ARCHAEOLOGY (kinds), ALWAYS,
-- NEVER, WORLDMAP_BUTTON (World Map), MINIMAP_LABEL (Minimap), FILTER, DELETE, REMOVE, ALL, NONE,
-- OPTIONS, UNKNOWN.

local ADDON, ns = ...
local L = qnCore.NewLocale(ns, ADDON)
if not qnCore.GERMAN then return end

-- Kinds.lua: gathering kinds without a Blizzard text
L["Treasure"] = "Schätze"
L["Gas"] = "Gas"
L["Logging"] = "Holzfällen"

-- Display.lua, WorldMap.lua: tooltips and the world map menu
L["Found by %s"] = "Gefunden von %s"
L["Imported from %s"] = "Importiert aus %s"
L["Required skill: %d"] = "Benötigte Fertigkeit: %d"
L["Delete: %s"] = "Löschen: %s"
L["The database of %s is locked."] = "Die Datenbank für %s ist gesperrt."
L["Set waypoint"] = "Wegpunkt setzen"
L["Add TomTom waypoint"] = "TomTom-Wegpunkt hinzufügen"
L["A waypoint cannot be set on this map."] = "Auf dieser Karte kann kein Wegpunkt gesetzt werden."

-- Options.lua: page qnGatherer
L["Shown nodes"] = "Angezeigte Punkte"
L["With the profession"] = "Mit dem Beruf"
L["While tracking"] = "Beim Aufspüren"
L["Always: always shown. With the profession: only if this character has the profession. While tracking: only while the matching minimap tracking (Find Herbs, Find Minerals …) is active. Never: hidden; nodes are still recorded."] = "Immer: immer angezeigt. Mit dem Beruf: nur wenn dieser Charakter den Beruf hat. Beim Aufspüren: nur solange das passende Aufspüren an der Minikarte (Kräutersuche, Mineraliensuche …) aktiv ist. Nie: ausgeblendet; die Punkte werden weiter aufgezeichnet."
L["Origin"] = "Herkunft"
L["Show nodes found by your guild"] = "Von der Gilde gefundene Punkte anzeigen"
L["Show imported nodes"] = "Importierte Punkte anzeigen"
L["Minimap button"] = "Minikarten-Knopf"
L["Show minimap button"] = "Minikarten-Knopf anzeigen"
L["Left-click: journal. Shift-left-click: minimap icons on/off. Ctrl-left-click: world map icons on/off. Right-click: options. Drag to move it along the minimap. Applies to all characters."] = "Linksklick: Nachschlagefenster. Umschalt-Linksklick: Minikartensymbole an/aus. Strg-Linksklick: Weltkartensymbole an/aus. Rechtsklick: Optionen. Ziehen verschiebt ihn am Rand der Minikarte. Gilt für alle Charaktere."

-- Options.lua: pages World Map and Minimap
L["Show icons on the world map"] = "Symbole auf der Weltkarte anzeigen"
L["Icons clickable"] = "Symbole anklickbar"
L["Tooltip on mouse over and menu on right-click (delete, waypoint). Off: the icons let the mouse through to the map."] = "Tooltip beim Überfahren und Menü per Rechtsklick (Löschen, Wegpunkt). Aus: die Symbole lassen die Maus zur Karte durch."
L["Icon size"] = "Symbolgröße"
L["Icon opacity"] = "Deckkraft der Symbole"
L["Show fishing areas"] = "Angelgebiete anzeigen"
L["Fishing areas as colored ellipses (learned from your catches or imported)."] = "Angelgebiete als farbige Ellipsen (aus deinen Fängen gelernt oder importiert)."
L["Show icons on the minimap"] = "Symbole auf der Minikarte anzeigen"
L["Tooltips on the minimap"] = "Tooltips auf der Minikarte"
L["Tooltip on mouse over, left-click pings the place. Off: the icons let the mouse through."] = "Tooltip beim Überfahren, Linksklick pingt die Stelle. Aus: die Symbole lassen die Maus durch."
L["Show nodes on the edge"] = "Punkte am Rand anzeigen"
L["Nodes outside the view slide along the edge of the minimap and fade out with the distance."] = "Punkte außerhalb des Ausschnitts gleiten am Rand der Minikarte entlang und verblassen mit der Entfernung."
L["Tracking ring"] = "Verfolgungsring"
L["Show tracking ring"] = "Verfolgungsring anzeigen"
L["Within the tracking distance the icon becomes a ring in the color of the kind."] = "Innerhalb der Verfolgungsdistanz wird das Symbol zu einem Ring in der Farbe der Art."
L["Tracking distance (yards)"] = "Verfolgungsdistanz (Meter)"
L["Color of the tracking ring and of the areas."] = "Farbe des Verfolgungsrings und der Gebiete."

-- Options.lua: pages Filter and Fishing
L["Hide single resources on the world map and the minimap. The list contains the resources you have gathered, imported or received from your guild. Hidden resources are still recorded."] = "Einzelne Ressourcen auf Weltkarte und Minikarte ausblenden. Die Liste enthält die Ressourcen, die du gesammelt, importiert oder von der Gilde erhalten hast. Ausgeblendete Ressourcen werden weiter aufgezeichnet."
L["No resources known yet."] = "Noch keine Ressourcen bekannt."
L["Sound boost while fishing"] = "Lautstärke beim Angeln anheben"
L["Turns the effect sound on and to full volume while you fish, so that the splash is easy to hear. Your settings are restored when the cast ends."] = "Schaltet beim Angeln die Effektgeräusche ein und auf volle Lautstärke, damit das Platschen gut zu hören ist. Deine Einstellungen werden am Ende des Wurfs wiederhergestellt."

-- Options.lua: page Data
L["Data"] = "Daten"
L["Merge radius (yards)"] = "Zusammenfassungsradius (Meter)"
L["Nodes of the same resource within this distance count as one node. After a change, clean up the database."] = "Punkte derselben Ressource innerhalb dieser Entfernung zählen als ein Punkt. Nach einer Änderung die Datenbank bereinigen."
L["Clean up database"] = "Datenbank bereinigen"
L["Clean up"] = "Bereinigen"
L["Merges nodes within the merge radius again and removes unreadable entries. Locked kinds stay untouched."] = "Fasst Punkte innerhalb des Zusammenfassungsradius erneut zusammen und entfernt unlesbare Einträge. Gesperrte Arten bleiben unverändert."
L["Database lock"] = "Datenbanksperre"
L["Locked: nothing is added, deleted, cleaned up or imported for this kind."] = "Gesperrt: für diese Art wird nichts hinzugefügt, gelöscht, bereinigt oder importiert."
L["Kind"] = "Art"
L["Delete all nodes of %s in %s?"] = "Alle Punkte von %s in %s löschen?"
L["Delete all stored nodes of %s?"] = "Alle gespeicherten Punkte von %s löschen?"
L["Delete in the current zone"] = "In der aktuellen Zone löschen"
L["Deletes all nodes of the selected kind in the zone you are in. They do not come back through the guild or an import."] = "Löscht alle Punkte der gewählten Art in der Zone, in der du bist. Sie kommen auch über Gilde oder Import nicht wieder."
L["Delete all nodes of the kind"] = "Alle Punkte der Art löschen"
L["Deletes all stored nodes and areas of the selected kind."] = "Löscht alle gespeicherten Punkte und Gebiete der gewählten Art."
L["Remove guild data"] = "Gildendaten entfernen"
L["Remove imported data"] = "Importierte Daten entfernen"
L["Remove all nodes found by your guild?"] = "Alle von der Gilde gefundenen Punkte entfernen?"
L["Remove all imported nodes?"] = "Alle importierten Punkte entfernen?"
L["Cleanup finished: %d duplicate nodes removed."] = "Bereinigung abgeschlossen: %d doppelte Punkte entfernt."
L["%d nodes deleted."] = "%d Punkte gelöscht."
L["All nodes of %s deleted."] = "Alle Punkte von %s gelöscht."

-- Options.lua: toggles, slash command, key bindings
L["Minimap icons shown."] = "Minikartensymbole eingeblendet."
L["Minimap icons hidden."] = "Minikartensymbole ausgeblendet."
L["World map icons shown."] = "Weltkartensymbole eingeblendet."
L["World map icons hidden."] = "Weltkartensymbole ausgeblendet."
L["Sound boost while fishing on."] = "Lautstärke beim Angeln: an."
L["Sound boost while fishing off."] = "Lautstärke beim Angeln: aus."
L["qnGatherer commands:\n/qngatherer - journal\n/qngatherer options - options\n/qngatherer mini - info window: keep open on/off\n/qngatherer minimap - minimap icons on/off\n/qngatherer worldmap - world map icons on/off\n/qngatherer sound - sound boost while fishing on/off\n/qngatherer cleanup - clean up the database\n/qngatherer help - this help"] = "qnGatherer-Befehle:\n/qngatherer - Nachschlagefenster\n/qngatherer options - Optionen\n/qngatherer mini - Infofenster: offen halten an/aus\n/qngatherer minimap - Minikartensymbole an/aus\n/qngatherer worldmap - Weltkartensymbole an/aus\n/qngatherer sound - Lautstärke beim Angeln an/aus\n/qngatherer cleanup - Datenbank bereinigen\n/qngatherer help - diese Hilfe"
L["Minimap icons on/off"] = "Minikartensymbole an/aus"
L["World map icons on/off"] = "Weltkartensymbole an/aus"

-- Launcher.lua, Titan.lua
L["on"] = "an"
L["off"] = "aus"
L["Minimap icons"] = "Minikartensymbole"
L["World map icons"] = "Weltkartensymbole"
L["Left-click: journal\nShift-left-click: minimap icons on/off\nCtrl-left-click: world map icons on/off\nRight-click: options"] = "Linksklick: Nachschlagefenster\nUmschalt-Linksklick: Minikartensymbole an/aus\nStrg-Linksklick: Weltkartensymbole an/aus\nRechtsklick: Optionen"
L["Nodes:"] = "Punkte:"
L["Zone / total"] = "Zone / gesamt"
L["Shown gathering nodes of the current zone; left-click: journal, Shift-left-click: minimap icons on/off, Ctrl-left-click: world map icons on/off."] = "Angezeigte Sammelpunkte der aktuellen Zone; Linksklick: Nachschlagefenster, Umschalt-Linksklick: Minikartensymbole an/aus, Strg-Linksklick: Weltkartensymbole an/aus."
L["Open/close the journal"] = "Nachschlagefenster öffnen/schließen"

-- Journal.lua, Mini.lua
L["%s %d (+%d)"] = "%s %d (+%d)"
L["%s %d"] = "%s %d"
L["Skill %d – %d"] = "Fertigkeit %d – %d"
L["%d nodes"] = "%d Punkte"
L["caught: %d"] = "gefangen: %d"
L["Learned from your catches"] = "Aus deinen Fängen gelernt"
L["Reported area"] = "Gemeldetes Gebiet"
L["Fish school area"] = "Gebiet mit Fischschwärmen"
L["No data for %s yet. Gather, import or receive nodes from your guild to fill the journal."] = "Noch keine Daten für %s. Sammle, importiere oder erhalte Punkte von deiner Gilde, um das Nachschlagefenster zu füllen."
L["Current zone"] = "Aktuelle Zone"
L["No map available for this zone."] = "Für diese Zone gibt es keine Karte."
L["No position in this area."] = "In diesem Gebiet gibt es keine Position."
L["No data for this zone yet."] = "Noch keine Daten für diese Zone."
L["Listen for the splash …"] = "Auf das Platschen achten …"
L["Keep open"] = "Offen halten"
L["Journal"] = "Nachschlagen"

L["all characters: %d"] = "alle Charaktere: %d"
L["Level %d – %d"] = "Stufe %d – %d"

-- Import.lua, Options.lua: import and export
L["Import from %s: %d new, %d merged, %d already known, %d rejected."] = "Import aus %s: %d neu, %d zusammengeführt, %d schon bekannt, %d abgelehnt."
L["This is not a qnGatherer export."] = "Das ist kein qnGatherer-Export."
L["text"] = "Text"
L["No data of %s found. It has to be loaded; for addons that do not load on Forever use the offline tool (tools\\Convert-QnGatherer.ps1)."] = "Keine Daten von %s gefunden. Das Addon muss geladen sein; für Addons, die auf Forever nicht laden, das Offline-Werkzeug verwenden (tools\\Convert-QnGatherer.ps1)."
L["Other addons"] = "Andere Addons"
L["Import mode"] = "Importart"
L["Merge"] = "Zusammenführen"
L["Adds what is new; nodes you deleted stay deleted."] = "Fügt Neues hinzu; von dir gelöschte Punkte bleiben gelöscht."
L["First removes everything imported from this addon before, then imports again."] = "Entfernt zuerst alles, was vorher aus diesem Addon importiert wurde, und importiert dann neu."
L["Imports the data of %s (nodes, areas, zone information) as \"imported\". The addon has to be loaded."] = "Importiert die Daten von %s (Punkte, Gebiete, Zoneninformationen) als „importiert“. Das Addon muss geladen sein."
L["Import automatically"] = "Automatisch importieren"
L["On login, imports again from every loaded addon whose data version changed since the last import."] = "Importiert beim Einloggen erneut aus jedem geladenen Addon, dessen Datenversion sich seit dem letzten Import geändert hat."
L["Exchange with other qnGatherer users"] = "Austausch mit anderen qnGatherer-Nutzern"
L["Copy the text (Ctrl+C):"] = "Text kopieren (Strg+C):"
L["Paste an export text (Ctrl+V):"] = "Exporttext einfügen (Strg+V):"
L["Export your nodes"] = "Eigene Punkte exportieren"
L["Export"] = "Exportieren"
L["Your own nodes and fishing areas as text for another qnGatherer."] = "Deine eigenen Punkte und Angelgebiete als Text für ein anderes qnGatherer."
L["Import an export text"] = "Exporttext importieren"
L["Imports the text of another qnGatherer as \"imported\"."] = "Importiert den Text eines anderen qnGatherer als „importiert“."

-- Options.lua: info window
L["Info window"] = "Infofenster"
L["Open while fishing"] = "Beim Angeln öffnen"
L["Shows the zone, its skill range and the fish of the zone with your catches when you cast."] = "Zeigt beim Auswerfen die Zone, ihren Fertigkeitsbereich und die Fische der Zone mit deinen Fängen."
L["Open while gathering"] = "Beim Sammeln öffnen"
L["Shows the resources of the zone with the required skill when you gather herbs, ore or open chests."] = "Zeigt beim Sammeln von Kräutern und Erz oder beim Öffnen von Truhen die Ressourcen der Zone mit der benötigten Fertigkeit."
L["Close after (seconds)"] = "Schließen nach (Sekunden)"
L["The window closes this long after the cast unless \"Keep open\" is checked (/qngatherer mini)."] = "Das Fenster schließt sich so lange nach dem Wurf, außer „Offen halten“ ist angehakt (/qngatherer mini)."
