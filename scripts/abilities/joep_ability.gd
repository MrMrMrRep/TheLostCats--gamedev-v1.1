class_name JoepAbility
extends MemberAbility
## Joep (keys).
## Special (B): hack the nearest electrical thing within reach: hack panels,
## electronic door locks, security cameras, amps. A wall plug wired to a device
## reaches it through the wall. (E on a hack panel works too.)
## Instrument (L): electric shockwave through the room. Rats close by are
## knocked out, rats further away are shocked (stunned), and every hackable
## device in range switches (panels, doors, cameras, amps).
## Beer bonus: quick for 5 s.

const HACK_RANGE := 40.0
const SHOCK_NEAR := 72.0                    # 3 tiles: knocked out
const SHOCK_MID := 168.0                    # 7 tiles: stunned, devices switched
const SHOCK_STUN := 2.5
const SHOCK_FX_TIME := 0.5
const BEER_SPEED := 1.3
const BEER_TIME := 5.0

var _quick_left := 0.0
var _shock_fx := 0.0


func setup(m: BandMember) -> void:
	super(m)
	can_hack = true


func physics_begin(delta: float) -> void:
	_quick_left = maxf(_quick_left - delta, 0.0)
	if _shock_fx > 0.0:
		_shock_fx = maxf(_shock_fx - delta, 0.0)
		queue_redraw()
	super(delta)


func special() -> void:
	hack_nearest()


## Hack the nearest hackable within reach. Returns what was hacked (or null).
func hack_nearest() -> Node:
	for target in nearby_in_group(&"hackable", HACK_RANGE):
		if target.hack(member):
			member.play_action(&"special")
			return target
	member.show_text("Nothing to hack", Color(0.75, 0.8, 1.0))
	return null


func instrument_cost() -> float:
	return config.shock_cost if config else 0.0


func instrument() -> void:
	shockwave()


func shockwave() -> void:
	_shock_fx = SHOCK_FX_TIME
	Audio.sfx(&"hack", 0.0)
	GameFeel.shake(member.get_tree(), 3.0, 0.25)
	var center := member.global_position + Vector2(0, -14)
	for rat in rats_near(center, SHOCK_MID):
		if rat.global_position.distance_to(center) <= SHOCK_NEAR:
			rat.defeat()
		else:
			rat.stun(SHOCK_STUN)
	for target in nearby_in_group(&"hackable", SHOCK_MID):
		if not target is WallPlug:         # the devices themselves, not their sockets
			target.hack(member)
	queue_redraw()


func speed_mult() -> float:
	return BEER_SPEED if _quick_left > 0.0 else 1.0


func on_beer() -> void:
	_quick_left = BEER_TIME


func reset() -> void:
	super()
	_quick_left = 0.0
	_shock_fx = 0.0
	queue_redraw()


func _draw() -> void:
	if _shock_fx <= 0.0:
		return
	var t := 1.0 - _shock_fx / SHOCK_FX_TIME
	var r := lerpf(8.0, SHOCK_MID, t)
	var pts := PackedVector2Array()
	for i in 33:                            # a jagged electric ring
		var a := i / 32.0 * TAU
		var rr := r + (3.0 if i % 2 else -3.0)
		pts.append(Vector2(cos(a), sin(a)) * rr + Vector2(0, -14))
	draw_polyline(pts, Color(0.62, 0.95, 1.0, 1.0 - t), 1.5)
	draw_arc(Vector2(0, -14), minf(r, SHOCK_NEAR), 0.0, TAU, 24, Color(1, 1, 1, 0.5 * (1.0 - t)), 1.0)
