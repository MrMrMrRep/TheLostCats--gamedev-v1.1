extends SceneTree
## Headless movement check for the M2 baseline (exits 1 on failure).
## Run: Summer --headless --path . --script res://tests/test_baseline_movement.gd

const TILE := 24.0
var failures := 0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var level: Node = load("res://scenes/dev/baseline.tscn").instantiate()
	root.add_child(level)
	var player: CharacterBody2D = level.get_node("Player")
	var sprite: AnimatedSprite2D = player.get_node("Sprite")
	await _frames(10)
	var ground_y := player.position.y
	_check(player.is_on_floor(), "starts on the floor")
	_check(sprite.animation == &"idle", "idle animation at rest (got %s)" % sprite.animation)

	# --- Jump in place (held): measure apex height and time to apex.
	Input.action_press("jump")
	var t := 0.0
	var peak := ground_y
	var apex_time := 0.0
	var seen := {}
	while t < 2.0:
		await physics_frame
		t += 1.0 / 60.0
		seen[sprite.animation] = true
		if player.position.y < peak:
			peak = player.position.y
			apex_time = t
		if player.is_on_floor() and t > 0.1:
			break
	Input.action_release("jump")
	var height_tiles := (ground_y - peak) / TILE
	print("jump: %.2f tiles, apex %.3f s, airtime %.3f s, anims %s" % [height_tiles, apex_time, t, seen.keys()])
	var profile: MovementProfile = player.profile
	_check(absf(height_tiles - profile.jump_height_tiles) < 0.15, "jump height ~%.1f tiles" % profile.jump_height_tiles)
	# Apex hang (jump held) stretches the top of the arc a little.
	_check(apex_time >= profile.time_to_apex - 0.02 and apex_time < profile.time_to_apex + 0.08, "time to apex ~%.2f s (+ apex hang)" % profile.time_to_apex)
	_check(t - apex_time < apex_time, "fall is faster than rise (%.2f s down vs %.2f s up)" % [t - apex_time, apex_time])
	_check(seen.has(&"jump_start") and seen.has(&"jump") and seen.has(&"fall"), "jump_start, jump, fall animations play")

	# --- Run right: time to top speed, run animation, facing.
	await _frames(20)
	Input.action_press("move_right")
	var accel_frames := 0
	while player.velocity.x < profile.run_speed() - 0.5 and accel_frames < 60:
		await physics_frame
		accel_frames += 1
	print("run: top speed %.1f px/s after %d frames" % [player.velocity.x, accel_frames])
	_check(accel_frames <= 6, "reaches top speed within 0.1 s")
	await _frames(5)
	_check(sprite.animation == &"run", "run animation while running")
	_check(not sprite.flip_h, "faces right")
	await _frames(60)
	_check(player.position.x < 14 * TILE, "1-tile step blocks running (x=%.1f)" % player.position.x)
	Input.action_release("move_right")

	# --- Turn left: sprite flips, stops in decel time.
	Input.action_press("move_left")
	await _frames(10)
	_check(sprite.flip_h, "faces left when moving left")
	Input.action_release("move_left")
	await _frames(6)
	_check(absf(player.velocity.x) < 1.0, "stops within 0.1 s after release")

	# --- Jump onto the 1-tile step (cols 14, x 336..360): release right once above it.
	Input.action_press("move_right")
	Input.action_press("jump")
	var guard := 0
	while player.position.x < 340.0 and guard < 120:
		await physics_frame
		guard += 1
	Input.action_release("move_right")
	Input.action_release("jump")
	await _frames(40)
	_check(player.is_on_floor() and player.position.y < ground_y - TILE + 1.0, "jumped onto the 1-tile step (y=%.1f)" % player.position.y)

	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _check(ok: bool, label: String) -> void:
	print(("  ok   " if ok else "  FAIL ") + label)
	if not ok:
		failures += 1
