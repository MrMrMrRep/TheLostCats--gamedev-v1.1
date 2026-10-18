extends CanvasLayer
## Scene changes with a fade, for doors (world map <-> level, room <-> room).
## Registered as the `SceneRouter` autoload. The new scene reads
## `pending_spawn` in _ready() to place the band at the right door.

signal transition_started(target: String)
signal transition_finished(target: String)

const FADE_TIME := 0.35

var pending_spawn: StringName = &""
var is_transitioning: bool = false

var _fade: ColorRect


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)


func go_to(scene_path: String, spawn: StringName = &"") -> void:
	if is_transitioning:
		return
	is_transitioning = true
	pending_spawn = spawn
	transition_started.emit(scene_path)
	await _tween_fade(1.0)
	var err := get_tree().change_scene_to_file(scene_path)
	if err != OK:
		push_error("SceneRouter: cannot load %s (error %d)" % [scene_path, err])
	await get_tree().process_frame
	await _tween_fade(0.0)
	is_transitioning = false
	transition_finished.emit(scene_path)


func _tween_fade(to_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", to_alpha, FADE_TIME)
	await tween.finished
