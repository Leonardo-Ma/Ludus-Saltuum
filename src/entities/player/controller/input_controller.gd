@icon("uid://bcle4jlufep4u") # joystick.png
## Player related inputs. Specific UI input is handled in respective feature
class_name InputController extends Node

signal attack_pressed
signal return_to_checkpoint_requested
signal return_hold_started(duration: float)
signal return_hold_cancelled

const RETURN_HOLD_DURATION: float = 1.5

var _respawn_timer: Timer

@onready var camera_controller: Node3D = %CamRoot


func _ready() -> void:
	camera_controller.capture_mouse_requested.connect(_on_capture_mouse_requested)
	camera_controller.release_mouse_requested.connect(_on_release_mouse_requested)

	_respawn_timer = Timer.new()
	_respawn_timer.one_shot = true
	_respawn_timer.wait_time = RETURN_HOLD_DURATION
	_respawn_timer.timeout.connect(
		func() -> void:
			return_to_checkpoint_requested.emit(),
	)
	add_child(_respawn_timer)


func _on_capture_mouse_requested() -> void:
	if not _is_ui_interacting() or PauseManager.is_paused():
		MouseModeManager.request_mode(&"gameplay", Input.MOUSE_MODE_CAPTURED)
		print_debug("Mouse captured by " + name)
	print_debug(name + " failed to capture mouse")


func _on_release_mouse_requested() -> void:
	MouseModeManager.release(&"gameplay")
	print_debug("Mouse released by " + name)


func _is_ui_interacting() -> bool:
	var viewport: Viewport = get_viewport()
	var focus_owner: Control = viewport.gui_get_focus_owner()
	if focus_owner:
		return true
	return false


# This may be better as _unhandled_input but camera controller keeps overriding
func _input(event: InputEvent) -> void:
	if _is_ui_interacting():
		return
	if event.is_action_pressed("attack"):
		attack_pressed.emit()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("return_to_checkpoint"):
		if CheckpointManager.has_active_checkpoint():
			_respawn_timer.start()
			return_hold_started.emit(RETURN_HOLD_DURATION)
		get_viewport().set_input_as_handled()
	elif event.is_action_released("return_to_checkpoint"):
		if not _respawn_timer.is_stopped():
			return_hold_cancelled.emit()
		_respawn_timer.stop()
