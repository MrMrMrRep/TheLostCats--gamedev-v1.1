@tool
class_name Hazard
extends Area2D
## Floor hazard. SPIKES hurt (1 HP + knockback, i-frames protect); ELECTRIC
## kills instantly while enabled. Joep's hack will call set_enabled(false) (M6).
## Placeholder art is drawn in code; the origin is the floor surface.

enum Kind { SPIKES, ELECTRIC }

@export var kind := Kind.SPIKES:
	set(value):
		kind = value
		queue_redraw()
@export var width := 48.0:
	set(value):
		width = value
		_update_shape()
		queue_redraw()
@export var damage := 1
@export var enabled := true:
	set(value):
		enabled = value
		queue_redraw()

var _start_enabled := true
var _shape: CollisionShape2D


func _ready() -> void:
	collision_layer = 1 << 4                # hazard
	collision_mask = 1 << 2                 # player
	monitorable = false
	_shape = CollisionShape2D.new()
	_shape.shape = RectangleShape2D.new()
	add_child(_shape)
	_update_shape()
	_start_enabled = enabled
	if not Engine.is_editor_hint():
		add_to_group(&"resettable")


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	if kind == Kind.ELECTRIC:
		queue_redraw()                      # flicker
	if not enabled:
		return
	for body in get_overlapping_bodies():
		if body is BandMember and not body.is_dead:
			if kind == Kind.ELECTRIC:
				var level := Level.of(self)
				if level:
					level.kill(body, &"electric")
			else:
				body.hurt(damage, global_position + Vector2(0, 8))


func set_enabled(value: bool) -> void:
	enabled = value


func reset_state() -> void:
	enabled = _start_enabled


func _update_shape() -> void:
	if _shape:
		var h := 6.0 if kind == Kind.SPIKES else 4.0
		(_shape.shape as RectangleShape2D).size = Vector2(width - 4.0, h)
		_shape.position = Vector2(0, -h / 2.0)


func _draw() -> void:
	var left := -width / 2.0
	if kind == Kind.SPIKES:
		var n := int(width / 8.0)
		for i in n:
			var x := left + i * 8.0
			draw_colored_polygon(PackedVector2Array([Vector2(x, 0), Vector2(x + 4, -8), Vector2(x + 8, 0)]), Color("b8bcc8"))
			draw_line(Vector2(x + 4, -8), Vector2(x + 8, 0), Color("6c7080"), 1.0)
	else:
		draw_rect(Rect2(left, -3, width, 3), Color("3a4a5a"))
		if enabled:
			var pts := PackedVector2Array()
			var x := left
			while x <= -left:
				pts.append(Vector2(x, -2 - randf() * 5.0))
				x += 4.0
			draw_polyline(pts, Color("9ff3ff"), 1.0)
			draw_rect(Rect2(left, -3, width, 1), Color("e0ffff"))
