extends Node
## Bakes the style v3 world art into res://assets/sprites/world/v3/ so the game
## only loads it: every CityBlock and WorldBuilding in the world map, the
## SideOpening (alleys, side streets, side canals), the
## street strip, the sky sprites, the cars and the palette filter's table.
## Run after changing the v3 painter (bump V3Cache.VERSION) or the buildings:
##   Summer --headless --path . res://tools/bake_world_v3.tscn
## (a scene, not --script: the game's autoloads have to be there).
## The world map scene is read as text (never saved), so editing it is safe.
## Files no longer used are deleted at the end.

const SCENE := "res://scenes/world/world_map.tscn"


func _ready() -> void:
	var t0 := Time.get_ticks_msec()
	V3Cache.save_to_disk = true
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(V3Cache.DIR))
	WorldPalette.snap_material()
	V3Cache.art("street_town", func() -> V3Art: return V3Painter.street_tile(1440))
	V3Cache.art("sky_sun", func() -> V3Art: return V3Painter.sun_sprite(22))
	for k in 4:
		V3Cache.art("sky_cloud%d" % k, func() -> V3Art: return V3Painter.cloud_sprite(0.9 + k * 0.35))
	_bake_vehicles()
	WorldScenery.bake_v3()
	var n := _bake_scene()
	_prune()
	print("v3 bake: %d buildings, %d files, %.1f s" % [n, V3Cache.used.size(), (Time.get_ticks_msec() - t0) / 1000.0])
	get_tree().quit()


func _bake_vehicles() -> void:
	for kind: String in CarArt.V3_KINDS.values():
		if kind == "taxi":
			CarArt.v3_art(kind, "yellow")
			continue
		for colour: String in CarArt.V3_COLOURS:
			CarArt.v3_art(kind, colour)
	for colour: String in CarArt.V3_COLOURS:
		CarArt.v3_art("coupe", colour)
	for colour in ["white", "cream", "silver", "teal", "red"]:
		CarArt.v3_art("van", colour)
	CarArt.v3_art("truck", "")
	CarArt.v3_art("bus", "teal")
	CarArt.v3_art("bus", "red")


## Reads the scene text: every node with the CityBlock or WorldBuilding script,
## its exported values, then asks it for its art.
func _bake_scene() -> int:
	var text := FileAccess.get_file_as_string(SCENE)
	var scripts := {}                       # ext_resource id -> path
	var re_ext := RegEx.create_from_string('\\[ext_resource type="Script"[^\\]]*path="([^"]+)" id="([^"]+)"\\]')
	for m in re_ext.search_all(text):
		scripts[m.get_string(2)] = m.get_string(1)
	var count := 0
	for section in text.split("\n[node "):
		var props := {}
		for line in section.split("\n"):
			var eq := line.find(" = ")
			if eq > 0 and not line.begins_with("["):
				props[line.substr(0, eq)] = line.substr(eq + 3)
		if not props.has("script"):
			continue
		var id := (props["script"] as String).trim_prefix('ExtResource("').trim_suffix('")')
		var path: String = scripts.get(id, "")
		var node: Node2D = null
		if path.ends_with("city_block.gd"):
			node = CityBlock.new()
		elif path.ends_with("outskirts.gd"):
			node = WorldBuilding.new()
		elif path.ends_with("side_opening.gd"):
			node = SideOpening.new()
		elif path.ends_with("street_life.gd"):
			node = WorldStreetLife.new()
		else:
			continue
		for key: String in ["houses", "seed_value", "sign_text", "shop_rate", "shop_signs", "style", "kind", "width", "open_width", "poort", "length", "keep_clear"]:
			if props.has(key):
				node.set(key, str_to_var(props[key]))
		if node is CityBlock:
			(node as CityBlock).v3_art()
		elif node is WorldStreetLife:
			(node as WorldStreetLife).v3_art()
		elif node is SideOpening:
			(node as SideOpening).v3_art()
			if (node as SideOpening).kind == SideOpening.Kind.CANAL:
				(node as SideOpening).bridge_art()
		else:
			(node as WorldBuilding).v3_art()
		node.free()
		count += 1
	return count


func _prune() -> void:
	var dir := DirAccess.open(V3Cache.DIR)
	if dir == null:
		return
	for f in dir.get_files():
		if f.ends_with(".res") and not V3Cache.used.has(f):
			dir.remove(f)
			print("removed old ", f)
