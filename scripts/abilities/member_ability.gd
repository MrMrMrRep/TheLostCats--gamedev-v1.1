class_name MemberAbility
extends Node2D
## A band member's skills. Every member has the same base set (walk, run,
## crouch and wall-slide live in BandMember):
##   A (J)  punch: knocks rats back; with a weapon selected (mic stand) it
##          swings that instead, reaches further and knocks rats out
##   B (K)  special(): the member's own skill
##   L      instrument(): the member's instrument skill. Costs stamina
##          (instrument_cost()) and has a shared cooldown.
## BandMember calls the hooks below each physics frame; override what you need.
## Input comes from member.in_*.

const TILE_PX := 24.0
const PUNCH_SIZE := Vector2(22, 22)
const PUNCH_COOLDOWN := 0.35
const PUNCH_KNOCKBACK := Vector2(160, -100)
const MASK_WORLD := 1 << 0
const MASK_ENEMY := 1 << 3

var member: BandMember
var config: StaminaConfig

## Lets Geoff's lines work on bouncers and other people.
var can_persuade := false
## Lets Joep use hack panels with E as well.
var can_hack := false

var _punch_cooldown := 0.0
var _instrument_cooldown := 0.0


func setup(m: BandMember) -> void:
	member = m
	config = m.stamina_config


## Start of the frame, before any movement.
func physics_begin(delta: float) -> void:
	_punch_cooldown = maxf(_punch_cooldown - delta, 0.0)
	_instrument_cooldown = maxf(_instrument_cooldown - delta, 0.0)
	if busy():
		return
	if member.in_a_pressed:
		punch()
	if member.in_b_pressed:
		special()
	if member.in_instrument_pressed:
		play_instrument()


## True while a skill has the member's hands full (swinging, dashing...): no punch.
func busy() -> bool:
	return false


# --- Punch (everyone) ------------------------------------------------------

## Returns the bodies hit. A weapon in the selected slot is swung instead of a fist.
func punch() -> Array:
	if _punch_cooldown > 0.0:
		return []
	_punch_cooldown = PUNCH_COOLDOWN
	var weapon := member.held_weapon()
	var reach: float = weapon.weapon_reach if weapon else PUNCH_SIZE.x
	member.play_action(&"punch")
	Audio.sfx(&"punch")
	var center: Vector2 = member.global_position + Vector2(member.facing * (reach / 2.0 + 4.0), -14)
	var hits := query_box(center, Vector2(reach, PUNCH_SIZE.y), MASK_ENEMY)
	for body in hits:
		if body is Rat:
			if weapon:
				body.defeat()
			else:
				body.knockback(Vector2(member.facing * PUNCH_KNOCKBACK.x, PUNCH_KNOCKBACK.y))
	return hits


# --- Special and instrument (per member) ------------------------------------

## B: the member's own skill.
func special() -> void:
	pass


## L: checks the cooldown and stamina, then plays instrument().
func play_instrument() -> bool:
	if _instrument_cooldown > 0.0:
		member.show_text("Not yet...", Color(0.75, 0.8, 1.0))
		return false
	if not member.stamina.try_spend(instrument_cost()):
		member.show_text("Too tired", Color(0.75, 0.8, 1.0))
		return false
	_instrument_cooldown = config.instrument_cooldown if config else 0.0
	member.play_action(&"instrument")
	instrument()
	return true


func instrument() -> void:
	pass


func instrument_cost() -> float:
	return 0.0


## Ready to play again (tests and the HUD).
func instrument_ready() -> bool:
	return _instrument_cooldown <= 0.0


# --- Movement hooks ----------------------------------------------------------

## Return true to take over movement completely this frame (call member.move_body).
func custom_physics(_delta: float) -> bool:
	return false


## Jump pressed in the air without coyote time. Return true if used.
func air_jump() -> bool:
	return false


func locks_horizontal() -> bool:
	return false


func speed_mult() -> float:
	return 1.0


func gravity_scale() -> float:
	return 1.0


func fall_cap(default_cap: float) -> float:
	return default_cap


## After the normal move_and_slide.
func physics_end(_delta: float) -> void:
	pass


func blocks_damage(_from: Vector2) -> bool:
	return false


func on_beer() -> void:
	pass


func on_landed(_fall_speed: float) -> void:
	pass


func on_hurt() -> void:
	pass


func on_deactivated() -> void:
	reset()


## Clear all ability state (respawn, switching away).
func reset() -> void:
	_punch_cooldown = 0.0
	_instrument_cooldown = 0.0


# --- Helpers ----------------------------------------------------------------

## Other members within `radius` px in the same room, nearest first.
func nearby_members(radius: float) -> Array[BandMember]:
	return member.nearby_members(radius)


## Nodes in `group` within `radius` px of the member, nearest first.
func nearby_in_group(group: StringName, radius: float) -> Array:
	var pos := member.global_position + Vector2(0, -14)
	var out := []
	for n in member.get_tree().get_nodes_in_group(group):
		var n2 := n as Node2D
		if n2 and n2.is_visible_in_tree() and n2.global_position.distance_to(pos) <= radius:
			out.append(n2)
	out.sort_custom(func(a: Node2D, b: Node2D) -> bool:
		return a.global_position.distance_squared_to(pos) < b.global_position.distance_squared_to(pos))
	return out


## Physics bodies/areas overlapping a box in front of the member.
func query_box(center: Vector2, size: Vector2, mask: int, areas := false) -> Array:
	var shape := RectangleShape2D.new()
	shape.size = size
	var q := PhysicsShapeQueryParameters2D.new()
	q.shape = shape
	q.transform = Transform2D(0.0, center)
	q.collision_mask = mask
	q.collide_with_areas = areas
	q.collide_with_bodies = not areas
	var out := []
	for hit in member.get_world_2d().direct_space_state.intersect_shape(q, 32):
		out.append(hit.collider)
	return out


## Where spawned things (bubbles, bridges) go: the level, else the member's parent.
func spawn_parent() -> Node:
	var level := Level.of(member)
	return level if level else member.get_parent()


## Rats within `radius` px of `center` (alive ones).
func rats_near(center: Vector2, radius: float) -> Array:
	var out := []
	for rat in member.get_tree().get_nodes_in_group(&"rat"):
		if rat.alive and rat.global_position.distance_to(center) <= radius:
			out.append(rat)
	return out
