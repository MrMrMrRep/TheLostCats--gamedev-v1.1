class_name HealthComponent
extends Node
## Hit points for one band member, with invulnerability frames after a hit.

signal health_changed(hp: int, max_hp: int)
signal damaged(amount: int)
signal died

@export var max_hp := 3
@export var invulnerable_time := 1.0        ## seconds of i-frames after taking damage

var hp := 3
var invulnerable_left := 0.0

var is_invulnerable: bool:
	get:
		return invulnerable_left > 0.0


func _ready() -> void:
	hp = max_hp


func _physics_process(delta: float) -> void:
	invulnerable_left = maxf(invulnerable_left - delta, 0.0)


func set_max_hp(value: int) -> void:
	max_hp = maxi(value, 1)
	restore(max_hp)


## Returns true if the damage landed (not blocked by i-frames).
func damage(amount: int = 1) -> bool:
	if hp <= 0 or amount <= 0 or is_invulnerable:
		return false
	hp = maxi(hp - amount, 0)
	invulnerable_left = invulnerable_time
	health_changed.emit(hp, max_hp)
	damaged.emit(amount)
	if hp == 0:
		died.emit()
	return true


func heal(amount: int = 1) -> void:
	if hp <= 0 or amount <= 0:
		return
	hp = mini(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)


## Back to a given HP (respawn) with `grace` seconds of i-frames.
func restore(value: int, grace := 0.0) -> void:
	hp = clampi(value, 1, max_hp)
	invulnerable_left = grace
	health_changed.emit(hp, max_hp)
