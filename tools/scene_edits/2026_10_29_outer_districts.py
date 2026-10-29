#!/usr/bin/env python3
"""One-off edit of scenes/world/world_map.tscn (2026-10-29, after the old
town and the red light district): the hotels, the park and the theatre, the
industry, the band's storage and the airport rebuilt from the SpriteCook kit,
with their own side streets and steegs. Text edits only, so the hand edits in
the scene stay. Safe to run twice; run it after 2026_10_28_districts.py.

    python3 -I tools/scene_edits/2026_10_29_outer_districts.py

West to east (world x), between the anchors the kit rows fill themselves:
  6400  hotel row | hotel street (open_hot_street) | Grand Hotel (lm_grand_hotel) | hotel row
  7092  park (fence, gate, pond) | stage-door steeg (open_th_steeg) | theatre (lm_theatre)
  7822  old town ... flats (done before)
 17284  service station (its door on StationDoor 17376) | mall | car park | sheds
        industrial road (open_ind_road) | self storage | industrial steeg (open_ind_steeg) | sheds
 18373.5 the band's storage (its roller door on StorageGate 18431) | sheds to the town's end 18706
 19386  airport (motorway, no kit pavement): two hotels, the terminal (three halls), the tower
Doors, the van, Geordie and the parking spots stay where they were.
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
SCENE = ROOT / "scenes/world/world_map.tscn"
KIT = "Vector2(6400, 18706)"
BACK = "Vector2(6400, 17276)"               # canal-house back layers; the industry keeps its own skyline
ROADS = "Array[Vector2]([Vector2(6400, 7822), Vector2(16436, 18706)])"


def main():
    s = SCENE.read_text()

    def block(name, parent, typ="Node2D"):
        m = re.search(r'\[node name="%s" type="%s" parent="%s"[^\]]*\]\n' % (re.escape(name), typ, re.escape(parent)), s)
        assert m, name
        end = s.find("\n\n", m.end())
        return m.start(), m.end(), end if end >= 0 else len(s)

    def set_props(name, parent, props, drop=(), typ="Node2D"):
        """Set (or add) properties on a node; `drop` removes keys."""
        nonlocal s
        a, b, e = block(name, parent, typ)
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

    def insert_after_node(name, parent, text):
        nonlocal s
        if text.split("\n")[0] in s:
            return
        a, b, e = block(name, parent)
        s = s[:e] + "\n\n" + text.rstrip("\n") + s[e:]

    def insert_before(header_re, text):
        nonlocal s
        if text.split("\n")[0] in s:
            return
        m = re.search(header_re, s)
        assert m, header_re
        s = s[:m.start()] + text + "\n" + s[m.start():]

    def row(x, district, seed):
        return [f"position = Vector2({x}, 288)", 'script = ExtResource("6_1co5k")', f"seed_value = {seed}",
                "kit = true", f'district = &"{district}"']

    def landmark(x, piece, sign="", repeat=1, pavement=True, colour=None):
        out = [f"position = Vector2({x}, 288)", 'script = ExtResource("93_kitlm")', f'piece = &"{piece}"']
        if sign:
            out.append(f'sign_text = "{sign}"')
        if colour:
            out.append(f"sign_color = {colour}")
        if repeat > 1:
            out.append(f"repeat = {repeat}")
        if not pavement:
            out.append("on_pavement = false")
        return out

    # The hotels: a hotel row, the hotel street, the Grand Hotel, a hotel row.
    replace_body("West0_Hotel", "Buildings/Hotels", row("6400", "hotels", 13))
    remove("West1_Houses", "Buildings/Hotels")
    replace_body("West2_Hotel", "Buildings/Hotels", landmark("6745.75", "lm_grand_hotel"))
    replace_body("West4_Hotel", "Buildings/Hotels", row("6992.75", "hotels", 17))

    # The park, the stage-door steeg and the theatre.
    replace_body("West6_Park", "Buildings/ParkTheater", row("7092", "park", 4))
    replace_body("West7_Theater", "Buildings/ParkTheater", landmark("7589", "lm_theatre"))

    # The industry and the band's storage.
    ind = "Buildings/Industry"
    replace_body("ServiceStation", ind, landmark("17284", "lm_station"))
    replace_body("Mall", ind, landmark("17403", "lm_mall", "WINKELCENTRUM"))
    replace_body("CarPark", ind, landmark("17518.5", "lm_carpark"))
    insert_after_node("CarPark", ind, '[node name="Industry1_Sheds" type="Node2D" parent="Buildings/Industry"]\n'
                      + "\n".join(row("17615", "industry", 21)))
    replace_body("SelfStorage", ind, landmark("17912.5", "lm_selfstorage", "SELF STORAGE"))
    insert_after_node("SelfStorage", ind, '[node name="Industry2_Sheds" type="Node2D" parent="Buildings/Industry"]\n'
                      + "\n".join(row("18160.5", "industry", 23)))
    replace_body("BandStorage", "Buildings/Storage", landmark("18373.5", "lm_band_storage", "THE LOST CATS - STORAGE"))
    insert_after_node("BandStorage", "Buildings/Storage", '[node name="Storage1_Sheds" type="Node2D" parent="Buildings/Storage"]\n'
                      + "\n".join(row("18615", "industry", 25)))
    set_props("StationDoor", "Places/Industry", {"draw_door": "false"}, typ="Area2D")

    # The airport, by the motorway: no kit pavement, the buildings stand on the street line.
    air = "Buildings/Airport"
    navy = "Color(0.118, 0.141, 0.2, 1)"
    replace_body("AirportHotel4", air, landmark("19386", "lm_ahotel_a", "AIRPORT HOTEL", pavement=False, colour=navy))
    replace_body("AirportHotel5", air, landmark("19556", "lm_ahotel_b", "SKY INN", pavement=False, colour=navy))
    replace_body("Terminal0", air, landmark("19744", "lm_terminal", repeat=3, pavement=False))
    replace_body("Tower0", air, landmark("20286", "lm_tower", pavement=False))

    # Side streets and steegs (centre x; the piece's width is the slot).
    for name, x, kind, district, seed in (("HotelStreet", "6620.25", 1, "hotels", 13), ("TheatreSteeg", "7507.25", 3, "theatre", 15),
                                          ("IndustryRoad", "17800", 1, "industry", 17), ("IndustrySteeg", "18083.25", 3, "industry", 19)):
        insert_before(r'\[node name="Buildings" type="Node2D" parent="\."',
                      f'[node name="{name}" type="Node2D" parent="Bridges"]\nposition = Vector2({x}, 288)\n'
                      f'script = ExtResource("90_sideop")\nkind = {kind}\nseed_value = {seed}\ndistrict = &"{district}"\n')

    # The kit street over the whole town (asphalt where cars come), the back
    # layers over the old stretches, the quay trees along the park's canal.
    set_props("Street", "Road", {"kit_span": KIT, "kit_roads": ROADS}, drop=("kit_road",))
    for layer in ("CanalSkyline", "CanalBackRow", "CanalYards"):
        set_props("Backdrop", f"Background/{layer}", {"span": BACK})
    set_props("Scenery", "Background/Skyline", {"skip": BACK})
    set_props("Scenery", "Background/BackStreet", {"skip": BACK})
    set_props("QuayTrees", ".", {"span": "Vector2(7092, 16436)"})
    set_props("Stretch1", "StreetLife/ParkTheater", {"quay_trees": "true"})
    SCENE.write_text(s)


if __name__ == "__main__":
    main()
