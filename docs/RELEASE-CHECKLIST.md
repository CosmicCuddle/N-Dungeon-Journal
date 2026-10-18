# Build and Release Checklist

This checklist keeps project versions, test results and downloadable packages consistent. Follow it for an addon release; a documentation-only change does not require a new client version or release asset.

**Applies from:** v0.6.2  
**Tag format:** `vX.Y.Z`, annotated  
**Asset name:** `DungeonJournal_vX.Y.Z.zip`, containing only `DungeonJournal/`  
**Release title format:** `Dungeon Journal vX.Y.Z – <short summary>`

## Quick reference

- Check that the version is the same in the addon metadata, code, readmes and test harness.
- Run the build script and review both offline and in-game results.
- Publish a zip containing only the `DungeonJournal/` addon directory.
- Treat changes to N-Addon-Collection as a separate update.

## Pre-release checks

- [ ] Version bumped in all five places: `DungeonJournal.toc` (`## Version`), `Core.lua` (`SDJ.VERSION`), `README.md`, `README.txt`, and `EXPECT_VERSION` in `tools/harness.lua`
- [ ] `CHANGELOG.md` has an entry for the version with the date
- [ ] `ROADMAP.md` updated: done-phase row, current state, next task
- [ ] `tools/build.sh` passes and writes `dist/DungeonJournal_vX.Y.Z.zip`
- [ ] Zip contains only `DungeonJournal/`, and no `docs/`, `tools/`, `ROADMAP.md` or `CHANGELOG.md` (`build.sh` checks this; also `unzip -l` it and look)
- [ ] In-game checks from [TESTING.md](TESTING.md) run where the release changes the UI, or the notes say it is automated-test only
- [ ] Commit messages describe the change in plain words

## Publishing to GitHub

```bash
git push origin main                 # fast-forward only; never --force on a branch
git tag -a vX.Y.Z -m "Dungeon Journal vX.Y.Z"
git push origin vX.Y.Z
gh release create vX.Y.Z dist/DungeonJournal_vX.Y.Z.zip \
  --title "Dungeon Journal vX.Y.Z – <summary>" --notes-file <notes.md> --latest
```

Release notes follow the earlier releases: a `## Changes` list, then `## Install` with the four steps (exit WoW; delete any old `ServerDungeonJournal`; extract so the path is `Interface\AddOns\DungeonJournal\DungeonJournal.toc`; restart and `/dj`).

## Post-release checks

- [ ] Release shows as **Latest**, asset downloads, and the zip opens to `DungeonJournal/`
- [ ] `gh release view vX.Y.Z` lists the asset with the expected size
- [ ] README "Current release" line points to the new version
- [ ] If N-Addon-Collection should pick it up, that is a separate import PR in that repository

## Release safeguards

- Replace a published asset or move a published tag as a shortcut. If a release is broken, publish a new patch version. (v0.6.1 was edited in place once, with explicit owner approval.)
- Force-push `main`.
- Attach a GitHub **Code → Download ZIP** archive as the release asset.

## Related guides

Read [Testing](TESTING.md) before publishing and [Developer Tools](../tools/README.md) for the build commands.
