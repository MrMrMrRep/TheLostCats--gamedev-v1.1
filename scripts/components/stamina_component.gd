class_name StaminaComponent
extends Node
## Reusable stamina pool. Spend with spend()/try_spend(); regenerates after
## regen_delay, faster while `grounded` (set by the owner each physics frame).
## Without settings the component is disabled and try_spend() always fails.

signal stamina_changed(current: float, maximum: float)
signal exhausted
signal recovered

@export var settings: StaminaSettings: set = set_settings

var max_stamina := 100.0
var current_stamina := 100.0
var regen_rate := 30.0
var regen_delay := 0.5
var ground_regen_mult := 2.0
var exhausted_threshold := 20.0
var is_exhausted := false
var grounded := false

var enabled: bool:
	get:
		return settings != null

var _since_spend := INF


func set_settings(value: StaminaSettings) -> void:
	settings = value
	if settings != null:
		max_stamina = settings.max_stamina
		regen_rate = settings.regen_rate
		regen_delay = settings.regen_delay
		ground_regen_mult = settings.ground_regen_mult
		exhausted_threshold = settings.exhausted_threshold
	refill()


## Spend unconditionally (clamped at 0). For continuous costs pass rate * delta.
func spend(amount: float) -> void:
	if not enabled or amount <= 0.0:
		return
	current_stamina = maxf(current_stamina - amount, 0.0)
	_since_spend = 0.0
	stamina_changed.emit(current_stamina, max_stamina)
	if current_stamina <= 0.0 and not is_exhausted:
		is_exhausted = true
		exhausted.emit()


## Spend only if enough stamina is left and not exhausted.
func try_spend(amount: float) -> bool:
	if not enabled or is_exhausted or current_stamina < amount:
		return false
	spend(amount)
	return true


func refill() -> void:
	current_stamina = max_stamina
	is_exhausted = false
	_since_spend = INF
	stamina_changed.emit(current_stamina, max_stamina)


func _physics_process(delta: float) -> void:
	if not enabled:
		return
	_since_spend += delta
	if _since_spend < regen_delay or current_stamina >= max_stamina:
		return
	var rate := regen_rate * (ground_regen_mult if grounded else 1.0)
	current_stamina = minf(current_stamina + rate * delta, max_stamina)
	stamina_changed.emit(current_stamina, max_stamina)
	if is_exhausted and current_stamina >= exhausted_threshold:
		is_exhausted = false
		recovered.emit()
