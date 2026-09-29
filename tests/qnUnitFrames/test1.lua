-- Scenario 1: qnUnitFrames - click casting on Blizzard's party and raid frames:
-- attributes per binding, frame selection, combat lock, new frames, profiles, cleanup, tooltip,
-- options page "Click Bindings"

-- Profile of the last session with broken entries
qnCoreCharDB = { layout = "preset:1" }
qnUnitFramesDB = { global = {}, profiles = {
	["preset:1"] = { bindings = {
		WARRIOR = { ["shift-1"] = { type = "bogus" }, ["x"] = { type = "spell" }, ["foo-1"] = { type = "focus" }, ["shift-7"] = { type = "focus" },
			["ctrl-3"] = { type = "focus" }, ["alt-2"] = { type = "spell", value = 17 } },
		MAGE = 5,
	} },
} }

-- Frames as Blizzard creates them (CompactUnitFrameTemplate inherits SecureUnitButtonTemplate)
local function UnitButton(name)
	local f = CreateFrame("Button", name, UIParent, "CompactUnitFrameTemplate")
	f._protected = true
	return f
end
local partyCUF = UnitButton("CompactPartyFrameMember1")
local partyPetCUF = UnitButton("CompactPartyFramePet1")
local raid1 = UnitButton("CompactRaidFrame1")
local raid2 = UnitButton("CompactRaidFrame2")
-- Pet in raid (GetUnitFrame(unit, "pet")); reachable once CompactRaidFrame3/4 are created below
local raidPet = UnitButton("CompactRaidFrame5")
raidPet.frameType = "pet"
local group = UnitButton("CompactRaidGroup2Member3")
local plate = UnitButton("NamePlate1UnitFrame")
local party = UnitButton(nil)
party.PetFrame = UnitButton(nil)
QN_PARTY_FRAMES = { party }

-- Intercept tooltip callback
local tooltipFn
TooltipDataProcessor.AddTooltipPostCall = function(kind, fn) if kind == Enum.TooltipDataType.Unit then tooltipFn = fn end end
-- Intercept canvas page
local pages = {}
local origCanvas = Settings.RegisterCanvasLayoutSubcategory
function Settings.RegisterCanvasLayoutSubcategory(p, f, n) pages[n] = f return origCanvas(p, f, n) end

QN_SPELLBOOK = {
	{ items = { { name = "Blitzheilung" }, { name = "Heilen" }, { name = "Heilen" }, { name = "Meditation", isPassive = true } } },
	{ info = { offSpecID = 7 }, items = { { name = "Nebenspezialisierung" } } },
	{ items = { { name = "Erneuerung" }, { name = "Zukunft", itemType = Enum.SpellBookItemType.FutureSpell } } },
}

LoadAddon("qnCore")
local uf = LoadAddon("qnUnitFrames")
local L = uf.L
local printed = {}
local oldPrint = uf.Print
uf.Print = function(fmt, ...) printed[#printed + 1] = tostring(fmt):format(...) oldPrint(fmt, ...) end

local function A(f, name) return f._attr and f._attr[name] end

---------------------------------------------------------------------------
-- Cleanup on load
---------------------------------------------------------------------------
local list = qnUnitFramesDB.profiles["preset:1"].bindings.WARRIOR
Check(list["shift-1"] == nil and list["x"] == nil, "unknown action and wrong key removed")
Check(list["foo-1"] == nil and list["shift-7"] == nil, "unknown modifier and mouse button removed")
Check(list["ctrl-3"] and list["ctrl-3"].type == "focus", "valid binding stays")
Check(list["alt-2"] and list["alt-2"].value == "17", "number as value becomes text (spell ID)")
Check(qnUnitFramesDB.profiles["preset:1"].bindings.MAGE == nil, "broken class table removed")
Check(uf.db.enabled == true and uf.db.raidStyle == true and uf.db.tooltip == true, "defaults added")

SetEditModeLayout(1)
FireEvent("PLAYER_LOGIN")
RunTimers()
Check(uf.db == qnUnitFramesDB.profiles["preset:1"], "profile preset:1 active")

---------------------------------------------------------------------------
-- Attributes
---------------------------------------------------------------------------
Check(A(partyCUF, "ctrl-type3") == "focus" and A(partyCUF, "ctrl-spell3") == nil, "focus: only type attribute")
Check(A(raid2, "alt-type2") == "spell" and A(raid2, "alt-spell2") == "17", "spell ID as spell attribute")
Check(A(plate, "ctrl-type3") == nil, "nameplate untouched")
Check(A(partyCUF, "*type1") == nil, "Blizzard's own attributes not set")

uf.SetBinding("shift-1", "spell", "Blitzheilung")
uf.SetBinding("ctrl-2", "macro", "/cast [@mouseover] Heilen")
uf.SetBinding("3", "target")
uf.SetBinding("alt-ctrl-shift-5", "spell", "")
for _, f in ipairs({ partyCUF, partyPetCUF, raid1, raid2, group, party, party.PetFrame }) do
	Check(A(f, "shift-type1") == "spell" and A(f, "shift-spell1") == "Blitzheilung", "spell on " .. tostring(f:GetName() or "party frame"))
end
Check(A(raid1, "ctrl-type2") == "macro" and A(raid1, "ctrl-macrotext2") == "/cast [@mouseover] Heilen", "macro: type and macrotext")
Check(A(raid1, "type3") == "target", "target without modifier: type3")
Check(A(raid1, "alt-ctrl-shift-type5") == nil, "spell without name binds nothing")
Check(A(plate, "shift-type1") == nil, "nameplate still untouched")

uf.SetBinding("ctrl-2", nil)
Check(A(raid1, "ctrl-type2") == nil and A(raid1, "ctrl-macrotext2") == nil, "deleted binding: attributes removed")
uf.SetBinding("shift-1", "focus")
Check(A(raid1, "shift-type1") == "focus" and A(raid1, "shift-spell1") == nil, "spell -> focus: spell attribute removed")
uf.SetBinding("shift-1", "spell", "Blitzheilung")

---------------------------------------------------------------------------
-- Combat
---------------------------------------------------------------------------
QN_COMBAT = true
printed = {}
uf.SetBinding("shift-2", "spell", "Erneuerung")
Check(A(raid1, "shift-type2") == nil, "nothing changed in combat (otherwise ADDON_ACTION_BLOCKED)")
Check(printed[1] == L["The change will be applied after combat."], "notice in combat")
-- new frame in combat
local raid3 = UnitButton("CompactRaidFrame3")
CompactUnitFrame_SetUpFrame(raid3, nop)
RunTimers()
Check(A(raid3, "shift-type1") == nil, "new frame in combat not bound yet")
QN_COMBAT = false
FireEvent("PLAYER_REGEN_ENABLED")
Check(A(raid1, "shift-type2") == "spell" and A(raid1, "shift-spell2") == "Erneuerung", "applied after combat")
Check(A(raid3, "shift-spell1") == "Blitzheilung", "new frame bound after combat")
-- new frame out of combat
local raid4 = UnitButton("CompactRaidFrame4")
CompactUnitFrame_SetUpFrame(raid4, nop)
RunTimers()
Check(A(raid4, "shift-spell1") == "Blitzheilung", "new frame bound immediately")
Check(A(raidPet, "shift-spell1") == "Blitzheilung", "pet in raid bound")
-- unchanged attributes are not rewritten
local writes = 0
local origSet = raid1.SetAttribute
raid1.SetAttribute = function(self, ...) writes = writes + 1 return origSet(self, ...) end
uf.Apply()
Check(writes == 0, "re-applying without change writes nothing")
uf.SetBinding("shift-1", "spell", "Heilen")
Check(writes == 1 and A(raid1, "shift-spell1") == "Heilen", "only the changed attribute written")
uf.SetBinding("shift-1", "spell", "Blitzheilung")
raid1.SetAttribute = nil
-- classic party frames from the pool
local party2 = UnitButton(nil)
QN_PARTY_FRAMES = { party, party2 }
PartyFrame:InitializePartyMemberFrames()
RunTimers()
Check(A(party2, "shift-spell1") == "Blitzheilung", "new classic party frame bound")

---------------------------------------------------------------------------
-- Frame selection and on/off
---------------------------------------------------------------------------
SETTINGS.QNUF_PETS:SetValue(false)
Check(A(partyPetCUF, "shift-type1") == nil and A(party.PetFrame, "shift-type1") == nil, "pets off: pet frames free")
Check(A(raidPet, "shift-type1") == nil and A(raid4, "shift-type1") == "spell", "pets off: free in raid too, members bound")
Check(A(partyCUF, "shift-type1") == "spell", "party members still bound")
SETTINGS.QNUF_RAIDSTYLE:SetValue(false)
Check(A(raid1, "shift-type1") == nil and A(group, "shift-type1") == nil and A(partyCUF, "shift-type1") == nil, "raid style off: compact frames free")
Check(A(party, "shift-type1") == "spell", "classic party frames still bound")
SETTINGS.QNUF_RAIDSTYLE:SetValue(true)
SETTINGS.QNUF_PETS:SetValue(true)
SlashCmdList.QNUNITFRAMES("off")
Check(uf.db.enabled == false and A(party, "shift-type1") == nil and A(raid1, "ctrl-type3") == nil, "/qnuf off: everything free")
SlashCmdList.QNUNITFRAMES("on")
Check(A(raid1, "shift-type1") == "spell" and A(partyPetCUF, "shift-type1") == "spell", "/qnuf on: bound again")

---------------------------------------------------------------------------
-- Tooltip
---------------------------------------------------------------------------
Check(type(tooltipFn) == "function", "tooltip callback for units registered")
GameTooltip:SetOwner(raid1, "ANCHOR_NONE")
tooltipFn(GameTooltip)
local texts = {}
for _, line in ipairs(TOOLTIP.lines) do texts[#texts + 1] = (line.text or "") .. "=" .. tostring(line.right) end
local joined = table.concat(texts, "|")
Check(joined:find(uf.BindingText("shift-1") .. "=Blitzheilung", 1, true) ~= nil, "tooltip shows spell for the binding")
Check(joined:find(KEY_BUTTON3 .. "=" .. TARGET, 1, true) ~= nil, "tooltip shows action without modifier")
Check(joined:find(uf.BindingText("alt-ctrl-shift-5"), 1, true) == nil, "empty spell not in tooltip")
local first, second
for i, line in ipairs(TOOLTIP.lines) do
	if line.text == uf.BindingText("shift-1") then first = i end
	if line.text == uf.BindingText("shift-2") then second = i end
end
Check(first and second and first < second, "tooltip sorted by mouse button")
GameTooltip:SetOwner(plate, "ANCHOR_NONE")
tooltipFn(GameTooltip)
Check(#TOOLTIP.lines == 0, "foreign frame: no addition")
SETTINGS.QNUF_TOOLTIP:SetValue(false)
GameTooltip:SetOwner(raid1, "ANCHOR_NONE")
tooltipFn(GameTooltip)
Check(#TOOLTIP.lines == 0, "tooltip option off: no addition")
SETTINGS.QNUF_TOOLTIP:SetValue(true)

---------------------------------------------------------------------------
-- Texts
---------------------------------------------------------------------------
Check(uf.ModifierText("") == L["No modifier"], "without modifier")
Check(uf.ModifierText("alt-ctrl-shift-") == ALT_KEY_TEXT .. "+" .. CTRL_KEY_TEXT .. "+" .. SHIFT_KEY_TEXT, "modifiers with Blizzard names")
Check(uf.BindingText("shift-4") == SHIFT_KEY_TEXT .. "+" .. KEY_BUTTON4, "binding text")

---------------------------------------------------------------------------
-- Profiles: bindings per profile, new layout = copy
---------------------------------------------------------------------------
SetEditModeLayout(3)
Check(uf.db == qnUnitFramesDB.profiles["account:Raid"], "profile account:Raid active")
Check(uf.Bindings()["shift-1"] and uf.Bindings()["shift-1"].value == "Blitzheilung", "new profile takes over the bindings")
uf.SetBinding("shift-1", "spell", "Heilen")
Check(A(raid1, "shift-spell1") == "Heilen", "change in the new profile takes effect")
Check(qnUnitFramesDB.profiles["preset:1"].bindings.WARRIOR["shift-1"].value == "Blitzheilung", "old profile unchanged")
SetEditModeLayout(1)
Check(A(raid1, "shift-spell1") == "Blitzheilung", "back: bindings of the old profile")

---------------------------------------------------------------------------
-- Options page "Click Bindings"
---------------------------------------------------------------------------
local page = pages[L["Click Bindings"]]
Check(page ~= nil, "Click Bindings page registered")
local rows = uf.clicksUI.rows
Check(#rows == #uf.MODIFIERS, "one row per modifier")
page:Show()
local shiftRow = rows[2]
Check(shiftRow.kind._text == L["Spell"] and shiftRow.spell:IsShown() and shiftRow.spell._text == "Blitzheilung", "Shift row shows spell and name")
Check(rows[1].kind._text == L["Blizzard default"] and not rows[1].spell:IsShown() and not rows[1].macro:IsShown(), "row without binding: Blizzard default")
Check(shiftRow.spell._scrollHeight == 400, "long spell list with scrolling")

-- Spell list from the spellbook
local names = {}
for _, r in ipairs(shiftRow.spell._radios) do names[#names + 1] = r.text end
Check(table.concat(names, ",") == "Blitzheilung,Erneuerung,Heilen," .. L["Other spell …"], "spellbook: sorted, without duplicates, passives, off-spec and future spells")
shiftRow.spell:PickRadio(3)
Check(uf.Bindings()["shift-1"].value == "Heilen" and A(raid1, "shift-spell1") == "Heilen", "spell picked from the list")

-- Other spell: input dialog
LAST_POPUP = nil
shiftRow.spell:PickRadio(#shiftRow.spell._radios)
Check(LAST_POPUP and LAST_POPUP.which == "QNUNITFRAMES_SPELL" and LAST_POPUP.a1 == uf.BindingText("shift-1"), "other spell opens input")
local function Dialog(text) return { GetEditBox = function() return { GetText = function() return text end } end } end
StaticPopupDialogs.QNUNITFRAMES_SPELL.OnAccept(Dialog("  Große Heilung  "))
Check(uf.Bindings()["shift-1"].value == "Große Heilung" and A(raid1, "shift-spell1") == "Große Heilung", "manually entered spell")
Check(shiftRow.spell._text == "Große Heilung", "custom spell shown as selection")

-- Macro in the Ctrl row
local ctrlRow = rows[3]
local macroIndex
for i, t in ipairs(uf.TYPES) do if t[1] == "macro" then macroIndex = i end end
local editor = uf.clicksUI.macro
Check(editor and not editor:IsShown(), "macro editor initially hidden")
ctrlRow.kind:PickRadio(macroIndex)
Check(uf.Bindings()["ctrl-1"] and uf.Bindings()["ctrl-1"].type == "macro", "action macro set")
Check(editor:IsShown() and editor.box:GetText() == "", "macro opens the editor")
Check(A(raid1, "ctrl-type1") == nil, "empty macro binds nothing")
-- multi-line, with blank lines and Windows line endings
editor.box:SetText("  /stopcasting\r\n\n/cast [@mouseover] Heilen\n  ")
editor.accept:GetScript("OnClick")(editor.accept)
local MACRO_TEXT = "/stopcasting\n/cast [@mouseover] Heilen"
Check(A(raid1, "ctrl-type1") == "macro" and A(raid1, "ctrl-macrotext1") == MACRO_TEXT, "multi-line macro text applied")
Check(not editor:IsShown(), "accept closes the editor")
Check(ctrlRow.macro:IsShown() and ctrlRow.macroText._text == "/stopcasting · /cast [@mouseover] Heilen" and not ctrlRow.spell:IsShown(), "row shows macro")
-- Edit and cancel
ctrlRow.macro:GetScript("OnClick")(ctrlRow.macro)
Check(editor:IsShown() and editor.box:GetText() == MACRO_TEXT, "edit shows the previous text")
editor.box:SetText("/cast Falsch")
editor.cancel:GetScript("OnClick")(editor.cancel)
Check(not editor:IsShown() and uf.Bindings()["ctrl-1"].value == MACRO_TEXT, "cancel applies nothing")
-- Tooltip: start of the macro text
GameTooltip:SetOwner(raid1, "ANCHOR_NONE")
tooltipFn(GameTooltip)
local macroLine
for _, line in ipairs(TOOLTIP.lines) do if line.text == uf.BindingText("ctrl-1") then macroLine = line.right end end
Check(macroLine == L["Macro: %s"]:format("/stopcasting…"), "tooltip shows start of the macro")
Check(uf.ActionText({ type = "macro", value = ("ä"):rep(40) }) == L["Macro: %s"]:format(("ä"):rep(32) .. "…"), "long macro shortened (UTF-8)")
Check(uf.ActionText({ type = "macro", value = "/cast X" }) == L["Macro: %s"]:format("/cast X"), "short macro complete")
-- Editor closes when the binding changes
ctrlRow.macro:GetScript("OnClick")(ctrlRow.macro)

-- Action back to Blizzard default
ctrlRow.kind:PickRadio(1)
Check(uf.Bindings()["ctrl-1"] == nil and A(raid1, "ctrl-type1") == nil and not ctrlRow.macro:IsShown(), "Blizzard default deletes the binding")
Check(not editor:IsShown(), "editor closed when the binding is no longer a macro")

-- Switch mouse button: the rows show the bindings of this button
local buttonDD = uf.clicksUI.button
Check(buttonDD._text == KEY_BUTTON1, "mouse button: left button selected")
buttonDD:PickRadio(2)
Check(buttonDD._text == KEY_BUTTON2 and shiftRow.spell._text == "Erneuerung", "right button: Shift row shows shift-2")
Check(rows[4].kind._text == L["Spell"] and rows[4].spell._text == "17", "Alt row shows spell ID from the old profile")
shiftRow.kind:PickRadio(1)
Check(uf.Bindings()["shift-2"] == nil and uf.Bindings()["shift-1"] ~= nil, "deletion affects only the selected mouse button")

-- Delete all
Check(uf.Bindings()["3"] ~= nil, "bound before deletion")
StaticPopupDialogs.QNUNITFRAMES_CLEAR.OnAccept(nil, nil)
Check(next(uf.Bindings()) == nil and A(raid1, "type3") == nil and A(raid1, "shift-type1") == nil, "delete all: bindings and attributes gone")
Check(qnUnitFramesDB.profiles["account:Raid"].bindings.WARRIOR["shift-1"].value == "Heilen", "other profile untouched")

-- Open options
SlashCmdList.QNUNITFRAMES("clicks")
SlashCmdList.QNUNITFRAMES("")
printed = {}
SlashCmdList.QNUNITFRAMES("help")
Check(#printed == 1 and printed[1]:find("/qnuf clicks", 1, true) ~= nil, "help for the commands")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
