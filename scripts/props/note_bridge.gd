class_name NoteBridge
extends StaticBody2D
## A platform made of music: Nikki's guitar solo plays it into the air. A
## one-way platform anyone can stand on (from above) that fades after
## `lifetime` seconds; it blinks for the last two. Gone when the room resets.
## Origin = top-left of the walking surface; rotate it for a ramp.

const HEIGHT := 6.0
const COLORS := [Color("ffd36b"), Color("9ff3ff"), Color("f2a65a")]

var size := Vector2(144, HEIGHT)
var lifetime := 8.0

var _age := 0.0


func _ready() -> void:
	collision_layer = 1 << 1                # one_way
	collision_mask = 0
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = size
	col.shape = rect
	col.position = size / 2.0
	col.one_way_collision = true
	col.one_way_collision_margin = 8.0      # feet walking into a ramp step onto it
	add_child(col)
	add_to_group(&"resettable")
	add_to_group(&"note_bridge")


func _physics_process(delta: float) -> void:
	_age += delta
	queue_redraw()
	if _age >= lifetime:
		queue_free()


func reset_state() -> void:
	queue_free()


func _draw() -> void:
	var left := lifetime - _age
	if left < 2.0 and int(left * 8.0) % 2 == 0:
		return
	var a := clampf(_age / 0.25, 0.0, 1.0)
	var n := int(size.x / 12.0)
	for i in n:                             # a row of glowing notes
		var c: Color = COLORS[i % COLORS.size()]
		c.a = 0.85 * a
		var x := i * 12.0 + 6.0
		draw_circle(Vector2(x - 2, 3), 2.5, c)
		draw_line(Vector2(x, 3), Vector2(x, -5), c, 1.0)
	draw_line(Vector2(0, HEIGHT), Vector2(size.x, HEIGHT), Color(1, 0.9, 0.6, 0.5 * a), 1.0)
