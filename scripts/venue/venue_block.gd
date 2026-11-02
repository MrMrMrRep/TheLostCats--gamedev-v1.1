@tool
class_name VenueBlock
extends Node2D
## How a solid part of a venue level looks: a concrete wall, a wooden raised
## floor or a steel stage rig. Purely visual; the collision is the level's
## Ground tiles under it. `size` in px, origin = top-left.
## The International (a painted bar and hotel): HIDDEN where the painting
## itself shows the solid part (the bar counter, the landing, a bed), and
## its own materials: a mahogany shelf, stairs with a red runner, the café's
## mosaic floor, the hotel carpet and attic floorboards.

enum Style { CONCRETE, WOOD, STEEL, STAGE, HIDDEN, MAHOGANY, STAIR, MOSAIC, CARPET, BOARDS }

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
		Style.HIDDEN:
			return
		Style.MAHOGANY:
			draw_rect(r, Color("4a2420"))
			draw_rect(Rect2(0, 0, size.x, 3), Color("8a4a32"))
			draw_rect(Rect2(0, 3, size.x, 1), Color("c28a4a"))   # brass edge
			var x := 12.0
			while x < size.x:                # brackets
				draw_rect(Rect2(x, 4, 2, size.y - 4), Color("2e1a1e"))
				x += 36
		Style.STAIR:
			draw_rect(r, Color("3a2a22"))
			var y := 0.0
			while y < size.y:                # a riser every 12 px, the red runner on the tread
				draw_rect(Rect2(0, y, size.x, 3), Color("a8322c"))
				draw_rect(Rect2(0, y + 3, size.x, 1), Color("6a1e24"))
				draw_rect(Rect2(0, y + 11, size.x, 1), Color("2a1f1a"))
				y += 12
		Style.MOSAIC:
			draw_rect(r, Color("c8b894"))
			var y := 0.0
			var row := 0
			while y < size.y:
				var x := 0.0 if row % 2 == 0 else 3.0
				while x < size.x:
					draw_rect(Rect2(x, y, 3, 3), Color("8a2a28") if int(x / 3.0 + row) % 3 == 0 else Color("3a2e30"))
					x += 6
				y += 3
				row += 1
			draw_rect(Rect2(0, 0, size.x, 2), Color("5a3a2e"))
		Style.CARPET:
			draw_rect(r, Color("6a1e24"))
			var y := 4.0
			while y < size.y:
				var x := fposmod(y * 2.0, 8.0)
				while x < size.x:
					draw_rect(Rect2(x, y, 2, 2), Color("d8b880"))
					x += 8
				y += 6
			draw_rect(Rect2(0, 0, size.x, 2), Color("3a2a22"))
		Style.BOARDS:
			draw_rect(r, Color("5a3a28"))
			draw_rect(Rect2(0, 0, size.x, 2), Color("8a5a3a"))
			var y := 6.0
			while y < size.y:
				draw_rect(Rect2(0, y, size.x, 1), Color("3a2a1e"))
				var x := fposmod(y * 5.0, 40.0)
				while x < size.x:
					draw_rect(Rect2(x, y - 5, 1, 5), Color("3a2a1e"))
					x += 40
				y += 6
	draw_rect(r, Color("1d1a22"), false, 1.0)
