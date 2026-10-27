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

enum Kind { MALL, GARAGE, SELF_STORAGE, OUR_STORAGE, CHURCH, MARKET, PARK, THEATER, HOTEL, APARTMENTS, TERMINAL, TOWER, ROUND_HOTEL, PETROL }

const WIDTHS := {Kind.MALL: 320.0, Kind.GARAGE: 200.0, Kind.SELF_STORAGE: 260.0, Kind.OUR_STORAGE: 340.0,
	Kind.CHURCH: 150.0, Kind.MARKET: 260.0, Kind.PARK: 480.0, Kind.THEATER: 250.0, Kind.HOTEL: 170.0, Kind.APARTMENTS: 210.0,
	Kind.TERMINAL: 560.0, Kind.TOWER: 70.0, Kind.ROUND_HOTEL: 66.0, Kind.PETROL: 150.0}
const CONCRETE := WorldPalette.R3
const CONCRETE_DARK := WorldPalette.R2
const STEEL := WorldPalette.W3
const SHOP_SIGNS := ["SUPER", "FIETS", "PIZZA", "DIER", "BOEK", "VERF"]
const CAR_COLOURS := [WorldPalette.B2, WorldPalette.T3, WorldPalette.W5, WorldPalette.T0, WorldPalette.O2, WorldPalette.G2]
## Same SpriteCook terrace as the house rows. A hotel front is several of
## these side by side, feet on the street, so it matches the canal.
const FACADE_BRICK := preload("res://assets/sprites/world/canal/brick.png")
const FACADE_CREAM := preload("res://assets/sprites/world/canal/cream.png")
const FACADE_ORANGE := preload("res://assets/sprites/world/canal/orange.png")
const FACADE_SHOP := preload("res://assets/sprites/world/canal/shop.png")
const HOTEL_FACADES: Array[Texture2D] = [FACADE_BRICK, FACADE_CREAM, FACADE_ORANGE]

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
@export var span := 0.0:                    ## width of its slot in world px (0 = the kind's usual width)
	set(value):
		span = value
		queue_redraw()


var _glow: NightGlow                        # lit windows and lamps at night (game only)


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_glow = NightGlow.attach(self)
	if WorldPalette.V3 and kind == Kind.CHURCH and not Engine.is_editor_hint():
		_add_front.call_deferred()


## The little square in front of the church lies on the street, so it is
## drawn just after the street strip (in the Road node), under the band.
func _add_front() -> void:
	var scene := get_tree().current_scene
	var road: Node = scene.get_node_or_null("Road") if scene else null
	var front := Node2D.new()
	front.name = "%sSquare" % name
	(road if road else get_parent()).add_child(front)
	front.global_position = global_position
	front.draw.connect(func() -> void:
		var art := front_art()
		if art:
			art.draw(front))
	front.queue_redraw()


## The church square in the style v3 look (baked once, see V3Cache / V3Painter).
func front_art() -> V3Art:
	var key := "front%d_%d|%.1f|t2" % [kind, seed_value, width()]
	var paint := func() -> V3Art: return V3Painter.building_front(kind, width(), seed_value)
	return V3Cache.art(key, paint)


## A wall at the band sprites' density: texture (0 plaster, 1 brick, 2 smooth),
## light from the left, shade on the right, a dark outline.
func _box(r: Rect2, c: Color, tex: int) -> void:
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	var a := Rect2(r.position * 2.0, r.size * 2.0)
	match tex:
		0: draw_texture_rect(PixelArt.plaster(), a, true, c)
		1: draw_texture_rect(PixelArt.brick(), a, true, c)
		_: draw_rect(a, c)
	draw_rect(Rect2(a.position, Vector2(2, a.size.y)), c.lightened(0.12))
	draw_rect(Rect2(a.position + Vector2(a.size.x - 6, 0), Vector2(6, a.size.y)), c.darkened(0.22))
	draw_rect(Rect2(a.position - Vector2(1, 1), Vector2(a.size.x + 2, 1)), PixelArt.OUTLINE)
	draw_rect(Rect2(a.position.x - 1, a.position.y, 1, a.size.y), PixelArt.OUTLINE)
	draw_rect(Rect2(a.end.x, a.position.y, 1, a.size.y), PixelArt.OUTLINE)
	draw_set_transform(Vector2.ZERO)


## A framed window at the sprites' density: outline, frame, glass with a sky
## reflection (or a lit room), mullions, a sill with its shadow. `bars` = panes across.
func _win(r: Rect2, lit := false, bars := 1) -> void:
	if _glow:
		_glow.add_window(r.grow(-1.0), NightGlow.window_threshold(r.position.x, r.position.y, lit))
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	var a := Rect2(r.position * 2.0, r.size * 2.0)
	var frame := WorldPalette.TRIM
	draw_rect(a.grow(1), PixelArt.OUTLINE)
	draw_rect(a, frame)
	var g := a.grow(-2)
	draw_rect(g, WorldPalette.O2 if lit else WorldPalette.T0)
	if not lit:
		draw_rect(Rect2(g.position, Vector2(g.size.x, 3)), WorldPalette.T0.lightened(0.25))
		draw_line(g.position + Vector2(2, g.size.y * 0.7), g.position + Vector2(g.size.x * 0.5, 3), Color(1, 1, 1, 0.15), 1.0)
	for k in range(1, bars + 1):
		var mx := a.position.x + a.size.x * k / (bars + 1.0)
		draw_rect(Rect2(mx - 1, a.position.y, 2, a.size.y), frame)
	draw_rect(Rect2(a.position.x - 3, a.end.y, a.size.x + 6, 3), WorldPalette.G4)
	draw_rect(Rect2(a.position.x - 2, a.end.y + 3, a.size.x + 4, 2), Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2.ZERO)


func width() -> float:
	return span if span > 0.0 else WIDTHS[kind]


func _draw() -> void:
	if _glow:
		_glow.clear()
	if WorldPalette.V3:
		var art := v3_art()
		if kind == Kind.HOTEL:
			_draw_hotel_facades()
		else:
			art.draw(self)
		art.add_glow(_glow)
		_district_stories()
	else:
		_draw_kind()
	if _glow:
		_glow.queue_redraw()


## A hotel front in the canal-terrace style: a few facades across the slab,
## overlapping a little so the walls meet, with the name on the ground floor.
func _draw_hotel_facades() -> void:
	var w := width()
	var n := maxi(2, int(round(w / 78.0)))
	var sw := w / float(n)
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var x := 0.0
	for i in n:
		var tex: Texture2D = FACADE_SHOP if i == n / 2 else HOTEL_FACADES[posmod(rng.randi(), HOTEL_FACADES.size())]
		var sz := tex.get_size()
		var h := sw * sz.y / sz.x
		var left := 0.0 if i == 0 else 3.0
		var right := 0.0 if i == n - 1 else 3.0
		draw_texture_rect(tex, Rect2(x - left, -h, sw + left + right, h), false)
		x += sw
	if sign_text != "":
		var board_w := minf(w - 8.0, 96.0)
		var board := Rect2((w - board_w) * 0.5, -36.0, board_w, 9.0)
		draw_rect(board, Color("1d2838"))
		PixelFont.draw_string(self, Vector2(board.position.x, board.position.y + 7.0), sign_text, HORIZONTAL_ALIGNMENT_CENTER, board.size.x, 6, Color("f2bc58"))


## The building in the style v3 look (baked once, see V3Cache / V3Painter).
func v3_art() -> V3Art:
	var key := "bld%d_%d|%s|%.1f|t2" % [kind, seed_value, sign_text, width()]
	var paint := func() -> V3Art: return V3Painter.building(kind, width(), sign_text, seed_value)
	return V3Cache.art(key, paint)


## Small street stories on the districts the house-row pass didn't cover:
## hotels, the park, the industrial edge and the airport. Drawn over the
## baked art, in the same palette, so the cache stays valid.
func _district_stories() -> void:
	var p := WorldPalette
	match kind:
		Kind.HOTEL, Kind.ROUND_HOTEL:
			_suitcase(22, p)
			_bay_tree(width() - 16, p)
		Kind.PARK:
			_lost_poster(48, -58, p)
		Kind.GARAGE, Kind.SELF_STORAGE, Kind.PETROL, Kind.MALL:
			_drum(16, p)
			_crate(width() - 28, p)
		Kind.TERMINAL:
			_departures(36, -86, p)
		_:
			pass


func _suitcase(x: float, p) -> void:
	draw_rect(Rect2(x, -11, 9, 7), p.W0)
	draw_rect(Rect2(x + 1, -10, 7, 5), p.O2)
	draw_rect(Rect2(x + 3, -13, 3, 3), p.W0)


func _bay_tree(x: float, p) -> void:
	draw_rect(Rect2(x, -8, 6, 6), p.B1)
	draw_rect(Rect2(x - 2, -16, 10, 8), p.G1)
	draw_rect(Rect2(x, -20, 6, 5), p.G2)


func _lost_poster(x: float, y: float, p) -> void:
	draw_rect(Rect2(x, y, 16, 20), p.W5)
	draw_rect(Rect2(x, y, 16, 20), p.T0, false, 1.0)
	draw_rect(Rect2(x + 5, y + 3, 6, 5), p.O2)
	draw_rect(Rect2(x + 4, y + 2, 2, 2), p.T0)
	draw_rect(Rect2(x + 10, y + 2, 2, 2), p.T0)
	PixelFont.draw_string(self, Vector2(x + 1, y + 16), "LOST", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, p.B0)


func _drum(x: float, p) -> void:
	draw_rect(Rect2(x, -12, 8, 10), p.B2)
	draw_rect(Rect2(x, -12, 8, 2), p.R0)
	draw_rect(Rect2(x, -4, 8, 2), p.R0)


func _crate(x: float, p) -> void:
	draw_rect(Rect2(x, -10, 12, 8), p.W1)
	draw_line(Vector2(x, -10), Vector2(x + 12, -2), p.W0, 1.0)
	draw_line(Vector2(x + 12, -10), Vector2(x, -2), p.W0, 1.0)


func _departures(x: float, y: float, p) -> void:
	draw_rect(Rect2(x, y, 54, 16), p.T0)
	draw_rect(Rect2(x, y, 54, 16), p.T3, false, 1.0)
	PixelFont.draw_string(self, Vector2(x + 3, y + 11), "AMS  ON TIME", HORIZONTAL_ALIGNMENT_LEFT, -1, 8, p.G3)


func _draw_kind() -> void:
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
		Kind.PETROL: _petrol(rng)


func _text(x: float, y: float, w: float, text: String, size: int, c: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_CENTER, w, size, c)


func _mall(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	var h := 104.0
	_box(Rect2(0, -h, w, h), WorldPalette.W3, 0)
	draw_rect(Rect2(0, -h, w, 8), CONCRETE_DARK)                 # roof edge
	draw_rect(Rect2(w - 3, -h, 3, h), WorldPalette.R3)
	# Tower with the centre's name.
	draw_rect(Rect2(w / 2 - 34, -h - 22, 68, 24), p.NAVY)
	_text(w / 2 - 34, -h - 7, 68, sign_text if sign_text != "" else "WINKELCENTRUM", 8, p.LIT)
	# Upper band of offices.
	for i in int(w / 18):
		_win(Rect2(6 + i * 18, -h + 14, 12, 10), rng.randf() < 0.15)
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
		var sc: Color = [p.ORANGE, WorldPalette.B2, WorldPalette.T3, WorldPalette.G2, WorldPalette.O2][i % 5]
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
	_box(Rect2(x0, -h, w, h), CONCRETE, 0)
	var floors := 4
	var fh := h / floors
	for f in floors:
		var y := -h + f * fh
		draw_rect(Rect2(x0, y, w, 4), CONCRETE_DARK)                 # slab
		if f == floors - 1:
			break                                                # ground floor: entrance
		draw_rect(Rect2(x0 + 4, y + 4, w - 8, fh - 10), WorldPalette.T0)
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
	draw_rect(Rect2(x0 + 12, -fh + 6, 36, fh - 6), WorldPalette.T0)
	draw_rect(Rect2(x0 + 12, -14, 30, 2), WorldPalette.B2)
	draw_rect(Rect2(x0 + 10, -16, 3, 16), p.IRON)
	if big_sign:
		draw_rect(Rect2(x0 + w - 40, -h - 12, 28, 28), WorldPalette.T2)
		_text(x0 + w - 40, -h + 10, 28, "P", 22, p.WHITE)
	else:
		draw_rect(Rect2(x0 + w - 22, -h + 8, 14, 14), WorldPalette.T2)
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
	_box(Rect2(0, -h, w, h), p.ORANGE, 2)
	for x in range(0, int(w), 4):                                # corrugation
		draw_rect(Rect2(x, -h, 1, h - 42), p.ORANGE.darkened(0.15))
	draw_rect(Rect2(0, -44, w, 44), p.WHITE)
	draw_rect(Rect2(0, -h, w, 4), CONCRETE_DARK)
	draw_rect(Rect2(10, -h + 8, 120, 14), p.WHITE)
	_text(10, -h + 19, 120, sign_text if sign_text != "" else "SELF STORAGE", 9, p.ORANGE.darkened(0.3))
	var doors := int((w - 10) / 42)
	for i in doors:
		_roll_door(8 + i * 42, 32, 36, STEEL if rng.randf() < 0.8 else WorldPalette.T3)
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
	draw_rect(Rect2(x0, -h, ww, h), WorldPalette.R0)
	for x in range(int(x0), int(w), 5):
		draw_rect(Rect2(x, -h, 1, h), WorldPalette.W0)
	draw_rect(Rect2(x0, -h + 26, ww, 6), p.ORANGE)                 # band stripe
	draw_rect(Rect2(x0, -h, ww, 4), CONCRETE_DARK)
	draw_rect(Rect2(x0 + 20, -h + 8, ww - 40, 14), p.NAVY)
	_text(x0 + 20, -h + 19, ww - 40, sign_text if sign_text != "" else "STORAGE", 9, p.LIT)
	# Loading door, a side door, small high windows.
	_roll_door(x0 + 30, 60, 44, STEEL)
	draw_rect(Rect2(x0 + 104, -34, 17, 34), p.NAVY)
	draw_rect(Rect2(x0 + 117, -18, 2, 2), p.LIT)
	for k in 5:
		_win(Rect2(x0 + 24 + k * 34, -h + 40, 14, 8), k == 2)
	# Camera and a lamp over the yard.
	draw_rect(Rect2(x0 + 4, -60, 6, 3), p.IRON)
	draw_rect(Rect2(x0 + 2, -62, 2, 6), p.IRON)
	draw_rect(Rect2(w - 14, -h - 18, 2, 18), p.IRON)
	draw_rect(Rect2(w - 20, -h - 20, 10, 3), p.LIT)


func _church(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var brick := WorldPalette.B1
	var w := width()
	# Nave with a steep roof and tall arched windows.
	_box(Rect2(0, -96, 104, 96), brick, 1)
	WorldPalette.triangle(self, -4, -96, 112, 46, p.ROOF)
	for k in 4:
		var x := 10 + k * 24
		draw_rect(Rect2(x, -78, 10, 40), p.GLASS)
		WorldPalette.disc(self, x + 5, -78, 5, p.GLASS)
		draw_rect(Rect2(x + 4, -82, 2, 44), WorldPalette.B4)
	# Tower: square shaft, belfry, clock, spire with a weathercock.
	var tx := 104.0
	_box(Rect2(tx, -150, 46, 150), brick.darkened(0.08), 1)
	draw_rect(Rect2(tx, -150, 46, 3), p.TRIM)
	draw_rect(Rect2(tx + 10, -140, 8, 18), p.GLASS)
	draw_rect(Rect2(tx + 28, -140, 8, 18), p.GLASS)
	WorldPalette.disc(self, tx + 23, -100, 9, p.TRIM)
	WorldPalette.disc(self, tx + 23, -100, 7, p.WHITE)
	draw_line(Vector2(tx + 23, -100), Vector2(tx + 23, -106), p.IRON, 1.0)
	draw_line(Vector2(tx + 23, -100), Vector2(tx + 27, -100), p.IRON, 1.0)
	WorldPalette.triangle(self, tx + 2, -150, 42, 58, WorldPalette.T2)   # copper spire
	draw_rect(Rect2(tx + 22, -218, 2, 12), p.IRON)
	draw_rect(Rect2(tx + 18, -220, 9, 2), WorldPalette.O2)
	# Big doors.
	draw_rect(Rect2(tx + 14, -30, 18, 30), WorldPalette.W0)
	WorldPalette.disc(self, tx + 23, -30, 9, WorldPalette.W0)
	draw_rect(Rect2(36, -24, 16, 24), WorldPalette.W0)
	draw_rect(Rect2(0, -3, w, 3), brick.darkened(0.35))


func _market(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	# Square: paving in front, lamp posts, a sign, stalls with striped awnings.
	draw_rect(Rect2(0, -2, w, 2), p.COBBLE_DARK)
	var colours := [[p.ORANGE, p.WHITE], [WorldPalette.B2, p.WHITE], [WorldPalette.T3, p.WHITE], [WorldPalette.G2, WorldPalette.W4]]
	var goods := [WorldPalette.O2, WorldPalette.B2, WorldPalette.T5, WorldPalette.W4, WorldPalette.B3]
	var x := 14.0
	var i := 0
	while x < w - 50:
		var sw := rng.randf_range(38, 50)
		var c: Array = colours[(i + seed_value) % colours.size()]
		draw_rect(Rect2(x, -34, 2, 34), p.IRON)
		draw_rect(Rect2(x + sw - 2, -34, 2, 34), p.IRON)
		for s in int(sw / 5):
			draw_rect(Rect2(x - 2 + s * 5, -40, 5, 7), c[s % 2])
		draw_rect(Rect2(x, -14, sw, 3), WorldPalette.W1)                # counter
		draw_rect(Rect2(x, -11, sw, 11), WorldPalette.W1)
		for g in int(sw / 6):
			WorldPalette.disc(self, x + 4 + g * 6, -16, 2, goods[(g + i) % goods.size()])
		x += sw + rng.randf_range(10, 18)
		i += 1
	for lx in [6.0, w - 8.0]:
		draw_rect(Rect2(lx, -50, 2, 50), p.IRON)
		draw_rect(Rect2(lx - 3, -54, 8, 4), p.LIT)
		if _glow:
			_glow.add_lamp(Vector2(lx + 1, -52), 14.0, 0.0, 0.05)
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
		draw_rect(Rect2(bx, -9, 22, 2), WorldPalette.W1)
		draw_rect(Rect2(bx, -14, 22, 2), WorldPalette.W1)
		draw_rect(Rect2(bx + 2, -7, 2, 7), p.IRON)
		draw_rect(Rect2(bx + 18, -7, 2, 7), p.IRON)
	for lx in [w * 0.1, w * 0.4, w * 0.7, w * 0.95]:
		draw_rect(Rect2(lx, -44, 2, 44), p.IRON)
		draw_rect(Rect2(lx - 3, -48, 8, 4), p.LIT)
		if _glow:
			_glow.add_lamp(Vector2(lx + 1, -46), 14.0, 0.0, 0.05)
	var rx := 0.0
	while rx < w:
		draw_rect(Rect2(rx, -12, 1, 12), p.IRON)
		rx += 5
	draw_rect(Rect2(0, -12, w, 1), p.IRON)
	draw_rect(Rect2(12, -30, 46, 10), WorldPalette.G1)
	_text(12, -22, 46, sign_text if sign_text != "" else "PARK", 7, p.WHITE)


func _theater(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	var stone := WorldPalette.W4
	_box(Rect2(0, -112, w, 112), stone, 0)
	draw_rect(Rect2(w - 3, -112, 3, 112), stone.darkened(0.15))
	WorldPalette.triangle(self, 10, -112, w - 20, 28, stone.darkened(0.06))  # pediment
	draw_rect(Rect2(10, -113, w - 20, 2), p.TRIM)
	draw_rect(Rect2(20, -100, w - 40, 12), p.NAVY)
	_text(20, -91, w - 40, sign_text if sign_text != "" else "STADSSCHOUWBURG", 8, p.LIT)
	# Columns and the dark portico behind them.
	draw_rect(Rect2(20, -84, w - 40, 70), WorldPalette.P0)
	for k in 7:
		var cx := 24 + k * (w - 56) / 6.0
		draw_rect(Rect2(cx, -84, 8, 70), stone)
		draw_rect(Rect2(cx - 2, -86, 12, 3), p.TRIM)
		draw_rect(Rect2(cx - 2, -16, 12, 2), p.TRIM)
	for k in 3:                                                    # doors and posters
		draw_rect(Rect2(50 + k * 56, -50, 18, 36), WorldPalette.B0)
		draw_rect(Rect2(36 + k * 56, -72, 10, 16), [p.ORANGE, WorldPalette.B2, WorldPalette.T3][k])
	for k in 3:                                                    # steps
		draw_rect(Rect2(12 - k * 4, -14 + k * 5, w - 24 + k * 8, 5), stone.darkened(0.08 + k * 0.05))


func _hotel(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	var h := rng.randf_range(150, 175)
	var c: Color = [WorldPalette.W3, WorldPalette.R3, WorldPalette.W2][seed_value % 3]
	_box(Rect2(0, -h, w, h), c, 0)
	draw_rect(Rect2(w - 3, -h, 3, h), c.darkened(0.2))
	draw_rect(Rect2(0, -h, w, 5), p.TRIM)
	var y := -h + 14
	while y < -52:
		var x := 12.0
		while x < w - 30:
			_win(Rect2(x, y, 12, 14), rng.randf() < 0.25)
			draw_rect(Rect2(x - 1, y + 14, 14, 2), p.TRIM)
			x += 22
		y += 24
	# Vertical neon sign, roof sign, flags, entrance canopy, revolving door.
	draw_rect(Rect2(w - 22, -h + 10, 14, 72), WorldPalette.B2)
	var word := "HOTEL"
	for i in word.length():
		_text(w - 22, -h + 22 + i * 13, 14, word[i], 10, p.WHITE)
	draw_rect(Rect2(20, -h - 14, w - 60, 14), p.NAVY)
	_text(20, -h - 4, w - 60, sign_text if sign_text != "" else "HOTEL", 9, p.LIT)
	for k in 3:
		draw_rect(Rect2(14 + k * 12, -60, 1, 22), p.IRON)
		draw_rect(Rect2(15 + k * 12, -60, 8, 5), [WorldPalette.B2, p.WHITE, WorldPalette.T3][k])
	draw_rect(Rect2(w / 2 - 34, -44, 68, 5), p.NAVY)
	draw_rect(Rect2(w / 2 - 32, -39, 2, 39), p.IRON)
	draw_rect(Rect2(w / 2 + 30, -39, 2, 39), p.IRON)
	draw_rect(Rect2(w / 2 - 14, -35, 28, 35), p.GLASS.lightened(0.2))
	draw_rect(Rect2(w / 2 - 1, -35, 2, 35), p.TRIM)


func _apartments(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	var h := rng.randf_range(120, 150)
	var panels := [WorldPalette.B3, WorldPalette.T3, WorldPalette.O2, WorldPalette.G2, WorldPalette.B2]
	var base := WorldPalette.W4 if seed_value % 2 == 0 else WorldPalette.R0
	_box(Rect2(0, -h, w, h), base, 0 if seed_value % 2 == 0 else 2)
	draw_rect(Rect2(w - 3, -h, 3, h), base.darkened(0.15))
	draw_rect(Rect2(0, -h - 4, w, 4), base.darkened(0.25))
	var floors := int((h - 24) / 18)
	var bays := int(w / 30)
	for f in floors:
		var y := -h + 8 + f * 18
		for b in bays:
			var x := 4 + b * 30
			_win(Rect2(x, y, 20, 12), rng.randf() >= 0.8, 2)
			if rng.randf() < 0.45:
				draw_rect(Rect2(x + 21, y, 5, 12), panels[(b + f + seed_value) % panels.size()])
			if b % 2 == 0:                                         # balcony
				draw_rect(Rect2(x - 2, y + 11, 26, 2), p.TRIM)
				draw_rect(Rect2(x - 2, y + 7, 26, 1), Color(1, 1, 1, 0.6))
	# Ground floor: lobby, bike shed, a young tree.
	draw_rect(Rect2(10, -36, 40, 36), p.GLASS.lightened(0.15))
	draw_rect(Rect2(10, -38, 40, 2), p.TRIM)
	draw_rect(Rect2(29, -36, 1, 36), p.TRIM)
	draw_rect(Rect2(w - 70, -16, 46, 16), WorldPalette.R1)
	WorldPalette.tree(self, w - 10, 0, 10)


func _terminal(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	var h := 96.0
	# Long low terminal: concrete base, a band of glass, a roof that overhangs.
	_box(Rect2(0, -h, w, h), WorldPalette.W3, 2)
	draw_rect(Rect2(0, -h + 16, w, 46), WorldPalette.R0)
	for x in range(0, int(w), 14):
		draw_rect(Rect2(x, -h + 16, 1, 46), WorldPalette.T4)
	draw_rect(Rect2(0, -h + 38, w, 1), WorldPalette.T4)
	for k in 8:                                                  # warm lit bits inside
		draw_rect(Rect2(rng.randf_range(10, w - 40), -h + 44, rng.randf_range(16, 40), 14), WorldPalette.O1)
	draw_rect(Rect2(-12, -h - 6, w + 24, 8), WorldPalette.T7)
	draw_rect(Rect2(-12, -h + 2, w + 24, 2), WorldPalette.R2)
	draw_rect(Rect2(w / 2 - 90, -h - 26, 180, 20), p.NAVY)
	_text(w / 2 - 90, -h - 11, 180, sign_text if sign_text != "" else "AIRPORT", 14, p.WHITE)
	# Departures canopy with columns, sliding doors, a departures board.
	draw_rect(Rect2(20, -44, w - 40, 5), WorldPalette.R2)
	for x in range(30, int(w) - 20, 60):
		draw_rect(Rect2(x, -39, 4, 39), WorldPalette.T7)
	for k in 4:
		var dx := 70 + k * 120
		draw_rect(Rect2(dx, -36, 34, 36), WorldPalette.R3)
		draw_rect(Rect2(dx + 16, -36, 2, 36), p.TRIM)
		draw_rect(Rect2(dx - 2, -40, 38, 3), WorldPalette.T1)
	draw_rect(Rect2(w - 110, -36, 60, 22), WorldPalette.T0)
	for r in 4:
		draw_rect(Rect2(w - 106, -32 + r * 5, rng.randf_range(30, 52), 2), WorldPalette.O2)
	for k in 3:                                                  # luggage trolleys
		draw_rect(Rect2(40 + k * 7, -9, 6, 6), WorldPalette.W3)


func _tower(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	draw_rect(Rect2(w / 2 - 12, -230, 24, 230), WorldPalette.W4)
	draw_rect(Rect2(w / 2 + 6, -230, 6, 230), WorldPalette.R3)
	for y in range(-220, -20, 30):
		draw_rect(Rect2(w / 2 - 3, y, 6, 8), WorldPalette.R0)
	draw_rect(Rect2(0, -262, w, 8), WorldPalette.R2)             # cab
	draw_rect(Rect2(4, -284, w - 8, 22), WorldPalette.T2)
	for x in range(6, int(w) - 6, 10):
		draw_rect(Rect2(x, -284, 1, 22), WorldPalette.R3)
	draw_rect(Rect2(-2, -290, w + 4, 6), WorldPalette.T7)
	draw_rect(Rect2(w / 2 - 1, -320, 2, 30), p.IRON)
	draw_rect(Rect2(w / 2 - 2, -324, 4, 4), WorldPalette.B2)
	draw_rect(Rect2(w / 2 - 20, -36, 40, 36), WorldPalette.W3)
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
		draw_rect(Rect2(x, top + 26, 1, h - 26 - 24), WorldPalette.T5.darkened(1.0 - shade))
	# The circles: bigger ones, smaller ones, squashed toward the edges.
	for i in 70:
		var u := rng.randf()
		var cx := w * u
		var cy := rng.randf_range(top + 34, -32)
		var r := rng.randf_range(3, 9) * (1.0 - pow(absf(u - 0.5) * 2.0, 3.0) * 0.7)
		var c: Color = [WorldPalette.T2, WorldPalette.T1, WorldPalette.T4, WorldPalette.W3][rng.randi_range(0, 3)]
		draw_circle(Vector2(cx, cy), r, c.darkened(pow(absf(u - 0.35), 2.0)))
	# Crown: dark glass band and the sign ring.
	draw_rect(Rect2(-1, top + 8, w + 2, 18), WorldPalette.T1)
	for x in range(2, int(w), 5):
		draw_rect(Rect2(x, top + 10, 1, 14), WorldPalette.R1)
	draw_rect(Rect2(-2, top, w + 4, 8), WorldPalette.T7)
	draw_string(ThemeDB.fallback_font, Vector2(0, top + 7), sign_text if sign_text != "" else "HOTEL", HORIZONTAL_ALIGNMENT_CENTER, w, 7, WorldPalette.T1)
	# Lobby: recessed glass on slim columns.
	draw_rect(Rect2(6, -24, w - 12, 24), WorldPalette.R0)
	draw_rect(Rect2(6, -24, w - 12, 2), WorldPalette.W3)
	for x in range(8, int(w) - 6, 10):
		draw_rect(Rect2(x, -22, 1, 22), WorldPalette.B4)
	draw_rect(Rect2(w / 2 - 8, -20, 16, 20), WorldPalette.O2)


## A petrol station: canopy on two columns, two pumps, a small shop with a
## glass front, the price pole.
func _petrol(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var brand := WorldPalette.T3
	# Shop at the back right.
	_box(Rect2(90, -46, 56, 46), WorldPalette.W4, 0)
	draw_rect(Rect2(94, -38, 30, 30), WorldPalette.R3)
	draw_rect(Rect2(94, -38, 30, 2), p.TRIM)
	draw_rect(Rect2(128, -34, 14, 34), WorldPalette.R3.darkened(0.2))
	draw_rect(Rect2(90, -50, 56, 6), brand)
	_text(90, -45, 56, "SHOP", 6, p.WHITE)
	# Canopy.
	for cx in [18.0, 72.0]:
		draw_rect(Rect2(cx - 2, -54, 4, 54), WorldPalette.W3)
	draw_rect(Rect2(-4, -66, 98, 12), p.WHITE)
	draw_rect(Rect2(-4, -58, 98, 4), brand)
	draw_rect(Rect2(-4, -54, 98, 2), Color(0, 0, 0, 0.2))
	for k in 6:                                                 # canopy lights
		draw_rect(Rect2(4 + k * 15, -53, 6, 1), WorldPalette.W5)
	# Pumps.
	for px in [32.0, 54.0]:
		draw_rect(Rect2(px, -24, 10, 24), WorldPalette.W4)
		draw_rect(Rect2(px, -24, 10, 4), brand)
		draw_rect(Rect2(px + 2, -18, 6, 4), WorldPalette.T0)
		draw_rect(Rect2(px + 1, -8, 8, 2), WorldPalette.B2)
		draw_line(Vector2(px + 10, -14), Vector2(px + 13, -6), WorldPalette.T0, 1.0)
	# Price pole.
	draw_rect(Rect2(-14, -70, 4, 70), WorldPalette.R2)
	draw_rect(Rect2(-24, -86, 24, 30), brand)
	for r in 3:
		draw_rect(Rect2(-22, -82 + r * 8, 20, 6), WorldPalette.T0)
		draw_rect(Rect2(-14, -81 + r * 8, 10, 4), WorldPalette.O2)
