extends SceneTree
## Renders code-drawn nodes of the world map to PNGs, so they can be painted
## on in Aseprite (each node is drawn on its own, exactly as in the game, at
## SCALE x resolution, cropped to what it draws). Prints, per node, the offset
## of the image's top-left corner from the node's origin (in world px).
## Needs a window (it renders): run without --headless:
##   Summer --path . --script res://tools/render_nodes_to_png.gd
## Edit NODES / OUT below for other pieces.

const SCENE := "res://scenes/world/world_map.tscn"
const NODES := ["Bridges/Bridge1", "Bridges/Bridge2", "Bridges/Bridge3", "Bridges/Bridge4", "Bridges/Bridge5",
	"Bridges/Bridge6", "Bridges/SideStreet1", "Bridges/SideStreet2"]
const OUT := "res://assets/sprites/world/bridges/%s.png"
const SCALE := 2
const AREA := Rect2(-260, -330, 520, 400)      # world px around the origin that gets rendered


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var map: Node = (load(SCENE) as PackedScene).instantiate()
	var vp := SubViewport.new()
	vp.size = Vector2i(AREA.size * SCALE)
	vp.transparent_bg = true
	vp.canvas_item_default_texture_filter = Viewport.DEFAULT_CANVAS_ITEM_TEXTURE_FILTER_NEAREST
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(vp)
	var offsets := {}
	for path in NODES:
		var src: Node2D = map.get_node(path)
		var n: Node2D = src.duplicate()
		n.position = -AREA.position * SCALE
		n.scale = Vector2(SCALE, SCALE)
		vp.add_child(n)
		for i in 4:
			await process_frame
		var img := vp.get_texture().get_image()
		var used := img.get_used_rect()
		var cropped := img.get_region(used)
		var name := String(src.name).to_lower()
		cropped.save_png(ProjectSettings.globalize_path(OUT % name))
		var off := AREA.position + Vector2(used.position) / SCALE
		offsets[String(src.name)] = off
		print("%s  %dx%d  offset %s" % [name, used.size.x, used.size.y, off])
		n.free()
	print("OFFSETS ", JSON.stringify(offsets))
	map.free()
	quit()
