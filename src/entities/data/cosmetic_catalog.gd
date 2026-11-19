class_name CosmeticCatalog
extends Resource

## Master catalog, one [CosmeticSlotCatalog] per slot in use

@export var slots: Array[CosmeticSlotCatalog] = []


## Null if id unknown
func find_asset(id: StringName) -> CosmeticAsset:
	for asset: CosmeticAsset in get_all_assets():
		if asset.cosmetic_id == id:
			return asset
	return null


func get_asset(id: StringName) -> CosmeticAsset:
	var asset: CosmeticAsset = find_asset(id)
	assert(asset != null, "Cosmetic id " + String(id) + " missing from catalog " + resource_path)
	return asset


## Empty if slot unused
func get_assets(slot: CosmeticAsset.Slot) -> Array[CosmeticAsset]:
	var slot_catalog: CosmeticSlotCatalog = _find_slot_catalog(slot)
	if slot_catalog == null:
		return []
	return slot_catalog.assets.duplicate()


func get_all_assets() -> Array[CosmeticAsset]:
	var result: Array[CosmeticAsset] = []
	for slot_catalog: CosmeticSlotCatalog in slots:
		result.append_array(slot_catalog.assets)
	return result


func get_default(slot: CosmeticAsset.Slot) -> CosmeticAsset:
	var slot_catalog: CosmeticSlotCatalog = _find_slot_catalog(slot)
	assert(slot_catalog != null, "Slot has no catalog in " + resource_path)
	return slot_catalog.get_default()


func validate() -> void:
	var seen_slots: Dictionary[int, bool] = { }
	var seen_ids: Dictionary[StringName, bool] = { }

	for slot_catalog: CosmeticSlotCatalog in slots:
		assert(slot_catalog != null, "Null slot catalog in " + resource_path)
		assert(not seen_slots.has(slot_catalog.slot), "Duplicate slot catalog in " + resource_path)
		seen_slots[slot_catalog.slot] = true
		slot_catalog.validate()

		for asset: CosmeticAsset in slot_catalog.assets:
			assert(not asset.cosmetic_id.is_empty(), "Empty cosmetic id in " + resource_path)
			assert(not seen_ids.has(asset.cosmetic_id), "Duplicate cosmetic id " + String(asset.cosmetic_id) + " in " + resource_path)
			seen_ids[asset.cosmetic_id] = true


func _find_slot_catalog(slot: CosmeticAsset.Slot) -> CosmeticSlotCatalog:
	for slot_catalog: CosmeticSlotCatalog in slots:
		if slot_catalog.slot == slot:
			return slot_catalog
	return null
