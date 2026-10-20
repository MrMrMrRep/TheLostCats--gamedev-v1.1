class_name JayAbility
extends MemberAbility
## Jay (bass): walks into flight cases to push them; A next to a case grabs it to
## pull while held. A next to another band member throws them up (~4 tiles).
## Otherwise A fires a bass wave: breaks glass and fragile walls, knocks rats
## back. Pushing/pulling slows him down.

const PUSH_SPEED := 70.0
const PULL_SPEED := 60.0
const THROW_RANGE := 22.0
const THROW_HEIGHT_TILES := 4.3
const WAVE_SIZE := Vector2(96, 28)
const WAVE_COOLDOWN := 0.6
const WAVE_FX_TIME := 0.3
const WAVE_KNOCKBACK := Vector2(180, -120)
const MASK_WORLD_AND_ENEMY := (1 << 0) | (1 << 3)

var pulling: FlightCase
var pushing := false

var _wave_cooldown := 0.0
var _wave_fx := 0.0


func physics_begin(delta: float) -> void:
	super(delta)
	_wave_cooldown = maxf(_wave_cooldown - delta, 0.0)
	if _wave_fx > 0.0:
		_wave_fx = maxf(_wave_fx - delta, 0.0)
		queue_redraw()
	if pulling and (not member.in_a_held or not member.is_on_floor()):
		pulling = null
	if member.in_a_pressed:
		_action()


func speed_mult() -> float:
	if pulling:
		return PULL_SPEED / member.profile.run_speed()
	if pushing:
		return PUSH_SPEED / member.profile.run_speed()
	return 1.0


func physics_end(_delta: float) -> void:
	pushing = false
	if pulling:
		member.facing = signf(pulling.global_position.x - member.global_position.x)
		if member.in_dir != 0.0 and member.in_dir == -member.facing:
			pulling.push(member.in_dir * PULL_SPEED)
		return
	if not member.is_on_floor() or member.in_dir == 0.0:
		return
	for i in member.get_slide_collision_count():
		var hit := member.get_slide_collision(i)
		var case: FlightCase = hit.get_collider() as FlightCase
		if case and signf(-hit.get_normal().x) == member.in_dir:
			case.push(member.in_dir * PUSH_SPEED)
			pushing = true


func reset() -> void:
	pulling = null
	pushing = false
	_wave_cooldown = 0.0
	_wave_fx = 0.0
	queue_redraw()


func _action() -> void:
	var others := nearby_members(THROW_RANGE)
	if not others.is_empty() and member.is_on_floor() and others[0].is_on_floor():
		throw_member(others[0])
		return
	var case: FlightCase = _case_in_front()
	if case and member.is_on_floor():
		pulling = case
		return
	bass_wave()


func throw_member(other: BandMember) -> void:
	var height: float = THROW_HEIGHT_TILES * TILE_PX
	other.velocity = Vector2(member.facing * 50.0, -sqrt(2.0 * other.gravity_value() * height))
	member.play_action(&"attack")


func bass_wave() -> void:
	if _wave_cooldown > 0.0:
		return
	_wave_cooldown = WAVE_COOLDOWN
	_wave_fx = WAVE_FX_TIME
	Audio.sfx(&"bass", 0.0)
	member.play_action(&"attack")
	var center: Vector2 = member.global_position + Vector2(member.facing * (WAVE_SIZE.x / 2.0 + 4.0), -14)
	for body in query_box(center, WAVE_SIZE, MASK_WORLD_AND_ENEMY):
		if body is Breakable:
			body.break_by(&"resonance")
		elif body is Rat:
			body.knockback(Vector2(member.facing * WAVE_KNOCKBACK.x, WAVE_KNOCKBACK.y))
	queue_redraw()


func _case_in_front() -> FlightCase:
	var hit := member.move_and_collide(Vector2(member.facing * 3.0, 0), true)
	return hit.get_collider() as FlightCase if hit else null


func _draw() -> void:
	if _wave_fx <= 0.0:
		return
	var t: float = 1.0 - _wave_fx / WAVE_FX_TIME
	var f: float = member.facing
	for i in 3:
		var r := 10.0 + (t * WAVE_SIZE.x) - i * 14.0
		if r <= 4.0:
			continue
		var start := -PI / 4 if f > 0 else PI * 0.75
		draw_arc(Vector2(0, -14), r, start, start + PI / 2, 10, Color(0.6, 0.85, 1.0, 1.0 - t), 1.5)
