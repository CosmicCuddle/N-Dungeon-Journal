# Art and Texture Rules

**Applies to:** v0.6.2
**Checked by:** `tools/harness.lua` (cover-art and listfile checks) and `tools/denylist.sh` (continent loading-screen rule)

The 3.3.5a client is picky about textures, and `SetTexture` returning true does not mean the texture will draw. A path that fails silently shows as a solid green box. These rules come from bugs that actually shipped.

## Bundled TGA files

- **Uncompressed, 32-bit** (TGA image type 2, 32 bits per pixel, with alpha). RLE-compressed TGAs are not used.
- **Power-of-two sides.** 64, 128, 256, 512, 1024. Non-square is fine (the Onyxia cover is 1024x512).
- At v0.6.2 all 348 bundled TGAs meet this: 332 portraits (128x128), 8 map TGAs (512x512), 7 UI pieces in `Media/` and the Onyxia cover (1024x512).
- The harness checks every bundled cover (`art` pointing into the addon folder): the file must exist and be uncompressed 32-bit with power-of-two sides. Portraits and maps are not checked by the harness yet, so check them yourself when adding new ones (see below).

Quick check with Python and Pillow:

```bash
python3 -c "
import glob
for f in glob.glob('**/*.tga', recursive=True):
    h = open(f, 'rb').read(18)
    w, ht = h[12] | h[13] << 8, h[14] | h[15] << 8
    ok = h[2] == 2 and h[16] == 32 and w & (w - 1) == 0 and ht & (ht - 1) == 0
    print('ok ' if ok else 'BAD', f, w, ht, 'type', h[2], 'bpp', h[16])
" | grep BAD
```

## Cover art

Each card uses `art`, then `artFallback`, then a book icon (`ApplyDungeonArt` in `UI.lua`).

- Use the instance's own loading screen when the client has one, for example `Interface\GLUES\LOADINGSCREENS\LoadScreenMoltenCore`.
- **Do not use the generic continent loading screens** as covers: `LoadScreenKalimdor`, `LoadScreenEasternKingdom`, `LoadScreenNorthrend`, `LoadScreenOutland`, `LoadScreenAzeroth` and the `Wide` variants. They are in the UI source listfile but rendered solid green on the client, and because `SetTexture` still returned true the fallback never ran. That is what happened to the Onyxia's Lair card before v0.6.1. The denylist and the harness both fail on these paths.
- If the client has no loading screen for an instance, bundle one as a TGA under `Media/Covers/` (as v0.6.1 did for Onyxia's Lair), or use the bundled map, as Jintha'Alor and the world bosses do.
- Set `artFallback` to the bundled map so a broken cover still shows something.
- `crop` is `{left, right, top, bottom}` in tex coords. The default for loading screens is `{0.04, 0.96, 0.29, 0.73}`.

## Client texture paths

Every client path the addon sets is checked against `tools/listfile_335.txt` (from the s0h2x/WoTLK-3.3.5-UI-Source file tree, blp branch). Paths that only exist in later clients fail the harness. Being in the listfile is necessary but not enough, as the continent loading screens showed.

The denylist also blocks later-client `Interface\WorldMap\<zone>\<tile>` paths and retail-only texture APIs such as `SetColorTexture` and `SetAtlas`.

## Maps

- Atlas BLPs are copied unmodified into `Maps/`, are 512x512 and use the whole texture (`coords = {0, 1, 0, 1}`).
- Maps that Atlas does not have (Jintha'Alor, the world bosses) are bundled as 512x512 TGAs following the TGA rules above, with the source in the `credit` line and CREDITS.txt.

## Portraits

128x128 uncompressed 32-bit TGA in `Portraits/`, named after the boss without spaces or punctuation (for example `TaragamanTheHungerer.tga`). If a portrait is missing the boss page shows a framed "?" and the harness prints `PORTRAIT FALLBACK` for it.
