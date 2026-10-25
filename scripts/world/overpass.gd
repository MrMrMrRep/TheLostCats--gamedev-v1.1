@tool
class_name WorldOverpass
extends Node2D
## The ring road crossing over our road at the edge of town: a concrete
## viaduct seen side-on. Two nodes share this script:
##   BACK   the far pillars, the shadow on the road, the speed signs (drawn
##          behind the band and the van)
##   FRONT  the deck with its parapet, a gantry sign and the near pillars
##          standing in the water (drawn in front: you drive under it)
## West of it the van may speed up again (the city limit ends here).
## Origin = street line at the centre of the deck.

enum Part { BACK, FRONT }

const CONCRETE := WorldPalette.R3
const DECK_BOTTOM := -64.0
const DECK_H := 20.0

@export var part := Part.BACK:
	set(value):
		part = value
		queue_redraw()
@export var width := 120.0                  ## deck width along our road
@export var city_side := 1.0                ## +1: the city is east of the overpass
@export var structure := true               ## false: only the speed signs (the city limit)
@export var only_sign := ""                 ## with structure off: "50" or "100" draws just that sign at x 0


func _draw() -> void:
	var half := width / 2.0
	if part == Part.BACK:
		_back(half)
	else:
		_front(half)


func _pillar(x: float, top: float, bottom: float, c: Color) -> void:
	draw_rect(Rect2(x - 7, top, 14, bottom - top), c)
	draw_rect(Rect2(x + 3, top, 4, bottom - top), c.darkened(0.18))
	draw_rect(Rect2(x - 10, top, 20, 5), c.lightened(0.06))           # bearing cap
	draw_rect(Rect2(x - 8, bottom - 3, 16, 3), c.darkened(0.25))


func _back(half: float) -> void:
	if not structure:
		if only_sign != "":
			_speed_sign(0.0, only_sign)
			return
		_speed_sign(city_side * 30.0, "50")
		_speed_sign(-city_side * 30.0, "100")
		return
	var far := CONCRETE.lerp(WorldPalette.HAZE, 0.3)
	_pillar(-half + 14, DECK_BOTTOM, -2, far)
	_pillar(half - 14, DECK_BOTTOM, -2, far)
	draw_rect(Rect2(-half, -2, width, 22), Color(0, 0, 0, 0.18))       # shadow on the road
	# Speed signs: 50 on the city side, 100 on the open road.
	_speed_sign(city_side * (half + 30), "50")
	_speed_sign(-city_side * (half + 30), "100")


func _speed_sign(x: float, text: String) -> void:
	draw_rect(Rect2(x - 1, -40, 2, 40), WorldPalette.R2)
	WorldPalette.disc(self, x, -46, 8, WorldPalette.B2)
	WorldPalette.disc(self, x, -46, 6, WorldPalette.W5)
	draw_string(ThemeDB.fallback_font, Vector2(x - 8, -43), text, HORIZONTAL_ALIGNMENT_CENTER, 16, 7, WorldPalette.T0)


func _front(half: float) -> void:
	if not structure:
		return
	var p := WorldPalette
	# Near pillars down into the water.
	_pillar(-half + 18, DECK_BOTTOM, 40, CONCRETE.darkened(0.05))
	_pillar(half - 18, DECK_BOTTOM, 40, CONCRETE.darkened(0.05))
	# Deck: underside in shadow, the side face, a parapet with a rail.
	draw_rect(Rect2(-half - 20, DECK_BOTTOM - DECK_H, width + 40, DECK_H), CONCRETE)
	draw_rect(Rect2(-half - 20, DECK_BOTTOM - 3, width + 40, 3), CONCRETE.darkened(0.3))
	draw_rect(Rect2(-half - 20, DECK_BOTTOM - DECK_H, width + 40, 2), CONCRETE.lightened(0.1))
	for x in range(int(-half - 16), int(half + 20), 24):               # panel joints
		draw_rect(Rect2(x, DECK_BOTTOM - DECK_H + 2, 1, DECK_H - 5), CONCRETE.darkened(0.12))
	draw_rect(Rect2(-half - 20, DECK_BOTTOM - DECK_H - 8, width + 40, 8), CONCRETE.darkened(0.04))
	draw_rect(Rect2(-half - 20, DECK_BOTTOM - DECK_H - 11, width + 40, 2), WorldPalette.R2)
	for x in range(int(-half - 18), int(half + 20), 8):
		draw_rect(Rect2(x, DECK_BOTTOM - DECK_H - 11, 1, 3), WorldPalette.R2)
	# A drip stain and a bit of graffiti, the way overpasses look.
	draw_rect(Rect2(-half + 40, DECK_BOTTOM - DECK_H + 4, 2, 14), CONCRETE.darkened(0.2))
	draw_string(ThemeDB.fallback_font, Vector2(-14, DECK_BOTTOM - 6), "LOST CATS", HORIZONTAL_ALIGNMENT_LEFT, -1, 7, WorldPalette.B2)
	# Gantry sign on the deck edge.
	draw_rect(Rect2(-36, DECK_BOTTOM - DECK_H - 34, 72, 22), WorldPalette.T2)
	draw_rect(Rect2(-36, DECK_BOTTOM - DECK_H - 34, 72, 1), p.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(-36, DECK_BOTTOM - DECK_H - 25), "A10  RING", HORIZONTAL_ALIGNMENT_CENTER, 72, 8, p.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(-36, DECK_BOTTOM - DECK_H - 16), "CENTRUM  ->" if city_side > 0 else "<-  CENTRUM", HORIZONTAL_ALIGNMENT_CENTER, 72, 7, p.WHITE)
	draw_rect(Rect2(-30, DECK_BOTTOM - DECK_H - 12, 2, 4), WorldPalette.R2)
	draw_rect(Rect2(28, DECK_BOTTOM - DECK_H - 12, 2, 4), WorldPalette.R2)
