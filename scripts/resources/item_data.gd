class_name ItemData
extends Resource
## One kind of item (beer, keycard, rolling papers...). Members carry up to 3 in
## their Inventory. Placeholder icons are drawn in code from `shape` + `color`.

enum Shape { BOTTLE, CARD, PAPERS, BOX, STICK }

@export var id: StringName
@export var display_name := ""
@export_multiline var description := ""     ## shown when used without an effect
@export var shape := Shape.BOX
@export var color := Color.WHITE
@export var consumable := false
@export var only_for: StringName            ## member id that can use it ("" = anyone)
@export var lures: StringName               ## member id that follows whoever carries it
@export var weapon := false                 ## selected in the inventory: punches use it
@export var weapon_reach := 36.0            ## px in front of the member a weapon hit reaches


## Draw the icon centred on `c`, about 8 px tall.
func draw_icon(ci: CanvasItem, c: Vector2) -> void:
	match shape:
		Shape.BOTTLE:
			ci.draw_rect(Rect2(c + Vector2(-1.5, -3), Vector2(3, 6)), color)
			ci.draw_rect(Rect2(c + Vector2(-0.5, -4.5), Vector2(1, 2)), color)
			ci.draw_rect(Rect2(c + Vector2(-1.5, -1), Vector2(3, 1.5)), Color("f0e0b0"))
		Shape.CARD:
			ci.draw_rect(Rect2(c + Vector2(-3, -2), Vector2(6, 4)), color)
			ci.draw_rect(Rect2(c + Vector2(-3, -1), Vector2(6, 1)), Color(0.1, 0.1, 0.1))
		Shape.PAPERS:
			ci.draw_rect(Rect2(c + Vector2(-3, -2), Vector2(6, 4)), color)
			ci.draw_line(c + Vector2(-2, 0), c + Vector2(2, 0), Color(0.6, 0.5, 0.4), 1.0)
		Shape.STICK:
			ci.draw_line(c + Vector2(-3, 3), c + Vector2(3, -3), color, 1.5)
			ci.draw_circle(c + Vector2(3, -3), 1.5, Color(0.25, 0.25, 0.3))
		_:
			ci.draw_rect(Rect2(c + Vector2(-2.5, -2.5), Vector2(5, 5)), color)
