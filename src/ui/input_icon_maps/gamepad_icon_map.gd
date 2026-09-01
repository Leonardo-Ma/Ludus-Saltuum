## Maps InputEvent to icon texture
## Listens to InputManager.device_changed to swap the active map
## Emits map_changed on device change
extends Node

signal map_changed

var _gamepad_map: GamepadMap = XboxMap.new()


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	InputManager.device_changed.connect(_on_device_changed)


## Returns null for unmapped events, should fall back to text
func get_icon_for_event(event: InputEvent) -> Texture2D:
	if event is InputEventKey:
		return KeyboardIconMap.get_keyboard_icon(event.keycode)
	if event is InputEventMouseButton:
		return KeyboardIconMap.get_mouse_icon(event.button_index)
	if event is InputEventJoypadButton:
		return _gamepad_map.get_button_icon(event.button_index)
	if event is InputEventJoypadMotion:
		var dir: int = 1 if event.axis_value > 0.0 else -1
		return _gamepad_map.get_axis_icon(event.axis, dir)
	return null


func _on_device_changed(device: InputManager.Device) -> void:
	match device:
		InputManager.Device.GAMEPAD_PLAYSTATION:
			_gamepad_map = PlaystationMap.new()
		InputManager.Device.GAMEPAD_XBOX, InputManager.Device.GAMEPAD_GENERIC:
			_gamepad_map = XboxMap.new()
	map_changed.emit()
