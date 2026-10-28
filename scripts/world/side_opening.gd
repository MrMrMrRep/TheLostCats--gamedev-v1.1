@tool
class_name SideOpening
extends Node2D
## An opening in the canal-house row: a side canal, a side street or a narrow
## steeg seen in one-point perspective between two complete corner houses,
## one SpriteCook canal-kit piece (CanalKit, `piece()`). The piece's width is
## the slot: the house rows (CityBlock.kit) stop at `span()`, and the street
## puts its arch under `mouth()`. `width` / `open_width` only matter to the
## older v3 tools (v3_art, bridge_art). Origin = the slot's middle on the street line.

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
@export var district := &"canal":           ## which district's views (DISTRICT_PIECES): canal, oldtown, wallen, flats
	set(value):
		district = value
		_changed()
@export var poort := false:                 ## steeg only: a covered gateway under the house
	set(value):
		poort = value
		_changed()

var _front: Node2D                          # the bridge: over the street and the canal
var _glow: NightGlow                        # its bulbs at night


func _ready() -> void:
	_glow_back = NightGlow.attach(self)
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
		# (The canal kit's street has no railing on its bridges, so no bulbs.)


func _draw() -> void:
	if _glow_back:
		_glow_back.clear()
	# One SpriteCook kit piece: the view between two complete corner houses
	# (flat kit fronts, their own side walls and roofs running into the depth).
	var n := piece()
	var tex := CanalRow.texture(n)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	draw_texture(tex, Vector2(-tex.get_width() / 2, -tex.get_height() - CanalRow.LIFT))
	draw_set_transform(Vector2.ZERO)
	CanalRow.add_glow(_glow_back, [[n, -tex.get_width() / 2, 0]])
	if _glow_back:
		_glow_back.queue_redraw()


const PIECES := {
	Kind.CANAL: [&"open_canal_a", &"open_canal_c", &"open_canal_b", &"open_canal_d"],
	Kind.STREET: [&"open_street_a", &"open_street_b"],
	Kind.ALLEY: [&"open_steeg"],
	Kind.STEEG: [&"open_steeg"],
}
## Per district (`district`), where it has its own views; other kinds fall back to PIECES.
const DISTRICT_PIECES := {
	&"oldtown": {Kind.STREET: [&"open_ot_street"], Kind.ALLEY: [&"open_ot_steeg"], Kind.STEEG: [&"open_ot_steeg"]},
	&"wallen": {Kind.CANAL: [&"open_wal_canal"], Kind.ALLEY: [&"open_wal_steeg"], Kind.STEEG: [&"open_wal_steeg"]},
	&"flats": {Kind.STREET: [&"open_fl_street"]},
}

var _glow_back: NightGlow                   # the corner houses' windows at night


## The kit piece for this opening (by kind; seed_value picks among them).
func piece() -> StringName:
	var list: Array = DISTRICT_PIECES.get(district, {}).get(kind, PIECES[kind])
	return list[posmod(seed_value, list.size())]


## World x range the piece covers (its two corner houses included): the
## house rows stop at these edges.
func span() -> Vector2:
	var half := CanalRow.width(piece()) * 0.25
	return Vector2(global_position.x - half, global_position.x + half)


## World x range of the side canal's water at the street (the street's
## arch goes there). A side street has none: Vector2.ZERO.
func mouth() -> Vector2:
	var n := piece()
	if not CanalKit.MOUTHS.has(n):
		return Vector2.ZERO
	var m: Vector2i = CanalKit.MOUTHS[n]
	var left := global_position.x - CanalRow.width(n) * 0.25
	return Vector2(left + m.x * 0.5, left + m.y * 0.5)


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
