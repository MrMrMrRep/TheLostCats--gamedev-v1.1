class_name WorldParallax
extends Node2D
## A world-space parallax layer: content is drawn in map coordinates by its
## children; this node shifts by camera_x * (1 - factor) so factor 0 stays put on
## screen and factor 1 moves with the world. Works at any camera zoom (unlike
## Parallax2D), which the world map needs for its zoom changes.

@export var factor := 0.5


func _process(_delta: float) -> void:
	var cam := get_viewport().get_camera_2d()
	if cam:
		position.x = roundf(cam.get_screen_center_position().x * (1.0 - factor))
