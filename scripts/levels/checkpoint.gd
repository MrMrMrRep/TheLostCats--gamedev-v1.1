@tool
class_name Checkpoint
extends Area2D
## Flag that becomes the respawn point when the active member touches it.
## The band respawns in a row here with the HP it had when it was activated.

const POLE := 26.0

var is_current := false:
	set(value):
		is_current = value
		queue_redraw()


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 2                 # player
	monitorable = false
	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(20, 32)
	shape.shape = rect
	shape.position = Vector2(0, -16)
	add_child(shape)
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if body is BandMember and body.is_active and not is_current:
		var level := Level.of(self)
		if level:
			level.activate_checkpoint(self)


func _draw() -> void:
	draw_line(Vector2(0, 0), Vector2(0, -POLE), Color("6b5a4a"), 2.0)
	var flag := Color("ffd36b") if is_current else Color(0.6, 0.6, 0.65)
	draw_colored_polygon(PackedVector2Array([Vector2(1, -POLE), Vector2(13, -POLE + 4), Vector2(1, -POLE + 8)]), flag)
