extends SceneTree
## Headless checks for "The International" (exits 1 on failure): the four
## painted rooms are linked; the whole band comes in but Geoff is lost, asleep
## on the bed in the attic; each room's way up works with its member's skill
## (Nikki's ramp to the key, The Germ through the luggage, Joep's hack on the
## camera's wall plug, The Germ's beat on the lift gate); reaching Geoff wakes him and
## only all five together get out (flag geoff_found, Geoff back in the party).
## Run: godot --headless --path . --script res://tests/test_the_international.gd
## Game classes stay untyped: naming them here would compile them before the
## autoloads exist in --script mode.

const EXPECTED_CHECKS := 21
const GY := 288.0
const STEP := 1200.0
const ACTIONS := ["move_left", "move_right", "move_up", "jump", "action_b", "instrument", "interact"]

var failures := 0
var checks := 0
var level
var band
var game


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	game = root.get_node("Game")
	level = load("res://scenes/levels/the_international.tscn").instantiate()
	root.add_child(level)
	await _frames(8)
	band = level.band
	var rooms = level.get_node("Rooms")
	var names: Array = rooms.get_children().map(func(r): return String(r.name))
	_check(names == ["Bar", "Stairs", "Corridor", "Attic"], "rooms: %s" % [names])
	var doors_ok := true
	for d in ["Bar/ToStairs", "Stairs/FromBar", "Stairs/ToCorridor", "Corridor/FromStairs", "Corridor/ToAttic", "Attic/FromLift"]:
		var door = rooms.get_node(d)
		doors_ok = doors_ok and door.get_node_or_null(door.target_door) != null
	_check(doors_ok, "every room's door leads into the next")
	var art_ok := true
	for a in level.get_node("Backdrops").get_children():
		art_ok = art_ok and a.texture != null and a.texture.get_size() == Vector2(1152, 720)
	_check(art_ok and level.get_node("Backdrops").get_child_count() == 4, "each room has its painting (1152x720, half a world px per texel)")

	var bar = rooms.get_node("Bar")
	var attic = rooms.get_node("Attic")
	var geoff = band.member_by_id(&"geoff")
	var sleeper = attic.get_node("Geoff")
	_check(band.members.size() == 5 and level.members_in(bar).size() == 4,
		"the whole band comes in: four in the bar (%d)" % level.members_in(bar).size())
	_check(level.room_of_member(geoff) == attic and sleeper.is_asleep() and geoff.global_position.distance_to(sleeper.global_position) < 6.0,
		"Geoff is lost: asleep on the bed in the attic")
	band.switch_to(band.members.find(geoff))
	await _frames(2)
	_check(band.active != geoff, "you can't switch to the sleeping Geoff")

	# --- The bar: the key on the barrel shelf, Nikki's ramp. ---
	var door = bar.get_node("ToStairs")
	var key = bar.get_node("HotelKey")
	_check(door.locked and key.global_position.y <= 120.0, "the HOTEL door is locked; the key is up on the barrel shelf")
	var nikki = await _use(&"nikki", Vector2(100, 216), 1.0)
	_check(nikki.is_on_floor(), "Nikki stands on the bar counter")
	nikki.stamina.refill()
	Input.action_press("move_up")
	await _tap("instrument")
	Input.action_release("move_up")
	Input.action_press("move_right")
	var got := false
	for i in 240:
		await physics_frame
		if nikki.inventory.has(&"hotel_key"):
			got = true
			break
	Input.action_release("move_right")
	_check(got, "she plays a ramp of notes up to the shelf and takes the key")
	await _gather(door.global_position)
	door.interact(nikki, level)
	await _idle()
	var stairs = rooms.get_node("Stairs")
	_check(not door.locked and level.members_in(stairs).size() == 4, "the key opens the HOTEL door: the four go up together")

	# --- The stairs: up the treads, the luggage, The Germ. ---
	var luggage = stairs.get_node("Luggage")
	var joep = await _use(&"joep", Vector2(STEP + 120, GY), 1.0)
	Input.action_press("move_right")
	await _frames(150)
	Input.action_release("move_right")
	_check(joep.global_position.y < 200.0 and joep.global_position.x < luggage.global_position.x,
		"Joep walks up the stairs to the landing; the luggage stops him (%.0f, %.0f)" % [joep.global_position.x, joep.global_position.y])
	var germ = await _use(&"germ", Vector2(STEP + 400, 192), 1.0)
	germ.stamina.refill()
	await _tap("action_b")
	await _frames(25)
	_check(luggage.is_broken, "The Germ's rage punch goes through the luggage")

	# --- The corridor: the camera and the fire door, the lift gate. ---
	var corridor = rooms.get_node("Corridor")
	await _gather(stairs.get_node("ToCorridor").global_position)
	stairs.get_node("ToCorridor").interact(band.active, level)
	await _idle()
	var cam = corridor.get_node("Camera")
	var fire = corridor.get_node("FireDoor")
	var jay = await _use(&"jay", Vector2(STEP * 2 + 70, GY), 1.0)
	_check(not fire.solid and not cam.tripped, "the fire door stands open while nobody's in the camera's view")
	jay.global_position = Vector2(STEP * 2 + 250, GY)
	await _frames(4)
	_check(cam.tripped and fire.solid, "walk into the camera's view: ALARM, the fire door slams")
	level.restart_room()
	await _idle()
	joep = await _use(&"joep", Vector2(STEP * 2 + 96, GY), 1.0)
	await _tap("action_b")
	await _frames(4)
	jay.global_position = Vector2(STEP * 2 + 250, GY)
	await _frames(4)
	_check(not cam.active and not fire.solid, "Joep hacks the camera off through its wall plug: the door stays open")
	var lever = corridor.get_node("LiftButton")
	var gate = corridor.get_node("LiftGate")
	germ = await _use(&"germ", lever.global_position, 1.0)
	germ.stamina.refill()
	await _tap("interact")
	await _tap("instrument")
	await _frames(60)
	_check(level.time_control.mode == 1 and not gate.solid, "the lift button opens the gate and The Germ's beat holds it open")
	await _tap("instrument")
	await _tap("instrument")
	await _frames(60)

	# --- The attic: wake Geoff, all out together. ---
	await _gather(corridor.get_node("ToAttic").global_position)
	corridor.get_node("ToAttic").interact(band.active, level)
	await _idle()
	var exit = attic.get_node("Exit")
	var router = root.get_node("SceneRouter")
	var target := [""]
	router.transition_started.connect(func(p): target[0] = p, CONNECT_ONE_SHOT)
	exit.interact(band.active, level)
	await _frames(2)
	_check(target[0] == "" and sleeper.is_asleep(), "no way out while Geoff sleeps")
	joep = await _use(&"joep", Vector2(STEP * 3 + 370, GY), 1.0)
	Input.action_press("move_right")
	Input.action_press("jump")
	await _frames(30)
	Input.action_release("jump")
	Input.action_release("move_right")
	await _frames(30)
	_check(joep.global_position.y < 220.0 and not sleeper.is_asleep(), "Joep jumps onto the bed and wakes Geoff (y %.0f)" % joep.global_position.y)
	band.switch_to(band.members.find(geoff))
	await _frames(2)
	_check(band.active == geoff, "awake, Geoff is one of the band again")
	attic.get_node("Rat").defeat()          # (no bites while they line up)
	await _gather(exit.global_position)
	exit.interact(band.active, level)
	await _frames(3)
	_check(target[0] == "res://scenes/world/world_map.tscn" and game.get_flag(&"geoff_found") and not game.missing(&"geoff"),
		"all five together: out to the map, Geoff found")
	_check(game.party.size() == 5, "Geoff is back in the party")

	if checks != EXPECTED_CHECKS:
		print("  FAIL ran %d of %d checks (script error?)" % [checks, EXPECTED_CHECKS])
		failures += 1
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


## Switch to member `id`, put them at `pos` facing `facing`.
func _use(id: StringName, pos: Vector2, facing: float):
	for a in ACTIONS:
		Input.action_release(a)
	await _idle()
	var m = band.member_by_id(id)
	band.switch_to(band.members.find(m), true)
	m.global_position = pos
	m.velocity = Vector2.ZERO
	m.facing = facing
	await _frames(3)
	return m


## Everyone awake in the active member's room stands at `pos` (a door).
func _gather(pos: Vector2) -> void:
	for a in ACTIONS:
		Input.action_release(a)
	await _idle()
	var room = level.room_of_member(band.active)
	var i := 0
	for m in band.members:
		if level.room_of_member(m) == room:
			m.global_position = pos + Vector2(-20 + i * 10, -4)
			m.velocity = Vector2.ZERO
			i += 1
	await _frames(10)


func _idle() -> void:
	var n := 0
	while (level.is_busy or paused) and n < 600:
		await physics_frame
		n += 1
	await _frames(3)


func _tap(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	print(("  ok   " if ok else "  FAIL ") + label)
	if not ok:
		failures += 1
