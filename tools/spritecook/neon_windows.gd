extends SceneTree
# Finds the red-curtain windows framed by neon tubes in a refined block and
# adds them as red night windows ([rect, false, colour]). env: RES
const CURTAIN := [Color("8f3f40"), Color("5e2e36"), Color("bd5a4b")]
const TUBE := [Color("e07d5e"), Color("e08a36"), Color("f2a77a")]
func _initialize() -> void:
	var a: V3Art = load(OS.get_environment("RES"))
	var img := Image.new(); img.load_png_from_buffer(a.png)
	img.convert(Image.FORMAT_RGBA8)
	var kept := []
	for w in a.windows:
		if w.size() < 3:
			kept.append(w)
	var seen := {}
	var found := 0
	for y in img.get_height():
		for x in img.get_width():
			var p := Vector2i(x, y)
			if seen.has(p) or not _in(img.get_pixel(x, y), TUBE):
				continue
			# a neon frame: a connected ring of tube pixels
			var stack := [p]; seen[p] = true
			var r := Rect2i(p, Vector2i.ONE); var n := 0
			while not stack.is_empty() and n < 3000:
				var q: Vector2i = stack.pop_back(); n += 1
				r = r.expand(q).expand(q + Vector2i.ONE)
				for d in [Vector2i(1,0), Vector2i(-1,0), Vector2i(0,1), Vector2i(0,-1)]:
					var t: Vector2i = q + d
					if t.x < 0 or t.y < 0 or t.x >= img.get_width() or t.y >= img.get_height() or seen.has(t):
						continue
					if _in(img.get_pixel(t.x, t.y), TUBE):
						seen[t] = true; stack.append(t)
			if r.size.x < 8 or r.size.y < 10 or r.size.x > 60 or r.size.y > 90:
				continue
			var fill := float(n) / r.get_area()
			if fill > 0.6:
				continue                         # a solid patch, not a frame
			# curtain inside?
			var c := img.get_pixel(r.position.x + r.size.x / 2, r.position.y + r.size.y / 2)
			var cin := 0
			for k in range(1, r.size.x - 1):
				if _in(img.get_pixel(r.position.x + k, r.position.y + r.size.y / 3), CURTAIN):
					cin += 1
			if cin < r.size.x / 4:
				continue
			kept.append([Rect2i(r.position + a.origin, r.size), false, Color(1.0, 0.12, 0.22, 0.85)])
			found += 1
	a.windows = kept
	ResourceSaver.save(a, OS.get_environment("RES"), ResourceSaver.FLAG_COMPRESS)
	print("NEON ", found)
	quit()
func _in(c: Color, list: Array) -> bool:
	for k: Color in list:
		if absf(c.r - k.r) + absf(c.g - k.g) + absf(c.b - k.b) < 0.03:
			return true
	return false
