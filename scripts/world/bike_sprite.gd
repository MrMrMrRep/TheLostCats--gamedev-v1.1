class_name BikeSprite
extends Node2D
## A bike drawn under a band member while the band rides (placeholder art).

var facing := 1.0:
	set(value):
		facing = value
		queue_redraw()


func _draw() -> void:
	draw_bike(self, Vector2.ZERO, facing, Color(0.85, 0.85, 0.9))


static func draw_bike(ci: CanvasItem, at: Vector2, f: float, color: Color) -> void:
	var back := at + Vector2(-7 * f, -4)
	var front := at + Vector2(7 * f, -4)
	ci.draw_arc(back, 4.0, 0.0, TAU, 12, color, 1.0)
	ci.draw_arc(front, 4.0, 0.0, TAU, 12, color, 1.0)
	ci.draw_line(back, at + Vector2(0, -8), Color("c94a3d"), 1.5)
	ci.draw_line(at + Vector2(0, -8), front, Color("c94a3d"), 1.5)
	ci.draw_line(at + Vector2(5 * f, -11), front, color, 1.0)
