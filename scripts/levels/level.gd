class_name Level
extends Node2D
## A level: Rooms, the Band, HUD. The band can be split over rooms: a door takes
## everyone in the room along when they all stand together (within
## `group_radius_tiles` of the member using it), otherwise just that member. The camera shows the
## active member's room. Each room has its own checkpoint (its entry door or a
## flag). Death resets only the dying member's room: the members in it respawn
## at that room's checkpoint (about 1.2 s); members elsewhere stay where they are.

signal room_changed(room: Room)
signal member_died(member: BandMember, cause: StringName)
signal respawned

const TILE := 24.0
const DEATH_ANIM_TIME := 0.5
const PIT_MARGIN := 16.0                    # px below the room before a fall kills
const RESPAWN_GRACE := 1.0                  # i-frames after a respawn

@export var start_room: NodePath
@export var start_spawn: NodePath           ## Marker2D or Door where the band starts
@export var group_radius_tiles := 3.0       ## "together" for doors: this far horizontally
@export var group_height_tiles := 1.0       ## ... and at most this far vertically
@export var party_only := true              ## only the party chosen at the base comes in (off: the base itself)

var current_room: Room                      # the active member's room
var is_busy := false                        # dying or going through a door

var _member_room := {}                      # BandMember -> Room
var _checkpoints := {}                      # Room -> {position, hp: {BandMember: int}, node}
var _highlighted: Interactable

@onready var band: Band = $Band
@onready var hud: CanvasLayer = $HUD
@onready var debug_overlay: CanvasLayer = get_node_or_null("DebugOverlay")


## The Level a node belongs to.
static func of(node: Node) -> Level:
	return node.get_tree().get_first_node_in_group(&"level") as Level


func _ready() -> void:
	add_to_group(&"level")
	if party_only:
		band.keep_only(Game.party)
	Audio.music(&"level_tense" if party_only else &"map_calm")   # the base is calm
	for m in band.members:
		m.health.died.connect(kill.bind(m, &"hurt"))
		GameFeel.hook_member(m, self)
	band.active_changed.connect(func(_m: BandMember, _i: int) -> void: Audio.sfx(&"switch"))
	band.gather_filter = func(m: BandMember) -> bool: return room_of_member(m) == room_of_member(band.active)
	band.same_room = func(a: BandMember, b: BandMember) -> bool: return room_of_member(a) == room_of_member(b)
	band.active_changed.connect(_on_active_changed)
	hud.bind_band(band)
	if debug_overlay:
		debug_overlay.player = band.active
		band.active_changed.connect(func(member: BandMember, _i: int) -> void: debug_overlay.player = member)

	var spawn := _spawn_from_router()
	if spawn == null:
		spawn = get_node(start_spawn)
	var room: Room = _room_of(spawn) if _room_of(spawn) else get_node(start_room) as Room
	for m in band.members:
		_member_room[m] = room
	_enter_room(room)
	band.place_at(spawn.global_position)
	_set_checkpoint(room, spawn.global_position, null)


func _physics_process(_delta: float) -> void:
	if is_busy:
		return
	for m in band.members:
		if m.global_position.y > room_of_member(m).bounds.end.y + PIT_MARGIN:
			kill(m, &"pit")
			return
		if m.health.hp <= 0 and not m.is_dead:   # hit while a transition was running
			kill(m, &"hurt")
			return
	_update_interactables()


func room_of_member(member: BandMember) -> Room:
	return _member_room.get(member)


## Put `member` in `room` at `pos` (a story moment, e.g. Geoff wandered off).
func move_member(member: BandMember, room: Room, pos: Vector2) -> void:
	_member_room[member] = room
	member.respawn(pos, member.health.hp)


func members_in(room: Room) -> Array[BandMember]:
	var out: Array[BandMember] = []
	for m in band.members:
		if _member_room[m] == room:
			out.append(m)
	return out


# --- Death and respawn -----------------------------------------------------

func kill(member: BandMember, cause: StringName = &"hazard") -> void:
	if is_busy:
		return
	is_busy = true
	member_died.emit(member, cause)
	Audio.sfx(&"death", 0.0)
	get_tree().paused = true
	member.play_death()
	await get_tree().create_timer(DEATH_ANIM_TIME, true).timeout
	await SceneRouter.fade_out()
	_respawn(room_of_member(member))
	get_tree().paused = false
	await SceneRouter.fade_in()
	is_busy = false
	respawned.emit()


## Pause menu: put the active member's room back to how it was and everyone
## in it at the room's checkpoint.
func restart_room() -> void:
	if is_busy:
		return
	is_busy = true
	get_tree().paused = true
	await SceneRouter.fade_out()
	_respawn(room_of_member(band.active))
	get_tree().paused = false
	await SceneRouter.fade_in()
	is_busy = false


func _respawn(room: Room) -> void:
	var cp: Dictionary = _checkpoints[room]
	room.reset_state()
	var group := members_in(room)
	var hp: Array = group.map(func(m: BandMember) -> int: return cp.hp.get(m, m.health.hp))
	band.place_group(group, cp.position, hp, RESPAWN_GRACE)
	_enter_room(room_of_member(band.active))
	band.camera.snap()


func activate_checkpoint(checkpoint: Checkpoint) -> void:
	_set_checkpoint(_room_of(checkpoint), checkpoint.global_position, checkpoint)


func _set_checkpoint(room: Room, pos: Vector2, node: Checkpoint) -> void:
	var old: Dictionary = _checkpoints.get(room, {})
	if old.get("node"):
		old.node.is_current = false
	var hp := {}
	for m in members_in(room):
		hp[m] = m.health.hp
	_checkpoints[room] = {"position": pos, "hp": hp, "node": node}
	if node:
		node.is_current = true


# --- Doors and rooms -------------------------------------------------------

## Who goes through a door used by `member`: everyone in their room if they all
## stand together around `member`, otherwise only `member` (plus a lured member
## following them who is close enough, e.g. Geoff after the rolling papers).
func door_group(member: BandMember) -> Array[BandMember]:
	var room_mates := members_in(room_of_member(member))
	var together := room_mates.all(func(m: BandMember) -> bool: return _close_to(m, member))
	if together:
		return room_mates
	var group: Array[BandMember] = [member]
	for f: BandMember in band.following:
		if band.following[f] == member and _close_to(f, member):
			group.append(f)
	return group


func _close_to(m: BandMember, member: BandMember) -> bool:
	return absf(m.global_position.x - member.global_position.x) <= group_radius_tiles * TILE \
		and absf(m.global_position.y - member.global_position.y) <= group_height_tiles * TILE


func go_through(door: Door, member: BandMember) -> void:
	if is_busy:
		return
	if door.target_scene != "":
		is_busy = true
		SceneRouter.go_to(door.target_scene, door.target_spawn)
		return
	var target := door.get_node_or_null(door.target_door) as Door
	if target == null:
		push_warning("Door %s has no target" % door.get_path())
		return
	var group := door_group(member)
	var room := _room_of(target)
	Audio.sfx(&"door")
	is_busy = true
	get_tree().paused = true
	await SceneRouter.fade_out()
	for m in group:
		_member_room[m] = room
	band.place_group(group, target.global_position, [], 0.0)
	_set_checkpoint(room, target.global_position, null)   # entering a room = checkpoint
	_enter_room(room_of_member(band.active))
	band.camera.snap()
	get_tree().paused = false
	await SceneRouter.fade_in()
	is_busy = false


func _group_text(group: Array[BandMember], member: BandMember) -> String:
	if group.size() == band.members.size():
		return "whole band"
	if group.size() == 1:
		return "%s alone" % member.profile.display_name
	if group.size() == 2 and group[0] == member:
		return "%s + %s" % [member.profile.display_name, group[1].profile.display_name]
	return "group of %d" % group.size()


func _enter_room(room: Room) -> void:
	if room == current_room:
		return
	current_room = room
	band.camera.set_bounds(room.bounds)
	room_changed.emit(room)


func _on_active_changed(member: BandMember, _index: int) -> void:
	var room := room_of_member(member)
	if room and room != current_room:
		_enter_room(room)
		band.camera.snap()                  # cut to the other room


func _room_of(node: Node) -> Room:
	var n := node
	while n and not n is Room:
		n = n.get_parent()
	return n as Room


## Spawn requested by the scene we came from (SceneRouter.pending_spawn).
func _spawn_from_router() -> Node2D:
	if SceneRouter.pending_spawn == &"":
		for arg in OS.get_cmdline_user_args():     # dev: start at a node, -- --spawn=Bouncer
			if arg.begins_with("--spawn="):
				return find_child(arg.trim_prefix("--spawn="), true, false) as Node2D
		return null
	var node := find_child(String(SceneRouter.pending_spawn), true, false) as Node2D
	SceneRouter.pending_spawn = &""
	return node


# --- Interact --------------------------------------------------------------

func _update_interactables() -> void:
	var active := band.active
	var best: Interactable = null
	var best_d := INF
	for node in get_tree().get_nodes_in_group(&"interactable"):
		var it := node as Interactable
		if it.overlaps_body(active) and it.can_interact(active):
			var d := it.global_position.distance_squared_to(active.global_position)
			if d < best_d:
				best = it
				best_d = d
	if best != _highlighted:
		if _highlighted:
			_highlighted.set_highlighted(false)
		_highlighted = best
		if best:
			best.set_highlighted(true)
	if best is Door and best.locked and active.inventory.has(best.key_id):
		best.set_prompt_text("E  use keycard")
	elif best is Door and not best.locked and best.target_scene == "":
		best.set_prompt_text("E  " + _group_text(door_group(active), active))
	if Input.is_action_just_pressed("interact"):
		if best:
			best.interact(active, self)
		else:                               # nothing to interact with: use the selected item
			active.use_current_item()
