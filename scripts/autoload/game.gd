extends Node
## Global game state: active band member, quest flags and coins.
## Registered as the `Game` autoload.

signal member_switched(index: int)
signal flag_changed(flag: StringName, value: Variant)
signal coins_changed(amount: int)

const MEMBERS: Array[StringName] = [&"joep", &"jay", &"nikki", &"germ", &"geoff"]

var active_member: int = 0
var coins: int = 0
var _flags: Dictionary = {}


func switch_member(index: int) -> void:
	index = wrapi(index, 0, MEMBERS.size())
	if index == active_member:
		return
	active_member = index
	member_switched.emit(index)


func set_flag(flag: StringName, value: Variant = true) -> void:
	if _flags.get(flag) == value:
		return
	_flags[flag] = value
	flag_changed.emit(flag, value)


func get_flag(flag: StringName, default: Variant = false) -> Variant:
	return _flags.get(flag, default)


func add_coins(amount: int) -> void:
	coins = max(coins + amount, 0)
	coins_changed.emit(coins)
