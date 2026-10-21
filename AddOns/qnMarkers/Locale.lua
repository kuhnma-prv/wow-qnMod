-- qnMarkers: German texts (deDE clients only). Key = English text in the code.

local ADDON, ns = ...
local L = qnCore.NewLocale(ns, ADDON)
if not qnCore.GERMAN then return end

-- Core.lua
L["Bar hidden. To show it, type /qnmarkers show"] = "Leiste ausgeblendet. Einblenden mit /qnmarkers show"
L["Position unlocked. Drag the bar by its grip."] = "Position entsperrt. Leiste am Griff ziehen."
L["Commands:\n  /qnmarkers – open options\n  /qnmarkers show | hide | toggle – show/hide the bar\n  /qnmarkers lock | unlock – lock/unlock position\n  /qnmarkers reset – reset position\n  /qnmarkers visible – move bar into the visible area"] = "Befehle:\n  /qnmarkers – Optionen öffnen\n  /qnmarkers show | hide | toggle – Leiste ein-/ausblenden\n  /qnmarkers lock | unlock – Position sperren/entsperren\n  /qnmarkers reset – Position zurücksetzen\n  /qnmarkers visible – Leiste in den sichtbaren Bereich holen"

-- Bar.lua
L["Drag: move bar\nLeft-click: minimize/expand\nRight-click: clear all world markers and the marker of your target"] = "Ziehen: Leiste verschieben\nLinksklick: minimieren/aufklappen\nRechtsklick: alle Bodenmarkierungen und die Markierung deines Ziels löschen"
L["Left-click: place world marker\nRight-click: set target marker"] = "Linksklick: Bodenmarkierung setzen\nRechtsklick: Zielmarkierung setzen"
L["Left- or right-click: set target marker\nWorld markers are not available."] = "Links- oder Rechtsklick: Zielmarkierung setzen\nBodenmarkierungen sind nicht verfügbar."
L["Requires group leader or assistant."] = "Nur als Gruppenleiter oder Assistent."
L["Pull timer: %d seconds"] = "Pull-Timer: %d Sekunden"
L["Clear world markers"] = "Bodenmarkierungen löschen"
L["Removes all world markers."] = "Entfernt alle Bodenmarkierungen."
L["World markers are not available."] = "Bodenmarkierungen sind nicht verfügbar."
L["Clear target marker"] = "Zielmarkierung löschen"
L["Removes the marker from your current target."] = "Entfernt die Markierung von deinem aktuellen Ziel."
L["Asks for confirmation first."] = "Fragt vorher nach."
L["Leave the current group?"] = "Die aktuelle Gruppe verlassen?"

-- Options.lua
L["Raid Marker Bar"] = "Markierungsleiste"
L["Show bar"] = "Leiste anzeigen"
L["In a group"] = "In einer Gruppe"
L["In a raid"] = "Im Schlachtzug"
L["Also applies in combat."] = "Gilt auch im Kampf."
L["Only as leader or assistant"] = "Nur als Leiter oder Assistent"
L["Hides the bar unless you are the group leader or a raid assistant. Checked again after combat."] = "Blendet die Leiste aus, solange du weder Gruppenleiter noch Schlachtzugsassistent bist. Wird nach dem Kampf neu geprüft."
L["Prevents moving the bar by its grip."] = "Verhindert das Verschieben der Leiste an ihrem Griff."
L["Floating"] = "Schwebend"
L["Without background and border: only the buttons are visible."] = "Ohne Hintergrund und Rahmen: nur die Knöpfe sind sichtbar."
L["Button spacing"] = "Knopfabstand"
