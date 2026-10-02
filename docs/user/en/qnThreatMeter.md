# qnThreatMeter – threat meter for your group

qnThreatMeter shows the threat of you and your group against your current target in a window that
looks like the built-in Damage Meter. It shows threat values, percent, threat per second and a
"Pull Aggro" bar, and warns you before you pull aggro. When the client hides the threat values
(secret values, typically in combat), the window keeps working in a restricted mode.

## Features

- Bars for every group or raid member (optionally pets) on the threat list of your target, sorted by
  threat, with rank, class icon and class color.
- Text per bar like the Damage Meter: value, threat per second (TPS) and percent.
- Percent relative to the tank (100 % = tank) or scaled (100 % = aggro).
- **Pull Aggro** bar: the threat at which you take aggro (110 % melee, 130 % ranged).
- Your own bar is always shown, even if it does not fit into the window.
- Warning on high threat: sound, red screen flash and a message in the middle of the screen.
- Look taken from the Edit Mode settings of the built-in Damage Meter, or set up yourself.
- Visibility: always, only in combat or only in a group/raid.
- Test mode with sample data to set up the window.
- **Restricted mode** with secret values: bars and texts are still filled, but without sorting,
  ranks, TPS, Pull Aggro bar and warnings.

## Getting started

Open *Options → AddOns → qnThreatMeter* (Esc → Options → AddOns tab), or type `/qnm config`.
`/qnm` shows or hides the window, `/qnm test` fills it with sample data.

The window:

- **Move** it by dragging it with the left mouse button.
- **Resize** it with the handle in the bottom-right corner (appears on mouseover, hidden when locked).
- **Right-click** the window or click the gear button in the title bar for a menu: **Lock Frame**,
  **Test Mode**, **Use focus target**, **Options …**, **Hide**.
- The title bar shows "Threat" and, on the right, the name of the enemy. An orange name means
  restricted mode (secret values).

## Options

All settings are stored per profile (= per Edit Mode layout, see qnCore).

### qnThreatMeter

**Window**

- **Show window** – shows the threat window. Default: on.
- **Lock Frame** – prevents moving and resizing. Default: off.
- **Visibility** – **Always**, **In combat only** or **In group or raid only**. Default: Always.
- **Show title bar** – title bar with title, enemy name and gear button. Default: on.
- **Scale** – size of the window, 0.50–2.00. Default: 1.00.
- **Keep in visible area automatically** – moves the window back onto a monitor after dragging, on
  login and when the monitor arrangement changes. With qnViewPort and monitor data, only areas
  actually visible on a monitor count. Default: off.
- **Find window** – button **Move into visible area** moves the window onto the nearest visible
  monitor now (same as `/qnm visible`).

**Bars**

- **Use Damage Meter settings** – takes style, bar height, spacing, text size, icons, class colors
  and transparency from the Edit Mode settings of the built-in Damage Meter (and follows changes made
  there). The next seven options are only usable while this is off. Default: on.
- **Style** – **Default**, **Thin**, **Bordered** or **Full Background**. Default: Default.
- **Bar height** – 8–40. Default: 24.
- **Bar spacing** – 0–10. Default: 2.
- **Font Size** – 0–24; 0 = default size of the Damage Meter. Default: 0.
- **Show class icons** – Default: on.
- **Class Colors** – colors bars by class (otherwise gray). Default: on.
- **Background opacity** – 0–100 %. Default: 50 %.
- **Bar texture** – **Damage Meter**, **Blizzard**, **Flat**, **Raid**, **Skill**, plus all bar
  textures of LibSharedMedia if installed. Default: Damage Meter.
- **Rank before the name** – "1. Name". Default: on.
- **Color your own bar red** – Default: off.
- **Color the tank bar dark red** – Default: off.

**Content**

- **Show threat values** – Default: on.
- **Show threat %** – Default: on.
- **Show threat per second (TPS)** – threat gained per second over the TPS window. Only possible
  while the client provides readable values. Default: on.
- **TPS window (seconds)** – 3–30. Default: 10.
- **Percent basis** – **Relative to the tank (100 % = tank)** or **Scaled (100 % = aggro)**. In
  restricted mode only "scaled" is available. Default: Relative to the tank.
- **Show pull aggro bar** – extra bar at the threat at which you pull aggro. Default: on.
- **Aggro threshold** – **Automatic (range, otherwise class)**, **Melee (110 %)** or
  **Ranged (130 %)**. Automatic: out of combat by range to the target, in combat by class. In combat
  only warriors, rogues and paladins count as melee; druids in Cat or Bear Form and Enhancement
  shamans then get 130 % – choose "Melee" for them. Default: Automatic.
- **Always show self** – if your bar does not fit, it replaces the last row (in restricted mode it is
  shown first). Default: on.
- **Display Pets** – also show pets. Default: on.
- **Use focus target** – uses your focus (or its target) before your target. Default: off.
- **Ignore player pets** – player-controlled enemies such as pets do not count as target. Default: on.
- **Update interval (seconds)** – 0.05–1.00. Default: 0.20.

**Warnings**

- **Warn on high threat** – warns when your threat reaches the warning threshold relative to the tank.
  Only possible while the client provides readable values. Default: on.
- **Warning threshold** – 50–130 %. Default: 90 %.
- **Play sound** – raid warning sound. Default: on.
- **Flash the screen** – short red flash. Default: on.
- **Show message** – "Threat: xx%" in the raid warning area. Default: on.
- **Warn when solo too** – otherwise only in a group. Default: off.

## Slash commands

| Command | Effect |
|---|---|
| `/qnm`, `/qnthreatmeter` (or `/qnm toggle`) | Shows/hides the window |
| `/qnm lock` | Locks/unlocks the window |
| `/qnm test` | Turns test mode (sample data) on/off |
| `/qnm config` (or `/qnm options`) | Opens the options |
| `/qnm check` | API check: client build, whether threat values on your target are secret, your own values |
| `/qnm visible` | Moves the window into the visible area |
| `/qnm reset` | Resets all settings of the active profile (in combat: after combat) |
| `/qnm <anything else>` | Shows the command help in chat |

## Tips & notes

- Requires qnCore. Optional: LibSharedMedia-3.0 for additional bar textures.
- The meter follows your target; if your target is friendly, it uses your target's target. Players
  are never used as enemy.
- When the client provides secret values (restricted mode), there is no sorting, no ranks, no TPS, no
  Pull Aggro bar and no warning; percent is always the client's scaled value.
- Warnings only fire if there is a real tank on the threat list, never while you are tanking
  yourself, and not in test mode. After a warning the next one comes only after your threat dropped
  10 points below the threshold. Warnings also work while the window is hidden (in combat).
- The aggro threshold by range only works out of combat; in combat the class decides.
- TPS history is cleared after combat.
- If `/qnm` says the window is enabled but hidden, the **Visibility** option is hiding it right now.
- With qnViewPort and several monitors, **Keep in visible area automatically** and `/qnm visible`
  bring the window onto a monitor that is actually visible.

[← Overview](README.md)
