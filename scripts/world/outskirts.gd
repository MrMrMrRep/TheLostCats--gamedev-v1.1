@tool
class_name WorldBuilding
extends Node2D
## Big buildings around town (procedural placeholder art, same palette as the
## canal houses). Origin = street level, left end; width() per kind.
##   MALL           shopping centre: flat roof, shop fronts with awnings, canopy
##   GARAGE         multi-storey car park: open floors with parked cars, big P
##   SELF_STORAGE   corrugated units with roll-up doors
##   OUR_STORAGE    the band's storage: its own car park on the left (the gate
##                  in front is a StorageGate node), warehouse with loading door
##   CHURCH         brick church with a tall tower and a clock
##   MARKET         market square: an open gap with stalls under striped awnings
##   PARK           an open gap with trees, a railing, benches, a fountain
##   THEATER        classical front: steps, columns, pediment, posters
##   HOTEL          tall hotel with a vertical sign, flags and a canopy
##   APARTMENTS     new apartment block: glass, coloured panels, balconies

enum Kind { MALL, GARAGE, SELF_STORAGE, OUR_STORAGE, CHURCH, MARKET, PARK, THEATER, HOTEL, APARTMENTS, TERMINAL, TOWER, ROUND_HOTEL }

const WIDTHS := {Kind.MALL: 320.0, Kind.GARAGE: 200.0, Kind.SELF_STORAGE: 260.0, Kind.OUR_STORAGE: 340.0,
	Kind.CHURCH: 150.0, Kind.MARKET: 260.0, Kind.PARK: 480.0, Kind.THEATER: 250.0, Kind.HOTEL: 170.0, Kind.APARTMENTS: 210.0,
	Kind.TERMINAL: 560.0, Kind.TOWER: 70.0, Kind.ROUND_HOTEL: 66.0}
const CONCRETE := Color("a7a3a8")
const CONCRETE_DARK := Color("7d7981")
const STEEL := Color("c9ccd2")
const SHOP_SIGNS := ["SUPER", "FIETS", "PIZZA", "DIER", "BOEK", "VERF"]
const CAR_COLOURS := [Color("c94a3d"), Color("5b7fa6"), Color("fbf8f2"), Color("2a2830"), Color("e0b23a"), Color("6f8f5a")]

@export var kind := Kind.MALL:
	set(value):
		kind = value
		queue_redraw()
@export var seed_value := 1:
	set(value):
		seed_value = value
		queue_redraw()
@export var sign_text := "":
	set(value):
		sign_text = value
		queue_redraw()


func width() -> float:
	return WIDTHS[kind]


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	match kind:
		Kind.MALL: _mall(rng)
		Kind.GARAGE: _garage(rng, 0.0, width(), 104.0, true)
		Kind.SELF_STORAGE: _self_storage(rng)
		Kind.OUR_STORAGE: _our_storage(rng)
		Kind.CHURCH: _church(rng)
		Kind.MARKET: _market(rng)
		Kind.PARK: _park(rng)
		Kind.THEATER: _theater(rng)
		Kind.HOTEL: _hotel(rng)
		Kind.APARTMENTS: _apartments(rng)
		Kind.TERMINAL: _terminal(rng)
		Kind.TOWER: _tower(rng)
		Kind.ROUND_HOTEL: _round_hotel(rng)


func _text(x: float, y: float, w: float, text: String, size: int, c: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_CENTER, w, size, c)


func _mall(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	var h := 104.0
	draw_rect(Rect2(0, -h, w, h), Color("d8cbb8"))
	draw_rect(Rect2(0, -h, w, 8), CONCRETE_DARK)                 # roof edge
	draw_rect(Rect2(w - 3, -h, 3, h), Color("b5a893"))
	# Tower with the centre's name.
	draw_rect(Rect2(w / 2 - 34, -h - 22, 68, 24), p.NAVY)
	_text(w / 2 - 34, -h - 7, 68, sign_text if sign_text != "" else "WINKELCENTRUM", 8, p.LIT)
	# Upper band of offices.
	for i in int(w / 18):
		draw_rect(Rect2(6 + i * 18, -h + 14, 12, 10), p.GLASS)
	# Canopy and shop fronts.
	draw_rect(Rect2(-4, -52, w + 8, 4), CONCRETE_DARK)
	var shops := 5
	var sw := w / shops
	for i in shops:
		var x := i * sw
		draw_rect(Rect2(x + 4, -46, sw - 8, 42), p.GLASS)
		draw_rect(Rect2(x + 4, -46, sw - 8, 1), p.TRIM)
		for k in 3:
			draw_rect(Rect2(x + 6 + k * (sw - 12) / 3.0, -42, 1, 38), p.GLASS.lightened(0.15))
		var sc: Color = [p.ORANGE, Color("c94a3d"), Color("5b7fa6"), Color("6f8f5a"), Color("e0b23a")][i % 5]
		draw_rect(Rect2(x + 8, -66, sw - 16, 12), sc)
		_text(x + 8, -57, sw - 16, SHOP_SIGNS[(i + seed_value) % SHOP_SIGNS.size()], 8, p.WHITE)
		draw_rect(Rect2(x + sw / 2 - 8, -34, 16, 34), p.GLASS.lightened(0.25))       # sliding doors
		draw_rect(Rect2(x + sw / 2, -34, 1, 34), p.TRIM)
	# Trolleys and a flag pole.
	for k in 3:
		draw_rect(Rect2(w - 30 + k * 5, -7, 4, 4), STEEL)
	draw_rect(Rect2(14, -h - 30, 1, 30), p.IRON)
	draw_rect(Rect2(15, -h - 30, 10, 6), p.ORANGE)


func _garage(rng: RandomNumberGenerator, x0: float, w: float, h: float, big_sign: bool) -> void:
	var p := WorldPalette
	draw_rect(Rect2(x0, -h, w, h), CONCRETE)
	var floors := 4
	var fh := h / floors
	for f in floors:
		var y := -h + f * fh
		draw_rect(Rect2(x0, y, w, 4), CONCRETE_DARK)                 # slab
		if f == floors - 1:
			break                                                # ground floor: entrance
		draw_rect(Rect2(x0 + 4, y + 4, w - 8, fh - 10), Color("2c2a33"))
		var cx := x0 + 8.0
		while cx < x0 + w - 26:
			if rng.randf() < 0.7:
				var c: Color = CAR_COLOURS[rng.randi_range(0, CAR_COLOURS.size() - 1)]
				draw_rect(Rect2(cx, y + fh - 14, 20, 6), c)
				draw_rect(Rect2(cx + 4, y + fh - 18, 11, 4), c.darkened(0.2))
				draw_rect(Rect2(cx + 3, y + fh - 8, 3, 2), p.IRON)
				draw_rect(Rect2(cx + 14, y + fh - 8, 3, 2), p.IRON)
			cx += 26
		draw_rect(Rect2(x0 + 4, y + fh - 8, w - 8, 2), STEEL)         # barrier rail
		for k in int(w / 40):
			draw_rect(Rect2(x0 + 20 + k * 40, y + 4, 3, fh - 6), CONCRETE)   # columns
	# Ground floor: entrance with a barrier arm.
	draw_rect(Rect2(x0 + 12, -fh + 6, 36, fh - 6), Color("2c2a33"))
	draw_rect(Rect2(x0 + 12, -14, 30, 2), Color("c94a3d"))
	draw_rect(Rect2(x0 + 10, -16, 3, 16), p.IRON)
	if big_sign:
		draw_rect(Rect2(x0 + w - 40, -h - 12, 28, 28), Color("2a5bd7"))
		_text(x0 + w - 40, -h + 10, 28, "P", 22, p.WHITE)
	else:
		draw_rect(Rect2(x0 + w - 22, -h + 8, 14, 14), Color("2a5bd7"))
		_text(x0 + w - 22, -h + 19, 14, "P", 10, p.WHITE)


func _roll_door(x: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, -h, w, h), c)
	for y in range(int(-h) + 2, 0, 3):
		draw_rect(Rect2(x, y, w, 1), c.darkened(0.2))
	draw_rect(Rect2(x - 1, -h - 2, w + 2, 2), CONCRETE_DARK)


func _self_storage(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	var h := 86.0
	draw_rect(Rect2(0, -h, w, h), p.ORANGE)
	for x in range(0, int(w), 4):                                # corrugation
		draw_rect(Rect2(x, -h, 1, h - 42), p.ORANGE.darkened(0.15))
	draw_rect(Rect2(0, -44, w, 44), p.WHITE)
	draw_rect(Rect2(0, -h, w, 4), CONCRETE_DARK)
	draw_rect(Rect2(10, -h + 8, 120, 14), p.WHITE)
	_text(10, -h + 19, 120, sign_text if sign_text != "" else "SELF STORAGE", 9, p.ORANGE.darkened(0.3))
	var doors := int((w - 10) / 42)
	for i in doors:
		_roll_door(8 + i * 42, 32, 36, STEEL if rng.randf() < 0.8 else Color("5b7fa6"))
		draw_string(ThemeDB.fallback_font, Vector2(18 + i * 42, -39), str(101 + i), HORIZONTAL_ALIGNMENT_LEFT, -1, 6, p.NAVY)


func _our_storage(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	# Left: the storage's own car park (two storeys), the gate stands in front.
	_garage(rng, 0.0, 130.0, 70.0, false)
	# Right: the warehouse.
	var x0 := 130.0
	var ww := w - x0
	var h := 96.0
	draw_rect(Rect2(x0, -h, ww, h), Color("3a3d48"))
	for x in range(int(x0), int(w), 5):
		draw_rect(Rect2(x, -h, 1, h), Color("33363f"))
	draw_rect(Rect2(x0, -h + 26, ww, 6), p.ORANGE)                 # band stripe
	draw_rect(Rect2(x0, -h, ww, 4), CONCRETE_DARK)
	draw_rect(Rect2(x0 + 20, -h + 8, ww - 40, 14), p.NAVY)
	_text(x0 + 20, -h + 19, ww - 40, sign_text if sign_text != "" else "STORAGE", 9, p.LIT)
	# Loading door, a side door, small high windows.
	_roll_door(x0 + 30, 60, 44, STEEL)
	draw_rect(Rect2(x0 + 104, -34, 17, 34), p.NAVY)
	draw_rect(Rect2(x0 + 117, -18, 2, 2), p.LIT)
	for k in 5:
		draw_rect(Rect2(x0 + 24 + k * 34, -h + 40, 14, 6), p.GLASS if k != 2 else p.LIT)
	# Camera and a lamp over the yard.
	draw_rect(Rect2(x0 + 4, -60, 6, 3), p.IRON)
	draw_rect(Rect2(x0 + 2, -62, 2, 6), p.IRON)
	draw_rect(Rect2(w - 14, -h - 18, 2, 18), p.IRON)
	draw_rect(Rect2(w - 20, -h - 20, 10, 3), p.LIT)


func _church(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var brick := Color("8c4a3a")
	var w := width()
	# Nave with a steep roof and tall arched windows.
	draw_rect(Rect2(0, -96, 104, 96), brick)
	WorldPalette.triangle(self, -4, -96, 112, 46, p.ROOF)
	for k in 4:
		var x := 10 + k * 24
		draw_rect(Rect2(x, -78, 10, 40), p.GLASS)
		WorldPalette.disc(self, x + 5, -78, 5, p.GLASS)
		draw_rect(Rect2(x + 4, -82, 2, 44), Color("c9a36a"))
	# Tower: square shaft, belfry, clock, spire with a weathercock.
	var tx := 104.0
	draw_rect(Rect2(tx, -150, 46, 150), brick.darkened(0.08))
	draw_rect(Rect2(tx, -150, 46, 3), p.TRIM)
	draw_rect(Rect2(tx + 10, -140, 8, 18), p.GLASS)
	draw_rect(Rect2(tx + 28, -140, 8, 18), p.GLASS)
	WorldPalette.disc(self, tx + 23, -100, 9, p.TRIM)
	WorldPalette.disc(self, tx + 23, -100, 7, p.WHITE)
	draw_line(Vector2(tx + 23, -100), Vector2(tx + 23, -106), p.IRON, 1.0)
	draw_line(Vector2(tx + 23, -100), Vector2(tx + 27, -100), p.IRON, 1.0)
	WorldPalette.triangle(self, tx + 2, -150, 42, 58, Color("3e5a5a"))   # copper spire
	draw_rect(Rect2(tx + 22, -218, 2, 12), p.IRON)
	draw_rect(Rect2(tx + 18, -220, 9, 2), Color("e0b23a"))
	# Big doors.
	draw_rect(Rect2(tx + 14, -30, 18, 30), Color("4a3426"))
	WorldPalette.disc(self, tx + 23, -30, 9, Color("4a3426"))
	draw_rect(Rect2(36, -24, 16, 24), Color("4a3426"))
	draw_rect(Rect2(0, -3, w, 3), brick.darkened(0.35))


func _market(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	# Square: paving in front, lamp posts, a sign, stalls with striped awnings.
	draw_rect(Rect2(0, -2, w, 2), p.COBBLE_DARK)
	var colours := [[p.ORANGE, p.WHITE], [Color("c94a3d"), p.WHITE], [Color("5b7fa6"), p.WHITE], [Color("6f8f5a"), Color("f2e8da")]]
	var goods := [Color("e0b23a"), Color("c94a3d"), Color("86b44f"), Color("f2e8da"), Color("e07a2e")]
	var x := 14.0
	var i := 0
	while x < w - 50:
		var sw := rng.randf_range(38, 50)
		var c: Array = colours[(i + seed_value) % colours.size()]
		draw_rect(Rect2(x, -34, 2, 34), p.IRON)
		draw_rect(Rect2(x + sw - 2, -34, 2, 34), p.IRON)
		for s in int(sw / 5):
			draw_rect(Rect2(x - 2 + s * 5, -40, 5, 7), c[s % 2])
		draw_rect(Rect2(x, -14, sw, 3), Color("8a6a4a"))                # counter
		draw_rect(Rect2(x, -11, sw, 11), Color("6b4f36"))
		for g in int(sw / 6):
			WorldPalette.disc(self, x + 4 + g * 6, -16, 2, goods[(g + i) % goods.size()])
		x += sw + rng.randf_range(10, 18)
		i += 1
	for lx in [6.0, w - 8.0]:
		draw_rect(Rect2(lx, -50, 2, 50), p.IRON)
		draw_rect(Rect2(lx - 3, -54, 8, 4), p.LIT)
	draw_rect(Rect2(w / 2 - 26, -64, 52, 12), p.NAVY)
	_text(w / 2 - 26, -55, 52, sign_text if sign_text != "" else "MARKT", 8, p.LIT)
	draw_rect(Rect2(w / 2 - 1, -52, 2, 12), p.IRON)


func _park(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	draw_rect(Rect2(0, -6, w, 6), p.GRASS[1])
	draw_rect(Rect2(0, -6, w, 1), p.GRASS[2])
	# Big trees at the back, then lamps, benches, a fountain, an iron railing.
	var x := 10.0
	while x < w - 10:
		WorldPalette.tree(self, x, -4, rng.randi_range(16, 24))
		x += rng.randf_range(40, 70)
	var fx := w * 0.55
	draw_rect(Rect2(fx - 22, -10, 44, 8), p.QUAY)
	draw_rect(Rect2(fx - 20, -9, 40, 4), p.WATER_HI)
	draw_rect(Rect2(fx - 2, -26, 4, 16), p.QUAY)
	for k in 5:
		draw_rect(Rect2(fx - 1 + (k - 2) * 3, -30 - absi(k - 2) * -2, 1, 6), p.WATER_HI)
	for bx in [w * 0.22, w * 0.8]:
		draw_rect(Rect2(bx, -9, 22, 2), Color("8a6a4a"))
		draw_rect(Rect2(bx, -14, 22, 2), Color("8a6a4a"))
		draw_rect(Rect2(bx + 2, -7, 2, 7), p.IRON)
		draw_rect(Rect2(bx + 18, -7, 2, 7), p.IRON)
	for lx in [w * 0.1, w * 0.4, w * 0.7, w * 0.95]:
		draw_rect(Rect2(lx, -44, 2, 44), p.IRON)
		draw_rect(Rect2(lx - 3, -48, 8, 4), p.LIT)
	var rx := 0.0
	while rx < w:
		draw_rect(Rect2(rx, -12, 1, 12), p.IRON)
		rx += 5
	draw_rect(Rect2(0, -12, w, 1), p.IRON)
	draw_rect(Rect2(12, -30, 46, 10), Color("3f6b34"))
	_text(12, -22, 46, sign_text if sign_text != "" else "PARK", 7, p.WHITE)


func _theater(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	var stone := Color("e6dcc8")
	draw_rect(Rect2(0, -112, w, 112), stone)
	draw_rect(Rect2(w - 3, -112, 3, 112), stone.darkened(0.15))
	WorldPalette.triangle(self, 10, -112, w - 20, 28, stone.darkened(0.06))  # pediment
	draw_rect(Rect2(10, -113, w - 20, 2), p.TRIM)
	draw_rect(Rect2(20, -100, w - 40, 12), p.NAVY)
	_text(20, -91, w - 40, sign_text if sign_text != "" else "STADSSCHOUWBURG", 8, p.LIT)
	# Columns and the dark portico behind them.
	draw_rect(Rect2(20, -84, w - 40, 70), Color("5a4f45"))
	for k in 7:
		var cx := 24 + k * (w - 56) / 6.0
		draw_rect(Rect2(cx, -84, 8, 70), stone)
		draw_rect(Rect2(cx - 2, -86, 12, 3), p.TRIM)
		draw_rect(Rect2(cx - 2, -16, 12, 2), p.TRIM)
	for k in 3:                                                    # doors and posters
		draw_rect(Rect2(50 + k * 56, -50, 18, 36), Color("6b2a2a"))
		draw_rect(Rect2(36 + k * 56, -72, 10, 16), [p.ORANGE, Color("c94a3d"), Color("5b7fa6")][k])
	for k in 3:                                                    # steps
		draw_rect(Rect2(12 - k * 4, -14 + k * 5, w - 24 + k * 8, 5), stone.darkened(0.08 + k * 0.05))


func _hotel(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	var h := rng.randf_range(150, 175)
	var c: Color = [Color("d9c9b0"), Color("9fb3c8"), Color("c98f6f")][seed_value % 3]
	draw_rect(Rect2(0, -h, w, h), c)
	draw_rect(Rect2(w - 3, -h, 3, h), c.darkened(0.2))
	draw_rect(Rect2(0, -h, w, 5), p.TRIM)
	var y := -h + 14
	while y < -52:
		var x := 12.0
		while x < w - 30:
			draw_rect(Rect2(x, y, 12, 14), p.LIT if rng.randf() < 0.25 else p.GLASS)
			draw_rect(Rect2(x - 1, y + 14, 14, 2), p.TRIM)
			x += 22
		y += 24
	# Vertical neon sign, roof sign, flags, entrance canopy, revolving door.
	draw_rect(Rect2(w - 22, -h + 10, 14, 72), Color("c94a3d"))
	var word := "HOTEL"
	for i in word.length():
		_text(w - 22, -h + 22 + i * 13, 14, word[i], 10, p.WHITE)
	draw_rect(Rect2(20, -h - 14, w - 60, 14), p.NAVY)
	_text(20, -h - 4, w - 60, sign_text if sign_text != "" else "HOTEL", 9, p.LIT)
	for k in 3:
		draw_rect(Rect2(14 + k * 12, -60, 1, 22), p.IRON)
		draw_rect(Rect2(15 + k * 12, -60, 8, 5), [Color("c94a3d"), p.WHITE, Color("5b7fa6")][k])
	draw_rect(Rect2(w / 2 - 34, -44, 68, 5), p.NAVY)
	draw_rect(Rect2(w / 2 - 32, -39, 2, 39), p.IRON)
	draw_rect(Rect2(w / 2 + 30, -39, 2, 39), p.IRON)
	draw_rect(Rect2(w / 2 - 14, -35, 28, 35), p.GLASS.lightened(0.2))
	draw_rect(Rect2(w / 2 - 1, -35, 2, 35), p.TRIM)


func _apartments(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	var h := rng.randf_range(120, 150)
	var panels := [Color("e07a2e"), Color("5b7fa6"), Color("e0b23a"), Color("6f8f5a"), Color("c94a3d")]
	var base := Color("e9e4dc") if seed_value % 2 == 0 else Color("4b4f5a")
	draw_rect(Rect2(0, -h, w, h), base)
	draw_rect(Rect2(w - 3, -h, 3, h), base.darkened(0.15))
	draw_rect(Rect2(0, -h - 4, w, 4), base.darkened(0.25))
	var floors := int((h - 24) / 18)
	var bays := int(w / 30)
	for f in floors:
		var y := -h + 8 + f * 18
		for b in bays:
			var x := 4 + b * 30
			draw_rect(Rect2(x, y, 20, 12), p.GLASS if rng.randf() < 0.8 else p.LIT)
			if rng.randf() < 0.45:
				draw_rect(Rect2(x + 21, y, 5, 12), panels[(b + f + seed_value) % panels.size()])
			if b % 2 == 0:                                         # balcony
				draw_rect(Rect2(x - 2, y + 11, 26, 2), p.TRIM)
				draw_rect(Rect2(x - 2, y + 7, 26, 1), Color(1, 1, 1, 0.6))
	# Ground floor: lobby, bike shed, a young tree.
	draw_rect(Rect2(10, -36, 40, 36), p.GLASS.lightened(0.15))
	draw_rect(Rect2(10, -38, 40, 2), p.TRIM)
	draw_rect(Rect2(29, -36, 1, 36), p.TRIM)
	draw_rect(Rect2(w - 70, -16, 46, 16), Color("6c6476"))
	WorldPalette.tree(self, w - 10, 0, 10)


func _terminal(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	var h := 96.0
	# Long low terminal: concrete base, a band of glass, a roof that overhangs.
	draw_rect(Rect2(0, -h, w, h), Color("c9ccd2"))
	draw_rect(Rect2(0, -h + 16, w, 46), Color("3a4a62"))
	for x in range(0, int(w), 14):
		draw_rect(Rect2(x, -h + 16, 1, 46), Color("8a9ab2"))
	draw_rect(Rect2(0, -h + 38, w, 1), Color("8a9ab2"))
	for k in 8:                                                  # warm lit bits inside
		draw_rect(Rect2(rng.randf_range(10, w - 40), -h + 44, rng.randf_range(16, 40), 14), Color("c98f4a"))
	draw_rect(Rect2(-12, -h - 6, w + 24, 8), Color("e9eef2"))
	draw_rect(Rect2(-12, -h + 2, w + 24, 2), Color("8a8f99"))
	draw_rect(Rect2(w / 2 - 90, -h - 26, 180, 20), p.NAVY)
	_text(w / 2 - 90, -h - 11, 180, sign_text if sign_text != "" else "AIRPORT", 14, p.WHITE)
	# Departures canopy with columns, sliding doors, a departures board.
	draw_rect(Rect2(20, -44, w - 40, 5), Color("8a8f99"))
	for x in range(30, int(w) - 20, 60):
		draw_rect(Rect2(x, -39, 4, 39), Color("e9eef2"))
	for k in 4:
		var dx := 70 + k * 120
		draw_rect(Rect2(dx, -36, 34, 36), Color("8ab0c8"))
		draw_rect(Rect2(dx + 16, -36, 2, 36), p.TRIM)
		draw_rect(Rect2(dx - 2, -40, 38, 3), Color("2a4ea0"))
	draw_rect(Rect2(w - 110, -36, 60, 22), Color("1e1e24"))
	for r in 4:
		draw_rect(Rect2(w - 106, -32 + r * 5, rng.randf_range(30, 52), 2), Color("f2c14a"))
	for k in 3:                                                  # luggage trolleys
		draw_rect(Rect2(40 + k * 7, -9, 6, 6), Color("c9ccd2"))


func _tower(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	draw_rect(Rect2(w / 2 - 12, -230, 24, 230), Color("dcdfe4"))
	draw_rect(Rect2(w / 2 + 6, -230, 6, 230), Color("b9bcc4"))
	for y in range(-220, -20, 30):
		draw_rect(Rect2(w / 2 - 3, y, 6, 8), Color("3a4a62"))
	draw_rect(Rect2(0, -262, w, 8), Color("8a8f99"))             # cab
	draw_rect(Rect2(4, -284, w - 8, 22), Color("3a6a8a"))
	for x in range(6, int(w) - 6, 10):
		draw_rect(Rect2(x, -284, 1, 22), Color("9ab8ca"))
	draw_rect(Rect2(-2, -290, w + 4, 6), Color("e9eef2"))
	draw_rect(Rect2(w / 2 - 1, -320, 2, 30), p.IRON)
	draw_rect(Rect2(w / 2 - 2, -324, 4, 4), Color("e04a3a"))
	draw_rect(Rect2(w / 2 - 20, -36, 40, 36), Color("c9ccd2"))
	draw_rect(Rect2(w / 2 - 8, -34, 16, 34), p.NAVY)


## The round glass hotel tower by the motorway: a cylinder clad in glass with
## big and small blue circles, a dark glass crown with the name ring on top,
## a recessed glass lobby. Shaded as a cylinder (light from the left).
func _round_hotel(rng: RandomNumberGenerator) -> void:
	var w := width()
	var h := 236.0
	var top := -h
	# Cylinder body: vertical bands, lightest a third from the left.
	for x in int(w):
		var u := (x + 0.5) / w
		var shade := 1.0 - pow(absf(u - 0.35) * 1.6, 2.0) * 0.55
		draw_rect(Rect2(x, top + 26, 1, h - 26 - 24), Color("8ec4ea").darkened(1.0 - shade))
	# The circles: bigger ones, smaller ones, squashed toward the edges.
	for i in 70:
		var u := rng.randf()
		var cx := w * u
		var cy := rng.randf_range(top + 34, -32)
		var r := rng.randf_range(3, 9) * (1.0 - pow(absf(u - 0.5) * 2.0, 3.0) * 0.7)
		var c: Color = [Color("2a5bd7"), Color("1f3f9a"), Color("6aa8e0"), Color("d8c87a")][rng.randi_range(0, 3)]
		draw_circle(Vector2(cx, cy), r, c.darkened(pow(absf(u - 0.35), 2.0)))
	# Crown: dark glass band and the sign ring.
	draw_rect(Rect2(-1, top + 8, w + 2, 18), Color("2a3448"))
	for x in range(2, int(w), 5):
		draw_rect(Rect2(x, top + 10, 1, 14), Color("4a5a74"))
	draw_rect(Rect2(-2, top, w + 4, 8), Color("e9eef2"))
	draw_string(ThemeDB.fallback_font, Vector2(0, top + 7), sign_text if sign_text != "" else "HOTEL", HORIZONTAL_ALIGNMENT_CENTER, w, 7, Color("2a4ea0"))
	# Lobby: recessed glass on slim columns.
	draw_rect(Rect2(6, -24, w - 12, 24), Color("3a4a62"))
	draw_rect(Rect2(6, -24, w - 12, 2), Color("c9ccd2"))
	for x in range(8, int(w) - 6, 10):
		draw_rect(Rect2(x, -22, 1, 22), Color("c9a36a"))
	draw_rect(Rect2(w / 2 - 8, -20, 16, 20), Color("f2c66a"))
