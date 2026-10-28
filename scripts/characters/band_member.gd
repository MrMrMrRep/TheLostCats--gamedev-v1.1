class_name BandMember
extends CharacterBody2D
## One band member: Celeste-style platformer controller plus health, stamina,
## a 3-slot Inventory and a MemberAbility (from the profile). All feel numbers come from the
## MovementProfile: walk accel/decel, derived gravity, fall multiplier, apex hang,
## coyote time, jump buffer, variable jump cut, corner and ledge correction,
## fast fall and drop-through on one-way platforms (down + jump).
## Moves everyone has: walk, run (hold Shift: faster, costs stamina), crouch
## (hold down on the ground: half height, slow, fits under 1-tile gaps) and
## wall-slide (push into a wall while falling: slow slide). Punch, the special
## skill (B) and the instrument skill (L) live in the MemberAbility, which hooks
## in at fixed points: air jump, gravity, horizontal lock, full movement
## takeover, after-move and damage blocking. Only the active member reads player
## input; the Band steers inactive members through `ai_dir` / ai_jump() (gather,
## following the rolling papers). Items: R (or E with nothing near) uses the
## selected item (a beer is drunk), F gives it to a member within 1 tile, V
## drops it, T selects the next slot. On the world map (`map_mode`) only
## walking and jumping work.

signal jumped
signal landed(fall_speed: float)

const TILE := 24.0
const ONE_WAY_LAYER := 1 << 1               # physics layer 2 "one_way"
const DROP_THROUGH_TIME := 0.2
const HURT_LOCK_TIME := 0.25               # no control while knocked back
const KNOCKBACK := Vector2(150, -200)
const FLASH_RATE := 12.0                    # blinks per second during i-frames
const DEATH_ANIM_SPEED := 2.0               # 12-frame death anim in 0.5 s
const GIVE_RANGE := 24.0                    # 1 tile
const KEY_RANGE := 32.0                     # how close a locked door must be to use a key
const BEER := preload("res://resources/items/beer.tres")
const RUN_MULT := 1.35                      # running speed vs walking
const CROUCH_MULT := 0.45                   # crawling speed vs walking
const STAND_HEIGHT := 28.0
const CROUCH_HEIGHT := 14.0
const WALL_SLIDE_SPEED := 40.0              # px/s max fall while sliding down a wall
const WALL_CHECK := 2.0                     # px probe for a wall beside the member
const PLACEHOLDER_OFFSET := Vector2(0, -28)
const FIDGET_TIME := 6.0                    # idle this long -> play an instrument, drink or smoke
const FIDGET_LENGTH := 5.0                  # drinking / smoking lasts this long (the instrument until you move)
const FIDGETS: Array[StringName] = [&"idle_instrument", &"idle_drinking", &"idle_smoking", &"idle_bottle"]
# The game asks for logical animations; a sprite set without one plays the first
# alias it has (band sheets name things differently from the placeholder).
# (Older temp sheets use idle_fists, jump, attack_special, crouch.)
const ANIM_ALIASES := {
	&"idle": [&"idle_breathing", &"idle_fists"],
	&"walk": [&"run"],
	&"jump_start": [&"jump_rise", &"jump"],
	&"jump": [&"jump_rise"],
	&"apex": [&"jump_apex", &"jump"],
	&"fall": [&"jump_fall", &"jump"],
	&"land": [&"jump_land", &"crouch"],
	&"wall_slide": [&"fall"],
	&"crouch": [&"crouch_hold", &"crouch", &"jump_land"],
	&"punch": [&"attack_punch", &"use", &"attack"],
	&"special": [&"attack_special_a", &"use", &"attack"],
	&"instrument": [&"idle_instrument_loop", &"use", &"attack"],
	&"throw": [&"attack_throw", &"use", &"attack"],
	&"attack": [&"attack_special_a", &"attack_special"],
	&"air_attack": [&"attack_punch"],
	&"hurt": [&"jump_fall", &"jump"],
	&"death": [&"crouch_hold", &"crouch"],
}

@export var profile: MovementProfile: set = set_profile
@export var stamina_config: StaminaConfig

var facing := 1.0
var is_active := false
var ai_dir := 0.0                           # horizontal input while inactive (-1..1)
var show_name_tag := true                   # the zoomed-out world map hides it
var anim_override: StringName = &""         # ability animation (swing, carry...)
var anim: StringName = &"idle"              # logical animation playing (see ANIM_ALIASES)
var speed_scale := 1.0                      # world map: a calm walk instead of the level run
var map_mode := false                       # world map: walk and jump only (no run, crouch or skills)
var crouching := false
var running := false
var wall_sliding := false
var shield_left := 0.0                      # Jay's bass bubble: hits bounce off while > 0
var fidget_after := FIDGET_TIME             # idle this long before an instrument / drink / smoke
var sprite_data: JTCSpriteData              # boxes and spawn events of a band sheet, else null
var ability: MemberAbility
var inventory: Inventory

# Input this frame (zero when not controlled). Abilities read these.
var in_dir := 0.0
var in_vertical := 0.0                      # -1 up, +1 down
var in_jump_pressed := false
var in_jump_held := false
var in_a_pressed := false
var in_a_held := false
var in_b_pressed := false
var in_b_held := false
var in_instrument_pressed := false
var in_run_held := false
var in_use_pressed := false
var in_give_pressed := false
var in_drop_pressed := false
var in_next_pressed := false

var coyote_left: float:
	get:
		return _coyote
var buffer_left: float:
	get:
		return _buffer
var is_dead: bool:
	get:
		return _dead
var beers: int:
	get:
		return inventory.count(&"beer")

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
var _ai_jump_queued := false
var _ai_jump_hold := 0.0
var _placeholder_frames: SpriteFrames
var _idle_time := 0.0
var _fidget: StringName = &""               # idle variation playing (FIDGETS)
var _fidget_time := 0.0

@onready var sprite: AnimatedSprite2D = $Sprite
@onready var stamina: StaminaComponent = $Stamina
@onready var health: HealthComponent = $Health
@onready var name_tag: Label = $NameTag
@onready var _collision: CollisionShape2D = $Collision


func _ready() -> void:
	_collision.shape = _collision.shape.duplicate()   # crouching resizes it per member
	add_to_group(&"band_member")
	inventory = Inventory.new()
	inventory.name = "Inventory"
	add_child(inventory)
	sprite.animation_finished.connect(_on_animation_finished)
	_placeholder_frames = sprite.sprite_frames
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
	if profile.sprite_frames:
		sprite.sprite_frames = profile.sprite_frames
		sprite.scale = Vector2.ONE * profile.sprite_scale
		sprite.offset = profile.sprite_offset
		sprite.modulate = Color.WHITE
		sprite_data = JTCSpriteData.load_member(profile.sprite_data) if profile.sprite_data != "" else null
	else:
		sprite.sprite_frames = _placeholder_frames
		sprite.scale = Vector2.ONE
		sprite.offset = PLACEHOLDER_OFFSET
		sprite.modulate = profile.tint
		sprite_data = null
	_play(&"idle")
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
		name_tag.visible = is_active and show_name_tag
		name_tag.modulate = Color("ffd36b")


func _process(delta: float) -> void:
	# Blink while invulnerable.
	sprite.visible = not health.is_invulnerable or int(Time.get_ticks_msec() / 1000.0 * FLASH_RATE) % 2 == 0
	if shield_left > 0.0:
		shield_left = maxf(shield_left - delta, 0.0)
		queue_redraw()


## Jay's bass bubble around the member while it lasts.
func _draw() -> void:
	if shield_left <= 0.0:
		return
	var a := clampf(shield_left / 0.5, 0.0, 1.0)
	draw_arc(Vector2(0, -15), 19.0, 0.0, TAU, 24, Color(0.6, 0.85, 1.0, 0.75 * a), 1.5)
	draw_circle(Vector2(0, -15), 18.0, Color(0.6, 0.85, 1.0, 0.12 * a))


func _physics_process(delta: float) -> void:
	_read_input(delta)
	var on_floor := is_on_floor()

	# Forgiveness timers.
	_coyote = profile.coyote_time if on_floor else maxf(_coyote - delta, 0.0)
	_buffer = profile.jump_buffer if in_jump_pressed else maxf(_buffer - delta, 0.0)
	if _drop_timer > 0.0:
		_drop_timer -= delta
		set_collision_mask_value(2, _drop_timer <= 0.0)
	_handle_items()

	if ability:
		ability.physics_begin(delta)
		if ability.custom_physics(delta):   # climb, ground pound, shield...
			_finish_frame()
			return

	_update_crouch(on_floor)

	# Jump: on the ground (buffered, coyote time), drop-through, or an air jump.
	if _buffer > 0.0:
		if crouching and not (in_vertical > 0.0 and _standing_on_one_way()):
			pass                            # stuck under something low: no jump until you can stand
		elif _coyote > 0.0:
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

	# Horizontal: reach top speed in accel_time, stop in decel_time. Shift runs
	# (stamina on the ground), crouching crawls.
	running = in_run_held and in_dir != 0.0 and not crouching and stamina.enabled and not stamina.is_exhausted
	if running and on_floor and stamina_config:
		stamina.spend(stamina_config.run_per_sec * delta)
	var top := profile.run_speed() * speed_scale * (ability.speed_mult() if ability else 1.0)
	if running:
		top *= RUN_MULT
	elif crouching:
		top *= CROUCH_MULT
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
	wall_sliding = not map_mode and not is_on_floor() and velocity.y > 0.0 and in_dir != 0.0 \
		and test_move(global_transform, Vector2(in_dir * WALL_CHECK, 0))
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
	if shield_left > 0.0:
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


## Jump on behalf of the Band's AI (followers hopping a step or gap).
func ai_jump(hold := 0.35) -> void:
	_ai_jump_queued = true
	_ai_jump_hold = hold


## Other living members within `radius` px in the same room, nearest first.
func nearby_members(radius: float) -> Array[BandMember]:
	var out: Array[BandMember] = []
	var level := Level.of(self)
	for n in get_parent().get_children():
		var m := n as BandMember
		if m == null or m == self or m.is_dead:
			continue
		if level and level.room_of_member(m) != level.room_of_member(self):
			continue
		if m.global_position.distance_to(global_position) <= radius:
			out.append(m)
	out.sort_custom(func(a: BandMember, b: BandMember) -> bool:
		return a.global_position.distance_squared_to(global_position) < b.global_position.distance_squared_to(global_position))
	return out


func add_beer() -> bool:
	return add_item(BEER)


func add_item(item: ItemData) -> bool:
	if not inventory.add(item):
		show_text("Hands full")
		return false
	show_text("+" + item.display_name)
	return true


## The selected item if it's a weapon (punches swing it), else null.
func held_weapon() -> ItemData:
	var i := inventory.current_index()
	if i < 0:
		return null
	var item := inventory.slots[i]
	return item if item.weapon else null


## Where something spawned by this member goes: the level, else the parent.
func spawn_parent() -> Node:
	var level := Level.of(self)
	return level if level else get_parent()


## Beer heals 1 HP for everyone; some members get a bonus (ability.on_beer()).
func drink_beer() -> bool:
	var i := inventory.index_of(&"beer")
	if i < 0 or _dead:
		return false
	inventory.remove_at(i)
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
	_play_once(&"death")
	if anim_name(&"death") != &"death":     # band sheets have no death anim: crouch and fade
		var tween := create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tween.tween_property(sprite, "modulate:a", 0.0, 0.5)


## Back to life at `pos` with `hp`, all transient state cleared.
## `grace` gives i-frames (flashing) so a respawn can't be hit straight away.
func respawn(pos: Vector2, hp: int, grace := 0.0) -> void:
	_dead = false
	global_position = pos
	velocity = Vector2.ZERO
	ai_dir = 0.0
	_ai_jump_queued = false
	_ai_jump_hold = 0.0
	_coyote = 0.0
	_buffer = 0.0
	_jump_held = false
	_hurt_lock = 0.0
	_drop_timer = 0.0
	set_collision_mask_value(2, true)
	_set_crouch(false)
	running = false
	wall_sliding = false
	shield_left = 0.0
	queue_redraw()
	health.restore(hp, grace)
	stamina.refill()
	if ability:
		ability.reset()
	anim_override = &""
	sprite.process_mode = Node.PROCESS_MODE_INHERIT
	sprite.speed_scale = 1.0
	sprite.visible = true
	sprite.modulate.a = 1.0
	_anim_lock = false
	_play(&"idle")


## E (with nothing to interact with) or R: use the current item. Beer is drunk, a keycard opens a locked door next
## to you, other items explain themselves.
func use_current_item() -> void:
	var i := inventory.current_index()
	if i < 0:
		return
	var item := inventory.slots[i]
	if item.only_for != &"" and item.only_for != profile.id:
		show_text("Not mine")
		return
	match item.id:
		&"beer":
			drink_beer()
		_:
			var door := _locked_door_for(item.id)
			if door:
				inventory.remove_at(i)
				door.unlock_with(item)
			elif item.weapon:
				if ability and not map_mode:
					ability.punch()
			else:
				show_text(item.description)


## F: hand the current item to the nearest member within 1 tile.
func give_current_item() -> bool:
	var i := inventory.current_index()
	if i < 0:
		return false
	var others := nearby_members(GIVE_RANGE)
	if others.is_empty():
		show_text("Nobody close enough")
		return false
	var item := inventory.slots[i]
	if not others[0].add_item(item):
		return false
	inventory.remove_at(i)
	return true


## V: put the current item on the floor.
func drop_current_item() -> void:
	var i := inventory.current_index()
	if i < 0:
		return
	var item := inventory.remove_at(i)
	var pickup := ItemPickup.new()
	pickup.item = item
	pickup.ignore(self)
	var level := Level.of(self)
	(level if level else get_parent()).add_child(pickup)
	pickup.global_position = global_position + Vector2(facing * 6.0, 0)


func show_text(text: String, color := Color.WHITE) -> void:
	var level := Level.of(self)
	FloatText.spawn(level if level else get_parent(), global_position + Vector2(0, -46), text, color)


# --- Internals -------------------------------------------------------------

func _handle_items() -> void:
	if in_next_pressed:
		inventory.select_next()
	if in_use_pressed:
		use_current_item()
	if in_give_pressed:
		give_current_item()
	if in_drop_pressed:
		drop_current_item()


func _locked_door_for(key: StringName) -> Door:
	for node in get_tree().get_nodes_in_group(&"interactable"):
		var door := node as Door
		if door and door.locked and door.key_id == key \
				and door.global_position.distance_to(global_position) <= KEY_RANGE:
			return door
	return null


func _read_input(delta: float) -> void:
	var controlled := is_active and _hurt_lock <= 0.0
	var skills := controlled and not map_mode
	if _hurt_lock > 0.0:
		_hurt_lock -= delta
	if controlled:
		in_dir = Input.get_axis("move_left", "move_right")
		in_vertical = Input.get_axis("move_up", "move_down")
		in_jump_pressed = Input.is_action_just_pressed("jump")
		in_jump_held = Input.is_action_pressed("jump")
		in_a_pressed = skills and Input.is_action_just_pressed("action_a")
		in_a_held = skills and Input.is_action_pressed("action_a")
		in_b_pressed = skills and Input.is_action_just_pressed("action_b")
		in_b_held = skills and Input.is_action_pressed("action_b")
		in_instrument_pressed = skills and Input.is_action_just_pressed("instrument")
		in_run_held = skills and Input.is_action_pressed("sprint")
		in_use_pressed = Input.is_action_just_pressed("use_item")
		in_give_pressed = Input.is_action_just_pressed("give")
		in_drop_pressed = Input.is_action_just_pressed("drop_item")
		in_next_pressed = Input.is_action_just_pressed("item_next")
	else:
		in_dir = 0.0 if _hurt_lock > 0.0 else clampf(ai_dir, -1.0, 1.0)
		in_vertical = 0.0
		in_jump_pressed = _ai_jump_queued
		in_jump_held = _ai_jump_hold > 0.0
		_ai_jump_queued = false
		_ai_jump_hold = maxf(_ai_jump_hold - delta, 0.0)
		in_a_pressed = false
		in_a_held = false
		in_b_pressed = false
		in_b_held = false
		in_instrument_pressed = false
		in_run_held = false
		in_use_pressed = false
		in_give_pressed = false
		in_drop_pressed = false
		in_next_pressed = false


func _finish_frame() -> void:
	if is_on_floor() and not _was_on_floor:
		landed.emit(_air_speed)
		if ability:
			ability.on_landed(_air_speed)
	stamina.grounded = is_on_floor()
	_update_animation()


## Hold down on the ground to crouch; stay down while something low is overhead.
func _update_crouch(on_floor: bool) -> void:
	var want := not map_mode and on_floor and in_vertical > 0.5 and (ability == null or not ability.busy())
	if want != crouching:
		if want or _can_stand():
			_set_crouch(want)


func _set_crouch(on: bool) -> void:
	crouching = on
	var h := CROUCH_HEIGHT if on else STAND_HEIGHT
	(_collision.shape as RectangleShape2D).size.y = h
	_collision.position.y = -h / 2.0


func _can_stand() -> bool:
	return not test_move(global_transform, Vector2(0, -(STAND_HEIGHT - CROUCH_HEIGHT)))


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
	if wall_sliding:
		cap = WALL_SLIDE_SPEED
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
	var moving := absf(velocity.x) > 1.0
	sprite.flip_h = facing < 0.0

	if on_floor and not _was_on_floor and not moving:
		_play_once(&"land")
	_was_on_floor = on_floor
	if not on_floor or moving or anim_override != &"" or crouching:
		_idle_time = 0.0
		_fidget = &""

	var pose := anim_override
	if pose == &"" and wall_sliding:
		pose = &"wall_slide"
	elif pose == &"" and crouching:
		pose = &"crouch"
	if pose != &"":
		_anim_lock = false
		_play(pose)
	elif _anim_lock:
		# Running or falling cancels a one-shot.
		if on_floor and moving and (anim == &"land" or anim == &"fidget"):
			_anim_lock = false
		elif not on_floor and velocity.y > 0.0:
			_anim_lock = false
	if pose == &"" and not _anim_lock:
		if on_floor:
			if moving:
				_play(&"run" if absf(velocity.x) > _run_speed() * 0.6 else &"walk")
			else:
				_update_idle()
		elif velocity.y < -profile.apex_threshold:
			_play(&"jump")
		elif velocity.y < profile.apex_threshold:
			_play(&"apex")
		else:
			_play(&"fall")
	# Band sheets draw the wall slide with the wall on the left of the art.
	if sprite.animation == &"wall_slide":
		sprite.flip_h = facing > 0.0


## World map followers move without physics: animate from their speed alone
## (walk, jog, or idle with the usual fidgets after a while).
func animate_as_follower(vx: float) -> void:
	sprite.flip_h = facing < 0.0
	if absf(vx) > 1.0:
		_idle_time = 0.0
		_fidget = &""
		if anim == &"fidget":
			_anim_lock = false
		_play(&"run" if absf(vx) > _run_speed() * 0.6 else &"walk")
	elif not _anim_lock:
		_update_idle()


func _run_speed() -> float:
	return profile.run_speed_tiles * TILE if profile else 1.0


## Standing still: breathe; after a while play an instrument, drink or smoke
## (band sheets only), with the _in / _loop / _out parts where the sheet has them.
func _update_idle() -> void:
	var delta := get_physics_process_delta_time()
	_idle_time += delta
	if _fidget == &"" and _idle_time >= fidget_after and profile and profile.sprite_frames:
		var options := FIDGETS.filter(func(f: StringName) -> bool: return _has_part(f, "") or _has_part(f, "_in"))
		if not options.is_empty():
			_fidget = options[randi() % options.size()]
			_fidget_time = 0.0
			if _has_part(_fidget, "_in"):
				_play_raw_once(StringName(_fidget + "_in"))
				return
	if _fidget == &"":
		_play(&"idle")
		return
	_fidget_time += delta
	if _fidget != &"idle_instrument" and _fidget_time >= FIDGET_LENGTH:
		var out := StringName(_fidget + "_out")
		_fidget = &""
		_idle_time = 0.0
		if _has_part(out, ""):
			_play_raw_once(out)
		else:
			_play(&"idle")
		return
	var loop := StringName(_fidget + "_loop")
	_play_raw(loop if _has_part(loop, "") else _fidget)


func _has_part(base: StringName, suffix: String) -> bool:
	return sprite.sprite_frames.has_animation(StringName(base + suffix))


## The sheet animation that plays for logical `name` (itself or an alias).
func anim_name(name: StringName, depth := 0) -> StringName:
	if sprite.sprite_frames.has_animation(name) or depth > 3:
		return name
	for alias in ANIM_ALIASES.get(name, []):
		var found := anim_name(alias, depth + 1)
		if sprite.sprite_frames.has_animation(found):
			return found
	return name


## Play logical animation `name` (looping; the sheet's alias if it lacks it).
func play_anim(name: StringName) -> void:
	_play(name)


func _play(name: StringName) -> void:
	anim = name
	var actual := anim_name(name)
	if sprite.animation != actual and sprite.sprite_frames.has_animation(actual):
		sprite.play(actual)


func _play_once(name: StringName) -> void:
	_anim_lock = true
	anim = name
	var actual := anim_name(name)
	if sprite.sprite_frames.has_animation(actual):
		sprite.play(actual)


## Idle variations play sheet names directly (logical anim "fidget").
func _play_raw(actual: StringName) -> void:
	anim = &"fidget"
	if sprite.animation != actual:
		sprite.play(actual)


func _play_raw_once(actual: StringName) -> void:
	_anim_lock = true
	anim = &"fidget"
	sprite.play(actual)


func _on_animation_finished() -> void:
	_anim_lock = false
