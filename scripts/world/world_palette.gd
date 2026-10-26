class_name WorldPalette
extends RefCounted
## The world-map palette, shared by all world art: the 32 colours of the
## style v2/v3 mocks (docs/art/style_v2_palette.png, docs/art/style_v3_*).
## T teal/navy ramp, W warm sand/wood, B brick/coral, O ochre/orange,
## G greens, R stone greys, P0 plum. The named colours below (SKY_TOP, ROOF...)
## are picked from these 32. Everything the world draws is snapped to the 32
## colours by the palette filter (snap_material) or painted in them directly
## (the v3 painter, scripts/world/v3/).

const V3 := true                            ## draw the world in the style v3 look (baked art, v3 sky/water/street)

const T0 := Color("1d2838")
const T1 := Color("2c4152")
const T2 := Color("35606c")
const T3 := Color("4b8189")
const T4 := Color("64a2a6")
const T5 := Color("86c1bb")
const T6 := Color("b0dcc9")
const T7 := Color("dcefd2")
const W0 := Color("4a3434")
const W1 := Color("7a5a4a")
const W2 := Color("b08e6c")
const W3 := Color("d8bf94")
const W4 := Color("f3e4bc")
const W5 := Color("fff7df")
const B0 := Color("5e2e36")
const B1 := Color("8f3f40")
const B2 := Color("bd5a4b")
const B3 := Color("e07d5e")
const B4 := Color("f2a77a")
const O1 := Color("e08a36")
const O2 := Color("f2bc58")
const O3 := Color("f8dc8a")
const G0 := Color("2b4434")
const G1 := Color("46663a")
const G2 := Color("789a3e")
const G3 := Color("b3c04a")
const G4 := Color("e2dc7c")
const R0 := Color("3d4552")
const R1 := Color("586170")
const R2 := Color("7c8590")
const R3 := Color("a6adb0")
const P0 := Color("4e3f5c")
const PALETTE := [T0, T1, T2, T3, T4, T5, T6, T7, W0, W1, W2, W3, W4, W5,
	B0, B1, B2, B3, B4, O1, O2, O3, G0, G1, G2, G3, G4, R0, R1, R2, R3, P0]

const SKY_TOP := T4                         # (was T3; brighter, closer to the reference street scene)
const SKY_MID := T5
const SKY_LOW := T7
const CLOUD := W5
const CLOUD_SHADE := T7
const CLOUD_DARK := T6
const SUN := O3
const HAZE := T4
const HAZE_DARK := T3

const NAVY := T0
const GLASS := T0
const LIT := O2
const TRIM := W4
const WHITE := W5
const ROOF := W0
const ORANGE := O1
const FACADES := [T3, T4, O1, B3, B2, B0, P0, O2, T1, B4]

const COBBLE := R2
const COBBLE_DARK := R1
const CURB := R3
const QUAY := R1
const QUAY_DARK := R0
const IRON := T0

const WATER := T2
const WATER_DEEP := T1
const WATER_HI := T5
const DITCH := T2

const LEAF := [G0, G1, G2]
const TRUNK := W0
const GRASS := [G1, G2, G3]
const FIELD_FAR := G3
const BARN := B1
const BARN_DARK := B0
const MILL := W0
const SAIL := W4
const TURBINE := W5
const ROAD := R0

const SNAP_SHADER := preload("res://shaders/palette_snap.gdshader")
static var _snap_mat: ShaderMaterial


## The nearest of the 32 colours (the mocks' weighting: green counts most).
static func nearest(c: Color) -> Color:
	var best: Color = PALETTE[0]
	var bd := INF
	for p: Color in PALETTE:
		var dr := (c.r - p.r) * 0.30
		var dg := (c.g - p.g) * 0.59
		var db := (c.b - p.b) * 0.11
		var d := dr * dr + dg * dg + db * db
		if d < bd:
			bd = d
			best = p
	return best


## The palette filter: a material that snaps whatever a node draws to the 32
## colours (through a lookup table baked by tools/bake_world_v3.gd). Alpha and
## the night tint (CanvasModulate, applied after) are left alone.
static func snap_material() -> ShaderMaterial:
	if _snap_mat == null:
		_snap_mat = ShaderMaterial.new()
		_snap_mat.shader = SNAP_SHADER
		var lut := V3Cache.art("palette_lut", func() -> V3Art: return V3Painter.palette_lut())
		_snap_mat.set_shader_parameter("lut", lut.texture())
	return _snap_mat


## Puts the palette filter on every world node under `root` that draws its
## own colours, now and when added later (traffic, people). Leaves out nodes
## with a material of their own (water, lights), CanvasLayers (sky, HUD),
## the `keep` subtrees (the band: its sprites keep their colours) and the
## v3-baked buildings (already in the palette).
static func snap_tree(root: Node, keep: Array[Node]) -> void:
	if not V3:
		return
	_snap(root, keep)
	var tree := root.get_tree()
	var on_added := func(n: Node) -> void: _added(n, root, keep)
	tree.node_added.connect(on_added)
	root.tree_exiting.connect(func() -> void: tree.node_added.disconnect(on_added), CONNECT_ONE_SHOT)


static func _added(n: Node, root: Node, keep: Array[Node]) -> void:
	if is_instance_valid(root) and root.is_ancestor_of(n) and _snappable(n, keep):
		_snap_one(n)


static func _snap(n: Node, keep: Array[Node]) -> void:
	if n in keep or n is CanvasLayer:
		return
	_snap_one(n)
	for c in n.get_children():
		_snap(c, keep)


static func _snappable(n: Node, keep: Array[Node]) -> bool:
	var p := n
	while p:
		if p in keep or p is CanvasLayer:
			return false
		p = p.get_parent()
	return true


static func _snap_one(n: Node) -> void:
	var ci := n as CanvasItem
	if ci == null or ci.material != null or ci is NightGlow:
		return
	if ci is CityBlock or (ci is WorldBuilding and (ci as WorldBuilding).kind != WorldBuilding.Kind.ROUND_HOTEL):
		return
	ci.material = snap_material()


## Filled circle made of rects (crisp pixel discs).
static func disc(ci: CanvasItem, cx: float, cy: float, r: int, c: Color) -> void:
	for y in range(-r, r + 1):
		var half := int(sqrt(maxf(r * r - y * y, 0.0)))
		ci.draw_rect(Rect2(cx - half, cy + y, half * 2 + 1, 1), c)


static func triangle(ci: CanvasItem, x: float, base: float, w: float, h: int, c: Color) -> void:
	for y in h:
		var half := int(w / 2.0 * (1.0 - float(y) / h))
		ci.draw_rect(Rect2(x + w / 2.0 - half, base - y - 1, half * 2, 1), c)


static func tree(ci: CanvasItem, x: float, base: float, r: int, tint := 0.0) -> void:
	if V3:                                  # the v3 leaf-cluster trees (hazy teal in the distance)
		var v := posmod(int(x * 7.0) + r, 3)
		var art := WorldScenery.v3_sprite(("treeh%d" if tint > 0.15 else "tree%d") % v)
		art.draw(ci, Vector2(x, base), 0.5 if r >= 9 else 0.4)
		return
	ci.draw_rect(Rect2(x - 1, base - r, 3, r), TRUNK.lerp(HAZE, tint))
	disc(ci, x, base - r - r / 2, r, LEAF[0].lerp(HAZE, tint))
	disc(ci, x - 3, base - r - r / 2 - 3, r - 3, LEAF[1].lerp(HAZE, tint))
	disc(ci, x - 5, base - r - r / 2 - 6, maxi(r - 7, 1), LEAF[2].lerp(HAZE, tint))
