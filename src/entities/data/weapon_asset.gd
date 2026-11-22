@tool
class_name WeaponAsset
extends CosmeticAsset

## Root origin of [member weapon_scene] is the grip, aligned to player WeaponSocket

@export var weapon_scene: PackedScene

@export_category("Attack Modifiers")
@export_range(0.1, 10.0, 0.05, "suffix:x") var damage_multiplier: float = 1.0
## Higher is faster, divides Attack.rate
@export_range(0.1, 10.0, 0.05, "suffix:x") var attack_speed_multiplier: float = 1.0


func get_slot() -> Slot:
	return Slot.WEAPON
