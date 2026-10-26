extends SceneTree
# Pastes edited chunks back into the strip. For each chunk in CHUNKS (with
# x0 from the crop step: env X0S "id:x0,...") the raw image RAWDIR/<id>_raw.jpg
# is scaled to the crop, snapped to the palette and written into the chunk's
# columns, except over WorldBuildings (churches...) and opening interiors.
# Sky becomes transparent. env: STRIPDIR CHUNKS X0S RAWDIR OUT
const SIDE := 460
const Y0 := 10
const SKY := Color("8ec5e6")
var _pal: Array = []
var _memo := {}
func _initialize() -> void:
	_run.call_deferred()
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
	var sd := OS.get_environment("STRIPDIR")
	var strip := Image.load_from_file(sd + "/strip.png")
	strip.convert(Image.FORMAT_RGBA8)
	var owner := Image.load_from_file(sd + "/owner.png")
	var meta: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(sd + "/pieces.json"))
	var a0: int = int(meta.a)
	var pieces: Array = meta.pieces
	var interiors := []
	for p: Dictionary in pieces:
		if p.has("open"):
			interiors.append(Vector2i(int(p.open[0]) - a0, int(p.open[1]) - a0))
	var x0s := {}
	for kv in OS.get_environment("X0S").split(","):
		var parts := kv.split(":")
		x0s[parts[0]] = int(parts[1])
	var out := strip.duplicate()
	var changed := Image.create(strip.get_width(), strip.get_height(), false, Image.FORMAT_L8)
	var chunks: Array = JSON.parse_string(FileAccess.get_file_as_string(OS.get_environment("CHUNKS")))
	for c: Dictionary in chunks:
		var path: String = OS.get_environment("RAWDIR") + "/" + c.id + "_raw.jpg"
		if not FileAccess.file_exists(path):
			continue
		var raw := Image.load_from_file(path)
		raw.convert(Image.FORMAT_RGBA8)
		raw.resize(SIDE, SIDE, Image.INTERPOLATE_LANCZOS)
		var cx0: int = x0s[c.id]
		for sx in range(int(c.a) - a0, int(c.b) - a0):
			var inside := false
			for iv: Vector2i in interiors:
				if sx >= iv.x and sx < iv.y:
					inside = true
			if inside:
				continue
			for y in SIDE:
				var sy := Y0 + y
				if sy >= strip.get_height():
					continue
				var oi := int(round(owner.get_pixel(sx, sy).r * 255.0)) - 1
				if oi >= 0 and pieces[oi].cls == "WorldBuilding":
					continue
				var col := _snap(raw.get_pixel(sx - cx0, y))
				out.set_pixel(sx, sy, Color(0, 0, 0, 0) if col == SKY else Color(col, 1.0))
				changed.set_pixel(sx, sy, Color.WHITE)
		print("applied ", c.id)
	out.save_png(OS.get_environment("OUT"))
	changed.save_png(OS.get_environment("OUT").get_basename() + "_changed.png")
	quit()
