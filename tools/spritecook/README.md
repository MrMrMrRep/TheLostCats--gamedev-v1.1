# Refining the side openings with SpriteCook

The canal/street/alley views (SideOpening) are painted in code. A view can be
touched up with a SpriteCook edit and saved as
`assets/sprites/world/openings/<node name>.res`; SideOpening then draws that
instead of the painted art (same origin, so nothing moves).

Steps (Bridge 1 done 2026-10-26; SpriteCook asset ids in `spritecook-assets.json`):
1. `KIND=0 SLOT=290 OPEN=124 SEED=11 OUT=<dir> NAME=bridge1 Summer --headless --path . -s tools/spritecook/export_opening.gd`
   writes the full art and a 360x360 crop of the opening (sky filled #8ec5e6).
2. Upload the crop to SpriteCook and edit it (edit_asset_id, gemini-nano-banana-2.1,
   pixel, bg include, no smart crop, the 32 palette colours + #8ec5e6). Prompt: keep
   framing/perspective/near buildings, close the far end with a row of canal houses,
   gables and chimneys on the wall tops, plain sky.
3. Take the job's raw 1024 px image (finer than the pixel output) and run
   `FULL=... CAND=raw.jpg CROPX=.. CROPY=.. OPEN=248 FAR=110,110,250,262 MODE=smooth OUT=refined.png ... -s tools/spritecook/composite_opening.gd`:
   scaled to the crop, snapped to the palette, pasted only into the far end and the
   original's sky (the near walls and flank houses keep their pixels).
4. `KIND=.. SLOT=.. OPEN=.. SEED=.. PNG=refined.png NAME=Bridge1 ... -s tools/spritecook/save_refined_opening.gd`
