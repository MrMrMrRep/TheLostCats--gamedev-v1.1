extends SceneTree
## Headless checks for the M8 world map (exits 1 on failure): band line,
## road blocks, Geordie's quest, bikes, van + parking, packages, coming back
## from the gig, the venue door.
## Run: Summer --headless --path . --script res://tests/test_world.gd
## Game classes stay untyped: naming them here would compile them before the
## autoloads exist in --script mode.

const EXPECTED_CHECKS := 38
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

	await _test_zoom_walking()
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

	if checks != EXPECTED_CHECKS:
		print("  FAIL ran %d of %d checks (script error?)" % [checks, EXPECTED_CHECKS])
		failures += 1
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _test_zoom_walking() -> void:
	_check(is_equal_approx(map.zoom, 3.0), "zoom 3x at the studio (%.2f)" % map.zoom)
	await _place_leader(2600.0)
	await _frames(240)
	_check(absf(map.zoom - 2.0) < 0.05, "zoom 2x in the city (%.2f)" % map.zoom)
	await _place_leader(map.get_node("Places/Start").global_position.x)
	await _frames(240)


func _test_band_line() -> void:
	var start = map.get_node("Places/Start")
	var leader = map.leader
	_check(absf(leader.global_position.x - start.global_position.x) < 1.0, "the band starts at the studio")
	Input.action_press("move_right")
	await _frames(40)
	Input.action_release("move_right")
	await _frames(10)
	var xs: Array = [leader.global_position.x]
	for f in map.followers:
		xs.append(f.global_position.x)
	var ordered := true
	for i in xs.size() - 1:
		var gap: float = xs[i] - xs[i + 1]
		ordered = ordered and gap > 10.0 and gap < 22.0
	_check(ordered, "the others trail behind in a line, ~16 px apart %s" % [xs.map(func(x): return int(x))])
	_check(map.followers.all(func(f): return f.global_position.x > start.global_position.x - 70.0), "the line moved along with the leader")


func _test_road_block() -> void:
	await _place_leader(140.0)
	Input.action_press("move_left")
	await _frames(60)
	Input.action_release("move_left")
	_check(map.leader.global_position.x > 40.0, "the west road block stops the band (x %.0f)" % map.leader.global_position.x)


func _test_geordie_quest() -> void:
	var geordie = map.get_node("Places/Geordie")
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
	var bikes = map.get_node("Places/Bikes")
	await _place_leader(bikes.global_position.x)
	await _tap("interact")
	await _frames(2)
	_check(map.vehicle == bikes and map._bikes[map.leader].visible, "E at the bikes: the whole band rides")
	Input.action_press("move_right")
	await _frames(90)
	var speed: float = bikes.velocity.x
	Input.action_release("move_right")
	_check(absf(speed - WALK_SPEED * 1.6) < 5.0, "bikes go 1.6x walking speed (%.0f px/s)" % speed)
	await _frames(30)
	await _tap("interact")
	await _frames(2)
	_check(map.vehicle == null and bikes.visible and absf(bikes.global_position.x - map.leader.global_position.x) < 2.0,
		"E anywhere: off the bikes, they stay parked there")


func _test_van() -> void:
	var van = map.get_node("Places/Van")
	_check(not map.in_town(van.global_position.x), "the van waits out of town (x %.0f)" % van.global_position.x)
	van.global_position.x = map.get_node("Places/ParkingStudio").global_position.x
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
	_check(absf(speed - WALK_SPEED * 2.2) < 5.0, "the van goes 2.2x walking speed (%.0f px/s)" % speed)
	await _frames(30)
	var coasted: float = van.velocity.x
	_check(coasted > speed * 0.6 and coasted < speed - 5.0, "letting go coasts (%.0f -> %.0f px/s)" % [speed, coasted])
	Input.action_press("move_left")
	await _frames(20)
	Input.action_release("move_left")
	_check(van.velocity.x < coasted - 200.0, "steering back brakes hard (%.0f px/s)" % van.velocity.x)
	_check(map.target_zoom_at(van.global_position.x) == 1.0 and map.zoom < 1.8, "driving in town: zoom slowly eases out toward 1x (%.2f)" % map.zoom)
	var x_back: float = van.global_position.x
	var zoom_before: float = map.zoom
	van.global_position.x = 700.0               # out of town, on the dike road
	await _frames(240)
	_check(map.target_zoom_at(700.0) == 0.5 and map.zoom < zoom_before - 0.2 and map.birds.active,
		"on the road outside town: zoom slowly out toward 0.5x (%.2f -> %.2f), birds" % [zoom_before, map.zoom])
	van.global_position.x = x_back
	await _frames(240)
	await _frames(70)
	await _tap("interact")
	await _frames(2)
	_check(map.vehicle == van, "outside a P spot you can't get out (x %.0f)" % van.global_position.x)
	var spot = map.get_node("Places/ParkingVenue")
	van.global_position.x = spot.global_position.x
	await _frames(20)
	await _tap("interact")
	await _frames(2)
	_check(map.vehicle == null and map.leader.visible, "at the venue's P sign the band gets out")
	_check(absf(float(game.get_flag(&"van_x", 0.0)) - spot.global_position.x) < 1.0, "the van's parking spot is remembered")


func _test_package() -> void:
	var pkg = map.get_node("Places/PackageEast")
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
	var door = map.get_node("Places/VenueDoor")
	var spot = map.get_node("Places/ParkingVenue")
	_check(absf(map.leader.global_position.x - door.global_position.x) < 1.0, "back from the gig: the band stands at the venue door")
	_check(absf(map.get_node("Places/Van").global_position.x - spot.global_position.x) < 1.0, "the van is where it was parked")
	_check(map.get_node("Places/PackageEast").collected, "a collected package stays collected")
	var geordie = map.get_node("Places/Geordie")
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
	var door = map.get_node("Places/StudioDoor")
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
	var gate = map.get_node("Places/StorageGate")
	_check(absf(map.get_node("Places/Geordie").global_position.x - gate.global_position.x) < 160.0, "Geordie waits in front of the storage")
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
	_check(target[0] == "res://scenes/levels/abilities_test.tscn", "the open gate leads into the level")
	await _frames(60)
	for node in root.get_children():
		if node.name != "Game" and node.name != "SceneRouter" and node.name != "Audio" and node != map:
			node.queue_free()
	router.is_transitioning = false
	# The level's exit names the studio door; the band comes out where it went in.
	map.queue_free()
	await _frames(2)
	router.pending_spawn = &"StudioDoor"
	map = await _load_map()
	gate = map.get_node("Places/StorageGate")
	_check(absf(map.leader.global_position.x - gate.global_position.x) < 1.0, "back out of the level: at the storage gate, not the studio")


func _test_venue_door() -> void:
	var door = map.get_node("Places/VenueDoor")
	var target := [""]
	router.transition_started.connect(func(p): target[0] = p, CONNECT_ONE_SHOT)
	await _place_leader(door.global_position.x)
	await _tap("interact")
	_check(target[0] == "res://scenes/levels/level_test.tscn", "the venue door leads into the level")


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
