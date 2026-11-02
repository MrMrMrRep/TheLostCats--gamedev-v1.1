extends SceneTree
## One-off (2026-11-02), kept for the record: builds the level
## scenes/levels/the_international.tscn, "The International": the band (all
## but Geoff) searches Hotel-Café International on the Warmoesstraat for him.
## Four rooms, each 24 tiles wide on a painting of the real bar and hotel
## (assets/sprites/levels/international/, tools/spritecook/international.py):
##   BAR       start at the bar. The spare key to the hotel stairs is on the
##             barrel shelf: Nikki jumps onto the counter and plays a ramp of
##             notes up to it. Door marked HOTEL (locked, the key).
##   STAIRS    up the steep stairs; the guests' luggage piles up on the landing
##             to the ceiling beam: The Germ's rage punch.
##   CORRIDOR  a camera watches the way to the lift: its alarm slams the fire
##             door, so Joep hacks it off through its wall plug by the door. The
##             old cage lift's gate shuts in 0.6 s: The Germ's Drumbeat Master.
##   ATTIC     Geoff, fast asleep on the bed (SleepingMember.from_start): Joep
##             or Nikki jump up, or Jay pushes the suitcase over as a step.
##             Awake, everybody out together (FinaleExit, flag geoff_found).
## Run: godot --headless --path . --script res://tools/scene_edits/2026_11_02_make_the_international.gd
## It overwrites the level: after that, edit it in the editor.

const PATH := "res://scenes/levels/the_international.tscn"
const ART := "res://assets/sprites/levels/international/"
const T := 24
const GY := 288.0
const COLS := 24
const STEP := 1200                          # room spacing (x)

enum S { CONCRETE, WOOD, STEEL, STAGE, HIDDEN, MAHOGANY, STAIR, MOSAIC, CARPET, BOARDS }

var scene: Node2D
var tm: TileMapLayer


func _initialize() -> void:
	scene = Node2D.new()
	scene.name = "TheInternational"
	scene.set_script(load("res://scripts/levels/level.gd"))
	var backs := _add(scene, Node2D.new(), "Backdrops")
	tm = TileMapLayer.new()
	tm.tile_set = load("res://resources/tiles/amwoods_tileset.tres")
	tm.visible = false
	_add(scene, tm, "Ground")
	var rooms := _add(scene, Node2D.new(), "Rooms")
	_bar(_room(rooms, backs, "Bar", 0, "bar", S.MOSAIC))
	_stairs(_room(rooms, backs, "Stairs", STEP, "stairs", S.BOARDS))
	_corridor(_room(rooms, backs, "Corridor", STEP * 2, "corridor", S.CARPET))
	_attic(_room(rooms, backs, "Attic", STEP * 3, "attic", S.BOARDS))
	scene.set("start_room", NodePath("Rooms/Bar"))
	scene.set("start_spawn", NodePath("Rooms/Bar/Start"))
	scene.set("party_only", false)          # the whole band searches (Geoff is up in the attic)
	scene.set("music", &"level_tense")
	_add(scene, load("res://scenes/characters/band.tscn").instantiate(), "Band")
	_add(scene, load("res://scenes/ui/hud.tscn").instantiate(), "HUD")
	_add(scene, load("res://scenes/ui/debug_overlay.tscn").instantiate(), "DebugOverlay")
	var ps := PackedScene.new()
	var err := ps.pack(scene)
	if err == OK:
		err = ResourceSaver.save(ps, PATH)
	print("saved %s: %s" % [PATH, error_string(err)])
	scene.free()
	quit(0 if err == OK else 1)


# --- rooms --------------------------------------------------------------------

func _bar(room: Node2D) -> void:
	var ox := 0
	_marker(room, "Start", Vector2(ox + 372, GY))
	_sign(room, ox + 226, 150, "CAFE INTERNATIONAL", "\"Geoff? Went up to the attic, mate.\"\nThe key's on the barrel shelf. Nikki:\nonto the bar, then notes up (up + L).")
	_solid(room, ox, 1, 9, 12, 11, S.HIDDEN)      # the bar counter (painted)
	_solid(room, ox, 13, 5, 17, 5, S.MAHOGANY)    # the barrel shelf
	var key := _node(room, "res://scripts/props/item_pickup.gd", "HotelKey", Vector2(ox + 15 * T + 12, 5 * T), Area2D)
	key.set("item", load("res://resources/items/hotel_key.tres"))
	_node(room, "res://scripts/props/item_pickup.gd", "Pint", Vector2(ox + 6 * T + 12, 9 * T), Area2D)
	_node(room, "res://scripts/enemies/rat.gd", "Rat", Vector2(ox + 19 * T, GY), CharacterBody2D)
	var door := _door(room, "ToStairs", Vector2(ox + 21 * T + 12, GY), "../../Stairs/FromBar")
	door.set("locked", true)
	door.set("key_id", &"hotel_key")


func _stairs(room: Node2D) -> void:
	var ox := STEP
	_door(room, "FromBar", Vector2(ox + 60, GY), "../../Bar/ToStairs")
	_sign(room, ox + 60, 150, "THE STAIRS", "Luggage piled up to the beam:\nThe Germ's rage punch (K).")
	_node(room, "res://scripts/enemies/rat.gd", "Rat", Vector2(ox + 5 * T, GY), CharacterBody2D)
	_ramp(room, "Stair", PackedVector2Array([Vector2(ox + 174, GY), Vector2(ox + 336, 8 * T), Vector2(ox + 336, GY)]))
	_solid(room, ox, 14, 8, 22, 11, S.HIDDEN)     # the landing (painted, dark under it)
	_solid(room, ox, 18, 0, 18, 3, S.MAHOGANY)    # the beam
	var luggage := _node(room, "res://scripts/props/breakable.gd", "Luggage", Vector2(ox + 18 * T + 12, 8 * T), StaticBody2D)
	luggage.set("substance", 2)
	luggage.set("size", Vector2(24, 96))
	_door(room, "ToCorridor", Vector2(ox + 21 * T + 12, 8 * T), "../../Corridor/FromStairs")


func _corridor(room: Node2D) -> void:
	var ox := STEP * 2
	_door(room, "FromStairs", Vector2(ox + 60, GY), "../../Stairs/ToCorridor")
	_sign(room, ox + 60, 150, "FIRST FLOOR", "Seen by the camera? The fire door\nslams. Joep: hack its wall plug (K).\nThe lift gate: The Germ's beat (L).")
	var cam := _node(room, "res://scripts/props/security_camera.gd", "Camera", Vector2(ox + 164, 38), Node2D)
	cam.set("view", Vector2(168, 260))
	cam.set("facing", 1.0)
	cam.set("targets", _paths(["../FireDoor"]))
	var plug := _node(room, "res://scripts/props/wall_plug.gd", "WallPlug", Vector2(ox + 100, GY - 12), Node2D)
	plug.set("target", NodePath("../Camera"))
	_solid(room, ox, 14, 0, 14, 6, S.MAHOGANY)    # the fire door's frame
	var fire := _node(room, "res://scripts/props/gate.gd", "FireDoor", Vector2(ox + 14 * T + 12, GY), StaticBody2D)
	fire.set("size", Vector2(24, 120))
	fire.set("solid", false)
	var rat := _node(room, "res://scripts/enemies/rat.gd", "Rat", Vector2(ox + 10 * T, GY), CharacterBody2D)
	rat.set("start_dir", -1.0)
	var lever := _node(room, "res://scripts/props/switch_panel.gd", "LiftButton", Vector2(ox + 17 * T + 12, GY), Area2D)
	lever.set("targets", _paths(["../LiftGate"]))
	_solid(room, ox, 20, 0, 20, 6, S.HIDDEN)      # the lift's frame (painted)
	var gate := _node(room, "res://scripts/props/timed_gate.gd", "LiftGate", Vector2(ox + 20 * T + 12, GY), StaticBody2D)
	gate.set("size", Vector2(24, 120))
	gate.set("open_time", 0.6)
	_door(room, "ToAttic", Vector2(ox + 22 * T, GY), "../../Attic/FromLift")


func _attic(room: Node2D) -> void:
	var ox := STEP * 3
	_door(room, "FromLift", Vector2(ox + 60, GY), "../../Corridor/ToAttic")
	_sign(room, ox + 110, 150, "TOP FLOOR", "Geoff! Get up on the bed to wake him\n(Jay: push the suitcase over as a step).\nThen all out together, Geoff too.")
	_solid(room, ox, 17, 9, 22, 11, S.HIDDEN)     # the bed (painted)
	var sleeper := _node(room, "res://scripts/venue/sleeping_member.gd", "Geoff", Vector2(ox + 20 * T, 9 * T), Node2D)
	sleeper.set("from_start", true)
	sleeper.set("wake_item", &"")
	sleeper.set("wake_line", "Closing time already? ...The van! Let's go.")
	_node(room, "res://scripts/props/flight_case.gd", "Suitcase", Vector2(ox + 9 * T, GY), CharacterBody2D)
	_node(room, "res://scripts/enemies/rat.gd", "Rat", Vector2(ox + 15 * T, GY), CharacterBody2D)
	_node(room, "res://scripts/props/item_pickup.gd", "Pint", Vector2(ox + 11 * T, GY), Area2D)
	var exit := _node(room, "res://scripts/venue/finale_exit.gd", "Exit", Vector2(ox + 13 * T + 12, GY), Area2D)
	exit.set("sleeper", NodePath("../Geoff"))
	exit.set("target_scene", "res://scenes/world/world_map.tscn")
	exit.set("target_spawn", &"InternationalDoor")
	exit.set("set_flag", &"geoff_found")


# --- helpers ------------------------------------------------------------------

## A room at x `ox`: floor, side walls (painted, so hidden), camera bounds and
## the painting behind it.
func _room(rooms: Node, backs: Node, room_name: String, ox: int, art: String, floor_style: int) -> Node2D:
	var a := Node2D.new()
	a.set_script(load("res://scripts/levels/painted_room_art.gd"))
	a.position = Vector2(ox, 0)
	a.set("texture", load(ART + art + ".png"))
	_add(backs, a, room_name + "Wall")
	var room := Node2D.new()
	room.set_script(load("res://scripts/levels/room.gd"))
	room.set("bounds", Rect2i(ox, 0, COLS * T, 312))
	_add(rooms, room, room_name)
	_solid(room, ox, 0, 12, COLS - 1, 14, floor_style)
	_solid(room, ox, 0, 0, 0, 11, S.HIDDEN)
	_solid(room, ox, COLS - 1, 0, COLS - 1, 11, S.HIDDEN)
	return room


## Solid tiles from (c0, r0) to (c1, r1) (room-relative columns) + how they look.
## A slope you walk up (the painted stairs' treads), solid like the tiles.
func _ramp(room: Node2D, node_name: String, points: PackedVector2Array) -> void:
	var body := StaticBody2D.new()
	_add(room, body, node_name)
	var shape := CollisionPolygon2D.new()
	shape.polygon = points
	_add(body, shape, "Shape")


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
	_add(room, b, "Block%d_%d" % [base + c0, r0])


func _node(parent: Node, script: String, node_name: String, pos: Vector2, type) -> Node:
	var n: Node = type.new()
	n.set_script(load(script))
	n.position = pos
	return _add(parent, n, node_name)


func _marker(parent: Node, node_name: String, pos: Vector2) -> void:
	var m := Marker2D.new()
	m.position = pos
	_add(parent, m, node_name)


func _door(room: Node, node_name: String, pos: Vector2, target: String) -> Node:
	var d := _node(room, "res://scripts/levels/door.gd", node_name, pos, Area2D)
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


func _add(parent: Node, node: Node, node_name: String) -> Node:
	node.name = node_name
	parent.add_child(node, true)
	node.owner = scene
	return node
