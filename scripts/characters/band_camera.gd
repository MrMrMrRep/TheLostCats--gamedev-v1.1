class_name BandCamera
extends Camera2D
## Follows the active band member. On a switch it blends to the new member in
## SWITCH_TIME instead of cutting. Deadzone and look-ahead come in M5.

const SWITCH_TIME := 0.25
const TARGET_OFFSET := Vector2(0, -16)      # aim at the body, not the feet

var target: Node2D

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
		_blend = 1.0
		global_position = _target_position()
		reset_smoothing()
		return
	_from = get_screen_center_position()
	_blend = 0.0
	position_smoothing_enabled = false
	_tween = create_tween()
	_tween.tween_property(self, "_blend", 1.0, SWITCH_TIME).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_tween.finished.connect(_on_blend_finished)


func _physics_process(_delta: float) -> void:
	if target == null:
		return
	if _blend < 1.0:
		global_position = _from.lerp(_target_position(), _blend)
	else:
		global_position = _target_position()


func _target_position() -> Vector2:
	return target.global_position + TARGET_OFFSET


func _on_blend_finished() -> void:
	global_position = _target_position()
	position_smoothing_enabled = true
	reset_smoothing()
