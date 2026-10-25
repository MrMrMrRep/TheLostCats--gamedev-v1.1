extends SceneTree
## Headless checks for the on-screen touch gamepad (exits 1 on failure):
## touching a button presses its action, the stick presses directions and
## sprint, two fingers work at once, and a key press hides the pad.
## Run: Summer --headless --path . --script res://tests/test_touch_pad.gd

var failures := 0
var pad


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	await process_frame
	pad = root.get_node("TouchPad")
	pad._set_enabled(true)
	if not InputMap.has_action(&"sprint"):
		InputMap.add_action(&"sprint")

	var jump_at: Vector2 = pad._centre(0)
	await _touch(0, jump_at, true)
	_check(Input.is_action_pressed(&"jump"), "touching JUMP presses jump")
	# Second finger on the stick, pushed right while jump is still held.
	await _touch(1, Vector2(100, 300), true)
	await _drag(1, Vector2(140, 300))
	_check(Input.is_action_pressed(&"move_right"), "stick right presses move_right")
	_check(Input.is_action_pressed(&"jump"), "jump still held with two fingers")
	_check(Input.get_action_strength(&"move_right") > 0.9, "full push is full strength")
	_check(Input.is_action_pressed(&"sprint"), "full push sprints")
	_check(not Input.is_action_pressed(&"move_left"), "move_left stays up")
	await _drag(1, Vector2(115, 300))
	_check(not Input.is_action_pressed(&"sprint"), "half push does not sprint")
	await _drag(1, Vector2(100, 270))
	_check(Input.is_action_pressed(&"move_up") and not Input.is_action_pressed(&"move_right"), "stick up")
	await _touch(1, Vector2(100, 270), false)
	_check(not Input.is_action_pressed(&"move_up"), "lifting the thumb releases the stick")
	await _touch(0, jump_at, false)
	_check(not Input.is_action_pressed(&"jump"), "lifting releases jump")

	var e_at: Vector2 = pad._centre(3)
	await _touch(2, e_at, true)
	_check(Input.is_action_pressed(&"interact"), "E button presses interact")
	var key := InputEventKey.new()
	key.physical_keycode = KEY_D
	key.pressed = true
	Input.parse_input_event(key)
	await process_frame
	_check(not pad.visible, "a key press hides the pad")
	_check(not Input.is_action_pressed(&"interact"), "hiding releases held buttons")
	await _touch(3, Vector2(320, 180), true)
	_check(pad.visible, "a touch shows the pad again")

	print("touch pad: %s" % ("OK" if failures == 0 else "%d FAILED" % failures))
	quit(1 if failures else 0)


func _touch(i: int, pos: Vector2, pressed: bool) -> void:
	var e := InputEventScreenTouch.new()
	e.index = i
	e.position = pos
	e.pressed = pressed
	Input.parse_input_event(e)
	await process_frame
	await process_frame


func _drag(i: int, pos: Vector2) -> void:
	var e := InputEventScreenDrag.new()
	e.index = i
	e.position = pos
	Input.parse_input_event(e)
	await process_frame
	await process_frame


func _check(ok: bool, what: String) -> void:
	if not ok:
		failures += 1
		push_error("FAIL: " + what)
		print("FAIL: " + what)
