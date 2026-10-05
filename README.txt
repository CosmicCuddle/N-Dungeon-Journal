Dungeon Journal - v0.4.2 (rename + Vanilla complete through Stratholme)
======================================================================

Install
1. Exit WoW completely.
2. Delete ANY old Interface\AddOns\ServerDungeonJournal folder (do not merge; both must not load).
3. Extract this zip into Interface\AddOns (it contains the DungeonJournal folder).
4. Enable "Dungeon Journal" on the character screen and type /dj in game.

SavedVariables
- New: DungeonJournalDB
- On first load, settings are copied once from ServerDungeonJournalDB if present
  (lastEra and any other keys). Delete the old ServerDungeonJournal folder after installing.

Slash commands (unchanged): /dj  /dungeonjournal

Layout
DungeonJournal.toc             Interface 30300, SavedVariables: DungeonJournalDB
Core.lua                       Addon table DungeonJournal, frame DungeonJournalFrame
Tooltips.lua
UI.lua
Data\Vanilla.lua               Vanilla browser order (all Vanilla dungeons populated)
Data\Vanilla\*.lua             Per-dungeon data (batches 1-9)
Data\TBC.lua / Data\Wrath.lua  Placeholders (unchanged)
Maps\ / Portraits\ / Media\

v0.4.0 content (Batch 9) is included: Scholomance, Stratholme Living, Stratholme Undead.
Vanilla dungeon set is complete. TBC and Wrath are unchanged.

Bot Consumables: home button + Preparation sections (v0.4.2).
