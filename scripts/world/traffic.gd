@tool
class_name WorldTraffic
extends Node2D
## Traffic the band never bumps into: cars on their own lane, kept around the
## camera only (spawned just off screen, dropped when far behind).
##   BACK   a lane just behind the street, drawn behind the band, smaller and
##          a little hazy. Outside town: cars, vans, trucks; in town: mostly bikes.
##   FRONT  an extra lane in front of the road outside town, drawn in front of
##          the band (and reflected in the water). None in town (canal quay).
## Origin at x 0, y = the street line.

enum Lane { BACK, FRONT }

const LANE_Y := {Lane.BACK: -3.0, Lane.FRONT: 19.0}
const COLOURS := [Color("c94a3d"), Color("5b7fa6"), Color("fbf8f2"), Color("2a2830"), Color("e0b23a"), Color("6f8f5a"), Color("8a8f99")]
const FADE := 40.0                          # front-lane cars fade out where the road turns into the quay

@export var lane := Lane.BACK
@export var town := Vector2(1100, 3640)
@export var map_width := 3840.0
@export var per_screen_road := 5            ## cars per screen width outside town
@export var per_screen_town := 2            ## bikes/cars per screen width in town (back lane)

var _cars: Array = []                       # [x, dir, speed, kind 0 car 1 van 2 truck 3 bike, colour, phase]
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 7 + lane


func _in_town(x: float) -> bool:
	return x >= town.x and x <= town.y


func _view() -> Vector2:
	var cam := get_viewport().get_camera_2d() if is_inside_tree() else null
	if cam == null:
		return Vector2(0, 640)
	var half := 320.0 / cam.zoom.x + 120.0
	var cx := cam.get_screen_center_position().x
	return Vector2(cx - half, cx + half)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var view := _view()
	var span := view.y - view.x
	for c in _cars:
		c[0] += c[1] * c[2] * delta
		c[5] += absf(c[2]) * delta
	_cars = _cars.filter(func(c: Array) -> bool:
		return c[0] > view.x - span * 0.6 and c[0] < view.y + span * 0.6 \
			and not (lane == Lane.FRONT and _in_town(c[0]) and _town_depth(c[0]) > FADE))
	var mid := (view.x + view.y) / 2.0
	var want := int(round(span / 640.0 * (per_screen_town if _in_town(mid) else per_screen_road)))
	if lane == Lane.FRONT and _in_town(mid):
		want = 0
	if _cars.size() < want:
		_spawn(view)
	queue_redraw()


## How far x is inside town (for the front lane's fade).
func _town_depth(x: float) -> float:
	return minf(x - town.x, town.y - x)


func _spawn(view: Vector2) -> void:
	var dir := 1.0 if _rng.randf() < 0.5 else -1.0
	var x := view.x - 30.0 if dir > 0.0 else view.y + 30.0
	if _rng.randf() < 0.3:                   # now and then one appears ahead, coming toward us
		x = _rng.randf_range(view.x, view.y)
		if absf(x - (view.x + view.y) / 2.0) < (view.y - view.x) * 0.45:
			return
	x = clampf(x, 0.0, map_width)
	var kind := 0
	if _in_town(x):
		if lane == Lane.FRONT:
			return
		kind = 3 if _rng.randf() < 0.7 else 0
	else:
		var r := _rng.randf()
		kind = 2 if r < 0.18 else (1 if r < 0.4 else 0)
	var speed: float = [_rng.randf_range(90, 170), _rng.randf_range(80, 150), _rng.randf_range(60, 105), _rng.randf_range(35, 55)][kind]
	_cars.append([x, dir, speed, kind, COLOURS[_rng.randi_range(0, COLOURS.size() - 1)], 0.0])


func _draw() -> void:
	var y: float = LANE_Y[lane]
	var back := lane == Lane.BACK
	for c in _cars:
		var col: Color = c[4]
		var alpha := 1.0
		if lane == Lane.FRONT and _in_town(c[0]):
			alpha = clampf(1.0 - _town_depth(c[0]) / FADE, 0.0, 1.0)
		if back:
			col = col.lerp(WorldPalette.HAZE, 0.25)
		draw_set_transform(Vector2(c[0], y), 0.0, Vector2(c[1] * (0.8 if back else 1.0), 0.8 if back else 1.0))
		match int(c[3]):
			0: _car(col, alpha, c[5])
			1: _van(col, alpha, c[5])
			2: _truck(col, alpha, c[5])
			3: _bike(col, alpha, c[5])
	draw_set_transform(Vector2.ZERO)


func _wheel(x: float, r: float, alpha: float, phase: float) -> void:
	draw_circle(Vector2(x, -r), r, Color(0.12, 0.12, 0.14, alpha))
	var a := phase / r
	draw_line(Vector2(x, -r), Vector2(x + cos(a) * (r - 1), -r + sin(a) * (r - 1)), Color(0.6, 0.6, 0.65, alpha), 1.0)


func _car(c: Color, alpha: float, phase: float) -> void:
	var a := Color(c, alpha)
	var glass := Color(WorldPalette.GLASS.lightened(0.25), alpha)
	draw_rect(Rect2(-14, -9, 28, 6), a)
	draw_rect(Rect2(-8, -14, 15, 5), a.darkened(0.1))
	draw_rect(Rect2(-6, -13, 5, 4), glass)
	draw_rect(Rect2(0, -13, 6, 4), glass)
	draw_rect(Rect2(12, -8, 2, 2), Color(WorldPalette.LIT, alpha))
	draw_rect(Rect2(-14, -8, 1, 2), Color(0.8, 0.15, 0.1, alpha))
	_wheel(-8, 3, alpha, phase)
	_wheel(8, 3, alpha, phase)


func _van(c: Color, alpha: float, phase: float) -> void:
	var a := Color(c, alpha)
	var glass := Color(WorldPalette.GLASS.lightened(0.25), alpha)
	draw_rect(Rect2(-16, -16, 32, 13), a)
	draw_rect(Rect2(8, -14, 7, 5), glass)
	draw_rect(Rect2(-14, -14, 18, 1), a.darkened(0.15))
	_wheel(-10, 3, alpha, phase)
	_wheel(10, 3, alpha, phase)


func _truck(c: Color, alpha: float, phase: float) -> void:
	var a := Color(c, alpha)
	var box := Color(WorldPalette.WHITE.darkened(0.08), alpha)
	draw_rect(Rect2(-30, -22, 42, 18), box)
	draw_rect(Rect2(-30, -22, 42, 2), a)
	draw_rect(Rect2(13, -17, 14, 13), a)
	draw_rect(Rect2(19, -15, 7, 5), Color(WorldPalette.GLASS.lightened(0.25), alpha))
	_wheel(-24, 3.5, alpha, phase)
	_wheel(-15, 3.5, alpha, phase)
	_wheel(20, 3.5, alpha, phase)


func _bike(c: Color, alpha: float, phase: float) -> void:
	var frame := Color(0.15, 0.15, 0.18, alpha)
	draw_arc(Vector2(-5, -4), 4, 0, TAU, 10, frame, 1.0)
	draw_arc(Vector2(5, -4), 4, 0, TAU, 10, frame, 1.0)
	draw_line(Vector2(-5, -4), Vector2(0, -8), frame, 1.0)
	draw_line(Vector2(0, -8), Vector2(5, -4), frame, 1.0)
	var leg := sin(phase * 0.4) * 2.0
	draw_rect(Rect2(-2, -18, 4, 8), Color(c, alpha))                        # rider
	draw_rect(Rect2(-1, -22, 3, 3), Color(0.9, 0.75, 0.6, alpha))
	draw_line(Vector2(0, -10), Vector2(leg, -5), frame, 1.0)
