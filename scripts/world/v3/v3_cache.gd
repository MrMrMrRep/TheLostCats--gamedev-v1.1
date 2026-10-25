class_name V3Cache
extends RefCounted
## Baked style-v3 art by key. Painting in GDScript is slow (a row of houses
## takes a moment), so every piece is painted once and saved as a V3Art in
## res://assets/sprites/world/v3/ (the editor and tools/bake_world_v3.gd do
## that); the game only loads them. A piece that isn't baked yet is painted
## on the spot (slower start, same look).
## Bump VERSION when the painter changes, then run the bake tool again.

const DIR := "res://assets/sprites/world/v3/"
const VERSION := 5                          # 5: planes at the gate, polder sprites, v3 trees

static var save_to_disk := false            ## the bake tool turns this on
static var used: Dictionary = {}            ## file names asked for this run (the bake tool prunes the rest)
static var _mem: Dictionary = {}


## The art for `key` (any string that changes whenever the look should);
## `paint` makes it (returns a V3Art) when it isn't baked yet.
static func art(key: String, paint: Callable) -> V3Art:
	var full := "%s|v%d" % [key, VERSION]
	if _mem.has(full):
		return _mem[full]
	var file := "%s_%s.res" % [key.get_slice("|", 0).validate_filename(), full.md5_text().substr(0, 10)]
	used[file] = true
	var path := DIR + file
	var a: V3Art = null
	if ResourceLoader.exists(path):
		a = load(path) as V3Art
	if a == null:
		a = paint.call() as V3Art
		if a and (save_to_disk or Engine.is_editor_hint()):
			DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(DIR))
			ResourceSaver.save(a, path, ResourceSaver.FLAG_COMPRESS)
	_mem[full] = a
	return a


## Forget the in-memory copies (the editor repaints after a change).
static func clear_memory() -> void:
	_mem.clear()
