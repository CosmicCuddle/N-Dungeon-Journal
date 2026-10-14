# Data Files and How to Add or Edit an Entry

**Applies to:** v0.6.2
**Reference entry:** `Data/Vanilla/RagefireChasm.lua` (the first one written, and the most commented)

## Layout

```text
DungeonJournal.toc        load order; every data file must be listed here
Core.lua                  SDJ:AddDungeon, SDJ.ORDER sorting, SDJ.MAPS / SDJ.PORTRAITS / SDJ.MEDIA paths
Data/Vanilla.lua          SDJ.ORDER.Vanilla (browser order)
Data/Vanilla/<Name>.lua   one file per dungeon, raid or world boss (39 files)
Data/TBC.lua              16 TBC cover cards (Add(id, name, level, location, art))
Data/Wrath.lua            16 Wrath cover cards
Maps/<Name>.blp|.tga      Atlas maps (BLP) and bundled 512x512 maps (TGA)
Portraits/<Name>.tga      boss portraits, 128x128
Media/Covers/<Name>.tga   bundled cover art (only OnyxiasLair.tga at v0.6.2)
```

`SDJ:AddDungeon(era, data)` registers an entry. If an entry with the same `id` already exists in that era it is replaced, so a detailed file can override a stub. The home page sorts each era by `SDJ.ORDER[era]`; ids not in the list go to the end in load order.

## Top-level fields

| Field | Type | Used for | Example (RFC unless noted) |
| --- | --- | --- | --- |
| `id` | string | Unique key; also the key into `SDJ.BOT_CONSUMABLES` and `SDJ.ORDER` | `"rfc"` |
| `name` | string | Card and page title | `"Ragefire Chasm"` |
| `level` | string | `LV` on card and header | `"12-18"` |
| `minLevel` | string | Entry level, used in Preparation text | `"8"` |
| `location` | string | Card and header | `"Orgrimmar - Cleft of Shadow"` |
| `tag` | string | Section filter: `"Dungeon"`, `"Outdoor Dungeon"`, `"Raid"`, `"World Boss"` | `"Dungeon"` |
| `players` | string | Raid size badge (raids only) | `"40"` (MC), `"20"` (ZG) |
| `raid` / `worldBoss` | boolean | Alternative to `tag` for the section filter | not used at v0.6.2 |
| `roleLevels` | table | Recommended level per role in the header | `{dps = 16, healer = 18, tank = 18}` (Deadmines) |
| `art` | texture path | Cover art | `"Interface\\GLUES\\LOADINGSCREENS\\LoadScreenRagefireChasm"` |
| `crop` | `{left, right, top, bottom}` | Tex coords for `art` | `{0.04, 0.96, 0.29, 0.73}` |
| `artFallback` | texture path | Used if `art` fails to load | `SDJ.MAPS .. "RagefireChasm"` |
| `fallbackCrop` | tex coords | Crop for `artFallback` | `{0.0, 1.0, 0.25, 0.70}` |
| `maps` | list | Map tab pages | see below |
| `trash` | table | Trash tab | see below |
| `bosses` | list | Bosses tab | see below |
| `quests` | list | Quests tab | see below |
| `preparation` | list | Preparation tab | see below |

## maps

```lua
maps = {
    {
        name = "Ragefire Chasm",
        texture = SDJ.MAPS .. "RagefireChasm",   -- 512x512, whole texture
        coords = {0, 1, 0, 1},
        legend = {
            {"A", "Entrance", "blue"},           -- {marker, text, optional colour: "blue" or "green"}
            {"1", "Maur Grimtotem"},
            {"", "Oggleflint <Ragefire Chieftain>"},
        },
        credit = "Map: Atlas (Dan Gilbert, map by Niflheim) - GPL",
    },
}
```

More than one entry in `maps` gives Prev / Next buttons.

## trash

```lua
trash = {
    mobs = {
        {
            name = "Ragefire Shaman", npc = 11319, level = "13-15 Elite", priority = 1,   -- 1 HIGH, 2 MEDIUM, 3 LOW
            abilities = {
                {spell = 11986, name = "Healing Wave", tag = "HEAL", desc = "Heals an injured ally."},
                {name = "Flees for help", tag = "FLEE", desc = "Runs at 15% health to pull more troggs."},
            },
            note = "Kill first. Interrupt Healing Wave; stop runners.",
        },
    },
    loot = { <loot rows> },
    lootNote = "AtlasLoot has no RFC trash table; only trash quest drops are listed (no recorded %).",
}
```

`spell` is optional; without it the ability has no icon. Tags in use include AOE, FLEE, DEBUFF, SUMMON, HEAL, STUN, ENRAGE, DOT, CURSE, ROOT, IMMUNE.

## bosses

```lua
{
    name = "Taragaman the Hungerer", npc = 11520, level = "16 Elite",
    subname = "Ragefire Chieftain",          -- optional, shown as <subname>
    optional = true,                         -- optional; or rare = true
    portrait = P .. "TaragamanTheHungerer",  -- P = SDJ.PORTRAITS
    summary = "Felguard on the central lava platform [2]. ...",
    abilities = { {spell = 18072, name = "Uppercut", desc = "Damage plus knock-back (10 yd)."} },
    mechanics = { "Tank him away from the lava edge: Uppercut knocks back." },
    loot = { <loot rows> },
    lootNote = "...",                        -- optional
}
```

Raid files also use `id` on bosses in some places (65 boss entries have one).

## Loot rows

```lua
{id = 14149, name = "Subterranean Cape", slot = "Back", quality = 3, icon = "INV_Misc_Cape_18", rate = "31.59%"},
{id = 14540, name = "Taragaman the Hungerer's Heart", slot = "Quest Item - Slaying the Beast", quality = 1,
 icon = "INV_Misc_Organ_01", rate = "100%", note = "Quest drop: only for players on Slaying the Beast."},
```

- `quality`: 0 poor, 1 common, 2 uncommon, 3 rare, 4 epic, 5 legendary.
- `icon`: file name under `Interface\Icons\`, no path.
- `rate`: a string as printed. Leave it out when no source gives one. Do not estimate.
- `note`: optional, shown on the row.

## quests

```lua
{
    id = 5725, name = "The Power to Destroy...", faction = "Horde", level = 16, minLevel = 9,   -- faction: "Alliance", "Horde" or "Both"
    giver = "Varimathras", giverLocation = "Undercity - Royal Quarter (56.2, 92.6)",
    prerequisites = "None.",
    objective = "Bring the books ... to Varimathras in Undercity.",
    requiredItems = { {id = 14395, name = "Spells of Shadow", where = "Searing Blade Cultists and Searing Blade Warlocks"} },
    where = "...",                                  -- optional
    turnin = "Varimathras", turninLocation = "Undercity - Royal Quarter (56.2, 92.6)",
    followUp = "Returning the Lost Satchel (5724)", -- optional
    chain = { {id = 5722, name = "...", text = "..."} },  -- optional; enables the Quest Chain button
    rewards = {
        money = 700,                                -- copper
        reputation = "Undercity",
        items = { <loot-style rows without rate> },
        choice = { <loot-style rows without rate> },
        text = "...",                               -- optional free text
    },
    notes = "...",                                  -- shown as SERVER NOTES
}
```

Check quest IDs, chain order and rewards against the AzerothCore world database tables `quest_template`, `quest_template_addon`, `creature_queststarter` and `creature_questender` on the Grimfeather fork.

## preparation

```lua
preparation = {
    {title = "Level", lines = { "Dungeon level 12-18; entry from level 8 (Atlas). Quests from level 9." }},
    {title = "Keys & required items", lines = { "No key or attunement. Entrance: Cleft of Shadow, Orgrimmar." }},
}
```

Do not add a Bot Consumables block here. It is added automatically from `SDJ.BOT_CONSUMABLES` in `Core.lua` (see [BOT-CONSUMABLES.md](BOT-CONSUMABLES.md)).

## Adding a new entry

1. Copy the header comment style from `RagefireChasm.lua` and list every source you used, with file names and commits.
2. Create `Data/<Era>/<Name>.lua` and call `SDJ:AddDungeon("<Era>", { ... })`.
3. Add the file to `DungeonJournal.toc`, after `Data\<Era>.lua`'s stubs if it replaces one (the later file wins).
4. Add the `id` to `SDJ.ORDER.<Era>` where it belongs.
5. Bundle maps and portraits following [ART-AND-TEXTURES.md](ART-AND-TEXTURES.md).
6. If the server has a `.bot consumables` profile for it, add `SDJ.BOT_CONSUMABLES[<id>]`.
7. Add the entry to CREDITS.txt and CHANGELOG.md.
8. Run `tools/build.sh --no-zip`. The harness opens every entry and every tab and fails on overflowing text, missing textures or 3.3.5-incompatible calls.

## Editing an entry

Change the field, then run the build script. If you change a number that came from a source (a drop rate, a level, a quest ID), note the source in the file header or the row's `note`.
