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
const INTERACT_COOLDOWN := 0.3
const EDGE_MARGIN := 30.0                   # vehicles stop this far from a road block
const WATER_LINE := GROUND_Y + 22.0         # top of the canal
# Tuning lives in resources/config/ (edit in the inspector, see
# docs/editing-the-world.md): the camera in map_camera_config.tres, the band's
# walk in band_map_config.tres, the bikes and the van in vehicle_config.tres.
# On foot and on the bikes the zoom follows the band's tempo, not the place:
# close when strolling or standing, further out the faster they go, and
# always wide enough for the group (a straggler may drop out of frame). In the
# van the view stays close wherever you drive; only the road trip proper (west
# of the ScenicFrom marker, past the last windmill) opens up, very slowly.

@export var map_width := 3840               ## east end of the map (world x)
@export var start_spawn: NodePath
@export var map_min := 0.0                  ## west end of the map (the cow land goes below 0)

# Rule lines, read from the markers in the Markers folder (drag them in the editor).
var town := Vector2(1100, 3640)             # TownWest..TownEast: the city (no birds)
var city_limit := Vector2.ZERO              # SpeedLimitStart..SpeedLimitEnd: the van keeps to city_speed
var foot_limit := -100000.0                 # FootLimit: west of it is motorway; no walking or cycling
var scenic_from := -100000.0                # ScenicFrom: west of it the road trip opens up
var road_from := -100000.0                  # RoadTransition: the city street begins (west of it: motorway)

var cam_cfg: MapCameraConfig:
	get: return MapCameraConfig.current()
var band_cfg: BandMapConfig:
	get: return BandMapConfig.current()
var veh_cfg: VehicleConfig:
	get: return VehicleConfig.current()

var leader: BandMember
var followers: Array[BandMember] = []
var vehicle: Vehicle                        # the one the band is using, or null on foot
var talking := false
var zoom := 3.0
var radio: VanRadio
var day: WorldDayCycle                      # the clock, the night tint and lights

var _fstate := {}                           # BandMember -> {v, gap, pause, walked, next_pause}
var _bikes := {}                            # BandMember -> BikeSprite (placeholder for members without bike art)
var _lamps := {}                            # BandMember -> NightGlow (bike lights)
var _ride_time := 0.0
var _cooldown := 0.0
var _highlighted: Interactable
var _min_x := 0.0
var _max_x := 0.0
var _tempo := 0.0                           # 0 standing .. 1 full speed (eases down slowly)
var _spread := 0.0                          # px from the front member to the back one framed
var _focus: Node2D                          # what the camera follows on foot / on the bikes
var _idle_cam := 0.0                        # seconds the band has stood still (camera wander)
var _foot_note := 0.0                       # cooldown for the "no walking/cycling" line
var _lane_y := 0.0                          # the van's lane offset on the motorway
var _drift := 0.0                           # current sideways drift of the shot

@onready var band: Band = $Band
@onready var hud: MapHud = $MapHud
@onready var dialogue: DialogueBox = $DialogueBox
@onready var birds: WorldBirds = get_node_or_null("Birds")


static func of(node: Node) -> WorldMap:
	return node.get_tree().get_first_node_in_group(&"world_map") as WorldMap


func _ready() -> void:
	add_to_group(&"world_map")
	_read_markers()
	zoom = cam_cfg.zoom_walk
	band.locked = true                      # no switching or gather on the map
	_focus = Node2D.new()
	_focus.name = "CameraFocus"
	add_child(_focus)
	radio = VanRadio.new()
	radio.name = "VanRadio"
	add_child(radio)
	radio.tuned.connect(hud.set_radio)
	day = WorldDayCycle.new()
	day.name = "DayCycle"
	add_child(day)
	day.hour_changed.connect(func(_h: float) -> void: hud.set_clock(day.clock_text()))
	hud.set_clock(day.clock_text())
	hud.skip_requested.connect(day.sleep)
	var cam := band.camera
	cam.position_smoothing_speed = cam_cfg.smoothing_speed
	cam.deadzone = cam_cfg.deadzone
	cam.look_ahead = cam_cfg.walk_look_ahead
	cam.sticky_look = true                  # stopping doesn't swing the view back
	cam.set_bounds(Rect2i(int(map_min), -10000, int(map_width - map_min), 20000))
	leader = band.active
	for m in band.members:
		m.speed_scale = band_cfg.walk_speed / m.profile.run_speed()
		m.show_name_tag = false
		m.name_tag.visible = false
		BikeRiders.ensure(m)                # bike_pedal / bike_roll for everyone
		var bike := BikeSprite.new()
		bike.z_index = 1
		bike.visible = false
		m.add_child(bike)
		_bikes[m] = bike
		_lamps[m] = NightGlow.attach(m)     # bike lights at night
		if m != leader:
			followers.append(m)
			m.set_physics_process(false)
			var bc := band_cfg
			_fstate[m] = {"v": 0.0, "gap": bc.walk_gap * followers.size() + randf_range(-bc.gap_jitter, bc.gap_jitter),
				"pause": 0.0, "walked": 0.0, "next_pause": randf_range(bc.pause_every.x, bc.pause_every.y),
				"ride_gap": bc.ride_gap * followers.size() + randf_range(-bc.ride_jitter, bc.ride_jitter),
				"phase": randf() * TAU, "sway": randf_range(0.15, 0.3)}
			m.fidget_after = randf_range(bc.fidget_after.x, bc.fidget_after.y)
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
	LiveConfig.poll()
	day.paused = talking                    # time stands still during a conversation
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
	if vehicle and vehicle.kind == Vehicle.Kind.BIKES:
		_ride_followers(delta)              # riding: a loose group, each at their own pace
	elif vehicle == null:
		_walk_followers(delta)              # walking: each follows at their own pace
	_update_bike_lights()
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
			return cam_cfg.zoom_road
		return lerpf(cam_cfg.zoom_van_slow, cam_cfg.zoom_van, _tempo)
	return _tempo_zoom()


## On foot / bikes: between the slow and the moving zoom by tempo, never
## closer than what fits the group.
func _tempo_zoom() -> float:
	var on_bikes := vehicle != null and vehicle.kind == Vehicle.Kind.BIKES
	var c := cam_cfg
	var near := c.zoom_bike_slow if on_bikes else c.zoom_walk
	var far := c.zoom_bike if on_bikes else c.zoom_walk_moving
	return minf(lerpf(near, far, _tempo), 640.0 / (_spread + c.fit_margin))


## The camera aims at the middle of the group (members within focus_cap of the
## front), leading a little in the direction the band goes.
func _update_focus(delta: float, instant := false) -> void:
	if vehicle and vehicle.kind == Vehicle.Kind.VAN:
		return
	var c := cam_cfg
	var front := leader.global_position.x
	var lo := front
	var hi := front
	for m in followers:
		var mx := m.global_position.x
		if absf(mx - front) <= c.focus_cap:
			lo = minf(lo, mx)
			hi = maxf(hi, mx)
	var spread := hi - lo
	var goal := (lo + hi) / 2.0 + leader.facing * c.focus_lead * _tempo
	# Idle for long: drift slowly sideways, keeping the band (partly) in frame.
	var want_drift := 0.0
	if _idle_cam > c.idle_after:
		var t := _idle_cam - c.idle_after
		var room := maxf(0.0, 640.0 / zoom / 2.0 - 40.0)
		want_drift = sin(t * TAU / c.drift_period) * minf(room, c.drift_max) * clampf(t / 20.0, 0.0, 1.0)
	_drift = 0.0 if instant else lerpf(_drift, want_drift, 1.0 - exp(-delta * c.drift_ease))
	goal += _drift
	var k := 1.0 if instant else 1.0 - exp(-delta * c.focus_ease)
	_spread = lerpf(_spread, spread, k)
	_focus.global_position = Vector2(lerpf(_focus.global_position.x, goal, k), leader.global_position.y)


func _update_zoom(delta: float) -> void:
	var x := vehicle.global_position.x if vehicle else leader.global_position.x
	var c := cam_cfg
	var target := 0.0
	var rate := 0.0
	if vehicle and vehicle.kind == Vehicle.Kind.VAN:
		var frac := clampf(absf(vehicle.velocity.x) / veh_cfg.city_speed, 0.0, 1.0)
		_tempo = frac if frac > _tempo else move_toward(_tempo, frac, delta / c.tempo_settle)
		target = target_zoom_at(x)
		rate = c.zoom_out_rate * 0.5 if target < zoom else c.zoom_in_rate
		if x < scenic_from:
			rate = c.scenic_rate                # the road trip: open up ever so slowly
	else:
		var speed := absf(vehicle.velocity.x) if vehicle else absf(leader.velocity.x)
		var ref := vehicle.top_speed() if vehicle else band_cfg.walk_speed
		var frac := clampf(speed / ref, 0.0, 1.0)
		# The tempo picks up at once and calms down slowly, so a short stop
		# doesn't make the view jump, and slowing down eases in over time.
		_tempo = frac if frac > _tempo else move_toward(_tempo, frac, delta / c.tempo_settle)
		target = _tempo_zoom()
		rate = c.zoom_out_rate if target < zoom else c.zoom_in_rate
		_idle_cam = _idle_cam + delta if speed < 2.0 and not talking else 0.0
		if _idle_cam > c.idle_after:            # long idle: wander out, very very slowly
			target = c.zoom_idle
			rate = c.idle_zoom_rate
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
	var c := cam_cfg
	var water_visible := clampf(view_h * c.water_share, c.water_min, c.water_max)   # a strip of canal; facades get the rest
	cam.fixed_y = WATER_LINE + water_visible - view_h / 2.0


## The rule lines come from the markers in the Markers folder (missing
## markers keep the values above).
func _read_markers() -> void:
	town = Vector2(_marker_x(&"TownWest", town.x), _marker_x(&"TownEast", town.y))
	city_limit = Vector2(_marker_x(&"SpeedLimitStart", city_limit.x), _marker_x(&"SpeedLimitEnd", city_limit.y))
	foot_limit = _marker_x(&"FootLimit", foot_limit)
	scenic_from = _marker_x(&"ScenicFrom", scenic_from)
	road_from = _marker_x(&"RoadTransition", road_from)


func _marker_x(marker: StringName, fallback: float) -> float:
	var m := get_node_or_null(NodePath("Markers/" + marker)) as Node2D
	return m.global_position.x if m else fallback


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
	for m in followers:                     # each stands at their own distance
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
	_lane_y = v.global_position.y - GROUND_Y
	v.occupied = true
	v.velocity = Vector2.ZERO
	v.facing = leader.facing
	leader.velocity = Vector2.ZERO
	leader.set_physics_process(false)
	var riding := v.kind == Vehicle.Kind.BIKES
	for m in band.members:
		m.visible = riding
		_bikes[m].visible = riding and not JTCBike.has_bike_art(m)
		if riding:
			BikeRiders.mount(m)
	if riding:                              # everyone gets on where they stand
		leader.global_position = v.global_position
		for m in followers:
			_fstate[m].v = 0.0
	if riding:
		band.camera.follow(_focus)
	else:
		band.camera.follow(v)
		band.camera.look_ahead = cam_cfg.drive_look_ahead
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
		BikeRiders.unmount(m)
	leader.set_physics_process(true)
	if v.kind == Vehicle.Kind.BIKES:        # everyone gets off where they are; the bikes park by the leader
		leader.respawn(Vector2(v.global_position.x, GROUND_Y), leader.health.hp)
		leader.facing = v.facing
		for m in followers:
			_fstate[m].v = 0.0
			m.velocity = Vector2.ZERO
			m.animate_as_follower(0.0)
		_idle_cam = 0.0
		band.camera.follow(_focus)
	else:
		place_band(v.global_position.x - v.facing * 28.0, v.facing)
	band.camera.look_ahead = cam_cfg.walk_look_ahead
	_cooldown = INTERACT_COOLDOWN
	_update_vehicle_hint()
	return true


func _drive(delta: float) -> void:
	var dir := Input.get_axis("move_left", "move_right")
	var top := vehicle.top_speed()
	if vehicle.kind == Vehicle.Kind.VAN and x_in(city_limit, vehicle.global_position.x):
		top = minf(top, veh_cfg.city_speed)
	var lo := _min_x
	if vehicle.kind == Vehicle.Kind.BIKES:
		lo = maxf(lo, foot_limit)            # bikes stop at the motorway fork
		if vehicle.global_position.x <= lo + 0.5 and dir < 0.0:
			_foot_warning(vehicle)
	vehicle.drive(dir, top, delta, lo, _max_x)
	# On the motorway the van keeps to its own carriageway: a little lower
	# heading into the city (east), a little higher heading out (west).
	if vehicle.kind == Vehicle.Kind.VAN:
		var vx := vehicle.global_position.x
		var vc := veh_cfg
		var lane := 0.0
		if vx < road_from or vx > town.y:
			lane = vc.lane_east if vehicle.facing > 0.0 else vc.lane_west
		_lane_y = move_toward(_lane_y, lane, vc.lane_change * delta)
		vehicle.global_position.y = GROUND_Y + _lane_y
	# The leader rides along (visible on the bikes, hidden in the van).
	leader.global_position = vehicle.global_position
	leader.velocity = vehicle.velocity
	leader.facing = vehicle.facing
	leader.sprite.flip_h = vehicle.facing < 0.0
	if vehicle.kind == Vehicle.Kind.BIKES:
		JTCBike.ride(leader, vehicle.velocity.x, top, dir != 0.0)
	else:
		_set_anim(leader, &"idle")
	_bikes[leader].facing = vehicle.facing
	if vehicle.kind == Vehicle.Kind.VAN and Input.is_action_just_pressed("use_item"):
		radio.next_channel()
	if Input.is_action_just_pressed("interact"):
		leave_vehicle()


# --- Followers -------------------------------------------------------------

## Riding followers: like walking, each rides after the leader at their own
## distance (which drifts in and out a little), pedals hard to catch up when
## far behind, coasts and brakes like the leader's bikes, turns on their own.
func _ride_followers(delta: float) -> void:
	_ride_time += delta
	var bc := band_cfg
	var vc := veh_cfg
	var top := vehicle.top_speed()
	var lx := leader.global_position.x
	var lv := vehicle.velocity.x
	for m in followers:
		var st: Dictionary = _fstate[m]
		var gap: float = st.ride_gap + sin(_ride_time * st.sway + st.phase) * bc.ride_sway
		var spot := lx - leader.facing * gap  # where they'd like to be
		var off := spot - m.global_position.x
		var want := 0.0
		if absf(lx - m.global_position.x) > gap * 0.5 or absf(lv) > 5.0:
			want = clampf(lv + off * bc.ride_follow, -top * bc.ride_sprint, top * bc.ride_sprint)
			if absf(off) > bc.ride_catch_up:
				want = signf(off) * top * bc.ride_sprint
		if absf(want) < 4.0:
			want = 0.0
		var v: float = st.v
		var rate := vc.bikes_rolling + vc.bikes_drag * absf(v)   # coasting
		if want != 0.0 and signf(want) != signf(v) and absf(v) > 1.0:
			rate = vc.bikes_brake                                    # turning around: brake first
		elif absf(want) > absf(v):
			rate = vc.bikes_pull * (1.0 - clampf(absf(v) / (top * bc.ride_sprint), 0.0, 0.9))
		st.v = move_toward(v, want, rate * delta)
		var x := clampf(m.global_position.x + st.v * delta, maxf(_min_x, foot_limit), _max_x)
		if x != m.global_position.x + st.v * delta:
			st.v = 0.0
		m.global_position = Vector2(x, GROUND_Y)
		m.velocity = Vector2(st.v, 0.0)
		if absf(st.v) > 3.0:
			m.facing = signf(st.v)
		m.sprite.flip_h = m.facing < 0.0
		_bikes[m].facing = m.facing
		JTCBike.ride(m, st.v, top, absf(want) > absf(st.v) + 2.0)


## Lamps on the bikes at night: a white light in front, a red one at the back.
func _update_bike_lights() -> void:
	var riding := vehicle != null and vehicle.kind == Vehicle.Kind.BIKES
	for m in band.members:
		var g: NightGlow = _lamps.get(m)
		if g == null:
			continue
		g.clear()
		if riding and WorldDayCycle.night_now > 0.0:
			var f := m.facing
			g.add_halo(Vector2(f * 15.0, -17.0), 3.0, 0.0, Color(1.0, 0.97, 0.85, 0.9))
			g.add_halo(Vector2(f * 34.0, 2.0), 22.0, 0.0, Color(1.0, 0.95, 0.75, 0.25), 0.25)
			g.add_halo(Vector2(-f * 15.0, -15.0), 2.5, 0.0, Color(1.0, 0.12, 0.1, 0.85))
		g.queue_redraw()


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
	var bc := band_cfg
	for m in followers:
		var st: Dictionary = _fstate[m]
		var dx := lx - m.global_position.x
		var dist := absf(dx)
		var want := 0.0
		if dist > st.gap + 6.0:
			want = signf(dx) * bc.walk_speed * (bc.jog_factor if dist > st.gap + bc.catch_up else 1.0)
		if st.pause > 0.0:
			st.pause -= delta
			if dist < st.gap + bc.catch_up:
				want = 0.0
		elif absf(st.v) > 1.0:
			st.walked += absf(st.v) * delta
			if st.walked > st.next_pause * bc.walk_speed and dist < st.gap + 40.0:
				st.pause = randf_range(bc.pause_length.x, bc.pause_length.y)   # a look around, a sip
				st.walked = 0.0
				st.next_pause = randf_range(bc.pause_every.x, bc.pause_every.y)
		st.v = move_toward(st.v, want, bc.follow_accel * delta)
		m.global_position = Vector2(clampf(m.global_position.x + st.v * delta, _min_x, _max_x), GROUND_Y)
		if absf(st.v) > 1.0:
			m.facing = signf(st.v)
		m.velocity = Vector2(st.v, 0.0)
		m.animate_as_follower(st.v)


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
