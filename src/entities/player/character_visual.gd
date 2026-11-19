@tool
class_name CharacterVisual
extends Node3D

## Replaces character meshes while preserving animation rig

signal meshes_replaced

const _EDITOR_PREVIEW_META: StringName = &"_character_visual_preview"

## Optional for entities without cosmetics, such as enemies
@export var _initial_character: CharacterEntityAsset:
	set(value):
		_initial_character = value

		if Engine.is_editor_hint() and is_node_ready():
			_refresh_editor_preview()

@onready var _skeleton: Skeleton3D = %Skeleton3D


func _ready() -> void:
	if Engine.is_editor_hint():
		_refresh_editor_preview()
	else:
		assert(_initial_character)
		replace_character_visual(_initial_character.character_mesh)


func _refresh_editor_preview() -> void:
	_clear_editor_preview()

	if _initial_character == null or _initial_character.character_mesh == null:
		return

	_replace_character_visual(_initial_character.character_mesh, true)


func _clear_editor_preview() -> void:
	for child: Node in _skeleton.get_children():
		if child is MeshInstance3D and child.has_meta(_EDITOR_PREVIEW_META):
			_skeleton.remove_child(child)
			child.free()


func replace_character_visual(character_scene: PackedScene) -> void:
	_replace_character_visual(character_scene, false)


func _replace_character_visual(character_scene: PackedScene, editor_preview: bool) -> void:
	assert(character_scene, "Character scene missing in " + name)

	var character_instance: Node3D = character_scene.instantiate() as Node3D
	assert(character_instance, "Character scene root must be Node3D in " + name)

	var source_skeleton: Skeleton3D = character_instance.get_node("Rig_Medium/Skeleton3D") as Skeleton3D
	assert(source_skeleton, "Skeleton3D missing in " + character_instance.name)

	_validate_skeleton(source_skeleton)

	var new_meshes: Array[MeshInstance3D] = []
	for child: Node in source_skeleton.get_children():
		if child is MeshInstance3D:
			new_meshes.append(child as MeshInstance3D)

	assert(not new_meshes.is_empty(), "Character has no meshes in " + character_instance.name)

	var previous_meshes: Array[MeshInstance3D] = []
	for child: Node in _skeleton.get_children():
		if child is MeshInstance3D:
			if not editor_preview or child.has_meta(_EDITOR_PREVIEW_META):
				previous_meshes.append(child as MeshInstance3D)

	for mesh: MeshInstance3D in previous_meshes:
		_skeleton.remove_child(mesh)

		if editor_preview:
			mesh.free()
		else:
			mesh.queue_free()

	for mesh: MeshInstance3D in new_meshes:
		if mesh.skin != null:
			mesh.skin = _remap_skin(mesh.skin, source_skeleton)

		source_skeleton.remove_child(mesh)
		mesh.owner = null
		_skeleton.add_child(mesh)
		mesh.skeleton = mesh.get_path_to(_skeleton)

		if editor_preview:
			mesh.set_meta(_EDITOR_PREVIEW_META, true)

	if editor_preview:
		character_instance.free()
	else:
		character_instance.queue_free()

	if not editor_preview:
		meshes_replaced.emit()


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
