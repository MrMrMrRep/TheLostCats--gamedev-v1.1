@tool
class_name Vendor
extends Interactable
## Something that sells: a bar tap, a vending machine. E buys one `item` for
## `base_price` coins, cheaper when Geoff is the one buying (Game.price()).

@export var item: ItemData = preload("res://resources/items/beer.tres")
@export var base_price := 10
@export var label := "BAR"


func _ready() -> void:
	area_size = Vector2(32, 40)
	super()


func price_for(member: BandMember) -> int:
	return Game.price(base_price, member.profile.id)


func set_highlighted(on: bool) -> void:
	super(on)
	var level := Level.of(self) if not Engine.is_editor_hint() else null
	if on and level:
		set_prompt_text("E  %s: %d coins" % [item.display_name.to_lower(), price_for(level.band.active)])


func interact(member: BandMember, _level: Node) -> void:
	var p := price_for(member)
	if Game.coins < p:
		say("%s is %d coins. You've got %d." % [item.display_name, p, Game.coins])
		return
	if not member.add_item(item):
		return
	Game.add_coins(-p)
	Audio.sfx(&"coin")
	say("Cheers, Geoff! Mate's rates: %d." % p if member.profile.id == &"geoff" else "That's %d." % p)


func _draw() -> void:
	draw_rect(Rect2(-14, -36, 28, 36), Color("4e2c26"))
	draw_rect(Rect2(-14, -36, 28, 4), Color("b8604a"))
	draw_rect(Rect2(-6, -28, 3, 12), Color("c8ccd4"))
	draw_rect(Rect2(3, -28, 3, 12), Color("c8ccd4"))
	draw_rect(Rect2(-10, -8, 20, 3), Color("8a6a42"))
	if item:
		item.draw_icon(self, Vector2(0, -14))
