@tool
class_name BaseProp
extends Node2D
## A piece of furniture in the band's base (the storage). Pick the `kind`, drag
## it. The base can grow: a piece only shows once Game.base_level reaches its
## `min_base_level` (1 = there from the start; 2, 3... = upgrades). Origin =
## the bottom centre, on the floor.

enum Kind { COUCH, FRIDGE, DRUMS, AMP_GUITAR, AMP_BASS, KEYS, MIC, POSTER, RUG, LAMP, BEER_CRATE }

const O := Color("1d1a22")                  # outline

@export var kind := Kind.COUCH:
	set(value):
		kind = value
		queue_redraw()
@export var min_base_level := 1             ## shows from this base level (upgrades)
@export var tint := Color.WHITE:            ## e.g. the couch's colour
	set(value):
		tint = value
		queue_redraw()
@export var text := "":                     ## poster text
	set(value):
		text = value
		queue_redraw()

var _glow: NightGlow


func _ready() -> void:
	if not Engine.is_editor_hint():
		visible = Game.base_level >= min_base_level
		if kind == Kind.LAMP:
			_glow = NightGlow.attach(self)
			if _glow:
				_glow.add_lamp(Vector2(0, -38), 34.0, 0.0, -1.0, Color(1.0, 0.85, 0.55, 0.45))
				_glow.night = 1.0           # indoors: always on


func _draw() -> void:
	match kind:
		Kind.COUCH: _couch()
		Kind.FRIDGE: _fridge()
		Kind.DRUMS: _drums()
		Kind.AMP_GUITAR: _amp(Color("2b2b33"), Color("c94a3d"), true)
		Kind.AMP_BASS: _amp(Color("1c1b20"), Color("e0b84a"), false)
		Kind.KEYS: _keys()
		Kind.MIC: _mic()
		Kind.POSTER: _poster()
		Kind.RUG: _rug()
		Kind.LAMP: _lamp()
		Kind.BEER_CRATE: _crate()


func _box(r: Rect2, c: Color) -> void:
	draw_rect(r.grow(1), O)
	draw_rect(r, c)


func _couch() -> void:
	var c := Color("8a3a2e") * tint
	var hi := c.lightened(0.18)
	var lo := c.darkened(0.3)
	_box(Rect2(-32, -22, 64, 12), c)                     # back rest
	draw_rect(Rect2(-32, -22, 64, 2), hi)
	_box(Rect2(-30, -12, 60, 8), hi)                     # seat cushions
	draw_rect(Rect2(-1, -12, 1, 8), lo)
	draw_rect(Rect2(-30, -6, 60, 2), lo)
	_box(Rect2(-36, -16, 7, 14), c)                      # arm rests
	_box(Rect2(29, -16, 7, 14), c)
	draw_rect(Rect2(-36, -16, 7, 2), hi)
	draw_rect(Rect2(29, -16, 7, 2), hi)
	draw_rect(Rect2(-34, -2, 3, 2), O)                   # feet
	draw_rect(Rect2(31, -2, 3, 2), O)
	_box(Rect2(-24, -19, 9, 7), Color("e0b84a"))         # a cushion
	draw_rect(Rect2(-22, -17, 5, 1), Color("f2d27a"))


func _fridge() -> void:
	var w := Color("e8ecef")
	_box(Rect2(-11, -42, 22, 42), w)
	draw_rect(Rect2(-11, -42, 2, 42), Color.WHITE)
	draw_rect(Rect2(9, -42, 2, 42), Color("b9c0c8"))
	draw_rect(Rect2(-11, -28, 22, 1), O)                 # freezer door line
	draw_rect(Rect2(6, -38, 2, 7), Color("8a9099"))      # handles
	draw_rect(Rect2(6, -24, 2, 10), Color("8a9099"))
	draw_rect(Rect2(-7, -22, 6, 5), Color("c94a3d"))     # stickers: a band sticker, a note
	draw_rect(Rect2(-6, -21, 4, 1), Color.WHITE)
	draw_rect(Rect2(-6, -14, 7, 6), Color("f2e27a"))
	draw_rect(Rect2(-5, -12, 5, 1), Color("8a8060"))
	draw_rect(Rect2(-9, -1, 18, 1), Color("6a7078"))


func _drums() -> void:
	var shell := Color("2a4ea0")
	# kick drum with the band logo
	WorldPalette.disc(self, 0, -10, 10, O)
	WorldPalette.disc(self, 0, -10, 9, Color("f2efe8"))
	WorldPalette.disc(self, 0, -10, 7, Color("e8e4dc"))
	draw_string(ThemeDB.fallback_font, Vector2(-8, -8), "CATS", HORIZONTAL_ALIGNMENT_LEFT, -1, 5, Color("1d1a22"))
	draw_rect(Rect2(-10, -11, 2, 3), shell)
	draw_rect(Rect2(8, -11, 2, 3), shell)
	# toms on the kick, snare and floor tom
	_box(Rect2(-9, -25, 8, 5), shell)
	_box(Rect2(2, -25, 8, 5), shell)
	_box(Rect2(-22, -15, 9, 5), Color("c9cdd4"))
	draw_rect(Rect2(-19, -10, 1, 10), O)
	_box(Rect2(14, -14, 9, 11), shell)
	draw_rect(Rect2(15, -3, 1, 3), O)
	draw_rect(Rect2(21, -3, 1, 3), O)
	# cymbals on stands
	for cx in [-24.0, 22.0]:
		draw_rect(Rect2(cx, -30, 1, 30), Color("8a8f99"))
		draw_rect(Rect2(cx - 7, -31, 15, 2), Color("e0b84a"))
		draw_rect(Rect2(cx - 5, -32, 11, 1), Color("f2d27a"))
	# stool
	_box(Rect2(-4, -8, 8, 2), Color("2a2a2e"))


func _amp(body: Color, accent: Color, guitar: bool) -> void:
	_box(Rect2(-10, -18, 20, 18), body)
	draw_rect(Rect2(-8, -13, 16, 11), body.lightened(0.12))   # grille
	for y in range(-12, -2, 2):
		draw_rect(Rect2(-8, y, 16, 1), body.lightened(0.2))
	draw_rect(Rect2(-8, -17, 16, 2), Color("8a8f99"))
	draw_rect(Rect2(-6, -17, 1, 1), accent)
	# the instrument on its stand next to it
	var x := 16.0
	draw_rect(Rect2(x - 4, -1, 9, 1), O)
	draw_rect(Rect2(x, -10, 1, 10), O)
	var neck := Color("8a5a3a")
	if guitar:                              # Nikki's flying V-ish guitar
		WorldPalette.triangle(self, x - 6, -16, 13, 9, accent)
		draw_rect(Rect2(x, -34, 2, 18), neck)
		draw_rect(Rect2(x - 1, -36, 4, 3), O)
	else:                                   # Jay's bass, longer neck
		_box(Rect2(x - 4, -18, 9, 10), accent)
		draw_rect(Rect2(x, -40, 2, 22), neck)
		draw_rect(Rect2(x - 1, -42, 4, 3), O)


func _keys() -> void:
	draw_rect(Rect2(-14, -14, 1, 14), O)                 # X stand
	draw_rect(Rect2(13, -14, 1, 14), O)
	draw_line(Vector2(-13, 0), Vector2(12, -13), O, 1.0)
	draw_line(Vector2(12, 0), Vector2(-13, -13), O, 1.0)
	_box(Rect2(-17, -19, 34, 5), Color("2a2a2e"))
	draw_rect(Rect2(-15, -16, 30, 2), Color("f2efe8"))
	for k in range(-15, 15, 3):
		draw_rect(Rect2(k + 2, -16, 1, 1), O)
	draw_rect(Rect2(-15, -19, 4, 1), Color("c94a3d"))


func _mic() -> void:
	draw_rect(Rect2(-5, -1, 11, 1), O)
	draw_rect(Rect2(0, -30, 1, 30), Color("8a8f99"))
	draw_line(Vector2(0, -30), Vector2(6, -34), Color("8a8f99"), 1.0)
	_box(Rect2(6, -37, 3, 5), Color("2a2a2e"))


func _poster() -> void:
	_box(Rect2(-9, -24, 18, 24), Color("e0b84a") * tint)
	draw_rect(Rect2(-7, -22, 14, 12), Color("1d1a22"))
	WorldPalette.disc(self, 0, -16, 4, Color("c94a3d"))
	draw_string(ThemeDB.fallback_font, Vector2(-8, -3), text if text != "" else "GIG", HORIZONTAL_ALIGNMENT_CENTER, 16, 6, Color("1d1a22"))


func _rug() -> void:
	draw_rect(Rect2(-40, -2, 80, 3), Color("6a2a3a") * tint)
	draw_rect(Rect2(-38, -1, 76, 1), Color("c98a5a") * tint)


func _lamp() -> void:
	draw_rect(Rect2(-5, -1, 11, 1), O)
	draw_rect(Rect2(0, -36, 1, 36), Color("2a2a2e"))
	for y in 8:                              # the shade, wider at the bottom
		draw_rect(Rect2(-3 - y * 0.5, -44 + y, 7 + y, 1), Color("e8c98a"))
	draw_rect(Rect2(-6, -37, 13, 1), Color("f2e2b0"))


func _crate() -> void:
	_box(Rect2(-9, -10, 18, 10), Color("e0b23a"))
	for i in 4:
		draw_rect(Rect2(-7 + i * 4, -13, 3, 4), Color("3f8f3a"))
		draw_rect(Rect2(-6 + i * 4, -15, 1, 2), Color("1f5a24"))
