extends Node
## Global game state: active band member, quest flags and coins.
## Registered as the `Game` autoload.

signal member_switched(index: int)
signal flag_changed(flag: StringName, value: Variant)
signal coins_changed(amount: int)

const MEMBERS: Array[StringName] = [&"joep", &"jay", &"nikki", &"germ", &"geoff"]

var active_member: int = 0
var coins: int = 0
var party: Array[StringName] = MEMBERS.duplicate()   # who goes out on the world map (chosen at the base)
var base_level := 1                         # the base (storage) upgrades: 1 = one room with a couch
var time_of_day := -1.0                     # clock hour 0..24 on the world map (-1: not started, uses DayConfig.start_hour)
var _flags: Dictionary = {}


func _ready() -> void:
	preload("res://scripts/ui/ui_font.gd").install()   # the pixel UI font for every Control
	# Browser and phone: scale by any amount so the game fills the whole screen
	# (the width follows the screen, no stretching). Desktop keeps whole-pixel scaling.
	if OS.has_feature("web") or OS.has_feature("mobile"):
		get_tree().root.content_scale_stretch = Window.CONTENT_SCALE_STRETCH_FRACTIONAL


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


func in_party(id: StringName) -> bool:
	return party.has(id)


func add_coins(amount: int) -> void:
	coins = max(coins + amount, 0)
	coins_changed.emit(coins)
