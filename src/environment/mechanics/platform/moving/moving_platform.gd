## NOTE loop = false and closed = false
## Moves while any player on it and returns to start if nobody on
class_name MovingPlatform
extends Node3D

const DELAY_UPON_LEAVING: float = 6.0
const MOVEMENT_SPEED: float = 2.0

var players_on_platform: Array[Node3D] = []
var returning_to_start: bool = false

@onready var surface_movement_detection: Area3D = %SurfaceMovementDetection
@onready var path_follow_3d: PathFollow3D = %PathFollow3D
@onready var return_delay: Timer = %ReturnDelay


func _ready() -> void:
	return_delay.wait_time = DELAY_UPON_LEAVING

	surface_movement_detection.body_entered.connect(_on_body_entered)
	surface_movement_detection.body_exited.connect(_on_body_exited)
	return_delay.timeout.connect(_on_return_delay_timeout)


func _physics_process(delta: float) -> void:
	if not players_on_platform.is_empty():
		returning_to_start = false
		return_delay.stop()
		_move_toward_destination(delta)
	elif returning_to_start:
		_move_toward_start(delta)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(Groups.CONTROLLED) and body not in players_on_platform:
		players_on_platform.append(body)
		returning_to_start = false
		return_delay.stop()


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group(Groups.CONTROLLED):
		players_on_platform.erase(body)

		if players_on_platform.is_empty():
			returning_to_start = false
			return_delay.start()


func _on_return_delay_timeout() -> void:
	if players_on_platform.is_empty():
		returning_to_start = true


func _move_toward_destination(delta: float) -> void:
	if path_follow_3d.progress_ratio >= 1.0:
		path_follow_3d.progress_ratio = 1.0
		return

	path_follow_3d.progress += MOVEMENT_SPEED * delta


func _move_toward_start(delta: float) -> void:
	if path_follow_3d.progress_ratio <= 0.0:
		path_follow_3d.progress_ratio = 0.0
		return

	path_follow_3d.progress -= MOVEMENT_SPEED * delta
