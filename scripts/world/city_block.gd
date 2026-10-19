@tool
class_name CityBlock
extends Node2D
## A row of Amsterdam canal houses on the play street (procedural placeholder
## art in the approved palette): narrow, 3-4 storeys, step/bell/neck gables or
## tiled roofs, cream cornices and window frames, the odd lit window, shop
## awnings. `seed_value` keeps the look stable. Origin = street level, left end.

@export var houses := 6:
	set(value):
		houses = value
		queue_redraw()
@export var seed_value := 1:
	set(value):
		seed_value = value
		queue_redraw()
@export var sign_text := "":                ## sign on the middle house (STUDIO, CAFE DE KAT...)
	set(value):
		sign_text = value
		queue_redraw()


## The row's houses as [width, height, colour, gable, shop].
func layout() -> Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var out := []
	for i in houses:
		var w := rng.randi_range(40, 54)
		var h := rng.randi_range(80, 100)
		var c: Color = WorldPalette.FACADES[(i * 3 + rng.randi_range(0, 2) + seed_value) % WorldPalette.FACADES.size()]
		out.append([w, h, c, rng.randi_range(0, 3), rng.randf() < 0.3, rng.randi()])
	return out


func width() -> float:
	var w := 0.0
	for hdef in layout():
		w += hdef[0]
	return w


func _draw() -> void:
	var x := 0.0
	var rows := layout()
	var mid := houses / 2
	for i in rows.size():
		var hdef: Array = rows[i]
		_house(x, hdef[0], hdef[1], hdef[2], hdef[3], hdef[4] and sign_text == "", hdef[5])
		if sign_text != "" and i == mid:
			var w: float = hdef[0]
			var top: float = -hdef[1]
			draw_rect(Rect2(x + 2, top + 22, w - 4, 11), WorldPalette.NAVY)
			draw_string(ThemeDB.fallback_font, Vector2(x + 2, top + 30), sign_text, HORIZONTAL_ALIGNMENT_CENTER, w - 4, 7, WorldPalette.LIT)
		x += hdef[0]


func _house(x: float, w: int, h: int, c: Color, gable: int, shop: bool, salt: int) -> void:
	var p := WorldPalette
	var rng := RandomNumberGenerator.new()
	rng.seed = salt
	var top := -h
	draw_rect(Rect2(x, top, w, h), c)
	draw_rect(Rect2(x + w - 2, top, 2, h), c.darkened(0.25))   # light from the left
	match gable:
		0:                                  # step gable
			draw_rect(Rect2(x + w / 5, top - 8, w * 3 / 5, 8), c)
			draw_rect(Rect2(x + w / 3, top - 15, w / 3, 7), c)
			draw_rect(Rect2(x + w / 5 - 1, top - 8, w * 3 / 5 + 2, 1), p.TRIM)
			draw_rect(Rect2(x + w / 3 - 1, top - 15, w / 3 + 2, 1), p.TRIM)
		1:                                  # bell gable
			WorldPalette.triangle(self, x + 4, top, w - 8, 16, c)
			draw_rect(Rect2(x + w / 2 - 4, top - 10, 8, 6), p.TRIM)
		2:                                  # neck gable
			draw_rect(Rect2(x + w / 4, top - 14, w / 2, 14), c)
			draw_rect(Rect2(x + w / 4 - 1, top - 15, w / 2 + 2, 2), p.TRIM)
		_:                                  # tiled roof
			WorldPalette.triangle(self, x, top, w, 14, p.ROOF)
	draw_rect(Rect2(x, top, w, 2), p.TRIM)  # cornice
	var cols := 3 if w > 46 else 2
	var gap: int = (w - 6 - cols * 8) / maxi(cols - 1, 1)
	var rows := int((h - 34) / 21)
	for r in rows:
		for k in cols:
			_window(x + 3 + k * (8 + gap), top + 8 + r * 21, 8, 12, rng.randf() < 0.15)
	var door_x := x + w / 2 - 4
	if shop:
		for s in w / 4:
			draw_rect(Rect2(x + 2 + s * 4, -26, 4, 5), p.ORANGE if s % 2 == 0 else p.WHITE)
		draw_rect(Rect2(x + 3, -20, w - 14, 14), p.GLASS)
		draw_rect(Rect2(x + 3, -20, w - 14, 1), p.TRIM)
		door_x = x + w - 10
	draw_rect(Rect2(door_x, -18, 8, 18), p.NAVY)
	draw_rect(Rect2(door_x - 1, -19, 10, 1), p.TRIM)
	draw_rect(Rect2(door_x + 6, -10, 1, 1), p.LIT)
	draw_rect(Rect2(x, -3, w, 3), c.darkened(0.35))   # plinth


func _window(x: float, y: float, w: float, h: float, lit: bool) -> void:
	var p := WorldPalette
	draw_rect(Rect2(x - 1, y - 1, w + 2, h + 2), p.TRIM)
	draw_rect(Rect2(x, y, w, h), p.LIT if lit else p.GLASS)
	draw_rect(Rect2(x + w / 2, y, 1, h), p.TRIM)
	draw_rect(Rect2(x, y + h / 2, w, 1), p.TRIM)
