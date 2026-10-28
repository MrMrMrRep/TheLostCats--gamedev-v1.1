class_name JayAbility
extends MemberAbility
## Jay (bass). Walks into flight cases to push them.
## Special (B): lift and throw heavy things. Next to a flight case: lift it
## over his head (slower walk, drains stamina; drops it when he runs out), B
## again throws it. Next to a band member: throws them up (~4 tiles).
## Instrument (L): slap bass. Sub-bass waves fill the space in front of him:
## rats are knocked back, glass and fragile walls shatter, flight cases are
## shoved away, and the members around him get a short defence bubble.

const PUSH_SPEED := 70.0
const CARRY_MULT := 0.7
const CARRY_OFFSET := Vector2(0, -30)       # the case's bottom, over his head
const LIFT_RANGE := 8.0                     # px gap to a case he can grab
const THROW_RANGE := 22.0
const THROW_HEIGHT_TILES := 4.3
const CASE_THROW := Vector2(220, -160)
const SLAP_SIZE := Vector2(144, 56)         # mid range, in front
const SLAP_KNOCKBACK := Vector2(220, -140)
const SLAP_CASE_PUSH := Vector2(260, -60)
const BUBBLE_RADIUS := 84.0
const BUBBLE_TIME := 2.5
const SLAP_FX_TIME := 0.35

var carrying: FlightCase
var pushing := false

var _slap_fx := 0.0


func physics_begin(delta: float) -> void:
	if _slap_fx > 0.0:
		_slap_fx = maxf(_slap_fx - delta, 0.0)
		queue_redraw()
	if carrying:
		member.stamina.spend(config.lift_per_sec * delta if config else 0.0)
		if member.stamina.is_exhausted:
			drop()
	super(delta)


func special() -> void:
	if carrying:
		throw_case()
		return
	var others := nearby_members(THROW_RANGE)
	if not others.is_empty() and member.is_on_floor() and others[0].is_on_floor():
		throw_member(others[0])
		return
	var case := _case_in_front()
	if case and member.is_on_floor():
		lift(case)
		return
	member.show_text("Nothing heavy here", Color(0.75, 0.8, 1.0))


func lift(case: FlightCase) -> void:
	if member.stamina.is_exhausted:
		member.show_text("Too tired", Color(0.75, 0.8, 1.0))
		return
	carrying = case
	case.lift()
	member.play_action(&"special")
	_place_case()


func throw_case() -> void:
	var case := carrying
	carrying = null
	member.play_action(&"throw")
	case.throw(Vector2(member.facing * CASE_THROW.x, CASE_THROW.y))


## Put it down in front of him (out of stamina, or hurt).
func drop() -> void:
	if carrying == null:
		return
	var case := carrying
	carrying = null
	case.global_position = member.global_position + Vector2(member.facing * 20.0, -6)
	case.throw(Vector2.ZERO)


func throw_member(other: BandMember) -> void:
	var height: float = THROW_HEIGHT_TILES * TILE_PX
	other.velocity = Vector2(member.facing * 50.0, -sqrt(2.0 * other.gravity_value() * height))
	member.play_action(&"throw")


func instrument_cost() -> float:
	return config.slap_cost if config else 0.0


func instrument() -> void:
	slap_bass()


func slap_bass() -> void:
	_slap_fx = SLAP_FX_TIME
	Audio.sfx(&"bass", 0.0)
	GameFeel.shake(member.get_tree(), 2.0, 0.2)
	var f := member.facing
	var center: Vector2 = member.global_position + Vector2(f * (SLAP_SIZE.x / 2.0 + 4.0), -18)
	for body in query_box(center, SLAP_SIZE, MASK_WORLD | MASK_ENEMY | (1 << 6)):
		if body is Breakable:
			body.break_by(&"resonance")
		elif body is Rat:
			body.knockback(Vector2(f * SLAP_KNOCKBACK.x, SLAP_KNOCKBACK.y))
		elif body is FlightCase and body != carrying:
			body.blast(Vector2(f * SLAP_CASE_PUSH.x, SLAP_CASE_PUSH.y))
	member.shield_left = BUBBLE_TIME
	member.queue_redraw()
	for m in nearby_members(BUBBLE_RADIUS):
		m.shield_left = BUBBLE_TIME
		m.queue_redraw()
	queue_redraw()


func speed_mult() -> float:
	if carrying:
		return CARRY_MULT
	if pushing:
		return PUSH_SPEED / member.profile.run_speed()
	return 1.0


func physics_end(_delta: float) -> void:
	pushing = false
	if carrying:
		_place_case()
		member.anim_override = &""
		return
	if not member.is_on_floor() or member.in_dir == 0.0:
		return
	for i in member.get_slide_collision_count():
		var hit := member.get_slide_collision(i)
		var case: FlightCase = hit.get_collider() as FlightCase
		if case and signf(-hit.get_normal().x) == member.in_dir:
			case.push(member.in_dir * PUSH_SPEED)
			pushing = true


func on_hurt() -> void:
	drop()


func reset() -> void:
	super()
	if carrying and is_instance_valid(carrying):
		carrying.reset_state()
	carrying = null
	pushing = false
	_slap_fx = 0.0
	queue_redraw()


func on_deactivated() -> void:
	drop()                                  # don't leave a case floating over an idle Jay
	super()


func _place_case() -> void:
	carrying.global_position = member.global_position + CARRY_OFFSET


func _case_in_front() -> FlightCase:
	var hit := member.move_and_collide(Vector2(member.facing * LIFT_RANGE, 0), true)
	return hit.get_collider() as FlightCase if hit else null


func _draw() -> void:
	if _slap_fx <= 0.0:
		return
	var t: float = 1.0 - _slap_fx / SLAP_FX_TIME
	var f: float = member.facing
	for i in 4:
		var r := 10.0 + (t * SLAP_SIZE.x) - i * 16.0
		if r <= 4.0:
			continue
		var start := -PI / 4 if f > 0 else PI * 0.75
		draw_arc(Vector2(0, -16), r, start, start + PI / 2, 12, Color(0.6, 0.85, 1.0, 1.0 - t), 2.0)
