class_name WorldDayCycle
extends Node
## Runs the clock on the world map and dresses the world for the hour: a tint
## over the street (CanvasModulate), the sky's colours, sun, moon and stars,
## and the night lights (every NightGlow). The clock lives in Game.time_of_day
## so it carries over between scenes; it only moves on the map. Lengths of the
## parts of the day and the colours: resources/config/day_config.tres.
## Skip ahead with sleep(hours): the screen fades to black and you wake up
## later (the HUD's +1 / +4 / +8 buttons use it).
## Dev: start at an hour with  -- --time=21 ; N = one hour on (Shift+N back).

signal hour_changed(hour: float)

static var night_now := 0.0                 # 0 by day .. 1 at night (new glows read it)
static var tint_now := Color.WHITE          # the street's tint right now (the unshaded water copies it)

var paused := false                         # e.g. during a conversation
var sleeping := false                       # fading through a sleep()
var _tint: CanvasModulate
var _sky: WorldSky
var _shown_minute := -1


func _ready() -> void:
	var cfg := DayConfig.current()
	if Game.time_of_day < 0.0:
		Game.time_of_day = cfg.start_hour
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--time="):
			Game.time_of_day = fposmod(arg.trim_prefix("--time=").to_float(), 24.0)
	_tint = CanvasModulate.new()
	_tint.name = "NightTint"
	add_child(_tint)
	_sky = get_parent().get_node_or_null("Sky") as WorldSky
	apply()


func _process(delta: float) -> void:
	var cfg := DayConfig.current()
	if cfg.clock_runs and not paused and not sleeping:
		Game.time_of_day = cfg.advance(Game.time_of_day, delta)
	apply()


## Set the clock (the story: a gig at 18:00, 4:00 after a show).
func set_hour(hour: float) -> void:
	Game.time_of_day = fposmod(hour, 24.0)
	apply()


## Sleep `hours`: fade to black, the clock jumps on, wake up.
func sleep(hours: float) -> void:
	if sleeping or hours <= 0.0:
		return
	sleeping = true
	var fade := maxf(DayConfig.current().sleep_fade, 0.01)
	var layer := CanvasLayer.new()
	layer.layer = 35                        # over the world, under the HUD
	add_child(layer)
	var black := ColorRect.new()
	black.color = Color(0.02, 0.02, 0.05, 0.0)
	black.set_anchors_preset(Control.PRESET_FULL_RECT)
	black.mouse_filter = Control.MOUSE_FILTER_IGNORE
	layer.add_child(black)
	var text := Label.new()
	text.text = "Zzz...   %d hour%s later" % [int(hours), "" if int(hours) == 1 else "s"]
	text.size = Vector2(640, 20)
	text.position = Vector2(0, 170)
	text.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	text.add_theme_font_size_override("font_size", 12)
	ScreenFit.full_width(text)
	text.modulate.a = 0.0
	layer.add_child(text)
	var tw := create_tween()
	tw.tween_property(black, "color:a", 1.0, fade)
	tw.parallel().tween_property(text, "modulate:a", 1.0, fade)
	tw.tween_callback(func() -> void: set_hour(Game.time_of_day + hours))
	tw.tween_interval(0.5)
	tw.tween_property(black, "color:a", 0.0, fade)
	tw.parallel().tween_property(text, "modulate:a", 0.0, fade)
	await tw.finished
	layer.queue_free()
	sleeping = false


func hour() -> float:
	return Game.time_of_day


## "08:00"
func clock_text() -> String:
	var m := int(Game.time_of_day * 60.0)
	return "%02d:%02d" % [(m / 60) % 24, m % 60]


func apply() -> void:
	var cfg := DayConfig.current()
	var h := Game.time_of_day
	var tint := cfg.tint(h)
	_tint.color = tint
	tint_now = tint
	var night := cfg.night(h)
	if _sky:
		_sky.set_time(h, cfg.sky(h), night, tint.lerp(Color.WHITE, 0.1))
	if absf(night - night_now) > 0.003 or (night == 0.0 and night_now != 0.0) or (night == 1.0 and night_now != 1.0):
		night_now = night
		get_tree().call_group(&"night_glow", &"set_night", night)
	var minute := int(h * 60.0)
	if minute != _shown_minute:
		_shown_minute = minute
		hour_changed.emit(h)


func _unhandled_key_input(event: InputEvent) -> void:
	if not OS.is_debug_build():
		return
	var k := event as InputEventKey
	if k and k.pressed and not k.echo and k.keycode == KEY_N:
		set_hour(Game.time_of_day + (-1.0 if k.shift_pressed else 1.0))
