class_name BandCamera
extends Camera2D
## Follows the active band member with a deadzone (small moves don't drag the
## view) and look-ahead (the view leads in the running direction). On a switch
## it blends to the new member in SWITCH_TIME instead of cutting. Limits come
## from the current room.

const SWITCH_TIME := 0.25
const TARGET_OFFSET := Vector2(0, -16)      # aim at the body, not the feet

@export var deadzone := Vector2(16, 24)     ## half-size in px the target can move freely
@export var look_ahead := 40.0              ## px the view leads while running
@export var look_ahead_time := 0.35         ## seconds to swing fully to one side
@export var look_ahead_min_speed := 20.0    ## px/s before look-ahead kicks in

var target: Node2D

var _focus := Vector2.ZERO
var _look := 0.0
var _from := Vector2.ZERO
var _blend := 1.0
var _tween: Tween


func _ready() -> void:
	process_callback = Camera2D.CAMERA2D_PROCESS_PHYSICS
	position_smoothing_enabled = true
	position_smoothing_speed = 8.0


func follow(new_target: Node2D, instant := false) -> void:
	var had_target := target != null
	target = new_target
	if _tween:
		_tween.kill()
	if instant or not had_target:
		snap()
		return
	_from = get_screen_center_position()
	_focus = _target_position()
	_look = 0.0
	_blend = 0.0
	position_smoothing_enabled = false
	_tween = create_tween()
	_tween.tween_property(self, "_blend", 1.0, SWITCH_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.finished.connect(_on_blend_finished)


## Jump straight to the target (after teleports, respawns, room changes).
func snap() -> void:
	if _tween:
		_tween.kill()
	_blend = 1.0
	_focus = _target_position()
	_look = 0.0
	position_smoothing_enabled = true
	global_position = _focus
	reset_smoothing()


func set_bounds(bounds: Rect2i) -> void:
	limit_left = bounds.position.x
	limit_top = bounds.position.y
	limit_right = bounds.end.x
	limit_bottom = bounds.end.y


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var t := _target_position()
	var d := t - _focus
	if absf(d.x) > deadzone.x:
		_focus.x = t.x - signf(d.x) * deadzone.x
	if absf(d.y) > deadzone.y:
		_focus.y = t.y - signf(d.y) * deadzone.y

	var want := 0.0
	var v: Variant = target.get("velocity")
	if v is Vector2 and absf(v.x) > look_ahead_min_speed:
		want = signf(v.x) * look_ahead
	_look = move_toward(_look, want, look_ahead / look_ahead_time * delta)

	var goal := _focus + Vector2(_look, 0)
	global_position = _from.lerp(goal, _blend) if _blend < 1.0 else goal


func _target_position() -> Vector2:
	return target.global_position + TARGET_OFFSET


func _on_blend_finished() -> void:
	position_smoothing_enabled = true
	reset_smoothing()
