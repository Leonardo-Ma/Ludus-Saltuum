@tool
@abstract class_name CosmeticAsset
extends Resource

## Base for purchasable equippable cosmetics, one equipped asset per [enum Slot]

enum Slot {
	CHARACTER = 0,
	WEAPON = 1,
}

## NOTE Do not change after being set under any circumstance
@export var cosmetic_id: StringName
@export var display_name: String
@export var icon: Texture2D
@export var price: int
## Owned and equipped from the start, exactly one per slot in use
@export var is_default: bool = false


@abstract func get_slot() -> Slot


## Override to assert subclass data
func validate() -> void:
	pass
