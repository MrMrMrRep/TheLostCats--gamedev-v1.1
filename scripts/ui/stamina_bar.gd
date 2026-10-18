class_name StaminaBar
extends Control
## Small stamina bar. Only visible while stamina is below max or just changed;
## turns red while exhausted. Bind it to a StaminaComponent with bind().

const LINGER := 0.8                         # seconds visible after reaching full
const FADE := 0.3

@export var bar_size := Vector2(40, 3)
@export var fill_color := Color("7ee08a")
@export var exhausted_color := Color("e05a4f")
@export var back_color := Color(0, 0, 0, 0.55)

var _stamina: StaminaComponent
var _ratio := 1.0
var _linger := 0.0


func _ready() -> void:
	custom_minimum_size = bar_size
	modulate.a = 0.0


func bind(stamina: StaminaComponent) -> void:
	if _stamina and _stamina.stamina_changed.is_connected(_on_changed):
		_stamina.stamina_changed.disconnect(_on_changed)
	_stamina = stamina
	_ratio = 1.0
	_linger = 0.0
	modulate.a = 0.0
	if _stamina:
		_stamina.stamina_changed.connect(_on_changed)
	queue_redraw()


func _on_changed(current: float, maximum: float) -> void:
	var ratio := current / maximum if maximum > 0.0 else 0.0
	if ratio < 1.0 or not is_equal_approx(ratio, _ratio):
		_linger = LINGER
	_ratio = ratio
	queue_redraw()


func _process(delta: float) -> void:
	if _stamina == null or not _stamina.enabled:
		modulate.a = 0.0
		return
	if _ratio < 1.0:
		modulate.a = 1.0
	else:
		_linger = maxf(_linger - delta, 0.0)
		modulate.a = clampf(_linger / FADE, 0.0, 1.0)


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, bar_size), back_color)
	var color := exhausted_color if _stamina and _stamina.is_exhausted else fill_color
	draw_rect(Rect2(Vector2.ZERO, Vector2(bar_size.x * _ratio, bar_size.y)), color)
