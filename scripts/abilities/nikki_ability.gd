class_name NikkiAbility
extends MemberAbility
## Nikki (guitar): one double jump in the air; hold jump while falling to hover
## on the guitar like a hoverboard (drains stamina; once it runs out there's no
## more hover until she lands). Beer: members within 2 tiles heal 1 HP too.

const DOUBLE_JUMP_TILES := 2.2
const HOVER_FALL_SPEED := 25.0
const AURA_RADIUS := 48.0

var hovering := false
var double_jump_used := false
var hover_spent := false                    # ran out of stamina this fall


func physics_begin(delta: float) -> void:
	super(delta)
	if member.is_on_floor():
		double_jump_used = false
		hover_spent = false


func air_jump() -> bool:
	if double_jump_used:
		return false
	double_jump_used = true
	var height: float = DOUBLE_JUMP_TILES * TILE_PX
	member.jump_with(-sqrt(2.0 * member.gravity_value() * height))
	return true


func fall_cap(default_cap: float) -> float:
	return HOVER_FALL_SPEED if hovering else default_cap


func physics_end(delta: float) -> void:
	var was := hovering
	if member.stamina.is_exhausted and was:
		hover_spent = true
	hovering = not member.is_on_floor() and member.in_jump_held and member.velocity.y >= 0.0 \
		and not member.stamina.is_exhausted and not hover_spent
	if hovering:
		member.stamina.spend(config.hover_per_sec * delta)
		member.anim_override = &"idle"      # standing on the guitar
	elif was:
		member.anim_override = &""
	if hovering != was:
		queue_redraw()


func on_beer() -> void:
	for m in nearby_members(AURA_RADIUS):
		m.health.heal(1)


func reset() -> void:
	hovering = false
	double_jump_used = false
	hover_spent = false
	if member:
		member.anim_override = &""
	queue_redraw()


func _draw() -> void:
	if hovering:                            # the guitar as a hoverboard
		draw_rect(Rect2(-11, 0, 22, 3), Color("b5462e"))
		draw_rect(Rect2(8, -1, 7, 2), Color("e0c080"))
		draw_line(Vector2(-9, 4), Vector2(9, 4), Color(0.6, 0.9, 1.0, 0.7), 1.0)
