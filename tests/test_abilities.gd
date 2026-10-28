extends SceneTree
## Headless checks for the skill set on the abilities test level (exits 1 on
## failure): the moves everyone has (run, crouch, wall slide, punch + weapon),
## each member's special and instrument skill, every station's gate opening
## only for the right member and then letting the others through, Geoff's
## prices and the beer bonuses.
## Run: Summer --headless --path . --script res://tests/test_abilities.gd
## Game classes stay untyped: naming them here would compile them before the
## autoloads exist in --script mode.

const EXPECTED_CHECKS := 69
const GY := 288.0
const T := 24.0
const JOEP := 0
const JAY := 1
const NIKKI := 2
const GERM := 3
const GEOFF := 4
const ACTIONS := ["move_left", "move_right", "move_up", "move_down", "jump", "action_a", "action_b",
	"instrument", "sprint", "interact", "use_item"]

var failures := 0
var checks := 0
var deaths := []
var level
var band
var hall


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	level = load("res://scenes/levels/abilities_test.tscn").instantiate()
	root.add_child(level)
	await _frames(5)
	band = level.band
	hall = level.get_node("Rooms/Hall")
	level.member_died.connect(func(m, c): deaths.append("%s (%s)" % [m.profile.display_name, c]))

	await _test_basics()
	await _test_joep()
	await _test_jay()
	await _test_germ()
	await _test_nikki()
	await _test_geoff()
	await _test_beer()
	_check(deaths.is_empty(), "nobody died during the skill tests %s" % [deaths])

	if checks != EXPECTED_CHECKS:
		print("  FAIL ran %d of %d checks (script error?)" % [checks, EXPECTED_CHECKS])
		failures += 1
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


# --- Everyone ---------------------------------------------------------------

func _test_basics() -> void:
	# Run: Shift is faster than walking and costs stamina.
	var joep = await _use(JOEP, Vector2(60, GY), 1.0)
	Input.action_press("move_right")
	await _frames(12)
	var walk: float = joep.velocity.x
	Input.action_release("move_right")
	joep = await _use(JOEP, Vector2(60, GY), 1.0)
	Input.action_press("move_right")
	Input.action_press("sprint")
	await _frames(12)
	var run: float = joep.velocity.x
	_release_all()
	_check(run > walk * 1.25 and joep.running, "Shift runs: %.0f vs %.0f px/s walking" % [run, walk])
	_check(joep.stamina.current_stamina < joep.stamina.max_stamina, "running costs stamina")

	# Crouch: the low beam (x 192..288) stops you standing, not crouching.
	joep = await _use(JOEP, Vector2(150, GY), 1.0)
	Input.action_press("move_right")
	await _frames(40)
	Input.action_release("move_right")
	_check(joep.global_position.x < 190.0, "standing, the low beam blocks the way (x %.0f)" % joep.global_position.x)
	Input.action_press("move_down")
	await _frames(2)
	_check(joep.crouching and joep.get_node("Collision").shape.size.y < 15.0, "hold down: crouch to half height")
	Input.action_press("move_right")
	await _frames(25)
	Input.action_release("move_right")
	var crawl: float = joep.global_position.x
	Input.action_release("move_down")
	await _frames(3)
	_check(joep.crouching and crawl > 192.0, "under the beam you stay down even when letting go")
	Input.action_press("move_down")
	Input.action_press("move_right")
	await _frames(60)
	_release_all()
	await _frames(3)
	_check(joep.global_position.x > 290.0 and not joep.crouching, "crawled through and stood up (x %.0f)" % joep.global_position.x)

	# Wall slide against the beam's face.
	joep = await _use(JOEP, Vector2(180, 100), 1.0)
	Input.action_press("move_right")
	await _frames(30)
	_check(joep.wall_sliding and joep.velocity.y <= 41.0, "wall slide: %.0f px/s down the beam" % joep.velocity.y)
	_release_all()
	await _frames(40)

	# Punch: knocks a rat back. With the mic stand it knocks it out.
	var rat = hall.get_node("PenRat")
	rat.reset_state()
	rat.global_position = Vector2(500, GY)
	rat.stun(3.0)
	var jay = await _use(JAY, Vector2(482, GY), 1.0)
	await _tap("action_a")
	await _frames(2)
	_check(rat.alive and rat.stunned_left > 0.0 and rat.velocity.x > 0.0, "a punch knocks the rat back")
	jay.add_item(load("res://resources/items/mic_stand.tres"))
	jay.inventory.selected = jay.inventory.index_of(&"mic_stand")
	rat.reset_state()
	rat.global_position = Vector2(505, GY)
	rat.stun(3.0)
	_place(jay, Vector2(470, GY))
	await _frames(25)                       # the punch cooldown
	await _tap("action_a")
	_check(not rat.alive, "with the mic stand selected, the punch knocks it out (longer reach)")
	jay.inventory.clear()
	rat.reset_state()


# --- Joep ---------------------------------------------------------------------

func _test_joep() -> void:
	var elec = hall.get_node("ElectricFloor")
	var panel = hall.get_node("HackPanel")
	await _use(JAY, Vector2(800, GY), 1.0)
	await _tap("action_b")
	_check(elec.enabled and not panel.used, "Jay can't hack the wall plug")
	var joep = await _use(JOEP, Vector2(800, GY), 1.0)
	await _tap("action_b")
	await _frames(2)
	_check(panel.used and not elec.enabled, "Joep hacks the wall plug: the panel up high switches the floor off")
	_check(await _walks_past(GEOFF, 920.0, 1160.0), "Geoff walks over the dead electric floor")

	# The camera: walking into view shuts the gate.
	var cam = hall.get_node("Camera")
	var gate = hall.get_node("CameraGate")
	await _use(GEOFF, Vector2(1240, GY), 1.0)
	await _frames(3)
	_check(cam.tripped and gate.solid, "walk into the camera's view: ALARM, the gate shuts")
	cam.reset_state()
	gate.reset_state()
	# Too high for a hack; the shockwave reaches it.
	joep = await _use(JOEP, Vector2(1160, GY), 1.0)
	await _tap("action_b")
	_check(cam.active, "Joep's hack doesn't reach the camera up there")
	var near_rat = _spawn_rat(Vector2(1190, GY))
	var far_rat = _spawn_rat(Vector2(1290, GY))
	near_rat.stun(5.0)
	far_rat.stun(0.1)
	await _frames(8)
	joep.stamina.refill()
	await _tap("instrument")
	_check(not cam.active, "the shockwave switches the camera off")
	_check(not near_rat.alive and far_rat.alive and far_rat.stunned_left > 1.0, "shockwave: rat close by out, rat further away shocked")
	_check(joep.stamina.current_stamina < joep.stamina.max_stamina and not joep.ability.instrument_ready(), "the instrument costs stamina and needs a moment")
	near_rat.queue_free()
	far_rat.queue_free()
	_check(await _walks_past(GEOFF, 1170.0, 1380.0) and not gate.solid, "camera off: Geoff walks under it, the gate stays open")

	# The amp: hacked, it blares and stuns rats around it.
	var amp = hall.get_node("Amp")
	var rat = _spawn_rat(Vector2(1470, GY))
	joep = await _use(JOEP, Vector2(1388, GY), 1.0)
	await _tap("action_b")
	await _frames(3)
	_check(amp.blare_left > 0.0 and rat.stunned_left > 0.0, "Joep hacks the amp: it blares and stuns the rat")
	rat.queue_free()
	await _frames(250)


# --- Jay ----------------------------------------------------------------------

func _test_jay() -> void:
	var glass = hall.get_node("GlassWall")
	await _use(GERM, Vector2(1524, GY), 1.0)
	await _tap("action_a")
	_check(not glass.is_broken, "a punch doesn't break the glass")
	var jay = await _use(JAY, Vector2(1480, GY), 1.0)
	jay.stamina.refill()
	await _tap("instrument")
	await _frames(2)
	_check(glass.is_broken, "Jay's slap bass shatters the glass from 3 tiles away")
	_check(await _walks_past(GEOFF, 1500.0, 1600.0), "Geoff walks through where the glass was")

	var case = hall.get_node("FlightCase")
	var x0: float = case.global_position.x
	await _use(GEOFF, Vector2(x0 - 20.0, GY), 1.0)
	Input.action_press("move_right")
	await _frames(30)
	Input.action_release("move_right")
	_check(absf(case.global_position.x - x0) < 1.0, "Geoff can't move the flight case")
	jay = await _use(JAY, Vector2(x0 - 20.0, GY), 1.0)
	Input.action_press("move_right")
	await _frames(30)
	Input.action_release("move_right")
	_check(case.global_position.x > x0 + 12.0, "Jay pushes it (%.0f px)" % (case.global_position.x - x0))
	# Lift and throw.
	await _frames(20)                       # let the case come to rest
	jay.stamina.refill()
	_place(jay, case.global_position + Vector2(-19, 0))
	await _frames(3)
	await _tap("action_b")
	await _frames(20)
	_check(jay.ability.carrying == case and case.global_position.y < jay.global_position.y - 25.0
		and jay.stamina.current_stamina < jay.stamina.max_stamina, "Jay lifts the case over his head (costs stamina)")
	var x1: float = case.global_position.x
	await _tap("action_b")
	await _frames(80)
	_check(jay.ability.carrying == null and case.global_position.x > x1 + 60.0 and case.is_on_floor(),
		"and throws it %.1f tiles" % ((case.global_position.x - x1) / T))
	# The case as a step up the 2-tile ledge (x 1848).
	case.global_position = Vector2(1835, GY)
	await _frames(3)
	var geoff = await _use(GEOFF, Vector2(1780, GY), 1.0)
	var up := await _run_and_jump(geoff, [1806.0, 1832.0], 1880.0, 200)
	_check(up and geoff.global_position.y < GY - 47.0, "with the case as a step Geoff gets up the 2-tile ledge")
	# Throw a mate up.
	await _use(JAY, Vector2(1700, GY), 1.0)
	_place(band.members[GEOFF], Vector2(1710, GY))
	await _frames(3)
	var y0: float = band.members[GEOFF].global_position.y
	await _tap("action_b")
	var peak := y0
	for i in 60:
		await physics_frame
		peak = minf(peak, band.members[GEOFF].global_position.y)
	_check((y0 - peak) / T > 3.8, "Jay throws Geoff %.1f tiles up" % ((y0 - peak) / T))
	await _frames(40)
	# The bass bubble: Geoff walks over the spikes unhurt.
	jay = await _use(JAY, Vector2(1905, 240), 1.0)
	geoff = band.members[GEOFF]
	_place(geoff, Vector2(1920, 240))
	geoff.health.restore(1)
	jay.stamina.refill()
	await _frames(3)
	var rat = _spawn_rat(Vector2(1990, 240))
	rat.stun(0.1)
	await _frames(8)
	await _tap("instrument")
	await _frames(2)
	_check(geoff.shield_left > 2.0 and jay.shield_left > 2.0, "slap bass: a defence bubble for Jay and Geoff next to him")
	_check(rat.stunned_left > 0.0 and rat.velocity.x > 0.0, "slap bass knocks the rat back")
	rat.queue_free()
	band.switch_to(GEOFF, true)
	Input.action_press("move_right")
	await _frames(40)
	Input.action_release("move_right")
	_check(geoff.health.hp == 1 and geoff.global_position.x > 2000.0, "in the bubble Geoff walks over the spikes unhurt")
	await _frames(150)


# --- The Germ -------------------------------------------------------------------

func _test_germ() -> void:
	var crates = hall.get_node("Crates")
	await _use(JOEP, Vector2(2240, GY), 1.0)
	await _tap("action_a")
	_check(not crates.is_broken, "a normal punch doesn't break the crates")
	var germ = await _use(GERM, Vector2(2200, GY), 1.0)
	germ.stamina.refill()
	await _tap("action_b")
	await _frames(20)
	_check(crates.is_broken, "The Germ's rage punch smashes the crates")
	_check(germ.stamina.current_stamina < germ.stamina.max_stamina, "the rage punch costs stamina")
	var rat = hall.get_node("Rat1")
	rat.reset_state()
	rat.global_position = Vector2(2360, GY)
	rat.stun(5.0)
	var x0 := 2290.0
	germ = await _use(GERM, Vector2(x0, GY), 1.0)
	germ.stamina.refill()
	await _tap("action_b")
	await _frames(20)
	_check(not rat.alive and germ.global_position.x > x0 + 60.0, "he charges %.1f tiles, straight through the rat" % ((germ.global_position.x - x0) / T))
	# Slam from the air: the cracked slab.
	var slab = hall.get_node("CrackedSlab")
	germ = await _use(GERM, Vector2(slab.global_position.x, 200), 1.0)
	germ.stamina.refill()
	await _tap("action_b")
	await _frames(30)
	_check(slab.is_broken, "in the air it's a slam: the cracked slab breaks")

	# The timed gate: too quick for anyone...
	var lever = hall.get_node("GateLever")
	var gate = hall.get_node("TimedGate")
	var geoff = await _use(GEOFF, lever.global_position, 1.0)
	await _tap("interact")
	_check(not gate.solid, "the lever opens the timed gate")
	Input.action_press("move_right")
	await _frames(120)
	Input.action_release("move_right")
	_check(gate.solid and geoff.global_position.x < gate.global_position.x, "it slams shut before Geoff gets there")
	lever.reset_state()
	# ...unless The Germ stops time.
	var rat2 = hall.get_node("Rat2")
	rat2.reset_state()
	var plat = hall.get_node("MovingPlatform")
	germ = await _use(GERM, lever.global_position, 1.0)
	germ.stamina.refill()
	await _frames(30)                       # some history for the rewind
	await _tap("interact")
	await _tap("instrument")
	var tc = level.time_control
	var rat_x: float = rat2.global_position.x
	var plat_x: float = plat.global_position.x
	await _frames(60)
	_check(tc.mode == 1 and not gate.solid, "Drumbeat Master: time stops, the gate stays open")
	_check(rat2.global_position.x == rat_x and plat.global_position.x == plat_x, "rats and the moving platform freeze too")
	_check(await _walks_past(GEOFF, gate.global_position.x - 60.0, gate.global_position.x + 30.0), "Geoff walks through the frozen-open gate")
	band.switch_to(GERM, true)
	await _frames(2)
	await _tap("instrument")
	await _frames(20)
	_check(tc.mode == 2 and absf(rat2.global_position.x - rat_x) > 2.0, "L again: rewind (the rat walks backwards %.0f px)" % absf(rat2.global_position.x - rat_x))
	await _tap("instrument")
	await _frames(2)
	_check(tc.mode == 0, "L once more: play")
	await _frames(60)
	_check(gate.solid, "time runs again: the gate shuts")


# --- Nikki ----------------------------------------------------------------------

func _test_nikki() -> void:
	# Grapple across the 8-tile pit (x 3216..3408), hook at x 3312.
	var nikki = await _use(NIKKI, Vector2(3190, GY), 1.0)
	await _tap("action_b")
	_check(not nikki.ability.swinging, "no hook in reach from back there: no grapple")
	nikki = await _use(NIKKI, Vector2(3150, GY), 1.0)
	Input.action_press("move_right")
	Input.action_press("sprint")
	var grabbed := false
	var released := false
	for i in 300:
		await physics_frame
		if level.is_busy:
			break
		if not grabbed and nikki.global_position.x >= 3205.0 and nikki.is_on_floor():
			Input.action_press("jump")
		if not grabbed and nikki.velocity.y > -40.0 and not nikki.is_on_floor() and nikki.global_position.x > 3215.0:
			Input.action_release("jump")
			await _tap("action_b")
			grabbed = nikki.ability.swinging
		if grabbed and not released and nikki.ability.swinging and nikki.global_position.x > 3330.0 and nikki.velocity.y < 0.0:
			await _tap("jump")
			released = true
		if released and nikki.is_on_floor():
			break
	_release_all()
	_check(grabbed, "Nikki's grapple catches the hook over the pit")
	_check(not level.is_busy and nikki.global_position.x > 3408.0 and nikki.is_on_floor(), "she swings and lets go: across the pit (x %.0f)" % nikki.global_position.x)
	await _await_idle()

	# The guitar solo bridge: Geoff walks across.
	nikki = await _use(NIKKI, Vector2(3205, GY), 1.0)
	nikki.stamina.refill()
	await _tap("instrument")
	var bridges: Array = level.get_tree().get_nodes_in_group(&"note_bridge")
	_check(bridges.size() == 1, "guitar solo: a bridge of notes over the pit")
	var geoff = await _use(GEOFF, Vector2(3195, GY), 1.0)
	var across := await _run_and_jump(geoff, [3368.0], 3430.0, 240)
	_check(across and not level.is_busy, "Geoff crosses on it (x %.0f)" % geoff.global_position.x)
	await _await_idle()
	await _frames(500)
	_check(level.get_tree().get_nodes_in_group(&"note_bridge").is_empty(), "the bridge fades after a few seconds")

	# Up held: a ramp over the 5-tile wall (x 3600).
	nikki = await _use(NIKKI, Vector2(3412, GY), 1.0)
	nikki.stamina.refill()
	Input.action_press("move_up")
	await _tap("instrument")
	Input.action_release("move_up")
	var ramp: Array = level.get_tree().get_nodes_in_group(&"note_bridge")
	_check(ramp.size() == 1 and ramp[0].rotation < -0.5, "up + solo: a ramp of notes going up")
	geoff = await _use(GEOFF, Vector2(3414, GY), 1.0)
	var over := await _run_and_jump(geoff, [], 3680.0, 420)
	_check(over, "Geoff walks up the ramp and over the 5-tile wall (x %.0f)" % geoff.global_position.x)


# --- Geoff ----------------------------------------------------------------------

func _test_geoff() -> void:
	var bouncer = hall.get_node("Bouncer")
	var security = hall.get_node("Security")
	var sound = hall.get_node("SoundGuy")
	var rat = hall.get_node("Rat")
	# The charm doesn't work on rats.
	rat.reset_state()
	rat.global_position = Vector2(3880, GY)
	rat.stun(5.0)
	var geoff = await _use(GEOFF, Vector2(3860, GY), 1.0)
	geoff.stamina.refill()
	await _tap("instrument")
	_check(geoff.stamina.current_stamina == geoff.stamina.max_stamina and rat.alive, "Geoff can't charm a rat (nothing spent)")
	# Talking: only Geoff gets past the bouncer.
	await _use(JOEP, bouncer.global_position + Vector2(-20, 0), 1.0)
	await _tap("interact")
	_check(not bouncer.persuaded, "the bouncer turns Joep away")
	geoff = await _use(GEOFF, bouncer.global_position + Vector2(-56, 0), 1.0)
	geoff.stamina.refill()
	await _tap("instrument")
	_check(bouncer.persuaded and geoff.stamina.current_stamina < geoff.stamina.max_stamina, "the voice and the charm: the bouncer steps aside (from 2 tiles)")
	# Bubbles: security drifts after them, the bouncer and rats don't care.
	rat.reset_state()
	rat.global_position = Vector2(4140, GY)
	rat.stun(10.0)                          # stunned rats don't bite either
	bouncer.reset_state()
	geoff = await _use(GEOFF, Vector2(4110, GY), 1.0)
	await _tap("action_b")
	await _frames(20)
	_check(security.distracted_left > 0.0 and bouncer.distracted_left == 0.0, "bubbles: security can't look away, the bouncer can")
	_check(rat.distracted_left == 0.0, "bubbles don't distract rats")
	_check(await _walks_past(GEOFF, 4140.0, 4200.0), "Geoff slips past the distracted security guard")
	rat.reset_state()
	rat.global_position = Vector2(3840, GY)
	# The sound guy.
	geoff = await _use(GEOFF, sound.global_position + Vector2(-40, 0), 1.0)
	await _frames(190)                      # the instrument cooldown
	geoff.stamina.refill()
	await _tap("instrument")
	_check(sound.persuaded, "the grumpy sound guy lets Geoff through")
	# Prices: the tip jar, then a beer at the bar.
	var game = root.get_node("Game")
	game.coins = 0
	await _walks_past(JOEP, 4340.0, 4390.0)
	_check(game.coins == 20, "the tip jar: +20 coins")
	var bar = hall.get_node("Bar")
	var joep = await _use(JOEP, bar.global_position, 1.0)
	joep.inventory.clear()
	await _frames(2)
	await _tap("interact")
	_check(game.coins == 10 and joep.beers == 1, "Joep buys a beer: 10 coins")
	geoff = await _use(GEOFF, bar.global_position, 1.0)
	geoff.inventory.clear()
	await _frames(2)
	await _tap("interact")
	_check(game.coins == 3 and geoff.beers == 1, "Geoff buys one: 7 coins (better prices)")
	geoff.inventory.clear()
	joep.inventory.clear()
	# The staff-only door.
	var staff = hall.get_node("StaffDoor")
	await _use(JOEP, staff.global_position, 1.0)
	await _tap("interact")
	_check(staff.locked and level.room_of_member(band.active) == hall, "STAFF ONLY: Joep can't get in")
	geoff = await _use(GEOFF, staff.global_position + Vector2(-30, 0), 1.0)
	await _frames(190)
	geoff.stamina.refill()
	await _tap("instrument")
	_check(not staff.locked, "Geoff charms the staff door open")


# --- Beer -------------------------------------------------------------------------

func _test_beer() -> void:
	var joep = await _use(JOEP, Vector2(4700, GY), 1.0)
	joep.inventory.clear()
	joep.add_beer()
	joep.health.restore(2)
	await _tap("action_b")
	_check(joep.beers == 1, "K is Joep's hack now, not a drink")
	await _tap("use_item")
	_check(joep.health.hp == 3 and joep.beers == 0, "R drinks the beer: +1 HP")
	_check(joep.ability.speed_mult() > 1.2, "Joep's beer bonus: quicker for 5 s")
	var nikki = await _use(NIKKI, Vector2(4680, GY), 1.0)
	var jay = band.members[JAY]
	_place(jay, Vector2(4690, GY))
	jay.health.restore(2)
	nikki.inventory.clear()
	nikki.add_beer()
	await _frames(3)
	await _tap("use_item")
	_check(jay.health.hp == 3, "Nikki's beer heals Jay standing next to her")


# --- Helpers ---------------------------------------------------------------------

## Switch to member `index`, put them at `pos` facing `facing`; the others are
## parked at the start, out of the way.
func _use(index: int, pos: Vector2, facing: float):
	_release_all()
	await _await_idle()
	band.switch_to(index, true)
	for i in band.members.size():
		if i != index:
			_place(band.members[i], Vector2(40 + i * 8, GY))
	var m = band.members[index]
	_place(m, pos)
	m.facing = facing
	await _frames(3)
	return m


func _place(m, pos: Vector2) -> void:
	m.global_position = pos
	m.velocity = Vector2.ZERO


func _spawn_rat(pos: Vector2):
	var rat = load("res://scripts/enemies/rat.gd").new()
	hall.add_child(rat)
	rat.global_position = pos
	return rat


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
		if level.is_busy:
			break
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
