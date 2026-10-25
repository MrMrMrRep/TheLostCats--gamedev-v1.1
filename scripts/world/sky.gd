class_name WorldSky
extends CanvasLayer
## Screen-space sky behind everything, in the style v3 look: a gradient of
## palette colours with ordered-dither seams and light streaks, the banded sun,
## the moon and stars at night, and two layers of shaded clouds that drift
## slowly and shift a little with the camera (parallax). Independent of the camera zoom, so it
## always fills the screen. The day/night cycle (WorldDayCycle) sets its
## colours and the time via set_time(); without it, it's a sunny morning.

const VIEW := Vector2(1024, 360)            # drawn wider than the base screen: phones are wider than 16:9
const FAR_PARALLAX := 0.04
const NEAR_PARALLAX := 0.1
const FAR_DRIFT := 3.0                      # px/s
const NEAR_DRIFT := 7.0

var _gradient: _Gradient
var _stars: _Stars
var _sun: _Disc
var _moon: _Disc
var _far: _CloudBand
var _near: _CloudBand


func _ready() -> void:
	layer = -20
	_gradient = _Gradient.new()
	add_child(_gradient)
	_stars = _Stars.new()
	add_child(_stars)
	_moon = _Disc.new()
	_moon.moon = true
	add_child(_moon)
	_sun = _Disc.new()
	add_child(_sun)
	_far = _CloudBand.new()
	_far.setup(11, 0.75, 30.0, 110.0, 7)
	add_child(_far)
	_near = _CloudBand.new()
	_near.setup(23, 1.1, 20.0, 150.0, 5)
	add_child(_near)
	set_time(8.0, [WorldPalette.SKY_TOP, WorldPalette.SKY_MID, WorldPalette.SKY_LOW], 0.0, Color.WHITE)


## Colours [top, mid, low], clock hour, night 0..1, tint for the clouds.
func set_time(hour: float, colours: Array[Color], night: float, cloud_tint: Color) -> void:
	_gradient.set_colours(colours)
	_stars.set_amount(night)
	# The sun crosses from the east (right) in the morning to the west at dusk;
	# the moon follows the same path through the night.
	var t := (hour - 6.0) / 14.5
	_sun.visible = t > -0.05 and t < 1.05
	var w := ScreenFit.width(_gradient)
	_sun.position = Vector2(lerpf(w - 40.0, 40.0, t), 200.0 - sin(clampf(t, 0.0, 1.0) * PI) * 170.0).round()
	_sun.warm = 1.0 - sin(clampf(t, 0.0, 1.0) * PI)
	var m := fposmod(hour - 19.0, 24.0) / 12.0
	_moon.visible = m < 1.0 and night > 0.01
	_moon.position = Vector2(lerpf(w - 40.0, 40.0, m), 210.0 - sin(m * PI) * 160.0).round()
	_moon.modulate.a = night
	_far.modulate = cloud_tint
	_near.modulate = cloud_tint


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	var cx := cam.get_screen_center_position().x if cam else 0.0
	var t := Time.get_ticks_msec() / 1000.0
	_far.offset_x = -(cx * FAR_PARALLAX + t * FAR_DRIFT)
	_near.offset_x = -(cx * NEAR_PARALLAX + t * NEAR_DRIFT)


class _Gradient:
	extends Control

	# Row of each colour stop on the screen (the mocks' sky, scaled to 360 rows).
	const ROWS := [0, 34, 104, 178, 238, 274, 304]
	const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]
	const STREAKS := [[40, 186, 160, 0], [300, 196, 110, 1], [520, 178, 200, 0], [760, 200, 140, 1],
		[120, 222, 150, 2], [420, 230, 190, 0], [680, 220, 100, 2], [900, 236, 130, 0]]

	var top := WorldPalette.SKY_TOP
	var mid := WorldPalette.SKY_MID
	var low := WorldPalette.SKY_LOW
	var _stops: Array = []
	var _tex: ImageTexture

	## Rebuilds the picture only when a colour stop lands on another palette colour.
	func set_colours(c: Array[Color]) -> void:
		top = c[0]
		mid = c[1]
		low = c[2]
		var stops := _make_stops()
		if stops != _stops:
			_stops = stops
			_bake()
			queue_redraw()

	func _ready() -> void:
		size = WorldSky.VIEW
		mouse_filter = Control.MOUSE_FILTER_IGNORE
		if _stops.is_empty():
			_stops = _make_stops()
			_bake()

	## Seven palette colours from the three of the hour: top -> mid -> low, then
	## (by day) the warm haze over the roofs.
	func _make_stops() -> Array:
		var out := []
		for i in 5:
			var t := i / 4.0
			var c := top.lerp(mid, t * 2.0) if t < 0.5 else mid.lerp(low, (t - 0.5) * 2.0)
			out.append(WorldPalette.nearest(c))
		var warm := clampf((low.get_luminance() - 0.35) / 0.45, 0.0, 1.0)
		out.append(WorldPalette.nearest(low.lerp(WorldPalette.W4, 0.9 * warm)))
		out.append(WorldPalette.nearest(low.lerp(WorldPalette.B4, 0.85 * warm)))
		return out

	func _bake() -> void:
		var w := int(WorldSky.VIEW.x)
		var h := int(WorldSky.VIEW.y)
		var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
		for i in _stops.size():
			var y0: int = ROWS[i]
			var y1: int = ROWS[i + 1] if i + 1 < ROWS.size() else h
			img.fill_rect(Rect2i(0, y0, w, y1 - y0), _stops[i])
		for i in range(1, _stops.size()):            # dithered seams, 12 rows each
			if _stops[i] == _stops[i - 1]:
				continue
			for d in range(-6, 6):
				var y: int = ROWS[i] + d
				if y < 0 or y >= h:
					continue
				var lim := (d + 6.5) / 13.0
				for x in w:
					var b: float = (BAYER[(y & 3) * 4 + (x & 3)] + 0.5) / 16.0
					img.set_pixel(x, y, _stops[i] if b < lim else _stops[i - 1])
		var warm: bool = _stops[5] != _stops[4]
		if warm:                                     # long thin light streaks low in the sky
			var cols := [WorldPalette.W4, WorldPalette.T7, WorldPalette.W5]
			for st: Array in STREAKS:
				var c: Color = cols[st[3]]
				img.fill_rect(Rect2i(st[0], st[1], st[2], 2), c)
				img.fill_rect(Rect2i(st[0] + 12, st[1] + 2, st[2] - 30, 1), c)
				img.fill_rect(Rect2i(st[0] - 6, st[1] + 1, 6, 1), c)
		if _tex == null:
			_tex = ImageTexture.create_from_image(img)
		else:
			_tex.update(img)

	func _draw() -> void:
		if _tex:
			# Repeat sideways if the screen is wider than the picture.
			var w := maxf(get_viewport_rect().size.x, WorldSky.VIEW.x)
			var x := 0.0
			while x < w:
				draw_texture(_tex, Vector2(x, 0))
				x += WorldSky.VIEW.x


## The sun (banded, with a dithered halo; warmer near the horizon) or the moon.
class _Disc:
	extends Node2D

	var moon := false
	var warm := 0.0:
		set(value):
			if absf(value - warm) > 0.02:
				warm = value
				modulate = Color.WHITE.lerp(Color(1.0, 0.72, 0.5), warm * 0.8)

	func _draw() -> void:
		if moon:
			WorldPalette.disc(self, 0, 0, 16, Color(WorldPalette.T6, 0.12))
			WorldPalette.disc(self, 0, 0, 11, WorldPalette.W4)
			draw_rect(Rect2(-4, -2, 3, 3), WorldPalette.W3)
			draw_rect(Rect2(2, 3, 2, 2), WorldPalette.W3)
			return
		V3Cache.art("sky_sun", func() -> V3Art: return V3Painter.sun_sprite(22)).draw(self, Vector2.ZERO, 1.0)


## Stars, fading in with the night.
class _Stars:
	extends Node2D

	var _pts: Array[Vector3] = []
	var _amount := 0.0

	func _ready() -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = 404
		for i in 90:
			_pts.append(Vector3(rng.randf_range(0, WorldSky.VIEW.x), rng.randf_range(0, WorldSky.VIEW.y * 0.6), rng.randf_range(0.35, 1.0)))

	func set_amount(night: float) -> void:
		if absf(night - _amount) > 0.02 or (night == 0.0) != (_amount == 0.0):
			_amount = night
			visible = night > 0.0
			queue_redraw()

	func _draw() -> void:
		for s in _pts:
			draw_rect(Rect2(int(s.x), int(s.y), 1, 1), Color(1, 1, 0.92, s.z * _amount))


## A repeating band of clouds, redrawn only when the offset moves a pixel.
class _CloudBand:
	extends Node2D

	const PERIOD := 960.0
	var offset_x := 0.0:
		set(value):
			var snapped := floorf(value)
			if snapped != offset_x:
				offset_x = snapped
				position.x = fposmod(offset_x, PERIOD) - PERIOD
	var _clouds: Array = []

	func setup(seed_value: int, scale_: float, y_min: float, y_max: float, count: int) -> void:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_value
		for i in count:
			_clouds.append(Vector3(i * PERIOD / count + rng.randf_range(-40, 40), rng.randf_range(y_min, y_max), scale_ * rng.randf_range(0.7, 1.2)))
		queue_redraw()

	func _draw() -> void:
		for rep in 3:                       # tile so the band always covers the view
			for c in _clouds:
				_cloud(c.x + rep * PERIOD, c.y, c.z)

	func _cloud(cx: float, cy: float, s: float) -> void:
		# Shaded v3 clouds in four sizes (baked once).
		var k := clampi(int(round((s - 0.5) / 0.25)), 0, 3)
		var art := V3Cache.art("sky_cloud%d" % k, func() -> V3Art: return V3Painter.cloud_sprite(0.9 + k * 0.35))
		art.draw(self, Vector2(roundf(cx), roundf(cy)), 1.0)
