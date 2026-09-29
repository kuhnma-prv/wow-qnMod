-- Scenario 3: qnTooltip - position only on request (default: Blizzard), cursor/fixed point,
-- own mode per unit type, back to Blizzard's position in combat, hide in combat with
-- modifier key, IDs and quality border, spells, chat links, "Lines" page, profile switch.
EnableTooltips()
QN_UNITS.mouseover = { name = "Thrall", class = "SHAMAN", className = "Schamane", level = 60, isPlayer = true,
	guid = "Player-5", factionGroup = "Horde", factionName = FACTION_HORDE }
QN_GUIDS["Player-5"] = "mouseover"
QN_ITEMS = { [19019] = { name = "Donnerzorn", quality = 5, icon = 135349, stack = 1 }, [2589] = { name = "Leinenstoff", quality = 1, icon = 132889, stack = 20 } }

LoadAddon("qnCore")
local tt = LoadAddon("qnTooltip")
local L = tt.L
FireEvent("PLAYER_LOGIN")
FireEvent("PLAYER_ENTERING_WORLD", true, false)
SetEditModeLayout(1)

local function Anchor()
	GameTooltip_SetDefaultAnchor(GameTooltip, UIParent)
	return GameTooltip._anchor[1], GameTooltip._points and GameTooltip._points[#GameTooltip._points]
end

---------------------------------------------------------------------------
-- Position
---------------------------------------------------------------------------
local anchor, point = Anchor()
Check(anchor == "ANCHOR_NONE" and point[1] == "BOTTOMRIGHT" and point[4] == -13, "default: Blizzard's position unchanged")

SETTINGS.QNTOOLTIP_ANCHORMODE:SetValue("cursor")
anchor = Anchor()
Check(anchor == "ANCHOR_CURSOR", "at the cursor")
QN_COMBAT = true
anchor = Anchor()
Check(anchor == "ANCHOR_NONE", "at Blizzard's position in combat")
QN_COMBAT = false

SETTINGS.QNTOOLTIP_ANCHORMODE:SetValue("static")
SETTINGS.QNTOOLTIP_ANCHORPOINT:SetValue("TOPLEFT")
SETTINGS.QNTOOLTIP_ANCHORX:SetValue(20)
SETTINGS.QNTOOLTIP_ANCHORY:SetValue(-30)
anchor, point = Anchor()
Check(point[1] == "TOPLEFT" and point[3] == "TOPLEFT" and point[4] == 20 and point[5] == -30, "fixed point")

SETTINGS.QNTOOLTIP_PLAYER_ANCHORMODE:SetValue("cursorRight")
anchor = Anchor()
Check(anchor == "ANCHOR_CURSOR_RIGHT" and GameTooltip._anchor[2] == 36, "own mode for players")
SETTINGS.QNTOOLTIP_RETURNONUNITFRAME:SetValue(true)
QN_FOCUS = CreateFrame("Button")
QN_FOCUS.unit = "mouseover"
anchor = Anchor()
Check(anchor == "ANCHOR_NONE", "over unit frames at Blizzard's position")
QN_FOCUS = nil

-- hide in combat, show anyway with Shift
SETTINGS.QNTOOLTIP_RETURNINCOMBAT:SetValue(false)
SETTINGS.QNTOOLTIP_HIDEINCOMBAT:SetValue(true)
SETTINGS.QNTOOLTIP_COMBATMODIFIER:SetValue("shift")
QN_COMBAT = true
GameTooltip:Hide()
Anchor()
GameTooltip:SetUnit("mouseover")
Check(not GameTooltip:IsShown(), "hidden in combat")
IsShiftKeyDown = function() return true end
FireEvent("MODIFIER_STATE_CHANGED", "LSHIFT", 1)
Check(GameTooltip:IsShown() and GameTooltip:Texts()[1]:find("Thrall", 1, true), "Shift shows the tooltip")
IsShiftKeyDown = function() return false end
FireEvent("MODIFIER_STATE_CHANGED", "LSHIFT", 0)
Check(not GameTooltip:IsShown(), "releasing hides again")
-- not at the default position (own owner): stays visible
GameTooltip:SetOwner(UIParent, "ANCHOR_RIGHT")
GameTooltip:SetUnit("mouseover")
Check(GameTooltip:IsShown(), "own anchor stays visible in combat")
QN_COMBAT = false
SETTINGS.QNTOOLTIP_HIDEINCOMBAT:SetValue(false)

---------------------------------------------------------------------------
-- Items and spells
---------------------------------------------------------------------------
local bd = GameTooltip.qnBackdrop
GameTooltip:SetOwner(UIParent, "ANCHOR_RIGHT")
ProcessTooltip(GameTooltip, { type = Enum.TooltipDataType.Item, id = 19019, lines = {
	{ type = Enum.TooltipDataLineType.ItemName, leftText = "Donnerzorn" }, { type = 0, leftText = "Einhand" } } })
local lines = GameTooltip:Texts()
Check(lines[1] == "|T135349:16:16:0:0:32:32:2:30:2:30|t Donnerzorn", "icon before the name: " .. lines[1])
Check(bd._bdBorder[1] == 0.64 and bd._bdBorder[4] == 0.8, "border in quality color")
local text = table.concat(lines, "\n")
Check(text:find(L["Item ID"] .. ": |cffffffff19019|r", 1, true) and text:find(L["Icon ID"] .. ": |cffffffff135349|r", 1, true), "item and icon ID")
Check(not text:find(AUCTION_STACK_SIZE, 1, true), "stack size only for stackable items")
ProcessTooltip(GameTooltip, { type = Enum.TooltipDataType.Item, id = 2589, lines = { { type = Enum.TooltipDataLineType.ItemName, leftText = "Leinenstoff" } } })
Check(table.concat(GameTooltip:Texts(), "\n"):find(AUCTION_STACK_SIZE .. ": |cffffffff20|r", 1, true), "stack size 20")

SETTINGS.QNTOOLTIP_IDSWITHMODIFIER:SetValue(true)
ProcessTooltip(GameTooltip, { type = Enum.TooltipDataType.Item, id = 2589, lines = { { type = Enum.TooltipDataLineType.ItemName, leftText = "Leinenstoff" } } })
Check(not table.concat(GameTooltip:Texts(), "\n"):find(L["Item ID"], 1, true), "IDs only with modifier key")
SETTINGS.QNTOOLTIP_IDSWITHMODIFIER:SetValue(false)

ProcessTooltip(GameTooltip, { type = Enum.TooltipDataType.Spell, id = 133, lines = { { type = Enum.TooltipDataLineType.SpellName, leftText = "Feuerball" } } })
lines = GameTooltip:Texts()
Check(lines[1] == "|T136133:16:16:0:0:32:32:2:30:2:30|t Feuerball", "spell icon")
Check(table.concat(lines, "\n"):find(L["Spell ID"] .. ": |cffffffff133|r", 1, true), "Spell ID")
Check(bd._bdColor[4] == 0.8, "spell: own background")

ProcessTooltip(ItemRefTooltip, { type = Enum.TooltipDataType.Quest, id = 783, lines = { { type = 0, leftText = "Eine Bedrohung" } } })
Check(table.concat(ItemRefTooltip:Texts(), "\n"):find(L["Quest ID"] .. ": |cffffffff783|r", 1, true), "quest ID in ItemRefTooltip")
Check(ItemRefTooltip.qnBackdrop._bdBorder[1] == 0.25, "quest: border in difficulty color")

---------------------------------------------------------------------------
-- Chat links
---------------------------------------------------------------------------
ChatFrame1._scripts.OnHyperlinkEnter(ChatFrame1, "item:19019:0:0:0", "[Donnerzorn]")
Check(GameTooltip._link == "item:19019:0:0:0" and GameTooltip._anchor[1] == "ANCHOR_CURSOR", "chat link: tooltip at the cursor")
ChatFrame1._scripts.OnHyperlinkLeave(ChatFrame1)
Check(not GameTooltip:IsShown(), "chat link left: hidden")
GameTooltip._link = nil
ChatFrame1._scripts.OnHyperlinkEnter(ChatFrame1, "player:Thrall", "[Thrall]")
Check(GameTooltip._link == nil, "player link without tooltip")

---------------------------------------------------------------------------
-- "Lines" page
---------------------------------------------------------------------------
local p = tt.elementsUI.player
p.page:Show()
Check(#p.rows == #tt.ELEMENTS.player, "one row per element")
local ed = p.editor
-- Dialog only via the pencil; icon: filter only
Check(not ed:IsShown() and not p.rows[1].sel:IsShown(), "dialog initially closed")
p.rows[1].edit._scripts.OnClick(p.rows[1].edit)
Check(ed:IsShown() and p.selected == "friendIcon" and p.rows[1].sel:IsShown(), "pencil opens the dialog, row highlighted")
Check(not ed.color:IsShown() and not ed.format:IsShown() and ed.iconNote:IsShown() and ed.filter:IsShown(),
	"icon: filter only, note instead of color and format")
Check(p.rows[1].preview._text and p.rows[1].preview._text:find("|A:", 1, true), "icon: preview shows a sample icon")
-- Arrows: disabled at the start or end of a tooltip line
local r1, r2 = p.rows[1], p.rows[2]
Check(not r1.up:IsEnabled() and r1.down:IsEnabled() and r2.up:IsEnabled(), "arrows: first element not up")
local lastOfLine1
for i, row in ipairs(p.rows) do
	if tt.db.player.elements[row.key] and tt.db.player.elements[row.key].line == 1 then lastOfLine1 = row end
end
Check(lastOfLine1 and not lastOfLine1.down:IsEnabled(), "arrows: last element of the line not down")
r1.down._scripts.OnClick(r1.down)
Check(p.rows[2].key == "friendIcon", "arrow down moves the element")
p.rows[2].up._scripts.OnClick(p.rows[2].up)
Check(p.rows[1].key == "friendIcon", "arrow up moves back")
-- Pencil of another row switches the element in the open dialog
local nameRow
for _, row in ipairs(p.rows) do if row.key == "name" then nameRow = row end end
nameRow.edit._scripts.OnClick(nameRow.edit)
Check(p.selected == "name" and nameRow.sel:IsShown() and not p.rows[1].sel:IsShown(), "pencil switches the element")
Check(ed.TitleContainer.TitleText._text == L["Element: %s"]:format(NAME) and ed.color:IsShown() and not ed.iconNote:IsShown(), "dialog for text")
Check(ed.color._text == L["Class Color"], "color selection shows class color")
-- custom color via the color picker
for i, r in ipairs(ed.color._radios) do
	if r.text == L["Custom color …"] then ed.color:PickRadio(i) end
end
ColorPickerFrame._rgb = { 1, 0, 0 }
ColorPickerFrame._info.swatchFunc()
Check(tt.db.player.elements.name.color == "ff0000", "custom color saved")
Check(ed.color._text == L["Custom color …"] and ed.swatch._color[1] == 1, "display of the custom color")
Check(nameRow.preview._text:find("|cffff0000", 1, true), "row preview in the custom color")
-- Cancel in the color picker: previous value back, also a color function
for i, r in ipairs(ed.color._radios) do
	if r.text == L["Class Color"] then ed.color:PickRadio(i) end
end
for i, r in ipairs(ed.color._radios) do
	if r.text == L["Custom color …"] then ed.color:PickRadio(i) end
end
ColorPickerFrame._rgb = { 0, 1, 0 }
ColorPickerFrame._info.swatchFunc()
Check(tt.db.player.elements.name.color == "00ff00", "color picker: color applied while dragging")
ColorPickerFrame:Cancel()
Check(tt.db.player.elements.name.color == "class" and ed.color._text == L["Class Color"], "cancel: class color back")
for i, r in ipairs(ed.color._radios) do
	if r.text == L["Custom color …"] then ed.color:PickRadio(i) end
end
ColorPickerFrame._rgb = { 1, 0, 0 }
ColorPickerFrame._info.swatchFunc()
-- Format in the edit area: preview while typing, apply with Enter
ed.format:SetText("«%s»")
ed.format._scripts.OnTextChanged(ed.format)
Check(ed.result._text:find("«", 1, true) and tt.db.player.elements.name.format == "%s", "preview while typing, not saved yet")
ed.format._scripts.OnEnterPressed(ed.format)
Check(tt.db.player.elements.name.format == "«%s»", "format applied")
Check(nameRow.preview._text:find("«", 1, true), "row preview with new format")
ed.format:SetText("%s%s")
ed.format._scripts.OnTextChanged(ed.format)
Check(ed.result._text:find("|cffff4040", 1, true), "invalid format marked red")
ed.format._scripts.OnEnterPressed(ed.format)
Check(tt.db.player.elements.name.format == "«%s»" and ed.format:GetText() == "«%s»", "invalid format rejected, input reset")
-- Click an example
Check(ed.examples[2].fmt == "<%s>" and ed.examples[2]._text == "<%s>" and ed.examples[2].result._text:find("<", 1, true),
	"example: button with format, result behind it")
ed.examples[2]._scripts.OnClick(ed.examples[2])
Check(tt.db.player.elements.name.format == "<%s>", "example applied")
-- Number element: own help and examples with %d
local speedRow
for _, row in ipairs(p.rows) do if row.key == "moveSpeed" then speedRow = row end end
speedRow.edit._scripts.OnClick(speedRow.edit)
Check(ed.examples[2].fmt == "%d%%" and ed.examples[2].result._text:find("100%", 1, true), "number: example %d%% with sample value")
Check(ed.help._text:find("%d", 1, true), "number: help mentions %d")
Check(tt.db.player.elements.name.format == "<%s>", "switch to another element: previous one applied with OK")
-- Cancel: pending input discarded, highlight gone
ed.format:SetText("%d km/h")
ed.cancel._scripts.OnClick(ed.cancel)
Check(not ed:IsShown() and tt.db.player.elements.moveSpeed.format == "%d%%" and not speedRow.sel:IsShown(), "cancel: input discarded, dialog closed")
-- OK: pending input applied
speedRow.edit._scripts.OnClick(speedRow.edit)
ed.format:SetText("%d km/h")
ed.ok._scripts.OnClick(ed.ok)
Check(not ed:IsShown() and tt.db.player.elements.moveSpeed.format == "%d km/h", "OK: input applied")
-- Cancel restores everything, including already applied changes (color, format, filter)
nameRow.edit._scripts.OnClick(nameRow.edit)
for i, r in ipairs(ed.color._radios) do
	if r.text == L["Faction Color"] then ed.color:PickRadio(i) end
end
ed.format:SetText("[%s]")
ed.format._scripts.OnEnterPressed(ed.format)
ed.filter:PickRadio(2)
Check(tt.db.player.elements.name.color == "faction" and tt.db.player.elements.name.format == "[%s]"
	and tt.db.player.elements.name.filter ~= "none" and nameRow.preview._text:find("[", 1, true), "changes already affect the preview")
ed.cancel._scripts.OnClick(ed.cancel)
local n = tt.db.player.elements.name
Check(n.color == "ff0000" and n.format == "<%s>" and n.filter == "none" and nameRow.preview._text:find("<", 1, true),
	"cancel: color, format and filter as before opening")
-- Closing another way (X, settings window closed) = cancel
nameRow.edit._scripts.OnClick(nameRow.edit)
ed.format:SetText("[%s]")
ed.format._scripts.OnEnterPressed(ed.format)
ed:Hide()
Check(tt.db.player.elements.name.format == "<%s>", "closing without OK: like cancel")

-- the same page for NPCs
local pn = tt.elementsUI.npc
pn.page:Show()
local npcName
for _, row in ipairs(pn.rows) do if row.key == "name" then npcName = row end end
Check(npcName and npcName.edit and pn.editor ~= ed, "NPC: rows with pencil, own dialog")
npcName.edit._scripts.OnClick(npcName.edit)
Check(pn.editor:IsShown() and pn.editor.ok and pn.editor.cancel, "NPC: dialog with OK and cancel")
pn.editor.format:SetText("«%s»")
pn.editor.ok._scripts.OnClick(pn.editor.ok)
Check(tt.db.npc.elements.name.format == "«%s»" and tt.db.player.elements.name.format == "<%s>", "NPC: OK applies only to NPCs")
npcName.edit._scripts.OnClick(npcName.edit)
pn.editor.format:SetText("%s!")
pn.editor.cancel._scripts.OnClick(pn.editor.cancel)
Check(tt.db.npc.elements.name.format == "«%s»", "NPC: cancel discards")
pn.page:Hide()
-- Line via the dropdown
nameRow.line:PickRadio(3)
Check(tt.db.player.elements.name.line == 3, "line changed")
-- reset
StaticPopupDialogs.QNTOOLTIP_ELEMENTS_RESET.OnAccept(nil, "player")
Check(tt.db.player.elements.name.line == 1 and tt.db.player.elements.name.color == "class", "elements reset")

---------------------------------------------------------------------------
-- Profile switch
---------------------------------------------------------------------------
SETTINGS.QNTOOLTIP_BGFILE:SetValue("marble")
Check(bd._backdrop.bgFile:find("Marble", 1, true), "background marble")
SetEditModeLayout(3)
Check(tt.db.bgFile == "marble", "new layout: copy of the previous profile")
SETTINGS.QNTOOLTIP_BGFILE:SetValue("dark")
SetEditModeLayout(1)
Check(bd._backdrop.bgFile:find("Marble", 1, true), "back: profile 1 applied")

print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
