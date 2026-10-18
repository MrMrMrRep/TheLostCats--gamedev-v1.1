class_name HealthComponent
extends Node
## Hit points for one band member. Damage, i-frames and death handling come in M5.

signal health_changed(hp: int, max_hp: int)
signal died

@export var max_hp := 3

var hp := 3


func _ready() -> void:
	hp = max_hp


func set_max_hp(value: int) -> void:
	max_hp = maxi(value, 1)
	hp = max_hp
	health_changed.emit(hp, max_hp)


func damage(amount: int = 1) -> void:
	if hp <= 0 or amount <= 0:
		return
	hp = maxi(hp - amount, 0)
	health_changed.emit(hp, max_hp)
	if hp == 0:
		died.emit()


func heal(amount: int = 1) -> void:
	if hp <= 0 or amount <= 0:
		return
	hp = mini(hp + amount, max_hp)
	health_changed.emit(hp, max_hp)
