-- Scenario 4: qnTooltip - player tooltip as in Forever (camelot): UnitName returns first and
-- last name, UnitPVPName "FirstName LastName", the level line has no line type, the class is on
-- its own line. Finding in game: "Xlash Qt Qt" (last name as realm and as title) and
-- Blizzard's lines "Stufe 20 Mensch (Spieler)", "Paladin", "Allianz" remained.
local function Forbidden() error("arithmetic/comparison with a secret value", 2) end
local SecretMT = { __add = Forbidden, __sub = Forbidden, __lt = Forbidden, __le = Forbidden, __eq = Forbidden,
	__concat = Forbidden, __len = Forbidden, __index = function() Forbidden() end,
	__tostring = function(t) return "S(" .. tostring(rawget(t, "v")) .. ")" end }
local function Secret(v) return setmetatable({ v = v }, SecretMT) end
issecretvalue = function(v) return getmetatable(v) == SecretMT end

EnableTooltips()
QN_UNITS.mouseover = {
	name = "Xlash", surname = "Qt", pvpName = "Xlash Qt", class = "PALADIN", className = "Paladin", level = 20,
	raceName = "Mensch", factionGroup = "Alliance", factionName = FACTION_ALLIANCE, isPlayer = true, guid = "Player-7",
	health = 971, maxHealth = 971, target = "player", extra = { "Weitere Zeile" },
}
QN_GUIDS["Player-7"] = "mouseover"

LoadAddon("qnCore")
local tt = LoadAddon("qnTooltip")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(1)

GameTooltip:SetUnit("mouseover")
local lines = GameTooltip:Texts()
local all = table.concat(lines, "\n")
local _, count = lines[1]:gsub("Qt", "")
Check(count == 1, "last name exactly once: " .. lines[1])
Check(lines[1]:find("Xlash|r |cff%x+Qt|r |cff00eeeeRealm|r") ~= nil, "first name, last name, realm: " .. lines[1])
Check(not all:find(TOOLTIP_UNIT_LEVEL:format("20"), 1, true), "Blizzard's level line replaced")
Check(not all:find("\nPaladin\n", 1, true) and not all:find("\n" .. FACTION_ALLIANCE .. "\n", 1, true), "class and faction line replaced")
Check(lines[2]:find("20", 1, true) and lines[2]:find("Paladin", 1, true), "line 2: level, race, class: " .. lines[2])
Check(all:find("Weitere Zeile", 1, true), "other lines stay")

-- suffix title follows the last name
QN_UNITS.mouseover.pvpName = "Xlash Qt der Geduldige"
GameTooltip:SetUnit("mouseover")
lines = GameTooltip:Texts()
Check(lines[1]:find("Qt|r |cffccffffder Geduldige|r") ~= nil, "title after the last name: " .. lines[1])
-- prefix title
QN_UNITS.mouseover.pvpName = "Ritter Xlash Qt"
GameTooltip:SetUnit("mouseover")
Check(GameTooltip:Texts()[1]:find("|cffccffffRitter|r |cff%x+Xlash") ~= nil, "title before the first name: " .. GameTooltip:Texts()[1])
QN_UNITS.mouseover.pvpName = "Xlash Qt"

-- Level line with line type (other clients or later builds)
QN_UNITS.mouseover.levelType = true
GameTooltip:SetUnit("mouseover")
Check(not table.concat(GameTooltip:Texts(), "\n"):find(TOOLTIP_UNIT_LEVEL:format("20"), 1, true), "level line via line type")
QN_UNITS.mouseover.levelType = nil

-- secret line texts (instances): fixed order name, level, class, faction
local data = UnitTooltipData("mouseover")
for _, line in ipairs(data.lines) do
	if line.leftText ~= "Weitere Zeile" then line.leftText = Secret(line.leftText) end
end
local ok, err = pcall(ProcessTooltip, GameTooltip, data)
Check(ok, "secret line texts without error: " .. tostring(err))
lines = GameTooltip:Texts()
all = table.concat(lines, "\n")
Check(not all:find("S(Paladin)", 1, true) and not all:find("S(" .. FACTION_ALLIANCE .. ")", 1, true), "secret: class and faction replaced")
Check(all:find("Weitere Zeile", 1, true), "secret: other line stays")

-- Realm of another realm
QN_UNITS.mouseover.realm = "Nachbar"
GameTooltip:SetUnit("mouseover")
Check(GameTooltip:Texts()[1]:find("|cff00eeeeNachbar|r", 1, true), "foreign realm from GetPlayerInfoByGUID")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
