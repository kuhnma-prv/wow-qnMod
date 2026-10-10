-- Scenario 17: qnCore 0.2.1 - opt-in "Hide the gamepad bag bar" (Bags.lua)
--   * off by default: Blizzard's bar stays as it is
--   * on and gamepad interface off: GamepadBagBar hidden; after switching off shown again
--   * with the gamepad interface the bar is never hidden
--   * the option exists on the Bag Automation page

local gamepad = false
InputUtil = { IsGamepadUIEnabled = function() return gamepad end }
GamepadBagBar = CreateFrame("Frame", "GamepadBagBar", UIParent)

local core = LoadAddon("qnCore")
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false) RunTimers()
local Bags = core.Bags

Check(Bags.defaults.hideGamepadBar == false, "default: off")
Check(GamepadBagBar:IsShown(), "off: bar untouched")

Bags.Config().hideGamepadBar = true
Bags.ApplyGamepadBar()
Check(not GamepadBagBar:IsShown(), "on, no gamepad interface: bar hidden")

gamepad = true
Bags.ApplyGamepadBar()
Check(GamepadBagBar:IsShown(), "gamepad interface on: bar shown again")
Bags.ApplyGamepadBar()
Check(GamepadBagBar:IsShown(), "gamepad interface: stays shown")

gamepad = false
Bags.ApplyGamepadBar()
Check(not GamepadBagBar:IsShown(), "hidden again without gamepad interface")
Bags.Config().hideGamepadBar = false
Bags.ApplyGamepadBar()
Check(GamepadBagBar:IsShown(), "option off: shown again")

-- a bar the user (or Blizzard) hid is not shown by us
GamepadBagBar:Hide()
Bags.ApplyGamepadBar()
Check(not GamepadBagBar:IsShown(), "bar we did not hide stays hidden")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
