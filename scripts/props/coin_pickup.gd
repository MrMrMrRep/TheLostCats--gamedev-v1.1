@tool
class_name CoinPickup
extends Area2D
## A tip jar / a few coins on the floor: touching it adds `coins` once (it
## doesn't come back when the room resets, so dying can't farm it).

@export var coins := 20

var collected := false


func _ready() -> void:
	collision_layer = 1 << 5                # interactable
	collision_mask = 1 << 2                 # player
	monitorable = false
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 14)
	col.shape = rect
	col.position = Vector2(0, -7)
	add_child(col)
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node) -> void:
	if collected or not body is BandMember:
		return
	collected = true
	visible = false
	Game.add_coins(coins)
	Audio.sfx(&"coin")
	body.show_text("+%d coins" % coins, Color("ffd36b"))


func _draw() -> void:
	for i in 3:
		draw_circle(Vector2(-3 + i * 3, -3 - i * 2), 3.0, Color("f2bc58"))
		draw_arc(Vector2(-3 + i * 3, -3 - i * 2), 3.0, 0.0, TAU, 10, Color("b8823a"), 1.0)
