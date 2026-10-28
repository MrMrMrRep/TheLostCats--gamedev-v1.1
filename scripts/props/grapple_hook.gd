@tool
class_name GrappleHook
extends Node2D
## A hook in the ceiling (a rigging eye, a lamp bracket). Nikki's special
## shoots her grapple at the nearest one within reach and she swings from it.
## Origin = the eye.

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group(&"grapple_hook")


func _draw() -> void:
	draw_line(Vector2(0, -8), Vector2(0, -3), Color("5a5f6a"), 2.0)
	draw_arc(Vector2.ZERO, 3.5, 0.0, TAU, 12, Color("c8ccd4"), 1.5)
