## Rotates platform through physics so bodies standing on it receive platform motion
@tool
class_name RotateObject
extends AnimatableBody3D

@export_category("Rotation")
@export var should_rotate_x: bool = false
@export var should_rotate_y: bool = true
@export var should_rotate_z: bool = false
@export_range(0.0, 720.0, 1.0, "suffix:deg/s") var rotation_speed: float = 30.0
@export var spin_enabled: bool = true

@export_category("Visual")
@export var platform_mesh: Mesh:
	set(value):
		platform_mesh = value
		if is_instance_valid(_rotating_platform_mesh):
			_rotating_platform_mesh.mesh = value

@export_category("Collision")
@export var platform_shape: Shape3D:
	set(value):
		platform_shape = value
		if is_instance_valid(_collision_shape):
			_collision_shape.shape = value

@export_category("Editor")
@export_tool_button("Reset Transform", "UndoRedo") var reset_transform_action: Callable = _reset_transform

@onready var _rotating_platform_mesh: MeshInstance3D = %RotatingPlatformMesh
@onready var _collision_shape: CollisionShape3D = %CollisionShape3D


func _ready() -> void:
	_rotating_platform_mesh.mesh = platform_mesh
	_collision_shape.shape = platform_shape


func _physics_process(delta: float) -> void:
	if not spin_enabled:
		return

	var rotation_axis: Vector3 = Vector3(float(should_rotate_x), float(should_rotate_y), float(should_rotate_z))

	if rotation_axis.is_zero_approx():
		return

	rotate(rotation_axis.normalized(), deg_to_rad(rotation_speed) * delta)


func set_spin_enabled(value: bool) -> void:
	spin_enabled = value


func _reset_transform() -> void:
	if not Engine.is_editor_hint():
		return

	position = Vector3.ZERO
	rotation = Vector3.ZERO
	scale = Vector3.ONE
