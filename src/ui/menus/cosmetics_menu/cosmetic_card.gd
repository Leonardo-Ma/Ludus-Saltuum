@tool
class_name CosmeticCard
extends VBoxContainer

## Card for one cosmetic asset, assigned in inspector or by CosmeticSlotTab

signal asset_changed

@export var asset: CosmeticAsset:
	set(value):
		asset = value
		asset_changed.emit()
