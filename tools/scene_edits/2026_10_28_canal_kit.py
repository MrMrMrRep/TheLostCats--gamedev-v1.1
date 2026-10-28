#!/usr/bin/env python3
"""One-off edit of scenes/world/world_map.tscn (2026-10-28): the canal belt
rebuilt from the SpriteCook canal kit. Text edits only, so every hand edit in
the scene stays. Safe to run twice (it checks before adding).

    python3 -I tools/scene_edits/2026_10_28_canal_kit.py

- CityBlocks under Buildings/CanalBelt: kit = true (flat kit facades)
- Road/Street: kit_span (pavement, kerb, cobbles, quay) over the canal belt
- Background: the old skyline and back street skip the canal belt; three
  CanalBackdrop layers take over there (skyline, back row, backyard trees)
- QuayTrees after TrafficFront: elms on the quay edge, in front of the band
- StudioDoor / VenueDoor: draw_door = false (the door houses have the doors)
- StreetLife/CanalBelt stretches: quay_trees = true (no elms on the pavement)
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
SCENE = ROOT / "scenes/world/world_map.tscn"
SPAN = "Vector2(9884, 16436)"


def main():
    s = SCENE.read_text()

    def add_after(header_re, line):
        nonlocal s
        m = re.search(header_re, s)
        assert m, header_re
        end = s.find("\n\n", m.end())
        block = s[m.start():end]
        key = line.split(" = ")[0]
        if re.search(r"^" + re.escape(key) + r" = ", block, re.M):
            return
        s = s[:end] + "\n" + line + s[end:]

    def insert_before(header_re, text):
        nonlocal s
        if text.split("\n")[0] in s:
            return
        m = re.search(header_re, s)
        assert m, header_re
        s = s[:m.start()] + text + "\n" + s[m.start():]

    if 'id="91_cbkdp"' not in s:
        last = [m.end() for m in re.finditer(r"^\[ext_resource [^\n]*\]$", s, re.M)][-1]
        s = (s[:last] + '\n[ext_resource type="Script" path="res://scripts/world/canal_backdrop.gd" id="91_cbkdp"]'
             + '\n[ext_resource type="Script" path="res://scripts/world/quay_trees.gd" id="92_qtree"]' + s[last:])

    for name in re.findall(r'\[node name="(\w+)" type="Node2D" parent="Buildings/CanalBelt"', s):
        add_after(r'\[node name="%s" type="Node2D" parent="Buildings/CanalBelt"[^\]]*\]' % name, "kit = true")
    add_after(r'\[node name="Street" type="Node2D" parent="Road"[^\]]*\]', f"kit_span = {SPAN}")
    add_after(r'\[node name="Scenery" type="Node2D" parent="Background/Skyline"[^\]]*\]', f"skip = {SPAN}")
    add_after(r'\[node name="Scenery" type="Node2D" parent="Background/BackStreet"[^\]]*\]', f"skip = {SPAN}")
    for door in ("StudioDoor", "VenueDoor"):
        add_after(r'\[node name="%s" type="Area2D" parent="Places/CanalBelt"[^\]]*\]' % door, "draw_door = false")
    for name in re.findall(r'\[node name="(\w+)" type="Node2D" parent="StreetLife/CanalBelt"', s):
        add_after(r'\[node name="%s" type="Node2D" parent="StreetLife/CanalBelt"[^\]]*\]' % name, "quay_trees = true")

    def layer(name, factor, kind, base, seed):
        return (f'[node name="{name}" type="Node2D" parent="Background"]\nscript = ExtResource("3_x5aeg")\nfactor = {factor}\n\n'
                f'[node name="Backdrop" type="Node2D" parent="Background/{name}"]\nscript = ExtResource("91_cbkdp")\n'
                f'kind = {kind}\nspan = {SPAN}\nbase = {base}\nseed_value = {seed}\n')

    insert_before(r'\[node name="PolderFar" type="Node2D" parent="Background"', layer("CanalSkyline", 0.2, 0, 190.0, 3))
    insert_before(r'\[node name="PolderNear" type="Node2D" parent="Background"', layer("CanalBackRow", 0.5, 1, 274.0, 5))
    insert_before(r'\[node name="Bridges" type="Node2D" parent="\."', layer("CanalYards", 0.8, 2, 232.0, 7))
    insert_before(r'\[node name="Water" type="Node2D" parent="\."',
                  '[node name="QuayTrees" type="Node2D" parent="."]\nposition = Vector2(0, 288)\n'
                  f'script = ExtResource("92_qtree")\nspan = {SPAN}\n')
    SCENE.write_text(s)


if __name__ == "__main__":
    main()
