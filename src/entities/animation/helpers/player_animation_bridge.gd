class_name PlayerAnimationBridge
extends AnimationBridge

@onready var _movement: PlayerMovementComponent = %PlayerMovementComponent
@onready var _skills: SkillsController = %SkillsController
@onready var _visual: CharacterVisual = %Visual


func _child_ready() -> void:
	assert(_movement and _skills and _visual, "Player animation bridge dependencies missing in " + name)
	_movement.movement_direction_changed.connect(_on_movement_direction_changed)
	_movement.jumped.connect(_controller.jump)
	_movement.in_air.connect(_controller.set_airborne.bind(true))
	_movement.landed.connect(_controller.set_airborne.bind(false))
	_movement.crouch_toggled.connect(_on_crouch_toggled)
	_skills.dash_started.connect(_on_dash_started)


func _on_movement_direction_changed(direction: Vector2, _speed_factor: float) -> void:
	_controller.set_movement(direction)


func _on_crouch_toggled(active: bool) -> void:
	_controller.set_stance(AnimKeys.CROUCHING if active else AnimKeys.STANDING)


func _on_dash_started(velocity: Vector3, duration: float) -> void:
	# KayKit dodge clips move forward along local +Z and left along local +X
	var local_velocity: Vector3 = _visual.global_basis.orthonormalized().inverse() * velocity
	var variant: StringName
	if absf(local_velocity.z) >= absf(local_velocity.x):
		variant = &"dodge_forward" if local_velocity.z >= 0.0 else &"dodge_backward"
	else:
		variant = &"dodge_left" if local_velocity.x > 0.0 else &"dodge_right"
	_controller.request_action(AnimKeys.DODGE, duration, variant)
