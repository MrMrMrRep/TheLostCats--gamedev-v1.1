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
const W := 21600
const GY := 288.0
const TOWN := Vector2(6400, 18240)          # canal + city
const HIGHWAY_MERGE := 5700.0               # the highway joins our road here
const FARM_P := 5300.0                      # the van, at a farm just out of town
const MAP_MIN := -4000.0                    # west end: open meadow with cows only (x < 0)
const PARK_END := 7083.0                    # hotels | park: the canal starts here (behind trees)
const CANAL_FROM := PARK_END
const VIADUCT := Vector2(5650, 7083)        # west of the park the road runs over a viaduct
const GRASS_BANK := Vector2(4700, 5650)     # then a grass bank in front, then the polder ditch
const CANOPIES := [7083.0, 5650.0, 18240.0] # dense trees in front hide each change
const OVERPASS_X := 6330.0                  # the ring road crosses over; the city limit starts here
const CONSTRUCTION := Vector2(5790, 6200)   # building site behind the road
const ROUND_HOTEL_X := 5120.0               # the round glass hotel, in front of the road
const GANTRIES := [[2300.0, "Utrecht|A2", "Schiphol|A4"], [200.0, "Haarlem|A9", "Amsterdam|A10"],
	[-1800.0, "Den Haag|A4", "Leiden|A44"], [20550.0, "Schiphol|A4", "Amsterdam|A10"]]
const CENTRE := 9600.0                      # old town ends, canal centre begins
const OUTSKIRTS := 15400.0                  # canal centre ends: apartments, then industry
const STUDIO_X := 11800.0
const BRIDGES := [10200.0, 10900.0, 12500.0, 13200.0, 13900.0, 14900.0]
const BRIDGE_W := 150.0
const LANDMARK_BRIDGE := 12500.0            # its canal view ends at the Pontsteiger
const SIDE_STREETS := [11250.0, 13550.0]    # gaps with a view down a side street
const SIDE_STREET_W := 110.0
const VENUE_X := 14400.0
const STATION := Vector2(16400, 16540)      # service station, no building here
const STORAGE_X := 17680.0                  # left end of the band's storage
const STORAGE_GATE_X := 17745.0             # gate in front of its car park
const CENTRE_SHOPS := ["KOFFIE", "BOEKEN", "ANTIEK", "KAAS", "GALERIE", "CAFE DE GRACHT", "BLOEMEN", "VINTAGE", "BAR 'T SLUISJE", "FIETSEN"]
const BARS := ["BAR DE KROEG", "CAFE 'T HOEKJE", "KAAS", "BAKKER", "FIETSEN", "BLOEMEN", "PLATEN", "BAR TABAK", "CAFE CENTRAAL", "SNACKBAR"]
# Strips laid out from a start x, left to right. Entries:
#   [kind, seed, sign]          a WorldBuilding (kinds as in WorldBuilding.Kind)
#   ["houses", n, seed, shops, style]  a CityBlock of n houses (shops: shop share;
#                                      style: 0 canal, 1 old town, 2 ring)
#   ["gap", px]
const WEST_STRIP := [
	[8, 1, "HOTEL AMSTEL"], ["houses", 2, 71, 0.2, 2], [8, 2, "GRAND HOTEL"], ["gap", 24], [8, 3, "HOSTEL"],
	["gap", 20], [6, 4, "VONDELPARK"], [7, 5, ""], ["houses", 3, 73, 0.3, 2],
	[4, 6, ""], ["houses", 4, 75, 0.8, 1], [5, 7, "MARKT"], ["houses", 5, 77, 0.9, 1], ["houses", 4, 79, 0.8, 1],
	[4, 8, ""], ["houses", 2, 81, 0.6, 1]]
const EAST_STRIP := [
	[9, 0, ""], ["gap", 34], [9, 1, ""], ["gap", 28], [9, 2, ""], ["gap", 40], [9, 3, ""]]
const OUTSKIRT_BUILDINGS := [[0, 16620.0, 3, "WINKELCENTRUM"], [1, 17020.0, 5, ""], [2, 17260.0, 7, "SELF STORAGE"]]
# Past the storage, out of town by the motorway: airport hotels, the terminal,
# the control tower and the airfield.
const AIRPORT_BUILDINGS := [[8, 18700.0, 4, "AIRPORT HOTEL"], [8, 18900.0, 5, "SKY INN"], [10, 19200.0, 0, "AIRPORT"], [11, 19820.0, 0, ""]]
const AIRFIELD := Vector2(19950, 21400)
# Districts for street furniture, traffic and pedestrians (world x ranges).
const OLD_TOWN := Vector2(7800, 9600)
const DISTRICTS := [[6400.0, 7800.0, 2], [7800.0, 9600.0, 1], [9600.0, 15400.0, 0], [15400.0, 16400.0, 2],
	[16400.0, 18240.0, 3], [18600.0, 19900.0, 4]]   # kinds as in WorldStreetLife.Kind
const PEOPLE := [Vector3(6400, 7800, 3), Vector3(7800, 9600, 6), Vector3(9600, 15400, 4), Vector3(15400, 16400, 2),
	Vector3(16400, 18240, 1), Vector3(18600, 19900, 3)]
const HOUSEBOATS := [9900.0, 10560.0, 11320.0, 12120.0, 12860.0, 13560.0, 14260.0, 15080.0]

var root: Node2D


func build() -> int:
	root = Node2D.new()
	root.name = "WorldMap"
	root.set_script(load("res://scripts/world/world_map.gd"))
	root.set("map_width", W)
	root.set("town", TOWN)
	root.set("map_min", MAP_MIN)
	root.set("city_limit", Vector2(OVERPASS_X, TOWN.y))

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
		s.set("map_min", MAP_MIN); s.set("cows_until", 0.0)
		_add(layer, s, "Scenery")

	# Bridges (behind the houses' layer so the gaps show their canal views).
	var bridges := _add(root, Node2D.new(), "Bridges")
	var Br = load("res://scripts/world/bridge.gd")
	for i in BRIDGES.size():
		var b := Node2D.new(); b.set_script(Br); b.position = Vector2(BRIDGES[i], GY)
		b.set("width", BRIDGE_W); b.set("seed_value", 3 + i); b.set("landmark", BRIDGES[i] == LANDMARK_BRIDGE)
		_add(bridges, b, "Bridge%d" % (i + 1))
	for i in SIDE_STREETS.size():
		var st := Node2D.new(); st.set_script(Br); st.position = Vector2(SIDE_STREETS[i], GY)
		st.set("width", SIDE_STREET_W); st.set("kind", 1); st.set("seed_value", 20 + i)
		_add(bridges, st, "SideStreet%d" % (i + 1))

	# Canal houses filling the town, leaving bridges, studio, station, venue.
	var city := _add(root, Node2D.new(), "City")
	var studio := _block(city, "Studio", 3, 7, "STUDIO", STUDIO_X)
	var venue := _block(city, "Venue", 3, 19, "CAFE DE KAT", VENUE_X)
	var keep_out := [Vector2(studio.position.x, studio.position.x + studio.width()),
		Vector2(venue.position.x, venue.position.x + venue.width())]
	for bx in BRIDGES:
		keep_out.append(Vector2(bx - BRIDGE_W / 2.0, bx + BRIDGE_W / 2.0))
	for sx in SIDE_STREETS:
		keep_out.append(Vector2(sx - SIDE_STREET_W / 2.0, sx + SIDE_STREET_W / 2.0))
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
	var station := Node2D.new(); station.set_script(load("res://scripts/world/outskirts.gd"))
	station.position = Vector2(STATION.x, GY); station.set("kind", 13)
	_add(city, station, "ServiceStation")
	var Bd = load("res://scripts/world/outskirts.gd")
	for b in OUTSKIRT_BUILDINGS:
		var ob := Node2D.new(); ob.set_script(Bd); ob.position = Vector2(b[1], GY)
		ob.set("kind", b[0]); ob.set("seed_value", b[2]); ob.set("sign_text", b[3])
		_add(city, ob, ["Mall", "CarPark", "SelfStorage"][b[0]])
	var hw := Node2D.new(); hw.set_script(load("res://scripts/world/highway.gd"))
	hw.position = Vector2(HIGHWAY_MERGE, GY)
	_add(root, hw, "Highway")
	var site := Node2D.new(); site.set_script(load("res://scripts/world/construction.gd"))
	site.position = Vector2(CONSTRUCTION.x, GY); site.set("length", CONSTRUCTION.y - CONSTRUCTION.x)
	_add(city, site, "Construction")
	var storage := Node2D.new(); storage.set_script(Bd); storage.position = Vector2(STORAGE_X, GY)
	storage.set("kind", 3); storage.set("sign_text", "THE LOST CATS - STORAGE")
	_add(city, storage, "Storage")
	for b in AIRPORT_BUILDINGS:
		var ab := Node2D.new(); ab.set_script(Bd); ab.position = Vector2(b[1], GY)
		ab.set("kind", b[0]); ab.set("seed_value", b[2]); ab.set("sign_text", b[3])
		_add(city, ab, ["", "", "", "", "", "", "", "", "AirportHotel", "", "Terminal", "Tower"][b[0]] + str(b[2]))
	var field := Node2D.new(); field.set_script(load("res://scripts/world/airport.gd"))
	field.position = Vector2(AIRFIELD.x, GY); field.set("length", AIRFIELD.y - AIRFIELD.x)
	_add(city, field, "Airfield")

	# Street: invisible collision + drawn street/quay/dike.
	var tm := TileMapLayer.new()
	tm.tile_set = load("res://resources/tiles/amwoods_tileset.tres")
	tm.visible = false
	_add(root, tm, "StreetCollision")
	for x in range(int(MAP_MIN) / 24 - 2, W / 24 + 2):
		tm.set_cell(Vector2i(x, 12), 0, Vector2i(12, 0))
	var street := Node2D.new(); street.set_script(load("res://scripts/world/street.gd"))
	street.position = Vector2(0, GY); street.set("map_width", float(W)); street.set("town", TOWN)
	street.set("map_min", MAP_MIN)
	_add(root, street, "Street")
	var Tr = load("res://scripts/world/traffic.gd")
	var traffic_back := Node2D.new(); traffic_back.set_script(Tr); traffic_back.position = Vector2(0, GY)
	traffic_back.set("lane", 0); traffic_back.set("town", TOWN); traffic_back.set("map_width", float(W))
	traffic_back.set("map_min", MAP_MIN)
	traffic_back.set("car_free", _ranges([Vector2(OLD_TOWN.x, OUTSKIRTS)]))
	traffic_back.set("parked", _ranges([Vector2(TOWN.x, OLD_TOWN.x), Vector2(OUTSKIRTS, TOWN.y), Vector2(18600, 19900)]))
	var ped_back := Node2D.new(); ped_back.set_script(load("res://scripts/world/pedestrians.gd")); ped_back.position = Vector2(0, GY)
	ped_back.set("side", 0); ped_back.set("busy", _people())
	_add(root, ped_back, "PeopleBack")
	_add(root, traffic_back, "TrafficBack")
	# Things we drive under: their far halves here, the rest after the band.
	var Ov = load("res://scripts/world/overpass.gd")
	var Gt = load("res://scripts/world/gantry.gd")
	var ov_back := Node2D.new(); ov_back.set_script(Ov); ov_back.position = Vector2(OVERPASS_X, GY)
	ov_back.set("part", 0); ov_back.set("structure", false)
	_add(root, ov_back, "OverpassBack")
	for i in GANTRIES.size():
		var g := Node2D.new(); g.set_script(Gt); g.position = Vector2(GANTRIES[i][0], GY); g.set("part", 0)
		g.set("signs", PackedStringArray([GANTRIES[i][1], GANTRIES[i][2]]))
		_add(root, g, "Gantry%d" % i)

	var Bar = load("res://scripts/world/barrier.gd")
	for x in [MAP_MIN + 40.0, W - 40.0]:
		var b := StaticBody2D.new(); b.set_script(Bar); b.position = Vector2(x, GY)
		_add(root, b, "RoadBlockWest" if x < W / 2.0 else "RoadBlockEast")

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

	# Street furniture per district, in stretches Godot can cull; doors stay clear.
	var clear := []
	for n in places.get_children():
		if n is Area2D or n.has_method("has_x"):
			clear.append(n.position.x)
	var life := _add(root, Node2D.new(), "StreetLife")
	var SL = load("res://scripts/world/street_life.gd")
	var chunk := 0
	for d in DISTRICTS:
		var x: float = d[0]
		while x < d[1]:
			var len := minf(1200.0, d[1] - x)
			var sl := Node2D.new(); sl.set_script(SL); sl.position = Vector2(x, GY)
			sl.set("kind", d[2]); sl.set("length", len); sl.set("seed_value", 100 + chunk)
			var keep: Array[Vector2] = []
			for cx in clear:
				if cx > x - 60 and cx < x + len + 60:
					keep.append(Vector2(cx - x - 45, cx - x + 45))
			for bx in BRIDGES + SIDE_STREETS:
				if bx > x - 100 and bx < x + len + 100:
					keep.append(Vector2(bx - x - 80, bx - x + 80))
			sl.set("keep_clear", keep)
			_add(life, sl, "Stretch%d" % chunk)
			chunk += 1
			x += len
	root.move_child(life, street.get_index() + 1)   # furniture behind the pavement people and parked cars

	# Band, then the water (it reflects everything drawn before it), birds.
	_add(root, load("res://scenes/characters/band.tscn").instantiate())
	var traffic_front := Node2D.new(); traffic_front.set_script(Tr); traffic_front.position = Vector2(0, GY)
	traffic_front.set("lane", 1); traffic_front.set("town", TOWN); traffic_front.set("map_width", float(W))
	traffic_front.set("map_min", MAP_MIN)
	traffic_front.set("car_free", _ranges([Vector2(OLD_TOWN.x, OUTSKIRTS)]))
	var ped_front := Node2D.new(); ped_front.set_script(load("res://scripts/world/pedestrians.gd")); ped_front.position = Vector2(0, GY)
	ped_front.set("side", 1); ped_front.set("busy", _people())
	_add(root, ped_front, "PeopleFront")
	_add(root, traffic_front, "TrafficFront")
	var rh := Node2D.new(); rh.set_script(load("res://scripts/world/outskirts.gd")); rh.position = Vector2(ROUND_HOTEL_X, GY + 46)
	rh.set("kind", 12); rh.set("sign_text", "HOTEL")
	_add(root, rh, "RoundHotel")
	var water := _add(root, Node2D.new(), "Water")
	var Wt = load("res://scripts/world/water.gd")
	for w in [["DitchWest", MAP_MIN - 400.0, GRASS_BANK.x, true], ["Canal", CANAL_FROM, TOWN.y, false], ["DitchEast", TOWN.y, W + 400.0, true]]:
		var r := ColorRect.new(); r.set_script(Wt)
		var ditch_y := 38.0 if w[3] else 22.0   # outside town the motorway and its verge come first
		r.position = Vector2(w[1], GY + ditch_y); r.size = Vector2(w[2] - w[1], 520)
		if w[3]:
			r.set("water_color", WorldPalette.DITCH); r.set("deep_color", WorldPalette.DITCH.darkened(0.35))
		_add(water, r, w[0])
	var boats := Node2D.new(); boats.set_script(load("res://scripts/world/houseboats.gd")); boats.position = Vector2(0, GY)
	var spots: Array[float] = []
	spots.assign(HOUSEBOATS)
	boats.set("spots", spots)
	_add(root, boats, "Houseboats")
	var birds := Node2D.new(); birds.set_script(load("res://scripts/world/birds.gd"))
	_add(root, birds, "Birds")
	# Life on the water by the old town and the lock, and in the polder ditch.
	var WL = load("res://scripts/world/water_life.gd")
	for wl in [[CANAL_FROM + 140.0, 8200.0 - CANAL_FROM - 140.0, -1.0, 5], [MAP_MIN, GRASS_BANK.x - 100.0 - MAP_MIN, -1.0, 9]]:
		var life_w := Node2D.new(); life_w.set_script(WL); life_w.position = Vector2(wl[0], GY)
		life_w.set("length", wl[1]); life_w.set("lock_x", wl[2]); life_w.set("seed_value", wl[3])
		life_w.set("water_y", 22.0 if wl[3] == 5 else 38.0)   # the ditch lies below the motorway verge
		_add(root, life_w, "WaterLife%d" % wl[3])
	# No water west of the park: a viaduct, then a grass bank; trees hide the joins.
	var FG = load("res://scripts/world/front_ground.gd")
	for f in [["ViaductRoad", VIADUCT.x, TOWN.x, 0, 27.0], ["ViaductTown", TOWN.x, VIADUCT.y, 0, 16.0],
			["GrassBank", GRASS_BANK.x, GRASS_BANK.y, 1, 38.0]]:
		var g := Node2D.new(); g.set_script(FG); g.position = Vector2(f[1], GY)
		g.set("length", f[2] - f[1]); g.set("kind", f[3]); g.set("top", f[4])
		_add(root, g, f[0])
	var Cn = load("res://scripts/world/canopy.gd")
	for i in CANOPIES.size():
		var cn := Node2D.new(); cn.set_script(Cn); cn.position = Vector2(CANOPIES[i], GY); cn.set("seed_value", 11 + i)
		_add(root, cn, "Canopy%d" % i)
	# Foreground trees along the country road, in a layer that moves faster.
	var fg := Node2D.new(); fg.set_script(Px); fg.set("factor", 1.35)
	_add(root, fg, "Foreground")
	var fgs := Node2D.new(); fgs.set_script(Sc)
	fgs.set("kind", 4); fgs.set("town", TOWN); fgs.set("map_width", float(W)); fgs.set("map_min", MAP_MIN)
	fgs.set("foreground", Vector2(MAP_MIN, CONSTRUCTION.x - 300.0)); fgs.set("seed_value", 23)
	_add(fg, fgs, "Scenery")

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
	cb.position = Vector2(center_x - cb.signed_center(), GY)   # the sign house sits on the door
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
			cb.set("shop_signs", PackedStringArray(CENTRE_SHOPS))
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
			cb.set("style", it[4] if it.size() > 4 else 0)
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


func _ranges(list: Array) -> Array[Vector2]:
	var out: Array[Vector2] = []
	out.assign(list)
	return out


func _people() -> Array[Vector3]:
	var out: Array[Vector3] = []
	out.assign(PEOPLE)
	return out
