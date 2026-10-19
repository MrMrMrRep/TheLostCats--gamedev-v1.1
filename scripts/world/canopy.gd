@tool
class_name WorldCanopy
extends Node2D
## A dense cluster of tree crowns right in front of the camera, used to hide
## a change in what lies in front of the road (canal -> viaduct -> grass). It
## fills everything below the road across `width` and just laps over the road
## edge, like trees growing up from the bank. Drawn at the band sprites'
## density, three leaf tones with a dark rim and speckle, a few branches.
## Origin = street line at the cluster's centre.

@export var width := 240.0:
	set(value):
		width = value
		queue_redraw()
@export var seed_value := 7


func _draw() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	var half := width                       # art px (width / 2 * 2)
	var leaves := PixelArt.leaves()
	var blobs := []
	# Big low crowns fill the lower part completely; smaller ones climb to the road edge.
	for i in 64:
		var u := rng.randf_range(-1.0, 1.0)
		var x := u * half
		var edge := 1.0 - absf(u)                               # taller in the middle
		var y := rng.randf_range(30.0, 420.0) - edge * 30.0
		var r := rng.randf_range(26, 46) * (0.75 + 0.25 * edge)
		blobs.append([Vector2(x, y + r * 0.6), r])
	for i in 14:                                                 # a few sprigs just over the road edge
		var x := rng.randf_range(-half * 0.6, half * 0.6)
		blobs.append([Vector2(x, rng.randf_range(14, 40)), rng.randf_range(12, 22)])
	blobs.sort_custom(func(a, b): return a[0].y > b[0].y)       # far (low) first
	# A couple of branches showing between the crowns.
	for k in 3:
		var bx := rng.randf_range(-half * 0.5, half * 0.5)
		draw_line(Vector2(bx, 400), Vector2(bx + rng.randf_range(-40, 40), 40), Color("3a2c22"), 7.0)
	for b in blobs:
		var c: Vector2 = b[0]
		var r: float = b[1]
		var shade := clampf(c.y / 400.0, 0.0, 1.0)              # deeper down = darker
		draw_circle(c, r + 3, leaves[0].darkened(0.55))
		draw_circle(c, r, leaves[0].darkened(0.25 + 0.25 * shade))
		draw_circle(c + Vector2(-r * 0.25, -r * 0.3), r * 0.66, leaves[1].darkened(0.15 + 0.25 * shade))
		if rng.randf() < 0.7:
			draw_circle(c + Vector2(-r * 0.4, -r * 0.45), r * 0.3, leaves[2].darkened(0.1 + 0.2 * shade))
	for i in 520:                                                # leaf speckle
		var p := Vector2(rng.randf_range(-half * 0.9, half * 0.9), rng.randf_range(60, 420))
		draw_rect(Rect2(p, Vector2(2, 2)), leaves[rng.randi_range(0, 2)].darkened(rng.randf_range(0.1, 0.5)))
	draw_set_transform(Vector2.ZERO)
