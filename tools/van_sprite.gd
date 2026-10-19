extends SceneTree
## Draws the band van (facing right) as a pixel sprite sheet:
## public/assets/vehicles/band_van.png, 4 frames of 112x56 (wheels turn).
## Boxy 70s/80s panel van (body), detailed like the reference (outline,
## highlights, chrome, glass reflections, retro stripe, hubcaps, shadow).
## Also writes docs/art/band_van_preview_4x.png and a street preview.
## Run: Summer --headless --path . --script res://tools/van_sprite.gd

const FW := 112
const FH := 56
const FRAMES := 4
const GROUND := 50                          # y of the tyre bottoms in the frame

# Palette (docs/art-style.md + van ramp)
const OUTLINE := Color("0e0f14")
const BODY := Color("262a36")
const BODY_HI := Color("3c4256")
const BODY_TOP := Color("59627d")
const BODY_SHADE := Color("1a1c25")
const STRIPE_A := Color("e07a2e")
const STRIPE_B := Color("f2a65a")
const STRIPE_LINE := Color("f2e8da")
const GLASS := Color("34507a")
const GLASS_DARK := Color("233756")
const GLASS_HI := Color("8fb8e0")
const CHROME := Color("c8ccd4")
const CHROME_DARK := Color("8a8e98")
const HEAD := Color("f6e7a0")
const INDICATOR := Color("f2a65a")
const TAIL := Color("d83a32")
const TYRE := Color("1b1b20")
const TYRE_SIDE := Color("2e2e36")
const HUB := Color("b8bcc4")
const HUB_DARK := Color("6e7280")
const SHADOW := Color(0.05, 0.06, 0.1, 0.35)
const LOGO := Color("f2e8da")

var img: Image


func _initialize() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://public/assets/vehicles"))
	var sheet := Image.create(FW * FRAMES, FH, false, Image.FORMAT_RGBA8)
	for f in FRAMES:
		img = Image.create(FW, FH, false, Image.FORMAT_RGBA8)
		_van(f)
		sheet.blit_rect(img, Rect2i(0, 0, FW, FH), Vector2i(f * FW, 0))
	sheet.save_png(ProjectSettings.globalize_path("res://public/assets/vehicles/band_van.png"))
	# 4x preview of frame 0 on a neutral background
	var prev := Image.create(FW, FH, false, Image.FORMAT_RGBA8)
	prev.fill(Color("8f9be0"))
	prev.blend_rect(sheet, Rect2i(0, 0, FW, FH), Vector2i.ZERO)
	prev.resize(FW * 4, FH * 4, Image.INTERPOLATE_NEAREST)
	prev.save_png(ProjectSettings.globalize_path("res://docs/art/band_van_preview_4x.png"))
	# On the city mock's street (feet line y 206)
	var city := Image.load_from_file(ProjectSettings.globalize_path("res://docs/art/style_mock_city.png"))
	if city:
		city.blend_rect(sheet, Rect2i(0, 0, FW, FH), Vector2i(150, 206 - GROUND))
		city.resize(city.get_width() * 2, city.get_height() * 2, Image.INTERPOLATE_NEAREST)
		city.save_png(ProjectSettings.globalize_path("res://docs/art/band_van_on_street_2x.png"))
	print("van saved")
	quit()


func _van(frame: int) -> void:
	# Shadow on the road
	for x in range(8, 104):
		var fade := 1.0 - absf(x - 56.0) / 52.0
		_px(x, GROUND, Color(SHADOW.r, SHADOW.g, SHADOW.b, SHADOW.a * (0.5 + fade * 0.5)))
		_px(x, GROUND + 1, Color(SHADOW.r, SHADOW.g, SHADOW.b, SHADOW.a * 0.5 * fade))

	# --- Body silhouette (outline first, then fill) ---------------------------
	# Box: x 6..78, roof y 8. Cab roof to x 84, windscreen slopes to (96, 22),
	# short hood to (104, 26), nose down to y 44.
	var top := 8
	var bottom := 44
	for y in range(top, bottom + 1):
		var x0 := 6
		if y < top + 4:                     # rounded rear top corner
			x0 = 6 + (top + 4 - y)
		var x1 := _front_edge(y)
		_hline(x0, x1, y, BODY)
		_px(x0 - 1, y, OUTLINE)
		_px(x1 + 1, y, OUTLINE)
	_hline(10, 84, top - 1, OUTLINE)        # roof outline
	for i in 4:
		_px(6 + i, top + 3 - i, OUTLINE)
	_hline(6, 104, bottom + 1, OUTLINE)     # sill outline

	# Shading: roof shine, upper highlight band, lower shade
	_hline(11, 83, top, BODY_TOP)
	_hline(8, 82, top + 1, BODY_HI)
	for y in range(top + 2, top + 5):
		_hline(7, _front_edge(y) - 1, y, BODY_HI.lerp(BODY, (y - top - 2) / 3.0))
	for y in range(36, bottom + 1):
		_hline(6, _front_edge(y), y, BODY_SHADE if y > 39 else BODY.lerp(BODY_SHADE, 0.5))

	# Retro two-tone stripe along the side (orange + light orange, cream line)
	_hline(6, 101, 27, STRIPE_LINE)
	_hline(6, 102, 28, STRIPE_A)
	_hline(6, 102, 29, STRIPE_A)
	_hline(6, 102, 30, STRIPE_B)
	_hline(6, 102, 31, STRIPE_LINE.darkened(0.25))

	# Panel lines: sliding door, cab door
	_vline(58, top + 3, 41, OUTLINE.lerp(BODY, 0.4))
	_vline(78, top + 3, 41, OUTLINE.lerp(BODY, 0.4))
	_hline(60, 63, 22, CHROME_DARK)         # sliding door handle
	_hline(80, 83, 23, CHROME_DARK)         # cab door handle

	# Rear side windows (band van: two tinted windows) and the cab window
	_window(14, 12, 18, 9)
	_window(36, 12, 18, 9)
	_cab_window()

	# Logo on the sliding door: a little cat head + "JTC" bars
	_cat_logo(63, 15)

	# Front: grille, headlight, indicator, chrome bumper
	for y in range(30, 40):
		_px(103, y, OUTLINE)
		_px(104, y, CHROME_DARK)
	for y in range(31, 38, 2):
		_hline(98, 102, y, CHROME_DARK)
	_hline(98, 102, 30, CHROME)
	_rect(100, 27, 4, 3, HEAD)
	_px(103, 27, Color.WHITE)
	_rect(100, 33, 3, 2, INDICATOR)
	_rect(95, 40, 11, 4, CHROME)            # front bumper
	_hline(95, 105, 43, CHROME_DARK)
	_hline(95, 105, 39, OUTLINE)
	# Rear: tail light, bumper
	_rect(5, 24, 2, 5, TAIL)
	_rect(2, 40, 8, 4, CHROME)
	_hline(2, 9, 43, CHROME_DARK)
	_hline(2, 9, 39, OUTLINE)
	# Mirror
	_rect(87, 17, 3, 4, OUTLINE)
	_px(88, 18, CHROME)

	# Wheel arches + wheels
	_wheel(24, frame)
	_wheel(88, frame)


## x of the body's front edge at row y (box, windscreen slope, hood, nose).
func _front_edge(y: int) -> int:
	if y < 10:
		return 84
	if y < 22:
		return 84 + int((y - 10) * 12 / 12.0)   # windscreen: 84 -> 96
	if y < 26:
		return 96 + (y - 22) * 2                # hood: 96 -> 104
	return 104 if y < 40 else 104


func _cab_window() -> void:
	# Door window under the sloping windscreen, plus the windscreen itself.
	for y in range(11, 21):
		var x1 := _front_edge(y) - 2
		_hline(80, x1, y, GLASS if y > 13 else GLASS.lerp(GLASS_HI, 0.3))
	for y in range(11, 21):
		_px(79, y, OUTLINE)
		_px(_front_edge(y) - 1, y, OUTLINE)
	_hline(79, 85, 10, OUTLINE)
	_hline(79, 94, 21, OUTLINE)
	# reflection streak
	for i in 6:
		_px(86 + i, 12 + i, GLASS_HI)
		_px(87 + i, 12 + i, GLASS_HI.lerp(GLASS, 0.5))
	_vline(85, 11, 20, OUTLINE.lerp(GLASS, 0.5))   # door pillar


func _window(x: int, y: int, w: int, h: int) -> void:
	_rect(x - 1, y - 1, w + 2, h + 2, OUTLINE)
	_rect(x, y, w, h, GLASS)
	_rect(x, y + h - 3, w, 3, GLASS_DARK)
	for i in 4:                             # diagonal reflection
		_px(x + 3 + i, y + 5 - i, GLASS_HI)
		_px(x + 4 + i, y + 5 - i, GLASS_HI.lerp(GLASS, 0.5))
	_hline(x, x + w - 1, y, GLASS_HI.lerp(GLASS, 0.6))


func _cat_logo(x: int, y: int) -> void:
	# ears
	_px(x, y, LOGO); _px(x + 6, y, LOGO)
	_hline(x, x + 1, y + 1, LOGO); _hline(x + 5, x + 6, y + 1, LOGO)
	_rect(x, y + 2, 7, 5, LOGO)
	_px(x + 2, y + 4, BODY); _px(x + 4, y + 4, BODY)     # eyes
	_px(x + 3, y + 5, STRIPE_A)                          # nose
	_hline(x + 9, x + 13, y + 3, LOGO)                   # "text" bars
	_hline(x + 9, x + 12, y + 5, LOGO.darkened(0.3))


func _wheel(cx: int, frame: int) -> void:
	var cy := GROUND - 7
	# arch (dark) above the tyre
	for a in range(0, 181, 6):
		var t := deg_to_rad(180 + a)
		_px(cx + int(cos(t) * 10), cy + int(sin(t) * 10), OUTLINE)
		_px(cx + int(cos(t) * 9), cy + int(sin(t) * 9), BODY_SHADE.darkened(0.4))
	_disc(cx, cy, 9, BODY_SHADE.darkened(0.5))
	_disc(cx, cy, 7, TYRE)
	_ring(cx, cy, 6, TYRE_SIDE)
	_disc(cx, cy, 4, HUB)
	_ring(cx, cy, 4, HUB_DARK)
	# 4 lug/spoke marks, rotated per frame
	for k in 4:
		var t := deg_to_rad(frame * 22.5 + k * 90.0)
		_px(cx + int(round(cos(t) * 2.4)), cy + int(round(sin(t) * 2.4)), HUB_DARK)
	_px(cx, cy, CHROME_DARK)
	_px(cx - 2, cy - 3, Color.WHITE)        # glint


# --- Primitives ---------------------------------------------------------------

func _px(x: int, y: int, c: Color) -> void:
	if x >= 0 and y >= 0 and x < FW and y < FH:
		if c.a < 1.0:
			img.set_pixel(x, y, img.get_pixel(x, y).blend(c))
		else:
			img.set_pixel(x, y, c)


func _hline(x0: int, x1: int, y: int, c: Color) -> void:
	for x in range(x0, x1 + 1):
		_px(x, y, c)


func _vline(x: int, y0: int, y1: int, c: Color) -> void:
	for y in range(y0, y1 + 1):
		_px(x, y, c)


func _rect(x: int, y: int, w: int, h: int, c: Color) -> void:
	for yy in range(y, y + h):
		_hline(x, x + w - 1, yy, c)


func _disc(cx: int, cy: int, r: int, c: Color) -> void:
	for y in range(-r, r + 1):
		var half := int(sqrt(maxf(r * r - y * y, 0.0)))
		_hline(cx - half, cx + half, cy + y, c)


func _ring(cx: int, cy: int, r: int, c: Color) -> void:
	for a in 32:
		var t := a / 32.0 * TAU
		_px(cx + int(round(cos(t) * r)), cy + int(round(sin(t) * r)), c)
