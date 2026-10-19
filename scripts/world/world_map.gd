class_name WorldMap
extends Node2D
## The calm side of the game: Amsterdam left and right of the studio. The active
## member leads; the others trail behind on the leader's exact path (Kingdom
## Eighties style). No switching, no deaths. Bikes (whole band rides, off
## anywhere) and the band van (fast, only at P signs) move the band; doors lead
## into levels; Geordie gives the tour quest. Camera: zoomed out, slow follow,
## wide look-ahead (wider while driving).

const GROUND_Y := 288.0
const TRAIL_STEP := 2.0                     # px between recorded trail points
const FOLLOW_GAP := 16.0                    # px between members in the line
const TRAIL_MAX := 400
const WALK_LOOK_AHEAD := 80.0
const DRIVE_LOOK_AHEAD := 160.0
const INTERACT_COOLDOWN := 0.3
const EDGE_MARGIN := 30.0                   # vehicles stop this far from a road block

@export var map_width := 3840
@export var start_spawn: NodePath

var leader: BandMember
var followers: Array[BandMember] = []
var vehicle: Vehicle                        # the one the band is using, or null on foot
var talking := false

var _trail: Array[Vector2] = []
var _bikes := {}                            # BandMember -> BikeSprite
var _cooldown := 0.0
var _highlighted: Interactable
var _min_x := 0.0
var _max_x := 0.0

@onready var band: Band = $Band
@onready var hud: MapHud = $MapHud
@onready var dialogue: DialogueBox = $DialogueBox


static func of(node: Node) -> WorldMap:
	return node.get_tree().get_first_node_in_group(&"world_map") as WorldMap


func _ready() -> void:
	add_to_group(&"world_map")
	band.locked = true                      # no switching or gather on the map
	var cam := band.camera
	cam.zoom = Vector2.ONE
	cam.position_smoothing_speed = 4.0
	cam.deadzone = Vector2(24, 40)
	cam.look_ahead = WALK_LOOK_AHEAD
	cam.set_bounds(Rect2i(0, 0, map_width, 360))
	leader = band.active
	for node in get_tree().get_nodes_in_group(&"interactable"):
		node.set_label_scale(1.0)
	for m in band.members:
		m.show_name_tag = false
		m.name_tag.visible = false
		var bike := BikeSprite.new()
		bike.z_index = 1
		bike.visible = false
		m.add_child(bike)
		_bikes[m] = bike
		if m != leader:
			followers.append(m)
			m.set_physics_process(false)
	_min_x = EDGE_MARGIN
	_max_x = map_width - EDGE_MARGIN
	for b in find_children("*", "RoadBarrier", true, false):
		if b.global_position.x < map_width / 2.0:
			_min_x = maxf(_min_x, b.global_position.x + EDGE_MARGIN)
		else:
			_max_x = minf(_max_x, b.global_position.x - EDGE_MARGIN)
	for v in vehicles():
		v.restore_position()
	var spawn := _spawn_from_router()
	if spawn == null:
		spawn = get_node(start_spawn)
	place_band(spawn.global_position.x, 1.0)
	_update_vehicle_hint()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if talking:
		return
	if vehicle:
		_drive(delta)
	_record_trail()
	_update_followers()
	_update_interact()


func vehicles() -> Array[Vehicle]:
	var out: Array[Vehicle] = []
	for v in find_children("*", "Vehicle", true, false):
		out.append(v)
	return out


func at_parking(x: float) -> bool:
	for p in get_tree().get_nodes_in_group(&"parking"):
		if p.has_x(x):
			return true
	return false


## Put the band in a line ending at `x`, facing `facing`.
func place_band(x: float, facing: float) -> void:
	leader.respawn(Vector2(x, GROUND_Y), leader.health.hp)
	leader.facing = facing
	_trail.clear()
	var back := x - facing * FOLLOW_GAP * followers.size()
	var steps := int(absf(x - back) / TRAIL_STEP)
	for i in steps + 1:
		_trail.append(Vector2(lerpf(back, x, float(i) / steps), GROUND_Y))
	_update_followers()
	band.camera.follow(leader, true)


# --- Vehicles --------------------------------------------------------------

func board(v: Vehicle) -> void:
	if vehicle:
		return
	if v.kind == Vehicle.Kind.VAN and not at_parking(v.global_position.x):
		leader.show_text("The van only stops at P signs")
		return
	vehicle = v
	v.occupied = true
	v.velocity = Vector2.ZERO
	v.facing = leader.facing
	leader.velocity = Vector2.ZERO
	leader.set_physics_process(false)
	var riding := v.kind == Vehicle.Kind.BIKES
	for m in band.members:
		m.visible = riding
		_bikes[m].visible = riding
	if riding:
		place_band(v.global_position.x, leader.facing)
		leader.set_physics_process(false)
	band.camera.follow(v)
	band.camera.look_ahead = DRIVE_LOOK_AHEAD
	_cooldown = INTERACT_COOLDOWN
	_update_vehicle_hint()


func leave_vehicle() -> bool:
	if vehicle == null or _cooldown > 0.0:
		return false
	var v := vehicle
	if v.kind == Vehicle.Kind.VAN and not at_parking(v.global_position.x):
		_say_at(v, "Park at a P sign first")
		return false
	vehicle = null
	v.occupied = false
	v.velocity = Vector2.ZERO
	v.save_position()
	for m in band.members:
		m.visible = true
		_bikes[m].visible = false
	leader.set_physics_process(true)
	place_band(v.global_position.x + (0.0 if v.kind == Vehicle.Kind.BIKES else -v.facing * 34.0), v.facing)
	band.camera.look_ahead = WALK_LOOK_AHEAD
	_cooldown = INTERACT_COOLDOWN
	_update_vehicle_hint()
	return true


func _drive(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	var top := leader.profile.run_speed() * vehicle.speed_mult()
	vehicle.drive(dir, top, delta, _min_x, _max_x)
	# The leader rides along (visible on the bikes, hidden in the van).
	leader.global_position = vehicle.global_position
	leader.velocity = vehicle.velocity
	leader.facing = vehicle.facing
	leader.sprite.flip_h = vehicle.facing < 0.0
	_set_anim(leader, &"idle")
	_bikes[leader].facing = vehicle.facing
	if Input.is_action_just_pressed("interact"):
		leave_vehicle()


# --- Followers -------------------------------------------------------------

func _record_trail() -> void:
	var p := leader.global_position
	if _trail.is_empty() or p.distance_to(_trail.back()) >= TRAIL_STEP:
		_trail.append(p)
		if _trail.size() > TRAIL_MAX:
			_trail.pop_front()


## Each follower stands FOLLOW_GAP px further back along the leader's path.
func _update_followers() -> void:
	if _trail.is_empty():
		return
	var want := FOLLOW_GAP
	var walked := 0.0
	var i := 0
	var k := _trail.size() - 1
	while i < followers.size() and k > 0:
		var seg := _trail[k].distance_to(_trail[k - 1])
		if walked + seg >= want:
			var t := (want - walked) / seg if seg > 0.0 else 0.0
			_move_follower(followers[i], _trail[k].lerp(_trail[k - 1], t))
			i += 1
			want += FOLLOW_GAP
		else:
			walked += seg
			k -= 1


func _move_follower(m: BandMember, p: Vector2) -> void:
	var old := m.global_position
	m.global_position = p
	var d := p - old
	if absf(d.x) > 0.05:
		m.facing = signf(d.x)
	m.sprite.flip_h = m.facing < 0.0
	_bikes[m].facing = m.facing
	if vehicle and vehicle.kind == Vehicle.Kind.BIKES:
		_set_anim(m, &"idle")
	elif p.y < GROUND_Y - 1.0:
		_set_anim(m, &"jump" if d.y < 0.0 else &"fall")
	else:
		_set_anim(m, &"run" if d.length() > 0.2 else &"idle")


func _set_anim(m: BandMember, anim: StringName) -> void:
	if m.sprite.animation != anim:
		m.sprite.play(anim)


# --- Interact, talk, doors -------------------------------------------------

func _update_interact() -> void:
	var best: Interactable = null
	if vehicle == null:
		var best_d := INF
		for node in get_tree().get_nodes_in_group(&"interactable"):
			var it := node as Interactable
			if it.overlaps_body(leader) and it.can_interact(leader):
				var d := it.global_position.distance_squared_to(leader.global_position)
				if d < best_d:
					best = it
					best_d = d
	if best != _highlighted:
		if _highlighted:
			_highlighted.set_highlighted(false)
		_highlighted = best
		if best:
			best.set_highlighted(true)
	if best is Vehicle:
		best.set_prompt_text("E  ride the bikes" if best.kind == Vehicle.Kind.BIKES else "E  drive the van")
	elif best is Npc:
		best.set_prompt_text("E  talk")
	if best and _cooldown <= 0.0 and Input.is_action_just_pressed("interact"):
		best.interact(leader, self)
		_cooldown = maxf(_cooldown, INTERACT_COOLDOWN)


func talk_to(npc: Npc) -> void:
	if talking:
		return
	talking = true
	if _highlighted:                        # no "E talk" prompt during the conversation
		_highlighted.set_highlighted(false)
		_highlighted = null
	leader.velocity = Vector2.ZERO
	leader.set_active(false)
	await dialogue.play(npc.speaker, npc.lines())
	npc.talked()
	leader.set_active(true)
	talking = false
	_cooldown = INTERACT_COOLDOWN


func enter_door(door: WorldDoor) -> void:
	for v in vehicles():
		v.save_position()
	SceneRouter.go_to(door.target_scene, door.target_spawn)


func _update_vehicle_hint() -> void:
	if vehicle == null:
		hud.set_vehicle_hint("")
	elif vehicle.kind == Vehicle.Kind.BIKES:
		hud.set_vehicle_hint("On the bikes: E to get off anywhere")
	else:
		hud.set_vehicle_hint("Driving the van: park at a P sign and press E")


func _say_at(node: Node2D, text: String) -> void:
	FloatText.spawn(self, node.global_position + Vector2(0, -40), text)


func _spawn_from_router() -> Node2D:
	if SceneRouter.pending_spawn == &"":
		return null
	var node := find_child(String(SceneRouter.pending_spawn), true, false) as Node2D
	SceneRouter.pending_spawn = &""
	return node
