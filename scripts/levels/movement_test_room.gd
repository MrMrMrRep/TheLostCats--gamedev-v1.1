extends "res://scripts/levels/baseline_level.gd"
## M3 movement test room. Keys 1-5 swap the player's movement profile so each
## band member's feel can be compared; hold F4 to drain stamina (hover rate).
## M4 replaces profile swapping with real switching between 5 band members.

@export var profiles: Array[MovementProfile] = []

@onready var player: Player = $Player
@onready var hud: CanvasLayer = $HUD
@onready var debug_overlay: CanvasLayer = $DebugOverlay


func _ready() -> void:
	super()
	debug_overlay.player = player
	hud.bind_player(player)


func _physics_process(delta: float) -> void:
	for i in profiles.size():
		if Input.is_action_just_pressed("select_%d" % (i + 1)):
			player.profile = profiles[i]
			hud.bind_player(player)
	if Input.is_key_pressed(KEY_F4):
		player.stamina.spend(player.stamina_config.hover_per_sec * delta)
