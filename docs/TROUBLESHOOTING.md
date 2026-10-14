# Troubleshooting

**Applies to:** v0.6.2

## The addon does not show up or does not load

- Check the folder name and depth: it must be `Interface\AddOns\DungeonJournal\DungeonJournal.toc`. `N-Dungeon-Journal-main`, `DungeonJournal-0.6.2` or a doubled `DungeonJournal\DungeonJournal` will not load.
- On the character screen, **AddOns**: make sure **Dungeon Journal** is ticked. If it says **Out of date**, tick **Load out of date AddOns**, or check your client is 3.3.5a. The `.toc` says `## Interface: 30300`.
- Old `ServerDungeonJournal` still installed: delete it ([INSTALL.md](INSTALL.md)).
- No chat line `Dungeon Journal v... loaded` after login means the addon did not load. Turn on Lua errors (`/console scriptErrors 1`) and log in again to see why.

## `/dj` does nothing

Another addon may have taken `/dj`. Use `/dungeonjournal`.

## Green or blank cover art

A solid green card means the client could not draw the texture, even though `SetTexture` accepted the path.

- If it is one card, report which one. Before v0.6.1 this was the Onyxia's Lair card, which used a generic continent loading screen. The fix was a bundled TGA ([ART-AND-TEXTURES.md](ART-AND-TEXTURES.md)).
- If it is every card, the client's loading-screen textures are not loading. Check that the client is a clean 3.3.5a and that no patch MPQ replaces `Interface\GLUES\LOADINGSCREENS`.
- A bundled TGA that is RLE-compressed, not 32-bit or not power-of-two can also show green or white. The harness checks covers; check portraits and maps by hand.

A book icon instead of art means both `art` and `artFallback` failed.

## Items show as "Item 12345" or a question mark

The item is not in your client cache yet. The journal asks the server for it and refreshes when it arrives. Shift-click on an uncached item prints "item not cached yet, shift-click again in a moment." If an item never resolves, the ID may not exist on the server; report it with the instance and boss.

## Text overlapping the tabs on the Bot Consumables page

Fixed in v0.6.2. If you still see it, check the login chat line shows v0.6.2, then delete the addon folder and reinstall (an old `UI.lua` left behind by extracting on top of an old install will do this).

## Escape does not close the journal

The journal adds itself to `UISpecialFrames` every time it is shown. If another addon replaces that table while the journal is open, Escape can reach the game menu first; the journal also closes itself in that case. If it still stays open, note which other addons are loaded and report it.

## Reporting a problem

Open an issue on [N-Dungeon-Journal](https://github.com/CosmicCuddle/N-Dungeon-Journal/issues) with: the version from the login line, the instance and tab, a screenshot, and the Lua error text if there is one.
