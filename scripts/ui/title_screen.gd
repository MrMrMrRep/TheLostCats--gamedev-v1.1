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
	var ground := ColorRect.new()                # a strip of street and canal
	ground.color = WorldPalette.COBBLE
	ground.position = Vector2(0, 250)
	ground.size = Vector2(640, 14)
	add_child(ground)
	var water := ColorRect.new()
	water.color = WorldPalette.WATER
	water.position = Vector2(0, 264)
	water.size = Vector2(640, 96)
	add_child(water)
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
	ui.add_child(_text("THE LOST CATS", Vector2(0, 34), 34, Color("ffd36b")))
	ui.add_child(_text("Nine Lives on the Road", Vector2(0, 76), 12, Color.WHITE))
	_menu = MenuList.new()
	_menu.position = Vector2(220, 280)
	_menu.size = Vector2(200, 70)
	_menu.spacing = 20.0
	_menu.font_size = 13
	ui.add_child(_menu)
	_menu.set_options(["Start the tour", "Go to the base", "Quit"])
	_menu.chosen.connect(_on_chosen)


func _text(t: String, pos: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = t
	l.position = pos
	l.size = Vector2(640, size + 10)
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("1d1a22"))
	l.add_theme_constant_override("outline_size", 6)
	return l


func _on_chosen(i: int) -> void:
	match i:
		0: SceneRouter.go_to(MAP, &"")
		1: SceneRouter.go_to(BASE, &"BaseEntry")
		_: get_tree().quit()
