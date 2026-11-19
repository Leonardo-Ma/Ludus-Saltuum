extends Node3D

## Card viewport content by slot, rigged character on idle pose or spinning weapon fitted to preview size

const WEAPON_PREVIEW_SIZE: float = 0.6
const WEAPON_SPIN_DURATION: float = 4.0

@onready var visual: Node3D = %Visual
@onready var weapon_pivot: Node3D = %WeaponPivot


func _ready() -> void:
	var card: CosmeticCard = owner as CosmeticCard
	assert(card != null and card.asset != null, "CosmeticCard asset missing in " + name)

	match card.asset.get_slot():
		CosmeticAsset.Slot.CHARACTER:
			weapon_pivot.queue_free()
			_show_character(card.asset as CharacterEntityAsset)
		CosmeticAsset.Slot.WEAPON:
			visual.queue_free()
			_show_weapon(card.asset as WeaponAsset)
		_:
			assert(false, "Preview unsupported for slot in " + name)


func _show_character(character: CharacterEntityAsset) -> void:
	var instance: Node3D = character.character_mesh.instantiate() as Node3D
	assert(instance != null, "Character scene root must be Node3D in " + self.name)

	for child: Node in visual.get_children():
		visual.remove_child(child)
		child.queue_free()

	visual.add_child(instance)


func _show_weapon(weapon: WeaponAsset) -> void:
	var instance: Node3D = weapon.weapon_scene.instantiate() as Node3D
	assert(instance != null, "Weapon scene root must be Node3D in " + self.name)
	weapon_pivot.add_child(instance)

	var bounds: AABB = _get_bounds(instance)
	var fit: float = WEAPON_PREVIEW_SIZE / bounds.get_longest_axis_size()
	instance.scale = Vector3.ONE * fit
	instance.position = -bounds.get_center() * fit

	var spin: Tween = create_tween().set_loops()
	spin.tween_property(weapon_pivot, "rotation:y", TAU, WEAPON_SPIN_DURATION).as_relative()


## Union of mesh bounds in root local space
func _get_bounds(root: Node3D) -> AABB:
	var meshes: Array[Node] = root.find_children("*", "MeshInstance3D", true, false)
	if root is MeshInstance3D:
		meshes.push_front(root)
	assert(not meshes.is_empty(), "Weapon scene has no mesh in " + name)

	var to_root: Transform3D = root.global_transform.affine_inverse()
	var bounds: AABB
	for index: int in meshes.size():
		var mesh_instance: MeshInstance3D = meshes[index] as MeshInstance3D
		var local_bounds: AABB = to_root * mesh_instance.global_transform * mesh_instance.get_aabb()
		bounds = local_bounds if index == 0 else bounds.merge(local_bounds)
	return bounds
