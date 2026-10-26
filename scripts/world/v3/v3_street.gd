@tool
class_name StreetPainter
extends V3Painter
## The town street in the style v3 look, painted along its whole length (no
## repeating tile) and changing with the district:
##   OLD  (old town, canal belt): bluestone and sandstone slabs on the pavement,
##        a granite kerb, kinderkopjes (small rounded cobbles) with brown and
##        mossy stones, patches of newer setts, drain grates, manholes and the
##        odd puddle; a stone-capped brick quay with mooring rings, drain
##        spouts and stone steps down to the water.
##   NEW  (hotels, park, flats, industry, storage): red-brown klinkers in a
##        herringbone (concrete tiles by the industry), a concrete kerb, a red
##        asphalt bike lane with a white edge line and bike symbols, then grey
##        asphalt with cracks and patches; a concrete cap on steel sheet piling.
## Across a side canal the road becomes the bridge deck (brick herringbone with
## granite edges); at a side street the kerb drops and a granite band crosses
## the pavement. Districts blend over a few stones, never with a hard cut.
## Rows (art px below the street line): 0-9 pavement, 10-13 kerb, 14-35 road,
## 36-43 quay cap, 44-71 quay wall to the waterline.

enum Kind { OLD, NEW, INDUSTRY }

const PAVE := 10
const KERB := 14
const ROAD_END := 36
const BLEND := 90                           ## art px over which two districts mix

var zones: Array = []                       # [x0, x1, Kind] in art px
var spans: Array = []                       # [x0, x1] road over a side canal (bridge decks)
var mouths: Array = []                      # [x0, x1] side street / alley mouths


## One stretch [x0, x0 + w) of the town street (art px).
static func street_segment(x0: int, w: int, zone_list: Array, bridge_list: Array, mouth_list: Array) -> V3Art:
	var p = load("res://scripts/world/v3/v3_street.gd").new()
	p.OX = x0
	p.W = w
	p.H = WL + 2
	p.img = Image.create(p.W, p.H, false, Image.FORMAT_RGBA8)
	p.zones = zone_list
	p.spans = bridge_list
	p.mouths = mouth_list
	p._paint()
	var art := V3Art.new()
	art.png = p.img.get_region(Rect2i(0, GY, p.W, WL + 2 - GY)).save_png_to_buffer()
	art.origin = Vector2i(0, 0)
	return art


## The district at art x, with a dithered blend near the edges.
func _kind(x: int, y: int) -> int:
	var k := Kind.NEW
	for z: Array in zones:
		if x >= int(z[0]) and x < int(z[1]):
			k = z[2]
	for z: Array in zones:                  # near a district edge: mix per stone
		for e: int in [int(z[0]), int(z[1])]:
			var d := x - e
			if absi(d) < BLEND:
				var other := _kind_raw(x - signi(d) * BLEND)
				if other != k and _hash(x / 6, y / 4 + 911) > 0.5 + float(absi(d)) / BLEND * 0.5:
					return other
	return k


func _kind_raw(x: int) -> int:
	for z: Array in zones:
		if x >= int(z[0]) and x < int(z[1]):
			return z[2]
	return Kind.NEW


func _in(list: Array, x: int, grow := 0) -> bool:
	for r: Array in list:
		if x >= int(r[0]) - grow and x < int(r[1]) + grow:
			return true
	return false


func _paint() -> void:
	for x in range(OX, OX + W):
		var on_bridge := _in(spans, x)
		var mouth := _in(mouths, x)
		for ry in range(0, WL + 2 - GY):
			var y := GY + ry
			var k := _kind(x, ry)
			var c: Color
			if ry < PAVE:
				c = _granite_band(x, ry) if mouth and ry >= 2 else _pavement(x, ry, k)
			elif ry < KERB:
				c = _kerb(x, ry, k, mouth)
			elif ry < ROAD_END:
				c = _deck(x, ry) if on_bridge else _road(x, ry, k)
			elif ry < ROAD_END + 8:
				c = _cap(x, ry - ROAD_END, _kind_raw(x))
			else:
				c = _quay_px(x, ry - ROAD_END - 8, _kind_raw(x))
			_put_px(x, y, c)
	_details()
	_rect(OX, GY, W, 1, T0)                  # the facades' foot


# --- Surfaces --------------------------------------------------------------

func _pavement(x: int, ry: int, k: int) -> Color:
	match k:
		Kind.OLD:                            # slabs of varying width, two rows, sandstone among bluestone
			var row := ry / 5
			var sx := x + row * 9
			var w := 14 + int(_hash(sx / 18, row + 3) * 12.0)
			var j := posmod(sx, w)
			var id := _hash(sx / w, row * 7 + 1)
			var base := R2 if id < 0.6 else (W3 if id < 0.8 else R3)
			if ry % 5 == 4 or j == 0:
				return R1
			if ry % 5 == 0 and j < w - 2:
				return base.lerp(W5, 0.0) if base == R3 else (R3 if base == R2 else W4)
			if id > 0.93 and j == w / 2 and ry % 5 == 2:
				return R1                    # a crack
			return base
		Kind.INDUSTRY:                       # big grey concrete tiles
			var j := posmod(x, 20)
			if ry == 4 or ry == 9 or j == 0:
				return R1
			return R3 if _hash(x / 20, ry / 5) < 0.7 else R2
		_:                                   # red klinkers, herringbone
			return _herring(x, ry, B1, W1, B0, B2)


func _herring(x: int, ry: int, a: Color, b: Color, joint: Color, hi: Color) -> Color:
	var cell := posmod(x + ry * 2, 8)
	var band := (posmod(x, 16) < 8) == (ry % 4 < 2)
	var edge := (cell == 0) if band else (ry % 2 == 1)
	if edge:
		return joint
	var id := _hash((x + ry * 2) / 8, ry / 2)
	var c := a if id < 0.55 else b
	if id > 0.9:
		c = hi
	return c


func _kerb(x: int, ry: int, k: int, mouth: bool) -> Color:
	if mouth:                                # lowered kerb: a flat granite strip
		return R2 if ry < 13 else R1
	if k == Kind.OLD:
		var w := 30 + int(_hash(x / 40, 77) * 20.0)
		if posmod(x, w) == 0:
			return R1
		return [R3, R3, R2, T0][ry - PAVE]
	if posmod(x, 24) == 0:
		return R2
	return [W4, R3, R2, T0][ry - PAVE]


func _road(x: int, ry: int, k: int) -> Color:
	var r := ry - KERB
	if k == Kind.OLD:
		# Patches of newer square setts here and there (relaid after works).
		var patch := _hash(x / 140, 5) > 0.82 and posmod(x, 140) > 20 and posmod(x, 140) < 110
		if patch:
			var j := posmod(x + (r / 4 % 2) * 3, 6)
			return R1 if r % 4 == 3 or j == 0 else (R2 if _hash(x / 6, r / 4) < 0.7 else R3)
		# Kinderkopjes: rows of small rounded stones of varying width; light
		# on the top, shadow below, the corners rounded off by the gaps.
		var row := r / 4
		var sx := x + row * 3
		var w := 4 + int(_hash(sx / 6, row) * 3.0)
		var j := posmod(sx, w)
		var id := _hash(sx / w, row + 50)
		var c := R1 if id < 0.5 else R2
		if id < 0.1:
			c = W1                           # a brown stone
		elif id > 0.96:
			c = W2
		elif id > 0.9:
			c = T1                           # a bluish one
		var ly := r % 4
		if ly == 3 or j == 0:                # the gaps
			return G0 if _hash(x, r + 300) < 0.05 else R0
		if (ly == 0 or ly == 2) and (j == 1 or j == w - 1):
			return R0                        # rounded corners
		if ly == 0:
			return R3 if c == R2 else (R2 if c == R1 else c.lightened(0.15))
		if ly == 2:
			return R0 if c == R1 else (R1 if c == R2 else c.darkened(0.2))
		return c
	# NEW / INDUSTRY: a red bike lane, then asphalt.
	if r < 6 and k == Kind.NEW:
		var c := B1
		var s := _hash(x, r + 20)
		if s < 0.12:
			c = B0
		elif s > 0.94:
			c = B2
		return c
	if r == 6 and k == Kind.NEW:
		return W5 if posmod(x, 14) < 8 else R0      # dashed edge line
	var a := R0
	var n := _hash(x, r + 40)
	if n < 0.1:
		a = T0
	elif n > 0.92:
		a = R1
	# Worn tyre tracks a shade lighter, cracks and dark patches.
	if r >= 15 and r <= 17 and _hash(x / 30, 61) > 0.3:
		a = R1 if n > 0.5 else a
	if _hash(x / 220, 9) > 0.8 and posmod(x, 220) < 60 and r > 8:
		a = T0 if n < 0.6 else R0
	return a


func _deck(x: int, ry: int) -> Color:
	var r := ry - KERB
	if r < 2 or r > 19:
		return R3 if r < 2 or r > 20 else R2           # granite edges
	return _herring(x, ry, B1, B2, B0, B3)


func _cap(x: int, cy: int, k: int) -> Color:
	if k == Kind.OLD:                        # bluestone caps of varying length
		var w := 20 + int(_hash(x / 26, 12) * 10.0)
		var j := posmod(x, w)
		if cy >= 6:
			return T0
		if j == 0:
			return R1
		if cy == 0:
			return R3
		return R2 if cy < 5 else R1
	if cy >= 6:
		return T0
	if posmod(x, 48) == 0:
		return R2
	return W4 if cy == 0 else (R3 if cy < 5 else R2)   # concrete


func _quay_px(x: int, wy: int, k: int) -> Color:
	var h := WL + 2 - GY - ROAD_END - 8
	if k == Kind.OLD:                        # brick, damp and algae towards the water
		var course := wy / 4
		var j := posmod(x + (course % 2) * 4, 8)
		var c := B1
		if wy % 4 == 3 or j == 0:
			c = B0
		elif _hash(x / 8, course + 70) < 0.12:
			c = W1
		if wy > h - 10 and _bayer(x, wy) < float(wy - (h - 10)) / 10.0:
			c = G0 if _hash(x / 3, wy) < 0.5 else T1
		return c
	# Steel sheet piling: corrugated, rust near the top, algae at the water.
	var cx := posmod(x, 12)
	var c := T1
	if cx < 2:
		c = T0
	elif cx < 4:
		c = R1
	elif cx >= 8 and cx < 10:
		c = T0
	if wy < 6 and _hash(x / 2, wy) < 0.25:
		c = B0 if _hash(x, wy + 9) < 0.5 else W1
	if wy > h - 8 and _bayer(x, wy) < float(wy - (h - 8)) / 8.0:
		c = G0
	return c


func _granite_band(x: int, ry: int) -> Color:
	var j := posmod(x + (ry / 4 % 2) * 4, 8)
	return R1 if ry % 4 == 3 or j == 0 else (R2 if _hash(x / 8, ry / 4 + 5) < 0.6 else R3)


# --- Details ---------------------------------------------------------------

func _details() -> void:
	var start := OX - posmod(OX, 64)
	for gx in range(start, OX + W, 64):
		var h := _hash(gx / 64, 444)
		if _in(spans, gx, 40) or _in(mouths, gx, 12):
			continue
		var k := _kind_raw(gx)
		var road_y := GY + KERB
		if h < 0.12:                         # a drain grate by the kerb
			_rect(gx, road_y, 14, 3, T0)
			for d in range(gx + 1, gx + 14, 3):
				_rect(d, road_y, 1, 3, R2)
		elif h < 0.18:                       # a round manhole
			var cy := road_y + 12
			WDisc.draw(self, gx + 6, cy, 5, R0)
			WDisc.ring(self, gx + 6, cy, 5, T0)
			for d: int in [-2, 0, 2]:
				_px(gx + 6 + d, cy, R2)
				_px(gx + 6 + d, cy - 2, R2)
		elif h < 0.22 and k == Kind.OLD:     # a puddle with sky in it
			for dy in 3:
				var half: int = [5, 8, 5][dy]
				_rect(gx + 8 - half, road_y + 15 + dy, half * 2, 1, T3 if dy != 1 else T4)
		elif h < 0.27 and k == Kind.NEW:     # a bike symbol on the red lane
			var by := road_y + 1
			WDisc.ring(self, gx + 2, by + 3, 2, W5)
			WDisc.ring(self, gx + 9, by + 3, 2, W5)
			_line(gx + 2, by + 3, gx + 5, by + 1, W5)
			_line(gx + 5, by + 1, gx + 9, by + 3, W5)
		elif h < 0.3 and k == Kind.OLD:      # fallen leaves
			for i in 5:
				_px(gx + int(_hash(gx, i) * 20.0), road_y + int(_hash(i, gx) * 20.0), O1 if i % 2 else B2)
	# The quay: mooring rings, drain spouts, stone steps down to the water.
	var cap_y := GY + ROAD_END
	for mx in range(OX - posmod(OX, 120), OX + W, 120):
		if _in(spans, mx, 30):
			continue
		var k := _kind_raw(mx)
		var h := _hash(mx / 120, 55)
		if k == Kind.OLD and h < 0.35:
			WDisc.ring(self, mx, cap_y + 14, 3, T0)
			_rect(mx - 1, cap_y + 9, 3, 3, R1)
		elif h > 0.85:                       # a drain spout with a dark streak
			_rect(mx, cap_y + 12, 4, 3, T0)
			for d in range(15, 26):
				if _hash(mx, d) < 0.7:
					_px(mx + 1 + int(_hash(d, mx) * 2.0), cap_y + d, G0)
		elif k == Kind.OLD and h > 0.78 and not _in(spans, mx, 90):
			_steps(mx, cap_y)
	# A stone pier where the old brick quay meets the sheet piling.
	for z: Array in zones:
		for e: int in [int(z[0]), int(z[1])]:
			if e < OX - 12 or e > OX + W + 12 or _kind_raw(e - 1) == _kind_raw(e):
				continue
			_bevel(e - 6, cap_y - 2, 12, WL + 2 - cap_y + 2, R2, R3, R1)
			_rect(e - 7, cap_y - 3, 14, 3, R3)
			_rect(e - 7, cap_y - 3, 14, 1, W4)
	# Bridge abutments: sandstone blocks from the road edge down into the
	# water on both sides of the span, a foot stone at the waterline.
	for b: Array in spans:
		for side in [-1, 1]:
			var ax: int = int(b[0]) - 14 if side < 0 else int(b[1]) + 2
			var yy := cap_y - 1
			var course := 0
			while yy < WL + 2:
				var bw := 12 if course % 2 == 0 else 9
				var bx := ax if side < 0 else ax + 12 - bw
				_bevel(bx, yy, bw, 5, W3, W4, W2)
				yy += 5
				course += 1
			_rect(ax - 2, WL - 3, 16, 5, W2)
			_rect(ax - 2, WL - 3, 16, 1, W3)
			for k in range(0, 8):               # algae on the foot
				_px(ax - 2 + int(_hash(ax, k) * 16.0), WL + int(_hash(k, ax) * 2.0), G0)
	# Granite edges where the deck meets the street.
	for b: Array in spans:
		for ex: int in [int(b[0]), int(b[1]) - 2]:
			_rect(ex, GY + KERB, 2, ROAD_END - KERB, R3)


## Stone steps down the quay wall to the water (seen from the front).
func _steps(x: int, cap_y: int) -> void:
	var n := 7
	for i in n:
		var sy := cap_y + 8 + i * 4
		var sx := x + i * 5
		_rect(sx, sy, 34 - i * 2, 4, W3 if i % 2 == 0 else W2)
		_rect(sx, sy, 34 - i * 2, 1, W4)
		_rect(sx, sy + 3, 34 - i * 2, 1, W1)
	_rect(x - 2, cap_y, 2, 8, T0)             # a gap in the cap where the steps start
	_rect(x + 32, cap_y + 2, 1, 10, T0)       # iron handrail post
	_line(x + 32, cap_y + 2, x + 62, cap_y + 30, T0)
