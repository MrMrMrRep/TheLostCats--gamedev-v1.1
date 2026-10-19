@tool
class_name WorldZone
extends Node2D
## A stretch of the world map (one district) that tells the street what goes on
## there: how many people walk by, whether cars may drive (or only bikes), and
## whether cars stand parked along the street. Drag it, and set `length` to
## resize it (the orange handle line shows its east end). Only visible in the
## editor. Zones may touch but shouldn't overlap (the first one wins).
## Speeds and the overall mix: resources/config/traffic_config.tres and
## people_config.tres.

@export var length := 1000.0:
	set(value):
		length = maxf(value, 10.0)
		queue_redraw()
@export var people_per_screen := 0.0:       ## walkers per screen width (0 = nobody)
	set(value):
		people_per_screen = value
		queue_redraw()
@export var bikes_only := false:            ## no cars: only bikes ride here (old town, canal belt)
	set(value):
		bikes_only = value
		queue_redraw()
@export var parked_cars := false:           ## cars parked along the street
	set(value):
		parked_cars = value
		queue_redraw()
@export var color := Color(0.3, 0.7, 1.0):
	set(value):
		color = value
		queue_redraw()


func _enter_tree() -> void:
	add_to_group(&"world_zone")
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED:
		queue_redraw()


func span() -> Vector2:
	return Vector2(global_position.x, global_position.x + length)


## All zones in the scene of `node`, west to east.
static func all(node: Node) -> Array[WorldZone]:
	var out: Array[WorldZone] = []
	if node.is_inside_tree():
		for z in node.get_tree().get_nodes_in_group(&"world_zone"):
			if z is WorldZone and z.is_visible_in_tree():
				out.append(z)
	out.sort_custom(func(a: WorldZone, b: WorldZone) -> bool: return a.global_position.x < b.global_position.x)
	return out


## World x ranges of the zones where `pick` is true; touching ranges joined.
static func ranges(node: Node, pick: Callable) -> Array[Vector2]:
	var out: Array[Vector2] = []
	for z in all(node):
		if not pick.call(z):
			continue
		var r := z.span()
		if not out.is_empty() and r.x <= out[-1].y + 0.5:
			out[-1].y = maxf(out[-1].y, r.y)
		else:
			out.append(r)
	return out


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var y := 46.0                           # a band just under the street, above the water's reflection
	draw_rect(Rect2(0, y, length, 14), Color(color, 0.28))
	draw_rect(Rect2(0, y, length, 14), Color(color, 0.9), false, 1.0)
	draw_rect(Rect2(length - 2, y - 30, 2, 44), Color(1.0, 0.55, 0.1, 0.9))   # east end
	var bits: Array[String] = [String(name)]
	bits.append("%s people" % str(people_per_screen))
	if bikes_only:
		bits.append("bikes only")
	if parked_cars:
		bits.append("parked cars")
	draw_string(ThemeDB.fallback_font, Vector2(4, y + 11), "  ·  ".join(bits), HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color.WHITE)
