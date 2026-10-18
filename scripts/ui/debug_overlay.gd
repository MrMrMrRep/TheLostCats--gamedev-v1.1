extends CanvasLayer
## F3 debug overlay: live movement and stamina state of the bound player.

var player: Player

@onready var label: Label = $Label


func _ready() -> void:
	layer = 90
	visible = false


func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("debug_overlay"):
		visible = not visible
	if not visible or player == null:
		return
	var p := player.profile
	var s := player.stamina
	label.text = "\n".join([
		"%s  run %.1f t/s  jump %.1f t" % [p.display_name, p.run_speed_tiles, p.jump_height_tiles],
		"pos  %.0f, %.0f" % [player.position.x, player.position.y],
		"vel  %.0f, %.0f" % [player.velocity.x, player.velocity.y],
		"floor %s  coyote %.2f  buffer %.2f" % [player.is_on_floor(), player.coyote_left, player.buffer_left],
		("stamina %.0f/%.0f%s" % [s.current_stamina, s.max_stamina, "  EXHAUSTED" if s.is_exhausted else ""]) if s.enabled else "stamina —",
		"fps %d" % Engine.get_frames_per_second(),
	])
