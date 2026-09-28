# NOTE If changed renderer to use forward +, this -may- be unnecessary due to shader baking
## Precompiles renderer variants off-screen at boot to avoid first time opening stutter
extends Node3D

@onready var _sub_viewport: SubViewport = SubViewport.new()
@onready var _material_mesh: MeshInstance3D = MeshInstance3D.new()


func _ready() -> void:
	var start_time_msec: int = Time.get_ticks_msec()

	_setup_viewport()
	_setup_material_mesh()

	await _warmup_scenes()

	_sub_viewport.queue_free()

	var elapsed_seconds: float = float(Time.get_ticks_msec() - start_time_msec) / 1000.0
	print("Shader warmup completed in %.3f seconds" % elapsed_seconds)

	queue_free()


func _setup_viewport() -> void:
	_sub_viewport.size = Vector2i(4, 4)
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	_sub_viewport.render_target_clear_mode = SubViewport.CLEAR_MODE_ALWAYS
	_sub_viewport.world_3d = World3D.new()
	add_child(_sub_viewport)


func _setup_material_mesh() -> void:
	var quad_mesh: QuadMesh = QuadMesh.new()
	quad_mesh.size = Vector2.ONE

	_material_mesh.mesh = quad_mesh
	_material_mesh.position = Vector3(0.0, 0.0, -2.0)
	_sub_viewport.add_child(_material_mesh)


func _warmup_scenes() -> void:
	for warmup_scene: Node in get_children():
		if warmup_scene == _sub_viewport:
			continue

		assert(warmup_scene is Node3D, "Warmup scene root must be Node3D in " + self.name)

		var scene_instance: Node3D = warmup_scene as Node3D
		var original_parent: Node = scene_instance.get_parent()
		var original_transform: Transform3D = scene_instance.global_transform

		scene_instance.reparent(_sub_viewport, false)
		scene_instance.global_transform = original_transform
		scene_instance.process_mode = Node.PROCESS_MODE_DISABLED

		await _render_frame()

		scene_instance.reparent(original_parent, false)
		scene_instance.global_transform = original_transform


func _render_frame() -> void:
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
