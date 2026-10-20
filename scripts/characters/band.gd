class_name Band
extends Node2D
## The 5 band members. Owns switching (Tab/Q cycle, 1-5 direct), gather (hold
## G: the others in the room walk to the active member and stop when G is
## released) and lures: a member follows whoever carries an item that lures them
## (Geoff and the rolling papers). AI-walking members hop walls, gaps and small
## hazards they can clear with their own jump, walk down small drops, and wait
## in front of anything too big or dangerous. Otherwise inactive members stay put.

signal active_changed(member: BandMember, index: int)

const TILE := 24.0
const GATHER_SPACING := 14.0                # px between members when gathered
const FOLLOW_DISTANCE := 20.0               # lured member stops this close
const WALL_LOOKAHEAD := 8.0                 # px: start the hop a little before the wall
const SAFE_DROP := 100.0                    # px: walk down drops up to ~4 tiles
const REACH_MARGIN := 0.85                  # use 85% of the jump reach, to be safe

@export var start_index := 0
@export var spawn_spacing := 18.0           ## members start in a row from the Band's position

var members: Array[BandMember] = []
var active: BandMember
var active_index := -1

var locked := false                        # no switching or gather (cutscenes, transitions)
var gather_filter := func(_m: BandMember) -> bool: return true   # Level: same room only
var same_room := func(_a: BandMember, _b: BandMember) -> bool: return true  # Level sets it
var following := {}                         # lured BandMember -> carrier BandMember

var _gathering := {}                        # BandMember -> slot distance (px) from the leader
var _gather_held := false

@onready var camera: BandCamera = $Camera


func _ready() -> void:
	for child in $Members.get_children():
		if child is BandMember:
			child.position = Vector2(members.size() * spawn_spacing, 0)
			members.append(child)
	switch_to(start_index, true)


func _physics_process(_delta: float) -> void:
	if locked:
		return
	if Input.is_action_just_pressed("switch_next"):
		switch_to(active_index + 1)
	elif Input.is_action_just_pressed("switch_prev"):
		switch_to(active_index - 1)
	for i in members.size():
		if Input.is_action_just_pressed("select_%d" % (i + 1)):
			switch_to(i)
	var held := Input.is_action_pressed("gather")
	if held and not _gather_held:
		start_gather()
	elif not held and _gather_held:
		stop_gather()
	_gather_held = held
	for m: BandMember in _gathering.keys():
		walk_towards(m, active.global_position.x, _gathering[m])
	_update_lures()


func switch_to(index: int, instant := false) -> void:
	index = wrapi(index, 0, members.size())
	if index == active_index:
		return
	if active:
		active.set_active(false)
	active_index = index
	active = members[index]
	active.set_active(true)
	camera.follow(active, instant)
	Game.switch_member(index)
	if _gather_held:
		start_gather()                      # keep gathering, now around the new leader
	active_changed.emit(active, index)


## Only `ids` come along (the party chosen at the base): the others leave the band.
func keep_only(ids: Array) -> void:
	var gone := members.filter(func(m: BandMember) -> bool: return m.profile and not ids.has(m.profile.id))
	if gone.size() == members.size():
		return                              # never an empty band
	var keep_active := active if not gone.has(active) else null
	for m in gone:
		members.erase(m)
		m.queue_free()
	active_index = -1
	active = null
	switch_to(members.find(keep_active) if keep_active else 0, true)


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


## Start calling the others (same room) to the active member. Slots are fixed
## now, closest member nearest the leader, so they line up instead of stacking.
func start_gather() -> void:
	stop_gather()
	var others := members.filter(func(m: BandMember) -> bool:
		return m != active and not m.is_dead and gather_filter.call(m))
	others.sort_custom(func(a: BandMember, b: BandMember) -> bool:
		return absf(a.position.x - active.position.x) < absf(b.position.x - active.position.x))
	for rank in others.size():
		_gathering[others[rank]] = GATHER_SPACING * (rank + 1)


## Everyone stops walking (G released).
func stop_gather() -> void:
	for m: BandMember in _gathering.keys():
		m.ai_dir = 0.0
	_gathering.clear()


func is_gathering(member: BandMember) -> bool:
	return _gathering.has(member)


## Steer `m` toward `target_x` like a careful player: hop walls, gaps and small
## hazards within its own jump, walk down small drops, otherwise wait.
## Returns true once within `stop_distance`.
func walk_towards(m: BandMember, target_x: float, stop_distance: float) -> bool:
	var dx := target_x - m.global_position.x
	if absf(dx) <= stop_distance:
		m.ai_dir = 0.0
		return true
	var dir := signf(dx)
	m.ai_dir = dir
	if not m.is_on_floor():
		return false                        # keep going mid-jump
	var reach := jump_reach(m)
	if _hazard_near(m, m.global_position + Vector2(dir * 14.0, -4.0)):
		if _safe_landing(m, dir, reach):
			m.ai_jump()
		else:
			m.ai_dir = 0.0
	elif m.test_move(m.global_transform, Vector2(dir * WALL_LOOKAHEAD, 0)):
		if _can_hop_wall(m, dir):
			m.ai_jump()
		else:
			m.ai_dir = 0.0
	elif _ledge_ahead(m, dir):
		if m.test_move(m.global_transform.translated(Vector2(dir * 20.0, 0)), Vector2(0, SAFE_DROP)):
			pass                            # just a drop: walk off it
		elif _safe_landing(m, dir, reach):
			m.ai_jump()
		else:
			m.ai_dir = 0.0
	return false


## How far this member gets with a running jump, in px (with a safety margin).
func jump_reach(m: BandMember) -> float:
	var p := m.profile
	var airtime := p.time_to_apex * (1.0 + 1.0 / sqrt(p.fall_gravity_mult))
	return p.run_speed() * airtime * REACH_MARGIN


## Members lured by an item walk after its carrier (same room, not active,
## not being gathered).
func _update_lures() -> void:
	var now := {}
	for carrier in members:
		if carrier.is_dead:
			continue
		for item in carrier.inventory.items():
			if item.lures == &"":
				continue
			var f := member_by_id(item.lures)
			if f and f != carrier and not f.is_active and not f.is_dead and not _gathering.has(f) \
					and same_room.call(f, carrier):
				now[f] = carrier
	for f: BandMember in following.keys():
		if not now.has(f):
			f.ai_dir = 0.0
	following = now
	for f: BandMember in following.keys():
		walk_towards(f, following[f].global_position.x, FOLLOW_DISTANCE)


func member_by_id(id: StringName) -> BandMember:
	for m in members:
		if m.profile.id == id:
			return m
	return null


## The wall ahead is lower than this member's jump.
func _can_hop_wall(m: BandMember, dir: float) -> bool:
	var h := m.profile.jump_height_tiles * TILE - 4.0
	return not m.test_move(m.global_transform.translated(Vector2(0, -h)), Vector2(dir * WALL_LOOKAHEAD, 0))


## Floor (and no hazard) where a jump of `dist` px would land.
func _safe_landing(m: BandMember, dir: float, dist: float) -> bool:
	var landing := m.global_transform.translated(Vector2(dir * dist, -2.0))
	if m.test_move(landing, Vector2.ZERO):
		return false                        # inside a wall there
	if not m.test_move(landing, Vector2(0, 30)):
		return false                        # no floor there
	return not _hazard_near(m, m.global_position + Vector2(dir * dist, -4.0))


## An enabled Hazard overlapping a small box at `point`.
func _hazard_near(m: BandMember, point: Vector2) -> bool:
	var shape := RectangleShape2D.new()
	shape.size = Vector2(10, 10)
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, point)
	q.collision_mask = 1 << 4               # hazard layer
	q.collide_with_areas = true
	q.collide_with_bodies = false
	for hit in m.get_world_2d().direct_space_state.intersect_shape(q, 4):
		if hit.collider is Hazard and hit.collider.enabled:
			return true
	return false


## No floor under the body one body-width (+ braking distance) ahead.
func _ledge_ahead(m: BandMember, dir: float) -> bool:
	return not m.test_move(m.global_transform.translated(Vector2(dir * 20.0, 0)), Vector2(0, 12))
