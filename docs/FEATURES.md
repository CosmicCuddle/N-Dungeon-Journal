# Features and Controls

Dungeon Journal puts Vanilla dungeon and raid information into a single movable in-game window. Open it with `/dj` or `/dungeonjournal`, choose a section and expansion, then select the entry to read.

**Applies to:** v0.6.2  
**Source files:** `UI.lua`, `Core.lua`, `Tooltips.lua`

## Quick reference

- Use **Dungeons**, **Raids** and **World Bosses** to switch between entry types.
- The **Vanilla** section contains the completed guides; TBC and Wrath currently provide dungeon cover cards.
- Open any populated entry to read Trash, Bosses, Quests, Preparation and Map information.
- Use the **Back** button to return to the section you came from. Closing the journal resets its starting view.

## Browsing from the home screen

### Section tabs

Across the top: **DUNGEONS | RAIDS | WORLD BOSSES**. Each tab filters the cards by the entry's `tag`:

| Tab | Shows entries where |
| --- | --- |
| Dungeons | `tag` is neither `Raid` nor `World Boss` (this includes `Outdoor Dungeon`, used by Jintha'Alor) |
| Raids | `tag = "Raid"` or `raid = true` |
| World Bosses | `tag = "World Boss"` or `worldBoss = true` |

The page title follows the tab: "Browse Dungeons", "Browse Raids" or "Browse World Bosses".

### Era filter

Under the section tabs are three expansion tabs: **Vanilla**, **The Burning Crusade** and **Wrath of the Lich King**. They filter by the era each entry was registered under (`SDJ:AddDungeon("Vanilla", ...)` and so on). At v0.6.2, TBC and Wrath only have dungeon cover cards, so their Raids and World Bosses tabs are empty.

### Cover cards

Two cards per row, in the order set by `SDJ.ORDER.Vanilla` in `Data/Vanilla.lua` (Ragefire Chasm first, then by level, then the raids in Individual Progression order, then the world bosses). Each card shows:

- the cover art (see [ART-AND-TEXTURES.md](ART-AND-TEXTURES.md) for how it falls back);
- the name;
- `LV <level>  |  <location>`, plus `|  <players>-PLAYER` for raids;
- a badge: `40-PLAYER` / `20-PLAYER` for raids, `WORLD` for world bosses, `OUTDOOR` for Jintha'Alor;
- a quest count for your faction, with the faction icon, if the entry has quests for it.

### Bot Consumables button

Top right of the home page. Opens the Bot Consumables page, described in [BOT-CONSUMABLES.md](BOT-CONSUMABLES.md). While that page is open the section tabs are hidden and a Back button takes their place, the same way instance pages work.

## Inside an entry

Click a card to open it. The header shows the name, `LV <level>  |  <location>` and, where it applies, `OUTDOOR DUNGEON`, `WORLD BOSS` or `40-PLAYER RAID`. Five dungeons also show a recommended level per role from `roleLevels` (for example The Deadmines: DPS 16 / Healer 18 / Tank 18).

The Back button (top left) is labelled with the section you came from (Dungeons, Raids or World Bosses) and returns to it. The section tabs are hidden while an instance is open.

The five tabs on the right of the header are **TRASH, BOSSES, QUESTS, PREPARATION, MAP**.

### Trash

- **Dangerous Trash** (left): each mob with its level, a priority (HIGH, MEDIUM or LOW), its abilities with spell icons and tags (AOE, FLEE, DEBUFF, SUMMON, HEAL, STUN and so on) and a short note.
- **Trash Loot** (right): notable trash drops with a DROP column. Rows without a sourced rate leave the column blank. If there is none: "No dungeon-specific trash loot recorded."

### Bosses

- Left: the boss list in kill order. Rare spawns are flagged **RARE**, optional bosses **Optional**.
- Right: portrait (a framed "?" if the file is missing), name, `<subname>` and level, then three blocks: **WHO THEY ARE**, **ABILITIES** and **KEY MECHANICS**.
- Below: **Full Loot Table** with the DROP column. Item rows use the client's cached item name, quality and icon when available; until then they show the stored name and icon and ask the server for the item.

Hover an item for its tooltip. Shift-click puts the item link in chat. If the item is not cached yet, the journal requests it and prints "item not cached yet, shift-click again in a moment."

### Quests

- Left: quests for one faction at a time. The Alliance and Horde buttons at the top switch it. It starts on your own faction. Quests open to both factions show "BOTH FACTIONS".
- Right: the quest page with any of these blocks the data has: quest ID, level and minimum level, **QUEST GIVER**, **QUEST START**, **PREREQUISITES**, **OBJECTIVE**, **REQUIRED ITEMS** (with where to get them), **WHERE**, **TURN IN**, **FOLLOW-UP**, **REWARDS** (money, reputation, items, choice items) and **SERVER NOTES**.
- **Quest Chain** button: expands the chain for that quest, with the current quest marked "(this quest)".

### Preparation

One scrolling page. Each `preparation` block from the data file is shown under its title (level, keys and attunements, resistances, server rules and so on). A **Bot Consumables** block is always added at the end with the matching `.bot consumables` command for that instance. Instances without a named profile get the generic `.bot consumables <1-54>` text. See [BOT-CONSUMABLES.md](BOT-CONSUMABLES.md).

### Map

Atlas map on the left (512x512), with the **Legend** on the right. Instances with more than one map page get **Prev / Next** buttons and a page counter (for example Naxxramas has five pages). The map credit line sits under the map. Entries without a map show "No map has been bundled for this dungeon yet."

## Content not added yet

Entries without data in a tab show a plain message instead of an empty panel, for example "Boss data for this dungeon has not been populated yet." Every TBC and Wrath card shows these at v0.6.2.

## Saved settings

`DungeonJournalDB`, one per account. It holds `lastEra` and the one-time migration flag `_migratedFromServerDungeonJournalDB`. Nothing else is saved at v0.6.2.

## Related guides

For installation help, see [Installation and Upgrades](INSTALL.md). For the commands described by Bot Consumables, see [Bot Consumables](BOT-CONSUMABLES.md).
