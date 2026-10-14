# Dungeon Journal - Test Plan

**Baseline:** v0.6.2, WoW 3.3.5a
**Last in-game test outcome:** Not yet run under this document (14 October 2026)
**Purpose:** checks to run before a release, in addition to the offline harness

## Offline checks (every change)

```bash
tools/build.sh --no-zip
```

Must end with `HARNESS OK`, `LAYOUT CHECKS: ... overflows: 0` and `CLIENT TEXTURES CHECKED AGAINST 3.3.5 LISTFILE, missing: 0`. See [tools/README.md](../tools/README.md).

## Preparation for in-game tests

1. Back up `Interface\AddOns\DungeonJournal\` and `WTF\Account\<account>\SavedVariables\DungeonJournal.lua`.
2. Record the client resolution, UI scale and the version on the login chat line.
3. Use an ordinary character; nothing here needs GM commands.
4. Mark anything you could not check as **Not tested**.

## Manual checks

| ID | Test | Expected result |
| --- | --- | --- |
| M01 | Log in | `Dungeon Journal v0.6.2 loaded` in chat, no Lua errors |
| M02 | `/dj`, then `/dj` again; `/dungeonjournal` | Opens and closes |
| M03 | Press Escape with the journal open | Journal closes; Escape with it closed opens the game menu as usual |
| M04 | Click DUNGEONS, RAIDS, WORLD BOSSES; then Vanilla, TBC, Wrath | Cards change; title follows the tab; TBC and Wrath Raids / World Bosses are empty |
| M05 | Click **Bot Consumables** on the home page | Page title and subtitle fully visible; the tab row is hidden; only the Back button shows; text scrolls to the end |
| M06 | Back from the Bot Consumables page | Home page with the tab row, on the same section |
| M07 | Open one card from each section | Tab row hidden, Back labelled Dungeons / Raids / World Bosses, nothing behind the header |
| M08 | Open Bot Consumables from the Raids tab, then Back | Returns to Raids |
| M09 | In an instance, go through TRASH, BOSSES, QUESTS, PREPARATION, MAP | No overlapping text; long panels scroll |
| M10 | Bosses: click each boss | Portrait or framed "?", abilities with icons, loot with DROP column |
| M11 | Hover and shift-click a loot item | Tooltip; link in chat (or the "not cached yet" message the first time) |
| M12 | Quests: switch Alliance / Horde, open a quest with a chain, click **Quest Chain** | Correct faction list; chain expands |
| M13 | Map: Naxxramas Prev / Next | Five pages, counter updates, legend changes |
| M14 | Check covers on all Vanilla cards | No green or blank cards |
| M15 | Close and reopen | Opens on Dungeons / Vanilla home |
| M16 | `/reload` | No errors; journal still works |

## Results

| Date | Version | Tester | Checks run | Result | Notes |
| --- | --- | --- | --- | --- | --- |
| | | | | | |
