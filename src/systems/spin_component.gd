## Continuously rotates the parent node around a given axis
class_name SpinComponent
extends Node

@export var axis: Vector3 = Vector3.UP
@export_range(0.0, 720.0, 1.0, "suffix:deg/s") var speed_degrees: float = 90.0
@export var spin_enabled: bool = true

@onready var _target: Node3D = get_parent()


func _ready() -> void:
	assert(_target is Node3D, "SpinComponent: parent must be Node3D in " + name)


func _physics_process(delta: float) -> void:
	if not spin_enabled:
		return
	_target.rotate(axis.normalized(), deg_to_rad(speed_degrees) * delta)


func set_spin_enabled(value: bool) -> void:
	spin_enabled = value
