class_name JTCSpriteData
extends RefCounted
## Reads <member>.json from the TheLostCats sprite pipeline: per-frame hurt/hit boxes and spawn events.
## Boxes come back in node-local pixels (origin = feet), already mirrored when facing left.

const CELL := 96
const ORIGIN := Vector2(48, 95)

var animations: Dictionary = {}


static func load_member(json_path: String) -> JTCSpriteData:
	var data := JTCSpriteData.new()
	var parsed = JSON.parse_string(FileAccess.get_file_as_string(json_path))
	if typeof(parsed) == TYPE_DICTIONARY:
		data.animations = parsed.get("animations", {})
	else:
		push_error("JTCSpriteData: cannot parse %s" % json_path)
	return data


func _to_local(r: Array, flip: bool) -> Rect2:
	var x: float = r[0]
	if flip:
		x = CELL - r[0] - r[2]
	return Rect2(Vector2(x, r[1]) - ORIGIN, Vector2(r[2], r[3]))


## Returns {"hurt": Rect2, "hit": Rect2 (only on active frames), "body": Rect2}
func get_boxes(anim: String, frame: int, flip: bool = false) -> Dictionary:
	var a: Dictionary = animations.get(anim, {})
	var boxes: Array = a.get("boxes", [])
	if frame < 0 or frame >= boxes.size():
		return {}
	var out := {}
	for key in boxes[frame].keys():
		out[key] = _to_local(boxes[frame][key], flip)
	return out


func is_active(anim: String, frame: int) -> bool:
	return frame in animations.get(anim, {}).get("active_frames", [])


## Returns {"frame": int, "object": String, "point": Vector2 (local)} or {}
func get_spawn(anim: String, flip: bool = false) -> Dictionary:
	var s: Dictionary = animations.get(anim, {}).get("spawn", {})
	if s.is_empty():
		return {}
	var p := Vector2(s.point[0], s.point[1])
	if flip:
		p.x = CELL - p.x
	return {"frame": int(s.frame), "object": String(s.object), "point": p - ORIGIN}
