-- Scenario 1: qnTooltip - loading, options pages, appearance (own background instead of NineSlice),
-- header lines of players and NPCs from the elements (order, colors, formats, filters,
-- titles), border/background colors, target line, "Targeted by", health bar, right-click hint.
EnableTooltips()
local L_ = function(s) return s end

QN_UNITS.mouseover = {
	name = "Arthas", realm = nil, class = "PALADIN", className = "Paladin", level = 60, raceName = "Mensch",
	factionGroup = "Alliance", factionName = FACTION_ALLIANCE, reaction = 5, isPlayer = true, guid = "Player-2",
	guild = { "Silberne Hand", "Offizier", 2, nil }, pvpName = "Ritter Arthas", afk = true,
	health = 3000, maxHealth = 4000, target = "player", raidIcon = 8,
}
QN_GUIDS["Player-2"] = "mouseover"

LoadAddon("qnCore")
local tt = LoadAddon("qnTooltip")
local L = tt.L
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(1)

---------------------------------------------------------------------------
-- Loading and options
---------------------------------------------------------------------------
Check(tt.db and tt.db.bgFile == "rock", "profile with defaults")
local cats = table.concat(LOG, ";")
for _, name in ipairs({ "qnTooltip" }) do
	Check(cats:find("Kategorie " .. name, 1, true), "category " .. name)
end
Check(SETTINGS.QNTOOLTIP_PLAYER_BORDERCOLOR and SETTINGS.QNTOOLTIP_NPC_ANCHORMODE, "settings for players and NPCs")
Check(tt.elementsUI.player and tt.elementsUI.npc, "lines pages created")

---------------------------------------------------------------------------
-- Appearance
---------------------------------------------------------------------------
local bd = GameTooltip.qnBackdrop
Check(bd and bd._backdrop and bd._backdrop.bgFile == "Interface\\FrameGeneral\\UI-Background-Rock", "background rock")
Check(bd._backdrop.edgeFile == "Interface\\Tooltips\\UI-Tooltip-Border" and bd._backdrop.edgeSize == 14, "default border")
Check(bd._bdColor[4] == 0.7 and bd._bdBorder[1] == 0.6, "general colors")
Check(ItemRefTooltip.qnBackdrop ~= nil, "ItemRefTooltip styled")

SETTINGS.QNTOOLTIP_BORDERSTYLE:SetValue("angular")
Check(bd._backdrop.edgeFile == "Interface\\Buttons\\WHITE8X8" and bd._backdrop.edgeSize == 1, "angular border")
SETTINGS.QNTOOLTIP_BORDERSIZE:SetValue(3)
Check(bd._backdrop.edgeSize == 3 and bd._backdrop.insets.left == 3, "border width 3")
SETTINGS.QNTOOLTIP_BORDERSTYLE:SetValue("default")
SETTINGS.QNTOOLTIP_SCALE:SetValue(1.2)
Check(GameTooltip._scale == 1.2, "Scale")

---------------------------------------------------------------------------
-- Players
---------------------------------------------------------------------------
GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
GameTooltip:SetUnit("mouseover")
local lines = GameTooltip:Texts()
Check(GameTooltip.NineSlice._shown == false, "NineSlice hidden after SetBackdropStyle")
-- Line 1: raid target icon, faction and class icon, title, name, realm, AFK
Check(lines[1]:find("RaidTargetingIcon_8", 1, true) and lines[1]:find("SmallCircle-Alliance", 1, true), "line 1: icons: " .. lines[1])
Check(lines[1]:find("|cffccffffRitter|r |cff%x%x%x%x%x%xArthas|r |cff00eeeeRealm|r") ~= nil, "line 1: title before name, realm: " .. lines[1])
Check(lines[1]:find("(" .. AFK .. ")", 1, true), "line 1: AFK")
Check(lines[2] == "|cffff00ff<Silberne Hand>|r |cffcc88ff(Offizier)|r", "line 2: guild and rank: " .. lines[2])
Check(lines[3]:find("|cffffff0060|r", 1, true) and lines[3]:find("Mensch", 1, true) and lines[3]:find("Paladin", 1, true), "line 3: level, race, class: " .. lines[3])
Check(lines[4]:find(STAT_AVERAGE_ITEM_LEVEL, 1, true) and lines[4]:find("??", 1, true), "line 4: item level unknown: " .. lines[4])
Check(#QN_INSPECT == 1 and QN_INSPECT[1] == "mouseover", "inspect requested")
local all = table.concat(lines, "\n")
Check(not all:find(FACTION_ALLIANCE .. "\n", 1, true) and lines[5] ~= FACTION_ALLIANCE, "faction line replaced")
Check(all:find(TARGET .. ": |cffff3333>>" .. strupper(YOU) .. "<<|r", 1, true), "target line: >>YOU<<")
-- Colors: border and background in class color (stub: white), background alpha 0.9
Check(bd._bdColor[4] == 0.9, "background opacity of players")

-- Item level arrives
QN_UNITS.mouseover.itemLevel = 62.6
FireEvent("INSPECT_READY", "Player-2")
Check(QN_INSPECT.cleared, "ClearInspectPlayer after reading")
Check(GameTooltip:Texts()[4]:find("63", 1, true), "tooltip rebuilt with item level: " .. GameTooltip:Texts()[4])

-- Target change: line is updated in OnUpdate
QN_UNITS.mouseover.target = nil
GameTooltip._scripts.OnUpdate(GameTooltip, 0.3)
local targetLine = tt.Left(GameTooltip, GameTooltip.qnTarget.index)
Check(targetLine._text == "", "target line empty without target")
QN_UNITS.mouseover.target = "player"

-- Health bar
local bar = GameTooltip.StatusBar
bar:Show()
bar:SetValue(0.75)
Check(bar.qnText._text == "3000 / 4000 (75%)", "health bar: text " .. tostring(bar.qnText._text))
Check(bar._barColor and bar._barColor[1] == 1, "health bar: class color")
QN_UNITS.mouseover.dead = true
bar:SetValue(0)
Check(bar.qnText._text:find(DEAD, 1, true), "health bar: dead")
QN_UNITS.mouseover.dead = nil

-- Rearrange elements: realm off, rank before guild name, guild format, filter
local el = tt.db.player.elements
el.realm.enable = false
-- two positions: the disabled rank number sits in between
Check(tt.MoveElement("player", "guildRank", -1) and tt.MoveElement("player", "guildRank", -1), "rank up two positions")
Check(not tt.MoveElement("player", "guildRank", -1), "first position: no further up")
el.guildName.format = "[%s]"
el.statusAFK.filter = "inraid"
GameTooltip:SetUnit("mouseover")
lines = GameTooltip:Texts()
Check(not lines[1]:find("Realm", 1, true), "realm disabled")
Check(not lines[1]:find(AFK, 1, true), "AFK only in raid (filter)")
Check(lines[2] == "|cffcc88ff(Offizier)|r |cffff00ff[Silberne Hand]|r", "rank before guild, custom format: " .. lines[2])
tt.SetElementLine("player", "className", 1)
GameTooltip:SetUnit("mouseover")
Check(GameTooltip:Texts()[1]:find("Paladin", 1, true) and not GameTooltip:Texts()[3]:find("Paladin", 1, true), "class moved to line 1")
Check(el.className.order > el.statusDC.order, "to the end of the line")
-- Alt: all elements
IsAltKeyDown = function() return true end
GameTooltip:SetUnit("mouseover")
Check(GameTooltip:Texts()[1]:find("Realm", 1, true) and GameTooltip:Texts()[1]:find(AFK, 1, true), "Alt shows all elements")
IsAltKeyDown = function() return false end
-- invalid formats are not applied
Check(not tt.UnitData.ValidFormat("%s %s", "text") and not tt.UnitData.ValidFormat("%d", "text")
	and tt.UnitData.ValidFormat("%d%%", "number") and not tt.UnitData.ValidFormat("50%", "text"), "format check")
el.guildName.format = "%d"
GameTooltip:SetUnit("mouseover")
Check(GameTooltip:Texts()[2]:find("<Silberne Hand>", 1, true), "invalid format: default")

---------------------------------------------------------------------------
-- NPC with title
---------------------------------------------------------------------------
QN_UNITS.mouseover = {
	name = "Gastwirtin Allison", class = "WARRIOR", className = "Krieger", level = 30, isPlayer = false,
	guid = "Creature-1", title = "Gastwirtin", reaction = 5, classif = "elite", creature = "Humanoid",
	health = 100, maxHealth = 100, extra = { "Quest-Ziel 0/1" }, pvp = true,
}
QN_GUIDS["Creature-1"] = "mouseover"
GameTooltip:SetUnit("mouseover")
lines = GameTooltip:Texts()
Check(lines[1] == "Gastwirtin Allison", "NPC line 1: name without color (Blizzard's line color): " .. lines[1])
Check(lines[2] == "|cff99e8e8<Gastwirtin>|r", "NPC title reformatted: " .. lines[2])
Check(lines[3]:find("(" .. ELITE .. ")", 1, true) and lines[3]:find("Humanoid", 1, true), "NPC line 3: elite, creature type: " .. lines[3])
Check(not lines[3]:find(REPUTATION, 1, true) and not lines[3]:find(FACTION_STANDING_LABEL5, 1, true), "reputation only from friendly")
Check(lines[4] == "" and lines[5] == "Quest-Ziel 0/1", "PvP line cleared, quest objective stays")
Check(bd._bdColor[1] == 0 and bd._bdColor[4] == 0.9, "NPC: general background with opacity 0.9")
Check(bd._bdBorder[1] == FACTION_BAR_COLORS[5].r, "NPC: border in reaction color")

---------------------------------------------------------------------------
-- Targeted by (group)
---------------------------------------------------------------------------
QN_GROUP = { "player", "party1" }
QN_UNITS.party1 = { name = "Jaina", class = "MAGE", className = "Magier", isPlayer = true, guid = "Player-3", target = "mouseover", role = "DAMAGER" }
GameTooltip:SetUnit("mouseover")
all = table.concat(GameTooltip:Texts(), "\n")
Check(all:find(L["Targeted by:"], 1, true) and all:find("Jaina", 1, true), "targeted by: Jaina")
QN_GROUP = nil

---------------------------------------------------------------------------
-- Right-click hint on unit frames
---------------------------------------------------------------------------
GameTooltip:SetUnit("mouseover")
GameTooltip_AddBlankLineToTooltip(GameTooltip)
GameTooltip_AddInstructionLine(GameTooltip, UNIT_POPUP_RIGHT_CLICK)
lines = GameTooltip:Texts()
Check(lines[#lines] == "" and lines[#lines - 1] == "", "right-click hint and blank line removed")

---------------------------------------------------------------------------
-- Clearing resets the colors
---------------------------------------------------------------------------
GameTooltip:ClearLines()
Check(bd._bdColor[4] == 0.7 and bd._bdBorder[1] == 0.6, "general colors again after clearing")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
