@tool
class_name StorageGate
extends WorldDoor
## The sliding gate in front of the band's storage car park. Locked: the keypad
## wants a code (for now Joep hacks it with his phone; the code hunt comes with
## the first mission). Open: it's the door into the level. Open state is the
## Game flag `open_flag`.

@export var open_flag: StringName = &"storage_gate_open"

var _slide := 0.0                           # 0 closed .. 1 open (animated)


func _ready() -> void:
	width = 64.0
	super()
	_slide = 1.0 if is_open() else 0.0
	if not Engine.is_editor_hint():
		Game.flag_changed.connect(func(_f: StringName, _v: Variant) -> void: queue_redraw())


func is_open() -> bool:
	return not Engine.is_editor_hint() and bool(Game.get_flag(open_flag, false))


func prompt_text() -> String:
	return "E  enter" if is_open() else "E  keypad"


func interact(member: BandMember, map: Node) -> void:
	if is_open():
		super(member, map)
	elif map.has_method("hack_gate"):
		map.hack_gate(self)


func open() -> void:
	Game.set_flag(open_flag, true)
	var tween := create_tween()
	tween.tween_method(func(v: float) -> void:
		_slide = v
		queue_redraw(), _slide, 1.0, 1.2).set_trans(Tween.TRANS_SINE)


func _draw() -> void:
	var p := WorldPalette
	var half := width / 2.0
	# Posts and the keypad on the right post.
	draw_rect(Rect2(-half - 4, -34, 4, 34), p.IRON)
	draw_rect(Rect2(half, -34, 4, 34), p.IRON)
	draw_rect(Rect2(half + 5, -24, 5, 7), Color("2c2a33"))
	draw_rect(Rect2(half + 6, -23, 3, 2), Color("6fe08a") if is_open() else Color("e05a4a"))
	# Gate leaf: slides to the left behind the fence.
	var x0 := -half - _slide * width
	var x1 := x0 + width
	draw_rect(Rect2(x0, -30, width, 2), WorldPalette.ORANGE)
	draw_rect(Rect2(x0, -4, width, 2), WorldPalette.ORANGE)
	var x := x0
	while x <= x1:
		draw_rect(Rect2(x, -30, 1, 28), p.IRON)
		x += 4
	# Fence continuing to the left (the gate slides behind it).
	draw_rect(Rect2(-half - 4 - width, -26, width, 1), p.IRON)
	var f := -half - 4 - width
	while f < -half - 4:
		draw_rect(Rect2(f, -26, 1, 26), p.IRON.lightened(0.15))
		f += 4
