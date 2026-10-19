class_name NightGlow
extends Node2D
## Light that shows at night: lit windows and the glow of lamps. Added by a
## building, the street furniture or a WorldLight as a child at runtime (never
## saved). Drawn unshaded and additive, so the night tint doesn't darken it,
## and the canal reflects it. Each light switches on when the night is deeper
## than its own `threshold`, so they don't all come on at once.

const GLASS_ON := Color(0.85, 0.55, 0.22, 0.8)
const HALO := Color(1.0, 0.82, 0.5, 0.55)

static var _material: CanvasItemMaterial
static var _halo: GradientTexture2D

var rects: Array = []                       # [Rect2, threshold, Color]
var halos: Array = []                       # [centre Vector2, radius, threshold, Color, y squash]
var night := 0.0:
	set(value):
		if absf(value - night) < 0.002:
			return
		night = value
		visible = night > 0.001
		queue_redraw()


## A glow child for `owner_node` (internal: not shown in the editor, never
## saved). Only in the game, not in the editor.
static func attach(owner_node: Node) -> NightGlow:
	if Engine.is_editor_hint():
		return null
	var g := NightGlow.new()
	g.name = "NightGlow"
	owner_node.add_child(g, false, Node.INTERNAL_MODE_BACK)
	return g


## Threshold for a window: lit-by-day ones first, then a share of the rest
## (DayConfig.night_windows) one by one as the night deepens.
static func window_threshold(x: float, y: float, lit_by_day: bool) -> float:
	if lit_by_day:
		return 0.02
	return 0.1 + spot_hash(x, y) * 0.9 / maxf(DayConfig.current().night_windows, 0.01)


func _init() -> void:
	if _material == null:
		_material = CanvasItemMaterial.new()
		_material.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
		_material.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = _material
	visible = false


func _enter_tree() -> void:
	add_to_group(&"night_glow")
	night = WorldDayCycle.night_now


func set_night(amount: float) -> void:
	night = amount


## A lit window (local rect), coming on at `threshold`.
func add_window(r: Rect2, threshold: float) -> void:
	rects.append([r, threshold, GLASS_ON])


## A lamp's halo around `centre`, plus a pool of light on the ground at `floor_y` (local).
func add_lamp(centre: Vector2, radius: float, floor_y: float, threshold: float, color := HALO) -> void:
	halos.append([centre, radius, threshold, color, 1.0])
	if not is_nan(floor_y):                 # NAN: no pool on the ground
		halos.append([Vector2(centre.x, floor_y), radius * 1.5, threshold, Color(color, color.a * 0.6), 0.22])


## A free halo (car lights, a sign): `squash` < 1 flattens it.
func add_halo(centre: Vector2, radius: float, threshold: float, color: Color, squash := 1.0) -> void:
	halos.append([centre, radius, threshold, color, squash])


func clear() -> void:
	rects.clear()
	halos.clear()


static func halo_texture() -> GradientTexture2D:
	if _halo == null:
		var g := Gradient.new()
		g.offsets = PackedFloat32Array([0.0, 0.25, 1.0])
		g.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
		_halo = GradientTexture2D.new()
		_halo.gradient = g
		_halo.fill = GradientTexture2D.FILL_RADIAL
		_halo.fill_from = Vector2(0.5, 0.5)
		_halo.fill_to = Vector2(1.0, 0.5)
		_halo.width = 64
		_halo.height = 64
	return _halo


## How far a light with `threshold` is on at this night amount (0..1).
func level(threshold: float) -> float:
	return clampf((night - threshold) * 5.0, 0.0, 1.0)


func _draw() -> void:
	for r in rects:
		var a := level(r[1])
		if a > 0.0:
			var c: Color = r[2]
			draw_rect(r[0], Color(c, c.a * a))
			draw_rect((r[0] as Rect2).grow(1.5), Color(c, c.a * a * 0.18))
	var tex := halo_texture()
	for h in halos:
		var a := level(h[2])
		if a > 0.0:
			var rad: float = h[1]
			var sq: float = h[4]
			var c: Color = h[3]
			draw_texture_rect(tex, Rect2(h[0] - Vector2(rad, rad * sq), Vector2(rad * 2.0, rad * 2.0 * sq)), false, Color(c, c.a * a))


## A stable 0..1 number for a spot (no RNG calls, so the day art never changes).
static func spot_hash(x: float, y: float) -> float:
	return float(hash(Vector2i(int(x * 4.0), int(y * 4.0))) % 10007) / 10007.0
