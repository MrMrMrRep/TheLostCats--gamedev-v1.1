@tool
extends RefCounted
## Builds scenes/world/world_map.tscn: sky, parallax scenery, canal houses with
## bridges, street, places, band, water, birds, HUD. Run in the editor:
##   load("res://tools/build_world_map.gd").new().build()
## Re-run after changing the layout numbers below.

const W := 3840
const GY := 288.0
const TOWN := Vector2(1000, 3700)
const STUDIO_X := 1892.0
const STUDIO_AREA := Vector2(1760, 2060)
const BRIDGES := [1560.0, 2440.0, 3060.0]
const BRIDGE_W := 96.0
const STATION := Vector2(3140, 3280)        # service station, no houses here
const VENUE_X := 3540.0

var root: Node2D


func build() -> int:
	root = Node2D.new()
	root.name = "WorldMap"
	root.set_script(load("res://scripts/world/world_map.gd"))
	root.set("map_width", W)
	root.set("town", TOWN)
	root.set("studio_area", STUDIO_AREA)

	var sky := CanvasLayer.new(); sky.set_script(load("res://scripts/world/sky.gd"))
	_add(root, sky, "Sky")
	var Sc = load("res://scripts/world/scenery.gd")
	var Px = load("res://scripts/world/parallax_layer.gd")
	for l in [["Skyline", 0.2, 0, 5], ["PolderFar", 0.3, 2, 9], ["BackStreet", 0.5, 1, 13], ["PolderNear", 0.75, 3, 17]]:
		var layer := Node2D.new(); layer.set_script(Px); layer.set("factor", l[1])
		_add(root, layer, l[0])
		var s := Node2D.new(); s.set_script(Sc)
		s.set("kind", l[2]); s.set("town", TOWN); s.set("map_width", float(W)); s.set("seed_value", l[3])
		_add(layer, s, "Scenery")

	# Bridges (behind the houses' layer so the gaps show their canal views).
	var bridges := _add(root, Node2D.new(), "Bridges")
	var Br = load("res://scripts/world/bridge.gd")
	for i in BRIDGES.size():
		var b := Node2D.new(); b.set_script(Br); b.position = Vector2(BRIDGES[i], GY)
		b.set("width", BRIDGE_W); b.set("seed_value", 3 + i)
		_add(bridges, b, "Bridge%d" % (i + 1))

	# Canal houses filling the town, leaving bridges, studio, station, venue.
	var city := _add(root, Node2D.new(), "City")
	var studio := _block(city, "Studio", 3, 7, "STUDIO", STUDIO_X)
	var venue := _block(city, "Venue", 3, 19, "CAFE DE KAT", VENUE_X)
	var keep_out := [Vector2(studio.position.x, studio.position.x + studio.width()),
		Vector2(venue.position.x, venue.position.x + venue.width()), STATION]
	for bx in BRIDGES:
		keep_out.append(Vector2(bx - BRIDGE_W / 2.0, bx + BRIDGE_W / 2.0))
	keep_out.sort_custom(func(a, b): return a.x < b.x)
	var cursor := TOWN.x + 10.0
	var seed := 40
	for zone in keep_out + [Vector2(TOWN.y - 10.0, TOWN.y)]:
		_fill(city, cursor, zone.x, seed)
		seed += 10
		cursor = zone.y
	var shop := AnimatedSprite2D.new()
	shop.sprite_frames = load("res://resources/sprites/shop_anim_frames.tres")
	shop.autoplay = "default"; shop.offset = Vector2(0, -64)
	shop.position = Vector2((STATION.x + STATION.y) / 2.0, GY)
	_add(city, shop, "ServiceStation")

	# Street: invisible collision + drawn street/quay/dike.
	var tm := TileMapLayer.new()
	tm.tile_set = load("res://resources/tiles/amwoods_tileset.tres")
	tm.visible = false
	_add(root, tm, "StreetCollision")
	for x in range(-2, W / 24 + 2):
		tm.set_cell(Vector2i(x, 12), 0, Vector2i(12, 0))
	var street := Node2D.new(); street.set_script(load("res://scripts/world/street.gd"))
	street.position = Vector2(0, GY); street.set("map_width", float(W)); street.set("town", TOWN)
	_add(root, street, "Street")

	var Bar = load("res://scripts/world/barrier.gd")
	for x in [40.0, W - 40.0]:
		var b := StaticBody2D.new(); b.set_script(Bar); b.position = Vector2(x, GY)
		_add(root, b, "RoadBlockWest" if x < 100 else "RoadBlockEast")

	# Places.
	var places := _add(root, Node2D.new(), "Places")
	var WD = load("res://scripts/world/world_door.gd")
	var studio_door := Area2D.new(); studio_door.set_script(WD); studio_door.position = Vector2(STUDIO_X, GY)
	studio_door.set("target_scene", "res://scenes/levels/abilities_test.tscn")
	studio_door.set("target_spawn", &"Start")
	_add(places, studio_door, "StudioDoor")
	var venue_door := Area2D.new(); venue_door.set_script(WD); venue_door.position = Vector2(VENUE_X, GY)
	venue_door.set("target_scene", "res://scenes/levels/level_test.tscn")
	venue_door.set("target_spawn", &"Start")
	_add(places, venue_door, "VenueDoor")
	var station_door := Area2D.new(); station_door.set_script(WD)
	station_door.position = Vector2((STATION.x + STATION.y) / 2.0 + 30.0, GY)
	station_door.set("closed_text", "Service station: coffee machine broken. Again.")
	_add(places, station_door, "StationDoor")
	var npc := Area2D.new(); npc.set_script(load("res://scripts/world/npc.gd")); npc.position = Vector2(STUDIO_X + 44, GY)
	_add(places, npc, "Geordie")
	var start := Marker2D.new(); start.position = Vector2(STUDIO_X + 150, GY)
	_add(places, start, "Start")
	var PS = load("res://scripts/world/parking_spot.gd")
	var V = load("res://scripts/world/vehicle.gd")
	var bikes := Area2D.new(); bikes.set_script(V); bikes.set("kind", 0); bikes.set("save_id", &"bikes_x")
	bikes.position = Vector2(STUDIO_X - 70, GY)
	_add(places, bikes, "Bikes")
	for p in [["ParkingStudio", 2290.0, 120.0], ["ParkingStation", 3330.0, 100.0], ["ParkingVenue", VENUE_X - 120.0, 100.0]]:
		var spot := Node2D.new(); spot.set_script(PS); spot.position = Vector2(p[1], GY); spot.set("width", p[2])
		_add(places, spot, p[0])
	var van := Area2D.new(); van.set_script(V); van.set("kind", 1); van.set("save_id", &"van_x")
	van.position = Vector2(2290, GY)
	_add(places, van, "Van")
	var Pk = load("res://scripts/world/package.gd")
	for p in [["PackageWest", 600.0], ["PackageEast", 2760.0]]:
		var pk := Area2D.new(); pk.set_script(Pk); pk.position = Vector2(p[1], GY)
		_add(places, pk, p[0])

	# Band, then the water (it reflects everything drawn before it), birds.
	_add(root, load("res://scenes/characters/band.tscn").instantiate())
	var water := _add(root, Node2D.new(), "Water")
	var Wt = load("res://scripts/world/water.gd")
	for w in [["DitchWest", -400.0, TOWN.x, true], ["Canal", TOWN.x, TOWN.y, false], ["DitchEast", TOWN.y, W + 400.0, true]]:
		var r := ColorRect.new(); r.set_script(Wt)
		r.position = Vector2(w[1], GY + 22.0); r.size = Vector2(w[2] - w[1], 520)
		if w[3]:
			r.set("water_color", WorldPalette.DITCH); r.set("deep_color", WorldPalette.DITCH.darkened(0.35))
		_add(water, r, w[0])
	var birds := Node2D.new(); birds.set_script(load("res://scripts/world/birds.gd"))
	_add(root, birds, "Birds")

	var hud := CanvasLayer.new(); hud.set_script(load("res://scripts/ui/map_hud.gd"))
	_add(root, hud, "MapHud")
	var dlg := CanvasLayer.new(); dlg.set_script(load("res://scripts/ui/dialogue_box.gd"))
	_add(root, dlg, "DialogueBox")
	_add(root, load("res://scenes/ui/debug_overlay.tscn").instantiate())
	var hint_layer := _add(root, CanvasLayer.new(), "DevHint")
	var hint := Label.new()
	hint.text = "Move: arrows/WASD   Jump: Space   E: talk / enter / ride the bikes / drive the van"
	hint.position = Vector2(8, 344)
	hint.add_theme_font_size_override("font_size", 8)
	hint.add_theme_color_override("font_color", Color(1, 1, 1, 0.75))
	hint.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	hint.add_theme_constant_override("outline_size", 3)
	_add(hint_layer, hint, "Hint")
	root.set("start_spawn", root.get_path_to(start))

	var ps := PackedScene.new()
	ps.pack(root)
	var err := ResourceSaver.save(ps, "res://scenes/world/world_map.tscn")
	root.free()
	return err


func _add(parent: Node, node: Node, name: String = "") -> Node:
	if name != "":
		node.name = name
	parent.add_child(node)
	node.owner = root
	return node


## A named block centred on `center_x`.
func _block(parent: Node, name: String, houses: int, seed: int, sign: String, center_x: float) -> Node2D:
	var cb := Node2D.new(); cb.set_script(load("res://scripts/world/city_block.gd"))
	cb.set("houses", houses); cb.set("seed_value", seed); cb.set("sign_text", sign)
	cb.position = Vector2(center_x - cb.width() / 2.0, GY)
	_add(parent, cb, name)
	return cb


## Fill [x0, x1] with as many houses as fit (in blocks).
func _fill(parent: Node, x0: float, x1: float, seed: int) -> void:
	var x := x0
	var n := 0
	while x1 - x > 40.0:
		var best: Node2D = null
		for houses in range(6, 0, -1):
			var cb := Node2D.new(); cb.set_script(load("res://scripts/world/city_block.gd"))
			cb.set("houses", houses); cb.set("seed_value", seed + n)
			if cb.width() <= x1 - x:
				best = cb
				break
			cb.free()
		if best == null:
			return
		best.position = Vector2(x, GY)
		_add(parent, best, "Block%d_%d" % [seed, n])
		x += best.width()
		n += 1
