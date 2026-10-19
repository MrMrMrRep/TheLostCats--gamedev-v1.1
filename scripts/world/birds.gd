class_name WorldBirds
extends Node2D
## Loose V-shaped flocks crossing the sky near the top of the view while
## `active` (the WorldMap turns it on outside town and on the road). Two-frame
## wing flap, drawn in world space so they feel part of the landscape.

const SPAWN_EVERY := Vector2(4.0, 9.0)      # seconds between flocks (random)
const SPEED := Vector2(28.0, 46.0)

var active := false

var _flocks: Array = []                     # {pos, vel, birds: [offset, phase]}
var _timer := 1.5
var _rng := RandomNumberGenerator.new()


func _process(delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam == null:
		return
	var view := get_viewport_rect().size / cam.zoom
	var center := cam.get_screen_center_position()
	if active:
		_timer -= delta
		if _timer <= 0.0:
			_timer = _rng.randf_range(SPAWN_EVERY.x, SPAWN_EVERY.y)
			_spawn(center, view)
	for f in _flocks:
		f.pos += f.vel * delta
	_flocks = _flocks.filter(func(f): return absf(f.pos.x - center.x) < view.x)
	queue_redraw()


func _spawn(center: Vector2, view: Vector2) -> void:
	var dir := -1.0 if _rng.randf() < 0.5 else 1.0
	var start := Vector2(center.x - dir * view.x * 0.6, center.y - view.y * _rng.randf_range(0.25, 0.42))
	var birds := []
	for i in _rng.randi_range(4, 8):
		var row := (i + 1) / 2
		var side := 1 if i % 2 == 0 else -1
		birds.append([Vector2(-dir * row * 7.0, side * row * 4.0 + _rng.randf_range(-1, 1)), _rng.randf() * TAU])
	_flocks.append({"pos": start, "vel": Vector2(dir * _rng.randf_range(SPEED.x, SPEED.y), _rng.randf_range(-2, 2)), "birds": birds})


func _draw() -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var c := WorldPalette.NAVY.lerp(WorldPalette.HAZE, 0.25)
	for f in _flocks:
		for b in f.birds:
			var p: Vector2 = (f.pos + b[0]).round()
			var up := int(t * 6.0 + b[1]) % 2 == 0
			if up:
				draw_rect(Rect2(p.x - 2, p.y - 1, 1, 1), c)
				draw_rect(Rect2(p.x + 2, p.y - 1, 1, 1), c)
				draw_rect(Rect2(p.x - 1, p.y, 3, 1), c)
			else:
				draw_rect(Rect2(p.x - 2, p.y, 5, 1), c)
				draw_rect(Rect2(p.x, p.y + 1, 1, 1), c)
