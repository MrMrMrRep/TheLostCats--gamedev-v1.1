class_name PeopleConfig
extends Resource
## People walking along the street on the world map.
## File: resources/config/people_config.tres. How busy each district is lives
## on the Zone nodes in the world map (Zones folder, "People per screen").

const PATH := "res://resources/config/people_config.tres"

@export var busy_scale := 1.0               ## multiplies every zone's people count (0 = nobody)
@export var walk_speed := Vector2(16, 28)   ## px/s, random in range
@export_range(0.0, 1.0) var kids := 0.12    ## share of kids
@export var kid_speed := 0.8                ## kids walk this fraction of the speed
@export var stop_chance := 0.04             ## chance per second someone stops to look in a window
@export var stop_length := Vector2(1.0, 3.5)  ## seconds a stop lasts


static func current() -> PeopleConfig:
	return LiveConfig.fetch(PATH, load("res://scripts/resources/people_config.gd")) as PeopleConfig
