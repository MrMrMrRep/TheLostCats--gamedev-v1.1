@tool
class_name Interactable
extends Area2D
## Something the active member can use with the interact key (E): doors, NPCs.
## The Level (or WorldMap) shows the prompt on the nearest one and calls interact().
## say() shows a short speech line above it.

@export var prompt := "E"
@export var area_size := Vector2(24, 40):
	set(value):
		area_size = value
		_update_shape()

var _shape: CollisionShape2D
var _prompt_label: Label
var _say_label: Label
var _say_timer: SceneTreeTimer


func _ready() -> void:
	collision_layer = 1 << 5                # interactable
	collision_mask = 1 << 2                 # player
	monitorable = false
	_shape = CollisionShape2D.new()
	_shape.shape = RectangleShape2D.new()
	add_child(_shape)
	_update_shape()
	_prompt_label = _make_label(Color("ffd36b"))
	_prompt_label.text = prompt
	_say_label = _make_label(Color.WHITE)
	_say_label.position.y -= 12
	add_to_group(&"interactable")


func can_interact(_member: BandMember) -> bool:
	return true


func interact(_member: BandMember, _level: Node) -> void:
	pass


func set_highlighted(on: bool) -> void:
	_prompt_label.visible = on
	if not on:
		_prompt_label.text = prompt


func set_prompt_text(text: String) -> void:
	_prompt_label.text = text


## World text is drawn at half size for the 2x-zoomed rooms; the 1x world map
## uses full size so it stays readable.
func set_label_scale(s: float) -> void:
	for l in [_prompt_label, _say_label]:
		l.scale = Vector2(s, s)
		l.position.x = -l.size.x * s / 2.0


func say(text: String, seconds := 1.6) -> void:
	_say_label.text = text
	_say_label.visible = true
	_say_timer = get_tree().create_timer(seconds)
	var timer := _say_timer
	await timer.timeout
	if _say_timer == timer:
		_say_label.visible = false


func _update_shape() -> void:
	if _shape:
		(_shape.shape as RectangleShape2D).size = area_size
		_shape.position = Vector2(0, -area_size.y / 2.0)


func _make_label(color: Color) -> Label:
	var l := Label.new()
	l.size = Vector2(240, 12)
	l.scale = Vector2(0.5, 0.5)
	l.position = Vector2(-60, -area_size.y - 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override("outline_size", 3)
	l.visible = false
	l.z_index = 10
	add_child(l)
	return l
