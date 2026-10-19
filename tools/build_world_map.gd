@tool
extends RefCounted
## Builds scenes/world/world_map.tscn: sky, parallax scenery, canal houses with
## bridges, street, places, band, water, birds, HUD. Run in the editor:
##   load("res://tools/build_world_map.gd").new().build()
## Re-run after changing the layout numbers below.

# West to east:
#   road block, a long country road (polder) with a farm where the van waits,
#   a highway sweeping in from the distance and joining the road,
#   town edge: hotels, a park and the theatre, then the old town (churches,
#   market square, bars and little shops), the canal centre with 6 bridges, the
#   studio and Café De Kat, new apartment blocks, the outskirts (service
#   station, shopping centre, car park, self storage) and all the way east the
#   band's storage with its gated car park.
const W := 18400
const GY := 288.0
const TOWN := Vector2(6400, 18240)          # canal + city
const HIGHWAY_MERGE := 5700.0               # the highway joins our road here
const FARM_P := 6100.0                      # the van, just out of town
const CENTRE := 9600.0                      # old town ends, canal centre begins
const OUTSKIRTS := 15400.0                  # canal centre ends: apartments, then industry
const STUDIO_X := 11800.0
const STUDIO_AREA := Vector2(11660, 11960)
const BRIDGES := [10200.0, 10900.0, 12500.0, 13200.0, 13900.0, 14900.0]
const BRIDGE_W := 96.0
const VENUE_X := 14400.0
const STATION := Vector2(16400, 16540)      # service station, no building here
const STORAGE_X := 17680.0                  # left end of the band's storage
const STORAGE_GATE_X := 17745.0             # gate in front of its car park
const BARS := ["BAR DE KROEG", "CAFE 'T HOEKJE", "KAAS", "BAKKER", "FIETSEN", "BLOEMEN", "PLATEN", "BAR TABAK", "CAFE CENTRAAL", "SNACKBAR"]
# Strips laid out from a start x, left to right. Entries:
#   [kind, seed, sign]          a WorldBuilding (kinds as in WorldBuilding.Kind)
#   ["houses", n, seed, shops]  a CityBlock of n canal houses (shops: shop share)
#   ["gap", px]
const WEST_STRIP := [
	[8, 1, "HOTEL AMSTEL"], ["houses", 2, 71, 0.2], [8, 2, "GRAND HOTEL"], ["gap", 24], [8, 3, "HOSTEL"],
	["gap", 20], [6, 4, "VONDELPARK"], [7, 5, ""], ["houses", 3, 73, 0.3],
	[4, 6, ""], ["houses", 4, 75, 0.8], [5, 7, "MARKT"], ["houses", 5, 77, 0.9], ["houses", 4, 79, 0.8],
	[4, 8, ""], ["houses", 3, 81, 0.6]]
const EAST_STRIP := [
	[9, 0, ""], ["gap", 34], [9, 1, ""], ["gap", 28], [9, 2, ""], ["gap", 40], [9, 3, ""]]
const OUTSKIRT_BUILDINGS := [[0, 16620.0, 3, "WINKELCENTRUM"], [1, 17020.0, 5, ""], [2, 17260.0, 7, "SELF STORAGE"]]

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
		s.set("kind", l[2]); s.set("town", TOWN); s.set("outskirts", OUTSKIRTS)
		s.set("centre", Vector2(TOWN.x, OUTSKIRTS))
		s.set("map_width", float(W)); s.set("seed_value", l[3])
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
		Vector2(venue.position.x, venue.position.x + venue.width())]
	for bx in BRIDGES:
		keep_out.append(Vector2(bx - BRIDGE_W / 2.0, bx + BRIDGE_W / 2.0))
	keep_out.sort_custom(func(a, b): return a.x < b.x)
	var old_town_end := _strip(city, TOWN.x + 10.0, WEST_STRIP, "West")
	assert(old_town_end <= CENTRE, "west strip runs into the centre (%d)" % old_town_end)
	_strip(city, OUTSKIRTS, EAST_STRIP, "Flats")
	var cursor := old_town_end
	var seed := 40
	for zone in keep_out + [Vector2(OUTSKIRTS, OUTSKIRTS)]:
		_fill(city, cursor, zone.x, seed)
		seed += 10
		cursor = zone.y
	var shop := AnimatedSprite2D.new()
	shop.sprite_frames = load("res://resources/sprites/shop_anim_frames.tres")
	shop.autoplay = "default"; shop.offset = Vector2(0, -64)
	shop.position = Vector2((STATION.x + STATION.y) / 2.0, GY)
	_add(city, shop, "ServiceStation")
	var Bd = load("res://scripts/world/outskirts.gd")
	for b in OUTSKIRT_BUILDINGS:
		var ob := Node2D.new(); ob.set_script(Bd); ob.position = Vector2(b[1], GY)
		ob.set("kind", b[0]); ob.set("seed_value", b[2]); ob.set("sign_text", b[3])
		_add(city, ob, ["Mall", "CarPark", "SelfStorage"][b[0]])
	var hw := Node2D.new(); hw.set_script(load("res://scripts/world/highway.gd"))
	hw.position = Vector2(HIGHWAY_MERGE, GY)
	_add(root, hw, "Highway")
	var storage := Node2D.new(); storage.set_script(Bd); storage.position = Vector2(STORAGE_X, GY)
	storage.set("kind", 3); storage.set("sign_text", "THE LOST CATS - STORAGE")
	_add(city, storage, "Storage")

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
	var Tr = load("res://scripts/world/traffic.gd")
	var traffic_back := Node2D.new(); traffic_back.set_script(Tr); traffic_back.position = Vector2(0, GY)
	traffic_back.set("lane", 0); traffic_back.set("town", TOWN); traffic_back.set("map_width", float(W))
	_add(root, traffic_back, "TrafficBack")

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
	var gate := Area2D.new(); gate.set_script(load("res://scripts/world/storage_gate.gd"))
	gate.position = Vector2(STORAGE_GATE_X, GY)
	gate.set("target_scene", "res://scenes/levels/abilities_test.tscn")
	gate.set("target_spawn", &"Start")
	_add(places, gate, "StorageGate")
	var station_door := Area2D.new(); station_door.set_script(WD)
	station_door.position = Vector2((STATION.x + STATION.y) / 2.0 + 30.0, GY)
	station_door.set("closed_text", "Service station: coffee machine broken. Again.")
	_add(places, station_door, "StationDoor")
	var npc := Area2D.new(); npc.set_script(load("res://scripts/world/npc.gd")); npc.position = Vector2(STORAGE_X - 50, GY)
	_add(places, npc, "Geordie")
	var start := Marker2D.new(); start.position = Vector2(STUDIO_X + 150, GY)
	_add(places, start, "Start")
	var PS = load("res://scripts/world/parking_spot.gd")
	var V = load("res://scripts/world/vehicle.gd")
	var bikes := Area2D.new(); bikes.set_script(V); bikes.set("kind", 0); bikes.set("save_id", &"bikes_x")
	bikes.position = Vector2(STUDIO_X - 70, GY)
	_add(places, bikes, "Bikes")
	for p in [["ParkingFarm", FARM_P, 120.0], ["ParkingStudio", STUDIO_X + 400.0, 120.0], ["ParkingVenue", VENUE_X - 160.0, 100.0],
			["ParkingMall", 16790.0, 120.0], ["ParkingStorage", STORAGE_X - 130.0, 110.0]]:
		var spot := Node2D.new(); spot.set_script(PS); spot.position = Vector2(p[1], GY); spot.set("width", p[2])
		_add(places, spot, p[0])
	var van := Area2D.new(); van.set_script(V); van.set("kind", 1); van.set("save_id", &"van_x")
	van.position = Vector2(FARM_P, GY)
	_add(places, van, "Van")
	var Pk = load("res://scripts/world/package.gd")
	for p in [["PackageWest", 10650.0], ["PackageEast", 13550.0]]:
		var pk := Area2D.new(); pk.set_script(Pk); pk.position = Vector2(p[1], GY)
		_add(places, pk, p[0])

	# Band, then the water (it reflects everything drawn before it), birds.
	_add(root, load("res://scenes/characters/band.tscn").instantiate())
	var traffic_front := Node2D.new(); traffic_front.set_script(Tr); traffic_front.position = Vector2(0, GY)
	traffic_front.set("lane", 1); traffic_front.set("town", TOWN); traffic_front.set("map_width", float(W))
	_add(root, traffic_front, "TrafficFront")
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


## Lay out `items` (see WEST_STRIP) from x0; returns the x where they end.
func _strip(parent: Node, x0: float, items: Array, prefix: String) -> float:
	var x := x0
	var Bd = load("res://scripts/world/outskirts.gd")
	var Cb = load("res://scripts/world/city_block.gd")
	for i in items.size():
		var it: Array = items[i]
		if it[0] is String and it[0] == "gap":
			x += it[1]
		elif it[0] is String and it[0] == "houses":
			var cb := Node2D.new(); cb.set_script(Cb)
			cb.set("houses", it[1]); cb.set("seed_value", it[2]); cb.set("shop_rate", it[3])
			cb.set("shop_signs", PackedStringArray(BARS))
			cb.position = Vector2(x, GY)
			_add(parent, cb, "%s%d_Houses" % [prefix, i])
			x += cb.width()
		else:
			var b := Node2D.new(); b.set_script(Bd)
			b.set("kind", it[0]); b.set("seed_value", it[1]); b.set("sign_text", it[2])
			b.position = Vector2(x, GY)
			_add(parent, b, "%s%d_%s" % [prefix, i, ["Mall", "CarPark", "SelfStorage", "Storage", "Church", "Market", "Park", "Theater", "Hotel", "Flats"][it[0]]])
			x += b.width()
	return x
