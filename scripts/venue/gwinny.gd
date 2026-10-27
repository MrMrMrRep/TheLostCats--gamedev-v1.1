class_name Gwinny
extends Interactable
## Hidden fan up in the rafters of Café De Kat. A quiet hum gives her away.
## Talking to her is optional; it turns the gig from Finished into Completed.

const CUE := preload("res://audio/sfx/gwinny.wav")


func _ready() -> void:
	prompt = "E"
	area_size = Vector2(36, 40)
	super()
	var sprite := AnimatedSprite2D.new()
	sprite.sprite_frames = load("res://resources/sprites/char_blue_frames.tres")
	sprite.animation = &"idle"
	sprite.offset = Vector2(0, -22)
	sprite.scale = Vector2(0.85, 0.85)
	sprite.modulate = Color("e2dc7c")
	sprite.play(&"idle")
	add_child(sprite)
	var hum := AudioStreamPlayer2D.new()
	hum.stream = CUE
	hum.volume_db = -18.0
	hum.max_distance = 560.0
	hum.attenuation = 1.6
	hum.bus = &"SFX"
	if hum.stream is AudioStreamWAV:
		hum.stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	hum.autoplay = not Engine.is_editor_hint()
	add_child(hum)


func interact(_member: BandMember, _level: Node) -> void:
	var game: Node = Engine.get_main_loop().root.get_node("Game")
	game.set_flag(&"gwinny_met", true)
	say("Psst. Gwinny. I know every song. Break a leg.")
