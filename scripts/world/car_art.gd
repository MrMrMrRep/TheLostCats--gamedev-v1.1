class_name CarArt
extends RefCounted
## Cars drawn at the band sprites' density (art px), facing right, tyres on
## y 0. One generator, many body styles: city car, hatchback, saloon, estate,
## SUV, MPV, taxi and a vintage beetle, each with its own proportions, plus
## extras picked by a seed (roof box, bike on the roof, a racing stripe).
## Every car sits on the ground: a contact shadow, tyres flattened where they
## touch, dark wheel arches.

enum Style { CITY, HATCH, SALOON, ESTATE, SUV, MPV, TAXI, BEETLE }

# length, sill (ground to body), body (sill to beltline), roof (belt to top),
# hood (front to windscreen foot), wind (windscreen run), rear (rear glass run),
# trunk (boot length), wheel radius
const SPECS := {
	Style.CITY: [94.0, 6.0, 20.0, 18.0, 18.0, 12.0, 6.0, 0.0, 9.0],
	Style.HATCH: [116.0, 7.0, 21.0, 19.0, 26.0, 16.0, 12.0, 0.0, 10.0],
	Style.SALOON: [134.0, 7.0, 20.0, 18.0, 30.0, 18.0, 14.0, 22.0, 10.0],
	Style.ESTATE: [138.0, 7.0, 21.0, 19.0, 30.0, 16.0, 4.0, 0.0, 10.0],
	Style.SUV: [132.0, 12.0, 25.0, 21.0, 28.0, 14.0, 6.0, 0.0, 13.0],
	Style.MPV: [130.0, 8.0, 24.0, 24.0, 16.0, 26.0, 4.0, 0.0, 10.0],
	Style.TAXI: [134.0, 7.0, 20.0, 18.0, 30.0, 18.0, 14.0, 22.0, 10.0],
	Style.BEETLE: [100.0, 8.0, 18.0, 22.0, 0.0, 0.0, 0.0, 0.0, 10.0],
}
const COLOURS := [Color("c94a3d"), Color("2a4ea0"), Color("f2efe8"), Color("2a2a2e"), Color("e0b23a"),
	Color("6f8f5a"), Color("8a8f99"), Color("3a4a6a"), Color("9a2a3a"), Color("d8d0c0"), Color("4a6a8a"), Color("e07a2e")]


static func colour(seed: int) -> Color:
	return COLOURS[absi(seed) % COLOURS.size()]


static func style_for(seed: int) -> int:
	var r := absi(seed * 7919) % 100
	if r < 16: return Style.CITY
	if r < 40: return Style.HATCH
	if r < 56: return Style.SALOON
	if r < 70: return Style.ESTATE
	if r < 82: return Style.SUV
	if r < 91: return Style.MPV
	if r < 96: return Style.TAXI
	return Style.BEETLE


## A car of `style` in colour `c`. `phase` turns the wheels; `seed` picks extras.
static func car(ci: CanvasItem, style: int, c: Color, alpha: float, phase: float, seed: int) -> void:
	if style == Style.TAXI:
		c = Color("1e1e22")
	c = Color(c, alpha)
	var o := Color(PixelArt.OUTLINE, alpha)
	var sp: Array = SPECS[style]
	var hl: float = sp[0] / 2.0
	var sill: float = sp[1]
	var belt: float = -sill - sp[2]
	var top: float = belt - sp[3]
	var r: float = sp[8]
	var wb: float = sp[0] * 0.31
	shadow(ci, sp[0], alpha)
	if style == Style.BEETLE:
		_beetle(ci, c, o, hl, sill, alpha, phase, wb, r)
		return
	# Lower body with rounded corners, then the cabin.
	var body := PackedVector2Array([Vector2(-hl, -sill - 3), Vector2(-hl + 3, -sill), Vector2(hl - 3, -sill),
		Vector2(hl, -sill - 3), Vector2(hl, belt + 5), Vector2(hl - 6, belt), Vector2(-hl + 3, belt), Vector2(-hl, belt + 4)])
	var hood: float = sp[4]
	var wind: float = sp[5]
	var rear: float = sp[6]
	var trunk: float = sp[7]
	var cabin := PackedVector2Array([Vector2(hl - hood, belt), Vector2(hl - hood - wind, top),
		Vector2(-hl + trunk + rear + 2, top), Vector2(-hl + trunk, belt)])
	ci.draw_colored_polygon(body, c)
	ci.draw_colored_polygon(cabin, c)
	_outline(ci, body, o)
	_outline(ci, cabin, o)
	ci.draw_rect(Rect2(-hl + 4, top + 1, (hl - hood - wind) - (-hl + trunk + rear) - 4, 2), c.lightened(0.25))   # roof shine
	ci.draw_rect(Rect2(-hl + 2, belt + 1, sp[0] - 8, 1), c.lightened(0.2))                                       # beltline
	ci.draw_rect(Rect2(-hl + 2, -sill - 5, sp[0] - 4, 4), c.darkened(0.3))                                       # sill / bumper line
	# Windows with pillars.
	var g := Color(Color("3a4a62"), alpha)
	var win := PackedVector2Array([Vector2(hl - hood - 3, belt - 2), Vector2(hl - hood - wind + 1, top + 3),
		Vector2(-hl + trunk + rear + 4, top + 3), Vector2(-hl + trunk + 3, belt - 2)])
	ci.draw_colored_polygon(win, g)
	var mid := (hl - hood - wind + (-hl + trunk + rear)) / 2.0
	ci.draw_rect(Rect2(mid - 1, top + 2, 3, belt - top - 2), c)                                                   # B pillar
	if style == Style.ESTATE or style == Style.MPV or style == Style.SUV:
		ci.draw_rect(Rect2(-hl + trunk + 16, top + 2, 3, belt - top - 2), c)                                     # C pillar
	ci.draw_line(Vector2(mid + 6, belt - 3), Vector2(mid + 14, top + 4), Color(1, 1, 1, 0.22 * alpha), 2.0)        # glass glint
	# Doors, handles, mirror, lights.
	ci.draw_rect(Rect2(hl - hood - 3, belt, 1, sp[2] - 4), c.darkened(0.3))
	ci.draw_rect(Rect2(mid, belt, 1, sp[2] - 4), c.darkened(0.3))
	ci.draw_rect(Rect2(mid + 5, belt + 4, 5, 1), c.darkened(0.4))
	ci.draw_rect(Rect2(mid - 12, belt + 4, 5, 1), c.darkened(0.4))
	ci.draw_rect(Rect2(hl - hood - 2, belt - 4, 4, 3), c.darkened(0.25))
	ci.draw_rect(Rect2(hl - 5, belt + 3, 5, 4), Color(Color("f6e8b0"), alpha))
	ci.draw_rect(Rect2(-hl, belt + 3, 3, 5), Color(Color("d83a2a"), alpha))
	ci.draw_rect(Rect2(hl - 4, -sill - 6, 4, 3), Color(Color("f2c14a"), alpha))                                   # indicator
	# Extras.
	var x := absi(seed * 31) % 100
	if style == Style.TAXI:
		ci.draw_rect(Rect2(mid - 8, top - 6, 16, 6), Color(Color("f2c14a"), alpha))
		ci.draw_string(ThemeDB.fallback_font, Vector2(mid - 8, top - 1), "TAXI", HORIZONTAL_ALIGNMENT_CENTER, 16, 5, o)
	elif x < 14:                                                                                                  # roof box
		ci.draw_rect(Rect2(mid - 20, top - 7, 40, 6), Color(Color("2a2a2e"), alpha))
		ci.draw_rect(Rect2(mid - 18, top - 7, 36, 1), Color(Color("4a4a50"), alpha))
	elif x < 20:                                                                                                  # a bike on the roof
		ci.draw_line(Vector2(mid - 22, top - 1), Vector2(mid + 22, top - 1), o, 1.0)
		ci.draw_arc(Vector2(mid - 12, top - 9), 7, 0, TAU, 12, o, 1.0)
		ci.draw_arc(Vector2(mid + 12, top - 9), 7, 0, TAU, 12, o, 1.0)
		ci.draw_line(Vector2(mid - 12, top - 9), Vector2(mid, top - 16), Color(Color("c94a3d"), alpha), 1.0)
		ci.draw_line(Vector2(mid, top - 16), Vector2(mid + 12, top - 9), Color(Color("c94a3d"), alpha), 1.0)
	elif x < 28:                                                                                                  # racing stripe
		ci.draw_rect(Rect2(-hl + 4, belt + 8, sp[0] - 10, 2), Color(Color.WHITE, 0.7 * alpha))
	wheel(ci, wb, r, alpha, phase)
	wheel(ci, -wb, r, alpha, phase)


static func shadow(ci: CanvasItem, length: float, alpha: float) -> void:
	ci.draw_rect(Rect2(-length / 2.0 + 4, -2, length - 8, 4), Color(0, 0, 0, 0.32 * alpha))
	ci.draw_rect(Rect2(-length / 2.0 + 10, -1, length - 20, 3), Color(0, 0, 0, 0.18 * alpha))


## Arch, tyre flattened where it meets the road, hub and a turning spoke.
static func wheel(ci: CanvasItem, x: float, r: float, alpha: float, phase: float) -> void:
	var c := Vector2(x, -r + 1)
	ci.draw_circle(c, r + 3, Color(0.08, 0.08, 0.1, alpha))
	ci.draw_circle(c, r, Color(0.13, 0.13, 0.15, alpha))
	ci.draw_rect(Rect2(x - r * 0.7, -2, r * 1.4, 2), Color(0.13, 0.13, 0.15, alpha))
	ci.draw_circle(c, r * 0.52, Color(0.62, 0.62, 0.66, alpha))
	ci.draw_circle(c, r * 0.2, Color(0.35, 0.35, 0.4, alpha))
	var a := phase * 2.0 / r
	ci.draw_line(c, c + Vector2(cos(a), sin(a)) * r * 0.5, Color(0.3, 0.3, 0.34, alpha), 1.0)


static func _outline(ci: CanvasItem, pts: PackedVector2Array, o: Color) -> void:
	var loop := pts.duplicate()
	loop.append(pts[0])
	ci.draw_polyline(loop, o, 1.0)


static func _beetle(ci: CanvasItem, c: Color, o: Color, hl: float, sill: float, alpha: float, phase: float, wb: float, r: float) -> void:
	var pts := PackedVector2Array()
	for i in 25:                                                  # one rounded hump
		var t := float(i) / 24.0
		var x := lerpf(-hl, hl, t)
		var u := absf(x) / hl
		pts.append(Vector2(x, -sill - 40.0 * sqrt(maxf(0.0, 1.0 - pow(u, 2.6)))))
	pts.append(Vector2(hl, -sill))
	pts.append(Vector2(-hl, -sill))
	ci.draw_colored_polygon(pts, c)
	_outline(ci, pts, o)
	for fx in [wb, -wb]:                                          # round fenders
		ci.draw_circle(Vector2(fx, -sill - 6), r + 5, c)
	ci.draw_circle(Vector2(-6, -sill - 28), 13, Color(Color("3a4a62"), alpha))
	ci.draw_rect(Rect2(-7, -sill - 40, 3, 26), c)
	ci.draw_rect(Rect2(-hl + 4, -sill - 3, hl * 2 - 8, 2), Color(Color("c9ccd2"), alpha))
	ci.draw_rect(Rect2(hl - 8, -sill - 14, 4, 4), Color(Color("f6e8b0"), alpha))
	wheel(ci, wb, r, alpha, phase)
	wheel(ci, -wb, r, alpha, phase)
