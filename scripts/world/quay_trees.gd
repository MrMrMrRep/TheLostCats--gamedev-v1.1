@tool
class_name QuayTrees
extends Node2D
## Elms on the quay edge between the cobbles and the water, in front of the
## band and the traffic (drawn after them), from the SpriteCook canal kit at
## 1 texel = 1 art px. They keep clear of doors, the bikes, parcels, P spots,
## the band's start and the openings in the house row, so nothing you need
## is hidden.
## Origin: x 0, y = the street line.

const ELMS: Array[StringName] = [&"elm_0", &"elm_1", &"elm_2", &"elm_3", &"elm_4"]
const FOOT := 44                            # art px below the street line: the cobbles' canal edge
const CLEAR := 46.0                         # world px kept free either side of a door, bikes, parcel
const CLEAR_OPENING := 70.0                 # world px either side of an opening's middle

@export var span := Vector2(9884, 16436):   ## world x range
	set(value):
		span = value
		_spots = []
		queue_redraw()
@export var spacing := Vector2(230, 380):   ## world px between two trees (min, max)
	set(value):
		spacing = value
		_spots = []
		queue_redraw()
@export var seed_value := 5:
	set(value):
		seed_value = value
		_spots = []
		queue_redraw()

var _spots: Array = []                      # [world x, elm, flip]


func _ready() -> void:
	queue_redraw()


func _keep_clear() -> Array[Vector2]:
	var out: Array[Vector2] = []
	if not is_inside_tree():
		return out
	var root: Node = get_tree().edited_scene_root if Engine.is_editor_hint() else owner
	if root == null:
		root = get_parent()
	for n in root.find_children("*", "", true, false):
		var x := (n as Node2D).global_position.x if n is Node2D else 0.0
		if n is Interactable or n is Package or n is Marker2D:   # doors, bikes, van, parcels, the band's start
			out.append(Vector2(x - CLEAR, x + CLEAR))
		elif n is ParkingSpot:
			var half: float = n.width * 0.5 + 30.0
			out.append(Vector2(x - half, x + half))
		elif n is SideOpening:
			out.append(Vector2(x - CLEAR_OPENING, x + CLEAR_OPENING))
	return out


func spots() -> Array:
	if not _spots.is_empty():
		return _spots
	var clear := _keep_clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var x := span.x + rng.randf_range(40, 160)
	while x < span.y - 40:
		var ok := true
		for r in clear:
			if x > r.x - 30.0 and x < r.y + 30.0:
				ok = false
				break
		if ok:
			_spots.append([x, ELMS[rng.randi_range(0, ELMS.size() - 1)], rng.randf() < 0.5])
			x += rng.randf_range(spacing.x, spacing.y)
		else:
			x += 24.0
	return _spots


func _draw() -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	for s: Array in spots():
		var tex := CanalRow.texture(s[1])
		var w := tex.get_width()
		var h := tex.get_height()
		var ax := roundf(float(s[0]) * 2.0 - global_position.x * 2.0)
		if s[2]:
			draw_set_transform(Vector2(ax * 0.5, 0.0), 0.0, Vector2(-0.5, 0.5))
			draw_texture(tex, Vector2(-w / 2, FOOT - h))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
		else:
			draw_texture(tex, Vector2(ax - w / 2, FOOT - h))
	draw_set_transform(Vector2.ZERO)
