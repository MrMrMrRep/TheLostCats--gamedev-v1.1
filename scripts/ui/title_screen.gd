extends Node2D
## The title screen: sky, the band lined up, the name, and a small menu
## (start the tour on the world map, go to the base, quit).

const MAP := "res://scenes/world/world_map.tscn"
const BASE := "res://scenes/levels/base.tscn"
const PROFILES := ["joep", "jay", "nikki", "germ", "geoff"]

var _menu: MenuList


func _ready() -> void:
	Audio.music(&"map_calm")
	add_child(WorldSky.new())
	var cam := Camera2D.new()                    # keeps the scene centred on wide screens
	cam.position = ScreenFit.BASE / 2.0
	add_child(cam)
	_backdrop()
	for i in PROFILES.size():                    # the band, idling
		var prof: MovementProfile = load("res://resources/profiles/%s.tres" % PROFILES[i])
		var s := AnimatedSprite2D.new()
		s.sprite_frames = prof.sprite_frames
		s.scale = Vector2.ONE * prof.sprite_scale * 2.0
		s.offset = prof.sprite_offset
		s.position = Vector2(200 + i * 60, 250)
		if s.sprite_frames:
			var anim := &"idle_breathing" if s.sprite_frames.has_animation(&"idle_breathing") else &"idle"
			if s.sprite_frames.has_animation(anim):
				s.play(anim)
		add_child(s)
	var ui := CanvasLayer.new()
	add_child(ui)
	ui.add_child(_text("THE LOST CATS", Vector2(0, 30), 32, Color("f2bc58")))
	ui.add_child(_text("Nine Lives on the Road", Vector2(0, 70), 16, Color("fff7df")))
	_menu = MenuList.new()
	_menu.position = Vector2(170, 282)
	_menu.size = Vector2(300, 70)
	_menu.spacing = 22.0
	_menu.font_size = 16
	ui.add_child(_menu)
	ScreenFit.pin(_menu, 0.5)
	_menu.set_options(["Start the tour", "Go to the base", "Quit"])
	_menu.chosen.connect(_on_chosen)


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
	var water := ColorRect.new()
	water.color = WorldPalette.WATER
	water.position = Vector2(-320, 250 + WorldStreet.EDGE_H)
	water.size = Vector2(1280, 120)
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


func _on_chosen(i: int) -> void:
	match i:
		0:                                  # the tour starts with Joep alone (the others join at the base)
			Game.party.assign([&"joep"])
			Game.active_member = 0
			SceneRouter.go_to(MAP, &"")
		1: SceneRouter.go_to(BASE, &"BaseEntry")
		_: get_tree().quit()
