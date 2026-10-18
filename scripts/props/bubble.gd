class_name Bubble
extends Node2D
## Geoff's bubble: drifts forward with a bob for a few seconds. Rats within
## DISTRACT_RADIUS stop and stare at it (and don't bite) while it lasts.

const SPEED := 40.0
const LIFETIME := 2.5
const DISTRACT_RADIUS := 72.0

var direction := 1.0

var _age := 0.0
var _base_y := NAN


func _physics_process(delta: float) -> void:
	if is_nan(_base_y):
		_base_y = global_position.y
	_age += delta
	global_position.x += direction * SPEED * delta
	global_position.y = _base_y - _age * 6.0 + sin(_age * 5.0) * 2.0
	for rat in get_tree().get_nodes_in_group(&"rat"):
		if rat.alive and rat.global_position.distance_to(global_position) <= DISTRACT_RADIUS:
			rat.distract(global_position, 0.25)
	queue_redraw()
	if _age >= LIFETIME:
		queue_free()


func _draw() -> void:
	var a := clampf((LIFETIME - _age) / 0.4, 0.0, 1.0)
	draw_arc(Vector2.ZERO, 5.0, 0.0, TAU, 16, Color(0.8, 0.95, 1.0, 0.9 * a), 1.0)
	draw_circle(Vector2(-1.5, -1.5), 1.2, Color(1, 1, 1, 0.8 * a))
