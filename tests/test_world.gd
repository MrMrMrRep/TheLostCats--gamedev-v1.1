extends SceneTree
## Headless checks for the M8 world map (exits 1 on failure): band line,
## road blocks, Geordie's quest, bikes, van + parking, packages, coming back
## from the gig, the venue door.
## Run: Summer --headless --path . --script res://tests/test_world.gd
## Game classes stay untyped: naming them here would compile them before the
## autoloads exist in --script mode.

const EXPECTED_CHECKS := 77
const GY := 288.0
const WALK_SPEED := 180.0                   # Joep, px/s
const ACTIONS := ["move_left", "move_right", "jump", "interact"]

var failures := 0
var checks := 0
var map
var game
var router


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	game = root.get_node("Game")
	router = root.get_node("SceneRouter")
	map = await _load_map()

	_test_canal_kit()
	_test_red_light()
	await _test_zoom_walking()
	await _test_day_night()
	await _test_band_line()
	await _test_road_block()
	await _test_geordie_quest()
	await _test_bikes()
	await _test_van()
	await _test_package()
	await _test_return_from_gig()
	await _test_studio_door()
	await _test_storage_gate()
	await _test_venue_door()
	await _test_switch_and_party()

	if checks != EXPECTED_CHECKS:
		print("  FAIL ran %d of %d checks (script error?)" % [checks, EXPECTED_CHECKS])
		failures += 1
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


## The canal belt from the SpriteCook kit (docs/city-layout.md §8).
func _test_canal_kit() -> void:
	var row_script = load("res://scripts/world/canal_row.gd")
	var gables: Dictionary = load("res://scripts/world/canal_kit.gd").GABLES
	var doors := [&"door_venue", &"door_studio", &"door_cafe"]
	var blocks: Array = map.get_node("Buildings").find_children("*", "", true, false).filter(func(n): return n.has_method("kit_row") and n.kit)
	var bad := []
	var flat := true
	var pieces := []                        # [world x0, world x1] of every row and opening
	for b in blocks:
		var sp: Vector2 = b.kit_span()
		var row: Array = b.kit_row()
		var a := int(round((sp.x - b.global_position.x) * 2.0))
		var e := int(round((sp.y - b.global_position.x) * 2.0))
		if e <= a:
			continue
		pieces.append(sp)
		if not b.kit or row.is_empty():
			bad.append("%s empty" % b.name)
			continue
		var items: Array = row.duplicate()
		items.sort_custom(func(p, q): return p[1] < q[1])
		var lead: int = row_script.OPEN_JOINTS.get(b.district, Vector2i(0, 2)).y   # sheds and the park stand apart
		if items[0][1] < a or items[0][1] - a > lead:
			bad.append("%s starts at %d of %d" % [b.name, items[0][1], a])
		for i in items.size():
			var it: Array = items[i]
			var end: int = it[1] + row_script.item_width(it)
			if i + 1 < items.size() and end > items[i + 1][1]:
				bad.append("%s: %s overlaps %s" % [b.name, it[0], items[i + 1][0]])
			if i + 1 == items.size() and (end > e or e - end > lead * 2):
				bad.append("%s ends at %d of %d" % [b.name, end, e])
			if it[0] == row_script.ALLEY and (i == 0 or i == items.size() - 1):
				bad.append("%s: a steeg at the end of the row" % b.name)
			if i + 1 < items.size() and gables.has(it[0]) and gables.has(items[i + 1][0]) \
					and gables[it[0]] == gables[items[i + 1][0]]:
				flat = false
	_check(blocks.size() >= 25 and bad.is_empty(), "kit rows (hotels, park, old town, Wallen, canal belt, flats, industry): exactly filled, no overlaps, steegjes only between houses %s" % [bad])
	_check(flat, "neighbouring facades never share a gable")
	for o in map.get_node("Bridges").get_children():
		pieces.append(o.span())
	for o in map.get_node("Buildings").find_children("*", "", true, false):
		if o.has_method("span") and "piece" in o and o.on_pavement:   # landmarks (not the airport's, by the motorway)
			pieces.append(o.span())
	pieces.sort_custom(func(p, q): return p.x < q.x)
	var gaps := []
	for i in pieces.size() - 1:
		if absf(pieces[i + 1].x - pieces[i].y) > 1.0:
			gaps.append("%.1f..%.1f" % [pieces[i].y, pieces[i + 1].x])
	_check(gaps.is_empty() and absf(pieces[0].x - 6400.0) < 1.0 and absf(pieces[-1].y - 18706.0) < 1.0,
		"rows, openings and landmarks meet without gaps or overlaps from the town's start (6400) to its end (18706) %s" % [gaps])
	# Side streets: their road runs across the pavement into the street, and nobody parks across it.
	var mouths := []
	var loose := []
	for o in map.get_node("Bridges").get_children():
		var m: Vector3 = o.road_mouth()
		if o.kind == 1 and (m == Vector3.ZERO or m.x < o.span().x or m.y > o.span().y):
			loose.append(o.name)
		if m != Vector3.ZERO:
			mouths.append(m)
	var traffic = map.get_node("TrafficBack")
	for pc: Array in traffic._parked:
		for m: Vector3 in mouths:
			if pc[0] > m.x - 20.0 and pc[0] < m.y + 20.0:
				loose.append("car parked at %.0f" % pc[0])
	_check(mouths.size() >= 5 and loose.is_empty() and map.get_node("Road/Street")._road_mouths().size() == mouths.size(),
		"%d side streets meet the street with their road, none blocked by a parked car %s" % [mouths.size(), loose])
	# The outer districts' doors stay where they were, on their buildings' own doors.
	var station = map.get_node("Buildings/Industry/ServiceStation")
	var store = map.get_node("Buildings/Storage/BandStorage")
	var sdoor = map.get_node("Places/Industry/StationDoor")
	var gate = map.get_node("Places/Storage/StorageGate")
	_check(absf(sdoor.global_position.x - 17376.0) < 0.5 and absf(station.span().x + 92.0 - sdoor.global_position.x) <= 1.5
		and not sdoor.draw_door and absf(gate.global_position.x - 18431.0) < 0.5
		and absf(store.span().x + 57.5 - gate.global_position.x) <= 1.5,
		"the service station's and the storage's doors stand on their buildings' doors (StationDoor 17376, StorageGate 18431)")
	for pair in [["Studio", "StudioDoor", &"door_studio"], ["Venue", "VenueDoor", &"door_venue"]]:
		var block = map.get_node("Buildings/CanalBelt/" + pair[0])
		var door = map.get_node("Places/CanalBelt/" + pair[1])
		var house: Array = block.kit_row()[-1]
		var mid: float = block.global_position.x + (house[1] + row_script.width(house[0]) / 2.0) * 0.5
		_check(house[0] == pair[2] and absf(mid - door.global_position.x) <= 1.5 and not door.draw_door,
			"%s: the door house stands on its door (x %.1f vs %.1f)" % [pair[1], mid, door.global_position.x])
	var trees = map.get_node("QuayTrees")
	var spots: Array = trees.spots()
	var blocked := []
	for t: Array in spots:
		for n in ["Places/CanalBelt/StudioDoor", "Places/CanalBelt/VenueDoor", "Places/CanalBelt/Start"]:
			if absf(t[0] - map.get_node(n).global_position.x) < 46.0:
				blocked.append(n)
	_check(spots.size() > 10 and blocked.is_empty(), "%d quay elms, none in front of a door %s" % [spots.size(), blocked])
	var floor: TileMapLayer = map.get_node("Road/StreetCollision")
	var used := floor.get_used_rect()
	var holes := []
	for x in range(used.position.x, used.end.x):
		if floor.get_cell_source_id(Vector2i(x, used.position.y)) == -1:
			holes.append(x * floor.tile_set.tile_size.x)
	_check(holes.is_empty(), "the street floor has no holes to fall through %s" % [holes])


## De Wallen between the old town and the canal belt: red at night, neon,
## night people who stand around and now and then offer something.
func _test_red_light() -> void:
	var zones: Node = map.get_node("Zones")
	var rl_zone = zones.get_node_or_null("RedLight")
	var old_town = zones.get_node("OldTown")
	var canal = zones.get_node("CanalBelt")
	_check(rl_zone != null and rl_zone.red_light and absf(rl_zone.span().x - old_town.span().y) < 1.0
		and absf(rl_zone.span().y - canal.span().x) < 1.0 and rl_zone.length >= 800.0,
		"the red light district lies between the old town and the canal belt, about two canal blocks long")
	var wallen := 0
	var neon := 0
	var kit: Dictionary = load("res://scripts/world/canal_kit.gd").NEON
	for b in map.get_node("Buildings").find_children("*", "", true, false):
		if b.has_method("kit_row") and b.kit and b.district == &"wallen":
			for it: Array in b.kit_row():
				wallen += 1
				neon += kit.get(it[0], []).size()
	_check(wallen >= 6 and neon >= 6, "the district is Wallen houses with red neon windows (%d houses, %d red windows)" % [wallen, neon])
	var night = map.get_node("RedLightNight")
	var day_cycle = load("res://scripts/world/day_cycle.gd")
	var was: float = day_cycle.night_now
	day_cycle.night_now = 1.0
	_check(night.signs.size() >= 3 and night.people.size() >= 6 and night.crowd() == 1.0,
		"at night: %d neon signs, %d night people out" % [night.signs.size(), night.people.size()])
	var seller: Dictionary = {}
	for p: Dictionary in night.people:
		if night.SELLERS[p.kind]:
			seller = p
			break
	map.leader.global_position.x = night.global_position.x + seller.x + 10.0
	night._offers()
	var bubbles: int = night._bubbles.size()
	_check(not seller.is_empty() and bubbles == 1 and seller.cooldown > 0.0 and not paused,
		"a seller near the band asks if they want something (a bubble, the game runs on)")
	night._offers()
	_check(night._bubbles.size() == bubbles, "and doesn't ask again right away")
	day_cycle.night_now = was
	for b: Array in night._bubbles:
		b[0].queue_free()
	night._bubbles.clear()
	map.leader.global_position = map.get_node("Places/CanalBelt/Start").global_position


func _test_day_night() -> void:
	var day = map.day
	_check(absf(game.time_of_day - 8.0) < 1.0, "a new day starts around 08:00 (%s)" % day.clock_text())
	var t0: float = game.time_of_day
	await _frames(120)
	_check(game.time_of_day > t0, "the clock runs on the map (%s)" % day.clock_text())
	_check(day._tint.color.is_equal_approx(Color.WHITE), "in the morning the street is in full daylight")
	day.set_hour(23.0)
	await _frames(2)
	var glows := root.get_tree().get_nodes_in_group(&"night_glow")
	var on := glows.filter(func(g): return g.visible and g.night > 0.99)
	_check(day._tint.color.get_luminance() < 0.45 and on.size() > 20,
		"at 23:00 it's dark and the lights are on (%d of %d glows)" % [on.size(), glows.size()])
	_check(map.hud._clock.text == "23:00", "the HUD shows the time (%s)" % map.hud._clock.text)
	day.set_hour(12.0)
	await _frames(2)
	_check(glows.all(func(g): return not g.visible), "at noon all the night lights are off")
	day.set_hour(8.0)
	map.hud.skip_requested.emit(4.0)           # the +4 button: sleep and wake up 4 hours later
	while day.sleeping:
		await _frames(1)
	_check(absf(game.time_of_day - 12.0) < 0.1, "+4: fade out, wake up at %s" % day.clock_text())
	day.set_hour(8.0)


func _test_switch_and_party() -> void:
	map = await _reload_map()
	var joep = map.leader
	Input.action_press("select_2")
	await _frames(2)
	Input.action_release("select_2")
	await _frames(2)
	_check(map.leader.profile.id == &"jay" and map.followers.has(joep) and map.followers.size() == 4,
		"2 on the map: Jay leads, Joep falls in behind (%s)" % map.leader.profile.id)
	Input.action_press("move_right")
	await _frames(90)
	Input.action_release("move_right")
	await _frames(60)
	_check(joep.global_position.x < map.leader.global_position.x - 10.0, "the old leader follows the new one")
	game.party.assign([&"joep", &"jay"])
	map = await _reload_map()
	var shown: Array = map.band.members.filter(func(m): return m.visible)
	_check(shown.size() == 2 and map.party.size() == 2 and map.followers.size() == 1,
		"only the party chosen at the base is on the map (%d)" % shown.size())
	Input.action_press("select_4")                 # The Germ stayed at the base: no switch
	await _frames(2)
	Input.action_release("select_4")
	await _frames(2)
	_check(map.party.has(map.leader), "you can only switch to members in the party")
	game.party.assign(game.MEMBERS)


func _reload_map():
	map.queue_free()
	await _frames(2)
	return await _load_map()


func _test_zoom_walking() -> void:
	_check(is_equal_approx(map.zoom, map.cam_cfg.zoom_walk), "standing still: close zoom (%.2f)" % map.zoom)
	Input.action_press("move_right")
	await _frames(180)
	Input.action_release("move_right")
	var walking: float = map.zoom
	# Camera was retuned: standing 1.5, full walk 1.333 (a 0.17 drop, not 0.25).
	_check(walking <= map.cam_cfg.zoom_walk_moving + 0.03 and walking < map.cam_cfg.zoom_walk - 0.08,
		"walking on: the zoom opens up with the tempo (%.2f)" % walking)
	await _frames(60)
	_check(map.zoom < map.cam_cfg.zoom_walk - 0.04 and map.zoom > walking - 0.02,
		"just stopped: no jump, the zoom eases in slowly (%.2f)" % map.zoom)
	await _frames(600)
	_check(map.zoom > map.cam_cfg.zoom_walk - 0.12, "after a while standing it's close again (%.2f)" % map.zoom)
	map._idle_cam = map.cam_cfg.idle_after + 0.1   # as if the band had stood here for 15 s
	var close: float = map.zoom
	await _frames(180)
	_check(map.zoom < close - 0.05 and absf(map._drift) > 0.5,
		"idle for long: the camera slowly zooms out and drifts (%.2f -> %.2f, drift %.1f)" % [close, map.zoom, map._drift])
	await _place_leader(_place("Start").global_position.x)
	await _frames(240)
	Input.action_press("move_right")              # hold left Shift: sprint
	Input.action_press("sprint")
	await _frames(60)
	var sprint_speed: float = map.leader.velocity.x
	Input.action_release("sprint")
	await _frames(60)
	var walk_speed: float = map.leader.velocity.x
	Input.action_release("move_right")
	_check(absf(sprint_speed - 2.0 * walk_speed) < 6.0, "Shift: sprinting is twice the walk (%.0f vs %.0f px/s)" % [sprint_speed, walk_speed])
	await _place_leader(_place("Start").global_position.x)
	await _frames(60)


func _test_band_line() -> void:
	var start = _place("Start")
	var leader = map.leader
	_check(absf(leader.global_position.x - start.global_position.x) < 1.0, "the band starts at the studio")
	Input.action_press("move_right")
	await _frames(40)
	Input.action_release("move_right")
	await _frames(10)
	var behind: bool = map.followers.all(func(f): return f.global_position.x < leader.global_position.x - 10.0)
	_check(behind, "the others follow behind the leader %s" % [map.followers.map(func(f): return int(f.global_position.x))])
	_check(map.followers.all(func(f): return f.global_position.x > start.global_position.x - 88.0), "the line moved along with the leader")
	_check(map.followers.any(func(f): return f.anim == &"walk"), "followers walk (not run) at walking pace")
	await _frames(150)                          # catch up and settle
	var settled := true
	for f in map.followers:
		var gap: float = map._fstate[f].gap
		settled = settled and absf(leader.global_position.x - f.global_position.x - gap) < 12.0
	_check(settled, "standing still, each keeps their own distance %s" % [map.followers.map(func(f): return int(leader.global_position.x - f.global_position.x))])
	await _frames(480)
	_check(map.followers.any(func(f): return f.anim == &"fidget"), "after a while standing, someone starts smoking, drinking or playing")


func _test_road_block() -> void:
	await _place_leader(map.foot_limit + 60.0)
	Input.action_press("move_left")
	await _frames(90)
	Input.action_release("move_left")
	_check(map.leader.global_position.x >= map.foot_limit - 0.5, "on foot the band stops at the motorway fork (x %.0f)" % map.leader.global_position.x)


func _test_geordie_quest() -> void:
	var geordie = _place("Geordie")
	_check(geordie.marker() == "!", "Geordie shows ! (has a quest)")
	await _place_leader(geordie.global_position.x)
	await _tap("interact")
	await _frames(2)
	_check(map.dialogue.is_open and map.talking, "E opens the dialogue with Geordie")
	var n := 0
	while map.dialogue.is_open and n < 30:
		await _tap("interact")
		await _frames(2)
		n += 1
	await _frames(25)
	_check(game.get_flag(&"quest_cafe", "") == "active" and not map.talking, "after the talk the quest is active")
	_check(map.hud._objective.text.contains("Café De Kat"), "HUD objective: %s" % map.hud._objective.text)


func _test_bikes() -> void:
	var bikes = _place("Bikes")
	await _place_leader(bikes.global_position.x)
	await _tap("interact")
	await _frames(2)
	# Members with bike art ride on their own sprite; the others on the placeholder bike.
	var all_ride: bool = map.band.members.all(func(m): return m.visible and m.sprite.sprite_frames.has_animation(&"bike_pedal"))
	_check(map.vehicle == bikes and all_ride, "E at the bikes: the whole band rides")
	Input.action_press("move_right")
	await _frames(90)
	var speed: float = bikes.velocity.x
	await _frames(90)
	var bike_zoom: float = map.zoom
	var lx: float = map.leader.global_position.x
	var gaps: Array = map.followers.map(func(f): return int(lx - f.global_position.x))
	_check(gaps.all(func(g): return g > 5 and g < 220) and map.followers.all(func(f): return f.anim == &"bike_pedal" or f.anim == &"bike_roll"),
		"riding: everyone on their own bike, a loose group behind the leader %s" % [gaps])
	Input.action_release("move_right")
	_check(absf(speed - bikes.top_speed()) < 5.0, "bikes ride at their top speed (%.0f px/s)" % speed)
	_check(bike_zoom < 2.25, "on the bikes at speed: the wider city view (%.2f)" % bike_zoom)
	await _frames(150)
	var spread: Array = map.followers.map(func(f): return int(map.leader.global_position.x - f.global_position.x))
	var sorted_gaps := spread.duplicate()
	sorted_gaps.sort()
	_check(sorted_gaps[0] > 8 and sorted_gaps[-1] - sorted_gaps[0] > 40, "stopped: they roll up and stop each at their own distance %s" % [spread])
	await _tap("interact")
	await _frames(2)
	_check(map.vehicle == null and bikes.visible and absf(bikes.global_position.x - map.leader.global_position.x) < 2.0,
		"E anywhere: off the bikes, they stay parked there")


func _test_van() -> void:
	var van = _place("Van")
	_check(map.at_parking(van.global_position.x), "the van waits at a P spot (x %.0f, by the storage)" % van.global_position.x)
	van.global_position.x = _place("ParkingStudio").global_position.x
	await _place_leader(van.global_position.x)
	await _tap("interact")
	await _frames(2)
	_check(map.vehicle == van and not map.leader.visible, "E at the van: the band drives off")
	_check(map.radio.is_on and map.hud._radio.text.begins_with("Radio: "), "the radio comes on in the van (%s)" % map.hud._radio.text)
	var station: int = map.radio.channel
	await _tap("use_item")
	_check(map.radio.channel != station and map.radio.CHANNELS[map.radio.channel].region == "NL", "R: next Dutch station (%s)" % map.radio.now_playing())
	Input.action_press("move_right")
	await _frames(150)
	var speed: float = van.velocity.x
	Input.action_release("move_right")
	_check(absf(speed - map.veh_cfg.city_speed) < 5.0, "in town the van keeps to the city limit (%.0f px/s)" % speed)
	_check(map.zoom >= map.cam_cfg.zoom_van - 0.01, "driving in town the view stays close (%.2f, never past %.1fx)" % [map.zoom, map.cam_cfg.zoom_van])
	await _frames(30)
	var coasted: float = van.velocity.x
	_check(coasted > speed * 0.6 and coasted < speed - 5.0, "letting go coasts (%.0f -> %.0f px/s)" % [speed, coasted])
	Input.action_press("move_left")
	await _frames(20)
	Input.action_release("move_left")
	_check(van.velocity.x < coasted - 150.0 and not van._skids.is_empty(), "steering back brakes hard, wheels lock: skid marks (%.0f px/s)" % van.velocity.x)
	var zoom_now: float = map.zoom
	await _frames(330)                          # let it roll to a stop and wait
	_check(map.zoom > zoom_now + 0.05, "standing still in the van: the camera eases in (%.2f -> %.2f)" % [zoom_now, map.zoom])
	var x_back: float = van.global_position.x
	van.global_position.x = 2500.0              # out of town, on the motorway, before the windmills end
	Input.action_press("move_right")
	await _frames(300)
	Input.action_release("move_right")
	_check(map.zoom >= map.cam_cfg.zoom_van - 0.02 and map.birds.active, "on the motorway the view still stays close (%.2f), birds" % map.zoom)
	_check(van.global_position.y > map.GROUND_Y + 2.0, "heading east on the motorway the van keeps to the lower lane (%.1f)" % (van.global_position.y - map.GROUND_Y))
	var zoom_before: float = map.zoom
	van.global_position.x = map.scenic_from - 1500.0   # past the last windmill: the road trip
	Input.action_press("move_left")
	await _frames(600)
	Input.action_release("move_left")
	_check(map.target_zoom_at(van.global_position.x) == map.cam_cfg.zoom_road and map.zoom < zoom_before - 0.2,
		"past the last windmill the road trip opens up, ever so slowly (%.2f -> %.2f)" % [zoom_before, map.zoom])
	_check(van.global_position.y < map.GROUND_Y - 2.0, "heading west the van keeps to the upper lane (%.1f)" % (van.global_position.y - map.GROUND_Y))
	van.global_position.x = x_back
	await _frames(240)
	await _frames(70)
	await _tap("interact")
	await _frames(2)
	_check(map.vehicle == van, "outside a P spot you can't get out (x %.0f)" % van.global_position.x)
	var spot = _place("ParkingVenue")
	van.global_position.x = spot.global_position.x
	await _frames(20)
	await _tap("interact")
	await _frames(2)
	_check(map.vehicle == null and map.leader.visible, "at the venue's P sign the band gets out")
	_check(absf(float(game.get_flag(&"van_x", 0.0)) - spot.global_position.x) < 1.0, "the van's parking spot is remembered")


func _test_package() -> void:
	var pkg = _place("PackageEast")
	var before: int = game.coins
	await _place_leader(pkg.global_position.x - 20.0)
	Input.action_press("move_right")
	await _frames(15)
	Input.action_release("move_right")
	_check(game.coins == before + 10 and pkg.collected, "a package gives 10 coins")


func _test_return_from_gig() -> void:
	# As if the band just walked out of the level's last door.
	map.queue_free()
	await _frames(2)
	game.set_flag(&"cafe_finished")
	router.pending_spawn = &"VenueDoor"
	map = await _load_map()
	var door = _place("VenueDoor")
	var spot = _place("ParkingVenue")
	_check(absf(map.leader.global_position.x - door.global_position.x) < 1.0, "back from the gig: the band stands at the venue door")
	_check(absf(_place("Van").global_position.x - spot.global_position.x) < 1.0, "the van is where it was parked")
	_check(_place("PackageEast").collected, "a collected package stays collected")
	var geordie = _place("Geordie")
	_check(geordie.marker() == "?", "Geordie shows ? (gig done)")
	await _place_leader(geordie.global_position.x)
	await _tap("interact")
	var n := 0
	while map.dialogue.is_open and n < 30:
		await _frames(2)
		await _tap("interact")
		n += 1
	await _frames(25)
	_check(game.get_flag(&"quest_cafe", "") == "done" and map.hud._objective.text == "Tour day 1 complete!",
		"talk to Geordie: Tour day 1 complete!")


func _test_studio_door() -> void:
	var door = _place("StudioDoor")
	var target := [""]
	router.transition_started.connect(func(p): target[0] = p, CONNECT_ONE_SHOT)
	await _place_leader(door.global_position.x)
	await _tap("interact")
	_check(target[0] == "res://scenes/levels/abilities_test.tscn", "the studio door leads into the abilities level")
	await _frames(60)
	# The transition loads the level on top in --script mode; start fresh.
	for n in root.get_children():
		if n.name != "Game" and n.name != "SceneRouter" and n.name != "Audio" and n != map:
			n.queue_free()
	router.is_transitioning = false
	await _frames(5)


func _test_storage_gate() -> void:
	var gate = _place("StorageGate")
	_check(absf(_place("Geordie").global_position.x - gate.global_position.x) < 160.0, "Geordie waits in front of the storage")
	var target := [""]
	router.transition_started.connect(func(p): target[0] = p, CONNECT_ONE_SHOT)
	await _place_leader(gate.global_position.x)
	await _tap("interact")
	_check(not gate.is_open() and map.talking and target[0] == "", "locked gate: Joep hacks the keypad instead of entering")
	var n := 0
	while map.talking and n < 400:
		await physics_frame
		n += 1
	_check(gate.is_open() and not map.talking, "hack complete: the gate is open (%d frames)" % n)
	await _frames(25)
	await _tap("interact")
	_check(target[0] == "res://scenes/levels/base.tscn", "the open gate leads into the band's base")
	await _frames(60)
	for node in root.get_children():
		if node.name != "Game" and node.name != "SceneRouter" and node.name != "Audio" and node != map:
			node.queue_free()
	router.is_transitioning = false
	# The base's door leads back out to the storage gate.
	map.queue_free()
	await _frames(2)
	router.pending_spawn = &"StorageGate"
	map = await _load_map()
	gate = _place("StorageGate")
	_check(absf(map.leader.global_position.x - gate.global_position.x) < 1.0, "back out of the base: at the storage gate")


func _test_venue_door() -> void:
	var door = _place("VenueDoor")
	var target := [""]
	router.transition_started.connect(func(p): target[0] = p, CONNECT_ONE_SHOT)
	await _place_leader(door.global_position.x)
	await _tap("interact")
	_check(target[0] == "res://scenes/levels/venue_puzzle.tscn", "the venue door leads into the puzzle level")


# --- Helpers ---------------------------------------------------------------

func _load_map():
	var m = load("res://scenes/world/world_map.tscn").instantiate()
	root.add_child(m)
	await _frames(5)
	return m


func _place_leader(x: float) -> void:
	_release_all()
	map.place_band(x, 1.0)
	await _frames(25)                       # interact cooldown + area overlap


func _tap(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _release_all() -> void:
	for a in ACTIONS:
		Input.action_release(a)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	print(("  ok   " if ok else "  FAIL ") + label)
	if not ok:
		failures += 1


## A place on the map by name (they sit in district folders under Places).
func _place(node_name: String):
	return map.get_node("Places").find_child(node_name, true, false)
