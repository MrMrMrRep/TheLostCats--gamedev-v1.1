@tool
class_name Vehicle
extends Interactable
## Band transport on the world map. BIKES: the whole band rides (1.6x walking
## speed), get on and off anywhere; parked bikes wait where you left them.
## VAN: 2.2x walking speed, but you can only get in and out at a P parking spot.
## The WorldMap drives it; position persists in Game.
## Driving model: the engine (or pedalling) pulls hard from standstill and
## fades toward top speed, letting go coasts with rolling resistance + drag,
## steering the other way brakes. The van's body pitches with acceleration on
## a spring, bounces a little when it stops, and puffs exhaust smoke.

enum Kind { BIKES, VAN }

@export var kind := Kind.BIKES:
	set(value):
		kind = value
		queue_redraw()
@export var save_id: StringName             ## Game flag key for the parked position

const VAN_SHEET := preload("res://public/assets/vehicles/band_van.png")
const VAN_FRAME := Vector2(112, 56)
const VAN_GROUND := 50.0                    # tyre bottoms in the frame
const VAN_FRAMES := 4
const VAN_SCALE := 0.75                     # the sheet is drawn bigger than the world's car scale (docs/city-layout.md)

# Feel per kind: [pull px/s^2, brake px/s^2, rolling px/s^2, drag 1/s]
const FEEL := {Kind.BIKES: [820.0, 700.0, 70.0, 0.35], Kind.VAN: [560.0, 800.0, 36.0, 0.16]}
const PITCH_PER_ACCEL := 0.000045           # rad of body pitch per px/s^2
const PITCH_MAX := 0.045
const PITCH_SPRING := 90.0
const PITCH_DAMP := 9.0
const EXHAUST := Vector2(-39, -7)           # tailpipe (world px, facing right)
const SMOKE_LIFE := 1.4

var velocity := Vector2.ZERO
var accel := 0.0                            # last frame's acceleration, px/s^2
var _odometer := 0.0
var _pedal := 0.0                           # pedal stroke phase (bikes pull in pulses)
var _pitch := 0.0
var _pitch_vel := 0.0
var _smoke: Array = []                      # [global pos, age, size, drift]
var _smoke_timer := 0.0
var facing := 1.0
var occupied := false:
	set(value):
		occupied = value
		queue_redraw()


func _ready() -> void:
	area_size = Vector2(76, 34) if kind == Kind.VAN else Vector2(40, 24)
	super()


func interact(_member: BandMember, map: Node) -> void:
	if map.has_method("board"):
		map.board(self)


func speed_mult() -> float:
	return 2.2 if kind == Kind.VAN else 1.6


func display_name() -> String:
	return "band van" if kind == Kind.VAN else "bikes"


## Drive toward `dir` (-1..1) with top speed `top` px/s; stays within [min_x, max_x].
func drive(dir: float, top: float, delta: float, min_x: float, max_x: float) -> void:
	var f: Array = FEEL[kind]
	var v := velocity.x
	var before_v := v
	if dir != 0.0 and v != 0.0 and signf(dir) != signf(v):
		v = move_toward(v, 0.0, f[1] * delta)          # braking
	elif dir != 0.0:
		facing = signf(dir)
		var frac := clampf(absf(v) / top, 0.0, 1.0)
		var pull: float = f[0] * (1.0 - frac * frac)    # strong low down, fades near top
		if kind == Kind.BIKES:
			_pedal += delta * (4.0 + frac * 6.0)
			pull *= 0.75 + 0.35 * absf(sin(_pedal * PI))
		v += dir * pull * delta
		if absf(v) > top - 1.5:
			v = dir * minf(absf(v), top)
	else:
		v = move_toward(v, 0.0, (f[2] + f[3] * absf(v)) * delta)   # coasting
	velocity.x = v
	accel = (v - before_v) / delta if delta > 0.0 else 0.0
	var before := position.x
	position.x = clampf(position.x + velocity.x * delta, min_x, max_x)
	_odometer += absf(position.x - before)
	if position.x <= min_x or position.x >= max_x:
		velocity.x = 0.0
	queue_redraw()


func _process(delta: float) -> void:
	super(delta)
	if Engine.is_editor_hint() or kind != Kind.VAN:
		return
	# Body pitch: accelerating squats the rear (nose up), braking dips the nose.
	var target := clampf(accel * facing * PITCH_PER_ACCEL, -PITCH_MAX, PITCH_MAX)   # forward accel lifts the nose
	if not occupied:
		target = 0.0
	_pitch_vel += ((target - _pitch) * PITCH_SPRING - _pitch_vel * PITCH_DAMP) * delta
	_pitch += _pitch_vel * delta
	# Exhaust: a lazy puff now and then with the engine on, more under load.
	if occupied:
		_smoke_timer -= delta
		var strain := absf(accel) / 700.0
		if _smoke_timer <= 0.0:
			_smoke_timer = lerpf(0.45, 0.08, clampf(strain, 0.0, 1.0))
			var pipe := global_position + Vector2(EXHAUST.x * facing, EXHAUST.y)
			_smoke.append([pipe, 0.0, randf_range(1.5, 2.5) + strain * 1.5, Vector2(-facing * randf_range(4, 10), randf_range(-14, -8))])
	for puff in _smoke:
		puff[1] += delta
		puff[0] += puff[3] * delta - Vector2(velocity.x * 0.15 * delta, 0)
	_smoke = _smoke.filter(func(puff: Array) -> bool: return puff[1] < SMOKE_LIFE)
	if occupied or not _smoke.is_empty() or absf(_pitch) > 0.0005:
		queue_redraw()


func save_position() -> void:
	if save_id != &"":
		Game.set_flag(save_id, position.x)


func restore_position() -> void:
	if save_id != &"":
		position.x = Game.get_flag(save_id, position.x)


func _draw() -> void:
	if kind == Kind.VAN:
		_draw_van()
	elif not occupied:                      # riding bikes are drawn under each member
		for i in 3:
			BikeSprite.draw_bike(self, Vector2(-12 + i * 10, 0), 1.0, Color(0.85, 0.85, 0.9, 0.9 - i * 0.15))


func _draw_van() -> void:
	var frame := int(_odometer / 3.0) % VAN_FRAMES
	var src := Rect2(Vector2(frame * VAN_FRAME.x, 0), VAN_FRAME)
	# Pitch around the axle under load: rear axle when the nose lifts, front when it dips.
	var axle := Vector2(-34.0 if _pitch > 0.0 else 34.0, -6.0)
	var xf := Transform2D(0.0, Vector2(facing * VAN_SCALE, VAN_SCALE), 0.0, Vector2.ZERO)
	xf = xf * Transform2D(-_pitch, axle) * Transform2D(0.0, -axle)
	draw_set_transform_matrix(xf)
	draw_texture_rect_region(VAN_SHEET, Rect2(Vector2(-VAN_FRAME.x / 2.0, -VAN_GROUND), VAN_FRAME), src)
	draw_set_transform(Vector2.ZERO)
	for puff in _smoke:
		var t: float = puff[1] / SMOKE_LIFE
		var r: float = puff[2] + t * 5.0
		var c := Color(0.85, 0.85, 0.88, 0.75 * (1.0 - t))
		draw_circle(to_local(puff[0]), r, c)
