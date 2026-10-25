@tool
class_name SideOpening
extends Node2D
## An opening in the canal-house row, in the style v3 look: a side canal
## (with a brick bridge in front), a wide side street, an alley or a narrow
## steeg, seen in perspective, with v3 houses filling the rest of the slot.
## Painted by V3Painter.side_opening (the mock: tools/style_mock_v3_alleys.gd),
## baked by tools/bake_world_v3.tscn. Origin = the slot's middle on the street line.

enum Kind { CANAL, STREET, ALLEY, STEEG }
const KINDS := ["canal", "street", "alley", "steeg"]

@export var kind := Kind.CANAL:
	set(value):
		kind = value
		_changed()
@export var width := 290.0:                 ## the whole slot between the house rows (world px)
	set(value):
		width = value
		_changed()
@export var open_width := 120.0:            ## the opening itself, centred in the slot (world px)
	set(value):
		open_width = value
		_changed()
@export var seed_value := 1:
	set(value):
		seed_value = value
		_changed()
@export var poort := false:                 ## steeg only: a covered gateway under the house
	set(value):
		poort = value
		_changed()

var _front: Node2D                          # the bridge: over the street and the canal


func _ready() -> void:
	_changed()


func _changed() -> void:
	queue_redraw()
	if not is_inside_tree():
		return
	var bridge := kind == Kind.CANAL
	if bridge and _front == null:
		_front = Node2D.new()
		_front.name = "Bridge"
		_front.z_index = 1
		_front.draw.connect(_draw_front)
		add_child(_front, false, Node.INTERNAL_MODE_FRONT)
	elif not bridge and _front != null:
		_front.queue_free()
		_front = null
	if _front:
		_front.queue_redraw()


func _draw() -> void:
	if WorldPalette.V3:
		v3_art().draw(self)


func _draw_front() -> void:
	if WorldPalette.V3 and _front:
		bridge_art().draw(_front)


## The opening + its houses (baked once, see V3Cache).
func v3_art() -> V3Art:
	var key := "opening%d_%d|%s|%s|%s" % [kind, seed_value, width, open_width, poort]
	var paint := func() -> V3Art:
		return V3Painter.side_opening(KINDS[kind], width, open_width, seed_value, poort)
	return V3Cache.art(key, paint)


## The bridge in front of a side canal.
func bridge_art() -> V3Art:
	var key := "sidebridge_%d|%s" % [seed_value, open_width]
	var paint := func() -> V3Art: return V3Painter.side_bridge(open_width, seed_value)
	return V3Cache.art(key, paint)
