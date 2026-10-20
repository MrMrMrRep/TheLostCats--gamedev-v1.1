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
## District rules come from the Zone nodes (WorldZone): in "bikes only" zones
## (old town + canal belt) only bikes ride; in "parked cars" zones cars stand
## along the street; elsewhere in town a few cars and bikes; outside town
## proper traffic on both lanes. Numbers: resources/config/traffic_config.tres.
## Origin at x 0, y = the street line.

enum Lane { BACK, FRONT }
enum Kind { CAR, VAN, TRUCK, BIKE, BUS }

const LANE_Y := {Lane.BACK: 0.0, Lane.FRONT: 20.0}   # tyres on the road surface
const LIVERIES := ["BAKKER BAS", "POST", "BLOEMEN", "KOERIER", "LOODGIETER", "VERHUIZER", "", "", ""]
const TRUCK_LIVERIES := ["TRANSPORT", "VERSE MELK", "DE VRIES", "KAAS", "BIER", ""]
const BACK_SCALE := 0.9
const COLOURS := [Color("c94a3d"), Color("5b7fa6"), Color("f2efe8"), Color("2a2a2e"), Color("e0b23a"), Color("6f8f5a"), Color("8a8f99"), Color("3a4a6a")]
const FADE := 40.0
# Per kind: half length and light height (art px): CAR (length from CarArt), VAN, TRUCK, BIKE, BUS.
const LIGHTS := [Vector2(60, -26), Vector2(76, -28), Vector2(150, -40), Vector2(22, -34), Vector2(170, -30)]                          # front-lane cars fade out where the road becomes the quay

@export var lane := Lane.BACK
@export var town := Vector2(1100, 3640)
@export var map_width := 3840.0
@export var map_min := 0.0

var car_free: Array[Vector2] = []           # world x ranges: bikes only (from the zones)
var parked: Array[Vector2] = []             # world x ranges with cars parked along the street

var _cars: Array = []                       # [x, dir, speed, kind, colour, phase, seed]
var _glow: NightGlow                        # head and tail lights at night (game only)
var _parked: Array = []                     # [x, kind, colour, seed] (static)
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7 + lane
	_glow = NightGlow.attach(self)
	car_free = WorldZone.ranges(self, func(z: WorldZone) -> bool: return z.bikes_only)
	parked = WorldZone.ranges(self, func(z: WorldZone) -> bool: return z.parked_cars)
	var cfg := TrafficConfig.current()
	if lane == Lane.BACK:
		var prng := RandomNumberGenerator.new()
		prng.seed = 31
		for r in parked:
			var x := r.x + prng.randf_range(10, 60)
			while x < r.y - 70:
				if prng.randf() < cfg.parked_fill:
					var k := Kind.VAN if prng.randf() < cfg.parked_vans else Kind.CAR
					var sd := prng.randi()
					_parked.append([x, k, CarArt.colour(sd), sd])
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
	var cfg := TrafficConfig.current()
	var want := int(round(span / 640.0 * (cfg.per_screen_town if _in_town(mid) else cfg.per_screen_road)))
	if lane == Lane.FRONT and _in_town(mid):
		want = 0
	if _cars.size() < want:
		_spawn(view)
	queue_redraw()


## Back lane: on the street in town, on the opposite carriageway outside.
func _lane_y(x: float) -> float:
	if lane == Lane.BACK and not _in_town(x):
		return -4.0
	return LANE_Y[lane]


func _town_depth(x: float) -> float:
	return minf(x - town.x, town.y - x)


func _spawn(view: Vector2) -> void:
	var dir := 1.0 if _rng.randf() < 0.5 else -1.0
	var mid := (view.x + view.y) / 2.0
	if not _in_town(mid):                   # motorway: drive on the right; leaving the city
		dir = -1.0 if lane == Lane.BACK else 1.0   # on the far carriageway, inbound on the near one
	var x := view.x - 60.0 if dir > 0.0 else view.y + 60.0
	if _rng.randf() < 0.25:                  # now and then one appears ahead
		x = _rng.randf_range(view.x, view.y)
		if absf(x - (view.x + view.y) / 2.0) < (view.y - view.x) * 0.45:
			return
	x = clampf(x, map_min, map_width)
	var cfg := TrafficConfig.current()
	var kind := Kind.CAR
	if _in(car_free, x):
		if lane == Lane.FRONT:
			return
		kind = Kind.BIKE
	elif _in_town(x):
		if lane == Lane.FRONT:
			return
		var r := _rng.randf()
		var bus := cfg.town_bikes + cfg.town_buses
		kind = Kind.BIKE if r < cfg.town_bikes else (Kind.BUS if r < bus else (Kind.VAN if r < bus + cfg.town_vans else Kind.CAR))
	else:
		var r := _rng.randf()
		var van := cfg.road_trucks + cfg.road_vans
		kind = Kind.TRUCK if r < cfg.road_trucks else (Kind.VAN if r < van else (Kind.BUS if r < van + cfg.road_buses else Kind.CAR))
	var sr := cfg.speed_range(kind)
	var speed := _rng.randf_range(sr.x, sr.y)
	if _in_town(x) and kind != Kind.BIKE:
		speed *= cfg.town_slowdown
	var sd := _rng.randi()
	_cars.append([x, dir, speed, kind, CarArt.colour(sd), 0.0, sd])


func _draw() -> void:
	var back := lane == Lane.BACK
	var s := (BACK_SCALE if back else 1.0) * 0.5   # art px -> world, with depth
	var view := _view()
	for pc in _parked:
		if pc[0] > view.x - 100 and pc[0] < view.y + 100:
			_vehicle(Vector2(pc[0], _lane_y(pc[0])), 1.0 if pc[3] % 2 == 0 else -1.0, s, pc[1], pc[2], 1.0, 0.0, back, pc[3])
	for c in _cars:
		var alpha := 1.0
		if lane == Lane.FRONT and _in_town(c[0]):
			alpha = clampf(1.0 - _town_depth(c[0]) / FADE, 0.0, 1.0)
		_vehicle(Vector2(c[0], _lane_y(c[0])), c[1], s, c[3], c[4], alpha, c[5], back, c[6])
	draw_set_transform(Vector2.ZERO)
	_lights(s)


## Headlights (a beam on the road ahead) and red tail lights, at night.
func _lights(s: float) -> void:
	if _glow == null:
		return
	_glow.clear()
	if WorldDayCycle.night_now > 0.0:
		for c in _cars:
			var kind: int = c[3]
			var half: float = LIGHTS[kind].x
			if kind == Kind.CAR:
				half = CarArt.SPECS[CarArt.style_for(c[6])][0] / 2.0
			var y: float = _lane_y(c[0]) + LIGHTS[kind].y * s
			var dir: float = c[1]
			var front := Vector2(c[0] + dir * half * s, y)
			_glow.add_halo(front + Vector2(dir * 4.0, 0), 5.0, 0.0, Color(1.0, 0.95, 0.8, 0.8))
			_glow.add_halo(front + Vector2(dir * 26.0, 6.0 - LIGHTS[kind].y * s * 0.6), 30.0, 0.0, Color(1.0, 0.92, 0.7, 0.3), 0.25)
			_glow.add_halo(Vector2(c[0] - dir * half * s, y), 2.5 if kind == Kind.BIKE else 4.0, 0.0, Color(1.0, 0.15, 0.1, 0.7))
	_glow.queue_redraw()


func _vehicle(pos: Vector2, dir: float, s: float, kind: int, col: Color, alpha: float, phase: float, back: bool, seed: int) -> void:
	if back:
		col = col.lerp(WorldPalette.HAZE, 0.12)
	draw_set_transform(pos, 0.0, Vector2(dir * s, s))
	match kind:
		Kind.CAR: CarArt.car(self, CarArt.style_for(seed), col, alpha, phase, seed)
		Kind.VAN:
			CarArt.shadow(self, 150, alpha)
			_van(Color(col, alpha), alpha, phase, "")
			var text: String = LIVERIES[absi(seed) % LIVERIES.size()]
			var ink := Color.WHITE if col.get_luminance() < 0.6 else Color("1d1a22")
			_livery(pos, dir, s, text, -70.0, -40.0, 104.0, 11, Color(ink, alpha))
		Kind.TRUCK:
			CarArt.shadow(self, 300, alpha)
			_truck(Color(col, alpha), alpha, phase, "")
			_livery(pos, dir, s, TRUCK_LIVERIES[absi(seed) % TRUCK_LIVERIES.size()], -140.0, -50.0, 190.0, 16, Color(col, alpha))
		Kind.BUS:
			CarArt.shadow(self, 340, alpha)
			_bus(alpha, phase)
		_:
			CarArt.shadow(self, 40, alpha)
			_bike(Color(col, alpha), alpha, phase)


# --- Vehicles in art px, facing right, wheels on y 0 -------------------------

## Lettering on a vehicle side, always readable: drawn unmirrored, with the
## text box mirrored when the vehicle faces left.
func _livery(pos: Vector2, dir: float, s: float, text: String, x0: float, y: float, w: float, size: int, c: Color) -> void:
	if text == "":
		return
	draw_set_transform(pos, 0.0, Vector2(s, s))
	var x := x0 if dir > 0.0 else -(x0 + w)
	draw_string(ThemeDB.fallback_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_CENTER, w, size, c)


func _glass(alpha: float) -> Color:
	return Color(Color("3a4a62"), alpha)


func _van(c: Color, alpha: float, phase: float, livery: String) -> void:
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
	draw_rect(Rect2(-6, -60, 2, 44), c.darkened(0.25))                  # sliding door
	if livery != "":
		draw_string(ThemeDB.fallback_font, Vector2(-70, -40), livery, HORIZONTAL_ALIGNMENT_CENTER, 104, 11,
			Color(Color.WHITE if c.get_luminance() < 0.6 else Color("1d1a22"), alpha))
	CarArt.wheel(self, -48, 11, alpha, phase)
	CarArt.wheel(self, 50, 11, alpha, phase)


func _truck(c: Color, alpha: float, phase: float, livery: String) -> void:
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
	if livery != "":
		draw_string(ThemeDB.fallback_font, Vector2(-140, -50), livery, HORIZONTAL_ALIGNMENT_CENTER, 190, 16, c)
	CarArt.wheel(self, -120, 12, alpha, phase)
	CarArt.wheel(self, -92, 12, alpha, phase)
	CarArt.wheel(self, 110, 12, alpha, phase)


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
	CarArt.wheel(self, -120, 12, alpha, phase)
	CarArt.wheel(self, 110, 12, alpha, phase)


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
