class_name MapCameraConfig
extends Resource
## The world map camera: how close it is, how fast it zooms, where it looks.
## File: resources/config/map_camera_config.tres.
## Zoom: higher = closer (3 = very close, 1 = normal, 0.5 = far away).
## Rates: higher = faster (they are "per second" ease speeds).

const PATH := "res://resources/config/map_camera_config.tres"

@export_group("On foot")
@export var zoom_walk := 3.0                ## standing or strolling
@export var zoom_walk_moving := 2.4         ## walking at full pace

@export_group("On the bikes")
@export var zoom_bike_slow := 2.6           ## rolling slowly
@export var zoom_bike := 2.0                ## at speed

@export_group("In the van")
@export var zoom_van_slow := 1.7            ## crawling or parked
@export var zoom_van := 1.3                 ## at speed in and around town (never further out)
@export var zoom_road := 0.5                ## the road trip: west of the ScenicFrom marker
@export var scenic_rate := 0.06             ## how slowly the road-trip view opens up

@export_group("Zoom speed")
@export var zoom_out_rate := 1.1            ## zooming out keeps up with the band (the van uses half)
@export var zoom_in_rate := 0.28            ## zooming in is slow, it settles over a while
@export var tempo_settle := 2.5             ## seconds the "tempo" takes to calm down after slowing

@export_group("Framing the band")
@export var focus_cap := 170.0              ## px: members further back than this don't widen the shot
@export var fit_margin := 80.0              ## px of room around the group
@export var focus_lead := 34.0              ## px the shot leads in the walking direction
@export var focus_ease := 3.0               ## how quickly the shot follows the group
@export var walk_look_ahead := 80.0         ## px the view leads on foot / bikes
@export var drive_look_ahead := 160.0       ## px the view leads in the van
@export var smoothing_speed := 4.0          ## camera smoothing (higher = snappier)
@export var deadzone := Vector2(24, 40)     ## half-size in px the target moves before the camera does

@export_group("Idle wander")
@export var idle_after := 15.0              ## seconds standing still before the camera wanders
@export var zoom_idle := 1.5                ## ...very slowly out to this zoom
@export var idle_zoom_rate := 0.05
@export var drift_period := 48.0            ## seconds for one slow sway left and right
@export var drift_max := 160.0              ## px; never so far the band leaves the frame
@export var drift_ease := 0.8

@export_group("Water strip")
@export_range(0.0, 0.5) var water_share := 0.13  ## part of the screen height showing canal under the street
@export var water_min := 22.0               ## px, at least this much water
@export var water_max := 160.0              ## px, at most this much water


static func current() -> MapCameraConfig:
	return LiveConfig.fetch(PATH, load("res://scripts/resources/map_camera_config.gd")) as MapCameraConfig
