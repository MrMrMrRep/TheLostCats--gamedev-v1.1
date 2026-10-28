@tool
class_name MovingPlatform
extends AnimatableBody2D
## A platform sliding back and forth between its start and start + `travel`
## (one round trip every `period` seconds). Members standing on it ride along.
## It's in the "timed" group: The Germ can stop it where he wants it, or
## rewind it. Origin = top-left of the walking surface. Resets on death.

@export var travel := Vector2(96, 0):
	set(value):
		travel = value
		queue_redraw()
@export var period := 4.0
@export var size := Vector2(48, 8):
	set(value):
		size = value
		_update_shape()
		queue_redraw()

var t := 0.0

var _start := Vector2.ZERO
var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 1 << 0                # world
	collision_mask = 0
	sync_to_physics = true
	_shape = CollisionShape2D.new()
	_shape.shape = RectangleShape2D.new()
	add_child(_shape)
	_update_shape()
	_start = position
	if not Engine.is_editor_hint():
		add_to_group(&"resettable")
		add_to_group(&"timed")


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	t = fmod(t + delta, period)
	_place()


func reset_state() -> void:
	t = 0.0
	_place()


func time_state() -> Array:
	return [t]


func set_time_state(state: Array) -> void:
	t = state[0]
	_place()


func _place() -> void:
	var u := 0.5 - 0.5 * cos(t / period * TAU)   # ease in and out at both ends
	position = _start + travel * u


func _update_shape() -> void:
	if _shape:
		(_shape.shape as RectangleShape2D).size = size
		_shape.position = size / 2.0


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, size), Color("5a5f6a"))
	draw_rect(Rect2(0, 0, size.x, 2), Color("9aa0a8"))
	if Engine.is_editor_hint():
		draw_rect(Rect2(travel, size), Color(1, 1, 1, 0.25), false, 1.0)
