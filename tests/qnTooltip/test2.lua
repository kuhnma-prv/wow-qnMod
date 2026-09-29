-- Scenario 2: qnTooltip - secret values (restrictions in instances): name, guild, level, class,
-- GUID and health secret. No errors from comparing/arithmetic/concatenation, values appear
-- via SetFormattedText, colors and filters are dropped, target and health bar keep working.

-- Secret values: tables that throw an error on arithmetic, comparison and concatenation; tostring
-- (also in string.format "%s", like SetFormattedText) shows S(value).
-- issecretvalue must be set before qnCore (qnCore remembers it on load).
local function Forbidden() error("arithmetic/comparison with a secret value", 2) end
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

-- Tooltip data with secret GUID: the unit is then the one under the mouse
local data = UnitTooltipData("mouseover")
data.lines[1].leftText = Secret("Fremder")
data.lines[2].leftText = Secret("Die Gilde")
local ok, err = pcall(ProcessTooltip, GameTooltip, data)
Check(ok, "secret values without error: " .. tostring(err))
local lines = GameTooltip:Texts()
Check(GameTooltip.qnUnit == "mouseover", "secret GUID: unit under the mouse")
Check(lines[1]:find("S(Fremder)", 1, true) and lines[1]:find("S(Qt)", 1, true), "first and last name via SetFormattedText: " .. lines[1])
Check(not lines[1]:find("|cff%x%x%x%x%x%xS%(Fremder%)"), "name without class color (class secret)")
Check(lines[2]:find("<S(Die Gilde)>", 1, true) and lines[2]:find("(S(Rang))", 1, true), "guild secret: " .. lines[2])
Check(lines[3]:find("S(60)", 1, true) and lines[3]:find("S(Magier)", 1, true), "level and class secret: " .. lines[3])
Check(not lines[3]:find("|cff%x+S%(60%)"), "level without color")
Check(table.concat(lines, "\n"):find(">>" .. strupper(YOU) .. "<<", 1, true), "target line despite secret")
Check(not lines[4] or not lines[4]:find(STAT_AVERAGE_ITEM_LEVEL, 1, true), "item level dropped with secret GUID")
Check(#QN_INSPECT == 0, "no inspect with secret GUID")

-- Health bar with secret health
local bar = GameTooltip.StatusBar
bar:Show()
ok, err = pcall(bar.SetValue, bar, Secret(0.5))
Check(ok, "health bar with secret value: " .. tostring(err))
Check(bar.qnText._text == "S(500) / S(1000) (S(500)%)" or bar.qnText._text:find("S(500) / S(1000)", 1, true), "health bar text via SetFormattedText: " .. tostring(bar.qnText._text))

-- Smooth color with secret value: HealthBar_OnValueChanged is not called
SETTINGS.QNTOOLTIP_BARCOLOR:SetValue("smooth")
bar._smooth = nil
bar:SetValue(Secret(0.4))
Check(bar._smooth == nil, "smooth color skipped (secret)")
bar:SetValue(0.4)
Check(bar._smooth == 0.4, "smooth color with readable value")

-- Target update with the target's secret GUID
QN_UNITS.player.guid = "Player-1"
GameTooltip._scripts.OnUpdate(GameTooltip, 0.3)
Check(true, "target update without error")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
