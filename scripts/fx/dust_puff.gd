class_name DustPuff
extends Node2D
## A little cloud of dust that puffs out sideways and fades (0.35 s).

const LIFE := 0.35

var size := 1.0
var _t := 0.0


func _process(delta: float) -> void:
	_t += delta
	if _t >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var k := _t / LIFE
	var c := Color(0.85, 0.82, 0.75, 0.7 * (1.0 - k))
	for side: float in [-1.0, 1.0]:
		for i in 3:
			var x: float = side * (3.0 + i * 3.0 + k * 10.0) * size
			var r: float = (1.5 + i * 0.5 + k * 2.0) * size
			draw_circle(Vector2(x, -1.0 - i * 0.6 - k * 2.0), r, c)
