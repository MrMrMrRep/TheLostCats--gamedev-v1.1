#!/usr/bin/env python3
"""The four rooms of the level "The International" (Hotel-Café International,
Warmoesstraat), painted with SpriteCook (2026-11-02, asset ids in
spritecook-assets.json, "intl_*"), cut into room backdrops.

    python3 -I tools/spritecook/international.py

Reads tools/spritecook/international_src/<room>.png (the raw 1376x768
paintings), writes assets/sprites/levels/international/<room>.png: the room's
back wall at 1 texel = half a world px (like the map's kit art), so 2 x ROOM_W
by 2 x 360 texels, with the painted floor (where the feet go) on the level's
floor line (world y 288). The stairwell is
mirrored so its landing is on the right (the band climbs left to right).
Colours are merged (SpriteCook leaves 1-step noise) and pure black becomes
the palette's navy.
"""
import pathlib

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
SRC = ROOT / "tools/spritecook/international_src"
OUT = ROOT / "assets/sprites/levels/international"
ROOM_W = 576 * 2                            # 24 tiles: every room of the level (texels)
ROOM_H = 360 * 2
FLOOR_Y = 288 * 2
NAVY = (0x1e, 0x24, 0x33)
COLOURS = 96
# room: (crop box in the raw painting, mirrored, raw y of the floor line inside the crop)
ROOMS = {
    "bar": ((0, 0, 1376, 768), False, 720),
    "stairs": ((0, 0, 1376, 768), True, 707),
    "corridor": ((0, 0, 1376, 768), False, 690),
    "attic": ((30, 30, 1346, 742), False, 672),
}


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    for name, (box, mirror, feet) in ROOMS.items():
        img = Image.open(SRC / (name + ".png")).convert("RGB").crop(box)
        if mirror:
            img = img.transpose(Image.Transpose.FLIP_LEFT_RIGHT)
        s = ROOM_W / img.width
        small = img.resize((ROOM_W, round(img.height * s)), Image.LANCZOS)
        top = round(FLOOR_Y - feet * s)     # where the painting's top edge goes
        canvas = Image.new("RGB", (ROOM_W, ROOM_H), NAVY)
        canvas.paste(small, (0, top))
        if top + small.height < ROOM_H:     # below the painting: its last row, darkened
            last = small.crop((0, small.height - 1, ROOM_W, small.height)).point(lambda v: v * 0.6)
            for y in range(top + small.height, ROOM_H):
                canvas.paste(last, (0, y))
        q = canvas.quantize(colors=COLOURS, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
        a = np.array(q)
        dark = (a[:, :, 0] < 20) & (a[:, :, 1] < 20) & (a[:, :, 2] < 28)
        a[dark] = NAVY
        Image.fromarray(a, "RGB").save(OUT / (name + ".png"))
        print(f"{name:9s} scale {s:.3f}  top {top:4d}  painted to y {top + small.height} (texels)")


if __name__ == "__main__":
    main()
