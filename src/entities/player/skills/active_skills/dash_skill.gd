@icon("uid://d4g1stey2kdtm") # character_move.pngd
## Unified dash skill for both ground and air movement
class_name PlayerDashSkill
extends BaseSkill

const DASH_SOUND: AudioStream = preload("uid://vo301kuo1mby") # whoosh_2.wav

var dash_velocity_multiplier: float = 5.0
var dash_duration: float = 0.4
var dash_cooldown: float = 1.0

var _dash_timer: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO


func get_hud_mode() -> HUDMode:
	return HUDMode.COOLDOWN


func _physics_process(delta: float) -> void:
	if _dash_timer > 0.0:
		_dash_timer -= delta
		if _dash_timer <= 0.0:
			skills_controller.is_sliding = false

	if _dash_cooldown > 0.0:
		_dash_cooldown -= delta
		if _dash_cooldown <= 0.0:
			cooldown_finished.emit()

	if skills_controller.is_sliding and _dash_timer > 0.0:
		var body: CharacterBody3D = skills_controller.entity
		body.velocity.x = _dash_direction.x
		body.velocity.z = _dash_direction.z
		body.velocity.y = 0.0 # Ignore gravity during dash


func process_input() -> void:
	if skills_controller.is_sliding or not skills_controller.movement_controller.movement_enabled or _dash_cooldown > 0.0:
		return

	if Input.is_action_just_pressed("dash"):
		_start_dash()


func _start_dash() -> void:
	skills_controller.is_sliding = true
	_dash_timer = dash_duration

	SoundManager.play_sound(DASH_SOUND, SoundManager.SoundCategory.SFX)
	skills_controller.spawn_ghost_trail(0.4)

	_dash_cooldown = dash_cooldown
	cooldown_started.emit(_dash_cooldown)

	var input_vec: Vector2 = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	if input_vec == Vector2.ZERO:
		input_vec = Vector2(0, -1)

	var camera_basis: Basis = skills_controller.camera.global_transform.basis
	var forward: Vector3 = camera_basis * Vector3(input_vec.x, 0, input_vec.y)
	forward.y = 0.0
	forward = forward.normalized()
	_dash_direction = forward * skills_controller.entity.movement.speed * dash_velocity_multiplier
	skills_controller.movement_controller.disable_movement(dash_duration)
