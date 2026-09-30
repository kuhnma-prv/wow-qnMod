#Requires -Version 7
<#
.SYNOPSIS
    Converts the qnLoadout sets (AddOns\qnLoadout\Sets\*.json) into AddOns\qnLoadout\Data.lua.
    With -Import it first writes the exports from the game (SavedVariables qnLoadoutDB) into Sets\*.json.

.DESCRIPTION
    WoW cannot read JSON files, therefore the sets are converted into a Lua file that the addon loads.
    After converting: /reload in the game.
    Spell and item names in the sets are English; Sets\Spells.json and Sets\Items.json map them to IDs
    (the game translates them into the client language). Format: AddOns\qnLoadout\Sets\README.md.

.PARAMETER Import
    Read the exports from WTF\Account\<account>\SavedVariables\qnLoadoutDB.lua of the client and write
    them as Sets\<CLASS>-<name>.json (an existing file is only replaced with -Force), then convert.

.PARAMETER WowRoot
    WoW root folder (contains _classic_beta_ …). Default: $env:QN_WOW_ROOT, otherwise the folder of a
    running client.

.PARAMETER Client
    Client folder below the WoW root. Default: _classic_beta_.

.EXAMPLE
    pwsh tools\Convert-QnLoadout.ps1
.EXAMPLE
    pwsh tools\Convert-QnLoadout.ps1 -Import -WowRoot 'C:\Games\World of Warcraft'
#>
[CmdletBinding()]
param(
    [switch]$Import,
    [string]$WowRoot,
    [string]$Client = '_classic_beta_',
    [switch]$Force
)
$ErrorActionPreference = 'Stop'

$repo = Split-Path $PSScriptRoot -Parent
$addon = Join-Path $repo 'AddOns\qnLoadout'
$setsDir = Join-Path $addon 'Sets'
$dataFile = Join-Path $addon 'Data.lua'
$spellsFile = Join-Path $setsDir 'Spells.json'   # English spell name -> spell ID, shared by all sets
$itemsFile = Join-Path $setsDir 'Items.json'     # English item name -> item ID (macro texts)

$PREFIX = 'qn'
$MAX_BODY = 255   # letters of the macro editor (Blizzard_MacroUI.xml)
$MAX_NAME = 16    # usual limit of macro names; not verified for Forever, therefore only a warning

#---------------------------------------------------------------------------
# Import: SavedVariables -> JSON
#---------------------------------------------------------------------------

function Find-WowRoot {
    if ($WowRoot) { return $WowRoot }
    if ($env:QN_WOW_ROOT) { return $env:QN_WOW_ROOT }
    $exe = Get-Process -Name 'Wow*' -ErrorAction SilentlyContinue | Where-Object Path |
        Select-Object -First 1 -ExpandProperty Path
    if ($exe) { return Split-Path (Split-Path $exe -Parent) -Parent }
    throw 'WoW root folder not found: use -WowRoot or $env:QN_WOW_ROOT (or start the client).'
}

# Content of a Lua string literal (without the quotes) -> text. WoW writes UTF-8; escapes \ddd are
# bytes, therefore the result is assembled as bytes and decoded at the end.
function ConvertFrom-LuaString([string]$s) {
    $bytes = [Collections.Generic.List[byte]]::new()
    $utf8 = [Text.Encoding]::UTF8
    $i = 0
    while ($i -lt $s.Length) {
        $c = $s[$i]
        if ($c -ne '\') {
            # surrogate pairs stay together
            $len = if ([char]::IsHighSurrogate($c) -and $i + 1 -lt $s.Length) { 2 } else { 1 }
            $bytes.AddRange($utf8.GetBytes($s.Substring($i, $len)))
            $i += $len
            continue
        }
        $n = $s[$i + 1]
        if ($n -match '\d') {
            $digits = [regex]::Match($s.Substring($i + 1), '^\d{1,3}').Value
            $bytes.Add([byte][int]$digits)
            $i += 1 + $digits.Length
            continue
        }
        $map = @{ 'n' = 10; 'r' = 13; 't' = 9; '\' = 92; '"' = 34; "'" = 39; "`n" = 10 }
        if ($map.ContainsKey([string]$n)) { $bytes.Add([byte]$map[[string]$n]) }
        else { $bytes.AddRange($utf8.GetBytes([string]$n)) }
        $i += 2
    }
    $utf8.GetString($bytes.ToArray())
}

function Import-Exports {
    $root = Find-WowRoot
    $accounts = Join-Path $root "$Client\WTF\Account"
    $files = Get-ChildItem $accounts -Recurse -Filter 'qnLoadoutDB.lua' -ErrorAction SilentlyContinue |
        Where-Object { $_.Directory.Name -eq 'SavedVariables' }
    if (-not $files) { Write-Warning "No qnLoadoutDB.lua below $accounts (log out or /reload after exporting)."; return }
    foreach ($file in $files) {
        $text = Get-Content $file.FullName -Raw -Encoding utf8
        foreach ($m in [regex]::Matches($text, '\["json"\]\s*=\s*"((?:[^"\\]|\\.|\\\r?\n)*)"')) {
            $set = ConvertFrom-LuaString $m.Groups[1].Value | ConvertFrom-Json
            $safe = ($set.name -replace '[\\/:*?"<>|]', '_').Trim()
            $target = Join-Path $setsDir ("{0}-{1}.json" -f $set.class, $safe)
            if ((Test-Path $target) -and -not $Force) {
                Write-Warning "Exists, not replaced (use -Force): $target"
                continue
            }
            $set | ConvertTo-Json -Depth 8 | Set-Content $target -Encoding utf8NoBOM
            Write-Host "Imported: $target"
        }
    }
}

#---------------------------------------------------------------------------
# Check a set
#---------------------------------------------------------------------------

function Test-Set($set, [string]$file, $spells) {
    $errors = [Collections.Generic.List[string]]::new()
    function Has($obj, $name) { $obj.PSObject.Properties.Name -contains $name }
    if (-not ($set.name -is [string]) -or $set.name.Trim() -eq '') { $errors.Add('name missing') }
    if (-not ($set.class -is [string]) -or $set.class -cnotmatch '^[A-Z]+$') { $errors.Add('class must be the class file in capitals, e.g. PRIEST') }
    $macroNames = @{}
    foreach ($m in @($set.macros)) {
        if ($null -eq $m) { continue }
        $n = $m.name
        if (-not ($n -is [string]) -or -not $n.StartsWith($PREFIX)) { $errors.Add("macro '$n': name must start with '$PREFIX'"); continue }
        if ($macroNames.ContainsKey($n)) { $errors.Add("macro '$n' twice") }
        $macroNames[$n] = $true
        if ($n.Length -gt $MAX_NAME) { Write-Warning "${file}: macro '$n' is longer than $MAX_NAME characters" }
        if ($m.scope -cnotin 'char', 'account') { $errors.Add("macro '$n': scope must be 'char' or 'account'") }
        if ((Has $m 'body') -and -not ($m.body -is [string])) { $errors.Add("macro '$n': body must be a text") }
        elseif ($m.body.Length -gt $MAX_BODY) { $errors.Add("macro '$n': body longer than $MAX_BODY characters ($($m.body.Length))") }
        if ((Has $m 'icon') -and -not ($m.icon -is [string] -or $m.icon -is [long] -or $m.icon -is [int])) { $errors.Add("macro '$n': icon must be a file ID or texture name") }
    }
    $keys = @{}
    foreach ($e in @($set.numpad)) {
        if ($null -eq $e) { continue }
        $k = $e.key
        if (-not ($k -is [string]) -or $k -cnotmatch '^[A-Z0-9]+$') { $errors.Add("numpad entry without valid key: $($e | ConvertTo-Json -Compress)"); continue }
        $s = if (Has $e 'set') { $e.set } else { $null }
        if ($null -ne $s -and $s -cnotin 'ctrl', 'alt') { $errors.Add("${k}: set must be 'ctrl' or 'alt'") }
        $id = "$k/$s"
        if ($keys.ContainsKey($id)) { $errors.Add("$k$(if ($s) { " ($s)" }) twice") }
        $keys[$id] = $true
        $kinds = @('spell', 'macro', 'empty') | Where-Object { Has $e $_ }
        if (@($kinds).Count -ne 1) { $errors.Add("${k}: exactly one of spell, macro or empty") }
        elseif ((Has $e 'empty') -and $e.empty -ne $true) { $errors.Add("${k}: empty must be true") }
        elseif ((Has $e 'macro') -and -not ($e.macro -is [string])) { $errors.Add("${k}: macro must be a name") }
        elseif ((Has $e 'spell') -and $e.spell -is [string] -and -not $spells.ContainsKey($e.spell)) { $errors.Add("${k}: spell '$($e.spell)' is not in Spells.json") }
        elseif ((Has $e 'macro') -and $e.macro.StartsWith($PREFIX) -and -not $macroNames.ContainsKey($e.macro)) {
            Write-Warning "${file}: $k uses macro '$($e.macro)', which is not defined in the set"
        }
    }
    $errors
}

#---------------------------------------------------------------------------
# JSON -> Lua
#---------------------------------------------------------------------------

function ConvertTo-LuaString([string]$s) {
    $sb = [Text.StringBuilder]::new('"')
    foreach ($ch in $s.ToCharArray()) {
        switch ($ch) {
            '\' { [void]$sb.Append('\\') }
            '"' { [void]$sb.Append('\"') }
            "`n" { [void]$sb.Append('\n') }
            "`r" { [void]$sb.Append('\r') }
            default {
                if ([int]$ch -lt 32) { [void]$sb.Append(('\{0:d3}' -f [int]$ch)) } else { [void]$sb.Append($ch) }
            }
        }
    }
    [void]$sb.Append('"')
    $sb.ToString()
}

function ConvertTo-LuaValue($v) {
    if ($v -is [string]) { return ConvertTo-LuaString $v }
    if ($v -is [bool]) { return $v.ToString().ToLower() }
    if ($v -is [long] -or $v -is [int] -or $v -is [double] -or $v -is [decimal]) { return [string]::Format([Globalization.CultureInfo]::InvariantCulture, '{0}', $v) }
    throw "Unsupported value: $v"
}

# One table line { key = value, ... } with the fields in the given order (missing ones left out)
function ConvertTo-LuaFields($obj, [string[]]$fields) {
    $parts = foreach ($f in $fields) {
        if ($obj.PSObject.Properties.Name -contains $f -and $null -ne $obj.$f) { '{0} = {1}' -f $f, (ConvertTo-LuaValue $obj.$f) }
    }
    '{ ' + ($parts -join ', ') + ' }'
}

# Spells.json / Items.json: { "English name": ID, ... } -> sorted dictionary (errors end the script)
function Read-Names([string]$path) {
    $names = [Collections.Generic.SortedDictionary[string, long]]::new([StringComparer]::Ordinal)
    if (-not (Test-Path $path)) { return ,$names }
    $file = Split-Path $path -Leaf
    $json = Get-Content $path -Raw -Encoding utf8 | ConvertFrom-Json
    foreach ($p in $json.PSObject.Properties) {
        if (-not ($p.Value -is [long] -or $p.Value -is [int]) -or $p.Value -le 0) { throw "${file}: '$($p.Name)' needs an ID (positive number)" }
        $names[$p.Name] = $p.Value
    }
    ,$names
}

# Dictionary as a Lua table: ns.<name> = { ["English"] = ID, ... }
function Add-LuaNames($out, [string]$name, [string]$comment, $names) {
    $out.Add('')
    $out.Add("-- $comment")
    $out.Add("ns.$name = {")
    foreach ($key in $names.Keys) { $out.Add("`t[$(ConvertTo-LuaString $key)] = $($names[$key]),") }
    $out.Add('}')
}

function Convert-Sets {
    $spells = Read-Names $spellsFile
    $items = Read-Names $itemsFile
    $both = @($spells.Keys | Where-Object { $items.ContainsKey($_) })
    if ($both) { throw "Names in Spells.json and Items.json: $($both -join ', ')" }
    $files = Get-ChildItem $setsDir -Filter '*.json' -ErrorAction SilentlyContinue | Where-Object Name -notin 'Spells.json', 'Items.json' | Sort-Object Name
    $out = [Collections.Generic.List[string]]::new()
    $out.Add('-- Generated by tools\Convert-QnLoadout.ps1 from AddOns\qnLoadout\Sets\*.json - do not edit, change the JSON files.')
    $out.Add('local _, ns = ...')
    $out.Add('')
    $out.Add('ns.SETS = {')
    $failed = 0
    foreach ($file in $files) {
        try { $set = Get-Content $file.FullName -Raw -Encoding utf8 | ConvertFrom-Json }
        catch { Write-Warning "$($file.Name): invalid JSON: $($_.Exception.Message)"; $failed++; continue }
        $errors = @(Test-Set $set $file.Name $spells)
        if ($errors.Count) {
            $errors | ForEach-Object { Write-Warning "$($file.Name): $_" }
            $failed++
            continue
        }
        $out.Add("`t{")
        $out.Add("`t`tname = $(ConvertTo-LuaString $set.name), class = $(ConvertTo-LuaString $set.class), file = $(ConvertTo-LuaString $file.Name),")
        if ($set.desc) { $out.Add("`t`tdesc = $(ConvertTo-LuaString $set.desc),") }
        $out.Add("`t`tmacros = {")
        foreach ($m in @($set.macros)) { if ($m) { $out.Add("`t`t`t$(ConvertTo-LuaFields $m 'name','scope','icon','body'),") } }
        $out.Add("`t`t},")
        $out.Add("`t`tnumpad = {")
        foreach ($e in @($set.numpad)) { if ($e) { $out.Add("`t`t`t$(ConvertTo-LuaFields $e 'key','set','spell','macro','empty'),") } }
        $out.Add("`t`t},")
        $out.Add("`t},")
        Write-Host "OK      $($file.Name) ($($set.class), $(@($set.macros).Count) macros, $(@($set.numpad).Count) numpad keys)"
    }
    $out.Add('}')
    Add-LuaNames $out 'SPELLS' 'English spell name -> spell ID (Sets\Spells.json); the client name comes from C_Spell.GetSpellName' $spells
    Add-LuaNames $out 'ITEMS' 'English item name -> item ID (Sets\Items.json); the client name comes from C_Item.GetItemNameByID' $items
    Write-Host "Spells: $($spells.Count) names, items: $($items.Count) names"
    Set-Content $dataFile ($out -join "`n") -Encoding utf8NoBOM -NoNewline
    Add-Content $dataFile "`n" -NoNewline
    Write-Host "Written: $dataFile"
    if ($failed) { Write-Warning "$failed file(s) skipped because of errors."; exit 1 }
}

if ($Import) { Import-Exports }
Convert-Sets
