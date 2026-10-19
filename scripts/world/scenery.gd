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
@export var seed_value := 5

var _turbines: Array = []                   # local x of each turbine (rotors)
var _mills: Array = []                      # local x of each windmill (sails)
var _cars: Array = []                       # [x, speed, colour] on the highway


func _ready() -> void:
	_plan()
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
				[WorldPalette.WHITE, WorldPalette.ORANGE, Color("5b7fa6"), Color("c94a3d")][i % 4]])
	elif kind == Kind.POLDER_NEAR:
		var x := x0
		while x < x1:
			if not _in_town(x) and not _in_town(x + 80) and x > _local(cows_until):
				_mills.append(x)
			x += rng.randf_range(520, 820)  # a mill now and then, not a row of them


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if kind == Kind.POLDER_FAR or kind == Kind.POLDER_NEAR:
		for c in _cars:
			c[0] += c[1] * delta
			if c[0] > _local(map_width) + 320.0:
				c[0] = _x0()
			elif c[0] < _x0():
				c[0] = _local(map_width) + 320.0
		queue_redraw()                      # rotors / sails / cars move


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	match kind:
		Kind.SKYLINE: _draw_skyline(rng)
		Kind.BACK_STREET: _draw_back_street(rng)
		Kind.POLDER_FAR: _draw_polder_far(rng)
		Kind.POLDER_NEAR: _draw_polder_near(rng)
		Kind.FOREGROUND: _draw_foreground(rng)


func _draw_skyline(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var base := STREET_Y - 40
	var x := _local(centre.x) - 120
	var end := _local(centre.y) + 60
	while x < end:
		var w := rng.randf_range(14, 30)
		var h := rng.randf_range(18, 44)
		draw_rect(Rect2(x, base - h, w, h + 60), p.HAZE)
		draw_rect(Rect2(x + w / 4, base - h - 5, w / 2, 5), p.HAZE)
		x += w
	var spires := int((end - _local(centre.x)) / 260.0) + 1
	for i in spires:
		var sx := _local(centre.x) + 60 + i * 260 + rng.randf_range(-30, 30)
		var th := rng.randf_range(70, 96)
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
			draw_rect(Rect2(sx + 4, base - th + 10 + k * 14, 4, 6), p.HAZE.lerp(p.HAZE_DARK, 0.3))
	var crane := _local((centre.x + centre.y) / 2.0) + 90
	draw_rect(Rect2(crane, base - 80, 2, 80), p.HAZE_DARK)
	draw_rect(Rect2(crane - 30, base - 80, 60, 2), p.HAZE_DARK)


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
		var c := Color("c9b9a6").lerp(p.HAZE, 0.45)
		draw_rect(Rect2(x, base - h, w, h + 14), c)
		var y := base - h + 6
		while y < base - 4:
			draw_rect(Rect2(x + 2, y, w - 4, 2), p.TRIM.lerp(p.HAZE, 0.5))
			var wx := x + 5
			while wx < x + w - 6:
				draw_rect(Rect2(wx, y + 3, 4, 4), p.GLASS.lerp(p.HAZE, 0.45))
				wx += 9
			y += 10
		WorldPalette.tree(self, x + w + 6, base, 10, 0.35)
		return w + 18
	var w := rng.randf_range(60, 100)       # warehouse with a shed roof
	var h := rng.randf_range(24, 36)
	var c: Color = [Color("8a8f99"), Color("6f8f9a"), Color("a08a6a")][rng.randi_range(0, 2)].lerp(p.HAZE, 0.45)
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
				_farm(x, base)
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
	var body := Color("2a2a2e") if dark else Color("f2f0ea")
	var spot := Color("f2f0ea") if dark else Color("2a2a2e")
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
		var trunk := Color("2e2620")
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
