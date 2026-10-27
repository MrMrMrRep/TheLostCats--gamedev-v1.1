@tool
class_name WorldStreet
extends Node2D
## The street the band walks on and its edge toward the water, across the whole
## map. In town: cobbles, curb, stone quay wall, iron railing and bollards.
## Outside town: a motorway with a median barrier, edge lines, a hard shoulder,
## a guardrail and a grass verge down to the ditch.
## Origin at x 0, y = the street line (the band's feet).

@export var map_width := 3840.0
@export var map_min := 0.0
@export var town := Vector2(1100, 3640)

const STREET_H := 14.0
const EDGE_H := 36.0                        # town: street + curb + quay wall down to the water
const ROAD_H := 27.0                        # outside town: carriageway + hard shoulder
const VERGE_H := 11.0                       # grass verge from the guardrail down to the ditch
const ROAD_WATER := ROAD_H + VERGE_H        # outside town the ditch starts this far down
const COBBLE := preload("res://assets/sprites/world/canal/cobble.png")


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED   # the v3 street strip repeats


func _draw() -> void:
	var p := WorldPalette
	# Town: the v3 street (pavement tiles, kerb, cobbles, quay with bollards
	# and mooring rings), one baked strip repeated along the town.
	var a := town.x
	var b := town.y
	if WorldPalette.V3:
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
		for seg: V3Art in segments():
			var t := seg.texture()
			if t:
				draw_texture(t, Vector2(seg.origin))
		draw_set_transform(Vector2.ZERO)
		_draw_town_cobble(a, b)
	else:
		_draw_town_legacy(a, b)
	# Outside town: motorway proportions. Behind us the opposite carriageway
	# and a concrete median barrier; our carriageway with a solid edge line on
	# both sides and a dashed lane line (we drive on the far lane, traffic
	# passes on the near one), a hard shoulder, a steel guardrail, a grass
	# verge down to the ditch.
	for seg in [Vector2(map_min - 400, a), Vector2(b, map_width + 400)]:
		var w: float = seg.y - seg.x
		var x0: float = seg.x
		draw_rect(Rect2(x0, -10, w, 8), p.ROAD.lerp(p.HAZE, 0.3))
		var xo := x0
		while xo < seg.y:
			draw_rect(Rect2(xo, -7, 9, 1), p.WHITE.lerp(p.HAZE, 0.5))
			xo += 27
		draw_rect(Rect2(x0, -3, w, 3), WorldPalette.W3)                 # median barrier
		draw_rect(Rect2(x0, -3, w, 1), WorldPalette.W4)
		draw_rect(Rect2(x0, 0, w, ROAD_H), p.ROAD)
		draw_rect(Rect2(x0, 1, w, 1), p.WHITE.lerp(p.ROAD, 0.25))        # edge line by the median
		var xd := x0
		while xd < seg.y:
			draw_rect(Rect2(xd, 11, 9, 1), p.WHITE.lerp(p.ROAD, 0.3))    # lane line (3 : 9)
			xd += 36
		draw_rect(Rect2(x0, 21, w, 1), p.WHITE.lerp(p.ROAD, 0.2))        # edge line by the shoulder
		draw_rect(Rect2(x0, 22, w, ROAD_H - 22), p.ROAD.lightened(0.06)) # hard shoulder
		draw_rect(Rect2(x0, ROAD_H, w, VERGE_H), p.GRASS[0])
		draw_rect(Rect2(x0, ROAD_H, w, 1), p.GRASS[1])
		draw_rect(Rect2(x0, ROAD_H - 2, w, 2), WorldPalette.R3)          # guardrail
		draw_rect(Rect2(x0, ROAD_H - 2, w, 1), WorldPalette.W4)
		var xp := x0
		while xp < seg.y:
			draw_rect(Rect2(xp, ROAD_H, 1, 3), WorldPalette.R1)
			xp += 12
		_motorway_details(x0, seg.y)


## SpriteCook setts, one band tall, repeated along the town road. Covers the
## pavement and the quay top so the ground matches the canal terrace; the
## motorway outside town is left alone.
func _draw_town_cobble(a: float, b: float) -> void:
	var th := float(COBBLE.get_height())
	draw_texture_rect(COBBLE, Rect2(a, 0.0, b - a, th), true)


const STREET_PAINTER := preload("res://scripts/world/v3/v3_street.gd")
const SEGMENT := 2048                       ## art px per baked street piece
const OLD_ZONES := ["OldTown", "CanalBelt"]
const INDUSTRY_ZONES := ["Industry", "Storage"]

var _segments: Array = []


## The town street in pieces of SEGMENT art px (StreetPainter: the district
## from the Zone nodes, bridges and side street mouths from the SideOpenings).
## Each piece's origin.x is its art x.
func segments() -> Array:
	if not _segments.is_empty():
		return _segments
	var zones := []
	for z in WorldZone.all(self):
		var r: Vector2 = z.span()
		var k: int = STREET_PAINTER.Kind.NEW
		if String(z.name) in OLD_ZONES:
			k = STREET_PAINTER.Kind.OLD
		elif String(z.name) in INDUSTRY_ZONES:
			k = STREET_PAINTER.Kind.INDUSTRY
		zones.append([int(r.x * 2.0), int(r.y * 2.0), k])
	var bridges := []
	var mouths := []
	var root := get_tree().edited_scene_root if Engine.is_editor_hint() else owner
	if root == null:
		root = get_parent()
	for o in root.find_children("*", "SideOpening", true, false):
		var c := int((o as Node2D).global_position.x * 2.0)
		var half := int(o.open_width)
		if o.kind == SideOpening.Kind.CANAL:
			bridges.append([c - half, c + half])
		else:
			mouths.append([c - half, c + half])
	var a := int(town.x * 2.0)
	var b := int(town.y * 2.0)
	var spec := "%s|%s|%s" % [zones, bridges, mouths]
	var x := a
	while x < b:
		var w := mini(SEGMENT, b - x)
		var x0 := x
		var key := "street_seg|%d|%d|%s|cobble2" % [x0, w, spec.md5_text()]
		var art := V3Cache.art(key, func() -> V3Art:
			return STREET_PAINTER.street_segment(x0, w, zones, bridges, mouths))
		art.origin = Vector2i(x0, 0)
		_segments.append(art)
		x += w
	return _segments


## Motorway life: asphalt repairs and tyre marks, white reflector posts on the
## verge and the green hectometre posts (every 100 m, with their number).
func _motorway_details(a: float, b: float) -> void:
	var p := WorldPalette
	var x := a - fposmod(a, 50.0)
	while x < b:
		var h := NightGlow.spot_hash(x, 31.0)
		if h < 0.18:                        # a darker repaired strip
			draw_rect(Rect2(x, 3 + int(h * 40.0), 18 + h * 60.0, 3), p.T0.lerp(p.ROAD, 0.5))
		elif h < 0.3:                       # tyre marks
			draw_rect(Rect2(x, 15, 30, 1), p.T0.lerp(p.ROAD, 0.3))
			draw_rect(Rect2(x + 4, 18, 26, 1), p.T0.lerp(p.ROAD, 0.3))
		x += 50.0
	var xr := a - fposmod(a, 25.0)
	while xr < b:                           # reflector posts on the verge
		draw_rect(Rect2(xr, ROAD_H - 6, 1, 6), p.WHITE)
		draw_rect(Rect2(xr, ROAD_H - 5, 1, 1), p.O2)
		xr += 25.0
	var xh := a - fposmod(a, 100.0)
	while xh < b:                           # hectometre posts
		draw_rect(Rect2(xh + 12, ROAD_H - 9, 3, 9), p.G1)
		draw_rect(Rect2(xh + 12, ROAD_H - 9, 3, 3), p.WHITE)
		xh += 100.0


func _draw_town_legacy(a: float, b: float) -> void:
	var p := WorldPalette
	draw_rect(Rect2(a, 0, b - a, STREET_H), p.COBBLE)
	for y in range(2, int(STREET_H), 3):
		var xs := a - fposmod(a, 6.0) - (y % 2) * 3
		while xs < b:
			draw_rect(Rect2(xs, y, 4, 1), p.COBBLE_DARK)
			xs += 6
	draw_rect(Rect2(a, STREET_H, b - a, 2), p.CURB)
	draw_rect(Rect2(a, STREET_H + 2, b - a, EDGE_H - STREET_H - 2), p.QUAY)
	for y in range(int(STREET_H) + 3, int(EDGE_H), 3):
		var xq := a + (y % 2) * 5
		while xq < b:
			draw_rect(Rect2(xq, y, 1, 3), p.QUAY_DARK)
			xq += 10
	var xr := a
	while xr < b:
		draw_rect(Rect2(xr, 8, 1, 8), p.IRON)
		xr += 10
	draw_rect(Rect2(a, 8, b - a, 1), p.IRON)
	var xb := a + 30
	while xb < b:
		draw_rect(Rect2(xb, 10, 3, 6), p.IRON)
		xb += 90
