@tool
class_name Door
extends Interactable
## Door the band goes through together. Either to another Door in this level
## (room to room) or out of the level to another scene (e.g. the world map).
## A locked door needs unlock() first (keycards come with the inventory in M7).

@export var target_door: NodePath           ## room -> room
@export_file("*.tscn") var target_scene := "" ## level exit
@export var target_spawn: StringName        ## spawn id in the target scene
@export var locked := false:
	set(value):
		locked = value
		queue_redraw()
@export var key_id: StringName              ## item that unlocks it (M7)

var _start_locked := false


func _ready() -> void:
	super()
	_start_locked = locked
	if not Engine.is_editor_hint():
		add_to_group(&"resettable")


func interact(_member: BandMember, level: Level) -> void:
	if locked:
		say("Locked")
		return
	level.go_through(self)


func unlock() -> void:
	locked = false


func reset_state() -> void:
	locked = _start_locked


func _draw() -> void:
	var w := 22.0
	var h := 38.0
	draw_rect(Rect2(-w / 2, -h, w, h), Color("2a1f1a"))
	draw_rect(Rect2(-w / 2, -h, w, h), Color("8a6a4a"), false, 2.0)
	draw_circle(Vector2(w / 2 - 5, -h / 2), 1.5, Color("ffd36b"))
	if locked:
		draw_rect(Rect2(-4, -h / 2 - 4, 8, 7), Color("c94a3d"))
