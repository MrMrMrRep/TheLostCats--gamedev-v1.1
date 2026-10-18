extends CanvasLayer
## In-game HUD (M3: active member name + stamina bar).
## M4 adds portraits and HP pips above the stamina bar.

@onready var name_label: Label = %NameLabel
@onready var stamina_bar: StaminaBar = %StaminaBar


func bind_player(player: Player) -> void:
	name_label.text = player.profile.display_name if player.profile else ""
	stamina_bar.bind(player.stamina)
