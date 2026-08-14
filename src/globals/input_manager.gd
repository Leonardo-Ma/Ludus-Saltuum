## Detects active input device and switches between keyboard/mouse and gamepad brands
## Defaults to keyboard/mouse and only switches on first gamepad input event
extends Node

signal device_changed(device: Device)

enum Device {
	KEYBOARD_MOUSE,
	GAMEPAD_XBOX,
	GAMEPAD_PLAYSTATION,
	GAMEPAD_GENERIC,
}

const AXIS_DEAD_ZONE: float = 0.4
const DEVICE_SWITCH_DELAY: float = 0.2

var active_device: Device = Device.KEYBOARD_MOUSE
var _pending_device: Device = Device.KEYBOARD_MOUSE
var _switch_timer: SceneTreeTimer


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	Input.joy_connection_changed.connect(_on_joy_connection_changed)
	if Input.get_connected_joypads().size() > 0:
		Input.mouse_mode = Input.MOUSE_MODE_HIDDEN  # Hidden allows to escape the game window
		active_device = Input.get_connected_joypads().get_typed_builtin() as Device


func _on_joy_connection_changed(device_id: int, connected: bool) -> void:
	if connected:
		print_debug("Gamepad: ", Input.get_joy_name(device_id), " connected!")
		return

	var still_connected: Array[int] = Input.get_connected_joypads()
	if still_connected.size() == 0 and active_device != Device.KEYBOARD_MOUSE:
		active_device = Device.KEYBOARD_MOUSE
		_apply_mouse_mode()
		device_changed.emit(active_device)
		print_debug("Last gamepad disconnected, switching to KEYBOARD_MOUSE")

	# Only pause mid-game — not during menus
	if ApplicationStateManager.is_gameplay_active():
		push_warning("Game paused due to gamepad disconnect")
		ApplicationStateManager.request_pause()


func _input(event: InputEvent) -> void:
	var new_device: Device = active_device

	if event is InputEventJoypadButton:
		new_device = _get_gamepad_device_type(event.device)
	elif event is InputEventJoypadMotion:
		if absf(event.axis_value) >= AXIS_DEAD_ZONE:
			new_device = _get_gamepad_device_type(event.device)
	elif event is InputEventKey or event is InputEventMouseButton or event is InputEventMouseMotion:
		new_device = Device.KEYBOARD_MOUSE

	if new_device == active_device:
		return

	_pending_device = new_device
	if _switch_timer != null:
		return
	_switch_timer = get_tree().create_timer(DEVICE_SWITCH_DELAY)
	_switch_timer.timeout.connect(_apply_device_switch)


func _apply_device_switch() -> void:
	_switch_timer = null
	active_device = _pending_device
	_apply_mouse_mode()
	device_changed.emit(active_device)
	print_debug("Device input changed to ", Device.keys()[active_device])


func is_gamepad_active() -> bool:
	return active_device != Device.KEYBOARD_MOUSE


func _get_gamepad_device_type(device_id: int) -> Device:
	var joy_name: String = Input.get_joy_name(device_id).to_lower()
	if "xbox" in joy_name or "xinput" in joy_name or "x360" in joy_name:
		return Device.GAMEPAD_XBOX
	if "dualsense" in joy_name or "dualshock" in joy_name or "ps3" in joy_name or "ps4" in joy_name or "ps5" in joy_name or "playstation" in joy_name:
		return Device.GAMEPAD_PLAYSTATION
	return Device.GAMEPAD_GENERIC


func _apply_mouse_mode() -> void:
	# TODO Double check this
	# Only manage visibility, captured mode is owned by UIManager/game state
	print(Input.mouse_mode)
	if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		return

	if active_device != Device.KEYBOARD_MOUSE:
		if Input.mouse_mode == Input.MOUSE_MODE_VISIBLE:
			Input.mouse_mode = Input.MOUSE_MODE_HIDDEN
	else:
		if Input.mouse_mode == Input.MOUSE_MODE_HIDDEN:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
