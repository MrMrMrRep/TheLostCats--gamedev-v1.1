class_name MemberAbility
extends Node2D
## Base for a band member's unique abilities. BandMember calls these hooks each
## physics frame; override the ones you need. Input comes from member.in_*.
## Default: B drinks a beer (The Germ uses B for his shield instead).

const TILE_PX := 24.0

var member: BandMember
var config: StaminaConfig

## Lets Geoff's lines work on the bouncer.
var can_persuade := false
## Lets Joep use hack panels.
var can_hack := false


func setup(m: BandMember) -> void:
	member = m
	config = m.stamina_config


## Start of the frame, before any movement.
func physics_begin(_delta: float) -> void:
	if uses_b_for_drink() and member.in_b_pressed:
		member.drink_beer()


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


func uses_b_for_drink() -> bool:
	return true


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
	pass


## Other members within `radius` px in the same room (via the Level), nearest first.
func nearby_members(radius: float) -> Array[BandMember]:
	var out: Array[BandMember] = []
	var level := Level.of(member)
	for m: BandMember in member.get_parent().get_children().filter(func(n: Node) -> bool: return n is BandMember):
		if m == member or m.is_dead:
			continue
		if level and level.room_of_member(m) != level.room_of_member(member):
			continue
		if m.global_position.distance_to(member.global_position) <= radius:
			out.append(m)
	out.sort_custom(func(a: BandMember, b: BandMember) -> bool:
		return a.global_position.distance_squared_to(member.global_position) < b.global_position.distance_squared_to(member.global_position))
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
	for hit in member.get_world_2d().direct_space_state.intersect_shape(q, 16):
		out.append(hit.collider)
	return out
