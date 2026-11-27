class_name PauseMenuView
extends MenuScreen

@onready var _cosmetics_button: PauseCosmeticsButton = %CosmeticsButton


## Assigns source of cosmetic reminders
func bind_cosmetics(cosmetics: CosmeticsController) -> void:
	_cosmetics_button.bind_cosmetics(cosmetics)
