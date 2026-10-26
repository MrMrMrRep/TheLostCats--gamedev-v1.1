extends "res://tools/style_mock_v3.gd"
## Style v3 mock: openings between the canal houses, in perspective.
##   steeg  - narrow, dark alley (optionally a covered gateway, "poort")
##   alley  - mid-size brick alley with a lamp on a wire
##   street - wide side street: shops, awnings, trees, people, a church
##   canal  - side canal with a little street on each bank; the street in
##            front crosses it on a brick arch bridge
## Two streets (A, B) with the houses moved to fit. Reuses the v3 painter;
## does not change it. Run:
##   Summer --headless --path . --script res://tools/style_mock_v3_alleys.gd

var bridges: Array = []                     # [x, w] of canal openings (bridge in front)


func _initialize() -> void:
	for street in ["a", "b"]:
		img = Image.create(W, H, false, Image.FORMAT_RGBA8)
		rng.seed = 5
		bridges = []
		call("_street_" + street)
		_quantize()
		_paste(street)
		img.save_png("res://docs/art/style_v3_alleys_%s_overview.png" % street)
		match street:
			"a":
				_frame("style_v3_alleys_a_zoom3_steeg", 40, GY - 152, 427, 240, 3)
				_frame("style_v3_alleys_a_zoom3_canal", 520, GY - 152, 427, 240, 3)
				_frame("style_v3_alleys_a_zoom2", 360, GY - 256, 640, 360, 2)
			"b":
				_frame("style_v3_alleys_b_zoom3_street", 160, GY - 152, 427, 240, 3)
				_frame("style_v3_alleys_b_zoom2", 0, GY - 256, 640, 360, 2)
				_frame("style_v3_alleys_b_zoom2_poort", 700, GY - 256, 640, 360, 2)
	quit()


func _paste(street: String) -> void:
	var spots := {"a": [[400, "keys_joep/keys_joep_sheet"], [640, "bass_jay/bass_jay_sheet"]],
		"b": [[330, "keys_joep/keys_joep_sheet"], [380, "bass_jay/bass_jay_sheet"]]}
	for s in spots[street]:
		var sheet := Image.load_from_file(ProjectSettings.globalize_path("res://assets/sprites/characters/%s.png" % s[1]))
		sheet.convert(Image.FORMAT_RGBA8)
		img.blend_rect(sheet.get_region(Rect2i(0, 0, 96, 96)), Rect2i(0, 0, 96, 96), Vector2i(int(s[0]) - 48, GY - 93))


func _backdrop() -> void:
	_sky()
	_sun(1180, 110, 26)
	_streaks()
	_cloud(220, 120, 2.4)
	_cloud(760, 80, 1.8)
	_cloud(1060, 200, 1.3)
	_skyline_far()
	_skyline_mid()
	_back_row()


## Lays out openings + houses from left to right, then the street on top.
func _build(items: Array) -> void:
	var x := 0
	var houses := []
	for it: Dictionary in items:
		if it.has("open"):
			_side_street(x, it["w"], it["open"], it.get("poort", false))
			if it["open"] == "canal":
				bridges.append([x, it["w"]])
		else:
			var hs := it.duplicate()
			hs["x"] = x
			houses.append(hs)
		x += int(it["w"])
	for hs: Dictionary in houses:
		_house(hs)
	_street()
	_quay()
	for b in bridges:
		_bridge_deck(b[0], b[1])
	_reflect()
	for b in bridges:
		_bridge_arch(b[0], b[1])


func _street_a() -> void:
	_backdrop()
	_build([
		{"w": 132, "f": 4, "s": "brick", "g": "step", "gr": "door", "boxes": true, "pipe": true, "no": "263"},
		{"w": 30, "open": "steeg"},
		{"w": 120, "f": 4, "s": "teal", "g": "bell", "gr": "shop", "shop": "cafe", "sign": "CAFE DE KAT", "awn": [B2, W5], "fascia": T1},
		{"w": 144, "f": 3, "s": "cream", "g": "mansard", "gr": "shop", "shop": "boek", "sign": "BOEKEN", "fascia": G0, "quoins": true},
		{"w": 74, "open": "alley"},
		{"w": 112, "f": 4, "s": "slate", "g": "neck", "gr": "door", "shutters": [G1, W5], "plaque": true, "cat": true, "no": "271"},
		{"w": 216, "open": "canal"},
		{"w": 128, "f": 4, "s": "mustard", "g": "neck", "gr": "shop", "shop": "bloem", "sign": "BLOEMEN", "fascia": G1},
		{"w": 112, "f": 5, "s": "tealdark", "g": "bell", "gr": "door", "lace": true, "no": "289"},
		{"w": 26, "open": "steeg"},
		{"w": 136, "f": 4, "s": "darkbrick", "g": "step", "gr": "shop", "shop": "koffie", "sign": "KOFFIE", "awn": [G1, W4], "fascia": B0},
		{"w": 120, "f": 4, "s": "cream", "g": "spout", "gr": "door", "shutters": [B1, W5], "boxes": true, "no": "297"},
		{"w": 112, "f": 3, "s": "plum", "g": "step", "gr": "door", "plaque": true, "pipe": true, "no": "301"},
	])
	_terrace(172)
	_aboard(268, "KOFFIE")
	_book_stand(300)
	_buckets(842)
	_lamp(476)
	_bin(1010)
	_bike(10, T0, true)
	_bike(1200, T2, true)
	for bx in [80, 380, 470, 790, 980, 1150, 1330]:
		_bollard(bx)
	_car(1020, B3)


func _street_b() -> void:
	_backdrop()
	_build([
		{"w": 112, "f": 4, "s": "plum", "g": "step", "gr": "door", "pipe": true, "no": "12"},
		{"w": 88, "open": "alley"},
		{"w": 124, "f": 4, "s": "coral", "g": "spout", "gr": "shop", "shop": "bakker", "sign": "BAKKER", "awn": [T2, W5], "fascia": T1},
		{"w": 168, "open": "street"},
		{"w": 120, "f": 4, "s": "brick", "g": "neck", "gr": "shop", "shop": "vis", "sign": "VIS", "awn": [T3, W5], "fascia": T1},
		{"w": 120, "f": 4, "s": "teal", "g": "bell", "gr": "door", "boxes": true, "no": "18"},
		{"w": 40, "open": "steeg", "poort": true},
		{"w": 144, "f": 3, "s": "cream", "g": "mansard", "gr": "door", "quoins": true, "no": "22"},
		{"w": 112, "f": 4, "s": "slate", "g": "neck", "gr": "door", "shutters": [B1, W5], "no": "24"},
		{"w": 60, "open": "alley"},
		{"w": 136, "f": 4, "s": "darkbrick", "g": "step", "gr": "shop", "shop": "koffie", "sign": "KOFFIE", "awn": [G1, W4], "fascia": B0},
		{"w": 112, "f": 5, "s": "tealdark", "g": "bell", "gr": "door", "lace": true, "no": "28"},
		{"w": 64, "f": 3, "s": "mustard", "g": "spout", "gr": "door"},
	])
	_lamp(206)
	_lamp(780)
	_bin(560)
	_bike(30, B1, false)
	_bike(880, G1, true)
	for bx in [96, 300, 520, 640, 900, 1100, 1290]:
		_bollard(bx)
	_car(560, T3)


# --- Openings in perspective -------------------------------------------------

func _side_street(x0: int, w: int, kind: String, poort: bool) -> void:
	var vx := x0 + w * 0.5
	var vy := float(GY - {"steeg": 70, "alley": 90, "street": 110, "canal": 160}[kind])
	var s_end: float = {"steeg": 0.2, "alley": 0.3, "street": 0.34, "canal": 0.3}[kind]
	var wall_h := 330.0
	var xl := vx + (x0 - vx) * s_end
	var xr := vx + (x0 + w - vx) * s_end
	var gy_end := vy + (GY - vy) * s_end
	_end_facade(int(floor(xl)), int(ceil(xr)), gy_end, s_end, kind)
	var shade_top := int(gy_end - (wall_h * 0.58) * s_end)
	for yy in range(shade_top, int(gy_end) + 1):
		for xx in range(int(floor(xl)), int(ceil(xr))):
			_px(xx, yy, _dark(img.get_pixel(clampi(xx, 0, W - 1), clampi(yy, 0, H - 1))))
	for x in range(x0, x0 + w):
		var left := float(x) < xl
		var right := float(x) >= xr
		var s := 1.0
		if left:
			s = (x + 0.5 - vx) / (x0 - vx)
		elif right:
			s = (x + 0.5 - vx) / (x0 + w - vx)
		for y in range(GY - int(wall_h) - 10, GY):
			if left or right:
				var yg := vy + (GY - vy) * s
				var d := 1.0 / s - 1.0
				var hidx := int(d / 0.9)
				var hh := wall_h - _hash(hidx, x0 + (7 if right else 0)) * 100.0
				var yt := vy + (GY - hh - vy) * s
				if y < int(yt):
					continue
				if y < yg:
					var hl := (yg - y) / s
					var wc := _wall_px(x, y, s, d, hl, hh, hidx, right, kind, s_end)
					# Cast shadow: left walls always, right walls up to where the sun reaches.
					if not right or hl < hh * 0.58:
						wc = _dark(wc)
					_px(x, y, wc)
					continue
			elif y < gy_end:
				continue
			var gc := _ground_px(x, y, vx, vy, w, kind, s_end)
			_px(x, y, _dark(gc))                     # shadow all the way to the end
	match kind:
		"steeg": _steeg_details(x0, w, vx, vy, poort)
		"alley": _alley_details(x0, w, vx, vy)
		"street": _street_details(x0, w, vx, vy)
		"canal": _canal_details(x0, w, vx, vy)


## One shade darker on the same ramp (lit windows keep their light).
func _dark(c: Color) -> Color:
	var m := {T7: T6, T6: T5, T5: T4, T4: T3, T3: T2, T2: T1, T1: T0, T0: T0,
		W5: W4, W4: W3, W3: W2, W2: W1, W1: W0, W0: T0,
		B4: B3, B3: B2, B2: B1, B1: B0, B0: T0, O1: B1,
		G4: G3, G3: G2, G2: G1, G1: G0, G0: T0,
		R3: R2, R2: R1, R1: R0, R0: T0, P0: T0}
	return m.get(c, c)


func _fog(c: Color, x: int, y: int, s: float, s_end: float, kind: String, lit: bool) -> Color:
	var f := clampf((1.0 - s) / (1.0 - s_end), 0.0, 1.0)
	if kind == "steeg":
		return T0 if f > 0.55 else c
	if (kind == "street" or kind == "canal") and f > 0.88:
		return T3 if lit else T2                  # a touch of haze at the very end
	return c


func _wall_px(x: int, y: int, s: float, d: float, hl: float, hh: float, hidx: int,
		lit: bool, kind: String, s_end: float) -> Color:
	var pal: Array = [[B2, B1], [T3, T2], [W4, W3], [O2, O1], [B3, B2], [T2, T1], [P0, T0]]
	var pair: Array = pal[int(_hash(hidx, int(vx_seed(kind))) * pal.size()) % pal.size()]
	var c: Color = pair[0] if lit else pair[1]
	var trim := W4 if lit else W3
	var brick: bool = kind == "alley" or pair[0] == B2
	if kind == "steeg":
		c = T1 if lit else T0
		trim = T2 if lit else T1
		brick = true
	if brick and int(hl) % 4 == 3 and s > 0.45:
		c = pair[1] if lit else T0
		if kind == "steeg":
			c = T0
	# House seams, cornice, string course.
	if fmod(d, 0.9) < 0.03:
		c = T0
	if hl > hh - 8:
		c = trim if hl < hh - 2 else T0
	elif absf(hl - GF) < 3.0:
		c = trim
	# Windows in perspective (spacing in depth), storeys above the ground floor.
	var fr := fmod(d / 0.3, 1.0)
	var row := -1
	if hl > GF + 14:
		var k := int((hl - GF - 14) / ST)
		var local := hl - GF - 14 - k * ST
		if local < 38 and hl < hh - 16:
			row = k
			if fr > 0.28 and fr < 0.72:
				var edge := fr < 0.33 or fr > 0.67 or local < 3.0 or local > 35.0
				c = trim if edge else T0
				if not edge:
					if _hash(int(d / 0.3), k + hidx * 7) < (0.35 if kind == "steeg" else 0.18):
						c = O2 if local > 18.0 else O3
					elif local < 9.0:
						c = T1
				if absf(local - 19.0) < 1.0 and not edge:
					c = trim
	elif hl > 6.0 and hl < GF - 8:                  # ground floor
		if kind == "street" and fr > 0.15 and fr < 0.85:
			var edge := fr < 0.2 or fr > 0.8
			c = W1 if edge else (O1 if hl < 40.0 else T0)
			if hl > GF - 26 and hl < GF - 12:        # awning
				var stripe := int(d / 0.04) % 2 == 0
				c = [B2, T2, G1][hidx % 3] if stripe else W5
				if not lit:
					c = [B1, T1, G0][hidx % 3] if stripe else W3
		elif fr > 0.38 and fr < 0.62 and hl < 68.0:  # doors
			c = [G1, T1, B1, W0][hidx % 4] if fr > 0.42 and fr < 0.58 else trim
			if kind == "steeg":
				c = T0 if fr > 0.42 and fr < 0.58 else T1
	return _fog(c, x, y, s, s_end, kind, lit)


func vx_seed(kind: String) -> int:
	return kind.length() * 13


func _ground_px(x: int, y: int, vx: float, vy: float, w: int, kind: String, s_end: float) -> Color:
	var s := (y + 0.5 - vy) / (GY - vy)
	var d := 1.0 / s - 1.0
	var u := (x + 0.5 - vx) / s                    # sideways, in near px
	var half := w * 0.5
	var c := R1
	match kind:
		"steeg":
			c = R0
			if fmod(d * 9.0, 1.0) < 0.22 or fmod(u / 6.0 + int(d * 9.0) * 0.5, 1.0) < 0.15:
				c = T0
			if absf(u) < 5.0 and d > 0.9 and d < 1.5:  # a puddle catching the light
				c = T2
		"alley":
			var row := int(d * 7.0)
			c = R1
			if fmod(d * 7.0, 1.0) < 0.18 or fmod(u / 8.0 + row * 0.5, 1.0) < 0.12:
				c = R0
			elif fmod(d * 7.0, 1.0) < 0.36:
				c = R2
			if absf(u) > half * 0.8:
				c = R2 if fmod(u / 10.0, 1.0) > 0.1 else R1
		"street":
			if absf(u) > half * 0.62:
				c = R2 if fmod(d * 5.0, 1.0) > 0.1 else R1
			elif absf(u) > half * 0.58:
				c = R3
			else:
				var row := int(d * 6.0)
				c = R1
				if fmod(d * 6.0, 1.0) < 0.15 or fmod(u / 9.0 + row * 0.5, 1.0) < 0.1:
					c = R0
		"canal":
			if absf(u) < half * 0.6:
				c = T1
				var band := fmod(d * 6.0 + sin(u * 0.12) * 0.06, 1.0)
				if band < 0.2:
					c = T2
				if absf(u) > half * 0.42:
					c = G0 if band > 0.3 else T1        # the banks' trees mirrored
				if _hash(int(u / 5.0), int(d * 40.0)) < 0.05:
					c = T4
				if absf(u) < half * 0.12 and band < 0.35:
					c = T3                            # sky down the middle
			elif absf(u) < half * 0.67:
				c = R3 if absf(u) < half * 0.64 else R1
			else:
				c = R2 if fmod(d * 6.0, 1.0) > 0.12 else R1
				if fmod(u / 12.0, 1.0) < 0.06:
					c = R1
	return _fog(c, x, y, s, s_end, kind, true)


func _end_facade(xl: int, xr: int, gy: float, s: float, kind: String) -> void:
	var w := xr - xl
	if w <= 0:
		return
	var g := int(gy)
	match kind:
		"steeg":
			# A bright little courtyard at the end: light, a stair, a plant.
			_rect(xl, g - int(330 * s), w, int(150 * s), T1)   # wall over the courtyard
			for yy in range(g - int(330 * s), g - int(180 * s), 4):
				_rect(xl, yy, w, 1, T0)
			_rect(xl, g - int(180 * s), w, int(180 * s), T6)
			_rect(xl, g - int(180 * s), w, 2, W4)
			for k in 4:
				_rect(xl + 1 + k, g - 3 - k * 3, w - 2 - k * 2, 3, R2 if k % 2 else R3)
			_rect(xl + w / 2, g - 14, 2, 6, G2)
			return
		"canal":
			# Far bridge over the canal and houses behind it.
			_end_houses(xl, xr, g - int(26 * s), s)
			var cx := (xl + xr) / 2
			var rx := int(w * 0.3)
			for yy in int(40 * s) + 4:
				_rect(xl, g - int(30 * s) + yy, w, 1, B1 if yy % 3 else B0)
			for yy in int(22 * s) + 2:
				var half := int(rx * sqrt(maxf(1.0 - pow(float(yy) / (22.0 * s + 2.0), 2.0), 0.0)))
				_rect(cx - half, g + 6 - yy, half * 2, 1, T1)
			_rect(xl, g - int(32 * s), w, 2, W3)
			for k in range(xl, xr, 3):
				_rect(k, g - int(40 * s), 1, int(8 * s), T0)
			return
	_end_houses(xl, xr, g, s)


func _end_houses(xl: int, xr: int, g: int, s: float) -> void:
	var x := xl
	var i := 0
	var pal := [[T3, T2], [W4, W3], [B2, B1], [O2, O1], [T2, T1]]
	while x < xr:
		var hw := mini(int((110 + _hash(i, xl) * 40.0) * s), xr - x)
		var hh := int((310 + _hash(xl, i) * 30.0) * s)
		var p: Array = pal[(i + xl) % pal.size()]
		_rect(x, g - hh, hw, hh, p[0])
		_rect(x + hw - maxi(1, int(4 * s)), g - hh, maxi(1, int(4 * s)), hh, p[1])
		_triangle(x, g - hh, hw, int(hw * 0.45), p[0])
		var ww := maxi(2, int(22 * s))
		var wh := maxi(3, int(36 * s))
		for f in 4:
			var wy := g - int((GF - 18 + f * ST) * s) - wh
			for b in 3:
				var wx := x + int((b * hw) / 3.0) + (hw / 3 - ww) / 2
				_rect(wx, wy, ww, wh, T0)
				_rect(wx, wy, ww, 1, W4)
				if _hash(wx, wy) < 0.2:
					_rect(wx, wy + 1, ww, wh - 1, O2)
		x += hw
		i += 1


# --- Details per opening -----------------------------------------------------

func _steeg_details(x0: int, w: int, vx: float, vy: float, poort: bool) -> void:
	if poort:
		# Covered gateway: the house continues over the passage on a stone arch.
		_rect(x0, GY - 330, w, 230, T1)
		for yy in range(GY - 330, GY - 100):
			if yy % 4 == 3:
				_rect(x0, yy, w, 1, T0)
		var cx := x0 + w / 2
		for a in range(180, 361, 4):
			var p := Vector2(cx, GY - 100) + Vector2(cos(deg_to_rad(a)), sin(deg_to_rad(a))) * (w / 2.0)
			_rect(int(p.x) - 2, int(p.y) - 2, 4, 4, W3 if (a / 12) % 2 == 0 else W2)
		_bevel(cx - 3, GY - 100 - w / 2 - 4, 6, 8, W4, W5, W3)
		_rect(x0 + 4, GY - 160, w - 8, 12, T0)          # name board
		_rect(x0 + 5, GY - 159, w - 10, 10, W4)
		_text3(x0 + 7, GY - 157, "POORT", T0)
		_lantern(cx - 3, GY - 96)
		return
	# Laundry line, a lit lantern on a bracket, a bin, a cat on the step.
	_line(x0, GY - 210, x0 + w, GY - 214, T0)
	for k in range(x0 + 3, x0 + w - 4, 6):
		_rect(k, GY - 211 + (k - x0) / 8, 4, 7, [W4, B2, T3, O2][(k / 6) % 4])
	_rect(x0 + w - 8, GY - 150, 8, 2, T0)
	_rect(x0 + w - 12, GY - 148, 6, 9, T0)
	_rect(x0 + w - 11, GY - 147, 4, 7, O3)
	for r in 3:                                      # glow
		for yy in range(GY - 160, GY - 130):
			for xx in range(x0, x0 + w):
				if Vector2(xx - (x0 + w - 9), yy - (GY - 143)).length() < 8 + r * 5 and _bayer(xx, yy) < 0.25 - r * 0.08:
					_px(xx, yy, O2)
	_rect(x0 + 3, GY - 14, 8, 12, G0)
	_rect(x0 + 3, GY - 15, 8, 2, G1)
	_cat(x0 + w - 14, GY - 1)


func _alley_details(x0: int, w: int, vx: float, vy: float) -> void:
	_line(x0, GY - 220, x0 + w, GY - 226, T0)
	var cx := x0 + w / 2
	_rect(cx - 4, GY - 224, 8, 10, T0)
	_rect(cx - 3, GY - 216, 6, 5, W4)
	_triangle(cx - 5, GY - 223, 10, 4, T0)
	# Hanging sign on the right wall, planters, a bike against the wall.
	_rect(x0 + w - 18, GY - 130, 18, 2, T0)
	_rect(x0 + w - 18, GY - 128, 14, 12, W1)
	_rect(x0 + w - 17, GY - 127, 12, 10, O2)
	_rect(x0 + w - 14, GY - 124, 6, 4, W0)
	_rect(x0 + 2, GY - 12, 12, 12, B1)
	_rect(x0 + 2, GY - 12, 12, 2, B2)
	_leaves(x0 + 8, GY - 18, 7)
	_bike(x0 + w - 56, T2, false)


func _street_details(x0: int, w: int, vx: float, vy: float) -> void:
	# Trees on the left pavement, people, lamps and a church tower beyond.
	_tower(int(vx) - 6, int(vy + (GY - vy) * 0.34) - 60, T5, T6)
	for d in [2.4, 1.3, 0.55]:
		var s: float = 1.0 / (1.0 + d)
		var tx := int(vx + (-w * 0.38) * s)
		var tb := int(vy + (GY - vy) * s)
		_rect(tx - maxi(1, int(3 * s)), tb - int(90 * s), maxi(2, int(6 * s)), int(90 * s), W0)
		for c in [[0, -110, 26], [-18, -96, 18], [18, -98, 20], [0, -132, 18]]:
			_leaves(tx + int(c[0] * s), tb + int(c[1] * s), maxi(2, int(c[2] * s)))
	for p in [[1.8, 0.2, B2], [0.9, -0.15, T1], [0.5, 0.25, G1]]:
		var s := 1.0 / (1.0 + float(p[0]))
		var px_ := int(vx + w * float(p[1]) * s)
		var pb := int(vy + (GY - vy) * s)
		var ph := maxi(4, int(54 * s))
		_rect(px_, pb - ph, maxi(2, int(12 * s)), ph * 3 / 4, p[2])
		_rect(px_ + maxi(0, int(2 * s)), pb - ph - maxi(2, int(8 * s)), maxi(2, int(8 * s)), maxi(2, int(8 * s)), B4)
		_rect(px_, pb - ph / 4, maxi(1, int(4 * s)), ph / 4, T0)
		_rect(px_ + maxi(1, int(7 * s)), pb - ph / 4, maxi(1, int(4 * s)), ph / 4, T0)
	# Wires overhead.
	_line(x0, GY - 250, x0 + w, GY - 244, T0)
	_line(x0, GY - 236, int(vx), int(vy) - 40, T1)
	_line(x0 + w, GY - 236, int(vx), int(vy) - 40, T1)
	# Street name on the corner.
	_rect(x0 + 4, GY - 120, 34, 10, T0)
	_rect(x0 + 5, GY - 119, 32, 8, W5)
	_rect(x0 + 6, GY - 118, 30, 6, T2)
	_text3(x0 + 8, GY - 118, "SPIEG", W5)


func _canal_details(x0: int, w: int, vx: float, vy: float) -> void:
	# Trees on both banks, houseboats on the water, bikes on the railing.
	for side in [-1, 1]:
		for d in [2.6, 1.4, 0.7]:
			var s: float = 1.0 / (1.0 + d)
			var tx := int(vx + side * w * 0.36 * s)
			var tb := int(vy + (GY - vy) * s)
			_rect(tx - maxi(1, int(3 * s)), tb - int(100 * s), maxi(2, int(6 * s)), int(100 * s), W0)
			for c in [[0, -126, 30], [-22, -108, 22], [22, -110, 24], [0, -150, 20]]:
				_leaves(tx + int(c[0] * s), tb + int(c[1] * s), maxi(2, int(c[2] * s)))
	for b in [[1.6, -1], [0.8, 1]]:
		var s := 1.0 / (1.0 + float(b[0]))
		var bx := int(vx + int(b[1]) * w * 0.12 * s) - int(70 * s)
		var by := int(vy + (GY - vy) * s)
		var bw := int(140 * s)
		_rect(bx, by - int(6 * s), bw, maxi(2, int(10 * s)), G1)
		_rect(bx + int(10 * s), by - int(22 * s), bw - int(20 * s), int(16 * s), W4)
		_rect(bx + int(8 * s), by - int(24 * s), bw - int(16 * s), maxi(1, int(3 * s)), B1)
		for k in range(bx + int(16 * s), bx + bw - int(16 * s), maxi(3, int(16 * s))):
			_rect(k, by - int(18 * s), maxi(1, int(7 * s)), maxi(1, int(6 * s)), T0)


func _bridge_deck(x0: int, w: int) -> void:
	# Stone piers at both ends with lamps, an iron railing along the front.
	for px_ in [x0 - 4, x0 + w - 8]:
		_bevel(px_, GY + 6, 12, WATER - GY - 6, W3, W5, W2)
		_bevel(px_ - 2, GY + 2, 16, 6, W4, W5, W3)
		_rect(px_ + 5, GY - 80, 2, 82, T0)
		_rect(px_ + 4, GY - 80, 1, 82, T1)
		_rect(px_ + 1, GY - 100, 10, 18, T0)
		_rect(px_ + 2, GY - 99, 8, 15, W4)
		_rect(px_ + 2, GY - 99, 3, 15, W5)
		_triangle(px_, GY - 100, 12, 6, T0)
		_rect(px_ + 5, GY - 110, 2, 5, T0)
	var y0 := WATER - 28
	_rect(x0 + 8, y0, w - 16, 2, T0)
	_rect(x0 + 8, y0 + 1, w - 16, 1, R1)
	_rect(x0 + 8, WATER - 9, w - 16, 2, T0)
	for k in range(x0 + 10, x0 + w - 10, 5):
		_rect(k, y0 + 2, 1, 17, T0)
		if (k - x0) % 20 < 5:
			WDisc.ring(self, k + 2, y0 + 10, 2, T0)


func _bridge_arch(x0: int, w: int) -> void:
	var top := WATER - 8
	var spring := WATER + 46
	var cx := x0 + w / 2
	var rx := w * 0.4
	var ry := 44.0
	# Brick spandrel.
	for yy in range(top, spring + 10):
		for xx in range(x0, x0 + w):
			var c := B1 if ((xx + (yy / 3 % 2) * 4) % 8 != 0 and yy % 3 != 2) else B0
			var e := pow((xx - cx) / rx, 2.0) + pow((yy - spring) / ry, 2.0)
			if yy <= spring and e < 1.0:
				c = T0 if yy < spring - 8 else T1
				if yy > spring - 4 and _hash(xx / 3, yy) < 0.3:
					c = T2
			elif e < 1.25 and yy <= spring:
				var ang := atan2(yy - spring, (xx - cx) / rx * ry)
				c = W3 if int(ang * 10.0) % 2 == 0 else W4
			_px(xx, yy, c)
	_bevel(cx - 4, spring - int(ry) - 10, 8, 10, W4, W5, W3)
	_rect(x0, top, w, 3, W3)
	_rect(x0, top, w, 1, W5)
	for yy in range(spring + 2, spring + 10):          # waterline algae
		for xx in range(x0, x0 + w):
			if _bayer(xx, yy) < 0.5:
				_px(xx, yy, G0)
