extends SceneTree
# Writes the refined strip back into each row piece it touches: a V3Art per
# CityBlock (assets/sprites/world/blocks/<name>.res) or SideOpening
# (.../openings/<name>.res), grown upwards when the new gables are taller.
# Changed pixels go to the piece that owned them; new pixels over the sky go to
# the topmost piece covering that column. CityBlock windows: unchanged ones are
# kept, new ones found in the changed area (dark or lit panes).
# env: STRIPDIR NEW (strip_new.png, with _changed.png next to it)
const DARK := [Color("1d2838"), Color("2c4152")]
const LIT := [Color("f2bc58"), Color("f8dc8a"), Color("e08a36")]
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var sd := OS.get_environment("STRIPDIR")
	var owner := Image.load_from_file(sd + "/owner.png")
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(sd + "/pieces.json"))
	var a0: int = int(meta.a)
	var top: int = int(meta.top)
	var pieces: Array = meta.pieces
	var newp := OS.get_environment("NEW")
	var strip := Image.load_from_file(newp)
	strip.convert(Image.FORMAT_RGBA8)
	var changed := Image.load_from_file(newp.get_basename() + "_changed.png")
	var W := strip.get_width()
	var H := strip.get_height()
	# Who gets each changed pixel.
	var assign := {}                         # piece index -> Array of Vector2i (strip px)
	for x in W:
		var cover := -1
		for i in pieces.size():
			var p: Dictionary = pieces[i]
			if p.cls == "WorldBuilding":
				continue
			var L: int = int(p.L) - a0
			if x >= L and x < L + int(p.w):
				cover = i                    # later = drawn on top
		for y in H:
			if changed.get_pixel(x, y).r < 0.5:
				continue
			var oi := int(round(owner.get_pixel(x, y).r * 255.0)) - 1
			var tgt := oi if oi >= 0 and pieces[oi].cls != "WorldBuilding" else cover
			if tgt < 0:
				continue
			if not assign.has(tgt):
				assign[tgt] = []
			assign[tgt].append(Vector2i(x, y))
	var map: Node = (load("res://scenes/world/world_map.tscn") as PackedScene).instantiate()
	for i: int in assign:
		var p: Dictionary = pieces[i]
		var node := map.get_node(NodePath(p.path))
		var art: V3Art = node.refined_art() if node.refined_art() else node.v3_art()
		var img := Image.new()
		img.load_png_from_buffer(art.png)
		img.convert(Image.FORMAT_RGBA8)
		var L: int = int(p.L) - a0
		var T: int = top + art.origin.y        # strip row of the image's top
		var pts: Array = assign[i]
		var min_y := T
		for v: Vector2i in pts:
			if strip.get_pixel(v.x, v.y).a > 0.5:
				min_y = mini(min_y, v.y)
		var grow := T - min_y
		var out := Image.create(img.get_width(), img.get_height() + grow, false, Image.FORMAT_RGBA8)
		out.blit_rect(img, Rect2i(Vector2i.ZERO, img.get_size()), Vector2i(0, grow))
		var mask := Image.create(out.get_width(), out.get_height(), false, Image.FORMAT_L8)
		for v: Vector2i in pts:
			var ix := v.x - L
			var iy := v.y - min_y
			if ix < 0 or ix >= out.get_width() or iy < 0 or iy >= out.get_height():
				continue
			out.set_pixel(ix, iy, strip.get_pixel(v.x, v.y))
			mask.set_pixel(ix, iy, Color.WHITE)
		var res := V3Art.new()
		res.png = out.save_png_to_buffer()
		res.origin = Vector2i(art.origin.x, art.origin.y - grow)
		var wins := []
		for w: Array in art.windows:              # rects are relative to the node origin
			var r: Rect2i = w[0]
			var cx := r.position.x - art.origin.x + r.size.x / 2
			var cy := r.position.y - res.origin.y + r.size.y / 2
			if cx >= 0 and cy >= 0 and cx < out.get_width() and cy < out.get_height() and mask.get_pixel(cx, cy).r > 0.5:
				continue
			wins.append(w)
		if p.cls == "CityBlock":
			wins.append_array(_find_windows(out, mask, res.origin))
		res.windows = wins
		var dir := "res://assets/sprites/world/" + ("blocks/" if p.cls == "CityBlock" else "openings/")
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
		ResourceSaver.save(res, dir + p.name + ".res", ResourceSaver.FLAG_COMPRESS)
		print("SPLIT ", p.name, " px ", pts.size(), " grow ", grow, " windows ", wins.size())
	quit()
## Window panes in the changed area: compact blobs of dark glass or lit glass.
func _find_windows(img: Image, mask: Image, origin: Vector2i) -> Array:
	var seen := {}
	var out := []
	for y in img.get_height():
		for x in img.get_width():
			if mask.get_pixel(x, y).r < 0.5 or seen.has(Vector2i(x, y)):
				continue
			var c := img.get_pixel(x, y)
			var lit := _in(c, LIT)
			if not lit and not _in(c, DARK):
				continue
			var stack := [Vector2i(x, y)]
			seen[Vector2i(x, y)] = true
			var n := 0
			var r := Rect2i(x, y, 1, 1)
			while not stack.is_empty() and n < 2000:
				var q: Vector2i = stack.pop_back()
				n += 1
				r = r.expand(q).expand(q + Vector2i.ONE)
				for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
					var t: Vector2i = q + d
					if t.x < 0 or t.y < 0 or t.x >= img.get_width() or t.y >= img.get_height() or seen.has(t):
						continue
					var tc := img.get_pixel(t.x, t.y)
					if (lit and _in(tc, LIT)) or (not lit and _in(tc, DARK)):
						seen[t] = true
						stack.append(t)
			var fill := float(n) / float(r.get_area())
			if r.size.x >= 4 and r.size.y >= 6 and r.size.x <= 26 and r.size.y <= 40 and r.size.y >= r.size.x and fill > 0.6 and r.position.y < img.get_height() - 30:
				out.append([Rect2i(r.position + origin, r.size), lit])
	return out
func _in(c: Color, list: Array) -> bool:
	for k: Color in list:
		if absf(c.r - k.r) + absf(c.g - k.g) + absf(c.b - k.b) < 0.03:
			return true
	return false
