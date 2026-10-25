@tool
class_name WorldHouseboats
extends Node2D
## Houseboats moored along the canal, in front of the quay wall (closer to us
## than the street), drawn at the band sprites' density. They sit on the water
## line and draw their own soft reflection (they're in front of the water).
## One node per boat: drag it along the canal, duplicate it for another boat,
## change `seed_value` for a different look. (`spots` can still list several
## boats for one node: local x of each.) Origin = the boat's left end on the
## street line.

const WATER_Y := 22.0                       # world px below the street line

@export var spots: Array[float] = []:      ## several boats from this node (local x each); empty = one boat here
	set(value):
		spots = value
		queue_redraw()
@export var seed_value := 3:                ## the boat's look
	set(value):
		seed_value = value
		look_state = 0
		queue_redraw()
@export_storage var look_state := 0         # keeps the exact look a boat had before the boats were split up


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	if look_state != 0:
		rng.state = look_state
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	for sx in (spots if not spots.is_empty() else [0.0]):
		_boat(sx * 2.0, WATER_Y * 2.0, rng)
	draw_set_transform(Vector2.ZERO)


func _boat(x: float, wy: float, rng: RandomNumberGenerator) -> void:
	var p := WorldPalette
	var length := rng.randf_range(150, 220)
	var hull: Color = [WorldPalette.T0, WorldPalette.T0, WorldPalette.G0, WorldPalette.B0][rng.randi_range(0, 3)]
	var cabin: Color = [WorldPalette.W1, WorldPalette.G4, WorldPalette.T3, WorldPalette.R2, WorldPalette.W2][rng.randi_range(0, 4)]
	var ark := rng.randf() < 0.4                # box-shaped "ark" vs. a converted barge
	# Reflection first (under the hull), then the hull and the cabin.
	draw_rect(Rect2(x + 4, wy + 10, length - 8, 10), Color(hull, 0.35))
	draw_rect(Rect2(x + 10, wy + 20, length - 20, 6), Color(cabin.darkened(0.4), 0.18))
	draw_rect(Rect2(x - 1, wy - 3, length + 2, 14), PixelArt.OUTLINE)
	draw_rect(Rect2(x, wy - 2, length, 12), hull)
	draw_rect(Rect2(x, wy + 1, length, 2), p.WHITE.darkened(0.1))
	if not ark:                              # barge bow and stern
		WorldPalette.triangle(self, x + length - 6, wy + 10, 14, 12, hull)
		draw_rect(Rect2(x - 4, wy - 2, 6, 10), hull)
	var ch := 30.0 if ark else 24.0
	var cx := x + (6.0 if ark else 24.0)
	var cw := length - (12.0 if ark else 48.0)
	draw_rect(Rect2(cx - 1, wy - 3 - ch - 1, cw + 2, ch + 2), PixelArt.OUTLINE)
	draw_rect(Rect2(cx, wy - 3 - ch, cw, ch), cabin)
	draw_rect(Rect2(cx + cw - 4, wy - 3 - ch, 4, ch), cabin.darkened(0.2))
	draw_rect(Rect2(cx - 3, wy - 6 - ch, cw + 6, 4), cabin.darkened(0.35))          # roof
	var wx := cx + 8
	while wx < cx + cw - 18:
		draw_rect(Rect2(wx, wy - ch + 4, 14, 12), p.TRIM)
		draw_rect(Rect2(wx + 2, wy - ch + 6, 10, 8), WorldPalette.O2 if rng.randf() < 0.2 else p.GLASS)
		wx += rng.randf_range(20, 28)
	draw_rect(Rect2(cx + cw - 22, wy - 3 - ch + 4, 12, ch - 4), cabin.darkened(0.3))   # door
	# Roof life: pots with plants, a chimney, sometimes a bike.
	for k in rng.randi_range(2, 4):
		var px := cx + 10 + k * rng.randf_range(18, 30)
		if px < cx + cw - 10:
			draw_rect(Rect2(px, wy - ch - 12, 7, 6), WorldPalette.B2)
			WorldPalette.disc(self, px + 3, wy - ch - 15, 4, WorldPalette.T3)
	draw_rect(Rect2(cx + cw - 12, wy - ch - 20, 4, 14), WorldPalette.W0)
	if rng.randf() < 0.4:
		var bx := cx + cw * 0.45
		draw_arc(Vector2(bx, wy - ch - 14), 7, 0, TAU, 12, PixelArt.OUTLINE, 2.0)
		draw_arc(Vector2(bx + 24, wy - ch - 14), 7, 0, TAU, 12, PixelArt.OUTLINE, 2.0)
		draw_line(Vector2(bx, wy - ch - 14), Vector2(bx + 10, wy - ch - 24), WorldPalette.B0, 2.0)
		draw_line(Vector2(bx + 10, wy - ch - 24), Vector2(bx + 24, wy - ch - 14), WorldPalette.B0, 2.0)
	# Mooring lines to the quay.
	draw_line(Vector2(x + 6, wy - 2), Vector2(x + 2, wy - 16), WorldPalette.R2, 1.0)
	draw_line(Vector2(x + length - 8, wy - 2), Vector2(x + length - 2, wy - 16), WorldPalette.R2, 1.0)
