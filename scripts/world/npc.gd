@tool
class_name Npc
extends Interactable
## A person on the world map you can talk to (E). Shows "!" when they have a
## quest for you and "?" when you've done it. The lines to say depend on the
## quest state; `talked()` moves the quest along. Geordie gives the tour-day-1
## quest: get to Café De Kat, play, come back. He waits at the storage.

const MARKER_COLOR := Color("ffd36b")

@export var speaker := "Geordie"
@export var tint := Color(0.75, 0.6, 0.45)

var _sprite: AnimatedSprite2D


func _ready() -> void:
	area_size = Vector2(36, 36)
	super()
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = load("res://resources/sprites/char_blue_frames.tres")
	_sprite.animation = &"idle"
	_sprite.offset = Vector2(0, -28)
	_sprite.flip_h = true
	_sprite.modulate = tint
	add_child(_sprite)
	if not Engine.is_editor_hint():
		_sprite.play(&"idle")
		Game.flag_changed.connect(func(_f: StringName, _v: Variant) -> void: queue_redraw())


## What they say right now.
func lines() -> Array[String]:
	match Game.get_flag(&"quest_cafe", ""):
		"":
			return [
				"Morning! Van's loaded, coffee's... somewhere.",
				"First gig of the tour: Café De Kat, back in the centre. Soundcheck's soon!",
				"Take the van, but it only stops at the P signs. The bikes by the studio are handy for short hops.",
			]
		"active":
			if Game.get_flag(&"cafe_finished"):
				return [
					"You played Café De Kat?! The whole street is talking about it.",
					"Tour day 1: done. Get some sleep, legends. Tomorrow we do it all again.",
				]
			return ["Café De Kat is west of here, in the centre past the studio. Go on, go!"]
	return ["Rest up. Big day tomorrow."]


## Called after the conversation: advance the quest.
func talked() -> void:
	match Game.get_flag(&"quest_cafe", ""):
		"":
			Game.set_flag(&"quest_cafe", "active")
		"active":
			if Game.get_flag(&"cafe_finished"):
				Game.set_flag(&"quest_cafe", "done")


func marker() -> String:
	var q: String = Game.get_flag(&"quest_cafe", "") if not Engine.is_editor_hint() else ""
	if q == "":
		return "!"
	if q == "active" and Game.get_flag(&"cafe_finished"):
		return "?"
	return ""


func interact(_member: BandMember, map: Node) -> void:
	if map.has_method("talk_to"):
		map.talk_to(self)


func _draw() -> void:
	var m := marker()
	if m != "":
		var bob := sin(Time.get_ticks_msec() / 250.0) * 1.5 if not Engine.is_editor_hint() else 0.0
		draw_string(ThemeDB.fallback_font, Vector2(-3, -48 + bob), m, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, MARKER_COLOR)


func _process(delta: float) -> void:
	super(delta)
	if marker() != "":
		queue_redraw()
