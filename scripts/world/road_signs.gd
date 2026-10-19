@tool
class_name WorldFork
extends Node2D
## Where the city road and the motorway part: on the far side of the road a
## pair of blue direction signs (Centrum one way, the motorway the other),
## the square blue motorway sign and the round "no pedestrians, no bicycles"
## sign. West of here only the van may go. Origin = street line at the fork.

@export var city_side := 1.0                ## +1: the city is east of the fork


func _draw() -> void:
	var p := WorldPalette
	var post := Color("8a8f99")
	# Direction signs on two posts.
	draw_rect(Rect2(-46, -74, 3, 74), post)
	draw_rect(Rect2(40, -74, 3, 74), post)
	_panel(Vector2(-58, -104), "Centrum", "S100", city_side)
	_panel(Vector2(4, -104), "Den Haag", "A4", -city_side)
	# Motorway sign (blue square, white bridge pictogram) and the ban.
	var mx := -city_side * 70.0
	draw_rect(Rect2(mx - 1, -44, 2, 44), post)
	draw_rect(Rect2(mx - 9, -62, 18, 18), Color("2a5bd7"))
	draw_rect(Rect2(mx - 6, -55, 12, 2), p.WHITE)
	draw_rect(Rect2(mx - 6, -53, 2, 6), p.WHITE)
	draw_rect(Rect2(mx + 4, -53, 2, 6), p.WHITE)
	draw_rect(Rect2(mx - 2, -53, 4, 2), p.WHITE)
	var bx := city_side * 70.0
	draw_rect(Rect2(bx - 1, -40, 2, 40), post)
	WorldPalette.disc(self, bx, -48, 9, Color("c94a3d"))
	WorldPalette.disc(self, bx, -48, 7, p.WHITE)
	draw_rect(Rect2(bx - 5, -52, 2, 6), Color("1d1a22"))            # walker
	draw_rect(Rect2(bx - 6, -54, 3, 2), Color("1d1a22"))
	draw_arc(Vector2(bx + 2, -45), 2, 0, TAU, 8, Color("1d1a22"), 1.0)  # bike
	draw_arc(Vector2(bx + 6, -45), 2, 0, TAU, 8, Color("1d1a22"), 1.0)
	draw_line(Vector2(bx + 2, -45), Vector2(bx + 4, -49), Color("1d1a22"), 1.0)


func _panel(pos: Vector2, place: String, road: String, dir: float) -> void:
	var p := WorldPalette
	draw_rect(Rect2(pos - Vector2(1, 1), Vector2(56, 32)), p.WHITE)
	draw_rect(Rect2(pos, Vector2(54, 30)), Color("2a5bd7"))
	draw_string(ThemeDB.fallback_font, pos + Vector2(4, 11), place, HORIZONTAL_ALIGNMENT_LEFT, 48, 8, p.WHITE)
	var badge := Color("c94a3d") if road.begins_with("A") else Color("e0b23a")
	draw_rect(Rect2(pos + Vector2(4, 16), Vector2(18, 9)), badge)
	draw_string(ThemeDB.fallback_font, pos + Vector2(4, 23), road, HORIZONTAL_ALIGNMENT_CENTER, 18, 6, p.WHITE)
	var ax := pos.x + 42
	var ay := pos.y + 24
	draw_line(Vector2(ax - dir * 5, ay), Vector2(ax + dir * 5, ay - 8), p.WHITE, 2.0)     # arrow
	draw_line(Vector2(ax + dir * 5, ay - 8), Vector2(ax + dir * 5, ay - 3), p.WHITE, 2.0)
	draw_line(Vector2(ax + dir * 5, ay - 8), Vector2(ax, ay - 8), p.WHITE, 2.0)
