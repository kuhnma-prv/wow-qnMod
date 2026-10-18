-- qnGatherer: German texts (deDE clients only). Key = English text in the code.

local ADDON, ns = ...
local L = qnCore.NewLocale(ns, ADDON)
if not qnCore.GERMAN then return end

-- Kinds.lua: gathering kinds
L["Herbalism"] = "Kräuterkunde"
L["Mining"] = "Bergbau"
L["Fishing"] = "Angeln"
L["Treasure"] = "Schätze"
L["Gas"] = "Gas"
L["Archaeology"] = "Archäologie"
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
