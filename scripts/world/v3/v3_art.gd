@tool
class_name V3Art
extends Resource
## One piece of baked style-v3 world art (a row of houses, a hotel, a car...):
## the image as PNG bytes, where it sits, and its windows (for the night glow).
## Made by V3Painter, kept by V3Cache in res://assets/sprites/world/v3/.
## All in art px (half a world px); the node's origin is the street line.

@export var png := PackedByteArray()
@export var origin := Vector2i.ZERO         ## art px of the image's top-left corner, from the node's origin
@export var windows: Array = []             ## [Rect2i (art px from the origin), lit by day]

var _tex: Texture2D


func texture() -> Texture2D:
	if _tex == null and not png.is_empty():
		var img := Image.new()
		if img.load_png_from_buffer(png) == OK:
			_tex = ImageTexture.create_from_image(img)
	return _tex


## Size in art px.
func size() -> Vector2i:
	var t := texture()
	return Vector2i(t.get_size()) if t else Vector2i.ZERO


## Draws the art at `at` (the node's street-line origin, in the node's px);
## `px` = node px per art px (0.5 in the world; 1.0 on the screen-space sky).
func draw(ci: CanvasItem, at := Vector2.ZERO, px := 0.5, tint := Color.WHITE) -> void:
	var t := texture()
	if t:
		ci.draw_texture_rect(t, Rect2(at + Vector2(origin) * px, t.get_size() * px), false, tint)


## Registers the windows with a NightGlow (they light up one by one at night).
func add_glow(glow: NightGlow, at := Vector2.ZERO) -> void:
	if glow == null:
		return
	for w: Array in windows:
		var r: Rect2i = w[0]
		var rr := Rect2(at + Vector2(r.position) * 0.5 + Vector2(1, 1), Vector2(r.size) * 0.5 - Vector2(2, 2))
		if rr.size.x > 0.0 and rr.size.y > 0.0:
			glow.add_window(rr, NightGlow.window_threshold(r.position.x, r.position.y, bool(w[1])))
