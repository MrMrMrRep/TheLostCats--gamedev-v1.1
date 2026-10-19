@tool
class_name SwitchPanel
extends Interactable
## Lever or hack panel that triggers its targets (Gate.trigger(),
## Hazard.trigger()...). A hack panel only works for members who can hack
## (Joep); a lever works for anyone. One use until the room resets.

enum Kind { LEVER, HACK_PANEL }

@export var kind := Kind.LEVER:
	set(value):
		kind = value
		queue_redraw()
@export var targets: Array[NodePath] = []

var used := false:
	set(value):
		used = value
		queue_redraw()


func _ready() -> void:
	area_size = Vector2(28, 36)
	super()
	if not Engine.is_editor_hint():
		add_to_group(&"resettable")


func can_interact(_member: BandMember) -> bool:
	return not used


func interact(member: BandMember, _level: Node) -> void:
	if kind == Kind.HACK_PANEL and not (member.ability and member.ability.can_hack):
		say("Needs a hacker... Joep?")
		return
	activate()
	say("Hacked!" if kind == Kind.HACK_PANEL else "*clunk*", 1.0)


func activate() -> void:
	if used:
		return
	used = true
	for path in targets:
		var t := get_node_or_null(path)
		if t and t.has_method("trigger"):
			t.trigger()


func reset_state() -> void:
	used = false


func _draw() -> void:
	if kind == Kind.LEVER:
		draw_rect(Rect2(-6, -6, 12, 6), Color("5a4a3a"))
		var tip := Vector2(7, -16) if used else Vector2(-7, -16)
		draw_line(Vector2(0, -6), tip, Color("c8ccd4"), 2.0)
		draw_circle(tip, 2.5, Color("c94a3d"))
	else:
		draw_rect(Rect2(-8, -26, 16, 18), Color("2a2a34"))
		draw_rect(Rect2(-6, -24, 12, 9), Color("4fe07a") if used else Color("e0544f"))
		for i in 3:
			draw_rect(Rect2(-6 + i * 4.5, -13, 3, 3), Color("8a8a96"))
