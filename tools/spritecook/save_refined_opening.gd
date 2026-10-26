extends SceneTree
# Saves a refined opening PNG as a V3Art with the painted art's origin.
# env: KIND SLOT OPEN SEED PNG NAME
func _initialize() -> void:
	_run.call_deferred()
func _run() -> void:
	var so: Node2D = load("res://scripts/world/side_opening.gd").new()
	so.kind = int(OS.get_environment("KIND"))
	so.width = float(OS.get_environment("SLOT"))
	so.open_width = float(OS.get_environment("OPEN"))
	so.seed_value = int(OS.get_environment("SEED"))
	var base = so.v3_art()
	var img := Image.load_from_file(OS.get_environment("PNG"))
	var art := V3Art.new()
	art.png = img.save_png_to_buffer()
	art.origin = base.origin - Vector2i(0, int(OS.get_environment("SHIFT")) if OS.get_environment("SHIFT") != "" else 0)
	art.windows = base.windows
	var dir := "res://assets/sprites/world/openings/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(dir))
	var err := ResourceSaver.save(art, dir + OS.get_environment("NAME") + ".res", ResourceSaver.FLAG_COMPRESS)
	print("SAVED ", err, " origin ", art.origin)
	quit()
