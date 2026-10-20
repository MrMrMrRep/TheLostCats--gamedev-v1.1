@tool
class_name Breakable
extends StaticBody2D
## Solid thing that one member can break. Which attack breaks which substance:
##   GLASS, FRAGILE_WALL -> "resonance" (Jay's bass wave)
##   WOOD, CRACKED_FLOOR -> "impact" (The Germ's punch / ground pound)
## Origin = bottom centre. Resets on death. Placeholder art drawn in code.

signal broken

enum Mat { GLASS, FRAGILE_WALL, WOOD, CRACKED_FLOOR }

const BREAKS_WITH := {
	Mat.GLASS: &"resonance",
	Mat.FRAGILE_WALL: &"resonance",
	Mat.WOOD: &"impact",
	Mat.CRACKED_FLOOR: &"impact",
}

@export var substance := Mat.WOOD:
	set(value):
		substance = value
		queue_redraw()
@export var size := Vector2(24, 48):
	set(value):
		size = value
		_update_shape()
		queue_redraw()

var is_broken := false

var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 1 << 0                # world
	collision_mask = 0
	_shape = CollisionShape2D.new()
	_shape.shape = RectangleShape2D.new()
	add_child(_shape)
	_update_shape()
	if not Engine.is_editor_hint():
		add_to_group(&"resettable")


## Returns true if this attack breaks this substance.
func break_by(kind: StringName) -> bool:
	if is_broken or BREAKS_WITH[substance] != kind:
		return false
	is_broken = true
	Audio.sfx(&"break")
	GameFeel.shake(get_tree(), 3.0, 0.2)
	_shape.set_deferred("disabled", true)
	_burst()
	visible = false
	broken.emit()
	return true


func reset_state() -> void:
	is_broken = false
	visible = true
	_shape.set_deferred("disabled", false)


func _update_shape() -> void:
	if _shape:
		(_shape.shape as RectangleShape2D).size = size
		_shape.position = Vector2(0, -size.y / 2.0)


func _burst() -> void:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = true
	p.amount = 14
	p.lifetime = 0.6
	p.explosiveness = 1.0
	p.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	p.emission_rect_extents = size / 2.0
	p.direction = Vector2(0, -1)
	p.spread = 70.0
	p.initial_velocity_min = 40.0
	p.initial_velocity_max = 110.0
	p.gravity = Vector2(0, 500)
	p.scale_amount_min = 2.0
	p.scale_amount_max = 3.0
	p.color = _color()
	p.position = position + Vector2(0, -size.y / 2.0)
	get_parent().add_child(p)
	get_tree().create_timer(1.0).timeout.connect(p.queue_free)


func _color() -> Color:
	match substance:
		Mat.GLASS: return Color(0.7, 0.9, 1.0, 0.8)
		Mat.FRAGILE_WALL: return Color("7a7680")
		Mat.WOOD: return Color("8a5a32")
		_: return Color("4a3a30")


func _draw() -> void:
	var r := Rect2(-size.x / 2.0, -size.y, size.x, size.y)
	match substance:
		Mat.GLASS:
			draw_rect(r, Color(0.6, 0.85, 1.0, 0.35))
			draw_rect(r, Color(0.8, 0.95, 1.0, 0.9), false, 1.0)
			draw_line(r.position + Vector2(4, 6), r.position + Vector2(10, 0), Color(1, 1, 1, 0.8), 1.0)
		Mat.FRAGILE_WALL:
			draw_rect(r, Color("5e5a64"))
			draw_polyline(PackedVector2Array([r.position + Vector2(6, 4), r.position + Vector2(12, 16), r.position + Vector2(8, 26), r.position + Vector2(16, size.y - 4)]), Color("2a2830"), 1.0)
		Mat.WOOD:
			draw_rect(r, Color("8a5a32"))
			draw_rect(r, Color("4a2e18"), false, 1.0)
			draw_line(r.position, r.end, Color("4a2e18"), 1.0)
			draw_line(Vector2(r.position.x, r.end.y), Vector2(r.end.x, r.position.y), Color("4a2e18"), 1.0)
		Mat.CRACKED_FLOOR:
			draw_rect(r, Color("4a3a30"))
			draw_polyline(PackedVector2Array([r.position + Vector2(2, 3), r.position + Vector2(9, 8), r.position + Vector2(15, 4), r.position + Vector2(22, 10)]), Color("1a1210"), 1.0)
