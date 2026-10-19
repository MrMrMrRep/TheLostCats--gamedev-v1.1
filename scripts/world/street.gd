@tool
class_name WorldStreet
extends Node2D
## The street the band walks on and its edge toward the water, across the whole
## map. In town: cobbles, curb, stone quay wall, iron railing and bollards.
## Outside town: an asphalt dike road with a dashed line and a grassy bank.
## Origin at x 0, y = the street line (the band's feet).

@export var map_width := 3840.0
@export var town := Vector2(1100, 3640)

const STREET_H := 14.0
const EDGE_H := 22.0                        # street + curb + quay down to the water


func _draw() -> void:
	var p := WorldPalette
	# Town: cobbles, curb, quay, railing.
	var a := town.x
	var b := town.y
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
	# Outside town: dike road and grass bank (both sides).
	for seg in [Vector2(-400, a), Vector2(b, map_width + 400)]:
		var w: float = seg.y - seg.x
		draw_rect(Rect2(seg.x, 0, w, 10), p.ROAD)
		var xd: float = seg.x
		while xd < seg.y:
			draw_rect(Rect2(xd, 5, 12, 1), p.WHITE.lerp(p.ROAD, 0.4))
			xd += 24
		draw_rect(Rect2(seg.x, 10, w, EDGE_H - 10), p.GRASS[0])
		draw_rect(Rect2(seg.x, 10, w, 2), p.GRASS[1])
