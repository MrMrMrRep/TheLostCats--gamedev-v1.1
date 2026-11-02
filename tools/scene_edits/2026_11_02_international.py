#!/usr/bin/env python3
"""One-off edit of scenes/world/world_map.tscn (2026-11-02): Hotel-Café
International on the Warmoesstraat, right where the red light district starts.
Text edits only, so the hand edits in the scene stay. Safe to run twice.

    python3 -I tools/scene_edits/2026_11_02_international.py

- The two old-town houses before the red light district (West13_Houses,
  x 8790.5 to 8990) make way for the landmark lm_international (KitLandmark),
  which is exactly as wide (399 art px = 199.5 world px).
- Its café door (Places/OldTown/InternationalDoor) leads into the level
  scenes/levels/the_international.tscn (find Geoff); the level's exit brings
  the band back out here.
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
SCENE = ROOT / "scenes/world/world_map.tscn"
X = 8790.5
DOOR_X = 8891.0                             # the middle double door in the art


def main():
    s = SCENE.read_text()
    # Drop the two houses (their whole node block).
    m = re.search(r'\[node name="West13_Houses" type="Node2D" parent="Buildings/OldTown"[^\]]*\]\n', s)
    if m:
        end = s.find("\n\n", m.end())
        s = s[:m.start()] + s[end + 2:]
    if 'name="International"' not in s:
        m = re.search(r'\[node name="West14_Church" type="Node2D" parent="Buildings/OldTown"[^\]]*\]\n', s)
        assert m
        block = ('[node name="International" type="Node2D" parent="Buildings/OldTown"]\n'
                 f'position = Vector2({X}, 288)\n'
                 'script = ExtResource("93_kitlm")\n'
                 'piece = &"lm_international"\n\n')
        s = s[:m.start()] + block + s[m.start():]
    if 'name="InternationalDoor"' not in s:
        m = re.search(r'\[node name="CanalBelt" type="Node2D" parent="Places"[^\]]*\]\n', s)
        assert m
        block = ('[node name="OldTown" type="Node2D" parent="Places"]\n\n'
                 '[node name="InternationalDoor" type="Area2D" parent="Places/OldTown"]\n'
                 f'position = Vector2({DOOR_X}, 288)\n'
                 'collision_layer = 32\n'
                 'collision_mask = 4\n'
                 'monitorable = false\n'
                 'script = ExtResource("20_j1unl")\n'
                 'target_scene = "res://scenes/levels/the_international.tscn"\n'
                 'area_size = Vector2(30, 40)\n'
                 'draw_door = false\n\n')
        s = s[:m.start()] + block + s[m.start():]
    SCENE.write_text(s)


if __name__ == "__main__":
    main()
