extends SceneTree
## Style v3 mock (2026-10-25): the v2 palette (32 colours) at the game's real
## scale and a much higher detail level, after the user's reference images.
## Drawn in ART px (= half a world px, the band sprites' density, see
## docs/city-layout.md): band 54, door 34x68, window 22x36, ground floor 88,
## storey 76. Exports the camera frames the map really shows:
##   zoom 3 (on foot, standing) = 427x240 art px, zoom 2 (bike) = 640x360,
## each scaled up to 1280x720, plus the whole street as an overview.
## Run: Summer --headless --path . --script res://tools/style_mock_v3.gd

const W := 1400
const H := 720
const GY := 560                             # street level = the band's feet
const WATER := 604                          # top of the canal (GROUND_Y + 22 world px)
const GF := 88                              # ground floor height
const ST := 76                              # upper storey height

# --- Palette v2 (32 colours, docs/art/style_v2_palette.png) -----------------
const T0 := Color("1d2838")
const T1 := Color("2c4152")
const T2 := Color("35606c")
const T3 := Color("4b8189")
const T4 := Color("64a2a6")
const T5 := Color("86c1bb")
const T6 := Color("b0dcc9")
const T7 := Color("dcefd2")
const W0 := Color("4a3434")
const W1 := Color("7a5a4a")
const W2 := Color("b08e6c")
const W3 := Color("d8bf94")
const W4 := Color("f3e4bc")
const W5 := Color("fff7df")
const B0 := Color("5e2e36")
const B1 := Color("8f3f40")
const B2 := Color("bd5a4b")
const B3 := Color("e07d5e")
const B4 := Color("f2a77a")
const O1 := Color("e08a36")
const O2 := Color("f2bc58")
const O3 := Color("f8dc8a")
const G0 := Color("2b4434")
const G1 := Color("46663a")
const G2 := Color("789a3e")
const G3 := Color("b3c04a")
const G4 := Color("e2dc7c")
const R0 := Color("3d4552")
const R1 := Color("586170")
const R2 := Color("7c8590")
const R3 := Color("a6adb0")
const P0 := Color("4e3f5c")
const PALETTE := [T0, T1, T2, T3, T4, T5, T6, T7, W0, W1, W2, W3, W4, W5,
	B0, B1, B2, B3, B4, O1, O2, O3, G0, G1, G2, G3, G4, R0, R1, R2, R3, P0]

# Facade schemes: base, shade, highlight, trim, trim shade, dark, brick?
var SCHEMES := {
	"brick": [B2, B1, B3, W4, W3, B0, true], "darkbrick": [B1, B0, B2, W4, W3, T0, true],
	"teal": [T3, T2, T4, W4, W3, T1, false], "tealdark": [T2, T1, T3, W4, W3, T0, false],
	"slate": [T1, T0, T2, W4, W3, T0, false], "cream": [W4, W3, W5, T1, T0, W2, false],
	"coral": [B3, B2, B4, W5, W3, B1, false], "mustard": [O2, O1, O3, W5, W3, W1, false],
	"plum": [P0, T0, R1, W4, W3, T0, false],
}
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
const FONT5 := {
	"A": "01110100011000111111100011000110001", "B": "11110100011000111110100011000111110",
	"C": "01110100011000010000100001000101110", "D": "11110100011000110001100011000111110",
	"E": "11111100001000011110100001000011111", "F": "11111100001000011110100001000010000",
	"G": "01110100011000010111100011000101111", "H": "10001100011000111111100011000110001",
	"I": "01110001000010000100001000010001110", "K": "10001100101010011000101001001010001",
	"L": "10000100001000010000100001000011111", "M": "10001110111010110101100011000110001",
	"N": "10001110011010110011100011000110001", "O": "01110100011000110001100011000101110",
	"P": "11110100011000111110100001000010000", "R": "11110100011000111110101001001010001",
	"S": "01111100001000001110000010000111110", "T": "11111001000010000100001000010000100",
	"U": "10001100011000110001100011000101110", "V": "10001100011000110001100010101000100",
	"W": "10001100011000110101101011010101010", "Z": "11111000010001000100010001000011111",
	" ": "00000000000000000000000000000000000",
}
const FONT3 := {
	"0": "111101101101111", "1": "010110010010111", "2": "111001111100111", "3": "111001111001111",
	"4": "101101111001001", "5": "111100111001111", "6": "111100111101111", "7": "111001010010010",
	"8": "111101111101111", "9": "111101111001111", "A": "010101111101101", "C": "011100100100011",
	"E": "111100110100111", "G": "011100101101011", "H": "101101111101101", "N": "110101101101101",
	"R": "110101110101101", "T": "111010010010010", "O": "010101101101010", "P": "110101110100100",
	" ": "000000000000000",
}

var img: Image
var rng := RandomNumberGenerator.new()
# Current facade scheme.
var cb: Color
var cs: Color
var ch: Color
var ct: Color
var cts: Color
var cd: Color
var is_brick := false


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art"))
	img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	rng.seed = 5
	_render()
	_quantize()
	_band()
	img.save_png("res://docs/art/style_v3_overview.png")
	_frame("style_v3_zoom3_a", 96, GY - 152, 427, 240, 3)
	_frame("style_v3_zoom3_b", 700, GY - 152, 427, 240, 3)
	_frame("style_v3_zoom2", 40, GY - 256, 640, 360, 2)
	quit()


func _frame(name: String, x: int, y: int, w: int, h: int, s: int) -> void:
	var f := img.get_region(Rect2i(x, y, w, h))
	f.resize(w * s, h * s, Image.INTERPOLATE_NEAREST)
	f.save_png("res://docs/art/%s.png" % name)
	print("saved ", name)


# --- Scene ------------------------------------------------------------------

func _render() -> void:
	_sky()
	_sun(1180, 110, 26)
	_streaks()
	_cloud(220, 120, 2.4)
	_cloud(700, 80, 1.8)
	_cloud(1000, 200, 1.3)
	_skyline_far()
	_skyline_mid()
	_back_row()
	var row := [
		{"x": 0, "w": 132, "f": 4, "s": "brick", "g": "step", "gr": "door", "boxes": true, "pipe": true, "no": "263"},
		{"x": 132, "w": 120, "f": 4, "s": "teal", "g": "bell", "gr": "shop", "shop": "cafe", "sign": "CAFE DE KAT", "awn": [B2, W5], "fascia": T1},
		{"x": 252, "w": 144, "f": 3, "s": "cream", "g": "mansard", "gr": "shop", "shop": "boek", "sign": "BOEKEN", "fascia": G0, "quoins": true},
		{"x": 396, "w": 112, "f": 4, "s": "slate", "g": "neck", "gr": "door", "shutters": [G1, W5], "plaque": true, "cat": true, "no": "271"},
		{"x": 508, "w": 124, "f": 4, "s": "coral", "g": "spout", "gr": "shop", "shop": "bakker", "sign": "BAKKER", "awn": [T2, W5], "fascia": T1, "pipe": true},
		{"x": 704, "w": 128, "f": 4, "s": "mustard", "g": "neck", "gr": "shop", "shop": "bloem", "sign": "BLOEMEN", "fascia": G1},
		{"x": 832, "w": 112, "f": 5, "s": "tealdark", "g": "bell", "gr": "door", "lace": true, "street": "HERENGRACHT", "no": "289"},
		{"x": 944, "w": 136, "f": 4, "s": "darkbrick", "g": "step", "gr": "shop", "shop": "koffie", "sign": "KOFFIE", "awn": [G1, W4], "fascia": B0},
		{"x": 1080, "w": 120, "f": 4, "s": "cream", "g": "spout", "gr": "door", "shutters": [B1, W5], "boxes": true, "no": "297"},
		{"x": 1200, "w": 112, "f": 3, "s": "plum", "g": "step", "gr": "door", "plaque": true, "pipe": true, "no": "301"},
		{"x": 1312, "w": 120, "f": 4, "s": "brick", "g": "neck", "gr": "shop", "shop": "vis", "sign": "VIS", "awn": [T3, W5], "fascia": T1},
	]
	_alley(632, 72)
	for hs: Dictionary in row:
		_house(hs)
	_street()
	_quay()
	_reflect()
	_houseboat(140)
	_houseboat(900)
	_tree(668, 1.0)
	_tree(1196, 0.9)
	_lamp(246)
	_lamp(1076)
	_terrace(142)
	_aboard(236, "KOFFIE")
	_buckets(712)
	_book_stand(270)
	_bin(500)
	_bin(1302)
	_bike(18, T0, true)
	_bike(600, B1, false)
	_bike(1140, T2, true)
	_rack(1236)
	_bike(1232, G1, false)
	for bx in [70, 386, 646, 790, 940, 1020, 1366]:
		_bollard(bx)
	_car(300, B3)
	_car(1170, T3)


func _sky() -> void:
	var stops := [[0, T3], [56, T4], [170, T5], [292, T6], [392, T7], [452, W4], [500, B4]]
	for y in GY:
		for x in W:
			var c: Color = stops[0][1]
			for i in stops.size():
				if y >= stops[i][0]:
					c = stops[i][1]
			for i in range(1, stops.size()):
				var d: int = y - int(stops[i][0])
				if d >= -6 and d < 6:
					c = stops[i][1] if _bayer(x, y) < (d + 6.5) / 13.0 else stops[i - 1][1]
			img.set_pixel(x, y, c)


func _streaks() -> void:
	for s in [[40, 300, 260, W4], [420, 316, 180, T7], [760, 288, 320, W4], [1040, 324, 220, T7],
			[180, 360, 240, W5], [600, 372, 300, W4], [940, 356, 160, W5], [1200, 380, 200, W4]]:
		_rect(s[0], s[1], s[2], 2, s[3])
		_rect(s[0] + 12, s[1] + 2, s[2] - 30, 1, s[3])
		_rect(s[0] - 6, s[1] + 1, 6, 1, s[3])


func _sun(cx: int, cy: int, r: int) -> void:
	for y in range(cy - r - 20, cy + r + 21):
		for x in range(cx - r - 20, cx + r + 21):
			var v := Vector2(x - cx, y - cy)
			var d := v.length()
			if d <= r:
				var c := W5
				if d > r - 4 and v.x + v.y > 0:
					c = W4
				if (y - cy) > r / 3 and (y - cy) % 5 == 0:   # banded lower half
					c = W4
				_px(x, y, c)
			elif d <= r + 8 and _bayer(x, y) < 0.5:
				_px(x, y, T7)
			elif d <= r + 20 and _bayer(x, y) < 0.15:
				_px(x, y, T7)


func _cloud(cx: int, base: int, s: float) -> void:
	var puffs := [[0, -11, 13], [-15, -6, 9], [15, -7, 10], [-6, -17, 10], [8, -20, 11],
		[-26, -3, 6], [27, -3, 7], [20, -15, 7], [-20, -12, 6]]
	var m := {}
	for p in puffs:
		var r := int(p[2] * s)
		var pc := Vector2i(cx + int(p[0] * s), base + int(p[1] * s))
		for y in range(pc.y - r, pc.y + r + 1):
			if y > base:
				continue
			for x in range(pc.x - r, pc.x + r + 1):
				var n := _hash(x / 3, y / 3)
				var rr := r + (n - 0.5) * 3.0
				if Vector2(x - pc.x, y - pc.y).length() <= rr:
					m[Vector2i(x, y)] = Vector2(x - pc.x, y - pc.y) / maxf(rr, 1.0)
	var light := Vector3(-0.5, -0.7, 0.5).normalized()
	for k: Vector2i in m:
		var nv: Vector2 = m[k]
		var nz := sqrt(maxf(1.0 - nv.length_squared(), 0.0))
		var l := Vector3(nv.x, nv.y, nz).dot(light)
		var c := W4
		if l > 0.55:
			c = W5
		if l < 0.0:
			c = T7
		if l < -0.35:
			c = T6
		if k.y >= base - 2:
			c = T6
		elif k.y >= base - 8 and _bayer(k.x, k.y) < 0.5:
			c = T6
		_px(k.x, k.y, c)


func _skyline_far() -> void:
	rng.seed = 2
	var base := GY - 120
	var x := -10
	while x < W:
		var w := rng.randi_range(22, 44)
		var h := rng.randi_range(40, 110)
		_rect(x, base - h, w, h + 120, T6)
		match rng.randi() % 3:
			0: _triangle(x, base - h, w, w / 2, T6)
			1:
				for st in 4:
					_rect(x + st * 3, base - h - (st + 1) * 4, w - st * 6, 4, T6)
			_: _rect(x + w / 2, base - h - 12, 6, 12, T6)
		for wy in range(base - h + 8, base, 10):
			for wx in range(x + 4, x + w - 4, 7):
				if _hash(wx, wy) < 0.4:
					_rect(wx, wy, 2, 4, T7)
		x += w
	_tower(330, base, T6, T7)
	_tower(1030, base + 10, T6, T7)
	# A crane on the skyline.
	_rect(820, base - 190, 4, 190, T6)
	_rect(760, base - 190, 120, 3, T6)
	for i in range(764, 876, 6):
		_line(i, base - 188, i + 3, base - 185, T6)
	_rect(860, base - 186, 1, 30, T6)
	_rect(764, base - 186, 12, 8, T6)


func _tower(x: int, base: int, c: Color, hi: Color) -> void:
	# Westertoren-like church tower: stacked stages, clock, open crown, spire.
	_rect(x, base - 160, 28, 160, c)
	_rect(x + 3, base - 196, 22, 36, c)
	_rect(x + 6, base - 226, 16, 30, c)
	_rect(x + 9, base - 246, 10, 20, c)
	_triangle(x + 8, base - 246, 12, 30, c)
	_rect(x + 13, base - 290, 2, 16, c)
	WDisc.ring(self, x + 14, base - 180, 6, hi)
	for i in 3:
		_rect(x + 8 + i * 5, base - 218, 2, 12, hi)
		_rect(x + 6 + i * 8, base - 150, 3, 14, hi)
	_rect(x, base - 160, 28, 2, hi)
	_rect(x + 3, base - 196, 22, 2, hi)


func _skyline_mid() -> void:
	rng.seed = 9
	var base := GY - 40
	var x := -6
	while x < W:
		var w := rng.randi_range(30, 56)
		var h := rng.randi_range(110, 200)
		_rect(x, base - h, w, h + 40, T5)
		_rect(x + w - 3, base - h, 3, h + 40, T4)
		var kind := rng.randi() % 3
		if kind == 0:
			_triangle(x, base - h, w, w / 2, T5)
		elif kind == 1:
			for st in 4:
				_rect(x + st * 4, base - h - (st + 1) * 6, w - st * 8, 6, T5)
		if rng.randf() < 0.5:                    # chimney
			_rect(x + 6, base - h - 18, 6, 18, T4)
			_rect(x + 5, base - h - 20, 8, 2, T4)
		for wy in range(base - h + 10, base, 18):
			for wx in range(x + 5, x + w - 8, 11):
				_rect(wx, wy, 6, 11, T4)
				_rect(wx, wy, 6, 1, T6)
				if _hash(wx, wy) < 0.12:
					_rect(wx + 1, wy + 1, 4, 9, O3)
		x += w


func _back_row() -> void:
	rng.seed = 13
	var x := -4
	while x < W:
		var w := rng.randi_range(56, 84)
		var h := rng.randi_range(230, 300)
		var top := GY - h
		_rect(x, top, w, h, T4)
		_rect(x + w - 4, top, 4, h, T3)
		_rect(x, top, 1, h, T5)
		var cx := x + w / 2
		match rng.randi() % 3:
			0:
				_triangle(x, top, w, w / 2, T4)
				_rect(cx - 1, top - w / 2 - 6, 2, 6, T3)
			1:
				for st in 4:
					_rect(x + st * 7, top - (st + 1) * 9, w - st * 14, 9, T4)
					_rect(x + st * 7, top - (st + 1) * 9, w - st * 14, 1, T5)
			_:
				_rect(x - 2, top - 4, w + 4, 4, T5)
		for wy in range(top + 18, GY - 30, 38):
			for i in 3:
				var wx := x + 8 + i * (w - 16) / 3
				_rect(wx, wy, 11, 18, T5)
				_rect(wx + 2, wy + 2, 7, 14, T2)
				_rect(wx + 2, wy + 9, 7, 1, T5)
				_px(wx + 3, wy + 3, T3)
		x += w


func _alley(x: int, w: int) -> void:
	# A narrow street between the houses: cobbles running off, side walls.
	for y in range(GY - 40, GY):
		var t := float(GY - y) / 40.0
		var inset := int(t * w * 0.38)
		for xx in range(x + inset, x + w - inset):
			var c := R1 if (xx + y / 3) % 6 else R0
			if y % 3 == 0:
				c = R0
			_px(xx, y, c)
	_rect(x, GY - 300, 10, 260, T3)
	_rect(x + w - 10, GY - 300, 10, 260, T2)
	for i in 5:
		_rect(x + 2, GY - 280 + i * 50, 5, 18, T2)
		_rect(x + w - 7, GY - 280 + i * 50, 5, 18, T1)
	# Lamp hanging on a wire across the alley.
	_line(x, GY - 210, x + w, GY - 214, T1)
	_rect(x + w / 2 - 3, GY - 212, 6, 8, T0)
	_rect(x + w / 2 - 2, GY - 206, 4, 4, W4)


# --- Houses -----------------------------------------------------------------

func _house(hs: Dictionary) -> void:
	var s: Array = SCHEMES[hs["s"]]
	cb = s[0]
	cs = s[1]
	ch = s[2]
	ct = s[3]
	cts = s[4]
	cd = s[5]
	is_brick = s[6]
	var x: int = hs["x"]
	var w: int = hs["w"]
	var floors: int = hs["f"]
	var top := GY - GF - ST * (floors - 1)
	rng.seed = x * 7 + 1
	_wall(x, top, w, GY - top)
	_gable(x, w, top, hs["g"])
	# Corner quoins.
	if hs.get("quoins", false):
		var qy := top
		var long := true
		while qy < GY - 8:
			for side in [0, 1]:
				var qw := 12 if long else 7
				var qx: int = x + 1 if side == 0 else x + w - qw - 1
				_bevel(qx, qy, qw, 9, W3, W5, W2)
			qy += 10
			long = not long
	# Light from the top-left: highlight left, shade right, dark outline.
	_rect(x + 1, top, 2, GY - top, ch)
	_rect(x + w - 4, top, 3, GY - top, cs)
	_rect(x, top, 1, GY - top, T0)
	_rect(x + w - 1, top, 1, GY - top, T0)
	# String course over the ground floor.
	var sc := GY - GF
	_rect(x, sc - 7, w, 1, cts)
	_rect(x, sc - 6, w, 1, W5 if ct != T1 else T2)
	_rect(x, sc - 5, w, 3, ct)
	for dx in range(x + 2, x + w - 2, 4):
		_rect(dx, sc - 3, 2, 2, cts)
	_rect(x, sc - 2, w, 1, cts)
	_rect(x, sc - 1, w, 1, T0)
	_rect(x, sc, w, 2, cs)
	# Upper storeys: 3 bays.
	var bay := w / 3
	for f in range(1, floors):
		var fy := GY - GF - ST * f
		var small: bool = f == floors - 1 and hs["g"] != "mansard"
		var wh := 30 if small else 36
		var wy := fy + (ST - wh) / 2 + 2
		for i in 3:
			var wx := x + i * bay + (bay - 22) / 2
			if hs.has("shutters"):
				_shutters(wx, wy, wh, hs["shutters"])
			_window(wx, wy, 22, wh, hs.get("lace", false), i == 1 and f == floors - 1)
			if hs.get("boxes", false) and f == 1:
				_flower_box(wx - 3, wy + wh + 3)
		_anchor(x + 8, fy + ST - 14)
		_anchor(x + w - 12, fy + ST - 14)
	if hs.get("pipe", false):
		_pipe(x + w - 9, top + 6)
	if hs.has("street"):
		_street_sign(x + w / 2 - 25, GY - GF - 22, hs["street"])
	# Ground floor.
	_plinth(x, w)
	if hs["gr"] == "door":
		_door_front(x, w, hs)
	else:
		_shop_front(x, w, hs)


func _wall(x: int, y: int, w: int, h: int) -> void:
	for yy in range(maxi(y, 0), mini(y + h, H)):
		for xx in range(maxi(x, 0), mini(x + w, W)):
			var c := cb
			var course := yy / 4
			var r := yy % 4
			var off := (course % 2) * 4
			var j := (xx + off) % 8
			if is_brick:
				if r == 3 or j == 0:
					c = cs
				else:
					var id := _hash((xx + off) / 8, course)
					if id < 0.09:
						c = ch
					elif id > 0.9:
						c = cs if r != 0 else cb
					if r == 0 and j == 1 and id < 0.45:
						c = ch
			else:
				if r == 3 and _bayer(xx, yy) < 0.3:
					c = cs
				elif j == 0 and _bayer(xx, yy) < 0.15:
					c = cs
			var grime := yy - (y + h - 22)
			if grime > 0 and _bayer(xx, yy) < grime / 22.0 * 0.5:
				c = cs
			img.set_pixel(xx, yy, c)


func _gable(x: int, w: int, top: int, kind: String) -> void:
	var cx := x + w / 2
	match kind:
		"step":
			var steps := 5
			var sw := w / (steps * 2 + 1)
			var sh := 13
			for i in steps:
				var y := top - (i + 1) * sh
				var l := x + i * sw + sw / 2
				var r := x + w - i * sw - sw / 2
				_wall(l, y, r - l, sh)
				_rect(l, y, 2, sh, ch)
				_rect(r - 4, y, 4, sh, cs)
				_rect(l - 1, y, 1, sh, T0)
				_rect(r, y, 1, sh, T0)
				# Stone coping on each step.
				_rect(l - 3, y - 1, r - l + 6, 1, T0)
				_rect(l - 3, y, r - l + 6, 1, W5)
				_rect(l - 3, y + 1, r - l + 6, 2, W3)
				_rect(l - 3, y + 3, r - l + 6, 1, cts if ct != T1 else W2)
				_rect(l - 3, y + 4, r - l + 6, 1, cs)
			var ty := top - steps * sh
			_bevel(cx - 5, ty - 8, 10, 8, W3, W5, W2)
			WDisc.draw(self, cx, ty - 13, 4, W3)
			_px(cx - 1, ty - 15, W5)
			_px(cx - 2, ty - 14, W5)
			_loading_door(cx - 9, top - 40, 18, 26)
			_hoist(cx, ty + 4)
		"spout":
			var gh := w / 2 + 10
			for yy in gh:
				var half := int(w / 2.0 * (1.0 - float(yy) / gh))
				_wall(cx - half, top - yy - 1, half * 2, 1)
				_rect(cx - half - 1, top - yy - 1, 3, 1, ct)
				_px(cx - half - 2, top - yy - 1, T0)
				_rect(cx + half - 5, top - yy - 1, 3, 1, cs)
				_rect(cx + half - 2, top - yy - 1, 3, 1, ct)
				_px(cx + half + 1, top - yy - 1, T0)
			_loading_door(cx - 9, top - gh / 2 - 6, 18, 26)
			_hoist(cx, top - gh + 10)
			_chimney(x + w - 24, top - gh / 2 - 10)
		"neck":
			var nw := int(w * 0.46)
			var gh := 62
			var nl := cx - nw / 2
			_wall(nl, top - gh, nw, gh)
			_rect(nl, top - gh, 2, gh, ch)
			_rect(nl + nw - 4, top - gh, 4, gh, cs)
			_rect(nl - 1, top - gh, 1, gh, T0)
			_rect(nl + nw, top - gh, 1, gh, T0)
			# Scroll pieces on the shoulders.
			for side in [-1, 1]:
				var r: int = (w - nw) / 2 - 2
				var ox: int = nl - 1 if side < 0 else nl + nw
				for yy in r:
					var len := int(sqrt(maxf(r * r - (r - yy) * (r - yy), 0.0)))
					var lx: int = ox - len if side < 0 else ox
					_rect(lx, top - r + yy, len + 1, 1, cb)
					var edge: int = lx if side < 0 else lx + len
					_rect(edge - (0 if side < 0 else 2), top - r + yy, 3, 1, ct)
					_px(edge + (-1 if side < 0 else 1), top - r + yy, T0)
				_rect(ox - (r if side < 0 else 0), top - 3, r + 1, 3, ct)
				_rect(ox - (r if side < 0 else 0), top - 1, r + 1, 1, cts)
				var vx: int = ox + side * (r / 2)
				WDisc.draw(self, vx, top - r / 2, 4, ct)
				WDisc.ring(self, vx, top - r / 2, 4, cts)
				_px(vx, top - r / 2, T0)
			# Pediment with an oculus and a vase.
			for yy in 14:
				var half := int((nw / 2 + 4) * (1.0 - yy / 14.0))
				_rect(cx - half, top - gh - yy - 1, half * 2, 1, ct if yy < 2 or half < 4 else cb)
				_px(cx - half, top - gh - yy - 1, ct)
				_px(cx + half - 1, top - gh - yy - 1, ct)
			_rect(cx - nw / 2 - 4, top - gh - 1, nw + 8, 2, ct)
			_rect(cx - nw / 2 - 4, top - gh + 1, nw + 8, 1, cts)
			_vase(cx, top - gh - 15)
			_window(cx - 10, top - gh + 12, 20, 32, false, true)
			_oculus(cx, top - gh - 6)
		"bell":
			var gh := 64
			for yy in gh:
				var t := float(yy) / gh
				var half := int(w / 2.0 * (0.92 - 0.5 * t + 0.25 * sin(t * PI)) * (1.0 - t * t * 0.55))
				_wall(cx - half, top - yy - 1, half * 2, 1)
				_rect(cx - half - 3, top - yy - 1, 3, 1, ct)
				_px(cx - half - 3, top - yy - 1, W5 if ct != T1 else T2)
				_px(cx - half - 4, top - yy - 1, T0)
				_rect(cx + half - 4, top - yy - 1, 4, 1, cs)
				_rect(cx + half, top - yy - 1, 3, 1, cts)
				_px(cx + half + 3, top - yy - 1, T0)
			_rect(cx - 10, top - gh - 4, 20, 4, ct)
			_rect(cx - 10, top - gh - 4, 20, 1, W5)
			_rect(cx - 10, top - gh, 20, 1, cts)
			WDisc.draw(self, cx, top - gh - 6, 4, ct)
			_window(cx - 11, top - 46, 22, 34, false, true)
		"mansard":
			_rect(x - 3, top - 10, w + 6, 10, ct)
			_rect(x - 3, top - 10, w + 6, 1, T0)
			_rect(x - 3, top - 9, w + 6, 1, W5 if ct != T1 else T2)
			for dx in range(x, x + w, 6):
				_rect(dx, top - 5, 3, 3, cts)
			_rect(x - 3, top - 2, w + 6, 1, cts)
			_rect(x, top, w, 2, cs)
			var rh := 40
			for yy in rh:
				var inset := yy / 3
				var row := yy / 5
				for xx in range(x + inset, x + w - inset):
					var j := (xx + (row % 2) * 4) % 8
					var c := R1
					if yy % 5 == 4 or j == 0:
						c = R0
					elif yy % 5 == 0 and j == 1:
						c = R2
					elif yy % 5 == 0:
						c = R2 if _hash(xx / 8, row) < 0.4 else R1
					_px(xx, top - 11 - yy, c)
			_rect(x + 13, top - 51, w - 26, 1, T0)
			for dx in range(x + 18, x + w - 30, 42):
				_dormer(dx, top - 44)
			_chimney(x + w - 30, top - 66)


func _window(x: int, y: int, w: int, h: int, lace: bool, arched: bool) -> void:
	# Reveal shadow (top + left inside the opening).
	_rect(x - 2, y - 2, w + 4, h + 3, cs)
	_rect(x - 1, y - 1, w + 2, h + 2, T0)
	# Frame.
	_rect(x, y, w, h, ct)
	_rect(x + w - 1, y, 1, h, cts)
	_rect(x, y + h - 1, w, 1, cts)
	var mid := y + h / 2 - 1
	var kind := int(_hash(x, y) * 10.0)
	if lace:
		kind = 2
	for pane in [[x + 2, y + 2, w / 2 - 3, mid - y - 2], [x + w / 2 + 1, y + 2, w / 2 - 3, mid - y - 2],
			[x + 2, mid + 2, w / 2 - 3, y + h - mid - 4], [x + w / 2 + 1, mid + 2, w / 2 - 3, y + h - mid - 4]]:
		_glass(pane[0], pane[1], pane[2], pane[3], kind)
	# Glare streak over the whole window.
	if kind < 6:
		for i in h:
			var gx := x + 2 + (h - i) * w / (h + 6)
			for k in 2:
				var px_ := gx + k
				if px_ > x + 1 and px_ < x + w - 2 and _is_glass(px_, y + i):
					_px(px_, y + i, T2 if k == 0 else T3)
	# Muntins in the upper sash.
	_rect(x + 2, y + 2 + (mid - y - 2) / 2, w - 4, 1, ct)
	# Meeting rail and centre bar.
	_rect(x, mid, w, 2, ct)
	_rect(x, mid + 1, w, 1, cts)
	_rect(x + w / 2 - 1, y, 2, h, ct)
	_rect(x + w / 2, y + 1, 1, h - 1, cts)
	if kind == 2 or lace:
		_lace(x + 2, mid + 2, w - 4, y + h - mid - 4)
	if kind == 5 and _hash(y, x) < 0.25:
		_window_cat(x + 4, mid + 2 + (y + h - mid - 4))
	# Head: arched brick arch or a stone lintel with keystone.
	if arched:
		var r := w / 2 + 3
		for a in range(180, 361, 6):
			var p := Vector2(x + w / 2, y + 2) + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * r
			_rect(int(p.x) - 1, int(p.y) - 1, 3, 3, ct if (a / 6) % 2 == 0 else cts)
		_px(x + w / 2, y - r + 1, W5)
	else:
		_rect(x - 4, y - 6, w + 8, 1, W5 if ct != T1 else W3)
		_rect(x - 4, y - 5, w + 8, 3, W3 if ct != T1 else W2)
		_rect(x - 4, y - 2, w + 8, 1, cts if ct != T1 else W1)
		_bevel(x + w / 2 - 3, y - 8, 6, 8, W4, W5, W3)
	# Sill + shadow + drip stain.
	_rect(x - 3, y + h, w + 6, 1, W5 if ct != T1 else W3)
	_rect(x - 3, y + h + 1, w + 6, 2, W3 if ct != T1 else W2)
	_rect(x - 2, y + h + 3, w + 4, 1, T0)
	_rect(x - 1, y + h + 4, w + 2, 1, cs)
	if _hash(x, y + 1) < 0.5:
		for i in 7:
			if _bayer(x + 4, y + h + 5 + i) < 0.6 - i * 0.08:
				_rect(x + 4 + int(_hash(x, 3) * (w - 8)), y + h + 5 + i, 2, 1, cs)


func _glass(x: int, y: int, w: int, h: int, kind: int) -> void:
	if kind == 3 or kind == 5:                      # lit room
		_rect(x, y, w, h, O2)
		_rect(x, y, w, 2, O3)
		_rect(x, y + h - 2, w, 2, O1)
		return
	_rect(x, y, w, h, T0)
	_rect(x, y, w, 2, T1)
	_px(x, y, T3)
	if kind == 1:                                   # curtains
		var cc: Color = [B2, G2, O2, W4][int(_hash(x / 30, y / 40) * 4.0) % 4]
		var csh: Color = {B2: B1, G2: G1, O2: O1, W4: W3}[cc]
		for i in 3:
			_rect(x + i if x % 2 == 0 else x + w - 1 - i, y, 1, h, cc if i % 2 == 0 else csh)
	elif kind == 4:                                 # plant
		_rect(x + 1, y + h - 4, w - 2, 4, B2)
		_rect(x + 1, y + h - 4, w - 2, 1, B3)
		for i in 8:
			var lx := x + int(_hash(x + i, y) * w)
			var ly := y + h - 5 - int(_hash(y, x + i) * (h - 4))
			_rect(lx, ly, 2, 2, G2 if i % 2 else G3)


func _is_glass(x: int, y: int) -> bool:
	var c := img.get_pixel(x, y)
	return c == T0 or c == T1


func _lace(x: int, y: int, w: int, h: int) -> void:
	for yy in range(y + 2, y + h):
		for xx in range(x, x + w):
			if (xx + yy) % 2 == 0 or yy == y + 2:
				_px(xx, yy, W4)
			elif yy % 3 == 0:
				_px(xx, yy, W3)
	for xx in range(x, x + w, 3):
		_px(xx + 1, y + 1, W4)


func _window_cat(x: int, base: int) -> void:
	_rect(x, base - 7, 7, 7, T0)
	_rect(x + 1, base - 11, 5, 4, T0)
	_px(x + 1, base - 12, T0)
	_px(x + 5, base - 12, T0)
	_px(x + 2, base - 9, O3)
	_px(x + 4, base - 9, O3)
	_rect(x + 7, base - 4, 3, 1, T0)


func _shutters(x: int, y: int, h: int, cols: Array) -> void:
	for sx in [x - 13, x + 23]:
		_rect(sx, y - 1, 12, h + 2, T0)
		for yy in range(y, y + h):
			for xx in range(sx + 1, sx + 11):
				var stripe: bool = ((xx - sx) + (yy - y)) / 4 % 2 == 0
				if sx > x:
					stripe = ((sx + 11 - xx) + (yy - y)) / 4 % 2 == 0
				_px(xx, yy, cols[0] if stripe else cols[1])
		_rect(sx + 1, y, 10, 1, W5)
		_rect(sx + 1, y + h / 2, 10, 1, T0)
		_px(sx + (11 if sx > x else 0), y + 4, R3)
		_px(sx + (11 if sx > x else 0), y + h - 5, R3)


func _flower_box(x: int, y: int) -> void:
	_rect(x, y, 28, 6, W1)
	_rect(x, y, 28, 1, W2)
	_rect(x, y + 5, 28, 1, W0)
	_rect(x, y + 3, 28, 1, W0)
	for i in 18:
		var fx := x + 1 + int(_hash(x + i, y) * 26.0)
		var fy := y - 1 - int(_hash(y, x + i * 3) * 7.0)
		_rect(fx, fy, 2, 2, G1 if i % 3 else G2)
	for i in 9:
		var fx := x + 2 + int(_hash(x - i, y + 9) * 23.0)
		var fy := y - 3 - int(_hash(y + i, x) * 6.0)
		var fc: Color = [B3, O2, W5, B2, O3][i % 5]
		_rect(fx, fy, 2, 2, fc)
		_px(fx, fy, W5 if fc != W5 else O3)


func _anchor(x: int, y: int) -> void:
	# Iron wall anchor (muuranker): an S-shaped bar.
	_rect(x + 1, y, 2, 9, T0)
	_rect(x, y, 2, 1, T0)
	_rect(x + 2, y + 8, 2, 1, T0)
	_px(x + 1, y + 1, R1)


func _pipe(x: int, top: int) -> void:
	_rect(x - 3, top, 10, 6, R1)
	_rect(x - 3, top, 10, 1, R2)
	_rect(x - 3, top + 5, 10, 1, R0)
	_rect(x, top + 6, 4, GY - top - 10, R1)
	_rect(x, top + 6, 1, GY - top - 10, R2)
	_rect(x + 3, top + 6, 1, GY - top - 10, R0)
	for yy in range(top + 20, GY - 8, 28):
		_rect(x - 1, yy, 6, 2, R0)
	_rect(x, GY - 6, 7, 3, R1)
	_rect(x, GY - 6, 7, 1, R2)


func _chimney(x: int, y: int) -> void:
	for yy in range(y, y + 28):
		for xx in range(x, x + 14):
			var c := B1 if ((xx + (yy / 3 % 2) * 3) % 6 != 0 and yy % 3 != 2) else B0
			_px(xx, yy, c)
	_rect(x, y, 1, 28, B2)
	_rect(x - 2, y - 4, 18, 4, R1)
	_rect(x - 2, y - 4, 18, 1, R2)
	_rect(x + 3, y - 9, 4, 5, W1)
	_rect(x + 8, y - 8, 4, 4, W1)
	_px(x + 3, y - 9, W2)


func _dormer(x: int, y: int) -> void:
	_rect(x, y, 22, 30, R0)
	_rect(x + 2, y + 2, 18, 26, ct)
	_rect(x + 4, y + 4, 14, 22, T0)
	_rect(x + 4, y + 4, 14, 2, T1)
	_rect(x + 10, y + 4, 2, 22, ct)
	_rect(x + 4, y + 14, 14, 1, ct)
	_px(x + 5, y + 5, T3)
	for yy in 8:
		var half := 14 - yy * 14 / 8
		_rect(x + 11 - half, y - yy - 1, half * 2, 1, ct if yy == 0 else R1)
		_px(x + 11 - half, y - yy - 1, T0)


func _loading_door(x: int, y: int, w: int, h: int) -> void:
	_rect(x - 1, y - 1, w + 2, h + 2, T0)
	for xx in range(x, x + w):
		_rect(xx, y, 1, h, W1 if (xx - x) % 3 else W0)
	_rect(x, y, w, 1, W2)
	_rect(x + w / 2, y, 1, h, T0)
	for hy in [y + 4, y + h - 6]:
		_rect(x + 1, hy, 6, 1, T0)
		_rect(x + w - 7, hy, 6, 1, T0)


func _hoist(x: int, y: int) -> void:
	_rect(x - 3, y, 6, 5, W0)
	_rect(x - 3, y, 6, 1, W1)
	_rect(x - 1, y + 5, 2, 3, T0)
	_rect(x - 2, y + 8, 4, 1, T0)
	_px(x - 2, y + 9, T0)


func _vase(x: int, y: int) -> void:
	_rect(x - 3, y + 6, 6, 3, W3)
	_rect(x - 4, y + 1, 8, 5, W3)
	_rect(x - 4, y + 1, 2, 5, W5)
	_rect(x - 2, y - 2, 4, 3, W3)
	_px(x, y - 3, W3)


func _oculus(x: int, y: int) -> void:
	WDisc.draw(self, x, y, 5, ct)
	WDisc.draw(self, x, y, 3, T0)
	_px(x - 1, y - 1, T3)


func _plinth(x: int, w: int) -> void:
	for bx in range(x, x + w, 14):
		_bevel(bx, GY - 7, mini(14, x + w - bx), 7, R2, R3, R1)
	_rect(x, GY - 8, w, 1, T0)


func _street_sign(x: int, y: int, text: String) -> void:
	var w := text.length() * 4 + 5
	_rect(x - 1, y - 1, w + 2, 11, T0)
	_rect(x, y, w, 9, T2)
	_rect(x + 1, y + 1, w - 2, 7, W5)
	_rect(x + 2, y + 2, w - 4, 5, T2)
	_text3(x + 3, y + 2, text, W5)


func _door_front(x: int, w: int, hs: Dictionary) -> void:
	var dx := x + 12
	var dy := GY - 14 - 68                         # the door sits up a stoop
	# Door case: pilasters + entablature + fanlight.
	_rect(dx - 7, dy - 22, 48, 3, T0)
	_rect(dx - 7, dy - 21, 48, 1, W5 if ct != T1 else T2)
	_rect(dx - 6, dy - 20, 46, 4, ct)
	_rect(dx - 6, dy - 16, 46, 1, cts)
	for px_ in [dx - 6, dx + 34]:
		_rect(px_, dy - 16, 6, 84, ct)
		_rect(px_, dy - 16, 1, 84, W5 if ct != T1 else T2)
		_rect(px_ + 5, dy - 16, 1, 84, cts)
		_rect(px_ - 1, dy - 16, 1, 84, T0)
		_rect(px_ + 6, dy - 16, 1, 84, T0)
	# Fanlight with radial bars.
	_rect(dx, dy - 15, 34, 14, T0)
	_rect(dx, dy - 15, 34, 2, T1)
	for a in range(200, 341, 28):
		var e := Vector2(dx + 17, dy - 2) + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 20.0
		_line(dx + 17, dy - 2, int(e.x), int(e.y), ct)
	_rect(dx, dy - 2, 34, 2, ct)
	# Panel door.
	var dc: Color = [G1, T1, B1, T2, W0][int(_hash(x, 9) * 5.0)]
	var dsh: Color = {G1: G0, T1: T0, B1: B0, T2: T1, W0: T0}[dc]
	var dhi: Color = {G1: G2, T1: T2, B1: B2, T2: T3, W0: W1}[dc]
	_rect(dx, dy, 34, 68, dc)
	_rect(dx, dy, 1, 68, dhi)
	_rect(dx + 33, dy, 1, 68, dsh)
	for row in 3:
		for col in 2:
			var px_ := dx + 4 + col * 14
			var py := dy + 4 + row * 21
			_rect(px_, py, 12, 18, dsh)
			_rect(px_ + 1, py + 1, 11, 17, dhi)
			_rect(px_ + 2, py + 2, 9, 15, dc)
			_rect(px_ + 2, py + 16, 9, 1, dsh)
	_rect(dx + 11, dy + 40, 12, 3, O2)            # letterbox
	_rect(dx + 11, dy + 40, 12, 1, O3)
	_rect(dx + 28, dy + 34, 3, 3, O2)             # knob
	_px(dx + 28, dy + 34, O3)
	# House number plate.
	if hs.has("no"):
		_rect(dx + 36 + 4, dy + 6, 15, 10, T0)
		_rect(dx + 36 + 5, dy + 7, 13, 8, T2)
		_text3(dx + 36 + 6, dy + 8, hs["no"], W5)
	# Stoop: three steps with an iron railing.
	for i in 3:
		var sy := GY - 14 + i * 4 + 2
		var sx := dx - 4 - i * 3
		_rect(sx, sy, 42 + i * 6, 4, R2)
		_rect(sx, sy, 42 + i * 6, 1, R3)
		_rect(sx, sy + 3, 42 + i * 6, 1, R1)
	_rect(dx - 4, GY - 14, 42, 2, R3)
	for rx in [dx - 10, dx + 44]:
		_rect(rx, GY - 30, 2, 30, T0)
		WDisc.ring(self, rx + (3 if rx > dx else -2), GY - 31, 3, T0)
		for k in range(4, 26, 5):
			_rect(rx + (2 if rx < dx else -4), GY - 26 + k / 2, 4, 1, T0)
	# Wall lantern.
	_lantern(dx + 46, dy + 18)
	if hs.get("plaque", false):
		_plaque(dx + 9, dy - 40)
	if hs.get("cat", false):
		_cat(dx + 40, GY - 12)
	# The other bays: tall ground-floor windows over basement grilles.
	var bay := w / 3
	for i in range(1, 3):
		var wx := x + i * bay + (bay - 22) / 2
		_window(wx, GY - GF + 14, 22, 42, false, false)
		_rect(wx - 2, GY - 24, 26, 14, T0)
		for bx in range(wx, wx + 22, 4):
			_rect(bx, GY - 23, 1, 12, R1)
		_rect(wx - 1, GY - 23, 24, 1, R1)
	# A potted bay tree by the door.
	_topiary(x + w - 18 if w > 120 else dx - 16, GY)


func _shop_front(x: int, w: int, hs: Dictionary) -> void:
	var fc: Color = hs.get("fascia", T1)
	var fsh: Color = {T1: T0, G0: T0, G1: G0, B0: T0}.get(fc, T0)
	var fhi: Color = {T1: T2, G0: G1, G1: G2, B0: B1}.get(fc, T2)
	var top := GY - GF + 4
	# Wooden shop front: pilasters, fascia board, stall riser.
	_rect(x + 2, top, w - 4, GF - 4, fc)
	_rect(x + 2, top, w - 4, 1, fhi)
	# Fascia with lettering and drop shadow.
	_rect(x + 6, top + 4, w - 12, 18, T0)
	_rect(x + 7, top + 5, w - 14, 16, fc)
	_rect(x + 7, top + 5, w - 14, 1, fhi)
	_rect(x + 7, top + 20, w - 14, 1, fsh)
	var sign: String = hs.get("sign", "")
	var tw := sign.length() * 6 - 1
	_text5(x + w / 2 - tw / 2 + 1, top + 10, sign, fsh)
	_text5(x + w / 2 - tw / 2, top + 9, sign, O2)
	_text5_top(x + w / 2 - tw / 2, top + 9, sign, O3)
	# Display window + glass door.
	var wy := top + 28
	var wh := GY - 12 - wy
	var door_w := 22
	var door_x := x + w - 10 - door_w
	var win_w := door_x - 6 - (x + 8)
	_rect(x + 7, wy - 1, win_w + 2, wh + 2, T0)
	_shop_window(x + 8, wy, win_w, wh, hs.get("shop", ""))
	_rect(door_x - 1, wy - 1, door_w + 2, GY - wy, T0)
	_rect(door_x, wy, door_w, GY - wy - 2, fc)
	_rect(door_x, wy, 1, GY - wy - 2, fhi)
	_rect(door_x + 3, wy + 3, door_w - 6, 34, T0)
	_rect(door_x + 3, wy + 3, door_w - 6, 2, T1)
	_rect(door_x + 3, wy + 37, door_w - 6, 1, fhi)
	for i in 10:
		_px(door_x + 5 + i, wy + 30 - i * 2, T2)
		_px(door_x + 6 + i, wy + 30 - i * 2, T2)
	_rect(door_x + door_w - 6, wy + 24, 2, 8, O2)
	_rect(door_x + 4, wy + 42, door_w - 8, 8, fsh)
	_rect(door_x + 5, wy + 43, door_w - 10, 6, fc)
	_rect(door_x + 6, wy + 10, 10, 5, W5)            # OPEN card
	_text3(door_x + 7, wy + 10, "OP", B1)
	# Stall riser under the window with panels.
	for px_ in range(x + 10, x + 8 + win_w - 14, 18):
		_rect(px_, GY - 11, 14, 6, fsh)
		_rect(px_ + 1, GY - 10, 13, 5, fhi)
		_rect(px_ + 2, GY - 9, 11, 3, fc)
	# Awning.
	if hs.has("awn"):
		_awning(x + 4, top + 22, w - 8, hs["awn"])
	_blade_sign(x + w - 4, top - 30, hs.get("shop", ""), fc)
	_lantern(x + 5, top + 30)


func _shop_window(x: int, y: int, w: int, h: int, shop: String) -> void:
	var lit := shop == "cafe" or shop == "koffie"
	_rect(x, y, w, h, O1 if lit else T1)
	_rect(x, y, w, 3, O2 if lit else T0)
	var shelf1 := y + h / 3
	var shelf2 := y + h * 2 / 3
	match shop:
		"cafe", "koffie":
			_rect(x, y + 3, w, h - 3, O1)
			_rect(x, y + h - 14, w, 14, W1)              # bar
			_rect(x, y + h - 14, w, 2, W2)
			for lx in range(x + 8, x + w - 4, 18):       # hanging lamps
				_rect(lx + 2, y, 1, 8, T0)
				_triangle(lx - 2, y + 13, 9, 5, W1)
				_rect(lx, y + 13, 5, 2, O3)
			for bx in range(x + 3, x + w - 3, 4):        # bottles
				_rect(bx, shelf1 - 6, 2, 6, [G1, B1, T2, W1, O2][bx % 5])
				_px(bx, shelf1 - 7, [G1, B1, T2, W1, O2][bx % 5])
			_rect(x, shelf1, w, 1, W0)
			for i in 3:                                  # silhouettes of guests
				var gx := x + 10 + i * (w - 20) / 3
				_rect(gx, y + h - 26, 7, 12, T1)
				_rect(gx + 1, y + h - 32, 5, 6, T1)
		"bakker":
			for sy in [shelf1, shelf2, y + h - 4]:
				_rect(x, sy, w, 2, W1)
				for lx in range(x + 2, x + w - 8, 9):
					var bread := (lx / 9) % 3
					if bread == 0:
						_rect(lx, sy - 5, 7, 5, W2)
						_rect(lx + 1, sy - 6, 5, 1, W2)
						_rect(lx + 1, sy - 5, 5, 1, W3)
						_px(lx + 2, sy - 4, W1)
						_px(lx + 4, sy - 4, W1)
					elif bread == 1:
						_rect(lx, sy - 4, 8, 4, W5)
						_rect(lx, sy - 4, 8, 1, B3)
						_px(lx + 3, sy - 5, B1)
					else:
						_rect(lx, sy - 3, 8, 3, O1)
						_rect(lx + 1, sy - 4, 6, 1, O2)
		"boek":
			for sy in [shelf1, shelf2, y + h - 3]:
				_rect(x, sy, w, 2, W1)
				var bx := x + 1
				while bx < x + w - 3:
					var bw := 2 + int(_hash(bx, sy) * 2.0)
					var bh := 9 + int(_hash(sy, bx) * 6.0)
					var bc: Color = [B1, B2, T2, T3, G1, O1, W3, P0, B0][int(_hash(bx, sy + 1) * 9.0)]
					_rect(bx, sy - bh, bw, bh, bc)
					_px(bx, sy - bh + 2, W4 if bc != W3 else W1)
					bx += bw
		"bloem":
			_rect(x, y + 3, w, h - 3, G0)
			for i in 60:
				var lx := x + int(_hash(i, 7) * w)
				var ly := y + 6 + int(_hash(7, i) * (h - 8))
				_rect(lx, ly, 3, 3, [G1, G2, G3, G1][i % 4])
			for i in 18:
				var lx := x + int(_hash(i, 17) * (w - 2))
				var ly := y + 6 + int(_hash(17, i) * (h - 10))
				_rect(lx, ly, 2, 2, [B3, O2, W5, B2][i % 4])
		"vis":
			_rect(x, y + h - 16, w, 16, T6)
			for i in w * 2:
				_px(x + int(_hash(i, 3) * w), y + h - 15 + int(_hash(3, i) * 15), W5)
			for fx in range(x + 3, x + w - 16, 15):
				_rect(fx, y + h - 13, 12, 4, R3)
				_rect(fx, y + h - 13, 12, 1, W5)
				_triangle(fx + 11, y + h - 9, 5, 4, R2)
				_px(fx + 2, y + h - 12, T0)
				_rect(fx + 3, y + h - 7, 10, 3, R2)
			for lx in range(x + 6, x + w - 6, 14):
				_rect(lx, shelf1 - 4, 4, 4, O3)
		_:
			pass
	# Glass: shadow under the frame top + a wide glare band.
	_rect(x, y, w, 2, T0)
	for i in h:
		var gx := x + 6 + (h - i) * 3 / 4
		for k in 6:
			if gx + k < x + w - 1 and (i + k) % 9 != 0:
				var c := T2 if k < 2 or k > 4 else T3
				_px(gx + k, y + i, c)
	_rect(x + w / 3, y, 1, h, T0)


func _awning(x: int, y: int, w: int, cols: Array) -> void:
	var h := 20
	for yy in h:
		for xx in range(x, x + w):
			var stripe: bool = ((xx - x) / 6) % 2 == 0
			var c: Color = cols[0] if stripe else cols[1]
			if yy < 3:
				c = T0 if yy == 0 else (cols[0] if yy == 1 else c)
			elif yy < 8 and not stripe and c == W5:
				c = W5
			elif yy > 12:
				c = ({B2: B1, T2: T1, G1: G0, T3: T2}.get(c, W3) if stripe else W3) if yy > 16 else c
			_px(xx, y + yy, c)
	for xx in range(x, x + w):                       # scalloped valance
		var k := (xx - x) % 6
		if k > 0 and k < 5:
			_px(xx, y + h, cols[0] if ((xx - x) / 6) % 2 == 0 else cols[1])
		if k > 1 and k < 4:
			_px(xx, y + h + 1, cols[0] if ((xx - x) / 6) % 2 == 0 else cols[1])
	_rect(x, y, 2, h + 2, T0)
	_rect(x + w - 2, y, 2, h + 2, T0)
	for yy in 6:                                     # shadow on the glass below
		for xx in range(x + 2, x + w - 2):
			if _bayer(xx, y + h + 2 + yy) < 0.6 - yy * 0.1:
				_px(xx, y + h + 2 + yy, T0)


func _blade_sign(x: int, y: int, shop: String, fc: Color) -> void:
	if shop == "":
		return
	_rect(x - 2, y, 4, 4, T0)
	_rect(x, y + 1, 18, 2, T0)
	_line(x, y + 8, x + 16, y + 2, T0)
	WDisc.ring(self, x + 4, y + 6, 2, T0)
	_rect(x + 4, y + 3, 1, 4, T0)
	_rect(x + 15, y + 3, 1, 4, T0)
	_rect(x + 1, y + 7, 18, 16, T0)
	_rect(x + 2, y + 8, 16, 14, W4)
	_rect(x + 3, y + 9, 14, 12, fc)
	var c := x + 10
	var m := y + 15
	match shop:
		"cafe", "koffie":
			_rect(c - 4, m - 2, 7, 6, W5)
			_rect(c + 3, m - 1, 2, 3, W5)
			_rect(c - 3, m - 5, 1, 2, W4)
			_rect(c, m - 5, 1, 2, W4)
		"bakker":
			_rect(c - 5, m - 1, 10, 4, O2)
			_rect(c - 4, m - 2, 8, 1, O2)
			_px(c - 2, m, O1)
			_px(c + 1, m, O1)
		"boek":
			_rect(c - 5, m - 3, 5, 7, W5)
			_rect(c, m - 3, 5, 7, W4)
			_rect(c, m - 3, 1, 7, T0)
		"bloem":
			WDisc.draw(self, c, m - 1, 3, B3)
			_px(c, m - 1, O3)
			_rect(c, m + 2, 1, 4, G2)
		"vis":
			_rect(c - 5, m - 1, 8, 3, R3)
			_triangle(c + 3, m + 2, 4, 3, R3)
			_px(c - 3, m - 1, T0)


func _lantern(x: int, y: int) -> void:
	_rect(x, y, 6, 2, T0)
	_rect(x + 4, y - 3, 1, 3, T0)
	_triangle(x - 1, y + 3, 9, 4, T0)
	_rect(x, y + 3, 7, 9, T0)
	_rect(x + 1, y + 4, 5, 7, W4)
	_rect(x + 1, y + 4, 2, 7, W5)
	_rect(x + 3, y + 4, 1, 7, T0)
	_rect(x + 1, y + 12, 5, 2, T0)


func _plaque(x: int, y: int) -> void:
	# Gevelsteen: a carved, painted stone with a ship.
	_rect(x - 1, y - 1, 18, 14, W2)
	_rect(x, y, 16, 12, W4)
	_rect(x + 1, y + 1, 14, 10, T3)
	_rect(x + 2, y + 8, 12, 2, T2)
	_rect(x + 4, y + 6, 8, 2, W1)
	_rect(x + 7, y + 2, 1, 4, W0)
	_triangle(x + 8, y + 6, 4, 4, W5)
	_rect(x + 3, y + 2, 2, 2, O3)


func _cat(x: int, base: int) -> void:
	_rect(x, base - 8, 9, 8, T0)
	_rect(x + 1, base - 9, 7, 1, T0)
	_rect(x + 6, base - 14, 6, 6, T0)
	_px(x + 6, base - 15, T0)
	_px(x + 11, base - 15, T0)
	_px(x + 8, base - 12, O3)
	_px(x + 10, base - 12, O3)
	_rect(x - 3, base - 3, 3, 1, T0)
	_rect(x - 4, base - 6, 1, 3, T0)
	_px(x + 1, base - 7, T1)


func _topiary(x: int, base: int) -> void:
	_rect(x - 4, base - 9, 9, 9, B1)
	_rect(x - 5, base - 10, 11, 2, B2)
	_rect(x - 4, base - 9, 2, 9, B2)
	_rect(x, base - 18, 1, 8, W0)
	_leaves(x, base - 24, 7)


func _leaves(cx: int, cy: int, r: int) -> void:
	var light := Vector3(-0.55, -0.65, 0.52).normalized()
	for yy in range(-r - 1, r + 2):
		for xx in range(-r - 1, r + 2):
			var p := Vector2i(cx + xx, cy + yy)
			var rr := r + (_hash(p.x / 2, p.y / 2) - 0.5) * 2.5
			if xx * xx + yy * yy > rr * rr:
				continue
			var nx := xx / rr
			var ny := yy / rr
			var l := Vector3(nx, ny, sqrt(maxf(1.0 - nx * nx - ny * ny, 0.0))).dot(light)
			l += (_hash(p.x / 2 + 5, p.y / 2) - 0.5) * 0.4
			_px(p.x, p.y, G3 if l > 0.6 else (G2 if l > 0.15 else (G1 if l > -0.3 else G0)))


# --- Street -----------------------------------------------------------------

func _street() -> void:
	# Pavement tiles (GY..GY+10), kerb (+10..+14), cobbled road (+14..+36).
	for y in range(GY, WATER - 8):
		for x in W:
			var c := R1
			var ry := y - GY
			if ry < 10:
				var row := ry / 5
				var j := (x + row * 6) % 12
				c = R2
				if ry % 5 == 4 or j == 0:
					c = R1
				elif ry % 5 == 0 and j < 4:
					c = R3
				if _hash(x / 12, row + 40) < 0.08 and ry % 5 != 4 and j != 0:
					c = R1
			elif ry < 14:
				c = R2 if ry > 10 else R3
				if ry == 13:
					c = R0
				if x % 36 == 0:
					c = R1
			else:
				var cy := (ry - 14) / 4
				var j := (x + (cy % 2) * 5) % 10
				c = R1
				if (ry - 14) % 4 == 3 or j == 0:
					c = R0
				elif (ry - 14) % 4 == 0 and j < 6:
					c = R2
				var id := _hash((x + (cy % 2) * 5) / 10, cy + 99)
				if id < 0.1 and c == R1:
					c = R0
				elif id > 0.93 and c == R1:
					c = R2
			img.set_pixel(x, y, c)
	_rect(0, GY, W, 1, T0)
	# Drain grates and a manhole cover.
	for gx in [180, 760, 1290]:
		_rect(gx, GY + 14, 16, 3, T0)
		for k in range(gx + 1, gx + 16, 3):
			_rect(k, GY + 14, 1, 3, R1)
	_rect(560, GY + 22, 30, 6, R0)
	_rect(562, GY + 23, 26, 4, T0)
	for k in range(563, 588, 4):
		_rect(k, GY + 24, 2, 2, R1)


func _quay() -> void:
	var y0 := WATER - 8
	for bx in range(0, W, 24):
		_bevel(bx, y0, 24, 6, R2, R3, R1)
	_rect(0, y0 + 6, W, 2, T0)
	for mx in [120, 520, 980, 1340]:                  # mooring rings
		WDisc.ring(self, mx, y0 + 4, 3, T0)
		_px(mx, y0 + 1, R3)


func _bollard(x: int) -> void:
	# Amsterdammertje: dark red cast-iron post with three crosses.
	var b := GY + 12
	_rect(x, b - 26, 6, 26, B0)
	_rect(x, b - 26, 2, 26, B1)
	_rect(x + 1, b - 28, 4, 2, B0)
	_px(x + 2, b - 29, B0)
	for k in 3:
		var cy := b - 22 + k * 6
		_rect(x + 2, cy, 3, 1, B2)
		_rect(x + 3, cy - 1, 1, 3, B2)
	_rect(x - 1, b - 2, 8, 2, T0)


func _lamp(x: int) -> void:
	var b := GY + 4
	# Fluted base.
	_rect(x - 6, b - 16, 13, 16, T0)
	for k in range(x - 5, x + 6, 3):
		_rect(k, b - 15, 1, 14, T1)
	_rect(x - 7, b - 2, 15, 2, T0)
	_rect(x - 5, b - 18, 11, 2, T0)
	# Pole with collars.
	_rect(x - 2, b - 128, 4, 112, T0)
	_rect(x - 2, b - 128, 1, 112, T1)
	for cy in [b - 60, b - 100]:
		_rect(x - 3, cy, 6, 3, T0)
		_px(x - 3, cy, T1)
	# Ladder rest + lantern.
	_rect(x - 9, b - 112, 18, 2, T0)
	_rect(x - 8, b - 128, 16, 2, T0)
	_triangle(x - 5, b - 128, 10, 4, T0)
	_rect(x - 7, b - 146, 14, 18, T0)
	_rect(x - 6, b - 145, 5, 16, W4)
	_rect(x + 1, b - 145, 5, 16, T6)
	_rect(x - 6, b - 145, 1, 16, W5)
	_triangle(x - 9, b - 146, 18, 8, T0)
	_rect(x - 1, b - 158, 2, 5, T0)
	WDisc.draw(self, x, b - 159, 2, T0)


func _bin(x: int) -> void:
	var b := GY + 8
	_rect(x, b - 24, 14, 24, G1)
	_rect(x, b - 24, 3, 24, G2)
	_rect(x + 11, b - 24, 3, 24, G0)
	_rect(x - 1, b - 27, 16, 4, G0)
	_rect(x - 1, b - 27, 16, 1, G2)
	_rect(x + 3, b - 20, 8, 2, T0)
	_rect(x + 6, b - 12, 2, 6, W5)
	_rect(x + 2, b, 10, 2, T0)


func _bike(x: int, frame: Color, crate: bool) -> void:
	var b := GY + 10
	var r := 10
	var fhi := {T0: T1, B1: B2, T2: T3, G1: G2}.get(frame, R2) as Color
	for wc in [x + r, x + r + 34]:
		WDisc.ring(self, wc, b - r, r, T0)
		WDisc.ring(self, wc, b - r, r - 1, T0)
		WDisc.ring(self, wc, b - r, r - 2, R2)
		for a in [0, 45, 90, 135]:
			var d := Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * (r - 3)
			_line(int(wc - d.x), int(b - r - d.y), int(wc + d.x), int(b - r + d.y), R1)
		_rect(wc - 1, b - r - 1, 3, 3, R3)
		for a in range(200, 341, 10):                # mudguard
			var p := Vector2(wc, b - r) + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * (r + 2)
			_px(int(p.x), int(p.y), frame)
	var bb := Vector2i(x + r + 16, b - r)           # bottom bracket
	var head := Vector2i(x + r + 31, b - 28)
	var seat := Vector2i(x + r + 10, b - 30)
	_thick(bb, head + Vector2i(-2, 6), frame, fhi)   # step-through down tube
	_thick(bb, seat, frame, fhi)
	_thick(bb, Vector2i(x + r, b - r), frame, fhi)
	_thick(seat, Vector2i(x + r, b - r), frame, fhi)
	_thick(head, Vector2i(x + r + 34, b - r), frame, fhi)
	_rect(bb.x - 8, bb.y - 3, 14, 5, frame)           # chain guard
	_rect(bb.x - 8, bb.y - 3, 14, 1, fhi)
	_rect(seat.x - 5, seat.y - 3, 10, 3, W0)          # saddle
	_rect(seat.x - 4, seat.y - 4, 7, 1, W1)
	_rect(head.x - 1, head.y - 6, 2, 6, T0)
	_line(head.x, head.y - 6, head.x - 8, head.y - 9, T0)
	_rect(head.x - 10, head.y - 10, 4, 2, W0)
	_rect(head.x + 2, head.y + 2, 4, 3, O3)           # lamp
	_rect(x - 2, b - 26, 22, 2, T0)                   # rear rack
	if crate:
		_rect(x, b - 38, 18, 12, W1)
		_rect(x, b - 38, 18, 1, W2)
		_rect(x, b - 33, 18, 1, W0)
		_rect(x + 8, b - 38, 1, 12, W0)


func _thick(a: Vector2i, b: Vector2i, c: Color, hi: Color) -> void:
	_line(a.x, a.y, b.x, b.y, c)
	_line(a.x, a.y - 1, b.x, b.y - 1, hi)


func _rack(x: int) -> void:
	for k in 2:
		var rx := x + k * 30
		_rect(rx, GY - 8, 2, 18, T0)
		_rect(rx + 16, GY - 8, 2, 18, T0)
		_rect(rx, GY - 10, 18, 2, T0)
		_px(rx + 1, GY - 9, R2)


func _car(x: int, body: Color) -> void:
	# Boxy 80s hatchback, 124 x 44 art px.
	var b := WATER - 9
	var dark := B1 if body == B3 else T2
	var hi := B4 if body == B3 else T5
	var shadow := B0 if body == B3 else T1
	for yy in 4:                                     # shadow under the car
		for xx in range(x + 4, x + 120):
			if _bayer(xx, b + yy) < 0.7 - yy * 0.15:
				_px(xx, b + yy - 2, T0)
	_rect(x + 2, b - 26, 120, 18, body)              # lower body
	_rect(x + 2, b - 26, 120, 2, hi)
	_rect(x + 2, b - 13, 120, 5, dark)
	_rect(x + 2, b - 14, 120, 1, T0)                 # rubber strip
	_rect(x + 26, b - 44, 72, 18, body)              # cabin
	for yy in 6:
		_rect(x + 20 + yy, b - 32 - yy, 8, 1, body)
		_rect(x + 98, b - 44 + yy * 3, 10 - yy, 3, body)
	_rect(x + 26, b - 44, 72, 1, hi)
	_rect(x + 30, b - 42, 30, 14, T0)                # windows
	_rect(x + 64, b - 42, 30, 14, T0)
	_rect(x + 30, b - 42, 30, 2, T1)
	_rect(x + 64, b - 42, 30, 2, T1)
	for i in 10:
		_px(x + 36 + i, b - 30 - i, T5)
		_px(x + 37 + i, b - 30 - i, T3)
		_px(x + 70 + i, b - 30 - i, T5)
		_px(x + 71 + i, b - 30 - i, T3)
	_rect(x + 61, b - 44, 3, 36, dark)               # B pillar + door seams
	_rect(x + 28, b - 26, 1, 12, shadow)
	_rect(x + 62, b - 26, 1, 12, shadow)
	_rect(x + 96, b - 26, 1, 12, shadow)
	_rect(x + 52, b - 22, 6, 2, R3)                  # handles
	_rect(x + 86, b - 22, 6, 2, R3)
	_rect(x + 98, b - 34, 4, 4, T0)                  # mirror
	_rect(x + 114, b - 24, 8, 5, W5)                 # headlight
	_rect(x + 114, b - 24, 8, 1, O3)
	_rect(x + 116, b - 19, 6, 2, O1)
	_rect(x + 2, b - 24, 5, 6, B2)                   # tail light
	_rect(x, b - 12, 10, 4, R2)                      # bumpers
	_rect(x, b - 12, 10, 1, R3)
	_rect(x + 114, b - 12, 10, 4, R2)
	_rect(x + 114, b - 12, 10, 1, R3)
	_rect(x + 6, b - 20, 14, 5, O2)                  # yellow Dutch plate
	_text3(x + 7, b - 20, "TL", T0)
	_rect(x + 30, b - 46, 1, 6, T0)                  # antenna
	for wx in [x + 24, x + 100]:
		WDisc.draw(self, wx, b - 8, 10, dark)
		WDisc.draw(self, wx, b - 7, 9, T0)
		WDisc.ring(self, wx, b - 7, 7, T1)
		WDisc.draw(self, wx, b - 7, 5, R2)
		WDisc.draw(self, wx, b - 7, 2, R3)
		for a in range(0, 360, 60):
			var p := Vector2(wx, b - 7) + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * 4
			_px(int(p.x), int(p.y), R1)
		_px(wx - 3, b - 10, R3)


func _terrace(x: int) -> void:
	for tx in [x + 8, x + 58]:
		var b := GY + 8
		_rect(tx, b - 22, 20, 3, W4)
		_rect(tx, b - 22, 20, 1, W5)
		_rect(tx + 1, b - 19, 18, 1, W2)
		_rect(tx + 9, b - 19, 2, 17, T0)
		_rect(tx + 5, b - 2, 10, 2, T0)
		_rect(tx + 6, b - 25, 3, 3, W5)                # cup
		_px(tx + 9, b - 24, W5)
		for side in [-1, 1]:                          # bistro chairs
			var cx: int = tx + (-8 if side < 0 else 22)
			_rect(cx, b - 14, 8, 2, W2)
			_rect(cx, b - 14, 8, 1, W3)
			_rect(cx + (0 if side < 0 else 7), b - 28, 1, 26, T0)
			_rect(cx + (7 if side < 0 else 0), b - 12, 1, 12, T0)
			for k in range(b - 27, b - 15, 3):
				_rect(cx + (1 if side < 0 else 4), k, 3, 1, W1)


func _aboard(x: int, text: String) -> void:
	var b := GY + 8
	_line(x, b, x + 6, b - 30, W1)
	_line(x + 18, b, x + 12, b - 30, W1)
	_rect(x + 2, b - 28, 14, 20, W1)
	_rect(x + 3, b - 27, 12, 18, T1)
	_text3(x + 4, b - 25, "CA", W5)
	_rect(x + 4, b - 18, 9, 1, W4)
	_rect(x + 4, b - 15, 6, 1, W4)
	_rect(x + 4, b - 12, 8, 1, O3)


func _buckets(x: int) -> void:
	# Flower stand: a stepped wooden rack with zinc buckets of flowers.
	var b := GY + 8
	_rect(x, b - 10, 86, 10, W1)
	_rect(x, b - 10, 86, 1, W2)
	_rect(x + 10, b - 18, 66, 8, W1)
	_rect(x + 10, b - 18, 66, 1, W2)
	for row in 2:
		var by: int = b - 10 - row * 8
		var start: int = x + 4 + row * 10
		for k in (6 - row * 2):
			var bx: int = start + k * 13
			_rect(bx, by - 9, 10, 9, R2)
			_rect(bx, by - 9, 10, 1, R3)
			_rect(bx + 7, by - 8, 3, 8, R1)
			var fc: Color = [B3, O2, W5, B2, O3, P0, B4][(k + row * 3) % 7]
			for i in 14:
				var fx := bx + int(_hash(bx + i, by) * 10.0)
				var fy := by - 11 - int(_hash(by, bx + i) * 9.0)
				_rect(fx, fy + 2, 1, by - 9 - fy - 2, G1)
				_rect(fx, fy, 2, 2, fc)
				if i % 3 == 0:
					_px(fx, fy, W5)


func _book_stand(x: int) -> void:
	var b := GY + 8
	_rect(x, b - 16, 30, 3, W1)
	_rect(x + 2, b - 13, 2, 13, W0)
	_rect(x + 26, b - 13, 2, 13, W0)
	for bx in range(x + 1, x + 29, 3):
		var bc: Color = [B1, T2, G1, O1, W3, P0][(bx / 3) % 6]
		_rect(bx, b - 24 + (bx % 2), 3, 8 - (bx % 2), bc)
		_px(bx, b - 23, W4)


func _tree(x: int, s: float) -> void:
	var base := GY + 6
	var th := int(150 * s)
	# Trunk with bark, a tree grate and an iron guard.
	_rect(x - 5, base - th, 10, th, W0)
	_rect(x - 5, base - th, 3, th, W1)
	for yy in range(base - th, base, 5):
		_rect(x - 1 + int(_hash(x, yy) * 3.0), yy, 1, 3, T0)
	_rect(x - 14, base - 2, 28, 3, T0)
	for k in range(x - 13, x + 14, 3):
		_px(k, base - 2, R1)
	_rect(x - 9, base - 30, 1, 28, T0)
	_rect(x + 9, base - 30, 1, 28, T0)
	_rect(x - 9, base - 30, 19, 1, T0)
	# Branches.
	var cy := base - th - 20
	_line(x, base - th + 30, x - 34, cy + 10, W0)
	_line(x, base - th + 30, x + 38, cy + 6, W0)
	_line(x, base - th + 20, x - 10, cy - 30, W0)
	_line(x + 1, base - th + 20, x + 14, cy - 34, W0)
	# Canopy of many small leaf clusters, lit from the top-left.
	var clumps := [[0, -8, 34], [-32, 6, 24], [32, 4, 26], [-16, -34, 22], [18, -36, 24],
		[-46, -16, 16], [46, -18, 16], [2, -56, 18], [-4, 18, 22], [-24, 24, 14], [26, 22, 16]]
	var light := Vector3(-0.55, -0.65, 0.52).normalized()
	var m := {}
	for c in clumps:
		var r: float = c[2] * s
		var cc := Vector2(x + c[0] * s, cy + c[1] * s)
		for yy in range(int(cc.y - r - 3), int(cc.y + r + 4)):
			for xx in range(int(cc.x - r - 3), int(cc.x + r + 4)):
				var p := Vector2i(xx, yy)
				var rr := r + (_hash(xx / 3, yy / 3) - 0.5) * 5.0
				var d := Vector2(xx, yy) - cc
				if d.length() > rr:
					continue
				var n := d / rr
				var big := Vector3(n.x, n.y, sqrt(maxf(1.0 - n.length_squared(), 0.0))).dot(light)
				# Small leaf clusters: a sphere per 5x4 cell.
				var cell := Vector2i(int(floor(xx / 5.0)), int(floor(yy / 4.0)))
				var jx := _hash(cell.x, cell.y) * 2.0
				var local := Vector2(xx - cell.x * 5 - 2.5 - jx + 1.0, yy - cell.y * 4 - 2.0) / 3.2
				var small := Vector3(local.x, local.y, sqrt(maxf(1.0 - local.length_squared(), 0.0))).dot(light)
				var l := big * 0.75 + small * 0.4 - 0.05
				var v: int = 1
				if l > 0.18:
					v = 2
				if l > 0.55:
					v = 3
				if l > 0.85:
					v = 4
				if l < -0.25:
					v = 0
				if not m.has(p) or int(m[p]) < v or true:
					m[p] = v
	var cols := [G0, G1, G2, G3, G4]
	for p: Vector2i in m:
		var v: int = m[p]
		if not m.has(p + Vector2i(0, 1)) or not m.has(p + Vector2i(1, 1)):
			v = 0
		_px(p.x, p.y, cols[v])
	# Holes where branches show through.
	for i in 14:
		var hx := x + int((_hash(i, 1) - 0.5) * 70 * s)
		var hy := cy + int((_hash(1, i) - 0.3) * 50 * s)
		if m.has(Vector2i(hx, hy)) and m.has(Vector2i(hx + 3, hy + 3)):
			_rect(hx, hy, 3, 2, G0)
			_px(hx + 1, hy, W0)


func _houseboat(x: int) -> void:
	var y := WATER + 34
	_rect(x, y, 210, 16, G1)                        # hull with planks
	for k in range(y + 4, y + 16, 4):
		_rect(x, k, 210, 1, G0)
	_rect(x, y, 210, 2, G2)
	_rect(x + 2, y + 14, 206, 2, T0)
	for fx in range(x + 20, x + 200, 40):           # tyre fenders
		WDisc.ring(self, fx, y + 6, 3, T0)
	_rect(x + 14, y - 26, 170, 26, W4)              # cabin
	_rect(x + 14, y - 26, 170, 1, W5)
	_rect(x + 180, y - 26, 4, 26, W3)
	_rect(x + 10, y - 30, 178, 4, B1)
	_rect(x + 10, y - 30, 178, 1, B2)
	for wx in range(x + 24, x + 170, 22):
		_rect(wx - 1, y - 21, 14, 12, W1)
		_rect(wx, y - 20, 12, 10, T0)
		_rect(wx, y - 20, 12, 2, T1)
		_rect(wx + 6, y - 20, 1, 10, W1)
		_px(wx + 1, y - 19, T3)
	for px_ in range(x + 18, x + 180, 12):          # pot plants on the roof
		_rect(px_, y - 36, 6, 6, B2)
		_rect(px_, y - 36, 6, 1, B3)
		_leaves(px_ + 3, y - 40, 4)
	_rect(x + 160, y - 50, 4, 20, T0)               # stove pipe
	_rect(x + 158, y - 52, 8, 2, T0)
	_bike_small(x + 30, y - 30)


func _bike_small(x: int, b: int) -> void:
	WDisc.ring(self, x + 5, b - 5, 5, T0)
	WDisc.ring(self, x + 22, b - 5, 5, T0)
	_line(x + 5, b - 5, x + 13, b - 12, B1)
	_line(x + 13, b - 12, x + 22, b - 5, B1)
	_line(x + 13, b - 5, x + 13, b - 12, B1)
	_rect(x + 10, b - 14, 5, 2, W0)


func _reflect() -> void:
	# The canal mirrors the street side on a few water tones by brightness
	# (greens stay olive, warm colours brick); ripples and light dashes on top.
	rng.seed = 3
	var cool := [T0, T1, T2, T3, T4]
	var green := [T0, T1, G0, G1, G1]
	var warm := [T0, T1, T1, B0, B1]
	var src := img.duplicate() as Image
	for y in range(WATER, H):
		var depth := float(y - WATER) / float(H - WATER)
		var band := (y - WATER) / 4
		var dx := int(round(sin(band * 1.7) * (2.0 + depth * 6.0)))
		var src_y := WATER - 1 - ((y - WATER) / 2 * 2) * 9 / 10
		for x in W:
			var c := T1
			if src_y >= 0:
				var sx := clampi((x + dx) / 3 * 3, 0, W - 3)
				var s := (src.get_pixel(sx, src_y) + src.get_pixel(sx + 1, src_y) + src.get_pixel(sx + 2, src_y)) / 3.0
				var lum := s.r * 0.3 + s.g * 0.59 + s.b * 0.11
				var idx := clampi(int(lum * 5.0 - depth * 0.9 - 0.5), 0, 4)
				var ramp: Array = cool
				if s.g > s.r + 0.05 and s.g > s.b + 0.05:
					ramp = green
				elif s.r > s.b + 0.15 and s.r > s.g + 0.1:
					ramp = warm
				c = ramp[idx]
			if y < WATER + 2:
				c = T0
			elif y < WATER + 5:
				c = T1
			img.set_pixel(x, y, c)
	for i in 900:
		var y := rng.randi_range(WATER + 5, H - 1)
		var x := rng.randi_range(0, W - 1)
		var depth := float(y - WATER) / float(H - WATER)
		var len := rng.randi_range(3, 8 + int(depth * 26))
		_rect(x, y, len, 1, T3 if rng.randf() < 0.55 else T4)
		if rng.randf() < 0.3:
			_rect(x + 2, y, maxi(len - 4, 1), 1, T6)


func _band() -> void:
	# The real band sprites, pasted 1:1 (they're drawn at art density).
	for b in [["res://assets/sprites/characters/keys_joep/keys_joep_sheet.png", 452],
			["res://assets/sprites/characters/bass_jay/bass_jay_sheet.png", 806]]:
		var sheet := Image.load_from_file(ProjectSettings.globalize_path(b[0]))
		if sheet == null:
			continue
		sheet.convert(Image.FORMAT_RGBA8)
		var frame := sheet.get_region(Rect2i(0, 0, 96, 96))
		img.blend_rect(frame, Rect2i(0, 0, 96, 96), Vector2i(int(b[1]) - 48, GY - 95 + 2))


# --- Helpers ----------------------------------------------------------------

func _quantize() -> void:
	var cache := {}
	for y in H:
		for x in W:
			var c := img.get_pixel(x, y)
			var key := c.to_rgba32()
			if not cache.has(key):
				cache[key] = _nearest(c)
			img.set_pixel(x, y, cache[key])


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


func _hash(x: int, y: int) -> float:
	var h := (x * 374761393 + y * 668265263) & 0x7fffffff
	h = ((h ^ (h >> 13)) * 1274126177) & 0x7fffffff
	return float(h % 1000) / 1000.0


func _text5(x: int, y: int, s: String, c: Color) -> void:
	for i in s.length():
		var g: String = FONT5.get(s[i], FONT5[" "])
		for k in 35:
			if g[k] == "1":
				_px(x + i * 6 + k % 5, y + k / 5, c)


func _text5_top(x: int, y: int, s: String, c: Color) -> void:
	# Highlight on the top row of each letter (gilded lettering).
	for i in s.length():
		var g: String = FONT5.get(s[i], FONT5[" "])
		for k in 10:
			if g[k] == "1":
				_px(x + i * 6 + k % 5, y + k / 5, c)


func _text3(x: int, y: int, s: String, c: Color) -> void:
	for i in s.length():
		var g: String = FONT3.get(s[i], FONT3[" "])
		for k in 15:
			if g[k] == "1":
				_px(x + i * 4 + k % 3, y + k / 3, c)


func _bevel(x: int, y: int, w: int, h: int, base: Color, hi: Color, sh: Color) -> void:
	_rect(x, y, w, h, base)
	_rect(x, y, w, 1, hi)
	_rect(x, y, 1, h, hi)
	_rect(x, y + h - 1, w, 1, sh)
	_rect(x + w - 1, y, 1, h, sh)


func _px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < W and y < H:
		img.set_pixel(x, y, c)


func _rect(x: int, y: int, w: int, h: int, c: Color) -> void:
	if w <= 0 or h <= 0:
		return
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


class WDisc:
	static func draw(m: Object, cx: int, cy: int, r: int, c: Color) -> void:
		for y in range(-r, r + 1):
			var half := int(sqrt(maxf(r * r - y * y, 0.0)))
			m._rect(cx - half, cy + y, half * 2 + 1, 1, c)

	static func ring(m: Object, cx: int, cy: int, r: int, c: Color) -> void:
		var n := maxi(12, r * 8)
		for i in n:
			var a := TAU * i / n
			m._px(cx + int(round(cos(a) * r)), cy + int(round(sin(a) * r)), c)
