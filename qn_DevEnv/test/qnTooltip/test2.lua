-- Szenario 2: qnTooltip – secret-Werte (Einschränkungen in Instanzen): Name, Gilde, Stufe, Klasse,
-- GUID und Lebenspunkte secret. Keine Fehler durch Vergleichen/Rechnen/Verketten, Werte erscheinen
-- über SetFormattedText, Farben und Filter entfallen, Ziel und Lebensbalken laufen weiter.

-- Secret-Values: Tabellen, die bei Rechnen, Vergleichen und Verketten einen Fehler werfen; tostring
-- (auch in string.format "%s", wie SetFormattedText) zeigt S(Wert).
-- issecretvalue muss vor qnCore stehen (qnCore merkt es sich beim Laden).
local function Forbidden() error("Rechnen/Vergleichen mit einem secret-Wert", 2) end
local SecretMT = { __add = Forbidden, __sub = Forbidden, __mul = Forbidden, __div = Forbidden, __unm = Forbidden,
	__lt = Forbidden, __le = Forbidden, __eq = Forbidden, __concat = Forbidden, __len = Forbidden,
	__index = function() Forbidden() end, __tostring = function(t) return "S(" .. tostring(rawget(t, "v")) .. ")" end }
local function Secret(v) return setmetatable({ v = v }, SecretMT) end
issecretvalue = function(v) return getmetatable(v) == SecretMT end
AbbreviateLargeNumbers = function(v)
	if issecretvalue(v) then return v end
	return tostring(math.floor(v))
end

EnableTooltips()
QN_UNITS.mouseover = {
	name = Secret("Fremder"), surname = Secret("Qt"), class = Secret("MAGE"), className = Secret("Magier"),
	level = Secret(60), raceName = "Gnom", factionGroup = "Horde", factionName = FACTION_HORDE, isPlayer = true,
	guid = Secret("Player-9"), guild = { Secret("Die Gilde"), Secret("Rang"), Secret(3), nil },
	health = Secret(500), maxHealth = Secret(1000), reaction = Secret(2), target = "player",
}

LoadAddon("qnCore")
local tt = LoadAddon("qnTooltip")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(1)

-- Tooltipdaten mit secret GUID: Einheit ist dann die unter der Maus
local data = UnitTooltipData("mouseover")
data.lines[1].leftText = Secret("Fremder")
data.lines[2].leftText = Secret("Die Gilde")
local ok, err = pcall(ProcessTooltip, GameTooltip, data)
Check(ok, "secret-Werte ohne Fehler: " .. tostring(err))
local lines = GameTooltip:Texts()
Check(GameTooltip.qnUnit == "mouseover", "secret GUID: Einheit unter der Maus")
Check(lines[1]:find("S(Fremder)", 1, true) and lines[1]:find("S(Qt)", 1, true), "Vor- und Nachname über SetFormattedText: " .. lines[1])
Check(not lines[1]:find("|cff%x%x%x%x%x%xS%(Fremder%)"), "Name ohne Klassenfarbe (Klasse secret)")
Check(lines[2]:find("<S(Die Gilde)>", 1, true) and lines[2]:find("(S(Rang))", 1, true), "Gilde secret: " .. lines[2])
Check(lines[3]:find("S(60)", 1, true) and lines[3]:find("S(Magier)", 1, true), "Stufe und Klasse secret: " .. lines[3])
Check(not lines[3]:find("|cff%x+S%(60%)"), "Stufe ohne Farbe")
Check(table.concat(lines, "\n"):find(">>" .. strupper(YOU) .. "<<", 1, true), "Zielzeile trotz secret")
Check(not lines[4] or not lines[4]:find(STAT_AVERAGE_ITEM_LEVEL, 1, true), "Gegenstandsstufe entfällt bei secret GUID")
Check(#QN_INSPECT == 0, "kein Betrachten mit secret GUID")

-- Lebensbalken mit secret Lebenspunkten
local bar = GameTooltip.StatusBar
bar:Show()
ok, err = pcall(bar.SetValue, bar, Secret(0.5))
Check(ok, "Lebensbalken mit secret Wert: " .. tostring(err))
Check(bar.qnText._text == "S(500) / S(1000) (S(500)%)" or bar.qnText._text:find("S(500) / S(1000)", 1, true), "Lebensbalken-Text über SetFormattedText: " .. tostring(bar.qnText._text))

-- Glatte Farbe mit secret Wert: HealthBar_OnValueChanged wird nicht aufgerufen
SETTINGS.QNTOOLTIP_BARCOLOR:SetValue("smooth")
bar._smooth = nil
bar:SetValue(Secret(0.4))
Check(bar._smooth == nil, "glatte Farbe übersprungen (secret)")
bar:SetValue(0.4)
Check(bar._smooth == 0.4, "glatte Farbe mit lesbarem Wert")

-- Zielaktualisierung mit secret GUID des Ziels
QN_UNITS.player.guid = "Player-1"
GameTooltip._scripts.OnUpdate(GameTooltip, 0.3)
Check(true, "Zielaktualisierung ohne Fehler")

print(FAILS and ("FEHLER: " .. FAILS) or "alle Prüfungen bestanden")
