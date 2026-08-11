extends Area3D

const THUNDER_SOUNDS: Array[AudioStream] = [
	preload("uid://dsk5roghsbtm3"),  # thunder_1_near
	preload("uid://cws8ps85wa78n"),  # thunder_5_near
]

const WORLD_ENVIRONMENT_SETTINGS: Environment = preload("uid://dsshmu8vrps28")
const CAVE_ENVIRONMENT: Environment = preload("uid://cukvscwyyjgeh")

@export var cave_environment: Environment
@export var darkness_intensity: float = 0.2


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group(Groups.PLAYERS):
		_apply_darkness(body)


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group(Groups.PLAYERS):
		_remove_darkness(body)


func _apply_darkness(player: PlayerEntity) -> void:
	SoundManager.play_sound(THUNDER_SOUNDS.pick_random(), SoundManager.SoundCategory.SFX, player.global_position + Vector3(0, 5, 0))
	var player_camera: Camera3D = player.camera_controller._camera

	var dark_env: Environment = cave_environment.duplicate()
	dark_env.ambient_light_color = Color(0.05, 0.05, 0.1) * darkness_intensity
	player_camera.environment = dark_env


func _remove_darkness(player: Node3D) -> void:
	var player_camera: Camera3D = player.camera_controller._camera
	player_camera.environment = WORLD_ENVIRONMENT_SETTINGS
