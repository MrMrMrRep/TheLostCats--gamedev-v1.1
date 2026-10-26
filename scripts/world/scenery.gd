@tool
class_name WorldScenery
extends Node2D
## Background scenery drawn into a WorldParallax layer. `kind` picks what:
##   SKYLINE     hazy rooftops, church towers, a crane (town only)
##   BACK_STREET muted canal houses and trees behind the street (centre), flats
##               and warehouses (outskirts), trees outside town
##   POLDER_FAR  horizon fields with ditches, wind turbines, a highway (outside town)
##   POLDER_NEAR farms, old windmills, cows, trees (outside town); west of
##               `cows_until` only cows and the odd tree
##   FOREGROUND  big trees right in front of the camera (country road, west),
##               in a layer that moves faster than the street
## Zones are given in world x; a layer with parallax factor f shows world x as
## local x * f, so zone edges are scaled by the factor. Turbine rotors, mill
## sails and highway cars animate.

enum Kind { SKYLINE, BACK_STREET, POLDER_FAR, POLDER_NEAR, FOREGROUND }

const STREET_Y := 288.0

@export var kind := Kind.SKYLINE:
	set(value):
		kind = value
		queue_redraw()
@export var town := Vector2(1100, 3640)     ## world x range of the city
@export var outskirts := 7200.0             ## world x where the centre turns into outskirts
@export var centre := Vector2(1100, 7200)   ## world x range with the church-tower skyline
@export var map_width := 3840.0
@export var map_min := 0.0                  ## world x of the map's west end
@export var cows_until := -100000.0         ## world x: west of it only cows (no farms, mills)
@export var foreground := Vector2.ZERO      ## world x range with foreground trees
@export var farm_clear := Vector2.ZERO      ## world x range where farms step aside (moved west)
@export var seed_value := 5
@export var quiet := Vector2.ZERO           ## world x range without farms, mills or poplars (the airport)
@export_range(0.1, 1.5) var tower_scale := 0.45:  ## skyline: height of the church towers (1 = the old, very tall ones)
	set(value):
		tower_scale = value
		queue_redraw()

var _turbines: Array = []                   # local x of each turbine (rotors)
var _mills: Array = []                      # local x of each windmill (sails)
var _cars: Array = []                       # [x, speed, colour] on the highway


const FAR_WINDOW := Color(0.85, 0.58, 0.28, 0.55)   # lit windows in the hazy distance
const NIGHT_SKYLINE := Color(0.5, 0.52, 0.62)      # the skyline's shade at full night (silhouettes, not glowing)

var _glow: NightGlow                        # windows lit at night (game only)


func _ready() -> void:
	_plan()
	_glow = NightGlow.attach(self)
	queue_redraw()


func _factor() -> float:
	var p := get_parent()
	return p.factor if p is WorldParallax else 1.0


## World x range -> this layer's local x range.
func _local(a: float) -> float:
	return a * _factor()


func _x0() -> float:
	return _local(map_min) - 320.0


func _in_town(local_x: float) -> bool:
	return local_x >= _local(town.x) and local_x <= _local(town.y)


static func _in_spans(spans: Array[Vector2], local_x: float) -> bool:
	for sp in spans:
		if local_x >= sp.x and local_x <= sp.y:
			return true
	return false


func _plan() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	_turbines.clear()
	_mills.clear()
	_cars.clear()
	var x0 := _x0()
	var x1 := _local(map_width) + 320.0
	if kind == Kind.POLDER_FAR:
		var x := x0
		while x < x1:
			if not _in_town(x):
				_turbines.append(x)
			x += rng.randf_range(60, 110)
		for i in 6:
			_cars.append([rng.randf_range(x0, x1), rng.randf_range(18, 40) * (1 if i % 2 == 0 else -1),
				[WorldPalette.WHITE, WorldPalette.ORANGE, WorldPalette.T3, WorldPalette.B2][i % 4]])
	elif kind == Kind.POLDER_NEAR:
		var x := x0
		while x < x1:
			if not _in_town(x) and not _in_town(x + 80) and x > _local(cows_until):
				_mills.append(x)
			x += rng.randf_range(520, 820)  # a mill now and then, not a row of them


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if kind == Kind.SKYLINE:                # the far city goes dark against the night sky
		self_modulate = Color.WHITE.lerp(NIGHT_SKYLINE, WorldDayCycle.night_now)
	if kind == Kind.POLDER_FAR or kind == Kind.POLDER_NEAR:
		for c in _cars:
			c[0] += c[1] * delta
			if c[0] > _local(map_width) + 320.0:
				c[0] = _x0()
			elif c[0] < _x0():
				c[0] = _local(map_width) + 320.0
		queue_redraw()                      # rotors / sails / cars move


func _draw() -> void:
	if _glow:
		_glow.clear()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	if WorldPalette.V3 and kind in [Kind.POLDER_FAR, Kind.POLDER_NEAR, Kind.FOREGROUND]:
		match kind:
			Kind.POLDER_FAR: _v3_far()
			Kind.POLDER_NEAR: _v3_near(rng)
			_: _v3_foreground(rng)
		return
	match kind:
		Kind.SKYLINE: _draw_skyline(rng)
		Kind.BACK_STREET: _draw_back_street(rng)
		Kind.POLDER_FAR: _draw_polder_far(rng)
		Kind.POLDER_NEAR: _draw_polder_near(rng)
		Kind.FOREGROUND: _draw_foreground(rng)
	if _glow:
		_glow.queue_redraw()


func _draw_skyline(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var base := STREET_Y - 40
	# The modern city far behind (towers, flats, chimneys, cranes), palest of
	# all and drawn first: behind the hotels in the west, and from the
	# outskirts out past the airport in the east. The old centre keeps its
	# low roofline in front.
	var far_rng := RandomNumberGenerator.new()
	far_rng.seed = seed_value + 77
	_far_city(far_rng, _local(town.x + FAR_CITY_WEST.x), _local(town.x + FAR_CITY_WEST.y), base)
	_far_city(far_rng, _local(outskirts - 500.0), _local(town.y + FAR_CITY_EAST), base)
	var x := _local(centre.x) - 120
	var end := _local(centre.y) + 60
	while x < end:
		var w := rng.randf_range(14, 30)
		var h := rng.randf_range(18, 44)
		draw_rect(Rect2(x, base - h, w, h + 60), p.HAZE)
		draw_rect(Rect2(x + w / 4, base - h - 5, w / 2, 5), p.HAZE)
		if _glow:                               # at night a few far windows light up
			for k in 3:
				var hx := NightGlow.spot_hash(x, k)
				var hy := NightGlow.spot_hash(x + 7.0, k)
				_glow.add_window(Rect2(floorf(x + 2 + hx * (w - 5)), floorf(base - h + 3 + hy * (h - 6)), 1, 2),
					0.1 + NightGlow.spot_hash(x, k + 9.0) * 1.2, Color(FAR_WINDOW, 0.45))
		x += w
	var spires := int((end - _local(centre.x)) / 260.0) + 1
	for i in spires:
		var sx := _local(centre.x) + 60 + i * 260 + rng.randf_range(-30, 30)
		var th := rng.randf_range(70, 96) * tower_scale   # old Amsterdam: towers only just above the roofs
		match i % 3:
			0:                                  # church tower with a needle spire
				draw_rect(Rect2(sx, base - th, 12, th + 2), p.HAZE_DARK)
				WorldPalette.triangle(self, sx - 2, base - th, 16, 26, p.HAZE_DARK)
				draw_rect(Rect2(sx + 5, base - th - 34, 2, 8), p.HAZE_DARK)
			1:                                  # stepped tower with an open lantern
				draw_rect(Rect2(sx, base - th, 14, th + 2), p.HAZE_DARK)
				draw_rect(Rect2(sx + 2, base - th - 12, 10, 12), p.HAZE_DARK)
				draw_rect(Rect2(sx + 4, base - th - 22, 6, 10), p.HAZE_DARK)
				draw_rect(Rect2(sx + 5, base - th - 19, 4, 5), p.HAZE)
				WorldPalette.disc(self, sx + 7, base - th - 24, 3, p.HAZE_DARK)
			_:                                  # a dome
				draw_rect(Rect2(sx - 4, base - th * 0.7, 22, th * 0.7 + 2), p.HAZE_DARK)
				WorldPalette.disc(self, sx + 7, base - th * 0.7, 11, p.HAZE_DARK)
				draw_rect(Rect2(sx + 6, base - th * 0.7 - 18, 2, 7), p.HAZE_DARK)
		for k in 3:                             # clock / windows, a touch lighter
			if 10 + k * 14 + 6 < th:
				draw_rect(Rect2(sx + 4, base - th + 10 + k * 14, 4, 6), p.HAZE.lerp(p.HAZE_DARK, 0.3))
	var crane := _local((centre.x + centre.y) / 2.0) + 90
	draw_rect(Rect2(crane, base - 80, 2, 80), p.HAZE_DARK)
	draw_rect(Rect2(crane - 30, base - 80, 60, 2), p.HAZE_DARK)


const FAR_CITY_WEST := Vector2(150, 1900)   ## world px from the town's west edge: towers behind the hotels
const FAR_CITY_EAST := 2800.0               ## world px past the town's east edge (behind the airport)


## A hazy band of modern city between local x `a` and `b` (base = its foot):
## two depths, the farther one paler. Rooftop tanks, antennas and lit
## windows at night, like the reference's distant high-rises.
func _far_city(rng: RandomNumberGenerator, a: float, b: float, base: float) -> void:
	if b <= a:
		return
	var far := WorldPalette.T6
	var mid := WorldPalette.T5
	var line := WorldPalette.T4
	# Farther row: tall, sparse towers.
	var x := a + rng.randf_range(0, 20)
	while x < b:
		var w := rng.randf_range(14, 26)
		var h := rng.randf_range(64, 118)
		draw_rect(Rect2(x, base - h, w, h + 60), far)
		if rng.randf() < 0.5:                   # setback crown
			draw_rect(Rect2(x + 3, base - h - 6, w - 6, 6), far)
		if rng.randf() < 0.4:                   # antenna
			draw_rect(Rect2(x + w * 0.5, base - h - 16, 1, 12), far)
		var y := base - h + 6
		while y < base:                         # floor bands, barely there
			draw_rect(Rect2(x + 2, y, w - 4, 1), mid)
			if _glow:
				_glow.add_window(Rect2(floorf(x + 3 + NightGlow.spot_hash(x, y) * (w - 7)), y - 2, 2, 1),
					NightGlow.window_threshold(x, y, false), Color(FAR_WINDOW, 0.4))
			y += 6
		x += w + rng.randf_range(8, 40)
	# Nearer row: blocks, chimneys, cranes, a gas holder, rooftop clutter.
	x = a + rng.randf_range(0, 30)
	while x < b:
		var roll := rng.randf()
		if roll < 0.45:                         # block of flats / offices
			var w := rng.randf_range(30, 56)
			var h := rng.randf_range(34, 62)
			draw_rect(Rect2(x, base - h, w, h + 60), mid)
			draw_rect(Rect2(x + w - 2, base - h, 2, h + 60), line)          # shade on the right
			var y := base - h + 5
			while y < base:
				var wx := x + 3
				while wx < x + w - 4:
					draw_rect(Rect2(wx, y, 2, 2), line)
					wx += 5
				y += 6
			if rng.randf() < 0.6:               # water tank / plant room / antenna
				var tx := x + rng.randf_range(4, w - 12)
				match rng.randi_range(0, 2):
					0:
						draw_rect(Rect2(tx, base - h - 7, 8, 5), line)
						draw_rect(Rect2(tx + 1, base - h - 2, 1, 2), line)
						draw_rect(Rect2(tx + 6, base - h - 2, 1, 2), line)
					1:
						draw_rect(Rect2(tx, base - h - 4, 10, 4), mid)
						draw_rect(Rect2(tx, base - h - 4, 10, 1), line)
					_:
						draw_rect(Rect2(tx + 4, base - h - 12, 1, 12), line)
						draw_rect(Rect2(tx + 2, base - h - 9, 5, 1), line)
			x += w + rng.randf_range(2, 14)
		elif roll < 0.6:                        # factory chimney with bands
			var h := rng.randf_range(70, 96)
			draw_rect(Rect2(x, base - h, 5, h + 60), mid)
			draw_rect(Rect2(x, base - h + 4, 5, 2), line)
			draw_rect(Rect2(x, base - h + 12, 5, 2), line)
			draw_rect(Rect2(x - 12, base - 24, 30, 84), mid)                  # its hall
			WorldPalette.triangle(self, x - 12, base - 24, 30, 5, line)
			x += 30 + rng.randf_range(6, 20)
		elif roll < 0.72:                       # tower crane
			var h := rng.randf_range(80, 104)
			draw_rect(Rect2(x, base - h, 2, h + 60), line)
			draw_rect(Rect2(x - 14, base - h, 50, 2), line)
			draw_rect(Rect2(x - 14, base - h + 2, 6, 3), line)              # counterweight
			draw_rect(Rect2(x + 30, base - h + 2, 1, 10), line)             # hook line
			x += 40 + rng.randf_range(10, 40)
		elif roll < 0.8:                        # gas holder
			var w := 36.0
			var h := 30.0
			draw_rect(Rect2(x, base - h, w, h + 60), mid)
			for k in range(0, int(w), 6):
				draw_rect(Rect2(x + k, base - h, 1, h), line)
			draw_rect(Rect2(x - 1, base - h - 1, w + 2, 2), line)
			x += w + rng.randf_range(10, 30)
		else:                                   # trees between the blocks
			WorldPalette.tree(self, x + 6, base + 4, 12, 0.4)
			x += rng.randf_range(16, 30)


func _draw_back_street(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var base := STREET_Y - 14
	var x := _x0()
	var end := _local(map_width) + 320.0
	while x < end:
		if _in_town(x) and x >= _local(outskirts):
			x += _outskirt_building(rng, x, base)
		elif _in_town(x):
			var w := float(rng.randi_range(22, 30))
			var h := float(rng.randi_range(46, 72))
			var c: Color = p.FACADES[rng.randi_range(0, p.FACADES.size() - 1)].lerp(p.HAZE, 0.5)
			var dark := c.darkened(0.18)
			draw_rect(Rect2(x, base - h, w, h + 14), c)
			draw_rect(Rect2(x + w - 2, base - h, 2, h + 14), dark)          # shade on the right
			match rng.randi_range(0, 3):                                     # gable silhouettes
				0:
					draw_rect(Rect2(x + w * 0.15, base - h - 5, w * 0.7, 5), c)
					draw_rect(Rect2(x + w * 0.3, base - h - 10, w * 0.4, 5), c)
				1:
					WorldPalette.triangle(self, x + 2, base - h, w - 4, 9, c)
				2:
					WorldPalette.triangle(self, x - 1, base - h, w + 2, 8, p.ROOF.lerp(p.HAZE, 0.55))
				_:
					draw_rect(Rect2(x - 1, base - h - 2, w + 2, 2), p.TRIM.lerp(p.HAZE, 0.5))
			if rng.randf() < 0.4:                                            # chimney
				draw_rect(Rect2(x + w * 0.7, base - h - 9, 3, 7), dark)
			var cols := 3 if w >= 27 else 2
			var step := (w - 4) / cols
			for r in int((h - 10) / 11):
				for k in cols:
					var wx := x + 3 + k * step + step / 2 - 1.5
					var wy := base - h + 7 + r * 11
					var lit := rng.randf() < 0.1
					draw_rect(Rect2(wx, wy, 3, 5), (p.LIT if lit else p.GLASS).lerp(p.HAZE, 0.45))
					if _glow:
						_glow.add_window(Rect2(wx, wy, 3, 5), NightGlow.window_threshold(wx, wy, lit), FAR_WINDOW)
					draw_rect(Rect2(wx - 0.5, wy + 5, 4, 1), p.TRIM.lerp(p.HAZE, 0.55))
			if rng.randf() < 0.35:
				WorldPalette.tree(self, x + w, base, 12, 0.35)
			x += w
		else:
			if rng.randf() < 0.55:
				WorldPalette.tree(self, x, base, rng.randi_range(9, 14), 0.3)
			x += rng.randf_range(30, 70)


## A flat or a warehouse behind the outskirts street; returns its width.
func _outskirt_building(rng: RandomNumberGenerator, x: float, base: float) -> float:
	var p := WorldPalette
	if rng.randf() < 0.45:                  # gallery flat
		var w := rng.randf_range(70, 110)
		var h := rng.randf_range(50, 70)
		var c := WorldPalette.W3.lerp(p.HAZE, 0.45)
		draw_rect(Rect2(x, base - h, w, h + 14), c)
		var y := base - h + 6
		while y < base - 4:
			draw_rect(Rect2(x + 2, y, w - 4, 2), p.TRIM.lerp(p.HAZE, 0.5))
			var wx := x + 5
			while wx < x + w - 6:
				draw_rect(Rect2(wx, y + 3, 4, 4), p.GLASS.lerp(p.HAZE, 0.45))
				if _glow:
					_glow.add_window(Rect2(wx, y + 3, 4, 4), NightGlow.window_threshold(wx, y, false), FAR_WINDOW)
				wx += 9
			y += 10
		WorldPalette.tree(self, x + w + 6, base, 10, 0.35)
		return w + 18
	var w := rng.randf_range(60, 100)       # warehouse with a shed roof
	var h := rng.randf_range(24, 36)
	var c: Color = [WorldPalette.R2, WorldPalette.R2, WorldPalette.W2][rng.randi_range(0, 2)].lerp(p.HAZE, 0.45)
	draw_rect(Rect2(x, base - h, w, h + 14), c)
	for k in int(w / 6):
		draw_rect(Rect2(x + k * 6, base - h, 1, h), c.darkened(0.1))
	WorldPalette.triangle(self, x, base - h, w, 6, c.darkened(0.15))
	return w + rng.randf_range(8, 30)


func _draw_polder_far(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var horizon := STREET_Y - 40
	var x0 := _x0()
	var x1 := _local(map_width) + 320.0
	# Fields and ditches (also under the town; the back street covers it there).
	draw_rect(Rect2(x0, horizon, x1 - x0, STREET_Y - horizon + 40), p.FIELD_FAR)
	for k in 4:
		var y := horizon + 9 + k * 7
		draw_rect(Rect2(x0, y, x1 - x0, 7), p.GRASS[k % 3])
		draw_rect(Rect2(x0, y + 6, x1 - x0, 1), p.DITCH)
	# Highway with cars, only outside town.
	draw_rect(Rect2(x0, horizon + 4, x1 - x0, 3), p.ROAD)
	for c in _cars:
		if not _in_town(c[0]):
			draw_rect(Rect2(c[0], horizon + 3, 6, 2), c[2])
	# Turbines with turning rotors.
	var t := Time.get_ticks_msec() / 1000.0
	for tx in _turbines:
		draw_rect(Rect2(tx, horizon - 46, 2, 46), p.TURBINE)
		for k in 3:
			var a: float = t * 1.2 + k * TAU / 3.0 + tx
			draw_line(Vector2(tx + 1, horizon - 46), Vector2(tx + 1 + cos(a) * 16, horizon - 46 + sin(a) * 16), p.TURBINE, 1.0)


func _draw_polder_near(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var base := STREET_Y - 6
	var t := Time.get_ticks_msec() / 1000.0
	var x := _x0()
	var end := _local(map_width) + 320.0
	while x < end:
		if not _in_town(x) and x < _local(cows_until):          # open meadow: just cows
			var roll := rng.randf()
			if roll < 0.7:
				for k in rng.randi_range(2, 6):
					_cow(x + k * rng.randf_range(14, 22), base - 8 + rng.randi_range(-2, 2), rng.randf() < 0.5)
			elif roll < 0.8:
				WorldPalette.tree(self, x, base, rng.randi_range(9, 12))
		elif not _in_town(x):
			var roll := rng.randf()
			if roll < 0.25:
				var fx := x
				if fx + 110.0 > _local(farm_clear.x) and fx < _local(farm_clear.y):
					fx = _local(farm_clear.x) - 120.0   # make room for the building site
				_farm(fx, base)
			elif roll < 0.6:
				for k in rng.randi_range(2, 4):
					_cow(x + k * 18, base - 8, rng.randf() < 0.5)
			else:
				WorldPalette.tree(self, x, base, rng.randi_range(10, 13))
		x += rng.randf_range(90, 160)
	for mx in _mills:
		_windmill(mx, base + 2, 70, t)


func _farm(x: float, base: float) -> void:
	var p := WorldPalette
	draw_rect(Rect2(x, base - 26, 60, 26), p.BARN)
	WorldPalette.triangle(self, x - 4, base - 26, 68, 18, p.BARN_DARK)
	draw_rect(Rect2(x + 24, base - 16, 12, 16), p.BARN_DARK)
	draw_rect(Rect2(x + 70, base - 22, 34, 22), p.WHITE)
	WorldPalette.triangle(self, x + 66, base - 22, 42, 14, p.ROOF)
	draw_rect(Rect2(x + 76, base - 16, 6, 7), p.GLASS)
	draw_rect(Rect2(x + 92, base - 16, 6, 7), p.LIT)


func _cow(x: float, y: float, dark: bool) -> void:
	var body := WorldPalette.T0 if dark else WorldPalette.W5
	var spot := WorldPalette.W5 if dark else WorldPalette.T0
	draw_rect(Rect2(x, y, 12, 6), body)
	draw_rect(Rect2(x + 3, y + 1, 3, 3), spot)
	draw_rect(Rect2(x + 11, y - 2, 4, 4), body)
	draw_rect(Rect2(x + 1, y + 6, 1, 3), body)
	draw_rect(Rect2(x + 9, y + 6, 1, 3), body)


func _windmill(x: float, base: float, h: float, t: float) -> void:
	var p := WorldPalette
	for y in int(h):
		var half := int(lerpf(14, 8, y / h))
		draw_rect(Rect2(x - half, base - y, half * 2, 1), p.MILL)
	draw_rect(Rect2(x - 4, base - 14, 8, 14), p.NAVY)
	draw_rect(Rect2(x - 16, base - h * 0.6, 32, 3), p.MILL.darkened(0.3))
	var hub := Vector2(x, base - h - 2)
	WorldPalette.disc(self, hub.x, hub.y, 3, p.NAVY)
	for k in 4:
		var a := t * 0.6 + k * TAU / 4.0
		var dir := Vector2(cos(a), sin(a))
		var side := Vector2(-dir.y, dir.x)
		draw_line(hub, hub + dir * 34, p.MILL.darkened(0.4), 1.0)
		for s in range(8, 34, 3):
			draw_line(hub + dir * s, hub + dir * s + side * 5, p.SAIL, 1.0)


## Big trees in front of the camera along the country road: trunks rise from
## below the screen, crowns overlap the top of the view now and then.
func _draw_foreground(rng: RandomNumberGenerator) -> void:
	if foreground.y <= foreground.x:
		return
	var x := _local(foreground.x)
	var end := _local(foreground.y)
	while x < end:
		var size := rng.randf_range(80, 120)
		var base := STREET_Y + 150.0
		var lean := rng.randf_range(-8, 8)
		var trunk := WorldPalette.T0
		draw_line(Vector2(x, base), Vector2(x + lean, base - size * 2.0), trunk, 10.0)
		draw_line(Vector2(x + lean, base - size * 1.4), Vector2(x + lean - size * 0.4, base - size * 2.1), trunk, 5.0)
		var cy := base - size * 2.3
		var leaves := PixelArt.leaves()
		for k in 8:
			var a := TAU * k / 8.0
			var c := Vector2(x + lean + cos(a) * size * 0.55, cy + sin(a) * size * 0.35)
			draw_circle(c, size * 0.42, (leaves[0] as Color).darkened(0.45))
		for k in 8:
			var a := TAU * k / 8.0 + 0.3
			var c := Vector2(x + lean + cos(a) * size * 0.45, cy + sin(a) * size * 0.3)
			draw_circle(c + Vector2(-size * 0.08, -size * 0.1), size * 0.3, (leaves[0] as Color).darkened(0.25))
		draw_circle(Vector2(x + lean - size * 0.2, cy - size * 0.25), size * 0.28, (leaves[1] as Color).darkened(0.2))
		x += rng.randf_range(700, 1300)


# --- Style v3 (the polder mocks' sprites, baked once, see V3Painter.scenery) --

const V3_SPRITES := ["farm", "mill", "cow0", "cow1", "sheep", "poplar0", "poplar1", "poplar2",
	"tree0", "tree1", "tree2", "treeh0", "treeh1", "treeh2", "bigtree", "willow", "fields", "jet", "jet_air"]


static func v3_sprite(name: String) -> V3Art:
	return V3Cache.art("scenery_" + name, func() -> V3Art: return V3Painter.scenery(name))


## The bake tool calls this so the game only loads them.
static func bake_v3() -> void:
	for n: String in V3_SPRITES:
		v3_sprite(n)


func _quiet(local_x: float) -> bool:
	var wx := local_x / maxf(_factor(), 0.001) if _factor() > 0.0 else local_x
	return quiet.y > quiet.x and wx > quiet.x and wx < quiet.y


## The far fields run outside town only (plus a little way into its west
## edge, where the hotels still look out over the polder): in town they
## showed through the gaps between the back buildings as green stripes.
func _field_spans() -> Array[Vector2]:
	var x0 := _x0()
	var x1 := _local(map_width) + 320.0
	var a := _local(town.x + FIELDS_INTO_TOWN)
	var b := _local(town.y)
	var out: Array[Vector2] = []
	if a > x0:
		out.append(Vector2(x0, minf(a, x1)))
	if b < x1:
		out.append(Vector2(maxf(b, x0), x1))
	return out


const FIELDS_INTO_TOWN := 900.0             ## world px the far fields reach past the town's west edge


func _v3_far() -> void:
	var horizon := STREET_Y - 40
	var x0 := _x0()
	var x1 := _local(map_width) + 320.0
	var fields := v3_sprite("fields")
	var tex := fields.texture()
	var spans := _field_spans()
	for sp in spans:
		draw_rect(Rect2(sp.x, horizon + 40, sp.y - sp.x, 40), WorldPalette.G2)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	if tex:
		var h := tex.get_height()
		for sp in spans:
			draw_texture_rect(tex, Rect2(sp.x * 2.0, (horizon + 40) * 2.0 - h, (sp.y - sp.x) * 2.0, h), true)
	# Far tree line and farms in haze, low and flat.
	var x := x0
	var r := RandomNumberGenerator.new()
	r.seed = seed_value * 3 + 1
	while x < x1:
		var w := r.randf_range(10, 40)
		var th := r.randf_range(2, 7)
		var far := r.randf() < 0.15
		if _in_spans(spans, x):
			if far:
				draw_rect(Rect2(x * 2.0, (horizon - 7) * 2.0, 24, 14), WorldPalette.T5)
				draw_rect(Rect2(x * 2.0 - 4, (horizon - 9) * 2.0, 32, 4), WorldPalette.T5)
			else:
				draw_rect(Rect2(x * 2.0, (horizon - th) * 2.0, w * 2.0, th * 2.0), WorldPalette.T5)
		x += w + r.randf_range(4, 30)
	for sp in spans:
		draw_rect(Rect2(sp.x * 2.0, horizon * 2.0 - 1, (sp.y - sp.x) * 2.0, 1), WorldPalette.T4)
	# Turbines: tapered masts, a nacelle, three turning blades.
	var t := Time.get_ticks_msec() / 1000.0
	for tx: float in _turbines:
		var bx := tx * 2.0
		var by := horizon * 2.0
		var h := 92.0
		for yy in int(h):
			var tw := 2 + int((h - yy) * 3.0 / h)
			draw_rect(Rect2(bx - tw / 2, by - yy - 1, tw, 1), WorldPalette.T7)
			draw_rect(Rect2(bx + tw / 2, by - yy - 1, 1, 1), WorldPalette.T6)
		draw_rect(Rect2(bx - 3, by - h - 3, 9, 5), WorldPalette.T7)
		draw_rect(Rect2(bx - 3, by - h + 1, 9, 1), WorldPalette.T6)
		var hub := Vector2(bx, by - h - 1)
		for k in 3:
			var a: float = t * 1.2 + k * TAU / 3.0 + tx
			var d := Vector2(cos(a), sin(a))
			draw_line(hub, hub + d * h * 0.46, WorldPalette.T7, 1.0)
			draw_line(hub + Vector2(-d.y, d.x), hub + Vector2(-d.y, d.x) + d * h * 0.18, WorldPalette.T6, 1.0)
		draw_rect(Rect2(hub.x - 1, hub.y - 1, 3, 3), WorldPalette.W5)
	draw_set_transform(Vector2.ZERO)
	# Highway with tiny cars, only outside town.
	for sp in spans:
		draw_rect(Rect2(sp.x, horizon + 4, sp.y - sp.x, 3), WorldPalette.R0)
	for c in _cars:
		if _in_spans(spans, c[0]):
			draw_rect(Rect2(c[0], horizon + 3, 6, 2), c[2])


func _v3_near(rng: RandomNumberGenerator) -> void:
	var base := STREET_Y - 6
	var t := Time.get_ticks_msec() / 1000.0
	var x := _x0()
	var end := _local(map_width) + 320.0
	var trees := ["tree0", "tree1", "tree2"]
	while x < end:
		if not _in_town(x) and x < _local(cows_until):          # open meadow: cows, sheep
			var roll := rng.randf()
			if roll < 0.7:
				for k in rng.randi_range(2, 5):
					var herd := "sheep" if roll < 0.15 else ("cow1" if rng.randf() < 0.3 else "cow0")
					v3_sprite(herd).draw(self, Vector2(x + k * rng.randf_range(16, 24), base + rng.randi_range(-2, 1)))
			elif roll < 0.8:
				v3_sprite(trees[rng.randi_range(0, 2)]).draw(self, Vector2(x, base))
		elif not _in_town(x):
			var roll := rng.randf()
			if roll < 0.25 and not _quiet(x):
				var fx := x
				if fx + 145.0 > _local(farm_clear.x) and fx < _local(farm_clear.y):
					fx = _local(farm_clear.x) - 150.0
				v3_sprite("farm").draw(self, Vector2(fx + 70.0, base))
			elif roll < 0.4 and not _quiet(x):
				for k in rng.randi_range(5, 8):
					v3_sprite("poplar%d" % rng.randi_range(0, 2)).draw(self, Vector2(x + k * 11.0, base - 2))
			elif roll < 0.65:
				for k in rng.randi_range(2, 4):
					v3_sprite("cow1" if rng.randf() < 0.3 else "cow0").draw(self, Vector2(x + k * 20, base))
			else:
				v3_sprite(trees[rng.randi_range(0, 2)]).draw(self, Vector2(x, base))
		x += rng.randf_range(90, 160)
	var mill := v3_sprite("mill")
	for mx: float in _mills:
		if _quiet(mx):
			continue
		mill.draw(self, Vector2(mx, base + 2))
		_v3_sails(Vector2(mx, base + 2 - 97.0), t)


## The mill's four lattice sails, turning (world px; two carry cloth).
func _v3_sails(hub: Vector2, t: float) -> void:
	for s in 4:
		var a := t * 0.6 + s * TAU / 4.0 + 0.5
		var d := Vector2(cos(a), sin(a))
		var n := Vector2(-d.y, d.x)
		if s % 2 == 0:
			var q := PackedVector2Array([hub + d * 11, hub + d * 64, hub + d * 64 + n * 7.5, hub + d * 11 + n * 7.5])
			draw_colored_polygon(q, WorldPalette.W4)
		draw_line(hub + d * 11 + n * 8, hub + d * 64 + n * 8, WorldPalette.W3, 1.0)
		for k in range(12, 64, 4):
			draw_line(hub + d * k, hub + d * k + n * 8, WorldPalette.W3, 1.0)
		draw_line(hub + d * 2, hub + d * 64, WorldPalette.W0, 1.5)
	draw_rect(Rect2(hub.x - 2, hub.y - 2, 4, 4), WorldPalette.W0)


func _v3_foreground(rng: RandomNumberGenerator) -> void:
	if foreground.y <= foreground.x:
		return
	var x := _local(foreground.x)
	var end := _local(foreground.y)
	var tree := v3_sprite("bigtree")
	while x < end:
		rng.randf_range(80, 120)
		rng.randf_range(-8, 8)
		tree.draw(self, Vector2(x, STREET_Y + 150.0), 1.0)
		x += rng.randf_range(700, 1300)
