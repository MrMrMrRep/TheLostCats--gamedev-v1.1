@tool
extends RefCounted
## Builds the Godot resources described in public/assets/amwoods/assets.json:
##   - one SpriteFrames .tres per spritesheet
##   - the TileSet .tres (collision + "kind" custom data per tile)
## Re-run after changing assets.json (via summer_run_script or an EditorScript).

const MANIFEST := "res://public/assets/amwoods/assets.json"
const HALF := 12.0  # half tile (24 px tiles)


static func build() -> Dictionary:
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(MANIFEST))
	var root: String = manifest.root
	var report := {}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://resources/sprites"))
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://resources/tiles"))
	for sheet in manifest.spritesheets:
		var out: String = sheet.get("godot_resource", "res://resources/sprites/%s_frames.tres" % sheet.id)
		report[sheet.id] = ResourceSaver.save(_build_frames(root, sheet), out)
	var tiles: Dictionary = manifest.tileset
	report[tiles.id] = ResourceSaver.save(_build_tileset(root, tiles), tiles.godot_resource)
	return report


static func _build_frames(root: String, sheet: Dictionary) -> SpriteFrames:
	var texture: Texture2D = load(root + sheet.path)
	var size := Vector2(sheet.frame_size[0], sheet.frame_size[1])
	var frames := SpriteFrames.new()
	frames.remove_animation(&"default")
	for anim in sheet.animations:
		frames.add_animation(anim.name)
		frames.set_animation_speed(anim.name, anim.fps)
		frames.set_animation_loop(anim.name, anim.loop)
		for cell in anim.frames:
			var atlas := AtlasTexture.new()
			atlas.atlas = texture
			atlas.region = Rect2(Vector2(cell[0], cell[1]) * size, size)
			frames.add_frame(anim.name, atlas)
	return frames


static func _build_tileset(root: String, spec: Dictionary) -> TileSet:
	var texture: Texture2D = load(root + spec.path)
	var image := texture.get_image()
	var tile := Vector2i(spec.tile_size[0], spec.tile_size[1])

	var ts := TileSet.new()
	ts.tile_size = tile
	ts.add_physics_layer()  # 0: solid
	ts.set_physics_layer_collision_layer(0, 1)
	ts.set_physics_layer_collision_mask(0, 0)
	ts.add_physics_layer()  # 1: one-way
	ts.set_physics_layer_collision_layer(1, 2)
	ts.set_physics_layer_collision_mask(1, 0)
	ts.add_custom_data_layer()
	ts.set_custom_data_layer_name(0, "kind")
	ts.set_custom_data_layer_type(0, TYPE_STRING)

	var src := TileSetAtlasSource.new()
	src.texture = texture
	src.texture_region_size = tile
	ts.add_source(src, 0)

	var kinds := _kind_lookup(spec.regions)
	var square := PackedVector2Array([Vector2(-HALF, -HALF), Vector2(HALF, -HALF), Vector2(HALF, HALF), Vector2(-HALF, HALF)])
	for row in spec.grid[1]:
		for col in spec.grid[0]:
			var coords := Vector2i(col, row)
			if image.get_region(Rect2i(coords * tile, tile)).is_invisible():
				continue
			src.create_tile(coords)
			var kind: String = kinds.get(coords, "background")
			var data := src.get_tile_data(coords, 0)
			data.set_custom_data("kind", kind)
			match kind:
				"solid":
					data.add_collision_polygon(0)
					data.set_collision_polygon_points(0, 0, square)
				"one_way":
					# Thin top surface so the player stands on the visible edge.
					data.add_collision_polygon(1)
					data.set_collision_polygon_points(1, 0, PackedVector2Array([Vector2(-HALF, -HALF), Vector2(HALF, -HALF), Vector2(HALF, -HALF + 6), Vector2(-HALF, -HALF + 6)]))
					data.set_collision_polygon_one_way(1, 0, true)
	return ts


static func _kind_lookup(regions: Array) -> Dictionary:
	var out := {}
	for region in regions:
		var cells: Array = []
		if region.has("tiles"):
			cells = region.tiles
		else:
			for y in region.size[1]:
				for x in region.size[0]:
					cells.append([region.origin[0] + x, region.origin[1] + y])
		for c in cells:
			out[Vector2i(c[0], c[1])] = region.kind
	return out
