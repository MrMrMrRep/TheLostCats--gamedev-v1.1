class_name Bubble
extends Node2D
## A bubble from Geoff's toy bubble gun: flies forward with a bob for a few
## seconds. Does no damage; people who can be distracted (Bouncer with
## `distractible`) within DISTRACT_RADIUS look at it and drift after it.
## Rats and machines don't care.

const SPEED := 110.0
const SLOW_DOWN := 70.0                     # px/s^2: it drifts to a float
const LIFETIME := 2.5
const DISTRACT_RADIUS := 96.0

var direction := 1.0

var _age := 0.0
var _speed := SPEED
var _base_y := NAN


func _physics_process(delta: float) -> void:
	if is_nan(_base_y):
		_base_y = global_position.y
	_age += delta
	_speed = maxf(_speed - SLOW_DOWN * delta, 25.0)
	global_position.x += direction * _speed * delta
	global_position.y = _base_y - _age * 6.0 + sin(_age * 5.0) * 2.0
	for h in get_tree().get_nodes_in_group(&"human"):
		if h.global_position.distance_to(global_position) <= DISTRACT_RADIUS and h.has_method("distract"):
			h.distract(global_position, 0.6)
	queue_redraw()
	if _age >= LIFETIME:
		queue_free()


func _draw() -> void:
	var a := clampf((LIFETIME - _age) / 0.4, 0.0, 1.0)
	draw_arc(Vector2.ZERO, 5.0, 0.0, TAU, 16, Color(0.8, 0.95, 1.0, 0.9 * a), 1.0)
	draw_circle(Vector2(-1.5, -1.5), 1.2, Color(1, 1, 1, 0.8 * a))
