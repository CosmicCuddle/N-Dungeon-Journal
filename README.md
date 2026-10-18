# Dungeon Journal

**Dungeon Journal** is a World of Warcraft 3.3.5a addon by **CosmicCuddle**, built for the Naxxramas progression server running Grimfeather's AzerothCore fork and Individual Progression.

It brings dungeon, raid and world-boss information into one in-game journal: encounters, loot, quests, preparation notes and maps. The aim is simple: find the information you need without switching between several addons or external guides.

**Current release:** [v0.6.2 — Bot Consumables update](https://github.com/CosmicCuddle/N-Dungeon-Journal/releases/latest)  
**Current coverage:** Vanilla content complete; The Burning Crusade and Wrath of the Lich King are planned for later.  
**Client:** WoW 3.3.5a (Interface 30300)

## What's included

| Content | Coverage |
| --- | --- |
| **Dungeons** | 29 Vanilla entries, from Ragefire Chasm to Stratholme, including the individual Scarlet Monastery, Maraudon and Dire Maul sections and Jintha'Alor |
| **Raids** | 7: Molten Core, Onyxia's Lair, Blackwing Lair, Zul'Gurub, Ruins of Ahn'Qiraj, Temple of Ahn'Qiraj and Naxxramas (40) |
| **World bosses** | Azuregos, Lord Kazzak and the Emerald Dragons |
| **Later expansions** | 16 TBC and 16 Wrath dungeon cover cards; full encounter data has not been added yet |

Vanilla entries follow the server's Individual Progression rules where those differ from ordinary guides or loot tables.

## Using the journal

Enter `/dj` or `/dungeonjournal` to open the journal. Choose **Dungeons**, **Raids** or **World Bosses**, then select the expansion and the entry you want.

Each populated entry has five sections:

| Tab | Information |
| --- | --- |
| **Trash** | Dangerous enemies, abilities, priorities and notable drops |
| **Bosses** | Encounter mechanics, portraits and loot tables |
| **Quests** | Alliance and Horde quests, objectives, chains and rewards |
| **Preparation** | Entry requirements, attunements, server rules and consumables |
| **Map** | Instance maps, legends and additional map pages where available |

The home screen also includes **Bot Consumables** guidance. This describes the server's `.bot consumables` commands; the journal does not run the commands itself.

For a closer look at the interface, see [Features and Controls](docs/FEATURES.md).

## Installing the addon

1. Download the zip from [GitHub Releases](https://github.com/CosmicCuddle/N-Dungeon-Journal/releases/latest).
2. Close World of Warcraft.
3. Remove any old `Interface\AddOns\ServerDungeonJournal` folder. Remove the previous `DungeonJournal` addon folder before replacing it.
4. Extract the new zip so the file sits at `Interface\AddOns\DungeonJournal\DungeonJournal.toc`.
5. Start the game, enable **Dungeon Journal**, and type `/dj`.

**Important:** GitHub's **Code → Download ZIP** creates a folder called `N-Dungeon-Journal-main`. Rename it to `DungeonJournal` if installing from source. The release zip is the recommended download.

See the [Installation and Upgrade Guide](docs/INSTALL.md) for backups, migration and rollback instructions.

## Documentation

| Guide | What you'll find |
| --- | --- |
| [Features and Controls](docs/FEATURES.md) | Home screen, browsing, instance tabs and item links |
| [Bot Consumables](docs/BOT-CONSUMABLES.md) | Commands, profile limits, group rules and server integration |
| [Installation and Upgrades](docs/INSTALL.md) | Installing, upgrading, older folder names and rollback |
| [Troubleshooting](docs/TROUBLESHOOTING.md) | Common loading, texture and item-cache problems |
| [Data Sources](docs/DATA-SOURCES.md) | Source priority and how server-specific data is checked |
| [Data Format](docs/DATA-FORMAT.md) | Entry structure, fields and examples for editing content |
| [Artwork and Textures](docs/ART-AND-TEXTURES.md) | Cover images, maps, portraits and 3.3.5a texture rules |
| [Testing](docs/TESTING.md) | Offline and in-game checks |
| [Release Checklist](docs/RELEASE-CHECKLIST.md) | Building, tagging and publishing a release |
| [Developer Tools](tools/README.md) | Build script, Lua harness and compatibility checks |
| [Roadmap](ROADMAP.md) | Completed work and future priorities |
| [Release History](CHANGELOG.md) | Changes by version |

## Development and future work

Vanilla content is the current focus. Planned improvements include search, favourites, more in-game testing and refinements to the existing pages. TBC and Wrath remain on the roadmap rather than being presented as finished features.

The [roadmap](ROADMAP.md) tracks the work in more detail. Changes for each published version are recorded in the [release history](CHANGELOG.md).

## Credits and licence

Dungeon Journal is maintained by **CosmicCuddle** and distributed under **GPLv2**. It includes material derived from Atlas, AtlasLoot and AtlasQuest, plus other credited artwork and reference sources.

See [CREDITS.txt](CREDITS.txt) for the source and asset acknowledgements, and [LICENSE-GPL-2.0.txt](LICENSE-GPL-2.0.txt) for the licence terms.
