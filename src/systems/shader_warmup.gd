extends Node3D

## NOTE If changed renderer to use forward +, this -may- be unnecessary due to shader baking
## Precompiles renderer variants off-screen at boot to avoid first time opening stutter

@onready var _sub_viewport: SubViewport = %WarmupViewport
@onready var _samples: Node3D = %Samples
@onready var _camera: Camera3D = %Camera3D
@onready var _environment_sample: Node3D = %WarmupEnvironment
@onready var _canvas_preview: Polygon2D = %CanvasShaderPreview
@onready var _canvas_material: ShaderMaterial = _canvas_preview.material

## Canvas shaders compiled at startup instead of first use to avoid stutter
@export var canvas_shaders: Array[Shader] = []
## Environments compiled at startup instead of first use
@export var environments: Array[Environment] = []


func _ready() -> void:
	if DisplayServer.get_name() == "headless" or not RenderingServer.is_render_loop_enabled():
		queue_free()
		return

	var start_time_msec: int = Time.get_ticks_msec()

	await _warmup_scenes()
	await _warmup_canvas_shaders()
	await _warmup_environments()

	var elapsed_seconds: float = float(Time.get_ticks_msec() - start_time_msec) / 1000.0
	print("Shader warmup completed in %.3f seconds" % elapsed_seconds)

	queue_free()


func _warmup_scenes() -> void:
	for sample: Node3D in _samples.get_children():
		sample.show()
		await _render_frame()
		sample.hide()


func _warmup_canvas_shaders() -> void:
	_canvas_preview.show()
	for shader: Shader in canvas_shaders:
		assert(shader != null and shader.get_mode() == Shader.MODE_CANVAS_ITEM, "Expected a canvas shader in " + name)
		_canvas_material.shader = shader
		await _render_frame()
	_canvas_preview.hide()


func _warmup_environments() -> void:
	_environment_sample.show()
	for environment: Environment in environments:
		_camera.environment = environment
		await _render_frame()


func _render_frame() -> void:
	_sub_viewport.render_target_update_mode = SubViewport.UPDATE_ONCE
	await RenderingServer.frame_post_draw
