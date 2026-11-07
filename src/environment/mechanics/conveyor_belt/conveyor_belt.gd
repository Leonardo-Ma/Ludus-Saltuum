## Surface carrying touching bodies along local +Z via constant_linear_velocity
class_name ConveyorBelt
extends StaticBody3D

@export_range(-50.0, 50.0, 0.1, "suffix:m/s") var speed: float = 2.0


func _ready() -> void:
	constant_linear_velocity = -global_basis.z.normalized() * speed
