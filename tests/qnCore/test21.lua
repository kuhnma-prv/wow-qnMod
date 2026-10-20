-- Scenario 21: qnCore.UI canvas building blocks: Checkbox, EditBox, Slider, Stripe, PageHeader and
-- UI.Page with refresh/parent
LoadAddon("qnCore")
local UI = qnCore.UI
local parent = CreateFrame("Frame")

-- Checkbox
local value = true
local cb = UI.Checkbox(parent, "Label", function() return value end, function(on) value = on end, "Tip")
cb:Refresh()
Check(cb:GetChecked() and cb.label._text == "Label", "checkbox shows get() and the label")
cb:SetChecked(false)
cb:GetScript("OnClick")(cb)
Check(value == false, "click takes the state over")

-- EditBox: numeric, Enter, focus loss, Escape
local num = 5
local box = UI.EditBox(parent, 60, function() return num end, function(v) num = v end, { numeric = true })
box:SetText("12")
box:GetScript("OnEnterPressed")(box)
Check(num == 12 and tostring(box:GetText()) == "12", "Enter takes the number over")
box:SetText("")
box:GetScript("OnEditFocusLost")(box)
Check(num == nil, "empty field: nil")
num = 7
box:SetText("99")
box:GetScript("OnEscapePressed")(box)
Check(num == 7 and tostring(box:GetText()) == "7", "Escape restores get()")
local committed
local enter = UI.EditBox(parent, 60, nil, function(t) committed = t end, { enterOnly = true })
Check(enter:GetScript("OnEditFocusLost") == nil, "enterOnly: no commit on focus loss")
enter:SetText("abc")
enter:GetScript("OnEnterPressed")(enter)
Check(committed == "abc", "enterOnly: Enter commits the text")

-- Slider: quiet refresh
local level, changes = 40, 0
local s = UI.Slider(parent, 200, 0, 100, 20, function() return level end, function(v) changes = changes + 1; level = v end)
level = 60
s:Refresh()
Check(changes == 0, "Refresh does not call set")
Check(UI.PercentLabel(49.6) == "50 %", "percent label")

-- Stripe
local r1, r2 = CreateFrame("Frame"), CreateFrame("Frame")
UI.Stripe(r1, 1)
UI.Stripe(r2, 2)
Check(#(r1._regions or {}) == 0 and #(r2._regions or { 1 }) >= 1, "every second row striped")

-- Page with refresh and parent
local filled = 0
local cat = Settings.RegisterVerticalLayoutCategory("Main")
local page = UI.Page("Sub", { refresh = function() filled = filled + 1 end, parent = cat })
page.Refresh()
Check(filled == 0, "Refresh only while visible")
page.panel:Show()
Check(filled == 1, "filled when shown")
page.Refresh()
Check(filled == 2, "Refresh while visible")
Check(page.category ~= nil and type(page.Open) == "function", "registered as subpage with Open")

-- PageHeader
local info, dd = UI.PageHeader(page, "Set:", 200, { { "a", "A" } }, function() return "a" end, function() end)
Check(info and dd and dd.Refresh, "header text and dropdown")
print(FAILS and ("FAILED: " .. FAILS) or "all checks passed")
