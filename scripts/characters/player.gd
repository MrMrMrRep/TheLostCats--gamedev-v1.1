class_name Player
extends CharacterBody2D
## Celeste-style platformer controller (M3). All feel numbers come from the
## MovementProfile: run accel/decel, derived gravity, fall multiplier, apex hang,
## coyote time, jump buffer, variable jump cut, corner and ledge correction,
## fast fall and drop-through on one-way platforms (down + jump).

signal jumped
signal landed(fall_speed: float)

const TILE := 24.0
const ONE_WAY_LAYER := 1 << 1               # physics layer 2 "one_way"
const DROP_THROUGH_TIME := 0.2

@export var profile: MovementProfile: set = set_profile
@export var stamina_config: StaminaConfig

var facing := 1.0
var input_enabled := true

var coyote_left: float:
	get:
		return _coyote
var buffer_left: float:
	get:
		return _buffer

var _gravity := 0.0
var _jump_velocity := 0.0
var _coyote := 0.0
var _buffer := 0.0
var _jump_held := false                     # rising from a jump; releasing jump cuts it
var _drop_timer := 0.0
var _was_on_floor := true
var _anim_lock := false                     # true while a one-shot (jump_start, land) plays

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var stamina: StaminaComponent = $Stamina


func _ready() -> void:
	sprite.animation_finished.connect(_on_animation_finished)
	_apply_profile()


func set_profile(value: MovementProfile) -> void:
	profile = value
	if is_node_ready():
		_apply_profile()


func _apply_profile() -> void:
	if profile == null:
		return
	_gravity = profile.gravity()
	_jump_velocity = profile.jump_velocity()
	sprite.modulate = profile.tint
	stamina.settings = stamina_config.for_member(profile.id) if stamina_config else null


func _physics_process(delta: float) -> void:
	var on_floor := is_on_floor()
	var dir := Input.get_axis("move_left", "move_right") if input_enabled else 0.0
	var down := input_enabled and Input.is_action_pressed("move_down")
	var jump_down := input_enabled and Input.is_action_pressed("jump")

	# Forgiveness timers.
	_coyote = profile.coyote_time if on_floor else maxf(_coyote - delta, 0.0)
	if input_enabled and Input.is_action_just_pressed("jump"):
		_buffer = profile.jump_buffer
	else:
		_buffer = maxf(_buffer - delta, 0.0)
	if _drop_timer > 0.0:
		_drop_timer -= delta
		set_collision_mask_value(2, _drop_timer <= 0.0)

	# Jump (buffered, with coyote time) or drop through a one-way platform.
	if _buffer > 0.0 and _coyote > 0.0:
		if down and on_floor and _standing_on_one_way():
			_drop_through()
		else:
			_jump()
		_buffer = 0.0
		_coyote = 0.0
		on_floor = false

	# Variable jump: releasing early cuts the rise.
	if _jump_held and (not jump_down or velocity.y >= 0.0):
		if velocity.y < 0.0:
			velocity.y *= profile.jump_cut
		_jump_held = false

	# Horizontal: reach top speed in accel_time, stop in decel_time.
	var top := profile.run_speed()
	var control := 1.0 if on_floor else profile.air_control
	if dir != 0.0:
		facing = signf(dir)
		velocity.x = move_toward(velocity.x, dir * top, top / profile.accel_time * control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, top / profile.decel_time * control * delta)

	# Gravity half before and half after the move (trapezoid step): the apex
	# lands exactly on jump_height_tiles at any frame rate.
	if not on_floor:
		_apply_gravity(delta * 0.5, jump_down, down)
	var air_speed := velocity.y
	_correct_corners(delta)
	move_and_slide()
	if not is_on_floor():
		_apply_gravity(delta * 0.5, jump_down, down)

	if is_on_floor() and not _was_on_floor:
		landed.emit(air_speed)
	stamina.grounded = is_on_floor()
	_update_animation()


func _jump() -> void:
	velocity.y = _jump_velocity
	_jump_held = true
	_play_once(&"jump_start")
	jumped.emit()


func _drop_through() -> void:
	set_collision_mask_value(2, false)
	_drop_timer = DROP_THROUGH_TIME
	position.y += 1.0
	velocity.y = maxf(velocity.y, 40.0)


func _standing_on_one_way() -> bool:
	var hit := move_and_collide(Vector2(0, 2), true)
	return hit != null and (PhysicsServer2D.body_get_collision_layer(hit.get_collider_rid()) & ONE_WAY_LAYER) != 0


## Fall faster than you rise; float near the apex while jump is held.
func _apply_gravity(step: float, jump_down: bool, fast_fall: bool) -> void:
	var g := _gravity
	if jump_down and absf(velocity.y) < profile.apex_threshold:
		g *= profile.apex_hang_mult
	elif velocity.y > 0.0:
		g *= profile.fall_gravity_mult
	var cap := (profile.fast_fall_tiles if fast_fall else profile.max_fall_tiles) * TILE
	velocity.y = minf(velocity.y + g * step, cap)


## Nudge near-misses through instead of failing them.
func _correct_corners(delta: float) -> void:
	var motion := velocity * delta
	# Rising into a ceiling edge: slide sideways up to N px.
	if motion.y < 0.0 and test_move(global_transform, Vector2(0, motion.y)):
		var first := facing if velocity.x == 0.0 else signf(velocity.x)
		for i in range(1, profile.ceiling_correction_px + 1):
			for side in [first, -first]:
				var shift := Vector2(i * side, 0)
				if not test_move(global_transform, shift) \
						and not test_move(global_transform.translated(shift), Vector2(0, motion.y)):
					position.x += shift.x
					return
	# Moving sideways into a ledge top in the air: pop up N px.
	if motion.x != 0.0 and not is_on_floor() and test_move(global_transform, Vector2(motion.x, 0)):
		for i in range(1, profile.ledge_correction_px + 1):
			var up := Vector2(0, -i)
			if not test_move(global_transform, up) \
					and not test_move(global_transform.translated(up), Vector2(motion.x, 0)):
				position.y -= i
				return


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
