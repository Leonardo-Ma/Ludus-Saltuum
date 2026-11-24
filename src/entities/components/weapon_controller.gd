@tool
class_name WeaponController
extends Node

## Equips one weapon per wielder and previews first loadout entry in editor

## Optional, empty list keeps socket empty
@export var weapons: Array[WeaponAsset] = []:
	set(value):
		weapons = value
		if Engine.is_editor_hint() and is_node_ready():
			_refresh_preview()
@export var randomize_weapon: bool = false

@export_category("Attack Modifiers")
@export var apply_weapon_damage: bool = true
@export var apply_weapon_attack_rate: bool = true

var equipped_weapon: WeaponAsset
var _preview_weapon: WeaponAsset

@onready var _visual: WeaponVisual = %WeaponVisual
@onready var _attack: AttackComponent = %AttackComponent


func _ready() -> void:
	assert(_visual, "WeaponVisual missing in " + name)
	if Engine.is_editor_hint():
		_refresh_preview()
		return

	assert(_attack, "AttackComponent missing in " + name)
	for weapon: WeaponAsset in weapons:
		assert(weapon, "Empty weapon entry in " + name)
	if not weapons.is_empty():
		equip_weapon(weapons.pick_random() if randomize_weapon else weapons[0])


## Visual and attack modifiers together
func equip_weapon(weapon: WeaponAsset) -> void:
	assert(weapon, "Weapon missing in " + name)
	weapon.validate()
	equipped_weapon = weapon
	var damage_multiplier: float = weapon.damage_multiplier if apply_weapon_damage else 1.0
	var speed_multiplier: float = weapon.attack_speed_multiplier if apply_weapon_attack_rate else 1.0
	_attack.set_multipliers(damage_multiplier, speed_multiplier)
	_visual.replace_weapon_visual(weapon)


func _refresh_preview() -> void:
	if _preview_weapon:
		_preview_weapon.changed.disconnect(_refresh_preview)
	_preview_weapon = null if weapons.is_empty() else weapons[0]
	if _preview_weapon:
		_preview_weapon.changed.connect(_refresh_preview)
	_visual.replace_weapon_visual(_preview_weapon)
