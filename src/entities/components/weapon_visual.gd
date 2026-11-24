@tool
class_name WeaponVisual
extends Node

## Replaces weapon at hand socket with equipped weapon scene

signal weapon_replaced

@export var socket: Node3D

var _instance: Node3D


func _ready() -> void:
	assert(socket, "Socket missing in " + name)


func replace_weapon_visual(weapon: WeaponAsset) -> void:
	if is_instance_valid(_instance):
		socket.remove_child(_instance)
		_instance.queue_free()
		_instance = null

	if weapon and weapon.weapon_scene:
		_instance = weapon.weapon_scene.instantiate()
		assert(_instance, "Weapon scene root must be Node3D in " + name)
		socket.add_child(_instance)

	if not Engine.is_editor_hint():
		weapon_replaced.emit()
