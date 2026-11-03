class_name CharacterVisual
extends Node3D

## Replaces character meshes while preserving animation rig

@onready var _skeleton: Skeleton3D = %Skeleton3D
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

	var source_skeleton: Skeleton3D = character_instance.get_node("Rig_Medium/Skeleton3D") as Skeleton3D
	assert(source_skeleton != null, "Skeleton3D missing in " + character_instance.name)

	_validate_skeleton(source_skeleton)

	var new_meshes: Array[MeshInstance3D] = []
	for child: Node in source_skeleton.get_children():
		if child is MeshInstance3D:
			new_meshes.append(child as MeshInstance3D)

	assert(not new_meshes.is_empty(), "Character has no meshes in " + character_instance.name)

	for mesh: MeshInstance3D in new_meshes:
		if mesh.skin != null:
			_remap_skin(mesh.skin, source_skeleton)

	var previous_meshes: Array[MeshInstance3D] = []
	for child: Node in _skeleton.get_children():
		if child is MeshInstance3D:
			previous_meshes.append(child as MeshInstance3D)

	for mesh: MeshInstance3D in previous_meshes:
		_skeleton.remove_child(mesh)
		mesh.queue_free()

	for mesh: MeshInstance3D in new_meshes:
		if mesh.skin != null:
			mesh.skin = _remap_skin(mesh.skin, source_skeleton)

		source_skeleton.remove_child(mesh)
		mesh.owner = null
		_skeleton.add_child(mesh)
		mesh.skeleton = mesh.get_path_to(_skeleton)

	character_instance.queue_free()


func _validate_skeleton(source_skeleton: Skeleton3D) -> void:
	assert(source_skeleton.get_bone_count() == _skeleton.get_bone_count(), "Skeleton bone count mismatch in " + name)

	for source_index: int in range(source_skeleton.get_bone_count()):
		var bone_name: StringName = source_skeleton.get_bone_name(source_index)
		var target_index: int = _skeleton.find_bone(bone_name)

		assert(target_index >= 0, "Missing bone " + str(bone_name) + " in " + name)

		var source_parent_index: int = source_skeleton.get_bone_parent(source_index)
		var target_parent_index: int = _skeleton.get_bone_parent(target_index)

		var source_parent_name: StringName = &""
		var target_parent_name: StringName = &""

		if source_parent_index >= 0:
			source_parent_name = source_skeleton.get_bone_name(source_parent_index)

		if target_parent_index >= 0:
			target_parent_name = _skeleton.get_bone_name(target_parent_index)

		assert(source_parent_name == target_parent_name, "Bone hierarchy mismatch at " + str(bone_name) + " in " + name)

		assert(
			source_skeleton.get_bone_rest(source_index).is_equal_approx(_skeleton.get_bone_rest(target_index)),
			"Bone rest pose mismatch at " + str(bone_name) + " in " + name,
		)


func _remap_skin(source_skin: Skin, source_skeleton: Skeleton3D) -> Skin:
	var remapped_skin: Skin = source_skin.duplicate() as Skin

	for bind_index: int in range(remapped_skin.get_bind_count()):
		var source_bone_index: int = source_skin.get_bind_bone(bind_index)
		var source_bone_name: StringName

		if source_bone_index >= 0:
			assert(source_bone_index < source_skeleton.get_bone_count(), "Invalid skin bone index in " + name)
			source_bone_name = source_skeleton.get_bone_name(source_bone_index)
		else:
			source_bone_name = source_skin.get_bind_name(bind_index)

		assert(not source_bone_name.is_empty(), "Skin binding has no bone name in " + name)

		var target_bone_index: int = _skeleton.find_bone(source_bone_name)

		assert(target_bone_index >= 0, "Skin references missing bone " + str(source_bone_name) + " in " + name)

		remapped_skin.set_bind_bone(bind_index, target_bone_index)

	return remapped_skin
