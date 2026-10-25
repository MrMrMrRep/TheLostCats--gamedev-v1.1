@tool
class_name WorldFrontGround
extends Node2D
## What lies in front of (below) the road where there's no water, drawn at the
## band sprites' density:
##   VIADUCT  the road runs over a bridge: a railing along the edge, the
##            concrete deck edge with its drip line, brick piers with arches,
##            deep shade under the deck, shrubs and a path far below
##   GRASS    a grass bank sloping down from the verge, with bushes, tall
##            grass and wildflowers
## Origin = street line at the left end; `top` = where it starts below the road.

enum Kind { VIADUCT, GRASS }

@export var kind := Kind.VIADUCT:
	set(value):
		kind = value
		queue_redraw()
@export var length := 1000.0:
	set(value):
		length = value
		queue_redraw()
@export var top := 22.0:
	set(value):
		top = value
		queue_redraw()
@export var seed_value := 4

const DEPTH := 220.0                        # how far down it's drawn (below the view)


func _ready() -> void:
	texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	var L := length * 2.0
	var t := top * 2.0
	if kind == Kind.VIADUCT:
		_viaduct(L, t, rng)
	else:
		_grass(L, t, rng)
	draw_set_transform(Vector2.ZERO)


func _viaduct(L: float, t: float, rng: RandomNumberGenerator) -> void:
	var concrete := WorldPalette.R3
	var brick := WorldPalette.B1
	var below := t + 30.0
	# Far below, in the shade: a hazy backdrop of trees and a path.
	draw_rect(Rect2(0, below, L, DEPTH * 2.0), WorldPalette.T0)
	var x := 0.0
	while x < L:
		var r := rng.randf_range(18, 34)
		draw_circle(Vector2(x, below + 120 + rng.randf_range(-10, 10)), r, WorldPalette.G0)
		x += rng.randf_range(20, 40)
	draw_rect(Rect2(0, below + 150, L, 12), WorldPalette.R0)
	# Brick piers with arches between them.
	var span := 180.0
	var px := fmod(rng.randf_range(0, 60), span) - span
	while px < L + span:
		draw_texture_rect(PixelArt.brick(), Rect2(px, below, 34, DEPTH * 2.0), true, brick)
		draw_rect(Rect2(px + 28, below, 6, DEPTH * 2.0), brick.darkened(0.3))
		draw_rect(Rect2(px - 1, below, 1, DEPTH * 2.0), PixelArt.OUTLINE)
		# arch spandrel to the next pier
		var ax := px + 34.0
		var aw := span - 34.0
		for i in int(aw):
			var u := (i - aw / 2.0) / (aw / 2.0)
			var h := 40.0 * (1.0 - sqrt(maxf(0.0, 1.0 - u * u))) + 6.0
			draw_rect(Rect2(ax + i, below, 1, h), brick.darkened(0.08))
			draw_rect(Rect2(ax + i, below + h, 1, 2), brick.darkened(0.45))
		px += span
	# Deck edge (concrete fascia) with a drip line and stains.
	draw_rect(Rect2(0, t, L, 30), concrete)
	draw_rect(Rect2(0, t, L, 2), concrete.lightened(0.15))
	draw_rect(Rect2(0, t + 24, L, 6), concrete.darkened(0.25))
	draw_rect(Rect2(0, t + 30, L, 3), Color(0, 0, 0, 0.35))
	var jx := 0.0
	while jx < L:
		draw_rect(Rect2(jx, t + 2, 1, 22), concrete.darkened(0.12))  # panel joints
		if rng.randf() < 0.3:
			draw_rect(Rect2(jx + rng.randf_range(10, 60), t + 22, 3, rng.randf_range(6, 20)), concrete.darkened(0.18))
		jx += 96
	# Railing along the edge, in front of the road.
	draw_rect(Rect2(0, t - 18, L, 3), WorldPalette.R2)
	draw_rect(Rect2(0, t - 18, L, 1), WorldPalette.W3)
	draw_rect(Rect2(0, t - 8, L, 2), WorldPalette.R2)
	var rx := 0.0
	while rx < L:
		draw_rect(Rect2(rx, t - 18, 2, 18), WorldPalette.R1)
		rx += 16
	# A bit of green clinging on: shrubs in front of some piers.
	var gx := rng.randf_range(0, 100)
	while gx < L:
		if rng.randf() < 0.5:
			for k in 4:
				draw_circle(Vector2(gx + k * 9, below + 40 + rng.randf_range(0, 20)), rng.randf_range(9, 15), PixelArt.leaves()[k % 3].darkened(0.35))
		gx += rng.randf_range(120, 260)


func _grass(L: float, t: float, rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	# The bank: bands of grass getting darker as it slopes down.
	for k in 6:
		var c: Color = (p.GRASS[k % 3] as Color).darkened(0.06 * k)
		draw_rect(Rect2(0, t + k * 30, L, 30 + (DEPTH * 2.0 if k == 5 else 0.0)), c)
	# Tall grass tufts and wildflowers along the top.
	var x := 0.0
	while x < L:
		var h := rng.randf_range(6, 16)
		draw_line(Vector2(x, t + 6), Vector2(x + rng.randf_range(-3, 3), t + 6 - h), WorldPalette.G2, 1.0)
		if rng.randf() < 0.18:
			draw_rect(Rect2(x - 1, t + 4 - h, 3, 3), [WorldPalette.O2, WorldPalette.W4, WorldPalette.B2, WorldPalette.W2][rng.randi_range(0, 3)])
		x += rng.randf_range(3, 7)
	# Bushes further down the slope.
	var bx := rng.randf_range(0, 80)
	while bx < L:
		var r := rng.randf_range(16, 30)
		var by := t + rng.randf_range(40, 110)
		var leaves := PixelArt.leaves()
		draw_circle(Vector2(bx, by), r + 2, (leaves[0] as Color).darkened(0.45))
		draw_circle(Vector2(bx, by), r, leaves[0])
		draw_circle(Vector2(bx - r * 0.3, by - r * 0.3), r * 0.6, leaves[1])
		bx += rng.randf_range(90, 220)
