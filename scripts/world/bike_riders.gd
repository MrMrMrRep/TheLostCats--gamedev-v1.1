class_name BikeRiders
extends RefCounted
## Riding clips for the members who don't have them in their own sheet yet
## (only Joep's sheet has bike_pedal / bike_roll). tools/make_bike_riders.py
## builds them from Joep's frames: assets/sprites/vehicles/bike_ride_<id>.png,
## 8 frames of 96 px, row 0 pedal, row 1 roll. Kept apart from jtc_bike.gd,
## which tools/sync_sprites.sh overwrites from the asset repo.

const STRIP := "res://assets/sprites/vehicles/bike_ride_%s.png"
const CELL := 96
const FRAMES := 8
const FPS := 12.0
const SCALE := 0.5                          # the bike art is at Joep's density
const OFFSET := Vector2(0, -48)             # wheels on the node origin


## Give `m` bike_pedal / bike_roll if their sheet lacks them (on a copy of their SpriteFrames).
static func ensure(m: BandMember) -> void:
	if m.sprite.sprite_frames == null or JTCBike.has_bike_art(m) or m.profile == null:
		return
	var path := STRIP % m.profile.id
	if not ResourceLoader.exists(path):
		return
	var tex: Texture2D = load(path)
	var frames: SpriteFrames = m.sprite.sprite_frames.duplicate()
	for row in 2:
		var anim: StringName = [JTCBike.RIDE_PEDAL, JTCBike.RIDE_ROLL][row]
		frames.add_animation(anim)
		frames.set_animation_speed(anim, FPS)
		frames.set_animation_loop(anim, true)
		for i in FRAMES:
			var at := AtlasTexture.new()
			at.atlas = tex
			at.region = Rect2(i * CELL, row * CELL, CELL, CELL)
			at.filter_clip = true
			frames.add_frame(anim, at)
	m.sprite.sprite_frames = frames


## The parked bikes of `ids` (the party) in the rack, centred on `at`.
static func draw_parked(ci: CanvasItem, at: Vector2, facing: float, ids: Array) -> void:
	var n := ids.size()
	for i in n:
		var tex: Texture2D = JTCBike.PARKED.get(ids[i])
		if tex == null:
			continue
		var x := (i - (n - 1) / 2.0) * JTCBike.PARKED_GAP
		ci.draw_set_transform(at + Vector2(x, 0), 0.0, Vector2(JTCBike.SCALE * facing, JTCBike.SCALE))
		ci.draw_texture(tex, -JTCBike.ORIGIN)
	ci.draw_set_transform(Vector2.ZERO)


## On the bike: the bike clips are drawn at Joep's scale, whatever the member's sheet uses.
static func mount(m: BandMember) -> void:
	m.sprite.scale = Vector2.ONE * SCALE
	m.sprite.offset = OFFSET


## Off the bike: back to the member's own sprite scale.
static func unmount(m: BandMember) -> void:
	if m.profile and m.profile.sprite_frames:
		m.sprite.scale = Vector2.ONE * m.profile.sprite_scale
		m.sprite.offset = m.profile.sprite_offset
	JTCBike.dismount(m)
