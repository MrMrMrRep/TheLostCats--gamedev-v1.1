extends SceneTree
# Exports a SideOpening's baked art: full PNG + info, and a square crop of the
# opening's far part over a flat sky colour (for a SpriteCook edit).
# env: KIND SLOT OPEN SEED OUT(dir) NAME
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var so: Node2D = load("res://scripts/world/side_opening.gd").new()
	so.kind = int(OS.get_environment("KIND"))
	so.width = float(OS.get_environment("SLOT"))
	so.open_width = float(OS.get_environment("OPEN"))
	so.seed_value = int(OS.get_environment("SEED"))
	var art = so.v3_art()
	var img := Image.new()
	img.load_png_from_buffer(art.png)
	var out := OS.get_environment("OUT")
	var nm := OS.get_environment("NAME")
	img.save_png(out + "/" + nm + "_full.png")
	var ow := int(so.open_width) * 2
	var side := 360
	var ox := -int(art.origin.x) - side / 2          # crop centred on the opening
	var oy := -int(art.origin.y) - side              # bottom = street line
	var crop := Image.create(side, side, false, Image.FORMAT_RGBA8)
	crop.fill(Color("8ec5e6"))
	var region := img.get_region(Rect2i(ox, oy, side, side))
	crop.blend_rect(region, Rect2i(0, 0, side, side), Vector2i.ZERO)
	crop.save_png(out + "/" + nm + "_crop.png")
	var mask := region.duplicate()               # keep alpha of the original crop
	mask.save_png(out + "/" + nm + "_crop_alpha.png")
	print("INFO size=", img.get_size(), " origin=", art.origin, " crop_at=", Vector2i(ox, oy), " open_px=", ow)
	quit()
