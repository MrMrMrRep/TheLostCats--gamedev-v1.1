class_name StaminaSettings
extends Resource
## Stamina pool for one band member. Lives inside StaminaConfig.

@export var max_stamina := 100.0
@export var regen_rate := 30.0              ## per second, in the air
@export var regen_delay := 0.5              ## seconds after spending before regen starts
@export var ground_regen_mult := 2.0        ## regen multiplier while standing on the ground
@export var exhausted_threshold := 20.0     ## exhausted until stamina recovers above this
