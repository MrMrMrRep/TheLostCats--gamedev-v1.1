@tool
class_name WallPlug
extends Node2D
## A socket in the wall wired to a device somewhere else (`target`: a hack
## panel, camera, amp or electronic door). Joep hacks the plug and reaches the
## device through the wiring, even behind a wall or up out of reach.
## Origin = the socket.

const SPARK_TIME := 0.6

@export var target: NodePath

var _spark := 0.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group(&"hackable")


func hack(by: BandMember = null) -> bool:
	var t := get_node_or_null(target)
	if t == null or not t.has_method("hack"):
		return false
	_spark = SPARK_TIME
	queue_redraw()
	return t.hack(by)


func _process(delta: float) -> void:
	if _spark > 0.0:
		_spark = maxf(_spark - delta, 0.0)
		queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-5, -7, 10, 10), Color("f2e8da"))
	draw_rect(Rect2(-5, -7, 10, 10), Color("8a8a96"), false, 1.0)
	draw_rect(Rect2(-3, -4, 1, 3), Color("2a2a34"))
	draw_rect(Rect2(2, -4, 1, 3), Color("2a2a34"))
	var t := get_node_or_null(target) as Node2D
	if t and (_spark > 0.0 or Engine.is_editor_hint()):
		var to := to_local(t.global_position)
		var a := 0.35 if Engine.is_editor_hint() else _spark / SPARK_TIME
		var pts := PackedVector2Array()
		for i in 9:                         # a zigzag spark along the wiring
			var p := Vector2.ZERO.lerp(to, i / 8.0)
			pts.append(p + Vector2(0, (-3.0 if i % 2 else 3.0) * (0.0 if i == 0 or i == 8 else 1.0)))
		draw_polyline(pts, Color(0.62, 0.95, 1.0, a), 1.0)
