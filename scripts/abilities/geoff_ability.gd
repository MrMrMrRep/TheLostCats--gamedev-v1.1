class_name GeoffAbility
extends MemberAbility
## Geoff (vocals).
## Special (B): toy bubble gun. The bubbles do nothing to anyone, but some
## people (security, fans) can't help looking at them and drift after them.
## Instrument (L): the voice and the charm. Talks the nearest person out of
## the way: bouncers, the grumpy sound guy, security, bartenders, early-bird
## fans, managers, and opens staff-only doors. Rats and machines don't listen.
## (E on a person works too, up close.)
## While he's the one selected, everything is cheaper (Game.price()).

const BUBBLE_COOLDOWN := 0.5
const CHARM_RANGE := 80.0

var _bubble_cooldown := 0.0


func setup(m: BandMember) -> void:
	super(m)
	can_persuade = true


func physics_begin(delta: float) -> void:
	_bubble_cooldown = maxf(_bubble_cooldown - delta, 0.0)
	super(delta)


func special() -> void:
	blow_bubble()


func blow_bubble() -> Bubble:
	if _bubble_cooldown > 0.0:
		return null
	_bubble_cooldown = BUBBLE_COOLDOWN
	member.play_action(&"special")
	var bubble := Bubble.new()
	bubble.direction = member.facing
	spawn_parent().add_child(bubble)
	bubble.global_position = member.global_position + Vector2(member.facing * 10.0, -22)
	return bubble


func instrument_cost() -> float:
	return config.charm_cost if config else 0.0


## Only spend the charm on someone who can hear it.
func play_instrument() -> bool:
	if charm_target() == null:
		if not rats_near(member.global_position, CHARM_RANGE).is_empty():
			member.show_text("Can't charm a rat", Color(0.75, 0.8, 1.0))
		elif not nearby_in_group(&"hackable", CHARM_RANGE).is_empty():
			member.show_text("Machines don't listen", Color(0.75, 0.8, 1.0))
		else:
			member.show_text("Nobody to charm", Color(0.75, 0.8, 1.0))
		return false
	return super()


func instrument() -> void:
	charm()


## Persuade the nearest person or staff door in range. Returns who (or null).
func charm() -> Node:
	var target := charm_target()
	if target:
		Audio.sfx(&"talk", 0.0)
		target.persuade(member)
	return target


func charm_target() -> Node:
	for p in nearby_in_group(&"persuadable", CHARM_RANGE):
		if not p.persuaded:
			return p
	return null


func reset() -> void:
	super()
	_bubble_cooldown = 0.0
