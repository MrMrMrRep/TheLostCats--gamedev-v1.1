extends CanvasLayer
## On-screen gamepad for phones and tablets. Registered as the `TouchPad`
## autoload. Shows on touch devices; hides when a key or a controller button
## is used, and comes back on the next touch.
##
## The buttons send the same input actions as the keyboard (jump, action_a,
## interact, ...), so the game, menus, dialogue and pause need no changes.
## Left side: a joystick that appears where the thumb lands (push it all the
## way to sprint on the world map). Right side: action buttons.
##
## Dev switch: F7 (debug builds) or the user arg `-- --touchpad` forces the
## pad on and lets the left mouse button act as a finger.

const STICK_RADIUS := 34.0
const KNOB_RADIUS := 13.0
const STICK_DEADZONE := 0.3        # per direction, as a share of the radius
const SPRINT_AT := 0.95            # stick length that counts as sprinting
const STICK_HOME := Vector2(80, 290)
const STICK_AREA := Rect2(0, 60, 300, 300)   # where a touch grabs the stick
const HIT_SLACK := 6.0             # extra px around a button that still counts
const MOUSE_FINGER := 99
const TITLE_SCENE := "res://scenes/ui/title.tscn"   # no pad here: the menu is tapped directly

# [action, label, centre, radius] on the 640x360 base screen. Buttons on the
# right half stay the same distance from the right edge on wider screens.
const BUTTONS := [
	[&"jump", "JUMP", Vector2(598, 306), 24.0],
	[&"action_a", "ABIL", Vector2(546, 322), 18.0],
	[&"action_b", "AB 2", Vector2(562, 264), 16.0],
	[&"interact", "E", Vector2(612, 248), 15.0],
	[&"use_item", "ITEM", Vector2(512, 212), 11.0],
	[&"item_next", "NEXT", Vector2(540, 212), 11.0],
	[&"give", "GIVE", Vector2(568, 212), 11.0],
	[&"drop_item", "DROP", Vector2(596, 212), 11.0],
	[&"gather", "GATH", Vector2(614, 142), 12.0],
	[&"switch_next", "SWAP", Vector2(614, 112), 12.0],
	[&"pause", "II", Vector2(614, 82), 12.0],
]

const COL_FILL := Color(0.05, 0.06, 0.1, 0.35)
const COL_FILL_DOWN := Color(1, 0.83, 0.42, 0.45)
const COL_EDGE := Color(1, 1, 1, 0.45)
const COL_TEXT := Color(1, 1, 1, 0.8)

var enabled := false
var forced := false                 # dev switch on: mouse acts as a finger

var _view: Control
var _fingers := {}                  # finger index -> "stick" or button index
var _down := {}                     # button index -> true while held
var _stick_finger := -1
var _stick_origin := STICK_HOME
var _stick_vec := Vector2.ZERO
var _held := {}                     # action -> true, for actions we pressed
var _on_title := false


func _ready() -> void:
	layer = 95
	process_mode = Node.PROCESS_MODE_ALWAYS
	_view = Control.new()
	_view.name = "Pad"
	_view.set_anchors_preset(Control.PRESET_FULL_RECT)
	_view.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_view.draw.connect(_draw_pad)
	get_viewport().size_changed.connect(_view.queue_redraw)
	add_child(_view)
	forced = "--touchpad" in OS.get_cmdline_user_args()
	_set_enabled(forced or is_touch_device())


static func is_touch_device() -> bool:
	if OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios"):
		return true
	return OS.has_feature("web") and DisplayServer.is_touchscreen_available()


func _process(_delta: float) -> void:
	var scene := get_tree().current_scene
	var title := scene != null and scene.scene_file_path == TITLE_SCENE
	if title != _on_title:
		_on_title = title
		if title:
			_release_all()
		visible = enabled and not title


func _notification(what: int) -> void:
	if what == NOTIFICATION_APPLICATION_FOCUS_OUT:
		_release_all()


func _input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo \
			and event.physical_keycode == KEY_F7:
		forced = not forced
		_set_enabled(forced)
		get_viewport().set_input_as_handled()
		return

	if event is InputEventScreenTouch:
		_on_touch(event.index, event.position, event.pressed)
	elif event is InputEventScreenDrag:
		_on_drag(event.index, event.position)
	elif forced and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		_on_touch(MOUSE_FINGER, event.position, event.pressed)
	elif forced and event is InputEventMouseMotion and _fingers.has(MOUSE_FINGER):
		_on_drag(MOUSE_FINGER, event.position)
	elif not forced and enabled and event.is_pressed() and not event.is_echo() \
			and (event is InputEventKey or event is InputEventJoypadButton):
		_set_enabled(false)   # a keyboard or controller took over


func _on_touch(finger: int, pos: Vector2, pressed: bool) -> void:
	if pressed:
		if not enabled:
			_set_enabled(true)
		if _on_title:
			return                          # let the tap reach the menu
		var b := _button_at(pos)
		if b >= 0:
			_fingers[finger] = b
			_down[b] = true
			_press(BUTTONS[b][0])
		elif STICK_AREA.has_point(pos) and _stick_finger < 0:
			_fingers[finger] = "stick"
			_stick_finger = finger
			_stick_origin = pos.clamp(Vector2(STICK_RADIUS + 4, STICK_AREA.position.y + STICK_RADIUS),
					Vector2(STICK_AREA.end.x - STICK_RADIUS, ScreenFit.BASE.y - STICK_RADIUS - 4))
			_update_stick(pos)
		else:
			return
		get_viewport().set_input_as_handled()
	elif _fingers.has(finger):
		var what = _fingers[finger]
		_fingers.erase(finger)
		if what is String:
			_stick_finger = -1
			_update_stick(_stick_origin)
		else:
			_down.erase(what)
			_release(BUTTONS[what][0])
		get_viewport().set_input_as_handled()
	_view.queue_redraw()


func _on_drag(finger: int, pos: Vector2) -> void:
	if finger == _stick_finger:
		_update_stick(pos)
		get_viewport().set_input_as_handled()
		_view.queue_redraw()


func _update_stick(pos: Vector2) -> void:
	_stick_vec = ((pos - _stick_origin) / STICK_RADIUS).limit_length(1.0)
	_axis(&"move_left", -_stick_vec.x)
	_axis(&"move_right", _stick_vec.x)
	_axis(&"move_up", -_stick_vec.y)
	_axis(&"move_down", _stick_vec.y)
	if InputMap.has_action(&"sprint"):
		if _stick_vec.length() >= SPRINT_AT:
			_press(&"sprint")
		else:
			_release(&"sprint")


## Analog direction: press/release send a real event (menus react once),
## strength changes in between only update the polled value.
func _axis(action: StringName, amount: float) -> void:
	if amount > STICK_DEADZONE:
		var strength := remap(amount, STICK_DEADZONE, 1.0, 0.4, 1.0)
		if _held.has(action):
			Input.action_press(action, strength)
		else:
			_press(action, strength)
	else:
		_release(action)


func _press(action: StringName, strength := 1.0) -> void:
	if _held.has(action):
		return
	_held[action] = true
	_send(action, true, strength)


func _release(action: StringName) -> void:
	if not _held.has(action):
		return
	_held.erase(action)
	_send(action, false, 0.0)


func _send(action: StringName, pressed: bool, strength: float) -> void:
	var e := InputEventAction.new()
	e.action = action
	e.pressed = pressed
	e.strength = strength
	Input.parse_input_event(e)


func _release_all() -> void:
	for action in _held.keys():
		_release(action)
	_fingers.clear()
	_down.clear()
	_stick_finger = -1
	_stick_vec = Vector2.ZERO
	if _view:
		_view.queue_redraw()


func _set_enabled(on: bool) -> void:
	enabled = on
	visible = on and not _on_title
	if not on:
		_release_all()


## Where button `i` is on the real screen.
func _centre(i: int) -> Vector2:
	var c: Vector2 = BUTTONS[i][2]
	if c.x > ScreenFit.BASE.x / 2.0:
		c.x += ScreenFit.width(_view) - ScreenFit.BASE.x
	return c


func _button_at(pos: Vector2) -> int:
	var best := -1
	var best_d := INF
	for i in BUTTONS.size():
		var d: float = pos.distance_to(_centre(i))
		if d <= BUTTONS[i][3] + HIT_SLACK and d < best_d:
			best = i
			best_d = d
	return best


func _draw_pad() -> void:
	var font := ThemeDB.fallback_font
	# Joystick: a faint ring at home until a thumb grabs it.
	var active := _stick_finger >= 0
	var centre := _stick_origin if active else STICK_HOME
	_view.draw_circle(centre, STICK_RADIUS, Color(1, 1, 1, 0.08 if active else 0.05))
	_view.draw_arc(centre, STICK_RADIUS, 0, TAU, 32, Color(1, 1, 1, 0.35 if active else 0.2), 1.0)
	var knob := centre + _stick_vec * STICK_RADIUS
	_view.draw_circle(knob, KNOB_RADIUS, COL_FILL_DOWN if active else COL_FILL)
	_view.draw_arc(knob, KNOB_RADIUS, 0, TAU, 20, COL_EDGE, 1.0)

	for i in BUTTONS.size():
		var c := _centre(i)
		var r: float = BUTTONS[i][3]
		_view.draw_circle(c, r, COL_FILL_DOWN if _down.has(i) else COL_FILL)
		_view.draw_arc(c, r, 0, TAU, 24, COL_EDGE, 1.0)
		var size := 8 if r >= 15.0 else 6
		var text: String = BUTTONS[i][1]
		var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, size).x
		_view.draw_string_outline(font, c + Vector2(-w * 0.5, size * 0.35), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, size, 2, Color(0, 0, 0, 0.6))
		_view.draw_string(font, c + Vector2(-w * 0.5, size * 0.35), text,
				HORIZONTAL_ALIGNMENT_LEFT, -1, size, COL_TEXT)
