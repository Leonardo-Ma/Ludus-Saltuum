@tool
class_name CharacterVisual
extends Node3D

## Replaces character meshes while preserving animation rig

signal meshes_replaced

const _EDITOR_PREVIEW_META: StringName = &"_character_visual_preview"
const _IMPORTED_ATTACHMENT_META: StringName = &"_character_visual_attachment"
## Right hand weapon belongs to WeaponVisual
const _WEAPON_ATTACHMENT_BONES: Array[StringName] = [&"handslot.r"]

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
		assert(_initial_character, "Initial character missing in " + name)
		replace_character_visual(_initial_character.character_mesh)


func _refresh_editor_preview() -> void:
	_clear_editor_preview()

	if _initial_character == null or _initial_character.character_mesh == null:
		return

	_replace_character_visual(_initial_character.character_mesh, true)


func _clear_editor_preview() -> void:
	for child: Node in _skeleton.get_children():
		if child is MeshInstance3D and child.has_meta(_EDITOR_PREVIEW_META):
			_remove_skeleton_child(child, true)


func replace_character_visual(character_scene: PackedScene) -> void:
	_replace_character_visual(character_scene, false)


func _replace_character_visual(character_scene: PackedScene, editor_preview: bool) -> void:
	assert(character_scene, "Character scene missing in " + name)

	var character_instance: Node3D = character_scene.instantiate() as Node3D
	assert(character_instance, "Character scene root must be Node3D in " + name)

	var source_skeleton: Skeleton3D = character_instance.get_node("Rig_Medium/Skeleton3D") as Skeleton3D
	assert(source_skeleton, "Skeleton3D missing in " + character_instance.name)

	_validate_skeleton(source_skeleton)

	var new_meshes: Array[MeshInstance3D] = _collect_source_meshes(source_skeleton, character_instance)
	var new_attachments: Array[BoneAttachment3D] = _collect_source_attachments(source_skeleton)

	_remove_previous_attachments(editor_preview)
	_remove_previous_meshes(editor_preview)

	_import_meshes(new_meshes, source_skeleton, editor_preview)
	_import_attachments(new_attachments, source_skeleton)

	_dispose_node(character_instance, editor_preview)

	if not editor_preview:
		meshes_replaced.emit()


func _collect_source_meshes(source_skeleton: Skeleton3D, character_instance: Node3D) -> Array[MeshInstance3D]:
	var meshes: Array[MeshInstance3D] = []

	for child: Node in source_skeleton.get_children():
		if child is MeshInstance3D:
			meshes.append(child)

	assert(not meshes.is_empty(), "Character has no meshes in " + character_instance.name)

	return meshes


func _collect_source_attachments(source_skeleton: Skeleton3D) -> Array[BoneAttachment3D]:
	var attachments: Array[BoneAttachment3D] = []

	for child: Node in source_skeleton.get_children():
		if child is BoneAttachment3D:
			if _WEAPON_ATTACHMENT_BONES.has(StringName(child.bone_name)):
				continue

			assert(_skeleton.find_bone(child.bone_name) >= 0, "Attachment bone missing in " + name + ": " + child.bone_name)

			attachments.append(child)

	return attachments


func _remove_previous_attachments(editor_preview: bool) -> void:
	var previous_attachments: Array[BoneAttachment3D] = []

	for child: Node in _skeleton.get_children():
		if child is BoneAttachment3D and child.has_meta(_IMPORTED_ATTACHMENT_META):
			previous_attachments.append(child)

	for attachment: BoneAttachment3D in previous_attachments:
		_remove_skeleton_child(attachment, editor_preview)


func _remove_previous_meshes(editor_preview: bool) -> void:
	var previous_meshes: Array[MeshInstance3D] = []

	for child: Node in _skeleton.get_children():
		if child is MeshInstance3D:
			if not editor_preview or child.has_meta(_EDITOR_PREVIEW_META):
				previous_meshes.append(child)

	for mesh: MeshInstance3D in previous_meshes:
		_remove_skeleton_child(mesh, editor_preview)


func _import_meshes(meshes: Array[MeshInstance3D], source_skeleton: Skeleton3D, editor_preview: bool) -> void:
	for mesh: MeshInstance3D in meshes:
		if mesh.skin != null:
			mesh.skin = _remap_skin(mesh.skin, source_skeleton)

		source_skeleton.remove_child(mesh)
		mesh.owner = null
		_skeleton.add_child(mesh)
		mesh.skeleton = mesh.get_path_to(_skeleton)

		if editor_preview:
			mesh.set_meta(_EDITOR_PREVIEW_META, true)


func _import_attachments(attachments: Array[BoneAttachment3D], source_skeleton: Skeleton3D) -> void:
	for attachment: BoneAttachment3D in attachments:
		source_skeleton.remove_child(attachment)
		_clear_owner(attachment)
		_skeleton.add_child(attachment)
		attachment.bone_idx = _skeleton.find_bone(attachment.bone_name)
		attachment.set_meta(_IMPORTED_ATTACHMENT_META, true)


func _remove_skeleton_child(child: Node, editor_preview: bool) -> void:
	_skeleton.remove_child(child)
	_dispose_node(child, editor_preview)


func _dispose_node(node: Node, editor_preview: bool) -> void:
	if editor_preview:
		node.free()
	else:
		node.queue_free()


func _validate_skeleton(source_skeleton: Skeleton3D) -> void:
	assert(source_skeleton.get_bone_count() == _skeleton.get_bone_count(), "Skeleton bone count mismatch in " + name)

	for source_index: int in range(source_skeleton.get_bone_count()):
		var bone_name: StringName = source_skeleton.get_bone_name(source_index)
		var target_index: int = _skeleton.find_bone(bone_name)

		assert(target_index >= 0, "Missing bone " + str(bone_name) + " in " + name)

		var source_parent_name: StringName = _get_parent_bone_name(source_skeleton, source_index)
		var target_parent_name: StringName = _get_parent_bone_name(_skeleton, target_index)

		assert(source_parent_name == target_parent_name, "Bone hierarchy mismatch at " + str(bone_name) + " in " + name)

		var source_rest: Transform3D = source_skeleton.get_bone_rest(source_index)
		var target_rest: Transform3D = _skeleton.get_bone_rest(target_index)

		assert(source_rest.is_equal_approx(target_rest), "Bone rest pose mismatch at " + str(bone_name) + " in " + name)


func _get_parent_bone_name(skeleton: Skeleton3D, bone_index: int) -> StringName:
	var parent_index: int = skeleton.get_bone_parent(bone_index)

	if parent_index < 0:
		return &""

	return skeleton.get_bone_name(parent_index)


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


func _clear_owner(node: Node) -> void:
	node.owner = null

	for child: Node in node.get_children():
		_clear_owner(child)
