class_name GameFeel
extends RefCounted
## Small bits of juice: a puff of dust (landing, jumping), a short freeze on
## hits (hit-stop), and screen shake on the band's camera.

const HIT_STOP := 0.07                      # seconds the game freezes on a hit

static var _stopping := false


## Sounds and juice for a band member: jump (sound, a puff, a stretch), land
## (sound, dust, a squash; harder landings more), hurt (sound, hit-stop, shake).
static func hook_member(m: BandMember, parent: Node) -> void:
	m.jumped.connect(func() -> void:
		Audio.sfx(&"jump")
		dust(parent, m.global_position, 0.6)
		_squash(m, Vector2(0.86, 1.14)))
	m.landed.connect(func(fall_speed: float) -> void:
		if fall_speed < 120.0:
			return
		var hard := clampf(fall_speed / 600.0, 0.0, 1.0)
		Audio.sfx(&"land")
		dust(parent, m.global_position, 0.7 + hard)
		_squash(m, Vector2(1.0 + 0.2 * hard, 1.0 - 0.2 * hard)))
	m.health.damaged.connect(func(_amount: int) -> void:
		Audio.sfx(&"hit")
		hit_stop(m.get_tree())
		shake(m.get_tree(), 3.0, 0.2))


## Squash or stretch the sprite for a moment (relative to its own scale).
static func _squash(m: BandMember, k: Vector2) -> void:
	var s := m.sprite
	if not s.has_meta(&"base_scale") or not s.get_meta(&"squashing", false):
		s.set_meta(&"base_scale", s.scale)
	var base: Vector2 = s.get_meta(&"base_scale")
	s.set_meta(&"squashing", true)
	s.scale = base * k
	var tw := s.create_tween()
	tw.tween_property(s, "scale", base, 0.14).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_callback(func() -> void: s.set_meta(&"squashing", false))


## A puff of dust at `pos` (world), drawn by a short-lived node under `parent`.
static func dust(parent: Node, pos: Vector2, size := 1.0) -> void:
	if parent == null or not parent.is_inside_tree():
		return
	var d := DustPuff.new()
	d.position = pos
	d.size = size
	parent.add_child(d)


## Freeze the game for a moment (time scale ~0), then carry on.
static func hit_stop(tree: SceneTree, seconds := HIT_STOP) -> void:
	if _stopping or tree == null or DisplayServer.get_name() == "headless":
		return                              # (not in headless test runs: they count frames)
	_stopping = true
	Engine.time_scale = 0.05
	await tree.create_timer(seconds, true, false, true).timeout
	Engine.time_scale = 1.0
	_stopping = false


## Shake the active camera (strength in px, fades out over `time`).
static func shake(tree: SceneTree, strength := 3.0, time := 0.25) -> void:
	var cam := tree.root.get_viewport().get_camera_2d() if tree else null
	if cam and cam.has_method("shake"):
		cam.shake(strength, time)
