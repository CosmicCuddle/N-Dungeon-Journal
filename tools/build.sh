#!/bin/bash
# Stage the addon, run the checks, and build the release zip.
#
#   tools/build.sh              stage + luac + denylist + harness + zip
#   tools/build.sh --no-zip     stage + checks only
#
# Only the files in SHIP below go into the zip. docs/, tools/, ROADMAP.md,
# CHANGELOG.md and README.md stay in the repository.
set -euo pipefail
cd "$(dirname "$0")/.."
ROOT=$(pwd)
STAGE="$ROOT/build/DungeonJournal"
VERSION=$(sed -n 's/^## Version: *//p' DungeonJournal.toc | tr -d '\r')
ZIP="$ROOT/dist/DungeonJournal_v${VERSION}.zip"

SHIP="DungeonJournal.toc Core.lua Tooltips.lua UI.lua Data Maps Media Portraits README.txt CREDITS.txt LICENSE-GPL-2.0.txt"

rm -rf "$ROOT/build"; mkdir -p "$STAGE"
for f in $SHIP; do cp -r "$f" "$STAGE/"; done
echo "staged $STAGE (v$VERSION)"

fail=0
while IFS= read -r f; do luac -p "$f" || fail=1; done < <(find "$STAGE" -name '*.lua')
[ $fail -eq 0 ] || { echo "luac: FAILED"; exit 1; }
echo "luac: ok"

bash tools/denylist.sh "$STAGE"
lua tools/harness.lua "$STAGE" > "$ROOT/build/harness.log" 2>&1 || { tail -20 "$ROOT/build/harness.log"; echo "harness: FAILED"; exit 1; }
grep -E 'VERSION CHECK|LAYOUT CHECKS|TAB-ROW CHECKS|LISTFILE|HARNESS OK' "$ROOT/build/harness.log" | sort -u

[ "${1:-}" = "--no-zip" ] && exit 0

mkdir -p "$ROOT/dist"; rm -f "$ZIP"
(cd "$ROOT/build" && zip -r -q "$ZIP" DungeonJournal)
tops=$(unzip -Z1 "$ZIP" | cut -d/ -f1 | sort -u)
[ "$tops" = "DungeonJournal" ] || { echo "zip: unexpected top-level entries: $tops"; exit 1; }
if unzip -Z1 "$ZIP" | grep -E '^DungeonJournal/(docs|tools|\.git)/|ROADMAP\.md|CHANGELOG\.md' ; then echo "zip: repo-only files leaked"; exit 1; fi
echo "zip: $ZIP ($(unzip -Z1 "$ZIP" | grep -vc '/$') files, DungeonJournal/ only)"
