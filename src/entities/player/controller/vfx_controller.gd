class_name VFXController
extends Node

var _feather_particles: GPUParticles3D

@onready var entity: CharacterBody3D = owner as CharacterBody3D


func spawn_ghost_trail(duration: float = 0.5, color: Color = Color(0.8, 1.0, 1.5, 0.4)) -> void:
	if not is_instance_valid(entity) or not entity.is_inside_tree():
		return

	var entity_model: Node = entity
	# TODO BUG Remove hardcoded references
	if entity.has_node("Visual/Rig_Medium"):
		entity_model = entity.get_node("Visual/Rig_Medium")
	elif entity.has_node("Visual"):
		entity_model = entity.get_node("Visual")

	var ghost: Node = entity_model.duplicate()
	entity.get_parent().add_child(ghost)

	if ghost is Node3D and entity_model is Node3D:
		ghost.global_transform = entity_model.global_transform
	elif ghost is Node3D:
		ghost.global_transform = entity.global_transform

	var override_mat: StandardMaterial3D = StandardMaterial3D.new()
	override_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	override_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	override_mat.albedo_color = color

	var all_meshes: Array[MeshInstance3D] = []
	_collect_sub_meshes(ghost, all_meshes)

	for m: MeshInstance3D in all_meshes:
		m.material_override = override_mat

	var tween: Tween = create_tween()
	tween.tween_property(override_mat, "albedo_color:a", 0.0, duration).set_trans(Tween.TRANS_QUART).set_ease(Tween.EASE_OUT)
	tween.tween_callback(ghost.queue_free)


func toggle_feather_fall(active: bool, target: Node3D = null) -> void:
	if active and not _feather_particles and target:
		_feather_particles = GPUParticles3D.new()
		var mat: ParticleProcessMaterial = ParticleProcessMaterial.new()
		mat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
		mat.emission_box_extents = Vector3(1.0, 0.1, 1.0)
		mat.gravity = Vector3(0.0, -1.0, 0.0)
		_feather_particles.process_material = mat

		var draw_mesh: BoxMesh = BoxMesh.new()
		draw_mesh.size = Vector3(0.05, 0.2, 0.05)
		var d_mat: StandardMaterial3D = StandardMaterial3D.new()
		d_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		draw_mesh.material = d_mat
		_feather_particles.draw_pass_1 = draw_mesh

		target.add_child(_feather_particles)

	if _feather_particles:
		_feather_particles.emitting = active


func _collect_sub_meshes(node: Node, arr: Array[MeshInstance3D]) -> void:
	for child: Node in node.get_children():
		if child is MeshInstance3D:
			arr.append(child)
		if child.get_script() != null:
			child.set_script(null)
		_collect_sub_meshes(child, arr)
