-- Scenario 2: secret values in aura data. Secret values are tables where every
-- arithmetic, comparison and concatenation throws an error (as in the client).
local SecretMT = {}
local function boom() error("operation on secret value", 2) end
for _, m in ipairs({ "__add", "__sub", "__mul", "__div", "__unm", "__lt", "__le", "__concat", "__len", "__index", "__call" }) do SecretMT[m] = boom end
local function Secret() return setmetatable({}, SecretMT) end
issecretvalue = function(v) return type(v) == "table" and getmetatable(v) == SecretMT end

local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
local printed = {}
local oldPrint = bm.Print
bm.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end
local function Count(key)
	local n = 0
	for _, m in ipairs(printed) do if m == bm.L[key] then n = n + 1 end end
	return n
end

AURAS.player = {
	{ name = "Offen", icon = 1, applications = 0, duration = 600, expirationTime = 1500, sourceUnit = "player", spellId = 111, auraInstanceID = 1 },
	{ name = Secret(), icon = Secret(), applications = Secret(), duration = Secret(), expirationTime = Secret(), sourceUnit = Secret(), spellId = Secret(), auraInstanceID = 2 },
}
ENCHANTS[16] = { remainingTimeMs = Secret(), chargesRemaining = Secret(), enchantID = 5 }
QN_TOOLTIP[16] = { Secret() }
UnitName = function() return Secret() end
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()
Check(true, "login with secret auras without errors")
local function Names()
	local out = {}
	for _, e in ipairs(bm.GetEntries(1)) do out[#out + 1] = e.weapon and ("W" .. e.slot) or e.name end
	return table.concat(out, ",")
end
Check(Names():find("Offen", 1, true) and Names():find("?", 1, true), "readable aura and placeholder: " .. Names())
local entries = bm.GetEntries(1)
local ph
for _, e in ipairs(entries) do if e.name == "?" then ph = e end end
Check(ph and ph.rec.icon == bm.QUESTION_MARK and ph.time == nil and ph.countText == "", "placeholder: question mark, no time remaining, no stacks")
-- weapon with secret time remaining: enchanted, time remaining 0, name unknown
local weapon
for _, e in ipairs(entries) do if e.weapon then weapon = e end end
Check(weapon and weapon.name == UNKNOWN and weapon.time == nil, "weapon with secret values: time remaining 0, name unknown")
FireEvent("UNIT_AURA", "player") RunTimers()
Check(true, "UNIT_AURA with secret auras without errors")
-- tooltip and warning check with secret names
entries = bm.GetEntries(1)
for _, e in ipairs(entries) do
	e.entry._scripts.OnEnter(e.entry)
	e.entry._scripts.OnLeave(e.entry)
end
RunTickers()
Check(true, "tooltips and warning check with secret values without errors")
-- whole return value secret: aura counts as absent
local old = C_UnitAuras.GetAuraDataByIndex
C_UnitAuras.GetAuraDataByIndex = function() return Secret() end
FireEvent("UNIT_AURA", "player") RunTimers()
Check(#bm.GetEntries(1) == 1 and bm.GetEntries(1)[1].weapon, "completely secret: no auras, no errors")
C_UnitAuras.GetAuraDataByIndex = old
-- weapon enchant info completely secret: unenchanted
C_PaperDollInfo.GetTemporaryEnchantmentInfo = function() return Secret() end
FireEvent("WEAPON_ENCHANT_CHANGED")
Check(#bm.GetEntries(1) == 0, "weapon info secret: unenchanted")
AURAS.player[2] = nil
FireEvent("UNIT_AURA", "player") RunTimers()
Check(Names() == "Offen", "back to readable values: " .. Names())
Check(Count("The client is currently withholding aura data (secret). Affected auras are shown without time remaining or with a question mark.") == 1, "hint about secret fields exactly once")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
