# https://www.youtube.com/watch?v=EP5AYllgHy8 Godot 4.0 Third Person Controller Tutorial ( 2023 )
@icon("uid://d4g1stey2kdtm") # character_move.png
## Player movement controller
class_name PlayerMovementController
extends EntityMovementController

signal jumped # emitted only in first ground jump
signal in_air
signal landed

const COYOTE_TIME: float = 0.05
const DEADZONE: float = 0.3 # gamepad joystick deadzone to prevent drift

@export var camera: CameraController

var coyote_timer: float = 0.0

var _was_on_floor: bool = false


func _child_ready() -> void:
	assert(camera != null, "Camera missing for " + owner.name)


func _move(delta: float) -> void:
	if movement_enabled:
		movement_logic()
	jump_air_logic(delta)


func movement_logic() -> void:
	# Get raw input vector (works for keyboard and gamepad left stick)
	var input_direction: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var input_length: float = input_direction.length()

	# Apply deadzone to ignore tiny stick movements (keyboard always gives 1.0)
	if input_length < DEADZONE:
		input_length = 0.0
		input_direction = Vector2.ZERO

	if input_length > 0.0:
		# Use camera's global basis for movement direction (relative to camera view)
		var camera_basis: Basis = camera.global_transform.basis
		var cam_right: Vector3 = Vector3(camera_basis.x.x, 0.0, camera_basis.x.z).normalized()
		var cam_forward: Vector3 = Vector3(camera_basis.z.x, 0.0, camera_basis.z.z).normalized()
		var direction: Vector3 = (cam_right * input_direction.x + cam_forward * input_direction.y).normalized()

		# Speed scales with stick deflection (0..1); keyboard always produces 1.0
		var current_speed: float = input_length * _movement.speed

		# Clamp to allowed maximum
		current_speed = clamp(current_speed, 0.0, _movement.speed)

		# Calculate blend direction in owner's local space (mesh is child of owner with 0 rotation)
		var local_direction: Vector3 = owner.global_transform.basis.inverse() * direction
		var speed_factor: float = current_speed / _movement.speed
		var blend_direction: Vector2 = Vector2(local_direction.x, local_direction.z) * speed_factor

		movement_direction_changed.emit(blend_direction, speed_factor)

		# Make armature relative to camera instead of locking upfront
		#if direction.length() > 0.01:
		#armature.look_at(armature.global_transform.origin + direction, Vector3.UP)
		owner.velocity.x = direction.x * current_speed
		owner.velocity.z = direction.z * current_speed
	else:
		movement_direction_changed.emit(Vector2.ZERO, 0.0)
		owner.velocity.x = move_toward(owner.velocity.x, 0.0, _movement.speed)
		owner.velocity.z = move_toward(owner.velocity.z, 0.0, _movement.speed)


func jump_air_logic(delta: float) -> void:
	var is_on_floor_now: bool = owner.is_on_floor()

	if not is_on_floor_now:
		coyote_timer -= delta
		if _was_on_floor:
			in_air.emit()
		owner.velocity += owner.get_gravity() * delta

		# Jump cutting: if jump button is released while moving upwards, cut velocity
		#if Input.is_action_just_released("jump") and owner.velocity.y > 0.0:
		#owner.velocity.y *= 0.5
	else:
		coyote_timer = COYOTE_TIME
		if not _was_on_floor:
			landed.emit()

	_was_on_floor = is_on_floor_now

	if not movement_enabled:
		return

	# Ground jump, only when coyote time is still valid
	if Input.is_action_just_pressed("jump") and coyote_timer > 0.0:
		jump(_movement.jump_velocity)
		jumped.emit()


# TODO Might be best to emit signal here?
## Doesn't emit signal so caller decide what to announce
func jump(velocity_y: float) -> void:
	owner.velocity.y = velocity_y
	coyote_timer = 0.0
