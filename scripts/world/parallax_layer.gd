@tool
class_name WorldParallax
extends Node2D
## A world-space parallax layer: content is drawn in map coordinates by its
## children; this node shifts by camera_x * (1 - factor) so factor 0 stays put on
## screen and factor 1 moves with the world. Works at any camera zoom (unlike
## Parallax2D), which the world map needs for its zoom changes.
##
## In the editor the layer shifts the same way with the editor view, so what
## you see in the middle of the screen is what the game shows there: drag a
## piece in this layer to where it should appear while you look at that spot.
## (A child's own x is in the layer's squeezed space: world x * factor.)
## Turn off `editor_preview` to see the layer unshifted.

@export var factor := 0.5:
	set(value):
		factor = value
		_shift()
@export var editor_preview := true:
	set(value):
		editor_preview = value
		_shift()


func _process(_delta: float) -> void:
	_shift()


func _notification(what: int) -> void:
	if what == NOTIFICATION_EDITOR_PRE_SAVE:
		position.x = 0.0                    # the scene stores the layer unshifted
	elif what == NOTIFICATION_EDITOR_POST_SAVE:
		_shift()


func _shift() -> void:
	if not is_inside_tree():
		return
	var cx := 0.0
	if Engine.is_editor_hint():
		if editor_preview:
			var vp := get_viewport()
			cx = (vp.global_canvas_transform.affine_inverse() * (vp.get_visible_rect().size / 2.0)).x
	else:
		var cam := get_viewport().get_camera_2d()
		if cam == null:
			return
		cx = cam.get_screen_center_position().x
	var x := roundf(cx * (1.0 - factor))
	if position.x != x:
		position.x = x
