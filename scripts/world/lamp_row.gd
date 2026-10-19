@tool
class_name WorldLampRow
extends Node2D
## A row of motorway lamp posts in the median, lit at night: drag it, set
## `length` and `spacing`. Origin = the west end on the street line.

@export var length := 2000.0:
	set(value):
		length = maxf(value, 0.0)
		_rebuild()
@export var spacing := 160.0:
	set(value):
		spacing = maxf(value, 40.0)
		_rebuild()
@export var height := 64.0:                 ## px from the median to the arms
	set(value):
		height = value
		_rebuild()

const POST := Color("8a8f99")
const HEAD := Color("f6e8b0")
const ARM := 13.0

var _glow: NightGlow


func _ready() -> void:
	_glow = NightGlow.attach(self)
	_rebuild()


func _rebuild() -> void:
	queue_redraw()
	if _glow == null:
		return
	_glow.clear()
	var x := 0.0
	while x <= length:
		for side in [-1.0, 1.0]:
			var head := Vector2(x + side * ARM, -height + 1.5)
			var t := 0.03 + NightGlow.spot_hash(global_position.x + x, side) * 0.1
			_glow.add_halo(head, 14.0, t, Color(1.0, 0.92, 0.72, 0.6))
			# Pools on the carriageways: ours (in front, east-bound side) and the far one.
			_glow.add_halo(Vector2(head.x + side * 6.0, 11.0 if side > 0.0 else -6.0), 30.0, t, Color(1.0, 0.88, 0.6, 0.28), 0.18)
		x += spacing
	_glow.queue_redraw()


func _draw() -> void:
	var x := 0.0
	while x <= length:
		draw_rect(Rect2(x - 1, -height, 2, height - 2), POST)
		draw_rect(Rect2(x - 2, -4, 4, 3), POST.darkened(0.25))
		draw_rect(Rect2(x - ARM, -height, ARM * 2.0, 1), POST)
		for side in [-1.0, 1.0]:
			draw_rect(Rect2(x + side * ARM - 3, -height + 1, 6, 1), HEAD)
		x += spacing
