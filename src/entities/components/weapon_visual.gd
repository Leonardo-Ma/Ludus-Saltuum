class_name WeaponVisual
extends Node

## Replaces weapon at hand socket with equipped weapon scene

signal weapon_replaced

@export var socket: Node3D


func _ready() -> void:
	assert(socket, "Socket missing in " + name)


func replace_weapon_visual(weapon: WeaponAsset) -> void:
	assert(weapon and weapon.weapon_scene, "Weapon scene missing in " + name)

	var instance: Node3D = weapon.weapon_scene.instantiate() as Node3D
	assert(instance, "Weapon scene root must be Node3D in " + name)

	for child: Node in socket.get_children():
		socket.remove_child(child)
		child.queue_free()

	socket.add_child(instance)
	weapon_replaced.emit()
