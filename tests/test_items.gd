extends SceneTree
## Headless checks for M7 items on the test level (exits 1 on failure): pickup,
## give, full hands, drop, use, slot cycling, keycard door, rolling papers lure.
## Run: Summer --headless --path . --script res://tests/test_items.gd
## Game classes stay untyped: naming them here would compile them before the
## autoloads exist in --script mode.

const EXPECTED_CHECKS := 23
const GY := 288.0
const JOEP := 0
const JAY := 1
const GERM := 3
const GEOFF := 4
const ACTIONS := ["move_left", "move_right", "jump", "interact", "use_item", "give", "drop_item", "item_next"]

var failures := 0
var checks := 0
var deaths := []
var level
var band
var BEER


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	BEER = load("res://resources/items/beer.tres")
	level = load("res://scenes/levels/level_test.tscn").instantiate()
	root.add_child(level)
	await _frames(5)
	band = level.band
	level.member_died.connect(func(m, c): deaths.append("%s (%s)" % [m.profile.display_name, c]))

	await _test_pickup_give_drop()
	await _test_use_and_slots()
	await _test_follower_avoids_hazard()
	await _test_keycard()
	await _test_rolling_papers()
	_check(deaths.is_empty(), "nobody died during the item tests %s" % [deaths])

	if checks != EXPECTED_CHECKS:
		print("  FAIL ran %d of %d checks (script error?)" % [checks, EXPECTED_CHECKS])
		failures += 1
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _test_pickup_give_drop() -> void:
	var beer = level.get_node("Rooms/Room1/Beer")
	var joep = await _use(JOEP, beer.global_position + Vector2(-24, 0))
	Input.action_press("move_right")
	await _frames(12)
	Input.action_release("move_right")
	_check(joep.beers == 1 and beer.collected, "Joep picks up the beer")
	# Give: nobody within 1 tile -> keeps it.
	await _tap("give")
	_check(joep.beers == 1, "no one within a tile: Joep keeps the beer")
	var jay = band.members[JAY]
	_place(jay, joep.global_position + Vector2(14, 0))
	await _frames(2)
	await _tap("give")
	_check(joep.beers == 0 and jay.beers == 1, "F hands the beer to Jay standing next to Joep")
	# Full hands: 3 slots.
	jay.inventory.clear()
	for i in 3:
		jay.add_item(BEER)
	_check(not jay.add_item(BEER) and jay.beers == 3, "3 slots: a 4th item doesn't fit")
	# Drop, and don't instantly pick it back up.
	jay = await _use(JAY, Vector2(300, GY))
	await _tap("drop_item")
	await _frames(10)
	_check(jay.beers == 2, "V drops the beer (and Jay doesn't grab it straight back)")
	await _frames(70)
	_check(jay.beers == 3, "after a moment Jay can pick it up again")
	jay.inventory.clear()


func _test_use_and_slots() -> void:
	var germ = await _use(GERM, Vector2(300, GY))
	germ.add_item(BEER)
	germ.health.restore(2)
	await _tap("use_item")
	_check(germ.health.hp == 3 and germ.beers == 0, "The Germ drinks with R (use item): +1 HP")
	germ.inventory.clear()
	germ.add_item(BEER)
	var sel: int = germ.inventory.selected
	await _tap("item_next")
	_check(germ.inventory.selected == (sel + 1) % 3, "T selects the next slot")
	_check(germ.inventory.current_index() == 0, "an empty selected slot falls back to the first item")
	germ.inventory.clear()


func _test_follower_avoids_hazard() -> void:
	# Spikes at x 240..264 in room 1: Geoff follows the papers but won't walk onto them.
	var joep = await _use(JOEP, Vector2(330, GY))
	var geoff = band.members[GEOFF]
	_place(geoff, Vector2(180, GY))
	joep.add_item(load("res://resources/items/rolling_papers.tres"))
	await _frames(90)
	_check(band.following.get(geoff) == joep and geoff.global_position.x < 236.0,
		"a following Geoff stops in front of the spikes (x %.0f)" % geoff.global_position.x)
	_check(geoff.health.hp == 1, "... and doesn't get hurt")
	joep.inventory.clear()
	await _frames(2)


func _test_keycard() -> void:
	# Bring the whole band to room 3 through the doors.
	await _whole_band_through("Rooms/Room1/DoorToRoom2")
	await _whole_band_through("Rooms/Room2/DoorToRoom3")
	var r3 = level.get_node("Rooms/Room3")
	var locked = level.get_node("Rooms/Room3/LockedDoor")
	var geoff = await _use(GEOFF, locked.global_position)
	await _tap("interact")
	await _await_idle()
	_check(locked.locked and level.room_of_member(geoff) == r3, "the red door stays shut without the keycard")
	# Joep fetches the card from the 3-tile ledge and gives it to Geoff.
	var card = level.get_node("Rooms/Room3/Keycard")
	var joep = await _use(JOEP, card.global_position + Vector2(-10, -1))
	await _frames(5)
	_check(joep.inventory.has(&"keycard_red") and card.collected, "Joep grabs the keycard on the ledge")
	_place(joep, Vector2(2620, GY))
	_place(geoff, Vector2(2634, GY))
	await _frames(3)
	await _tap("give")
	_check(geoff.inventory.has(&"keycard_red"), "Joep gives the keycard to Geoff")
	geoff = await _use(GEOFF, locked.global_position)
	await _tap("interact")
	await _await_idle()
	var r4 = level.get_node("Rooms/Room4")
	_check(not locked.locked and level.room_of_member(geoff) == r4, "Geoff opens the red door with the keycard and goes through")
	_check(not geoff.inventory.has(&"keycard_red"), "the keycard is used up")
	locked.reset_state()
	_check(not locked.locked, "a door opened with a key stays open after a room reset")


func _test_rolling_papers() -> void:
	var r4 = level.get_node("Rooms/Room4")
	var locked = level.get_node("Rooms/Room3/LockedDoor")
	var joep = await _use(JOEP, locked.global_position)
	await _tap("interact")                  # Joep follows Geoff into room 4
	await _await_idle()
	var geoff = band.members[GEOFF]
	var papers = level.get_node("Rooms/Room4/RollingPapers")
	_place(geoff, Vector2(3420, GY))
	joep = await _use(JOEP, papers.global_position + Vector2(-16, 0))
	Input.action_press("move_right")
	await _frames(8)
	Input.action_release("move_right")
	_check(joep.inventory.has(&"rolling_papers") and band.following.get(geoff) == joep, "Joep carries the rolling papers: Geoff follows him")
	# Joep runs to the exit over the step and the gap; Geoff must keep up.
	await _run_and_jump(joep, [3556.0, 3722.0], 3950.0, 240)
	var caught_up := false
	for i in 360:
		await physics_frame
		if absf(geoff.global_position.x - joep.global_position.x) < 30.0 and geoff.is_on_floor():
			caught_up = true
			break
	_check(caught_up and geoff.global_position.x > 3790.0 and not geoff.is_dead,
		"Geoff follows over the step and the gap (x %.0f)" % geoff.global_position.x)
	var exit = level.get_node("Rooms/Room4/LevelExit")
	_place(joep, exit.global_position)
	await _frames(60)
	_check(level.door_group(joep).has(geoff), "a following Geoff comes along through the door")
	await _tap("drop_item")
	await _frames(5)
	_check(not band.following.has(geoff), "drop the papers: Geoff stops following")
	await _frames(20)
	_check(r4.has_point(geoff.global_position), "Geoff stays in Backstage")


# --- Helpers ---------------------------------------------------------------

func _whole_band_through(door_path: String) -> void:
	var door = level.get_node(door_path)
	for i in band.members.size():
		_place(band.members[i], door.global_position + Vector2(-i * 14, 0))
	band.switch_to(0, true)
	await _frames(3)
	level.go_through(door, band.members[0])
	await _await_idle()


func _use(index: int, pos: Vector2):
	_release_all()
	await _await_idle()
	band.switch_to(index, true)
	var m = band.members[index]
	_place(m, pos)
	await _frames(3)
	return m


func _place(m, pos: Vector2) -> void:
	m.global_position = pos
	m.velocity = Vector2.ZERO


func _run_and_jump(m, jumps: Array, end_x: float, max_frames: int) -> bool:
	var todo := jumps.duplicate()
	var hold := 0
	Input.action_press("move_right")
	var ok := false
	for i in max_frames:
		await physics_frame
		if hold > 0:
			hold -= 1
			if hold == 0:
				Input.action_release("jump")
		if not todo.is_empty() and m.global_position.x >= todo[0] and m.is_on_floor():
			todo.pop_front()
			Input.action_press("jump")
			hold = 20
		if m.global_position.x >= end_x and m.is_on_floor():
			ok = true
			break
	_release_all()
	return ok


func _await_idle() -> void:
	var n := 0
	while (level.is_busy or paused) and n < 600:
		await physics_frame
		n += 1
	await _frames(2)


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
