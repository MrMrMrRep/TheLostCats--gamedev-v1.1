@tool
class_name KitLandmark
extends Node2D
## One landmark building from the SpriteCook kit (CanalKit): a church, the
## Waag on the Nieuwmarkt. It stands in the house row like an opening does:
## the kit rows (CityBlock.kit) stop at its `span()`. Drawn at 1 texel = 1 art
## px, standing at the back of the pavement; its windows light up at night.
## Origin = its left end on the street line.

@export var piece := &"lm_church":
	set(value):
		piece = value
		queue_redraw()

var _glow: NightGlow


func _ready() -> void:
	_glow = NightGlow.attach(self)
	queue_redraw()


## World x range it covers.
func span() -> Vector2:
	return Vector2(global_position.x, global_position.x + CanalRow.width(piece) * 0.5)


func _draw() -> void:
	if not CanalKit.SIZES.has(piece):
		return
	if _glow:
		_glow.clear()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	draw_texture(CanalRow.texture(piece), Vector2(0, -CanalRow.height(piece) - CanalRow.LIFT))
	draw_set_transform(Vector2.ZERO)
	CanalRow.add_glow(_glow, [[piece, 0, 0]])
	if _glow:
		_glow.queue_redraw()
