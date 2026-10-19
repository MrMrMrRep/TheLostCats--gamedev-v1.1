@tool
class_name Vehicle
extends Interactable
## Band transport on the world map. BIKES: the whole band rides (1.6x walking
## speed), get on and off anywhere; parked bikes wait where you left them.
## VAN: 3x walking speed with smooth acceleration, but you can only get in and
## out at a P parking spot. The WorldMap drives it; position persists in Game.

enum Kind { BIKES, VAN }

@export var kind := Kind.BIKES:
	set(value):
		kind = value
		queue_redraw()
@export var save_id: StringName             ## Game flag key for the parked position

const VAN_SHEET := preload("res://public/assets/vehicles/band_van.png")
const VAN_FRAME := Vector2(112, 56)
const VAN_GROUND := 50.0                    # tyre bottoms in the frame
const VAN_FRAMES := 4

var velocity := Vector2.ZERO
var _odometer := 0.0
var facing := 1.0
var occupied := false:
	set(value):
		occupied = value
		queue_redraw()


func _ready() -> void:
	area_size = Vector2(96, 40) if kind == Kind.VAN else Vector2(40, 24)
	super()


func interact(_member: BandMember, map: Node) -> void:
	if map.has_method("board"):
		map.board(self)


func speed_mult() -> float:
	return 3.0 if kind == Kind.VAN else 1.6


func accel_time() -> float:
	return 0.9 if kind == Kind.VAN else 0.3


func display_name() -> String:
	return "band van" if kind == Kind.VAN else "bikes"


## Accelerate toward `dir` (-1..1) at `top` px/s; stays within [min_x, max_x].
func drive(dir: float, top: float, delta: float, min_x: float, max_x: float) -> void:
	var rate := top / accel_time()
	if dir != 0.0:
		facing = signf(dir)
		velocity.x = move_toward(velocity.x, dir * top, rate * delta)
	else:
		velocity.x = move_toward(velocity.x, 0.0, rate * 1.5 * delta)
	var before := position.x
	position.x = clampf(position.x + velocity.x * delta, min_x, max_x)
	_odometer += absf(position.x - before)
	if position.x <= min_x or position.x >= max_x:
		velocity.x = 0.0
	queue_redraw()


func save_position() -> void:
	if save_id != &"":
		Game.set_flag(save_id, position.x)


func restore_position() -> void:
	if save_id != &"":
		position.x = Game.get_flag(save_id, position.x)


func _draw() -> void:
	if kind == Kind.VAN:
		_draw_van()
	elif not occupied:                      # riding bikes are drawn under each member
		for i in 3:
			BikeSprite.draw_bike(self, Vector2(-12 + i * 10, 0), 1.0, Color(0.85, 0.85, 0.9, 0.9 - i * 0.15))


func _draw_van() -> void:
	var frame := int(_odometer / 3.0) % VAN_FRAMES
	var src := Rect2(Vector2(frame * VAN_FRAME.x, 0), VAN_FRAME)
	draw_set_transform(Vector2.ZERO, 0.0, Vector2(facing, 1.0))
	draw_texture_rect_region(VAN_SHEET, Rect2(Vector2(-VAN_FRAME.x / 2.0, -VAN_GROUND), VAN_FRAME), src)
	draw_set_transform(Vector2.ZERO)
