@tool
class_name PartyBoard
extends Interactable
## The cork board in the base with a photo of each band member: E opens the
## party choice (who goes out on the world map). The ones going have a green
## pin. Origin = bottom centre of the board.

const PHOTO := [Color("e3b48e"), Color("e8b48e"), Color("ffcdb2"), Color("ffcdb2"), Color("ffcdb2")]


func _ready() -> void:
	prompt = "E  pick who goes out"
	area_size = Vector2(44, 60)
	super()


func interact(_member: BandMember, level: Node) -> void:
	if PartySelect.recently_closed():
		return
	var ui := PartySelect.new()
	level.add_child(ui)
	ui.closed.connect(queue_redraw)


func _draw() -> void:
	draw_rect(Rect2(-21, -55, 42, 30), Color("1d1a22"))
	draw_rect(Rect2(-20, -54, 40, 28), Color("b98a5a"))
	draw_rect(Rect2(-20, -54, 40, 2), Color("d0a070"))
	for i in Game.MEMBERS.size():
		var x := -18.0 + i * 8.0
		var y := -50.0 + (i % 2) * 9.0
		draw_rect(Rect2(x, y, 7, 9), Color("f2efe8"))
		draw_rect(Rect2(x + 1, y + 1, 5, 5), PHOTO[i].darkened(0.1))
		var going := Game.in_party(Game.MEMBERS[i]) if not Engine.is_editor_hint() else true
		draw_rect(Rect2(x + 3, y - 1, 2, 2), Color("3fbf5a") if going else Color("c94a3d"))
	draw_string(ThemeDB.fallback_font, Vector2(-20, -28), "TOUR", HORIZONTAL_ALIGNMENT_CENTER, 40, 6, Color("1d1a22"))
