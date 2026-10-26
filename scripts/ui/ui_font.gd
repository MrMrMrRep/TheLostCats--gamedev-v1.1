class_name UiFont
extends RefCounted
## The game's UI font: crisp pixel letters that match the world's signs
## (PixelFont's 5x7 capitals and digits), plus lower case, accents and
## punctuation drawn on the same grid. Built in code as a bitmap FontFile, so
## there is no import step. Proportional (an "i" is narrow), digits keep one
## width so the clock doesn't wobble.
##
## UiFont.install() (called by the Game autoload) makes it the default font of
## every Control, with a 1 px navy drop shadow for reading over the world.
## Sizes: 8-15 = 1x (7 px capitals on the 640x360 screen), 16-23 = 2x, 24+ = 3x...

const BASE_SIZE := 8                        ## the size the letters are drawn for (1x)
const ROWS := 9                             ## 7 rows of capitals + 2 for descenders
const CAP := 7
const ASCENT := 8                           ## one row of air above the capitals
const DESCENT := 3
const SHADOW := Color("1d2838")             ## WorldPalette.T0 (navy)

# Lower case, accents and punctuation: 5 columns x 9 rows ("#" = ink), rows
# 0-6 above the baseline, 7-8 below it.
const EXTRA := {
	"a": [".....", ".....", ".###.", "....#", ".####", "#...#", ".####", ".....", "....."],
	"b": ["#....", "#....", "####.", "#...#", "#...#", "#...#", "####.", ".....", "....."],
	"c": [".....", ".....", ".####", "#....", "#....", "#....", ".####", ".....", "....."],
	"d": ["....#", "....#", ".####", "#...#", "#...#", "#...#", ".####", ".....", "....."],
	"e": [".....", ".....", ".###.", "#...#", "#####", "#....", ".####", ".....", "....."],
	"f": ["..##.", ".#...", "####.", ".#...", ".#...", ".#...", ".#...", ".....", "....."],
	"g": [".....", ".....", ".####", "#...#", "#...#", "#...#", ".####", "....#", ".###."],
	"h": ["#....", "#....", "####.", "#...#", "#...#", "#...#", "#...#", ".....", "....."],
	"i": ["..#..", ".....", ".##..", "..#..", "..#..", "..#..", ".###.", ".....", "....."],
	"j": ["...#.", ".....", "..##.", "...#.", "...#.", "...#.", "...#.", "#..#.", ".##.."],
	"k": ["#....", "#....", "#..#.", "#.#..", "##...", "#.#..", "#..#.", ".....", "....."],
	"l": [".##..", "..#..", "..#..", "..#..", "..#..", "..#..", ".###.", ".....", "....."],
	"m": [".....", ".....", "##.#.", "#.#.#", "#.#.#", "#.#.#", "#...#", ".....", "....."],
	"n": [".....", ".....", "####.", "#...#", "#...#", "#...#", "#...#", ".....", "....."],
	"o": [".....", ".....", ".###.", "#...#", "#...#", "#...#", ".###.", ".....", "....."],
	"p": [".....", ".....", "####.", "#...#", "#...#", "#...#", "####.", "#....", "#...."],
	"q": [".....", ".....", ".####", "#...#", "#...#", "#...#", ".####", "....#", "....#"],
	"r": [".....", ".....", "#.##.", "##..#", "#....", "#....", "#....", ".....", "....."],
	"s": [".....", ".....", ".####", "#....", ".###.", "....#", "####.", ".....", "....."],
	"t": [".#...", ".#...", "####.", ".#...", ".#...", ".#...", "..##.", ".....", "....."],
	"u": [".....", ".....", "#...#", "#...#", "#...#", "#...#", ".####", ".....", "....."],
	"v": [".....", ".....", "#...#", "#...#", "#...#", ".#.#.", "..#..", ".....", "....."],
	"w": [".....", ".....", "#...#", "#...#", "#.#.#", "#.#.#", ".#.#.", ".....", "....."],
	"x": [".....", ".....", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", ".....", "....."],
	"y": [".....", ".....", "#...#", "#...#", "#...#", "#...#", ".####", "....#", ".###."],
	"z": [".....", ".....", "#####", "...#.", "..#..", ".#...", "#####", ".....", "....."],
	"é": ["...#.", "..#..", ".###.", "#...#", "#####", "#....", ".####", ".....", "....."],
	"è": [".#...", "..#..", ".###.", "#...#", "#####", "#....", ".####", ".....", "....."],
	"ë": [".#.#.", ".....", ".###.", "#...#", "#####", "#....", ".####", ".....", "....."],
	"á": ["...#.", "..#..", ".###.", "....#", ".####", "#...#", ".####", ".....", "....."],
	"ä": [".#.#.", ".....", ".###.", "....#", ".####", "#...#", ".####", ".....", "....."],
	"ö": [".#.#.", ".....", ".###.", "#...#", "#...#", "#...#", ".###.", ".....", "....."],
	"ü": [".#.#.", ".....", "#...#", "#...#", "#...#", "#...#", ".####", ".....", "....."],
	"ï": [".#.#.", ".....", ".##..", "..#..", "..#..", "..#..", ".###.", ".....", "....."],
	":": [".....", ".....", "..#..", ".....", ".....", ".....", "..#..", ".....", "....."],
	".": [".....", ".....", ".....", ".....", ".....", ".....", "..#..", ".....", "....."],
	"'": ["..#..", "..#..", ".....", ".....", ".....", ".....", ".....", ".....", "....."],
	"!": ["..#..", "..#..", "..#..", "..#..", "..#..", ".....", "..#..", ".....", "....."],
	"?": [".###.", "#...#", "...#.", "..#..", "..#..", ".....", "..#..", ".....", "....."],
	",": [".....", ".....", ".....", ".....", ".....", ".....", "..#..", ".#...", "....."],
	";": [".....", ".....", "..#..", ".....", ".....", ".....", "..#..", ".#...", "....."],
	"\"": [".#.#.", ".#.#.", ".....", ".....", ".....", ".....", ".....", ".....", "....."],
	"(": ["...#.", "..#..", ".#...", ".#...", ".#...", "..#..", "...#.", ".....", "....."],
	")": [".#...", "..#..", "...#.", "...#.", "...#.", "..#..", ".#...", ".....", "....."],
	"[": [".###.", ".#...", ".#...", ".#...", ".#...", ".#...", ".###.", ".....", "....."],
	"]": [".###.", "...#.", "...#.", "...#.", "...#.", "...#.", ".###.", ".....", "....."],
	"+": [".....", "..#..", "..#..", "#####", "..#..", "..#..", ".....", ".....", "....."],
	"=": [".....", ".....", "#####", ".....", "#####", ".....", ".....", ".....", "....."],
	"%": ["##..#", "##.#.", "..#..", ".#...", "#.##.", "#..##", ".....", ".....", "....."],
	"#": [".#.#.", "#####", ".#.#.", ".#.#.", "#####", ".#.#.", ".....", ".....", "....."],
	"*": [".....", "#.#.#", ".###.", "#####", ".###.", "#.#.#", ".....", ".....", "....."],
	"_": [".....", ".....", ".....", ".....", ".....", ".....", "#####", ".....", "....."],
	"·": [".....", ".....", ".....", "..#..", ".....", ".....", ".....", ".....", "....."],
	"…": [".....", ".....", ".....", ".....", ".....", ".....", "#.#.#", ".....", "....."],
	"€": ["..###", ".#...", "####.", ".#...", "####.", ".#...", "..###", ".....", "....."],
	"$": ["..#..", ".####", "#.#..", ".###.", "..#.#", "####.", "..#..", ".....", "....."],
	"@": [".###.", "#...#", "#.###", "#.#.#", "#.###", "#....", ".###.", ".....", "....."],
	"|": ["..#..", "..#..", "..#..", "..#..", "..#..", "..#..", "..#..", "..#..", "....."],
}
const SAME_AS := {"’": "'", "‘": "'", "“": "\"", "”": "\"", "–": "-", "—": "-", "×": "x"}
const DIGITS := "0123456789"

static var _font: FontFile


## The font (built once).
static func font() -> FontFile:
	if _font == null:
		_font = _build()
	return _font


## Make it the default font of every Control (call before any UI exists).
static func install() -> void:
	var t := ThemeDB.get_default_theme()
	if t == null:
		return
	t.default_font = font()
	t.default_font_size = BASE_SIZE
	for type: StringName in [&"Label", &"Button", &"LinkButton", &"RichTextLabel", &"LineEdit", &"CheckBox", &"OptionButton"]:
		t.set_color(&"font_shadow_color", type, Color(SHADOW, 0.9))
		t.set_constant(&"shadow_offset_x", type, 1)
		t.set_constant(&"shadow_offset_y", type, 1)
		t.set_constant(&"shadow_outline_size", type, 0)


## Every glyph as 9 rows of 5 ("#" ink), from the sign font and EXTRA.
static func _glyphs() -> Dictionary:
	var out := {}
	for ch: String in PixelFont.GLYPHS:
		var bits: String = PixelFont.GLYPHS[ch]
		var rows: Array = []
		for r in CAP:
			rows.append(bits.substr(r * 5, 5).replace("1", "#").replace("0", "."))
		rows.append(".....")
		rows.append(".....")
		out[ch] = rows
	# The sign font's Q has its tail inside the box; give it a real one.
	out["Q"] = [".###.", "#...#", "#...#", "#...#", "#.#.#", "#..#.", ".##.#", ".....", "....."]
	for ch: String in EXTRA:
		out[ch] = EXTRA[ch]
	for ch: String in SAME_AS:
		out[ch] = out[SAME_AS[ch]]
	return out


static func _build() -> FontFile:
	var glyphs := _glyphs()
	var chars: Array = glyphs.keys()
	var cols := 16
	var cell := Vector2i(7, ROWS + 2)          # 1 px free all round (outlines grow into it)
	var img := Image.create(cols * cell.x, ceili(chars.size() / float(cols)) * cell.y, false, Image.FORMAT_RGBA8)
	var f := FontFile.new()
	f.fixed_size = BASE_SIZE
	f.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	f.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	f.generate_mipmaps = false
	f.hinting = TextServer.HINTING_NONE
	f.subpixel_positioning = TextServer.SUBPIXEL_POSITIONING_DISABLED
	var size := Vector2i(BASE_SIZE, 0)
	f.set_cache_ascent(0, BASE_SIZE, ASCENT)
	f.set_cache_descent(0, BASE_SIZE, DESCENT)
	var placed := []                        # [code, uv rect, advance]
	for i in chars.size():
		var ch: String = chars[i]
		var rows: Array = glyphs[ch]
		var cx := (i % cols) * cell.x + 1
		var cy := (i / cols) * cell.y + 1
		var lo := 5
		var hi := -1
		for r in ROWS:
			var row: String = rows[r]
			for c in 5:
				if row[c] == "#":
					img.set_pixel(cx + c, cy + r, Color.WHITE)
					lo = mini(lo, c)
					hi = maxi(hi, c)
		var adv := 4                        # a space
		var uv := Rect2(cx, cy, 1, ROWS)
		if hi >= 0:
			if ch in DIGITS:                # digits keep one width
				lo = 0
				hi = 4
			uv = Rect2(cx + lo, cy, hi - lo + 1, ROWS)
			adv = hi - lo + 2
		placed.append([ch.unicode_at(0), uv, adv])
	f.set_texture_image(0, size, 0, img)
	for p: Array in placed:
		var code: int = p[0]
		var uv: Rect2 = p[1]
		f.set_glyph_texture_idx(0, size, code, 0)
		f.set_glyph_uv_rect(0, size, code, uv)
		f.set_glyph_size(0, size, code, uv.size)
		f.set_glyph_offset(0, size, code, Vector2(0, -CAP))
		f.set_glyph_advance(0, BASE_SIZE, code, Vector2(p[2], 0))
	# Outlines: a fixed-size font looks its outline glyphs up at
	# (size, 1) whatever outline size a Label asks for, so every outline is
	# one crisp pixel (without these the smooth fallback font's outline showed).
	var osize := Vector2i(BASE_SIZE, 1)
	var oimg := Image.create(img.get_width(), img.get_height(), false, Image.FORMAT_RGBA8)
	for y in img.get_height():
		for x in img.get_width():
			if img.get_pixel(x, y).a > 0.5:
				for dy in range(-1, 2):
					for dx in range(-1, 2):
						var qx := x + dx
						var qy := y + dy
						if qx >= 0 and qy >= 0 and qx < oimg.get_width() and qy < oimg.get_height():
							oimg.set_pixel(qx, qy, Color.WHITE)
	f.set_texture_image(0, osize, 0, oimg)
	for p: Array in placed:
		var code: int = p[0]
		var uv: Rect2 = p[1]
		var ouv := uv.grow(1.0)              # the cells leave a free column and row for this
		f.set_glyph_texture_idx(0, osize, code, 0)
		f.set_glyph_uv_rect(0, osize, code, ouv)
		f.set_glyph_size(0, osize, code, ouv.size)
		f.set_glyph_offset(0, osize, code, Vector2(-1, -CAP - 1))
	f.fallbacks = [ThemeDB.fallback_font]    # anything not drawn here
	return f
