extends Node
## Screenshots of the real world map at the spots of the style v3 mocks, to
## compare the game with docs/art/style_v3_*. Opens a window, walks the band
## to each spot, saves docs/art/game_v3_<spot>.png (1280x720) and quits.
##   Summer --path . res://tools/world_shots.tscn
## Optional: -- --time=21 (hour of the day), -- --only=oldtown

const SPOTS := [["polder", 2600.0], ["viaduct", 5500.0], ["hotels", 6720.0], ["park", 7420.0],
	["oldtown", 8240.0], ["market", 8800.0], ["canal", 10500.0], ["studio", 11780.0], ["venue", 14400.0],
	["flats", 15800.0], ["industry", 16900.0], ["storage", 17800.0], ["airport", 19500.0]]


func _ready() -> void:
	var hour := 11.0
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--time="):
			hour = arg.trim_prefix("--time=").to_float()
		elif arg.begins_with("--only="):
			only = arg.trim_prefix("--only=")
	Game.time_of_day = hour
	var cfg := DayConfig.current()
	cfg.clock_runs = false
	var map: WorldMap = load("res://scenes/world/world_map.tscn").instantiate()
	add_child(map)
	for i in 10:
		await get_tree().process_frame
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://docs/art"))
	for s: Array in SPOTS:
		if only != "" and not only.split(",").has(s[0]):
			continue
		map.place_band(s[1], 1.0)
		for i in 45:
			await get_tree().process_frame
		var img := get_viewport().get_texture().get_image()
		var suffix := "" if is_equal_approx(hour, 11.0) else "_%02dh" % int(hour)
		img.save_png("res://docs/art/game_v3_%s%s.png" % [s[0], suffix])
		print("saved ", s[0])
	get_tree().quit()
