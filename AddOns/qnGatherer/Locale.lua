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
