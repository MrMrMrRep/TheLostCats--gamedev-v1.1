class_name InventoryPopup
extends CanvasLayer
## The active member's three item slots, opened by holding the character box
## (HUD top left, made for phones; works with the mouse too). Tap a slot to
## select it, then USE, GIVE (to the member next to you) or DROP it; CLOSE or
## a tap outside goes back. The game waits while it's open; the chosen action
## is sent as the usual input (use_item, give, drop_item) once it closes.

const INK := Color("fff7df")
const GOLD := Color("f2bc58")
const PANEL := Color(0.114, 0.157, 0.220, 0.92)
const EDGE := Color("35606c")
const SLOT := Vector2(44, 34)

static var _open: InventoryPopup

var member: BandMember
var _slots: Array[Button] = []
var _was_paused := false


## Open it for `m` (closes one that's already open).
static func open(m: BandMember, parent: Node) -> InventoryPopup:
	if _open and is_instance_valid(_open):
		_open.close()
	var p := InventoryPopup.new()
	p.member = m
	parent.get_tree().root.add_child(p)
	_open = p
	return p


static func is_open() -> bool:
	return _open != null and is_instance_valid(_open)


func _ready() -> void:
	layer = 90
	process_mode = Node.PROCESS_MODE_ALWAYS
	_was_paused = get_tree().paused
	get_tree().paused = true
	var shade := ColorRect.new()                # a tap outside closes it
	shade.color = Color(0, 0, 0, 0.35)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.gui_input.connect(func(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed:
			close())
	add_child(shade)
	var panel := PanelContainer.new()
	var sb := StyleBoxFlat.new()
	sb.bg_color = PANEL
	sb.border_color = EDGE
	sb.set_border_width_all(1)
	sb.set_content_margin_all(6)
	panel.add_theme_stylebox_override("panel", sb)
	add_child(panel)
	var box := VBoxContainer.new()
	box.add_theme_constant_override("separation", 5)
	panel.add_child(box)
	var title := Label.new()
	title.text = "%s's items" % (member.profile.display_name if member and member.profile else "Band")
	title.add_theme_color_override("font_color", GOLD)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	box.add_child(title)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 4)
	box.add_child(row)
	for i in member.inventory.slots.size():
		var b := _button("")
		b.custom_minimum_size = SLOT
		b.pressed.connect(_select.bind(i))
		b.draw.connect(_draw_slot.bind(b, i))
		row.add_child(b)
		_slots.append(b)
	var acts := HBoxContainer.new()
	acts.add_theme_constant_override("separation", 4)
	box.add_child(acts)
	for a in [["USE", &"use_item"], ["GIVE", &"give"], ["DROP", &"drop_item"], ["CLOSE", &""]]:
		var b := _button(a[0])
		b.pressed.connect(_act.bind(a[1]))
		acts.add_child(b)
	member.inventory.changed.connect(_refresh)
	_refresh()
	panel.reset_size()
	panel.position = (Vector2(ScreenFit.width(panel), ScreenFit.BASE.y) - panel.get_combined_minimum_size()) * 0.5


func _select(i: int) -> void:
	member.inventory.selected = i
	member.inventory.changed.emit()


func _act(action: StringName) -> void:
	var item := member.inventory.slots[member.inventory.selected]
	close()
	if action != &"" and item:
		get_node(^"/root/TouchPad").tap(action)


func close() -> void:
	if member and member.inventory.changed.is_connected(_refresh):
		member.inventory.changed.disconnect(_refresh)
	get_tree().paused = _was_paused
	if _open == self:
		_open = null
	queue_free()


func _refresh() -> void:
	for i in _slots.size():
		var item := member.inventory.slots[i]
		_slots[i].tooltip_text = item.display_name if item else "empty"
		_slots[i].queue_redraw()


func _draw_slot(b: Button, i: int) -> void:
	var item := member.inventory.slots[i]
	var r := Rect2(Vector2.ZERO, b.size)
	if i == member.inventory.selected:
		b.draw_rect(r.grow(-1), GOLD, false, 1.0)
	if item:
		item.draw_icon(b, Vector2(b.size.x * 0.5, 12))
	var font := b.get_theme_font("font")
	var text := item.display_name if item else "-"
	var w := font.get_string_size(text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6).x
	b.draw_string(font, Vector2((b.size.x - w) * 0.5, b.size.y - 4), text, HORIZONTAL_ALIGNMENT_LEFT, -1, 6, INK)


func _button(text: String) -> Button:
	var b := Button.new()
	b.text = text
	b.focus_mode = Control.FOCUS_NONE
	for state in ["normal", "hover", "pressed"]:
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.05, 0.06, 0.1, 0.6 if state == "normal" else 0.85)
		sb.border_color = EDGE
		sb.set_border_width_all(1)
		sb.set_content_margin_all(3)
		b.add_theme_stylebox_override(state, sb)
	b.add_theme_color_override("font_color", INK)
	b.add_theme_font_size_override("font_size", 8)
	return b
