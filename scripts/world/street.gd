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
const EDGE_H := 36.0                        # town: sidewalk + curb + quay wall, down to the water
const ROAD_H := 27.0                        # outside town: carriageway + hard shoulder
const VERGE_H := 11.0                       # grass verge from the guardrail down to the ditch
const ROAD_WATER := ROAD_H + VERGE_H        # outside town the ditch starts this far down
## SpriteCook strips, 1 texel = 1 world px, tiled along the street.
const SETTS := preload("res://assets/sprites/world/canal/setts.png")
const CURB_SETT := preload("res://assets/sprites/world/canal/curb.png")
const WALL := preload("res://assets/sprites/world/canal/wall.png")
const PAVER := preload("res://assets/sprites/world/canal/paver.png")
const CURB_ROAD := preload("res://assets/sprites/world/canal/curb_road.png")
const ASPHALT := preload("res://assets/sprites/world/canal/asphalt.png")
const BRIDGE := preload("res://assets/sprites/world/canal/bridge_span.png")
const SETTS_H := 16.0
const CURB_H := 4.0
const WALL_H := 16.0
const PAVER_H := 10.0
const ROAD_CURB_H := 3.0
const ASPHALT_H := 7.0                      # 10 + 3 + 7 + 16 = the 36 down to the water
const BRIDGE_DECK := 25.0                   # source row that sits on the street line
const BRIDGE_ARCH := 51.0                   # source row where the arch opens


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
		_draw_town_surfaces(a, b)
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


## Cobble setts along the old town and the canal belt, concrete pavers and
## asphalt on the ring, and the same stone quay wall wherever the canal is.
## A canal opening is a bridge (iron rail, one arch) instead of the wall.
func _draw_town_surfaces(a: float, b: float) -> void:
	var holes := _bridge_spans()
	var centre := _centre_span()
	var canal := _canal_span()
	var cuts: Array[float] = [a, b, centre.x, centre.y, canal.x, canal.y]
	for hole: Vector2 in holes:
		cuts.append(hole.x)
		cuts.append(hole.y)
	cuts.sort()
	var xs: Array[float] = []
	for x: float in cuts:
		if xs.is_empty() or x > xs[-1] + 0.5:
			xs.append(x)
	for i in xs.size() - 1:
		var x0 := xs[i]
		var x1 := xs[i + 1]
		if x1 - x0 < 1.0 or _covered(x0, holes):
			continue
		_draw_piece(x0, x1, centre, canal)
	for hole: Vector2 in holes:
		var x0 := maxf(hole.x, a)
		var x1 := minf(hole.y, b)
		if x1 - x0 > 1.0:
			_draw_bridge(x0, x1)


func _covered(x: float, holes: Array) -> bool:
	for hole: Vector2 in holes:
		if x >= hole.x and x < hole.y:
			return true
	return false


func _draw_piece(a: float, b: float, centre: Vector2, canal: Vector2) -> void:
	if b - a < 1.0:
		return
	var mid := (a + b) * 0.5
	var on_centre := mid >= centre.x and mid < centre.y
	var on_canal := mid >= canal.x and mid < canal.y
	if on_centre:
		_tile(SETTS, a, 0.0, b - a, SETTS_H)
		_tile(CURB_SETT, a, SETTS_H, b - a, CURB_H)
		_tile(WALL, a, SETTS_H + CURB_H, b - a, WALL_H)
	elif on_canal:
		_tile(PAVER, a, 0.0, b - a, PAVER_H)
		_tile(CURB_ROAD, a, PAVER_H, b - a, ROAD_CURB_H)
		_tile(ASPHALT, a, PAVER_H + ROAD_CURB_H, b - a, ASPHALT_H)
		_tile(WALL, a, EDGE_H - WALL_H, b - a, WALL_H)
	else:
		_tile(PAVER, a, 0.0, b - a, 12.0)
		_tile(CURB_ROAD, a, 12.0, b - a, 4.0)
		_tile(ASPHALT, a, 16.0, b - a, EDGE_H - 16.0)


func _tile(tex: Texture2D, x: float, y: float, w: float, h: float) -> void:
	draw_texture_rect(tex, Rect2(x, y, w, h), true)


## One arch module stretched across the opening. The deck is the street line;
## the railing stands above it and the arch meets the water.
func _draw_bridge(a: float, b: float) -> void:
	var bh := float(BRIDGE.get_height())
	var scale := EDGE_H / (bh - BRIDGE_DECK)
	var arch_y := (BRIDGE_ARCH - BRIDGE_DECK) * scale
	draw_rect(Rect2(a, arch_y, b - a, EDGE_H - arch_y), WorldPalette.T1)
	draw_rect(Rect2(a, arch_y + 4.0, b - a, 2.0), WorldPalette.T2)
	var saved := texture_repeat
	texture_repeat = CanvasItem.TEXTURE_REPEAT_DISABLED
	draw_texture_rect(BRIDGE, Rect2(a - 2.0, -BRIDGE_DECK * scale, b - a + 4.0, bh * scale), false)
	texture_repeat = saved


var _bridges: Array[Vector2] = []
var _bridges_ready := false
var _canal := Vector2(-1, -1)


func _bridge_spans() -> Array[Vector2]:
	if _bridges_ready:
		return _bridges
	_bridges_ready = true
	var root := _map_root()
	if root == null:
		return _bridges
	for o in root.find_children("*", "SideOpening", true, false):
		var op := o as SideOpening
		if op.kind != SideOpening.Kind.CANAL:
			continue
		var c := op.global_position.x - global_position.x
		var half := op.open_width * 0.5
		_bridges.append(Vector2(c - half, c + half))
	_bridges.sort_custom(func(p: Vector2, q: Vector2) -> bool: return p.x < q.x)
	return _bridges


func _canal_span() -> Vector2:
	if _canal.x >= 0.0:
		return _canal
	_canal = Vector2(7092.0, town.y)
	var root := _map_root()
	if root == null:
		return _canal
	var canal := root.find_child("Canal", true, false)
	if canal is ColorRect:
		var rect := canal as ColorRect
		var origin := 0.0
		if canal.get_parent() is Node2D:
			origin = (canal.get_parent() as Node2D).global_position.x
		_canal = Vector2(origin + rect.offset_left, origin + rect.offset_right)
	return _canal


func _map_root() -> Node:
	if not is_inside_tree():
		return null
	var n: Node = self
	while n.get_parent():
		n = n.get_parent()
	return n


func _centre_span() -> Vector2:
	var a := town.x
	var b := town.y
	var found := false
	if is_inside_tree():
		for z in WorldZone.all(self):
			if String(z.name) in ["OldTown", "CanalBelt"]:
				var r: Vector2 = z.span()
				if not found:
					a = r.x
					b = r.y
					found = true
				else:
					a = minf(a, r.x)
					b = maxf(b, r.y)
	return Vector2(a, b)


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
