#!/usr/bin/env python3
"""Lists hex colours in the world-map scripts that aren't from WorldPalette.

    python3 -I tools/check_palette.py          # report, exit 1 if any
    python3 -I tools/check_palette.py --fix    # replace each with its nearest palette colour

Looks at Color("rrggbb") / Color("rrggbbaa") literals in scripts/world/*.gd
(world_palette.gd itself is the palette). --fix writes WorldPalette.<name> for
the nearest of the 32 colours, using the same weighting as WorldPalette.nearest
and the in-game snap, so the map looks the same before and after the fix.
"""
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
PALETTE_FILE = ROOT / "scripts/world/world_palette.gd"
SCRIPTS = sorted((ROOT / "scripts/world").glob("*.gd"))
LITERAL = re.compile(r'Color\("#?([0-9a-fA-F]{6})([0-9a-fA-F]{2})?"\)')


def palette():
    out = {}
    for m in re.finditer(r'^const ([A-Z]\d) := Color\("([0-9a-fA-F]{6})"\)', PALETTE_FILE.read_text(), re.M):
        out[m.group(1)] = tuple(int(m.group(2)[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return out


def nearest(rgb, pal):
    best, bd = None, 1e9
    for name, p in pal.items():
        d = ((rgb[0] - p[0]) * 0.30) ** 2 + ((rgb[1] - p[1]) * 0.59) ** 2 + ((rgb[2] - p[2]) * 0.11) ** 2
        if d < bd:
            best, bd = name, d
    return best


def main():
    fix = "--fix" in sys.argv
    pal = palette()
    hexes = {"%02x%02x%02x" % tuple(round(c * 255) for c in v) for v in pal.values()}
    found = 0
    for path in SCRIPTS:
        if path == PALETTE_FILE:
            continue
        text = path.read_text()

        def repl(m):
            nonlocal found
            hx = m.group(1).lower()
            rgb = tuple(int(hx[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
            name = nearest(rgb, pal)
            if hx not in hexes:
                found += 1
                if not fix:
                    line = text[:m.start()].count("\n") + 1
                    print(f"{path.relative_to(ROOT)}:{line}: #{hx} (nearest {name})")
            ref = f"WorldPalette.{name}"
            if m.group(2):
                return f"Color({ref}, {int(m.group(2), 16) / 255.0:.2f})"
            return ref

        new = LITERAL.sub(repl, text)
        if fix and new != text:
            path.write_text(new)
    if fix:
        print(f"replaced {found} off-palette literals (palette literals were renamed too)")
        return 0
    print(f"{found} colours outside the palette")
    return 1 if found else 0


if __name__ == "__main__":
    sys.exit(main())
