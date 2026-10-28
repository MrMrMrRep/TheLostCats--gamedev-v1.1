@tool
class_name FlightCase
extends CharacterBody2D
## Heavy band flight case: everyone can stand on it, only Jay can move it.
## He pushes it by walking into it, lifts it over his head and throws it
## (special), and his slap bass shoves it away (blast()). Falls with gravity.
## In the "timed" group (The Germ can freeze and rewind it).

const GRAVITY := 900.0
const SIZE := Vector2(24, 24)
const SOLID_LAYERS := (1 << 0) | (1 << 6)   # world (solid for everyone) + pushable

var carried := false                        # over Jay's head: no collision, he places it

var _push := 0.0
var _flying := false                        # thrown or blasted: keeps its speed until it lands
var _start_position := Vector2.ZERO


func _ready() -> void:
	collision_layer = SOLID_LAYERS
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
		add_to_group(&"timed")


## Move this frame at `speed` px/s (called by Jay every frame he pushes).
func push(speed: float) -> void:
	_push = speed


## Jay picks it up: it stops colliding and he carries it.
func lift() -> void:
	carried = true
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	_flying = false


## Thrown (or dropped) from Jay's hands with `impulse` px/s.
func throw(impulse: Vector2) -> void:
	carried = false
	collision_layer = SOLID_LAYERS
	collision_mask = (1 << 0) | (1 << 1)
	velocity = impulse
	_flying = true


## Shoved by the slap bass.
func blast(impulse: Vector2) -> void:
	if carried:
		return
	velocity = impulse
	_flying = true


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or carried:
		return
	if _flying:
		velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
		move_and_slide()
		if is_on_floor() and velocity.y >= 0.0:
			_flying = false
			velocity.x = 0.0
		elif is_on_wall():
			velocity.x = 0.0
		return
	velocity.x = _push if _push != 0.0 else move_toward(velocity.x, 0.0, 800.0 * delta)
	_push = 0.0
	velocity.y = 0.0 if is_on_floor() else minf(velocity.y + GRAVITY * delta, 400.0)
	move_and_slide()


func reset_state() -> void:
	carried = false
	collision_layer = SOLID_LAYERS
	collision_mask = (1 << 0) | (1 << 1)
	position = _start_position
	velocity = Vector2.ZERO
	_push = 0.0
	_flying = false


func time_state() -> Array:
	return [_flying]


func set_time_state(state: Array) -> void:
	_flying = state[0]


func _draw() -> void:
	var r := Rect2(-SIZE.x / 2.0, -SIZE.y, SIZE.x, SIZE.y)
	draw_rect(r, Color("1c1c22"))
	draw_rect(r, Color("9aa0aa"), false, 1.0)
	for c in [Vector2(r.position), Vector2(r.end.x - 3, r.position.y), Vector2(r.position.x, r.end.y - 3), r.end - Vector2(3, 3)]:
		draw_rect(Rect2(c, Vector2(3, 3)), Color("c8ccd4"))
	draw_rect(Rect2(-6, -14, 12, 3), Color("c8ccd4"))  # handle
