class_name TimeControl
extends Node
## The Germ's Drumbeat Master. While his beat runs, everything in the "timed"
## group (rats, flight cases, timed gates, moving platforms) is under his
## control; the band keeps moving:
##   STOP    frozen in place (the beat starts here)
##   REWIND  plays the last few seconds backwards, then holds
##   PLAY    back to normal (the beat ends)
## L during the beat steps STOP -> REWIND -> PLAY; it ends by itself after
## BEAT_TIME. Each level gets one (TimeControl.of()). Timed nodes may define
## time_state() / set_time_state() for more than their position.

signal mode_changed(mode: Mode)

enum Mode { PLAY, STOP, REWIND }

const BEAT_TIME := 6.0                      # seconds the beat lasts
const HISTORY := 240                        # physics frames kept for a rewind (4 s)
const REWIND_SPEED := 2                     # frames rewound per frame
const TINT := {Mode.STOP: Color(0.45, 0.6, 1.0, 0.22), Mode.REWIND: Color(1.0, 0.45, 0.8, 0.22)}
const BANNER := {Mode.STOP: "||  STOP", Mode.REWIND: "<<  REWIND"}

var mode := Mode.PLAY
var beat_left := 0.0

var _history: Array = []                    # per frame: {node: [position, state]}
var _modes := {}                            # node -> process_mode before the stop
var _overlay: ColorRect
var _banner: Label


## The TimeControl of the level `node` is in (made on first use).
static func of(node: Node) -> TimeControl:
	var level := Level.of(node)
	var host: Node = level if level else node.get_tree().current_scene
	var tc := host.get_node_or_null("TimeControl") as TimeControl
	if tc == null:
		tc = TimeControl.new()
		tc.name = "TimeControl"
		host.add_child(tc)
	return tc


func _ready() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 5
	add_child(layer)
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.visible = false
	layer.add_child(_overlay)
	_banner = Label.new()                   # "|| STOP" and the beat running out, top centre
	_banner.position = Vector2(0, 52)
	_banner.size = Vector2(640, 20)
	_banner.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_banner.add_theme_font_size_override("font_size", 16)
	_banner.add_theme_color_override("font_color", Color("ffd36b"))
	_banner.add_theme_color_override("font_outline_color", Color("1d2838"))
	_banner.add_theme_constant_override("outline_size", 2)
	_banner.visible = false
	layer.add_child(_banner)


func is_running() -> bool:
	return mode != Mode.PLAY


## L: start the beat (STOP), or step it on (REWIND, then PLAY).
func step() -> Mode:
	match mode:
		Mode.PLAY:
			beat_left = BEAT_TIME
			_set_mode(Mode.STOP)
		Mode.STOP:
			_set_mode(Mode.REWIND)
		Mode.REWIND:
			_set_mode(Mode.PLAY)
	return mode


## Back to normal now (end of the beat, a death, leaving the level).
func end() -> void:
	if mode != Mode.PLAY:
		_set_mode(Mode.PLAY)


func _physics_process(_delta: float) -> void:
	if mode == Mode.PLAY:
		_record()
		return
	beat_left -= get_physics_process_delta_time()
	_banner.text = "%s  %.1f" % [BANNER[mode], maxf(beat_left, 0.0)]
	if beat_left <= 0.0:
		_set_mode(Mode.PLAY)
		return
	if mode == Mode.REWIND:
		for i in REWIND_SPEED:
			if _history.is_empty():
				break
			_apply(_history.pop_back())


func _record() -> void:
	var frame := {}
	for n in get_tree().get_nodes_in_group(&"timed"):
		var n2 := n as Node2D
		if n2 == null or not n2.is_inside_tree():
			continue
		frame[n2] = [n2.global_position, n2.time_state() if n2.has_method("time_state") else null]
	_history.append(frame)
	if _history.size() > HISTORY:
		_history.pop_front()


func _apply(frame: Dictionary) -> void:
	for n in frame:
		if not is_instance_valid(n):
			continue
		var snap: Array = frame[n]
		n.global_position = snap[0]
		if snap[1] != null:
			n.set_time_state(snap[1])
		if n is CharacterBody2D:
			n.velocity = Vector2.ZERO


func _set_mode(m: Mode) -> void:
	var was := mode
	mode = m
	if was == Mode.PLAY and m != Mode.PLAY:
		_modes.clear()
		for n in get_tree().get_nodes_in_group(&"timed"):
			if n.process_mode != Node.PROCESS_MODE_DISABLED:
				_modes[n] = n.process_mode
				n.process_mode = Node.PROCESS_MODE_DISABLED
	elif m == Mode.PLAY:
		for n in _modes:
			if is_instance_valid(n):
				n.process_mode = _modes[n]
		_modes.clear()
		_history.clear()
		beat_left = 0.0
	_overlay.visible = m != Mode.PLAY
	_banner.visible = m != Mode.PLAY
	if m != Mode.PLAY:
		_overlay.color = TINT[m]
		_banner.text = BANNER[m]
	mode_changed.emit(m)
