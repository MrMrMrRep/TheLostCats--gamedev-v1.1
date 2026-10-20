@tool
class_name Rat
extends CharacterBody2D
## Rat: patrols, turns at walls and ledges, hurts band members on touch.
## stun() and knockback() are for The Germ and Jay; defeat() removes it.
## distract() (Geoff's bubbles) makes it stop, stare and not bite.
## Placeholder art is drawn in code.

const GRAVITY := 900.0

@export var speed := 40.0
@export var start_dir := 1.0

var dir := 1.0
var stunned_left := 0.0
var distracted_left := 0.0
var alive := true

var _start_position := Vector2.ZERO
var _hurtbox: Area2D


func _ready() -> void:
	collision_layer = 1 << 3                # enemy
	collision_mask = (1 << 0) | (1 << 1)    # world + one_way
	floor_snap_length = 4.0
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 7)
	col.shape = rect
	col.position = Vector2(0, -3.5)
	add_child(col)
	_hurtbox = Area2D.new()
	_hurtbox.collision_layer = 0
	_hurtbox.collision_mask = 1 << 2        # player
	_hurtbox.monitorable = false
	var hcol := CollisionShape2D.new()
	var hrect := RectangleShape2D.new()
	hrect.size = Vector2(12, 6)
	hcol.shape = hrect
	hcol.position = Vector2(0, -3)
	_hurtbox.add_child(hcol)
	add_child(_hurtbox)
	_start_position = position
	dir = start_dir
	if not Engine.is_editor_hint():
		add_to_group(&"resettable")
		add_to_group(&"rat")


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or not alive:
		return
	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 400.0)
	distracted_left = maxf(distracted_left - delta, 0.0)
	if stunned_left > 0.0:
		stunned_left -= delta
		velocity.x = move_toward(velocity.x, 0.0, 600.0 * delta)
	elif distracted_left > 0.0:
		velocity.x = 0.0
	else:
		if is_on_floor() and (_blocked() or _ledge_ahead()):
			dir = -dir
		velocity.x = dir * speed
	move_and_slide()
	queue_redraw()
	if stunned_left <= 0.0 and distracted_left <= 0.0:
		for body in _hurtbox.get_overlapping_bodies():
			if body is BandMember and not body.is_dead:
				body.hurt(1, global_position)


func stun(seconds: float) -> void:
	stunned_left = maxf(stunned_left, seconds)


## Stare at `pos` for `seconds` (no walking, no biting).
func distract(pos: Vector2, seconds: float) -> void:
	distracted_left = maxf(distracted_left, seconds)
	dir = signf(pos.x - global_position.x) if pos.x != global_position.x else dir


func knockback(impulse: Vector2) -> void:
	velocity = impulse
	stun(0.6)


func defeat() -> void:
	if alive:
		Audio.sfx(&"squeak")
		GameFeel.hit_stop(get_tree())
	alive = false
	visible = false
	set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)


func reset_state() -> void:
	alive = true
	visible = true
	process_mode = Node.PROCESS_MODE_INHERIT
	position = _start_position
	velocity = Vector2.ZERO
	dir = start_dir
	stunned_left = 0.0
	distracted_left = 0.0


func _blocked() -> bool:
	return test_move(global_transform, Vector2(dir * 2.0, 0))


func _ledge_ahead() -> bool:
	return not test_move(global_transform.translated(Vector2(dir * 10.0, 0)), Vector2(0, 8))


func _draw() -> void:
	var f := dir if not Engine.is_editor_hint() else start_dir
	var body_color := Color("4a4448") if stunned_left <= 0.0 else Color("6a6070")
	draw_line(Vector2(-6 * f, -2), Vector2(-12 * f, -4), Color("d98a9a"), 1.0)      # tail
	draw_rect(Rect2(-7, -7, 14, 7), body_color)                                       # body
	draw_rect(Rect2(5 * f - (2 if f < 0 else 0), -8, 4, 5), body_color)               # head
	draw_rect(Rect2(3 * f - (1 if f < 0 else 0), -10, 2, 2), Color("d98a9a"))          # ear
	draw_rect(Rect2(7 * f - (1 if f < 0 else 0), -6, 1, 1), Color("ff5050"))           # eye
	if distracted_left > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-3, -12), "?", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(0.8, 0.95, 1.0))
	if stunned_left > 0.0:
		draw_string(ThemeDB.fallback_font, Vector2(-6, -12), "*", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("ffd36b"))
