@tool
class_name Amp
extends Node2D
## A big amp. Hack it (Joep, a wall plug, or his shockwave) and it blares for
## a few seconds: rats near it are stunned by the noise and people who can be
## distracted turn to look at it. Origin = bottom centre. Resets on death.

const BLARE_TIME := 4.0
const RADIUS := 120.0

var blare_left := 0.0


func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group(&"hackable")
		add_to_group(&"resettable")


func hack(_by: BandMember = null) -> bool:
	if blare_left > 0.0:
		return false
	blare_left = BLARE_TIME
	Audio.sfx(&"bass", 0.0)
	FloatText.spawn(get_parent(), global_position + Vector2(0, -40), "WAAAAH", Color("ffd36b"))
	return true


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or blare_left <= 0.0:
		return
	blare_left -= delta
	queue_redraw()
	for rat in get_tree().get_nodes_in_group(&"rat"):
		if rat.alive and rat.global_position.distance_to(global_position) <= RADIUS:
			rat.stun(0.5)
	for h in get_tree().get_nodes_in_group(&"human"):
		if h.global_position.distance_to(global_position) <= RADIUS * 1.5 and h.has_method("distract"):
			h.distract(global_position, 0.5)


func reset_state() -> void:
	blare_left = 0.0
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(-14, -32, 28, 32), Color("1d1a22"))
	draw_rect(Rect2(-14, -32, 28, 32), Color("5a5f6a"), false, 1.0)
	draw_circle(Vector2(0, -12), 8.0, Color("3a3e48"))
	draw_circle(Vector2(0, -12), 3.0, Color("1d1a22"))
	draw_rect(Rect2(-10, -29, 20, 4), Color("8a6a42"))
	draw_circle(Vector2(9, -27), 1.2, Color("4fe07a") if blare_left > 0.0 else Color("e0544f"))
	if blare_left > 0.0:
		var t := fmod(blare_left * 3.0, 1.0)
		for i in 2:
			draw_arc(Vector2(0, -12), 14.0 + (t + i * 0.5) * 30.0, -0.6, 0.6, 8, Color(1, 0.85, 0.4, 0.6 - t * 0.5), 1.0)
			draw_arc(Vector2(0, -12), 14.0 + (t + i * 0.5) * 30.0, PI - 0.6, PI + 0.6, 8, Color(1, 0.85, 0.4, 0.6 - t * 0.5), 1.0)
