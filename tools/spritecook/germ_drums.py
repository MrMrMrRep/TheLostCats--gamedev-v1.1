#!/usr/bin/env python3
"""Germ's instrument clip with one drum kit throughout (rows 1-3 of
assets/sprites/characters/drums_germ/drums_germ_sheet.png). The old clip
changed kits from frame to frame (a keyboard, a red, a teal and an orange
kit, and loop frames with no kit at all).

Sources (tools/spritecook/germ_src/, SpriteCook asset ids in spritecook-assets.json):
  kit_a.png       Germ behind a solid red kit (a SpriteCook edit of the old loop frame)
  loop_sheet.png  8 frames animated from kit_a by SpriteCook (92 px cells; the
                  kit stands still, only his arms, sticks and head move)
  old_rows.png    the old rows 1-3: his standing poses and the sparkles of the
                  kit popping in and out

  idle_instrument_in   stand, sticks up, sparkles, the kit pops in, he starts
  idle_instrument_loop the animated loop
  idle_instrument_out  the kit pops away in sparkles, he stands, breathes

    python3 -I tools/spritecook/germ_drums.py
"""
import pathlib

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
SRC = ROOT / "tools/spritecook/germ_src"
SHEET = ROOT / "assets/sprites/characters/drums_germ/drums_germ_sheet.png"
CELL = 96
LOOP_AT = (3, 3)                            # where a 92 px loop frame sits in the 96 px cell (kit on kit_a's)


def old(row, col):
    """A frame of the old rows (row 0 = the old in, 1 = loop, 2 = out)."""
    return Image.open(SRC / "old_rows.png").convert("RGBA").crop((col * CELL, row * CELL, col * CELL + CELL, row * CELL + CELL))


def loop(i):
    strip = Image.open(SRC / "loop_sheet.png").convert("RGBA")
    f = strip.crop((i * 92, 0, i * 92 + 92, 92))
    cell = Image.new("RGBA", (CELL, CELL))
    cell.alpha_composite(f, LOOP_AT)
    return cell


def sparkles(frame, plain):
    """The gold sparkles of `frame`: its yellow pixels that `plain` (the same
    pose without them) doesn't have."""
    a = np.array(frame).astype(int)
    b = np.array(plain).astype(int)
    r, g, bl, al = a[..., 0], a[..., 1], a[..., 2], a[..., 3]
    gold = (al > 0) & (r > 170) & (g > 120) & (bl < 120) & (r - bl > 90)
    new = gold & ((b[..., 3] == 0) | (np.abs(a[..., :3] - b[..., :3]).sum(2) > 60))
    out = np.zeros_like(a)
    out[new] = a[new]
    return Image.fromarray(out.astype("uint8"), "RGBA")


def over(base, top):
    out = base.copy()
    out.alpha_composite(top)
    return out


def main():
    stand = old(2, 5)                        # standing, breathing
    sticks = old(1, 0)                       # standing, sticks up
    big = sparkles(old(2, 3), stand)
    small = sparkles(old(2, 4), stand)
    first = loop(0)
    rows = [
        [old(0, 0), stand, sticks, over(sticks, small), over(sticks, big), over(first, big), over(first, small), first],
        [loop(i) for i in range(8)],
        [first, over(first, small), over(first, big), over(stand, big), over(stand, small), stand, old(2, 6), old(2, 7)],
    ]
    sheet = Image.open(SHEET).convert("RGBA")
    for r, frames in enumerate(rows):
        for c, f in enumerate(frames):
            sheet.paste(Image.new("RGBA", (CELL, CELL)), (c * CELL, (r + 1) * CELL))
            sheet.paste(f, (c * CELL, (r + 1) * CELL))
    sheet.save(SHEET)


if __name__ == "__main__":
    main()
