@tool
class_name WorldBridge
extends Node2D
## Where the street crosses a side canal: the house row opens up and you look
## down the canal into the distance (houses on both banks getting smaller),
## with an iron railing along the bridge and a stone arch in the quay wall
## where the side canal meets the front canal. Origin = street line, centre.
## Keep the play-layer houses out of [-width/2, width/2].

@export var width := 96.0:
	set(value):
		width = value
		queue_redraw()
@export var seed_value := 3


func _draw() -> void:
	var p := WorldPalette
	var half := width / 2.0
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	# Receding side canal: a corridor toward a vanishing point above the street,
	# stone banks converging, rows of houses on both banks getting smaller.
	var vp := Vector2(0, -42)
	var near := width * 0.3
	var water := PackedVector2Array([Vector2(-near, 0), Vector2(near, 0), vp + Vector2(2, 0), vp - Vector2(2, 0)])
	draw_colored_polygon(water, p.WATER.lerp(p.WATER_HI, 0.15))
	for i in 5:                             # ripple lines, closer together far away
		var t := pow(i / 5.0, 0.7)
		var y := lerpf(-3, vp.y + 4, t)
		var hw := lerpf(near, 2, t) * 0.7
		draw_rect(Rect2(-hw, y, hw * 2, 1), p.WATER_HI.lerp(p.WATER, 0.4))
	for side in [-1.0, 1.0]:
		draw_line(Vector2(side * near, 0), vp + Vector2(side * 2, 0), p.QUAY, 2.0)
		# houses along the bank, far to near so the near ones overlap
		var steps := 9
		for k in range(steps - 1, -1, -1):
			var t := float(k) / steps
			var base := Vector2(side * (near + 2), 0).lerp(vp + Vector2(side * 3, 0), t)
			var sc := 1.0 - t * 0.88
			var hw := 18.0 * sc
			var hh := rng.randf_range(52, 66) * sc
			var x := base.x if side > 0 else base.x - hw
			var c: Color = p.FACADES[(k * 3 + int(side + 1)) % p.FACADES.size()].lerp(p.HAZE, 0.15 + t * 0.6)
			draw_rect(Rect2(x, base.y - hh, hw, hh), c)
			draw_rect(Rect2(x, base.y - hh, hw, maxf(1, sc * 2)), p.TRIM.lerp(p.HAZE, t * 0.6))
			if sc > 0.45:
				for r in int(hh / (11.0 * sc)):
					for col in 2:
						draw_rect(Rect2(x + hw * (0.2 + col * 0.45), base.y - hh + (4 + r * 11) * sc, maxf(1, 3 * sc), maxf(1, 5 * sc)), p.GLASS.lerp(p.HAZE, t * 0.5))
	# Bridge railing on the far side of the deck.
	var x := -half
	while x <= half:
		draw_rect(Rect2(x, -8, 1, 8), p.IRON)
		x += 6
	draw_rect(Rect2(-half, -8, width, 1), p.IRON)
	draw_rect(Rect2(-half - 3, -10, 4, 10), p.QUAY)
	draw_rect(Rect2(half - 1, -10, 4, 10), p.QUAY)
	# Stone arch in the quay wall (y 16..22) opening onto the side canal.
	var aw := width * 0.5
	for i in int(aw):
		var t := (i - aw / 2.0) / (aw / 2.0)
		var hgt := 6.0 * sqrt(maxf(1.0 - t * t, 0.0))
		draw_rect(Rect2(-aw / 2 + i, 22 - hgt, 1, hgt), p.WATER_DEEP)
	draw_rect(Rect2(-aw / 2 - 2, 15, aw + 4, 1), p.QUAY_DARK)
