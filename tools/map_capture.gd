class_name MapCapture
extends Node
## Dev tool: screenshots of the running world map at fixed spots, for
## before/after comparisons of art changes. Debug builds only.
##   Summer --path . res://scenes/world/world_map.tscn -- --capture=3:11800,1:8500 --capture-dir=/abs/dir --time=10
## Each shot is "zoom:x" (x = the band's world x); saved as zoom<z>_x<x>.png
## at the window size, then the game quits. --capture-drive: the band sits in
## the van at each spot (shots named van_zoom<z>_x<x>.png).

var shots: Array = []                       # [zoom, x]
var out_dir := ""
var drive := false


static func from_args(map: WorldMap) -> void:
	if not OS.is_debug_build():
		return
	var spec := ""
	var dir := ""
	var c_drive := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--capture="):
			spec = arg.trim_prefix("--capture=")
		elif arg.begins_with("--capture-dir="):
			dir = arg.trim_prefix("--capture-dir=")
		elif arg == "--capture-drive":
			c_drive = true
	if spec == "":
		return
	var c := MapCapture.new()
	c.name = "MapCapture"
	c.out_dir = dir if dir != "" else ProjectSettings.globalize_path("user://captures")
	c.drive = c_drive
	for s in spec.split(","):
		var p := s.split(":")
		if p.size() == 2:
			c.shots.append([p[0].to_float(), p[1].to_float()])
	map.add_child(c)


func _ready() -> void:
	DirAccess.make_dir_recursive_absolute(out_dir)
	_run.call_deferred()


func _run() -> void:
	var map := get_parent() as WorldMap
	for i in 20:                            # let the scene settle (glows, sky)
		await get_tree().process_frame
	for s in shots:
		var z: float = s[0]
		var x: float = s[1]
		map.place_band(x, 1.0)
		if drive:
			var van: Vehicle = map.find_children("*", "Vehicle", true, false).filter(func(v: Vehicle) -> bool: return v.kind == Vehicle.Kind.VAN)[0]
			if map.vehicle:
				map.vehicle = null
			van.global_position.x = x
			map.board(van, true)
			map._lane_y = RoadLanes.y(x, 1.0, map.veh_cfg.van_lane)   # already in its lane
			van.global_position.y = map.GROUND_Y + map._lane_y
		map.set_physics_process(false)      # hold the zoom where we put it
		map.zoom = z
		map._apply_zoom()
		for i in 12:
			await get_tree().physics_frame
		map.band.camera.snap()
		for i in 6:
			await get_tree().process_frame
		await RenderingServer.frame_post_draw
		var img := get_viewport().get_texture().get_image()
		var path := out_dir.path_join("%szoom%s_x%d.png" % ["van_" if drive else "", str(z).replace(".", "_"), int(x)])
		img.save_png(path)
		print("captured ", path)
		map.set_physics_process(true)
	get_tree().quit()
