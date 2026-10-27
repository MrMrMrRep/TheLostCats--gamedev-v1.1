@tool
class_name CityBlock
extends Node2D
## A row of Amsterdam houses on the play street, drawn at the band sprites'
## pixel density (art px = half a world px, see PixelArt). Scale follows
## docs/city-layout.md: band 27 px, doors 17x34, windows 11x18, ground floor
## 44, upper storeys 38 (world px).
## Each house: brick or painted wall (textured), outline and light from the
## left, string courses, framed sash windows with sills and lintels (curtains,
## flower boxes, lit rooms, the odd cat), a gable (step, neck, bell, spout,
## flat cornice or slate mansard) with a hoist beam, and a ground floor that is
## either a front door with a stoop or a shop: signboard, display window with
## goods, glass door, wall lamps, maybe an awning, with an A-board or a café
## terrace on the pavement. `style` picks the mix per district.
## Origin = street level, left end; seed_value keeps the look stable.

enum Style { CANAL, OLD_TOWN, RING }

const GROUND := 44.0
const STOREY := 38.0
const BRICKS := [WorldPalette.B1, WorldPalette.B1, WorldPalette.B1, WorldPalette.W0, WorldPalette.B2, WorldPalette.B1]
const PAINTED := [WorldPalette.W4, WorldPalette.G4, WorldPalette.T3, WorldPalette.T1, WorldPalette.R2, WorldPalette.O1, WorldPalette.R3]
const DOORS := [WorldPalette.G0, WorldPalette.T0, WorldPalette.B0, WorldPalette.T0, WorldPalette.T2, WorldPalette.W0]
const SHOPS := [WorldPalette.G0, WorldPalette.T0, WorldPalette.B0, WorldPalette.W0, WorldPalette.T0, WorldPalette.W1, WorldPalette.T1]
const CURTAINS := [WorldPalette.W4, WorldPalette.B2, WorldPalette.G2, WorldPalette.O2, WorldPalette.W4]
const FLOWERS := [WorldPalette.B2, WorldPalette.O2, WorldPalette.W4, WorldPalette.B2, WorldPalette.O1]
const GOODS := [WorldPalette.O2, WorldPalette.B2, WorldPalette.T5, WorldPalette.W4, WorldPalette.T3, WorldPalette.B3, WorldPalette.W1]
const STREETS := ["Prinsengracht", "Herengracht", "Keizersgracht", "Spiegelstraat", "Leidsestraat", "Runstraat"]
## SpriteCook facades in the canal-reference style. Every house row (canal,
## old town and the ring road) is built from these, one per house, flush,
## feet on the street.
const FACADE_BRICK := preload("res://assets/sprites/world/canal/brick.png")
const FACADE_CREAM := preload("res://assets/sprites/world/canal/cream.png")
const FACADE_ORANGE := preload("res://assets/sprites/world/canal/orange.png")
const FACADE_SHOP := preload("res://assets/sprites/world/canal/shop.png")
const FACADES: Array[Texture2D] = [FACADE_BRICK, FACADE_CREAM, FACADE_ORANGE]

@export var houses := 6:
	set(value):
		houses = value
		queue_redraw()
@export var seed_value := 1:
	set(value):
		seed_value = value
		queue_redraw()
@export var sign_text := "":                ## sign on the middle house (STUDIO, CAFE DE KAT...); its door is a WorldDoor
	set(value):
		sign_text = value
		queue_redraw()
@export_range(0.0, 1.0) var shop_rate := 0.3:  ## share of houses with a shop front
	set(value):
		shop_rate = value
		queue_redraw()
@export var shop_signs: PackedStringArray = []: ## shop/bar names; shops get one each
	set(value):
		shop_signs = value
		queue_redraw()
@export var style := Style.CANAL:
	set(value):
		style = value
		queue_redraw()


var _glow: NightGlow                        # lit windows at night (game only)


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	_glow = NightGlow.attach(self)


## The row's houses: {w, upper, wall, brick, gable, shop, salt} (w in world px).
func layout() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out := []
	var last := Color.BLACK
	for i in houses:
		var d := {}
		match style:
			Style.RING:
				d.w = rng.randi_range(36, 44) * 2
				d.upper = 3
				d.gable = 4 if rng.randf() < 0.6 else 5
			Style.OLD_TOWN:
				d.w = rng.randi_range(26, 34) * 2
				d.upper = 2 if rng.randf() < 0.7 else 1
				d.gable = rng.randi_range(0, 3)
			_:
				d.w = rng.randi_range(27, 36) * 2
				d.upper = 2 if rng.randf() < 0.55 else 3
				d.gable = rng.randi_range(0, 5) if rng.randf() < 0.85 else 4
		d.brick = rng.randf() < (0.75 if style == Style.RING else 0.6)
		var pal: Array = BRICKS if d.brick else PAINTED
		var c: Color = pal[rng.randi_range(0, pal.size() - 1)]
		if c == last:
			c = pal[(pal.find(c) + 1) % pal.size()]
		last = c
		d.wall = c
		d.shop = rng.randf() < shop_rate
		d.salt = rng.randi()
		out.append(d)
	return out


## World x (from the block's left end) of the middle of house `i`; the signed
## house's door (a WorldDoor) goes there.
func house_center(i: int) -> float:
	var x := 0.0
	var rows := layout()
	for k in i:
		x += rows[k].w
	return x + rows[i].w / 2.0


func signed_center() -> float:
	return house_center(houses / 2)


func width() -> float:
	var w := 0.0
	for d in layout():
		w += d.w
	return w


## Houses from the SpriteCook reference set. Each facade fills its slot
## exactly, so the row stays flush with no gaps.
func _draw_reference_row() -> void:
	var x := 0.0
	var rows := layout()
	var mid := rows.size() / 2
	for i in rows.size():
		var d: Dictionary = rows[i]
		var w: float = d.w
		var tex: Texture2D = FACADE_SHOP if d.shop else FACADES[posmod(int(d.salt), FACADES.size())]
		var sz := tex.get_size()
		var h := w * sz.y / sz.x
		# A couple of pixels of overlap so neighbouring facades meet, the way the terrace does.
		var left := 0.0 if i == 0 else 3.0
		var right := 0.0 if i == rows.size() - 1 else 3.0
		draw_texture_rect(tex, Rect2(x - left, -h, w + left + right, h), false)
		if i == mid and sign_text != "":
			var board := Rect2(x + 3.0, -GROUND + 8.0, w - 6.0, 9.0)
			draw_rect(board, Color("1d2838"))
			PixelFont.draw_string(self, Vector2(board.position.x, board.position.y + 7.0), sign_text, HORIZONTAL_ALIGNMENT_CENTER, board.size.x, 6, Color("f2bc58"))
		x += w


func _draw() -> void:
	if _glow:
		_glow.clear()
	if WorldPalette.V3:
		var art := v3_art()
		_draw_reference_row()
		art.add_glow(_glow)
		if _glow:
			_glow.queue_redraw()
		return
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	var x := 0.0
	var rows := layout()
	var mid := houses / 2
	for i in rows.size():
		var d: Dictionary = rows[i]
		var signed := sign_text != "" and i == mid
		_house(x, d, i, signed)
		x += d.w * 2.0
	draw_set_transform(Vector2.ZERO)
	if _glow:
		_glow.queue_redraw()


const REFINED_DIR := "res://assets/sprites/world/blocks/"

var _refined: V3Art
var _refined_checked := false


## A hand-refined version of this row (the painted art touched up per
## district, e.g. with SpriteCook; see tools/spritecook/), saved as
## REFINED_DIR/<node name>.res with its own origin and windows. When there is
## none, the painted art is used.
func refined_art() -> V3Art:
	if _refined_checked:
		return _refined
	_refined_checked = true
	var path := REFINED_DIR + String(name) + ".res"
	if ResourceLoader.exists(path):
		_refined = load(path) as V3Art   # kept: its texture must outlive the draw call
	return _refined


## The row in the style v3 look (baked once, see V3Cache / V3Painter).
func v3_art() -> V3Art:
	var rows := layout()
	var key := "block%d|%d|%d|%s|%s|%.3f" % [seed_value, houses, style, sign_text, ",".join(shop_signs), shop_rate]
	var paint := func() -> V3Art: return V3Painter.city_block(rows, style, sign_text, shop_signs, seed_value)
	return V3Cache.art(key, paint)


# --- One house, legacy look (all in art px; y up is negative) -----------------

func _house(x0: float, d: Dictionary, index: int, signed: bool) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = d.salt
	var W: float = d.w * 2.0
	var GH := GROUND * 2.0
	var SH := STOREY * 2.0
	var H: float = GH + d.upper * SH
	var wall: Color = d.wall
	var brick: bool = d.brick
	var dark := wall.darkened(0.55)
	var stone := WorldPalette.G4 if brick else wall.darkened(0.12)
	# Chimney behind the roof line.
	if d.gable >= 3 and rng.randf() < 0.7:
		var cx := x0 + W * rng.randf_range(0.2, 0.75)
		_tex(Rect2(cx, -H - 40, 12, 40), PixelArt.brick(), BRICKS[1])
		draw_rect(Rect2(cx - 1, -H - 42, 14, 3), WorldPalette.R1)
		draw_rect(Rect2(cx + 3, -H - 48, 5, 6), WorldPalette.W1)
	_gable(x0, W, H, d.gable, wall, brick, stone, dark, rng)
	# Wall with texture, outline, light from the left.
	_tex(Rect2(x0, -H, W, H), PixelArt.brick() if brick else PixelArt.plaster(), wall)
	draw_rect(Rect2(x0, -H, 2, H), wall.lightened(0.12))
	draw_rect(Rect2(x0 + W - 5, -H, 5, H), wall.darkened(0.22))
	draw_rect(Rect2(x0 + W - 1, -H, 1, H), PixelArt.OUTLINE)
	# String course above the ground floor.
	draw_rect(Rect2(x0, -GH - 4, W, 4), stone)
	draw_rect(Rect2(x0, -GH, W, 2), wall.darkened(0.35))
	# Upper storeys.
	var cols := 3 if W >= 124 else 2
	var ww := 22.0
	var gap := (W - cols * ww) / (cols + 1)
	var cat_at := rng.randi_range(0, cols * d.upper - 1) if rng.randf() < 0.08 else -1
	var n := 0
	for s in d.upper:
		var base: float = -GH - s * SH
		for k in cols:
			var wx := x0 + gap + k * (ww + gap)
			var tall := 40.0 if s == 0 else 36.0
			_window(wx, base - 14 - tall, ww, tall, rng, brick, wall, stone, n == cat_at)
			n += 1
		if style == Style.RING and s < d.upper - 1 and rng.randf() < 0.5:
			_balcony(x0 + gap - 6, base - 12, W - gap * 2 + 12)
	# Drainpipe, street-name plaque.
	if rng.randf() < 0.45:
		draw_rect(Rect2(x0 + 3, -H + 6, 3, H - 8), WorldPalette.R1)
		draw_rect(Rect2(x0 + 1, -H + 4, 7, 4), WorldPalette.R1)
	if index == 0 and rng.randf() < 0.3:
		var street: String = STREETS[(seed_value + index) % STREETS.size()]
		draw_rect(Rect2(x0 + 8, -GH - 24, 64, 13), WorldPalette.W5)
		draw_rect(Rect2(x0 + 9, -GH - 23, 62, 11), WorldPalette.T1)
		draw_string(ThemeDB.fallback_font, Vector2(x0 + 9, -GH - 14), street, HORIZONTAL_ALIGNMENT_CENTER, 62, 9, Color.WHITE)
	# Ground floor.
	if signed:
		_signed_ground(x0, W, GH, stone)
	elif d.shop:
		_shop_front(x0, W, GH, rng, index)
	else:
		_entrance(x0, W, GH, rng, wall, brick, stone)
	# Plinth.
	draw_rect(Rect2(x0, -6, W, 6), WorldPalette.R1)
	draw_rect(Rect2(x0, -6, W, 1), WorldPalette.R2)


func _tex(r: Rect2, tex: Texture2D, c: Color) -> void:
	draw_texture_rect(tex, r, true, c)


func _gable(x0: float, W: float, H: float, kind: int, wall: Color, brick: bool, stone: Color, dark: Color, rng: RandomNumberGenerator) -> void:
	var tex := PixelArt.brick() if brick else PixelArt.plaster()
	var top := -H
	var cx := x0 + W / 2.0
	var hoist := false
	match kind:
		0:                                  # step gable
			var tiers := [[0.82, 16], [0.58, 16], [0.34, 16]]
			var y := top
			for t in tiers:
				var tw: float = W * t[0]
				_tex(Rect2(cx - tw / 2, y - t[1], tw, t[1]), tex, wall)
				draw_rect(Rect2(cx - tw / 2 - 1, y - t[1] - 2, tw + 2, 3), stone)
				y -= t[1]
			draw_rect(Rect2(cx - 3, y - 8, 6, 8), stone)
			_attic_window(cx - 8, top - 30, 16, 20, rng)
			hoist = true
		1:                                  # neck gable with scrolls
			var nw := W * 0.46
			_tex(Rect2(cx - nw / 2, top - 44, nw, 44), tex, wall)
			for side in [-1.0, 1.0]:
				for y in 14:
					var reach := (14 - y) * 1.1
					var sx: float = cx + side * nw / 2 + (0.0 if side > 0 else -reach)
					draw_rect(Rect2(sx, top - y - 1, reach, 1), wall)
				draw_rect(Rect2(cx + side * (nw / 2 + 10) - 3, top - 6, 6, 6), stone)
			WorldPalette.triangle(self, cx - nw / 2 - 3, top - 44, nw + 6, 10, stone)
			draw_rect(Rect2(cx - nw / 2 - 2, top - 45, nw + 4, 2), stone)
			_attic_window(cx - 8, top - 36, 16, 22, rng)
			hoist = true
		2:                                  # bell gable
			var bw := W * 0.7
			for y in 46:
				var t := float(y) / 46.0
				var half := bw / 2.0 * (1.0 - pow(t, 1.7)) + 6.0
				draw_rect(Rect2(cx - half, top - y - 1, half * 2, 1), wall)
				if y % 2 == 0:
					draw_rect(Rect2(cx - half - 1, top - y - 1, 2, 1), stone)
					draw_rect(Rect2(cx + half - 1, top - y - 1, 2, 1), stone)
			WorldPalette.disc(self, cx, top - 50, 5, stone)
			_attic_window(cx - 8, top - 32, 16, 20, rng)
			hoist = true
		3:                                  # spout gable with a tiled roof behind
			WorldPalette.triangle(self, x0 - 2, top, W + 4, 40, WorldPalette.T0)
			WorldPalette.triangle(self, x0 + 10, top, W - 20, 30, wall)
			draw_rect(Rect2(cx - 10, top - 40, 20, 14), wall)
			draw_rect(Rect2(cx - 11, top - 42, 22, 2), stone)
			_attic_window(cx - 7, top - 24, 14, 18, rng)
			hoist = true
		4:                                  # flat cornice with dentils and brackets
			draw_rect(Rect2(x0 - 3, top - 10, W + 6, 6), stone)
			draw_rect(Rect2(x0 - 3, top - 4, W + 6, 2), stone.darkened(0.2))
			var x := x0
			while x < x0 + W - 2:
				draw_rect(Rect2(x + 1, top - 2, 3, 3), stone.darkened(0.08))
				x += 6
			for bx in [x0 + 2, x0 + W - 8]:
				draw_rect(Rect2(bx, top - 4, 6, 10), stone)
			draw_rect(Rect2(x0 - 3, top - 11, W + 6, 1), PixelArt.OUTLINE)
		_:                                  # slate mansard with dormers
			var mh := 40.0
			var inset := 10.0
			for y in int(mh):
				var t := float(y) / mh
				var half := W / 2.0 - inset * t
				_tex(Rect2(cx - half, top - y - 1, half * 2, 1), PixelArt.slate(), WorldPalette.R0)
			draw_rect(Rect2(x0 - 3, top - 4, W + 6, 4), stone)
			var dorm := 2 if W >= 120 else 1
			for k in dorm:
				var dx := x0 + W * (k + 1) / (dorm + 1) - 9
				draw_rect(Rect2(dx - 2, top - 32, 22, 26), stone)
				WorldPalette.triangle(self, dx - 4, top - 32, 26, 8, WorldPalette.R0)
				draw_rect(Rect2(dx + 2, top - 28, 14, 18), PixelArt.OUTLINE)
				draw_rect(Rect2(dx + 3, top - 27, 12, 16), WorldPalette.GLASS)
				draw_rect(Rect2(dx + 8, top - 27, 2, 16), stone)
	if hoist:                               # hoist beam with a hook
		draw_rect(Rect2(cx - 2, top - 14, 4, 6), WorldPalette.W0)
		draw_rect(Rect2(cx - 1, top - 8, 2, 1), PixelArt.OUTLINE)
		draw_line(Vector2(cx, top - 8), Vector2(cx, top + 2), WorldPalette.T0, 1.0)


func _attic_window(x: float, y: float, w: float, h: float, rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(x - 1, y - 1, w + 2, h + 2), PixelArt.OUTLINE)
	if rng.randf() < 0.5:                   # hoist doors (shutters)
		draw_rect(Rect2(x, y, w, h), WorldPalette.G0)
		draw_rect(Rect2(x + w / 2, y, 1, h), PixelArt.OUTLINE)
	else:
		draw_rect(Rect2(x, y, w, h), WorldPalette.TRIM)
		draw_rect(Rect2(x + 2, y + 2, w - 4, h - 4), WorldPalette.GLASS)


func _window(x: float, y: float, w: float, h: float, rng: RandomNumberGenerator, brick: bool, wall: Color, stone: Color, cat: bool) -> void:
	var p := WorldPalette
	var frame := p.TRIM if (brick or wall.get_luminance() < 0.6) else WorldPalette.G0
	var lit := rng.randf() < 0.14
	var glass := WorldPalette.O2 if lit else WorldPalette.T0
	if _glow:                               # art px -> world px
		_glow.add_window(Rect2((x + 2) * 0.5, (y + 2) * 0.5, (w - 4) * 0.5, (h - 4) * 0.5),
			NightGlow.window_threshold(x, y, lit))
	# Lintel: a brick arch with a keystone, or a stone cap on plaster.
	if brick:
		draw_rect(Rect2(x - 3, y - 5, w + 6, 5), wall.lightened(0.18))
		draw_rect(Rect2(x + w / 2 - 2, y - 6, 4, 6), stone)
	else:
		draw_rect(Rect2(x - 4, y - 4, w + 8, 3), stone)
		draw_rect(Rect2(x - 4, y - 1, w + 8, 1), wall.darkened(0.3))
	draw_rect(Rect2(x - 1, y - 1, w + 2, h + 2), PixelArt.OUTLINE)
	draw_rect(Rect2(x, y, w, h), frame)
	var gx := x + 2
	var gw := w - 4
	draw_rect(Rect2(gx, y + 2, gw, h - 4), glass)
	if not lit:                             # sky reflection
		draw_rect(Rect2(gx, y + 2, gw, 3), glass.lightened(0.25))
		draw_line(Vector2(gx + 2, y + h * 0.5), Vector2(gx + gw * 0.6, y + 4), glass.lightened(0.18), 1.0)
	if rng.randf() < 0.4:                   # curtains
		var cc: Color = CURTAINS[rng.randi_range(0, CURTAINS.size() - 1)]
		draw_rect(Rect2(gx, y + 2, 3, h * 0.55), cc)
		draw_rect(Rect2(gx + gw - 3, y + 2, 3, h * 0.55), cc)
	if cat:                                 # a lost cat, watching the street
		var cy := y + h * 0.55
		draw_rect(Rect2(gx + 4, cy - 6, 8, 7), PixelArt.OUTLINE)
		draw_rect(Rect2(gx + 5, cy - 11, 6, 5), PixelArt.OUTLINE)
		draw_rect(Rect2(gx + 5, cy - 13, 1, 2), PixelArt.OUTLINE)
		draw_rect(Rect2(gx + 10, cy - 13, 1, 2), PixelArt.OUTLINE)
		draw_rect(Rect2(gx + 6, cy - 9, 1, 1), WorldPalette.O3)
		draw_rect(Rect2(gx + 9, cy - 9, 1, 1), WorldPalette.O3)
	draw_rect(Rect2(x, y + h * 0.5 - 1, w, 2), frame)          # sash bar
	draw_rect(Rect2(x + w / 2 - 1, y, 2, h), frame)            # mullion
	# Sill with its shadow; sometimes a flower box.
	draw_rect(Rect2(x - 3, y + h, w + 6, 3), stone)
	draw_rect(Rect2(x - 2, y + h + 3, w + 4, 2), wall.darkened(0.32))
	if rng.randf() < 0.22:
		draw_rect(Rect2(x - 1, y + h - 5, w + 2, 5), WorldPalette.W1)
		for f in int(w / 3):
			var fc: Color = FLOWERS[rng.randi_range(0, FLOWERS.size() - 1)] if f % 2 == 0 else WorldPalette.T3
			draw_rect(Rect2(x + f * 3, y + h - 8, 2, 3), fc)


func _balcony(x: float, y: float, w: float) -> void:
	draw_rect(Rect2(x, y, w, 3), WorldPalette.R2)
	draw_rect(Rect2(x, y - 12, w, 1), PixelArt.OUTLINE)
	var bx := x
	while bx < x + w:
		draw_rect(Rect2(bx, y - 12, 1, 12), PixelArt.OUTLINE)
		bx += 4


func _entrance(x0: float, W: float, GH: float, rng: RandomNumberGenerator, wall: Color, brick: bool, stone: Color) -> void:
	var p := WorldPalette
	var left := rng.randf() < 0.5
	var dw := 34.0
	var dh := 64.0
	var dx := x0 + (12.0 if left else W - dw - 12.0)
	var step := 8.0
	# Stoop: steps and an iron railing.
	draw_rect(Rect2(dx - 6, -step, dw + 12, step), stone.darkened(0.08))
	draw_rect(Rect2(dx - 3, -step - 4, dw + 6, 4), stone)
	draw_rect(Rect2(dx - 8, -step - 18, 1, 18), PixelArt.OUTLINE)
	draw_rect(Rect2(dx - 8, -step - 18, 6, 1), PixelArt.OUTLINE)
	# Door: frame, four panels, fanlight, knob, mail slot, number.
	var dc: Color = DOORS[rng.randi_range(0, DOORS.size() - 1)]
	var top := -step - 4 - dh
	draw_rect(Rect2(dx - 4, top - 16, dw + 8, dh + 16), p.TRIM)
	draw_rect(Rect2(dx - 5, top - 17, dw + 10, 1), PixelArt.OUTLINE)
	draw_rect(Rect2(dx, top - 12, dw, 10), p.GLASS)
	for k in 4:
		draw_line(Vector2(dx + dw / 2, top - 2), Vector2(dx + 4 + k * (dw - 8) / 3.0, top - 12), p.TRIM, 1.0)
	draw_rect(Rect2(dx, top, dw, dh), dc)
	for r in 2:
		for c in 2:
			draw_rect(Rect2(dx + 4 + c * 15, top + 5 + r * 28, 11, 22), dc.darkened(0.25))
			draw_rect(Rect2(dx + 5 + c * 15, top + 6 + r * 28, 9, 20), dc.lightened(0.06))
	draw_rect(Rect2(dx + dw - 6, top + dh / 2, 2, 3), p.LIT)
	draw_rect(Rect2(dx + 10, top + dh * 0.62, 14, 2), WorldPalette.B4)
	draw_rect(Rect2(dx + dw + 6, top + 10, 8, 6), WorldPalette.T1)
	draw_string(ThemeDB.fallback_font, Vector2(dx + dw + 6, top + 15), str(rng.randi_range(2, 480)), HORIZONTAL_ALIGNMENT_CENTER, 8, 6, Color.WHITE)
	# Wall lamp by the door.
	var lx := dx + (dw + 18.0 if left else -18.0)
	draw_rect(Rect2(lx, top + 2, 6, 10), PixelArt.OUTLINE)
	draw_rect(Rect2(lx + 1, top + 4, 4, 6), p.LIT)
	# Front-room window and a basement window with bars.
	var wx := x0 + (W - 50.0 if left else 14.0)
	_window(wx, -GH + 14, 26, 40, rng, brick, wall, stone, false)
	draw_rect(Rect2(wx + 4, -20, 18, 10), PixelArt.OUTLINE)
	draw_rect(Rect2(wx + 5, -19, 16, 8), p.GLASS)
	for k in 4:
		draw_rect(Rect2(wx + 7 + k * 4, -19, 1, 8), WorldPalette.R0)
	if rng.randf() < 0.25:
		_bike(x0 + (W - 66.0 if left else 46.0), 0.0, rng)


func _shop_front(x0: float, W: float, GH: float, rng: RandomNumberGenerator, index: int) -> void:
	var p := WorldPalette
	var fc: Color = SHOPS[rng.randi_range(0, SHOPS.size() - 1)]
	var shop_name := ""
	if not shop_signs.is_empty():
		shop_name = shop_signs[(index + seed_value) % shop_signs.size()]
	var top := -GH + 6
	# Frame, signboard.
	draw_rect(Rect2(x0 + 2, top, W - 4, GH - 12), fc)
	draw_rect(Rect2(x0 + 1, top - 1, W - 2, 1), PixelArt.OUTLINE)
	draw_rect(Rect2(x0 + 6, top + 3, W - 12, 16), fc.darkened(0.35))
	draw_rect(Rect2(x0 + 6, top + 3, W - 12, 1), fc.lightened(0.3))
	if shop_name != "":
		draw_string(ThemeDB.fallback_font, Vector2(x0 + 6, top + 15), shop_name, HORIZONTAL_ALIGNMENT_CENTER, W - 12, 11, WorldPalette.O3)
	# Display window with goods on lit shelves, glass door.
	var door_w := 26.0
	var door_left := rng.randf() < 0.5
	var dx := x0 + (8.0 if door_left else W - door_w - 8.0)
	var wx := x0 + (door_w + 14.0 if door_left else 8.0)
	var wwid := W - door_w - 22.0
	var wy := top + 24
	var wh := GH - 12 - 24 - 14
	draw_rect(Rect2(wx - 1, wy - 1, wwid + 2, wh + 2), PixelArt.OUTLINE)
	draw_rect(Rect2(wx, wy, wwid, wh), WorldPalette.P0)
	draw_rect(Rect2(wx, wy, wwid, wh * 0.45), WorldPalette.W1)      # warm light
	for s in 2:
		var sy := wy + 10 + s * 14
		draw_rect(Rect2(wx + 2, sy, wwid - 4, 2), WorldPalette.W0)
		var gx := wx + 4
		while gx < wx + wwid - 6:
			if rng.randf() < 0.75:
				draw_rect(Rect2(gx, sy - rng.randi_range(4, 7), 3, 4), GOODS[rng.randi_range(0, GOODS.size() - 1)])
			gx += 5
	draw_line(Vector2(wx + 4, wy + wh - 2), Vector2(wx + wh * 0.6 + 4, wy + 2), Color(1, 1, 1, 0.18), 2.0)
	draw_rect(Rect2(wx, wy + wh, wwid, 8), fc.darkened(0.2))
	draw_rect(Rect2(dx - 1, top + 22, door_w + 2, GH - 12 - 22 + 1), PixelArt.OUTLINE)
	draw_rect(Rect2(dx, top + 23, door_w, GH - 12 - 23), fc.darkened(0.15))
	draw_rect(Rect2(dx + 4, top + 27, door_w - 8, 30), WorldPalette.W1)
	draw_rect(Rect2(dx + door_w - 6, top + 50, 2, 3), p.LIT)
	# Gooseneck lamps over the window, sometimes an awning.
	for lx in [wx + 6, wx + wwid - 10]:
		draw_rect(Rect2(lx, top + 19, 1, 4), PixelArt.OUTLINE)
		draw_rect(Rect2(lx - 2, top + 22, 5, 3), p.LIT)
	if rng.randf() < 0.45:
		var ac: Color = [p.ORANGE, WorldPalette.B2, WorldPalette.G1, WorldPalette.T1][rng.randi_range(0, 3)]
		for k in int(wwid / 6) + 1:
			draw_rect(Rect2(wx - 3 + k * 6, wy - 2, 6, 10), ac if k % 2 == 0 else p.WHITE)
			draw_rect(Rect2(wx - 2 + k * 6, wy + 8, 4, 2), ac if k % 2 == 0 else p.WHITE)
		draw_rect(Rect2(wx - 3, wy - 3, wwid + 6, 1), PixelArt.OUTLINE)
	# On the pavement: a terrace for bars and cafés, otherwise an A-board or plants.
	if shop_name.contains("BAR") or shop_name.contains("CAFE"):
		_terrace(wx + wwid * 0.5, rng)
	elif rng.randf() < 0.6:
		_aboard(x0 + (W - 22.0 if door_left else 10.0), rng)
	if rng.randf() < 0.5:
		_plant(dx - 10.0 if door_left else dx + door_w + 2.0)


func _signed_ground(x0: float, W: float, GH: float, stone: Color) -> void:
	# Studio / Café De Kat: the big sign and a stone surround for the WorldDoor.
	draw_rect(Rect2(x0 + 4, -GH - 34, W - 8, 24), WorldPalette.NAVY)
	draw_rect(Rect2(x0 + 4, -GH - 34, W - 8, 1), WorldPalette.LIT)
	draw_string(ThemeDB.fallback_font, Vector2(x0 + 4, -GH - 16), sign_text, HORIZONTAL_ALIGNMENT_CENTER, W - 8, 16, WorldPalette.LIT)
	var cx := x0 + W / 2.0
	draw_rect(Rect2(cx - 30, -GH + 4, 60, GH - 4), stone)
	for lx in [cx - 40, cx + 34]:
		draw_rect(Rect2(lx, -60, 6, 12), PixelArt.OUTLINE)
		draw_rect(Rect2(lx + 1, -58, 4, 8), WorldPalette.LIT)


func _terrace(cx: float, rng: RandomNumberGenerator) -> void:
	var uc: Color = [WorldPalette.B2, WorldPalette.W4, WorldPalette.G1][rng.randi_range(0, 2)]
	for k in 2:
		var tx := cx - 22 + k * 40
		draw_rect(Rect2(tx - 1, -46, 2, 34), WorldPalette.R1)
		WorldPalette.triangle(self, tx - 18, -44, 36, 8, uc)
		draw_rect(Rect2(tx - 18, -44, 36, 2), uc.darkened(0.2))
		draw_rect(Rect2(tx - 8, -14, 16, 2), WorldPalette.W1)           # table
		draw_rect(Rect2(tx - 1, -12, 2, 12), WorldPalette.W0)
		for side in [-1.0, 1.0]:                                         # chairs
			var chx: float = tx + side * 13
			draw_rect(Rect2(chx - 3, -9, 7, 2), WorldPalette.W0)
			draw_rect(Rect2(chx + (3.0 if side > 0 else -3.0), -18, 1, 18), WorldPalette.W0)
			draw_rect(Rect2(chx - 3, -7, 1, 7), WorldPalette.W0)
		if rng.randf() < 0.6:                                            # glasses
			draw_rect(Rect2(tx - 5, -18, 2, 4), WorldPalette.O2)
			draw_rect(Rect2(tx + 3, -18, 2, 4), WorldPalette.W4)


func _aboard(x: float, rng: RandomNumberGenerator) -> void:
	draw_line(Vector2(x, 0), Vector2(x + 6, -24), WorldPalette.W0, 2.0)
	draw_line(Vector2(x + 12, 0), Vector2(x + 6, -24), WorldPalette.W0, 2.0)
	draw_rect(Rect2(x + 2, -21, 9, 14), WorldPalette.T0)
	for k in 3:
		draw_rect(Rect2(x + 3, -19 + k * 4, rng.randi_range(4, 7), 1), WorldPalette.W4)


func _plant(x: float) -> void:
	draw_rect(Rect2(x, -10, 8, 10), WorldPalette.B2)
	draw_rect(Rect2(x - 1, -11, 10, 2), WorldPalette.B3)
	WorldPalette.disc(self, x + 4, -16, 5, WorldPalette.T3)
	WorldPalette.disc(self, x + 3, -18, 3, WorldPalette.G2)


func _bike(x: float, y: float, rng: RandomNumberGenerator) -> void:
	var fc: Color = [WorldPalette.T0, WorldPalette.B0, WorldPalette.T1, WorldPalette.W4][rng.randi_range(0, 3)]
	draw_arc(Vector2(x, y - 10), 9, 0, TAU, 16, PixelArt.OUTLINE, 2.0)
	draw_arc(Vector2(x + 30, y - 10), 9, 0, TAU, 16, PixelArt.OUTLINE, 2.0)
	draw_line(Vector2(x, y - 10), Vector2(x + 12, y - 22), fc, 2.0)
	draw_line(Vector2(x + 12, y - 22), Vector2(x + 30, y - 10), fc, 2.0)
	draw_line(Vector2(x + 12, y - 22), Vector2(x + 14, y - 10), fc, 2.0)
	draw_line(Vector2(x + 14, y - 10), Vector2(x, y - 10), fc, 2.0)
	draw_line(Vector2(x + 26, y - 26), Vector2(x + 30, y - 10), fc, 2.0)
	draw_rect(Rect2(x + 22, y - 28, 9, 2), PixelArt.OUTLINE)
	draw_rect(Rect2(x + 9, y - 25, 7, 2), WorldPalette.W0)
