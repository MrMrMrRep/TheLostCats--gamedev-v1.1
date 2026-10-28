@tool
class_name Bouncer
extends Interactable
## A person blocking a passage: bouncer, grumpy sound guy, security, bartender,
## early-bird fan, manager (`role`). Only Geoff talks them out of the way: his
## charm (instrument, L) from a few steps away, or E up close. Everyone else
## gets `refusal`. A `distractible` one also turns to look at Geoff's bubbles
## and wanders after them for a moment, leaving the way open. Resets on death.

const STEP_ASIDE := 18.0
const WANDER := 40.0                        # px a distracted person drifts after a bubble
const TINT := Color(0.32, 0.3, 0.36)
const BACKGROUND_TINT := Color(0.2, 0.18, 0.24)

@export var role := "Bouncer"
@export var refusal := "Members only, mate."
@export var agreement := "Alright Geoff... go on."
@export var distractible := false           ## follows Geoff's bubbles with their eyes (and feet)
@export var tint := TINT

var persuaded := false
var distracted_left := 0.0

var _start_position := Vector2.ZERO
var _blocker: StaticBody2D
var _blocker_shape: CollisionShape2D
var _sprite: AnimatedSprite2D
var _look_x := 0.0


func _ready() -> void:
	area_size = Vector2(56, 40)
	super()
	_start_position = position
	_blocker = StaticBody2D.new()
	_blocker.collision_layer = 1 << 0       # world: blocks the band
	_blocker.collision_mask = 0
	_blocker_shape = CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(16, 40)
	_blocker_shape.shape = rect
	_blocker_shape.position = Vector2(0, -20)
	_blocker.add_child(_blocker_shape)
	add_child(_blocker)
	_sprite = AnimatedSprite2D.new()
	_sprite.sprite_frames = load("res://resources/sprites/char_blue_frames.tres")
	_sprite.animation = &"idle"
	_sprite.offset = Vector2(0, -28)
	_sprite.scale = Vector2(1.3, 1.3)
	_sprite.flip_h = true
	_sprite.modulate = tint
	add_child(_sprite)
	if not Engine.is_editor_hint():
		_sprite.play(&"idle")
		add_to_group(&"resettable")
		add_to_group(&"human")
		add_to_group(&"persuadable")


func can_interact(_member: BandMember) -> bool:
	return not persuaded


func interact(member: BandMember, _level: Node) -> void:
	if member.ability and member.ability.can_persuade:
		persuade(member)
	else:
		say(refusal)


## Geoff's charm: steps aside for good (until the room resets).
func persuade(_by: BandMember = null) -> bool:
	if persuaded:
		return false
	persuaded = true
	distracted_left = 0.0
	say(agreement)
	_blocker_shape.set_deferred("disabled", true)
	# Side view: "aside" means stepping back into the background. Rooms are drawn
	# before the Band, so they already stand behind the members.
	var tween := create_tween().set_parallel()
	tween.tween_property(_sprite, "position", Vector2(STEP_ASIDE, -3), 0.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_sprite, "modulate", BACKGROUND_TINT, 0.5)
	_sprite.play(&"run")
	tween.chain().tween_callback(_sprite.play.bind(&"idle"))
	return true


## Geoff's bubble at `pos`: a distractible person turns and drifts after it.
func distract(pos: Vector2, seconds: float) -> void:
	if not distractible or persuaded:
		return
	if distracted_left <= 0.0:
		say("Ooh, bubbles...", 1.0)
	distracted_left = maxf(distracted_left, seconds)
	_look_x = clampf(pos.x - global_position.x, -WANDER, WANDER)
	_blocker_shape.set_deferred("disabled", true)


func _physics_process(delta: float) -> void:
	if Engine.is_editor_hint() or persuaded:
		return
	if distracted_left > 0.0:
		distracted_left -= delta
		_sprite.position.x = move_toward(_sprite.position.x, _look_x, 40.0 * delta)
		_sprite.flip_h = _look_x < 0.0
		_sprite.modulate = BACKGROUND_TINT
		if distracted_left <= 0.0:
			_sprite.flip_h = true
	elif _sprite.position.x != 0.0:
		_sprite.position.x = move_toward(_sprite.position.x, 0.0, 40.0 * delta)
		if _sprite.position.x == 0.0 and not _member_in_the_way():
			_blocker_shape.set_deferred("disabled", false)
			_sprite.modulate = tint


func _member_in_the_way() -> bool:
	for body in get_overlapping_bodies():
		if body is BandMember and absf(body.global_position.x - global_position.x) < 14.0:
			return true
	return false


func reset_state() -> void:
	persuaded = false
	distracted_left = 0.0
	position = _start_position
	_sprite.position = Vector2.ZERO
	_sprite.modulate = tint
	_sprite.flip_h = true
	_sprite.play(&"idle")
	_blocker_shape.set_deferred("disabled", false)
