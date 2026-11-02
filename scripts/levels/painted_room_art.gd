@tool
class_name PaintedRoomArt
extends Node2D
## A room's back wall from a painting (The International: SpriteCook paintings
## of the real bar and hotel, cut by tools/spritecook/international.py). Drawn
## at 1 texel = half a world px (as sharp as the band) from the room's
## top-left; the painted floor sits on the level's floor line (y 288).
## Purely visual.

@export var texture: Texture2D:
	set(value):
		texture = value
		queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST


func _draw() -> void:
	if texture:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
		draw_texture(texture, Vector2.ZERO)
		draw_set_transform(Vector2.ZERO)
