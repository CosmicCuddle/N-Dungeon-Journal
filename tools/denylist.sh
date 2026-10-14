#!/bin/bash
# Grep for retail-only / non-3.3.5 APIs and unsafe texture paths (code lines only, comments ignored).
dir="${1:-.}"
pat='BackdropTemplate|\bC_[A-Z][A-Za-z]+\.|\bMixin\(|CreateFromMixins|SetColorTexture|SetAtlas|C_Timer|ScrollBox|ScrollUtil|\bEJ_[A-Za-z]+|GetItemInfoInstant|SetGradientAlpha|CreateColor\(|WrapTextInColorCode|SetShown\(|SetObeyStepOnDrag|RegisterUnitEvent|\bEnum\.|SetResizeBounds|GET_ITEM_INFO_RECEIVED|FrameGeneral|Interface\\\\WorldMap\\\\[A-Za-z]+\\\\[A-Za-z]+[0-9]_|SetDisplayInfo|"PlayerModel"|SetCreature|SetPortraitZoom|SetBackdrop\([^)]*,[^)]*Template'
out=$(rg -n --no-heading -e "$pat" "$dir" -g '*.lua' -g '*.xml' -g '*.toc' | grep -v -E '^[^:]+:[0-9]+:\s*--' | grep -v -E -- '--.*('"$pat"')' )
if [ -n "$out" ]; then echo "$out"; exit 1; else echo "denylist: clean"; fi

# v0.6.1: generic continent / glue loadscreens must not be used as cover art.
# They can appear in the 3.3.5 listfile (UI source tree) but fail to load on
# clients — SetTexture still returns true, so artFallback never runs (green card).
cover_pat='LoadScreenKalimdor|LoadScreenEasternKingdom|LoadScreenNorthrend|LoadScreenOutland|LoadScreenAzeroth|LoadScreenKalimdorWide|LoadScreenEasternKingdomWide'
cover_out=$(rg -n --no-heading -e "$cover_pat" "$dir" -g '*.lua' | grep -v -E '^[^:]+:[0-9]+:\s*--' || true)
if [ -n "$cover_out" ]; then
  echo "denylist: generic continent/glue loadscreen used as cover art:"
  echo "$cover_out"
  exit 1
fi
echo "denylist: continent cover-art check clean"
