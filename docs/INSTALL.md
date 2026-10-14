# Install, Upgrade and Removal

**Applies to:** v0.6.2
**Client:** WoW 3.3.5a (Interface 30300)

## Install

1. Download `DungeonJournal_v<version>.zip` from the [latest release](https://github.com/CosmicCuddle/N-Dungeon-Journal/releases/latest). Do not use **Code → Download ZIP** (see below).
2. Exit WoW completely.
3. Extract the zip into `World of Warcraft\Interface\AddOns\`.
4. Check the path: `Interface\AddOns\DungeonJournal\DungeonJournal.toc`. If you get `DungeonJournal\DungeonJournal\...`, move the inner folder up one level.
5. Start WoW. On the character screen open **AddOns** and make sure **Dungeon Journal** is enabled.
6. In game, type `/dj`. The chat line `Dungeon Journal v<version> loaded. Type /dj to open.` confirms which version is running.

## Upgrade

1. Exit WoW.
2. Back up `Interface\AddOns\DungeonJournal\` and `WTF\Account\<account>\SavedVariables\DungeonJournal.lua` somewhere outside the AddOns folder.
3. **Delete** the old `Interface\AddOns\DungeonJournal\` folder. Do not extract on top of it: files removed in the new version would stay behind.
4. Extract the new zip as in Install.

Settings carry over; they are in `DungeonJournalDB`, which is not inside the addon folder.

## Removing the old ServerDungeonJournal

Before v0.4.1 the addon was called ServerDungeonJournal.

1. Exit WoW.
2. Delete `Interface\AddOns\ServerDungeonJournal\`. Do not keep both installed.
3. Install Dungeon Journal as above.

On first load Dungeon Journal copies any values from the old `ServerDungeonJournalDB` that it does not already have into `DungeonJournalDB`, once, and sets `_migratedFromServerDungeonJournalDB`. The old SavedVariables file `WTF\Account\<account>\SavedVariables\ServerDungeonJournal.lua` can be deleted afterwards.

## Code → Download ZIP

GitHub's **Code → Download ZIP** gives a folder called `N-Dungeon-Journal-main`. WoW only loads an addon whose folder name matches its `.toc`, so it will not load. It also contains `docs/` and `tools/`, which the release zip does not. Use the release zip. If you must use the source download, rename the folder to `DungeonJournal`; the extra folders are ignored by the client.

## N-Addon-Collection

[N-Addon-Collection](https://github.com/CosmicCuddle/N-Addon-Collection) also packages Dungeon Journal, pinned to a specific release in its `sources.lock.json` (v0.6.1 at the time of writing). Install it from one place only, not both.

## Rollback

Exit WoW, delete `Interface\AddOns\DungeonJournal\`, and extract the previous release zip from the [Releases page](https://github.com/CosmicCuddle/N-Dungeon-Journal/releases). Restore your SavedVariables backup if needed.
