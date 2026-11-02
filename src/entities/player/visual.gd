class_name CharacterVisual
extends Node3D

## Replaces character rig while preserving animation

@onready var _rig: Node3D = %Rig_Medium
@onready var _cosmetics_controller: CosmeticsController = %CosmeticsController


func _ready() -> void:
	_cosmetics_controller.equipped_character_changed.connect(_on_equipped_character_changed)
	_on_equipped_character_changed(_cosmetics_controller.get_equipped_character_asset())


func _on_equipped_character_changed(character_asset: CharacterEntityAsset) -> void:
	replace_character_visual(character_asset.character_mesh)


func replace_character_visual(character_scene: PackedScene) -> void:
	assert(character_scene != null, "Character scene missing in " + name)

	var character_instance: Node3D = character_scene.instantiate() as Node3D
	assert(character_instance != null, "Character scene root must be Node3D in " + name)

	var new_rig: Node3D = character_instance.get_node("Rig_Medium") as Node3D
	assert(new_rig != null, "Rig_Medium missing in " + character_instance.name)

	var previous_rig: Node3D = _rig

	new_rig.transform = previous_rig.transform
	character_instance.remove_child(new_rig)
	new_rig.name = previous_rig.name

	remove_child(previous_rig)
	add_child(new_rig)

	_rig = new_rig
	previous_rig.queue_free()
	character_instance.queue_free()
