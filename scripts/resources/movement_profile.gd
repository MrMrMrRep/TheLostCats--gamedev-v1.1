class_name MovementProfile
extends Resource
## Movement feel for one band member, tuned by outcome (tiles, seconds).
## Gravity and jump speed are derived from jump height and time to apex.
## Stat -> tiles mapping lives in docs/gdd-review.md (section 3.1).

const TILE := 24.0

@export var id: StringName
@export var display_name := ""
@export var tint := Color.WHITE
@export var max_hp := 3                     ## Geoff has 1
@export var ability: Script                 ## MemberAbility subclass (scripts/abilities/)

@export_group("Run")
@export var run_speed_tiles := 7.0          ## top speed, tiles per second
@export var accel_time := 0.08              ## seconds from standstill to top speed
@export var decel_time := 0.06              ## seconds from top speed to standstill
@export_range(0.0, 1.0) var air_control := 0.8  ## acceleration multiplier in the air

@export_group("Jump")
@export var jump_height_tiles := 3.0        ## apex height when jump is held
@export var time_to_apex := 0.34            ## seconds from takeoff to apex
@export var fall_gravity_mult := 1.8        ## heavier fall, snappy non-floaty arc
@export var max_fall_tiles := 18.0          ## terminal fall speed, tiles per second
@export var fast_fall_tiles := 26.0         ## terminal fall speed while holding down
@export_range(0.0, 1.0) var jump_cut := 0.45  ## upward speed kept when jump is released early
@export_range(0.0, 1.0) var apex_hang_mult := 0.5  ## gravity multiplier near the apex (jump held)
@export var apex_threshold := 60.0          ## |vertical speed| in px/s that counts as "near apex"

@export_group("Forgiveness")
@export var coyote_time := 0.1              ## jump still works this long after leaving a ledge
@export var jump_buffer := 0.12             ## jump pressed this long before landing still fires
@export var ceiling_correction_px := 4      ## slide past ceiling corners clipped by up to N px
@export var ledge_correction_px := 3        ## pop onto ledges missed by up to N px


func gravity() -> float:
	var height := jump_height_tiles * TILE
	return 2.0 * height / (time_to_apex * time_to_apex)


func jump_velocity() -> float:
	return -2.0 * jump_height_tiles * TILE / time_to_apex


func run_speed() -> float:
	return run_speed_tiles * TILE
