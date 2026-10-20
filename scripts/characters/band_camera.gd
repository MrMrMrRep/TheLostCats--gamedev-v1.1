class_name BandCamera
extends Camera2D
## Follows the active band member with a deadzone (small moves don't drag the
## view) and look-ahead (the view leads in the running direction). On a switch
## it blends to the new member in `switch_time` instead of cutting. Limits come
## from the current room.

@export var deadzone := Vector2(16, 24)     ## half-size in px the target can move freely
@export var look_ahead := 40.0              ## px the view leads while running
@export var look_ahead_time := 0.35         ## seconds to swing fully to one side
@export var look_ahead_min_speed := 20.0    ## px/s before look-ahead kicks in
@export var sticky_look := false            ## keep leading after a stop (no swing back); turn around to swing
@export var switch_time := 0.25             ## seconds to blend to another member on a switch
@export var target_offset := Vector2(0, -16)  ## aim at the body, not the feet

var target: Node2D
var fixed_y := NAN                          # world map: keep the view at this height

var _shake := 0.0                           # px, fading
var _shake_time := 0.0
var _shake_left := 0.0
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
	_tween.tween_property(self, "_blend", 1.0, switch_time).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.finished.connect(_on_blend_finished)


## Jump straight to the target (after teleports, respawns, room changes).
func snap() -> void:
	if _tween:
		_tween.kill()
	_blend = 1.0
	_focus = _target_position()
	if not is_nan(fixed_y):
		_focus.y = fixed_y
	_look = 0.0
	position_smoothing_enabled = true
	global_position = _focus
	reset_smoothing()


## Screen shake: `strength` px, fading out over `time` seconds.
func shake(strength: float, time: float) -> void:
	_shake = maxf(_shake, strength)
	_shake_time = maxf(time, 0.01)
	_shake_left = _shake_time


func _process(delta: float) -> void:
	if _shake_left <= 0.0:
		if offset != Vector2.ZERO:
			offset = Vector2.ZERO
		return
	_shake_left -= delta
	var k := clampf(_shake_left / _shake_time, 0.0, 1.0)
	offset = Vector2(randf_range(-1, 1), randf_range(-1, 1)) * _shake * k
	if _shake_left <= 0.0:
		_shake = 0.0


func set_bounds(bounds: Rect2i) -> void:
	limit_left = bounds.position.x
	limit_top = bounds.position.y
	limit_right = bounds.end.x
	limit_bottom = bounds.end.y


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var t := _target_position()
	if not is_nan(fixed_y):
		t.y = fixed_y
		_focus.y = fixed_y
	var d := t - _focus
	if absf(d.x) > deadzone.x:
		_focus.x = t.x - signf(d.x) * deadzone.x
	if absf(d.y) > deadzone.y:
		_focus.y = t.y - signf(d.y) * deadzone.y

	var want := _look if sticky_look else 0.0
	var v: Variant = target.get("velocity")
	if v is Vector2 and absf(v.x) > look_ahead_min_speed:
		want = signf(v.x) * look_ahead
	elif sticky_look and absf(_look) > 0.5:
		want = signf(_look) * look_ahead    # stopped: hold the lead
	# Eased swing (exponential), so the view never starts or stops abruptly.
	_look = lerpf(_look, want, 1.0 - exp(-delta * 3.0 / look_ahead_time))

	var goal := _focus + Vector2(_look, 0)
	global_position = _from.lerp(goal, _blend) if _blend < 1.0 else goal


func _target_position() -> Vector2:
	return target.global_position + target_offset


func _on_blend_finished() -> void:
	position_smoothing_enabled = true
	reset_smoothing()
