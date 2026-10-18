class_name Level
extends Node2D
## A level: Rooms, the Band, HUD. Handles the room the band is in (camera
## bounds), checkpoints, doors (room to room with a fade, or out of the level),
## interact prompts, and death: pause, death animation, fade, reset the room,
## respawn the band at the checkpoint, fade in (about 1.2 s in total).

signal room_changed(room: Room)
signal member_died(member: BandMember, cause: StringName)
signal respawned

const DEATH_ANIM_TIME := 0.5
const PIT_MARGIN := 16.0                    # px below the room before a fall kills
const RESPAWN_GRACE := 1.0                  # i-frames after a respawn

@export var start_room: NodePath
@export var start_spawn: NodePath           ## Marker2D or Door where the band starts

var current_room: Room
var is_busy := false                        # dying or going through a door

var _checkpoint := {}                       # {room, position, hp, node}
var _highlighted: Interactable

@onready var band: Band = $Band
@onready var hud: CanvasLayer = $HUD
@onready var debug_overlay: CanvasLayer = get_node_or_null("DebugOverlay")


## The Level a node belongs to.
static func of(node: Node) -> Level:
	return node.get_tree().get_first_node_in_group(&"level") as Level


func _ready() -> void:
	add_to_group(&"level")
	for m in band.members:
		m.health.died.connect(kill.bind(m, &"hurt"))
	hud.bind_band(band)
	if debug_overlay:
		debug_overlay.player = band.active
		band.active_changed.connect(func(member: BandMember, _i: int) -> void: debug_overlay.player = member)

	var spawn := _spawn_from_router()
	if spawn == null:
		spawn = get_node(start_spawn)
	_enter_room(_room_of(spawn) if _room_of(spawn) else get_node(start_room) as Room)
	band.place_at(spawn.global_position)
	_set_checkpoint(spawn.global_position, null)


func _physics_process(_delta: float) -> void:
	if is_busy:
		return
	for m in band.members:
		if m.global_position.y > current_room.bounds.end.y + PIT_MARGIN:
			kill(m, &"pit")
			return
		if m.health.hp <= 0 and not m.is_dead:   # hit while a transition was running
			kill(m, &"hurt")
			return
	_update_interactables()


# --- Death and respawn -----------------------------------------------------

func kill(member: BandMember, cause: StringName = &"hazard") -> void:
	if is_busy:
		return
	is_busy = true
	member_died.emit(member, cause)
	get_tree().paused = true
	member.play_death()
	await get_tree().create_timer(DEATH_ANIM_TIME, true).timeout
	await SceneRouter.fade_out()
	_respawn()
	get_tree().paused = false
	await SceneRouter.fade_in()
	is_busy = false
	respawned.emit()


func _respawn() -> void:
	_enter_room(_checkpoint.room)
	current_room.reset_state()
	band.place_at(_checkpoint.position, _checkpoint.hp, RESPAWN_GRACE)


func activate_checkpoint(checkpoint: Checkpoint) -> void:
	_set_checkpoint(checkpoint.global_position, checkpoint)


func _set_checkpoint(pos: Vector2, node: Checkpoint) -> void:
	if _checkpoint.get("node"):
		_checkpoint.node.is_current = false
	_checkpoint = {
		"room": current_room,
		"position": pos,
		"hp": band.members.map(func(m: BandMember) -> int: return m.health.hp),
		"node": node,
	}
	if node:
		node.is_current = true


# --- Doors and rooms -------------------------------------------------------

func go_through(door: Door) -> void:
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
	is_busy = true
	get_tree().paused = true
	await SceneRouter.fade_out()
	_enter_room(_room_of(target))
	band.place_at(target.global_position)
	_set_checkpoint(target.global_position, null)   # every room starts with a checkpoint
	get_tree().paused = false
	await SceneRouter.fade_in()
	is_busy = false


func _enter_room(room: Room) -> void:
	current_room = room
	band.camera.set_bounds(room.bounds)
	room_changed.emit(room)


func _room_of(node: Node) -> Room:
	var n := node
	while n and not n is Room:
		n = n.get_parent()
	return n as Room


## Spawn requested by the scene we came from (SceneRouter.pending_spawn).
func _spawn_from_router() -> Node2D:
	if SceneRouter.pending_spawn == &"":
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
	if best and Input.is_action_just_pressed("interact"):
		best.interact(active, self)
