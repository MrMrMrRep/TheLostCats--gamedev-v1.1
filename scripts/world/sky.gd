class_name WorldSky
extends CanvasLayer
## Screen-space sky behind everything: dithered blue gradient, the sun, and two
## cloud layers that drift slowly and shift a little with the camera
## (parallax). Independent of the camera zoom, so it always fills the screen.

const VIEW := Vector2(640, 360)
const FAR_PARALLAX := 0.04
const NEAR_PARALLAX := 0.1
const FAR_DRIFT := 3.0                      # px/s
const NEAR_DRIFT := 7.0

var _gradient: Control
var _far: _CloudBand
var _near: _CloudBand


func _ready() -> void:
	layer = -20
	_gradient = _Gradient.new()
	add_child(_gradient)
	_far = _CloudBand.new()
	_far.setup(11, 0.75, 30.0, 110.0, 7)
	add_child(_far)
	_near = _CloudBand.new()
	_near.setup(23, 1.1, 20.0, 150.0, 5)
	add_child(_near)


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	var cx := cam.get_screen_center_position().x if cam else 0.0
	var t := Time.get_ticks_msec() / 1000.0
	_far.offset_x = -(cx * FAR_PARALLAX + t * FAR_DRIFT)
	_near.offset_x = -(cx * NEAR_PARALLAX + t * NEAR_DRIFT)


class _Gradient:
	extends Control

	func _ready() -> void:
		size = WorldSky.VIEW
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var p := WorldPalette
		for y in int(WorldSky.VIEW.y):
			var t := float(y) / (WorldSky.VIEW.y * 0.8)
			var c := p.SKY_TOP.lerp(p.SKY_MID, clampf(t * 1.6, 0.0, 1.0)) if t < 0.6 \
				else p.SKY_MID.lerp(p.SKY_LOW, clampf((t - 0.55) * 2.2, 0.0, 1.0))
			draw_rect(Rect2(0, y, WorldSky.VIEW.x, 1), c)
			if int(t * 24) % 2 == 0:            # light 2x2 dither on alternate bands
				var dc := c.lerp(p.SKY_LOW, 0.12)
				for x in range(y % 2, int(WorldSky.VIEW.x), 2):
					draw_rect(Rect2(x, y, 1, 1), dc)
		# sun with soft halo
		var s := Vector2(470, 46)
		WorldPalette.disc(self, s.x, s.y, 22, p.SUN.lerp(p.SKY_MID, 0.75))
		WorldPalette.disc(self, s.x, s.y, 19, p.SUN.lerp(p.SKY_MID, 0.45))
		WorldPalette.disc(self, s.x, s.y, 16, p.SUN)


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
