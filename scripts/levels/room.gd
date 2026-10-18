@tool
class_name Room
extends Node2D
## One room of a level: its camera bounds and the things that reset on death.
## Every descendant in the "resettable" group gets reset_state() when the band
## dies in this room (Lost Vikings rule: the room goes back to how it was).

@export var bounds := Rect2i(0, 0, 960, 360):
	set(value):
		bounds = value
		queue_redraw()


func reset_state() -> void:
	for node in get_tree().get_nodes_in_group(&"resettable"):
		if is_ancestor_of(node):
			node.reset_state()


func has_point(point: Vector2) -> bool:
	return Rect2(bounds).has_point(point)


func _draw() -> void:
	if Engine.is_editor_hint():
		draw_rect(Rect2(Vector2(bounds.position) - global_position, bounds.size), Color(0.4, 0.8, 1.0, 0.8), false, 2.0)
