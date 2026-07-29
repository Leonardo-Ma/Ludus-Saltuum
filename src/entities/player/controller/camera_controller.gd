# https://www.youtube.com/watch?v=EP5AYllgHy8 Godot 4.0 Third Person Controller Tutorial ( 2023 )
# https://www.youtube.com/watch?v=JlgZtOFMdfc&t=611s GDQuest - 3D TUTORIAL: Make a Smooth 3D Character Controller in Godot 4
class_name CameraController
extends Node3D

signal capture_mouse_requested
signal release_mouse_requested

@export var gamepad_look_invert_y: bool = false

var horizontal_sensibility: float = 0.2
var vertical_sensibility: float = 0.2

var gamepad_look_sensitivity: float = 120.0

var mouse_look_enabled: bool = false

@onready var cam_root: Node3D = $"."
@onready var player: CharacterBody3D = $".."
@onready var _spring_arm: SpringArm3D = $SpringArm3D
@onready var _camera: Camera3D = $SpringArm3D/Camera3D


func _ready() -> void:
	refresh_sensitivity_from_settings()
	refresh_camera_from_settings()
	SettingsManager.settings_reset.connect(refresh_sensitivity_from_settings)
	SettingsManager.settings_reset.connect(refresh_camera_from_settings)
	SettingsManager.camera_settings_changed.connect(refresh_camera_from_settings)


## Call after settings changes
func refresh_sensitivity_from_settings() -> void:
	horizontal_sensibility = SettingsManager.mouse_sensitivity_horizontal
	vertical_sensibility = SettingsManager.mouse_sensitivity_vertical
	gamepad_look_sensitivity = SettingsManager.gamepad_sensitivity


## Call after camera settings changes (FOV, spring arm distance, gamepad invert)
func refresh_camera_from_settings() -> void:
	_camera.fov = SettingsManager.camera_fov
	_spring_arm.spring_length = SettingsManager.camera_distance
	gamepad_look_invert_y = SettingsManager.gamepad_invert_y


func set_active(active: bool) -> void:
	_camera.current = active


#region Keyboard and mouse
# Handle camera x and y movement
# TODO Confirm if this should be on _input instead of _unhandled_input or _physics_process
func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		release_mouse_requested.emit()
		if Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

	if event.is_action_pressed("attack"):  # Left mouse click
		if not GameStateManager.is_in_menu():
			capture_mouse_requested.emit()
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

	var player_is_using_mouse: bool = event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED
	if player_is_using_mouse:
		# TODO Smooth the camera rotation (Maybe lerp()?)
		# Handles horizontal camera rotation
		player.rotate_y(deg_to_rad(-event.relative.x * horizontal_sensibility))
		# Handles vertical camera rotation
		cam_root.rotate_x(deg_to_rad(-event.relative.y * vertical_sensibility))
		# Limit vertical camera rotation
		rotation.x = clamp(rotation.x, deg_to_rad(-90), deg_to_rad(45))


#endregion


#region Gamepad (right stick)
func _process(delta: float) -> void:
	var look_input: Vector2 = Input.get_vector("look_left", "look_right", "look_down", "look_up")
	if look_input.length() > 0.1:  # small deadzone
		var h: float = look_input.x * gamepad_look_sensitivity * delta
		var v: float = look_input.y * gamepad_look_sensitivity * delta * (1.0 if gamepad_look_invert_y else -1.0)
		player.rotate_y(deg_to_rad(-h))
		cam_root.rotate_x(deg_to_rad(-v))
		# Limit vertical camera rotation
		rotation.x = clamp(rotation.x, deg_to_rad(-90), deg_to_rad(45))
#endregion
