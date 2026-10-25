@tool
class_name WorldWaterLife
extends Node2D
## Small things on the water in front of us, for life and depth: ducks and
## swans paddling, a rowing boat, reed clumps along the bank, mooring posts,
## a buoy, and a lock (sluis) where the canal meets the polder ditch: two
## wooden gates with white-and-black balance beams, the chamber walls, a
## traffic light for boats. Each thing draws its own soft reflection (this is
## in front of the water). Origin = street line; `length` world px wide.



@export var length := 2000.0:
	set(value):
		length = value
		queue_redraw()
@export var lock_x := -1.0                  ## local x of the lock, < 0: none
@export var seed_value := 5
@export var water_y := 22.0              ## world px below the street where the water starts


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var t := Time.get_ticks_msec() / 1000.0
	if lock_x >= 0.0:
		_lock(lock_x)
	var x := rng.randf_range(30, 120)
	while x < length:
		if lock_x < 0.0 or absf(x - lock_x) > 90.0:
			var r := rng.randf()
			if r < 0.25:
				_reeds(x, rng)
			elif r < 0.45:
				_ducks(x + sin(t * 0.2 + x) * 20.0, rng, t)
			elif r < 0.55:
				_swan(x + sin(t * 0.1 + x) * 30.0, t)
			elif r < 0.7:
				_posts(x, rng)
			elif r < 0.78:
				_rowboat(x + fmod(t * 6.0 + x, 200.0) - 100.0, t)
			elif r < 0.85:
				_buoy(x, t)
		x += rng.randf_range(90, 200)


func _bob(t: float, x: float) -> float:
	return sin(t * 2.0 + x * 0.1) * 0.6


func _reflect(r: Rect2, c: Color) -> void:
	draw_rect(Rect2(r.position.x, water_y + (water_y - r.end.y) + 2, r.size.x, r.size.y * 0.6), Color(c, 0.25))


func _reeds(x: float, rng: RandomNumberGenerator) -> void:
	for k in rng.randi_range(6, 12):
		var rx := x + k * 2.5
		var h := rng.randf_range(8, 16)
		var c := WorldPalette.G2 if k % 3 else WorldPalette.W2
		draw_line(Vector2(rx, water_y + 1), Vector2(rx + rng.randf_range(-2, 2), water_y + 1 - h), c, 1.0)
		if k % 4 == 0:                                        # bulrush heads
			draw_rect(Rect2(rx - 1, water_y - h - 1, 2, 4), WorldPalette.W0)
	draw_rect(Rect2(x - 2, water_y + 2, 34, 3), Color(0.3, 0.4, 0.2, 0.25))


func _ducks(x: float, rng: RandomNumberGenerator, t: float) -> void:
	for k in rng.randi_range(1, 4):
		var dx := x + k * 9
		var y := water_y + 3 + _bob(t, dx)
		var drake := k % 2 == 0
		draw_rect(Rect2(dx, y - 3, 6, 3), WorldPalette.W1 if not drake else WorldPalette.W2)
		draw_rect(Rect2(dx + 5, y - 6, 3, 3), WorldPalette.G1 if drake else WorldPalette.W1)
		draw_rect(Rect2(dx + 8, y - 5, 1, 1), WorldPalette.O2)
		_reflect(Rect2(dx, y - 6, 8, 6), WorldPalette.W1)


func _swan(x: float, t: float) -> void:
	var y := water_y + 3 + _bob(t, x)
	draw_rect(Rect2(x, y - 5, 12, 5), WorldPalette.W5)
	draw_rect(Rect2(x + 9, y - 13, 2, 9), WorldPalette.W5)
	draw_rect(Rect2(x + 9, y - 14, 4, 2), WorldPalette.W5)
	draw_rect(Rect2(x + 13, y - 13, 2, 1), WorldPalette.B3)
	_reflect(Rect2(x, y - 14, 14, 14), WorldPalette.W5)


func _posts(x: float, rng: RandomNumberGenerator) -> void:
	for k in rng.randi_range(1, 3):                           # mooring posts (dukdalven)
		var px := x + k * 7
		var h := rng.randf_range(10, 16)
		draw_rect(Rect2(px, water_y + 2 - h, 3, h + 2), WorldPalette.W0)
		draw_rect(Rect2(px, water_y + 2 - h, 3, 2), WorldPalette.W1)
		_reflect(Rect2(px, water_y + 2 - h, 3, h), WorldPalette.W0)


func _rowboat(x: float, t: float) -> void:
	var y := water_y + 4 + _bob(t, x)
	draw_rect(Rect2(x, y - 4, 22, 4), WorldPalette.G1)
	draw_rect(Rect2(x + 2, y - 1, 18, 2), WorldPalette.G0)
	draw_rect(Rect2(x + 9, y - 13, 4, 9), WorldPalette.B2)   # rower
	draw_rect(Rect2(x + 9, y - 17, 4, 4), WorldPalette.W3)
	var oar := sin(t * 2.5 + x) * 4.0
	draw_line(Vector2(x + 11, y - 9), Vector2(x + 11 + 12, y + 1 + oar * 0.3), WorldPalette.W1, 1.0)
	_reflect(Rect2(x, y - 17, 22, 17), WorldPalette.G1)


func _buoy(x: float, t: float) -> void:
	var y := water_y + 3 + _bob(t, x) * 2.0
	draw_rect(Rect2(x, y - 8, 6, 8), WorldPalette.B2)
	draw_rect(Rect2(x, y - 5, 6, 2), WorldPalette.W5)
	draw_rect(Rect2(x + 2, y - 11, 2, 3), WorldPalette.T0)
	_reflect(Rect2(x, y - 11, 6, 11), WorldPalette.B2)


## The lock: chamber walls, two gates with balance beams, a boat light.
func _lock(x: float) -> void:
	var stone := WorldPalette.R1
	draw_rect(Rect2(x - 70, water_y - 2, 140, 4), stone)                 # chamber edge
	for gx in [x - 60.0, x + 60.0]:
		draw_rect(Rect2(gx - 4, water_y - 14, 8, 22), WorldPalette.W0)    # gate
		draw_rect(Rect2(gx - 4, water_y - 14, 8, 2), WorldPalette.W1)
		for k in 4:                                                     # balance beam, striped
			draw_rect(Rect2(gx - 30 + k * 7, water_y - 18, 7, 3), WorldPalette.W5 if k % 2 == 0 else WorldPalette.T0)
		draw_rect(Rect2(gx - 1, water_y - 18, 3, 4), WorldPalette.T0)
		_reflect(Rect2(gx - 30, water_y - 18, 34, 26), WorldPalette.W0)
	draw_rect(Rect2(x - 1, water_y - 30, 2, 28), WorldPalette.W0)       # boat light
	draw_rect(Rect2(x - 3, water_y - 38, 6, 9), WorldPalette.T0)
	draw_rect(Rect2(x - 2, water_y - 37, 4, 3), WorldPalette.B2)
	draw_rect(Rect2(x - 2, water_y - 33, 4, 3), WorldPalette.G0)
	draw_rect(Rect2(x - 60, water_y + 3, 120, 1), Color(1, 1, 1, 0.2))   # a slight step in level
