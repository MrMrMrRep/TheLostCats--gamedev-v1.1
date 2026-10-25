@tool
class_name WorldDoor
extends Interactable
## Door on the world map: into a level (venue, service station...) or, without
## a target, a building that isn't open yet (says `closed_text`).

@export_file("*.tscn") var target_scene := ""
@export var target_spawn: StringName = &"Start"
@export var closed_text := "Closed for now."
@export var sign_text := ""
@export var width := 22.0


func _ready() -> void:
	area_size = Vector2(width + 8, 40)
	super()


func interact(_member: BandMember, map: Node) -> void:
	if target_scene == "":
		say(closed_text)
		return
	if map.has_method("enter_door"):
		map.enter_door(self)


func _draw() -> void:
	var h := 38.0
	draw_rect(Rect2(-width / 2, -h, width, h), WorldPalette.T0)
	draw_rect(Rect2(-width / 2, -h, width, h), WorldPalette.W1, false, 2.0)
	draw_circle(Vector2(width / 2 - 5, -h / 2), 1.5, WorldPalette.O3)
