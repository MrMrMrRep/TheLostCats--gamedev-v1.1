class_name MemberCard
extends Control
## HUD card for one band member: portrait, key number, HP pips, stamina bar
## (only while below max), 3 item slots (selected slot outlined on the active
## member's card) and name.
## The active member's card is highlighted, the others are dimmed.

const SIZE := Vector2(58, 50)
const SHEET := preload("res://public/assets/amwoods/character/char_blue.png")
const PORTRAIT_REGION := Rect2(18, 24, 22, 32)   # idle frame 0 body (assets.json body_bounds)
const ITEM_SLOTS := 3
const ACTIVE_COLOR := Color("ffd36b")
const HP_COLOR := Color("e05a4f")
const SLOT := 8.0
const SLOT_X := 29.0
const SLOT_Y := 21.0

var member: BandMember
var active := false


func _init() -> void:
	custom_minimum_size = SIZE
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func bind(m: BandMember, index: int) -> void:
	member = m
	var atlas := AtlasTexture.new()
	atlas.atlas = SHEET
	atlas.region = PORTRAIT_REGION
	var portrait := TextureRect.new()
	portrait.texture = atlas
	portrait.position = Vector2(4, 3)
	portrait.modulate = m.profile.tint
	add_child(portrait)
	add_child(_label(str(index + 1), Vector2(50, 0), Vector2(8, 10)))
	var name_label := _label(m.profile.display_name, Vector2(0, 37), Vector2(SIZE.x, 10))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	add_child(name_label)
	var bar := StaminaBar.new()
	bar.bar_size = Vector2(25, 3)
	bar.position = Vector2(29, 14)
	add_child(bar)
	bar.bind(m.stamina)
	m.health.health_changed.connect(func(_hp: int, _max: int) -> void: queue_redraw())
	m.inventory.changed.connect(queue_redraw)
	queue_redraw()


func set_active(value: bool) -> void:
	active = value
	modulate = Color.WHITE if active else Color(1, 1, 1, 0.6)
	queue_redraw()


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.08, 0.06, 0.1, 0.75))
	draw_rect(Rect2(Vector2.ZERO, SIZE), ACTIVE_COLOR if active else Color(1, 1, 1, 0.25), false, 1.0)
	if member == null:
		return
	for i in member.health.max_hp:
		var filled := i < member.health.hp
		draw_rect(Rect2(29 + i * 7, 6, 5, 5), HP_COLOR if filled else Color(1, 1, 1, 0.15))
	for i in ITEM_SLOTS:
		var r := Rect2(SLOT_X + i * (SLOT + 1), SLOT_Y, SLOT, SLOT)
		draw_rect(r, Color(0, 0, 0, 0.35))
		var item := member.inventory.slots[i]
		if item:
			item.draw_icon(self, r.get_center())
		var picked := active and i == member.inventory.selected
		draw_rect(r, ACTIVE_COLOR if picked else Color(1, 1, 1, 0.3), false, 1.0)


func _label(text: String, pos: Vector2, size_px: Vector2) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = size_px
	l.add_theme_font_size_override("font_size", 8)
	l.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("outline_size", 3)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return l
