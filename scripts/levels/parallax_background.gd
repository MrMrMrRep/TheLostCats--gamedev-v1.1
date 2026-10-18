extends Node2D
## Holds the Parallax2D layers. Layers with scroll_scale.y < 1 are (partly)
## screen-locked vertically, so rooms can be taller than the 180 px art.
## Parallax2D misplaces those layers by half a view when the camera is zoomed,
## so this shifts them back: offset = half view height * (1 - scroll_scale.y).


func _ready() -> void:
	var camera := get_viewport().get_camera_2d()
	var zoom := camera.zoom if camera else Vector2.ONE
	var half_view := get_viewport_rect().size / zoom / 2.0
	for layer in get_children():
		if layer is Parallax2D:
			layer.scroll_offset.y = half_view.y * (1.0 - layer.scroll_scale.y)
