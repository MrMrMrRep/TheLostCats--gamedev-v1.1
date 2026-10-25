@tool
class_name WorldGantry
extends Node2D
## An overhead sign gantry on the motorway, standing in the median between
## the two carriageways: a steel post and a lattice beam with blue direction
## signs (and a green route number), arrows under them. Drawn behind our lane,
## in front of the opposite carriageway. (`part` FRONT draws nothing; kept so
## old scenes load.) Origin = street line.

enum Part { BACK, FRONT }

const STEEL := WorldPalette.W3
const BEAM_Y := -66.0

@export var part := Part.BACK:
	set(value):
		part = value
		queue_redraw()
@export var signs: PackedStringArray = ["Amsterdam|A10", "Den Haag|A4"]   ## "Place|Road" per panel
@export var seed_value := 1


func _draw() -> void:
	if part == Part.FRONT:
		return
	_post(0.0, -1.0, STEEL)
	# Lattice beam.
	var w := 70.0 + signs.size() * 76.0
	var x0 := -w + 10.0
	draw_rect(Rect2(x0, BEAM_Y - 4, w, 2), STEEL)
	draw_rect(Rect2(x0, BEAM_Y + 6, w, 2), STEEL)
	var x := x0
	while x < x0 + w - 6:
		draw_line(Vector2(x, BEAM_Y + 6), Vector2(x + 6, BEAM_Y - 4), STEEL.darkened(0.15), 1.0)
		x += 6
	# Sign panels with place, road number and an arrow.
	for i in signs.size():
		var parts := signs[i].split("|")
		var sx := x0 + 14 + i * 76
		draw_rect(Rect2(sx - 1, BEAM_Y - 33, 66, 32), WorldPalette.WHITE)
		draw_rect(Rect2(sx, BEAM_Y - 32, 64, 30), WorldPalette.T2)
		draw_string(ThemeDB.fallback_font, Vector2(sx + 4, BEAM_Y - 21), parts[0], HORIZONTAL_ALIGNMENT_LEFT, 58, 8, WorldPalette.WHITE)
		if parts.size() > 1:
			draw_rect(Rect2(sx + 4, BEAM_Y - 16, 18, 9), WorldPalette.B2)
			draw_string(ThemeDB.fallback_font, Vector2(sx + 4, BEAM_Y - 9), parts[1], HORIZONTAL_ALIGNMENT_CENTER, 18, 7, WorldPalette.WHITE)
		draw_line(Vector2(sx + 50, BEAM_Y - 5), Vector2(sx + 50, BEAM_Y - 17), WorldPalette.WHITE, 2.0)   # arrow
		draw_line(Vector2(sx + 46, BEAM_Y - 13), Vector2(sx + 50, BEAM_Y - 17), WorldPalette.WHITE, 2.0)
		draw_line(Vector2(sx + 54, BEAM_Y - 13), Vector2(sx + 50, BEAM_Y - 17), WorldPalette.WHITE, 2.0)
	draw_rect(Rect2(x0 + w - 40, BEAM_Y - 30, 22, 12), WorldPalette.T3)
	draw_string(ThemeDB.fallback_font, Vector2(x0 + w - 40, BEAM_Y - 21), "E19", HORIZONTAL_ALIGNMENT_CENTER, 22, 7, WorldPalette.WHITE)


func _post(x: float, bottom: float, c: Color) -> void:
	draw_rect(Rect2(x - 2, BEAM_Y - 6, 4, bottom - BEAM_Y + 6), c)
	draw_rect(Rect2(x + 1, BEAM_Y - 6, 1, bottom - BEAM_Y + 6), c.darkened(0.2))
	draw_rect(Rect2(x - 4, bottom - 3, 8, 3), c.darkened(0.3))
