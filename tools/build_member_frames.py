#!/usr/bin/env python3
"""Rebuild a band member's SpriteFrames (<member>_frames.tres) from the sprite
pipeline's <member>.json: every animation in its "animations" (fps, loop),
with the frame cells from its "frames" (name_01, name_02 ...) on the sheet.
Keeps the resource's and the sheet's uids, so nothing that loads it breaks.

    python3 -I tools/build_member_frames.py [member ...]   (default: all five)
"""
import json
import pathlib
import re
import sys

ROOT = pathlib.Path(__file__).resolve().parent.parent
CHARS = ROOT / "assets/sprites/characters"
MEMBERS = ["keys_joep", "bass_jay", "guitar_nikki", "drums_germ", "singer_geoff"]


def build(member):
    folder = CHARS / member
    data = json.loads((folder / f"{member}.json").read_text())
    out = folder / f"{member}_frames.tres"
    old = out.read_text() if out.exists() else ""
    uid = re.search(r'\[gd_resource [^\]]*uid="([^"]+)"', old)
    sheet_uid = re.search(r'\[ext_resource [^\]]*uid="([^"]+)"', old)
    cells = {}
    for key, f in data["frames"].items():
        name, num = key.rsplit("_", 1)
        cells.setdefault(name, []).append((int(num), f["frame"]))
    lines = ['[gd_resource type="SpriteFrames" format=3%s]' % (f' uid="{uid.group(1)}"' if uid else ""), ""]
    lines.append('[ext_resource type="Texture2D"%s path="res://assets/sprites/characters/%s/%s_sheet.png" id="1_sheet"]'
                 % (f' uid="{sheet_uid.group(1)}"' if sheet_uid else "", member, member))
    lines.append("")
    anims = []
    n = 0
    for name, spec in data["animations"].items():
        frames = [c for _, c in sorted(cells.get(name, []), key=lambda t: t[0])]
        assert frames, (member, name)
        ids = []
        for c in frames:
            n += 1
            lines += [f'[sub_resource type="AtlasTexture" id="AtlasTexture_{n}"]', 'atlas = ExtResource("1_sheet")',
                      f'region = Rect2({c["x"]}, {c["y"]}, {c["w"]}, {c["h"]})', ""]
            ids.append(n)
        anims.append((name, ids, float(spec["fps"]), bool(spec.get("loop", True))))
    lines += ["[resource]", "animations = [" + ", ".join(
        '{\n"frames": [' + ", ".join('{\n"duration": 1.0,\n"texture": SubResource("AtlasTexture_%d")\n}' % i for i in ids)
        + '],\n"loop": %s,\n"name": &"%s",\n"speed": %s\n}' % ("true" if loop else "false", name, fps)
        for name, ids, fps, loop in sorted(anims)) + "]", ""]
    out.write_text("\n".join(lines))
    return [a[0] for a in anims]


if __name__ == "__main__":
    for m in sys.argv[1:] or MEMBERS:
        print(m, len(build(m)), "animations")
