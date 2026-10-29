@tool
class_name KitLandmark
extends Node2D
## One landmark building from the SpriteCook kit (CanalKit): a church, the
## Waag on the Nieuwmarkt, the theatre, the mall, the band's storage, the
## airport terminal. It stands in the house row like an opening does: the kit
## rows (CityBlock.kit) stop at its `span()`. Drawn at 1 texel = 1 art px,
## standing at the back of the pavement; its windows light up at night.
## Origin = its left end on the street line.

@export var piece := &"lm_church":
	set(value):
		piece = value
		queue_redraw()
@export var sign_text := "":                ## lettering on its board (CanalKit.SIGNS), if it has one
	set(value):
		sign_text = value
		queue_redraw()
@export var sign_color := Color("f2bc58")
@export_range(1, 6) var repeat := 1:        ## copies side by side (the terminal's halls)
	set(value):
		repeat = value
		queue_redraw()
@export var on_pavement := true:            ## false: stands right on the street line (the motorway, no kit pavement)
	set(value):
		on_pavement = value
		queue_redraw()

var _glow: NightGlow


func _ready() -> void:
	_glow = NightGlow.attach(self)
	queue_redraw()


## World x range it covers.
func span() -> Vector2:
	return Vector2(global_position.x, global_position.x + CanalRow.width(piece) * repeat * 0.5)


func _lift() -> int:
	return CanalRow.LIFT if on_pavement else 0


func _draw() -> void:
	if not CanalKit.SIZES.has(piece):
		return
	if _glow:
		_glow.clear()
	var w := CanalRow.width(piece)
	var top := -CanalRow.height(piece) - _lift()
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	for i in repeat:
		draw_texture(CanalRow.texture(piece), Vector2(w * i, top))
	draw_set_transform(Vector2.ZERO)
	if sign_text != "" and CanalKit.SIGNS.has(piece):
		var sign: Rect2i = CanalKit.SIGNS[piece]
		var board := Rect2(sign.position.x * 0.5, (top + sign.position.y) * 0.5, sign.size.x * 0.5, sign.size.y * 0.5)
		var base := roundf((board.position.y + (board.size.y + 3.5) * 0.5) * 2.0) * 0.5
		PixelFont.draw_string(self, Vector2(board.position.x, base), sign_text, HORIZONTAL_ALIGNMENT_CENTER, board.size.x, 5, sign_color)
	var row := []
	for i in repeat:
		row.append([piece, w * i, 0])
	CanalRow.add_glow(_glow, row, Vector2(0, (CanalRow.LIFT - _lift()) * 0.5))
	if _glow:
		_glow.queue_redraw()
