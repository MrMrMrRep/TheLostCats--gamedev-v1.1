extends SceneTree
## Headless checks for the band's base (exits 1 on failure): the whole band is
## there, the party board picks who goes out, at least one has to go, only the
## party comes along into a level, base upgrades show furniture.
## Run: Summer --headless --path . --script res://tests/test_base.gd
## Game classes stay untyped: naming them here would compile them before the
## autoloads exist in --script mode.

const EXPECTED_CHECKS := 8

var failures := 0
var checks := 0
var game


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	game = root.get_node("Game")
	var base = await _load("res://scenes/levels/base.tscn")
	_check(base.band.members.size() == 5, "everyone hangs out at the base (%d)" % base.band.members.size())
	var exit = base.find_child("BaseExit", true, false)
	_check(exit.target_scene == "res://scenes/world/world_map.tscn" and exit.target_spawn == &"StorageGate",
		"the base door leads back out to the storage gate")
	_check(not base.find_child("PosterTour", true, false).visible and base.find_child("Couch", true, false).visible,
		"base level 1: couch, fridge, instruments; upgrades hidden")

	var board = base.find_child("PartyBoard", true, false)
	board.interact(base.band.active, base)
	await _frames(2)
	var ui = base.get_children().filter(func(n): return n.get_script() and n.get_script().get_global_name() == &"PartySelect")
	_check(ui.size() == 1 and base.band.locked, "E at the board: the party choice opens (the band waits)")
	var sel = ui[0]
	for i in [2, 3, 4]:                         # Nikki, The Germ, Geoff stay home
		sel.toggle(i)
	sel.toggle(1)                               # Jay too...
	sel.toggle(0)                               # ...and Joep can't: someone has to go
	_check(sel._going == [&"joep"], "at least one has to go (%s)" % [sel._going])
	sel.toggle(1)                               # Jay goes after all
	sel.confirm()
	await _frames(2)
	_check(game.party == [&"joep", &"jay"] and not base.band.locked, "done: Joep and Jay go out (%s)" % [game.party])

	base.queue_free()
	await _frames(2)
	var level = await _load("res://scenes/levels/level_test.tscn")
	var ids: Array = level.band.members.map(func(m): return m.profile.id)
	_check(ids == [&"joep", &"jay"], "only the party comes into a level (%s)" % [ids])
	level.queue_free()
	await _frames(2)
	game.party.assign(game.MEMBERS)
	game.base_level = 2
	base = await _load("res://scenes/levels/base.tscn")
	_check(base.find_child("PosterTour", true, false).visible, "base level 2: the upgrade shows up")
	game.base_level = 1

	if checks != EXPECTED_CHECKS:
		print("  FAIL ran %d of %d checks (script error?)" % [checks, EXPECTED_CHECKS])
		failures += 1
	print("FAILURES: %d" % failures)
	quit(1 if failures > 0 else 0)


func _load(path: String):
	var scene = load(path).instantiate()
	root.add_child(scene)
	await _frames(5)
	return scene


func _frames(n: int) -> void:
	for i in n:
		await physics_frame


func _check(ok: bool, label: String) -> void:
	checks += 1
	print(("  ok   " if ok else "  FAIL ") + label)
	if not ok:
		failures += 1
