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
	["Sprint (world map)", "hold left Shift"],
	["Gather the band (hold)", "G"],
	["Pause", "Esc / P"],
]

const TITLE_SCENE := "res://scenes/ui/title.tscn"
const MAP_SCENE := "res://scenes/world/world_map.tscn"

var is_open := false

var _panel: Control
var _menu: MenuList
var _actions: Array[StringName] = []


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_panel = ColorRect.new()
	(_panel as ColorRect).color = Color(0.05, 0.06, 0.1, 0.85)
	_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_panel.visible = false
	add_child(_panel)
	var title := _label("PAUSED", Vector2(0, 26), 20, Color("ffd36b"))
	title.size.x = 640
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_menu = MenuList.new()
	_menu.position = Vector2(40, 90)
	_menu.size = Vector2(200, 120)
	_menu.chosen.connect(_on_chosen)
	_panel.add_child(_menu)
	for i in CONTROLS.size():
		var y := 80 + i * 17
		var what := _label(CONTROLS[i][0], Vector2(250, y), 8, Color(1, 1, 1, 0.7))
		what.size.x = 150
		what.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		_label(CONTROLS[i][1], Vector2(410, y), 8, Color.WHITE)
	var hint := _label("Up / Down + Enter, or click.   Esc / P: continue", Vector2(0, 318), 9, Color(1, 1, 1, 0.6))
	hint.size.x = 640
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause"):
		toggle()
		get_viewport().set_input_as_handled()


func toggle() -> void:
	var scene := get_tree().current_scene
	if not is_open and (get_tree().paused or (scene and scene.scene_file_path == TITLE_SCENE)):
		return                              # somebody else paused (death, respawn), or the title screen
	is_open = not is_open
	_panel.visible = is_open
	get_tree().paused = is_open
	if is_open:
		_build_menu(scene)


## What the menu offers here: in a level also restart the room / back to the map.
func _build_menu(scene: Node) -> void:
	_actions = [&"resume"]
	var names: Array = ["Resume"]
	if scene == null:
		scene = get_tree().get_first_node_in_group(&"level")
	if scene is Level and scene.party_only:     # a real level (not the base)
		_actions.append_array([&"restart", &"map"])
		names.append_array(["Restart room", "Back to the map"])
	_actions.append(&"title")
	names.append("Title screen")
	_menu.selected = 0
	_menu.set_options(names)


func _on_chosen(i: int) -> void:
	var what: StringName = _actions[i]
	toggle()                                # close first: unpaused
	match what:
		&"restart":
			var level := get_tree().current_scene as Level
			if level:
				level.restart_room()
		&"map":
			SceneRouter.go_to(MAP_SCENE, StringName(Game.get_flag(&"map_return", "")))
		&"title":
			SceneRouter.go_to(TITLE_SCENE)


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
