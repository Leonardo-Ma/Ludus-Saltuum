## Only moves if a player is on top of it, after player leaves waits 4 seconds and returns to initial position
class_name MovingPlatform
extends Node3D

const DELAY_UPON_ARRIVING: float = 4.0

var player_in_platform: bool

@onready var wait_delay_before_returning: float = DELAY_UPON_ARRIVING

@onready var surface_movement_detection: Area3D = %SurfaceMovementDetection
@onready var path_follow_3d: PathFollow3D = %PathFollow3D


func _ready() -> void:
	surface_movement_detection.body_entered.connect(_on_body_entered)
	surface_movement_detection.body_exited.connect(_on_body_exited)


func _physics_process(delta: float) -> void:
	if player_in_platform:
		_move_platform_forward(delta)
	# TODO check this number
	elif path_follow_3d.progress_ratio > 0.001:
		wait_delay_before_returning -= delta
		if wait_delay_before_returning <= 0:
			_move_platform_forward(delta)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(Groups.PLAYERS):
		player_in_platform = true


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group(Groups.PLAYERS):
		player_in_platform = false
		wait_delay_before_returning = DELAY_UPON_ARRIVING


func _move_platform_forward(delta: float) -> void:
	path_follow_3d.progress += 2 * delta
