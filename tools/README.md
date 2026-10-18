# Development Tools and Build Checks

The `tools/` directory contains the local verification and packaging utilities for Dungeon Journal. These files are kept in the source repository and are not included in the player download.



## Quick reference

- Run `tools/build.sh --no-zip` for checks without packaging.
- Run `tools/build.sh` to perform checks and create the release zip in `dist/`.
- The Lua harness simulates the supported WoW interface; it cannot confirm the final on-screen appearance.
- Verify interface changes in the game using the [test plan](../docs/TESTING.md).

## Required tools

Lua 5.1 (`lua` and `luac`), bash, ripgrep (`rg`), `zip` and `unzip`. On Debian or Ubuntu:

```bash
sudo apt-get install lua5.1 ripgrep zip unzip
```

## Running a build

From the repository root:

```bash
tools/build.sh --no-zip     # checks only
tools/build.sh              # checks, then the release zip in dist/
```

The checks run against the staged copy in `build/DungeonJournal/`, not the repository root. The harness lists every file in the folder it is given, and the denylist would flag the mock API names inside `harness.lua` itself.

To run them by hand on a staged folder:

```bash
for f in $(find build/DungeonJournal -name '*.lua'); do luac -p "$f"; done
bash tools/denylist.sh build/DungeonJournal
lua tools/harness.lua build/DungeonJournal
```

The harness takes about 15 seconds. The full log is written to `build/harness.log` by `build.sh`.

## What is checked

- Every entry in every era opens, and every tab (Trash, Bosses, Quests, Preparation, Map) renders. Every boss row, quest row, quest chain and map page is clicked.
- **Layout:** no text runs outside its panel unless it is inside a scroll frame whose height covers it; scrollbars show only when content overflows; the map credit does not overlap the map or legend.
- **Tab row (v0.6.2):** no page opened from home (Bot Consumables, instance pages) overlaps the DUNGEONS | RAIDS | WORLD BOSSES tab row, and a visible tab row never covers a page or the Back button. The Bot Consumables page hides the tabs, and Back brings them back.
- **3.3.5 API:** calling a widget method that does not exist on 3.3.5 raises an error.
- **Textures:** every client path must be in `listfile_335.txt`; continent loading screens fail; bundled cover TGAs must exist and be uncompressed 32-bit with power-of-two sides.
- **Escape:** the frame is registered once in `UISpecialFrames`, closes, and resets to the home page.
- **Version:** `SDJ.VERSION` must equal `EXPECT_VERSION` in `harness.lua`. Bump both, plus the `.toc`, when releasing.
- Bot Consumables help and Preparation text exist for each profile.

It ends with `HARNESS OK`, or stops at the first failed assert, or exits with a list of `LAYOUT OVERFLOW` lines.

## Limits of offline testing

It does not draw anything. It models anchors and font metrics, not the client's actual textures, so a pass is not an in-game test. Use [docs/TESTING.md](../docs/TESTING.md) for that.

## Optional preview output

`SDJ_DUMP=/path/out.txt lua tools/harness.lua build/DungeonJournal` also writes the Bot Consumables page's frame rectangles and help text to that file, for making a mock preview image. It changes nothing else.

## Related guides

Use the [Release Checklist](../docs/RELEASE-CHECKLIST.md) before publishing and the [Testing Guide](../docs/TESTING.md) for manual checks.
