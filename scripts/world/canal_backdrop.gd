@tool
class_name CanalBackdrop
extends Node2D
## A background band of the canal kit (CanalKit) in a WorldParallax layer,
## between world x `span`: the far skyline with the church towers, the hazy
## back row of houses, or the backyard trees between that row and the street.
## Drawn at 1 texel = 1 art px. Strips repeat mirrored (A, A flipped, A...) so
## every join is seamless; the yards come in clumps with gaps. The WorldScenery
## in the same layer leaves `span` to this node (its `skip`).
## Origin: x 0 of the layer, y 0; `base` = the strip's foot (world y).

enum Kind { SKYLINE, BACK_ROW, YARDS }

const STRIPS := {
	Kind.SKYLINE: [&"skyline_a", &"skyline_b"],
	Kind.BACK_ROW: [&"back_row"],
	Kind.YARDS: [&"yard_a", &"yard_b"],
}
const NIGHT_FAR := Color(0.5, 0.52, 0.62)   # the far skyline goes dark against the night sky (as WorldScenery)

@export var kind := Kind.SKYLINE:
	set(value):
		kind = value
		queue_redraw()
@export var span := Vector2(9884, 16436):   ## world x range
	set(value):
		span = value
		queue_redraw()
@export var base := 250.0:                  ## world y of the strip's foot
	set(value):
		base = value
		queue_redraw()
@export var seed_value := 3:
	set(value):
		seed_value = value
		queue_redraw()
@export var edge_fade := 160.0:             ## world px at each end where the strip sinks away
	set(value):
		edge_fade = value
		queue_redraw()


func _factor() -> float:
	var p := get_parent()
	return p.factor if p is WorldParallax else 1.0


func _process(_delta: float) -> void:
	if Engine.is_editor_hint() or kind != Kind.SKYLINE:
		return
	self_modulate = Color.WHITE.lerp(NIGHT_FAR, WorldDayCycle.night_now)


func _draw() -> void:
	var f := _factor()
	# Art px in the layer's local space: world x * f, drawn at scale 0.5.
	var a := span.x * f * 2.0
	var b := span.y * f * 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var names: Array = STRIPS[kind]
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	var x := a
	var i := 0
	while x < b:
		var n: StringName = names[i % names.size()] if kind != Kind.SKYLINE else names[rng.randi_range(0, names.size() - 1)]
		var tex := CanalRow.texture(n)
		var w := tex.get_width()
		var h := tex.get_height()
		var flip := i % 2 == 1
		var sink := _sink(x + w * 0.5, a, b)
		var top := base * 2.0 - h + sink
		var shown := mini(w, int(b - x))
		if flip:
			draw_set_transform(Vector2(x * 0.5 + shown * 0.5, 0.0), 0.0, Vector2(-0.5, 0.5))
			draw_texture_rect_region(tex, Rect2(0, top, shown, h), Rect2(w - shown, 0, shown, h))
			draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
		else:
			draw_texture_rect_region(tex, Rect2(x, top, shown, h), Rect2(0, 0, shown, h))
		x += w
		if kind == Kind.YARDS:
			x += rng.randi_range(120, 520)  # clumps of trees, not a hedge
		i += 1
	draw_set_transform(Vector2.ZERO)


## The strip sinks below the houses at its ends instead of stopping in mid-air.
func _sink(x: float, a: float, b: float) -> float:
	var fade := edge_fade * _factor() * 2.0
	if fade <= 0.0:
		return 0.0
	var d := minf(x - a, b - x)
	return 0.0 if d >= fade else roundf((1.0 - d / fade) * 120.0)
