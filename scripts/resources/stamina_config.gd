class_name StaminaConfig
extends Resource
## The one place for all stamina numbers: per-member pools, the shared run and
## the cost of each special and instrument skill. A member without an entry
## has no stamina (can't run or play their instrument).

@export var members: Dictionary[StringName, StaminaSettings] = {}

@export_group("Shared")
@export var run_per_sec := 12.0             ## holding Shift while moving on the ground
@export var instrument_cooldown := 3.0      ## seconds before any instrument skill works again

@export_group("Special skills")
@export var lift_per_sec := 20.0            ## Jay holding a lifted flight case
@export var rage_punch_cost := 30.0         ## The Germ's fire punch / slam

@export_group("Instrument skills")
@export var shock_cost := 60.0              ## Joep: electric shockwave
@export var slap_cost := 40.0               ## Jay: slap bass
@export var beat_cost := 70.0               ## The Germ: Drumbeat Master (time stop / rewind)
@export var solo_cost := 50.0               ## Nikki: guitar solo bridge
@export var charm_cost := 15.0              ## Geoff: the voice and the charm


func for_member(id: StringName) -> StaminaSettings:
	return members.get(id)
