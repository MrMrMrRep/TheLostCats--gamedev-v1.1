@tool
class_name WorldAirport
extends Node2D
## The apron and runway beside the terminal, seen over a fence: a parked
## plane with a stair truck and baggage carts, a windsock, light poles, and
## now and then a plane that rolls down the runway, rotates and climbs away.
## Planes are drawn a bit smaller than true scale: they're further back.
## Origin = street level at the field's left end; `length` = field width.

const CYCLE := 42.0                          # seconds between take-offs
const ROLL := 11.0                           # take-off run + climb, seconds

@export var length := 1200.0:
	set(value):
		length = value
		queue_redraw()


func _process(_delta: float) -> void:
	if not Engine.is_editor_hint():
		queue_redraw()


func _draw() -> void:
	var p := WorldPalette
	# Apron and runway behind the fence (they sit a little higher: further away).
	draw_rect(Rect2(0, -14, length, 12), WorldPalette.W2)
	draw_rect(Rect2(0, -22, length, 8), WorldPalette.R1)
	for x in range(0, int(length), 40):
		draw_rect(Rect2(x, -18, 20, 1), p.WHITE)
	for x in range(60, int(length), 180):                      # light poles
		draw_rect(Rect2(x, -110, 3, 96), WorldPalette.R2)
		draw_rect(Rect2(x - 8, -112, 19, 4), WorldPalette.R2)
		draw_rect(Rect2(x - 7, -110, 17, 2), WorldPalette.W4)
	_windsock(length - 80, -14)
	# Parked plane with a stair truck and baggage carts.
	_plane(Vector2(length * 0.28, -14), 1.0, 0.0, 1.0)
	draw_rect(Rect2(length * 0.28 + 40, -40, 26, 4), WorldPalette.O2)
	draw_line(Vector2(length * 0.28 + 40, -36), Vector2(length * 0.28 + 30, -14), WorldPalette.R2, 2.0)
	for k in 3:
		draw_rect(Rect2(length * 0.28 - 60 - k * 18, -22, 14, 8), WorldPalette.W3)
		draw_rect(Rect2(length * 0.28 - 60 - k * 18, -14, 3, 3), PixelArt.OUTLINE)
	# The plane taking off.
	var t := fmod(Time.get_ticks_msec() / 1000.0, CYCLE)
	if t < ROLL:
		var u := t / ROLL
		var x := lerpf(length * 0.45, length * 1.6, u * u)
		var climb := maxf(0.0, (u - 0.55) / 0.45)
		var y := -22.0 - climb * climb * 160.0
		_plane(Vector2(x, y), lerpf(0.85, 0.6, climb), -0.18 * minf(climb * 3.0, 1.0), 1.0 - climb * 0.3)
	# Chain-link fence in front.
	draw_rect(Rect2(0, -30, length, 1), WorldPalette.R2)
	for x in range(0, int(length), 30):
		draw_rect(Rect2(x, -30, 2, 30), WorldPalette.R2)
	for x in range(0, int(length), 4):
		draw_line(Vector2(x, -30), Vector2(x + 6, 0), Color(0.55, 0.57, 0.6, 0.35), 1.0)


func _windsock(x: float, y: float) -> void:
	draw_rect(Rect2(x, y - 40, 2, 40), WorldPalette.W3)
	var wave := sin(Time.get_ticks_msec() / 400.0) * 2.0
	for k in 4:
		draw_rect(Rect2(x + 2 + k * 5, y - 40 + k * 0.5 + wave * k * 0.3, 5, 6 - k), WorldPalette.B3 if k % 2 == 0 else WorldPalette.W5)


## Airliner side view, nose to the right; `s` scale, `rot` pitch (rad).
func _plane(pos: Vector2, s: float, rot: float, alpha: float) -> void:
	draw_set_transform(pos, rot, Vector2(s, s))
	var body := Color(0.95, 0.95, 0.97, alpha)
	var o := Color(PixelArt.OUTLINE, alpha)
	var tail := Color(WorldPalette.T1, alpha)
	draw_rect(Rect2(-90, -30, 180, 18), o)
	draw_rect(Rect2(-89, -29, 178, 16), body)
	WorldPalette.triangle(self, 86, -12, 10, 16, body)       # nose
	draw_rect(Rect2(88, -26, 6, 5), Color(WorldPalette.R0, alpha))
	draw_rect(Rect2(-120, -18, 40, 6), body)                 # tail cone
	draw_rect(Rect2(-112, -62, 22, 34), tail)                # fin
	draw_rect(Rect2(-89, -18, 178, 3), tail)
	for x in range(-70, 80, 9):
		draw_rect(Rect2(x, -25, 4, 4), Color(WorldPalette.R0, alpha))
	draw_rect(Rect2(-20, -16, 60, 6), Color(WorldPalette.W3, alpha))   # wing
	draw_rect(Rect2(0, -12, 22, 8), Color(WorldPalette.R3, alpha))     # engine
	draw_rect(Rect2(-10, -6, 3, 6), o)                                  # gear
	draw_rect(Rect2(70, -6, 3, 6), o)
	draw_set_transform(Vector2.ZERO)
