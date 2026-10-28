class_name NikkiAbility
extends MemberAbility
## Nikki (guitar).
## Special (B): grapple. Shoots a line at the nearest hook (GrappleHook) within
## reach, above her and not behind her, and swings from it: left/right pump
## the swing, up/down climb or let out the line, jump lets go with a boost
## (B lets go without one). Crosses wide gaps and gets her up high.
## Instrument (L): guitar solo. Her riff turns into a platform of notes that
## the whole band can stand on: a bridge straight ahead, or with up held a
## ramp rising 5 tiles (walkable for everyone). It fades after a few seconds
## (NoteBridge).
## Beer bonus: members within 2 tiles heal 1 HP too.

const GRAPPLE_RANGE := 150.0
const ROPE_MIN := 24.0
const ROPE_MAX := 160.0
const ROPE_CLIMB := 80.0                    # px/s up or down the line
const PUMP := 3.0                           # rad/s^2 from left/right input
const SWING_DAMP := 0.4                     # per second
const RELEASE_BOOST := 140.0                # px/s up when jumping off
const FLOOR_CLEAR := 4.0                    # from the ground the line reels in so the swing clears the floor by this
const TOUCHDOWN_GRACE := 0.25               # s after hooking on before landing lets go
const BRIDGE_LENGTH := 168.0                # 7 tiles
const BRIDGE_TIME := 8.0
const RAMP_RUN := 180.0                     # 7.5 tiles across...
const RAMP_RISE := 124.0                    # ...a touch over 5 tiles up (about 35 degrees: walkable)
const AURA_RADIUS := 48.0

var swinging := false
var hook: Node2D

var _rope := 0.0
var _angle := 0.0                           # 0 = hanging straight down; + towards the right
var _omega := 0.0
var _hooked_for := 0.0


func busy() -> bool:
	return swinging


func physics_begin(delta: float) -> void:
	if swinging and member.in_b_pressed:
		release(false)
		member.in_b_pressed = false         # letting go isn't a new grapple
	super(delta)


func special() -> void:
	grapple()


## Hook onto the nearest hook in reach. Returns false if there's none.
func grapple() -> bool:
	var target := _find_hook()
	if target == null:
		member.show_text("No hook in reach", Color(0.75, 0.8, 1.0))
		return false
	hook = target
	var off := _origin() - hook.global_position
	_rope = off.length()
	if member.is_on_floor():                # reel in: the bottom of the swing stays off the floor
		_rope = minf(_rope, member.global_position.y - FLOOR_CLEAR - 20.0 - hook.global_position.y)
	_rope = clampf(_rope, ROPE_MIN, ROPE_MAX)
	_angle = atan2(off.x, off.y)
	_omega = member.velocity.dot(Vector2(cos(_angle), -sin(_angle))) / _rope
	_hooked_for = 0.0
	swinging = true
	member.play_action(&"special")
	Audio.sfx(&"switch")
	queue_redraw()
	return true


## Let go; with `boost` (jump) she gets a kick upwards.
func release(boost := true) -> void:
	if not swinging:
		return
	swinging = false
	member.velocity = _swing_velocity()
	if boost:
		member.jump_with(minf(member.velocity.y, 0.0) - RELEASE_BOOST)
	member.anim_override = &""
	hook = null
	queue_redraw()


func custom_physics(delta: float) -> bool:
	if not swinging:
		return false
	if not is_instance_valid(hook):
		release(false)
		return false
	if member.in_jump_pressed:
		release(true)
		return true
	_hooked_for += delta
	var g := member.gravity_value()
	_rope = clampf(_rope + member.in_vertical * ROPE_CLIMB * delta, ROPE_MIN, ROPE_MAX)
	_omega += (-g / _rope * sin(_angle) + member.in_dir * PUMP) * delta
	_omega *= 1.0 - SWING_DAMP * delta
	_angle += _omega * delta
	var target := hook.global_position + Vector2(sin(_angle), cos(_angle)) * _rope
	member.velocity = (target - _origin()) / delta
	if member.in_dir != 0.0:
		member.facing = signf(member.in_dir)
	member.move_body(delta)
	var off := _origin() - hook.global_position   # walls stop the swing where it hit
	if off.distance_to(target - hook.global_position) > 1.0:
		_angle = atan2(off.x, off.y)
		_omega *= 0.3
	if member.is_on_floor() and member.velocity.y >= 0.0 and _hooked_for > TOUCHDOWN_GRACE:
		release(false)                      # touched down
		return true
	member.anim_override = &"jump"
	queue_redraw()
	return true


func instrument_cost() -> float:
	return config.solo_cost if config else 0.0


func instrument() -> void:
	guitar_solo(member.in_vertical < 0.0)


## Play a bridge ahead, or a ramp going up with `ramp`. Returns the platform.
func guitar_solo(ramp := false) -> NoteBridge:
	Audio.sfx(&"switch", 0.0)
	var f := member.facing
	var feet := member.global_position
	if not ramp:
		var x0 := feet.x + f * 10.0
		return _note_platform(Vector2(x0 if f > 0 else x0 - BRIDGE_LENGTH, feet.y), BRIDGE_LENGTH, 0.0)
	# The platform's own x runs along the ramp, always left to right, so its
	# one-way side stays on top: from her feet up to the right, or from the
	# top end down to her feet on the left.
	var slope := atan2(RAMP_RISE, RAMP_RUN)
	var length := Vector2(RAMP_RUN, RAMP_RISE).length()
	if f > 0:
		return _note_platform(feet + Vector2(10, 2), length, -slope)
	return _note_platform(feet + Vector2(-10 - RAMP_RUN, 2 - RAMP_RISE), length, slope)


func on_beer() -> void:
	for m in nearby_members(AURA_RADIUS):
		m.health.heal(1)


func on_hurt() -> void:
	release(false)


func reset() -> void:
	super()
	swinging = false
	hook = null
	if member:
		member.anim_override = &""
	queue_redraw()


func _note_platform(top_left: Vector2, width: float, angle: float) -> NoteBridge:
	var nb := NoteBridge.new()
	nb.size = Vector2(width, NoteBridge.HEIGHT)
	nb.lifetime = BRIDGE_TIME
	nb.rotation = angle
	spawn_parent().add_child(nb)
	nb.global_position = top_left
	return nb


## The point the line pulls on: her hands, not her feet.
func _origin() -> Vector2:
	return member.global_position + Vector2(0, -20)


func _swing_velocity() -> Vector2:
	return Vector2(cos(_angle), -sin(_angle)) * _omega * _rope


func _find_hook() -> Node2D:
	var from := _origin()
	for h in nearby_in_group(&"grapple_hook", GRAPPLE_RANGE + 14.0):
		var off: Vector2 = h.global_position - from
		if off.length() > GRAPPLE_RANGE or off.y > -8.0:
			continue                        # out of reach, or not above her
		if off.x * member.facing < -24.0:
			continue                        # behind her
		return h
	return null


func _draw() -> void:
	if swinging and is_instance_valid(hook):
		draw_line(Vector2(0, -20), to_local(hook.global_position), Color("e0c080"), 1.0)
