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
## Facades per district (CityBlock.district): which houses a row is made of.
const POOLS := {
	&"canal": POOL,
	&"oldtown": [&"ot_cheese", &"ot_cafe", &"ot_bike", &"ot_antique", &"ot_cheese2", &"ot_cafe2", &"ot_bike2", &"ot_curio",
		&"ot_res_a", &"ot_res_b", &"ot_res_c", &"ot_res_d"],
	&"wallen": [&"wal_kroeg", &"wal_neon_a", &"wal_coffee", &"wal_neon_b", &"wal_kroeg2", &"wal_coffee2", &"wal_neon_c", &"wal_neon_d",
		&"ot_res_a", &"ot_res_d"],
	&"flats": [&"flat_shop", &"flat_cafe", &"flat_laund", &"flat_shop2", &"flat_cafe2", &"flat_laund2"],
}
const JOINT := 3                            # art px of dark party wall allowed between two facades
const END_JOINT := 2                        # and at either end of a stretch
const TRIES := 400
const ALLEY := &"alley"
const ALLEY_MIN := 22                       # art px: the narrowest steeg
const ALLEY_MAX := 84
const ALLEY_VIEW := &"gap_street_b"         # cut from the middle of this view
const NEON_RED := Color(1.0, 0.12, 0.22, 0.85)
const NEON_HALO := Color(1.0, 0.1, 0.25, 0.4)
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


## Facades filling exactly `length` art px from art x `x0`: no facade ever
## overlaps another. What whole facades leave over goes into thin party-wall
## joints (JOINT px at most, between two houses or at the ends) or into one
## steeg, a narrow alley cut from the side-street view, and a steeg only ever
## stands between two houses. `avoid_left` / `avoid_right`: the gables of the
## neighbours outside the stretch. Returns [] when the stretch can't be filled.
static func fill(x0: int, length: int, rng: RandomNumberGenerator, avoid_left := -1, avoid_right := -1, district := &"canal") -> Array:
	var pool: Array = POOLS.get(district, POOL)
	if length <= 0:
		return []
	var best: Array = []
	var best_score := 1 << 30
	for t in TRIES:
		var seq: Array[StringName] = []
		var total := 0
		var last := avoid_left
		while total < length - 110:
			var n := _pick(rng, last, -1, pool)
			seq.append(n)
			total += width(n)
			last = CanalKit.GABLES[n]
		var longer := seq.duplicate()
		longer.append(_pick(rng, last, avoid_right, pool))
		for opt: Array in [seq, longer]:
			if opt.is_empty():
				continue
			var sum := 0
			for n: StringName in opt:
				sum += width(n)
			var seams: int = opt.size() - 1
			var slack := JOINT * seams + END_JOINT * 2
			var diff := length - sum
			if diff < 0:
				continue
			var alley := 0
			var score := diff
			if diff > slack:
				if seams < 1:
					continue
				alley = clampi(diff, ALLEY_MIN, ALLEY_MAX)
				if diff - alley < 0 or diff - alley > slack:
					continue
				score = 30 + diff - alley
			if score < best_score:
				best_score = score
				var at := rng.randi_range(1, seams) if alley > 0 else -1
				best = _place(x0, length, opt, alley, at)
		if best_score <= 2:
			break
	return best


static func _pick(rng: RandomNumberGenerator, not_gable: int, not_gable2: int, pool: Array = POOL) -> StringName:
	for i in 20:
		var n: StringName = pool[rng.randi_range(0, pool.size() - 1)]
		if n == &"merchant" and rng.randf() < 0.8:
			continue                        # a double-wide house now and then, not every few doors
		var g: int = CanalKit.GABLES[n]
		if g != not_gable and g != not_gable2:
			return n
	return pool[0]


## Lay out `seq` with a steeg of `alley` px just before facade `alley_at`
## (1 .. size-1: always between two houses) and spread what's left over the
## joints: first between the houses, then at the two ends.
static func _place(x0: int, length: int, seq: Array, alley: int, alley_at: int) -> Array:
	var total := alley
	for n: StringName in seq:
		total += width(n)
	var rest := length - total
	var seams := seq.size() - 1
	var per := []
	for i in seams:
		var share := mini(int(ceil(float(rest) / float(seams - i))), JOINT) if rest > 0 else 0
		share = mini(share, maxi(rest - 0, 0))
		per.append(share)
		rest -= share
	var lead := rest / 2                    # what's left: the two end joints
	var out := []
	var x := x0 + lead
	for i in seq.size():
		if i == alley_at:
			out.append([ALLEY, x, 0, alley])
			x += alley
		var joint: int = per[i] if i < seams else 0
		out.append([seq[i], x, joint])
		x += width(seq[i]) + joint
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
		for r: Rect2i in CanalKit.NEON.get(n, []):   # red light district: the red windows come on first, with a halo
			var rr := Rect2(at + Vector2(x + r.position.x, top + r.position.y) * 0.5, Vector2(r.size) * 0.5)
			glow.add_window(rr, 0.02, NEON_RED)
			glow.add_halo(rr.get_center(), maxf(rr.size.x, rr.size.y) * 1.6, 0.02, NEON_HALO)
