## Simple node to draw visual debug lines for the perception system
class_name PerceptionDebug
extends Node3D

var _immediate_mesh: ImmediateMesh
var _mesh_instance: MeshInstance3D
var _perception_system: PerceptionSystem


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return
	_perception_system = get_parent() as PerceptionSystem
	assert(_perception_system != null, "PerceptionDebug must be a child of PerceptionSystem in " + self.name)

	_immediate_mesh = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _immediate_mesh

	var material: StandardMaterial3D = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.vertex_color_use_as_albedo = true
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_mesh_instance.material_override = material

	# Add to top level so it doesn't move with the AI
	get_tree().root.call_deferred("add_child", _mesh_instance)

	_perception_system.perception_updated.connect(_on_perception_updated)


func _exit_tree() -> void:
	if is_instance_valid(_mesh_instance):
		_mesh_instance.queue_free()


func _on_perception_updated(_detections: Array) -> void:
	if not visible:
		return

	# Delay drawing slightly to let physics sync
	call_deferred("_draw_debug")


func _process(_delta: float) -> void:
	if not visible:
		if _immediate_mesh.get_surface_count() > 0:
			_immediate_mesh.clear_surfaces()
		return
	_draw_debug()


func _draw_debug() -> void:
	# gdlint-ignore-next-line private-access
	if not is_instance_valid(_perception_system) or not is_instance_valid(_perception_system._owner_node):
		return

	# gdlint-ignore-next-line private-access
	var owner_pos: Vector3 = _perception_system._owner_node.global_position + Vector3(0, 1.0, 0)
	var time: float = Time.get_ticks_msec() / 1000.0

	var valid_targets: int = 0
	for target: Node3D in _perception_system.known_entities:
		if is_instance_valid(target) and _perception_system.known_entities[target].is_valid(time, _perception_system.config.memory_duration):
			valid_targets += 1

	_immediate_mesh.clear_surfaces()

	if valid_targets == 0:
		return

	_immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)

	for target: CharacterBody3D in _perception_system.known_entities:
		if not is_instance_valid(target):
			continue

		var data: KnownEntityData = _perception_system.known_entities[target]
		if not data.is_valid(time, _perception_system.config.memory_duration):
			continue

		var target_pos: Vector3 = data.last_known_position + Vector3(0, 1.0, 0)

		# Draw Line to Target
		_immediate_mesh.surface_set_color(Color(1, 0, 0, 0.8)) # Red line
		_immediate_mesh.surface_add_vertex(owner_pos)
		_immediate_mesh.surface_add_vertex(target_pos)

		# Draw Marker (Cross) at Last Known Position
		_immediate_mesh.surface_set_color(Color(1, 1, 0, 1.0)) # Yellow cross
		var s: float = 0.5
		_immediate_mesh.surface_add_vertex(target_pos + Vector3(-s, 0, 0))
		_immediate_mesh.surface_add_vertex(target_pos + Vector3(s, 0, 0))
		_immediate_mesh.surface_add_vertex(target_pos + Vector3(0, -s, 0))
		_immediate_mesh.surface_add_vertex(target_pos + Vector3(0, s, 0))
		_immediate_mesh.surface_add_vertex(target_pos + Vector3(0, 0, -s))
		_immediate_mesh.surface_add_vertex(target_pos + Vector3(0, 0, s))

	_immediate_mesh.surface_end()
