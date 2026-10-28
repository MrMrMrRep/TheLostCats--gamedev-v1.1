class_name GermAbility
extends MemberAbility
## The Germ (drums).
## Special (B): the big punch with rage and fire. On the ground he charges
## forward through everything: rats are knocked out, wooden crates and cracked
## floors in his way burst, and it ends in a shockwave that stuns rats around
## him. In the air it's a slam straight down that does the same where he lands
## (cracked floors!). People stop the charge. Costs stamina.
## Instrument (L): Drumbeat Master. He starts a beat that stops time for
## everything but the band (rats, cases, timed gates, moving platforms); L
## again rewinds the last seconds, L once more plays on (TimeControl).

const DASH_SPEED := 460.0
const DASH_TIME := 0.24
const DASH_BOX := Vector2(26, 24)
const SLAM_SPEED := 520.0
const SLAM_BOX := Vector2(64, 20)
const SHOCK_RADIUS := 64.0
const SHOCK_STUN := 1.5
const FIRE_TIME := 0.4
const MASK_HITS := MASK_WORLD | MASK_ENEMY

var dashing := false
var slamming := false

var _dash_left := 0.0
var _fire := 0.0


func physics_begin(delta: float) -> void:
	if _fire > 0.0:
		_fire = maxf(_fire - delta, 0.0)
		queue_redraw()
	super(delta)


func busy() -> bool:
	return dashing or slamming


func special() -> void:
	rage_punch()


func rage_punch() -> bool:
	if busy():
		return false
	if not member.stamina.try_spend(config.rage_punch_cost if config else 0.0):
		member.show_text("Too tired", Color(0.75, 0.8, 1.0))
		return false
	_fire = FIRE_TIME
	Audio.sfx(&"punch", 0.0)
	if member.is_on_floor():
		dashing = true
		_dash_left = DASH_TIME
		member.play_action(&"special")
	else:
		slamming = true
		member.play_action(&"air_attack")
	queue_redraw()
	return true


func custom_physics(delta: float) -> bool:
	if dashing:
		_dash_left -= delta
		member.velocity = Vector2(member.facing * DASH_SPEED, 0.0)
		var stopped := _smash_ahead()
		member.move_body(delta)
		if stopped or _dash_left <= 0.0 or member.is_on_wall():
			_end_dash()
		return true
	if slamming:
		member.velocity = Vector2(0, SLAM_SPEED)
		member.move_body(delta)
		if member.is_on_floor():
			_slam_impact()
		return true
	return false


func instrument_cost() -> float:
	return config.beat_cost if config else 0.0


## L: start the beat, or step it on (stop -> rewind -> play). Stepping an
## running beat is free.
func play_instrument() -> bool:
	var tc := TimeControl.of(member)
	if tc.is_running():
		_announce(tc.step())
		return true
	return super()


func instrument() -> void:
	var tc := TimeControl.of(member)
	_announce(tc.step())


func reset() -> void:
	super()
	dashing = false
	slamming = false
	_dash_left = 0.0
	_fire = 0.0
	queue_redraw()


func _announce(mode: int) -> void:
	Audio.sfx(&"pound", 0.0)
	var text: String = {TimeControl.Mode.STOP: "STOP", TimeControl.Mode.REWIND: "REWIND", TimeControl.Mode.PLAY: "PLAY"}[mode]
	member.show_text(text, Color("ffd36b"))


## Hit what's right in front of the charge. True if a person stops him.
func _smash_ahead() -> bool:
	var center: Vector2 = member.global_position + Vector2(member.facing * (DASH_BOX.x / 2.0 + 2.0), -14)
	for body in query_box(center, DASH_BOX, MASK_HITS):
		if body is Rat:
			body.defeat()
		elif body is Breakable:
			body.break_by(&"impact")
		elif body.get_parent() is Bouncer:
			body.get_parent().say("Oof! Easy, big man.", 1.0)
			return true
	return false


func _end_dash() -> void:
	dashing = false
	member.velocity.x = 0.0
	_shockwave(member.global_position)


func _slam_impact() -> void:
	slamming = false
	var feet: Vector2 = member.global_position
	for body in query_box(feet + Vector2(0, 6), SLAM_BOX, MASK_WORLD):
		if body is Breakable:
			body.break_by(&"impact")
	_shockwave(feet)


func _shockwave(at: Vector2) -> void:
	Audio.sfx(&"pound")
	GameFeel.shake(member.get_tree(), 5.0, 0.3)
	GameFeel.dust(member.get_parent(), at, 1.8)
	for rat in rats_near(at + Vector2(0, -6), SHOCK_RADIUS):
		if absf(rat.global_position.x - at.x) < 16.0:
			rat.defeat()
		else:
			rat.stun(SHOCK_STUN)


func _draw() -> void:
	if _fire <= 0.0:
		return
	var a := _fire / FIRE_TIME
	var f := member.facing
	for i in 5:                             # flames around the fist
		var p := Vector2(f * (10.0 + i * 3.0), -16.0 + sin(i * 2.1 + _fire * 30.0) * 3.0)
		draw_circle(p, 4.0 - i * 0.5, Color(1.0, 0.55 + i * 0.08, 0.15, 0.8 * a))
