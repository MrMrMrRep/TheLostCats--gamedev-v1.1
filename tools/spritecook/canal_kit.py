#!/usr/bin/env python3
"""Cuts the SpriteCook canal-belt kit (2026-10-28) into game sprites.

    python3 -I tools/spritecook/canal_kit.py

Reads the raw SpriteCook sheets in tools/spritecook/canal_kit_src/ (asset ids
in spritecook-assets.json, "canal2_*"), writes the pieces to
assets/sprites/world/canal2/ and the kit table scripts/world/canal_kit.gd.

Every piece is drawn at 1 texel = 1 art px (half a world px), so nothing is
ever scaled in the game. Per piece: the colours are merged (SpriteCook leaves
1-step noise), alpha is made hard, pure black becomes the palette's navy, and
for facades the glass of each window is found (lit at night by NightGlow).
"""
import pathlib
from collections import deque

import numpy as np
from PIL import Image

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
SRC = ROOT / "tools/spritecook/canal_kit_src"
OUT = ROOT / "assets/sprites/world/canal2"
GD = ROOT / "scripts/world/canal_kit.gd"
NAVY = (0x1e, 0x24, 0x33)                   # docs/art-style.md: glass, the darkest colour
COLOURS = 48                                # per piece, after merging the noise

# Facade sheets: names left to right. Door houses: the double door's middle and
# the empty sign band above it, in piece px (measured on the cut pieces).
FACADE_SHEETS = {
    "fac_d1": ["res_blue", "res_cream", "res_brown", "res_red"],
    "fac_d2": ["res_blue2", "res_cream2", "res_ochre", "res_wine"],
    "fac_b1": ["shop_orange", "shop_cream", "shop_brown", "shop_red"],
    "fac_c2": ["merchant", "spout_green", "bakery"],
    "fac_e1": ["door_venue", "door_studio", "door_cafe"],
    # Old town (Nieuwmarkt / Zeedijk side): shops and older houses with shutters.
    "ot_shop_a": ["ot_cheese", "ot_cafe", "ot_bike", "ot_antique"],
    "ot_shop_b": ["ot_cheese2", "ot_cafe2", "ot_bike2", "ot_curio"],
    "ot_res_b": ["ot_res_a", "ot_res_b", "ot_res_c", "ot_res_d"],
    # De Wallen: the oldest narrow houses, red neon windows, brown bar, coffeeshop.
    "wal_a": ["wal_kroeg", "wal_neon_a", "wal_coffee", "wal_neon_b"],
    "wal_b": ["wal_kroeg2", "wal_coffee2", "wal_neon_c", "wal_neon_d"],
    # The flats east of the canal belt: 19th-century ring blocks with shops.
    "flats_a": ["flat_shop", "flat_cafe", "flat_laund"],
    "flats_b": ["flat_shop2", "flat_cafe2", "flat_laund2"],
    # The hotel street (west): boutique hotel, hostel, café.
    "hst_a": ["hot_boutique", "hot_hostel", "hot_cafe"],
}
# Sheets cut by their empty columns (pieces that aren't wall-to-wall facades:
# park fence, gate and pond, sheds), optionally one band of rows. Pool items
# (no window glow when `glow` is False) or landmarks (KitLandmark).
COLUMN_SHEETS = {
    "park_a": (["park_fence", "park_gate", "park_pond"], None, False),
    "ind_a": (["ind_workshop", "ind_shed", "ind_office", "ind_warehouse"], (150, 288), True),
    "sm_a": (["lm_station", "lm_mall"], None, True),
    "cp_a": (["lm_carpark", "lm_selfstorage"], None, True),
    "ah_a": (["lm_ahotel_a", "lm_ahotel_b"], None, True),
}
# Door houses: the empty sign band above the double door (piece px, measured).
SIGNS = {
    "door_venue": (48, 171, 110, 13),
    "door_studio": (7, 188, 90, 12),
    "door_cafe": (5, 188, 85, 12),
    # Landmarks' empty boards (KitLandmark.sign_text).
    "lm_mall": (73, 103, 94, 26), "lm_selfstorage": (32, 1, 123, 18), "lm_band_storage": (135, 72, 235, 25),
    "lm_ahotel_a": (84, 2, 83, 27), "lm_ahotel_b": (95, 4, 75, 22),
}
# Modern buildings: light glass and grey-blue walls fool windows(), so their
# window grids are measured by eye: (columns x, rows y, w, h) in piece px.
WINDOW_GRIDS = {
    "lm_ahotel_a": [((31, 51, 71, 101, 121), (43, 80, 116, 153, 190), 16, 28),
                    ((174, 196), (84, 121, 158, 194), 20, 24)],
    "lm_ahotel_b": [((84, 116, 149, 179), (57, 97, 137, 179), 14, 21),
                    ((18, 48), (97, 137, 178), 7, 21)],
    "lm_mall": [((5, 35, 170, 200), (60,), 26, 34), ((82, 106, 128), (5, 52), 20, 38), ((82, 106, 128), (136,), 20, 30),
                ((22, 44, 170, 190), (152, 195), 18, 34)],
}


def grid_windows(name, img):
    if name not in WINDOW_GRIDS:
        return windows(img)
    return [(x, y, w, h) for xs, ys, w, h in WINDOW_GRIDS[name] for y in ys for x in xs]
# Gable silhouette per facade: neighbours never share one.
GABLES = {
    "res_blue": 0, "res_blue2": 0, "shop_orange": 0,
    "res_cream": 1, "res_cream2": 1, "shop_cream": 1,
    "res_brown": 2, "res_ochre": 2, "shop_brown": 2, "bakery": 2,
    "res_red": 3, "res_wine": 3, "shop_red": 3,
    "merchant": 4, "spout_green": 5,
    "door_venue": 4, "door_studio": 5, "door_cafe": 2,
    "ot_cheese": 2, "ot_cafe": 0, "ot_bike": 1, "ot_antique": 6,
    "ot_cheese2": 2, "ot_cafe2": 0, "ot_bike2": 1, "ot_curio": 6,
    "ot_res_a": 6, "ot_res_b": 2, "ot_res_c": 0, "ot_res_d": 1,
    "wal_kroeg": 2, "wal_neon_a": 0, "wal_coffee": 7, "wal_neon_b": 6,
    "wal_kroeg2": 6, "wal_coffee2": 2, "wal_neon_c": 0, "wal_neon_d": 3,
    "flat_shop": 8, "flat_cafe": 10, "flat_laund": 9, "flat_shop2": 10, "flat_cafe2": 8, "flat_laund2": 9,
    "hot_boutique": 11, "hot_hostel": 12, "hot_cafe": 13,
    "park_fence": 20, "park_gate": 21, "park_pond": 22,
    "ind_workshop": 30, "ind_shed": 31, "ind_office": 32, "ind_warehouse": 33,
}
# Landmarks: one building each, a row anchor like an opening (KitLandmark).
LANDMARKS = {"waag_a": "lm_waag", "church_n1": "lm_church", "church_oude": "lm_oude_kerk",
             "th_c": "lm_theatre", "th_b": "lm_grand_hotel", "bs_c": "lm_band_storage", "tw_a": "lm_tower",
             "term_a": "lm_terminal"}
# Night-life people for the red light district (RedLightNight): drawn at twice
# the band's size, so halved (nearest) to stand at band scale.
NIGHT_SHEET = ("night_b", ["nl_hoodie", "nl_leather", "nl_coat", "nl_cap", "nl_tourist"])
# Neon signs: one sheet, read row by row, left to right.
NEON_SHEET = ("neon_a", ["neon_heart", "neon_cocktail", "neon_bar", "neon_leaf", "neon_guitar", "neon_star"])
# Strips (backgrounds, trees, openings) and tiling textures: source -> name.
STRIPS = {
    "back4": "back_row", "back3": "skyline_low",
    "sky2": "skyline_a", "sky1": "skyline_b",
    "yard1": "yard_a", "yard3": "yard_b",
    "gapc2": "gap_canal", "gaps2": "gap_street", "gaps1": "gap_street_b",
}
# Openings: a side canal / side street / steeg seen between two complete
# corner houses (flat kit fronts, their side walls and roofs running into the
# depth). Made by SpriteCook edits of kit-front + view + kit-front composites.
OPENINGS = {
    "open_c1b": "open_canal_a", "open_c1c": "open_canal_b", "open_c2a": "open_canal_c", "open_c2b": "open_canal_d",
    "open_s1a": "open_street_a", "open_s1b": "open_street_b", "open_s2b": "open_steeg",
    "open_ots": "open_ot_street", "open_otg": "open_ot_steeg",
    "open_wc": "open_wal_canal", "open_ws": "open_wal_steeg", "open_fs": "open_fl_street",
    "open_hs": "open_hot_street", "open_ts": "open_th_steeg", "open_ir": "open_ind_road", "open_is": "open_ind_steeg",
}
# Where each side street's own road leaves its piece: the columns between its
# kerbs on the bottom row (piece px, after the crop) and 1 for asphalt, 0 for
# cobbles. Measured by eye on the pieces; the street runs the road across the
# pavement there (Street._kit_road_mouth). Steegs have none: the pavement runs on.
ROADS = {
    "open_street_a": (160, 280, 0), "open_street_b": (160, 280, 0),
    "open_ot_street": (166, 287, 0), "open_fl_street": (161, 283, 1),
    "open_hot_street": (168, 309, 1), "open_ind_road": (152, 292, 1),
}
TREES = {"tree_a": ["elm_0", "elm_1"], "trees": ["elm_2", "elm_3", "elm_4"]}
TEXTURES = {"tex_setts": "setts", "tex_paver": "paver", "tex_wall": "quay_wall"}


def clean(img, colours=COLOURS, hard_alpha=True):
    """Merge near colours, hard alpha, no pure black."""
    rgba = img.convert("RGBA")
    a = np.array(rgba)
    alpha = a[:, :, 3]
    rgb = Image.fromarray(a[:, :, :3], "RGB")
    q = rgb.quantize(colors=colours, method=Image.Quantize.MEDIANCUT, dither=Image.Dither.NONE).convert("RGB")
    out = np.array(q)
    dark = (out[:, :, 0] < 20) & (out[:, :, 1] < 20) & (out[:, :, 2] < 28)
    out[dark] = NAVY
    if hard_alpha:
        alpha = np.where(alpha >= 128, 255, 0).astype(np.uint8)
    return Image.fromarray(np.dstack([out, alpha]), "RGBA")


def bbox(img):
    return img.getchannel("A").point(lambda v: 255 if v >= 128 else 0).getbbox()


def cut_facades(sheet, names):
    """Houses in a row on one ground line (the sheet's last opaque row is that
    line: dropped). A house's span is where its wall is, measured across the
    upper storeys, so hanging signs and brackets don't widen it."""
    a = np.array(sheet.convert("RGBA"))[:, :, 3] >= 128
    rows = np.nonzero(a.any(1))[0]
    ground = rows[-1]                       # the drawn ground line
    base = ground - 1
    while a[base].sum() < a[ground].sum() * 0.5 and base > ground - 4:
        base -= 1
    body = a[: base - 4].sum(0)
    spans, x = [], 0
    while x < a.shape[1]:
        if body[x] > 0:
            s = x
            while x < a.shape[1] and body[x] > 0:
                x += 1
            if x - s > 30:
                spans.append([s, x])
        x += 1
    assert len(spans) == len(names), (names, spans)
    out = []
    for (s, e), name in zip(spans, names):
        top = int(np.nonzero(a[:, s:e].any(1))[0][0])
        # The wall: columns opaque half way up the upper storeys.
        probe = a[top + (base - top) // 2, s:e]
        cols = np.nonzero(probe)[0]
        x0, x1 = s + int(cols[0]), s + int(cols[-1]) + 1
        out.append((name, sheet.crop((x0, top, x1, base + 1))))
    return out


def windows(img):
    """Glass panes: dark, bluish regions of window size. Rects in piece px."""
    a = np.array(img.convert("RGBA")).astype(int)
    r, g, b, al = a[:, :, 0], a[:, :, 1], a[:, :, 2], a[:, :, 3]
    lum = 0.3 * r + 0.59 * g + 0.11 * b
    glass = (al > 0) & (lum < 80) & (b >= r) & (b + 6 >= g)
    h, w = glass.shape
    seen = np.zeros_like(glass)
    found = []
    for y in range(h):
        for x in range(w):
            if not glass[y, x] or seen[y, x]:
                continue
            q = deque([(y, x)])
            seen[y, x] = True
            pts = []
            while q:
                cy, cx = q.popleft()
                pts.append((cy, cx))
                for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                    if 0 <= ny < h and 0 <= nx < w and glass[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        q.append((ny, nx))
            ys = [p[0] for p in pts]
            xs = [p[1] for p in pts]
            x0, x1, y0, y1 = min(xs), max(xs) + 1, min(ys), max(ys) + 1
            bw, bh = x1 - x0, y1 - y0
            if not (3 <= bw <= 60 and 4 <= bh <= 44):
                continue
            if bw > 1.6 * bh and bh < 12:     # flower boxes, basement lights
                continue
            if len(pts) < 0.45 * bw * bh:
                continue
            if y1 > h - 6 and bh > 28:          # a door, not a window
                continue
            found.append((x0, y0, bw, bh))
    # Panes of one window (split by glazing bars) -> one rect.
    found.sort(key=lambda t: (t[0], t[1]))
    merged = []
    for f in found:
        for i, m in enumerate(merged):
            mx0, my0, mw, mh = m
            if f[0] <= mx0 + mw + 2 and mx0 <= f[0] + f[2] + 2 and f[1] <= my0 + mh + 2 and my0 <= f[1] + f[3] + 2:
                nx0, ny0 = min(mx0, f[0]), min(my0, f[1])
                nx1, ny1 = max(mx0 + mw, f[0] + f[2]), max(my0 + mh, f[1] + f[3])
                if nx1 - nx0 > 30 and ny1 - ny0 > 30:
                    continue                # a door next to a window: keep apart
                merged[i] = (nx0, ny0, nx1 - nx0, ny1 - ny0)
                break
        else:
            merged.append(f)
    return [m for m in merged if m[2] >= 5 and m[3] >= 7]


def main():
    OUT.mkdir(parents=True, exist_ok=True)
    facades = {}
    for src, names in FACADE_SHEETS.items():
        sheet = Image.open(SRC / (src + ".png"))
        for name, piece in cut_facades(sheet, names):
            piece = clean(piece)
            piece.save(OUT / (name + ".png"))
            facades[name] = (piece.size, windows(piece))
    strips = {}
    for src, name in STRIPS.items():
        img = clean(Image.open(SRC / (src + ".png")), 64)
        img = img.crop(bbox(img))
        img.save(OUT / (name + ".png"))
        strips[name] = img.size
    mouths = {}
    for src, name in OPENINGS.items():
        img = clean(Image.open(SRC / (src + ".png")), 64)
        img = img.crop(bbox(img))
        img.save(OUT / (name + ".png"))
        facades[name] = (img.size, windows(img))
        if "canal" in name:
            mouths[name] = water_mouth(img)
    for src, names in TREES.items():
        img = clean(Image.open(SRC / (src + ".png")), 40)
        a = np.array(img)[:, :, 3] > 0
        last = int(np.nonzero(a.any(1))[0][-1])
        cols = a[: last - 6].any(0)         # above the drawn ground line
        spans, x = [], 0
        while x < len(cols):
            if cols[x]:
                s = x
                while x < len(cols) and cols[x]:
                    x += 1
                if x - s > 20:
                    spans.append((s, x))
            x += 1
        assert len(spans) == len(names), (src, spans)
        for (s, e), name in zip(spans, names):
            piece = img.crop((s, 0, e, img.height))
            # The drawn ground line under the trees: cut where the trunk ends.
            al = np.array(piece)[:, :, 3] > 0
            widths = al.sum(1)
            bottom = int(np.nonzero(widths)[0][-1])
            while bottom > 0 and widths[bottom] > (e - s) * 0.6:
                bottom -= 1
            piece = piece.crop((0, 0, piece.width, bottom + 1))
            piece = piece.crop(bbox(piece))
            piece.save(OUT / (name + ".png"))
            strips[name] = piece.size
    for src, name in TEXTURES.items():
        clean(Image.open(SRC / (src + ".png")), 32, hard_alpha=False).save(OUT / (name + ".png"))
    for src, (names, band, glow) in COLUMN_SHEETS.items():
        for name, piece in cut_columns(Image.open(SRC / (src + ".png")), names, band):
            piece = clean(piece, 56)
            piece.save(OUT / (name + ".png"))
            facades[name] = (piece.size, grid_windows(name, piece) if glow else [])
    for src, name in LANDMARKS.items():
        img = clean(Image.open(SRC / (src + ".png")), 64)
        img = img.crop(bbox(img))
        img = ground_trim(img)
        img = img.crop(bbox(img))
        img.save(OUT / (name + ".png"))
        facades[name] = (img.size, windows(img))
    src, names = NEON_SHEET
    sheet = clean(Image.open(SRC / (src + ".png")), 32)
    al = np.array(sheet)[:, :, 3] > 0
    boxes = []
    seen = np.zeros_like(al)
    for y in range(al.shape[0]):
        for x in range(al.shape[1]):
            if al[y, x] and not seen[y, x]:
                q = deque([(y, x)])
                seen[y, x] = True
                xs, ys = [], []
                while q:
                    cy, cx = q.popleft()
                    xs.append(cx)
                    ys.append(cy)
                    for ny in range(cy - 2, cy + 3):          # tubes may break: join near pixels
                        for nx in range(cx - 2, cx + 3):
                            if 0 <= ny < al.shape[0] and 0 <= nx < al.shape[1] and al[ny, nx] and not seen[ny, nx]:
                                seen[ny, nx] = True
                                q.append((ny, nx))
                if len(xs) > 30:
                    boxes.append((min(xs), min(ys), max(xs) + 1, max(ys) + 1))
    boxes = [bx for bx in boxes if not any(o != bx and o[0] <= bx[0] and o[1] <= bx[1] and o[2] >= bx[2] and o[3] >= bx[3] for o in boxes)]
    boxes.sort(key=lambda bx: (round(bx[1] / 40), bx[0]))
    assert len(boxes) == len(names), boxes
    for bx, name in zip(boxes, names):
        piece = sheet.crop(bx)
        piece.save(OUT / (name + ".png"))
        strips[name] = piece.size
    src, names = NIGHT_SHEET
    raw = Image.open(SRC / (src + ".png")).convert("RGBA")
    small = clean(raw.resize((raw.width // 2, raw.height // 2), Image.NEAREST), 40)
    al = np.array(small)[:, :, 3] > 0
    cols = al.any(0)
    spans, x = [], 0
    while x < len(cols):
        if cols[x]:
            st = x
            while x < len(cols) and (cols[x] or (x + 1 < len(cols) and cols[x + 1])):
                x += 1
            if x - st > 6:
                spans.append((st, x))
        x += 1
    assert len(spans) == len(names), spans
    for (a0, a1), name in zip(spans, names):
        piece = small.crop((a0, 0, a1, small.height))
        piece = piece.crop(bbox(piece))
        piece.save(OUT / (name + ".png"))
        strips[name] = piece.size
    neons = {}
    for name in facades:
        if name.startswith("wal_") or name.startswith("open_wal"):
            neons[name] = neon_windows(Image.open(OUT / (name + ".png")))
    write_gd(facades, strips, mouths, neons, ROADS)
    for k, (size, win) in facades.items():
        print(f"{k:12s} {size[0]:3d}x{size[1]:3d}  windows {len(win)}")
    for k, size in strips.items():
        print(f"{k:12s} {size[0]:3d}x{size[1]:3d}")


def water_mouth(img):
    """Columns where the side canal's water meets the bottom edge (piece px):
    the run of water around the middle."""
    a = np.array(img.convert("RGBA")).astype(int)
    row = a[-3]
    wet = [row[x, 3] > 0 and row[x, 2] > row[x, 0] + 25 and row[x, 1] > row[x, 0] for x in range(a.shape[1])]
    mid = a.shape[1] // 2
    near = [x for x in range(a.shape[1]) if wet[x]]
    assert near, "no water at the bottom"
    x0 = x1 = min(near, key=lambda x: abs(x - mid))
    while x0 > 0 and (wet[x0 - 1] or (x0 > 1 and wet[x0 - 2])):
        x0 -= 1
    while x1 < a.shape[1] - 1 and (wet[x1 + 1] or (x1 < a.shape[1] - 2 and wet[x1 + 2])):
        x1 += 1
    return (x0, x1 + 1)


def cut_columns(sheet, names, band=None):
    """Pieces separated by empty columns, feet on the sheet's ground line (dropped)."""
    if band:
        sheet = sheet.crop((0, band[0], sheet.width, min(band[1], sheet.height)))
    a = np.array(sheet.convert("RGBA"))[:, :, 3] >= 128
    rows = np.nonzero(a.any(1))[0]
    base = rows[-1]
    for _ in range(8):                      # a drawn ground strip wider than the pieces: drop it
        if a[base].sum() > a[base - 1].sum() * 1.3 or a[base].mean() > 0.97:
            base -= 1
    cols = a[: base - 2].any(0)
    spans, x = [], 0
    while x < len(cols):
        if cols[x]:
            st = x
            while x < len(cols) and (cols[x] or (x + 1 < len(cols) and cols[x + 1])):
                x += 1
            if x - st > 20:
                spans.append((st, x))
        x += 1
    assert len(spans) == len(names), (names, spans)
    out = []
    for (s0, s1), name in zip(spans, names):
        piece = sheet.crop((s0, 0, s1, base + 1))
        out.append((name, piece.crop(bbox(piece))))
    return out


def neon_windows(img):
    """Red-light windows: red curtains framed by red neon tubes (piece px)."""
    a = np.array(img.convert("RGBA")).astype(int)
    r, g, b, al = a[:, :, 0], a[:, :, 1], a[:, :, 2], a[:, :, 3]
    red = (al > 0) & (r > 110) & (g < 55) & (r > g * 2.5) & (r > b * 1.8)
    grown = red.copy()                      # join the tube pieces and curtain of one window
    for dy in range(-3, 4):
        for dx in range(-3, 4):
            grown |= np.roll(np.roll(red, dy, 0), dx, 1)
    red = grown & (al > 0)
    h, w = red.shape
    seen = np.zeros_like(red)
    out = []
    for y in range(h):
        for x in range(w):
            if not red[y, x] or seen[y, x]:
                continue
            q = deque([(y, x)])
            seen[y, x] = True
            xs, ys = [], []
            while q:
                cy, cx = q.popleft()
                xs.append(cx)
                ys.append(cy)
                for ny, nx in ((cy + 1, cx), (cy - 1, cx), (cy, cx + 1), (cy, cx - 1)):
                    if 0 <= ny < h and 0 <= nx < w and red[ny, nx] and not seen[ny, nx]:
                        seen[ny, nx] = True
                        q.append((ny, nx))
            x0, x1, y0, y1 = min(xs), max(xs) + 1, min(ys), max(ys) + 1
            if 6 <= x1 - x0 <= 70 and 8 <= y1 - y0 <= 70 and len(xs) >= 20:
                out.append((x0, y0, x1 - x0, y1 - y0))
    return out


def ground_trim(img):
    """Drop a drawn ground line under a landmark (a thin dark full-width row)."""
    a = np.array(img.convert("RGBA"))
    last = a[-1]
    op = last[:, 3] > 0
    if op.mean() > 0.6 and np.median(last[op][:, :3].sum(1)) < 200:
        return img.crop((0, 0, img.width, img.height - 1))
    return img


def write_gd(facades, strips, mouths, neons=None, roads=None):
    lines = [
        "class_name CanalKit",
        "## The SpriteCook canal-belt kit (2026-10-28): flat facades, the back",
        "## layers, trees and the openings. Generated by tools/spritecook/canal_kit.py",
        "## (don't edit by hand). 1 texel = 1 art px = half a world px: draw at",
        "## scale 0.5, never stretched. Facade origin: bottom-left on the street line.",
        "",
        'const DIR := "res://assets/sprites/world/canal2/"',
        "",
        "## name -> glass rects (texture px), lit at night.",
        "const WINDOWS := {",
    ]
    for name, (size, win) in facades.items():
        rects = ", ".join(f"Rect2i({x}, {y}, {w}, {h})" for x, y, w, h in win)
        lines.append(f'\t&"{name}": [{rects}],')
    lines += ["}", "", "## Door houses: the empty sign band above the door (texture px).", "const SIGNS := {"]
    for name, (x, y, w, h) in SIGNS.items():
        lines.append(f'\t&"{name}": Rect2i({x}, {y}, {w}, {h}),')
    lines += ["}", "", "## Openings over a side canal: the water's columns at the bottom edge (texture px).", "const MOUTHS := {"]
    for name, (x0, x1) in mouths.items():
        lines.append(f'\t&"{name}": Vector2i({x0}, {x1}),')
    lines += ["}", "", "## Side streets: their road's columns at the bottom edge (texture px) and 1 for asphalt (0: cobbles).", "const ROADS := {"]
    for name, (x0, x1, asphalt) in (roads or {}).items():
        lines.append(f'\t&"{name}": Vector3i({x0}, {x1}, {asphalt}),')
    lines += ["}", "", "## Red-light windows (red curtains, neon frames): lit red at night (texture px).", "const NEON := {"]
    for name, rects in (neons or {}).items():
        lines.append(f'\t&"{name}": [' + ", ".join(f"Rect2i({x}, {y}, {w}, {h})" for x, y, w, h in rects) + "],")
    lines += ["}", "", "## Gable silhouette per facade (neighbours differ).", "const GABLES := {"]
    for name, g in GABLES.items():
        lines.append(f'\t&"{name}": {g},')
    lines += ["}", "", "## Texture sizes (art px).", "const SIZES := {"]
    for name, (size, _win) in facades.items():
        lines.append(f'\t&"{name}": Vector2i({size[0]}, {size[1]}),')
    for name, size in strips.items():
        lines.append(f'\t&"{name}": Vector2i({size[0]}, {size[1]}),')
    lines += ["}", ""]
    GD.write_text("\n".join(lines))


if __name__ == "__main__":
    main()
