@tool
class_name Door
extends Interactable
## Door to go through. Either to another Door in this level
## (room to room) or out of the level to another scene (e.g. the world map).
## The whole band goes through only when everyone stands together (see Level).
## A locked door opens for a member carrying its keycard (key_id): E uses it
## and goes through. Two more kinds of lock: `hack_lock` (electronic: Joep
## hacks it open) and `charm_lock` (staff only: Geoff talks his way in).
## Unlocked with a key, a hack or a charm, it stays unlocked after a death.

@export var target_door: NodePath           ## room -> room
@export_file("*.tscn") var target_scene := "" ## level exit
@export var target_spawn: StringName        ## spawn id in the target scene
@export var locked := false:
	set(value):
		locked = value
		queue_redraw()
@export var key_id: StringName              ## item that unlocks it
@export var set_flag: StringName            ## Game flag set when going through (e.g. gig done)
@export var hack_lock := false:              ## electronic lock: Joep's hack opens it
	set(value):
		hack_lock = value
		queue_redraw()
@export var charm_lock := false:             ## "staff only": Geoff's charm opens it
	set(value):
		charm_lock = value
		queue_redraw()

var _start_locked := false


func _ready() -> void:
	super()
	_start_locked = locked
	if not Engine.is_editor_hint():
		add_to_group(&"resettable")
		if hack_lock:
			add_to_group(&"hackable")
		if charm_lock:
			add_to_group(&"persuadable")


func interact(member: BandMember, level: Node) -> void:
	if locked:
		var key := member.inventory.take(key_id) if key_id != &"" else null
		if key == null:
			if hack_lock:
				say("Electronic lock. A hacker could open it.")
			elif charm_lock:
				say("STAFF ONLY. Someone with charm, maybe?")
			else:
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


## Joep's hack on an electronic lock.
func hack(_by: BandMember = null) -> bool:
	if not (hack_lock and locked):
		return false
	_open_for_good("*beep* Unlocked")
	return true


## Geoff's charm on a staff-only door.
func persuade(_by: BandMember = null) -> bool:
	if not (charm_lock and locked):
		return false
	_open_for_good("Oh, it's Geoff! Come on in.")
	return true


var persuaded: bool:
	get:
		return charm_lock and not locked


func _open_for_good(line: String) -> void:
	locked = false
	_start_locked = false
	say(line)


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
	if hack_lock:
		draw_rect(Rect2(w / 2 - 7, -h / 2 - 8, 5, 8), Color("2a2a34"))
		draw_rect(Rect2(w / 2 - 6, -h / 2 - 7, 3, 2), Color("e0544f") if locked else Color("4fe07a"))
	elif charm_lock:
		draw_rect(Rect2(-9, -h + 5, 18, 6), Color("f2e8da"))
		draw_rect(Rect2(-7, -h + 7, 14, 2), Color("c94a3d") if locked else Color("4fe07a"))
	elif locked:
		draw_rect(Rect2(-4, -h / 2 - 4, 8, 7), Color("c94a3d"))
