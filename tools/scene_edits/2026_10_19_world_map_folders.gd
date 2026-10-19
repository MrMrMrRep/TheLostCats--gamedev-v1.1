@tool
extends EditorScript
## One-off edit (2026-10-19), kept for the record: sorts the world map into
## depth-layer folders with a folder per district inside, and adds the rule
## Markers and the district Zones. Edits the scene in place (positions stay
## the same); it does not regenerate anything. Don't run it again.

const PATH := "res://scenes/world/world_map.tscn"
const GY := 288.0
# District folders, west to east: [name, from world x] (each runs to the next).
const DISTRICTS := [["WestRoad", -1e9], ["Viaduct", 4600.0], ["Hotels", 6400.0], ["ParkTheater", 7083.0],
	["OldTown", 7800.0], ["CanalBelt", 9600.0], ["Flats", 15400.0], ["Industry", 16400.0],
	["Storage", 17500.0], ["Airport", 18240.0]]

var root: Node2D


func _run() -> void:
	var ps: PackedScene = load(PATH)
	root = ps.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	if root.has_node("Markers"):
		push_error("already done")
		root.free()
		return

	# Background: the sky stays first, the parallax layers go in a folder.
	var bg := _folder(root, "Background")
	root.move_child(bg, root.get_node("Sky").get_index() + 1)
	for n in ["Skyline", "PolderFar", "BackStreet", "PolderNear"]:
		_move(root.get_node(n), bg)

	# Buildings (was City): a folder per district.
	var city := root.get_node("City")
	city.name = "Buildings"
	city.get_node("Storage").name = "BandStorage"     # "Storage" is a district folder now
	_by_district(city, city.get_children())

	# Road: the highway ramp, the street's collision and the drawn street.
	var road := _folder(root, "Road")
	root.move_child(road, root.get_node("Highway").get_index())
	for n in ["Highway", "StreetCollision", "Street"]:
		_move(root.get_node(n), road)

	_by_district(root.get_node("StreetLife"), root.get_node("StreetLife").get_children())

	# Signs over and along the road.
	var signs := _folder(root, "Signs")
	root.move_child(signs, root.get_node("Sign50").get_index())
	var sign_nodes: Array[Node] = []
	for n in ["Sign50", "Sign100", "Fork", "Gantry0", "Gantry1", "Gantry2", "Gantry3"]:
		sign_nodes.append(root.get_node(n))
	for n in sign_nodes:
		_move(n, signs)
	_by_district(signs, sign_nodes)

	var places := root.get_node("Places")
	_by_district(places, places.get_children())
	root.set("start_spawn", root.get_path_to(root.find_child("Start", true, false)))
	var geordie := root.find_child("Geordie", true, false)
	geordie.set("tour_quest", true)

	# The ground in front of the road and the trees that hide the joins.
	var front := _folder(root, "FrontGround")
	root.move_child(front, root.get_node("ViaductRoad").get_index())
	var front_nodes: Array[Node] = []
	for n in ["ViaductRoad", "ViaductTown", "GrassBank", "ConstructionFront"]:
		front_nodes.append(root.get_node(n))
	for n in front_nodes:
		_move(n, front)
	_by_district(front, front_nodes)
	var canopies := _folder(root, "Canopies")
	root.move_child(canopies, root.get_node("Canopy0").get_index())
	for i in 5:
		_move(root.get_node("Canopy%d" % i), canopies)

	_add_zones()
	_add_markers()

	var out := PackedScene.new()
	var err := out.pack(root)
	if err == OK:
		err = ResourceSaver.save(out, PATH)
	print("saved: ", error_string(err))
	root.free()


func _folder(parent: Node, name: String) -> Node2D:
	var f := Node2D.new()
	f.name = name
	parent.add_child(f)
	f.owner = root
	return f


func _move(n: Node, to: Node) -> void:
	_disown(n)
	n.reparent(to, false)              # folders sit at the origin: positions stay
	_own(n)


func _disown(n: Node) -> void:
	for c in n.get_children():
		_disown(c)
	if n.owner == root:
		n.owner = null


func _own(n: Node) -> void:
	if n.owner == null:
		n.owner = root
	for c in n.get_children():
		_own(c)


## Sort `nodes` (children of `parent`) into district sub-folders by world x,
## keeping their order within a district (draw order).
func _by_district(parent: Node, nodes: Array) -> void:
	var folders := {}
	for d in DISTRICTS:
		folders[d[0]] = null
	var list := nodes.duplicate()
	for n in list:
		var x: float = n.position.x if n is Node2D else 0.0   # every folder sits at the origin
		var name: String = DISTRICTS[0][0]
		for d in DISTRICTS:
			if x >= d[1]:
				name = d[0]
		if folders[name] == null:
			folders[name] = _folder(parent, name)
			if folders[name].name != name:
				push_error("folder name clash: " + name)
		_move(n, folders[name])
	var i := 0
	for d in DISTRICTS:                      # folders west to east, first in the parent
		if folders[d[0]] != null:
			parent.move_child(folders[d[0]], i)
			i += 1


func _add_zones() -> void:
	var zones := _folder(root, "Zones")
	for z in [["WestRoad", -4000.0, 4600.0, 0.0, false, false, Color(0.55, 0.8, 0.4)],
			["Viaduct", 4600.0, 6400.0, 0.0, false, false, Color(0.6, 0.6, 0.65)],
			["Hotels", 6400.0, 7083.0, 3.0, false, true, Color(0.9, 0.6, 0.3)],
			["ParkTheater", 7083.0, 7800.0, 3.0, false, true, Color(0.4, 0.8, 0.5)],
			["OldTown", 7800.0, 9600.0, 6.0, true, false, Color(0.95, 0.45, 0.4)],
			["CanalBelt", 9600.0, 15400.0, 4.0, true, false, Color(0.35, 0.6, 1.0)],
			["Flats", 15400.0, 16400.0, 2.0, false, true, Color(0.8, 0.8, 0.5)],
			["Industry", 16400.0, 17500.0, 1.0, false, true, Color(0.6, 0.65, 0.75)],
			["Storage", 17500.0, 18240.0, 1.0, false, true, Color(0.75, 0.5, 0.9)],
			["Airport", 18600.0, 19900.0, 3.0, false, true, Color(0.5, 0.85, 0.9)]]:
		var n := Node2D.new()
		n.set_script(load("res://scripts/world/world_zone.gd"))
		n.position = Vector2(z[1], GY)
		n.set("length", z[2] - z[1])
		n.set("people_per_screen", z[3])
		n.set("bikes_only", z[4])
		n.set("parked_cars", z[5])
		n.set("color", z[6])
		n.name = z[0]
		zones.add_child(n)
		n.owner = root


func _add_markers() -> void:
	var markers := _folder(root, "Markers")
	var scenery: Array[NodePath] = []
	for l in ["Skyline", "PolderFar", "BackStreet", "PolderNear"]:
		scenery.append(NodePath("../../Background/%s/Scenery" % l))
	scenery.append(NodePath("../../Foreground/Scenery"))
	var lanes: Array[NodePath] = [NodePath("../../Road/Street"), NodePath("../../TrafficBack"), NodePath("../../TrafficFront")]
	var both: Array[NodePath] = lanes.duplicate()
	both.append_array(scenery)
	# The values the scene had on WorldMap (its exports are gone now).
	for m in [["FootLimit", 4600.0, "Foot / bike limit", Color(1.0, 0.4, 0.4), [], ""],
			["ScenicFrom", -300.0, "Road trip view", Color(0.5, 0.9, 1.0), [], ""],
			["RoadTransition", 6000.0, "City street starts", Color(1.0, 0.85, 0.2), lanes, "town:x"],
			["SpeedLimitStart", 6000.0, "50 km/h from here", Color(1.0, 0.6, 0.2), [], ""],
			["SpeedLimitEnd", 18240.0, "50 km/h until here", Color(1.0, 0.6, 0.2), [], ""],
			["TownWest", 6400.0, "Town starts", Color(0.6, 1.0, 0.6), scenery, "town:x"],
			["TownEast", 18240.0, "Town ends", Color(0.6, 1.0, 0.6), both, "town:y"],
			["CanalStart", 7083.0, "Canal starts", Color(0.4, 0.7, 1.0), [NodePath("../../Water/Canal")], "left_edge"]]:
		var n := Node2D.new()
		n.set_script(load("res://scripts/world/world_marker.gd"))
		n.name = m[0]
		var row := markers.get_child_count() % 3        # stagger the flags so close ones don't overlap
		n.position = Vector2(m[1], GY - row * 36.0)
		n.set("label", m[2])
		n.set("color", m[3])
		var t: Array[NodePath] = []
		t.assign(m[4])
		n.set("targets", t)
		n.set("target_property", m[5])
		markers.add_child(n)
		n.owner = root
