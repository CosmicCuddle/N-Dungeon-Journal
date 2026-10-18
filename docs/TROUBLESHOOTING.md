# Troubleshooting

Most installation problems come from an incorrect addon folder, mixed old and new files, or a client texture that does not load. Work through the checks below before reporting a problem.

**Applies to:** v0.6.2

## Quick reference

- Confirm the client is WoW 3.3.5a and the addon folder is named `DungeonJournal`.
- Check that no earlier `ServerDungeonJournal` folder is also installed.
- Use `/console scriptErrors 1` to make Lua errors visible.
- Include the addon version, the affected entry and any error text when reporting a problem.

## Addon missing or not loading

- Check the folder name and depth: it must be `Interface\AddOns\DungeonJournal\DungeonJournal.toc`. `N-Dungeon-Journal-main`, `DungeonJournal-0.6.2` or a doubled `DungeonJournal\DungeonJournal` will not load.
- On the character screen, **AddOns**: make sure **Dungeon Journal** is ticked. If it says **Out of date**, tick **Load out of date AddOns**, or check your client is 3.3.5a. The `.toc` says `## Interface: 30300`.
- Old `ServerDungeonJournal` still installed: delete it ([INSTALL.md](INSTALL.md)).
- No chat line `Dungeon Journal v... loaded` after login means the addon did not load. Turn on Lua errors (`/console scriptErrors 1`) and log in again to see why.

## Slash command not responding

Another addon may have taken `/dj`. Use `/dungeonjournal`.

## Missing or green artwork

A solid green card means the client could not draw the texture, even though `SetTexture` accepted the path.

- If it is one card, report which one. Before v0.6.1 this was the Onyxia's Lair card, which used a generic continent loading screen. The fix was a bundled TGA ([ART-AND-TEXTURES.md](ART-AND-TEXTURES.md)).
- If it is every card, the client's loading-screen textures are not loading. Check that the client is a clean 3.3.5a and that no patch MPQ replaces `Interface\GLUES\LOADINGSCREENS`.
- A bundled TGA that is RLE-compressed, not 32-bit or not power-of-two can also show green or white. The harness checks covers; check portraits and maps by hand.

A book icon instead of art means both `art` and `artFallback` failed.

## Missing item names or icons

The item is not in your client cache yet. The journal asks the server for it and refreshes when it arrives. Shift-click on an uncached item prints "item not cached yet, shift-click again in a moment." If an item never resolves, the ID may not exist on the server; report it with the instance and boss.

## Bot Consumables page layout

Fixed in v0.6.2. If you still see it, check the login chat line shows v0.6.2, then delete the addon folder and reinstall (an old `UI.lua` left behind by extracting on top of an old install will do this).

## Escape key behaviour

The journal adds itself to `UISpecialFrames` every time it is shown. If another addon replaces that table while the journal is open, Escape can reach the game menu first; the journal also closes itself in that case. If it still stays open, note which other addons are loaded and report it.

## Reporting bugs

Open an issue on [N-Dungeon-Journal](https://github.com/CosmicCuddle/N-Dungeon-Journal/issues) with: the version from the login line, the instance and tab, a screenshot, and the Lua error text if there is one.

## Related guides

See [Installation and Upgrades](INSTALL.md) for a clean reinstall and [Artwork and Textures](ART-AND-TEXTURES.md) for texture requirements.
