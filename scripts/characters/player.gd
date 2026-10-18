class_name Player
extends CharacterBody2D
## Baseline platformer controller (M2): run, jump, gravity and animation states.
## Tuned by outcome (tiles, seconds); gravity and jump speed are derived from them.
## M3 adds coyote time, jump buffer, variable jump, apex hang and corner correction.

const TILE := 24.0

@export_group("Run")
@export var run_speed_tiles := 7.0          ## top speed in tiles per second
@export var accel_time := 0.08              ## seconds from standstill to top speed
@export var decel_time := 0.06              ## seconds from top speed to standstill
@export var air_control := 0.8              ## acceleration multiplier while airborne

@export_group("Jump")
@export var jump_height_tiles := 3.0        ## apex height in tiles
@export var time_to_apex := 0.34            ## seconds from takeoff to apex
@export var fall_gravity_mult := 1.8        ## heavier fall for a snappy, non-floaty arc
@export var max_fall_tiles := 18.0          ## terminal fall speed in tiles per second

var facing := 1.0

var _gravity: float
var _jump_velocity: float
var _was_on_floor := true
var _anim_lock := false                     # true while a one-shot (jump_start, land) plays

@onready var sprite: AnimatedSprite2D = $Sprite


func _ready() -> void:
	_recalculate()
	sprite.animation_finished.connect(_on_animation_finished)


## Derive physics from the feel values: h = g*t^2/2 and v = g*t.
func _recalculate() -> void:
	var height := jump_height_tiles * TILE
	_gravity = 2.0 * height / (time_to_apex * time_to_apex)
	_jump_velocity = -2.0 * height / time_to_apex


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()

	# Jump.
	if on_floor and Input.is_action_just_pressed("jump"):
		velocity.y = _jump_velocity
		on_floor = false
		_play_once(&"jump_start")

	# Gravity, half before and half after the move (trapezoid step), so the
	# apex lands exactly on jump_height_tiles at any frame rate.
	if not on_floor:
		_apply_gravity(delta * 0.5)

	# Horizontal: reach top speed in accel_time, stop in decel_time.
	var dir := Input.get_axis("move_left", "move_right")
	var top := run_speed_tiles * TILE
	var control := 1.0 if on_floor else air_control
	if dir != 0.0:
		facing = signf(dir)
		velocity.x = move_toward(velocity.x, dir * top, top / accel_time * control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, top / decel_time * control * delta)

	move_and_slide()
	if not is_on_floor():
		_apply_gravity(delta * 0.5)
	_update_animation()


## Heavier gravity on the way down; capped at terminal fall speed.
func _apply_gravity(step: float) -> void:
	var g := _gravity * (fall_gravity_mult if velocity.y > 0.0 else 1.0)
	velocity.y = minf(velocity.y + g * step, max_fall_tiles * TILE)


func _update_animation() -> void:
	var on_floor := is_on_floor()
	sprite.flip_h = facing < 0.0

	if on_floor and not _was_on_floor and absf(velocity.x) < 1.0:
		_play_once(&"land")
	_was_on_floor = on_floor

	if _anim_lock:
		# Running or falling cancels a one-shot.
		if on_floor and absf(velocity.x) > 1.0 and sprite.animation == &"land":
			_anim_lock = false
		elif not on_floor and velocity.y > 0.0:
			_anim_lock = false
		else:
			return

	if on_floor:
		_play(&"run" if absf(velocity.x) > 1.0 else &"idle")
	else:
		_play(&"jump" if velocity.y < 0.0 else &"fall")


func _play(anim: StringName) -> void:
	if sprite.animation != anim:
		sprite.play(anim)


func _play_once(anim: StringName) -> void:
	_anim_lock = true
	sprite.play(anim)


func _on_animation_finished() -> void:
	_anim_lock = false
