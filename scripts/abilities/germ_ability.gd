class_name GermAbility
extends MemberAbility
## The Germ (drums): A punches (defeats rats, smashes wooden crates). A in the
## air = ground pound: shoots down, on impact breaks cracked floors and wood,
## defeats rats underneath and stuns rats nearby. Hold B = drumstick shield
## (drains stamina): blocks hits from the front; hold up to aim it up, which
## makes a platform other members can stand on. B is the shield, so The Germ
## drinks beer through the item key (M7).

const PUNCH_SIZE := Vector2(22, 22)
const PUNCH_COOLDOWN := 0.35
const POUND_SPEED := 520.0
const POUND_SIZE := Vector2(64, 20)
const POUND_STUN_RADIUS := 56.0
const SHIELD_PLATFORM_Y := -38.0
const MASK_WORLD_AND_ENEMY := (1 << 0) | (1 << 3)

var pounding := false
var shielding := false
var shield_up := false

var _punch_cooldown := 0.0
var _platform: StaticBody2D
var _platform_shape: CollisionShape2D


func setup(m: BandMember) -> void:
	super(m)
	_platform = StaticBody2D.new()
	_platform.collision_layer = 1 << 1      # one_way: others can stand on it
	_platform.collision_mask = 0
	_platform_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(28, 6)
	_platform_shape.shape = rect
	_platform_shape.position = Vector2(0, SHIELD_PLATFORM_Y + 3)
	_platform_shape.one_way_collision = true
	_platform_shape.disabled = true
	_platform.add_child(_platform_shape)
	add_child(_platform)


func uses_b_for_drink() -> bool:
	return false


func physics_begin(delta: float) -> void:
	super(delta)
	_punch_cooldown = maxf(_punch_cooldown - delta, 0.0)
	if member.in_a_pressed and not shielding and not pounding:
		if member.is_on_floor():
			punch()
		else:
			pounding = true
			member.play_action(&"air_attack")


func custom_physics(delta: float) -> bool:
	if pounding:
		member.velocity = Vector2(0, POUND_SPEED)
		member.move_body(delta)
		if member.is_on_floor():
			_pound_impact()
		return true
	var want_shield: bool = member.in_b_held and member.is_on_floor() and not member.stamina.is_exhausted
	if want_shield != shielding or (shielding and shield_up != (member.in_vertical < 0.0)):
		_set_shield(want_shield, want_shield and member.in_vertical < 0.0)
	if not shielding:
		return false
	member.stamina.spend(config.shield_per_sec * delta)
	member.velocity.x = 0.0
	member.velocity.y = minf(member.velocity.y + member.gravity_value() * delta, 400.0)
	member.anim_override = &"idle"
	member.move_body(delta)
	return true


func punch() -> void:
	if _punch_cooldown > 0.0:
		return
	_punch_cooldown = PUNCH_COOLDOWN
	member.play_action(&"attack")
	Audio.sfx(&"punch")
	var center: Vector2 = member.global_position + Vector2(member.facing * (PUNCH_SIZE.x / 2.0 + 4.0), -14)
	for body in query_box(center, PUNCH_SIZE, MASK_WORLD_AND_ENEMY):
		if body is Rat:
			body.defeat()
		elif body is Breakable:
			body.break_by(&"impact")


func blocks_damage(from: Vector2) -> bool:
	if not shielding:
		return false
	var covered: bool = from.y < member.global_position.y - 20.0 if shield_up \
		else signf(from.x - member.global_position.x) == member.facing
	if covered:
		member.stamina.spend(config.shield_hit_cost)
	return covered


func reset() -> void:
	pounding = false
	_set_shield(false, false)
	_punch_cooldown = 0.0
	if member:
		member.anim_override = &""


func _pound_impact() -> void:
	pounding = false
	Audio.sfx(&"pound")
	GameFeel.shake(member.get_tree(), 5.0, 0.3)
	GameFeel.dust(member.get_parent(), member.global_position, 1.8)
	var feet: Vector2 = member.global_position
	for body in query_box(feet + Vector2(0, 6), POUND_SIZE, MASK_WORLD_AND_ENEMY):
		if body is Breakable:
			body.break_by(&"impact")
	for body in query_box(feet + Vector2(0, -10), Vector2(POUND_STUN_RADIUS * 2.0, 24), 1 << 3):
		if body is Rat:
			if absf(body.global_position.x - feet.x) < 16.0:
				body.defeat()
			else:
				body.stun(1.5)


func _set_shield(on: bool, up: bool) -> void:
	shielding = on
	shield_up = on and up
	if _platform_shape:
		_platform_shape.set_deferred("disabled", not shield_up)
	if member and not on:
		member.anim_override = &""
	queue_redraw()


func _draw() -> void:
	if not shielding:
		return
	var c := Color(1.0, 0.85, 0.4, 0.85)
	if shield_up:
		draw_rect(Rect2(-14, SHIELD_PLATFORM_Y, 28, 3), c)
		draw_line(Vector2(-6, SHIELD_PLATFORM_Y + 3), Vector2(-3, -24), Color("6b4a2a"), 1.5)
		draw_line(Vector2(6, SHIELD_PLATFORM_Y + 3), Vector2(3, -24), Color("6b4a2a"), 1.5)
	else:
		var x := member.facing * 10.0
		draw_arc(Vector2(x, -15), 13.0, -PI / 2.5 if member.facing > 0 else PI - PI / 2.5, (PI / 2.5 if member.facing > 0 else PI + PI / 2.5), 8, c, 2.0)
