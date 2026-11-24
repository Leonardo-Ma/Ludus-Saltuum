@tool
class_name WeaponAsset
extends Resource

## Root origin of [member weapon_scene] is the grip, aligned to player WeaponSocket

enum WeaponType {
	UNDEFINED = 0,
	SWORD = 1,
	DAGGER = 2,
	AXE = 3,
	HAMMER = 4,
	SPEAR = 5,
	STAFF = 6,
	WAND = 7,
	CLUB = 8,
	OTHER = 99,
}

enum WeaponMaterial {
	UNDEFINED = 0,
	WOOD = 1,
	STONE = 2,
	GOLD = 3,
	ELEMENTAL = 4,
	SPECIAL = 5,
}

@export var weapon_scene: PackedScene:
	set(value):
		weapon_scene = value
		emit_changed()

@export_category("Category")
@export var weapon_type: WeaponType = WeaponType.UNDEFINED
@export var weapon_material: WeaponMaterial = WeaponMaterial.UNDEFINED

@export_category("Attack Modifiers")
@export_range(0.1, 10.0, 0.05, "suffix:x") var damage_multiplier: float = 1.0
## Higher is faster, divides Attack.rate
@export_range(0.1, 10.0, 0.05, "suffix:x") var attack_speed_multiplier: float = 1.0


func validate() -> void:
	assert(weapon_scene, "Weapon scene missing in " + resource_path)
	assert(weapon_type != WeaponType.UNDEFINED, "Weapon type undefined in " + resource_path)
	assert(weapon_material != WeaponMaterial.UNDEFINED, "Weapon material undefined in " + resource_path)
