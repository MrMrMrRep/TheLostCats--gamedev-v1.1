@tool
class_name BaseRoomArt
extends Node2D
## The band's rehearsal room in the storage: brick back wall, wooden floor,
## a skirting board, a small high window, cables. `size` = the room (origin =
## top-left; the floor line is at `floor_y`).

@export var size := Vector2(640, 360):
	set(value):
		size = value
		queue_redraw()
@export var floor_y := 288.0:
	set(value):
		floor_y = value
		queue_redraw()


func _draw() -> void:
	var brick := Color("6a3a32")
	var mortar := Color("4a2822")
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, floor_y)), brick)
	var row := 0
	var y := 0.0
	while y < floor_y:
		draw_rect(Rect2(0, y + 5, size.x, 1), mortar)
		var x := -8.0 if row % 2 == 0 else 0.0
		while x < size.x:
			draw_rect(Rect2(x, y, 1, 6), mortar)
			if int(x * 7 + y) % 5 == 0:
				draw_rect(Rect2(x + 1, y, 14, 5), brick.lightened(0.06))
			x += 16
		y += 6
		row += 1
	# soft dark corners: it's a storage, not a palace
	for i in 6:
		draw_rect(Rect2(0, 0, size.x, 12 - i * 2), Color(0, 0, 0, 0.08))
	# small high window with the street light behind it
	var wx := size.x * 0.72
	draw_rect(Rect2(wx - 1, 61, 46, 22), Color("1d1a22"))
	draw_rect(Rect2(wx, 62, 44, 20), Color("3a4a6a"))
	draw_rect(Rect2(wx + 21, 62, 2, 20), Color("1d1a22"))
	draw_rect(Rect2(wx, 62, 44, 3), Color("5a6a8a"))
	# a long cable along the wall
	draw_line(Vector2(0, 120), Vector2(size.x * 0.4, 132), Color("1d1a22"), 1.0)
	draw_line(Vector2(size.x * 0.4, 132), Vector2(size.x, 118), Color("1d1a22"), 1.0)
	# skirting and floor planks
	draw_rect(Rect2(0, floor_y - 4, size.x, 4), Color("3a2a22"))
	draw_rect(Rect2(0, floor_y, size.x, size.y - floor_y), Color("8a5a3a"))
	var py := floor_y
	while py < size.y:
		draw_rect(Rect2(0, py, size.x, 1), Color("6a4228"))
		var px := fposmod(py * 3.0, 60.0)
		while px < size.x:
			draw_rect(Rect2(px, py, 1, 6), Color("6a4228"))
			px += 60
		py += 6
