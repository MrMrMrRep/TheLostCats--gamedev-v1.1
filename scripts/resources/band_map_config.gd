class_name BandMapConfig
extends Resource
## How the band walks and follows the leader on the world map.
## File: resources/config/band_map_config.tres. (Jump height, run speed in
## levels etc. live per member in resources/profiles/*.tres.)

const PATH := "res://resources/config/band_map_config.tres"

@export_group("Walking")
@export var walk_speed := 85.0              ## px/s, a calm walk on the map (levels keep their run)
@export var walk_gap := 26.0                ## px: each member walks about this much further back than the one before
@export var gap_jitter := 5.0               ## px of random extra/less gap per member
@export var catch_up := 90.0                ## px further behind than their gap: they jog
@export var jog_factor := 1.9               ## jogging speed = walk speed x this
@export var follow_accel := 380.0           ## px/s² a follower speeds up / slows down

@export_group("Little pauses")
@export var pause_every := Vector2(5.0, 12.0)    ## seconds of walking between short stops (random in range)
@export var pause_length := Vector2(0.4, 1.3)    ## seconds a stop lasts (a look around, a sip)
@export var fidget_after := Vector2(2.5, 7.0)    ## seconds standing before someone smokes, drinks or plays

@export_group("On the bikes")
@export var ride_gap := 30.0                ## px: each rider keeps about this much more distance than the one before
@export var ride_jitter := 6.0              ## px of random extra/less gap per rider
@export var ride_sway := 10.0               ## px the gaps drift in and out while riding (a loose group)
@export var ride_catch_up := 120.0          ## px further behind than their gap: they pedal hard to catch up
@export var ride_sprint := 1.2              ## catching up: up to the bikes' top speed x this
@export var ride_follow := 1.4              ## how firmly riders close the gap (speed per px off their spot)


static func current() -> BandMapConfig:
	return LiveConfig.fetch(PATH, load("res://scripts/resources/band_map_config.gd")) as BandMapConfig
