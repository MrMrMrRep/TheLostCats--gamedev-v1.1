class_name CanalRow
## Flat canal-house terraces from the SpriteCook kit (CanalKit): picks
## facades to fill a stretch exactly, then draws them at 1 texel = 1 art px
## (scale 0.5, never stretched) with their lit windows at night.
## A row is an Array of [name, art x, joint]: the facade's left edge and, when
## the next facade doesn't quite meet it, the width of the dark party-wall
## joint after it. An alley is [ALLEY, art x, 0, width].

## Facades for an ordinary terrace (door houses are only placed on purpose).
const POOL: Array[StringName] = [
	&"res_blue", &"res_cream", &"res_brown", &"res_red",
	&"res_blue2", &"res_cream2", &"res_ochre", &"res_wine",
	&"shop_orange", &"shop_cream", &"shop_brown", &"shop_red",
	&"merchant", &"spout_green", &"bakery",
]
const OVERLAP := 6                          # art px a facade may slide over its left neighbour
const JOINT := 3                            # art px of dark party wall allowed between two facades
const TRIES := 400
const ALLEY := &"alley"
const ALLEY_MIN := 22                       # art px: the narrowest steeg
const ALLEY_MAX := 84
const ALLEY_VIEW := &"gap_street_b"         # cut from the middle of this view
const LIFT := 16                            # art px: the facades stand at the back of the pavement, the band walks on it

static var _tex := {}


static func texture(name: StringName) -> Texture2D:
	if not _tex.has(name):
		_tex[name] = load(CanalKit.DIR + String(name) + ".png")
	return _tex[name]


static func width(name: StringName) -> int:
	return CanalKit.SIZES[name].x


static func height(name: StringName) -> int:
	return CanalKit.SIZES[name].y


## Facades filling `length` art px from art x `x0`. `soft_left` / `soft_right`:
## that end may tuck up to `tuck` px under whatever is drawn over it there (a
## door house, an opening's side wall). `avoid` = gables of the neighbours.
## The kit has no narrow houses, so where whole facades can't fill the stretch
## a narrow alley (a steeg, cut from the side-street view) takes up the rest.
static func fill(x0: int, length: int, rng: RandomNumberGenerator, soft_left := false, soft_right := false,
		tuck := 40, avoid_left := -1, avoid_right := -1) -> Array:
	if length <= 0:
		return []
	var best: Array = []
	var best_score := 1 << 30
	for t in TRIES:
		var seq: Array[StringName] = []
		var total := 0
		var last := avoid_left
		while total < length - 110:
			var n := _pick(rng, last, -1)
			seq.append(n)
			total += width(n)
			last = CanalKit.GABLES[n]
		var options := [seq.duplicate()]
		var tail := _pick(rng, last, avoid_right)
		var longer := seq.duplicate()
		longer.append(tail)
		options.append(longer)
		for opt: Array in options:
			if opt.is_empty():
				continue
			var sum := 0
			for n: StringName in opt:
				sum += width(n)
			var seams: int = opt.size() - 1
			var diff := length - sum
			var lo := -OVERLAP * seams - (tuck if soft_left else 0) - (tuck if soft_right else 0)
			var hi := JOINT * seams
			var alley := 0
			var score := absi(diff)
			if diff < lo or diff > hi:
				alley = clampi(diff, ALLEY_MIN, ALLEY_MAX)
				var rest := diff - alley
				if rest < lo or rest > hi:
					continue
				score = 20 + absi(rest)
			if score < best_score:
				best_score = score
				var at := rng.randi_range(0, opt.size()) if alley > 0 else -1
				best = _place(x0, length, opt, alley, at, soft_left, soft_right)
		if best_score <= 4:
			break
	return best


static func _pick(rng: RandomNumberGenerator, not_gable: int, not_gable2: int) -> StringName:
	for i in 20:
		var n: StringName = POOL[rng.randi_range(0, POOL.size() - 1)]
		if n == &"merchant" and rng.randf() < 0.6:
			continue                        # a double-wide house now and then, not every few doors
		var g: int = CanalKit.GABLES[n]
		if g != not_gable and g != not_gable2:
			return n
	return POOL[0]


## Lay out `seq` (with an alley of `alley` px before facade `alley_at`; at
## seq.size(): after the last) and spread what's left over the seams
## (overlaps or joints), the rest into the soft ends.
static func _place(x0: int, length: int, seq: Array, alley: int, alley_at: int, soft_left: bool, soft_right: bool) -> Array:
	var total := alley
	for n: StringName in seq:
		total += width(n)
	var rest := length - total              # > 0: joints, < 0: overlaps / tucks
	var seams := seq.size() - 1
	var per := []
	for i in seams:
		per.append(0)
	if seams > 0:
		var cap := JOINT if rest > 0 else OVERLAP
		for i in seams:
			var share := clampi(int(round(float(rest) / float(seams - i))), -cap, cap)
			per[i] = share
			rest -= share
	var x := x0
	if rest < 0 and soft_left and not soft_right:
		x += rest                           # tuck the first facade under the left end
	elif rest < 0 and soft_left and soft_right:
		x += rest / 2
	var out := []
	for i in seq.size():
		if i == alley_at:
			out.append([ALLEY, x, 0, alley])
			x += alley
		var joint: int = per[i] if i < seams else 0
		out.append([seq[i], x, maxi(joint, 0)])
		x += width(seq[i]) + joint
	if alley_at == seq.size():
		out.append([ALLEY, x, 0, alley])
	return out


## Width of a row item (a facade or an alley), art px.
static func item_width(it: Array) -> int:
	return it[3] if it[0] == ALLEY else width(it[0])


## Draw a row (art px, origin on the street line). Call between
## draw_set_transform(…, Vector2(0.5, 0.5)) and its reset.
static func draw(ci: CanvasItem, row: Array) -> void:
	var view := texture(ALLEY_VIEW)
	for it: Array in row:                   # alleys first: the facades either side close over their edges
		if it[0] == ALLEY:
			var w: int = it[3]
			var h := view.get_height()
			ci.draw_texture_rect_region(view, Rect2(it[1], -h - LIFT, w, h), Rect2((view.get_width() - w) / 2, 0, w, h))
	for it: Array in row:
		var n: StringName = it[0]
		if n == ALLEY:
			continue
		var x: int = it[1]
		var joint: int = it[2]
		ci.draw_texture(texture(n), Vector2(x, -height(n) - LIFT))
		if joint > 0:                       # a dark sliver of party wall where two facades don't touch
			var nh := mini(height(n), 240)
			ci.draw_rect(Rect2(x + width(n), -nh + 30 - LIFT, joint, nh - 30), WorldPalette.T0)


## Its windows into a NightGlow (world px, relative to the row's origin).
static func add_glow(glow: NightGlow, row: Array, at := Vector2.ZERO) -> void:
	if glow == null:
		return
	for it: Array in row:
		var n: StringName = it[0]
		if n == ALLEY:
			continue
		var x: int = it[1]
		var top := -height(n) - LIFT
		for r: Rect2i in CanalKit.WINDOWS.get(n, []):
			var rr := Rect2(at + Vector2(x + r.position.x, top + r.position.y) * 0.5, Vector2(r.size) * 0.5)
			glow.add_window(rr.grow(-0.5), NightGlow.window_threshold(rr.position.x, rr.position.y, false))
