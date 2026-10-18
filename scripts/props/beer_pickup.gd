@tool
class_name BeerPickup
extends Area2D
## Beer bottle: the first band member to touch it carries it (max 3 for now;
## the M7 inventory takes over). Drink with B. Collected beer stays collected.

var collected := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 2                 # player
	monitorable = false
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(10, 16)
	col.shape = rect
	col.position = Vector2(0, -8)
	add_child(col)
	if not Engine.is_editor_hint():
		body_entered.connect(_on_body_entered)


func _on_body_entered(body: Node2D) -> void:
	if collected or not body is BandMember:
		return
	if body.add_beer():
		collected = true
		visible = false
		set_deferred("monitoring", false)


func _draw() -> void:
	draw_rect(Rect2(-3, -12, 6, 10), Color("8a4a1a"))
	draw_rect(Rect2(-1.5, -16, 3, 4), Color("8a4a1a"))
	draw_rect(Rect2(-3, -9, 6, 3), Color("f0e0b0"))
