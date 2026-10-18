class_name StaminaConfig
extends Resource
## The one place for all stamina numbers: per-member pools and ability costs.
## Values from docs/gdd-review.md section 4. Members without an entry (Geoff)
## don't use stamina.

@export var members: Dictionary[StringName, StaminaSettings] = {}

@export_group("Costs")
@export var climb_per_sec := 25.0           ## Joep climbing
@export var wall_jump_cost := 15.0          ## Joep, per wall jump
@export var hover_per_sec := 45.0           ## Nikki guitar hover (~2.2 s from full)
@export var shield_per_sec := 30.0          ## The Germ holding the drumstick shield
@export var shield_hit_cost := 10.0         ## The Germ, per blocked hit
@export var lift_per_sec := 20.0            ## Jay holding a lifted object or member


func for_member(id: StringName) -> StaminaSettings:
	return members.get(id)
