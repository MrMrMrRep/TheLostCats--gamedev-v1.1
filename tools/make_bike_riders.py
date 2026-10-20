"""Bike riding clips for Jay, Nikki, Germ and Geoff, built from Joep's (no new AI art):
Joep's bike_pedal / bike_roll frames (keys_joep sheet rows) with
  - the bike recoloured to the member's own bike (colour map from the parked bikes),
  - Joep's tee, arms, trousers and shoes recoloured to the member's clothes,
  - Joep's head swapped for the member's own head (from their idle frame).
Output: assets/sprites/vehicles/bike_ride_<member>.png, 8 columns x 2 rows (pedal, roll) of 96x96 cells,
wheels on row 95 like every band cell; the game adds them as bike_pedal / bike_roll (JTCBike).
Temp members (64x64 cells at 0.75) get their head scaled x1.5 to Joep's density.

usage (from the game folder): python3 tools/make_bike_riders.py
"""
import json, os
from collections import Counter
from PIL import Image

GAME = os.path.abspath(os.path.join(os.path.dirname(__file__), ".."))
CH = os.path.join(GAME, "assets/sprites/characters")
VEH = os.path.join(GAME, "assets/sprites/vehicles")
CELL = 96

JOEP_PAL = {  # palette_joep.json (asset repo)
    "outline": "#0e0c10", "pants": "#1c1a22", "pants_hi": "#3a3644", "hair_dark": "#2e1c18", "hair": "#4a2e24",
    "hair_mid": "#6e4a36", "hair_hi": "#93684c", "skin_hi": "#f4d0b0", "skin": "#e3b48e", "skin_mid": "#c48c6c",
    "skin_shadow": "#96604c", "shirt": "#f6fbff", "shirt_mid": "#dce9f5", "shirt_shade": "#b2c4d8",
    "shirt_dark": "#8794aa", "eye_white": "#ffffff", "pupil": "#2f6a2a", "pupil_dark": "#183a17",
    "shoe_grey": "#cdd5dc", "shoe_shadow": "#8e98a4"}


def rgb(h):
    return tuple(int(h[i:i + 2], 16) for i in (1, 3, 5))


J = {k: rgb(v) for k, v in JOEP_PAL.items()}
SHIRT = [J["shirt"], J["shirt_mid"], J["shirt_shade"], J["shirt_dark"]]
SKIN = [J["skin_hi"], J["skin"], J["skin_mid"], J["skin_shadow"]]
PANTS = [J["pants_hi"], J["pants"]]
SHOES = [J["shoe_grey"], J["shoe_shadow"]]
HEADC = {J[k] for k in ("hair_dark", "hair", "hair_mid", "hair_hi", "eye_white", "pupil", "pupil_dark")} | {rgb("#1f5a24")}

# Members: sheet, idle cell (x, y, size), clothes (light -> dark), how much to scale the head.
MEMBERS = {
    "jay": {"sheet": "bass_jay/bass_jay_sheet.png", "idle": (0, 0, 96), "head_scale": 1.0,
            "shirt": ["#47474e", "#2f2f35", "#1c1b20", "#0a0a0c"], "skin": ["#f4cba8", "#e8b48e", "#c88d70", "#95604a"],
            "pants": ["#8a875c", "#605e47"], "shoes": ["#2f2f35", "#1c1b20"]},
    # Temp art (64 px cells): head rows picked by hand, clothes from the sprite's own colours.
    "nikki": {"sheet": "_temp/guitar_nikki/guitar_nikki.png", "idle": (0, 0, 64), "head_scale": 1.5, "head_box": (23, 25, 39, 42),
              "shirt": ["#2d2f3b", "#1c1d24", "#0d0d11", "#0d0d11"], "skin": ["#ffcdb2", "#ffcdb2", "#f2a687", "#f2a687"],
              "pants": ["#1c1d24", "#0d0d11"], "shoes": ["#ffffff", "#2d2f3b"]},
    "germ": {"sheet": "_temp/drums_germ/drums_germ.png", "idle": (0, 0, 64), "head_scale": 1.5, "head_box": (23, 26, 39, 42),
             "shirt": ["#2d2f3b", "#1c1d24", "#0d0d11", "#0d0d11"], "skin": ["#ffcdb2", "#ffcdb2", "#f2a687", "#f2a687"],
             "pants": ["#1c1d24", "#0d0d11"], "shoes": ["#2d2f3b", "#0d0d11"]},
    "geoff": {"sheet": "_temp/singer_geoff/singer_geoff.png", "idle": (0, 0, 64), "head_scale": 1.5, "head_box": (24, 21, 40, 38),
              "shirt": ["#f5f7fa", "#d2d7df", "#b5bbc4", "#6e2053"], "skin": ["#ffcdb2", "#ffcdb2", "#f2a687", "#f2a687"],
              "pants": ["#d442a6", "#1a0d14"], "shoes": ["#de7d3a", "#180c12"]},
}


def joep_frames():
    sheet = Image.open(os.path.join(CH, "keys_joep/keys_joep_sheet.png")).convert("RGBA")
    meta = json.load(open(os.path.join(CH, "keys_joep/keys_joep.json")))
    out = {}
    for clip in ("bike_pedal", "bike_roll"):
        fr = sorted(k for k in meta["frames"] if k.startswith(clip + "_"))
        out[clip] = [sheet.crop((meta["frames"][k]["frame"]["x"], meta["frames"][k]["frame"]["y"],
                                 meta["frames"][k]["frame"]["x"] + CELL, meta["frames"][k]["frame"]["y"] + CELL)) for k in fr]
    return out


def bike_map(member):
    """Joep bike colour -> member bike colour, from the parked bikes (same pixels)."""
    a = Image.open(os.path.join(VEH, "bike_parked_joep.png")).convert("RGBA").load()
    bim = Image.open(os.path.join(VEH, f"bike_parked_{member}.png")).convert("RGBA")
    b = bim.load()
    votes = {}
    for y in range(bim.height):
        for x in range(bim.width):
            if a[x, y][3] > 128 and b[x, y][3] > 128:
                votes.setdefault(a[x, y][:3], Counter())[b[x, y][:3]] += 1
    return {k: v.most_common(1)[0][0] for k, v in votes.items()}


def bike_colours():
    im = Image.open(os.path.join(VEH, "bike_parked_joep.png")).convert("RGBA")
    return {p[:3] for p in im.getdata() if p[3] > 128}


def member_head(m):
    """The member's head (hair/cap down to the chin) from their idle frame, scaled to Joep's density."""
    x, y, s = m["idle"]
    im = Image.open(os.path.join(CH, m["sheet"])).convert("RGBA").crop((x, y, x + s, y + s))
    if "head_box" in m:                     # temp art: face and beard sit low on the body
        head = im.crop(m["head_box"])
        head = head.resize((round(head.width * m["head_scale"]), round(head.height * m["head_scale"])), Image.NEAREST)
        hb = head.getbbox()
        return head.crop((hb[0], 0, hb[2], head.height))
    if m["head_scale"] != 1.0:
        im = im.resize((round(s * m["head_scale"]), round(s * m["head_scale"])), Image.NEAREST)
    bb = im.getbbox()
    px = im.load()
    # the head ends where the shoulders start: the first row (from the top) much wider than the head
    top = bb[1]
    widths = []
    for yy in range(bb[1], bb[3]):
        xs = [xx for xx in range(im.width) if px[xx, yy][3] > 128]
        widths.append((yy, (max(xs) - min(xs) + 1) if xs else 0))
    head_w = max(w for yy, w in widths[: max(4, len(widths) // 5)])
    end = top + int(len(widths) * 0.34)
    for yy, w in widths[len(widths) // 6:]:
        if w > head_w * 1.45:
            end = yy
            break
    head = im.crop((0, top, im.width, end))
    hb = head.getbbox()
    return head.crop((hb[0], 0, hb[2], head.height))


def rank_map(src_list, dst_list):
    """Map Joep shades (light -> dark) onto the member's shades."""
    if not dst_list:
        return {}
    return {c: dst_list[min(i * len(dst_list) // len(src_list), len(dst_list) - 1)] for i, c in enumerate(src_list)}


def sample_clothes(m):
    """For temp members: guess shirt / skin / pants / shoe shades from their idle frame."""
    x, y, s = m["idle"]
    im = Image.open(os.path.join(CH, m["sheet"])).convert("RGBA").crop((x, y, x + s, y + s))
    bb = im.getbbox()
    px = im.load()
    h = bb[3] - bb[1]

    def band(f0, f1, narrow=False):
        c = Counter()
        cx = (bb[0] + bb[2]) // 2
        for yy in range(bb[1] + int(h * f0), bb[1] + int(h * f1)):
            for xx in range(bb[0], bb[2]):
                if narrow and abs(xx - cx) > (bb[2] - bb[0]) // 5:
                    continue
                p = px[xx, yy]
                if p[3] > 128 and sum(p[:3]) > 40:
                    c[p[:3]] += 1
        return c

    def shades(counter, n=4):
        cols = [c for c, _ in counter.most_common(n)]
        return sorted(cols, key=lambda c: -sum(c))
    skin_c = Counter({c: k for c, k in band(0.1, 0.9).items() if c[0] > c[2] + 40 and c[0] > 150})
    torso = Counter({c: k for c, k in band(0.42, 0.62, True).items() if c not in skin_c})
    legs = Counter({c: k for c, k in band(0.72, 0.9, True).items() if c not in skin_c})
    feet = Counter({c: k for c, k in band(0.92, 1.0).items() if c not in skin_c})
    return {"shirt": shades(torso), "skin": shades(skin_c), "pants": shades(legs, 2), "shoes": shades(feet, 2)}


def to_hex(c):
    return "#%02x%02x%02x" % c


def build(member, m, frames, bikecols):
    if "shirt" not in m:
        guess = sample_clothes(m)
        m.update({k: [to_hex(c) for c in v] for k, v in guess.items()})
    cmap = {}
    cmap.update(rank_map(SHIRT, [rgb(c) for c in m["shirt"]]))
    cmap.update(rank_map(SKIN, [rgb(c) for c in m["skin"]]))
    cmap.update(rank_map(PANTS, [rgb(c) for c in m["pants"]]))
    cmap.update(rank_map(SHOES, [rgb(c) for c in m["shoes"]]))
    cmap[J["eye_white"]] = rgb(m["shirt"][0])  # below the head, white is the tee's highlight
    bmap = bike_map(member)
    head = member_head(m)
    rider = set(SHIRT + SKIN + PANTS + SHOES) | HEADC
    parked = Image.open(os.path.join(VEH, "bike_parked_joep.png")).convert("RGBA").load()
    out = Image.new("RGBA", (CELL * 8, CELL * 2))
    for row, clip in enumerate(("bike_pedal", "bike_roll")):
        for i, f in enumerate(frames[clip]):
            src = f.load()
            # Joep's head: hair/eyes and the skin above the shoulders (topmost tee row)
            tee_top = min((yy for yy in range(CELL) for xx in range(CELL) if src[xx, yy][3] > 128 and src[xx, yy][:3] in SHIRT), default=40)
            head_px = [(xx, yy) for yy in range(tee_top + 3) for xx in range(CELL)
                       if src[xx, yy][3] > 128 and src[xx, yy][:3] not in SHIRT and src[xx, yy][:3] not in bikecols]
            hx = [p[0] for p in head_px if src[p][:3] in HEADC] or [p[0] for p in head_px]
            hy = [p[1] for p in head_px]
            chin = (sum(hx) // len(hx), max(hy)) if head_px else (CELL // 2, tee_top)
            cell = Image.new("RGBA", (CELL, CELL))
            dst = cell.load()
            hset = set(head_px)
            for yy in range(CELL):
                for xx in range(CELL):
                    p = src[xx, yy]
                    if p[3] <= 128 or (xx, yy) in hset:
                        continue
                    c = p[:3]
                    on_bike = parked[xx, yy][3] > 128 and parked[xx, yy][:3] == c   # tyres share the skin tones
                    if c in rider and c in cmap and not (on_bike and c in bikecols):
                        dst[xx, yy] = cmap[c] + (255,)
                    elif c in bikecols and c in bmap:
                        dst[xx, yy] = bmap[c] + (255,)
                    else:
                        dst[xx, yy] = p
            # the member's head, chin on Joep's chin, a little forward like his
            cell.alpha_composite(head, (max(0, chin[0] - head.width // 2 + 2), max(0, chin[1] - head.height + 2)))
            out.alpha_composite(cell, (i * CELL, row * CELL))
    path = os.path.join(VEH, f"bike_ride_{member}.png")
    out.save(path)
    print(member, "->", os.path.relpath(path, GAME), "clothes", {k: m[k] for k in ("shirt", "skin", "pants", "shoes")})


def main():
    frames = joep_frames()
    bikecols = bike_colours()
    for member, m in MEMBERS.items():
        build(member, dict(m), frames, bikecols)


if __name__ == "__main__":
    main()
