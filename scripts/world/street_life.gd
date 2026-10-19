@tool
class_name WorldStreetLife
extends Node2D
## Street furniture along one stretch of the play street, drawn at the band
## sprites' density (art px, see PixelArt) and placed by district rules from
## docs/city-layout.md. One node per stretch so Godot can cull it.
##   CANAL     elms every 2-3 houses, canal lamps, Amsterdammertje bollards,
##             bike racks, a bench now and then, bins, a no-cars sign
##   OLD_TOWN  lamps, planters, bollards, bike racks; few trees
##   RING      young trees in pits, bins, bike racks, parking meters
##   INDUSTRY  tall lamps, fences, signs
##   AIRPORT   tall lamps, flags, a bus stop
## `keep_clear` (local x ranges) stays empty: doors and gates.
## Origin = street level at the stretch's left end.

enum Kind { CANAL, OLD_TOWN, RING, INDUSTRY, AIRPORT }

@export var kind := Kind.CANAL:
	set(value):
		kind = value
		queue_redraw()
@export var length := 1200.0:
	set(value):
		length = value
		queue_redraw()
@export var seed_value := 1
@export var keep_clear: Array[Vector2] = []


func _clear(x: float, half: float) -> bool:
	for r in keep_clear:
		if x + half > r.x and x - half < r.y:
			return false
	return true


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	var x := rng.randf_range(20, 80)
	while x < length - 20:
		var ax := x * 2.0                   # art px
		match kind:
			Kind.CANAL: x += _canal(ax, rng)
			Kind.OLD_TOWN: x += _old_town(ax, rng)
			Kind.RING: x += _ring(ax, rng)
			Kind.INDUSTRY: x += _industry(ax, rng)
			_: x += _airport(ax, rng)
	draw_set_transform(Vector2.ZERO)


# --- District rules (return the world px to the next spot) ------------------

func _canal(ax: float, rng: RandomNumberGenerator) -> float:
	var r := rng.randf()
	if r < 0.45 and _clear(ax / 2.0, 30):
		PixelArt.tree(self, ax, 0, rng.randf_range(50, 64), rng)
		if rng.randf() < 0.5:
			_bike_rack(ax + 30, rng.randi_range(2, 4), rng)
	elif r < 0.7 and _clear(ax / 2.0, 6):
		_lamp(ax)
		_bollards(ax + 14, rng.randi_range(2, 4))
	elif r < 0.8 and _clear(ax / 2.0, 16):
		_bench(ax)
		_bin(ax + 50)
	elif r < 0.85 and _clear(ax / 2.0, 6):
		_sign(ax, 0)
	elif _clear(ax / 2.0, 30):
		_bike_rack(ax, rng.randi_range(3, 5), rng)
	return rng.randf_range(55, 95)


func _old_town(ax: float, rng: RandomNumberGenerator) -> float:
	var r := rng.randf()
	if r < 0.3 and _clear(ax / 2.0, 6):
		_lamp(ax)
	elif r < 0.5 and _clear(ax / 2.0, 14):
		_planter(ax, rng)
	elif r < 0.7 and _clear(ax / 2.0, 20):
		_bike_rack(ax, rng.randi_range(2, 4), rng)
	elif r < 0.8 and _clear(ax / 2.0, 24):
		PixelArt.tree(self, ax, 0, rng.randf_range(40, 50), rng)
	else:
		_bollards(ax, rng.randi_range(3, 5))
	return rng.randf_range(50, 90)


func _ring(ax: float, rng: RandomNumberGenerator) -> float:
	var r := rng.randf()
	if r < 0.5 and _clear(ax / 2.0, 20):
		PixelArt.tree(self, ax, 0, rng.randf_range(34, 44), rng)
	elif r < 0.7 and _clear(ax / 2.0, 6):
		_lamp(ax)
	elif r < 0.85 and _clear(ax / 2.0, 6):
		_meter(ax)
		_bin(ax + 20)
	elif _clear(ax / 2.0, 20):
		_bike_rack(ax, rng.randi_range(2, 3), rng)
	return rng.randf_range(70, 110)


func _industry(ax: float, rng: RandomNumberGenerator) -> float:
	if _clear(ax / 2.0, 8):
		_tall_lamp(ax)
	if rng.randf() < 0.3 and _clear(ax / 2.0 + 30, 6):
		_sign(ax + 60, 1)
	return rng.randf_range(120, 160)


func _airport(ax: float, rng: RandomNumberGenerator) -> float:
	if _clear(ax / 2.0, 8):
		_tall_lamp(ax)
	if rng.randf() < 0.3 and _clear(ax / 2.0 + 40, 10):
		_flags(ax + 80, rng)
	return rng.randf_range(110, 150)


# --- Pieces (art px, standing on y 0) ---------------------------------------

func _lamp(x: float) -> void:
	var post := Color("23302a")
	draw_rect(Rect2(x - 4, -8, 8, 8), post)                 # base
	draw_rect(Rect2(x - 3, -10, 6, 2), post.lightened(0.2))
	draw_rect(Rect2(x - 1, -80, 3, 72), post)
	draw_rect(Rect2(x - 3, -50, 7, 2), post)
	draw_rect(Rect2(x - 6, -96, 13, 3), post)               # lantern
	draw_rect(Rect2(x - 5, -93, 11, 11), Color("f6d98a"))
	draw_rect(Rect2(x - 5, -93, 11, 1), Color("fff3c4"))
	draw_rect(Rect2(x, -93, 1, 11), post)
	draw_rect(Rect2(x - 6, -82, 13, 2), post)
	draw_rect(Rect2(x - 1, -100, 3, 4), post)


func _tall_lamp(x: float) -> void:
	var post := Color("8a8f99")
	draw_rect(Rect2(x - 2, -150, 4, 150), post)
	draw_rect(Rect2(x - 4, -4, 8, 4), post.darkened(0.2))
	draw_rect(Rect2(x - 2, -150, 26, 3), post)
	draw_rect(Rect2(x + 16, -148, 12, 4), Color("f6e8b0"))


func _bollards(x: float, n: int) -> void:
	for k in n:
		var bx := x + k * 14
		draw_rect(Rect2(bx - 3, -22, 6, 22), Color("5a2a22"))
		draw_rect(Rect2(bx - 2, -22, 2, 22), Color("7a3a2e"))
		draw_rect(Rect2(bx - 4, -24, 8, 3), Color("4a221c"))
		for m in 3:                                        # the three crosses
			draw_rect(Rect2(bx - 1, -18 + m * 5, 2, 2), Color("e8e0d0"))


func _bench(x: float) -> void:
	var wood := Color("8a5a3a")
	for k in 3:
		draw_rect(Rect2(x, -18 - k * 5, 40, 3), wood if k > 0 else wood.darkened(0.15))
	draw_rect(Rect2(x, -12, 40, 3), wood)
	draw_rect(Rect2(x + 3, -10, 3, 10), PixelArt.OUTLINE)
	draw_rect(Rect2(x + 34, -10, 3, 10), PixelArt.OUTLINE)


func _bin(x: float) -> void:
	draw_rect(Rect2(x, -18, 12, 18), Color("2f4f3a"))
	draw_rect(Rect2(x - 1, -20, 14, 3), Color("23302a"))
	draw_rect(Rect2(x + 3, -14, 6, 2), Color("1a2a20"))


func _bike_rack(x: float, n: int, rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(x - 4, -12, n * 18 + 30, 2), Color("8a8f99"))
	for k in n:
		_bike(x + k * 18, rng)


func _bike(x: float, rng: RandomNumberGenerator) -> void:
	var fc: Color = [Color("2a2a2e"), Color("6b2a2a"), Color("2a4a6a"), Color("e8e0d0"), Color("2f4f3a")][rng.randi_range(0, 4)]
	draw_arc(Vector2(x, -10), 9, 0, TAU, 16, PixelArt.OUTLINE, 2.0)
	draw_arc(Vector2(x + 30, -10), 9, 0, TAU, 16, PixelArt.OUTLINE, 2.0)
	draw_line(Vector2(x, -10), Vector2(x + 12, -22), fc, 2.0)
	draw_line(Vector2(x + 12, -22), Vector2(x + 30, -10), fc, 2.0)
	draw_line(Vector2(x + 12, -22), Vector2(x + 14, -10), fc, 2.0)
	draw_line(Vector2(x + 14, -10), Vector2(x, -10), fc, 2.0)
	draw_line(Vector2(x + 26, -26), Vector2(x + 30, -10), fc, 2.0)
	draw_rect(Rect2(x + 22, -28, 9, 2), PixelArt.OUTLINE)
	draw_rect(Rect2(x + 9, -25, 7, 2), Color("3a2a22"))
	if rng.randf() < 0.4:                                   # crate on the front
		draw_rect(Rect2(x + 26, -36, 10, 8), Color("8a6a4a"))


func _planter(x: float, rng: RandomNumberGenerator) -> void:
	draw_rect(Rect2(x, -16, 28, 16), Color("6b4a32"))
	draw_rect(Rect2(x - 1, -18, 30, 3), Color("8a6a4a"))
	for k in 6:
		WorldPalette.disc(self, x + 3 + k * 4.5, -22, 3, Color("4f7a3a"))
	for k in 5:
		draw_rect(Rect2(x + 4 + k * 5, -26, 2, 2), CityBlock.FLOWERS[rng.randi_range(0, 4)])


func _meter(x: float) -> void:
	draw_rect(Rect2(x - 1, -30, 3, 30), Color("5a5a60"))
	draw_rect(Rect2(x - 5, -40, 11, 12), Color("2a4ea0"))
	draw_rect(Rect2(x - 3, -37, 7, 4), Color("cfe0ea"))


## kind 0: no motor vehicles (red ring, white), 1: a direction sign.
func _sign(x: float, sign_kind: int) -> void:
	draw_rect(Rect2(x - 1, -70, 3, 70), Color("8a8f99"))
	if sign_kind == 0:
		WorldPalette.disc(self, x, -76, 9, Color("c94a3d"))
		WorldPalette.disc(self, x, -76, 6, Color("f2f2f2"))
		draw_rect(Rect2(x - 4, -78, 8, 4), PixelArt.OUTLINE)    # car + bike symbol
	else:
		draw_rect(Rect2(x - 22, -86, 44, 14), Color("2a5bd7"))
		draw_rect(Rect2(x - 22, -86, 44, 1), Color.WHITE)
		draw_string(ThemeDB.fallback_font, Vector2(x - 22, -76), "A10 RING", HORIZONTAL_ALIGNMENT_CENTER, 44, 8, Color.WHITE)


func _flags(x: float, rng: RandomNumberGenerator) -> void:
	for k in 3:
		var fx := x + k * 16
		draw_rect(Rect2(fx, -120, 2, 120), Color("c9ccd2"))
		draw_rect(Rect2(fx + 2, -118, 12, 30), [Color("c94a3d"), Color("f2f2f2"), Color("2a4ea0")][(k + rng.randi_range(0, 2)) % 3])
