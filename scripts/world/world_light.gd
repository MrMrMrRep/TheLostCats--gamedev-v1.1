@tool
class_name WorldLight
extends Node2D
## A light that comes on at night: a soft halo here and, if `pool`, a pool of
## light on the street below. Place it on a lantern, a sign, a doorway, a
## window: duplicate and drag. Draws nothing by day; in the editor it shows
## as a small bulb with its reach. Times and colours of the night:
## resources/config/day_config.tres.

@export var radius := 22.0:                 ## px reach of the halo
	set(value):
		radius = value
		queue_redraw()
@export var color := Color(1.0, 0.82, 0.5, 0.55):
	set(value):
		color = value
		queue_redraw()
@export var pool := true:                   ## also light up the street below
	set(value):
		pool = value
		queue_redraw()
@export var street_y := 288.0:              ## world y of the street (the pool)
	set(value):
		street_y = value
		queue_redraw()
@export_range(0.0, 0.9) var comes_on := 0.05  ## 0 = first at dusk .. 0.9 = only deep in the night

var _glow: NightGlow


func _ready() -> void:
	_glow = NightGlow.attach(self)
	if _glow:
		var floor_y := street_y - global_position.y if pool else NAN
		_glow.add_lamp(Vector2.ZERO, radius, floor_y, comes_on, color)


func _draw() -> void:
	if not Engine.is_editor_hint():
		return
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 32, Color(color, 0.6), 1.0)
	WorldPalette.disc(self, 0, 0, 3, Color(1.0, 0.9, 0.5))
	if pool:
		var fy := street_y - global_position.y
		draw_line(Vector2(0, 4), Vector2(0, fy), Color(color, 0.3), 1.0)
		draw_rect(Rect2(-radius * 1.5, fy - 2, radius * 3.0, 4), Color(color, 0.3))
