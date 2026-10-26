class_name ScreenFit
## The screen is always 360 px tall; its width follows the device (640 on a
## 16:9 screen, wider on phones). UI is laid out on the 640-wide base screen;
## these helpers keep a control at the left, centre or right of the real one.

const BASE := Vector2(640, 360)


## Keep `c` where it is on the base screen, measured from the left (0.0),
## the centre (0.5) or the right edge (1.0) of the real screen. Call it after
## setting position and size; `c` must sit directly in a CanvasLayer.
static func pin(c: Control, edge: float) -> void:
	var left := c.offset_left
	var right := c.offset_right
	c.anchor_left = edge
	c.anchor_right = edge
	c.offset_left = left - BASE.x * edge
	c.offset_right = right - BASE.x * edge


## Stretch `c` across the whole width (keeps its y and height).
static func full_width(c: Control) -> void:
	c.anchor_left = 0.0
	c.anchor_right = 1.0
	c.offset_left = 0.0
	c.offset_right = 0.0


## Real screen width in base pixels.
static func width(node: CanvasItem) -> float:
	return node.get_viewport_rect().size.x
