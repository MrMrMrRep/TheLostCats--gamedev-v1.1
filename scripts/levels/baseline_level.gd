extends Node2D
## Baseline test level (M2): clamps the player's camera to the level bounds.
## Replaced by the Room framework in M5.

@export var bounds := Rect2i(0, 0, 1440, 180)   ## playable area in pixels

@onready var camera: Camera2D = $Player/Camera


func _ready() -> void:
	camera.limit_left = bounds.position.x
	camera.limit_top = bounds.position.y
	camera.limit_right = bounds.end.x
	camera.limit_bottom = bounds.end.y
	camera.reset_smoothing()
