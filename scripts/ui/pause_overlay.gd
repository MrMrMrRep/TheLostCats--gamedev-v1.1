extends CanvasLayer
## Esc / P: pause the game and show the controls. Registered as the `Pause`
## autoload. Leaves pauses it didn't make alone (death, respawn).

const CONTROLS := [
	["Move", "Arrows / WASD"],
	["Jump", "Space / C   (down + jump: drop through a platform)"],
	["Ability", "J / X"],
	["Second ability / drink beer", "K / Z"],
	["Interact (doors, talk) or use item", "E"],
	["Use item", "R   (in the van: radio)"],
	["Next item / give / drop", "T / F / V"],
	["Switch member", "1-5, Tab, Q"],
	["Gather the band (hold)", "G"],
	["Pause", "Esc / P"],
]

var is_open := false

var _panel: Control


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = ColorRect.new()
	(_panel as ColorRect).color = Color(0.05, 0.06, 0.1, 0.82)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	add_child(_panel)
	var title := _label("PAUSED", Vector2(0, 40), 20, Color("ffd36b"))
	title.size.x = 640
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	for i in CONTROLS.size():
		var y := 90 + i * 20
		var what := _label(CONTROLS[i][0], Vector2(70, y), 10, Color(1, 1, 1, 0.8))
		what.size.x = 230
		what.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_label(CONTROLS[i][1], Vector2(320, y), 10, Color.WHITE)
	var hint := _label("Esc / P to continue", Vector2(0, 312), 10, Color(1, 1, 1, 0.6))
	hint.size.x = 640
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	if not is_open and get_tree().paused:
		return                              # somebody else paused (death, respawn)
	is_open = not is_open
	_panel.visible = is_open
	get_tree().paused = is_open


func _label(text: String, pos: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color.BLACK)
	l.add_theme_constant_override("outline_size", 3)
	_panel.add_child(l)
	return l
