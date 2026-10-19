@tool
class_name Bouncer
extends Interactable
## Bouncer: blocks a passage. Only a member who can persuade (Geoff) talks him
## aside; others get turned away. Resets on death.

const STEP_ASIDE := 18.0
const TINT := Color(0.32, 0.3, 0.36)
const BACKGROUND_TINT := Color(0.2, 0.18, 0.24)

@export var refusal := "Members only, mate."
@export var agreement := "Alright Geoff... go on."

var persuaded := false

var _start_position := Vector2.ZERO
var _blocker: StaticBody2D
var _sprite: AnimatedSprite2D


func _ready() -> void:
	area_size = Vector2(56, 40)
	super()
	_start_position = position
	_blocker = StaticBody2D.new()
	_blocker.collision_layer = 1 << 0       # world: blocks the band
	_blocker.collision_mask = 0
	var col := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 40)
	col.shape = rect
	col.position = Vector2(0, -20)
	_blocker.add_child(col)
	add_child(_blocker)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = load("res://resources/sprites/char_blue_frames.tres")
	_sprite.animation = &"idle"
	_sprite.offset = Vector2(0, -28)
	_sprite.scale = Vector2(1.3, 1.3)
	_sprite.flip_h = true
	_sprite.modulate = TINT
	add_child(_sprite)
	if not Engine.is_editor_hint():
		_sprite.play(&"idle")
		add_to_group(&"resettable")


func can_interact(_member: BandMember) -> bool:
	return not persuaded


func interact(member: BandMember, _level: Node) -> void:
	if member.ability and member.ability.can_persuade:
		persuade()
	else:
		say(refusal)


func persuade() -> void:
	if persuaded:
		return
	persuaded = true
	say(agreement)
	_blocker.set_deferred("process_mode", Node.PROCESS_MODE_DISABLED)
	# Side view: "aside" means stepping back into the background. Rooms are drawn
	# before the Band, so he already stands behind the members.
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, "position", Vector2(STEP_ASIDE, -3), 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_sprite, "modulate", BACKGROUND_TINT, 0.5)
	_sprite.play(&"run")
	tween.chain().tween_callback(_sprite.play.bind(&"idle"))


func reset_state() -> void:
	persuaded = false
	position = _start_position
	_sprite.position = Vector2.ZERO
	_sprite.modulate = TINT
	_sprite.play(&"idle")
	_blocker.process_mode = Node.PROCESS_MODE_INHERIT
