extends SceneTree
## Headless checks for M6 abilities on the abilities test level (exits 1 on
## failure): each gate opens only for the right member and then lets everyone
## through; every ability and beer effect does what it says.
## Run: Summer --headless --path . --script res://tests/test_abilities.gd
## Game classes stay untyped: naming them here would compile them before the
## autoloads exist in --script mode.

const EXPECTED_CHECKS := 41
const GY := 288.0
const JOEP := 0
const JAY := 1
const NIKKI := 2
const GERM := 3
const GEOFF := 4
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "jump", "action_a", "action_b", "interact"]

var failures := 0
var checks := 0
var deaths := []
var level
var band
var stage


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	level = load("res://scenes/levels/abilities_test.tscn").instantiate()
	root.add_child(level)
	await _frames(5)
	band = level.band
	stage = level.get_node("Rooms/Stage")
	level.member_died.connect(func(m, c): deaths.append("%s (%s)" % [m.profile.display_name, c]))

	await _test_germ_gate()
	await _test_jay_gate()
	await _test_jay_case_and_throw()
	await _test_joep()
	await _test_nikki()
	await _test_germ_more()
	await _test_geoff()
	await _test_beer()
	_check(deaths.is_empty(), "nobody died during the ability tests %s" % [deaths])

	if checks != EXPECTED_CHECKS:
		print("  FAIL ran %d of %d checks (script error?)" % [checks, EXPECTED_CHECKS])
		failures += 1
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


# --- Gates -----------------------------------------------------------------

func _test_germ_gate() -> void:
	var wood = stage.get_node("WoodenCrates")
	var joep = await _use(JOEP, Vector2(232, GY), 1.0)
	await _tap("action_a")
	_check(not wood.is_broken, "Joep can't break the wooden crates")
	var germ = await _use(GERM, Vector2(232, GY), 1.0)
	await _tap("action_a")
	await _frames(2)
	_check(wood.is_broken, "The Germ punches the wooden crates apart")
	_check(await _walks_past(GEOFF, 200.0, 290.0), "Geoff walks through the opened doorway")


func _test_jay_gate() -> void:
	var glass = stage.get_node("GlassPane")
	await _use(GERM, Vector2(376, GY), 1.0)
	await _tap("action_a")
	_check(not glass.is_broken, "The Germ's punch doesn't break glass")
	await _use(JAY, Vector2(340, GY), 1.0)
	await _tap("action_a")
	await _frames(2)
	_check(glass.is_broken, "Jay's bass wave shatters the glass from 2 tiles away")
	_check(await _walks_past(GEOFF, 360.0, 430.0), "Geoff walks through where the glass was")


func _test_jay_case_and_throw() -> void:
	var case = stage.get_node("FlightCase")
	var x0: float = case.global_position.x
	await _use(GEOFF, Vector2(x0 - 20.0, GY), 1.0)
	Input.action_press("move_right")
	await _frames(30)
	Input.action_release("move_right")
	_check(absf(case.global_position.x - x0) < 1.0, "Geoff can't move the flight case")
	await _use(JAY, Vector2(x0 - 20.0, GY), 1.0)
	Input.action_press("move_right")
	await _frames(40)
	Input.action_release("move_right")
	_check(case.global_position.x > x0 + 20.0, "Jay pushes the flight case (%.0f px)" % (case.global_position.x - x0))
	# Pull: stand right of it facing it, hold A and walk away.
	var x1: float = case.global_position.x
	var jay = await _use(JAY, Vector2(x1 + 19.0, GY), -1.0)
	Input.action_press("action_a")
	await _frames(2)
	Input.action_press("move_right")
	await _frames(30)
	Input.action_release("move_right")
	Input.action_release("action_a")
	_check(case.global_position.x > x1 + 15.0, "Jay pulls the flight case while holding A")
	# Case against the 2-tile ledge (x 552) as a step: Geoff climbs up.
	case.global_position = Vector2(540, GY)
	await _frames(3)
	var geoff = await _use(GEOFF, Vector2(490, GY), 1.0)
	var on_top := await _run_and_jump(geoff, [510.0, 532.0], 640.0, 200)
	_check(on_top and geoff.global_position.y < GY - 47.0, "with the case as a step Geoff climbs the 2-tile ledge")
	# Throw: Jay launches Geoff ~4 tiles up.
	await _use(JAY, Vector2(760, GY), 1.0)
	_place(band.members[GEOFF], Vector2(770, GY))
	await _frames(3)
	var y0: float = band.members[GEOFF].global_position.y
	await _tap("action_a")
	var peak := y0
	for i in 60:
		await physics_frame
		peak = minf(peak, band.members[GEOFF].global_position.y)
	_check((y0 - peak) / 24.0 > 3.8, "Jay throws Geoff %.1f tiles up" % ((y0 - peak) / 24.0))


func _test_joep() -> void:
	var elec = stage.get_node("ElectricFloor")
	var panel = stage.get_node("HackPanel")
	# Geoff on the platform can't hack.
	await _use(GEOFF, panel.global_position, 1.0)
	await _frames(2)
	await _tap("interact")
	_check(elec.enabled, "Geoff can't hack the panel")
	# Joep climbs the wall (x 792..816, rows 6-8) to the platform.
	# Running jump from a tile back reaches the wall face while rising
	# (from right underneath you'd bump the block's underside).
	var joep = await _use(JOEP, Vector2(760, GY), 1.0)
	for a in ["move_right", "move_up", "action_a", "jump"]:
		Input.action_press(a)
	var climbed := false
	for i in 150:
		await physics_frame
		if joep.ability.climbing and not climbed:
			climbed = true
			Input.action_release("jump")
			Input.action_release("move_right")   # don't walk on once up top
		if joep.is_on_floor() and joep.global_position.y < 150.0:
			break
	_release_all()
	_check(climbed, "Joep grabs the wall and climbs")
	_check(joep.is_on_floor() and absf(joep.global_position.y - 144.0) < 1.0, "Joep pulls up onto the 6-tile platform (y %.0f)" % joep.global_position.y)
	_check(joep.stamina.current_stamina < joep.stamina.max_stamina, "climbing costs stamina (%.0f left)" % joep.stamina.current_stamina)
	_place(joep, panel.global_position)
	await _frames(3)
	await _tap("interact")
	_check(not elec.enabled, "Joep hacks the panel: electric floor off")
	_check(await _walks_past(GEOFF, 900.0, 1080.0), "Geoff walks over the dead electric floor")
	# Wall slide and wall jump on the room's left wall (x 0..24).
	joep = await _use(JOEP, Vector2(31, 120), -1.0)
	Input.action_press("move_left")
	await _frames(25)
	_check(joep.velocity.y <= 41.0 and joep.ability.wall_sliding, "wall slide caps the fall (%.0f px/s)" % joep.velocity.y)
	await _tap("jump")
	Input.action_release("move_left")
	_check(joep.velocity.x > 100.0 and joep.velocity.y < 0.0, "wall jump kicks away from the wall")
	await _frames(40)


func _test_nikki() -> void:
	# Double jump: noticeably higher than one jump (3.3 tiles).
	var nikki = await _use(NIKKI, Vector2(760, GY), 1.0)
	Input.action_press("jump")
	var peak: float = GY
	var doubled := false
	for i in 120:
		await physics_frame
		peak = minf(peak, nikki.global_position.y)
		if not doubled and nikki.velocity.y > -20.0 and not nikki.is_on_floor():
			Input.action_release("jump")
			await physics_frame
			Input.action_press("jump")
			doubled = true
		if doubled and nikki.is_on_floor():
			break
	Input.action_release("jump")
	_check((GY - peak) / 24.0 > 4.8, "double jump reaches %.1f tiles" % ((GY - peak) / 24.0))
	# Hover: slow fall while holding jump, until stamina runs out.
	_place(nikki, Vector2(760, 40))
	nikki.stamina.refill()
	await _frames(20)
	Input.action_press("jump")
	await _frames(40)
	_check(nikki.ability.hovering and nikki.velocity.y <= 26.0, "hover: falls at %.0f px/s" % nikki.velocity.y)
	var n := 0
	while nikki.ability.hovering and n < 200:
		await physics_frame
		n += 1
	await _frames(6)
	_check(not nikki.ability.hovering and nikki.velocity.y > 100.0 and nikki.ability.hover_spent,
		"out of stamina after %.1f s: the hover ends and she drops" % ((40 + n) / 60.0))
	Input.action_release("jump")
	await _frames(60)
	# Cross the 7-tile pit and pull the lever.
	nikki.stamina.refill()
	_place(nikki, Vector2(1080, GY))
	await _frames(3)
	Input.action_press("move_right")
	var jumped := false
	var doubled2 := false
	for i in 240:
		await physics_frame
		if level.is_busy:
			break
		if not jumped and nikki.global_position.x >= 1112.0:
			Input.action_press("jump")
			jumped = true
		elif jumped and not doubled2 and nikki.velocity.y > 0.0:
			Input.action_release("jump")
			await physics_frame
			Input.action_press("jump")
			doubled2 = true
		if nikki.global_position.x > 1316.0:
			Input.action_release("move_right")
		if doubled2 and nikki.is_on_floor():
			break
	_release_all()
	_check(not level.is_busy and nikki.global_position.x > 1296.0, "Nikki crosses the 7-tile pit (x %.0f)" % nikki.global_position.x)
	await _await_idle()
	var bridge = stage.get_node("Bridge")
	_place(nikki, stage.get_node("Lever").global_position)
	await _frames(3)
	await _tap("interact")
	_check(bridge.solid, "the lever extends the bridge")
	_check(await _walks_past(GEOFF, 1090.0, 1310.0), "Geoff walks across the bridge")


func _test_germ_more() -> void:
	var rat = stage.get_node("Rat")
	# Ground pound breaks a cracked floor slab.
	var slab = load("res://scripts/props/breakable.gd").new()
	slab.substance = 3
	slab.size = Vector2(48, 12)
	stage.add_child(slab)
	slab.global_position = Vector2(1580, GY)
	var germ = await _use(GERM, Vector2(1580, 200), 1.0)
	await _tap("action_a")
	await _frames(40)
	_check(slab.is_broken, "ground pound smashes a cracked floor")
	slab.queue_free()
	# Shield blocks a rat bite from the front.
	rat.reset_state()
	rat.global_position = Vector2(1560, GY)
	await _use(GERM, Vector2(1548, GY), 1.0)
	germ.stamina.refill()
	Input.action_press("action_b")
	await _frames(40)
	_check(germ.health.hp == 3 and germ.ability.shielding, "the drumstick shield blocks the rat")
	_check(germ.stamina.current_stamina < 100.0, "holding the shield costs stamina")
	# Shield up: a platform Jay can stand on.
	Input.action_press("move_up")
	await _frames(3)
	var jay = band.members[JAY]
	_place(jay, Vector2(1548, GY - 80))
	await _frames(40)
	_check(jay.is_on_floor() and absf(jay.global_position.y - (GY - 38.0)) < 2.0, "Jay stands on the raised shield (y %.0f)" % jay.global_position.y)
	_release_all()
	await _frames(20)
	# Punch defeats a rat.
	rat.reset_state()
	rat.global_position = Vector2(1570, GY)
	await _use(GERM, Vector2(1556, GY), 1.0)
	await _tap("action_a")
	_check(not rat.alive, "The Germ's punch knocks out the rat")
	rat.reset_state()
	# B is the shield, not a drink.
	germ.add_beer()
	await _tap("action_b")
	_check(germ.beers == 1, "The Germ's B doesn't drink the beer")
	germ.beers = 0


func _test_geoff() -> void:
	var rat = stage.get_node("Rat")
	rat.reset_state()
	rat.global_position = Vector2(1580, GY)
	await _frames(2)
	var geoff = await _use(GEOFF, Vector2(1540, GY), 1.0)
	geoff.health.restore(1)
	await _tap("action_a")
	await _frames(15)
	_check(rat.distracted_left > 0.0, "Geoff's bubble distracts the rat")
	_place(geoff, rat.global_position)
	await _frames(5)
	_check(geoff.health.hp == 1, "a distracted rat doesn't bite")
	_place(geoff, Vector2(1500, GY))   # step away before the bubble pops
	await _frames(150)
	# Bass wave knocks the rat back.
	rat.reset_state()
	rat.global_position = Vector2(1600, GY)
	await _use(JAY, Vector2(1560, GY), 1.0)
	await _frames(40)
	await _tap("action_a")
	await _frames(2)
	_check(rat.stunned_left > 0.0 and rat.velocity.x > 0.0, "the bass wave knocks the rat back")
	rat.reset_state()
	# Persuade comes from the ability.
	var bouncer = stage.get_node("Bouncer")
	await _use(JOEP, bouncer.global_position + Vector2(-20, 0), 1.0)
	await _tap("interact")
	_check(not bouncer.persuaded, "Joep can't talk the bouncer round")
	await _use(GEOFF, bouncer.global_position + Vector2(-20, 0), 1.0)
	await _tap("interact")
	_check(bouncer.persuaded, "Geoff persuades the bouncer")


func _test_beer() -> void:
	var beer = stage.get_node("Beer")
	var joep = await _use(JOEP, beer.global_position + Vector2(-20, 0), 1.0)
	Input.action_press("move_right")
	await _frames(15)
	Input.action_release("move_right")
	_check(joep.beers == 1 and beer.collected, "walking over a beer picks it up")
	joep.health.restore(2)
	await _tap("action_b")
	_check(joep.health.hp == 3 and joep.beers == 0, "B drinks it: +1 HP")
	_check(joep.ability.speed_mult() > 1.2, "Joep's beer bonus: quicker for 5 s")
	var nikki = await _use(NIKKI, Vector2(1520, GY), 1.0)
	var jay = band.members[JAY]
	_place(jay, Vector2(1530, GY))
	jay.health.restore(2)
	nikki.add_beer()
	await _frames(3)
	await _tap("action_b")
	_check(jay.health.hp == 3, "Nikki's beer heals Jay standing next to her")


# --- Helpers ---------------------------------------------------------------

## Switch to member `index`, put them at `pos` facing `facing`, others parked
## at the start (out of throw range and away from hazards).
func _use(index: int, pos: Vector2, facing: float):
	_release_all()
	await _await_idle()
	band.switch_to(index, true)
	for i in band.members.size():
		if i != index:
			_place(band.members[i], Vector2(130 + i * 18, GY))
	var m = band.members[index]
	_place(m, pos)
	m.facing = facing
	await _frames(3)
	return m


func _place(m, pos: Vector2) -> void:
	m.global_position = pos
	m.velocity = Vector2.ZERO


## Member walks right from x0 for up to 2 s; true if they pass x1 alive.
func _walks_past(index: int, x0: float, x1: float) -> bool:
	var m = await _use(index, Vector2(x0, GY), 1.0)
	Input.action_press("move_right")
	var ok := false
	for i in 120:
		await physics_frame
		if level.is_busy:
			break
		if m.global_position.x > x1:
			ok = true
			break
	Input.action_release("move_right")
	await _await_idle()
	return ok and not m.is_dead


## Hold right, jump (from the ground) at each x in `jumps`; true when past end_x on the floor.
func _run_and_jump(m, jumps: Array, end_x: float, max_frames: int) -> bool:
	var todo := jumps.duplicate()
	var hold := 0
	Input.action_press("move_right")
	var ok := false
	for i in max_frames:
		await physics_frame
		if hold > 0:
			hold -= 1
			if hold == 0:
				Input.action_release("jump")
		if not todo.is_empty() and m.global_position.x >= todo[0] and m.is_on_floor():
			todo.pop_front()
			Input.action_press("jump")
			hold = 20
		if m.global_position.x >= end_x and m.is_on_floor():
			ok = true
			break
	_release_all()
	return ok


func _await_idle() -> void:
	var n := 0
	while (level.is_busy or paused) and n < 600:
		await physics_frame
		n += 1


func _tap(action: String) -> void:
	Input.action_press(action)
	await physics_frame
	Input.action_release(action)
	await physics_frame


func _release_all() -> void:
	for a in ACTIONS:
		Input.action_release(a)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	print(("  ok   " if ok else "  FAIL ") + label)
	if not ok:
		failures += 1
