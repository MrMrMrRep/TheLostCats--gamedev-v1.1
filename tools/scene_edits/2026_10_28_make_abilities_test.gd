extends SceneTree
## One-off (2026-10-28), kept for the record: rebuilds the abilities test level
## scenes/levels/abilities_test.tscn for the new skill set (behind the studio
## door and the storage gate). One long hall, a station per member, plus a
## staff-only green room:
##   BASICS  crouch under the beam, mic stand + rat pen (punch), wall slide
##   JOEP    wall plug -> hack panel up high (electric floor off); a security
##           camera only his shockwave reaches (or the gate shuts)
##   JAY     glass wall (slap bass), flight case to lift/throw onto the 2-tile
##           ledge, spikes (the bass bubble), a 4-tile shelf (throw a member)
##   GERM    wooden crates (rage punch), cracked slab (slam), a timed gate too
##           quick for anyone (Drumbeat Master), a moving platform over a pit
##   NIKKI   8-tile pit with a grapple hook, a 5-tile wall (solo staircase)
##   GEOFF   bouncer, distractible security, sound guy (charm), tip jar + bar
##           (Geoff pays less), staff-only door to the green room
## Run: godot --headless --path . --script res://tools/scene_edits/2026_10_28_make_abilities_test.gd
## It overwrites the level: after that, edit it in the editor.

const PATH := "res://scenes/levels/abilities_test.tscn"
const T := 24
const GY := 288.0
const HALL_COLS := 200
const GREEN_X := 5040
const GREEN_COLS := 20

var scene: Node2D
var tm: TileMapLayer


func _initialize() -> void:
	scene = Node2D.new()
	scene.name = "AbilitiesTest"
	scene.set_script(load("res://scripts/levels/level.gd"))
	var backs := _add(scene, Node2D.new(), "Backdrops")
	tm = TileMapLayer.new()
	tm.tile_set = load("res://resources/tiles/amwoods_tileset.tres")
	tm.visible = false
	_add(scene, tm, "Ground")
	var rooms := _add(scene, Node2D.new(), "Rooms")

	var hall := _room(rooms, backs, "Hall", 0, HALL_COLS, [[120, 125], [134, 141]])
	_basics(hall)
	_joep(hall)
	_jay(hall)
	_germ(hall)
	_nikki(hall)
	_geoff(hall)
	var green := _room(rooms, backs, "GreenRoom", GREEN_X, GREEN_COLS, [])
	_green_room(green)

	scene.set("start_room", NodePath("Rooms/Hall"))
	scene.set("start_spawn", NodePath("Rooms/Hall/Start"))
	_add(scene, load("res://scenes/characters/band.tscn").instantiate(), "Band")
	_add(scene, load("res://scenes/ui/hud.tscn").instantiate(), "HUD")
	_add(scene, load("res://scenes/ui/debug_overlay.tscn").instantiate(), "DebugOverlay")
	_dev_hint()
	var ps := PackedScene.new()
	var err := ps.pack(scene)
	if err == OK:
		err = ResourceSaver.save(ps, PATH)
	print("saved %s: %s" % [PATH, error_string(err)])
	scene.free()
	quit(0 if err == OK else 1)


# --- stations -----------------------------------------------------------------

func _basics(room: Node2D) -> void:
	_marker(room, "Start", Vector2(72, GY))
	_sign(room, 40, 150, "BASICS", "Walk: arrows. Run: hold Shift. Jump: Space.\nCrouch (hold down) to get under the beam.\nFall against a wall to slide down it.\nPunch: J. Pick up the mic stand: punch swings it.")
	_solid(room, 0, 8, 0, 11, 10, 0)             # the low beam: crouch under it
	var mic := _node(room, "res://scripts/props/item_pickup.gd", "MicStand", Vector2(14 * T + 12, GY), Area2D)
	mic.set("item", load("res://resources/items/mic_stand.tres"))
	_solid(room, 0, 16, 11, 16, 11, 1)           # rat pen walls (1 tile: everyone hops them)
	_solid(room, 0, 25, 11, 25, 11, 1)
	_node(room, "res://scripts/enemies/rat.gd", "PenRat", Vector2(20 * T, GY), CharacterBody2D)


func _joep(room: Node2D) -> void:
	_sign(room, 30 * T, 150, "JOEP", "Special (K): hack what's in reach, even\nthrough a wall plug. Instrument (L): a\nshockwave that knocks out rats and hacks\nevery device around (the camera!).")
	var elec := _node(room, "res://scripts/props/hazard.gd", "ElectricFloor", Vector2(43.5 * T, GY), Area2D)
	elec.set("kind", 1)
	elec.set("width", 9.0 * T)
	_solid(room, 0, 35, 5, 37, 5, 2)            # shelf way up: the panel nobody reaches
	var panel := _node(room, "res://scripts/props/switch_panel.gd", "HackPanel", Vector2(36 * T + 12, 5 * T), Area2D)
	panel.set("kind", 1)
	panel.set("targets", _paths(["../ElectricFloor"]))
	var plug := _node(room, "res://scripts/props/wall_plug.gd", "WallPlug", Vector2(33 * T + 12, GY - 12), Node2D)
	plug.set("target", NodePath("../HackPanel"))
	var cam := _node(room, "res://scripts/props/security_camera.gd", "Camera", Vector2(54 * T, 8 * T), Node2D)
	cam.set("view", Vector2(120, 96))
	cam.set("facing", -1.0)
	cam.set("targets", _paths(["../CameraGate"]))
	_solid(room, 0, 56, 0, 56, 6, 0)            # the gate's frame: no way over
	var gate := _node(room, "res://scripts/props/gate.gd", "CameraGate", Vector2(56 * T + 12, GY), StaticBody2D)
	gate.set("size", Vector2(24, 120))
	gate.set("solid", false)
	_node(room, "res://scripts/props/amp.gd", "Amp", Vector2(58 * T + 12, GY), Node2D)


func _jay(room: Node2D) -> void:
	_sign(room, 60 * T, 150, "JAY", "Special (K): lift the flight case and\nthrow it (K again), or throw a mate up.\nInstrument (L): slap bass: glass breaks,\ncases fly, everyone near gets a bubble.")
	var glass := _node(room, "res://scripts/props/breakable.gd", "GlassWall", Vector2(64 * T + 12, GY), StaticBody2D)
	glass.set("substance", 0)
	glass.set("size", Vector2(24, 72))
	_solid(room, 0, 64, 0, 64, 8, 0)            # glass in a frame: no way over
	_node(room, "res://scripts/props/flight_case.gd", "FlightCase", Vector2(69 * T, GY), CharacterBody2D)
	_solid(room, 0, 72, 8, 74, 8, 1)            # 4-tile shelf: a throw gets you up
	_node(room, "res://scripts/props/item_pickup.gd", "ShelfBeer", Vector2(73 * T + 12, 8 * T), Area2D)
	_solid(room, 0, 77, 10, 88, 11, 1)          # the 2-tile ledge (case as a step)
	var spikes := _node(room, "res://scripts/props/hazard.gd", "Spikes", Vector2(82 * T, 10 * T), Area2D)
	spikes.set("width", 2.0 * T)


func _germ(room: Node2D) -> void:
	_sign(room, 90 * T, 150, "THE GERM", "Special (K): rage punch, through rats and\ncrates (in the air: a slam). Instrument (L):\nDrumbeat Master. L stops time, L again\nrewinds, L once more plays. Beat the gate!")
	var crates := _node(room, "res://scripts/props/breakable.gd", "Crates", Vector2(94 * T + 12, GY), StaticBody2D)
	crates.set("size", Vector2(24, 72))
	_solid(room, 0, 94, 0, 94, 8, 0)
	_node(room, "res://scripts/enemies/rat.gd", "Rat1", Vector2(98 * T, GY), CharacterBody2D)
	var r2 := _node(room, "res://scripts/enemies/rat.gd", "Rat2", Vector2(102 * T, GY), CharacterBody2D)
	r2.set("start_dir", -1.0)
	var slab := _node(room, "res://scripts/props/breakable.gd", "CrackedSlab", Vector2(105 * T, GY), StaticBody2D)
	slab.set("substance", 3)
	slab.set("size", Vector2(48, 12))
	var lever := _node(room, "res://scripts/props/switch_panel.gd", "GateLever", Vector2(108 * T + 12, GY), Area2D)
	lever.set("targets", _paths(["../TimedGate"]))
	_solid(room, 0, 117, 0, 117, 6, 0)
	var tg := _node(room, "res://scripts/props/timed_gate.gd", "TimedGate", Vector2(117 * T + 12, GY), StaticBody2D)
	tg.set("size", Vector2(24, 120))
	tg.set("open_time", 0.6)
	var plat := _node(room, "res://scripts/props/moving_platform.gd", "MovingPlatform", Vector2(120 * T, GY - T), AnimatableBody2D)
	plat.set("size", Vector2(48, 8))
	plat.set("travel", Vector2(96, 0))
	plat.set("period", 4.0)


func _nikki(room: Node2D) -> void:
	_sign(room, 128 * T, 150, "NIKKI", "Special (K): grapple the hook and swing\n(jump lets go). Instrument (L): a guitar\nsolo bridge for everyone; hold up for\nstairs over the wall.")
	_node(room, "res://scripts/props/grapple_hook.gd", "PitHook", Vector2(137 * T, 5 * T), Node2D)
	_solid(room, 0, 150, 7, 151, 11, 0)          # 5-tile wall: solo stairs, or swing over
	_node(room, "res://scripts/props/grapple_hook.gd", "WallHook", Vector2(149 * T, 2 * T), Node2D)


func _geoff(room: Node2D) -> void:
	_sign(room, 156 * T, 150, "GEOFF", "Special (K): bubbles. Security can't look\naway. Instrument (L): the voice and the\ncharm: bouncers, sound guys, staff doors.\nNot rats. And Geoff buys cheaper.")
	_node(room, "res://scripts/enemies/rat.gd", "Rat", Vector2(160 * T, GY), CharacterBody2D)
	_human(room, "Bouncer", 168, "Bouncer", "Members only, mate.", "Alright Geoff... go on.", false)
	_human(room, "Security", 174, "Security", "Move along.", "...fine. Quick, though.", true)
	_human(room, "SoundGuy", 179, "Sound guy", "Don't touch my desk!", "Geoff! Love your work. Go on.", false)
	var jar := _node(room, "res://scripts/props/coin_pickup.gd", "TipJar", Vector2(182 * T, GY), Area2D)
	jar.set("coins", 20)
	_node(room, "res://scripts/props/vendor.gd", "Bar", Vector2(186 * T, GY), Area2D)
	var staff := _door(room, "StaffDoor", Vector2(190 * T, GY), "../../GreenRoom/FromHall")
	staff.set("locked", true)
	staff.set("charm_lock", true)
	var exit := _node(room, "res://scripts/levels/door.gd", "Exit", Vector2(197 * T, GY), Area2D)
	exit.set("target_scene", "res://scenes/world/world_map.tscn")
	exit.set("target_spawn", &"StudioDoor")


func _green_room(room: Node2D) -> void:
	var ox := GREEN_X
	_sign(room, ox + 100, 150, "GREEN ROOM", "Staff only. Free beer for the charming.")
	_door(room, "FromHall", Vector2(ox + 60, GY), "../../Hall/StaffDoor")
	_node(room, "res://scripts/props/item_pickup.gd", "Beer1", Vector2(ox + 260, GY), Area2D)
	_node(room, "res://scripts/props/item_pickup.gd", "Beer2", Vector2(ox + 300, GY), Area2D)
	_human(room, "Manager", (ox + 400) / T, "Manager", "Who let you in here?", "Geoff, darling! Help yourself.", false)


# --- helpers ------------------------------------------------------------------

## A room `cols` tiles wide at x `ox`: floor (minus the `pits` column ranges),
## side walls, camera bounds and the back wall art.
func _room(rooms: Node, backs: Node, room_name: String, ox: int, cols: int, pits: Array) -> Node2D:
	var art := Node2D.new()
	art.set_script(load("res://scripts/base/base_room_art.gd"))
	art.position = Vector2(ox, 0)
	art.set("size", Vector2(cols * T, 360))
	_add(backs, art, room_name + "Wall")
	var room := Node2D.new()
	room.set_script(load("res://scripts/levels/room.gd"))
	room.set("bounds", Rect2i(ox, 0, cols * T, 312))
	_add(rooms, room, room_name)
	var c := 0
	while c < cols:                             # floor runs between the pits
		var c1 := c
		while c1 + 1 < cols and not _in_pit(c1 + 1, pits):
			c1 += 1
		if not _in_pit(c, pits):
			_solid(room, ox, c, 12, c1, 14, 0)
		c = c1 + 1
		while c < cols and _in_pit(c, pits):
			c += 1
	_solid(room, ox, 0, 0, 0, 11, 0)
	_solid(room, ox, cols - 1, 0, cols - 1, 11, 0)
	return room


func _in_pit(c: int, pits: Array) -> bool:
	for p in pits:
		if c >= p[0] and c <= p[1]:
			return true
	return false


func _human(room: Node, node_name: String, col: int, role: String, refusal: String, agreement: String, distractible: bool) -> void:
	var h := _node(room, "res://scripts/enemies/bouncer.gd", node_name, Vector2(col * T, GY), Area2D)
	h.set("role", role)
	h.set("refusal", refusal)
	h.set("agreement", agreement)
	h.set("distractible", distractible)
	if distractible:
		h.set("tint", Color(0.28, 0.32, 0.42))


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
	var s := _node(room, "res://scripts/venue/venue_sign.gd", "Sign" + title.replace(" ", ""), Vector2(x, y), Node2D)
	s.set("title", title)
	s.set("hint", hint)


func _dev_hint() -> void:
	var layer := CanvasLayer.new()
	_add(scene, layer, "DevHint")
	var l := Label.new()
	l.position = Vector2(8, 344)
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 3)
	l.text = "Move: arrows/WASD  Shift: run  Down: crouch  Space: jump  J: punch  K: special  L: instrument  E: door/talk  R/T/F/V: item  1-5/Tab: switch  G: gather  Esc: pause"
	_add(layer, l, "Hint")


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
