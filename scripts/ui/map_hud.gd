class_name MapHud
extends CanvasLayer
## World map HUD, kept small and tidy so the street stays the picture: the
## character box top left (who you are; tap it: the next member, hold it:
## their items), the current objective next to it (a gold quest mark, the
## vehicle hint under it), the clock and coins in a panel top right, the van
## radio's station under that. Tap the clock: a little panel to turn time an
## hour back or on (DayConfig.time_buttons). The controls line along the
## bottom shows for the first seconds and then fades out (it comes back for a
## while when the band stands still long).

signal skip_requested(hours: float)         # sleep this many hours (fade out, the clock jumps on)
signal time_shift_requested(hours: float)   # the time panel's -1 h / +1 h
signal switch_requested                     # the character box was tapped
signal inventory_requested                  # ... or held

const INK := Color("fff7df")                ## WorldPalette.W5
const DIM := Color("b0dcc9")                ## WorldPalette.T6
const GOLD := Color("f2bc58")               ## WorldPalette.O2
const PANEL := Color(0.114, 0.157, 0.220, 0.78)   ## WorldPalette.T0, see-through
const EDGE := Color("35606c")               ## WorldPalette.T2
const HINT_SHOW := 10.0                     ## seconds the controls line shows at the start
const HINT_IDLE := 25.0                     ## seconds of no input before it shows again

var _objective: Label
var _coins: Label
var _vehicle: Label
var _radio: Label
var _clock: Label
var _left: PanelContainer
var _right: PanelContainer
var _time: PanelContainer                   # the -1 h / +1 h panel under the clock
var _time_label: Label
var _card: MemberCard
var _hint: Label                            # the scene's DevHint/Hint line
var _hint_time := 0.0
var _idle := 0.0


func _ready() -> void:
	layer = 40
	# Top left: the character box, then the objective (+ vehicle hint).
	_left = _panel()
	_left.position = Vector2(6 + MemberCard.SIZE.x + 4, 6)
	var lbox := VBoxContainer.new()
	lbox.add_theme_constant_override("separation", 1)
	_left.add_child(lbox)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	lbox.add_child(row)
	var mark := _label(GOLD)
	mark.text = "!"
	row.add_child(mark)
	_objective = _label(INK)
	row.add_child(_objective)
	_vehicle = _label(DIM)
	_vehicle.visible = false
	lbox.add_child(_vehicle)
	# Top right: clock and coins.
	_right = _panel()
	var rbox := HBoxContainer.new()
	rbox.add_theme_constant_override("separation", 6)
	_right.add_child(rbox)
	_clock = _label(INK)
	rbox.add_child(_clock)
	var coin := TextureRect.new()
	coin.texture = _coin_texture()
	coin.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	coin.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	rbox.add_child(coin)
	_coins = _label(GOLD)
	rbox.add_child(_coins)
	_radio = _label(GOLD)
	_radio.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	add_child(_radio)
	# Tap the clock: turn time an hour back or on.
	if DayConfig.current().time_buttons:
		_right.mouse_filter = Control.MOUSE_FILTER_STOP
		_right.gui_input.connect(func(e: InputEvent) -> void:
			if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT:
				toggle_time_panel()
				_right.accept_event())
	_time = _panel()
	_time.visible = false
	_time.mouse_filter = Control.MOUSE_FILTER_STOP
	var trow := HBoxContainer.new()
	trow.add_theme_constant_override("separation", 4)
	_time.add_child(trow)
	trow.add_child(_time_button("-1 h", -1.0))
	_time_label = _label(INK)
	trow.add_child(_time_label)
	trow.add_child(_time_button("+1 h", 1.0))
	Game.coins_changed.connect(func(_c: int) -> void: refresh())
	Game.flag_changed.connect(func(_f: StringName, _v: Variant) -> void: refresh())
	get_viewport().size_changed.connect(_layout)
	refresh()
	_style_hint.call_deferred()


func _process(delta: float) -> void:
	if _hint == null:
		return
	_hint_time += delta
	var moving := Input.get_vector("move_left", "move_right", "move_up", "move_down").length() > 0.1
	_idle = 0.0 if moving or Input.is_anything_pressed() else _idle + delta
	var want := 1.0 if _hint_time < HINT_SHOW or _idle > HINT_IDLE else 0.0
	_hint.modulate.a = move_toward(_hint.modulate.a, want, delta * 1.5)


func refresh() -> void:
	_coins.text = str(Game.coins)
	_objective.text = objective_text()
	_left.visible = _objective.text != ""
	_layout.call_deferred()


func set_clock(text: String) -> void:
	_clock.text = text
	_time_label.text = text
	_layout.call_deferred()


## Who you are: the leader's card in the character box.
func set_member(m: BandMember, index: int) -> void:
	if _card and _card.member == m:
		return
	if _card:
		_card.queue_free()
	_card = MemberCard.new()
	_card.position = Vector2(6, 6)
	add_child(_card)
	_card.bind(m, index)
	_card.set_active(true)
	_card.tapped.connect(func() -> void: switch_requested.emit())
	_card.held.connect(func() -> void: inventory_requested.emit())


func toggle_time_panel() -> void:
	_time.visible = not _time.visible
	_layout()


func set_vehicle_hint(text: String) -> void:
	_vehicle.text = text
	_vehicle.visible = text != ""
	_layout.call_deferred()


## "" hides it.
func set_radio(text: String) -> void:
	_radio.text = ("Radio: " + text) if text != "" else ""
	_layout.call_deferred()


## The tour-day-1 quest, as one line.
static func objective_text() -> String:
	match Game.get_flag(&"quest_cafe", ""):
		"":
			return "Talk to Geordie at the storage (far east)"
		"active":
			if Game.get_flag(&"cafe_finished"):
				return "Back to Geordie at the storage"
			return "Get to Café De Kat (in the centre, east of the studio)"
		"done":
			return "Tour day 1 complete!"
	return ""


## Panels hug their text; the right-hand ones stay pinned to the right edge
## (also on wide screens).
func _layout() -> void:
	if not is_inside_tree():
		return
	var w := ScreenFit.width(_left)
	_left.size = Vector2.ZERO
	_right.size = Vector2.ZERO
	_right.position = Vector2(w - _right.get_combined_minimum_size().x - 6, 6)
	var y := _right.position.y + _right.get_combined_minimum_size().y + 3
	_time.size = Vector2.ZERO
	_time.position = Vector2(w - _time.get_combined_minimum_size().x - 6, y)
	if _time.visible:
		y += _time.get_combined_minimum_size().y + 3
	_radio.size = Vector2(240, 12)
	_radio.position = Vector2(w - 240 - 8, y)


## The scene's controls line: same font and shadow as the rest, a calm colour,
## then it fades out after the first seconds.
func _style_hint() -> void:
	_hint = get_parent().get_node_or_null("DevHint/Hint") as Label
	if _hint == null:
		return
	_hint.remove_theme_constant_override("outline_size")
	_hint.remove_theme_font_size_override("font_size")
	_hint.add_theme_color_override("font_color", Color(INK, 0.85))
	_hint.position.y = 360 - 14


func _time_button(text: String, hours: float) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE        # never steals the keyboard (space = jump)
	for state in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(PANEL, 0.6 if state == "normal" else (0.8 if state == "hover" else 0.95))
		sb.border_color = EDGE
		sb.set_border_width_all(1)
		sb.content_margin_left = 4
		sb.content_margin_right = 4
		sb.content_margin_top = 2
		sb.content_margin_bottom = 2
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", INK)
	b.pressed.connect(func() -> void: time_shift_requested.emit(hours))
	return b


func _panel() -> PanelContainer:
	var p := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.border_color = EDGE
	sb.set_border_width_all(1)
	sb.content_margin_left = 5
	sb.content_margin_right = 5
	sb.content_margin_top = 2
	sb.content_margin_bottom = 3
	p.add_theme_stylebox_override("panel", sb)
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(p)
	return p


func _label(color: Color) -> Label:
	var l := Label.new()
	l.add_theme_color_override("font_color", color)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l


## A little gold coin, 7 x 7 px.
static func _coin_texture() -> ImageTexture:
	var rows := [".###.", "#####", "##.##", "##.##", "#####", ".###."]
	var img := Image.create(5, 7, false, Image.FORMAT_RGBA8)
	for r in rows.size():
		for c in 5:
			if rows[r][c] == "#":
				img.set_pixel(c, r + 1, GOLD if r < 4 or c > 0 else GOLD.darkened(0.25))
	return ImageTexture.create_from_image(img)
