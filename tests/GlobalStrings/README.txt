Blizzard GlobalStrings of WoW Classic Forever (deDE, enUS), from
https://github.com/Ketho/BlizzardInterfaceResources, branch forever, Resources/GlobalStrings.
The files deDE.lua and enUS.lua are not in the repo: run.mjs and gs.mjs load missing ones
automatically (globalstrings.mjs). The test stub loads the file of the configured locale
(QN_LOCALE, default deDE).
Update: node globalstrings.mjs --update
