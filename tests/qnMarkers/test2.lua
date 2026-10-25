-- Scenario 2: qnMarkers - markers above nameplates: repair of saved values, opt-in, icon types with
-- fallback, filters (allies, enemies, NPCs, pets, PvP, arena, totems), roles, friends and guild,
-- secret values, look (size, border, shape, colors, fade), target glow, removing nameplates,
-- profiles, options pages.

-- secret values: tables marked here count as secret (qnCore reads issecretvalue when loading)
local SECRET = setmetatable({}, { __tostring = function() return "<secret>" end })
issecretvalue = function(v) return v == SECRET end

qnCoreCharDB = { layout = "preset:1" }
qnMarkersDB = { settingsVersion = "1.0", profiles = { ["preset:1"] = {
	plates = { texture = "bogus", rotation = 999, glowColor = { 1, 2 }, friendly = { icon = "spec", size = 500, shape = "hexagon" } },
} } }

EnableTooltips()
EnableNamePlates()
LoadAddon("qnCore")
local mk = LoadAddon("qnMarkers")
FireEvent("PLAYER_LOGIN")
SetEditModeLayout(1)

local p = mk.db.plates
local MEDIA = "Interface\\AddOns\\qnMarkers\\Media\\"
local function Set(key, value) SETTINGS["QNMARKERS_PLATES_" .. key:upper()]:SetValue(value) end
local function SetSide(side, key, value) SETTINGS["QNMARKERS_" .. side:upper() .. "_" .. key:upper()]:SetValue(value) end
local function M(plate) local m = mk.PlateMarker(plate) return m and m:IsShown() and m or nil end
local function Refresh() mk.ApplyPlates() RunTimers() end

---------------------------------------------------------------------------
-- Repair on load
---------------------------------------------------------------------------
Check(qnMarkersDB.settingsVersion == "1.3", "settings version raised from 1.0 (minor: only additions)")
Check(p.texture == "arrow" and p.rotation == 360 and #p.glowColor == 4, "unknown texture, rotation and broken color repaired")
Check(p.friendly.icon == "class" and p.friendly.size == 100 and p.friendly.shape == "square", "invalid icon type, size and shape repaired")
Check(p.enabled == false and p.enemies == false, "markers and enemy markers off by default")
SetSide("friendly", "size", 40)
Set("rotation", 0)

---------------------------------------------------------------------------
-- Opt-in, class icon, look
---------------------------------------------------------------------------
local ally = AddNamePlate("nameplate1", { name = "Ally", class = "MAGE", className = "Magier", isPlayer = true, guid = "Player-2" })
Check(M(ally) == nil, "off: no marker")
Set("enabled", true)
RunTimers()
local m = M(ally)
Check(m and m.icon._atlas == "classicon-mage", "friendly player: class icon")
Check(m and m:GetWidth() == 40 + 2 * (1 + 2), "size: icon 40 + padding 1 + border 2 on each side: " .. tostring(m and m:GetWidth()))
local mage = RAID_CLASS_COLORS.MAGE
Check(m and m.border:IsShown() and m.border._color[1] == mage.r and m.bg:IsShown(), "border in class color, background")
Check(m and m._ignoreAlpha == true, "without fading: ignores the nameplate's alpha")
Set("distanceFade", true)
RunTimers()
Check(m._ignoreAlpha == false, "fading with the nameplate")
SetSide("friendly", "shape", "circle")
RunTimers()
Check(m.icon._mask ~= nil and m.bg._texture == MEDIA .. "Circle", "round: icon masked, round background")
SetSide("friendly", "shape", "square")
SetSide("friendly", "border", false)
SetSide("friendly", "background", false)
RunTimers()
Check(m.icon._mask == nil and not m.border:IsShown() and not m.bg:IsShown() and m:GetWidth() == 40, "square without border and background")
SetSide("friendly", "border", true)
SetSide("friendly", "background", true)

-- fallback when the class icon is missing
QN_NO_ATLAS["classicon-mage"] = true
Refresh()
Check(m.icon._texture == MEDIA .. "Arrow" and m.icon._color[1] == mage.r and m.icon._desat == true, "no class icon: texture in class color, desaturated")
Set("classColors", false)
Set("desaturate", false)
RunTimers()
Check(m.icon._color[1] == 1 and m.icon._color[2] == 1 and m.icon._desat == false, "without class colors: white, not desaturated")
Set("classColors", true)
Set("desaturate", true)
Set("texture", "skull")
RunTimers()
Check(m.icon._texture == "Interface\\TargetingFrame\\UI-RaidTargetingIcon_8", "texture choice: skull")
mk.PlatesBuilder:Set("customTexture", "Interface\\Icons\\Foo")
Set("texture", "custom")
RunTimers()
Check(m.icon._texture == "Interface\\Icons\\Foo", "custom texture")
Set("rotation", 90)
RunTimers()
Check(math.abs(m.icon._rotation - math.pi / 2) < 1e-6, "rotation")
Set("rotation", 0)
Set("texture", "arrow")
SetSide("friendly", "fallback", "none")
RunTimers()
Check(M(ally) == nil, "fallback none: no marker without class icon")
SetSide("friendly", "fallback", "texture")
QN_NO_ATLAS["classicon-mage"] = nil
Refresh()
Check(M(ally) and m.icon._atlas == "classicon-mage", "class icon back")
Set("allies", false)
RunTimers()
Check(M(ally) == nil, "allies off: no marker for other friendly players")
Set("allies", true)

---------------------------------------------------------------------------
-- Secret values
---------------------------------------------------------------------------
local hidden = AddNamePlate("nameplate2", { name = "Hidden", class = SECRET, className = SECRET, isPlayer = true, guid = "Player-3" })
m = M(hidden)
Check(m and m.icon._texture == MEDIA .. "Arrow" and not m.border:IsShown() and m.icon._color[1] == 1, "secret class: fallback texture, white, no border")
RemoveNamePlate("nameplate2")
Check(M(hidden) == nil, "removed nameplate: marker hidden")

---------------------------------------------------------------------------
-- Enemies, NPCs, totems, PvP, arena
---------------------------------------------------------------------------
local foe = AddNamePlate("nameplate3", { name = "Foe", class = "ROGUE", className = "Schurke", isPlayer = true, enemy = true, guid = "Player-4" })
Check(M(foe) == nil, "enemy players off by default")
Set("enemies", true)
RunTimers()
Check(M(foe) and M(foe).icon._atlas == "classicon-rogue", "enemy players on: class icon")
SetSide("enemy", "icon", "texture")
SetSide("enemy", "size", 30)
RunTimers()
Check(M(foe).icon._color[1] == 1 and M(foe).icon._color[2] == 0 and M(foe):GetWidth() == 36, "enemy: red texture, own size")
Check(M(ally):GetWidth() == 46, "friendly size unchanged")
Set("enemies", false)
Set("pvp", true)
QN_UNITS.nameplate3.pvp = true
FireEvent("UNIT_FACTION", "nameplate3")
RunTimers()
Check(M(foe) ~= nil, "PvP-flagged players")
Set("pvp", false)
RunTimers()
Check(M(foe) == nil, "PvP off: enemy hidden again")

local npc = AddNamePlate("nameplate4", { name = "Wolf", isPlayer = false, creature = "Wildtier", creatureID = 1 })
local totem = AddNamePlate("nameplate5", { name = "Totem", isPlayer = false, creature = "Totem", creatureID = 11 })
Check(M(npc) == nil, "NPCs off by default")
Set("npcs", true)
RunTimers()
Check(M(npc) and M(npc).icon._texture == MEDIA .. "Arrow", "NPC: no class, fallback texture")
Check(M(totem) == nil, "totems never")
Set("arenaOnly", true)
RunTimers()
Check(M(npc) == nil and M(ally) == nil, "only in arenas: nothing outside")
local oldInstance = IsInInstance
IsInInstance = function() return true, "arena" end
Refresh()
Check(M(npc) ~= nil and M(ally) ~= nil, "only in arenas: shown in an arena")
IsInInstance = oldInstance
Set("arenaOnly", false)
Set("npcs", false)

---------------------------------------------------------------------------
-- Pets, friends, guild
---------------------------------------------------------------------------
local pet = AddNamePlate("nameplate6", { name = "Pet", isPlayer = false, otherPet = true })
Check(M(pet) == nil, "pets off by default")
Set("pets", true)
RunTimers()
Check(M(pet) and M(pet).icon._portrait == "nameplate6" and M(pet).icon._mask ~= nil, "pet: round portrait")
Check(M(pet):GetWidth() == 40 * 0.5 + 2 * (1 + 2), "pet: half size")
Set("pets", false)

local friend = AddNamePlate("nameplate7", { name = "Friend", class = "PRIEST", className = "Priester", isPlayer = true, guid = "Player-5" })
Check(M(friend).icon._atlas == "classicon-priest", "before: normal class icon")
QN_FRIENDS = { ["Player-5"] = true }
FireEvent("FRIENDLIST_UPDATE")
RunTimers()
Check(M(friend).icon._texture == MEDIA .. "Heart", "friend: heart")
QN_FRIENDS = nil
QN_BNET["Player-5"] = true
FireEvent("BN_FRIEND_INFO_CHANGED")
RunTimers()
Check(M(friend).icon._texture == MEDIA .. "Heart", "Battle.net friend: heart")
Set("friends", false)
QN_UNITS.nameplate7.myGuild = true
FireEvent("PLAYER_GUILD_UPDATE")
RunTimers()
Check(M(friend).icon._texture == MEDIA .. "Shield", "guild member: shield")
Set("guild", false)
RunTimers()
Check(M(friend).icon._atlas == "classicon-priest", "special icons off: class icon")
Set("friends", true)
Set("guild", true)

---------------------------------------------------------------------------
-- Group and roles
---------------------------------------------------------------------------
local healer = AddNamePlate("nameplate8", { name = "Healer", class = "PRIEST", className = "Priester", isPlayer = true, inParty = true, role = "HEALER", guid = "Player-6" })
SetSide("friendly", "icon", "role")
RunTimers()
Check(M(healer) and M(healer).icon._atlas == "UI-LFG-RoleIcon-Healer", "group member: role icon")
Check(M(ally) and M(ally).icon._texture == MEDIA .. "Arrow", "no role (not in the group): fallback texture")
Set("healer", false)
RunTimers()
Check(M(healer) == nil and M(ally) ~= nil, "healers off: only the healer is hidden")
Set("healer", true)
QN_UNITS.nameplate8.role = SECRET
Refresh()
Check(M(healer) and M(healer).icon._texture == MEDIA .. "Arrow", "secret role: not filtered, fallback texture")
QN_UNITS.nameplate8.role = "HEALER"
SetSide("friendly", "icon", "class")
Set("allies", false)
Set("group", false)
RunTimers()
Check(M(healer) == nil, "group and allies off: group member hidden")
Set("allies", true)
Set("group", true)
RunTimers()

---------------------------------------------------------------------------
-- Target glow
---------------------------------------------------------------------------
QN_PLATES.target = ally
FireEvent("PLAYER_TARGET_CHANGED")
Check(not M(ally).glow:IsShown(), "glow off by default")
Set("targetGlow", true)
RunTimers()
Check(M(ally).glow:IsShown() and not M(friend).glow:IsShown(), "glow only on the target")
QN_PLATES.target = friend
FireEvent("PLAYER_TARGET_CHANGED")
Check(not M(ally).glow:IsShown() and M(friend).glow:IsShown(), "glow follows the target")
QN_PLATES.target = nil

---------------------------------------------------------------------------
-- Profiles
---------------------------------------------------------------------------
SetEditModeLayout(3)
local p3 = mk.db.plates
Check(p3 ~= p and p3.enabled and p3.enemy.size == 30, "new layout: copy of the previous profile")
Set("enabled", false)
RunTimers()
Check(M(ally) == nil, "off in the new profile")
SetEditModeLayout(1)
RunTimers()
Check(mk.db.plates == p and M(ally) ~= nil, "back: markers on again")

---------------------------------------------------------------------------
-- Options pages
---------------------------------------------------------------------------
Check(#INITIALIZERS.QNMARKERS_FRIENDLY_ICON.getOptions() == 3 and #INITIALIZERS.QNMARKERS_ENEMY_FALLBACK.getOptions() == 4, "icon type and fallback as dropdowns")
Check(#INITIALIZERS.QNMARKERS_PLATES_TEXTURE.getOptions() == #mk.TEXTURES, "texture as a dropdown")
Check(INITIALIZERS.QNMARKERS_ENEMY_SIZE:IsModifiable(), "enemy page usable while markers are on")
Set("enabled", false)
Check(not INITIALIZERS.QNMARKERS_ENEMY_SIZE:IsModifiable() and not INITIALIZERS.QNMARKERS_PLATES_NPCS:IsModifiable(), "pages disabled while markers are off")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
