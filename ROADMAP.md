# Dungeon Journal — Development Roadmap

**Maintained by:** CosmicCuddle  
**Updated:** 18 October 2026  
**Current addon release:** v0.6.2  
**Client:** WoW 3.3.5a (Interface 30300)  
**Repository:** https://github.com/CosmicCuddle/N-Dungeon-Journal

## Direction

Vanilla coverage is complete. The next priority is a polish and verification pass over the existing guides, interface and release process. TBC and Wrath already have cover cards, but their full encounter content is deferred.

This roadmap separates shipped features, work that has only been tested offline and ideas that have not yet been started. Planned items are not release promises.

## Priorities at a glance

| Priority | Work | Position |
| --- | --- | --- |
| First | Verify the v0.6.2 interface in the client | Awaiting in-game checks |
| Next | Vanilla search, favourites and presentation improvements | Proposed |
| Later | The Burning Crusade data and progression rules | Deferred |
| Later | Wrath of the Lich King data and progression rules | Deferred |

## How progress is tracked

- **Released** - in a published GitHub release.
- **Automated-test only** - passes luac, the denylist and the offline harness ([tools/README.md](tools/README.md)), but has not been checked in a 3.3.5a client.
- **In-game tested** - checked in a real 3.3.5a client on the server, with the result written down here.
- **Proposed** - not started.
- **Deferred / later** - agreed to wait until earlier phases are done.

The harness mocks the WoW API. A passing harness run is not an in-game test.

## Current content — v0.6.2

Counted from the data files at v0.6.2:

| Section | Entries | Notes |
| --- | ---: | --- |
| Vanilla dungeons | 29 | 28 tagged `Dungeon` plus Jintha'Alor tagged `Outdoor Dungeon` |
| Vanilla raids | 7 | Molten Core, Onyxia's Lair, Blackwing Lair, Zul'Gurub, Ruins of Ahn'Qiraj, Temple of Ahn'Qiraj, Naxxramas (40) |
| Vanilla world bosses | 3 | Azuregos, Lord Kazzak, Emerald Dragons |
| TBC | 16 | cover cards only (name, level range, zone, loading-screen art) |
| Wrath | 16 | cover cards only |

Vanilla content across the 39 entries: 318 bosses, 482 trash mob entries, 365 quests, 2,480 boss loot rows and 628 trash loot rows. Bundled art: 42 Atlas map BLPs, 8 map TGAs, 332 boss portraits and one cover TGA (Onyxia's Lair).

## Project rules

- **Server wins.** Where the Grimfeather AzerothCore or Individual Progression data differs from AtlasLoot, AtlasQuest or Wowhead, the server data is used. See [docs/DATA-SOURCES.md](docs/DATA-SOURCES.md).
- **No invented data.** A drop rate that is not in a source is left as `rate = nil`. A missing Bot Consumables profile is stated as missing, not guessed.
- **3.3.5a APIs only.** No retail-only calls. [tools/denylist.sh](tools/denylist.sh) blocks the common ones.
- **Addon folder is `DungeonJournal`.** SavedVariables are `DungeonJournalDB`. The pre-rename `ServerDungeonJournalDB` is copied once on first load and then left alone.
- **Cover art must load on the client.** Bundled art is uncompressed 32-bit TGA with power-of-two sides. Generic continent loading screens are not used as covers. See [docs/ART-AND-TEXTURES.md](docs/ART-AND-TEXTURES.md).
- **Only the addon ships.** The release zip contains `DungeonJournal/` and nothing else; `docs/`, `tools/`, this file and `CHANGELOG.md` stay in the repository.
- **N-Addon-Collection is separate.** It pins Dungeon Journal at v0.6.1 (commit `a35e440`) in its `sources.lock.json`. Updating that pin is its own reviewed import, not part of a Dungeon Journal release.

## Repository structure

| Path | Responsibility |
| --- | --- |
| `DungeonJournal.toc` | Load order, version, SavedVariables |
| `Core.lua` | `SDJ.VERSION`, media paths, `SDJ:AddDungeon`, `SDJ.ORDER` sorting, Bot Consumables text (`SDJ.BOT_CONSUMABLES`), SavedVariables and `/dj` |
| `Tooltips.lua` | Item display, tooltips, item cache polling, shift-click chat links |
| `UI.lua` | The window: home tabs, era filter, cover cards, instance tabs, Bot Consumables page, Escape handling |
| `Data/Vanilla.lua` | `SDJ.ORDER.Vanilla` (browser order) |
| `Data/Vanilla/*.lua` | One file per instance, raid or world boss |
| `Data/TBC.lua`, `Data/Wrath.lua` | Cover-card stubs |
| `Maps/`, `Portraits/`, `Media/` | Bundled art |
| `tools/` | Offline harness, denylist, 3.3.5 listfile, build script |
| `docs/` | Player and maintainer documentation |

## Completed milestones

| Phase | Version | Date | What it delivered | Evidence |
| --- | --- | --- | --- | --- |
| Skeleton | v0.2.1-WIP | 2026-09-28 | First public test build: Vanilla / TBC / Wrath categories, Trash / Bosses / Quests / Preparation / Map sections, `/dj`. Pre-release removed 14 October 2026. | GitHub pre-release |
| Vanilla batch 1 | v0.3.1 | 2026-09-27 | Ragefire Chasm in full; 3.3.5a fixes (background texture, static portraits, bundled Atlas map, uncached items, shift-click links) | harness |
| Vanilla batches 2-8 | v0.3.2 - v0.3.8 | 2026-09-27 | Deadmines through Upper Blackrock Spire. v0.3.7 switched all data to the Grimfeather forks and added the layout check and listfile texture check | harness |
| Final Vanilla dungeons | v0.4.0 | 2026-10-05 | Scholomance, Stratholme Living and Undead | harness |
| Rename | v0.4.1 | 2026-10-05 | ServerDungeonJournal became Dungeon Journal; SavedVariables migration | harness |
| Bot Consumables | v0.4.2 | 2026-10-05 | Help page on the home screen and a Bot Consumables block in each Preparation tab | harness |
| Raids | v0.5.0 - v0.5.4 | 2026-10-05 | Raid framework, MC, Onyxia, ZG, home section tabs and world bosses (v0.5.2), BWL, AQ20, AQ40 | harness |
| Vanilla complete | v0.6.0 | 2026-10-05 | Naxxramas 40; Vanilla consistency pass | Released |
| Onyxia cover | v0.6.1 | 2026-10-06 | Onyxia loading-screen TGA; version message fix; continent cover guard | Released |
| Bot Consumables update | v0.6.2 | 2026-10-14 | Help page moved below the tab row; consumables text rechecked against `BotRaidConsumables.cpp`; docs, roadmap and tools added to the repo | Released, automated-test only |

Per-version detail is in [CHANGELOG.md](CHANGELOG.md).

## Next validation task

| Field | Information |
| --- | --- |
| Task | In-game check of v0.6.2 on the server: open the Bot Consumables page and three instance pages from each home tab, and confirm nothing draws under the tab row |
| Why | The overlap fix is automated-test only. The harness models anchors, not the client's tab textures |
| Files | `UI.lua` (`SDJ:ShowBotConsumablesHelp`, `SDJ:OpenDungeon`, `SDJ:ShowHome`) |
| Acceptance | Page title fully visible; tab row hidden while the page is open; Back returns to the home tab you came from |
| Tests | Manual checks M01-M08 in [docs/TESTING.md](docs/TESTING.md) |
| Blocking question | None |
| Rollback | Install the v0.6.1 release zip |

## P1 - Vanilla polish

**Status:** Proposed (no release date set).

- [ ] **Search.** There is no search today. A text box on the home page that filters cards by instance, boss and item name across the selected section and era. 3.3.5a has no built-in search widget, so this is an EditBox plus a filter over `SDJ.DUNGEONS`.
- [ ] **Favourites.** No favourites today. Mark instances, bosses or items and keep them in `DungeonJournalDB` (additive keys only, so older saves still load).
- [ ] **Remember the last tab.** On close, `ResetOnClose` sets the section to Dungeons and the era to Vanilla and overwrites `DungeonJournalDB.lastEra`, so the saved era never survives a close. Decide whether that is wanted; if not, keep the last section and era.
- [ ] **Unsourced MC note.** `Data/Vanilla/MoltenCore.lua:150` says the packs near Magmadar "may revive". Check against the AzerothCore Molten Core scripts and either cite the script or drop the hedge.
- [ ] **Bot Consumables raid profiles.** `BotRaidConsumables.cpp` only has `mc` for raids. If the server adds profiles for Onyxia, BWL, ZG, AQ20, AQ40, Naxxramas or world bosses, update `SDJ.BOT_CONSUMABLES` in `Core.lua` and the help page, with file:line references to the module.
- [ ] **Bot Consumables recheck on module updates.** The text was checked against Mod-Naxxramas-Core commit `69a91be` and N-MultiBot-Chatless commit `7bc9baa`. Recheck when either changes `BotRaidConsumables.cpp` or `MultiBotConsumablesUI.lua`.
- [ ] **In-game pass over all 39 Vanilla entries.** Nothing has been recorded as in-game tested per entry. Record results in [docs/TESTING.md](docs/TESTING.md).
- [ ] **CI.** Run `tools/build.sh --no-zip` in a GitHub Actions workflow on pull requests, as Individual-Progression-Companion does with its Lua 5.1 workflow.

**Acceptance:** each item lands with a CHANGELOG entry, the harness passing, and an in-game note where it changes the UI.

## P2 - The Burning Crusade

**Status:** Deferred / later.

Cover cards exist for 16 dungeons in `Data/TBC.lua`: Hellfire Ramparts, The Blood Furnace, The Shattered Halls, The Slave Pens, The Underbog, The Steamvault, Mana-Tombs, Auchenai Crypts, Sethekk Halls, Shadow Labyrinth, Old Hillsbrad Foothills, The Black Morass, The Mechanar, The Botanica, The Arcatraz, Magisters' Terrace. Opening one shows the empty-state messages ("Boss data for this dungeon has not been populated yet." and so on).

- [ ] One data file per dungeon under `Data/TBC/`, same fields as Vanilla
- [ ] TBC raids (none listed yet)
- [ ] TBC world bosses (none listed yet)
- [ ] Individual Progression TBC gates and attunements from the Grimfeather IP fork
- [ ] Maps and portraits, with the same art rules

## P3 - Wrath of the Lich King

**Status:** Deferred / later.

Cover cards exist for 16 dungeons in `Data/Wrath.lua`, Utgarde Keep through Halls of Reflection. Same work list as TBC.

- [ ] One data file per dungeon under `Data/Wrath/`
- [ ] Wrath raids and world bosses
- [ ] Note where Wrath Naxxramas (map 533) differs from the Vanilla Naxxramas 40 page, which already uses that map id

## Testing and rollback

- Offline: `tools/build.sh --no-zip` (luac, denylist, harness). See [tools/README.md](tools/README.md).
- In game: [docs/TESTING.md](docs/TESTING.md).
- Players: back up `Interface\AddOns\DungeonJournal` and `WTF\Account\<account>\SavedVariables\DungeonJournal.lua` before upgrading. Roll back by reinstalling the previous release zip.

## Known limitations

- Every Vanilla entry is automated-test only unless noted.
- Item names, icons and quality are stored in the data files; the client replaces them with cached item info when it has it. An item ID that does not exist on the server shows the stored text only.
- AtlasLoot drop rates are kept where the server has no rate; the server's own loot tables are used where they exist (see [docs/DATA-SOURCES.md](docs/DATA-SOURCES.md)).
- The 3.3.5 listfile in `tools/` comes from the client UI source tree. A path being in it does not prove the client can load it; the continent loading screens were in it and still rendered green.

## Releases

See [docs/RELEASE-CHECKLIST.md](docs/RELEASE-CHECKLIST.md). Tags are `vX.Y.Z`, annotated. A published tag or asset is not replaced in place except with explicit owner approval (this happened once, for v0.6.1).

## Keeping the documentation current

- [ ] ROADMAP.md matches the code and version
- [ ] CHANGELOG.md has an entry for the change
- [ ] Harness passes; in-game results recorded if the UI changed
- [ ] Next task above rewritten if it is done
- [ ] Docs do not contradict the roadmap
