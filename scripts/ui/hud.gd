extends CanvasLayer
## In-game HUD: one MemberCard per band member, active one highlighted. Tap
## a card: that member (the active one's: the next); hold it: the inventory.

var _cards: Array[MemberCard] = []

@onready var cards_box: HBoxContainer = %Cards


func bind_band(band: Band) -> void:
	for card in _cards:
		card.queue_free()
	_cards.clear()
	for i in band.members.size():
		var card := MemberCard.new()
		cards_box.add_child(card)
		card.bind(band.members[i], i)
		card.tapped.connect(_on_card_tapped.bind(band, i))
		card.held.connect(_on_card_held.bind(band, i))
		_cards.append(card)
	band.active_changed.connect(_on_active_changed)
	_on_active_changed(band.active, band.active_index)


func _on_active_changed(_member: BandMember, index: int) -> void:
	for i in _cards.size():
		_cards[i].set_active(i == index)


func _on_card_tapped(band: Band, i: int) -> void:
	get_node(^"/root/TouchPad").tap(&"switch_next" if i == band.active_index else StringName("select_%d" % (i + 1)))


func _on_card_held(band: Band, i: int) -> void:
	if i != band.active_index:
		band.switch_to(i)
	InventoryPopup.open(band.active, self)
