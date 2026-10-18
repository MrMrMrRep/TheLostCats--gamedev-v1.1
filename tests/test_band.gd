extends SceneTree
## Headless checks for the M4 band: switching, input isolation, camera blend,
## gather (arrive, wall, ledge). Exits 1 on failure.
## Game classes stay untyped here: naming Band at compile time would compile
## band.gd before the autoloads (Game) exist in --script mode.
## Run: Summer --headless --path . --script res://tests/test_band.gd

const ACTIONS := ["move_left", "move_right", "move_down", "jump", "switch_next", "switch_prev", "gather",
	"select_1", "select_2", "select_3", "select_4", "select_5"]

var failures := 0
var checks := 0
const EXPECTED_CHECKS := 20          # a crashed check must not look like a pass


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var room := _load_room("res://scenes/dev/baseline.tscn")
	await _frames(10)
	var band = room.get_node("Band")
	await _test_switching(band)
	await _test_input_isolation(band)
	await _test_speeds(band)
	await _test_camera_blend(band)
	await _test_gather_arrive(band)
	await _test_gather_wall(band)
	room.queue_free()

	room = _load_room("res://scenes/dev/movement_test.tscn")
	await _frames(10)
	await _test_gather_ledge(room.get_node("Band"))

	if checks != EXPECTED_CHECKS:
		print("  FAIL ran %d of %d checks (script error?)" % [checks, EXPECTED_CHECKS])
		failures += 1
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _test_switching(band) -> void:
	_check(band.members.size() == 5, "5 band members")
	var names: Array = band.members.map(func(m): return m.profile.display_name)
	_check(names == ["Joep", "Jay", "Nikki", "The Germ", "Geoff"], "order Joep, Jay, Nikki, The Germ, Geoff")
	_check(band.active_index == 0 and band.active.is_active, "Joep starts active")
	_check(band.members[4].health.max_hp == 1 and band.members[0].health.max_hp == 3, "Geoff 1 HP, others 3 HP")
	await _tap("select_3")
	_check(band.active_index == 2 and root.get_node("Game").active_member == 2, "key 3 selects Nikki (Game.active_member synced)")
	_check(band.members.filter(func(m): return m.is_active).size() == 1, "exactly one member is active")
	await _tap("select_5")
	await _tap("switch_next")
	_check(band.active_index == 0, "Tab after the 5th wraps to the 1st")
	await _tap("switch_prev")
	_check(band.active_index == 4, "Q before the 1st wraps to the 5th")
	await _tap("select_1")


func _test_input_isolation(band) -> void:
	var before: Array = band.members.map(func(m): return m.position.x)
	Input.action_press("move_right")
	await _frames(20)
	Input.action_release("move_right")
	await _frames(10)
	var moved: Array = band.members.map(func(m): return m.position.x - before[band.members.find(m)])
	_check(moved[0] > 40.0, "active Joep moved (%.0f px)" % moved[0])
	_check(moved.slice(1).all(func(d): return absf(d) < 0.5), "inactive members stayed put")
	# Switching mid-run: the previous member stops by itself.
	Input.action_press("move_right")
	await _frames(10)
	await _tap("select_2")
	await _frames(10)
	Input.action_release("move_right")
	_check(absf(band.members[0].velocity.x) < 1.0, "Joep stops after switching away mid-run")
	await _tap("select_1")


func _test_speeds(band) -> void:
	var dist := {}
	for i in [1, 2]:                         # Jay (5.5 t/s) vs Nikki (8.5 t/s)
		await _tap("select_%d" % (i + 1))
		var m = band.active
		m.global_position = Vector2(60, 144)
		m.velocity = Vector2.ZERO
		await _frames(5)
		var x0: float = m.global_position.x
		Input.action_press("move_right")
		await _frames(20)
		Input.action_release("move_right")
		dist[i] = m.global_position.x - x0
		await _frames(10)
	_check(dist[2] > dist[1] * 1.3, "Nikki outruns Jay (%.0f vs %.0f px in 1/3 s)" % [dist[2], dist[1]])
	await _tap("select_1")


func _test_camera_blend(band) -> void:
	var cam = band.camera
	band.members[0].global_position = Vector2(60, 144)
	band.members[4].global_position = Vector2(300, 144)
	await _frames(20)
	await _tap("select_5")
	var target: Vector2 = band.members[4].global_position + band.camera.TARGET_OFFSET
	_check(cam.global_position.distance_to(target) > 20.0, "camera blends (not a cut) after switching")
	await _frames(20)
	_check(cam.global_position.distance_to(target) < 1.0, "camera reaches the new member within 0.25 s")
	await _tap("select_1")


func _test_gather_arrive(band) -> void:
	_spread(band, 40.0)
	band.members[0].global_position = Vector2(300, 144)
	await _frames(5)
	await _tap("gather")
	await _frames(180)
	var xs: Array = band.members.slice(1).map(func(m): return m.global_position.x)
	var near: bool = xs.all(func(x): return x > 300.0 - 14.0 * 4 - 8.0 and x <= 300.0)
	_check(near, "gather: everyone comes to Joep %s" % [xs.map(func(x): return int(x))])
	var sorted_xs := xs.duplicate()
	sorted_xs.sort()
	var spaced := true
	for i in sorted_xs.size() - 1:
		spaced = spaced and sorted_xs[i + 1] - sorted_xs[i] > 8.0
	_check(spaced, "gather: they line up in a row instead of stacking")
	_check(band.members.all(func(m): return not band.is_gathering(m) and m.ai_dir == 0.0), "gather: everyone stopped")


func _test_gather_wall(band) -> void:
	# The 1-tile step at x 336..360 blocks the walk to x 420.
	_spread(band, 40.0)
	band.members[0].global_position = Vector2(420, 144)
	await _frames(5)
	await _tap("gather")
	await _frames(240)
	var xs: Array = band.members.slice(1).map(func(m): return m.global_position.x)
	_check(xs.all(func(x): return x < 336.0), "gather: a wall stops them %s" % [xs.map(func(x): return int(x))])
	_check(band.members.all(func(m): return m.ai_dir == 0.0), "gather: blocked members give up instead of walking into the wall")


func _test_gather_ledge(band) -> void:
	# Pit at x 672..696 (movement test room); leader stands beyond it.
	for i in band.members.size():
		band.members[i].global_position = Vector2(720 if i == 0 else 590 + i * 10, 288)
	await _frames(5)
	await _tap("gather")
	await _frames(180)
	var ms: Array = band.members.slice(1)
	_check(ms.all(func(m): return m.global_position.x <= 666.0 and m.global_position.y < 289.0),
		"gather: members stop fully on solid ground before the pit %s" % [ms.map(func(m): return int(m.global_position.x))])


# --- Helpers ---------------------------------------------------------------

func _load_room(path: String) -> Node:
	var room: Node = load(path).instantiate()
	root.add_child(room)
	return room


func _spread(band, x0: float) -> void:
	for i in band.members.size():
		band.members[i].global_position = Vector2(x0 + i * 18, 144)
		band.members[i].velocity = Vector2.ZERO


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
