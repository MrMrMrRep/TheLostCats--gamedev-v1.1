extends SceneTree
# Pastes a SpriteCook refinement back into a SideOpening's art.
# env: FULL (art png), CAND (candidate image), CROPX CROPY (crop pos in the art),
#      OPEN (opening width in art px), FAR (x0,y0,x1,y1 in crop px: the far end,
#      taken whole), MODE (nearest|smooth), OUT (png)
const SKY := Color("8ec5e6")
func _initialize() -> void:
	_run.call_deferred()
var _pal: Array = []
var _memo := {}
func _snap(c: Color) -> Color:
	var key := c.to_rgba32()
	if _memo.has(key):
		return _memo[key]
	if _pal.is_empty():
		_pal = WorldPalette.PALETTE.duplicate()
		_pal.append(SKY)
	var best: Color = SKY
	var bd := INF
	for p: Color in _pal:
		var dr := (c.r - p.r) * 0.30
		var dg := (c.g - p.g) * 0.59
		var db := (c.b - p.b) * 0.11
		var d := dr * dr + dg * dg + db * db
		if d < bd:
			bd = d
			best = p
	_memo[key] = best
	return best
func _run() -> void:
	var full := Image.load_from_file(OS.get_environment("FULL"))
	full.convert(Image.FORMAT_RGBA8)
	var cand := Image.load_from_file(OS.get_environment("CAND"))
	cand.convert(Image.FORMAT_RGBA8)
	var side := 360
	if OS.get_environment("MODE") == "nearest":
		cand.resize(side, side, Image.INTERPOLATE_NEAREST)
	else:
		cand.resize(side, side, Image.INTERPOLATE_LANCZOS)
	var cx := int(OS.get_environment("CROPX"))
	var cy := int(OS.get_environment("CROPY"))
	var half := int(OS.get_environment("OPEN")) / 2
	var far := OS.get_environment("FAR").split(",")
	var fr := Rect2i(int(far[0]), int(far[1]), int(far[2]) - int(far[0]), int(far[3]) - int(far[1]))
	# The refinement can reach above the art's top (roofs over a low wall):
	# grow the canvas upwards; SHIFT (written next to OUT) moves the origin.
	var shift := maxi(0, -cy)
	var base := Image.create(full.get_width(), full.get_height() + shift, false, Image.FORMAT_RGBA8)
	base.blit_rect(full, Rect2i(Vector2i.ZERO, full.get_size()), Vector2i(0, shift))
	full = base
	cy += shift
	var out := full.duplicate()
	var f := FileAccess.open(OS.get_environment("OUT") + ".shift", FileAccess.WRITE)
	f.store_string(str(shift))
	f.close()
	# Grow the canvas upwards if the refinement reaches above the art's top.
	for y in side:
		for x in side:
			if absi(x - side / 2) > half:
				continue                         # the flank houses stay as they are
			var ax := cx + x
			var ay := cy + y
			if ax < 0 or ay < 0 or ax >= out.get_width() or ay >= out.get_height():
				continue
			var orig := full.get_pixel(ax, ay)
			var c := _snap(cand.get_pixel(x, y))
			var in_far := fr.has_point(Vector2i(x, y))
			if orig.a < 0.5 or in_far:
				if c == SKY:
					if not in_far:
						continue
					out.set_pixel(ax, ay, Color(0, 0, 0, 0))
				else:
					out.set_pixel(ax, ay, Color(c, 1.0))
	# TOPCLEAR=x0,x1 (crop px): wipe the original art above the crop in these
	# columns (e.g. a tower the refinement replaced).
	if OS.get_environment("TOPCLEAR") != "":
		var tc := OS.get_environment("TOPCLEAR").split(",")
		for y in range(0, cy):
			for x in range(int(tc[0]), int(tc[1])):
				if cx + x >= 0 and cx + x < out.get_width():
					out.set_pixel(cx + x, y, Color(0, 0, 0, 0))
	out.save_png(OS.get_environment("OUT"))
	print("composited ", OS.get_environment("OUT"), " shift ", shift)
	quit()
