extends CanvasLayer
## In-game HUD: one MemberCard per band member, active one highlighted.

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
		_cards.append(card)
	band.active_changed.connect(_on_active_changed)
	_on_active_changed(band.active, band.active_index)


func _on_active_changed(_member: BandMember, index: int) -> void:
	for i in _cards.size():
		_cards[i].set_active(i == index)
