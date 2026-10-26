class_name PartySelect
extends CanvasLayer
## "Who goes out?": pick the party at the base. 1-5 (or a click) toggles a
## member, E / Enter is done, Esc cancels. At least one has to go. Only the
## party shows up on the world map (and goes into levels from there).

signal closed

static var _closed_at := -100000

var _going: Array[StringName] = []
var _rows: Array[Label] = []
var _status: Array[Label] = []
var _note: Label
var _opened_at := 0
var _band: Band


static func recently_closed() -> bool:
	return Time.get_ticks_msec() - _closed_at < 300


func _ready() -> void:
	layer = 60
	process_mode = Node.PROCESS_MODE_ALWAYS
	_opened_at = Time.get_ticks_msec()
	_going.assign(Game.party)
	var level := get_parent() as Level
	if level:
		_band = level.band
		_band.locked = true
		_band.active.set_active(false)
	var dim := ColorRect.new()
	dim.color = Color(0.03, 0.03, 0.06, 0.7)
	dim.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(dim)
	var panel := ColorRect.new()
	panel.color = Color("2a2230")
	panel.position = Vector2(200, 70)
	panel.size = Vector2(240, 210)
	add_child(panel)
	_label("Who goes out?", Vector2(200, 80), 14, Color("ffd36b"), 240)
	for i in Game.MEMBERS.size():
		var row := _label("", Vector2(226, 112 + i * 22), 11, Color.WHITE, 110)
		row.mouse_filter = Control.MOUSE_FILTER_STOP
		row.gui_input.connect(_on_row_input.bind(i))
		_rows.append(row)
		_status.append(_label("", Vector2(330, 112 + i * 22), 11, Color.WHITE, 110))
	_note = _label("", Vector2(200, 226), 8, Color(1, 0.6, 0.5), 240)
	_label("1-5 or click: in / out", Vector2(200, 246), 8, Color(1, 1, 1, 0.7), 240)
	_label("E: done     Esc: cancel", Vector2(200, 258), 8, Color(1, 1, 1, 0.7), 240)
	for c in get_children():                # centred on wide screens
		if c is Control and c != dim:
			ScreenFit.pin(c, 0.5)
	_refresh()


func _label(text: String, pos: Vector2, size: int, color: Color, width: float) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(width, size + 6)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER if width > 200 else HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	add_child(l)
	return l


func _refresh() -> void:
	for i in Game.MEMBERS.size():
		var id := Game.MEMBERS[i]
		var going := _going.has(id)
		_rows[i].text = "%d   %s" % [i + 1, _name(id)]
		_status[i].text = "going" if going else "stays home"
		for l in [_rows[i], _status[i]]:
			l.add_theme_color_override("font_color", Color("8fe08a") if going else Color(1, 1, 1, 0.45))


func _name(id: StringName) -> String:
	var names := {&"joep": "Joep", &"jay": "Jay", &"nikki": "Nikki", &"germ": "The Germ", &"geoff": "Geoff"}
	return names.get(id, String(id))


func toggle(i: int) -> void:
	var id := Game.MEMBERS[i]
	if _going.has(id):
		if _going.size() == 1:
			_note.text = "Someone has to go!"
			return
		_going.erase(id)
	else:
		_going.append(id)
	_note.text = ""
	_refresh()


func _on_row_input(event: InputEvent, i: int) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		toggle(i)


func _process(_delta: float) -> void:
	for i in Game.MEMBERS.size():
		if Input.is_action_just_pressed("select_%d" % (i + 1)):
			toggle(i)
	if Time.get_ticks_msec() - _opened_at < 300:
		return
	if Input.is_action_just_pressed("interact") or Input.is_action_just_pressed("ui_accept"):
		confirm()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") or event.is_action_pressed("pause"):
		get_viewport().set_input_as_handled()   # Esc closes this, not the pause menu
		close()


## Keep the choice (in band order).
func confirm() -> void:
	var order: Array[StringName] = []
	for id in Game.MEMBERS:
		if _going.has(id):
			order.append(id)
	Game.party = order
	close()


func close() -> void:
	_closed_at = Time.get_ticks_msec()
	if _band:
		_band.locked = false
		_band.active.set_active(true)
	closed.emit()
	queue_free()
