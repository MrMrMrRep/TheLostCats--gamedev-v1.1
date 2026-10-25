@tool
class_name V3Painter
extends "res://scripts/world/v3/v3_alleys.gd"
## Paints world-map art in the style v3 look of the mocks (docs/art/style_v3_*),
## with the very same drawing code: v3_base.gd and v3_zones.gd are made from
## tools/style_mock_v3.gd, tools/style_mock_v3_zones.gd and
## tools/style_mock_v3_alleys.gd (v3_alleys.gd) by
## tools/port_v3_painter.py (change the mocks, then run that script).
## Coordinates are the mocks': art px, the street line (the band's feet) at
## y = GY. Each piece paints on its own canvas and comes out as a V3Art.
## The world nodes (CityBlock, WorldBuilding, CarArt...) ask V3Cache for their
## art, which calls the static painters below the first time.

const CANVAS_BOTTOM := GY + 16              # canvases end a little below the street line

const CANAL_SCHEMES := ["brick", "teal", "cream", "coral", "mustard", "teal", "brick", "cream", "slate", "tealdark", "darkbrick", "coral", "plum", "mustard"]
const OLD_SCHEMES := ["brick", "cream", "brick", "mustard", "coral", "teal", "darkbrick", "cream", "slate"]
const RING_SCHEMES := ["brick", "cream", "teal", "darkbrick", "coral", "brick"]
const FASCIAS := [T1, G0, G1, B0]
const AWNINGS := [[B2, W5], [T2, W5], [G1, W4], [T3, W5], [B1, W4], [O1, W5]]


# --- Canvas ------------------------------------------------------------------

## A fresh transparent canvas covering art x [x0, x0 + width), y [0, CANVAS_BOTTOM).
func begin(x0: int, width: int) -> void:
	OX = x0
	W = maxi(width, 1)
	H = CANVAS_BOTTOM
	img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	windows.clear()
	rng.seed = 5


## The painted canvas, cropped to what was drawn, with `anchor_x` (art px)
## as the node's origin (on the street line).
func finish(anchor_x: int) -> V3Art:
	var art := V3Art.new()
	var used := img.get_used_rect()
	if used.size.x <= 0 or used.size.y <= 0:
		return art
	art.png = img.get_region(used).save_png_to_buffer()
	art.origin = Vector2i(OX + used.position.x - anchor_x, used.position.y - GY)
	for w: Array in windows:
		var r: Rect2i = w[0]
		art.windows.append([Rect2i(r.position.x - anchor_x, r.position.y - GY, r.size.x, r.size.y), w[1]])
	return art


## Where a piece is painted along the mocks' x axis: far apart per seed, so
## position-based detail (hash patterns, window contents) differs per piece
## but stays the same when the node is moved.
static func base_x(seed_value: int) -> int:
	return posmod(seed_value * 7919, 4096) * 64


# --- Canal / old-town / ring houses (CityBlock) -------------------------------

## A CityBlock: `rows` = its layout() (w in world px, upper storeys, shop...),
## `style` 0 canal, 1 old town, 2 ring. The house in the middle gets
## `sign_text` and a central door (the WorldDoor sits there).
static func city_block(rows: Array, style: int, sign_text: String, shop_signs: PackedStringArray, seed_value: int) -> V3Art:
	var p := V3Painter.new()
	var total := 0
	for d: Dictionary in rows:
		total += int(d.w) * 2
	var bx := base_x(seed_value + style * 101)
	p.begin(bx - 64, total + 128)
	p._block(bx, rows, style, sign_text, shop_signs, seed_value)
	return p.finish(bx)


## The round hotel tower: a shaded cylinder with porthole windows (squashed
## toward the edges), a dark glass crown under a white sign ring, a lobby.
func _round_hotel(x: int, w: int, sign: String) -> void:
	var top := GY - 472
	var body_top := top + 52
	var body_bot := GY - 50
	var ramp := [T2, T3, T4, T5, T6]
	var down := {T6: T5, T5: T4, T4: T3, T3: T2, T2: T1, T1: T0}
	for xx in range(x, x + w):
		var u := (xx - x + 0.5) / w
		var l := 1.0 - pow(absf(u - 0.35) * 1.6, 2.0)
		var c: Color = ramp[clampi(int(l * 4.6), 0, 4)]
		_rect(xx, body_top, 1, body_bot - body_top, c)
		for fy in range(body_top + 22, body_bot, 26):        # floor lines
			_px(xx, fy, down[c])
	_rect(x - 1, body_top, 1, body_bot - body_top, T0)
	_rect(x + w, body_top, 1, body_bot - body_top, T0)
	# Portholes in rows, squashed toward the edges of the cylinder.
	var row := 0
	for fy in range(body_top + 4, body_bot - 22, 26):
		for k in 9:
			var th := deg_to_rad(-78.0 + k * 19.5 + (9.75 if row % 2 else 0.0))
			if absf(th) > deg_to_rad(80.0):
				continue
			var cx := x + (0.5 + 0.5 * sin(th)) * w
			var rx := maxf(7.0 * cos(th), 1.0)
			var cy := fy + 9
			var lit := _hash(k + row * 9, x) < 0.18
			for yy in range(-8, 9):
				for xx in range(int(cx - rx - 1), int(cx + rx + 2)):
					var e := pow((xx - cx) / (rx + 1.0), 2.0) + pow(yy / 8.5, 2.0)
					if e > 1.0:
						continue
					var inner := pow((xx - cx) / maxf(rx - 1.0, 0.6), 2.0) + pow(yy / 6.5, 2.0)
					var c := W5 if (yy < 0 and xx < cx) else R3
					if inner <= 1.0:
						c = (O3 if yy < -2 else O2) if lit else (T0 if cos(th) < 0.35 else T1)
						if not lit and yy < -3 and xx < cx - rx * 0.2:
							c = T3
					_px(xx, cy + yy, c)
		row += 1
	# Crown: dark glass band with mullions, the white sign ring, a roof edge.
	_rect(x - 2, top + 20, w + 4, 32, T1)
	for xx in range(x, x + w, 6):
		_rect(xx, top + 22, 1, 28, R1)
	_rect(x - 2, top + 20, w + 4, 2, T2)
	_rect(x - 4, top, w + 8, 20, T7)
	_rect(x - 4, top + 18, w + 8, 2, T6)
	_rect(x - 5, top, 1, 20, T0)
	_rect(x + w + 4, top, 1, 20, T0)
	_rect(x - 4, top - 3, w + 8, 3, R3)
	_rect(x - 4, top - 3, w + 8, 1, W5)
	var tw := sign.length() * 6 - 1
	_text5(x + w / 2 - tw / 2, top + 6, sign, T1)
	# Lobby: a canopy, recessed glass on slim columns, the door.
	_rect(x + 4, body_bot, w - 8, GY - body_bot, R0)
	_rect(x + 8, body_bot + 10, w - 16, GY - body_bot - 10, T2)
	for i in 12:
		_px(x + 20 + i, GY - 6 - i * 3, T4)
	for cxx in range(x + 10, x + w - 8, 20):
		_rect(cxx, body_bot + 8, 3, GY - body_bot - 8, W3)
	_rect(x + w / 2 - 16, GY - 34, 32, 34, O2)
	_rect(x + w / 2 - 16, GY - 34, 32, 3, O3)
	_rect(x + w / 2, GY - 34, 1, 34, O1)
	_rect(x - 8, body_bot, w + 16, 6, W5)
	_rect(x - 8, body_bot + 6, w + 16, 2, R1)
	_topiary(x + 2, GY)
	_topiary(x + w - 2, GY)


## Polder scenery sprites (WorldScenery): "farm", "mill" (without sails, they
## turn in the game), "cow0" / "cow1" (Holstein / brown), "sheep", "poplar0..2",
## "tree0..2", "bigtree", "willow", "fields" (a tile of striped fields, 1024 px).
## Origin = the sprite's foot on the street line.
static func scenery(name: String) -> V3Art:
	var p := V3Painter.new()
	var bx := base_x(name.hash() % 3000 + 120)
	p.begin(bx - 260, 520)
	match name:
		"farm": p._farm(bx - 140, GY)
		"mill": p._windmill_body(bx, GY)
		"cow0": p._cow(bx - 20, GY, false)
		"cow1": p._cow(bx - 20, GY, true)
		"sheep": p._sheep(bx - 10, GY)
		"poplar0": p._poplar(bx, GY, 78)
		"poplar1": p._poplar(bx, GY, 90)
		"poplar2": p._poplar(bx, GY, 66)
		"tree0": p._tree_small(bx, GY, 0.8)
		"tree1": p._tree_small(bx, GY, 0.95)
		"tree2": p._tree_small(bx, GY, 0.7)
		"bigtree":                          # right in front of the camera: in shade
			p._tree(bx, 1.7)
			p._haze_all({G4: G2, G3: G1, G2: G1, G1: G0, G0: T0, W1: W0, W0: T0})
		"willow": p._willow(bx, GY)
		"treeh0", "treeh1", "treeh2":
			p._tree_small(bx, GY, [0.8, 0.95, 0.7][int(name.right(1))])
			p._haze_all({G4: T6, G3: T5, G2: T4, G1: T3, G0: T3, W0: T2, W1: T3})
		"jet": p._airliner(bx - 150, GY - 40, 300, 0.0, true)
		"jet_air": p._airliner(bx - 150, GY - 40, 300, 0.0, false)
		"fields":
			p.begin(bx, 1024)
			p._fields_tile(bx, 1024)
	return p.finish(bx)


## Recolours what's painted (distant, hazy copies of a sprite).
func _haze_all(m: Dictionary) -> void:
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a > 0.0 and m.has(c):
				img.set_pixel(x, y, m[c])


## The windmill without its sails (V3Painter's _windmill, sails cut off).
func _windmill_body(x: int, b: int) -> void:
	for yy in range(b - 34, b):
		for xx in range(x - 34, x + 34):
			var c := B1 if ((xx + (yy / 3 % 2) * 4) % 8 != 0 and yy % 3 != 2) else B0
			_px(xx, yy, c)
	_rect(x - 34, b - 34, 2, 34, B2)
	_rect(x - 8, b - 26, 16, 26, T0)
	_rect(x - 7, b - 25, 14, 25, G1)
	_rect(x - 7, b - 25, 14, 1, G2)
	var bh := 150
	for yy in bh:
		var half := 30 - yy * 14 / bh
		for xx in range(-half, half):
			var t := float(xx + half) / (half * 2)
			var c := R1
			if t < 0.25:
				c = R2
			elif t > 0.75:
				c = R0
			if (x + xx) % 3 == 0 and _hash(x + xx, (b - 34 - yy) / 3) < 0.6:
				c = R0 if c != R0 else T1
			_px(x + xx, b - 34 - yy, c)
		_px(x - half - 1, b - 34 - yy, T0)
		_px(x + half, b - 34 - yy, T0)
	for wy in [b - 90, b - 140]:
		_rect(x - 4, wy, 8, 10, W5)
		_rect(x - 3, wy + 1, 6, 8, T0)
	var sy := b - 70
	_rect(x - 50, sy, 100, 4, W0)
	_rect(x - 50, sy, 100, 1, W1)
	_rect(x - 50, sy - 12, 100, 2, W0)
	for k in range(x - 50, x + 51, 6):
		_rect(k, sy - 12, 1, 12, W0)
	for k in range(x - 46, x + 47, 14):
		_line(k, sy + 4, x + (k - x) / 3, b - 34, W0)
	var cy := b - 34 - bh
	for yy in 18:
		var half := 20 - yy / 2
		_rect(x - half, cy - yy, half * 2, 1, W1 if yy % 3 else W0)
		_px(x - half, cy - yy, W2)
	_rect(x - 20, cy, 40, 2, T0)
	_line(x + 4, cy - 4, x + 70, b - 2, W0)
	_line(x + 5, cy - 4, x + 71, b - 2, W0)
	WDisc.ring(self, x + 70, b - 8, 6, W0)


## Striped fields with crop rows and ditches, 80 art px deep, tileable across.
func _fields_tile(x0: int, w: int) -> void:
	var y := GY - 80
	var band := 3
	var i := 0
	var cols := [G3, G2, G4, G2, G3, G1, G2]
	while y < GY:
		_rect(x0, y, w, band, cols[i % cols.size()])
		for x in range(x0, x0 + w, 2):
			if _hash(x / 2 % (w / 2), y) < 0.2:
				_px(x, y + band / 2, [G1, G2, G3, G2, G4, G1, G1][i % 7])
		if i % 3 == 2:
			_rect(x0, y, w, 1, T4)
			for x in range(x0, x0 + w, 9):
				if _hash(x % w, y) < 0.3:
					_rect(x, y, 3, 1, T6)
		y += band
		band += 1
		i += 1


## Street furniture along one stretch (WorldStreetLife.plan()): elms, canal
## lamps, Amsterdammertjes, bikes in racks, benches, bins, planters, signs.
## Origin = the stretch's left end on the street line.
static func street_life(items: Array, length: float, seed_value: int) -> V3Art:
	var p := V3Painter.new()
	var bx := base_x(seed_value + 4211)
	p.begin(bx - 100, int(length) * 2 + 200)
	var r := RandomNumberGenerator.new()
	r.seed = seed_value * 7 + 1
	for it: Array in items:                 # trees behind everything else
		if it[0] == "tree":
			p._tree(bx + int(it[1]), float(it[2]))
	for it: Array in items:
		var x := bx + int(it[1])
		match it[0]:
			"lamp": p._lamp(x)
			"tall_lamp": p._motorway_lamp(x, GY + 4)
			"bollards":
				for k in int(it[2]):
					p._bollard(x + k * 16)
			"rack":
				p._rack(x)
				for k in int(it[2]):
					p._bike(x - 6 + k * 30, [T0, B1, T2, G1, W4][r.randi_range(0, 4)], r.randf() < 0.4)
			"bench": p._bench_v3(x)
			"bin": p._bin(x)
			"planter": p._planter_v3(x)
			"meter": p._meter_v3(x)
			"sign": p._sign_v3(x)
			"flags": p._flags(x)
	return p.finish(bx)


func _bench_v3(x: int) -> void:
	var b := GY + 8
	for k in [b - 30, b - 24]:                   # back rest
		_rect(x, k, 34, 4, W1)
		_rect(x, k, 34, 1, W2)
	_rect(x - 2, b - 15, 38, 4, W1)              # seat
	_rect(x - 2, b - 15, 38, 1, W2)
	_rect(x - 2, b - 12, 38, 1, W0)
	for lx in [x + 2, x + 30]:                   # cast-iron sides
		_rect(lx, b - 32, 2, 32, T0)
		_rect(lx - 2, b - 2, 6, 2, T0)
		_rect(lx - 2, b - 16, 6, 2, T0)


func _planter_v3(x: int) -> void:
	var b := GY + 8
	_rect(x, b - 16, 26, 16, W1)
	_rect(x, b - 16, 26, 2, W2)
	for k in range(x + 3, x + 24, 6):
		_rect(k, b - 13, 1, 13, W0)
	_leaves(x + 8, b - 22, 9)
	_leaves(x + 18, b - 24, 10)
	for i in 5:
		_rect(x + 4 + i * 4, b - 30 + (i % 2) * 3, 2, 2, [B3, O2, W5][i % 3])


func _meter_v3(x: int) -> void:
	var b := GY + 8
	_rect(x, b - 30, 3, 30, R1)
	_rect(x, b - 30, 1, 30, R2)
	_bevel(x - 4, b - 44, 11, 14, R2, R3, R0)
	_rect(x - 2, b - 41, 7, 4, T1)
	_rect(x - 1, b - 40, 2, 2, O3)


func _sign_v3(x: int) -> void:
	# A "no motor vehicles" sign on a pole (the canal streets are for bikes).
	var b := GY + 8
	_rect(x, b - 70, 3, 70, R2)
	_rect(x, b - 70, 1, 70, R3)
	WDisc.draw(self, x + 1, b - 78, 9, B2)
	WDisc.draw(self, x + 1, b - 78, 6, W5)
	_rect(x - 3, b - 80, 9, 3, T1)
	_rect(x - 6, b - 64, 15, 7, W5)
	_rect(x - 5, b - 63, 13, 5, T2)


## An opening in the house row (SideOpening): a side canal, a wide side
## street or an alley in perspective, with v3 houses filling the rest of the
## slot. Widths in world px; the origin is the slot's middle on the street line.
static func side_opening(kind: String, slot_w: float, open_w: float, seed_value: int, poort: bool) -> V3Art:
	var p := V3Painter.new()
	var tw := int(slot_w) * 2
	var ow := mini(int(open_w) * 2, tw)
	var bx := base_x(seed_value + 977)
	var x0 := bx - tw / 2
	p.begin(x0 - 8, tw + 16)
	var left := (tw - ow) / 2
	p._side_street(x0 + left, ow, kind, poort)
	var r := RandomNumberGenerator.new()
	r.seed = seed_value * 17 + 3
	p._flank_houses(r, x0, left)
	p._flank_houses(r, x0 + left + ow, tw - left - ow)
	return p.finish(bx)


## The bridge in front of a side canal: stone piers with lamps, the iron
## railing and the brick arch over the water (drawn over street and canal).
static func side_bridge(open_w: float, seed_value: int) -> V3Art:
	var p := V3Painter.new()
	var ow := int(open_w) * 2
	var bx := base_x(seed_value + 977)
	p.begin(bx - ow / 2 - 16, ow + 32)
	p.H = WATER + 64
	p.img = Image.create(p.W, p.H, false, Image.FORMAT_RGBA8)
	p._bridge_deck(bx - ow / 2, ow)
	p._bridge_arch(bx - ow / 2, ow)
	return p.finish(bx)


## Canal houses filling `w` art px from `x` (beside an opening).
func _flank_houses(r: RandomNumberGenerator, x: int, w: int) -> void:
	if w < 40:
		return
	var n := maxi(1, roundi(w / 130.0))
	var last := ""
	var shops := [["cafe", "CAFE"], ["bakker", "BAKKER"], ["bloem", "BLOEMEN"], ["boek", "BOEKEN"], ["vis", "VIS"], ["koffie", "KOFFIE"]]
	for i in n:
		var hw := w / n if i < n - 1 else w - (w / n) * (n - 1)
		var scheme: String = CANAL_SCHEMES[r.randi_range(0, CANAL_SCHEMES.size() - 1)]
		if scheme == last:
			scheme = CANAL_SCHEMES[(CANAL_SCHEMES.find(scheme) + 1) % CANAL_SCHEMES.size()]
		last = scheme
		var hs := {"x": x, "w": hw, "f": r.randi_range(3, 4), "s": scheme, "g": _pick_gable(r, 0)}
		if r.randf() < 0.5:
			var sh: Array = shops[r.randi_range(0, shops.size() - 1)]
			hs.gr = "shop"
			hs.shop = sh[0]
			hs.sign = sh[1]
			hs.fascia = FASCIAS[r.randi_range(0, FASCIAS.size() - 1)]
			if r.randf() < 0.55:
				hs.awn = AWNINGS[r.randi_range(0, AWNINGS.size() - 1)]
		else:
			hs.gr = "door"
			hs.no = str(r.randi_range(2, 480))
		hs.boxes = r.randf() < 0.3
		hs.pipe = r.randf() < 0.35
		_house(hs)
		x += hw


func _block(bx: int, rows: Array, style: int, sign_text: String, shop_signs: PackedStringArray, seed_value: int) -> void:
	var r := RandomNumberGenerator.new()
	r.seed = seed_value * 31 + 7
	var schemes: Array = [CANAL_SCHEMES, OLD_SCHEMES, RING_SCHEMES][clampi(style, 0, 2)]
	var last := ""
	var x := bx
	var mid := rows.size() / 2
	var furniture := []                     # pavement things go in front of all houses
	for i in rows.size():
		var d: Dictionary = rows[i]
		var w := int(d.w) * 2
		var floors := int(d.upper) + 1
		var scheme: String = schemes[r.randi_range(0, schemes.size() - 1)]
		if scheme == last:
			scheme = schemes[(schemes.find(scheme) + 1) % schemes.size()]
		last = scheme
		var signed := sign_text != "" and i == mid
		# Now and then a narrow alley (steeg) or a covered gateway next to the
		# house; its own dice, so the rest of the row keeps its look.
		var gap := 0
		var poort := false
		var rs := RandomNumberGenerator.new()
		rs.seed = seed_value * 97 + i * 13 + 5
		if style != 2 and not signed and i > 0 and i < rows.size() - 1 and w >= 116 and rs.randf() < 0.16:
			poort = rs.randf() < 0.35
			gap = 40 if poort else rs.randi_range(13, 18) * 2
			w -= gap
		var shop_name := ""
		if d.shop and not shop_signs.is_empty():
			shop_name = shop_signs[(i + seed_value) % shop_signs.size()]
		var kind := _shop_kind(shop_name) if d.shop else ""
		if style == 2 and not signed:
			_ring_block(x, w, floors, scheme, r.randf() < 0.6, shop_name if d.shop else "")
		else:
			var hs := {"x": x, "w": w, "f": floors, "s": scheme, "g": _pick_gable(r, style)}
			if signed:
				hs.gr = "shop"
				hs.sign = ""
				hs.shop = ""
			elif d.shop:
				hs.gr = "shop"
				hs.sign = shop_name
				hs.shop = kind
				hs.fascia = FASCIAS[r.randi_range(0, FASCIAS.size() - 1)]
				if r.randf() < 0.55:
					hs.awn = AWNINGS[r.randi_range(0, AWNINGS.size() - 1)]
			else:
				hs.gr = "door"
				hs.no = str(r.randi_range(2, 480))
				hs.plaque = r.randf() < 0.15
				hs.cat = r.randf() < 0.08
			hs.boxes = r.randf() < 0.3
			hs.pipe = r.randf() < 0.35
			hs.lace = r.randf() < 0.15
			hs.quoins = scheme == "cream" and r.randf() < 0.5
			if r.randf() < 0.2 and w >= 112:
				hs.shutters = [[G1, W5], [B1, W5], [T1, W4]][r.randi_range(0, 2)]
			if i == 0 and r.randf() < 0.35:
				hs.street = ["PRINSENGRACHT", "HERENGRACHT", "KEIZERSGRACHT", "SPIEGELSTRAAT", "RUNSTRAAT"][seed_value % 5]
			_house(hs)
			if signed:
				_signed_front(x, w, sign_text)
		# Pavement: café terraces, A-boards, flower buckets, bikes, bins.
		if d.shop and not signed:
			match kind:
				"cafe", "koffie":
					if w >= 100:
						furniture.append(["terrace", x + 10])
					else:
						furniture.append(["aboard", x + w - 22])
				"bloem":
					furniture.append(["buckets", x + 8])
				"boek":
					furniture.append(["books", x + 12])
				_:
					if r.randf() < 0.5:
						furniture.append(["aboard", x + w - 24])
		elif not signed and r.randf() < 0.22:
			furniture.append(["bike", x + w - 62])
		if r.randf() < 0.1:
			furniture.append(["bin", x + w - 18])
		x += w
		if gap > 0:
			_side_street(x, gap, "steeg", poort)
			x += gap
	for f: Array in furniture:
		match f[0]:
			"terrace": _terrace(f[1])
			"aboard": _aboard(f[1], "CA")
			"buckets": _buckets(f[1])
			"books": _book_stand(f[1])
			"bike": _bike(f[1], [T0, B1, T2, G1][r.randi_range(0, 3)], r.randf() < 0.5)
			"bin": _bin(f[1])


func _pick_gable(r: RandomNumberGenerator, style: int) -> String:
	var v := r.randf()
	if style == 1:
		return "step" if v < 0.35 else ("spout" if v < 0.7 else ("neck" if v < 0.85 else "bell"))
	return "step" if v < 0.22 else ("neck" if v < 0.46 else ("bell" if v < 0.68 else ("spout" if v < 0.86 else "mansard")))


## Shop name -> the kind of window display the mock painter knows.
func _shop_kind(name: String) -> String:
	var n := name.to_upper()
	if n.contains("KOFFIE"):
		return "koffie"
	if n.contains("CAFE") or n.contains("BAR") or n.contains("PROEF") or n.contains("SNACK") or n.contains("TABAK"):
		return "cafe"
	if n.contains("BAKKER"):
		return "bakker"
	if n.contains("BLOEM"):
		return "bloem"
	if n.contains("KAAS"):
		return "kaas"
	if n.contains("VIS"):
		return "vis"
	return "boek"


## The studio / Café De Kat ground floor: a long name board and a central
## double door (the WorldDoor is in the middle of the house).
func _signed_front(x: int, w: int, text: String) -> void:
	var cafe := text.to_upper().contains("CAFE")
	var fc: Color = B0 if cafe else T1
	var fhi: Color = B1 if cafe else T2
	var top := GY - GF + 4
	_rect(x + 2, top, w - 4, GF - 4, fc)
	_rect(x + 2, top, w - 4, 1, fhi)
	# Name board, gilded letters.
	_rect(x + 4, top + 3, w - 8, 20, T0)
	_rect(x + 5, top + 4, w - 10, 18, fc)
	_rect(x + 5, top + 4, w - 10, 1, fhi)
	var name := text.to_upper()
	var tw := name.length() * 6 - 1
	_text5(x + w / 2 - tw / 2 + 1, top + 10, name, T0)
	_text5(x + w / 2 - tw / 2, top + 9, name, O2)
	_text5_top(x + w / 2 - tw / 2, top + 9, name, O3)
	# Double door in the middle.
	var dw := 40
	var dx := x + w / 2 - dw / 2
	var wy := top + 28
	_rect(dx - 2, wy - 2, dw + 4, GY - wy + 2, T0)
	for leaf in 2:
		var lx := dx + leaf * (dw / 2)
		_rect(lx, wy, dw / 2 - 1, GY - wy - 2, fc)
		_rect(lx, wy, 1, GY - wy - 2, fhi)
		_rect(lx + 3, wy + 3, dw / 2 - 7, 30, T0)
		_rect(lx + 3, wy + 3, dw / 2 - 7, 2, T1)
		for k in 8:
			_px(lx + 5 + k, wy + 26 - k * 3, T2)
		_rect(lx + 3, wy + 38, dw / 2 - 7, 10, fc)
		_rect(lx + 4, wy + 39, dw / 2 - 9, 8, fhi)
		_rect(lx + (dw / 2 - 5 if leaf == 0 else 2), wy + 30, 2, 6, O2)
	# Display windows either side.
	var lw := dx - 6 - (x + 8)
	var rw := x + w - 8 - (dx + dw + 6)
	if lw > 10:
		_rect(x + 7, wy - 1, lw + 2, GY - 12 - wy + 2, T0)
		_shop_window(x + 8, wy, lw, GY - 12 - wy, "cafe" if cafe else "")
	if rw > 10:
		_rect(dx + dw + 5, wy - 1, rw + 2, GY - 12 - wy + 2, T0)
		_shop_window(dx + dw + 6, wy, rw, GY - 12 - wy, "cafe" if cafe else "")
		if not cafe and rw > 26:
			_poster(dx + dw + 10, wy + 8, 18, 26, 1)
	_lantern(dx - 9, top + 30)
	_lantern(dx + dw + 3, top + 30)


# --- Big buildings (WorldBuilding) --------------------------------------------

## A WorldBuilding of `kind` (WorldBuilding.Kind), `width` world px wide.
static func building(kind: int, width: float, sign_text: String, seed_value: int) -> V3Art:
	var p := V3Painter.new()
	var w := int(width * 2.0)
	var bx := base_x(seed_value * 13 + kind * 977 + 3)
	p.begin(bx - 96, w + 192)
	p.rng.seed = seed_value + 11
	p._building(bx, w, kind, sign_text, seed_value)
	return p.finish(bx)


## What a building puts on the street in front of it (drawn after the street):
## the church's little square (herringbone bricks, a street pump, a bench).
static func building_front(kind: int, width: float, seed_value: int) -> V3Art:
	var p := V3Painter.new()
	var w := int(width * 2.0)
	var bx := base_x(seed_value * 13 + kind * 977 + 3)
	p.begin(bx - 8, w + 16)
	p.H = GY + 40
	p.img = Image.create(p.W, p.H, false, Image.FORMAT_RGBA8)
	if kind == 4:
		p._church_square(bx, bx + w)
		p._bench_v3(bx + w / 4 - 18)
		p._street_pump(bx + w * 3 / 4)
	return p.finish(bx)


func _building(x: int, w: int, kind: int, sign_text: String, seed_value: int) -> void:
	var up := sign_text.to_upper()
	match kind:
		0:                                  # MALL
			_new_block(x, w / 2)
			_ring_block(x + w / 2, w - w / 2, 3, "cream", false, up if up != "" else "WINKELCENTRUM")
			_lamp_modern(x + w / 2 - 6)
		1:                                  # GARAGE
			_car_park(x, w)
		2:                                  # SELF_STORAGE
			_self_storage(x, w)
		3:                                  # OUR_STORAGE: its car park (the gate stands in front), then the storage
			_car_park(x, 260)
			_band_storage(x + 260, w - 260)
		4:                                  # CHURCH: free-standing in its slot, a walled graveyard behind
			var cw := mini(w, 300)
			if w >= cw + 120:
				_graveyard(x, x + w)
			_church(x + (w - cw) / 2, cw)
		5:                                  # MARKET
			_church_square(x, x + w)
			var kinds := ["kaas", "bloem", "vis", "groente"]
			var cols := [[B2, W5], [G1, W4], [T2, W5], [O1, W5]]
			var sx := x + 14
			var k := 0
			while sx + 90 <= x + w - 10:
				_market_stall(sx, 90, cols[k % 4], kinds[k % 4])
				sx += 124
				k += 1
			_lamp(x + w - 8)
		6:                                  # PARK
			_park(x, w)
		7:                                  # THEATER
			sign_override = up if up != "" else ""
			_theatre(x + 16, w - 32)
			_poster_column(x + w - 6)
		8:                                  # HOTEL
			sign_override = up
			if up.contains("GRAND"):
				_grand_hotel(x, w)
				_flags(x + 20)
			elif up.contains("AIRPORT"):
				sign_override = "HOTEL DE KAT" if up == "AIRPORT HOTEL" else up
				_airport_hotel(x, w)
			elif up.contains("HOSTEL"):
				sign_override = ""
				_ring_block(x, w, 5, "teal", true, up)
			else:
				_hotel_70s(x, w)
		9:                                  # APARTMENTS
			match posmod(seed_value, 4):
				0:
					_ring_block(x, w / 2, 4, "brick", true, "")
					_ring_block(x + w / 2, w - w / 2, 4, "cream", true, "SUPERMARKT")
				1:
					_ring_block(x, w / 2, 5, "teal", false, "")
					_ring_block(x + w / 2, w - w / 2, 4, "darkbrick", true, "")
				2:
					_new_block(x, w)
				_:
					_ring_block(x, w / 2, 4, "coral", true, "")
					_ring_block(x + w / 2, w - w / 2, 4, "brick", true, "")
			for tx in [x + 40, x + w - 40]:
				_young_tree(tx)
		10:                                 # TERMINAL
			sign_override = "" if up == "" or up == "AIRPORT" else up
			_apron()
			_terminal2(x + 40, w - 80)
			# v3.1: an airliner at the gate in full view, a jet climbing out.
			_airliner(x + 300, 250, 300, 11.0, false)
			_jet_bridge(x + 640, x + 780)
			_airliner(x + 120, GY - 118, 560, 0.0, true)
			_tug(x + 900, GY - 32)
		11:                                 # TOWER
			_tower2(x + w / 2)
		12:                                 # ROUND_HOTEL
			_round_hotel(x, w, up if up != "" else "HOTEL")
		13:                                 # PETROL
			_service_station(x, w)
		_:
			pass


func _park(x: int, w: int) -> void:
	# Big trees behind a hedge and an iron fence, a bandstand, a gate with the name.
	var n := maxi(w / 170, 2)
	for i in n:
		_park_tree(x + 40 + i * (w - 80) / maxi(n - 1, 1), [1.1, 0.95, 1.15, 1.0, 0.9][i % 5])
	_bandstand(x + w / 2 - 80)
	_hedge(x, w, GY - 40)
	_park_fence(x, w)
	_park_gate(x + w / 2 + 120 if w > 600 else x + w - 120)
	for bx in [x + 90, x + w / 2 - 150, x + w - 220]:
		_bench(bx)
	_lamp(x + 150)
	_lamp(x + w - 40)


# --- Vehicles (CarArt, traffic) ------------------------------------------------

## A vehicle facing right, wheels on the street line; origin = its left end.
static func vehicle(kind: String, colour: String) -> V3Art:
	var p := V3Painter.new()
	var L := 260 if kind == "truck" else (int(p._vspec(kind)["L"]) if kind != "band_van" else 170)
	p.begin(-8, L + 24)
	match kind:
		"truck":
			p._truck(0, GY)
		"band_van":
			p._van(0, GY)
		_:
			p._vehicle(0, GY, kind, colour)
	return p.finish(0)


## Length in art px of a v3 vehicle kind.
static func vehicle_length(kind: String) -> int:
	match kind:
		"truck": return 244
		"band_van": return 170
		"hatch": return 124
		"sedan", "taxi", "police": return 138
		"wagon": return 142
		"coupe": return 132
		"mpv": return 134
		"duck": return 112
		"van": return 152
		"bus": return 330
	return 130


# --- Street (WorldStreet) -------------------------------------------------------

## A strip of the town street (pavement, kerb, cobbles, drains, quay) `width`
## art px wide (a multiple of 360, at least 1440), from the street line down
## to the water; it repeats along the town.
static func street_tile(width: int) -> V3Art:
	var p := V3Painter.new()
	p.OX = 0
	p.W = width
	p.H = WATER + 2
	p.img = Image.create(p.W, p.H, false, Image.FORMAT_RGBA8)
	p._street_strip()
	var art := V3Art.new()
	var region := p.img.get_region(Rect2i(0, GY, p.W, WATER - GY))
	art.png = region.save_png_to_buffer()
	art.origin = Vector2i(0, 0)
	return art


func _street_strip() -> void:
	# _street() without the drains (those go on per spot), then the quay.
	for y in range(GY, WATER - 8):
		for x in range(OX, OX + W):
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
				var id := _hash(posmod(x + (cy % 2) * 5, W) / 10, cy + 99)
				if id < 0.1 and c == R1:
					c = R0
				elif id > 0.93 and c == R1:
					c = R2
			_put_px(x, y, c)
	_rect(OX, GY, W, 1, T0)
	for gx in [180, 760, 1290]:                     # drain grates and a manhole cover
		_rect(gx, GY + 14, 16, 3, T0)
		for k in range(gx + 1, gx + 16, 3):
			_rect(k, GY + 14, 1, 3, R1)
	_rect(560, GY + 22, 30, 6, R0)
	_rect(562, GY + 23, 26, 4, T0)
	for k in range(563, 588, 4):
		_rect(k, GY + 24, 2, 2, R1)
	_quay()


# --- Palette filter lookup table (WorldPalette.snap_material) -------------------

## 1024 x 32 table: the nearest palette colour for every 5-bit RGB,
## at x = b * 32 + r, y = g.
static func palette_lut() -> V3Art:
	var img := Image.create(1024, 32, false, Image.FORMAT_RGBA8)
	var n := PALETTE.size()
	var dr := []
	var dg := []
	var db := []
	for v in 32:
		var a := []
		var b := []
		var c := []
		for p: Color in PALETTE:
			var t := v / 31.0
			a.append(pow((t - p.r) * 0.30, 2.0))
			b.append(pow((t - p.g) * 0.59, 2.0))
			c.append(pow((t - p.b) * 0.11, 2.0))
		dr.append(a)
		dg.append(b)
		db.append(c)
	for g in 32:
		var rg: Array = dg[g]
		for bl in 32:
			var rb: Array = db[bl]
			for r in 32:
				var rr: Array = dr[r]
				var best := 0
				var bd := INF
				for i in n:
					var d: float = rr[i] + rg[i] + rb[i]
					if d < bd:
						bd = d
						best = i
				img.set_pixel(bl * 32 + r, g, PALETTE[best])
	var art := V3Art.new()
	art.png = img.save_png_to_buffer()
	return art


# --- Sky sprites (WorldSky) -------------------------------------------------------

## The banded sun with its dithered halo; origin = its centre.
static func sun_sprite(r: int) -> V3Art:
	var p := V3Painter.new()
	p.begin(-r - 24, r * 2 + 48)
	p.H = GY + r + 24
	p.img = Image.create(p.W, p.H, false, Image.FORMAT_RGBA8)
	p._sun(0, GY, r)
	return p.finish(0)


## A shaded cloud (light from the top-left, flat dithered underside); origin =
## the middle of its base.
static func cloud_sprite(s: float) -> V3Art:
	var p := V3Painter.new()
	var half := int(40 * s) + 8
	p.begin(-half, half * 2)
	p._cloud(0, GY, s)
	return p.finish(0)
