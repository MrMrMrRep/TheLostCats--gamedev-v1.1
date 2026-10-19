class_name WorldMap
extends Node2D
## The calm side of the game: Amsterdam left and right of the studio. The active
## member leads; the others trail behind on the leader's exact path (Kingdom
## Eighties style). No switching, no deaths. Bikes (whole band rides, off
## anywhere) and the band van (fast, only at P signs) move the band; doors lead
## into levels; Geordie gives the tour quest. The camera zoom tells you where
## you are: 3x at the studio, 2x in the city, 1x driving the van in town and
## 0.5x on the road outside town (birds fly by). Zoom changes ease slowly (slower still while driving) and
## the view height follows, so the canal stays in shot.

const GROUND_Y := 288.0
const TRAIL_STEP := 2.0                     # px between recorded trail points
const FOLLOW_GAP := 16.0                    # px between members riding in the bike line
const WALK_GAP := 26.0                      # walking: each member keeps about this much more distance
const CATCH_UP := 90.0                      # further behind than their gap + this: they jog
const FOLLOW_ACCEL := 380.0                 # px/s^2 a follower speeds up / slows down
const TRAIL_MAX := 400
const WALK_LOOK_AHEAD := 80.0
const DRIVE_LOOK_AHEAD := 160.0
const INTERACT_COOLDOWN := 0.3
const EDGE_MARGIN := 30.0                   # vehicles stop this far from a road block
const WATER_LINE := GROUND_Y + 22.0         # top of the canal
# On foot and on the bikes the zoom follows the band's tempo, not the place:
# close when strolling or standing, further out the faster they go, and
# always wide enough for the group (a straggler may drop out of frame).
const ZOOM_WALK := 3.0                      # standing / strolling
const ZOOM_WALK_MOVING := 2.4               # walking at full pace
const ZOOM_BIKE_SLOW := 2.6                 # on the bikes, rolling slowly
const ZOOM_BIKE := 2.0                      # on the bikes at speed
const ZOOM_OUT_RATE := 1.1                  # zooming out keeps up with the band
const ZOOM_IN_RATE := 0.28                  # zooming in is slow: it takes a while to settle
const TEMPO_SETTLE := 2.5                   # seconds for the tempo to calm down after slowing
const FOCUS_CAP := 170.0                    # members further back than this don't widen the shot
const FIT_MARGIN := 80.0                    # px of room around the group
const FOCUS_LEAD := 34.0                    # the shot leads in the walking direction
const IDLE_ZOOM_AFTER := 15.0               # band idle this long: the camera starts to wander
const ZOOM_IDLE := 1.5                      # ...very slowly out to here
const IDLE_ZOOM_RATE := 0.05
const DRIFT_PERIOD := 48.0                  # seconds for one slow sway left and right
const DRIFT_MAX := 160.0                    # px, and never so far that the band leaves the frame
# In the van the view stays close wherever you drive: a little tempo zoom
# between parked and full speed, never further out than ZOOM_VAN_TOWN. Only
# the road trip proper (west of `scenic_from`, past the last windmill) opens
# up, very slowly, to ZOOM_ROAD.
const ZOOM_VAN_TOWN := 1.3                  # the van at speed: this far out, no further
const ZOOM_VAN_SLOW_TOWN := 1.7             # the van crawling or parked
const SCENIC_RATE := 0.06                   # the road-trip zoom-out: ever so slowly
const WALK_SPEED := 85.0                    # a calm walk on the map (levels keep their run)
const CITY_SPEED := 190.0                   # the van's speed limit in town
const ZOOM_ROAD := 0.5
const ZOOM_EASE := 0.9                      # higher = faster zoom changes (on foot)
const ZOOM_EASE_DRIVE := 0.22               # driving: a slow, calm zoom out / in

@export var map_width := 3840
@export var start_spawn: NodePath
@export var town := Vector2(1100, 3640)     ## world x range of the city
@export var map_min := 0.0                  ## west end of the map (the cow land goes below 0)
@export var city_limit := Vector2.ZERO      ## world x range where the van keeps to CITY_SPEED
@export var foot_limit := -100000.0         ## world x: west of it is motorway; no walking or cycling
@export var scenic_from := -100000.0        ## world x: west of it the road trip opens up (past the last windmill)

var leader: BandMember
var followers: Array[BandMember] = []
var vehicle: Vehicle                        # the one the band is using, or null on foot
var talking := false
var zoom := ZOOM_WALK
var radio: VanRadio

var _trail: Array[Vector2] = []
var _fstate := {}                           # BandMember -> {v, gap, pause, walked, next_pause}
var _bikes := {}                            # BandMember -> BikeSprite
var _cooldown := 0.0
var _highlighted: Interactable
var _min_x := 0.0
var _max_x := 0.0
var _tempo := 0.0                           # 0 standing .. 1 full speed (eases down slowly)
var _spread := 0.0                          # px from the front member to the back one framed
var _focus: Node2D                          # what the camera follows on foot / on the bikes
var _idle_cam := 0.0                        # seconds the band has stood still (camera wander)
var _foot_note := 0.0                       # cooldown for the "no walking/cycling" line
var _drift := 0.0                           # current sideways drift of the shot

@onready var band: Band = $Band
@onready var hud: MapHud = $MapHud
@onready var dialogue: DialogueBox = $DialogueBox
@onready var birds: WorldBirds = get_node_or_null("Birds")


static func of(node: Node) -> WorldMap:
	return node.get_tree().get_first_node_in_group(&"world_map") as WorldMap


func _ready() -> void:
	add_to_group(&"world_map")
	band.locked = true                      # no switching or gather on the map
	_focus = Node2D.new()
	_focus.name = "CameraFocus"
	add_child(_focus)
	radio = VanRadio.new()
	radio.name = "VanRadio"
	add_child(radio)
	radio.tuned.connect(hud.set_radio)
	var cam := band.camera
	cam.position_smoothing_speed = 4.0
	cam.deadzone = Vector2(24, 40)
	cam.look_ahead = WALK_LOOK_AHEAD
	cam.sticky_look = true                  # stopping doesn't swing the view back
	cam.set_bounds(Rect2i(int(map_min), -10000, int(map_width - map_min), 20000))
	leader = band.active
	for m in band.members:
		m.speed_scale = WALK_SPEED / m.profile.run_speed()
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
			_fstate[m] = {"v": 0.0, "gap": WALK_GAP * followers.size() + randf_range(-5.0, 5.0),
				"pause": 0.0, "walked": 0.0, "next_pause": randf_range(5.0, 12.0)}
			m.fidget_after = randf_range(2.5, 7.0)
	_min_x = map_min + EDGE_MARGIN
	_max_x = map_width - EDGE_MARGIN
	for b in find_children("*", "RoadBarrier", true, false):
		if b.global_position.x < (map_min + map_width) / 2.0:
			_min_x = maxf(_min_x, b.global_position.x + EDGE_MARGIN)
		else:
			_max_x = minf(_max_x, b.global_position.x - EDGE_MARGIN)
	for v in vehicles():
		v.restore_position()
	var spawn := _spawn_from_router()
	if spawn == null:
		spawn = get_node(start_spawn)
	zoom = target_zoom_at(spawn.global_position.x)
	_apply_zoom()
	place_band(spawn.global_position.x, 1.0)
	_update_vehicle_hint()


func _physics_process(delta: float) -> void:
	_cooldown = maxf(_cooldown - delta, 0.0)
	if talking:
		if vehicle == null:
			for m in followers:                 # stand and listen (and fidget)
				_fstate[m].v = 0.0
				m.animate_as_follower(0.0)
		_update_focus(delta)
		_update_zoom(delta)
		return
	if vehicle:
		_drive(delta)
	_foot_note = maxf(_foot_note - delta, 0.0)
	if vehicle == null and leader.global_position.x < foot_limit:
		leader.global_position.x = foot_limit # on foot: the motorway starts here
		leader.velocity.x = maxf(leader.velocity.x, 0.0)
		_foot_warning(leader)
	_record_trail()
	if vehicle and vehicle.kind == Vehicle.Kind.BIKES:
		_update_followers()                 # riding: a tight line on the leader's track
	elif vehicle == null:
		_walk_followers(delta)              # walking: each follows at their own pace
	_update_focus(delta)
	_update_zoom(delta)
	_update_interact()


# --- Zoom ------------------------------------------------------------------

func x_in(r: Vector2, x: float) -> bool:
	return x >= r.x and x <= r.y


func in_town(x: float) -> bool:
	return x >= town.x and x <= town.y


## Zoom the van wants at world x (on foot and on the bikes it's the tempo).
func target_zoom_at(x: float) -> float:
	if vehicle and vehicle.kind == Vehicle.Kind.VAN:
		if x < scenic_from:
			return ZOOM_ROAD
		return lerpf(ZOOM_VAN_SLOW_TOWN, ZOOM_VAN_TOWN, _tempo)
	return _tempo_zoom()


## On foot / bikes: between the slow and the moving zoom by tempo, never
## closer than what fits the group.
func _tempo_zoom() -> float:
	var on_bikes := vehicle != null and vehicle.kind == Vehicle.Kind.BIKES
	var near := ZOOM_BIKE_SLOW if on_bikes else ZOOM_WALK
	var far := ZOOM_BIKE if on_bikes else ZOOM_WALK_MOVING
	return minf(lerpf(near, far, _tempo), 640.0 / (_spread + FIT_MARGIN))


## The camera aims at the middle of the group (members within FOCUS_CAP of the
## front), leading a little in the direction the band goes.
func _update_focus(delta: float, instant := false) -> void:
	if vehicle and vehicle.kind == Vehicle.Kind.VAN:
		return
	var front := leader.global_position.x
	var lo := front
	var hi := front
	for m in followers:
		var mx := m.global_position.x
		if absf(mx - front) <= FOCUS_CAP:
			lo = minf(lo, mx)
			hi = maxf(hi, mx)
	var spread := hi - lo
	var goal := (lo + hi) / 2.0 + leader.facing * FOCUS_LEAD * _tempo
	# Idle for long: drift slowly sideways, keeping the band (partly) in frame.
	var want_drift := 0.0
	if _idle_cam > IDLE_ZOOM_AFTER:
		var t := _idle_cam - IDLE_ZOOM_AFTER
		var room := maxf(0.0, 640.0 / zoom / 2.0 - 40.0)
		want_drift = sin(t * TAU / DRIFT_PERIOD) * minf(room, DRIFT_MAX) * clampf(t / 20.0, 0.0, 1.0)
	_drift = 0.0 if instant else lerpf(_drift, want_drift, 1.0 - exp(-delta * 0.8))
	goal += _drift
	var k := 1.0 if instant else 1.0 - exp(-delta * 3.0)
	_spread = lerpf(_spread, spread, k)
	_focus.global_position = Vector2(lerpf(_focus.global_position.x, goal, k), leader.global_position.y)


func _update_zoom(delta: float) -> void:
	var x := vehicle.global_position.x if vehicle else leader.global_position.x
	var target := 0.0
	var rate := ZOOM_EASE
	if vehicle and vehicle.kind == Vehicle.Kind.VAN:
		var frac := clampf(absf(vehicle.velocity.x) / CITY_SPEED, 0.0, 1.0)
		_tempo = frac if frac > _tempo else move_toward(_tempo, frac, delta / TEMPO_SETTLE)
		target = target_zoom_at(x)
		rate = ZOOM_OUT_RATE * 0.5 if target < zoom else ZOOM_IN_RATE
		if x < scenic_from:
			rate = SCENIC_RATE                  # the road trip: open up ever so slowly
	else:
		var speed := absf(vehicle.velocity.x) if vehicle else absf(leader.velocity.x)
		var ref := vehicle.top_speed() if vehicle else WALK_SPEED
		var frac := clampf(speed / ref, 0.0, 1.0)
		# The tempo picks up at once and calms down slowly, so a short stop
		# doesn't make the view jump, and slowing down eases in over time.
		_tempo = frac if frac > _tempo else move_toward(_tempo, frac, delta / TEMPO_SETTLE)
		target = _tempo_zoom()
		rate = ZOOM_OUT_RATE if target < zoom else ZOOM_IN_RATE
		_idle_cam = _idle_cam + delta if speed < 2.0 and not talking else 0.0
		if _idle_cam > IDLE_ZOOM_AFTER:         # long idle: wander out, very very slowly
			target = ZOOM_IDLE
			rate = IDLE_ZOOM_RATE
	zoom = lerpf(zoom, target, 1.0 - exp(-delta * rate))
	if absf(zoom - target) < 0.002:
		zoom = target
	_apply_zoom()
	if birds:
		birds.active = not in_town(x)


## Camera zoom + view height: the street sits low, with a band of canal below.
func _apply_zoom() -> void:
	var cam := band.camera
	cam.zoom = Vector2(zoom, zoom)
	var view_h := 360.0 / zoom
	var water_visible := clampf(view_h * 0.13, 22.0, 160.0)   # a strip of canal; facades get the rest
	cam.fixed_y = WATER_LINE + water_visible - view_h / 2.0


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
	if vehicle and vehicle.kind == Vehicle.Kind.BIKES:
		_update_followers()
	else:
		for m in followers:                 # walkers stand at their own distance
			var st: Dictionary = _fstate[m]
			st.v = 0.0
			st.pause = 0.0
			m.global_position = Vector2(clampf(x - facing * st.gap, _min_x, _max_x), GROUND_Y)
			m.facing = facing
			m.velocity = Vector2.ZERO
			m.animate_as_follower(0.0)
	_idle_cam = 0.0
	_update_focus(0.0, true)
	band.camera.follow(_focus, true)


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
	if riding:
		band.camera.follow(_focus)
	else:
		band.camera.follow(v)
		band.camera.look_ahead = DRIVE_LOOK_AHEAD
	if not riding:
		radio.power(true)
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
	radio.power(false)
	v.velocity = Vector2.ZERO
	v.save_position()
	for m in band.members:
		m.visible = true
		_bikes[m].visible = false
	leader.set_physics_process(true)
	place_band(v.global_position.x + (0.0 if v.kind == Vehicle.Kind.BIKES else -v.facing * 28.0), v.facing)
	band.camera.look_ahead = WALK_LOOK_AHEAD
	_cooldown = INTERACT_COOLDOWN
	_update_vehicle_hint()
	return true


func _drive(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	var top := vehicle.top_speed()
	if vehicle.kind == Vehicle.Kind.VAN and x_in(city_limit, vehicle.global_position.x):
		top = minf(top, CITY_SPEED)
	var lo := _min_x
	if vehicle.kind == Vehicle.Kind.BIKES:
		lo = maxf(lo, foot_limit)            # bikes stop at the motorway fork
		if vehicle.global_position.x <= lo + 0.5 and dir < 0.0:
			_foot_warning(vehicle)
	vehicle.drive(dir, top, delta, lo, _max_x)
	# The leader rides along (visible on the bikes, hidden in the van).
	leader.global_position = vehicle.global_position
	leader.velocity = vehicle.velocity
	leader.facing = vehicle.facing
	leader.sprite.flip_h = vehicle.facing < 0.0
	_set_anim(leader, &"idle")
	_bikes[leader].facing = vehicle.facing
	if vehicle.kind == Vehicle.Kind.VAN and Input.is_action_just_pressed("use_item"):
		radio.next_channel()
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


## Walking followers behave like members following a lure: anyone further
## from the leader than their own gap walks after them (jogs when far
## behind), now and then someone pauses for a moment, and when they stand
## still long enough they smoke, drink or play.
func _foot_warning(at: Node2D) -> void:
	if _foot_note > 0.0:
		return
	_foot_note = 3.0
	_say_at(at, "No walking or cycling on the motorway")


func _walk_followers(delta: float) -> void:
	var lx := leader.global_position.x
	for m in followers:
		var st: Dictionary = _fstate[m]
		var dx := lx - m.global_position.x
		var dist := absf(dx)
		var want := 0.0
		if dist > st.gap + 6.0:
			want = signf(dx) * WALK_SPEED * (1.9 if dist > st.gap + CATCH_UP else 1.0)
		if st.pause > 0.0:
			st.pause -= delta
			if dist < st.gap + CATCH_UP:
				want = 0.0
		elif absf(st.v) > 1.0:
			st.walked += absf(st.v) * delta
			if st.walked > st.next_pause * WALK_SPEED and dist < st.gap + 40.0:
				st.pause = randf_range(0.4, 1.3)    # stops for a second (a look around, a sip)
				st.walked = 0.0
				st.next_pause = randf_range(5.0, 12.0)
		st.v = move_toward(st.v, want, FOLLOW_ACCEL * delta)
		m.global_position = Vector2(clampf(m.global_position.x + st.v * delta, _min_x, _max_x), GROUND_Y)
		if absf(st.v) > 1.0:
			m.facing = signf(st.v)
		m.velocity = Vector2(st.v, 0.0)
		m.animate_as_follower(st.v)


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
	m.play_anim(anim)


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
	elif best is StorageGate:
		best.set_prompt_text(best.prompt_text())
	if vehicle == null and _cooldown <= 0.0 and Input.is_action_just_pressed("interact"):
		if best:
			best.interact(leader, self)
		else:                               # nothing here: use the selected item
			leader.use_current_item()
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
	Game.set_flag(&"map_return", String(door.name))
	SceneRouter.go_to(door.target_scene, door.target_spawn)


## The storage gate's keypad: no code yet, so Joep hacks it with his phone.
## The gate opens on the frame his hack completes (hack_complete spawn event).
func hack_gate(gate: StorageGate) -> void:
	if talking:
		return
	talking = true
	if _highlighted:
		_highlighted.set_highlighted(false)
		_highlighted = null
	leader.velocity = Vector2.ZERO
	leader.set_active(false)
	var hacker := leader
	for m in band.members:
		if m.profile and m.profile.id == &"joep":
			hacker = m
	gate.say("Keypad: ENTER CODE", 1.0)
	await get_tree().create_timer(1.1).timeout
	hacker.facing = 1.0 if gate.global_position.x >= hacker.global_position.x else -1.0
	hacker.sprite.flip_h = hacker.facing < 0.0
	hacker.show_text("Code? Who needs a code")
	var spawn: Dictionary = hacker.sprite_data.get_spawn("attack_special_a") if hacker.sprite_data else {}
	if spawn.is_empty():
		await get_tree().create_timer(1.0).timeout
	else:
		hacker.play_action(&"attack_special_a")
		var waited := 0.0
		while hacker.sprite.animation == &"attack_special_a" and hacker.sprite.frame < spawn.frame and waited < 4.0:
			waited += await _frame_time()
	gate.open()
	gate.say("ACCESS GRANTED")
	await get_tree().create_timer(1.0).timeout
	leader.set_active(true)
	talking = false
	_cooldown = INTERACT_COOLDOWN


func _frame_time() -> float:
	await get_tree().process_frame
	return get_process_delta_time()


func _update_vehicle_hint() -> void:
	if vehicle == null:
		hud.set_vehicle_hint("")
	elif vehicle.kind == Vehicle.Kind.BIKES:
		hud.set_vehicle_hint("On the bikes: E to get off anywhere")
	else:
		hud.set_vehicle_hint("Driving the van: park at a P sign and press E.  R: radio")


func _say_at(node: Node2D, text: String) -> void:
	FloatText.spawn(self, node.global_position + Vector2(0, -40), text)


func _spawn_from_router() -> Node2D:
	if SceneRouter.pending_spawn == &"":
		for arg in OS.get_cmdline_user_args():     # dev: start at a node, -- --spawn=StorageGate
			if arg.begins_with("--spawn="):
				return find_child(arg.trim_prefix("--spawn="), true, false) as Node2D
		return null
	var node := find_child(String(SceneRouter.pending_spawn), true, false) as Node2D
	SceneRouter.pending_spawn = &""
	# Several doors can lead into one level: come back out of the one you used.
	var back_name := String(Game.get_flag(&"map_return", ""))
	var back := find_child(back_name, true, false) as WorldDoor if back_name != "" else null
	Game.set_flag(&"map_return", "")
	if node is WorldDoor and back and back.target_scene == node.target_scene:
		return back
	return node
