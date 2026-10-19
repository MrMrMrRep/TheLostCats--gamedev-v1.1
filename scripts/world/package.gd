@tool
class_name Package
extends Area2D
## A parcel lying on the street: touching it gives coins (once; remembered in
## Game so it stays gone when you come back). Not from inside the van.

@export var coins := 10

var collected := false


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 2                 # player
	monitorable = false
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(14, 12)
	col.shape = rect
	col.position = Vector2(0, -6)
	add_child(col)
	if Engine.is_editor_hint():
		return
	if Game.get_flag(_flag()):
		_hide()
	body_entered.connect(func(body: Node2D) -> void:
		if body is BandMember and body.visible and not collected:
			collect(body))


func collect(by: BandMember) -> void:
	collected = true
	Game.set_flag(_flag())
	Game.add_coins(coins)
	by.show_text("+%d coins" % coins, Color("ffd36b"))
	_hide()


func _flag() -> StringName:
	return StringName("package_" + name)


func _hide() -> void:
	collected = true
	visible = false
	set_deferred("monitoring", false)


func _draw() -> void:
	draw_rect(Rect2(-7, -10, 14, 10), Color("b8864e"))
	draw_rect(Rect2(-7, -10, 14, 10), Color("6a4a2a"), false, 1.0)
	draw_line(Vector2(0, -10), Vector2(0, 0), Color("e8d8a8"), 2.0)
