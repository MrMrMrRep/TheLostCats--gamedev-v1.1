class_name MapHud
extends CanvasLayer
## World map HUD: the current objective (top left), coins and the clock (top
## right), a hint about the vehicle the band is in, and the van radio's station.
## For testing, +1 / +4 / +8 buttons under the clock skip time (DayConfig.time_buttons).

signal skip_requested(hours: float)         # a +1 / +4 / +8 button was clicked

var _objective: Label
var _coins: Label
var _vehicle: Label
var _radio: Label
var _clock: Label


func _ready() -> void:
	layer = 40
	_objective = _label(Vector2(8, 6), Vector2(420, 14), HORIZONTAL_ALIGNMENT_LEFT)
	_coins = _label(Vector2(472, 6), Vector2(160, 14), HORIZONTAL_ALIGNMENT_RIGHT)
	_vehicle = _label(Vector2(8, 22), Vector2(420, 14), HORIZONTAL_ALIGNMENT_LEFT)
	_vehicle.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_clock = _label(Vector2(472, 22), Vector2(160, 14), HORIZONTAL_ALIGNMENT_RIGHT)
	_radio = _label(Vector2(212, 52), Vector2(420, 14), HORIZONTAL_ALIGNMENT_RIGHT)
	if DayConfig.current().time_buttons:   # testing: skip ahead in time
		var x := 560.0
		for h in [1, 4, 8]:
			_skip_button(Vector2(x, 37), h)
			x += 24.0
	_radio.add_theme_color_override("font_color", Color("ffd36b"))
	Game.coins_changed.connect(func(_c: int) -> void: refresh())
	Game.flag_changed.connect(func(_f: StringName, _v: Variant) -> void: refresh())
	refresh()


func refresh() -> void:
	_coins.text = "Coins: %d" % Game.coins
	_objective.text = objective_text()


func set_clock(text: String) -> void:
	_clock.text = text


func set_vehicle_hint(text: String) -> void:
	_vehicle.text = text


## "" hides it.
func set_radio(text: String) -> void:
	_radio.text = ("Radio: " + text) if text != "" else ""


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


func _skip_button(pos: Vector2, hours: int) -> void:
	var b := Button.new()
	b.text = "+%d" % hours
	b.tooltip_text = "Sleep %d hour%s" % [hours, "" if hours == 1 else "s"]
	b.position = pos
	b.size = Vector2(22, 13)
	b.focus_mode = Control.FOCUS_NONE        # never steals the keyboard (space = jump)
	b.add_theme_font_size_override("font_size", 8)
	for state in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0, 0, 0, 0.45 if state == "normal" else (0.65 if state == "hover" else 0.85))
		sb.set_corner_radius_all(3)
		sb.content_margin_left = 2
		sb.content_margin_right = 2
		sb.content_margin_top = 0
		sb.content_margin_bottom = 0
		b.add_theme_stylebox_override(state, sb)
	b.pressed.connect(func() -> void: skip_requested.emit(float(hours)))
	add_child(b)
	b.size = Vector2.ZERO                    # shrink to fit the small font (else it keeps the default height)


func _label(pos: Vector2, size_px: Vector2, align: HorizontalAlignment) -> Label:
	var l := Label.new()
	l.position = pos
	l.size = size_px
	l.horizontal_alignment = align
	l.add_theme_font_size_override("font_size", 10)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 3)
	add_child(l)
	return l
