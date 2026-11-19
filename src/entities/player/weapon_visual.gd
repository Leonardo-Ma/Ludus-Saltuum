class_name WeaponVisual
extends Node

## Replaces weapon at hand socket with equipped weapon scene

signal weapon_replaced

@export var socket: Node3D

@onready var _cosmetics_controller: CosmeticsController = %CosmeticsController


func _ready() -> void:
	assert(socket != null, "Socket missing in " + name)
	_cosmetics_controller.equipped_changed.connect(_on_equipped_changed)
	_on_equipped_changed(_cosmetics_controller.get_equipped_asset(CosmeticAsset.Slot.WEAPON))


func _on_equipped_changed(asset: CosmeticAsset) -> void:
	var weapon: WeaponAsset = asset as WeaponAsset
	if weapon == null:
		return

	assert(weapon.weapon_scene != null, "Weapon scene missing in " + String(weapon.cosmetic_id))
	var instance: Node3D = weapon.weapon_scene.instantiate() as Node3D
	assert(instance != null, "Weapon scene root must be Node3D in " + name)

	for child: Node in socket.get_children():
		socket.remove_child(child)
		child.queue_free()

	socket.add_child(instance)
	weapon_replaced.emit()
