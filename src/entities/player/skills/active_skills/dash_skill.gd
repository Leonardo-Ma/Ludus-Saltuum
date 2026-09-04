## Unified dash skill for both ground and air movement
class_name PlayerDashSkill
extends BaseSkill

const DASH_SOUND: AudioStream = preload("uid://vo301kuo1mby") # whoosh_2.wav
const DOUBLE_TAP_THRESHOLD: float = 0.3

var dash_velocity_multiplier: float = 5.0
var dash_duration: float = 0.4
var dash_cooldown: float = 1.0

var _dash_timer: float = 0.0
var _dash_cooldown: float = 0.0
var _dash_direction: Vector3 = Vector3.ZERO
var _last_pressed_action: String = ""
var _last_pressed_time: float = 0.0


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

	var current_time: float = Time.get_ticks_msec() / 1000.0
	var actions: Array[String] = ["move_forward", "move_backward", "move_left", "move_right"]

	for action: String in actions:
		if Input.is_action_just_pressed(action):
			if _last_pressed_action == action and (current_time - _last_pressed_time) < DOUBLE_TAP_THRESHOLD:
				_start_dash(action)
				_last_pressed_action = ""
			else:
				_last_pressed_action = action
				_last_pressed_time = current_time
			break


func _start_dash(action_dir: String) -> void:
	skills_controller.is_sliding = true
	_dash_timer = dash_duration

	SoundManager.play_sound(DASH_SOUND, SoundManager.SoundCategory.SFX)
	skills_controller.spawn_ghost_trail(0.4)

	_dash_cooldown = dash_cooldown
	cooldown_started.emit(_dash_cooldown)

	var input_vec: Vector2 = Vector2.ZERO
	match action_dir:
		"move_forward":
			input_vec = Vector2(0, -1)
		"move_backward":
			input_vec = Vector2(0, 1)
		"move_left":
			input_vec = Vector2(-1, 0)
		"move_right":
			input_vec = Vector2(1, 0)
		_:
			assert(false, "Dash direction didn't match options")

	var camera_basis: Basis = skills_controller.camera.global_transform.basis
	var forward: Vector3 = camera_basis * Vector3(input_vec.x, 0, input_vec.y)
	forward.y = 0.0
	forward = forward.normalized()
	_dash_direction = forward * skills_controller.entity.movement.speed * dash_velocity_multiplier
	skills_controller.movement_controller.disable_movement(dash_duration)
