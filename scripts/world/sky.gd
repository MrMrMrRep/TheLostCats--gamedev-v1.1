class_name WorldSky
extends CanvasLayer
## Screen-space sky behind everything: dithered gradient, the sun, the moon
## and stars at night, and two cloud layers that drift slowly and shift a
## little with the camera (parallax). Independent of the camera zoom, so it
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

	var top := WorldPalette.SKY_TOP
	var mid := WorldPalette.SKY_MID
	var low := WorldPalette.SKY_LOW

	## Redraws only when a colour visibly changed (the gradient is a lot of rects).
	func set_colours(c: Array[Color]) -> void:
		var d := 0.0
		for i in 3:
			var old: Color = [top, mid, low][i]
			d = maxf(d, absf(old.r - c[i].r) + absf(old.g - c[i].g) + absf(old.b - c[i].b))
		if d < 0.012:
			return
		top = c[0]
		mid = c[1]
		low = c[2]
		queue_redraw()

	func _ready() -> void:
		size = WorldSky.VIEW
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var p := WorldPalette
		for y in int(WorldSky.VIEW.y):
			var t := float(y) / (WorldSky.VIEW.y * 0.8)
			var c := top.lerp(mid, clampf(t * 1.6, 0.0, 1.0)) if t < 0.6 \
				else mid.lerp(low, clampf((t - 0.55) * 2.2, 0.0, 1.0))
			draw_rect(Rect2(0, y, WorldSky.VIEW.x, 1), c)
			if int(t * 24) % 2 == 0:            # light 2x2 dither on alternate bands
				var dc := c.lerp(low, 0.12)
				for x in range(y % 2, int(WorldSky.VIEW.x), 2):
					draw_rect(Rect2(x, y, 1, 1), dc)


## The sun (warmer and bigger near the horizon) or the moon, with a soft halo.
class _Disc:
	extends Node2D

	var moon := false
	var warm := 0.0:
		set(value):
			if absf(value - warm) > 0.02:
				warm = value
				queue_redraw()

	func _draw() -> void:
		var p := WorldPalette
		if moon:
			WorldPalette.disc(self, 0, 0, 16, Color(0.85, 0.88, 1.0, 0.12))
			WorldPalette.disc(self, 0, 0, 11, Color("e8ecf4"))
			draw_rect(Rect2(-4, -2, 3, 3), Color("c8ccd8"))
			draw_rect(Rect2(2, 3, 2, 2), Color("c8ccd8"))
			return
		var sun := p.SUN.lerp(Color("ff8a3a"), warm * 0.8)
		WorldPalette.disc(self, 0, 0, 22, Color(sun, 0.25))
		WorldPalette.disc(self, 0, 0, 19, Color(sun, 0.45))
		WorldPalette.disc(self, 0, 0, 16, sun)


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
		var p := WorldPalette
		var puffs := [[0, 0, 14], [16, -6, 16], [34, -2, 13], [50, 2, 10], [-14, 4, 9], [24, 6, 12]]
		for q in puffs:
			WorldPalette.disc(self, cx + q[0] * s, cy + q[1] * s + 3, int(q[2] * s), p.CLOUD_DARK)
		for q in puffs:
			WorldPalette.disc(self, cx + q[0] * s, cy + q[1] * s + 1, int(q[2] * s), p.CLOUD_SHADE)
		for q in puffs:
			WorldPalette.disc(self, cx + q[0] * s - 1, cy + q[1] * s - 1, int(q[2] * s) - 2, p.CLOUD)
