# Source and Accuracy Guide

Dungeon Journal is written around the actual Naxxramas progression server. Its source rules put server behaviour first, followed by established reference addons for information the server does not provide.

**Applies to:** v0.6.2  
**Full attribution:** [CREDITS.txt](../CREDITS.txt), which lists the files and commits used for each batch

## Quick reference

- Use the Grimfeather AzerothCore and Individual Progression forks as the source of truth for server-specific mechanics.
- Use Atlas, AtlasLoot and AtlasQuest for maps, loot and quests where the server does not provide an override.
- Do not estimate missing percentages, quest requirements or bot profiles.
- Keep attribution in `CREDITS.txt` and explain any server-specific exceptions in the relevant entry.

## Which source takes priority

The journal describes what happens on this server, not on retail Classic or another private server. When sources disagree:

1. The server's own code and database win. That is the Grimfeather AzerothCore fork and the Grimfeather mod-individual-progression fork.
2. AtlasLoot, AtlasQuest and Atlas fill in what the server does not define (most drop rates, quest text, maps).
3. Wowhead is used only for portraits and for checking spell and item tooltips.
4. Nothing is invented. A drop rate that no source gives is left out (`rate = nil`), and the row or `lootNote` says so.

## Reference projects

| Source | Used for | Notes |
| --- | --- | --- |
| [Grimfeather/azerothcore-wotlk](https://github.com/Grimfeather/azerothcore-wotlk) | Creature levels and elite rank (`creature_template`), abilities (`smart_scripts`, boss scripts), quest IDs, chains and rewards (`quest_template`, `quest_template_addon`, `creature_queststarter`, `creature_questender`) | All data is generated from this fork since v0.3.7. Before that, upstream azerothcore-wotlk |
| [Grimfeather/mod-individual-progression](https://github.com/Grimfeather/mod-individual-progression) | Progression gates and attunements, restored Vanilla content (for example Naxxramas 40 on map 533), raid loot tables where IP defines them | Since v0.3.7. Before that, ZhengPeiRu21/mod-individual-progression |
| Atlas 1.17.0 for 3.3.5 (Dan Gilbert, maps by Niflheim), from [TrinityCore/wow_335a_addons](https://github.com/TrinityCore/wow_335a_addons) | Map BLPs (copied unmodified) and legends | GPLv2 |
| AtlasLoot (`AtlasLoot_OriginalWoW/originalwow.lua`, `AtlasLoot_WorldEvents`) | Boss and trash loot lists and drop percentages | GPL. Replaced by IP tables where IP has them (Nefarian, AQ20, Naxxramas) |
| [AtlasQuest](https://github.com/nanderson11/AtlasQuest) (commit `19998f5`) | Quest lists per instance, quest text and locations | GPLv2, cross-checked with the world database |
| Wowhead (wow.zamimg.com Wrath model-viewer thumbnails) | Boss portraits, cropped to 128x128 | Also used to check spell and item tooltip text |
| Mod-Naxxramas-Core `BotRaidConsumables.cpp` and N-MultiBot-Chatless | Bot Consumables text | See [BOT-CONSUMABLES.md](BOT-CONSUMABLES.md) |
| Blizzard loading screens | Cover art (client textures, and the bundled Onyxia's Lair TGA) | |

## Server-specific overrides

From the CHANGELOG:

- Naxxramas 40 boss loot comes from the IP `naxx40` tables, because AtlasLoot OriginalWoW only has T3 tables for it (v0.6.0).
- Nefarian's loot uses IP references 30486, 30487 and 30551; the rest of BWL uses AtlasLoot (v0.5.3).
- AQ20 boss loot uses IP references 30411-30436 (v0.5.4).
- Ragefire Chasm boss drops were corrected from green to blue to match AtlasLoot's quality (v0.3.1).

## Missing or unverified information

Say so in the data. Examples already in the files:

- `lootNote = "AtlasLoot has no RFC trash table; only trash quest drops are listed (no recorded %)."`
- Quest `notes` such as "Both books are unique quest drops; no drop rate is recorded in the sources."
- Bot Consumables: "has no named .bot consumables profile" rather than a guessed profile.

One open item: `Data/Vanilla/MoltenCore.lua:150` says the packs near Magmadar "may revive" with no source cited. It is on the [roadmap](../ROADMAP.md).

## Related guides

See [Data Format](DATA-FORMAT.md) for where source notes belong and [Bot Consumables](BOT-CONSUMABLES.md) for the module references.
