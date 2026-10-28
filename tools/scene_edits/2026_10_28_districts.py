#!/usr/bin/env python3
"""One-off edit of scenes/world/world_map.tscn (2026-10-28, after the canal
belt): the old town, a red light district (De Wallen) and the flats rebuilt
from the SpriteCook kit. Text edits only, so the hand edits in the scene stay.
Safe to run twice.

    python3 -I tools/scene_edits/2026_10_28_districts.py

West to east (world x), between the anchors the kit rows fill themselves:
  7822  old town row        | church (lm_church)       | old town row
        old town side street | old town row             | Nieuwmarkt, the Waag (lm_waag)
        old town row
  8990  red light district: Wallen row | Wallen steeg | Wallen row
        Oude Kerk (lm_oude_kerk) | Wallen canal (Oudezijds Achterburgwal)
  9884  canal belt (done before)
 16436  flats row | flats side street | flats row (asphalt road in front)
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
SCENE = ROOT / "scenes/world/world_map.tscn"
KIT = "Vector2(7822, 17276)"


def main():
    s = SCENE.read_text()

    def block(name, parent):
        m = re.search(r'\[node name="%s" type="Node2D" parent="%s"[^\]]*\]\n' % (re.escape(name), re.escape(parent)), s)
        assert m, name
        end = s.find("\n\n", m.end())
        return m.start(), m.end(), end if end >= 0 else len(s)

    def set_props(name, parent, props, drop=()):
        """Set (or add) properties on a node; `drop` removes keys."""
        nonlocal s
        a, b, e = block(name, parent)
        body = s[b:e].split("\n") if e > b else []
        keys = {}
        out = []
        for line in body:
            k = line.split(" = ")[0]
            if k in drop:
                continue
            if k in props:
                if k in keys:
                    continue
                keys[k] = True
                out.append(f"{k} = {props[k]}")
            else:
                out.append(line)
        for k, v in props.items():
            if k not in keys:
                out.append(f"{k} = {v}")
        s = s[:b] + "\n".join(out) + s[e:]

    def replace_body(name, parent, lines):
        nonlocal s
        a, b, e = block(name, parent)
        s = s[:b] + "\n".join(lines) + s[e:]

    def remove(name, parent):
        nonlocal s
        if f'[node name="{name}" type="Node2D" parent="{parent}"' not in s:
            return
        a, b, e = block(name, parent)
        s = s[:a] + s[e + 2:]

    def insert_before(header_re, text):
        nonlocal s
        if text.split("\n")[0] in s:
            return
        m = re.search(header_re, s)
        assert m, header_re
        s = s[:m.start()] + text + "\n" + s[m.start():]

    def insert_after_node(name, parent, text):
        nonlocal s
        if text.split("\n")[0] in s:
            return
        a, b, e = block(name, parent)
        s = s[:e] + "\n\n" + text.rstrip("\n") + s[e:]

    for rid, path in (("93_kitlm", "kit_landmark.gd"), ("94_redlt", "red_light.gd")):
        if f'id="{rid}"' not in s:
            last = [m.end() for m in re.finditer(r"^\[ext_resource [^\n]*\]$", s, re.M)][-1]
            s = s[:last] + f'\n[ext_resource type="Script" path="res://scripts/world/{path}" id="{rid}"]' + s[last:]

    # Old town and the red light district.
    town = "Buildings/OldTown"
    for name, x, district in (("West8_Houses", "7822", "oldtown"), ("West10_Houses", "8056.5", "oldtown"),
                              ("West12_Houses", "8413", "oldtown"), ("West13_Houses", "8790.5", "oldtown"),
                              ("West15_Houses", "8990", "wallen"), ("Block40_0", "9251.5", "wallen")):
        set_props(name, town, {"position": f"Vector2({x}, 288)", "kit": "true", "district": f'&"{district}"'})
    for name, x, piece in (("West9_Church", "7922", "lm_church"), ("West11_Market", "8543", "lm_waag"),
                           ("West14_Church", "9412.5", "lm_oude_kerk")):
        replace_body(name, town, [f"position = Vector2({x}, 288)", 'script = ExtResource("93_kitlm")', f'piece = &"{piece}"'])
    for name, x, kind, district, seed in (("OldTownStreet", "8299.75", 1, "oldtown", 5), ("WallenSteeg", "9175.75", 3, "wallen", 7),
                                          ("WallenCanal", "9771.25", 0, "wallen", 9), ("FlatsStreet", "16810.5", 1, "flats", 11)):
        insert_before(r'\[node name="Buildings" type="Node2D" parent="\."',
                      f'[node name="{name}" type="Node2D" parent="Bridges"]\nposition = Vector2({x}, 288)\n'
                      f'script = ExtResource("90_sideop")\nkind = {kind}\nseed_value = {seed}\ndistrict = &"{district}"\n')

    # The flats: two kit rows either side of a side street.
    for name, x, seed in (("Flats0_Flats", "16436", 3), ("Flats4_Flats", "16921", 5)):
        if 'script = ExtResource("7_q6byn")' in s[block(name, "Buildings/Flats")[1]:block(name, "Buildings/Flats")[2]]:
            replace_body(name, "Buildings/Flats", ["texture_repeat = 2", f"position = Vector2({x}, 288)", 'script = ExtResource("6_1co5k")',
                                                   f"seed_value = {seed}", "kit = true", 'district = &"flats"'])
    remove("Flats2_Flats", "Buildings/Flats")
    remove("Flats6_Flats", "Buildings/Flats")

    # The kit street, the back layers and the quay trees over the new stretch.
    set_props("Street", "Road", {"kit_span": KIT, "kit_road": "Vector2(16436, 17276)"})
    for layer in ("CanalSkyline", "CanalBackRow", "CanalYards"):
        set_props("Backdrop", f"Background/{layer}", {"span": KIT})
    set_props("Scenery", "Background/Skyline", {"skip": KIT})
    set_props("Scenery", "Background/BackStreet", {"skip": KIT})
    set_props("QuayTrees", ".", {"span": "Vector2(7822, 16436)"})
    for name in ("Stretch2", "Stretch3"):
        set_props(name, "StreetLife/OldTown", {"quay_trees": "true"})

    # Zones: the old town ends where the red light district begins.
    set_props("OldTown", "Zones", {"length": "1168.0"})
    insert_after_node("OldTown", "Zones",
                      '[node name="RedLight" type="Node2D" parent="Zones"]\nposition = Vector2(8990, 288)\n'
                      'script = ExtResource("38_ao3qg")\nlength = 894.0\npeople_per_screen = 6.0\nbikes_only = true\n'
                      'red_light = true\ncolor = Color(1, 0.2, 0.35, 1)')

    # The night layer of the red light district, behind the band.
    insert_before(r'\[node name="PeopleBack" type="Node2D" parent="\."',
                  '[node name="RedLightNight" type="Node2D" parent="."]\nposition = Vector2(0, 288)\nscript = ExtResource("94_redlt")\n')
    SCENE.write_text(s)


if __name__ == "__main__":
    main()
