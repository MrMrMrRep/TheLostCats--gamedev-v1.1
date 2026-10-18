class_name GeoffAbility
extends MemberAbility
## Geoff (vocals): talks people round (bouncers; via E). A blows a bubble that
## floats forward; rats near it stop to stare at it and don't bite.

const BUBBLE_COOLDOWN := 1.2

var _cooldown := 0.0


func setup(m: BandMember) -> void:
	super(m)
	can_persuade = true


func physics_begin(delta: float) -> void:
	super(delta)
	_cooldown = maxf(_cooldown - delta, 0.0)
	if member.in_a_pressed:
		blow_bubble()


func blow_bubble() -> Bubble:
	if _cooldown > 0.0:
		return null
	_cooldown = BUBBLE_COOLDOWN
	var bubble := Bubble.new()
	bubble.direction = member.facing
	var level := Level.of(member)
	(level if level else member.get_parent()).add_child(bubble)
	bubble.global_position = member.global_position + Vector2(member.facing * 10.0, -22)
	return bubble


func reset() -> void:
	_cooldown = 0.0
