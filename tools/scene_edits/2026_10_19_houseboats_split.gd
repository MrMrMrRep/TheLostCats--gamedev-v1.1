@tool
extends EditorScript
## One-off edit (2026-10-19), kept for the record: the Houseboats node (one
## node drawing 8 boats from a list) becomes a Houseboats folder with one node
## per boat, each keeping its exact look (look_state). Don't run it again.

const PATH := "res://scenes/world/world_map.tscn"
# [world x, rng state the boat was drawn with] from the old single node.
const BOATS := [[9900.0, -7684921244414978279], [10560.0, 6482100845623445162], [11320.0, 9077513261364656873],
	[12120.0, 9001845482762850780], [12860.0, -245767071805463409], [13560.0, -7071870012224556958],
	[14260.0, -6351730282319425995], [15080.0, -7694558130491081212]]


func _run() -> void:
	var root: Node = (load(PATH) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var old: Node2D = root.get_node("Houseboats")
	if old.get_script() == null:
		push_error("already done")
		root.free()
		return
	var script: Script = old.get_script()
	var idx := old.get_index()
	var y := old.position.y
	root.remove_child(old)
	old.free()
	var folder := Node2D.new()
	folder.name = "Houseboats"
	root.add_child(folder)
	root.move_child(folder, idx)
	folder.owner = root
	for i in BOATS.size():
		var b := Node2D.new()
		b.set_script(script)
		b.name = "Houseboat%d" % (i + 1)
		b.position = Vector2(BOATS[i][0], y)
		b.set("seed_value", 3)
		b.set("look_state", BOATS[i][1])
		folder.add_child(b)
		b.owner = root
	var out := PackedScene.new()
	var err := out.pack(root)
	if err == OK:
		err = ResourceSaver.save(out, PATH)
	print("saved: ", error_string(err))
	root.free()
