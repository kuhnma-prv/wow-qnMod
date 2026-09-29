-- Szenario 4: qnTooltip – Spieler-Tooltip wie in Forever (camelot): UnitName liefert Vor- und
-- Nachname, UnitPVPName "Vorname Nachname", die Stufenzeile hat keinen Zeilentyp, die Klasse steht in
-- einer eigenen Zeile. Befund im Spiel: "Xlash Qt Qt" (Nachname als Realm und als Titel) und
-- Blizzards Zeilen "Stufe 20 Mensch (Spieler)", "Paladin", "Allianz" blieben stehen.
local function Forbidden() error("Rechnen/Vergleichen mit einem secret-Wert", 2) end
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
Check(count == 1, "Nachname genau einmal: " .. lines[1])
Check(lines[1]:find("Xlash|r |cff%x+Qt|r |cff00eeeeRealm|r") ~= nil, "Vorname, Nachname, Realm: " .. lines[1])
Check(not all:find(TOOLTIP_UNIT_LEVEL:format("20"), 1, true), "Blizzards Stufenzeile ersetzt")
Check(not all:find("\nPaladin\n", 1, true) and not all:find("\n" .. FACTION_ALLIANCE .. "\n", 1, true), "Klassen- und Fraktionszeile ersetzt")
Check(lines[2]:find("20", 1, true) and lines[2]:find("Paladin", 1, true), "Zeile 2: Stufe, Volk, Klasse: " .. lines[2])
Check(all:find("Weitere Zeile", 1, true), "übrige Zeilen bleiben")

-- nachgestellter Titel steht hinter dem Nachnamen
QN_UNITS.mouseover.pvpName = "Xlash Qt der Geduldige"
GameTooltip:SetUnit("mouseover")
lines = GameTooltip:Texts()
Check(lines[1]:find("Qt|r |cffccffffder Geduldige|r") ~= nil, "Titel hinter dem Nachnamen: " .. lines[1])
-- vorangestellter Titel
QN_UNITS.mouseover.pvpName = "Ritter Xlash Qt"
GameTooltip:SetUnit("mouseover")
Check(GameTooltip:Texts()[1]:find("|cffccffffRitter|r |cff%x+Xlash") ~= nil, "Titel vor dem Vornamen: " .. GameTooltip:Texts()[1])
QN_UNITS.mouseover.pvpName = "Xlash Qt"

-- Stufenzeile mit Zeilentyp (andere Clients bzw. spätere Builds)
QN_UNITS.mouseover.levelType = true
GameTooltip:SetUnit("mouseover")
Check(not table.concat(GameTooltip:Texts(), "\n"):find(TOOLTIP_UNIT_LEVEL:format("20"), 1, true), "Stufenzeile über Zeilentyp")
QN_UNITS.mouseover.levelType = nil

-- secret Zeilentexte (Instanzen): feste Folge Name, Stufe, Klasse, Fraktion
local data = UnitTooltipData("mouseover")
for _, line in ipairs(data.lines) do
	if line.leftText ~= "Weitere Zeile" then line.leftText = Secret(line.leftText) end
end
local ok, err = pcall(ProcessTooltip, GameTooltip, data)
Check(ok, "secret Zeilentexte ohne Fehler: " .. tostring(err))
lines = GameTooltip:Texts()
all = table.concat(lines, "\n")
Check(not all:find("S(Paladin)", 1, true) and not all:find("S(" .. FACTION_ALLIANCE .. ")", 1, true), "secret: Klasse und Fraktion ersetzt")
Check(all:find("Weitere Zeile", 1, true), "secret: übrige Zeile bleibt")

-- Realm eines anderen Realms
QN_UNITS.mouseover.realm = "Nachbar"
GameTooltip:SetUnit("mouseover")
Check(GameTooltip:Texts()[1]:find("|cff00eeeeNachbar|r", 1, true), "fremder Realm aus GetPlayerInfoByGUID")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
