extends SceneTree
## Style v2 mock (2026-10-25): the 16/32-bit look with a ~32-colour
## teal / cream / coral / olive palette taken from the user's reference images.
## Renders a canal-street frame and a polder frame at 640x360 into docs/art/
## (1x, 3x, plus a palette strip). Everything is snapped to PALETTE at the end.
## Run: Summer --headless --path . --script res://tools/style_mock_v2.gd

const W := 640
const H := 360
const STREET_Y := 206                       # feet line (top of the street)
const WATER_Y := 228                        # top of the canal / ditch

# --- Palette v2 (32 colours) ------------------------------------------------
# Teal ramp: sky, haze, water, glass, teal facades, shadows. T0 is the darkest
# colour of the game (no black).
const T0 := Color("1d2838")
const T1 := Color("2c4152")
const T2 := Color("35606c")
const T3 := Color("4b8189")
const T4 := Color("64a2a6")
const T5 := Color("86c1bb")
const T6 := Color("b0dcc9")
const T7 := Color("dcefd2")
# Warm ramp: wood, stone, cream trims, clouds.
const W0 := Color("4a3434")
const W1 := Color("7a5a4a")
const W2 := Color("b08e6c")
const W3 := Color("d8bf94")
const W4 := Color("f3e4bc")
const W5 := Color("fff7df")
# Brick / coral ramp (B4 = the peach glow).
const B0 := Color("5e2e36")
const B1 := Color("8f3f40")
const B2 := Color("bd5a4b")
const B3 := Color("e07d5e")
const B4 := Color("f2a77a")
# Orange / mustard / lamp light.
const O1 := Color("e08a36")
const O2 := Color("f2bc58")
const O3 := Color("f8dc8a")
# Greens (olive to yellow-green).
const G0 := Color("2b4434")
const G1 := Color("46663a")
const G2 := Color("789a3e")
const G3 := Color("b3c04a")
const G4 := Color("e2dc7c")
# Street greys (slightly violet).
const R0 := Color("3d4552")
const R1 := Color("586170")
const R2 := Color("7c8590")
const R3 := Color("a6adb0")
# Plum (one facade colour).
const P0 := Color("4e3f5c")

const PALETTE := [T0, T1, T2, T3, T4, T5, T6, T7, W0, W1, W2, W3, W4, W5,
	B0, B1, B2, B3, B4, O1, O2, O3, G0, G1, G2, G3, G4, R0, R1, R2, R3, P0]

# Facade schemes: base, shade (right side, under sills), highlight, trim.
var SCHEMES := {
	"brick": [B2, B1, B3, W4], "darkbrick": [B1, B0, B2, W4], "teal": [T3, T2, T4, W4],
	"tealdark": [T2, T1, T3, W4], "slate": [T1, T0, T2, W4], "cream": [W4, W3, W5, T1],
	"coral": [B3, B2, B4, W5], "mustard": [O2, O1, O3, W5], "plum": [P0, T0, T1, W4],
}
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const FONT := {
	"A": "010101111101101", "B": "110101110101110", "C": "011100100100011", "D": "110101101101110",
	"E": "111100110100111", "F": "111100110100100", "G": "011100101101011", "H": "101101111101101",
	"I": "111010010010111", "K": "101101110101101", "L": "100100100100111", "M": "101111111101101",
	"N": "110101101101101", "O": "010101101101010", "P": "110101110100100", "R": "110101110101101",
	"S": "011100010001110", "T": "111010010010010", "U": "101101101101111", "V": "101101101101010",
	"W": "101101111111101", " ": "000000000000000",
}

var img: Image
var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art"))
	_render_city()
	_save("style_v2_city")
	_render_polder()
	_save("style_v2_polder")
	_save_palette()
	quit()


func _save(name: String) -> void:
	_quantize()
	img.save_png("res://docs/art/%s.png" % name)
	var big := img.duplicate() as Image
	big.resize(W * 3, H * 3, Image.INTERPOLATE_NEAREST)
	big.save_png("res://docs/art/%s_3x.png" % name)
	print("saved ", name)


func _save_palette() -> void:
	var s := Image.create(PALETTE.size() * 24, 24, false, Image.FORMAT_RGBA8)
	for i in PALETTE.size():
		s.fill_rect(Rect2i(i * 24, 0, 24, 24), PALETTE[i])
	s.save_png("res://docs/art/style_v2_palette.png")


# --- City ---------------------------------------------------------------------

func _render_city() -> void:
	img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	rng.seed = 7
	_sky()
	_sun(512, 70, 13)
	_streaks()
	_cloud(120, 62, 1.25)
	_cloud(330, 40, 0.9)
	_cloud(600, 104, 0.8)
	_cloud(440, 118, 0.6)
	_skyline(2, STREET_Y - 58, T6, T7, 26, 60, true)
	_skyline(5, STREET_Y - 40, T5, T6, 30, 70, false)
	_back_row()
	var row := [
		[0, 44, 4, "brick", "step", "door"], [44, 38, 4, "teal", "bell", "awning"],
		[82, 52, 3, "cream", "mansard", "shop"], [134, 36, 5, "slate", "neck", "door"],
		[170, 42, 4, "coral", "spout", "door"], [212, 42, 4, "darkbrick", "step", "awning"],
		[300, 46, 4, "mustard", "neck", "shop"], [346, 38, 5, "tealdark", "bell", "door"],
		[384, 54, 3, "cream", "mansard", "awning"], [438, 36, 4, "brick", "spout", "door"],
		[474, 44, 4, "plum", "step", "door"], [518, 40, 5, "teal", "neck", "shop"],
		[558, 46, 4, "coral", "bell", "door"], [604, 40, 4, "slate", "step", "awning"],
	]
	var signs := ["KOFFIE", "", "ANTIEK", "", "", "BAKKER", "BLOEM", "", "CAFE", "", "", "BOEK", "", "VIS"]
	var awnings := [[B2, W5], [T3, W5], [G1, W4], [B1, W4], [O1, W5]]
	for i in row.size():
		var r: Array = row[i]
		_house(r[0], r[1], r[2], SCHEMES[r[3]], r[4], r[5], signs[i], awnings[i % awnings.size()])
	_side_street(254, 46)
	_street()
	_tree(118, 46, 1.0)
	_tree(277, 48, 1.1)
	_tree(456, 46, 0.95)
	_tree(612, 46, 1.0)
	_lamp(64)
	_lamp(330)
	_lamp(540)
	for x in [24, 31, 190, 404, 411, 580]:
		_bike(x, [B2, T3, W4, O1, G2, T1][x % 6])
	for p in [[150, B2, W3], [370, T1, B3], [430, G1, O2], [566, P0, W4]]:
		_person(p[0], p[1], p[2])
	_quay()
	_reflect(true)
	_car(196, B3)
	_car(486, T3)
	_houseboat(80)
	_houseboat(360)


func _sky() -> void:
	# Hard bands with ordered-dither seams, like the references.
	var stops := [[0, T3], [24, T4], [80, T5], [128, T6], [172, T7], [196, W4], [206, B4]]
	for y in H:
		for x in W:
			var c: Color = stops[0][1]
			for i in stops.size():
				if y >= stops[i][0]:
					c = stops[i][1]
			for i in range(1, stops.size()):
				var b: int = stops[i][0]
				var d := y - b
				if d >= -4 and d < 4:
					var t := (d + 4.5) / 9.0
					c = stops[i][1] if _bayer(x, y) < t else stops[i - 1][1]
			img.set_pixel(x, y, c)


func _streaks() -> void:
	# Long thin horizontal cloud bands low in the sky.
	for s in [[30, 150, 140, W4], [210, 158, 90, T7], [380, 144, 170, W4], [520, 162, 110, T7],
			[90, 180, 120, W5], [300, 186, 160, W4], [470, 178, 80, W5]]:
		_rect(s[0], s[1], s[2], 1, s[3])
		_rect(s[0] + 6, s[1] + 1, s[2] - 18, 1, s[3])


func _sun(cx: int, cy: int, r: int) -> void:
	for y in range(cy - r - 10, cy + r + 11):
		for x in range(cx - r - 10, cx + r + 11):
			var d := Vector2(x - cx, y - cy).length()
			if d <= r:
				_px(x, y, W5 if d < r - 3 or (x - cx) + (y - cy) < 0 else W4)
			elif d <= r + 4 and _bayer(x, y) < 0.5:
				_px(x, y, T7)
			elif d <= r + 10 and _bayer(x, y) < 0.18:
				_px(x, y, T7)


func _cloud(cx: int, base: int, s: float) -> void:
	var puffs := [[0, -11, 13], [-15, -6, 9], [15, -7, 10], [-6, -17, 10], [8, -20, 11],
		[-26, -3, 6], [27, -3, 7], [20, -15, 7]]
	var m := {}
	var shells := []
	for p in puffs:
		var r := int(p[2] * s)
		var pc := Vector2i(cx + int(p[0] * s), base + int(p[1] * s))
		shells.append([pc, r])
		for y in range(pc.y - r, pc.y + r + 1):
			if y > base:
				continue
			var half := int(sqrt(maxf(r * r - (y - pc.y) * (y - pc.y), 0.0)))
			for x in range(pc.x - half, pc.x + half + 1):
				m[Vector2i(x, y)] = true
	for k: Vector2i in m:
		var c := W4
		if not m.has(k + Vector2i(0, -1)) or not m.has(k + Vector2i(-1, -1)) or not m.has(k + Vector2i(0, -2)):
			c = W5
		if k.y >= base - 1:
			c = T6
		elif k.y >= base - 4:
			c = T7 if _bayer(k.x, k.y) < 0.6 else c
		elif not m.has(k + Vector2i(1, 1)) or not m.has(k + Vector2i(2, 0)):
			c = T7
		_px(k.x, k.y, c)
	# Puff seams: the lower-right rim of each upper puff, where it sits on another.
	for sh in shells:
		var pc: Vector2i = sh[0]
		var r: int = sh[1]
		if pc.y > base - int(12 * s):
			continue
		for a in range(10, 100, 4):
			var p := pc + Vector2i(int(cos(deg_to_rad(a)) * r), int(sin(deg_to_rad(a)) * r))
			if m.has(p + Vector2i(1, 1)) and m.has(p + Vector2i(0, 2)) and p.y < base - 4:
				_px(p.x, p.y, T7)


func _skyline(seed: int, base: int, c: Color, hi: Color, min_h: int, max_h: int, far: bool) -> void:
	rng.seed = seed
	var x := -8
	while x < W:
		var w := rng.randi_range(10, 24)
		var h := rng.randi_range(min_h, max_h)
		var kind := rng.randi() % 7
		if kind == 0 and far:                # church tower with a spire
			var tw := 10
			_rect(x, base - h - 10, tw, h + 10, c)
			_rect(x + 2, base - h - 22, tw - 4, 12, c)
			_triangle(x + 1, base - h - 22, tw - 2, 20, c)
			_rect(x + tw / 2, base - h - 46, 1, 6, c)
			_rect(x + 3, base - h - 4, 4, 1, hi)
			w = tw + 2
		elif kind == 1 and far:              # crane
			_rect(x + 4, base - h - 30, 2, h + 30, c)
			_rect(x - 14, base - h - 30, 44, 2, c)
			_rect(x + 24, base - h - 28, 1, 10, c)
			_rect(x - 14, base - h - 28, 6, 4, c)
			w = 8
			_rect(x, base - h, w + 6, h, c)
		else:
			_rect(x, base - h, w, h, c)
			match kind % 3:
				0: _triangle(x, base - h, w, w / 2, c)
				1:
					for st in 3:
						_rect(x + st * 3, base - h - (st + 1) * 3, w - st * 6, 3, c)
				_: pass
			if not far:
				for wy in range(base - h + 6, base - 4, 7):
					for wx in range(x + 3, x + w - 3, 5):
						if rng.randf() < 0.7:
							_rect(wx, wy, 2, 3, hi)
		x += w


func _back_row() -> void:
	rng.seed = 11
	var x := 236
	while x < 300:
		var w := rng.randi_range(18, 26)
		var h := rng.randi_range(70, 96)
		_rect(x, STREET_Y - h, w, h, T4)
		_rect(x + w - 2, STREET_Y - h, 2, h, T3)
		_triangle(x, STREET_Y - h, w, w / 2 + 2, T4)
		for wy in range(STREET_Y - h + 8, STREET_Y - 8, 12):
			for wx in range(x + 3, x + w - 4, 6):
				_rect(wx, wy, 3, 6, T3)
		x += w


func _side_street(x0: int, w: int) -> void:
	# A narrow view between houses: cobbles running into the back row.
	for y in range(STREET_Y - 6, STREET_Y):
		var inset := (STREET_Y - y)
		_rect(x0 + inset, y, w - inset * 2, 1, R2 if y % 2 == 0 else R3)


func _house(x: int, w: int, floors: int, s: Array, gable: String, ground: String, sign: String, awn: Array) -> void:
	var base: Color = s[0]
	var shade: Color = s[1]
	var hi: Color = s[2]
	var trim: Color = s[3]
	var ground_h := 30
	var floor_h := 22
	var top := STREET_Y - ground_h - floor_h * (floors - 1)
	_rect(x, top, w, STREET_Y - top, base)
	if base == B2 or base == B1:               # brick texture: sparse mortar
		for y in range(top + 1, STREET_Y - 3):
			for xx in range(x + 1, x + w - 2):
				if y % 3 == 0 and (xx + (y / 3) % 2 * 3) % 6 == 0:
					_px(xx, y, shade)
	_gable(x, w, top, gable, base, shade, hi, trim)
	# Light from the top-left: 1 px highlight left, 2 px shade right.
	_rect(x, top, 1, STREET_Y - top, hi)
	_rect(x + w - 2, top, 2, STREET_Y - top, shade)
	# Floor cornices.
	for f in range(1, floors):
		var fy := STREET_Y - ground_h - floor_h * (f - 1)
		if f == 1:
			_rect(x, fy - 2, w, 2, trim)
			_rect(x, fy, w, 1, shade)
	# Upper windows.
	var n := maxi(2, (w - 6) / 12)
	var ww := 8
	var gap := (w - n * ww) / (n + 1)
	for f in range(1, floors):
		var fy := STREET_Y - ground_h - floor_h * f + 5
		var wh := 14 if f < floors - 1 else 12
		for i in n:
			var wx := x + gap + i * (ww + gap)
			_window(wx, fy, ww, wh, trim, shade, f == floors - 1 and gable == "bell")
	# Ground floor.
	_rect(x, STREET_Y - 3, w, 3, R2)
	_rect(x, STREET_Y - 3, w, 1, R3)
	match ground:
		"door":
			var dx := x + 4
			_rect(dx - 1, STREET_Y - 26, 10, 23, trim)
			_rect(dx, STREET_Y - 19, 8, 16, [G1, B1, T1, T2][x % 4])
			_rect(dx, STREET_Y - 19, 1, 16, hi if base != T1 else T2)
			_px(dx + 6, STREET_Y - 11, O2)
			for i in 3:                         # fanlight
				_rect(dx + 1 + i * 2, STREET_Y - 25, 1, 5, T0)
			_rect(dx - 2, STREET_Y - 3, 12, 1, R3)
			_rect(dx - 3, STREET_Y - 2, 14, 2, R2)
			var wx := dx + 14
			while wx + 8 < x + w - 2:
				_window(wx, STREET_Y - 24, 8, 17, trim, shade, false)
				wx += 13
		"shop", "awning":
			_rect(x + 2, STREET_Y - 28, w - 4, 7, T0)
			_rect(x + 2, STREET_Y - 28, w - 4, 1, trim)
			if sign != "":
				_text(x + w / 2 - sign.length() * 2, STREET_Y - 26, sign, W5 if trim != W5 else O3)
			_rect(x + 3, STREET_Y - 20, w - 6, 17, T0)
			_rect(x + 2, STREET_Y - 21, 1, 18, trim)
			_rect(x + w - 3, STREET_Y - 21, 1, 18, trim)
			for gx in range(x + 5, x + w - 6, 4):     # shop window: goods + glare
				var gc: Color = [O2, B3, G3, W4, T5][(gx * 7 + x) % 5]
				_rect(gx, STREET_Y - 8, 3, 4, gc)
				_px(gx + 1, STREET_Y - 9, gc)
			for i in 6:
				_px(x + 6 + i, STREET_Y - 18 + i, T2)
				_px(x + 7 + i, STREET_Y - 18 + i, T2)
			_rect(x + w / 2, STREET_Y - 20, 1, 17, trim)
			if ground == "awning":
				for ax in range(x + 1, x + w - 1):
					var col: Color = awn[0] if ((ax - x) / 4) % 2 == 0 else awn[1]
					_rect(ax, STREET_Y - 21, 1, 6, col)
					if (ax - x) % 4 < 2:
						_px(ax, STREET_Y - 15, col)
				_rect(x + 1, STREET_Y - 21, w - 2, 1, awn[0])
				_rect(x + 3, STREET_Y - 14, w - 6, 1, T0)


func _gable(x: int, w: int, top: int, kind: String, base: Color, shade: Color, hi: Color, trim: Color) -> void:
	var cx := x + w / 2
	match kind:
		"step":
			var steps := 4
			var sw := w / (steps * 2 + 1)
			for i in steps:
				var y := top - (i + 1) * 6
				var l := x + i * sw + sw / 2
				var r := x + w - i * sw - sw / 2
				_rect(l, y, r - l, 6, base)
				_rect(l - 1, y, r - l + 2, 1, trim)
				_rect(r - 2, y + 1, 2, 5, shade)
			_rect(cx - 2, top - steps * 6 - 4, 4, 4, trim)
			_window(cx - 3, top - 18, 6, 9, trim, shade, true)
			_rect(cx - 1, top - steps * 6 + 1, 2, 3, W0)           # hoist beam
		"spout":
			var gh := w / 2 + 4
			_triangle(x, top, w, gh, base)
			for y in gh:
				var half := int(w / 2.0 * (1.0 - float(y) / gh))
				_px(cx - half, top - y - 1, trim)
				_px(cx + half - 1, top - y - 1, shade)
				_px(cx + half - 2, top - y - 1, shade)
			_window(cx - 3, top - gh / 2 - 2, 6, 8, trim, shade, false)
			_rect(cx - 1, top - gh + 2, 2, 3, W0)
		"neck":
			var nw := int(w * 0.45)
			var gh := 26
			_rect(cx - nw / 2, top - gh, nw, gh, base)
			_rect(cx + nw / 2 - 2, top - gh, 2, gh, shade)
			for side in [-1, 1]:                # scrolls (claw pieces) on the shoulders
				var sx: int = cx + side * (nw / 2) + (0 if side > 0 else -1)
				var r := (w - nw) / 2 - 1
				for yy in r:
					var len := int(sqrt(maxf(r * r - (r - yy) * (r - yy), 0.0)))
					var lx: int = sx if side > 0 else sx - len
					_rect(lx, top - r + yy, len + 1, 1, base)
					_px(sx + side * len, top - r + yy, trim)
			_triangle(cx - nw / 2 - 2, top - gh, nw + 4, 7, trim)
			_triangle(cx - nw / 2, top - gh - 1, nw, 5, base)
			_window(cx - 3, top - gh + 5, 6, 12, trim, shade, true)
		"bell":
			var gh := 26
			for y in gh:
				var t := float(y) / gh
				var half := int(w / 2.0 * (0.92 - 0.55 * t + 0.25 * sin(t * PI)) * (1.0 - t * t * 0.6))
				_rect(cx - half, top - y - 1, half * 2, 1, base)
				_px(cx - half - 1, top - y - 1, trim)
				_px(cx + half, top - y - 1, trim)
				_rect(cx + half - 2, top - y - 1, 2, 1, shade)
			_rect(cx - 4, top - gh - 2, 8, 2, trim)
			_window(cx - 3, top - 18, 6, 10, trim, shade, true)
		"mansard":
			_rect(x - 1, top - 3, w + 2, 3, trim)
			_rect(x, top, w, 1, shade)
			var rh := 16
			for y in rh:
				var inset := y / 2
				_rect(x + 1 + inset, top - 4 - y, w - 2 - inset * 2, 1, R1 if y % 3 else R2)
			for dx in range(x + 8, x + w - 10, 14):  # dormers
				_rect(dx, top - 15, 8, 10, trim)
				_rect(dx + 1, top - 13, 6, 7, T0)
				_px(dx + 2, top - 12, T3)
				_triangle(dx - 1, top - 15, 10, 4, R0)


func _window(x: int, y: int, w: int, h: int, frame: Color, shade: Color, arched: bool) -> void:
	_rect(x, y, w, h, frame)
	var kind := rng.randi() % 10
	var glass := T0
	if kind < 2:
		glass = T2
	_rect(x + 1, y + 1, w - 2, h - 2, glass)
	if kind == 9:                                   # warm light / curtains
		_rect(x + 1, y + 1, w - 2, h - 2, O3)
		_rect(x + 1, y + h / 2, w - 2, h / 2 - 1, O2)
	else:
		for i in mini(w, h) - 2:                    # glare streak
			if x + 2 + i < x + w - 1:
				_px(x + 2 + i, y + h - 3 - i, T5 if glass == T2 else T2)
		_px(x + 1, y + 1, T3)
		if kind == 8:
			_rect(x + 1, y + 1, 1, h - 2, W3)
			_rect(x + w - 2, y + 1, 1, h - 2, W3)
	_rect(x, y + h * 2 / 5, w, 1, frame)            # sash bar
	if w >= 8:
		_rect(x + w / 2, y + 1, 1, h - 2, frame)
	if arched:
		for i in w / 2:
			_rect(x + i, y - 2 + (1 if i == 0 else 0), w - i * 2, 1, frame)
	else:
		_rect(x - 1, y - 1, w + 2, 1, frame)
	_rect(x - 1, y + h, w + 2, 1, frame)            # sill + its shadow
	_rect(x, y + h + 1, w, 1, shade)
	_rect(x + w, y, 1, h, shade)


func _street() -> void:
	for y in range(STREET_Y, STREET_Y + 14):
		for x in W:
			var row := (y - STREET_Y) / 3
			var c := R1
			if (y - STREET_Y) % 3 == 0:
				c = R0
			elif (x + row * 3) % 6 == 0:
				c = R0
			elif (y - STREET_Y) % 3 == 1 and (x + row * 3) % 6 == 1:
				c = R2
			_px(x, y, c)
	_rect(0, STREET_Y, W, 1, R2)
	_rect(0, STREET_Y + 12, W, 1, R3)
	_rect(0, STREET_Y + 13, W, 1, R2)


func _quay() -> void:
	var y0 := STREET_Y + 14
	_rect(0, y0, W, WATER_Y - y0, R1)
	for x in range(0, W, 12):
		_rect(x, y0, 1, WATER_Y - y0, R0)
	_rect(0, y0 + 4, W, 1, R0)
	_rect(0, y0, W, 1, R2)
	for x in range(6, W, 12):
		_px(x + 2, y0 + 1, R2)
	# Iron railing along the canal and Amsterdammertjes (bollards).
	for x in range(0, W, 3):
		_rect(x, STREET_Y + 7, 1, 5, T0)
	_rect(0, STREET_Y + 6, W, 1, T0)
	_rect(0, STREET_Y + 5, W, 1, T1)
	for x in range(8, W, 48):
		_rect(x, STREET_Y + 2, 3, 10, B0)
		_px(x, STREET_Y + 3, B1)
		_rect(x, STREET_Y + 5, 3, 1, B1)


func _reflect(city: bool) -> void:
	# Mirror of the street side, mapped onto a few water colours by brightness
	# (greens stay olive, warm colours stay brick) so the canal reads calm.
	rng.seed = 3
	var cool := [T0, T1, T2, T3, T4]
	var green := [T0, T1, G0, G1, G1]
	var warm := [T0, T1, T1, B0, B1]
	var src := img.duplicate() as Image
	for y in range(WATER_Y, H):
		var depth := float(y - WATER_Y) / float(H - WATER_Y)
		var band := (y - WATER_Y) / 3
		var dx := int(round(sin(band * 1.7) * (1.0 + depth * 3.0)))
		var src_y := WATER_Y - 1 - ((y - WATER_Y) / 2 * 2) * 9 / 10
		for x in W:
			var c := T1
			if src_y >= 0:
				var s := src.get_pixel(clampi((x + dx) / 2 * 2, 0, W - 1), src_y)
				var lum := s.r * 0.3 + s.g * 0.59 + s.b * 0.11
				var idx := clampi(int(lum * 5.0 - depth * 0.9 - 0.5), 0, 4)
				var ramp: Array = cool
				if s.g > s.r + 0.06 and s.g > s.b + 0.06:
					ramp = green
				elif s.r > s.b + 0.18 and s.r > s.g + 0.12:
					ramp = warm
				c = ramp[idx]
			if y == WATER_Y:
				c = T0
			elif y < WATER_Y + 3:
				c = T1
			img.set_pixel(x, y, c)
	# Ripple lines: short light dashes, longer and denser further away.
	for i in 340:
		var y := rng.randi_range(WATER_Y + 3, H - 1)
		var x := rng.randi_range(0, W - 1)
		var depth := float(y - WATER_Y) / float(H - WATER_Y)
		var len := rng.randi_range(2, 5 + int(depth * 12))
		_rect(x, y, len, 1, T3 if rng.randf() < 0.55 else T4)
		if rng.randf() < 0.25:
			_rect(x + 1, y, maxi(len - 2, 1), 1, T6)
	if city:
		# Sun glitter column.
		for y in range(WATER_Y + 4, H, 2):
			var half := 4 + (y - WATER_Y) / 7
			var x0 := 512 - half + rng.randi_range(-3, 3)
			_rect(x0, y, rng.randi_range(half / 2, half * 2), 1, W4 if (y / 2) % 3 == 0 else T6)


func _tree(x: int, h: int, s: float) -> void:
	var base := STREET_Y + 1
	_rect(x - 1, base - h, 4, h, W0)
	_rect(x - 1, base - h, 1, h, W1)
	_rect(x + 1, base - h + 10, 4, 1, W0)
	_rect(x + 4, base - h + 6, 1, 4, W0)
	_rect(x - 5, base - h + 8, 4, 1, W0)
	var clumps := [[0, -h - 8, 15], [-14, -h + 2, 11], [14, -h + 1, 12], [-7, -h - 20, 10],
		[9, -h - 19, 11], [-20, -h - 9, 8], [21, -h - 10, 8], [1, -h - 28, 8], [-2, -h + 6, 10]]
	var light := Vector3(-0.55, -0.65, 0.52).normalized()
	var m := {}
	for c in clumps:
		var r := int(c[2] * s)
		var cc := Vector2i(x + int(c[0] * s), base + int(c[1] * s))
		for yy in range(-r - 1, r + 2):
			for xx in range(-r - 1, r + 2):
				var p := cc + Vector2i(xx, yy)
				# Leafy edge: the radius wobbles in 2 px clusters.
				var n := _hash(p.x / 2, p.y / 2)
				var rr := r + (n - 0.5) * 3.0
				var d2 := float(xx * xx + yy * yy)
				if d2 > rr * rr:
					continue
				var nx := xx / maxf(rr, 1.0)
				var ny := yy / maxf(rr, 1.0)
				var nz := sqrt(maxf(1.0 - nx * nx - ny * ny, 0.0))
				var l := Vector3(nx, ny, nz).dot(light) + (_hash(p.x / 2 + 31, p.y / 2 + 7) - 0.5) * 0.35
				var col := G1
				if l > 0.2:
					col = G2
				if l > 0.62:
					col = G3
				if l > 0.9:
					col = G4
				if l < -0.25:
					col = G0
				m[p] = col
	for p: Vector2i in m:
		var col: Color = m[p]
		if not m.has(p + Vector2i(0, 1)):
			col = G0
		_px(p.x, p.y, col)


func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 1000) / 1000.0


func _lamp(x: int) -> void:
	_rect(x, STREET_Y - 42, 2, 42, T0)
	_rect(x - 1, STREET_Y - 4, 4, 4, T0)
	_rect(x - 2, STREET_Y - 50, 6, 1, T0)
	_rect(x - 2, STREET_Y - 49, 6, 6, W5)
	_rect(x - 2, STREET_Y - 49, 1, 6, T0)
	_rect(x + 3, STREET_Y - 49, 1, 6, T0)
	_rect(x - 1, STREET_Y - 43, 4, 1, T0)
	_triangle(x - 3, STREET_Y - 50, 8, 3, T0)


func _bike(x: int, frame: Color) -> void:
	var y := STREET_Y - 4
	for c in [x, x + 11]:
		for a in range(0, 360, 30):
			_px(c + int(round(cos(deg_to_rad(a)) * 4)), y + int(round(sin(deg_to_rad(a)) * 4)), T0)
		_px(c, y, R3)
	_line(x, y, x + 5, y - 6, frame)
	_line(x + 5, y - 6, x + 11, y, frame)
	_line(x + 4, y, x + 5, y - 6, frame)
	_line(x + 5, y - 6, x + 9, y - 6, frame)
	_rect(x + 3, y - 8, 4, 1, T0)
	_rect(x + 9, y - 9, 1, 3, T0)
	_rect(x + 8, y - 9, 3, 1, T0)


func _car(x: int, body: Color) -> void:
	# A boxy 80s hatchback, 46x18.
	var y := STREET_Y + 9
	var dark := B1 if body == B3 else T2
	var hi := B4 if body == B3 else T5
	_rect(x + 2, y - 12, 44, 9, body)
	_rect(x + 10, y - 20, 26, 8, body)
	_rect(x + 9, y - 19, 1, 7, body)
	_rect(x + 36, y - 19, 3, 7, body)
	_rect(x + 11, y - 19, 11, 6, T0)
	_rect(x + 24, y - 19, 11, 6, T0)
	for i in 4:
		_px(x + 13 + i, y - 18 + i, T5)
		_px(x + 26 + i, y - 18 + i, T5)
	_rect(x + 10, y - 20, 26, 1, hi)
	_rect(x + 2, y - 12, 44, 1, hi)
	_rect(x + 2, y - 7, 44, 1, dark)
	_rect(x + 2, y - 6, 44, 3, dark)
	_rect(x + 23, y - 12, 1, 8, dark)
	_rect(x, y - 5, 4, 2, R3)
	_rect(x + 44, y - 5, 4, 2, R3)
	_rect(x + 44, y - 11, 2, 2, O3)
	_rect(x + 2, y - 11, 2, 2, B1)
	_rect(x + 2, y - 2, 44, 2, T0)
	for wx in [x + 10, x + 37]:
		WorldDisc.draw(self, wx, y - 2, 4, T0)
		WorldDisc.draw(self, wx, y - 2, 2, R2)
		_px(wx - 1, y - 3, R3)


func _person(x: int, coat: Color, skin_hair: Color) -> void:
	var y := STREET_Y + 2
	_rect(x, y - 4, 2, 4, T0)
	_rect(x + 3, y - 4, 2, 4, T0)
	_rect(x - 1, y - 13, 7, 9, coat)
	_rect(x - 1, y - 13, 1, 9, coat.lightened(0.15))
	_rect(x + 1, y - 18, 4, 5, B4)
	_rect(x + 1, y - 19, 4, 2, skin_hair)


func _houseboat(x: int) -> void:
	var y := WATER_Y + 3
	_rect(x, y, 70, 8, G1)
	_rect(x, y, 70, 1, G2)
	_rect(x + 2, y + 6, 66, 2, T0)
	_rect(x + 8, y - 10, 50, 10, W4)
	_rect(x + 8, y - 10, 50, 1, W5)
	_rect(x + 56, y - 10, 2, 10, W3)
	_rect(x + 6, y - 12, 54, 2, B1)
	for wx in range(x + 12, x + 54, 9):
		_rect(wx, y - 7, 5, 4, T0)
		_px(wx + 1, y - 6, T3)
	for px_ in range(x + 10, x + 56, 6):
		_rect(px_, y - 15, 3, 3, B2 if px_ % 12 == 0 else G2)
		_px(px_ + 1, y - 16, G3)
	_rect(x + 2, y + 8, 66, 2, T0)
	_rect(x + 6, y + 10, 58, 1, T1)


# --- Polder -------------------------------------------------------------------

func _render_polder() -> void:
	img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	rng.seed = 21
	_sky()
	_sun(150, 64, 13)
	_streaks()
	_cloud(300, 70, 1.4)
	_cloud(520, 50, 1.0)
	_cloud(70, 110, 0.75)
	var horizon := 170
	# Far tree line and farms in haze: low and flat (it's Holland).
	for x in range(0, W):
		var h := 1 + int(_hash(x / 4, 1) * 2.0)
		if _hash(x / 18, 2) > 0.55:
			h += 2 + int(_hash(x / 3, 3) * 3.0)
		_rect(x, horizon - h, 1, h, T5)
	for fx in [36, 228, 352, 548]:
		_rect(fx, horizon - 7, 12, 7, T5)
		_triangle(fx - 2, horizon - 7, 16, 5, T5)
	_rect(0, horizon - 1, W, 1, T4)
	for t in [[60, 46], [180, 52], [255, 40], [400, 58], [470, 44], [590, 50]]:
		_turbine(t[0], horizon, t[1])
	# Striped fields with ditches, growing toward the viewer.
	var y := horizon
	var band := 2
	var cols := [G3, G2, G4, G2, G3, G1]
	var i := 0
	while y < STREET_Y:
		_rect(0, y, W, band, cols[i % cols.size()])
		if i % 2 == 1:
			_rect(0, y, W, 1, T4)
		y += band
		band += 1
		i += 1
	_farm(110)
	_tree(70, 34, 0.75)
	_tree(205, 30, 0.7)
	_windmill(470)
	for c in [[300, STREET_Y - 10, false], [326, STREET_Y - 9, true], [560, STREET_Y - 12, false]]:
		_cow(c[0], c[1], c[2])
	for x in range(0, W, 16):                        # fence along the dike
		_rect(x, STREET_Y - 7, 1, 7, W1)
	_rect(0, STREET_Y - 6, W, 1, W2)
	# Dike road + grass slope.
	_rect(0, STREET_Y, W, 10, R1)
	_rect(0, STREET_Y, W, 1, R2)
	for x in range(0, W, 24):
		_rect(x, STREET_Y + 5, 10, 1, W4)
	_rect(0, STREET_Y + 10, W, WATER_Y - STREET_Y - 10, G2)
	for x in range(0, W, 2):
		_px(x, STREET_Y + 10 + (x * 7) % 5, G3)
	_rect(0, WATER_Y - 2, W, 2, G1)
	_car(260, B3)
	_reflect(false)
	for x in [20, 130, 250, 380, 530, 600]:
		_reeds(x)


func _turbine(x: int, base: int, h: int) -> void:
	_rect(x, base - h, 2, h, T7)
	_rect(x + 2, base - h, 1, h, T6)
	_rect(x - 1, base - h - 2, 4, 3, T7)
	var hub := Vector2(x + 1, base - h - 1)
	for a in [-90.0, 30.0, 150.0]:
		var ang := deg_to_rad(a + x)
		var tip := hub + Vector2(cos(ang), sin(ang)) * h * 0.45
		_line(int(hub.x), int(hub.y), int(tip.x), int(tip.y), T7)


func _farm(x: int) -> void:
	var b := STREET_Y - 14
	_rect(x, b - 18, 60, 18, B2)
	_rect(x + 58, b - 18, 2, 18, B1)
	for yy in 18:                                    # big hipped roof
		var inset := yy * 2 / 3
		_rect(x - 4 + (18 - yy) * 2 / 3, b - 18 - yy, 68 - (18 - yy) * 4 / 3, 1, T1 if yy % 3 else T2)
	_rect(x - 4, b - 19, 68, 1, T0)
	_rect(x + 8, b - 12, 8, 12, W4)
	_rect(x + 10, b - 10, 4, 10, G1)
	_window(x + 24, b - 13, 7, 8, W4, B1, false)
	_window(x + 38, b - 13, 7, 8, W4, B1, false)
	_rect(x - 18, b - 22, 16, 22, W5)                # white front house
	_rect(x - 4, b - 22, 2, 22, W3)
	_triangle(x - 20, b - 22, 20, 12, T1)
	_window(x - 15, b - 15, 4, 7, G1, W3, false)
	_window(x - 9, b - 15, 4, 7, G1, W3, false)


func _windmill(x: int) -> void:
	var b := STREET_Y - 4
	for yy in 74:                                    # tapering smock body
		var half := 12 - yy * 6 / 74
		_rect(x - half, b - yy, half * 2, 1, R1 if yy % 4 else R0)
		_px(x - half, b - yy, R2)
		_rect(x + half - 2, b - yy, 2, 1, R0)
	_rect(x - 14, b - 30, 28, 2, W0)                 # stage
	for sx in range(x - 14, x + 14, 3):
		_rect(sx, b - 28, 1, 4, W0)
	_rect(x - 3, b - 12, 6, 12, W1)
	_rect(x - 2, b - 10, 4, 10, T0)
	var cap := Vector2i(x, b - 78)
	_rect(x - 8, b - 80, 16, 6, W1)
	_rect(x - 7, b - 84, 14, 4, W0)
	for a in [35.0, 125.0, 215.0, 305.0]:
		var d := Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a)))
		var n := Vector2(-d.y, d.x)
		for k in range(4, 46):
			var p := Vector2(cap) + d * k
			_px(int(p.x), int(p.y), W0)
			if k > 10:
				var e := p + n * 6
				_px(int(e.x), int(e.y), W4)
				if k % 4 == 0:
					for j in range(1, 6):
						var q := p + n * j
						_px(int(q.x), int(q.y), W3)
	_rect(x - 2, b - 80, 4, 4, T0)


func _cow(x: int, y: int, dark: bool) -> void:
	_rect(x, y, 14, 6, W5)
	_rect(x + 3, y + 1, 4, 3, T0)
	_rect(x + 9, y, 3, 2, T0)
	if dark:
		_rect(x, y, 14, 6, W1)
		_rect(x, y, 14, 1, W2)
	_rect(x + 13, y - 2, 4, 4, W5 if not dark else W1)
	_px(x + 16, y + 1, B4)
	for lx in [x + 1, x + 4, x + 9, x + 12]:
		_rect(lx, y + 6, 1, 3, T0)


func _reeds(x: int) -> void:
	# A foreground clump: blades leaning out, a few cattails.
	for i in 9:
		var rx := x + i * 3 + int(_hash(x, i) * 3.0)
		var h := 22 + int(_hash(i, x) * 22.0)
		var lean := (i - 4) * 0.18
		for k in h:
			var px_ := rx + int(lean * k * k / float(h))
			_rect(px_, H - 1 - k, 2 if k < h * 2 / 3 else 1, 1, G1 if i % 2 else (G2 if k > 6 else G0))
		if i % 3 == 1:
			var tx := rx + int(lean * h)
			_rect(tx, H - h - 7, 2, 7, W0)
			_px(tx, H - h - 7, W1)
			_rect(tx, H - h - 10, 1, 3, G1)


# --- Helpers ----------------------------------------------------------------

func _quantize() -> void:
	for y in H:
		for x in W:
			img.set_pixel(x, y, _nearest(img.get_pixel(x, y)))


func _nearest(c: Color) -> Color:
	var best: Color = PALETTE[0]
	var bd := INF
	for p: Color in PALETTE:
		var dr := (c.r - p.r) * 0.30
		var dg := (c.g - p.g) * 0.59
		var db := (c.b - p.b) * 0.11
		var d := dr * dr + dg * dg + db * db
		if d < bd:
			bd = d
			best = p
	return best


func _bayer(x: int, y: int) -> float:
	return (BAYER[(y & 3) * 4 + (x & 3)] + 0.5) / 16.0


func _text(x: int, y: int, s: String, c: Color) -> void:
	for i in s.length():
		var g: String = FONT.get(s[i], FONT[" "])
		for k in 15:
			if g[k] == "1":
				_px(x + i * 4 + k % 3, y + k / 3, c)


func _px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < W and y < H:
		img.set_pixel(x, y, c)


func _rect(x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, W, H))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, c)


func _triangle(x: int, base: int, w: int, h: int, c: Color) -> void:
	for y in h:
		var half := int(w / 2.0 * (1.0 - float(y) / h))
		_rect(x + w / 2 - half, base - y - 1, half * 2, 1, c)


func _line(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var n := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in n + 1:
		var t := float(i) / maxf(n, 1)
		_px(int(round(lerpf(x0, x1, t))), int(round(lerpf(y0, y1, t))), c)


class WorldDisc:
	static func draw(m: Object, cx: int, cy: int, r: int, c: Color) -> void:
		for y in range(-r, r + 1):
			var half := int(sqrt(maxf(r * r - y * y, 0.0)))
			m._rect(cx - half, cy + y, half * 2 + 1, 1, c)
