class_name DayConfig
extends Resource
## The day on the world map: when it starts, how long each part of the day
## lasts in real minutes, and its colours.
## File: resources/config/day_config.tres. The clock only runs on the world
## map; the story can set it (a gig at 18:00, 4:00 after a show).

const PATH := "res://resources/config/day_config.tres"

@export_range(0.0, 24.0, 0.25) var start_hour := 8.0   ## clock time when a new game starts
@export var clock_runs := true              ## off: time stands still (handy while building)
@export var time_buttons := true            ## show the +1 / +4 / +8 hour buttons under the clock (testing)
@export var sleep_fade := 0.6               ## seconds the screen takes to fade out (and back in) when skipping time

@export_group("How long each part lasts (real minutes)")
@export var night_minutes := 3.0            ## from night_starts until dawn_starts
@export var dawn_minutes := 1.0             ## from dawn_starts until morning_starts
@export var morning_minutes := 4.0          ## from morning_starts until afternoon_starts
@export var afternoon_minutes := 4.0        ## from afternoon_starts until evening_starts
@export var evening_minutes := 2.0          ## golden hour: from evening_starts until dusk_starts
@export var dusk_minutes := 1.0             ## from dusk_starts until night_starts

@export_group("When each part starts (clock hour)")
@export_range(0.0, 24.0, 0.25) var dawn_starts := 5.0
@export_range(0.0, 24.0, 0.25) var morning_starts := 7.0
@export_range(0.0, 24.0, 0.25) var afternoon_starts := 12.0
@export_range(0.0, 24.0, 0.25) var evening_starts := 17.0
@export_range(0.0, 24.0, 0.25) var dusk_starts := 20.0
@export_range(0.0, 24.0, 0.25) var night_starts := 22.0

@export_group("Lights")
@export_range(0.0, 24.0, 0.25) var lights_on_from := 19.0   ## street lights and windows start coming on
@export_range(0.0, 24.0, 0.25) var lights_full_at := 21.0   ## ...all on
@export_range(0.0, 24.0, 0.25) var lights_dim_from := 5.5   ## morning: they start going off
@export_range(0.0, 24.0, 0.25) var lights_off_at := 7.0     ## ...all off
@export_range(0.0, 1.0) var night_windows := 0.55           ## share of windows lit deep in the night

@export_group("Colours (left = 00:00, middle = 12:00, right = 24:00)")
@export var world_tint: Gradient            ## multiplies the whole street (white = daylight)
@export var sky_top: Gradient
@export var sky_mid: Gradient
@export var sky_low: Gradient


static func current() -> DayConfig:
	return LiveConfig.fetch(PATH, load("res://scripts/resources/day_config.gd")) as DayConfig


## [name, start hour, real minutes] per part, in clock order from midnight.
func parts() -> Array:
	var out := [["Night", night_starts, night_minutes], ["Dawn", dawn_starts, dawn_minutes],
		["Morning", morning_starts, morning_minutes], ["Afternoon", afternoon_starts, afternoon_minutes],
		["Evening", evening_starts, evening_minutes], ["Dusk", dusk_starts, dusk_minutes]]
	out.sort_custom(func(a: Array, b: Array) -> bool: return a[1] < b[1])
	return out


## The part of the day at `hour`: [name, start, minutes, end].
func part_at(hour: float) -> Array:
	var ps := parts()
	for i in ps.size():
		var start: float = ps[i][1]
		var end: float = ps[(i + 1) % ps.size()][1]
		var len := fposmod(end - start, 24.0)
		if fposmod(hour - start, 24.0) < len:
			return [ps[i][0], start, ps[i][2], end]
	return [ps[0][0], ps[0][1], ps[0][2], ps[1][1]]


## The clock `seconds` of real time after `hour`.
func advance(hour: float, seconds: float) -> float:
	var guard := 0
	while seconds > 0.0 and guard < 12:
		guard += 1
		var p := part_at(hour)
		var span := fposmod(p[3] - p[1], 24.0)
		var real := maxf(float(p[2]) * 60.0, 0.01)      # real seconds for the whole part
		var rate := span / real                        # clock hours per real second
		var left := fposmod(p[3] - hour, 24.0)
		if left <= 0.0:
			left = span
		if seconds * rate < left:
			return fposmod(hour + seconds * rate, 24.0)
		seconds -= left / rate
		hour = fposmod(p[3] + 0.0001, 24.0)
	return hour


## 0 by day .. 1 at night: how much the lights are on.
func night(hour: float) -> float:
	if _between(hour, lights_full_at, lights_dim_from):
		return 1.0
	if _between(hour, lights_on_from, lights_full_at):
		return smoothstep(0.0, 1.0, fposmod(hour - lights_on_from, 24.0) / maxf(fposmod(lights_full_at - lights_on_from, 24.0), 0.01))
	if _between(hour, lights_dim_from, lights_off_at):
		return 1.0 - smoothstep(0.0, 1.0, fposmod(hour - lights_dim_from, 24.0) / maxf(fposmod(lights_off_at - lights_dim_from, 24.0), 0.01))
	return 0.0


func _between(h: float, a: float, b: float) -> bool:
	return fposmod(h - a, 24.0) < fposmod(b - a, 24.0)


func tint(hour: float) -> Color:
	return _sample(world_tint, hour, &"tint")


func sky(hour: float) -> Array[Color]:
	return [_sample(sky_top, hour, &"top"), _sample(sky_mid, hour, &"mid"), _sample(sky_low, hour, &"low")]


func _sample(g: Gradient, hour: float, which: StringName) -> Color:
	if g == null:
		g = default_gradient(which)
	return g.sample(fposmod(hour, 24.0) / 24.0)


static var _defaults := {}


## The built-in colours (used when the config has none).
static func default_gradient(which: StringName) -> Gradient:
	if _defaults.has(which):
		return _defaults[which]
	var p := WorldPalette
	var night := {&"tint": Color(0.30, 0.33, 0.55), &"top": p.T0, &"mid": p.T0, &"low": p.T1}
	var dawn := {&"tint": Color(0.62, 0.52, 0.66), &"top": p.P0, &"mid": p.B3, &"low": p.B4}
	var day := {&"tint": Color.WHITE, &"top": p.SKY_TOP, &"mid": p.SKY_MID, &"low": p.SKY_LOW}
	var gold := {&"tint": Color(1.0, 0.86, 0.70), &"top": p.T3, &"mid": p.O2, &"low": p.O3}
	var dusk := {&"tint": Color(0.62, 0.50, 0.68), &"top": p.T1, &"mid": p.P0, &"low": p.B3}
	var keys := [[0.0, night], [4.5, night], [5.75, dawn], [7.25, day], [16.75, day], [18.75, gold],
		[20.5, dusk], [22.0, night], [24.0, night]]
	var g := Gradient.new()
	g.offsets = PackedFloat32Array(keys.map(func(k: Array) -> float: return k[0] / 24.0))
	g.colors = PackedColorArray(keys.map(func(k: Array) -> Color: return k[1][which]))
	_defaults[which] = g
	return g
