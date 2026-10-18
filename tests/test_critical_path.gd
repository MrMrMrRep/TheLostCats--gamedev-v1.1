extends SceneTree
## Can every band member get through the test level on their own? Each member
## runs right, jumping at fixed points like a player would, and must reach the
## end of each stretch alive and unhurt. Catches levels nobody but Joep/Nikki
## can finish (exits 1 on failure).
## Run: Summer --headless --path . --script res://tests/test_critical_path.gd
## Game classes stay untyped: naming them here would compile them before the
## autoloads exist in --script mode.

const GY := 288.0
const JUMP_HOLD_FRAMES := 20
## Stretches of the critical path: start x, x positions to jump at, x to reach.
const STRETCHES := [
	{"name": "room 1: spikes, rat pen walls", "start": 150.0, "jumps": [226.0, 366.0, 606.0], "end": 700.0},
	{"name": "room 2: pit with island, electric catwalk", "start": 1300.0, "jumps": [1428.0, 1548.0, 1656.0], "end": 1830.0},
	{"name": "room 4: step, gap", "start": 3420.0, "jumps": [3556.0, 3722.0], "end": 3900.0},
]

var failures := 0
var checks := 0
var level
var band
var deaths := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	level = load("res://scenes/levels/level_test.tscn").instantiate()
	root.add_child(level)
	await _frames(5)
	band = level.band
	level.member_died.connect(func(_m, _c): deaths += 1)

	for i in band.members.size():
		var m = band.members[i]
		band.switch_to(i, true)
		for stretch in STRETCHES:
			var ok: Array = await _run_stretch(m, stretch)
			_check(ok[0], "%s: %s (%s)" % [m.profile.display_name, stretch.name, ok[1]])

	var expected: int = band.members.size() * STRETCHES.size()
	if checks != expected:
		print("  FAIL ran %d of %d checks (script error?)" % [checks, expected])
		failures += 1
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _run_stretch(m, stretch: Dictionary) -> Array:
	await _await_idle()
	level.get_node("Rooms/Room1/Rat").defeat()   # dodging the rat is timing, not a gate
	# Teleporting doesn't change rooms, so no items: a carried lure would make
	# Geoff walk after this member from another room.
	for other in band.members:
		other.inventory.clear()
	m.respawn(Vector2(stretch.start, GY), m.health.max_hp)
	await _frames(5)
	var hp_before: int = m.health.hp
	var deaths_before := deaths
	var jumps: Array = stretch.jumps.duplicate()
	var hold := 0
	Input.action_press("move_right")
	for frame in 360:
		await physics_frame
		if level.is_busy:
			break
		if hold > 0:
			hold -= 1
			if hold == 0:
				Input.action_release("jump")
		# Like a player: jump from the ground (an air press would be Nikki's double jump).
		if not jumps.is_empty() and m.global_position.x >= jumps[0] and m.is_on_floor():
			jumps.pop_front()
			Input.action_release("jump")
			await physics_frame
			Input.action_press("jump")
			hold = JUMP_HOLD_FRAMES
		if m.global_position.x >= stretch.end and m.is_on_floor():
			break
	Input.action_release("move_right")
	Input.action_release("jump")
	var x: float = m.global_position.x
	if deaths != deaths_before:
		await _await_idle()
		return [false, "died near x=%.0f" % x]
	if m.health.hp < hp_before:
		return [false, "got hurt near x=%.0f" % x]
	if x < stretch.end:
		return [false, "stuck at x=%.0f" % x]
	return [true, "made it"]


func _await_idle() -> void:
	var n := 0
	while (level.is_busy or paused) and n < 600:
		await physics_frame
		n += 1
	await _frames(2)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	print(("  ok   " if ok else "  FAIL ") + label)
	if not ok:
		failures += 1
