class_name Band
extends Node2D
## The 5 band members. Owns switching (Tab/Q cycle, 1-5 direct) and gather (G):
## inactive members walk to the active one on flat ground and stop at walls,
## ledges or when they arrive. Inactive members stay where they are otherwise.

signal active_changed(member: BandMember, index: int)

const GATHER_SPACING := 14.0                # px between members when gathered
const GATHER_TIMEOUT := 6.0

@export var start_index := 0
@export var spawn_spacing := 18.0           ## members start in a row from the Band's position

var members: Array[BandMember] = []
var active: BandMember
var active_index := -1

var locked := false                        # no switching or gather (cutscenes, transitions)
var gather_filter := func(_m: BandMember) -> bool: return true   # Level: same room only

var _gathering := {}                        # BandMember -> {"time": seconds left, "slot": px from leader}

@onready var camera: BandCamera = $Camera


func _ready() -> void:
	for child in $Members.get_children():
		if child is BandMember:
			child.position = Vector2(members.size() * spawn_spacing, 0)
			members.append(child)
	switch_to(start_index, true)


func _physics_process(delta: float) -> void:
	if locked:
		return
	if Input.is_action_just_pressed("switch_next"):
		switch_to(active_index + 1)
	elif Input.is_action_just_pressed("switch_prev"):
		switch_to(active_index - 1)
	for i in members.size():
		if Input.is_action_just_pressed("select_%d" % (i + 1)):
			switch_to(i)
	if Input.is_action_just_pressed("gather"):
		gather()
	_update_gather(delta)


func switch_to(index: int, instant := false) -> void:
	index = wrapi(index, 0, members.size())
	if index == active_index:
		return
	if active:
		active.set_active(false)
	active_index = index
	active = members[index]
	_gathering.erase(active)
	active.set_active(true)
	camera.follow(active, instant)
	Game.switch_member(index)
	active_changed.emit(active, index)


## Put everyone in a row centred on `pos` (level start), standing still.
func place_at(pos: Vector2, hp: Array = [], grace := 0.0) -> void:
	place_group(members, pos, hp, grace)
	camera.snap()


## Put `group` in a row centred on `pos` (doors, respawn). `hp[i]` per member,
## or keep their current HP.
func place_group(group: Array, pos: Vector2, hp: Array = [], grace := 0.0) -> void:
	var start := pos.x - spawn_spacing * (group.size() - 1) / 2.0
	for i in group.size():
		var m: BandMember = group[i]
		_gathering.erase(m)
		var keep_hp: int = hp[i] if i < hp.size() else m.health.hp
		m.respawn(Vector2(start + i * spawn_spacing, pos.y), keep_hp, grace)


## Call the others to the active member. Slots are fixed at the call, closest
## member nearest the leader, so they line up instead of stacking.
func gather() -> void:
	var others := members.filter(func(m: BandMember) -> bool: return m != active and gather_filter.call(m))
	others.sort_custom(func(a: BandMember, b: BandMember) -> bool:
		return absf(a.position.x - active.position.x) < absf(b.position.x - active.position.x))
	for rank in others.size():
		_gathering[others[rank]] = {"time": GATHER_TIMEOUT, "slot": GATHER_SPACING * (rank + 1)}


func is_gathering(member: BandMember) -> bool:
	return _gathering.has(member)


func _update_gather(delta: float) -> void:
	for m: BandMember in _gathering.keys():
		var state: Dictionary = _gathering[m]
		state.time -= delta
		var slot: float = state.slot
		var dx := active.position.x - m.position.x
		var dir := signf(dx)
		var arrived := absf(dx) <= slot
		var blocked := m.is_on_floor() and (_wall_ahead(m, dir) or _ledge_ahead(m, dir))
		if arrived or blocked or float(state.time) <= 0.0:
			m.ai_dir = 0.0
			_gathering.erase(m)
		else:
			m.ai_dir = dir


func _wall_ahead(m: BandMember, dir: float) -> bool:
	return m.test_move(m.global_transform, Vector2(dir * 2.0, 0))


## No floor under the body one body-width (+ braking distance) ahead: stop on
## solid ground instead of walking into a pit.
func _ledge_ahead(m: BandMember, dir: float) -> bool:
	return not m.test_move(m.global_transform.translated(Vector2(dir * 20.0, 0)), Vector2(0, 12))
