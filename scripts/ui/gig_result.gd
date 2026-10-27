class_name GigResult
extends CanvasLayer
## After Café De Kat: Finished if you only played, Completed if you also
## found Gwinny. Enter (or the button) goes back to the world map.

signal finished

const HIDDEN_NPCS := 1


static func present(host: Node) -> void:
	var layer := GigResult.new()
	host.add_child(layer)
	await layer.finished


static func _game() -> Node:
	return Engine.get_main_loop().root.get_node("Game")


## title / npcs / blurb. Pure, so the headless test can read it.
static func verdict() -> Dictionary:
	var talked := 1 if _game().get_flag(&"gwinny_met") else 0
	var done := talked >= HIDDEN_NPCS
	return {
		"title": "COMPLETED" if done else "FINISHED",
		"npcs": "%d/%d" % [talked, HIDDEN_NPCS],
		"blurb": "Gwinny heard every song." if done else "Gwinny is still hiding in the club.",
	}


func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	var shade := ColorRect.new()
	shade.color = Color(0.05, 0.07, 0.12, 0.88)
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(shade)
	var frame := Control.new()
	frame.size = ScreenFit.BASE
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	shade.add_child(frame)
	ScreenFit.pin(frame, 0.5)
	var v := verdict()
	var title := _label(v.title, Vector2(0, 78), 28, Color("f2bc58"))
	title.size.x = 640
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(title)
	var sub := _label("Café De Kat", Vector2(0, 118), 16, Color("fff7df"))
	sub.size.x = 640
	sub.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(sub)
	var npcs := _label("NPCs  " + v.npcs, Vector2(0, 156), 14, Color("b0dcc9"))
	npcs.size.x = 640
	npcs.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(npcs)
	var blurb := _label(v.blurb, Vector2(40, 190), 12, Color("fff7df"))
	blurb.size = Vector2(560, 24)
	blurb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	frame.add_child(blurb)
	var menu := MenuList.new()
	menu.position = Vector2(170, 240)
	menu.size = Vector2(300, 28)
	menu.font_size = 14
	frame.add_child(menu)
	menu.set_options(["Back to the map"])
	menu.chosen.connect(func(_i: int) -> void:
		finished.emit()
		queue_free())


func _label(text: String, pos: Vector2, size: int, color: Color) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_color_override("font_outline_color", Color("1d2838"))
	l.add_theme_constant_override("outline_size", 4)
	return l
