@tool
class_name VenueBlock
extends Node2D
## How a solid part of a venue level looks: a concrete wall, a wooden raised
## floor or a steel stage rig. Purely visual; the collision is the level's
## Ground tiles under it. `size` in px, origin = top-left.

enum Style { CONCRETE, WOOD, STEEL, STAGE }

@export var size := Vector2(48, 48):
	set(value):
		size = value
		queue_redraw()
@export var style := Style.CONCRETE:
	set(value):
		style = value
		queue_redraw()


func _draw() -> void:
	var r := Rect2(Vector2.ZERO, size)
	match style:
		Style.CONCRETE:
			draw_rect(r, Color("7a7e86"))
			draw_rect(Rect2(0, 0, size.x, 2), Color("9aa0a8"))
			var y := 12.0
			while y < size.y:
				draw_rect(Rect2(0, y, size.x, 1), Color("6a6e76"))
				y += 12
		Style.WOOD:
			draw_rect(r, Color("8a5a3a"))
			draw_rect(Rect2(0, 0, size.x, 3), Color("b07a4a"))
			var y := 8.0
			while y < size.y:
				draw_rect(Rect2(0, y, size.x, 1), Color("6a4228"))
				y += 8
		Style.STEEL:
			draw_rect(r, Color("3a3e48"))
			draw_rect(Rect2(0, 0, size.x, 3), Color("8a8f99"))
			var x := 0.0
			while x < size.x:                # truss crosses
				draw_line(Vector2(x, 3), Vector2(x + 12, size.y), Color("5a5f6a"), 1.0)
				draw_line(Vector2(x + 12, 3), Vector2(x, size.y), Color("5a5f6a"), 1.0)
				x += 12
		Style.STAGE:
			draw_rect(r, Color("1d1a22"))
			draw_rect(Rect2(0, 0, size.x, 3), Color("4a3a5a"))
	draw_rect(r, Color("1d1a22"), false, 1.0)
