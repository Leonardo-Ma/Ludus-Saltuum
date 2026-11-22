@tool
class_name CosmeticSlotCatalog
extends Resource

## Assets of one slot, exactly one default

@export var slot: CosmeticAsset.Slot
@export var assets: Array[CosmeticAsset] = []:
	set(value):
		assets = value
		emit_changed()


func get_default() -> CosmeticAsset:
	for asset: CosmeticAsset in assets:
		if asset.is_default:
			return asset

	assert(false, "Default missing in slot catalog " + resource_path)
	return null


## Ascending price, ties by display name
func get_assets_by_price() -> Array[CosmeticAsset]:
	var sorted: Array[CosmeticAsset] = assets.filter(
		func(asset: CosmeticAsset) -> bool:
			return asset != null,
	)
	sorted.sort_custom(
		func(a: CosmeticAsset, b: CosmeticAsset) -> bool:
			return a.price < b.price or (a.price == b.price and a.display_name < b.display_name),
	)
	return sorted


func validate() -> void:
	assert(not assets.is_empty(), "Empty slot catalog " + resource_path)

	var default_count: int = 0
	for asset: CosmeticAsset in assets:
		assert(asset != null, "Null cosmetic in slot catalog " + resource_path)
		assert(asset.get_slot() == slot, "Cosmetic " + String(asset.cosmetic_id) + " in wrong slot catalog " + resource_path)
		asset.validate()
		if asset.is_default:
			default_count += 1

	assert(default_count == 1, "Slot catalog needs exactly one default in " + resource_path)
