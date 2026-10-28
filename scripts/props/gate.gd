@tool
class_name Gate
extends StaticBody2D
## Something a switch turns on or off: a gate (solid until opened) or a bridge
## (not there until extended). trigger() flips it. Origin = bottom-left for a
## bridge's walking surface; bottom-centre for a gate. Resets on death.

enum Style { GATE, BRIDGE }

@export var style := Style.GATE:
	set(value):
		style = value
		queue_redraw()
@export var size := Vector2(12, 48):
	set(value):
		size = value
		_update_shape()
		queue_redraw()
@export var solid := true:
	set(value):
		solid = value
		if _shape:
			_shape.set_deferred("disabled", not solid)
		queue_redraw()

var _start_solid := true
var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 1 << 0                # world
	collision_mask = 0
	_shape = CollisionShape2D.new()
	_shape.shape = RectangleShape2D.new()
	add_child(_shape)
	_update_shape()
	_shape.disabled = not solid
	_start_solid = solid
	if not Engine.is_editor_hint():
		add_to_group(&"resettable")


func trigger() -> void:
	solid = not solid


## A gate opens / a bridge extends (for switches that only ever open).
func open() -> void:
	solid = style == Style.BRIDGE


## An alarm shuts the gate (security camera).
func close() -> void:
	solid = style == Style.GATE


func reset_state() -> void:
	solid = _start_solid


func _rect() -> Rect2:
	if style == Style.BRIDGE:
		return Rect2(0, -size.y, size.x, size.y)
	return Rect2(-size.x / 2.0, -size.y, size.x, size.y)


func _update_shape() -> void:
	if _shape:
		var r := _rect()
		(_shape.shape as RectangleShape2D).size = r.size
		_shape.position = r.get_center()


func _draw() -> void:
	var r := _rect()
	if style == Style.BRIDGE:
		if solid:
			var x := r.position.x
			while x < r.end.x:
				draw_rect(Rect2(x, r.position.y, 7, r.size.y), Color("8a6a42"))
				x += 8.0
			draw_line(r.position, Vector2(r.end.x, r.position.y), Color("4a3420"), 1.0)
		else:
			draw_rect(r, Color(1, 1, 1, 0.12), false, 1.0)
	else:
		if solid:
			draw_rect(r, Color("3a3a44"))
			var x := r.position.x + 2
			while x < r.end.x:
				draw_line(Vector2(x, r.position.y), Vector2(x, r.end.y), Color("8a8a96"), 1.0)
				x += 4.0
		else:
			draw_rect(Rect2(r.position, Vector2(r.size.x, 4)), Color("3a3a44"))
