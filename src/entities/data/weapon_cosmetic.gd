@tool
class_name WeaponCosmetic
extends CosmeticAsset

## Makes gameplay weapon available for purchase and cosmetic equipment

@export var weapon: WeaponAsset:
	set(value):
		weapon = value
		resource_name = weapon.resource_name if weapon else ""
		if weapon and resource_name.is_empty() and not weapon.is_built_in():
			resource_name = weapon.resource_path.get_file()


func get_slot() -> Slot:
	return Slot.WEAPON


func validate() -> void:
	assert(weapon, "Weapon missing in " + String(cosmetic_id))
	weapon.validate()
