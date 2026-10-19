@tool
class_name WorldConstruction
extends Node2D
## A building site at the edge of town, behind the road: a hoarding with
## posters, a concrete frame going up, two tower cranes (thin lattice, so they
## don't block the view; the jibs slowly swing a load), site cabins, a sand
## heap and an excavator. Origin = street level at the site's left end.

@export var length := 360.0:
	set(value):
		length = value
		queue_redraw()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	var p := WorldPalette
	var concrete := Color("b9b6b0")
	var t := Time.get_ticks_msec() / 1000.0
	# The frame going up: floors and columns, top floor half done, scaffolding.
	var fx := length * 0.3
	var fw := length * 0.45
	for f in 5:
		var y := -10.0 - f * 30.0
		draw_rect(Rect2(fx, y - 4, fw, 4), concrete)
		if f < 4:
			for c in range(0, int(fw) + 1, 30):
				draw_rect(Rect2(fx + c, y - 30, 4, 26), concrete.darkened(0.08))
	for c in [0.0, 10.0, 20.0]:                                  # scaffold up one side only
		draw_rect(Rect2(fx - 22 + c, -132, 1, 132), Color("8a8f99"))
	for y in range(-132, 0, 15):
		draw_rect(Rect2(fx - 22, y, 22, 1), Color("8a8f99"))
		draw_line(Vector2(fx - 22, y), Vector2(fx - 2, y + 15), Color(0.54, 0.56, 0.6, 0.6), 1.0)
	draw_rect(Rect2(fx - 22, -134, 22, 14), Color(0.2, 0.5, 0.3, 0.45))       # safety net
	# Two tower cranes with swinging loads.
	_crane(length * 0.15, 230.0, 160.0, t, 0.0)
	_crane(length * 0.85, 190.0, -130.0, t, 1.7)
	# Sand heap, excavator, cabins.
	WorldPalette.triangle(self, length * 0.05, -2, 80, 26, Color("d8b878"))
	_excavator(length * 0.62)
	for k in 2:
		draw_rect(Rect2(length * 0.82 - k * 2, -24 - k * 20, 54, 20), Color("e8e0d0") if k == 0 else Color("2a5bd7"))
		draw_rect(Rect2(length * 0.82 + 6 - k * 2, -18 - k * 20, 12, 8), p.GLASS)
	# Hoarding along the street with posters, a gate and a warning sign.
	var hx := 0.0
	var colours := [Color("e07a2e"), Color("2f6f4a"), Color("c94a3d"), Color("2a4ea0")]
	while hx < length:
		draw_rect(Rect2(hx, -24, 40, 24), Color("e8e0d0"))
		draw_rect(Rect2(hx, -24, 40, 2), Color("8a8f99"))
		draw_rect(Rect2(hx + 39, -24, 1, 24), Color("8a8f99"))
		if int(hx / 40) % 3 == 1:
			draw_rect(Rect2(hx + 6, -20, 28, 14), colours[int(hx / 40) % 4])
		hx += 40
	draw_rect(Rect2(length * 0.5 - 20, -24, 40, 24), Color("e0b23a"))
	for k in 4:
		draw_line(Vector2(length * 0.5 - 20 + k * 10, -24), Vector2(length * 0.5 - 10 + k * 10, 0), Color("1d1a22"), 2.0)
	draw_string(ThemeDB.fallback_font, Vector2(4, -10), "NIEUWBOUW", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, Color("2a2a2e"))


func _crane(x: float, h: float, jib: float, t: float, phase: float) -> void:
	var yellow := Color("e8b830")
	for y in range(0, int(h), 8):                                # lattice mast
		draw_line(Vector2(x - 3, -y), Vector2(x + 3, -y - 8), yellow, 1.0)
		draw_line(Vector2(x + 3, -y), Vector2(x - 3, -y - 8), yellow, 1.0)
	draw_line(Vector2(x - 3, 0), Vector2(x - 3, -h), yellow, 1.0)
	draw_line(Vector2(x + 3, 0), Vector2(x + 3, -h), yellow, 1.0)
	draw_rect(Rect2(x - 5, -h - 8, 10, 8), Color("e8e0d0"))     # cab
	var reach := jib * (0.85 + 0.15 * sin(t * 0.25 + phase))      # the jib swings toward/away from us
	draw_line(Vector2(x, -h - 4), Vector2(x + reach, -h - 4), yellow, 2.0)
	draw_line(Vector2(x, -h - 4), Vector2(x - signf(jib) * 30, -h - 4), yellow, 2.0)
	draw_rect(Rect2(x - signf(jib) * 30 - 5, -h - 8, 10, 8), Color("8a8f99"))   # counterweight
	draw_line(Vector2(x, -h - 18), Vector2(x + reach, -h - 4), yellow, 1.0)
	var trolley := x + reach * (0.5 + 0.35 * sin(t * 0.4 + phase))
	var drop := 60.0 + 30.0 * sin(t * 0.3 + phase)
	draw_line(Vector2(trolley, -h - 4), Vector2(trolley, -h - 4 + drop), Color("3a3a40"), 1.0)
	draw_rect(Rect2(trolley - 8, -h - 4 + drop, 16, 6), Color("8a6a4a"))   # a pallet


func _excavator(x: float) -> void:
	var yellow := Color("e8b830")
	draw_rect(Rect2(x, -10, 34, 8), Color("3a3a40"))
	draw_rect(Rect2(x + 4, -26, 26, 16), yellow)
	draw_rect(Rect2(x + 18, -24, 10, 9), WorldPalette.GLASS)
	draw_line(Vector2(x + 6, -22), Vector2(x - 14, -40), yellow, 3.0)
	draw_line(Vector2(x - 14, -40), Vector2(x - 26, -16), yellow, 3.0)
	draw_rect(Rect2(x - 32, -16, 10, 8), Color("8a8f99"))
