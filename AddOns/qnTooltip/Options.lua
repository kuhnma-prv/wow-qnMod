-- qnTooltip: Optionen im Blizzard-Einstellungsfenster (Settings-API).
-- Hauptseite: allgemeine Schalter; Unterseiten: Darstellung, Position, Lebensbalken, Spieler, NSC,
-- Gegenstände & Zauber sowie die Zeilen-Bausteine (ElementsPage.lua).
-- Die Einstellungen gehören zum aktiven Profil (qnCore); die Werte von Spielern und NSC liegen in
-- ns.db.player bzw. ns.db.npc.

local _, ns = ...
local L = ns.L
local S = qnCore.Settings

local function Apply()
	ns.Apply()
end

local function Builders()
	local B = S.New({ store = ns.store, prefix = "QNTOOLTIP_", apply = Apply })
	local function Unit(kind)
		return S.New({
			store = ns.store,
			prefix = "QNTOOLTIP_" .. kind:upper() .. "_",
			source = function() return ns.db[kind] end,
			defaults = ns.defaults[kind],
		})
	end
	return B, Unit("player"), Unit("npc")
end

local function FontOptions(B, cat, prefix, title)
	B:Dropdown(cat, prefix .. "Font", L["Font: %s"]:format(title), ns.Style.FontEntries)
	B:Slider(cat, prefix .. "Size", L["Font size: %s"]:format(title), 0, 24, 1, S.FontSizeFormatter,
		L["0 = Blizzard's size."])
	B:Dropdown(cat, prefix .. "Flag", L["Outline: %s"]:format(title), ns.Style.FlagEntries)
end

local function MainPage(B, cat, layout)
	S.Header(layout, GENERAL)
	B:Checkbox(cat, "moreTooltips", L["Also style link, comparison and friend tooltips"],
		L["When turned off, these tooltips keep their look until the next /reload."])
	B:Checkbox(cat, "hideUnitFrameHint", L["Remove the right-click hint on unit frames"])
	B:Checkbox(cat, "chatHover", L["Tooltip when hovering chat links"])
	B:Checkbox(cat, "modifierShowsAll", L["Show all elements while holding Alt or Ctrl"],
		L["While Alt or Ctrl is held, unit tooltips also show disabled and filtered elements."])
end

local function AppearancePage(B, category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, APPEARANCE_LABEL)
	-- eigene Kopfzeile statt APPEARANCE_LABEL: das hieße wie die Seite (wie in qnNumKeyPad)
	S.Header(layout, DISPLAY)
	B:Slider(cat, "scale", L["Scale"], 0.5, 2, 0.05, S.DecimalFormatter)
	B:Dropdown(cat, "bgFile", BACKGROUND, ns.Style.BackgroundEntries)
	B:Color(cat, "bgColor", L["Background color"], nil, nil, L["Background opacity"])
	B:Dropdown(cat, "borderStyle", L["Border"], {
		{ "default", DEFAULT },
		{ "angular", L["Angular"] },
		{ "none", NONE },
	})
	B:Slider(cat, "borderSize", L["Border width (angular)"], 1, 8, 1)
	B:Color(cat, "borderColor", L["Border color"], nil, nil, L["Border opacity"])
	B:Checkbox(cat, "mask", L["Light gradient over the header"])

	S.Header(layout, L["Fonts"])
	FontOptions(B, cat, "header", L["Header"])
	FontOptions(B, cat, "body", L["Text lines"])
end

local function PositionPage(B, BP, BN, category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Position"])
	S.Header(layout, L["Position"])
	B:Dropdown(cat, "anchorMode", L["Position"], ns.Anchor.ModeEntries(false),
		L["qnTooltip moves the tooltip only if something other than 'Blizzard default' is selected here."])
	B:Dropdown(cat, "anchorPoint", L["Fixed point: anchor"], qnCore.PointEntries())
	B:Slider(cat, "anchorX", L["Fixed point: X offset"], -1000, 1000, 1)
	B:Slider(cat, "anchorY", L["Fixed point: Y offset"], -1000, 1000, 1)
	BP:Dropdown(cat, "anchorMode", L["Position for players"], ns.Anchor.ModeEntries(true))
	BN:Dropdown(cat, "anchorMode", L["Position for NPCs"], ns.Anchor.ModeEntries(true))
	B:Checkbox(cat, "returnInCombat", L["At Blizzard's position in combat"])
	B:Checkbox(cat, "returnOnUnitFrame", L["At Blizzard's position over unit frames"])

	S.Header(layout, COMBAT)
	B:Checkbox(cat, "hideInCombat", L["Hide tooltip in combat"],
		L["Applies to tooltips at Blizzard's default position (units in the world, unit frames, action bars)."])
	B:Dropdown(cat, "combatModifier", L["Show anyway with this key"], ns.Anchor.ModifierEntries)
end

local function BarPage(B, category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Health Bar"])
	S.Header(layout, L["Health Bar"])
	B:Checkbox(cat, "barHide", L["Hide health bar"])
	B:Slider(cat, "barHeight", L["Height"], 1, 20, 1)
	B:Dropdown(cat, "barPosition", L["Placement"], {
		{ "bottom", L["On the bottom edge"] },
		{ "top", L["On the top edge"] },
		{ "default", L["Below the tooltip (Blizzard)"] },
	})
	B:Slider(cat, "barOffsetX", L["Side inset"], 0, 30, 1, S.FontSizeFormatter,
		L["0 = matching the border."])
	B:Dropdown(cat, "barTexture", L["Texture"], ns.StatusBar.TextureEntries)
	B:Dropdown(cat, "barColor", COLOR, {
		{ "default", L["Blizzard (green)"] },
		{ "auto", L["Class or selection color"] },
		{ "smooth", L["By health (green – yellow – red)"] },
	})
	S.Header(layout, L["Text"])
	B:Checkbox(cat, "barText", L["Show health points"])
	B:Checkbox(cat, "barPercent", L["Show percent"])
	FontOptions(B, cat, "bar", L["Health Bar"])
end

local function UnitPage(BU, category, kind, title)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, title)
	S.Header(layout, title)
	BU:Dropdown(cat, "borderColor", L["Border color"], ns.UnitData.ColorEntries)
	BU:Dropdown(cat, "bgColor", L["Background color"], ns.UnitData.ColorEntries,
		L["'Default' uses the general background color."])
	BU:Slider(cat, "bgAlpha", L["Background opacity"], 0, 1, 0.05, S.FractionFormatter)
	BU:Checkbox(cat, "showTarget", L["Show target"])
	BU:Checkbox(cat, "showTargetBy", L["Show 'Targeted by'"],
		L["Group and raid members targeting the unit."])
	BU:Checkbox(cat, "showModel", L["Show 3D model"], L["The model rotates while Ctrl or Alt is held."])
	BU:Checkbox(cat, "grayDead", L["Show dead units in gray"])
	BU:Checkbox(cat, "bigFaction", L["Large faction emblem"])
	S.Button(layout, L["Lines"], L["Edit lines …"], function()
		ns.OpenElementsPage(kind)
	end, L["Elements of the header lines: on/off, line, order, color, format and filter."])
	ns.InitElementsPage(category, kind, L["Lines: %s"]:format(title))
end

local function ItemsPage(B, category)
	local cat, layout = Settings.RegisterVerticalLayoutSubcategory(category, L["Items & Spells"])
	S.Header(layout, ITEMS)
	B:Checkbox(cat, "itemBorder", L["Border in the quality color"])
	B:Checkbox(cat, "itemIcon", L["Icon before the name"])
	B:Checkbox(cat, "itemId", L["Item ID"])
	B:Checkbox(cat, "itemIconId", L["Icon ID"])
	B:Checkbox(cat, "itemMaxStack", AUCTION_STACK_SIZE)
	S.Header(layout, SPELLS)
	B:Checkbox(cat, "spellIcon", L["Icon before the name"])
	B:Checkbox(cat, "spellId", L["Spell ID"])
	B:Checkbox(cat, "spellIconId", L["Icon ID"])
	B:Color(cat, "spellBgColor", L["Background color"], nil, nil, L["Background opacity"])
	B:Color(cat, "spellBorderColor", L["Border color"], nil, nil, L["Border opacity"])
	S.Header(layout, L["Quests"])
	B:Checkbox(cat, "questBorder", L["Border in the difficulty color"])
	B:Checkbox(cat, "questId", L["Quest ID"])
	S.Header(layout, L["IDs"])
	B:Checkbox(cat, "idsWithModifier", L["IDs only while Shift, Ctrl or Alt is held"])
end

local function Build(category, layout)
	local B, BP, BN = Builders()
	MainPage(B, category, layout)
	AppearancePage(B, category)
	PositionPage(B, BP, BN, category)
	BarPage(B, category)
	UnitPage(BP, category, "player", PLAYER)
	UnitPage(BN, category, "npc", L["NPC"])
	ItemsPage(B, category)
end

-- setzt ns.category und ns.OpenOptions
function ns.InitOptions()
	S.NewCategory(ns, "qnTooltip", Build)
end
