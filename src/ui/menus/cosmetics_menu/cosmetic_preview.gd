@tool
extends Node3D

## Card viewport content by slot, rigged character on idle pose or spinning weapon fitted to preview size

const WEAPON_PREVIEW_SIZE: float = 0.6
const WEAPON_SPIN_DURATION: float = 4.0

var _card: CosmeticCard
var _preview_instance: Node3D
var _spin: Tween

@onready var visual: Node3D = %Visual
@onready var weapon_pivot: Node3D = %WeaponPivot


func _ready() -> void:
	_card = owner as CosmeticCard
	if _card == null:
		assert(Engine.is_editor_hint(), "CosmeticCard owner missing in " + name)
		return

	_card.asset_changed.connect(_refresh)
	_refresh()


func _refresh() -> void:
	if _spin != null:
		_spin.kill()
	if is_instance_valid(_preview_instance):
		_preview_instance.queue_free()
	_preview_instance = null

	var asset: CosmeticAsset = _card.asset
	assert(asset or Engine.is_editor_hint(), "CosmeticCard asset missing in " + name)
	if asset == null:
		return

	match asset.get_slot():
		CosmeticAsset.Slot.CHARACTER:
			_discard(weapon_pivot)
			_show_character(asset as CharacterEntityAsset)
		CosmeticAsset.Slot.WEAPON:
			_discard(visual)
			_show_weapon(asset as WeaponAsset)
		_:
			assert(false, "Preview unsupported for slot in " + name)


## Editor hides, runtime frees
func _discard(node: Node3D) -> void:
	if not is_instance_valid(node):
		return
	if Engine.is_editor_hint():
		node.visible = false
	else:
		node.queue_free()


func _show_character(character: CharacterEntityAsset) -> void:
	assert(character != null and (character.character_mesh != null or Engine.is_editor_hint()), "Character mesh missing in " + name)
	if character == null or character.character_mesh == null:
		return

	visual.visible = true
	for child: Node in visual.get_children():
		var model: Node3D = child as Node3D
		if model != null:
			_discard(model)

	_preview_instance = character.character_mesh.instantiate() as Node3D
	assert(_preview_instance != null, "Character scene root must be Node3D in " + self.name)
	visual.add_child(_preview_instance)


func _show_weapon(weapon: WeaponAsset) -> void:
	assert(weapon != null and (weapon.weapon_scene != null or Engine.is_editor_hint()), "Weapon scene missing in " + name)
	if weapon == null or weapon.weapon_scene == null:
		return

	weapon_pivot.visible = true
	weapon_pivot.rotation = Vector3.ZERO

	_preview_instance = weapon.weapon_scene.instantiate() as Node3D
	assert(_preview_instance != null, "Weapon scene root must be Node3D in " + self.name)
	weapon_pivot.add_child(_preview_instance)

	var bounds: AABB = _get_bounds(_preview_instance)
	var fit: float = WEAPON_PREVIEW_SIZE / bounds.get_longest_axis_size()
	_preview_instance.scale = Vector3.ONE * fit
	_preview_instance.position = -bounds.get_center() * fit

	_spin = create_tween().set_loops()
	_spin.tween_property(weapon_pivot, "rotation:y", TAU, WEAPON_SPIN_DURATION).as_relative()


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
