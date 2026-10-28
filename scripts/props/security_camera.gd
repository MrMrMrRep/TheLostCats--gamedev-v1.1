@tool
class_name SecurityCamera
extends Node2D
## A camera on the wall watching the floor in front of it (`view`, a box
## below and ahead of it). A band member walking into view sets off the alarm:
## its `targets` close (Gate.close()) or flip (trigger()). Joep's hack, a wall
## plug wired to it or his shockwave switches it off. Origin = the mount.
## Resets on death.

@export var view := Vector2(144, 96):       ## width ahead, depth below
	set(value):
		view = value
		queue_redraw()
@export var facing := -1.0:                 ## -1 looks left, 1 right
	set(value):
		facing = value
		queue_redraw()
@export var targets: Array[NodePath] = []

var active := true
var tripped := false


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group(&"hackable")
		add_to_group(&"resettable")


func view_rect() -> Rect2:
	var x := 0.0 if facing > 0.0 else -view.x
	return Rect2(global_position + Vector2(x, 0), view)


func _physics_process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	queue_redraw()
	if not active or tripped:
		return
	var r := view_rect()
	for m in get_tree().get_nodes_in_group(&"band_member"):
		if not m.is_dead and m.is_visible_in_tree() and r.has_point(m.global_position + Vector2(0, -10)):
			_alarm()
			return


func hack(_by: BandMember = null) -> bool:
	if not active:
		return false
	active = false
	Audio.sfx(&"hack")
	queue_redraw()
	return true


func _alarm() -> void:
	tripped = true
	Audio.sfx(&"switch")
	FloatText.spawn(get_parent(), global_position + Vector2(0, -12), "ALARM!", Color("ff6a5a"))
	for path in targets:
		var t := get_node_or_null(path)
		if t == null:
			continue
		if t.has_method("close"):
			t.close()
		elif t.has_method("trigger"):
			t.trigger()


func reset_state() -> void:
	active = true
	tripped = false
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-3, -6, 6, 6), Color("3a3e48"))
	draw_rect(Rect2(-6 if facing < 0 else 0, 0, 6, 5), Color("2a2a34"))
	draw_circle(Vector2(facing * 5.0, 2.5), 1.5, Color("e0544f") if active else Color("4a4a54"))
	if active or Engine.is_editor_hint():
		var x := 0.0 if facing > 0.0 else -view.x
		var c := Color(1.0, 0.3, 0.25, 0.12 if not tripped else 0.25)
		draw_colored_polygon(PackedVector2Array([Vector2(facing * 6.0, 4), Vector2(x + (view.x if facing > 0 else 0.0), view.y), Vector2(x + (0.0 if facing > 0 else view.x), view.y)]), c)
