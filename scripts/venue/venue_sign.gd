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


const UI_FONT := preload("res://scripts/ui/ui_font.gd")
const SHADOW := Color("1d2838")


## In the game's pixel letters (UiFont): the name at 2x, the hint at 1x, each
## with a 1 px navy shadow so it reads on brick.
func _draw() -> void:
	var f: Font = UI_FONT.font()
	draw_string(f, Vector2(2, 16), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, SHADOW)
	draw_string(f, Vector2(0, 14), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color("f2bc58"))
	var y := 30.0
	for line in hint.split("\n"):
		draw_string(f, Vector2(1, y + 1), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, SHADOW)
		draw_string(f, Vector2(0, y), line, HORIZONTAL_ALIGNMENT_LEFT, -1, 8, Color("fff7df"))
		y += 11
