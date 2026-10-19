@tool
class_name WorldCanopy
extends Node2D
## A dense cluster of tree crowns right in front of the camera, used to hide
## a change in what lies in front of the road (canal -> viaduct -> grass). It
## fills everything below the road across `width` and just laps over the road
## edge, like trees growing up from the bank.
## Rendered as real pixel art at the band sprites' density: leaf clumps with
## ragged edges, lit from the upper left, a leaf texture quantised to six
## greens with ordered dithering, dark rims where clumps overlap, blue shadow
## pockets deep inside, branches showing in the gaps, loose leaves at the
## edges. Built once per seed (cached). Origin = street line, cluster centre.

const PALETTE := [Color("17301f"), Color("24482c"), Color("356a36"), Color("4f8d3b"), Color("79b444"), Color("b4d860")]
const SHADOW_BLUE := Color("2f4f63")
const BRANCH := Color("3a2c22")
const HEIGHT := 460                         # art px, from just above the road to below the view
const TOP_PAD := 30                         # art px above the street line the crowns may reach
const BAYER := [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

static var _cache := {}

@export var width := 240.0:
	set(value):
		width = value
		_tex = null
		queue_redraw()
@export var seed_value := 7:
	set(value):
		seed_value = value
		_tex = null
		queue_redraw()

var _tex: ImageTexture


func _draw() -> void:
	if _tex == null:
		var key := "%d:%d" % [seed_value, int(width)]
		if not _cache.has(key):
			_cache[key] = _render()
		_tex = _cache[key]
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
	draw_texture(_tex, Vector2(-_tex.get_width() / 2.0, -TOP_PAD))
	draw_set_transform(Vector2.ZERO)


func _render() -> ImageTexture:
	var W := int(width * 2.0) + 40
	var H := HEIGHT
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var leaf := FastNoiseLite.new()
	leaf.seed = seed_value
	leaf.noise_type = FastNoiseLite.TYPE_SIMPLEX
	leaf.frequency = 0.16
	var wobble := FastNoiseLite.new()
	wobble.seed = seed_value + 1
	wobble.frequency = 0.045
	var holes := FastNoiseLite.new()
	holes.seed = seed_value + 2
	holes.frequency = 0.05

	var who := PackedInt32Array()
	who.resize(W * H)
	who.fill(-1)
	var light := PackedFloat32Array()
	light.resize(W * H)

	# Clumps: big low ones fill the bottom, smaller ones climb to the road edge.
	# A dense dark mass behind everything, so nothing behind shows through.
	for y in H:
		for x in W:
			var side := absf(x - W / 2.0) - (W / 2.0 - 26.0) + wobble.get_noise_2d(x, y) * 26.0
			var top := 96.0 + wobble.get_noise_2d(x * 0.7, 0.0) * 40.0
			if side > 0.0 or y < top:
				continue
			var i := y * W + x
			who[i] = 0
			light[i] = 0.2 + leaf.get_noise_2d(x, y) * 0.3 - (y / float(H)) * 0.12
	var clumps := [Vector3(-1000, -1000, 1)]                  # index 0 = the mass behind
	for i in 46:
		var u := rng.randf_range(-1.0, 1.0)
		var edge := 1.0 - absf(u)
		var r := rng.randf_range(40, 68) * (0.75 + 0.25 * edge)
		clumps.append(Vector3(W / 2.0 + u * (W / 2.0 - 30), rng.randf_range(80.0, H - 20.0) - edge * 30.0, r))
	for i in 18:
		clumps.append(Vector3(W / 2.0 + rng.randf_range(-W * 0.34, W * 0.34), rng.randf_range(TOP_PAD + 16, TOP_PAD + 70), rng.randf_range(16, 30)))
	var front := clumps.slice(1)
	front.sort_custom(func(a, b): return a.y > b.y)           # lower ones first, upper ones on top
	clumps = [clumps[0]] + front

	for ci in range(1, clumps.size()):
		var c: Vector3 = clumps[ci]
		var r := c.z
		var depth := clampf(c.y / float(H), 0.0, 1.0)          # deeper down = darker
		for y in range(maxi(0, int(c.y - r * 1.4)), mini(H, int(c.y + r * 1.4))):
			for x in range(maxi(0, int(c.x - r * 1.4)), mini(W, int(c.x + r * 1.4))):
				var nx := (x - c.x) / r
				var ny := (y - c.y) / (r * 0.88)
				var d := nx * nx + ny * ny
				if d > 1.0 + wobble.get_noise_2d(x, y) * 0.5:
					continue
				var i := y * W + x
				var l := 0.62 - 0.38 * (nx * 0.55 + ny * 0.83)  # light from the upper left
				l -= 0.45 * clampf((d - 0.6) / 0.5, 0.0, 1.0) * clampf(0.4 + ny, 0.0, 1.0)   # rim in shade
				l += leaf.get_noise_2d(x, y) * 0.28
				l -= depth * 0.35
				who[i] = ci
				light[i] = l

	var img := Image.create(W, H, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	# Branches first: they only show where the leaves leave gaps.
	for k in 4:
		var bx := W / 2.0 + rng.randf_range(-W * 0.3, W * 0.3)
		var tx := bx + rng.randf_range(-60, 60)
		for s in H:
			var t := s / float(H - 1)
			var px := int(lerpf(bx, tx, t))
			var py := int(lerpf(H - 10, 80, t))
			for w in 4:
				if px + w >= 0 and px + w < W:
					img.set_pixel(px + w, py, BRANCH)
	for y in H:
		for x in W:
			var i := y * W + x
			if who[i] < 0:
				continue
			var l := light[i]
			# Ordered dithering, then six tones.
			l += (BAYER[(y % 4) * 4 + (x % 4)] / 16.0 - 0.5) * 0.16
			var tone := clampi(int(floor(l * 6.0)), 0, 5)
			var col: Color = PALETTE[tone]
			if tone <= 1 and holes.get_noise_2d(x, y) > 0.45:
				col = SHADOW_BLUE                                  # deep pockets of shade
			# Dark seam where a clump sits on another one.
			if y > 0 and who[i - W] >= 0 and who[i - W] > who[i]:
				col = PALETTE[0]
			img.set_pixel(x, y, col)
	# Loose leaves around the edges.
	for n in 900:
		var x := rng.randi_range(1, W - 2)
		var y := rng.randi_range(1, H - 2)
		var i := y * W + x
		if who[i] >= 0:
			continue
		if who[i - 1] >= 0 or who[i + 1] >= 0 or who[i - W] >= 0 or who[i + W] >= 0:
			img.set_pixel(x, y, PALETTE[rng.randi_range(2, 5)])
	return ImageTexture.create_from_image(img)
