class_name JoepAbility
extends MemberAbility
## Joep (keys): wall-slide when pushing into a wall in the air, wall-jump off
## walls (costs stamina), hold A to grab and climb walls (drains stamina; at the
## top he hops over the edge). Hacks panels (E). Beer: quick for 5 s.

const WALL_CHECK := 2.0                     # px probe distance
const WALL_SLIDE_SPEED := 40.0              # px/s max fall while sliding
const WALL_JUMP_SPEED_X := 150.0
const WALL_JUMP_FORCE_TIME := 0.16          # horizontal input ignored after a wall jump
const CLIMB_UP_SPEED := 60.0
const CLIMB_DOWN_SPEED := 90.0
const CLIMB_STILL_COST := 0.3               # fraction of climb cost while hanging still
const LEDGE_HOP := Vector2(90, -200)
const BEER_SPEED := 1.3
const BEER_TIME := 5.0

var climbing := false
var wall_sliding := false

var _force_left := 0.0
var _quick_left := 0.0


func setup(m: BandMember) -> void:
	super(m)
	can_hack = true


func physics_begin(delta: float) -> void:
	super(delta)
	_force_left = maxf(_force_left - delta, 0.0)
	_quick_left = maxf(_quick_left - delta, 0.0)


func custom_physics(delta: float) -> bool:
	var wall: float = wall_dir()
	if not climbing and member.in_a_held and wall != 0.0 and not member.stamina.is_exhausted:
		climbing = true
	if climbing and (not member.in_a_held or wall == 0.0 or member.stamina.is_exhausted):
		_stop_climbing()
		return false
	if not climbing:
		return false

	member.facing = wall
	if member.in_jump_pressed:              # jump off the wall
		_stop_climbing()
		_wall_jump(wall)
		return false
	var v: float = member.in_vertical
	if v < 0.0:
		member.velocity.y = -CLIMB_UP_SPEED
		member.stamina.spend(config.climb_per_sec * delta)
		if _at_top(wall):                   # pull up over the edge
			_stop_climbing()
			member.velocity = Vector2(wall * LEDGE_HOP.x, LEDGE_HOP.y)
			return false
	elif v > 0.0:
		member.velocity.y = CLIMB_DOWN_SPEED
	else:
		member.velocity.y = 0.0
		member.stamina.spend(config.climb_per_sec * CLIMB_STILL_COST * delta)
	member.velocity.x = wall * 10.0         # stay pressed against the wall
	member.anim_override = &"jump"
	member.move_body(delta)
	return true


func air_jump() -> bool:
	var wall: float = wall_dir()
	if wall == 0.0:
		return false
	return _wall_jump(wall)


func locks_horizontal() -> bool:
	return _force_left > 0.0


func speed_mult() -> float:
	return BEER_SPEED if _quick_left > 0.0 else 1.0


func fall_cap(default_cap: float) -> float:
	return WALL_SLIDE_SPEED if wall_sliding else default_cap


func physics_end(_delta: float) -> void:
	var wall: float = wall_dir()
	wall_sliding = wall != 0.0 and member.in_dir == wall and member.velocity.y > 0.0 and not member.is_on_floor()
	member.anim_override = &"fall" if wall_sliding else &""


func on_beer() -> void:
	_quick_left = BEER_TIME


func reset() -> void:
	climbing = false
	wall_sliding = false
	_force_left = 0.0
	_quick_left = 0.0
	if member:
		member.anim_override = &""


## -1 wall on the left, 1 on the right, 0 none (only in the air or while climbing).
func wall_dir() -> float:
	if member.is_on_floor() and not climbing and not member.in_a_held:
		return 0.0
	if member.test_move(member.global_transform, Vector2(WALL_CHECK, 0)):
		return 1.0
	if member.test_move(member.global_transform, Vector2(-WALL_CHECK, 0)):
		return -1.0
	return 0.0


func _wall_jump(wall: float) -> bool:
	if not member.stamina.try_spend(config.wall_jump_cost):
		return false
	member.jump_with(member.profile.jump_velocity() * 0.95)
	member.velocity.x = -wall * WALL_JUMP_SPEED_X
	member.facing = -wall
	_force_left = WALL_JUMP_FORCE_TIME
	return true


## No wall at chest height above: the climb has reached the top edge.
func _at_top(wall: float) -> bool:
	return not member.test_move(member.global_transform.translated(Vector2(0, -20)), Vector2(wall * WALL_CHECK, 0))


func _stop_climbing() -> void:
	climbing = false
	member.anim_override = &""
