class_name TrafficConfig
extends Resource
## Cars, vans, trucks, buses and bikes on the world map's road.
## File: resources/config/traffic_config.tres. Where cars may drive or park
## is set per district by the Zone nodes in the world map (Zones folder).

const PATH := "res://resources/config/traffic_config.tres"

@export_group("How many")
@export var per_screen_road := 4            ## moving vehicles per screen width outside town (each lane)
@export var per_screen_town := 2            ## in town (back lane only)

@export_group("Speeds (px/s, random in range)")
@export var car_speed := Vector2(110, 190)
@export var van_speed := Vector2(100, 170)
@export var truck_speed := Vector2(80, 120)
@export var bus_speed := Vector2(70, 110)
@export var bike_speed := Vector2(40, 60)
@export var town_slowdown := 0.55           ## motor vehicles in town drive this fraction of their speed

@export_group("Mix in town")
@export_range(0.0, 1.0) var town_bikes := 0.45   ## share of bikes
@export_range(0.0, 1.0) var town_buses := 0.07
@export_range(0.0, 1.0) var town_vans := 0.10

@export_group("Mix on the motorway")
@export_range(0.0, 1.0) var road_trucks := 0.18
@export_range(0.0, 1.0) var road_vans := 0.18
@export_range(0.0, 1.0) var road_buses := 0.04

@export_group("Parked cars")
@export_range(0.0, 1.0) var parked_fill := 0.82  ## chance each parking space has a car
@export_range(0.0, 1.0) var parked_vans := 0.18  ## share of parked vans


static func current() -> TrafficConfig:
	return LiveConfig.fetch(PATH, load("res://scripts/resources/traffic_config.gd")) as TrafficConfig


## Random speed for a vehicle kind (WorldTraffic.Kind order: CAR, VAN, TRUCK, BIKE, BUS).
func speed_range(kind: int) -> Vector2:
	return [car_speed, van_speed, truck_speed, bike_speed, bus_speed][kind]
