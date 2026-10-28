@tool
class_name TimedGate
extends Gate
## A gate on a timer: its switch opens it for `open_time` seconds, then it
## slams shut again. Too quick for the slow members on their own; The Germ's
## Drumbeat Master stops the clock with it open (it's in the "timed" group).

@export var open_time := 1.5

var open_left := 0.0


func _ready() -> void:
	super()
	if not Engine.is_editor_hint():
		add_to_group(&"timed")


func trigger() -> void:
	open()


func open() -> void:
	solid = false
	open_left = open_time


func close() -> void:
	solid = true
	open_left = 0.0


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or open_left <= 0.0:
		return
	open_left -= delta
	queue_redraw()
	if open_left <= 0.0:
		solid = true


func reset_state() -> void:
	super()
	open_left = 0.0


## Drumbeat Master: what a rewind puts back.
func time_state() -> Array:
	return [open_left, solid]


func set_time_state(state: Array) -> void:
	open_left = state[0]
	solid = state[1]


func _draw() -> void:
	super()
	if not solid and open_time > 0.0:      # the timer, as a shrinking bar above the gap
		var r := _rect()
		draw_rect(Rect2(r.position.x, r.position.y - 6, r.size.x * clampf(open_left / open_time, 0.0, 1.0), 2), Color("ffd36b"))
