class_name PlayerAppearance
extends Node

## Applies equipped cosmetics to player rig and weapon

@onready var _visual: CharacterVisual = %Visual
@onready var _weapons: WeaponController = %WeaponController
@onready var _cosmetics: CosmeticsController = %CosmeticsController


func initialize() -> void:
	assert(_visual and _weapons and _cosmetics, "Appearance dependencies missing in " + name)

	_cosmetics.equipped_changed.connect(_on_equipped_changed)
	_on_equipped_changed(_cosmetics.get_equipped_asset(CosmeticAsset.Slot.CHARACTER))
	var weapon: CosmeticAsset = _cosmetics.get_equipped_asset(CosmeticAsset.Slot.WEAPON)
	if _weapons.equipped_weapon == null or not weapon.is_default:
		_on_equipped_changed(weapon)


func _on_equipped_changed(asset: CosmeticAsset) -> void:
	if asset is CharacterEntityAsset:
		_visual.replace_character_visual(asset.character_mesh)
	elif asset is WeaponCosmetic:
		_weapons.equip_weapon(asset.weapon)
