@tool
extends EditorScript
## One-off (2026-10-20), kept for the record: creates the puzzle test level
## scenes/levels/venue_puzzle.tscn (behind the Café De Kat door): back
## entrance, storage, bar with the bouncer, backstage and the finale "Where is
## Geoff?". Refuses if it exists: from then on it's edited by hand.

const PATH := "res://scenes/levels/venue_puzzle.tscn"
const T := 24
const GY := 288.0

var root: Node2D
var tm: TileMapLayer
var rooms: Node2D


func _run() -> void:
	if ResourceLoader.exists(PATH):
		push_error("venue_puzzle.tscn exists already: edit it in the editor")
		return
	root = Node2D.new()
	root.name = "VenuePuzzle"
	root.set_script(load("res://scripts/levels/level.gd"))
	var backs := _add(root, Node2D.new(), "Backdrops")
	tm = TileMapLayer.new()
	tm.tile_set = load("res://resources/tiles/amwoods_tileset.tres")
	tm.visible = false
	_add(root, tm, "Ground")
	rooms = _add(root, Node2D.new(), "Rooms")
	var names := ["BackEntrance", "Storage", "Bar", "Backstage", "Finale"]
	for i in names.size():
		var ox := i * 50 * T
		var art := Node2D.new()
		art.set_script(load("res://scripts/base/base_room_art.gd"))
		art.position = Vector2(ox, 0)
		art.set("size", Vector2(40 * T, 360))
		_add(backs, art, names[i] + "Wall")
		var room := Node2D.new()
		room.set_script(load("res://scripts/levels/room.gd"))
		room.set("bounds", Rect2i(ox, 0, 40 * T, 312))   # the view stops just under the floor
		_add(rooms, room, names[i])
		_solid(room, ox, 0, 12, 39, 14, 0)          # floor
		_solid(room, ox, 0, 0, 0, 11, 0)            # side walls
		_solid(room, ox, 39, 0, 39, 11, 0)
	_back_entrance(rooms.get_node("BackEntrance"), 0)
	_storage(rooms.get_node("Storage"), 50 * T)
	_bar(rooms.get_node("Bar"), 100 * T)
	_backstage(rooms.get_node("Backstage"), 150 * T)
	_finale(rooms.get_node("Finale"), 200 * T)
	root.set("start_room", NodePath("Rooms/BackEntrance"))
	root.set("start_spawn", NodePath("Rooms/BackEntrance/Start"))
	_add(root, load("res://scenes/characters/band.tscn").instantiate(), "Band")
	_add(root, load("res://scenes/ui/hud.tscn").instantiate(), "HUD")
	_add(root, load("res://scenes/ui/debug_overlay.tscn").instantiate(), "DebugOverlay")
	var ps := PackedScene.new()
	var err := ps.pack(root)
	if err == OK:
		err = ResourceSaver.save(ps, PATH)
	print("saved: ", error_string(err))
	root.free()


func _back_entrance(room: Node2D, ox: int) -> void:
	var start := Marker2D.new()
	start.position = Vector2(ox + 72, GY)
	_add(room, start, "Start")
	_sign(room, ox + 100, 168, "BACK ENTRANCE", "Over the wall: Nikki double-jumps, Joep climbs, Jay throws.\nPull the lever up there to open the gate for the others.")
	_solid(room, ox, 14, 8, 16, 8, 1)               # a shelf to jump to (4 tiles up: double jump / throw)
	_solid(room, ox, 19, 6, 21, 6, 1)               # a second shelf, the floor runs on underneath
	_solid(room, ox, 24, 4, 24, 8, 0)               # high wall, the gate under it
	var gate := _node(room, "res://scripts/props/gate.gd", "Gate", Vector2(ox + 24 * T + 12, GY), StaticBody2D)
	gate.set("size", Vector2(24, 72))
	var lever := _node(room, "res://scripts/props/switch_panel.gd", "Lever", Vector2(ox + 24 * T + 12, 4 * T), Area2D)
	lever.set("targets", _paths(["../Gate"]))
	_node(room, "res://scripts/enemies/rat.gd", "Rat", Vector2(ox + 760, GY), CharacterBody2D)
	_door(room, "ToStorage", Vector2(ox + 900, GY), "../../Storage/FromEntrance")


func _storage(room: Node2D, ox: int) -> void:
	_door(room, "FromEntrance", Vector2(ox + 60, GY), "../../BackEntrance/ToStorage")
	_sign(room, ox + 100, 168, "STORAGE", "The Germ smashes the crates. Only Jay pushes the flight case:\nThe Germ and Geoff need it as a step up.")
	_node(room, "res://scripts/enemies/rat.gd", "Rat", Vector2(ox + 220, GY), CharacterBody2D)
	var crates := _node(room, "res://scripts/props/breakable.gd", "Crates", Vector2(ox + 320, GY), StaticBody2D)
	crates.set("size", Vector2(24, 48))
	_node(room, "res://scripts/props/flight_case.gd", "FlightCase", Vector2(ox + 420, GY), CharacterBody2D)
	_solid(room, ox, 28, 10, 38, 11, 1)             # raised floor (2 tiles: too high for Germ and Geoff)
	_node(room, "res://scripts/props/item_pickup.gd", "Beer", Vector2(ox + 760, 10 * T), Area2D)
	var rat := _node(room, "res://scripts/enemies/rat.gd", "RatUp", Vector2(ox + 840, 10 * T), CharacterBody2D)
	rat.set("start_dir", -1.0)
	_door(room, "ToBar", Vector2(ox + 900, 10 * T), "../../Bar/FromStorage")


func _bar(room: Node2D, ox: int) -> void:
	_door(room, "FromStorage", Vector2(ox + 60, GY), "../../Storage/ToBar")
	_sign(room, ox + 100, 168, "BAR", "Joep hacks the fuse box. Jay's bass wave breaks the glass.\nGeoff talks to the bouncer. Give the keycard to whoever's at the door.")
	var hack := _node(room, "res://scripts/props/switch_panel.gd", "FuseBox", Vector2(ox + 150, GY), Area2D)
	hack.set("kind", 1)
	hack.set("targets", _paths(["../ElectricFloor"]))
	var floor_ := _node(room, "res://scripts/props/hazard.gd", "ElectricFloor", Vector2(ox + 300, GY), Area2D)
	floor_.set("kind", 1)
	floor_.set("width", 168.0)
	var glass := _node(room, "res://scripts/props/breakable.gd", "Glass", Vector2(ox + 470, GY), StaticBody2D)
	glass.set("substance", 0)
	glass.set("size", Vector2(24, 72))
	var card := _node(room, "res://scripts/props/item_pickup.gd", "Keycard", Vector2(ox + 520, GY), Area2D)
	card.set("item", load("res://resources/items/keycard_red.tres"))
	_node(room, "res://scripts/enemies/bouncer.gd", "Bouncer", Vector2(ox + 640, GY), Area2D)
	var door := _door(room, "LockedDoor", Vector2(ox + 900, GY), "../../Backstage/FromBar")
	door.set("locked", true)
	door.set("key_id", &"keycard_red")


func _backstage(room: Node2D, ox: int) -> void:
	_door(room, "FromBar", Vector2(ox + 60, GY), "../../Bar/LockedDoor")
	_sign(room, ox + 100, 168, "BACKSTAGE", "Split up: someone goes over the top and opens the gate\nfor the others down below.")
	var spikes := _node(room, "res://scripts/props/hazard.gd", "Spikes", Vector2(ox + 250, GY), Area2D)
	spikes.set("width", 48.0)
	_solid(room, ox, 6, 8, 8, 8, 1)                 # step up
	_solid(room, ox, 10, 6, 30, 6, 2)               # the walkway over the top
	var gate := _node(room, "res://scripts/props/gate.gd", "LowerGate", Vector2(ox + 21 * T + 12, GY), StaticBody2D)
	gate.set("size", Vector2(24, 120))
	var lever := _node(room, "res://scripts/props/switch_panel.gd", "Lever", Vector2(ox + 26 * T, 6 * T), Area2D)
	lever.set("targets", _paths(["../LowerGate"]))
	_door(room, "ToFinale", Vector2(ox + 900, GY), "../../Finale/FromBackstage")


func _finale(room: Node2D, ox: int) -> void:
	_door(room, "FromBackstage", Vector2(ox + 60, GY), "../../Backstage/ToFinale")
	_sign(room, ox + 100, 168, "WHERE IS GEOFF?", "He's asleep up on the stage rig. Take him the rolling papers:\nhe follows whoever carries them. Then everyone out together.")
	var papers := _node(room, "res://scripts/props/item_pickup.gd", "RollingPapers", Vector2(ox + 130, GY), Area2D)
	papers.set("item", load("res://resources/items/rolling_papers.tres"))
	_solid(room, ox, 10, 8, 13, 8, 2)               # rig: a step
	_solid(room, ox, 15, 4, 15, 11, 2)              # a tower Joep can climb
	_solid(room, ox, 16, 4, 24, 4, 2)               # the rig top
	_solid(room, ox, 25, 8, 28, 8, 2)               # the way down for Geoff
	var drums := _node(room, "res://scripts/base/base_prop.gd", "DrumCase", Vector2(ox + 19 * T, 4 * T), Node2D)
	drums.set("kind", 2)
	var sleeper := _node(room, "res://scripts/venue/sleeping_member.gd", "Sleeper", Vector2(ox + 22 * T, 4 * T), Node2D)
	var exit := _node(room, "res://scripts/venue/finale_exit.gd", "Exit", Vector2(ox + 900, GY), Area2D)
	exit.set("sleeper", NodePath("../Sleeper"))
	exit.set("target_scene", "res://scenes/world/world_map.tscn")
	exit.set("target_spawn", &"VenueDoor")
	exit.set("set_flag", &"cafe_finished")


# --- helpers ------------------------------------------------------------------

## Solid tiles from (c0, r0) to (c1, r1) (room-relative columns) + how they look.
func _solid(room: Node2D, ox: int, c0: int, r0: int, c1: int, r1: int, style: int) -> void:
	var base := ox / T
	for c in range(c0, c1 + 1):
		for r in range(r0, r1 + 1):
			tm.set_cell(Vector2i(base + c, r), 0, Vector2i(12, 0))
	var b := Node2D.new()
	b.set_script(load("res://scripts/venue/venue_block.gd"))
	b.position = Vector2(ox + c0 * T, r0 * T)
	b.set("size", Vector2((c1 - c0 + 1) * T, (r1 - r0 + 1) * T))
	b.set("style", style)
	_add(room, b, "Block%d_%d" % [c0, r0])


func _node(parent: Node, script: String, name: String, pos: Vector2, type) -> Node:
	var n: Node = type.new()
	n.set_script(load(script))
	n.position = pos
	return _add(parent, n, name)


func _door(room: Node, name: String, pos: Vector2, target: String) -> Node:
	var d := _node(room, "res://scripts/levels/door.gd", name, pos, Area2D)
	d.set("target_door", NodePath(target))
	return d


func _sign(room: Node, x: float, y: float, title: String, hint: String) -> void:
	var s := _node(room, "res://scripts/venue/venue_sign.gd", "Sign", Vector2(x, y), Node2D)
	s.set("title", title)
	s.set("hint", hint)


func _paths(list: Array) -> Array[NodePath]:
	var out: Array[NodePath] = []
	for p in list:
		out.append(NodePath(p))
	return out


func _add(parent: Node, node: Node, name: String) -> Node:
	node.name = name
	parent.add_child(node, true)
	node.owner = root
	return node
