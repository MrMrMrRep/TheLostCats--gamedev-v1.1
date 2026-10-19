@tool
class_name Door
extends Interactable
## Door to go through. Either to another Door in this level
## (room to room) or out of the level to another scene (e.g. the world map).
## The whole band goes through only when everyone stands together (see Level).
## A locked door opens for a member carrying its keycard (key_id): E uses it
## and goes through. Unlocked with a key, it stays unlocked after a death.

@export var target_door: NodePath           ## room -> room
@export_file("*.tscn") var target_scene := "" ## level exit
@export var target_spawn: StringName        ## spawn id in the target scene
@export var locked := false:
	set(value):
		locked = value
		queue_redraw()
@export var key_id: StringName              ## item that unlocks it
@export var set_flag: StringName            ## Game flag set when going through (e.g. gig done)

var _start_locked := false


func _ready() -> void:
	super()
	_start_locked = locked
	if not Engine.is_editor_hint():
		add_to_group(&"resettable")


func interact(member: BandMember, level: Node) -> void:
	if locked:
		var key := member.inventory.take(key_id) if key_id != &"" else null
		if key == null:
			say("Locked: needs the %s" % _key_name())
			return
		unlock_with(key)
	if set_flag != &"":
		Game.set_flag(set_flag)
	level.go_through(self, member)


## Opened with a keycard: stays open for good (the card is used up).
func unlock_with(_key: ItemData) -> void:
	locked = false
	_start_locked = false
	say("Unlocked")


func _key_name() -> String:
	return String(key_id).replace("_", " ")


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
