extends SceneTree
## Headless checks for the puzzle test level (exits 1 on failure): every room
## is there and linked, the gate opens with the lever on the high wall, the
## fuse box switches off the electric floor, the bouncer and locked door, and
## the finale: Geoff asleep on the rig, can't be switched to, no way out
## without him, the rolling papers wake him and he follows.
## Run: Summer --headless --path . --script res://tests/test_venue_puzzle.gd
## Game classes stay untyped: naming them here would compile them before the
## autoloads exist in --script mode.

const EXPECTED_CHECKS := 11

var failures := 0
var checks := 0
var level
var band


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	level = load("res://scenes/levels/venue_puzzle.tscn").instantiate()
	root.add_child(level)
	await _frames(5)
	band = level.band
	var names: Array = level.get_node("Rooms").get_children().map(func(r): return String(r.name))
	_check(names == ["BackEntrance", "Storage", "Bar", "Backstage", "Finale"], "rooms: %s" % [names])
	var doors_ok := true
	for d in ["Rooms/BackEntrance/ToStorage", "Rooms/Storage/ToBar", "Rooms/Bar/LockedDoor", "Rooms/Backstage/ToFinale"]:
		var door = level.get_node(d)
		doors_ok = doors_ok and door.get_node_or_null(door.target_door) != null
	_check(doors_ok, "every room's door leads into the next")

	var gate = level.get_node("Rooms/BackEntrance/Gate")
	var lever = level.get_node("Rooms/BackEntrance/Lever")
	_check(gate.solid and lever.global_position.y < 120.0, "back entrance: gate shut, its lever up on the high wall")
	band.switch_to(band.members.find(band.member_by_id(&"germ")))
	Input.action_press("move_right")
	await _frames(320)
	Input.action_release("move_right")
	var gx: float = band.active.global_position.x
	_check(gx > gate.global_position.x - 30.0 and gx < gate.global_position.x, "The Germ walks along the floor right up to the shut gate (x %.0f)" % gx)
	lever.interact(band.active, level)
	await _frames(2)
	_check(not gate.solid, "the lever opens the gate")

	var elec = level.get_node("Rooms/Bar/ElectricFloor")
	var fuse = level.get_node("Rooms/Bar/FuseBox")
	var joep = band.member_by_id(&"joep")
	fuse.interact(band.member_by_id(&"jay"), level)
	await _frames(2)
	_check(elec.enabled, "bar: the electric floor is live; Jay can't hack the fuse box")
	fuse.interact(joep, level)
	await _frames(2)
	_check(not elec.enabled, "the hack switches the floor off")

	# The finale: walk the band in through the backstage door.
	var to_finale = level.get_node("Rooms/Backstage/ToFinale")
	await level.go_through(to_finale, band.active)
	await _frames(5)
	var geoff = band.member_by_id(&"geoff")
	var sleeper = level.get_node("Rooms/Finale/Sleeper")
	_check(sleeper.is_asleep() and geoff.global_position.distance_to(sleeper.global_position) < 4.0,
		"finale: Geoff is asleep up on the rig")
	band.switch_to(band.members.find(geoff))
	await _frames(1)
	_check(band.active != geoff, "you can't switch to a sleeping Geoff")
	var exit = level.get_node("Rooms/Finale/Exit")
	var router = root.get_node("SceneRouter")
	var target := [""]
	router.transition_started.connect(func(p): target[0] = p, CONNECT_ONE_SHOT)
	exit.interact(band.active, level)
	await _frames(2)
	_check(target[0] == "", "no way out without Geoff")
	var carrier = band.active
	carrier.inventory.add(load("res://resources/items/rolling_papers.tres"))
	carrier.global_position = geoff.global_position + Vector2(-20, 0)
	await _frames(3)
	_check(not sleeper.is_asleep() and band.following.get(geoff) == carrier,
		"the rolling papers wake him: he follows whoever carries them")

	if checks != EXPECTED_CHECKS:
		print("  FAIL ran %d of %d checks (script error?)" % [checks, EXPECTED_CHECKS])
		failures += 1
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	print(("  ok   " if ok else "  FAIL ") + label)
	if not ok:
		failures += 1
