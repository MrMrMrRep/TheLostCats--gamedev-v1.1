@tool
extends EditorScript
## One-off (2026-10-20), kept for the record: creates scenes/levels/base.tscn,
## the band's base in the storage: one room with a door (in and out), a couch,
## a fridge, instruments and the party board. Refuses if the scene exists:
## from then on it's edited by hand like any level.

const PATH := "res://scenes/levels/base.tscn"
const GY := 288.0

var root: Node2D


func _run() -> void:
	if ResourceLoader.exists(PATH):
		push_error("base.tscn exists already: edit it in the editor")
		return
	root = Node2D.new()
	root.name = "Base"
	root.set_script(load("res://scripts/levels/level.gd"))
	root.set("party_only", false)
	var art := Node2D.new()
	art.set_script(load("res://scripts/base/base_room_art.gd"))
	_add(root, art, "RoomArt")
	var tm := TileMapLayer.new()
	tm.tile_set = load("res://resources/tiles/amwoods_tileset.tres")
	tm.visible = false
	_add(root, tm, "Ground")
	for x in range(-2, 29):
		tm.set_cell(Vector2i(x, 12), 0, Vector2i(12, 0))
	for y in range(0, 12):
		tm.set_cell(Vector2i(-1, y), 0, Vector2i(12, 0))
		tm.set_cell(Vector2i(27, y), 0, Vector2i(12, 0))
	var rooms := _add(root, Node2D.new(), "Rooms")
	var room := Node2D.new()
	room.set_script(load("res://scripts/levels/room.gd"))
	room.set("bounds", Rect2i(0, 0, 640, 360))
	_add(rooms, room, "Rehearsal")
	var entry := Marker2D.new()
	entry.position = Vector2(84, GY)
	_add(room, entry, "BaseEntry")
	var door := Area2D.new()
	door.set_script(load("res://scripts/levels/door.gd"))
	door.position = Vector2(40, GY)
	door.set("target_scene", "res://scenes/world/world_map.tscn")
	door.set("target_spawn", &"StorageGate")
	_add(room, door, "BaseExit")
	var Prop = load("res://scripts/base/base_prop.gd")
	# [name, kind, x, y, min_base_level, text]
	for p in [["Fridge", 1, 112.0, GY, 1, ""], ["BeerCrate", 10, 136.0, GY, 1, ""],
			["Poster", 7, 168.0, 214.0, 1, "DE KAT"], ["Rug", 8, 226.0, GY, 1, ""],
			["Couch", 0, 226.0, GY, 1, ""], ["Lamp", 9, 272.0, GY, 1, ""],
			["AmpBass", 4, 382.0, GY, 1, ""], ["Drums", 2, 452.0, GY, 1, ""],
			["AmpGuitar", 3, 512.0, GY, 1, ""], ["Mic", 6, 548.0, GY, 1, ""], ["Keys", 5, 592.0, GY, 1, ""],
			["PosterBand", 7, 452.0, 196.0, 1, "LOST CATS"],
			["PosterTour", 7, 560.0, 206.0, 2, "TOUR"]]:   # an upgrade (base level 2)
		var n := Node2D.new()
		n.set_script(Prop)
		n.position = Vector2(p[2], p[3])
		n.set("kind", p[1])
		n.set("min_base_level", p[4])
		n.set("text", p[5])
		_add(room, n, p[0])
	var board := Area2D.new()
	board.set_script(load("res://scripts/base/party_board.gd"))
	board.position = Vector2(318, GY)
	_add(room, board, "PartyBoard")
	root.set("start_room", NodePath("Rooms/Rehearsal"))
	root.set("start_spawn", NodePath("Rooms/Rehearsal/BaseEntry"))
	_add(root, load("res://scenes/characters/band.tscn").instantiate(), "Band")
	_add(root, load("res://scenes/ui/hud.tscn").instantiate(), "HUD")
	_add(root, load("res://scenes/ui/debug_overlay.tscn").instantiate(), "DebugOverlay")
	var hint_layer := _add(root, CanvasLayer.new(), "DevHint")
	var hint := Label.new()
	hint.text = "E at the board: pick who goes out     E at the door: back to the city     1-5 / Tab: switch"
	hint.position = Vector2(8, 344)
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("outline_size", 3)
	_add(hint_layer, hint, "Hint")
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err == OK:
		err = ResourceSaver.save(ps, PATH)
	print("saved: ", error_string(err))
	root.free()


func _add(parent: Node, node: Node, name: String) -> Node:
	node.name = name
	parent.add_child(node)
	node.owner = root
	return node
