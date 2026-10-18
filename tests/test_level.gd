extends SceneTree
## Headless checks for the M5 level framework (exits 1 on failure): damage and
## i-frames, every death type with respawn under 1.5 s, room reset, checkpoints,
## doors, bouncer, locked door, level exit.
## Run: Summer --headless --path . --script res://tests/test_level.gd
## Game classes stay untyped: naming them here would compile them before the
## autoloads exist in --script mode.

const EXPECTED_CHECKS := 40
const GY := 288.0
const MAX_RESPAWN_TIME := 1.5

var failures := 0
var checks := 0
var level
var band


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	level = load("res://scenes/levels/level_test.tscn").instantiate()
	root.add_child(level)
	await _frames(5)
	band = level.band

	await _test_start()
	await _test_spikes_and_iframes()
	await _test_rat()
	await _test_death_by_damage_and_reset()
	await _test_checkpoint()
	await _test_door()
	await _test_pit()
	await _test_electric()
	await _test_bouncer()
	await _test_locked_and_exit()

	if checks != EXPECTED_CHECKS:
		print("  FAIL ran %d of %d checks (script error?)" % [checks, EXPECTED_CHECKS])
		failures += 1
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _test_start() -> void:
	var r1 = level.get_node("Rooms/Room1")
	_check(level.current_room == r1, "starts in room 1")
	_check(band.camera.limit_right == r1.bounds.end.x, "camera clamped to room 1 bounds")
	_check(band.members.all(func(m): return r1.has_point(m.global_position)), "whole band spawned in room 1")


func _test_spikes_and_iframes() -> void:
	var joep = band.members[0]
	_place(joep, Vector2(258, GY - 2))
	await _frames(4)
	_check(joep.health.hp == 2, "spikes take 1 HP (hp %d)" % joep.health.hp)
	_check(joep.velocity.y < 0.0 and joep.health.is_invulnerable, "knockback + i-frames after a hit")
	_place(joep, Vector2(258, GY - 2))
	await _frames(20)
	_check(joep.health.hp == 2, "no damage again during i-frames")
	await _frames(45)
	_place(joep, Vector2(258, GY - 2))
	await _frames(4)
	_check(joep.health.hp == 1, "damage again after i-frames end")
	_place(joep, Vector2(150, GY))
	await _frames(70)


func _test_rat() -> void:
	var jay = band.members[1]
	var rat = level.get_node("Rooms/Room1/Rat")
	_place(jay, rat.global_position + Vector2(0, -1))
	await _frames(3)
	_check(jay.health.hp == 2, "rat bite takes 1 HP")
	_place(jay, Vector2(170, GY))
	await _frames(5)


func _test_death_by_damage_and_reset() -> void:
	var rat = level.get_node("Rooms/Room1/Rat")
	var rat_start: Vector2 = Vector2(21 * 24 + 12, GY)
	_check(rat.global_position.distance_to(rat_start) > 4.0, "rat has patrolled away from its start")
	var geoff = band.members[4]
	var cause := [&""]
	level.member_died.connect(func(_m, c): cause[0] = c, CONNECT_ONE_SHOT)
	_place(geoff, Vector2(258, GY - 2))
	var t := await _await_respawn()
	_check(cause[0] == &"hurt", "Geoff (1 HP) dies from one spike hit")
	_check(t <= MAX_RESPAWN_TIME, "respawn in %.2f s (<= %.1f)" % [t, MAX_RESPAWN_TIME])
	_check(not paused and not level.is_busy, "game unpaused after respawn")
	var hps: Array = band.members.map(func(m): return m.health.hp)
	_check(hps == [3, 3, 3, 3, 1], "HP back to checkpoint values (Joep, Jay healed) %s" % [hps])
	_check(band.members.all(func(m): return absf(m.global_position.x - 108.0) < 40.0 and not m.is_dead), "band back at the start in a row")
	# It patrols on during the 0.35 s fade-in (40 px/s).
	_check(rat.global_position.distance_to(rat_start) < 18.0, "room reset: rat back at its start (%.0f px off)" % rat.global_position.distance_to(rat_start))


func _test_checkpoint() -> void:
	var cp = level.get_node("Rooms/Room1/Checkpoint")
	_place(band.active, cp.global_position)
	await _frames(3)
	_check(cp.is_current, "touching the flag activates the checkpoint")
	_place(band.members[4], Vector2(258, GY - 2))
	await _await_respawn()
	_check(absf(band.active.global_position.x - cp.global_position.x) < 40.0, "respawn at the checkpoint, not the room start")


func _test_door() -> void:
	var r1 = level.get_node("Rooms/Room1")
	var r2 = level.get_node("Rooms/Room2")
	var door = level.get_node("Rooms/Room1/DoorToRoom2")
	var entry = level.get_node("Rooms/Room2/DoorToRoom1")
	band.switch_to(0, true)
	# Joep alone at the door, the others back at the checkpoint (> 3 tiles away).
	for i in band.members.size():
		_place(band.members[i], Vector2(door.global_position.x if i == 0 else 700 + i * 10, GY))
	await _frames(3)
	_check(level.door_group(band.active).size() == 1 and door._prompt_label.text.ends_with("Joep alone"),
		"door prompt: 'Joep alone' when the others are far")
	var others_before: Array = band.members.slice(1).map(func(m): return m.global_position)
	await _tap("interact")
	await _await_idle()
	_check(r2.has_point(band.members[0].global_position) and level.current_room == r2, "Joep goes through alone")
	_check(band.members.slice(1).map(func(m): return m.global_position) == others_before, "the others stay in room 1")
	_check(band.camera.limit_left == r2.bounds.position.x, "camera clamped to room 2 bounds")

	# Switching to someone in room 1 cuts the camera back there.
	band.switch_to(1, true)
	await _frames(2)
	_check(level.current_room == r1 and band.camera.limit_left == r1.bounds.position.x, "switching to Jay shows room 1")
	band.switch_to(0, true)
	await _frames(2)
	_check(level.current_room == r2, "switching back to Joep shows room 2")

	# Gather only calls members in the same room.
	await _tap("gather")
	await _frames(30)
	_check(band.members.slice(1).map(func(m): return m.global_position) == others_before, "gather doesn't pull members from another room")

	# A solo death resets only Joep's room; the others don't move.
	_place(band.members[0], Vector2(61 * 24 + 12, 200))
	await _await_respawn()
	_check(absf(band.members[0].global_position.x - entry.global_position.x) < 20.0, "Joep respawns at the room 2 entry")
	_check(band.members.slice(1).map(func(m): return m.global_position) == others_before, "members in room 1 are untouched by Joep's death")

	# The four in room 1 stand together at the door: they all go.
	band.switch_to(1, true)
	for i in range(1, 5):
		_place(band.members[i], door.global_position + Vector2(-(i - 1) * 16, 0))
	await _frames(3)
	_check(door._prompt_label.text.ends_with("group of 4"), "door prompt: 'group of 4' when the room's members are together")
	await _tap("interact")
	await _await_idle()
	_check(band.members.all(func(m): return r2.has_point(m.global_position)), "the group of 4 joins Joep: whole band in room 2")
	band.switch_to(0, true)


func _test_pit() -> void:
	var cause := [&""]
	level.member_died.connect(func(_m, c): cause[0] = c, CONNECT_ONE_SHOT)
	_place(band.active, Vector2(61 * 24 + 12, 200))
	var t := await _await_respawn()
	var entry = level.get_node("Rooms/Room2/DoorToRoom1")
	_check(cause[0] == &"pit", "falling into the pit kills")
	_check(t <= MAX_RESPAWN_TIME and absf(band.active.global_position.x - entry.global_position.x) < 40.0,
		"respawn at the room 2 entry in %.2f s" % t)


func _test_electric() -> void:
	var cause := [&""]
	level.member_died.connect(func(_m, c): cause[0] = c, CONNECT_ONE_SHOT)
	_place(band.active, Vector2(72 * 24 + 12, GY - 2))
	var t := await _await_respawn()
	_check(cause[0] == &"electric" and t <= MAX_RESPAWN_TIME, "electric floor kills at full HP (respawn %.2f s)" % t)


func _test_bouncer() -> void:
	var bouncer = level.get_node("Rooms/Room2/Bouncer")
	var joep = band.members[0]
	band.switch_to(0, true)
	_place(joep, bouncer.global_position + Vector2(-20, 0))
	await _frames(3)
	await _tap("interact")
	_check(not bouncer.persuaded, "the bouncer turns Joep away")
	Input.action_press("move_right")
	await _frames(30)
	Input.action_release("move_right")
	_check(joep.global_position.x < bouncer.global_position.x, "the bouncer blocks the doorway")
	var geoff = band.members[4]
	band.switch_to(4, true)
	_place(geoff, bouncer.global_position + Vector2(-20, 0))
	await _frames(3)
	await _tap("interact")
	_check(bouncer.persuaded, "Geoff talks the bouncer aside")
	Input.action_press("move_right")
	await _frames(40)
	Input.action_release("move_right")
	_check(geoff.global_position.x > bouncer.global_position.x + 10.0, "Geoff walks through the doorway")
	_place(geoff, Vector2(72 * 24 + 12, GY - 2))   # die on the electric floor
	await _await_respawn()
	_check(not bouncer.persuaded, "room reset: the bouncer blocks again")


func _test_locked_and_exit() -> void:
	band.switch_to(0, true)
	var door = level.get_node("Rooms/Room2/DoorToRoom3")
	var bouncer = level.get_node("Rooms/Room2/Bouncer")
	bouncer.persuade()
	for i in band.members.size():
		_place(band.members[i], door.global_position + Vector2(-i * 14, 0))
	await _frames(3)
	_check(door._prompt_label.text.ends_with("whole band"), "door prompt: 'whole band' when all 5 stand together")
	await _tap("interact")
	await _await_idle()
	var r3 = level.get_node("Rooms/Room3")
	_check(level.current_room == r3, "on to room 3")
	var locked = level.get_node("Rooms/Room3/LockedDoor")
	_place(band.active, locked.global_position)
	await _frames(3)
	await _tap("interact")
	await _frames(40)
	_check(level.current_room == r3 and locked.locked, "a locked door doesn't open")
	var exit = level.get_node("Rooms/Room3/LevelExit")
	var target := [""]
	root.get_node("SceneRouter").transition_started.connect(func(p): target[0] = p, CONNECT_ONE_SHOT)
	_place(band.active, exit.global_position)
	await _frames(3)
	await _tap("interact")
	_check(target[0] == "res://scenes/dev/movement_test.tscn", "level exit loads the next scene")


# --- Helpers ---------------------------------------------------------------

func _place(m, pos: Vector2) -> void:
	m.global_position = pos
	m.velocity = Vector2.ZERO


## Frames until the death sequence finishes; returns seconds from now.
func _await_respawn() -> float:
	var n := 0
	while not level.is_busy and n < 120:
		await physics_frame
		n += 1
	var start := Time.get_ticks_msec()
	await _await_idle()
	return (Time.get_ticks_msec() - start) / 1000.0


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


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	print(("  ok   " if ok else "  FAIL ") + label)
	if not ok:
		failures += 1
