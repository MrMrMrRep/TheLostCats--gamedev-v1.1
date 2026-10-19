class_name WorldPalette
extends RefCounted
## The approved world-map palette (docs/art-style.md section 3), shared by all
## procedurally drawn world-map art.

const SKY_TOP := Color("7fb0ea")
const SKY_MID := Color("a9cbf2")
const SKY_LOW := Color("d4e5f8")
const CLOUD := Color("f6f9fe")
const CLOUD_SHADE := Color("d3e0f3")
const CLOUD_DARK := Color("b4c8e6")
const SUN := Color("fff1b8")
const HAZE := Color("9db6d8")
const HAZE_DARK := Color("86a2c9")

const NAVY := Color("232c42")
const GLASS := Color("1e2433")
const LIT := Color("f4cf78")
const TRIM := Color("f2e8da")
const WHITE := Color("fbf8f2")
const ROOF := Color("3b2522")
const ORANGE := Color("e07a2e")
const FACADES := [Color("5b7fa6"), Color("8fb0d2"), Color("e07a2e"), Color("d08a72"),
	Color("b8604a"), Color("4e2c26"), Color("5c4149"), Color("c9a15a"), Color("41587a"), Color("f2a65a")]

const COBBLE := Color("8a8292")
const COBBLE_DARK := Color("6c6476")
const CURB := Color("b9b1bb")
const QUAY := Color("6f6a72")
const QUAY_DARK := Color("524e58")
const IRON := Color("2a2830")

const WATER := Color("2b5779")
const WATER_DEEP := Color("1f4060")
const WATER_HI := Color("9cc4e4")
const DITCH := Color("3f7396")

const LEAF := [Color("3f6b34"), Color("5d8c3e"), Color("86b44f")]
const TRUNK := Color("4a3426")
const GRASS := [Color("6ea142"), Color("8dbc52"), Color("a9cf63")]
const FIELD_FAR := Color("9cc06a")
const BARN := Color("a8432f")
const BARN_DARK := Color("6b3a2a")
const MILL := Color("5a4636")
const SAIL := Color("efe6d2")
const TURBINE := Color("e9eef2")
const ROAD := Color("4a4a52")


## Filled circle made of rects (crisp pixel discs).
static func disc(ci: CanvasItem, cx: float, cy: float, r: int, c: Color) -> void:
	for y in range(-r, r + 1):
		var half := int(sqrt(maxf(r * r - y * y, 0.0)))
		ci.draw_rect(Rect2(cx - half, cy + y, half * 2 + 1, 1), c)


static func triangle(ci: CanvasItem, x: float, base: float, w: float, h: int, c: Color) -> void:
	for y in h:
		var half := int(w / 2.0 * (1.0 - float(y) / h))
		ci.draw_rect(Rect2(x + w / 2.0 - half, base - y - 1, half * 2, 1), c)


static func tree(ci: CanvasItem, x: float, base: float, r: int, tint := 0.0) -> void:
	ci.draw_rect(Rect2(x - 1, base - r, 3, r), TRUNK.lerp(HAZE, tint))
	disc(ci, x, base - r - r / 2, r, LEAF[0].lerp(HAZE, tint))
	disc(ci, x - 3, base - r - r / 2 - 3, r - 3, LEAF[1].lerp(HAZE, tint))
	disc(ci, x - 5, base - r - r / 2 - 6, maxi(r - 7, 1), LEAF[2].lerp(HAZE, tint))
