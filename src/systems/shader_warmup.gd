# NOTE As it's a small procedurally generated game, this is mostly  fine, but anything bigger should
# use a level/biome/area specific warmup to avoid compiling unnecessary things
# TODO Add a timer to print how long it took
# TODO Either hardcode folders paths for levels folder or add certain asserts
## Precompiles shaders/materials off-screen at boot to avoid first-use stutter
## GL Compatibility renderer compiles synchronously, no async ubershader fallback
extends Node

@export var environments: Array[Environment] = []
@export var materials: Array[Material] = []
@export var warmup_scenes: Array[PackedScene] = []

@onready var _sub_viewport: SubViewport = SubViewport.new()
@onready var _camera: Camera3D = Camera3D.new()


func _ready() -> void:
	# TODO Need to check if this works without look at the viewport
	_sub_viewport.size = Vector2i(4, 4)
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(_sub_viewport)

	_sub_viewport.add_child(_camera)
	_camera.current = true

	await _warmup_environments()
	await _warmup_materials()
	await _warmup_scenes()

	_sub_viewport.queue_free()


func _warmup_environments() -> void:
	for environment: Environment in environments:
		_camera.environment = environment
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw


func _warmup_materials() -> void:
	if materials.is_empty():
		return
	var mesh_instance: MeshInstance3D = MeshInstance3D.new()
	mesh_instance.mesh = QuadMesh.new()
	_sub_viewport.add_child(mesh_instance)
	for material: Material in materials:
		mesh_instance.material_override = material
		await RenderingServer.frame_post_draw
	mesh_instance.queue_free()


func _warmup_scenes() -> void:
	for scene: PackedScene in warmup_scenes:
		var instance: Node3D = scene.instantiate()
		_sub_viewport.add_child(instance)
		await RenderingServer.frame_post_draw
		instance.queue_free()
