-- Scenario 20: qnCore.Media - own lists plus LibSharedMedia: Entries without duplicates, File with
-- fallback to LSM, UnpackColor
LoadAddon("qnCore")
local Media = qnCore.Media

local own = { { "Blizzard", "Blizzard", "own\\blizzard" }, { "Flat", "Flat", "own\\flat" } }
-- without LibSharedMedia
local list = Media.Entries(own, "statusbar")
Check(#list == 2 and list[1][1] == "Blizzard", "without LSM: only own entries")
Check(Media.File(own, "statusbar", "Flat") == "own\\flat" and Media.File(own, "statusbar", "Smooth") == nil, "File without LSM")

-- with a LibSharedMedia that also has a "Flat"
local lsm = { media = { statusbar = { Flat = "lsm\\flat", Smooth = "lsm\\smooth" } } }
function lsm:List(kind) return { "Flat", "Smooth" } end
function lsm:IsValid(kind, name) return self.media[kind] and self.media[kind][name] ~= nil end
function lsm:Fetch(kind, name) return self.media[kind][name] end
function lsm:Register() end
LibStub = function(name, silent) return name == "LibSharedMedia-3.0" and lsm or nil end
list = Media.Entries(own, "statusbar")
Check(#list == 3 and list[3][1] == "Smooth" and list[3][2] == "Smooth", "LSM entries after the own ones, own keys not twice")
Check(Media.File(own, "statusbar", "Flat") == "own\\flat", "own file wins")
Check(Media.File(own, "statusbar", "Smooth") == "lsm\\smooth", "LSM file")
Check(Media.LSMFetch("statusbar", "Missing") == nil, "unknown LSM name: nil")
Check(#Media.STATUSBARS == 3 and Media.STATUSBARS[1][3] == Media.STATUSBAR, "shared status bar list")

-- UnpackColor
local r, g, b, a = qnCore.UnpackColor({ 0.5 })
Check(r == 0.5 and g == 0 and b == 0 and a == 1, "UnpackColor default 0, alpha 1")
r, g, b, a = qnCore.UnpackColor({}, 1)
Check(r == 1 and g == 1 and b == 1 and a == 1, "UnpackColor with default 1")
LibStub = nil
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
