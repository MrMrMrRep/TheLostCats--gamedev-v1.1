@tool
class_name WorldMarker
extends Node2D
## A rule line on the world map, dragged left/right in the editor (only its x
## counts). The WorldMap reads the markers in its Markers folder by name:
##   FootLimit         west of it is motorway: no walking or cycling
##   ScenicFrom        west of it the van's view opens up (the road trip)
##   RoadTransition    the city street begins here (west of it: motorway look,
##                     motorway traffic, the van keeps to its lane)
##   SpeedLimitStart / SpeedLimitEnd   the van keeps to the city speed between them
##   TownWest / TownEast               the city (no birds; background skyline)
##   CanalStart        the canal water begins here
## Don't rename them. A marker can also push its x into other nodes while you
## drag it (`targets`), so e.g. the street's look moves along with
## RoadTransition. Only visible in the editor.

@export var label := "":                    ## text on the flag (empty = the node name)
	set(value):
		label = value
		queue_redraw()
@export var color := Color(1.0, 0.85, 0.2):
	set(value):
		color = value
		queue_redraw()
## Nodes that get this marker's x while you drag it (in the editor).
@export var targets: Array[NodePath] = []
## Property set on each target: a float, a Vector2's x ("town:x") or y
## ("town:y"), or "left_edge" for a water strip (moves its left side only).
@export var target_property := ""


func _enter_tree() -> void:
	set_notify_transform(true)


func _notification(what: int) -> void:
	if what == NOTIFICATION_TRANSFORM_CHANGED and Engine.is_editor_hint():
		queue_redraw()
		apply()


## Push this marker's x into the targets.
func apply() -> void:
	if target_property == "" or not is_inside_tree():
		return
	var x := global_position.x
	for path in targets:
		var t := get_node_or_null(path)
		if t == null:
			continue
		if target_property == "left_edge" and t is Control:
			var right: float = t.position.x + t.size.x
			var gx: float = (t.get_parent() as Node2D).to_local(Vector2(x, 0)).x if t.get_parent() is Node2D else x
			if absf(t.position.x - gx) > 0.01:
				t.position.x = gx
				t.size.x = right - gx
		elif target_property.contains(":"):
			var parts := target_property.split(":")
			var v: Variant = t.get(parts[0])
			if v is Vector2:
				var axis := 1 if parts[1] == "y" else 0
				if absf(v[axis] - x) > 0.01:
					v[axis] = x
					t.set(parts[0], v)
					_refresh(t)
		elif absf(float(t.get(target_property)) - x) > 0.01:
			t.set(target_property, x)
			_refresh(t)


func _refresh(t: Node) -> void:
	if t.has_method("_plan"):
		t.call("_plan")
	if t is CanvasItem:
		t.queue_redraw()


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	var top := -260.0
	draw_line(Vector2(0, top), Vector2(0, 120), Color(color, 0.85), 2.0)
	for y in range(int(top), 120, 16):              # dashes so it reads as a guide, not art
		draw_line(Vector2(-4, y), Vector2(4, y), Color(color, 0.5), 1.0)
	var text := label if label != "" else String(name)
	var font := ThemeDB.fallback_font
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_rect(Rect2(2, top, w + 8, 16), Color(0, 0, 0, 0.7))
	draw_rect(Rect2(2, top, w + 8, 16), color, false, 1.0)
	draw_string(font, Vector2(6, top + 12), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, color)
