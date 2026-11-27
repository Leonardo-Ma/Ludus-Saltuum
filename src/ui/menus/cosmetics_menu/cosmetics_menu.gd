# TODO Consider a better approach in the future to remove this need, this may be needed for multiplayer
class_name CosmeticsMenuView
extends MenuScreen

## Displays selected player's cosmetics and purchase balance

@onready var _costume_cards: CosmeticSlotTab = %CostumesTab
@onready var _weapon_cards: CosmeticSlotTab = %WeaponsTab
@onready var _gold: GoldView = %Gold


## Assigns sources for both cosmetic slots and balance display
func bind_player_features(economy: EconomyController, cosmetics: CosmeticsController) -> void:
	_costume_cards.bind_player_features(economy, cosmetics)
	_weapon_cards.bind_player_features(economy, cosmetics)
	_gold.bind_economy(economy)
