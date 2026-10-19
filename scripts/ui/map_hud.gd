class_name MapHud
extends CanvasLayer
## World map HUD: the current objective (top left), coins (top right) and a
## hint about the vehicle the band is in, and the van radio's station.

var _objective: Label
var _coins: Label
var _vehicle: Label
var _radio: Label


func _ready() -> void:
	layer = 40
	_objective = _label(Vector2(8, 6), Vector2(420, 14), HORIZONTAL_ALIGNMENT_LEFT)
	_coins = _label(Vector2(472, 6), Vector2(160, 14), HORIZONTAL_ALIGNMENT_RIGHT)
	_vehicle = _label(Vector2(8, 22), Vector2(420, 14), HORIZONTAL_ALIGNMENT_LEFT)
	_vehicle.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	_radio = _label(Vector2(212, 22), Vector2(420, 14), HORIZONTAL_ALIGNMENT_RIGHT)
	_radio.add_theme_color_override("font_color", Color("ffd36b"))
	Game.coins_changed.connect(func(_c: int) -> void: refresh())
	Game.flag_changed.connect(func(_f: StringName, _v: Variant) -> void: refresh())
	refresh()


func refresh() -> void:
	_coins.text = "Coins: %d" % Game.coins
	_objective.text = objective_text()


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
