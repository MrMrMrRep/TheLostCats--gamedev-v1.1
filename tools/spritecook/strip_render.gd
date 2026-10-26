extends SceneTree
# Renders the house row between art x A..B as the game draws it (Bridges, then
# Buildings, in tree order) into strip.png, plus owner.png (R = piece index+1,
# the topmost opaque piece per pixel) and pieces.json. GY at y = TOP.
# env: A B OUTDIR
const TOP := 440
const H := 470
func _initialize() -> void:
	_run.call_deferred()
func _wx(n: Node) -> float:
	var x := 0.0
	var p := n
	while p:
		if p is Node2D:
			x += (p as Node2D).position.x
		p = p.get_parent()
	return x
func _run() -> void:
	var a := int(OS.get_environment("A"))
	var b := int(OS.get_environment("B"))
	var outdir := OS.get_environment("OUTDIR")
	var map: Node = (load("res://scenes/world/world_map.tscn") as PackedScene).instantiate()
	var strip := Image.create(b - a, H, false, Image.FORMAT_RGBA8)
	var owner := Image.create(b - a, H, false, Image.FORMAT_RGBA8)
	var pieces := []
	for path in ["Bridges", "Buildings"]:
		for n in map.get_node(path).find_children("*", "", true, false):
			if not n.has_method("v3_art"):
				continue
			var art = n.refined_art() if n.has_method("refined_art") and n.refined_art() else n.v3_art()
			var img := Image.new()
			img.load_png_from_buffer(art.png)
			img.convert(Image.FORMAT_RGBA8)
			var L: int = int(round(_wx(n) * 2.0)) + int(art.origin.x)
			if L + img.get_width() < a or L > b:
				continue
			var idx := pieces.size()
			var d := {"name": String(n.name), "path": String(map.get_path_to(n)), "cls": n.get_script().get_global_name(),
				"L": L, "T": TOP + art.origin.y, "w": img.get_width(), "h": img.get_height(), "ox": art.origin.x, "oy": art.origin.y}
			if "open_width" in n:
				var c := int(round(_wx(n) * 2.0))
				d["open"] = [c - int(n.open_width), c + int(n.open_width)]
				d["kind"] = n.kind; d["slot"] = n.width; d["openw"] = n.open_width; d["seed"] = n.seed_value
			if n.has_method("layout"):
				var cuts := []
				var x := int(round(_wx(n) * 2.0))
				for r in n.layout():
					x += int(r.w) * 2
					cuts.append(x)
				d["cuts"] = cuts
			pieces.append(d)
			for y in img.get_height():
				var sy: int = TOP + int(art.origin.y) + y
				if sy < 0 or sy >= H:
					continue
				for x in img.get_width():
					var sx: int = L + x - a
					if sx < 0 or sx >= b - a:
						continue
					var c := img.get_pixel(x, y)
					if c.a > 0.5:
						strip.set_pixel(sx, sy, Color(c, 1.0))
						owner.set_pixel(sx, sy, Color8(idx + 1, 0, 0, 255))
	strip.save_png(outdir + "/strip.png")
	owner.save_png(outdir + "/owner.png")
	var f := FileAccess.open(outdir + "/pieces.json", FileAccess.WRITE)
	f.store_string(JSON.stringify({"a": a, "b": b, "top": TOP, "pieces": pieces}, " "))
	f.close()
	print("STRIP ", b - a, "x", H, " pieces ", pieces.size())
	quit()
