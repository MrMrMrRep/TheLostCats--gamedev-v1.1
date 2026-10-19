class_name JTCBike
extends RefCounted
## Bike art from the asset repo for TheLostCats (sprites/INTEGRATION.md §3b).
## - Riding: members whose SpriteFrames have `bike_pedal` / `bike_roll` ride on their own sprite
##   (the placeholder BikeSprite is hidden for them). Wheel speed follows the bike's speed.
## - Parked: bike_parked_<member>.png, same scale as the band sheets (draw at 0.5), origin = ground (48,95).

const RIDE_PEDAL := &"bike_pedal"
const RIDE_ROLL := &"bike_roll"
const CELL := 96.0
const ORIGIN := Vector2(48, 95)
const SCALE := 0.5                      # same as MovementProfile.sprite_scale
const PARKED := {
	&"joep": preload("res://assets/sprites/vehicles/bike_parked_joep.png"),
	&"jay": preload("res://assets/sprites/vehicles/bike_parked_jay.png"),
	&"nikki": preload("res://assets/sprites/vehicles/bike_parked_nikki.png"),
	&"germ": preload("res://assets/sprites/vehicles/bike_parked_germ.png"),
	&"geoff": preload("res://assets/sprites/vehicles/bike_parked_geoff.png"),
}
const PARKED_ORDER: Array[StringName] = [&"joep", &"jay", &"nikki", &"germ", &"geoff"]
const PARKED_GAP := 12.0                # world px between parked bikes in the rack


static func has_bike_art(m: BandMember) -> bool:
	return m.sprite.sprite_frames != null and m.sprite.sprite_frames.has_animation(RIDE_PEDAL)


## Play the right riding clip. `pedalling` = the player holds a direction (Vehicle pulls),
## otherwise the bike coasts. Wheels/legs animate with the speed; standing still freezes the clip.
static func ride(m: BandMember, speed: float, top: float, pedalling: bool) -> void:
	if not has_bike_art(m):
		m.play_anim(&"idle")
		return
	var frac := clampf(absf(speed) / maxf(top, 1.0), 0.0, 1.0)
	m.play_anim(RIDE_PEDAL if pedalling else RIDE_ROLL)
	if pedalling:
		m.sprite.speed_scale = lerpf(0.55, 1.4, frac)
	else:
		m.sprite.speed_scale = 0.0 if absf(speed) < 2.0 else lerpf(0.3, 1.3, frac)


## Call when getting off: back to normal animation speed.
static func dismount(m: BandMember) -> void:
	m.sprite.speed_scale = 1.0


## Draw the parked bikes (one per band member) with their kickstands down, centred on `at`.
static func draw_parked(ci: CanvasItem, at: Vector2, facing: float = 1.0, count: int = 5) -> void:
	var n := mini(count, PARKED_ORDER.size())
	for i in n:
		var tex: Texture2D = PARKED[PARKED_ORDER[i]]
		var x := (i - (n - 1) / 2.0) * PARKED_GAP
		ci.draw_set_transform(at + Vector2(x, 0), 0.0, Vector2(SCALE * facing, SCALE))
		ci.draw_texture(tex, -ORIGIN)
	ci.draw_set_transform(Vector2.ZERO)
