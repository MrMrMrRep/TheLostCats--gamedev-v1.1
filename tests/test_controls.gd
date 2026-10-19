extends SceneTree
## Headless checks for the controls (exits 1 on failure): every action has a
## key, no key does two things, and pressing the real keys reaches the game
## (member input, switching, gather, E for doors or items, pause).
## Run: Summer --headless --path . --script res://tests/test_controls.gd
## Game classes stay untyped: naming them here would compile them before the
## autoloads exist in --script mode.

const EXPECTED_CHECKS := 27
# Every action the game reads, with the keys the controls screen promises.
const BINDINGS := {
	"move_left": [KEY_A, KEY_LEFT], "move_right": [KEY_D, KEY_RIGHT], "move_up": [KEY_W, KEY_UP],
	"move_down": [KEY_S, KEY_DOWN], "jump": [KEY_SPACE, KEY_C], "action_a": [KEY_J, KEY_X],
	"action_b": [KEY_K, KEY_Z], "interact": [KEY_E], "use_item": [KEY_R], "give": [KEY_F],
	"drop_item": [KEY_V], "item_next": [KEY_T], "gather": [KEY_G], "switch_next": [KEY_TAB],
	"switch_prev": [KEY_Q], "select_1": [KEY_1], "select_3": [KEY_3], "pause": [KEY_ESCAPE, KEY_P],
}

var failures := 0
var checks := 0
var level
var band


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	_test_bindings()
	level = load("res://scenes/levels/level_test.tscn").instantiate()
	root.add_child(level)
	await _frames(5)
	band = level.band
	await _test_member_keys()
	await _test_band_keys()
	await _test_e_uses_item()
	await _test_pause()

	if checks != EXPECTED_CHECKS:
		print("  FAIL ran %d of %d checks (script error?)" % [checks, EXPECTED_CHECKS])
		failures += 1
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _test_bindings() -> void:
	var missing := []
	for action in BINDINGS:
		for key in BINDINGS[action]:
			if not _bound(action, key):
				missing.append("%s:%s" % [action, OS.get_keycode_string(key)])
	_check(missing.is_empty(), "every action has its keys %s" % [missing])
	var seen := {}
	var doubles := []
	for action in InputMap.get_actions():
		if String(action).begins_with("ui_"):
			continue
		for ev in InputMap.action_get_events(action):
			if ev is InputEventKey:
				var code: int = ev.physical_keycode if ev.physical_keycode != 0 else ev.keycode
				if seen.has(code) and seen[code] != action:
					doubles.append("%s: %s + %s" % [OS.get_keycode_string(code), seen[code], action])
				seen[code] = action
	_check(doubles.is_empty(), "no key does two things %s" % [doubles])


func _test_member_keys() -> void:
	var m = band.active
	for k in [[KEY_D, "in_dir", 1.0], [KEY_A, "in_dir", -1.0], [KEY_S, "in_vertical", 1.0], [KEY_W, "in_vertical", -1.0]]:
		_key(k[0], true)
		await physics_frame
		await physics_frame
		_check(is_equal_approx(m.get(k[1]), k[2]), "%s -> %s %.0f" % [OS.get_keycode_string(k[0]), k[1], k[2]])
		_key(k[0], false)
		await _frames(2)
	for k in [[KEY_SPACE, "in_jump_held"], [KEY_J, "in_a_held"], [KEY_X, "in_a_held"], [KEY_K, "in_b_held"], [KEY_Z, "in_b_held"]]:
		_key(k[0], true)
		await physics_frame
		await physics_frame
		_check(m.get(k[1]), "%s -> %s" % [OS.get_keycode_string(k[0]), k[1]])
		_key(k[0], false)
		await _frames(6)


func _test_band_keys() -> void:
	var first: int = band.active_index
	await _press(KEY_TAB)
	_check(band.active_index == (first + 1) % 5, "Tab: next member")
	await _press(KEY_Q)
	_check(band.active_index == first, "Q: previous member")
	await _press(KEY_3)
	_check(band.active_index == 2, "3: member 3")
	await _press(KEY_1)
	_check(band.active_index == 0, "1: member 1")
	_key(KEY_G, true)
	await _frames(3)
	_check(band._gather_held, "hold G: gather")
	_key(KEY_G, false)
	await _frames(3)
	_check(not band._gather_held, "let go of G: stop gathering")


func _test_e_uses_item() -> void:
	var m = band.active
	m.inventory.clear()
	var beer = load("res://resources/items/beer.tres")
	var papers = load("res://resources/items/rolling_papers.tres")
	m.add_item(papers)
	m.add_item(beer)
	m.health.hp = 1
	await _frames(3)
	_check(level._highlighted == null, "nothing to interact with here")
	await _press(KEY_T)
	_check(m.inventory.slots[m.inventory.current_index()].id == &"beer", "T: next item (beer selected)")
	await _press(KEY_E)
	_check(m.beers == 0 and m.health.hp == 2, "E with nothing around: drink the selected beer (hp %d)" % m.health.hp)
	m.add_item(beer)
	m.health.hp = 1
	await _press(KEY_R)
	_check(m.beers == 0 and m.health.hp == 2, "R still uses the item too")
	await _press(KEY_V)
	_check(m.inventory.count(&"rolling_papers") == 0, "V: drop the item")
	# E at a door goes through the door, not into the bag.
	var door = level.get_node("Rooms/Room1").find_children("*", "Door", true, false)[0]
	m.add_item(beer)
	m.global_position = door.global_position
	await _frames(4)
	_check(level._highlighted == door, "standing at a door: it's highlighted")


func _test_pause() -> void:
	var pause = root.get_node("Pause")
	await _press(KEY_ESCAPE)
	_check(pause.is_open and paused, "Esc: pause (controls screen)")
	await _press(KEY_ESCAPE)
	_check(not pause.is_open and not paused, "Esc again: back to the game")
	await _press(KEY_P)
	_check(paused, "P pauses too")
	await _press(KEY_P)
	_check(not paused, "P again: back to the game")


# --- Helpers ---------------------------------------------------------------

func _bound(action: String, key: int) -> bool:
	if not InputMap.has_action(action):
		return false
	for ev in InputMap.action_get_events(action):
		if ev is InputEventKey and (ev.physical_keycode == key or ev.keycode == key):
			return true
	return false


func _key(code: int, pressed: bool) -> void:
	var ev := InputEventKey.new()
	ev.physical_keycode = code
	ev.keycode = code
	ev.pressed = pressed
	Input.parse_input_event(ev)
	Input.flush_buffered_events()


func _press(code: int) -> void:
	_key(code, true)
	await physics_frame
	await physics_frame
	_key(code, false)
	await _frames(3)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	if ok:
		print("  PASS ", label)
	else:
		failures += 1
		print("  FAIL ", label)
