class_name SleepingMember
extends Node2D
## "Where is Geoff?": when the band comes into this room, `member_id` (Geoff)
## has wandered off and lies asleep here (in the drum case on the stage rig).
## Asleep he can't be switched to and nothing lures him. He wakes up when
## someone carrying `wake_item` (the rolling papers) reaches him, and from then
## on follows whoever carries them. Origin = where he sleeps.

signal woke_up

@export var member_id: StringName = &"geoff"
@export var wake_item: StringName = &"rolling_papers"
@export var wake_radius := 40.0

var _level: Level
var _member: BandMember
var _room: Room
var _asleep := false
var _done := false
var _zzz := 0.0


func _ready() -> void:
	_hook.call_deferred()                   # the Level registers itself after its children


func _hook() -> void:
	_level = Level.of(self)
	var n: Node = get_parent()
	while n and not n is Room:
		n = n.get_parent()
	_room = n as Room
	if _level:
		_level.room_changed.connect(_on_room_changed)
		if _level.current_room == _room:   # the level started in here
			_on_room_changed(_room)


func is_asleep() -> bool:
	return _asleep


func _on_room_changed(room: Room) -> void:
	if room != _room or _done:
		return
	_fall_asleep.call_deferred()            # after the level has placed the band


func _fall_asleep() -> void:
	_member = _level.band.member_by_id(member_id)
	if _member == null:
		return                              # he didn't come along
	_done = true
	_asleep = true
	_level.move_member(_member, _room, global_position)
	_level.band.asleep[_member] = true
	if _level.band.active == _member:      # you were him: now someone else
		_level.band.switch_to(_level.band.members.find(_level.band.members.filter(func(m): return m != _member)[0]))


func _process(delta: float) -> void:
	if not _asleep:
		return
	_zzz -= delta
	if _zzz <= 0.0:
		_zzz = 2.2
		_member.show_text("Zzz...", Color(0.75, 0.8, 1.0))
	for m in _level.band.members:
		if m != _member and m.inventory.has(wake_item) and m.global_position.distance_to(_member.global_position) < wake_radius:
			_asleep = false
			_level.band.asleep.erase(_member)
			_member.show_text("Rolling papers?! ...right behind you.", Color("ffd36b"))
			woke_up.emit()
			return
