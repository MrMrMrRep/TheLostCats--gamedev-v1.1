extends Node2D
## Dev/test room: clamps the band camera to the room and wires the HUD and the
## F3 debug overlay to the active member. Hold F4 to drain the active member's
## stamina (45/s). Replaced by the Room framework in M5.

@export var bounds := Rect2i(0, 0, 1440, 180)   ## playable area in pixels

@onready var band: Band = $Band
@onready var hud: CanvasLayer = $HUD
@onready var debug_overlay: CanvasLayer = get_node_or_null("DebugOverlay")


func _ready() -> void:
	var camera := band.camera
	camera.limit_left = bounds.position.x
	camera.limit_top = bounds.position.y
	camera.limit_right = bounds.end.x
	camera.limit_bottom = bounds.end.y
	camera.reset_smoothing()
	hud.bind_band(band)
	if debug_overlay:
		debug_overlay.player = band.active
		band.active_changed.connect(func(member: BandMember, _i: int) -> void: debug_overlay.player = member)


func _physics_process(delta: float) -> void:
	if Input.is_key_pressed(KEY_F4) and band.active.stamina_config:
		band.active.stamina.spend(45.0 * delta)
