extends Node2D
## The title screen: sky, the band lined up, the name, and a small menu
## (start the tour on the world map, go to the base, quit).
## Click a cat, or press 1-5 / left-right, to pick who leads the tour.
## The picked cat plays their instrument; the others idle or smoke.

const MAP := "res://scenes/world/world_map.tscn"
const BASE := "res://scenes/levels/base.tscn"
const PROFILES := ["joep", "jay", "nikki", "germ", "geoff"]
## Jay, The Germ and Geoff smoke while they wait; Joep and Nikki just idle.
const SMOKE := [false, true, false, true, true]
const STEP := 108.0
const FEET_Y := 250.0
const CENTER_X := 320.0
const NAME_COLOR := Color("ffd36b")
const NAME_DIM := Color(1, 1, 1, 0.55)
const INK := Color("1d2838")
## Commit time of this build (day/month and 24h), so a browser load can be checked.
const BUILT := "27/10  23:33"

var _menu: MenuList
var _sprites: Array[AnimatedSprite2D] = []
var _names: PackedStringArray = []
var _picked := 0


func _ready() -> void:
	Audio.music(&"map_calm")
	add_child(WorldSky.new())
	var cam := Camera2D.new()                    # keeps the scene centred on wide screens
	cam.position = ScreenFit.BASE / 2.0
	add_child(cam)
	_backdrop()
	_line_up()
	var ui := CanvasLayer.new()
	add_child(ui)
	ui.add_child(_text("THE LOST CATS", Vector2(0, 30), 32, Color("f2bc58")))
	ui.add_child(_text("Nine Lives on the Road", Vector2(0, 70), 16, Color("fff7df")))
	ui.add_child(_text("Click a cat    ·    1-5", Vector2(0, 98), 8, Color(1, 1, 1, 0.75)))
	ui.add_child(_built_stamp())
	_menu = MenuList.new()
	_menu.position = Vector2(170, 282)
	_menu.size = Vector2(300, 70)
	_menu.spacing = 22.0
	_menu.font_size = 16
	ui.add_child(_menu)
	ScreenFit.pin(_menu, 0.5)
	_menu.set_options(["Start the tour", "Go to the base", "Quit"])
	_menu.chosen.connect(_on_chosen)
	_select(0)


## The five cats, feet on the quay. Spread so a click lands on one of them
## and an instrument doesn't sit inside the next cat.
func _line_up() -> void:
	for i in PROFILES.size():
		var prof: MovementProfile = load("res://resources/profiles/%s.tres" % PROFILES[i])
		var s := AnimatedSprite2D.new()
		s.sprite_frames = prof.sprite_frames
		s.scale = Vector2.ONE * prof.sprite_scale * 2.0
		s.offset = prof.sprite_offset
		s.position = _slot(i)
		s.animation_finished.connect(_on_anim_finished.bind(s))
		add_child(s)
		_sprites.append(s)
		_names.append(prof.display_name)


func _slot(i: int) -> Vector2:
	return Vector2(CENTER_X + (i - 2) * STEP, FEET_Y)


func _select(i: int) -> void:
	_picked = wrapi(i, 0, PROFILES.size())
	for k in _sprites.size():
		var s := _sprites[k]
		var on := k == _picked
		s.z_index = 1 if on else 0
		s.modulate = Color.WHITE if on else Color(0.82, 0.82, 0.86)
		s.position = _slot(k) + Vector2(0, -4 if on else 0)
		if on:
			_play_instrument(s)
		else:
			_play_rest(s, k)
	queue_redraw()


## Pick up the instrument, then hold the playing loop (the sheet's _in is one shot).
func _play_instrument(s: AnimatedSprite2D) -> void:
	var frames := s.sprite_frames
	if frames == null:
		return
	if frames.has_animation(&"idle_instrument_in"):
		s.play(&"idle_instrument_in")
	elif frames.has_animation(&"idle_instrument_loop"):
		s.play(&"idle_instrument_loop")
	elif frames.has_animation(&"idle_instrument"):
		s.play(&"idle_instrument")


## Waiting: breathe, or smoke when this cat's sheet has a smoking loop.
func _play_rest(s: AnimatedSprite2D, i: int) -> void:
	var frames := s.sprite_frames
	if frames == null:
		return
	var anim := &"idle"
	if i < SMOKE.size() and SMOKE[i]:
		if frames.has_animation(&"idle_smoking_loop"):
			anim = &"idle_smoking_loop"
		elif frames.has_animation(&"idle_smoking"):
			anim = &"idle_smoking"
		elif frames.has_animation(&"idle_breathing"):
			anim = &"idle_breathing"
	elif frames.has_animation(&"idle_breathing"):
		anim = &"idle_breathing"
	if not frames.has_animation(anim):
		return
	if s.animation == anim and s.is_playing():
		return
	s.play(anim)


func _on_anim_finished(s: AnimatedSprite2D) -> void:
	var i := _sprites.find(s)
	if i < 0 or s.sprite_frames == null:
		return
	if i == _picked and s.animation == &"idle_instrument_in":
		if s.sprite_frames.has_animation(&"idle_instrument_loop"):
			s.play(&"idle_instrument_loop")
		return
	# Switched away mid-intro: the one-shot ended, so drop back to waiting.
	if i != _picked and not s.sprite_frames.get_animation_loop(s.animation):
		_play_rest(s, i)


func _process(_delta: float) -> void:
	if not is_visible_in_tree() or _sprites.is_empty():
		return
	if Input.is_action_just_pressed("move_left") or Input.is_action_just_pressed("ui_left"):
		_select(_picked - 1)
	elif Input.is_action_just_pressed("move_right") or Input.is_action_just_pressed("ui_right"):
		_select(_picked + 1)
	else:
		for i in PROFILES.size():
			if Input.is_action_just_pressed("select_%d" % (i + 1)):
				_select(i)
				return


func _unhandled_input(event: InputEvent) -> void:
	if _sprites.is_empty():
		return
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		var hit := _hit(get_global_mouse_position())
		if hit >= 0:
			_select(hit)
			get_viewport().set_input_as_handled()


## A column around each cat, from the head down through the name.
func _hit(at: Vector2) -> int:
	if at.y < FEET_Y - 104.0 or at.y > FEET_Y + 20.0:
		return -1
	var best := -1
	var best_dx := STEP * 0.5 + 1.0
	for i in _sprites.size():
		var dx := absf(at.x - _slot(i).x)
		if dx < best_dx:
			best = i
			best_dx = dx
	return best


func _draw() -> void:
	if _names.is_empty():
		return
	var font := UiFont.font()
	for i in _names.size():
		var on := i == _picked
		var x := _sprites[i].position.x
		var y := FEET_Y + 14.0
		draw_string(font, Vector2(x - 46, y + 1), _names[i], HORIZONTAL_ALIGNMENT_CENTER, 92, 8, INK)
		draw_string(font, Vector2(x - 46, y), _names[i], HORIZONTAL_ALIGNMENT_CENTER, 92, 8, NAME_COLOR if on else NAME_DIM)
		if on:
			draw_rect(Rect2(x - 12, y + 3, 24, 1), NAME_COLOR)


## The world map's look behind the band: hazy skyline and canal houses, the
## v3 street with its quay, then the canal; the map's colour grade on top.
func _backdrop() -> void:
	var lift := 250.0 - WorldScenery.STREET_Y   # the scenery is drawn for the map's street line
	for k: int in [WorldScenery.Kind.SKYLINE, WorldScenery.Kind.BACK_STREET]:
		var sc := WorldScenery.new()
		sc.kind = k
		sc.town = Vector2(-500, 1200)
		sc.centre = Vector2(-500, 1200)
		sc.outskirts = 100000.0
		sc.map_min = -500.0
		sc.map_width = 1200.0
		sc.seed_value = 13 if k == WorldScenery.Kind.BACK_STREET else 5
		sc.position.y = lift
		sc.modulate = Color(1, 1, 1, 0.9) if k == WorldScenery.Kind.BACK_STREET else Color.WHITE
		add_child(sc)
	var street := Node2D.new()
	street.position = Vector2(-320, 250)
	street.draw.connect(func() -> void:
		var tile := V3Cache.art("street_town", func() -> V3Art: return V3Painter.street_tile(1440)).texture()
		if tile:
			street.draw_set_transform(Vector2.ZERO, 0.0, Vector2(0.5, 0.5))
			street.draw_texture_rect(tile, Rect2(0, 0, 2560, WorldStreet.EDGE_H * 2.0), true))
	street.texture_repeat = CanvasItem.TEXTURE_REPEAT_ENABLED
	add_child(street)
	var water := WorldWater.new()
	water.water_color = Color("3a8f9a")
	water.deep_color = Color("1c5560")
	water.street_gap = WorldStreet.EDGE_H
	water.position = Vector2(-640, 250 + WorldStreet.EDGE_H)
	water.size = Vector2(1920, 160)
	add_child(water)
	var shine := ColorRect.new()                 # the dark line along the quay
	shine.color = WorldPalette.T0
	shine.position = water.position
	shine.size = Vector2(1280, 1)
	add_child(shine)
	preload("res://scripts/world/color_grade.gd").attach(self)


func _text(t: String, pos: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.size = Vector2(640, size + 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("1d2838"))
	l.add_theme_constant_override("outline_size", 1)    # UiFont: a crisp 1 px outline at any scale
	ScreenFit.full_width(l)
	return l


## Quiet corner stamp: the commitment's day/month and time.
func _built_stamp() -> Label:
	var l := Label.new()
	l.text = BUILT
	l.position = Vector2(8, 4)
	l.size = Vector2(120, 14)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_color", Color(1, 1, 1, 0.8))
	l.add_theme_color_override("font_outline_color", INK)
	l.add_theme_constant_override("outline_size", 1)
	return l


func _on_chosen(i: int) -> void:
	match i:
		0:
			# The tour is this one cat. The others stay at the base.
			Game.party.assign([StringName(PROFILES[_picked])])
			Game.active_member = _picked
			SceneRouter.go_to(MAP, &"")
		1: SceneRouter.go_to(BASE, &"BaseEntry")
		_: get_tree().quit()
