class_name MenuList
extends Control
## A vertical list of menu options: Up/Down (or W/S) to pick, Enter / Space /
## E to choose, or hover and click with the mouse. Works while the game is
## paused. `chosen(index)` fires on a choice.

signal chosen(index: int)

const COLOR := Color(1, 1, 1, 0.75)
const SELECTED := Color("ffd36b")

@export var spacing := 22.0
@export var font_size := 14
@export var centred := true

var selected := 0
var _labels: Array[Label] = []


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_options(options: Array) -> void:
	for l in _labels:
		l.queue_free()
	_labels.clear()
	for i in options.size():
		var l := Label.new()
		l.text = options[i]
		l.position = Vector2(0, i * spacing)
		l.size = Vector2(size.x, spacing)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if centred else HORIZONTAL_ALIGNMENT_LEFT
		l.add_theme_font_size_override("font_size", font_size)
		l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
		l.add_theme_constant_override("outline_size", 4)
		l.mouse_filter = Control.MOUSE_FILTER_STOP
		l.mouse_entered.connect(func() -> void: select(i))
		l.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				select(i)
				chosen.emit(i))
		add_child(l)
		_labels.append(l)
	select(clampi(selected, 0, options.size() - 1))


func select(i: int) -> void:
	selected = i
	for k in _labels.size():
		var on := k == i
		_labels[k].add_theme_color_override("font_color", SELECTED if on else COLOR)
		_labels[k].text = ("> " + _labels[k].text.trim_prefix("> ").trim_suffix(" <") + " <") if on else _labels[k].text.trim_prefix("> ").trim_suffix(" <")


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _labels.is_empty():
		return
	if event.is_action_pressed("ui_down") or event.is_action_pressed("move_down"):
		select(wrapi(selected + 1, 0, _labels.size()))
	elif event.is_action_pressed("ui_up") or event.is_action_pressed("move_up"):
		select(wrapi(selected - 1, 0, _labels.size()))
	elif event.is_action_pressed("ui_accept") or event.is_action_pressed("interact") or event.is_action_pressed("jump"):
		chosen.emit(selected)
	else:
		return
	get_viewport().set_input_as_handled()
