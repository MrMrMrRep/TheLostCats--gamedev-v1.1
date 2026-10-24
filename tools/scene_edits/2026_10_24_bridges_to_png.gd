@tool
extends EditorScript
## One-off (2026-10-24), kept for the record: Bridge1-6 and SideStreet1-2
## become painted images (assets/sprites/world/bridges/*.png, rendered at 2x by
## tools/render_nodes_to_png.gd) so they can be edited in Aseprite. Each keeps
## its name and position; a child Sprite2D "Image" shows the PNG at half scale.

const PATH := "res://scenes/world/world_map.tscn"
const OFFSETS := {"Bridge1": Vector2(-145, -158), "Bridge2": Vector2(-145, -175), "Bridge3": Vector2(-145, -145),
	"Bridge4": Vector2(-145, -194), "Bridge5": Vector2(-145, -177), "Bridge6": Vector2(-145, -174),
	"SideStreet1": Vector2(-125, -160), "SideStreet2": Vector2(-125, -168)}


func _run() -> void:
	var root: Node = (load(PATH) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var bridges := root.get_node("Bridges")
	for name in OFFSETS:
		var old: Node2D = bridges.get_node(name)
		if old.get_script() == null:
			continue                            # done already
		var idx := old.get_index()
		var n := Node2D.new()
		n.name = name + "_new"
		n.position = old.position
		bridges.add_child(n)
		bridges.move_child(n, idx)
		n.owner = root
		bridges.remove_child(old)
		old.free()
		n.name = name
		var img := Sprite2D.new()
		img.name = "Image"
		img.texture = load("res://assets/sprites/world/bridges/%s.png" % name.to_lower())
		img.centered = false
		img.position = OFFSETS[name]
		img.scale = Vector2(0.5, 0.5)           # painted at 2x the world's pixels
		n.add_child(img)
		img.owner = root
	var out := PackedScene.new()
	var err := out.pack(root)
	if err == OK:
		err = ResourceSaver.save(out, PATH)
	print("saved: ", error_string(err))
	root.free()
