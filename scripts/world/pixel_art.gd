class_name PixelArt
extends RefCounted
## Shared bits for world art drawn at the band sprites' pixel density
## ("art px" = half a world px; draw with draw_set_transform scale 0.5).
## Tiling surface textures (white, tinted by modulate) are built once.
## The node that tiles them needs texture_repeat = ENABLED.

const ART := 0.5                            # world px per art px
const OUTLINE := Color("1d1a22")

static var _brick: ImageTexture
static var _slate: ImageTexture
static var _plaster: ImageTexture
static var _cobble: ImageTexture


## 16x8 bricks: mortar every 4 rows, joints staggered, a few odd bricks.
static func brick() -> ImageTexture:
	if _brick == null:
		var img := Image.create(16, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		var mortar := Color(0.80, 0.80, 0.80)
		for x in 16:
			img.set_pixel(x, 3, mortar)
			img.set_pixel(x, 7, mortar)
		for y in 3:
			img.set_pixel(0, y, mortar)
			img.set_pixel(8, y + 4, mortar)
		for p in [Vector2i(3, 1), Vector2i(4, 1), Vector2i(12, 5), Vector2i(13, 5)]:
			img.set_pixel(p.x, p.y, Color(0.92, 0.92, 0.92))
		for p in [Vector2i(10, 1), Vector2i(2, 5)]:
			img.set_pixel(p.x, p.y, Color.WHITE)
		_brick = ImageTexture.create_from_image(img)
	return _brick


## 12x8 slates for roofs.
static func slate() -> ImageTexture:
	if _slate == null:
		var img := Image.create(12, 8, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		var joint := Color(0.72, 0.72, 0.76)
		for x in 12:
			img.set_pixel(x, 3, joint)
			img.set_pixel(x, 7, joint)
		for y in 3:
			img.set_pixel(0, y, joint)
			img.set_pixel(6, y + 4, joint)
		for x in 5:
			img.set_pixel(x + 1, 0, Color(1, 1, 1).darkened(0.04))
		_slate = ImageTexture.create_from_image(img)
	return _slate


## 16x16 plaster with a faint grain.
static func plaster() -> ImageTexture:
	if _plaster == null:
		var img := Image.create(16, 16, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		var rng := RandomNumberGenerator.new()
		rng.seed = 4
		for i in 14:
			img.set_pixel(rng.randi_range(0, 15), rng.randi_range(0, 15), Color(0.95, 0.95, 0.95))
		_plaster = ImageTexture.create_from_image(img)
	return _plaster


## 8x6 cobbles / pavers.
static func cobble() -> ImageTexture:
	if _cobble == null:
		var img := Image.create(8, 6, false, Image.FORMAT_RGBA8)
		img.fill(Color.WHITE)
		var joint := Color(0.78, 0.78, 0.8)
		for x in 8:
			img.set_pixel(x, 2, joint)
			img.set_pixel(x, 5, joint)
		img.set_pixel(3, 0, joint); img.set_pixel(3, 1, joint)
		img.set_pixel(7, 3, joint); img.set_pixel(7, 4, joint)
		_cobble = ImageTexture.create_from_image(img)
	return _cobble


## A street tree in art px at (x, base): trunk with a fork, tree guard, a
## crown of leaf clusters in three tones with a dark rim, light from the left.
static func tree(ci: CanvasItem, x: float, base: float, size: float, rng: RandomNumberGenerator, haze := 0.0) -> void:
	var h := leaves()
	var trunk := Color("5a4232").lerp(WorldPalette.HAZE, haze)
	var th := size * 1.1
	ci.draw_rect(Rect2(x - 3, base - th, 6, th), trunk)
	ci.draw_rect(Rect2(x + 1, base - th, 2, th), trunk.darkened(0.3))
	ci.draw_line(Vector2(x, base - th * 0.6), Vector2(x - size * 0.35, base - th - size * 0.2), trunk, 3.0)
	ci.draw_line(Vector2(x, base - th * 0.7), Vector2(x + size * 0.3, base - th - size * 0.25), trunk, 3.0)
	var cy := base - th - size * 0.55
	var blobs := []
	for i in 9:
		var a := TAU * i / 9.0 + rng.randf_range(-0.3, 0.3)
		var d := size * rng.randf_range(0.25, 0.5)
		blobs.append([Vector2(x + cos(a) * d * 1.2, cy + sin(a) * d * 0.8), size * rng.randf_range(0.32, 0.45)])
	blobs.append([Vector2(x, cy), size * 0.5])
	for b in blobs:                          # dark rim
		ci.draw_circle(b[0], b[1] + 2.0, h[0].darkened(0.45).lerp(WorldPalette.HAZE, haze))
	for b in blobs:
		ci.draw_circle(b[0], b[1], h[0].lerp(WorldPalette.HAZE, haze))
	for b in blobs:                          # lit side up-left
		ci.draw_circle(b[0] + Vector2(-b[1] * 0.25, -b[1] * 0.3), b[1] * 0.62, h[1].lerp(WorldPalette.HAZE, haze))
	for b in blobs:
		if rng.randf() < 0.6:
			ci.draw_circle(b[0] + Vector2(-b[1] * 0.4, -b[1] * 0.45), b[1] * 0.28, h[2].lerp(WorldPalette.HAZE, haze))
	# leaf speckle
	for i in int(size):
		var p := Vector2(x + rng.randf_range(-size, size), cy + rng.randf_range(-size * 0.7, size * 0.6))
		ci.draw_rect(Rect2(p, Vector2(2, 2)), h[rng.randi_range(0, 2)].darkened(0.15).lerp(WorldPalette.HAZE, haze))
	# iron tree guard and the pit
	ci.draw_rect(Rect2(x - 9, base - 2, 18, 2), Color("3a3330"))
	for k in 4:
		ci.draw_rect(Rect2(x - 8 + k * 5, base - 16, 1, 14), OUTLINE)
	ci.draw_rect(Rect2(x - 9, base - 16, 18, 1), OUTLINE)


static func leaves() -> Array:
	return [Color("3f6b34"), Color("5d8c3e"), Color("8dbc52")]
