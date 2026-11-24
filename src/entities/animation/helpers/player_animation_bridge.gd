class_name PlayerAnimationBridge
extends AnimationBridge

@onready var _movement: PlayerMovementComponent = %PlayerMovementComponent


func _child_ready() -> void:
	_movement.movement_direction_changed.connect(_on_movement_direction_changed)
	_movement.jumped.connect(_controller.jump)
	_movement.in_air.connect(_controller.set_airborne.bind(true))
	_movement.landed.connect(_controller.set_airborne.bind(false))
	_movement.crouch_toggled.connect(_on_crouch_toggled)


func _on_movement_direction_changed(direction: Vector2, _speed_factor: float) -> void:
	_controller.set_movement(direction)


func _on_crouch_toggled(active: bool) -> void:
	_controller.set_stance(AnimKeys.CROUCHING if active else AnimKeys.STANDING)
