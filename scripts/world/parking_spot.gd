@tool
class_name ParkingSpot
extends Node2D
## A P sign: the band van can only be entered or left within `width` of it.

@export var width := 96.0:
	set(value):
		width = value
		queue_redraw()


func _ready() -> void:
	add_to_group(&"parking")


func has_x(x: float) -> bool:
	return absf(x - global_position.x) <= width / 2.0


func _draw() -> void:
	draw_rect(Rect2(-width / 2.0, -1, width, 1), Color(1, 1, 1, 0.35))
	draw_line(Vector2(0, 0), Vector2(0, -26), Color("8a8a96"), 1.5)
	draw_rect(Rect2(-6, -38, 12, 12), Color("2a5bd7"))
	draw_string(ThemeDB.fallback_font, Vector2(-3, -28), "P", HORIZONTAL_ALIGNMENT_LEFT, -1, 9, Color.WHITE)
