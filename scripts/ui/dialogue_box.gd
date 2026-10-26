class_name DialogueBox
extends CanvasLayer
## Bottom-of-screen dialogue with a typewriter effect. play() shows the lines
## one by one: E / Space / A finishes the current line, or goes to the next.
## Await play() to know when the conversation is over.

signal finished

const CHARS_PER_SECOND := 45.0
const ADVANCE_ACTIONS := ["interact", "jump", "action_a"]

var is_open := false

var _lines: Array[String] = []
var _index := 0
var _shown := 0.0
var _opened_frame := -1                     # the E that opened it must not advance it
var _panel: Panel
var _name_label: Label
var _text_label: Label
var _next_label: Label


func _ready() -> void:
	layer = 50
	_panel = Panel.new()
	_panel.position = Vector2(40, 270)
	_panel.size = Vector2(560, 76)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.08, 0.06, 0.1, 0.92)
	style.border_color = Color("ffd36b")
	style.set_border_width_all(1)
	style.set_corner_radius_all(3)
	_panel.add_theme_stylebox_override("panel", style)
	add_child(_panel)
	ScreenFit.pin(_panel, 0.5)
	_name_label = _label(Vector2(10, 4), Vector2(300, 12), 9, Color("ffd36b"))
	_text_label = _label(Vector2(10, 20), Vector2(540, 48), 9, Color.WHITE)
	_text_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_next_label = _label(Vector2(526, 58), Vector2(30, 12), 8, Color(1, 1, 1, 0.7))
	_next_label.text = "E ▸"
	_panel.visible = false


func play(speaker: String, lines: Array[String]) -> void:
	_lines = lines
	_index = 0
	_name_label.text = speaker
	is_open = true
	_opened_frame = Engine.get_process_frames()
	_panel.visible = true
	_show_line()
	await finished


func _process(delta: float) -> void:
	if not is_open:
		return
	var line := _lines[_index]
	if _shown < line.length():
		_shown = minf(_shown + CHARS_PER_SECOND * delta, line.length())
		_text_label.visible_characters = int(_shown)
	_next_label.visible = _shown >= line.length()
	if _advance_pressed() and Engine.get_process_frames() > _opened_frame + 1:
		if _shown < line.length():
			_shown = line.length()          # finish the line first
			_text_label.visible_characters = -1
		elif _index + 1 < _lines.size():
			_index += 1
			_show_line()
		else:
			_close()


func _show_line() -> void:
	Audio.sfx(&"talk", 0.15)
	_shown = 0.0
	_text_label.text = _lines[_index]
	_text_label.visible_characters = 0


func _close() -> void:
	is_open = false
	_panel.visible = false
	finished.emit()


func _advance_pressed() -> bool:
	for a in ADVANCE_ACTIONS:
		if Input.is_action_just_pressed(a):
			return true
	return false


func _label(pos: Vector2, size_px: Vector2, font_size: int, color: Color) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size_px
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	_panel.add_child(l)
	return l
