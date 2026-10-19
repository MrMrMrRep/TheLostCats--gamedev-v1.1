@tool
class_name WorldTraffic
extends Node2D
## Traffic the band never bumps into, at the scale of docs/city-layout.md
## (a car is ~2.3x a band member long, the same size as our van's world), drawn
## at the band sprites' density. Moving vehicles are kept around the camera
## only (spawned just off screen, dropped when far behind).
##   BACK   the lane behind us (in front of the facades), drawn behind the band,
##          a touch smaller and hazier. Parked cars stand here too.
##   FRONT  the near lane outside town, drawn in front of the band (reflected).
## District rules: in `car_free` ranges (old town + canal belt) only bikes
## ride; in `parked` ranges cars stand along the street; elsewhere in town a
## few cars and bikes; outside town proper traffic on both lanes.
## Origin at x 0, y = the street line.

enum Lane { BACK, FRONT }
enum Kind { CAR, VAN, TRUCK, BIKE, BUS }

const LANE_Y := {Lane.BACK: -2.0, Lane.FRONT: 19.0}
const BACK_SCALE := 0.9
const COLOURS := [Color("c94a3d"), Color("5b7fa6"), Color("f2efe8"), Color("2a2a2e"), Color("e0b23a"), Color("6f8f5a"), Color("8a8f99"), Color("3a4a6a")]
const FADE := 40.0                          # front-lane cars fade out where the road becomes the quay

@export var lane := Lane.BACK
@export var town := Vector2(1100, 3640)
@export var map_width := 3840.0
@export var map_min := 0.0
@export var car_free: Array[Vector2] = []   ## world x ranges: bikes only
@export var parked: Array[Vector2] = []     ## world x ranges with cars parked along the street
@export var per_screen_road := 4            ## vehicles per screen width outside town
@export var per_screen_town := 2            ## per screen width in town

var _cars: Array = []                       # [x, dir, speed, kind, colour, phase]
var _parked: Array = []                     # [x, kind, colour] (static)
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7 + lane
	if lane == Lane.BACK:
		var prng := RandomNumberGenerator.new()
		prng.seed = 31
		for r in parked:
			var x := r.x + prng.randf_range(10, 60)
			while x < r.y - 70:
				if prng.randf() < 0.82:
					var k := Kind.VAN if prng.randf() < 0.18 else Kind.CAR
					_parked.append([x, k, COLOURS[prng.randi_range(0, COLOURS.size() - 1)]])
				x += prng.randf_range(72, 90) if prng.randf() < 0.85 else prng.randf_range(120, 200)


func _in_town(x: float) -> bool:
	return x >= town.x and x <= town.y


func _in(ranges: Array[Vector2], x: float) -> bool:
	for r in ranges:
		if x >= r.x and x <= r.y:
			return true
	return false


func _view() -> Vector2:
	var cam := get_viewport().get_camera_2d() if is_inside_tree() else null
	if cam == null:
		return Vector2(0, 640)
	var half := 320.0 / cam.zoom.x + 160.0
	var cx := cam.get_screen_center_position().x
	return Vector2(cx - half, cx + half)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var view := _view()
	var span := view.y - view.x
	for c in _cars:
		c[0] += c[1] * c[2] * delta
		c[5] += absf(c[2]) * delta
	_cars = _cars.filter(func(c: Array) -> bool:
		if c[0] < view.x - span * 0.6 or c[0] > view.y + span * 0.6:
			return false
		if lane == Lane.FRONT and _in_town(c[0]) and _town_depth(c[0]) > FADE:
			return false
		return not (c[3] != Kind.BIKE and _in(car_free, c[0])))   # cars turn off before the car-free zone
	var mid := (view.x + view.y) / 2.0
	var want := int(round(span / 640.0 * (per_screen_town if _in_town(mid) else per_screen_road)))
	if lane == Lane.FRONT and _in_town(mid):
		want = 0
	if _cars.size() < want:
		_spawn(view)
	queue_redraw()


func _town_depth(x: float) -> float:
	return minf(x - town.x, town.y - x)


func _spawn(view: Vector2) -> void:
	var dir := 1.0 if _rng.randf() < 0.5 else -1.0
	var x := view.x - 60.0 if dir > 0.0 else view.y + 60.0
	if _rng.randf() < 0.25:                  # now and then one appears ahead
		x = _rng.randf_range(view.x, view.y)
		if absf(x - (view.x + view.y) / 2.0) < (view.y - view.x) * 0.45:
			return
	x = clampf(x, map_min, map_width)
	var kind := Kind.CAR
	if _in(car_free, x):
		if lane == Lane.FRONT:
			return
		kind = Kind.BIKE
	elif _in_town(x):
		if lane == Lane.FRONT:
			return
		var r := _rng.randf()
		kind = Kind.BIKE if r < 0.45 else (Kind.BUS if r < 0.52 else (Kind.VAN if r < 0.62 else Kind.CAR))
	else:
		var r := _rng.randf()
		kind = Kind.TRUCK if r < 0.18 else (Kind.VAN if r < 0.36 else (Kind.BUS if r < 0.4 else Kind.CAR))
	var speed: float = {Kind.CAR: _rng.randf_range(110, 190), Kind.VAN: _rng.randf_range(100, 170),
		Kind.TRUCK: _rng.randf_range(80, 120), Kind.BIKE: _rng.randf_range(40, 60), Kind.BUS: _rng.randf_range(70, 110)}[kind]
	if _in_town(x) and kind != Kind.BIKE:
		speed *= 0.55
	_cars.append([x, dir, speed, kind, COLOURS[_rng.randi_range(0, COLOURS.size() - 1)], 0.0])


func _draw() -> void:
	var y: float = LANE_Y[lane]
	var back := lane == Lane.BACK
	var s := (BACK_SCALE if back else 1.0) * 0.5   # art px -> world, with depth
	var view := _view()
	for pc in _parked:
		if pc[0] > view.x - 100 and pc[0] < view.y + 100:
			_vehicle(Vector2(pc[0], y), 1.0, s, pc[1], pc[2], 1.0, 0.0, back)
	for c in _cars:
		var alpha := 1.0
		if lane == Lane.FRONT and _in_town(c[0]):
			alpha = clampf(1.0 - _town_depth(c[0]) / FADE, 0.0, 1.0)
		_vehicle(Vector2(c[0], y), c[1], s, c[3], c[4], alpha, c[5], back)
	draw_set_transform(Vector2.ZERO)


func _vehicle(pos: Vector2, dir: float, s: float, kind: int, col: Color, alpha: float, phase: float, back: bool) -> void:
	if back:
		col = col.lerp(WorldPalette.HAZE, 0.15)
	draw_set_transform(pos, 0.0, Vector2(dir * s, s))
	match kind:
		Kind.CAR: _car(Color(col, alpha), alpha, phase)
		Kind.VAN: _van(Color(col, alpha), alpha, phase)
		Kind.TRUCK: _truck(Color(col, alpha), alpha, phase)
		Kind.BUS: _bus(alpha, phase)
		_: _bike(Color(col, alpha), alpha, phase)


# --- Vehicles in art px, facing right, wheels on y 0 -------------------------

func _wheel(x: float, r: float, alpha: float, phase: float) -> void:
	draw_circle(Vector2(x, -r), r + 1, Color(PixelArt.OUTLINE, alpha))
	draw_circle(Vector2(x, -r), r, Color(0.14, 0.14, 0.16, alpha))
	draw_circle(Vector2(x, -r), r * 0.5, Color(0.62, 0.62, 0.66, alpha))
	var a := phase * 2.0 / r
	draw_line(Vector2(x, -r), Vector2(x + cos(a) * r * 0.5, -r + sin(a) * r * 0.5), Color(0.3, 0.3, 0.34, alpha), 1.0)


func _glass(alpha: float) -> Color:
	return Color(Color("3a4a62"), alpha)


func _car(c: Color, alpha: float, phase: float) -> void:
	var o := Color(PixelArt.OUTLINE, alpha)
	# body (124 x 44 art = 62 x 22 world)
	draw_rect(Rect2(-62, -30, 124, 18), o)
	draw_rect(Rect2(-61, -29, 122, 16), c)
	draw_rect(Rect2(-36, -44, 66, 15), o)                     # cabin
	draw_rect(Rect2(-35, -43, 64, 14), c)
	draw_rect(Rect2(-32, -41, 27, 11), _glass(alpha))
	draw_rect(Rect2(-2, -41, 27, 11), _glass(alpha))
	draw_rect(Rect2(-30, -40, 8, 2), Color(1, 1, 1, 0.3 * alpha))
	draw_rect(Rect2(-4, -43, 3, 30), c.darkened(0.25))       # door seam
	draw_rect(Rect2(8, -26, 6, 2), c.darkened(0.35))          # handles
	draw_rect(Rect2(-22, -26, 6, 2), c.darkened(0.35))
	draw_rect(Rect2(-61, -29, 122, 3), c.lightened(0.2))      # top light
	draw_rect(Rect2(56, -26, 5, 4), Color(Color("f6e8b0"), alpha))
	draw_rect(Rect2(-61, -26, 4, 4), Color(Color("d83a2a"), alpha))
	draw_rect(Rect2(-62, -15, 124, 3), Color(Color("3a3a40"), alpha))   # bumpers line
	draw_rect(Rect2(26, -38, 4, 4), c.darkened(0.3))          # mirror
	_wheel(-38, 10, alpha, phase)
	_wheel(38, 10, alpha, phase)


func _van(c: Color, alpha: float, phase: float) -> void:
	var o := Color(PixelArt.OUTLINE, alpha)
	draw_rect(Rect2(-76, -64, 152, 52), o)
	draw_rect(Rect2(-75, -63, 150, 50), c)
	draw_rect(Rect2(-75, -63, 150, 3), c.lightened(0.2))
	draw_rect(Rect2(44, -58, 28, 18), _glass(alpha))
	draw_rect(Rect2(40, -60, 3, 46), c.darkened(0.25))
	draw_rect(Rect2(-75, -36, 115, 4), c.darkened(0.15))
	draw_rect(Rect2(68, -30, 6, 5), Color(Color("f6e8b0"), alpha))
	draw_rect(Rect2(-75, -30, 4, 6), Color(Color("d83a2a"), alpha))
	draw_rect(Rect2(-76, -15, 152, 3), Color(Color("3a3a40"), alpha))
	_wheel(-48, 11, alpha, phase)
	_wheel(50, 11, alpha, phase)


func _truck(c: Color, alpha: float, phase: float) -> void:
	var o := Color(PixelArt.OUTLINE, alpha)
	var box := Color(Color("eeeae2"), alpha)
	draw_rect(Rect2(-150, -84, 214, 70), o)                   # box (300 x 84 art)
	draw_rect(Rect2(-149, -83, 212, 68), box)
	draw_rect(Rect2(-149, -83, 212, 6), c)
	draw_rect(Rect2(-149, -30, 212, 4), c)
	for k in 6:
		draw_rect(Rect2(-140 + k * 34, -77, 1, 46), box.darkened(0.08))
	draw_rect(Rect2(68, -66, 80, 52), o)                      # cab
	draw_rect(Rect2(69, -65, 78, 50), c)
	draw_rect(Rect2(110, -60, 34, 22), _glass(alpha))
	draw_rect(Rect2(142, -28, 6, 6), Color(Color("f6e8b0"), alpha))
	draw_rect(Rect2(-150, -16, 300, 4), Color(Color("3a3a40"), alpha))
	_wheel(-120, 12, alpha, phase)
	_wheel(-92, 12, alpha, phase)
	_wheel(110, 12, alpha, phase)


func _bus(alpha: float, phase: float) -> void:
	var o := Color(PixelArt.OUTLINE, alpha)
	var body := Color(Color("f2f2f2"), alpha)
	var stripe := Color(Color("2a4ea0"), alpha)
	draw_rect(Rect2(-170, -80, 340, 66), o)                   # city bus (170 x 40 world)
	draw_rect(Rect2(-169, -79, 338, 64), body)
	draw_rect(Rect2(-169, -30, 338, 6), stripe)
	var wx := -160.0
	while wx < 140:
		draw_rect(Rect2(wx, -72, 34, 26), _glass(alpha))
		wx += 40
	draw_rect(Rect2(150, -72, 18, 40), _glass(alpha))
	draw_rect(Rect2(-60, -70, 22, 52), stripe.darkened(0.2))  # doors
	draw_rect(Rect2(60, -70, 22, 52), stripe.darkened(0.2))
	draw_rect(Rect2(110, -79, 50, 6), Color(Color("f2c14a"), alpha))
	_wheel(-120, 12, alpha, phase)
	_wheel(110, 12, alpha, phase)


func _bike(c: Color, alpha: float, phase: float) -> void:
	var o := Color(PixelArt.OUTLINE, alpha)
	var frame := Color(c.darkened(0.2), alpha)
	draw_arc(Vector2(-15, -10), 10, 0, TAU, 16, o, 2.0)
	draw_arc(Vector2(17, -10), 10, 0, TAU, 16, o, 2.0)
	draw_line(Vector2(-15, -10), Vector2(-2, -24), frame, 2.0)
	draw_line(Vector2(-2, -24), Vector2(17, -10), frame, 2.0)
	draw_line(Vector2(-2, -24), Vector2(0, -10), frame, 2.0)
	draw_line(Vector2(0, -10), Vector2(-15, -10), frame, 2.0)
	draw_line(Vector2(12, -30), Vector2(17, -10), frame, 2.0)
	# rider (same build as a pedestrian, sitting)
	var leg := sin(phase * 0.25) * 5.0
	var skin := Color(Color("e8b896"), alpha)
	var shirt := Color(c, alpha)
	draw_line(Vector2(-2, -28), Vector2(leg, -12), Color(Color("2a3040"), alpha), 4.0)
	draw_line(Vector2(-2, -28), Vector2(-leg, -12), Color(Color("3a4050"), alpha), 4.0)
	draw_rect(Rect2(-6, -50, 12, 22), o)
	draw_rect(Rect2(-5, -49, 10, 20), shirt)
	draw_line(Vector2(2, -46), Vector2(12, -32), shirt.darkened(0.15), 3.0)       # arm to the bars
	draw_rect(Rect2(-5, -60, 10, 10), o)
	draw_rect(Rect2(-4, -59, 8, 8), skin)
	draw_rect(Rect2(-5, -61, 10, 4), Color(Color("3a2a22"), alpha))
