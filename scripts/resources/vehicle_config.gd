class_name VehicleConfig
extends Resource
## How the bikes and the band van drive on the world map.
## File: resources/config/vehicle_config.tres. Speeds are in pixels per second
## (the band walks 85 px/s on the map; a house is about 60 px wide).

const PATH := "res://resources/config/vehicle_config.tres"

@export_group("Top speed")
@export var bikes_top_speed := 150.0        ## px/s
@export var van_top_speed := 295.0          ## px/s, on the open road
@export var city_speed := 190.0             ## px/s: the van's speed limit between the SpeedLimit markers
@export var limit_ease := 220.0             ## px/s² the van slows down by itself when over a limit

@export_group("Bikes feel")
@export var bikes_pull := 420.0             ## px/s² pedalling from standstill (fades near top speed)
@export var bikes_brake := 520.0            ## px/s² steering the other way
@export var bikes_rolling := 60.0           ## px/s² slowing down when you let go
@export var bikes_drag := 0.3               ## extra slowing per px/s of speed (air drag)

@export_group("Van feel")
@export var van_pull := 240.0               ## px/s² engine pull from standstill (fades near top speed)
@export var van_brake := 520.0              ## px/s² steering the other way
@export var van_rolling := 34.0             ## px/s² slowing down when you let go
@export var van_drag := 0.12                ## extra slowing per px/s of speed (air drag)
@export var skid_from := 60.0               ## px/s: braking faster than this locks the wheels (smoke, marks)
@export var skid_marks_last := 6.0          ## seconds the skid marks stay on the road

@export_group("Van body")
@export var pitch_per_accel := 0.000045     ## body tilt (radians) per px/s² of speeding up / braking
@export var pitch_max := 0.045              ## most the body tilts (radians)
@export var pitch_spring := 90.0            ## how hard the springs pull the body level
@export var pitch_damp := 9.0               ## how fast the bounce dies out

@export_group("Van lanes")
@export var lane_town := 14.0               ## px below the street line the van drives and parks in town (on the cobbles)
@export var lane_east := 4.0                ## px lower on the motorway heading into the city (east)
@export var lane_west := -5.0               ## px (negative = higher) heading out of the city (west)
@export var lane_change := 10.0             ## px/s: how gently the van changes lane


static func current() -> VehicleConfig:
	return LiveConfig.fetch(PATH, load("res://scripts/resources/vehicle_config.gd")) as VehicleConfig


## [pull, brake, rolling, drag] for bikes or van.
func feel(van: bool) -> Array[float]:
	if van:
		return [van_pull, van_brake, van_rolling, van_drag]
	return [bikes_pull, bikes_brake, bikes_rolling, bikes_drag]
