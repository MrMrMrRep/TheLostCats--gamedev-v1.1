@tool
class_name WorldHighway
extends Node2D
## A highway coming out of the distance and joining our road: a raised road on
## an embankment that starts small and hazy near the horizon to the west and
## sweeps down to the street at this node's origin (the merge point), with a
## guard rail, lamps, a blue sign and cars that come down it and merge.

const HORIZON_Y := -40.0                    # the far end sits on the horizon
const CAR_COLOURS := [Color("c94a3d"), Color("5b7fa6"), Color("fbf8f2"), Color("2a2830"), Color("e0b23a"), Color("8a8f99")]

@export var length := 1100.0:
	set(value):
		length = value
		queue_redraw()
@export var sign_text := "A10  CENTRUM"
@export var cars := 7

var _cars: Array = []                       # [t 0..1 along the ramp, speed in t/s, colour, truck]


func _ready() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12
	for i in cars:
		_cars.append([rng.randf(), rng.randf_range(0.05, 0.09), CAR_COLOURS[i % CAR_COLOURS.size()], i % 4 == 3])


## Point on the road's centre line at t (0 = far end, 1 = merge) and its size.
func ramp(t: float) -> Array:
	var e := t * t * (3.0 - 2.0 * t)        # ease: flat far away, sweeping down near us
	var pos := Vector2(lerpf(-length, 0.0, t), lerpf(HORIZON_Y + 1.0, -3.0, e))
	return [pos, lerpf(0.25, 1.0, t)]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	for c in _cars:
		c[0] += c[1] * delta * lerpf(0.6, 1.4, c[0])     # looks faster when close
		if c[0] >= 1.0:
			c[0] = 0.0
	queue_redraw()


func _draw() -> void:
	var p := WorldPalette
	var steps := 40
	var haze := p.HAZE
	# Embankment and road surface, far to near.
	for i in steps:
		var a: Array = ramp(float(i) / steps)
		var b: Array = ramp(float(i + 1) / steps)
		var t := float(i) / steps
		var s: float = a[1]
		var x0: float = a[0].x
		var x1: float = b[0].x
		var y: float = a[0].y
		var thick := maxf(1.0, 7.0 * s)
		var bank: Color = p.GRASS[0].lerp(haze, 0.6 * (1.0 - t))
		if -y - thick > 0.0:
			draw_rect(Rect2(x0, y + thick, x1 - x0 + 1, -y - thick + 1), bank)
		draw_rect(Rect2(x0, y, x1 - x0 + 1, thick), p.ROAD.lerp(haze, 0.6 * (1.0 - t)))
		if i % 2 == 0 and s > 0.4:
			draw_rect(Rect2(x0, y + thick / 2.0, (x1 - x0) * 0.6, 1), p.WHITE.lerp(p.ROAD, 0.4))
	# Guard rail and lamp posts along the top edge.
	var k := 0
	while k <= steps:
		var a: Array = ramp(float(k) / steps)
		var s: float = a[1]
		var top: Vector2 = a[0]
		var rail := p.CURB.lerp(haze, 0.6 * (1.0 - float(k) / steps))
		draw_rect(Rect2(top.x, top.y - 3.0 * s, 1, 3.0 * s), rail)
		if k % 8 == 4:
			draw_rect(Rect2(top.x, top.y - 22.0 * s, 1, 22.0 * s), rail)
			draw_rect(Rect2(top.x - 2.0 * s, top.y - 23.0 * s, 4.0 * s, 1), p.LIT.lerp(haze, 0.4))
		k += 1
	for i in steps:
		var a: Array = ramp(float(i) / steps)
		var b: Array = ramp(float(i + 1) / steps)
		draw_line(a[0] + Vector2(0, -3.0 * a[1]), b[0] + Vector2(0, -3.0 * b[1]), p.CURB.lerp(haze, 0.5 * (1.0 - float(i) / steps)), 1.0)
	# Blue motorway sign near the merge.
	var sx := -170.0
	var sy: float = ramp(1.0 - 170.0 / length)[0].y
	draw_rect(Rect2(sx, sy - 34, 2, 34), p.IRON)
	draw_rect(Rect2(sx + 40, sy - 34, 2, 34), p.IRON)
	draw_rect(Rect2(sx - 6, sy - 48, 54, 16), Color("2a5bd7"))
	draw_rect(Rect2(sx - 6, sy - 48, 54, 1), p.WHITE)
	draw_string(ThemeDB.fallback_font, Vector2(sx - 6, sy - 37), sign_text, HORIZONTAL_ALIGNMENT_CENTER, 54, 7, p.WHITE)
	# Cars coming down.
	for c in _cars:
		var a: Array = ramp(c[0])
		var s: float = a[1]
		var pos: Vector2 = a[0]
		var col: Color = (c[2] as Color).lerp(haze, 0.6 * (1.0 - c[0]))
		var w := (34.0 if c[3] else 18.0) * s
		var h := (12.0 if c[3] else 6.0) * s
		draw_rect(Rect2(pos.x - w / 2.0, pos.y - h, w, h), col)
		if not c[3]:
			draw_rect(Rect2(pos.x - w / 4.0, pos.y - h - 3.0 * s, w / 2.0, 3.0 * s), col.darkened(0.2))
