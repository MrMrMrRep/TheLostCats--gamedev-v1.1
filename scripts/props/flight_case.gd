@tool
class_name FlightCase
extends CharacterBody2D
## Heavy band flight case: everyone can stand on it, only Jay can move it
## (push by walking into it, pull while holding A). Falls with gravity.

const GRAVITY := 900.0
const SIZE := Vector2(24, 24)

var _push := 0.0
var _start_position := Vector2.ZERO


func _ready() -> void:
	collision_layer = (1 << 0) | (1 << 6)   # world (solid for everyone) + pushable
	collision_mask = (1 << 0) | (1 << 1)    # world + one_way
	floor_snap_length = 4.0
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = SIZE - Vector2(0.5, 0)
	col.shape = rect
	col.position = Vector2(0, -SIZE.y / 2.0)
	add_child(col)
	_start_position = position
	if not Engine.is_editor_hint():
		add_to_group(&"resettable")


## Move this frame at `speed` px/s (called by Jay every frame he pushes/pulls).
func push(speed: float) -> void:
	_push = speed


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	velocity.x = _push if _push != 0.0 else move_toward(velocity.x, 0.0, 800.0 * delta)
	_push = 0.0
	velocity.y = 0.0 if is_on_floor() else minf(velocity.y + GRAVITY * delta, 400.0)
	move_and_slide()


func reset_state() -> void:
	position = _start_position
	velocity = Vector2.ZERO
	_push = 0.0


func _draw() -> void:
	var r := Rect2(-SIZE.x / 2.0, -SIZE.y, SIZE.x, SIZE.y)
	draw_rect(r, Color("1c1c22"))
	draw_rect(r, Color("9aa0aa"), false, 1.0)
	for c in [Vector2(r.position), Vector2(r.end.x - 3, r.position.y), Vector2(r.position.x, r.end.y - 3), r.end - Vector2(3, 3)]:
		draw_rect(Rect2(c, Vector2(3, 3)), Color("c8ccd4"))
	draw_rect(Rect2(-6, -14, 12, 3), Color("c8ccd4"))  # handle
