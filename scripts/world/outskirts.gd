@tool
class_name WorldBuilding
extends Node2D
## Big buildings at the edge of town (procedural placeholder art, same palette
## as the canal houses). Origin = street level, left end; width() per kind.
##   MALL           shopping centre: flat roof, shop fronts with awnings, canopy
##   GARAGE         multi-storey car park: open floors with parked cars, big P
##   SELF_STORAGE   corrugated units with roll-up doors
##   OUR_STORAGE    the band's storage: its own car park on the left (the gate
##                  in front is a StorageGate node), warehouse with loading door

enum Kind { MALL, GARAGE, SELF_STORAGE, OUR_STORAGE }

const WIDTHS := {Kind.MALL: 320.0, Kind.GARAGE: 200.0, Kind.SELF_STORAGE: 260.0, Kind.OUR_STORAGE: 340.0}
const CONCRETE := Color("a7a3a8")
const CONCRETE_DARK := Color("7d7981")
const STEEL := Color("c9ccd2")
const SHOP_SIGNS := ["SUPER", "FIETS", "PIZZA", "DIER", "BOEK", "VERF"]
const CAR_COLOURS := [Color("c94a3d"), Color("5b7fa6"), Color("fbf8f2"), Color("2a2830"), Color("e0b23a"), Color("6f8f5a")]

@export var kind := Kind.MALL:
	set(value):
		kind = value
		queue_redraw()
@export var seed_value := 1:
	set(value):
		seed_value = value
		queue_redraw()
@export var sign_text := "":
	set(value):
		sign_text = value
		queue_redraw()


func width() -> float:
	return WIDTHS[kind]


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	match kind:
		Kind.MALL: _mall(rng)
		Kind.GARAGE: _garage(rng, 0.0, width(), 104.0, true)
		Kind.SELF_STORAGE: _self_storage(rng)
		Kind.OUR_STORAGE: _our_storage(rng)


func _text(x: float, y: float, w: float, text: String, size: int, c: Color) -> void:
	draw_string(ThemeDB.fallback_font, Vector2(x, y), text, HORIZONTAL_ALIGNMENT_CENTER, w, size, c)


func _mall(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	var h := 78.0
	draw_rect(Rect2(0, -h, w, h), Color("d8cbb8"))
	draw_rect(Rect2(0, -h, w, 8), CONCRETE_DARK)                 # roof edge
	draw_rect(Rect2(w - 3, -h, 3, h), Color("b5a893"))
	# Tower with the centre's name.
	draw_rect(Rect2(w / 2 - 34, -h - 22, 68, 24), p.NAVY)
	_text(w / 2 - 34, -h - 7, 68, sign_text if sign_text != "" else "WINKELCENTRUM", 8, p.LIT)
	# Upper band of offices.
	for i in int(w / 18):
		draw_rect(Rect2(6 + i * 18, -h + 14, 12, 10), p.GLASS)
	# Canopy and shop fronts.
	draw_rect(Rect2(-4, -40, w + 8, 4), CONCRETE_DARK)
	var shops := 5
	var sw := w / shops
	for i in shops:
		var x := i * sw
		draw_rect(Rect2(x + 4, -34, sw - 8, 30), p.GLASS)
		draw_rect(Rect2(x + 4, -34, sw - 8, 1), p.TRIM)
		for k in 3:
			draw_rect(Rect2(x + 6 + k * (sw - 12) / 3.0, -30, 1, 26), p.GLASS.lightened(0.15))
		var sc: Color = [p.ORANGE, Color("c94a3d"), Color("5b7fa6"), Color("6f8f5a"), Color("e0b23a")][i % 5]
		draw_rect(Rect2(x + 8, -52, sw - 16, 10), sc)
		_text(x + 8, -44, sw - 16, SHOP_SIGNS[(i + seed_value) % SHOP_SIGNS.size()], 7, p.WHITE)
		if rng.randf() < 0.5:
			draw_rect(Rect2(x + sw / 2 - 4, -18, 8, 18), p.NAVY)
	# Trolleys and a flag pole.
	for k in 3:
		draw_rect(Rect2(w - 30 + k * 5, -7, 4, 4), STEEL)
	draw_rect(Rect2(14, -h - 30, 1, 30), p.IRON)
	draw_rect(Rect2(15, -h - 30, 10, 6), p.ORANGE)


func _garage(rng: RandomNumberGenerator, x0: float, w: float, h: float, big_sign: bool) -> void:
	var p := WorldPalette
	draw_rect(Rect2(x0, -h, w, h), CONCRETE)
	var floors := 4
	var fh := h / floors
	for f in floors:
		var y := -h + f * fh
		draw_rect(Rect2(x0, y, w, 4), CONCRETE_DARK)                 # slab
		if f == floors - 1:
			break                                                # ground floor: entrance
		draw_rect(Rect2(x0 + 4, y + 4, w - 8, fh - 10), Color("2c2a33"))
		var cx := x0 + 8.0
		while cx < x0 + w - 26:
			if rng.randf() < 0.7:
				var c: Color = CAR_COLOURS[rng.randi_range(0, CAR_COLOURS.size() - 1)]
				draw_rect(Rect2(cx, y + fh - 14, 20, 6), c)
				draw_rect(Rect2(cx + 4, y + fh - 18, 11, 4), c.darkened(0.2))
				draw_rect(Rect2(cx + 3, y + fh - 8, 3, 2), p.IRON)
				draw_rect(Rect2(cx + 14, y + fh - 8, 3, 2), p.IRON)
			cx += 26
		draw_rect(Rect2(x0 + 4, y + fh - 8, w - 8, 2), STEEL)         # barrier rail
		for k in int(w / 40):
			draw_rect(Rect2(x0 + 20 + k * 40, y + 4, 3, fh - 6), CONCRETE)   # columns
	# Ground floor: entrance with a barrier arm.
	draw_rect(Rect2(x0 + 12, -fh + 6, 36, fh - 6), Color("2c2a33"))
	draw_rect(Rect2(x0 + 12, -14, 30, 2), Color("c94a3d"))
	draw_rect(Rect2(x0 + 10, -16, 3, 16), p.IRON)
	if big_sign:
		draw_rect(Rect2(x0 + w - 40, -h - 12, 28, 28), Color("2a5bd7"))
		_text(x0 + w - 40, -h + 10, 28, "P", 22, p.WHITE)
	else:
		draw_rect(Rect2(x0 + w - 22, -h + 8, 14, 14), Color("2a5bd7"))
		_text(x0 + w - 22, -h + 19, 14, "P", 10, p.WHITE)


func _roll_door(x: float, w: float, h: float, c: Color) -> void:
	draw_rect(Rect2(x, -h, w, h), c)
	for y in range(int(-h) + 2, 0, 3):
		draw_rect(Rect2(x, y, w, 1), c.darkened(0.2))
	draw_rect(Rect2(x - 1, -h - 2, w + 2, 2), CONCRETE_DARK)


func _self_storage(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	var h := 64.0
	draw_rect(Rect2(0, -h, w, h), p.ORANGE)
	for x in range(0, int(w), 4):                                # corrugation
		draw_rect(Rect2(x, -h, 1, h - 26), p.ORANGE.darkened(0.15))
	draw_rect(Rect2(0, -28, w, 28), p.WHITE)
	draw_rect(Rect2(0, -h, w, 4), CONCRETE_DARK)
	draw_rect(Rect2(10, -h + 8, 120, 14), p.WHITE)
	_text(10, -h + 19, 120, sign_text if sign_text != "" else "SELF STORAGE", 9, p.ORANGE.darkened(0.3))
	var doors := int((w - 10) / 30)
	for i in doors:
		_roll_door(8 + i * 30, 22, 24, STEEL if rng.randf() < 0.8 else Color("5b7fa6"))
		draw_string(ThemeDB.fallback_font, Vector2(15 + i * 30, -27), str(101 + i), HORIZONTAL_ALIGNMENT_LEFT, -1, 5, p.NAVY)


func _our_storage(rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var w := width()
	# Left: the storage's own car park (two storeys), the gate stands in front.
	_garage(rng, 0.0, 130.0, 70.0, false)
	# Right: the warehouse.
	var x0 := 130.0
	var ww := w - x0
	var h := 96.0
	draw_rect(Rect2(x0, -h, ww, h), Color("3a3d48"))
	for x in range(int(x0), int(w), 5):
		draw_rect(Rect2(x, -h, 1, h), Color("33363f"))
	draw_rect(Rect2(x0, -h + 26, ww, 6), p.ORANGE)                 # band stripe
	draw_rect(Rect2(x0, -h, ww, 4), CONCRETE_DARK)
	draw_rect(Rect2(x0 + 20, -h + 8, ww - 40, 14), p.NAVY)
	_text(x0 + 20, -h + 19, ww - 40, sign_text if sign_text != "" else "STORAGE", 9, p.LIT)
	# Loading door, a side door, small high windows.
	_roll_door(x0 + 30, 60, 44, STEEL)
	draw_rect(Rect2(x0 + 110, -18, 8, 18), p.NAVY)
	draw_rect(Rect2(x0 + 116, -10, 1, 1), p.LIT)
	for k in 5:
		draw_rect(Rect2(x0 + 24 + k * 34, -h + 40, 14, 6), p.GLASS if k != 2 else p.LIT)
	# Camera and a lamp over the yard.
	draw_rect(Rect2(x0 + 4, -60, 6, 3), p.IRON)
	draw_rect(Rect2(x0 + 2, -62, 2, 6), p.IRON)
	draw_rect(Rect2(w - 14, -h - 18, 2, 18), p.IRON)
	draw_rect(Rect2(w - 20, -h - 20, 10, 3), p.LIT)
