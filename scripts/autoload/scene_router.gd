extends CanvasLayer
## Scene changes with a fade, for doors (world map <-> level, room <-> room).
## Leaving the title passes a loading line: a canal screen stays up while the
## next scene loads, then fades away. Registered as the `SceneRouter` autoload.
## The new scene reads `pending_spawn` in _ready() to place the band at the right door.

signal transition_started(target: String)
signal transition_finished(target: String)

const FADE_TIME := 0.35
const LOAD_MIN := 0.7                       # seconds the loading screen stays up, even if the scene is cached

var pending_spawn: StringName = &""
var is_transitioning: bool = false

var _fade: ColorRect
var _load: Control
var _caption: Label
var _fill: ColorRect
var _town: Node2D


func _ready() -> void:
	layer = 100
	process_mode = Node.PROCESS_MODE_ALWAYS
	_fade = ColorRect.new()
	_fade.color = Color.BLACK
	_fade.modulate.a = 0.0
	_fade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_fade.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(_fade)
	_build_loading()


func _process(_delta: float) -> void:
	if _load != null and _load.visible and _town != null:
		_town.queue_redraw()


func go_to(scene_path: String, spawn: StringName = &"", loading := "") -> void:
	if is_transitioning:
		return
	is_transitioning = true
	pending_spawn = spawn
	transition_started.emit(scene_path)
	if loading != "":
		await _play_loading(scene_path, loading)
	else:
		Audio.sfx(&"door")
		await _tween_fade(1.0)
		var err := get_tree().change_scene_to_file(scene_path)
		if err != OK:
			push_error("SceneRouter: cannot load %s (error %d)" % [scene_path, err])
		await get_tree().process_frame
		await _tween_fade(0.0)
	is_transitioning = false
	transition_finished.emit(scene_path)


## Fade to black (doors inside a level, death). Works while the tree is paused.
func fade_out() -> void:
	await _tween_fade(1.0)


func fade_in() -> void:
	await _tween_fade(0.0)


func _tween_fade(to_alpha: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade, "modulate:a", to_alpha, FADE_TIME)
	await tween.finished


## Sky, a row of canal houses, the quay and the canal. The picked cat walks
## the quay while the bar fills. Sits above every scene.
func _build_loading() -> void:
	_load = Control.new()
	_load.set_anchors_preset(Control.PRESET_FULL_RECT)
	_load.mouse_filter = Control.MOUSE_FILTER_STOP
	_load.visible = false
	add_child(_load)
	var sky := ColorRect.new()
	sky.color = Color("48c1ca")
	sky.set_anchors_preset(Control.PRESET_FULL_RECT)
	sky.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load.add_child(sky)
	var water := ColorRect.new()
	water.color = Color("1c5560")
	water.anchor_left = 0.0
	water.anchor_right = 1.0
	water.anchor_top = 1.0
	water.anchor_bottom = 1.0
	water.offset_top = -78.0
	water.offset_bottom = 0.0
	water.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load.add_child(water)
	var quay := ColorRect.new()
	quay.color = Color("7c8590")
	quay.anchor_left = 0.0
	quay.anchor_right = 1.0
	quay.anchor_top = 1.0
	quay.anchor_bottom = 1.0
	quay.offset_top = -96.0
	quay.offset_bottom = -78.0
	quay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load.add_child(quay)
	var cap := ColorRect.new()
	cap.color = Color("d8bf94")
	cap.anchor_left = 0.0
	cap.anchor_right = 1.0
	cap.anchor_top = 1.0
	cap.anchor_bottom = 1.0
	cap.offset_top = -98.0
	cap.offset_bottom = -96.0
	cap.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load.add_child(cap)
	_town = Node2D.new()
	_town.name = "Town"
	_town.draw.connect(_draw_town)
	_load.add_child(_town)
	_load.add_child(_label("THE LOST CATS", 28.0, 22, Color("f2bc58")))
	_caption = _label("Loading the tour", 64.0, 16, Color("fff7df"))
	_load.add_child(_caption)
	var track := ColorRect.new()
	track.color = Color("1d2838")
	track.anchor_left = 0.5
	track.anchor_right = 0.5
	track.offset_left = -84.0
	track.offset_right = 84.0
	track.offset_top = 100.0
	track.offset_bottom = 108.0
	track.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_load.add_child(track)
	_fill = ColorRect.new()
	_fill.color = Color("f2bc58")
	_fill.set_anchors_preset(Control.PRESET_FULL_RECT)
	_fill.offset_right = -168.0
	_fill.mouse_filter = Control.MOUSE_FILTER_IGNORE
	track.add_child(_fill)


const HOUSES := [Color("8f3f40"), Color("f3e4bc"), Color("e08a36"), Color("bd5a4b"), Color("4b8189"), Color("d8bf94")]


func _draw_town() -> void:
	var view := get_viewport().get_visible_rect().size
	var ground := view.y - 98.0
	var x := -8.0
	var i := 0
	while x < view.x + 8.0:
		var w := 34.0 + (i % 4) * 10.0
		var h := 64.0 + (i % 5) * 14.0
		var wall: Color = HOUSES[i % HOUSES.size()]
		_town.draw_rect(Rect2(x, ground - h, w, h), wall)
		_town.draw_rect(Rect2(x, ground - h, w, 6.0), wall.darkened(0.25))
		var wy := ground - h + 16.0
		while wy < ground - 16.0:
			_town.draw_rect(Rect2(x + 6.0, wy, 8.0, 10.0), Color("1d2838"))
			if w > 40.0:
				_town.draw_rect(Rect2(x + w - 16.0, wy, 8.0, 10.0), Color("1d2838"))
			wy += 18.0
		_town.draw_rect(Rect2(x + w * 0.5 - 5.0, ground - 16.0, 10.0, 16.0), Color("4a3434"))
		x += w - 2.0
		i += 1
	var t := Time.get_ticks_msec() / 1000.0
	var cx := fposmod(t * 36.0, view.x + 48.0) - 24.0
	_draw_cat(cx, ground, int(t * 8.0) % 2 == 0)


func _draw_cat(x: float, ground: float, step: bool) -> void:
	var y := ground - (1.0 if step else 0.0)
	_town.draw_rect(Rect2(x, y - 10.0, 14.0, 8.0), Color("f2bc58"))
	_town.draw_rect(Rect2(x + 10.0, y - 14.0, 8.0, 8.0), Color("f2bc58"))
	_town.draw_rect(Rect2(x + 15.0, y - 13.0, 2.0, 2.0), Color("1d2838"))
	_town.draw_rect(Rect2(x + 8.0, y - 16.0, 2.0, 3.0), Color("f2bc58"))
	_town.draw_rect(Rect2(x + 14.0, y - 16.0, 2.0, 3.0), Color("f2bc58"))
	var leg := 2.0 if step else 0.0
	_town.draw_rect(Rect2(x + 2.0, y - 2.0, 2.0, 2.0 + leg), Color("4a3434"))
	_town.draw_rect(Rect2(x + 8.0, y - 2.0 - leg, 2.0, 2.0 + leg), Color("4a3434"))
	_town.draw_rect(Rect2(x - 4.0, y - 8.0, 5.0, 2.0), Color("f2bc58"))


func _label(text: String, y: float, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.anchor_left = 0.0
	l.anchor_right = 1.0
	l.offset_left = 0.0
	l.offset_right = 0.0
	l.offset_top = y
	l.offset_bottom = y + size + 10.0
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("1d2838"))
	l.add_theme_constant_override("outline_size", 1)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


func _set_bar(amount: float) -> void:
	_fill.offset_right = -168.0 * (1.0 - clampf(amount, 0.0, 1.0))


func _play_loading(scene_path: String, loading: String) -> void:
	_caption.text = loading
	_set_bar(0.12)
	_load.modulate.a = 1.0
	_load.visible = true
	var started := Time.get_ticks_msec()
	var shown := 0.12
	var packed: PackedScene = null
	if ResourceLoader.load_threaded_request(scene_path) == OK:
		while true:
			var prog: Array = []
			var status := ResourceLoader.load_threaded_get_status(scene_path, prog)
			var reported := float(prog[0]) if not prog.is_empty() else 0.0
			if status == ResourceLoader.THREAD_LOAD_LOADED:
				shown = 1.0
				break
			if status != ResourceLoader.THREAD_LOAD_IN_PROGRESS:
				break
			shown = maxf(shown, minf(reported, 0.9))
			shown = minf(shown + 0.035, 0.9)
			_set_bar(shown)
			var dots := int(Time.get_ticks_msec() / 280) % 4
			_caption.text = loading + ".".repeat(dots)
			await get_tree().process_frame
		packed = ResourceLoader.load_threaded_get(scene_path) as PackedScene
	if packed == null:
		packed = load(scene_path) as PackedScene
	var hold := LOAD_MIN - (Time.get_ticks_msec() - started) / 1000.0
	if hold > 0.0:
		_set_bar(1.0)
		_caption.text = loading
		await get_tree().create_timer(hold, true).timeout
	_set_bar(1.0)
	_caption.text = loading
	await get_tree().process_frame
	if packed == null:
		push_error("SceneRouter: cannot load %s" % scene_path)
	else:
		var err := get_tree().change_scene_to_packed(packed)
		if err != OK:
			push_error("SceneRouter: cannot load %s (error %d)" % [scene_path, err])
		# _ready of the new scene has run; give it a frame to draw under the screen.
		await get_tree().process_frame
		await get_tree().process_frame
	var tween := create_tween()
	tween.tween_property(_load, "modulate:a", 0.0, FADE_TIME)
	await tween.finished
	_load.visible = false
	_load.modulate.a = 1.0
