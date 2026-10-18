@tool
class_name ItemPickup
extends Area2D
## An item lying in the world. The first band member to touch it with a free
## slot carries it. Dropped items ignore the dropper for a moment so they don't
## jump straight back into the same hands. Collected items stay collected.

const IGNORE_TIME := 1.0

@export var item: ItemData = preload("res://resources/items/beer.tres"):
	set(value):
		item = value
		queue_redraw()

var collected := false

var _ignored: Node
var _ignore_left := 0.0


func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 << 2                 # player
	monitorable = false
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(12, 16)
	col.shape = rect
	col.position = Vector2(0, -8)
	add_child(col)


func ignore(member: Node) -> void:
	_ignored = member
	_ignore_left = IGNORE_TIME


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or collected:
		return
	_ignore_left = maxf(_ignore_left - delta, 0.0)
	for body in get_overlapping_bodies():
		if body is BandMember and not body.is_dead:
			if body == _ignored and _ignore_left > 0.0:
				continue
			if body.inventory.is_full():
				continue
			if body.add_item(item):
				collected = true
				visible = false
				set_deferred("monitoring", false)
				return


func _draw() -> void:
	if item == null:
		return
	draw_rect(Rect2(-5, -12, 10, 10), Color(0, 0, 0, 0.25))
	draw_set_transform(Vector2(0, -7), 0.0, Vector2(1.4, 1.4))
	item.draw_icon(self, Vector2.ZERO)
	draw_set_transform(Vector2.ZERO)
