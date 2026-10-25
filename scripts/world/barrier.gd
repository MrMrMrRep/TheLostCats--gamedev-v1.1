@tool
class_name RoadBarrier
extends StaticBody2D
## Red-and-white road block with a sign: the edge of the map for now.

@export var text := "ROAD CLOSED"


func _ready() -> void:
	collision_layer = 1 << 0
	collision_mask = 0
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 200)
	col.shape = rect
	col.position = Vector2(0, -100)
	add_child(col)


func _draw() -> void:
	for x in [-14.0, 10.0]:
		draw_rect(Rect2(x, -18, 4, 18), WorldPalette.R2)
	for i in 6:
		draw_rect(Rect2(-16 + i * 6, -16, 6, 5), WorldPalette.B2 if i % 2 == 0 else Color.WHITE)
	draw_rect(Rect2(-22, -44, 44, 14), WorldPalette.O2)
	draw_string(ThemeDB.fallback_font, Vector2(-20, -34), text, HORIZONTAL_ALIGNMENT_CENTER, 40, 6, WorldPalette.T0)
