class_name NPCAnimationBridge
extends AnimationBridge

@onready var _movement: NPCMovementController = %NPCMovementController


func _child_ready() -> void:
	_movement.movement_direction_changed.connect(_on_movement_direction_changed)


func _on_movement_direction_changed(direction: Vector2, _speed_factor: float) -> void:
	_controller.set_movement(direction)
