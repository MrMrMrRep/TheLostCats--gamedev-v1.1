@tool
class_name WorldPedestrians
extends Node2D
## People walking along the street, at band scale (an adult is ~27 world px,
## like Joep; kids ~19), drawn at the band sprites' density. Kept around the
## camera only. Two sides of the street, for depth:
##   BACK   the pavement by the facades: behind the band, 0.94 size, a touch hazy
##   FRONT  the quay side: in front of the band (they walk past/through us)
## How busy each district is comes from the Zone nodes (WorldZone, "people
## per screen"); speeds etc. from resources/config/people_config.tres. Never in
## the countryside. Origin = street line.

enum Side { BACK, FRONT }

const SIDE_Y := {Side.BACK: 1.0, Side.FRONT: 5.0}   # both on the pavement (the band walks between, at 3)
const SKIN := [WorldPalette.W3, WorldPalette.B4, WorldPalette.B3, WorldPalette.W1, WorldPalette.W0]
const HAIR := [WorldPalette.T0, WorldPalette.W0, WorldPalette.W2, WorldPalette.B1, WorldPalette.G4, WorldPalette.T0]
const SHIRTS := [WorldPalette.B2, WorldPalette.T1, WorldPalette.W5, WorldPalette.G0, WorldPalette.O2, WorldPalette.P0, WorldPalette.W0, WorldPalette.B3, WorldPalette.R2]
const PANTS := [WorldPalette.T0, WorldPalette.W0, WorldPalette.P0, WorldPalette.T0, WorldPalette.R2]

@export var side := Side.BACK
var busy: Array[Vector3] = []               # (x0, x1, people per screen width), from the zones

var _people: Array = []                     # dictionaries: x, dir, speed, look, phase, kid, extra
var _rng := RandomNumberGenerator.new()


func _ready() -> void:
	_rng.seed = 21 + side
	busy.clear()
	for z in WorldZone.all(self):
		var r := z.span()
		busy.append(Vector3(r.x, r.y, z.people_per_screen))


func density_at(x: float) -> float:
	for b in busy:
		if x >= b.x and x <= b.y:
			return b.z * PeopleConfig.current().busy_scale
	return 0.0


func _view() -> Vector2:
	var cam := get_viewport().get_camera_2d() if is_inside_tree() else null
	if cam == null:
		return Vector2(0, 640)
	var half := ScreenFit.width(self) / 2.0 / cam.zoom.x + 60.0
	var cx := cam.get_screen_center_position().x
	return Vector2(cx - half, cx + half)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var view := _view()
	var span := view.y - view.x
	var cfg := PeopleConfig.current()
	for p in _people:
		p.x += p.dir * p.speed * delta
		p.phase += p.speed * delta
		if p.pause > 0.0:                    # window shopping
			p.pause -= delta
			p.x -= p.dir * p.speed * delta
			p.phase -= p.speed * delta
		elif _rng.randf() < delta * cfg.stop_chance:
			p.pause = _rng.randf_range(cfg.stop_length.x, cfg.stop_length.y)
	_people = _people.filter(func(p: Dictionary) -> bool:
		return p.x > view.x - span * 0.5 and p.x < view.y + span * 0.5 and density_at(p.x) > 0.0)
	var want := int(round(span / 640.0 * density_at((view.x + view.y) / 2.0)))
	if _people.size() < want:
		_spawn(view)
	queue_redraw()


func _spawn(view: Vector2) -> void:
	var dir := 1.0 if _rng.randf() < 0.5 else -1.0
	var x := view.x - 20.0 if dir > 0.0 else view.y + 20.0
	if _people.is_empty() or _rng.randf() < 0.3:
		x = _rng.randf_range(view.x, view.y)
	if density_at(x) <= 0.0:
		return
	var cfg := PeopleConfig.current()
	var kid := _rng.randf() < cfg.kids
	_people.append({
		"x": x, "dir": dir, "speed": _rng.randf_range(cfg.walk_speed.x, cfg.walk_speed.y) * (cfg.kid_speed if kid else 1.0),
		"phase": _rng.randf() * 10.0, "pause": 0.0, "kid": kid,
		"skin": SKIN[_rng.randi_range(0, SKIN.size() - 1)], "hair": HAIR[_rng.randi_range(0, HAIR.size() - 1)],
		"shirt": SHIRTS[_rng.randi_range(0, SHIRTS.size() - 1)], "pants": PANTS[_rng.randi_range(0, PANTS.size() - 1)],
		"long_hair": _rng.randf() < 0.4, "extra": _rng.randi_range(0, 5),
	})


func _draw() -> void:
	var back := side == Side.BACK
	var y: float = SIDE_Y[side]
	var s := (0.94 if back else 1.0) * 0.5
	for p in _people:
		var k: float = 0.7 if p.kid else 1.0
		draw_set_transform(Vector2(p.x, y), 0.0, Vector2(p.dir * s * k, s * k))
		_person(p, back)
	draw_set_transform(Vector2.ZERO)


## A walking person in art px, ~54 tall, facing right, feet on y 0.
func _person(p: Dictionary, back: bool) -> void:
	var haze := 0.12 if back else 0.0
	var o := PixelArt.OUTLINE
	var skin: Color = (p.skin as Color).lerp(WorldPalette.HAZE, haze)
	var shirt: Color = (p.shirt as Color).lerp(WorldPalette.HAZE, haze)
	var pants: Color = (p.pants as Color).lerp(WorldPalette.HAZE, haze)
	var hair: Color = (p.hair as Color).lerp(WorldPalette.HAZE, haze)
	var walking: bool = p.pause <= 0.0
	var swing := sin(p.phase * 0.35) * 7.0 if walking else 0.0
	# legs (far leg darker), shoes
	draw_line(Vector2(0, -24), Vector2(-swing, -2), pants.darkened(0.25), 6.0)
	draw_line(Vector2(0, -24), Vector2(swing, -2), pants, 6.0)
	draw_rect(Rect2(-swing - 3, -3, 8, 3), o)
	draw_rect(Rect2(swing - 3, -3, 8, 3), o)
	# far arm, torso, near arm
	draw_line(Vector2(0, -42), Vector2(swing * 0.7, -26), shirt.darkened(0.25), 4.0)
	draw_rect(Rect2(-7, -45, 14, 23), o)
	draw_rect(Rect2(-6, -44, 12, 21), shirt)
	draw_rect(Rect2(-6, -44, 3, 21), shirt.lightened(0.15))
	draw_line(Vector2(0, -42), Vector2(-swing * 0.7, -26), shirt, 4.0)
	draw_rect(Rect2(-swing * 0.7 - 2, -27, 4, 4), skin)
	# head and hair
	draw_rect(Rect2(-6, -56, 12, 12), o)
	draw_rect(Rect2(-5, -55, 10, 10), skin)
	draw_rect(Rect2(2, -52, 2, 2), o)                     # eye
	draw_rect(Rect2(-6, -57, 12, 4), hair)
	draw_rect(Rect2(-6, -55, 3, 4 if not p.long_hair else 12), hair)
	# one small story each
	match int(p.extra):
		0:                                  # shopping bag
			draw_rect(Rect2(-swing * 0.7 - 4, -24, 9, 10), WorldPalette.W4.lerp(WorldPalette.HAZE, haze))
		1:                                  # backpack
			draw_rect(Rect2(-11, -44, 6, 14), WorldPalette.P0.lerp(WorldPalette.HAZE, haze))
		2:                                  # phone in hand, looking down
			draw_rect(Rect2(6, -36, 3, 5), o)
		3:                                  # a dog on a lead
			var dx := 22.0
			draw_line(Vector2(-swing * 0.7, -26), Vector2(dx, -10), o, 1.0)
			draw_rect(Rect2(dx - 2, -12, 14, 7), WorldPalette.W1)
			draw_rect(Rect2(dx + 10, -16, 6, 6), WorldPalette.W1)
			draw_rect(Rect2(dx, -5, 2, 5), o); draw_rect(Rect2(dx + 9, -5, 2, 5), o)
		_:
			pass
