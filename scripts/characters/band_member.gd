class_name BandMember
extends CharacterBody2D
## One band member: Celeste-style platformer controller plus health, stamina,
## beer and a MemberAbility (from the profile). All feel numbers come from the
## MovementProfile: run accel/decel, derived gravity, fall multiplier, apex hang,
## coyote time, jump buffer, variable jump cut, corner and ledge correction,
## fast fall and drop-through on one-way platforms (down + jump). The ability
## hooks in at fixed points: air jump, gravity, horizontal lock, full movement
## takeover, after-move and damage blocking. Only the active member reads player
## input; the Band steers inactive members through `ai_dir` (gather).

signal jumped
signal landed(fall_speed: float)
signal beers_changed(count: int)

const TILE := 24.0
const ONE_WAY_LAYER := 1 << 1               # physics layer 2 "one_way"
const DROP_THROUGH_TIME := 0.2
const HURT_LOCK_TIME := 0.25               # no control while knocked back
const KNOCKBACK := Vector2(150, -200)
const FLASH_RATE := 12.0                    # blinks per second during i-frames
const DEATH_ANIM_SPEED := 2.0               # 12-frame death anim in 0.5 s
const MAX_BEERS := 3                        # until the M7 inventory takes over

@export var profile: MovementProfile: set = set_profile
@export var stamina_config: StaminaConfig

var facing := 1.0
var is_active := false
var ai_dir := 0.0                           # horizontal input while inactive (-1..1)
var beers := 0
var anim_override: StringName = &""         # ability animation (climb, hover, shield)
var ability: MemberAbility

# Input this frame (zero when not controlled). Abilities read these.
var in_dir := 0.0
var in_vertical := 0.0                      # -1 up, +1 down
var in_jump_pressed := false
var in_jump_held := false
var in_a_pressed := false
var in_a_held := false
var in_b_pressed := false
var in_b_held := false

var coyote_left: float:
	get:
		return _coyote
var buffer_left: float:
	get:
		return _buffer
var is_dead: bool:
	get:
		return _dead

var _gravity := 0.0
var _jump_velocity := 0.0
var _coyote := 0.0
var _buffer := 0.0
var _jump_held := false                     # rising from a jump; releasing jump cuts it
var _drop_timer := 0.0
var _was_on_floor := true
var _anim_lock := false                     # true while a one-shot (jump_start, land) plays
var _hurt_lock := 0.0
var _dead := false
var _air_speed := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var stamina: StaminaComponent = $Stamina
@onready var health: HealthComponent = $Health
@onready var name_tag: Label = $NameTag


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
	health.set_max_hp(profile.max_hp)
	name_tag.text = profile.display_name
	_update_name_tag()
	if ability:
		ability.queue_free()
		ability = null
	if profile.ability:
		ability = profile.ability.new()
		ability.name = "Ability"
		add_child(ability)
		ability.setup(self)


func set_active(value: bool) -> void:
	is_active = value
	ai_dir = 0.0
	if not is_active:
		_buffer = 0.0
		_jump_held = false
		if ability:
			ability.on_deactivated()
	_update_name_tag()


## Only the active member shows a name tag; gathered tags would overlap.
func _update_name_tag() -> void:
	if is_node_ready():
		name_tag.visible = is_active
		name_tag.modulate = Color("ffd36b")


func _process(_delta: float) -> void:
	# Blink while invulnerable.
	sprite.visible = not health.is_invulnerable or int(Time.get_ticks_msec() / 1000.0 * FLASH_RATE) % 2 == 0


func _physics_process(delta: float) -> void:
	_read_input(delta)
	var on_floor := is_on_floor()

	# Forgiveness timers.
	_coyote = profile.coyote_time if on_floor else maxf(_coyote - delta, 0.0)
	_buffer = profile.jump_buffer if in_jump_pressed else maxf(_buffer - delta, 0.0)
	if _drop_timer > 0.0:
		_drop_timer -= delta
		set_collision_mask_value(2, _drop_timer <= 0.0)

	if ability:
		ability.physics_begin(delta)
		if ability.custom_physics(delta):   # climb, ground pound, shield...
			_finish_frame()
			return

	# Jump: on the ground (buffered, coyote time), drop-through, or an air jump.
	if _buffer > 0.0:
		if _coyote > 0.0:
			if in_vertical > 0.0 and on_floor and _standing_on_one_way():
				_drop_through()
			else:
				jump_with(_jump_velocity)
			_buffer = 0.0
			_coyote = 0.0
			on_floor = false
		elif ability and ability.air_jump():
			_buffer = 0.0

	# Variable jump: releasing early cuts the rise.
	if _jump_held and (not in_jump_held or velocity.y >= 0.0):
		if velocity.y < 0.0:
			velocity.y *= profile.jump_cut
		_jump_held = false

	# Horizontal: reach top speed in accel_time, stop in decel_time.
	var top := profile.run_speed() * (ability.speed_mult() if ability else 1.0)
	var control := 1.0 if on_floor else profile.air_control
	if _hurt_lock > 0.0 or (ability and ability.locks_horizontal()):
		pass                                # keep knockback / wall-jump speed
	elif in_dir != 0.0:
		facing = signf(in_dir)
		velocity.x = move_toward(velocity.x, in_dir * top, top / profile.accel_time * control * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, top / profile.decel_time * control * delta)

	# Gravity half before and half after the move (trapezoid step): the apex
	# lands exactly on jump_height_tiles at any frame rate.
	if not on_floor:
		_apply_gravity(delta * 0.5)
	_air_speed = velocity.y
	move_body(delta)
	if not is_on_floor():
		_apply_gravity(delta * 0.5)
	if ability:
		ability.physics_end(delta)
	_finish_frame()


# --- API for abilities, hazards and the level ------------------------------

func jump_with(vy: float) -> void:
	velocity.y = vy
	_jump_held = true
	_play_once(&"jump_start")
	jumped.emit()


## Corner correction + move_and_slide (abilities that take over movement use it).
func move_body(delta: float) -> void:
	_correct_corners(delta)
	move_and_slide()


func gravity_value() -> float:
	return _gravity


## One-shot animation for an ability (punch, ground pound...).
func play_action(anim: StringName) -> void:
	_play_once(anim)


## Damage from a hazard or enemy at `from`. Returns true if it landed.
func hurt(amount: int, from: Vector2) -> bool:
	if _dead:
		return false
	if ability and ability.blocks_damage(from):
		return false
	if not health.damage(amount):
		return false
	var away := signf(global_position.x - from.x)
	if away == 0.0:
		away = -facing
	velocity = Vector2(away * KNOCKBACK.x, KNOCKBACK.y)
	_hurt_lock = HURT_LOCK_TIME
	_jump_held = false
	if ability:
		ability.on_hurt()
	if health.hp > 0:
		_play_once(&"hurt")
	return true


func add_beer() -> bool:
	if beers >= MAX_BEERS:
		return false
	beers += 1
	beers_changed.emit(beers)
	return true


## Beer heals 1 HP for everyone; some members get a bonus (ability.on_beer()).
func drink_beer() -> bool:
	if beers <= 0 or _dead:
		return false
	beers -= 1
	beers_changed.emit(beers)
	health.heal(1)
	if ability:
		ability.on_beer()
	return true


## Death animation; keeps playing while the tree is paused.
func play_death() -> void:
	_dead = true
	sprite.visible = true
	sprite.process_mode = Node.PROCESS_MODE_ALWAYS
	sprite.speed_scale = DEATH_ANIM_SPEED
	_anim_lock = true
	anim_override = &""
	sprite.play(&"death")


## Back to life at `pos` with `hp`, all transient state cleared.
## `grace` gives i-frames (flashing) so a respawn can't be hit straight away.
func respawn(pos: Vector2, hp: int, grace := 0.0) -> void:
	_dead = false
	global_position = pos
	velocity = Vector2.ZERO
	ai_dir = 0.0
	_coyote = 0.0
	_buffer = 0.0
	_jump_held = false
	_hurt_lock = 0.0
	_drop_timer = 0.0
	set_collision_mask_value(2, true)
	health.restore(hp, grace)
	stamina.refill()
	if ability:
		ability.reset()
	anim_override = &""
	sprite.process_mode = Node.PROCESS_MODE_INHERIT
	sprite.speed_scale = 1.0
	sprite.visible = true
	_anim_lock = false
	sprite.play(&"idle")


# --- Internals -------------------------------------------------------------

func _read_input(delta: float) -> void:
	var controlled := is_active and _hurt_lock <= 0.0
	if _hurt_lock > 0.0:
		_hurt_lock -= delta
	if controlled:
		in_dir = Input.get_axis("move_left", "move_right")
		in_vertical = Input.get_axis("move_up", "move_down")
		in_jump_pressed = Input.is_action_just_pressed("jump")
		in_jump_held = Input.is_action_pressed("jump")
		in_a_pressed = Input.is_action_just_pressed("action_a")
		in_a_held = Input.is_action_pressed("action_a")
		in_b_pressed = Input.is_action_just_pressed("action_b")
		in_b_held = Input.is_action_pressed("action_b")
	else:
		in_dir = 0.0 if _hurt_lock > 0.0 else clampf(ai_dir, -1.0, 1.0)
		in_vertical = 0.0
		in_jump_pressed = false
		in_jump_held = false
		in_a_pressed = false
		in_a_held = false
		in_b_pressed = false
		in_b_held = false


func _finish_frame() -> void:
	if is_on_floor() and not _was_on_floor:
		landed.emit(_air_speed)
		if ability:
			ability.on_landed(_air_speed)
	stamina.grounded = is_on_floor()
	_update_animation()


func _drop_through() -> void:
	set_collision_mask_value(2, false)
	_drop_timer = DROP_THROUGH_TIME
	position.y += 1.0
	velocity.y = maxf(velocity.y, 40.0)


func _standing_on_one_way() -> bool:
	var hit := move_and_collide(Vector2(0, 2), true)
	return hit != null and (PhysicsServer2D.body_get_collision_layer(hit.get_collider_rid()) & ONE_WAY_LAYER) != 0


## Fall faster than you rise; float near the apex while jump is held.
## Abilities scale gravity and cap the fall (wall slide, hover).
func _apply_gravity(step: float) -> void:
	var g := _gravity
	if in_jump_held and absf(velocity.y) < profile.apex_threshold:
		g *= profile.apex_hang_mult
	elif velocity.y > 0.0:
		g *= profile.fall_gravity_mult
	var cap := (profile.fast_fall_tiles if in_vertical > 0.0 else profile.max_fall_tiles) * TILE
	if ability:
		g *= ability.gravity_scale()
		cap = ability.fall_cap(cap)
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

	if anim_override != &"":
		_anim_lock = false
		_play(anim_override)
		return

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
