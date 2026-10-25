@tool
class_name WorldBridge
extends Node2D
## A gap in the house row with a view down a side street or a side canal, in
## real one-point perspective from eye height (like standing on the opposite
## quay): the facades along both sides recede to a vanishing point, with their
## windows, doors and roof edges, trees and lamps on the quays, a distant
## bridge, and the city fading into haze at the end. Light comes from the left,
## so the left row is lit and the right row is in shade.
##   CANAL   water between two cobbled quays; our street crosses it on a
##           bridge (iron railing, stone arch in the front quay wall)
##   STREET  a cobbled side street with pavements, bikes and people
## Things that spill outside the gap are hidden behind the corner houses
## (the City is drawn after this). Origin = street line, centre of the gap.

enum Kind { CANAL, STREET }

const EYE_Y := -30.0                        # vanishing point height (eye level)
const FOCAL := 110.0                        # depth px per unit of z
const DEPTH := 1500.0
const WATER_Y := 10.0                       # side canal water, below street level

@export var width := 150.0:
	set(value):
		width = value
		queue_redraw()
@export var kind := Kind.CANAL:
	set(value):
		kind = value
		queue_redraw()
@export var seed_value := 3:
	set(value):
		seed_value = value
		queue_redraw()
@export var landmark := false:              ## the Pontsteiger closes the view at the far end
	set(value):
		landmark = value
		queue_redraw()


## World point (X across, Y up negative, d depth) -> screen.
func P(x: float, y: float, d: float) -> Vector2:
	var z := 1.0 + d / FOCAL
	return Vector2(x / z, EYE_Y + (y - EYE_Y) / z)


func _haze(c: Color, d: float) -> Color:
	return c.lerp(WorldPalette.HAZE, clampf(d / DEPTH, 0.0, 1.0) * 0.8)


func _quad(a: Vector2, b: Vector2, c: Vector2, e: Vector2, col: Color) -> void:
	draw_colored_polygon(PackedVector2Array([a, b, c, e]), col)


func _draw() -> void:
	var p := WorldPalette
	var half := width / 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var canal := kind == Kind.CANAL
	var edge := half - (half * 0.24 if canal else 12.0)     # water edge / kerb
	_backdrop(half, rng)
	# Ground: water or cobbles, then the quays / pavements.
	if canal:
		var steps := 12
		for i in steps:
			var d0 := DEPTH * pow(float(i) / steps, 1.6)
			var d1 := DEPTH * pow(float(i + 1) / steps, 1.6)
			var wc := _haze(p.WATER.lerp(p.WATER_HI, 0.1 + 0.25 * float(i) / steps), d0)
			_quad(P(-edge, WATER_Y, d0), P(edge, WATER_Y, d0), P(edge, WATER_Y, d1), P(-edge, WATER_Y, d1), wc)
		for k in 9:                                         # glints, denser far away
			var d := DEPTH * pow((k + 0.5) / 9.0, 1.4)
			var a := P(-edge * 0.6, WATER_Y, d)
			var b := P(edge * 0.6, WATER_Y, d)
			draw_line(a + Vector2(rng.randf_range(0, 6), 0), b - Vector2(rng.randf_range(0, 6), 0), _haze(p.WATER_HI, d), 1.0)
		for s in [-1.0, 1.0]:                               # quay walls down to the water
			_quad(P(s * edge, 0, 0), P(s * edge, 0, DEPTH), P(s * edge, WATER_Y, DEPTH), P(s * edge, WATER_Y, 0), _haze(p.QUAY_DARK, 400))
	else:
		_quad(P(-edge, 0, 0), P(edge, 0, 0), P(edge, 0, DEPTH), P(-edge, 0, DEPTH), _haze(p.COBBLE, 300))
		for k in 14:                                        # cobble courses
			var d := DEPTH * pow(k / 14.0, 1.5)
			draw_line(P(-edge, 0, d), P(edge, 0, d), _haze(p.COBBLE_DARK, d), 1.0)
		draw_line(P(0, 0, 0), P(0, 0, DEPTH), _haze(p.COBBLE_DARK, 300), 1.0)
	for s in [-1.0, 1.0]:
		_quad(P(s * edge, 0, 0), P(s * half, 0, 0), P(s * half, 0, DEPTH), P(s * edge, 0, DEPTH), _haze(p.COBBLE.lightened(0.08), 300))
		draw_line(P(s * edge, 0, 0), P(s * edge, 0, DEPTH), _haze(p.CURB, 200), 1.0)
	# Everything standing up, drawn far to near so nearer things overlap.
	var items := []
	for s in [-1.0, 1.0]:
		var d := 0.0
		while d < DEPTH:
			var len := rng.randf_range(48, 80)
			var pal: Array = CityBlock.BRICKS if rng.randf() < 0.6 else CityBlock.PAINTED
			items.append({"t": "house", "s": s, "d0": d, "d1": d + len, "h": rng.randf_range(115, 175),
				"c": pal[rng.randi_range(0, pal.size() - 1)], "shop": rng.randf() < 0.3, "salt": rng.randi()})
			d += len
		var td := rng.randf_range(20, 70)
		while td < DEPTH * 0.8:
			var what := "tree" if (canal or rng.randf() < 0.35) and rng.randf() < 0.75 else "lamp"
			items.append({"t": what, "s": s, "d0": td, "x": s * (edge + (half - edge) * 0.35), "salt": rng.randi()})
			if rng.randf() < 0.35:
				items.append({"t": "person", "s": s, "d0": td + rng.randf_range(10, 40), "x": s * (edge + (half - edge) * 0.6), "salt": rng.randi()})
			td += rng.randf_range(80, 140)
	if canal:
		items.append({"t": "bridge", "s": 0.0, "d0": rng.randf_range(600, 800)})
	else:
		for k in 3:
			items.append({"t": "cyclist", "s": 0.0, "d0": rng.randf_range(80, 900), "x": rng.randf_range(-edge * 0.6, edge * 0.6), "salt": rng.randi()})
	items.sort_custom(func(a, b): return a.d0 > b.d0)
	for it in items:
		match it.t:
			"house": _house(it, half)
			"tree": _tree(it.x, it.d0, it.salt)
			"lamp": _lamp(it.x, it.d0)
			"person": _person(it.x, it.d0, it.salt)
			"cyclist": _person(it.x, it.d0, it.salt, true)
			"bridge": _far_bridge(half, edge, it.d0)
	if canal:
		_front(half)


## The city at the far end: hazy rooftops and a church tower at the vanishing point.
func _backdrop(half: float, rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var x := -half
	while x < half:
		var w := rng.randf_range(5, 12)
		var top := rng.randf_range(-58, -42)
		draw_rect(Rect2(x, top, w + 1, EYE_Y - top + 2), p.HAZE)
		x += w
	if landmark:
		_pontsteiger()
		return
	var tx := rng.randf_range(-12, 8)
	draw_rect(Rect2(tx, -86, 5, 58), p.HAZE_DARK)
	WorldPalette.triangle(self, tx - 1, -86, 7, 12, p.HAZE_DARK)


## The Pontsteiger (Houthaven) on the water at the end of the canal: a low wing,
## two towers of different width and, joining them at the top, a block that
## rests on a white truss, with sky through the gap. Far away, so a little hazy,
## but crisp enough to read: the focal point of this view.
func _pontsteiger() -> void:
	var haze := 0.38
	var wall := WorldPalette.W3.lerp(WorldPalette.HAZE, haze)
	var shade := WorldPalette.R3.lerp(WorldPalette.HAZE, haze)
	var win := WorldPalette.R0.lerp(WorldPalette.HAZE, haze * 0.8)
	var lit := WorldPalette.O3.lerp(WorldPalette.HAZE, haze * 0.6)
	# Drawn small (0.34): it stands far back, at the end of the canal.
	draw_set_transform(Vector2(0, EYE_Y + 1.0), 0.0, Vector2(0.34, 0.34))
	var base := 0.0
	var x0 := -46.0                          # left edge of the towers
	var H := 214.0
	var lt := Rect2(x0, base - H, 26, H)                     # left tower (narrow)
	var rt := Rect2(x0 + 58, base - H, 40, H)                # right tower (wide)
	var top := Rect2(x0, base - H, 98, 52)                   # the block on top
	var wing := Rect2(x0 - 34, base - 62, 150, 62)           # the low wing by the water
	for r in [wing, lt, rt, top]:
		draw_rect(r, wall)
	draw_rect(Rect2(rt.position.x + rt.size.x - 8, rt.position.y, 8, H), shade)   # shaded side
	draw_rect(Rect2(wing.position.x + wing.size.x - 6, wing.position.y, 6, 62), shade)
	# Window grid, rows of 4 px, with the odd lit room.
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for r: Rect2 in [lt, rt, top]:
		var yy: float = r.position.y + 3
		while yy < r.position.y + r.size.y - 3:
			var xx: float = r.position.x + 2
			while xx < r.position.x + r.size.x - 3:
				draw_rect(Rect2(xx, yy, 2, 2), lit if rng.randf() < 0.06 else win)
				xx += 4
			yy += 4
	var y := wing.position.y + 4
	while y < base - 6:                                      # the wing: long bands of glass
		draw_rect(Rect2(wing.position.x + 2, y, wing.size.x - 8, 2), win)
		y += 6
	# The gap with sky behind and the white truss under the top block.
	var gap := Rect2(x0 + 26, top.position.y + top.size.y, 32, wing.position.y - (top.position.y + top.size.y))
	draw_rect(gap, WorldPalette.SKY_LOW.lerp(WorldPalette.HAZE, 0.2))
	draw_rect(Rect2(gap.position.x, gap.position.y, gap.size.x, 2), shade.darkened(0.2))   # underside
	var ty := top.position.y + top.size.y - 9
	var white := Color(0.97, 0.97, 0.98)
	draw_rect(Rect2(x0, ty, 98, 1), white)
	draw_rect(Rect2(x0, ty + 8, 98, 1), white)
	var k := 0
	while k + 12 <= 98:
		draw_line(Vector2(x0 + k, ty + 8), Vector2(x0 + k + 6, ty), white, 1.0)
		draw_line(Vector2(x0 + k + 6, ty), Vector2(x0 + k + 12, ty + 8), white, 1.0)
		k += 12
	# Columns under the wing at the waterline, and the roof edge.
	for cx in range(int(wing.position.x) + 4, int(wing.position.x + wing.size.x), 10):
		draw_rect(Rect2(cx, base - 4, 1, 4), shade.darkened(0.3))
	draw_rect(Rect2(x0, base - H - 1, 98, 1), shade)
	draw_set_transform(Vector2.ZERO)


func _house(it: Dictionary, half: float) -> void:
	var p := WorldPalette
	var s: float = it.s
	var X := s * half
	var d0: float = it.d0
	var d1: float = it.d1
	var h: float = it.h
	var rng := RandomNumberGenerator.new()
	rng.seed = it.salt
	var lit: Color = it.c
	var face := lit.lightened(0.04) if s < 0 else lit.darkened(0.28)     # left row in the sun
	var front := lit.darkened(0.12) if s < 0 else lit.darkened(0.4)
	var mid := (d0 + d1) / 2.0
	# Front face (toward us): only its top shows where it rises above the nearer house.
	_quad(P(X, 0, d0), P(X + s * 70, 0, d0), P(X + s * 70, -h, d0), P(X, -h, d0), _haze(front, d0))
	# Roof edge running back from the facade, and a gable notch now and then.
	var roof := _haze(WorldPalette.T0 if rng.randf() < 0.6 else WorldPalette.R0, mid)
	_quad(P(X, -h, d0), P(X, -h, d1), P(X + s * 26, -h - 20, d1), P(X + s * 26, -h - 20, d0), roof)
	if rng.randf() < 0.5:
		_quad(P(X, -h, d0), P(X, -h - 16, d0 + 8), P(X, -h - 16, d1 - 8), P(X, -h, d1), _haze(face, mid))
	# The facade along the side street / canal.
	_quad(P(X, 0, d0), P(X, 0, d1), P(X, -h, d1), P(X, -h, d0), _haze(face, mid))
	draw_line(P(X, -h, d0), P(X, -h, d1), _haze(p.TRIM, mid), 1.0)            # cornice
	draw_line(P(X, 0, d0), P(X, -h, d0), _haze(face.darkened(0.35), mid), 1.0)  # party wall line
	if mid > DEPTH * 0.75:
		return
	# Windows in perspective, storey by storey.
	var glass := WorldPalette.T0
	var y := -58.0
	while y > -h + 18:
		var wd := d0 + 7.0
		while wd + 11.0 < d1 - 5.0:
			var gl := WorldPalette.O2 if rng.randf() < 0.12 else glass
			_quad(P(X, y, wd - 1), P(X, y, wd + 12), P(X, y - 20, wd + 12), P(X, y - 20, wd - 1), _haze(p.TRIM, wd))
			_quad(P(X, y - 2, wd + 1), P(X, y - 2, wd + 10), P(X, y - 18, wd + 10), P(X, y - 18, wd + 1), _haze(gl, wd))
			wd += 21.0
		y -= 38.0
	# Ground floor: a door, or a shop window with an awning.
	if it.shop:
		var ac: Color = [p.ORANGE, WorldPalette.B2, WorldPalette.G1][rng.randi_range(0, 2)]
		_quad(P(X, -6, d0 + 6), P(X, -6, d1 - 6), P(X, -30, d1 - 6), P(X, -30, d0 + 6), _haze(WorldPalette.P0, mid))
		_quad(P(X, -32, d0 + 4), P(X, -32, d1 - 4), P(X - s * 10, -26, d1 - 4), P(X - s * 10, -26, d0 + 4), _haze(ac, mid))
	else:
		var dd := d0 + (d1 - d0) * 0.3
		_quad(P(X, 0, dd), P(X, 0, dd + 12), P(X, -34, dd + 12), P(X, -34, dd), _haze(CityBlock.DOORS[rng.randi_range(0, 5)], dd))


func _tree(x: float, d: float, salt: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = salt
	var z := 1.0 + d / FOCAL
	var base := P(x, 0, d)
	var top := P(x, -46, d)
	draw_line(base, top, _haze(WorldPalette.P0, d), maxf(1.0, 3.0 / z))
	var r := 26.0 / z
	var c := top + Vector2(0, -r * 0.4)
	var leaves := PixelArt.leaves()
	draw_circle(c, r + 1.0, _haze(leaves[0].darkened(0.4), d))
	draw_circle(c, r, _haze(leaves[0], d))
	draw_circle(c + Vector2(-r * 0.3, -r * 0.3), r * 0.6, _haze(leaves[1], d))
	draw_circle(c + Vector2(-r * 0.45, -r * 0.5), r * 0.25, _haze(leaves[2], d))


func _lamp(x: float, d: float) -> void:
	var z := 1.0 + d / FOCAL
	draw_line(P(x, 0, d), P(x, -44, d), _haze(WorldPalette.T0, d), maxf(1.0, 2.0 / z))
	var l := P(x, -46, d)
	draw_rect(Rect2(l - Vector2(2, 3) / z, Vector2(5, 6) / z), _haze(WorldPalette.O3, d))


func _person(x: float, d: float, salt: int, cycling := false) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = salt
	var z := 1.0 + d / FOCAL
	var feet := P(x, 0, d)
	var hgt := 27.0 / z
	var w := maxf(1.0, 6.0 / z)
	var shirt: Color = WorldPedestrians.SHIRTS[rng.randi_range(0, 8)]
	draw_rect(Rect2(feet.x - w / 2, feet.y - hgt * 0.45, w, hgt * 0.45), _haze(WorldPalette.T0, d))
	draw_rect(Rect2(feet.x - w / 2, feet.y - hgt * 0.85, w, hgt * 0.42), _haze(shirt, d))
	draw_rect(Rect2(feet.x - w * 0.4, feet.y - hgt, w * 0.8, hgt * 0.17), _haze(WorldPedestrians.SKIN[rng.randi_range(0, 4)], d))
	if cycling:
		draw_arc(feet + Vector2(-w, -3.0 / z), 3.0 / z, 0, TAU, 8, _haze(PixelArt.OUTLINE, d), 1.0)
		draw_arc(feet + Vector2(w, -3.0 / z), 3.0 / z, 0, TAU, 8, _haze(PixelArt.OUTLINE, d), 1.0)


## A brick bridge across the side canal further down: deck, parapet, arches.
func _far_bridge(half: float, edge: float, d: float) -> void:
	var p := WorldPalette
	var brick := _haze(WorldPalette.B1, d)
	var tl := P(-half, -16, d)
	var br := P(half, WATER_Y, d)
	draw_rect(Rect2(tl, br - tl), brick)
	var arches := 3
	var span := edge * 2.0 / arches
	for k in arches:
		var cx := -edge + span * (k + 0.5)
		var c := P(cx, WATER_Y, d)
		var r := span * 0.38 / (1.0 + d / FOCAL)
		draw_circle(c, r, _haze(p.WATER_DEEP, d))
	draw_rect(Rect2(P(-half, -16, d), P(half, -14, d) - P(-half, -16, d)), _haze(p.TRIM, d))
	var rail := P(-half, -22, d)
	draw_line(rail, P(half, -22, d), _haze(p.IRON, d), 1.0)


## Our bridge: iron railing on the far side of the deck, stone arch below.
func _front(half: float) -> void:
	var p := WorldPalette
	var x := -half
	while x <= half:
		draw_rect(Rect2(x, -8, 1, 8), p.IRON)
		x += 6
	draw_rect(Rect2(-half, -8, width, 1), p.IRON)
	draw_rect(Rect2(-half - 3, -10, 4, 10), p.QUAY)
	draw_rect(Rect2(half - 1, -10, 4, 10), p.QUAY)
	var aw := width * 0.5
	for i in int(aw):
		var t := (i - aw / 2.0) / (aw / 2.0)
		var hgt := 6.0 * sqrt(maxf(1.0 - t * t, 0.0))
		draw_rect(Rect2(-aw / 2 + i, 22 - hgt, 1, hgt), p.WATER_DEEP)
	draw_rect(Rect2(-aw / 2 - 2, 15, aw + 4, 1), p.QUAY_DARK)
