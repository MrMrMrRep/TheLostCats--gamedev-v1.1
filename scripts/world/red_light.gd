@tool
class_name RedLightNight
extends Node2D
## The red light district (the zones with `red_light`) after dark:
## - neon signs on the Wallen houses (hearts, a cocktail glass, BAR, a leaf,
##   a guitar, a star) that flicker on at dusk and glow at night,
## - a red haze over the street from all the red windows,
## - night-life people instead of the daytime walkers: they stand around on
##   the pavement and smoke, and now and then one of them leans in when the
##   band walks past ("Psst... want something?"): a little sound and a speech
##   bubble. It never stops the game; there is nothing to buy (yet).
## The red windows themselves glow through CanalRow.add_glow (CanalKit.NEON).
## Origin: x 0, y = the street line. Numbers: the constants below.

const SIGNS: Array[StringName] = [&"neon_heart", &"neon_cocktail", &"neon_bar", &"neon_leaf", &"neon_guitar", &"neon_star"]
const SIGN_COLOURS := {
	&"neon_heart": Color(1.0, 0.15, 0.3), &"neon_cocktail": Color(1.0, 0.35, 0.8), &"neon_bar": Color(1.0, 0.2, 0.15),
	&"neon_leaf": Color(0.3, 1.0, 0.35), &"neon_guitar": Color(0.5, 0.45, 1.0), &"neon_star": Color(1.0, 0.3, 0.2),
}
const PEOPLE: Array[StringName] = [&"nl_hoodie", &"nl_leather", &"nl_coat", &"nl_cap", &"nl_tourist"]
const SMOKERS := [true, true, false, true, false]         # per PEOPLE: a cigarette in hand
const SELLERS := [true, false, true, false, false]        # per PEOPLE: may offer the band something
const OFFERS := ["Psst... want something?", "Hey man, need anything?", "You looking for something?",
	"Psst! Good stuff, cheap...", "Want to buy? Best in town.", "Hey... special price for you."]
const NIGHT_FROM := 0.35                    # the night people come out (WorldDayCycle.night_now)
const PEOPLE_EVERY := Vector2(70, 130)      # world px between two of them
const SIGN_SHARE := 0.55                    # share of the Wallen houses with a neon sign
const OFFER_RANGE := 30.0                   # world px: a seller speaks when the leader comes this close
const OFFER_COOLDOWN := 14.0                # seconds before the same one asks again
const BUBBLE_TIME := 2.4

@export var seed_value := 9

var spans: Array[Vector2] = []              # world x ranges of the red light zones
var signs: Array = []                       # [world pos (bottom centre), name, flicker seed]
var people: Array = []                      # {x, kind, flip, cooldown, phase}
var _glow: Node2D                           # additive: neon light, haze
var _bubbles: Array = []                    # [Label, time left, person]
var _t := 0.0


func _ready() -> void:
	if Engine.is_editor_hint():
		return
	_glow = Node2D.new()
	_glow.name = "Glow"
	var mat := CanvasItemMaterial.new()
	mat.light_mode = CanvasItemMaterial.LIGHT_MODE_UNSHADED
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = mat
	_glow.draw.connect(_draw_glow)
	add_child(_glow, false, Node.INTERNAL_MODE_BACK)
	_setup.call_deferred()


func _setup() -> void:
	spans.clear()
	for z in WorldZone.all(self):
		if z.red_light:
			spans.append(z.span())
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	signs.clear()
	var root: Node = owner if owner else get_tree().current_scene
	if root:
		for n in root.find_children("*", "CityBlock", true, false):
			var b := n as CityBlock
			if not b.kit or b.district != &"wallen":
				continue
			for it: Array in b.kit_row():
				if it[0] == CanalRow.ALLEY or rng.randf() > SIGN_SHARE:
					continue
				var w := CanalRow.width(it[0])
				var ax: float = it[1] + w * rng.randf_range(0.3, 0.7)
				var ground := 96.0 + rng.randf_range(0.0, 20.0)   # art px above the pavement: over the ground floor
				var pos := Vector2(b.global_position.x + ax * 0.5 - global_position.x, -(CanalRow.LIFT + ground) * 0.5)
				signs.append([pos, SIGNS[rng.randi_range(0, SIGNS.size() - 1)], rng.randf() * 100.0])
	people.clear()
	for sp in spans:
		var x := sp.x + rng.randf_range(20, 60)
		while x < sp.y - 20:
			var k := rng.randi_range(0, PEOPLE.size() - 1)
			people.append({"x": x - global_position.x, "kind": k, "flip": rng.randf() < 0.5, "cooldown": 0.0,
				"phase": rng.randf() * TAU})
			x += rng.randf_range(PEOPLE_EVERY.x, PEOPLE_EVERY.y)
	queue_redraw()


func night() -> float:
	return WorldDayCycle.night_now


## People are out (0..1): they fade in as the night falls.
func crowd() -> float:
	return clampf((night() - NIGHT_FROM) / 0.15, 0.0, 1.0)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	for p: Dictionary in people:
		p.cooldown = maxf(p.cooldown - delta, 0.0)
	_offers()
	for b: Array in _bubbles:
		b[1] -= delta
		var cam := get_viewport().get_camera_2d()
		var s := 1.0 / cam.zoom.x if cam else 0.5
		var lbl: Label = b[0]
		lbl.scale = Vector2(s, s)
		lbl.position = Vector2(b[2].x - lbl.size.x * s * 0.5, -58.0)
		if b[1] <= 0.0:
			lbl.queue_free()
	_bubbles = _bubbles.filter(func(b: Array) -> bool: return b[1] > 0.0)
	if night() > 0.01 or not _bubbles.is_empty():
		queue_redraw()
		if _glow:
			_glow.queue_redraw()


## A seller near the leader speaks up (non-blocking: sound + bubble only).
func _offers() -> void:
	if crowd() < 1.0:
		return
	var map := owner
	if map == null or not ("leader" in map) or map.leader == null:
		return
	var lx: float = map.leader.global_position.x - global_position.x
	for p: Dictionary in people:
		if not SELLERS[p.kind] or p.cooldown > 0.0:
			continue
		if absf(lx - p.x) <= OFFER_RANGE:
			p.cooldown = OFFER_COOLDOWN
			p.flip = lx < p.x                 # turn to the band
			say(p, OFFERS[randi() % OFFERS.size()])
			break


func say(p: Dictionary, text: String) -> void:
	Audio.sfx(&"talk", 0.15)
	var lbl := Label.new()
	lbl.text = text
	lbl.size = Vector2(240, 12)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.add_theme_font_size_override("font_size", 8)
	lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.9))
	lbl.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.85))
	lbl.add_theme_constant_override("outline_size", 3)
	lbl.z_index = 5
	add_child(lbl, false, Node.INTERNAL_MODE_BACK)
	_bubbles.append([lbl, BUBBLE_TIME, p])


func _draw() -> void:
	# Neon signs: dim tubes by day, lit at night (the glow pass adds the light).
	var n := night()
	for s: Array in signs:
		var tex := CanalRow.texture(s[1])
		var on := _sign_on(s, n)
		var c := Color(0.55, 0.5, 0.55).lerp(Color.WHITE, on)
		draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
		draw_texture(tex, s[0] * 2.0 - Vector2(tex.get_width() * 0.5, tex.get_height()), c)
		draw_set_transform(Vector2.ZERO)
	# The night people, at the back of the pavement (behind the band).
	var a := crowd()
	if a <= 0.0:
		return
	for p: Dictionary in people:
		var tex := CanalRow.texture(PEOPLE[p.kind])
		var w := tex.get_width()
		var h := tex.get_height()
		var bob := 1.0 if sin(_t * 1.3 + p.phase) > 0.85 else 0.0     # shifting weight now and then
		draw_set_transform(Vector2(p.x, 0.0), 0.0, Vector2(-0.5 if p.flip else 0.5, 0.5))
		draw_texture(tex, Vector2(-w * 0.5, -h + bob), Color(1, 1, 1, a))
		draw_set_transform(Vector2.ZERO)
		if SMOKERS[p.kind]:
			_smoke(p, a)


## A glowing cigarette tip and a wisp of smoke rising from it.
func _smoke(p: Dictionary, a: float) -> void:
	var side := -1.0 if p.flip else 1.0
	var tip := Vector2(p.x + side * 4.5, -15.0)
	var pulse := 0.6 + 0.4 * sin(_t * 2.0 + p.phase)
	draw_rect(Rect2(tip, Vector2(0.5, 0.5)), Color(1.0, 0.55, 0.2, a * pulse))
	for i in 3:
		var k := fposmod(_t * 0.35 + p.phase + i * 0.33, 1.0)
		var off := Vector2(sin(k * 6.0 + p.phase) * 1.5, -k * 10.0)
		draw_rect(Rect2(tip + off + Vector2(0, -1), Vector2(1, 1)), Color(0.85, 0.85, 0.9, a * (1.0 - k) * 0.5))


## How lit a sign is: off by day, buzzing on at dusk, the odd flicker at night.
func _sign_on(s: Array, n: float) -> float:
	var on := clampf((n - 0.15) * 4.0, 0.0, 1.0)
	var f: float = s[2]
	if on > 0.0 and fposmod(_t * 0.7 + f, 9.0) < 0.12:
		on *= 0.25                          # a flicker
	return on


func _draw_glow() -> void:
	var n := night()
	if n <= 0.01:
		return
	var halo := NightGlow.halo_texture()
	for s: Array in signs:
		var on := _sign_on(s, n)
		if on <= 0.0:
			continue
		var c: Color = SIGN_COLOURS.get(s[1], Color.RED)
		var tex := CanalRow.texture(s[1])
		var size := Vector2(tex.get_size()) * 0.5
		var centre: Vector2 = s[0] - Vector2(0, size.y * 0.5)
		_glow.draw_texture_rect(halo, Rect2(centre - size * 1.6, size * 3.2), false, Color(c, 0.55 * on))
		_glow.draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
		_glow.draw_texture(tex, s[0] * 2.0 - Vector2(tex.get_width() * 0.5, tex.get_height()), Color(c, 0.6 * on))
		_glow.draw_set_transform(Vector2.ZERO)
	# The red haze over the whole district: from the facades down onto the street.
	var haze := clampf((n - 0.1) * 2.0, 0.0, 1.0)
	for sp in spans:
		var x := sp.x - global_position.x
		while x < sp.y - global_position.x:
			_glow.draw_texture_rect(halo, Rect2(Vector2(x - 70, -110), Vector2(140, 150)), false, Color(1.0, 0.08, 0.2, 0.16 * haze))
			_glow.draw_texture_rect(halo, Rect2(Vector2(x - 50, -6), Vector2(100, 24)), false, Color(1.0, 0.1, 0.25, 0.22 * haze))
			x += 60.0
