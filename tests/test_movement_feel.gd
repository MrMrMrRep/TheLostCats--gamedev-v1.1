extends SceneTree
## Headless checks for the M3 feel kit and stamina (exits 1 on failure).
## Run: Summer --headless --path . --script res://tests/test_movement_feel.gd

const TILE := 24.0
const GROUND_Y := 288.0                     # movement_test.tscn ground surface
const ACTIONS := ["move_left", "move_right", "move_down", "jump"]

var failures := 0
var checks := 0
const EXPECTED_CHECKS := 26          # a crashed check must not look like a pass
var player   # BandMember (untyped: see test_band.gd)
var profiles := {}


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var room: Node = load("res://scenes/dev/movement_test.tscn").instantiate()
	root.add_child(room)
	await physics_frame
	player = room.get_node("Band").active
	for id in ["joep", "jay", "nikki", "germ", "geoff"]:
		profiles[id] = load("res://resources/profiles/%s.tres" % id)
	await _frames(5)

	await _test_jump_heights()
	await _test_variable_jump()
	await _test_coyote_time()
	await _test_jump_buffer()
	await _test_corner_correction()
	await _test_one_way()
	await _test_fast_fall()
	await _test_gating()
	await _test_stamina()

	if checks != EXPECTED_CHECKS:
		print("  FAIL ran %d of %d checks (script error?)" % [checks, EXPECTED_CHECKS])
		failures += 1
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


# --- Movement --------------------------------------------------------------

func _test_jump_heights() -> void:
	print("jump height per member (held jump):")
	for id in profiles:
		await _reset(Vector2(72, GROUND_Y), profiles[id])
		var h := await _measure_jump(-1)
		var want: float = profiles[id].jump_height_tiles
		_check(absf(h - want) < 0.15, "%s jumps %.2f tiles (profile %.1f)" % [id, h, want])


func _test_variable_jump() -> void:
	await _reset(Vector2(72, GROUND_Y), profiles.joep)
	var full := await _measure_jump(-1)
	await _reset(Vector2(72, GROUND_Y), profiles.joep)
	var tap := await _measure_jump(2)
	_check(tap < full * 0.5 and tap > 0.3, "tap jump %.2f tiles vs held %.2f (short hop)" % [tap, full])


func _test_coyote_time() -> void:
	# Run off the 4-tile ledge (top y=192, right edge x=576) and jump late.
	for late in [4, 9]:
		await _reset(Vector2(560, 192), profiles.joep)
		Input.action_press("move_right")
		var guard := 0
		while player.is_on_floor() and guard < 60:
			await physics_frame
			guard += 1
		await _frames(late - 1)
		Input.action_press("jump")
		await _frames(2)
		var jumped = player.velocity.y < -200.0
		_release_all()
		if late == 4:
			_check(jumped, "coyote: jump %d frames (%.0f ms) after leaving the ledge works" % [late, late * 16.7])
		else:
			_check(not jumped, "coyote: jump %d frames (%.0f ms) late does not fire" % [late, late * 16.7])


func _test_jump_buffer() -> void:
	# Press jump N frames before landing from a drop; the jump fires on landing.
	for early in [5, 12]:
		await _reset(Vector2(72, 100), profiles.joep)
		var guard := 0
		while GROUND_Y - player.global_position.y > player.velocity.y / 60.0 * early and guard < 200:
			await physics_frame
			guard += 1
		Input.action_press("jump")          # held through the landing, like a player would
		var rose := false
		for i in early + 6:
			await physics_frame
			if player.velocity.y < -200.0:
				rose = true
		Input.action_release("jump")
		if early == 5:
			_check(rose, "buffer: jump pressed %d frames before landing still jumps" % early)
		else:
			_check(not rose, "buffer: jump pressed %d frames early is dropped" % early)


func _test_corner_correction() -> void:
	# Ceiling slab y 216..240 with a hole at x 1320..1344. Body is 12 px wide,
	# so x 1326..1338 fits cleanly. A bonk stops the rise at ~20 px.
	await _reset(Vector2(1323, GROUND_Y), profiles.joep)
	var rise := await _measure_jump(-1) * TILE
	_check(rise > 60.0, "corner correction: 3 px off slips through the hole (rise %.0f px)" % rise)
	await _reset(Vector2(1316, GROUND_Y), profiles.joep)
	rise = await _measure_jump(-1) * TILE
	_check(rise < 30.0, "no correction beyond 4 px: 10 px off bonks (rise %.0f px)" % rise)


func _test_one_way() -> void:
	# One-way platform x 1488..1560, top y=240.
	await _reset(Vector2(1524, GROUND_Y), profiles.joep)
	await _jump_and_settle()
	_check(absf(player.global_position.y - 240.0) < 1.0 and player.is_on_floor(), "jumps up through a one-way platform and lands on it")
	Input.action_press("move_down")
	Input.action_press("jump")
	await physics_frame
	Input.action_release("jump")
	await _frames(40)
	Input.action_release("move_down")
	_check(player.global_position.y > GROUND_Y - 1.0, "down + jump drops through (y=%.0f)" % player.global_position.y)


func _test_fast_fall() -> void:
	await _reset(Vector2(1000, -400), profiles.joep)
	await _frames(60)
	var normal = player.velocity.y / TILE
	await _reset(Vector2(1000, -400), profiles.joep)
	Input.action_press("move_down")
	await _frames(60)
	var fast = player.velocity.y / TILE
	_release_all()
	_check(absf(normal - 18.0) < 0.1 and absf(fast - 26.0) < 0.1, "fall speed %.1f t/s, fast fall %.1f t/s" % [normal, fast])


func _test_gating() -> void:
	# 2-tile ledge at x 288..336: Jay (2 tiles) makes it, The Germ (1.5) doesn't.
	for id in ["jay", "germ"]:
		await _reset(Vector2(270, GROUND_Y), profiles[id])
		Input.action_press("move_right")
		Input.action_press("jump")
		var on_top := false
		for i in 45:
			await physics_frame
			if player.is_on_floor() and player.global_position.y < GROUND_Y - 2 * TILE + 1.0:
				on_top = true
		_release_all()
		if id == "jay":
			_check(on_top, "gating: Jay (2.3 tiles) climbs the 2-tile ledge")
		else:
			_check(not on_top, "gating: The Germ (1.3 tiles) can't climb the 2-tile ledge")


# --- Stamina ---------------------------------------------------------------

func _test_stamina() -> void:
	var cfg: StaminaConfig = load("res://resources/config/stamina_config.tres")
	var s := StaminaComponent.new()
	root.add_child(s)
	var events := []
	s.exhausted.connect(func(): events.append("exhausted"))
	s.recovered.connect(func(): events.append("recovered"))
	s.settings = cfg.for_member(&"nikki")

	_check(s.try_spend(30.0) and is_equal_approx(s.current_stamina, 70.0), "try_spend(30) succeeds: 70 left")
	_check(not s.try_spend(80.0), "try_spend(80) fails with 70 left")
	s.spend(100.0)
	_check(s.is_exhausted and events == ["exhausted"], "spending to 0 sets exhausted and emits once")
	_check(not s.try_spend(1.0), "try_spend fails while exhausted")

	s.grounded = false
	await _frames(20)                       # 0.33 s < regen_delay 0.5 s
	_check(s.current_stamina == 0.0, "no regen during regen_delay")
	await _frames(40)                       # ~0.5 s of air regen at 30/s
	var air := s.current_stamina
	_check(air > 10.0 and air < 20.0 and s.is_exhausted, "air regen ~30/s, still exhausted below 20 (%.1f)" % air)
	s.grounded = true
	await _frames(30)                       # 0.5 s of ground regen at 60/s
	_check(s.current_stamina - air > 25.0, "ground regen is faster (+%.1f in 0.5 s)" % (s.current_stamina - air))
	_check(not s.is_exhausted and events == ["exhausted", "recovered"], "recovers above the threshold and emits recovered")

	s.settings = cfg.for_member(&"geoff")
	_check(not s.enabled and not s.try_spend(1.0), "Geoff has no stamina pool")
	s.queue_free()


# --- Helpers ---------------------------------------------------------------

func _reset(pos: Vector2, profile: MovementProfile) -> void:
	_release_all()
	player.profile = profile
	player.global_position = pos
	player.velocity = Vector2.ZERO
	await _frames(3)
	if pos.y >= 0.0 and pos.y <= GROUND_Y:
		var guard := 0
		while not player.is_on_floor() and guard < 120 and pos.y > 200.0:
			await physics_frame
			guard += 1


## Jump in place; hold_frames < 0 holds jump until landing. Returns height in tiles.
func _measure_jump(hold_frames: int) -> float:
	var start = player.global_position.y
	var peak = start
	Input.action_press("jump")
	var t := 0
	while t < 150:
		await physics_frame
		t += 1
		if hold_frames >= 0 and t == hold_frames:
			Input.action_release("jump")
		peak = minf(peak, player.global_position.y)
		if t > 3 and player.is_on_floor():
			break
	Input.action_release("jump")
	return (start - peak) / TILE


func _jump_and_settle() -> void:
	Input.action_press("jump")
	await _frames(60)
	Input.action_release("jump")
	await _frames(20)


func _release_all() -> void:
	for a in ACTIONS:
		Input.action_release(a)


func _frames(n: int) -> void:
	for i in maxi(n, 0):
		await physics_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	print(("  ok   " if ok else "  FAIL ") + label)
	if not ok:
		failures += 1
