# https://www.youtube.com/watch?v=EP5AYllgHy8 Godot 4.0 Third Person Controller Tutorial ( 2023 )
@icon("uid://d4g1stey2kdtm")  # character_move.png
## Player movement controller
class_name MovementController extends Node3D

# These signals go to animation controller, debug...
signal movement_direction_changed(direction: Vector2, speed_factor: float)
signal jumped  # emitted only in first ground jump
signal in_air
signal landed

const COYOTE_TIME: float = 0.05
const DEADZONE: float = 0.3  # deadzone to prevent drift

@export var camera: Node3D

var gravity: float = ProjectSettings.get_setting("physics/3d/default_gravity")
var current_speed: float = 0.0
var movement_enabled: bool = true

var coyote_timer: float = 0.0
var disable_timer: float = 0.0

var _was_on_floor: bool = false
var _external_force: Vector3 = Vector3.ZERO


## This is executed by entity's _physics_process
func move(body: CharacterBody3D, delta: float) -> void:
	if disable_timer > 0.0:
		disable_timer -= delta
		if disable_timer <= 0.0:
			movement_enabled = true

	movement_logic(body)
	jump_air_logic(body, delta)
	_apply_external_force(body)


func disable_movement(duration: float) -> void:
	movement_enabled = false
	if duration > disable_timer:
		disable_timer = duration


func movement_logic(body: CharacterBody3D) -> void:
	if not movement_enabled:
		movement_direction_changed.emit(Vector2.ZERO, 0.0)
		body.velocity.x = move_toward(body.velocity.x, 0, current_speed)
		body.velocity.z = move_toward(body.velocity.z, 0, current_speed)
		return

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
		var speed_mult: float = input_length
		current_speed = speed_mult * owner.movement.speed
		# Clamp to allowed maximum
		current_speed = clamp(current_speed, 0.0, owner.movement.speed)

		# Calculate blend direction in body's local space (mesh is child of body with 0 rotation)
		var local_direction: Vector3 = body.global_transform.basis.inverse() * direction
		var speed_factor: float = current_speed / owner.movement.speed
		var blend_direction: Vector2 = Vector2(local_direction.x, local_direction.z) * speed_factor

		movement_direction_changed.emit(blend_direction, speed_factor)

		# Make armature relative to camera instead of locking upfront
		#if direction.length() > 0.01:
		#armature.look_at(armature.global_transform.origin + direction, Vector3.UP)

		body.velocity.x = direction.x * current_speed
		body.velocity.z = direction.z * current_speed
	else:
		movement_direction_changed.emit(Vector2.ZERO, 0.0)
		body.velocity.x = move_toward(body.velocity.x, 0, current_speed)
		body.velocity.z = move_toward(body.velocity.z, 0, current_speed)


func jump_air_logic(body: CharacterBody3D, delta: float) -> void:
	var is_on_floor_now: bool = body.is_on_floor()

	if not is_on_floor_now:
		coyote_timer -= delta
		if _was_on_floor:
			in_air.emit()
		body.velocity.y -= gravity * delta

		# Jump cutting: if jump button is released while moving upwards, cut velocity
		#if Input.is_action_just_released("jump") and body.velocity.y > 0.0:
		#body.velocity.y *= 0.5
	else:
		coyote_timer = COYOTE_TIME
		if not _was_on_floor:
			landed.emit()

	_was_on_floor = is_on_floor_now

	if not movement_enabled:
		return

	# Ground jump, only when coyote time is still valid
	if Input.is_action_just_pressed("jump") and coyote_timer > 0.0:
		jump(owner.movement.jump_velocity, body)
		jumped.emit()


## Doesn't emit signal so caller decide what to announce
func jump(velocity_y: float, body: CharacterBody3D) -> void:
	body.velocity.y = velocity_y
	coyote_timer = 0.0


## Called by external systems (wind, hazards...) to add continuous push force this frame
func add_external_force(force: Vector3) -> void:
	_external_force += force


func _apply_external_force(body: CharacterBody3D) -> void:
	if _external_force != Vector3.ZERO:
		body.velocity += _external_force
		_external_force = Vector3.ZERO
