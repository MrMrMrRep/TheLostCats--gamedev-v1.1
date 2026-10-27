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
var _glow: NightGlow                        # its bulbs at night


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
		if not Engine.is_editor_hint() and _glow == null:
			_glow = NightGlow.attach(_front)
			if _glow:                       # bulbs along the new railing
				var n := 3
				for i in n:
					var x := -open_width * 0.5 + open_width * (float(i) + 0.5) / float(n)
					_glow.add_lamp(Vector2(x, -6.0), 3.0, NAN, 0.02, Color(1.0, 0.8, 0.45, 0.7))


func _draw() -> void:
	if WorldPalette.V3:
		var refined := refined_art()
		(refined if refined else v3_art()).draw(self)


const REFINED_DIR := "res://assets/sprites/world/openings/"


## A hand-refined version of this opening (the painted art touched up, e.g.
## with SpriteCook: far end closed, wall tops with gables), saved as
## REFINED_DIR/<node name>.res with the same origin as the painted art.
## When there is none, the painted art is used.
func refined_art() -> V3Art:
	if _refined_checked:
		return _refined
	_refined_checked = true
	var path := REFINED_DIR + String(name) + ".res"
	if ResourceLoader.exists(path):
		_refined = load(path) as V3Art   # kept: its texture must outlive the draw call
	return _refined


var _refined: V3Art
var _refined_checked := false


func _draw_front() -> void:
	# The street draws the SpriteCook arch. This node only keeps the night bulbs.
	pass


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
