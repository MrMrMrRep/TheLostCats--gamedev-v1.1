@tool
class_name WorldTraffic
extends Node2D
## Traffic the band never bumps into, at the scale of docs/city-layout.md
## (a car is ~2.3x a band member long, the same size as our van's world), drawn
## at the band sprites' density. Moving vehicles are kept around the camera
## only (spawned just off screen, dropped when far behind).
## Every vehicle keeps to a lane of the road (RoadLanes): two each way on the
## motorway, one each way at the city's edges, one in the centre (one-way
## east for cars; bikes ride both ways). A lane that ends tapers into the one
## that goes on. Each vehicle keeps its distance to the one ahead in its lane
## (the band's van included), so they queue instead of driving through it.
##   BACK   the westbound traffic (the far carriageway, the far half of the
##          town's road), and the parked cars along the far kerb
##   FRONT  the eastbound traffic
## Drawn in depth order around the band's van: behind it (and on the far
## carriageway, behind the band) or in front of it.
## District rules come from the Zone nodes (WorldZone): in "bikes only" zones
## (old town + canal belt) mostly bikes ride, the odd car among them
## (TrafficConfig.quiet_cars); in "parked cars" zones in town cars stand
## along the street. Numbers: resources/config/traffic_config.tres.
## Origin at x 0, y = the street line.

enum Lane { BACK, FRONT }
enum Kind { CAR, VAN, TRUCK, BIKE, BUS }

const LIVERIES := ["BAKKER BAS", "POST", "BLOEMEN", "KOERIER", "LOODGIETER", "VERHUIZER", "", "", ""]
const TRUCK_LIVERIES := ["TRANSPORT", "VERSE MELK", "DE VRIES", "KAAS", "BIER", ""]
const COLOURS := [WorldPalette.B2, WorldPalette.T3, WorldPalette.W5, WorldPalette.T0, WorldPalette.O2, WorldPalette.G2, WorldPalette.R2, WorldPalette.R0]
const FADE := 40.0                          # px over which a car turning off fades out
# Per kind: half length and light height (art px): CAR (length from CarArt), VAN, TRUCK, BIKE, BUS.
const LIGHTS := [Vector2(60, -26), Vector2(76, -28), Vector2(150, -40), Vector2(22, -34), Vector2(170, -30)]
const GAP := 18.0                           # world px kept between two vehicles in a lane (bumper to bumper, at a standstill)
const HEADWAY := 0.35                       # + seconds of travel at their speed
const SAME_LANE := 3.0                      # tyre lines this close: the same lane

@export var lane := Lane.BACK
@export var town := Vector2(1100, 3640)
@export var map_width := 3840.0
@export var map_min := 0.0

var car_free: Array[Vector2] = []           # world x ranges: bikes only (from the zones)
var parked: Array[Vector2] = []             # world x ranges with cars parked along the street

var _cars: Array = []                       # [x, dir, speed, kind, colour, phase, seed, side, cruise, alpha]
var _glow: NightGlow                        # head and tail lights at night (game only)
var _parked: Array = []                     # [x, kind, colour, seed] (static)
var _rng := RandomNumberGenerator.new()
var _mid: Node2D                            # on the road behind the band's van
var _near: Node2D                           # on the road in front of it
var _ci: CanvasItem = self                  # the pass being drawn
var _band_van: Vehicle


func _ready() -> void:
	_rng.seed = 7 + lane
	_glow = NightGlow.attach(self)
	for pass_name in ["Mid", "Near"]:
		var n := Node2D.new()
		n.name = pass_name
		n.z_as_relative = false
		n.z_index = 1 if pass_name == "Mid" else 3   # the band's van is 2 (WorldMap.VAN_Z)
		n.draw.connect(_draw_pass.bind(n))
		add_child(n, false, Node.INTERNAL_MODE_BACK)
		if pass_name == "Mid":
			_mid = n
		else:
			_near = n
	car_free = WorldZone.ranges(self, func(z: WorldZone) -> bool: return z.bikes_only)
	parked = WorldZone.ranges(self, func(z: WorldZone) -> bool: return z.parked_cars)
	var cfg := TrafficConfig.current()
	if lane == Lane.BACK:
		var prng := RandomNumberGenerator.new()
		prng.seed = 31
		var mouths := _road_mouths()
		for r in parked:
			var x := maxf(r.x, town.x) + prng.randf_range(10, 60)
			while x < minf(r.y, town.y) - 70:       # in town only (the motorway has no parking)
				if prng.randf() < cfg.parked_fill and not _in(mouths, x):
					var k := Kind.VAN if prng.randf() < cfg.parked_vans else Kind.CAR
					var sd := prng.randi()
					_parked.append([x, k, CarArt.colour(sd), sd])
				x += prng.randf_range(72, 90) if prng.randf() < 0.85 else prng.randf_range(120, 200)


## Where side streets come out (SideOpening.road_mouth()), widened by a car
## length: nobody parks across them.
func _road_mouths() -> Array[Vector2]:
	var out: Array[Vector2] = []
	var root: Node = owner if owner else (get_tree().current_scene if is_inside_tree() else null)
	if root == null:
		return out
	for o in root.find_children("*", "SideOpening", true, false):
		var m: Vector3 = (o as SideOpening).road_mouth()
		if m != Vector3.ZERO:
			out.append(Vector2(m.x - 48.0, m.y + 48.0))
	return out


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
	var half := ScreenFit.width(self) / 2.0 / cam.zoom.x + 160.0
	var cx := cam.get_screen_center_position().x
	return Vector2(cx - half, cx + half)


## The band's van, if it's on the map.
func band_van() -> Vehicle:
	if _band_van == null or not is_instance_valid(_band_van):
		_band_van = get_tree().get_first_node_in_group(&"band_van") as Vehicle if is_inside_tree() else null
	return _band_van


## A moving vehicle's tyre line.
func car_y(c: Array) -> float:
	return RoadLanes.y(c[0], c[1], c[7])


## Moving vehicles near world x range [a, b]: [x, tyre y, velocity, half length, kind].
func cars_between(a: float, b: float) -> Array:
	var out := []
	for c in _cars:
		if c[0] > a and c[0] < b:
			out.append([c[0], car_y(c), c[1] * c[2], _half(c[3], c[6]) * 0.5, c[3]])
	return out


func _half(kind: int, seed: int) -> float:
	if kind == Kind.CAR:
		return CarArt.SPECS[CarArt.style_for(seed)][0] / 2.0
	return LIGHTS[kind].x


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var view := _view()
	var span := view.y - view.x
	_follow(delta)
	for c in _cars:
		c[0] += c[1] * c[2] * delta
		c[5] += absf(c[2]) * delta
		if _turns_off(c):                   # a westbound car at the one-way centre: off into a side street
			c[9] = maxf(c[9] - delta * 3.0, 0.0)
	_cars = _cars.filter(func(c: Array) -> bool:
		return c[0] > view.x - span * 0.6 and c[0] < view.y + span * 0.6 and c[9] > 0.0)
	var mid := (view.x + view.y) / 2.0
	var cfg := TrafficConfig.current()
	var want := int(round(span / 640.0 * (cfg.per_screen_town if _in_town(mid) else cfg.per_screen_road)))
	if _cars.size() < want:
		_spawn(view)
	queue_redraw()
	_mid.queue_redraw()
	_near.queue_redraw()


## Keep their distance: each slows to the speed of what's ahead in its lane
## (another vehicle or the band's van) and speeds back up to its cruise.
func _follow(delta: float) -> void:
	var van := band_van()
	var vx := van.global_position.x - global_position.x if van else INF
	var vy := van.global_position.y - global_position.y if van else INF
	var vv := van.velocity.x if van else 0.0
	for c in _cars:
		var y := car_y(c)
		var dir: float = c[1]
		var len_c := _half(c[3], c[6]) * 0.5
		var ahead := INF
		var ahead_v := 0.0
		for o in _cars:
			if o == c or (o[1] != dir and c[3] != Kind.BIKE) or absf(car_y(o) - y) > SAME_LANE:
				continue
			var d: float = (o[0] - c[0]) * dir - len_c - _half(o[3], o[6]) * 0.5
			if d > -4.0 and d < ahead:
				ahead = d
				ahead_v = o[2] if o[1] == dir else 0.0
		if van and absf(vy - y) < SAME_LANE + 2.0 and vv * dir > -5.0:   # (an oncoming van they pass)
			var d: float = (vx - c[0]) * dir - len_c - 40.0
			if d > -4.0 and d < ahead:
				ahead = d
				ahead_v = maxf(vv * dir, 0.0)
		var target: float = c[8]
		var safe: float = GAP + c[2] * HEADWAY
		if ahead < safe:
			target = minf(target, ahead_v * clampf(ahead / safe, 0.0, 1.0))
		var rate := 260.0 if target < c[2] else 90.0   # brakes harder than it pulls away
		c[2] = move_toward(c[2], target, rate * delta)


func _turns_off(c: Array) -> bool:
	return c[1] < 0.0 and c[3] != Kind.BIKE and c[0] < RoadLanes.CENTRE.y + RoadLanes.CENTRE_TAPER + 20.0 \
		and c[0] > RoadLanes.CENTRE.x


## BACK: westbound; FRONT: eastbound. In the centre cars only go east.
func _spawn(view: Vector2) -> void:
	var dir := -1.0 if lane == Lane.BACK else 1.0
	var x := view.x - 60.0 if dir > 0.0 else view.y + 60.0
	if _rng.randf() < 0.25:                  # now and then one appears ahead
		x = _rng.randf_range(view.x, view.y)
		if absf(x - (view.x + view.y) / 2.0) < (view.y - view.x) * 0.45:
			return
	x = clampf(x, map_min, map_width)
	var cfg := TrafficConfig.current()
	var kind := Kind.CAR
	var centre := RoadLanes.section(x) == RoadLanes.Section.CENTRE
	if _in(car_free, x) or centre:
		kind = Kind.BIKE                    # bikes, and now and then a car or a delivery van
		var q := _rng.randf()
		if q < cfg.quiet_cars and dir > 0.0:
			kind = Kind.VAN if q < cfg.quiet_cars * 0.35 else Kind.CAR
	elif _in_town(x):
		var r := _rng.randf()
		var bus := cfg.town_bikes + cfg.town_buses
		kind = Kind.BIKE if r < cfg.town_bikes else (Kind.BUS if r < bus else (Kind.VAN if r < bus + cfg.town_vans else Kind.CAR))
	else:
		var r := _rng.randf()
		var van := cfg.road_trucks + cfg.road_vans
		kind = Kind.TRUCK if r < cfg.road_trucks else (Kind.VAN if r < van else (Kind.BUS if r < van + cfg.road_buses else Kind.CAR))
	# The lane: on the motorway trucks and buses keep right, the rest mostly too.
	var side := RoadLanes.Side.LEFT
	if RoadLanes.lanes(x) > 1:
		var right := 0.9 if kind == Kind.TRUCK or kind == Kind.BUS else 0.55
		side = RoadLanes.Side.RIGHT if _rng.randf() < right else RoadLanes.Side.LEFT
	var sr := cfg.speed_range(kind)
	var speed := _rng.randf_range(sr.x, sr.y)
	if _in_town(x) and kind != Kind.BIKE:
		speed *= cfg.town_slowdown
	elif side == RoadLanes.Side.LEFT and RoadLanes.lanes(x) > 1:
		speed *= 1.15                       # the fast lane
	var y := RoadLanes.y(x, dir, side)
	for c in _cars:                         # never on top of another one
		if absf(c[0] - x) < 90.0 and absf(car_y(c) - y) < SAME_LANE:
			return
	var van := band_van()
	if van and absf(van.global_position.x - global_position.x - x) < 90.0 and absf(van.global_position.y - global_position.y - y) < SAME_LANE + 2.0:
		return
	var sd := _rng.randi()
	_cars.append([x, dir, speed, kind, CarArt.colour(sd), 0.0, sd, side, speed, 1.0])


## The tyre line splitting the passes: the band's van (2) between them (a
## vehicle level with it counts as behind).
func _split_y() -> float:
	var van := band_van()
	return van.global_position.y - global_position.y + 0.5 if van else INF


func _draw() -> void:
	_draw_pass(self)


## Self: on the far carriageway (behind the band); _mid: on the road behind
## the van; _near: in front of it.
func _draw_pass(ci: CanvasItem) -> void:
	_ci = ci
	var split := _split_y()
	var lo := -INF
	var hi := 0.0
	if ci == _mid:
		lo = 0.0
		hi = split
	elif ci == _near:
		lo = split
		hi = INF
	var view := _view()
	for pc in _parked:
		var y := RoadLanes.park_y(pc[0])
		if pc[0] > view.x - 100 and pc[0] < view.y + 100 and y >= lo and y < hi:
			_vehicle(Vector2(pc[0], y), 1.0 if pc[3] % 2 == 0 else -1.0, 0.5 * RoadLanes.depth_scale(y), pc[1], pc[2], 1.0, 0.0, y < 0.0, pc[3])
	for c in _cars:
		var y := car_y(c)
		if y >= lo and y < hi:
			_vehicle(Vector2(c[0], y), c[1], 0.5 * RoadLanes.depth_scale(y), c[3], c[4], c[9], c[5], y < 0.0, c[6])
	ci.draw_set_transform(Vector2.ZERO)
	_ci = self
	if ci == self:
		_lights()


## Headlights (a beam on the road ahead) and red tail lights, at night.
func _lights() -> void:
	if _glow == null:
		return
	_glow.clear()
	if WorldDayCycle.night_now > 0.0:
		for c in _cars:
			var kind: int = c[3]
			var y := car_y(c)
			var s := 0.5 * RoadLanes.depth_scale(y)
			var half := _half(kind, c[6])
			var ly: float = y + LIGHTS[kind].y * s
			var dir: float = c[1]
			var front := Vector2(c[0] + dir * half * s, ly)
			var a: float = c[9]
			_glow.add_halo(front + Vector2(dir * 4.0, 0), 5.0, 0.0, Color(1.0, 0.95, 0.8, 0.8 * a))
			_glow.add_halo(front + Vector2(dir * 26.0, 6.0 - LIGHTS[kind].y * s * 0.6), 30.0, 0.0, Color(1.0, 0.92, 0.7, 0.3 * a), 0.25)
			_glow.add_halo(Vector2(c[0] - dir * half * s, ly), 2.5 if kind == Kind.BIKE else 4.0, 0.0, Color(1.0, 0.15, 0.1, 0.7 * a))
	_glow.queue_redraw()


func _vehicle(pos: Vector2, dir: float, s: float, kind: int, col: Color, alpha: float, phase: float, back: bool, seed: int) -> void:
	if back:
		col = col.lerp(WorldPalette.HAZE, 0.12)
	_ci.draw_set_transform(pos, 0.0, Vector2(dir * s, s))
	if WorldPalette.V3 and kind != Kind.CAR and kind != Kind.BIKE:
		match kind:
			Kind.VAN:
				CarArt.v3_vehicle(_ci, "van", ["white", "cream", "silver", "teal", "red"][absi(seed) % 5], alpha)
				var text: String = LIVERIES[absi(seed) % LIVERIES.size()]
				_livery(pos, dir, s, text, -70.0, -40.0, 104.0, 11, Color(WorldPalette.T0, alpha))
			Kind.TRUCK:
				CarArt.v3_vehicle(_ci, "truck", "", alpha)
			Kind.BUS:
				CarArt.v3_vehicle(_ci, "bus", "teal" if absi(seed) % 3 else "red", alpha)
		return
	match kind:
		Kind.CAR: CarArt.car(_ci, CarArt.style_for(seed), col, alpha, phase, seed)
		Kind.VAN:
			CarArt.shadow(_ci, 150, alpha)
			_van(Color(col, alpha), alpha, phase, "")
			var text: String = LIVERIES[absi(seed) % LIVERIES.size()]
			var ink := Color.WHITE if col.get_luminance() < 0.6 else WorldPalette.T0
			_livery(pos, dir, s, text, -70.0, -40.0, 104.0, 11, Color(ink, alpha))
		Kind.TRUCK:
			CarArt.shadow(_ci, 300, alpha)
			_truck(Color(col, alpha), alpha, phase, "")
			_livery(pos, dir, s, TRUCK_LIVERIES[absi(seed) % TRUCK_LIVERIES.size()], -140.0, -50.0, 190.0, 16, Color(col, alpha))
		Kind.BUS:
			CarArt.shadow(_ci, 340, alpha)
			_bus(alpha, phase)
		_:
			CarArt.shadow(_ci, 40, alpha)
			_bike(Color(col, alpha), alpha, phase)


# --- Vehicles in art px, facing right, wheels on y 0 -------------------------

## Lettering on a vehicle side, always readable: drawn unmirrored, with the
## text box mirrored when the vehicle faces left.
func _livery(pos: Vector2, dir: float, s: float, text: String, x0: float, y: float, w: float, size: int, c: Color) -> void:
	if text == "":
		return
	_ci.draw_set_transform(pos, 0.0, Vector2(s, s))
	var x := x0 if dir > 0.0 else -(x0 + w)
	_ci.draw_string(ThemeDB.fallback_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_CENTER, w, size, c)


func _glass(alpha: float) -> Color:
	return Color(WorldPalette.R0, alpha)


func _van(c: Color, alpha: float, phase: float, livery: String) -> void:
	var o := Color(PixelArt.OUTLINE, alpha)
	_ci.draw_rect(Rect2(-76, -64, 152, 52), o)
	_ci.draw_rect(Rect2(-75, -63, 150, 50), c)
	_ci.draw_rect(Rect2(-75, -63, 150, 3), c.lightened(0.2))
	_ci.draw_rect(Rect2(44, -58, 28, 18), _glass(alpha))
	_ci.draw_rect(Rect2(40, -60, 3, 46), c.darkened(0.25))
	_ci.draw_rect(Rect2(-75, -36, 115, 4), c.darkened(0.15))
	_ci.draw_rect(Rect2(68, -30, 6, 5), Color(WorldPalette.W4, alpha))
	_ci.draw_rect(Rect2(-75, -30, 4, 6), Color(WorldPalette.B2, alpha))
	_ci.draw_rect(Rect2(-76, -15, 152, 3), Color(WorldPalette.W0, alpha))
	_ci.draw_rect(Rect2(-6, -60, 2, 44), c.darkened(0.25))                  # sliding door
	if livery != "":
		_ci.draw_string(ThemeDB.fallback_font, Vector2(-70, -40), livery, HORIZONTAL_ALIGNMENT_CENTER, 104, 11,
			Color(Color.WHITE if c.get_luminance() < 0.6 else WorldPalette.T0, alpha))
	CarArt.wheel(_ci, -48, 11, alpha, phase)
	CarArt.wheel(_ci, 50, 11, alpha, phase)


func _truck(c: Color, alpha: float, phase: float, livery: String) -> void:
	var o := Color(PixelArt.OUTLINE, alpha)
	var box := Color(WorldPalette.W4, alpha)
	_ci.draw_rect(Rect2(-150, -84, 214, 70), o)                   # box (300 x 84 art)
	_ci.draw_rect(Rect2(-149, -83, 212, 68), box)
	_ci.draw_rect(Rect2(-149, -83, 212, 6), c)
	_ci.draw_rect(Rect2(-149, -30, 212, 4), c)
	for k in 6:
		_ci.draw_rect(Rect2(-140 + k * 34, -77, 1, 46), box.darkened(0.08))
	_ci.draw_rect(Rect2(68, -66, 80, 52), o)                      # cab
	_ci.draw_rect(Rect2(69, -65, 78, 50), c)
	_ci.draw_rect(Rect2(110, -60, 34, 22), _glass(alpha))
	_ci.draw_rect(Rect2(142, -28, 6, 6), Color(WorldPalette.W4, alpha))
	_ci.draw_rect(Rect2(-150, -16, 300, 4), Color(WorldPalette.W0, alpha))
	if livery != "":
		_ci.draw_string(ThemeDB.fallback_font, Vector2(-140, -50), livery, HORIZONTAL_ALIGNMENT_CENTER, 190, 16, c)
	CarArt.wheel(_ci, -120, 12, alpha, phase)
	CarArt.wheel(_ci, -92, 12, alpha, phase)
	CarArt.wheel(_ci, 110, 12, alpha, phase)


func _bus(alpha: float, phase: float) -> void:
	var o := Color(PixelArt.OUTLINE, alpha)
	var body := Color(WorldPalette.W5, alpha)
	var stripe := Color(WorldPalette.T1, alpha)
	_ci.draw_rect(Rect2(-170, -80, 340, 66), o)                   # city bus (170 x 40 world)
	_ci.draw_rect(Rect2(-169, -79, 338, 64), body)
	_ci.draw_rect(Rect2(-169, -30, 338, 6), stripe)
	var wx := -160.0
	while wx < 140:
		_ci.draw_rect(Rect2(wx, -72, 34, 26), _glass(alpha))
		wx += 40
	_ci.draw_rect(Rect2(150, -72, 18, 40), _glass(alpha))
	_ci.draw_rect(Rect2(-60, -70, 22, 52), stripe.darkened(0.2))  # doors
	_ci.draw_rect(Rect2(60, -70, 22, 52), stripe.darkened(0.2))
	_ci.draw_rect(Rect2(110, -79, 50, 6), Color(WorldPalette.O2, alpha))
	CarArt.wheel(_ci, -120, 12, alpha, phase)
	CarArt.wheel(_ci, 110, 12, alpha, phase)


func _bike(c: Color, alpha: float, phase: float) -> void:
	var o := Color(PixelArt.OUTLINE, alpha)
	var frame := Color(c.darkened(0.2), alpha)
	_ci.draw_arc(Vector2(-15, -10), 10, 0, TAU, 16, o, 2.0)
	_ci.draw_arc(Vector2(17, -10), 10, 0, TAU, 16, o, 2.0)
	_ci.draw_line(Vector2(-15, -10), Vector2(-2, -24), frame, 2.0)
	_ci.draw_line(Vector2(-2, -24), Vector2(17, -10), frame, 2.0)
	_ci.draw_line(Vector2(-2, -24), Vector2(0, -10), frame, 2.0)
	_ci.draw_line(Vector2(0, -10), Vector2(-15, -10), frame, 2.0)
	_ci.draw_line(Vector2(12, -30), Vector2(17, -10), frame, 2.0)
	# rider (same build as a pedestrian, sitting)
	var leg := sin(phase * 0.25) * 5.0
	var skin := Color(WorldPalette.W3, alpha)
	var shirt := Color(c, alpha)
	_ci.draw_line(Vector2(-2, -28), Vector2(leg, -12), Color(WorldPalette.T0, alpha), 4.0)
	_ci.draw_line(Vector2(-2, -28), Vector2(-leg, -12), Color(WorldPalette.R0, alpha), 4.0)
	_ci.draw_rect(Rect2(-6, -50, 12, 22), o)
	_ci.draw_rect(Rect2(-5, -49, 10, 20), shirt)
	_ci.draw_line(Vector2(2, -46), Vector2(12, -32), shirt.darkened(0.15), 3.0)       # arm to the bars
	_ci.draw_rect(Rect2(-5, -60, 10, 10), o)
	_ci.draw_rect(Rect2(-4, -59, 8, 8), skin)
	_ci.draw_rect(Rect2(-5, -61, 10, 4), Color(WorldPalette.W0, alpha))
