-- Scenario 6: qnBuffMod – expiration warnings and key "Recast Buffs"
local clicks = {}
local orig = CreateSettingsButtonInitializer
function CreateSettingsButtonInitializer(n, bt, click, ...) clicks[bt] = click return orig(n, bt, click, ...) end
local overrides, cleared = {}, 0
function SetOverrideBindingClick(owner, prio, key, name) overrides[#overrides + 1] = { owner, prio, key, name } end
function ClearOverrideBindings() cleared = cleared + 1 end
local sounds = {}
function PlaySoundFile(id) sounds[#sounds + 1] = id end
local boundKey
function GetBindingKey(action) if action == "QNBUFFMOD_RECASTBUFFS" then return boundKey end end

local core = LoadAddon("qnCore")
local bm = LoadAddon("qnBuffMod")
local E, L = bm.enum, bm.L
local printed = {}
local oldPrint = bm.Print
bm.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end
local function Count(pattern)
	local n = 0
	for _, m in ipairs(printed) do if m:find(pattern, 1, true) then n = n + 1 end end
	return n
end
local function Msg(name, sec)
	return L["The |cFFFFFFFF%s|r buff will expire in |cFFFFFFFF%s|r."]:format(name, bm.FormatTime(sec, 1, true))
end
local function MsgKey(name, sec, key)
	return L["The |cFFFFFFFF%s|r buff will expire in |cFFFFFFFF%s|r. Press |cFFFFFFFF%s|r while out of combat to recast."]:format(name, bm.FormatTime(sec, 1, true), key)
end
local function Has(text)
	for _, m in ipairs(printed) do if m == text then return true end end
	return false
end

-- GetTime() = 1000
local function Buff(name, dur, exp, caster, extra)
	local a = { name = name, icon = 1, applications = 0, duration = dur, expirationTime = exp, sourceUnit = caster or "player", spellId = #name, cancelable = true }
	for k, v in pairs(extra or {}) do a[k] = v end
	return a
end
AURAS.player = {
	Buff("Arkane Intelligenz", 600, 1010),      -- 2:00–10:00, threshold 15 s: warns
	Buff("Segen der Macht", 1200, 1050),        -- 10:01–30:00, threshold 60 s: warns
	Buff("Seelenstärke", 3600, 1170),           -- from 30:01, threshold 180 s: warns
	Buff("Kurz", 100, 1005),                    -- below 2:00: never
	Buff("Krumm", 1800.002, 1100),              -- rounded down counts as 30:00 (threshold 60): not yet
	Buff("Lang", 600, 1020),                    -- still above the threshold
	Buff("Fluch", 600, 1005, "target", { isHarmful = true }),   -- debuff: never
}
boundKey = "F5"
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
RunTimers()

---------------------------------------------------------------------------
-- key binding (criterion 41)
---------------------------------------------------------------------------
local button = _G.QNBUFFMOD_RECASTBUFFFRAME
Check(button and button._template == "SecureActionButtonTemplate" and button:GetAttribute("type") == "spell" and button:GetAttribute("unit") == "player", "secure button QNBUFFMOD_RECASTBUFFFRAME")
Check(#overrides == 1 and overrides[1][1] == button and overrides[1][3] == "F5" and overrides[1][4] == "QNBUFFMOD_RECASTBUFFFRAME", "key bound to the button via override")
FireEvent("UPDATE_BINDINGS")
Check(#overrides == 1, "same binding: nothing repeated")
Check(BINDING_HEADER_QNBUFFMOD == "qnBuffMod" and BINDING_NAME_QNBUFFMOD_RECASTBUFFS == L["Recast Buffs"], "key binding named")
-- without warning: own aura with the shortest time remaining that the player can cast (decision 10)
Check(button:GetAttribute("spell") == "Kurz", "without warning: shortest own aura: " .. tostring(button:GetAttribute("spell")))

---------------------------------------------------------------------------
-- thresholds (criterion 38)
---------------------------------------------------------------------------
RunTickers()
Check(Has(MsgKey("Arkane Intelligenz", 10, "F5")), "warning duration 2:00–10:00 with key")
Check(Has(MsgKey("Segen der Macht", 50, "F5")) and Has(MsgKey("Seelenstärke", 170, "F5")), "warnings 10:01–30:00 and from 30:01")
Check(Count("Kurz") == 0 and Count("Fluch") == 0 and Count("Lang") == 0, "no warning below 2:00, for debuffs, above the threshold")
Check(Count("Krumm") == 0, "duration 1800.002 counts as 30:00")
Check(#sounds == 3 and sounds[1] == 569634, "sound 569634 per warning")
Check(button:GetAttribute("spell") == "Seelenstärke", "button carries the last queued spell")
SETTINGS.QNBUFFMOD_EXPIRATIONTIME1:SetValue(0)
AURAS.player[#AURAS.player + 1] = Buff("Null", 300, 1005)
FireEvent("UNIT_AURA", "player") RunTimers()
RunTickers()
Check(Count("Null") == 0, "threshold 0: no warning")
AURAS.player[#AURAS.player] = nil
FireEvent("UNIT_AURA", "player") RunTimers()
SETTINGS.QNBUFFMOD_EXPIRATIONTIME1:SetValue(15)

---------------------------------------------------------------------------
-- one warning per application (criterion 39)
---------------------------------------------------------------------------
RunTickers()
Check(Count("Arkane Intelligenz") == 1, "second tick: no second warning")
AURAS.player[1].expirationTime = 1011   -- small correction (more than 60 s below full duration)
FireEvent("UNIT_AURA", "player") RunTimers()
RunTickers()
Check(Count("Arkane Intelligenz") == 1, "small expiration correction does not warn again")
AURAS.player[1].expirationTime = 1600   -- real renewal
FireEvent("UNIT_AURA", "player") RunTimers()
Check(button:GetAttribute("spell") == "Seelenstärke", "renewal removes the spell from the list")
SetTime(1590)
RunTickers()
Check(Count("Arkane Intelligenz") == 2, "after a real renewal a warning again")
SetTime(1000)
AURAS.player[1].expirationTime = 1010

---------------------------------------------------------------------------
-- only castable spells, message with key only when newly queued (criterion 40)
---------------------------------------------------------------------------
C_Spell.IsSpellUsable = function(name) if name == "Unwirkbar" then return false, false end return true, false end
SETTINGS.QNBUFFMOD_EXPIRATIONCASTONLY:SetValue(true)
AURAS.player[#AURAS.player + 1] = Buff("Unwirkbar", 600, 1005)
FireEvent("UNIT_AURA", "player") RunTimers()
local nSounds = #sounds
RunTickers()
Check(Count("Unwirkbar") == 0 and #sounds == nSounds, "only castable spells: uncastable skipped, no sound")
SETTINGS.QNBUFFMOD_EXPIRATIONCASTONLY:SetValue(false)
SETTINGS.QNBUFFMOD_EXPIRATIONSOUND:SetValue(false)
-- two auras with the same name in the same tick: the second is not newly queued
AURAS.player[#AURAS.player + 1] = Buff("Doppel", 600, 1005, "player")
AURAS.player[#AURAS.player + 1] = Buff("Doppel", 600, 1006, "party1")
FireEvent("UNIT_AURA", "player") RunTimers()
RunTickers()
Check(Has(MsgKey("Doppel", 5, "F5")) and Has(Msg("Doppel", 6)), "newly queued with key, already queued without")
Check(#sounds == nSounds, "no sound without the sound option")
-- without a bound key: message without key
boundKey = nil
AURAS.player[#AURAS.player + 1] = Buff("Ohne Taste", 600, 1005)
FireEvent("UNIT_AURA", "player") RunTimers()
RunTickers()
Check(Has(Msg("Ohne Taste", 5)), "without binding: message without key")
FireEvent("UPDATE_BINDINGS")
Check(cleared >= 2 and #overrides == 1, "without binding: overrides removed")
boundKey = "F5"
FireEvent("UPDATE_BINDINGS")

---------------------------------------------------------------------------
-- recast key (criterion 41)
---------------------------------------------------------------------------
local list = bm.Recast.list
local top = list[#list]
Check(button:GetAttribute("spell") == top, "button carries the last queued: " .. tostring(top))
button._scripts.PostClick(button, "LeftButton", true)   -- press does not count (ActionButtonUseKeyDown off)
Check(list[#list] == top, "only the triggering key half counts")
local n = #list
button._scripts.PostClick(button, "LeftButton", false)
Check(#list == n - 1 and button:GetAttribute("spell") == list[#list], "cast: removed from the list, next one on the button")
QN_COMBAT = true
local spell = button:GetAttribute("spell")
button._scripts.PostClick(button, "LeftButton", false)
Check(#list == n - 1, "in combat the key does not change the list")
AURAS.player[#AURAS.player + 1] = Buff("Im Kampf", 600, 1005)
FireEvent("UNIT_AURA", "player") RunTimers()
RunTickers()
Check(list[#list] == "Im Kampf" and button:GetAttribute("spell") == spell, "in combat no change of the button's spell")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
Check(button:GetAttribute("spell") == "Im Kampf", "changed after combat")
-- newly appearing aura leaves the list (by name)
local idx
for i, a in ipairs(AURAS.player) do if a.name == "Im Kampf" then idx = i end end
table.remove(AURAS.player, idx)
FireEvent("UNIT_AURA", "player") RunTimers()
AURAS.player[#AURAS.player + 1] = Buff("Im Kampf", 600, 1600)
FireEvent("UNIT_AURA", "player") RunTimers()
Check(list[#list] ~= "Im Kampf", "newly appeared aura no longer in the list")

---------------------------------------------------------------------------
-- warnings for other units and vehicle (decision 5)
---------------------------------------------------------------------------
clicks[ADD]()
SETTINGS.QNBUFFMOD_W_UNITTYPE:SetValue(E.unit.TARGET)
AURAS.target = { Buff("Zielsegen", 600, 1008, "player") }
FireEvent("PLAYER_TARGET_CHANGED") RunTimers()
n = #list
RunTickers()
Check(Has(L["The |cFFFFFFFF%s|r buff on |cFFFFFFFF%s|r will expire in |cFFFFFFFF%s|r."]:format("Zielsegen", "Tester", bm.FormatTime(8, 1, true))), "warning for the target names the unit")
Check(#list == n, "target auras do not go into the recast list")
AURAS.vehicle = { Buff("Fahrzeugschild", 300, 1007, "vehicle") }
FireEvent("UNIT_ENTERED_VEHICLE", "player")
RunTickers()
Check(Count("Fahrzeugschild") == 1, "warning for vehicle auras")
FireEvent("UNIT_EXITED_VEHICLE", "player")

---------------------------------------------------------------------------
-- hints about restricted aura data once per session (criterion 60)
---------------------------------------------------------------------------
QN_AURAS_SECRET = true
FireEvent("UNIT_AURA", "player") RunTimers()
FireEvent("UNIT_AURA", "player") RunTimers()
QN_AURAS_SECRET = false
FireEvent("PLAYER_REGEN_ENABLED") RunTimers()
QN_AURAS_SECRET = true
FireEvent("UNIT_AURA", "player") RunTimers()
QN_AURAS_SECRET = false
FireEvent("ADDON_RESTRICTION_STATE_CHANGED") RunTimers()
Check(Count(L["In combat the client withholds aura data. Until then the windows show the last known state."]) == 1, "hint about the restriction exactly once")
AURAS.player[1].locked = true
FireEvent("UNIT_AURA", "player") RunTimers()
FireEvent("UNIT_AURA", "player") RunTimers()
Check(Count(L["The client is currently withholding aura data (secret). Affected auras are shown without time remaining or with a question mark."]) == 1, "hint about secret fields exactly once")
-- warning switched off
AURAS.player[1].locked = nil
SETTINGS.QNBUFFMOD_ENABLEEXPIRATION:SetValue(false)
AURAS.player[#AURAS.player + 1] = Buff("Still", 600, 1005)
FireEvent("UNIT_AURA", "player") RunTimers()
RunTickers()
Check(Count("Still") == 0, "chat warning off: no message")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
