class_name LiveConfig
extends RefCounted
## Loads the tuning files in resources/config/ and, while the game runs from
## the editor, picks up changes saved in the inspector (checked about once a
## second): edit a number, press Ctrl+S, and the running game uses it.
## Scripts read the values when they need them, so nothing is copied at start.

const POLL_MS := 1000

static var _cache := {}                     # path -> {res, mtime}
static var _next_poll := 0


## The shared config at `path` (defaults from `script` if the file is missing).
static func fetch(path: String, script: Script) -> Resource:
	var entry: Dictionary = _cache.get(path, {})
	if entry.is_empty():
		var res: Resource = load(path) if ResourceLoader.exists(path) else null
		if res == null:
			res = script.new()
		entry = {"res": res, "mtime": _mtime(path)}
		_cache[path] = entry
	return entry.res


## Reload files that changed on disk (only when run from the editor).
static func poll() -> void:
	if not OS.has_feature("editor") or Engine.is_editor_hint():
		return
	var now := Time.get_ticks_msec()
	if now < _next_poll:
		return
	_next_poll = now + POLL_MS
	for path: String in _cache:
		var entry: Dictionary = _cache[path]
		var mtime := _mtime(path)
		if mtime == entry.mtime:
			continue
		entry.mtime = mtime
		var fresh: Resource = ResourceLoader.load(path, "", ResourceLoader.CACHE_MODE_IGNORE)
		if fresh == null:
			continue
		for p in fresh.get_property_list():
			if p.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
				entry.res.set(p.name, fresh.get(p.name))
		print("[config] reloaded ", path.get_file())


static func _mtime(path: String) -> int:
	return FileAccess.get_modified_time(path) if FileAccess.file_exists(path) else 0
