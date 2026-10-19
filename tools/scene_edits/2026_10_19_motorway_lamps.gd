@tool
extends EditorScript
## One-off edit (2026-10-19), kept for the record: adds lamp rows along the
## motorway (west of town and past the storage). Don't run it again.

const PATH := "res://scenes/world/world_map.tscn"


func _run() -> void:
	var root: Node = (load(PATH) as PackedScene).instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	if root.find_child("MotorwayLampsWest", true, false):
		push_error("already done")
		root.free()
		return
	var row: Script = load("res://scripts/world/lamp_row.gd")
	for r in [["Signs/WestRoad", "MotorwayLampsWest", -3950.0, 9900.0], ["Signs/Airport", "MotorwayLampsEast", 18300.0, 3250.0]]:
		var n := Node2D.new()
		n.set_script(row)
		n.name = r[1]
		n.position = Vector2(r[2], 288.0)
		n.set("length", r[3])
		root.get_node(r[0]).add_child(n)
		n.owner = root
	var out := PackedScene.new()
	var err := out.pack(root)
	if err == OK:
		err = ResourceSaver.save(out, PATH)
	print("saved: ", error_string(err))
	root.free()
