@tool
class_name CosmeticCard
extends VBoxContainer

## Card for one cosmetic asset, assigned in inspector or by CosmeticSlotTab

signal asset_changed

@export var asset: CosmeticAsset:
	set(value):
		asset = value
		asset_changed.emit()


## Binds purchase control to selected player's features
func bind_player_features(economy: EconomyController, cosmetics: CosmeticsController) -> void:
	var buy_button: BuyCosmeticButton = %BuyCosmetic
	buy_button.bind_player_features(economy, cosmetics)
