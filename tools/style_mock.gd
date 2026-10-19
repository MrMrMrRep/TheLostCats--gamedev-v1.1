extends SceneTree
## Renders the world-map style concept as 640x360 pixel mocks (city + polder)
## into docs/art/. Same palette and layer stack as docs/art-style.md.
## Run: Summer --headless --path . --script res://tools/style_mock.gd

const W := 640
const H := 360
const STREET_Y := 206                       # top of the street (feet line)
const WATER_Y := 228                        # top of the canal / ditch

# --- Palette (docs/art-style.md) ----------------------------------------------
const SKY_TOP := Color("7fb0ea")
const SKY_MID := Color("a9cbf2")
const SKY_LOW := Color("d4e5f8")
const CLOUD := Color("f6f9fe")
const CLOUD_SHADE := Color("d3e0f3")
const CLOUD_DARK := Color("b4c8e6")
const SUN := Color("fff1b8")
const HAZE := Color("9db6d8")
const HAZE_DARK := Color("86a2c9")
const NAVY := Color("232c42")
const GLASS := Color("1e2433")
const LIT := Color("f4cf78")
const TRIM := Color("f2e8da")
const WHITE := Color("fbf8f2")
const ROOF := Color("3b2522")
const FACADES := [Color("5b7fa6"), Color("8fb0d2"), Color("e07a2e"), Color("d08a72"),
	Color("b8604a"), Color("4e2c26"), Color("5c4149"), Color("c9a15a"), Color("41587a"), Color("f2a65a")]
const COBBLE := Color("8a8292")
const COBBLE_DARK := Color("6c6476")
const CURB := Color("b9b1bb")
const QUAY := Color("6f6a72")
const QUAY_DARK := Color("524e58")
const RAIL := Color("2a2830")
const WATER := Color("2b5779")
const WATER_DEEP := Color("1f4060")
const WATER_HI := Color("9cc4e4")
const LEAF := [Color("3f6b34"), Color("5d8c3e"), Color("86b44f")]
const TRUNK := Color("4a3426")
const GRASS := [Color("6ea142"), Color("8dbc52"), Color("a9cf63")]
const FIELD_FAR := Color("9cc06a")
const DITCH := Color("3f7396")
const BARN := Color("a8432f")
const BARN_DARK := Color("6b3a2a")
const MILL := Color("5a4636")
const SAIL := Color("efe6d2")
const TURBINE := Color("e9eef2")
const ROAD := Color("4a4a52")

var img: Image
var rng := RandomNumberGenerator.new()


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art"))
	_render_city()
	_save("city")
	_render_polder()
	_save("polder")
	quit()


func _save(name: String) -> void:
	img.save_png(ProjectSettings.globalize_path("res://docs/art/style_mock_%s.png" % name))
	var big := img.duplicate()
	big.resize(W * 2, H * 2, Image.INTERPOLATE_NEAREST)
	big.save_png(ProjectSettings.globalize_path("res://docs/art/style_mock_%s_2x.png" % name))
	print("saved ", name)


# --- City -------------------------------------------------------------------

func _render_city() -> void:
	img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	rng.seed = 7
	_sky()
	_sun(470, 46, 16)
	for c in [[60, 40, 1.0], [250, 26, 0.8], [520, 70, 1.1], [380, 90, 0.6]]:
		_cloud(c[0], c[1], c[2])
	_skyline()
	_back_row()
	# Trees between the rows.
	for x in [30, 140, 300, 455, 600]:
		_tree(x, STREET_Y - 2, 16)
	# Play layer: canal houses on the street.
	var x := -6
	var i := 0
	while x < W:
		var w := rng.randi_range(40, 56)
		var h := rng.randi_range(104, 132)
		var c: Color = FACADES[(i * 3 + rng.randi_range(0, 2)) % FACADES.size()]
		_house(x, STREET_Y, w, h, c, rng.randi_range(0, 3), i % 4 == 1)
		x += w
		i += 1
	_street()
	_lamp(110); _lamp(390)
	_bike(200); _bike(214)
	_band(268)
	_quay()
	_canal()
	_houseboat(420, WATER_Y + 4)


func _sky() -> void:
	for y in H:
		for x in W:
			var t := float(y) / STREET_Y
			var a := SKY_TOP.lerp(SKY_MID, clampf(t * 1.6, 0.0, 1.0))
			var b := SKY_MID.lerp(SKY_LOW, clampf((t - 0.55) * 2.2, 0.0, 1.0))
			var c := a if t < 0.6 else b
			# 2x2 ordered dither at band edges
			if int(t * 24) % 2 == 0 and (x + y) % 2 == 0:
				c = c.lerp(SKY_LOW, 0.12)
			img.set_pixel(x, y, c)


func _sun(cx: int, cy: int, r: int) -> void:
	_disc(cx, cy, r + 6, SUN.lerp(SKY_MID, 0.75))
	_disc(cx, cy, r + 3, SUN.lerp(SKY_MID, 0.45))
	_disc(cx, cy, r, SUN)


func _cloud(cx: int, cy: int, s: float) -> void:
	var puffs := [[0, 0, 14], [16, -6, 16], [34, -2, 13], [50, 2, 10], [-14, 4, 9], [24, 6, 12]]
	for p in puffs:
		_disc(cx + int(p[0] * s), cy + int(p[1] * s) + 3, int(p[2] * s), CLOUD_DARK)
	for p in puffs:
		_disc(cx + int(p[0] * s), cy + int(p[1] * s) + 1, int(p[2] * s), CLOUD_SHADE)
	for p in puffs:
		_disc(cx + int(p[0] * s) - 1, cy + int(p[1] * s) - 1, int(p[2] * s) - 2, CLOUD)


func _skyline() -> void:
	var base := STREET_Y - 70
	var x := 0
	while x < W:
		var w := rng.randi_range(14, 30)
		var h := rng.randi_range(18, 40)
		_rect(x, base - h, w, h + 80, HAZE)
		_gable_tip(x, base - h, w, HAZE)
		x += w
	for sx in [120, 410]:                   # church towers
		_rect(sx, base - 78, 12, 80, HAZE_DARK)
		_triangle(sx - 2, base - 78, 16, 22, HAZE_DARK)
		_rect(sx + 5, base - 106, 2, 8, HAZE_DARK)
	_rect(560, base - 70, 2, 70, HAZE_DARK)  # crane
	_rect(530, base - 70, 60, 2, HAZE_DARK)


func _back_row() -> void:
	var base := STREET_Y - 30
	var x := -4
	while x < W:
		var w := rng.randi_range(22, 30)
		var h := rng.randi_range(46, 70)
		var c: Color = FACADES[rng.randi_range(0, FACADES.size() - 1)].lerp(HAZE, 0.55)
		_rect(x, base - h, w, h + 30, c)
		_gable_tip(x, base - h, w, c)
		for r in int((h - 10) / 14):
			for k in 2:
				_rect(x + 5 + k * (w - 14), base - h + 8 + r * 14, 4, 6, GLASS.lerp(HAZE, 0.5))
		x += w


func _house(x: int, base: int, w: int, h: int, c: Color, gable: int, shop: bool) -> void:
	var top := base - h
	_rect(x, top, w, h, c)
	_rect(x + w - 2, top, 2, h, c.darkened(0.25))  # shade line at the party wall
	match gable:
		0:                                  # step gable
			_rect(x + w / 5, top - 8, w * 3 / 5, 8, c)
			_rect(x + w / 3, top - 15, w / 3, 7, c)
			_rect(x + w / 5 - 1, top - 8, w * 3 / 5 + 2, 1, TRIM)
			_rect(x + w / 3 - 1, top - 15, w / 3 + 2, 1, TRIM)
		1:                                  # bell gable with scrolls
			_triangle(x + 4, top, w - 8, 16, c)
			_rect(x + w / 2 - 4, top - 10, 8, 6, TRIM)
		2:                                  # neck gable
			_rect(x + w / 4, top - 14, w / 2, 14, c)
			_rect(x + w / 4 - 1, top - 15, w / 2 + 2, 2, TRIM)
		_:                                  # roof with tiles
			_triangle(x, top, w, 14, ROOF)
	_rect(x, top, w, 2, TRIM)               # cornice
	var cols := 3 if w > 46 else 2
	var gap: int = (w - 6 - cols * 8) / maxi(cols - 1, 1)
	var rows := int((h - 34) / 22)
	for r in rows:
		for k in cols:
			_window(x + 3 + k * (8 + gap), top + 8 + r * 22, 8, 13, rng.randf() < 0.18)
	var door_x := x + w / 2 - 4
	if shop:                                # awning + shop window
		for s in w / 4:
			_rect(x + 2 + s * 4, base - 26, 4, 5, Color("e07a2e") if s % 2 == 0 else WHITE)
		_rect(x + 3, base - 20, w - 14, 14, GLASS)
		_rect(x + 3, base - 20, w - 14, 1, TRIM)
		door_x = x + w - 10
	_rect(door_x, base - 18, 8, 18, NAVY)
	_rect(door_x - 1, base - 19, 10, 1, TRIM)
	_rect(door_x + 6, base - 10, 1, 1, LIT)
	_rect(x, base - 3, w, 3, c.darkened(0.35))  # plinth


func _window(x: int, y: int, w: int, h: int, lit: bool) -> void:
	_rect(x - 1, y - 1, w + 2, h + 2, TRIM)
	_rect(x, y, w, h, LIT if lit else GLASS)
	_rect(x + w / 2, y, 1, h, TRIM)
	_rect(x, y + h / 2, w, 1, TRIM)


func _street() -> void:
	_rect(0, STREET_Y, W, 14, COBBLE)
	for y in range(STREET_Y + 2, STREET_Y + 14, 3):
		for x in range(-(y % 2) * 3, W, 6):
			_rect(x, y, 4, 1, COBBLE_DARK)
	_rect(0, STREET_Y + 14, W, 2, CURB)


func _quay() -> void:
	_rect(0, STREET_Y + 16, W, WATER_Y - STREET_Y - 16, QUAY)
	for y in range(STREET_Y + 17, WATER_Y, 3):
		for x in range((y % 2) * 5, W, 10):
			_rect(x, y, 1, 3, QUAY_DARK)
	# railing along the canal
	for x in range(0, W, 10):
		_rect(x, STREET_Y + 8, 1, 8, RAIL)
	_rect(0, STREET_Y + 8, W, 1, RAIL)
	for x in range(30, W, 90):
		_rect(x, STREET_Y + 10, 3, 6, RAIL)  # bollards


func _canal() -> void:
	_reflect(WATER, WATER_DEEP, 0.42)


## Mirror of everything above the waterline, pulled toward the water colour,
## with small per-row jitter (deeper = more) and horizontal light streaks:
## the Kingdom Eighties look, no sine zigzags.
func _reflect(water: Color, deep: Color, tint: float) -> void:
	var src := img.duplicate()
	var jitter := [0, 0, 1, 0, 0, -1, 0, 1, 0, 0, -1, 0]
	for y in range(WATER_Y, H):
		var d := y - WATER_Y
		var sy := WATER_Y - 1 - d
		var amp := 1 + d / 40
		var shift: int = jitter[(d / 2 + rng.randi_range(0, 1)) % jitter.size()] * amp
		for x in W:
			var c := water
			if sy >= 0:
				c = src.get_pixel(clampi(x + shift, 0, W - 1), sy).lerp(deep, tint + d * 0.0015)
			img.set_pixel(x, y, c)
	# light streaks on the surface
	for i in 140:
		var sy2 := WATER_Y + 2 + rng.randi_range(0, H - WATER_Y - 3)
		var sx2 := rng.randi_range(0, W)
		var ln := rng.randi_range(3, 12)
		var col := WATER_HI if rng.randf() < 0.6 else deep.darkened(0.2)
		for k in ln:
			if sx2 + k < W:
				img.set_pixel(sx2 + k, sy2, img.get_pixel(sx2 + k, sy2).lerp(col, 0.65))
	_rect(0, WATER_Y, W, 1, WATER_HI.lerp(water, 0.4))


func _houseboat(x: int, y: int) -> void:
	_rect(x, y + 4, 96, 10, Color("2f3a4a"))
	_rect(x + 8, y - 8, 70, 12, Color("5d8c3e"))
	_rect(x + 8, y - 9, 70, 1, TRIM)
	for k in 5:
		_rect(x + 14 + k * 13, y - 5, 7, 6, LIT if k == 2 else GLASS)
	_rect(x - 4, y + 13, 104, 2, WATER_DEEP)


func _lamp(x: int) -> void:
	_rect(x, STREET_Y - 34, 2, 34, RAIL)
	_rect(x - 3, STREET_Y - 38, 8, 5, RAIL)
	_rect(x - 2, STREET_Y - 37, 6, 3, LIT)


func _bike(x: int) -> void:
	_ring(x, STREET_Y - 4, 4, Color("c8ccd4"))
	_ring(x + 12, STREET_Y - 4, 4, Color("c8ccd4"))
	_line(x, STREET_Y - 4, x + 6, STREET_Y - 9, Color("e07a2e"))
	_line(x + 6, STREET_Y - 9, x + 12, STREET_Y - 4, Color("e07a2e"))


## The band, for scale: the idle frame of the current sprite sheet, tinted.
func _band(x: int) -> void:
	var sheet := Image.load_from_file(ProjectSettings.globalize_path("res://public/assets/amwoods/character/char_blue.png"))
	if sheet == null:
		return
	var frame := sheet.get_region(Rect2i(18, 24, 22, 32))
	var tints := [Color.WHITE, Color("ff9a9a"), Color("9affb0"), Color("ffe08a"), Color("c9a0ff")]
	for i in 5:
		var f := frame.duplicate()
		for yy in f.get_height():
			for xx in f.get_width():
				var p: Color = f.get_pixel(xx, yy)
				if p.a > 0.0:
					f.set_pixel(xx, yy, p * tints[i])
		img.blend_rect(f, Rect2i(0, 0, 22, 32), Vector2i(x + i * 16, STREET_Y - 32))


# --- Polder -----------------------------------------------------------------

func _render_polder() -> void:
	img = Image.create(W, H, false, Image.FORMAT_RGBA8)
	rng.seed = 11
	_sky()
	_sun(140, 52, 16)
	for c in [[300, 34, 1.2], [520, 60, 0.9], [60, 84, 0.7]]:
		_cloud(c[0], c[1], c[2])
	var horizon := STREET_Y - 42
	_rect(0, horizon, W, STREET_Y - horizon, FIELD_FAR)
	for x in [60, 130, 470, 560, 620]:       # wind turbines on the horizon
		_turbine(x, horizon, 46)
	_rect(0, horizon + 6, W, 2, ROAD)       # distant highway
	for x in [90, 260, 410]:
		_rect(x, horizon + 4, 6, 2, Color("e07a2e") if x == 260 else WHITE)
	# Fields in stripes with ditches.
	for k in 4:
		var y := horizon + 10 + k * 7
		_rect(0, y, W, 7, GRASS[k % 3])
		_rect(0, y + 6, W, 1, DITCH)
	_farm(300, STREET_Y - 6)
	_windmill(470, STREET_Y - 4, 70)
	for c in [[180, 0], [205, 1], [232, 0], [540, 1]]:
		_cow(c[0], STREET_Y - 10, c[1] == 1)
	for x in [20, 90, 380, 610]:
		_tree(x, STREET_Y - 6, 12)
	# Dike road the band walks on, ditch with reeds in front.
	_rect(0, STREET_Y, W, 10, ROAD)
	for x in range(0, W, 24):
		_rect(x, STREET_Y + 5, 12, 1, WHITE.lerp(ROAD, 0.4))
	_rect(0, STREET_Y + 10, W, WATER_Y - STREET_Y - 10, GRASS[0])
	_band(240)
	_canal_ditch()
	for x in range(0, W, 37):
		_reeds(x, WATER_Y + 2)


func _canal_ditch() -> void:
	_reflect(DITCH, DITCH.darkened(0.35), 0.42)


func _turbine(x: int, base: int, h: int) -> void:
	_rect(x, base - h, 2, h, TURBINE)
	var hub := Vector2i(x + 1, base - h)
	for a in [0.3, 2.4, 4.5]:
		_line(hub.x, hub.y, hub.x + int(cos(a) * 16), hub.y + int(sin(a) * 16), TURBINE)


func _windmill(x: int, base: int, h: int) -> void:
	for y in h:                             # tapered tower
		var half := int(lerpf(14, 8, float(y) / h))
		_rect(x - half, base - y, half * 2, 1, MILL)
	_rect(x - 4, base - 14, 8, 14, NAVY)
	_rect(x - 16, base - h * 3 / 5, 32, 3, MILL.darkened(0.3))   # stage
	var hub := Vector2i(x, base - h - 2)
	_disc(hub.x, hub.y, 3, NAVY)
	for a in [0.6, 2.17, 3.74, 5.31]:
		var ex := hub.x + int(cos(a) * 34)
		var ey := hub.y + int(sin(a) * 34)
		_line(hub.x, hub.y, ex, ey, MILL.darkened(0.4))
		var px := int(-sin(a) * 5)
		var py := int(cos(a) * 5)
		for t in range(8, 34, 2):
			var bx := hub.x + int(cos(a) * t)
			var by := hub.y + int(sin(a) * t)
			_line(bx, by, bx + px, by + py, SAIL)


func _farm(x: int, base: int) -> void:
	_rect(x, base - 26, 60, 26, BARN)
	_triangle(x - 4, base - 26, 68, 18, BARN_DARK)
	_rect(x + 24, base - 16, 12, 16, BARN_DARK)
	_rect(x + 70, base - 22, 34, 22, WHITE)
	_triangle(x + 66, base - 22, 42, 14, ROOF)
	_window(x + 76, base - 16, 6, 7, false)
	_window(x + 92, base - 16, 6, 7, true)


func _cow(x: int, y: int, dark: bool) -> void:
	var body := Color("2a2a2e") if dark else Color("f2f0ea")
	var spot := Color("f2f0ea") if dark else Color("2a2a2e")
	_rect(x, y, 12, 6, body)
	_rect(x + 3, y + 1, 3, 3, spot)
	_rect(x + 11, y - 2, 4, 4, body)
	_rect(x + 1, y + 6, 1, 3, body); _rect(x + 9, y + 6, 1, 3, body)


func _reeds(x: int, y: int) -> void:
	for k in 5:
		_rect(x + k * 2, y - 6 - (k % 3) * 2, 1, 8 + (k % 3) * 2, GRASS[(k + 1) % 3])
	_rect(x + 4, y - 9, 2, 3, Color("6b4a2a"))


# --- Primitives -------------------------------------------------------------

func _tree(x: int, base: int, r: int) -> void:
	_rect(x - 1, base - r, 3, r, TRUNK)
	_disc(x, base - r - r / 2, r, LEAF[0])
	_disc(x - 3, base - r - r / 2 - 3, r - 3, LEAF[1])
	_disc(x - 5, base - r - r / 2 - 6, r - 7, LEAF[2])


func _gable_tip(x: int, y: int, w: int, c: Color) -> void:
	_rect(x + w / 4, y - 5, w / 2, 5, c)


func _rect(x: int, y: int, w: int, h: int, c: Color) -> void:
	var r := Rect2i(x, y, w, h).intersection(Rect2i(0, 0, W, H))
	if r.size.x > 0 and r.size.y > 0:
		img.fill_rect(r, c)


func _disc(cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(-r, r + 1):
		var half := int(sqrt(maxf(r * r - y * y, 0.0)))
		_rect(cx - half, cy + y, half * 2 + 1, 1, c)


func _ring(cx: int, cy: int, r: int, c: Color) -> void:
	for a in 24:
		var t := a / 24.0 * TAU
		_rect(cx + int(cos(t) * r), cy + int(sin(t) * r), 1, 1, c)


func _triangle(x: int, base: int, w: int, h: int, c: Color) -> void:
	for y in h:
		var half := int(w / 2.0 * (1.0 - float(y) / h))
		_rect(x + w / 2 - half, base - y - 1, half * 2, 1, c)


func _line(x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	var n := maxi(absi(x1 - x0), absi(y1 - y0))
	for i in n + 1:
		var t: float = float(i) / maxi(n, 1)
		_rect(int(lerpf(x0, x1, t)), int(lerpf(y0, y1, t)), 1, 1, c)
