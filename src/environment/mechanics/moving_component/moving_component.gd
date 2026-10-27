class_name MovingComponent
extends Node3D

## Moves assigned object along while someone on top or looping

@export_category("References")
@export var moving_object: Node3D
@export var path: Path3D
@export var surface_detection: Area3D

@export_category("Movement")
@export_range(0.01, 20.0, 0.01, "or_greater")
var movement_speed: float = 2.0

## If true, always move, no matter what
@export var loop: bool = false

## When loop is true: if true, reverses direction at path endpoints, if false, wraps around continuously from end to start
@export var ping_pong: bool = true

@export var return_when_unoccupied: bool = true:
	set(value):
		return_when_unoccupied = value

		if not value:
			_returning_to_start = false

			if is_instance_valid(_return_delay):
				_return_delay.stop()

@export_range(0.0, 60.0, 0.1, "or_greater") var return_delay: float = 6.0

@export_category("Orientation")
@export var rotate_at_destination: bool = true
@export var face_backward_when_returning: bool = true

## If true, uses +Z as model forward vector during orientation calculation; if false, uses -Z
@export var use_model_front: bool = true

@export_range(0.1, 10.0, 0.1, "or_greater") var rotation_speed: float = 3.0

var _players_on_platform: Array[Node3D] = []
var _returning_to_start: bool = false
var _loop_direction: float = 1.0
var _current_progress: float = 0.0
var _start_position: Vector3
var _path_start_transform: Transform3D
var _initialized: bool = false

@onready var _return_delay: Timer = %ReturnDelay


func _ready() -> void:
	assert(moving_object != null, "MovingObject missing in " + name)
	assert(path != null, "Path3D missing in " + name)
	assert(surface_detection != null, "SurfaceMovementDetection missing in " + name)
	assert(path.curve != null, "Path3D curve missing in " + name)
	assert(path.curve.get_baked_length() > 0.0, "Path3D curve has zero length in " + name)

	if moving_object is AnimatableBody3D:
		moving_object.sync_to_physics = false

	_current_progress = 0.0

	_return_delay.one_shot = true
	_return_delay.wait_time = return_delay

	surface_detection.body_entered.connect(_on_body_entered)
	surface_detection.body_exited.connect(_on_body_exited)
	_return_delay.timeout.connect(_on_return_delay_timeout)


func _physics_process(delta: float) -> void:
	if not _initialized:
		initialize_start_transforms()

	_prune_invalid_players()

	if loop:
		_return_delay.stop()
		_returning_to_start = false
		_move_back_and_forth(delta)
	elif not _players_on_platform.is_empty():
		_returning_to_start = false
		_return_delay.stop()
		_move_toward_destination(delta)
	elif _returning_to_start and return_when_unoccupied:
		_move_toward_start(delta)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group(Groups.CONTROLLED):
		return

	if body not in _players_on_platform:
		_players_on_platform.append(body)

	_returning_to_start = false
	_return_delay.stop()


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group(Groups.CONTROLLED):
		return

	_players_on_platform.erase(body)

	if _players_on_platform.is_empty():
		_start_return_delay()


func _start_return_delay() -> void:
	_returning_to_start = false

	if loop or not return_when_unoccupied:
		return

	if return_delay <= 0.0:
		_returning_to_start = true
		return

	_return_delay.wait_time = return_delay
	_return_delay.start()


func _on_return_delay_timeout() -> void:
	if (not loop and return_when_unoccupied and _players_on_platform.is_empty()):
		_returning_to_start = true


## Removes invalid or destroyed player references from tracking array
func _prune_invalid_players() -> void:
	for index: int in range(_players_on_platform.size() - 1, -1, -1):
		if not is_instance_valid(_players_on_platform[index]):
			_players_on_platform.remove_at(index)

	if (_players_on_platform.is_empty() and not loop and return_when_unoccupied and _return_delay.is_stopped() and not _returning_to_start):
		_start_return_delay()


func _move_toward_destination(delta: float) -> void:
	var path_length: float = path.curve.get_baked_length()
	_current_progress = minf(_current_progress + movement_speed * delta, path_length)
	_apply_path_position()

	if _current_progress < path_length and rotate_at_destination:
		_update_orientation(delta, 1.0)


func _move_toward_start(delta: float) -> void:
	_current_progress = maxf(_current_progress - movement_speed * delta, 0.0)
	_apply_path_position()

	var direction_sign: float = -1.0 if face_backward_when_returning else 1.0
	if _current_progress > 0.0 and rotate_at_destination:
		_update_orientation(delta, direction_sign)

	if _current_progress <= 0.0:
		_returning_to_start = false


func _move_back_and_forth(delta: float) -> void:
	var path_length: float = path.curve.get_baked_length()

	if not ping_pong:
		_current_progress = fmod(_current_progress + movement_speed * delta, path_length)
		_apply_path_position()
		_update_orientation(delta, 1.0)
		return

	var next_progress: float = (_current_progress + movement_speed * delta * _loop_direction)

	while next_progress < 0.0 or next_progress > path_length:
		if next_progress > path_length:
			next_progress = path_length - (next_progress - path_length)
			_loop_direction = -1.0
		elif next_progress < 0.0:
			next_progress = -next_progress
			_loop_direction = 1.0

	_current_progress = next_progress
	_apply_path_position()

	var direction_sign: float = -1.0 if (face_backward_when_returning and _loop_direction < 0.0) else 1.0
	_update_orientation(delta, direction_sign)


## Captures initial global transform of moving object and path
func initialize_start_transforms() -> void:
	_start_position = moving_object.global_position
	_path_start_transform = path.global_transform
	_initialized = true


## Updates global position of moving object relative to path curve offset
func _apply_path_position() -> void:
	var local_offset: Vector3 = path.curve.sample_baked(_current_progress) - path.curve.sample_baked(0.0)
	moving_object.global_position = _start_position + (_path_start_transform.basis * local_offset)


## Smoothly rotates moving object toward path tangent vector
func _update_orientation(delta: float, direction_sign: float) -> void:
	var path_length: float = path.curve.get_baked_length()
	var sample_distance: float = minf(0.05, path_length)

	var before_progress: float = maxf(_current_progress - sample_distance, 0.0)
	var after_progress: float = minf(_current_progress + sample_distance, path_length)

	var local_tangent: Vector3 = (path.curve.sample_baked(after_progress) - path.curve.sample_baked(before_progress))

	if local_tangent.is_zero_approx():
		return

	var world_forward: Vector3 = (_path_start_transform.basis * local_tangent).normalized() * direction_sign

	if world_forward.is_zero_approx():
		return

	var up_direction: Vector3 = Vector3.UP
	if absf(world_forward.dot(up_direction)) > 0.98:
		up_direction = Vector3.RIGHT

	var target_basis: Basis = Basis.looking_at(world_forward, up_direction, use_model_front)

	var current_scale: Vector3 = moving_object.global_transform.basis.get_scale()
	var current_rotation: Quaternion = moving_object.global_basis.get_rotation_quaternion()
	var target_rotation: Quaternion = target_basis.get_rotation_quaternion()
	var weight: float = 1.0 - exp(-rotation_speed * delta)
	var slerped_rotation: Quaternion = current_rotation.slerp(target_rotation, weight)

	moving_object.global_basis = Basis(slerped_rotation).scaled(current_scale)
