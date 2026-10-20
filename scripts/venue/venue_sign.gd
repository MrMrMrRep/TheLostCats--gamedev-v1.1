@tool
class_name VenueSign
extends Node2D
## A painted sign or hint on a venue wall: the room's name in big letters, a
## hint below. Origin = top-left.

@export var title := "ROOM":
	set(value):
		title = value
		queue_redraw()
@export_multiline var hint := "":
	set(value):
		hint = value
		queue_redraw()


func _draw() -> void:
	var f := ThemeDB.fallback_font
	draw_string(f, Vector2(0, 14), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color("ffd36b"))
	var y := 28.0
	for line in hint.split("\n"):
		draw_string(f, Vector2(0, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color(1, 1, 1, 0.8))
		y += 11
