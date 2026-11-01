#!/usr/bin/env python3
"""One-off edit of scenes/world/world_map.tscn (2026-11-01): the road's lanes
and the draw order. Text edits only, so the hand edits in the scene stay.
Safe to run twice; run it after 2026_10_29_outer_districts.py.

    python3 -I tools/scene_edits/2026_11_01_roads.py

- The kit street (pavement, kerb, the town's road) starts where the city's
  street does (x 6000, the end of the motorway taper, RoadLanes.WEST), with
  asphalt and a lane each way at the city's edges.
- The viaduct under the hotels starts below the road's near edge (it used to
  cover the road with its own deck).
- Draw order (z): the band and the pavement 0, traffic behind the van 1, the
  van 2, traffic in front of it 3, and what stands in front of the road 4:
  the quay elms, the viaducts and grass banks, the tree clumps and the
  foreground (the round hotel, the crane).
"""
import pathlib
import re

ROOT = pathlib.Path(__file__).resolve().parent.parent.parent
SCENE = ROOT / "scenes/world/world_map.tscn"
FRONT_Z = 4


def main():
    s = SCENE.read_text()

    def block(name, parent, typ="Node2D"):
        m = re.search(r'\[node name="%s" type="%s" parent="%s"[^\]]*\]\n' % (re.escape(name), typ, re.escape(parent)), s)
        assert m, name
        end = s.find("\n\n", m.end())
        return m.start(), m.end(), end if end >= 0 else len(s)

    def set_props(name, parent, props, typ="Node2D"):
        nonlocal s
        a, b, e = block(name, parent, typ)
        body = s[b:e].split("\n") if e > b else []
        out, seen = [], set()
        for line in body:
            k = line.split(" = ")[0]
            if k in props:
                if k not in seen:
                    out.append(f"{k} = {props[k]}")
                    seen.add(k)
            elif line:
                out.append(line)
        out += [f"{k} = {v}" for k, v in props.items() if k not in seen]
        s = s[:b] + "\n".join(out) + s[e:]

    set_props("Street", "Road", {"kit_span": "Vector2(6000, 18706)",
                                 "kit_roads": "Array[Vector2]([Vector2(6000, 7822), Vector2(16436, 18706)])"})
    set_props("ViaductTown", "FrontGround/Viaduct", {"top": "23.0"})
    for name in ("QuayTrees", "FrontGround", "Canopies", "Foreground"):
        set_props(name, ".", {"z_index": str(FRONT_Z)})
    SCENE.write_text(s)


if __name__ == "__main__":
    main()
