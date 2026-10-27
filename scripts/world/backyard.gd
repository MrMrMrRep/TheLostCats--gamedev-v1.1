@tool
class_name WorldBackyard
extends Node2D
## Trees in the yards behind the house rows. The node sits on the street line
## with a lower z than the facades, so the trunks disappear behind the walls
## and the crowns show over the roofs.

const TREES: Array[Texture2D] = [
	preload("res://assets/sprites/world/canal/yard0.png"),
	preload("res://assets/sprites/world/canal/yard1.png"),
	preload("res://assets/sprites/world/canal/yard2.png"),
]
const YARD_KINDS: Array[int] = [
	WorldBuilding.Kind.HOTEL, WorldBuilding.Kind.ROUND_HOTEL, WorldBuilding.Kind.APARTMENTS,
	WorldBuilding.Kind.THEATER, WorldBuilding.Kind.CHURCH,
]

var _spots: Array = []


func _ready() -> void:
	z_index = -1
	position = Vector2(0.0, WorldMap.GROUND_Y)
	_gather()


func _gather() -> void:
	_spots.clear()
	var buildings := get_parent()
	if buildings == null:
		return
	for n in buildings.find_children("*", "CityBlock", true, false):
		_block(n as CityBlock)
	for n in buildings.find_children("*", "WorldBuilding", true, false):
		var b := n as WorldBuilding
		if b.kind in YARD_KINDS:
			_building(b)
	queue_redraw()


func _block(b: CityBlock) -> void:
	var rows := b.layout()
	if rows.is_empty():
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = b.seed_value * 13 + 7
	var n := clampi(rows.size() / 3, 1, 3)
	var step := maxi(int(rows.size() / float(n)), 1)
	var x := 0.0
	var placed := 0
	var origin := to_local(b.global_position).x
	for i in rows.size():
		var d: Dictionary = rows[i]
		var w: float = d.w
		if placed < n and i % step == step / 2:
			var hh := w * 2.15
			_spots.append({
				"x": origin + x + w * 0.5,
				"h": hh * rng.randf_range(1.28, 1.55),
				"t": rng.randi() % TREES.size(),
				"flip": rng.randf() < 0.5,
			})
			placed += 1
		x += w


func _building(b: WorldBuilding) -> void:
	var w := b.width()
	if w < 40.0:
		return
	var rng := RandomNumberGenerator.new()
	rng.seed = b.seed_value * 29 + int(b.kind)
	var n := clampi(int(w / 150.0), 1, 4)
	var origin := to_local(b.global_position).x
	var gap := w / float(n + 1)
	for i in n:
		_spots.append({
			"x": origin + gap * float(i + 1),
			"h": rng.randf_range(210.0, 265.0),
			"t": rng.randi() % TREES.size(),
			"flip": rng.randf() < 0.5,
		})


func _draw() -> void:
	for s: Dictionary in _spots:
		var tex: Texture2D = TREES[int(s.t)]
		var th: float = s.h
		var tw := th * tex.get_width() / tex.get_height()
		var x: float = s.x
		if s.flip:
			draw_set_transform(Vector2(x, 0.0), 0.0, Vector2(-1.0, 1.0))
			draw_texture_rect(tex, Rect2(-tw * 0.5, -th, tw, th), false)
			draw_set_transform(Vector2.ZERO)
		else:
			draw_texture_rect(tex, Rect2(x - tw * 0.5, -th, tw, th), false)
