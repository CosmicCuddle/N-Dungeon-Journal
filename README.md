# Dungeon Journal

A **WoW 3.3.5a** dungeon journal addon, styled after [Forever Dungeon Journal](https://www.curseforge.com/wow/addons/forever-dungeon-journal) and built for Michael’s Naxxramas progression server on **Grimfeather’s AzerothCore** fork with **Individual Progression**.

Current release: **[v0.6.1 – Vanilla Complete](https://github.com/CosmicCuddle/Naxx-Dungeon-Journal/releases/latest)**

## What’s in Vanilla

| Section | Count | Contents |
|--------|------:|----------|
| **Dungeons** | 29 | Ragefire Chasm through Stratholme (Living / Undead), including Scarlet Monastery wings, Maraudon sides, Dire Maul wings, LBRS/UBRS, Scholomance, and Jintha’Alor |
| **Raids** | 7 | In Individual Progression order: **Molten Core → Onyxia → Blackwing Lair → Zul’Gurub → Ruins of Ahn’Qiraj → Temple of Ahn’Qiraj → Naxxramas (40)** |
| **World Bosses** | 3 | Azuregos, Lord Kazzak, Emerald Dragons |

**The Burning Crusade** and **Wrath of the Lich King** tabs exist in the UI but are **not populated yet**.

## Features

- Home tabs: **Dungeons | Raids | World Bosses**, with a Vanilla / TBC / Wrath expansion filter
- Per-instance tabs: **Trash | Bosses | Quests | Preparation | Map** (Atlas maps; Prev/Next where multiple pages exist)
- Loot, mechanics and preparation notes aligned to this server’s Individual Progression data where it differs from AtlasLoot
- **Bot Consumables** guidance on the home screen and in Preparation (commands and packages from the Naxxramas Core bot consumables system; named profiles are only listed where the server actually has them)

## Install

Prefer the **[Releases](https://github.com/CosmicCuddle/Naxx-Dungeon-Journal/releases/latest)** zip (`DungeonJournal_v0.6.1.zip`):

1. Exit WoW completely.
2. Delete any old `Interface\AddOns\ServerDungeonJournal` folder (do not leave both addons installed).
3. Extract so the folder is `Interface\AddOns\DungeonJournal` (with `DungeonJournal.toc` inside).
4. Restart WoW, enable **Dungeon Journal**, type `/dj` or `/dungeonjournal`.

### Warning: GitHub “Code → Download ZIP”

Downloading the repository via **Code → Download ZIP** produces a folder named **`Naxx-Dungeon-Journal-main`**. WoW will not load that name as this addon. Either:

- rename that folder to **`DungeonJournal`**, or  
- use the release zip instead (recommended).

## Licence and credits

Distributed under **GPLv2** (`LICENSE-GPL-2.0.txt`) because it includes GPL-derived material:

- **Atlas** instance maps (Dan Gilbert / Niflheim) — GPLv2  
- **AtlasLoot** loot table baselines — GPL (server / IP rates win where they conflict)  
- **AtlasQuest** quest text / locations where used  
- Boss **portraits** cropped from Wowhead Wrath model-viewer thumbnails (see `CREDITS.txt`)

Full attribution: **[CREDITS.txt](CREDITS.txt)**. Version history: **[CHANGELOG.txt](CHANGELOG.txt)**.
