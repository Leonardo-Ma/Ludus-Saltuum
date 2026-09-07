## Displays input prompt icon for given action, reacting to device switches and rebinds
class_name PromptIcon
extends TextureRect

@export_category("Prompt")
## Input action this icon represents (&"jump", &"dash", &"ui_accept" ...)
@export var action: StringName
## When true, shows joystick axis events; when false, shows dpad button events (gamepad only)
@export var prefer_axis: bool = false
## Optional overlay drawn on top (e.g. rotation arrow on a joystick icon)
@export var flavor_overlay: TextureRect
## Optional keyboard override texture
@export var keyb_texture_override: Texture2D

var _gamepad_icon_map: GamepadIconMap = GamepadIconMap.new()


func _ready() -> void:
	assert(action != &"", "Action not assigned in " + name)
	assert(InputMap.has_action(action), "Wrong action in " + name)
	_gamepad_icon_map.map_changed.connect(_refresh)
	InputManager.device_changed.connect(_on_device_changed)
	InputBindingManager.binding_changed.connect(_on_binding_changed)
	_refresh()


func _on_binding_changed(changed_action: StringName) -> void:
	if changed_action == action:
		_refresh()


func _refresh() -> void:
	texture = _resolve()
	visible = texture != null
	if flavor_overlay != null:
		flavor_overlay.visible = visible


func _resolve() -> Texture2D:
	var events: Array[InputEvent] = InputMap.action_get_events(action)

	if InputManager.is_gamepad_active():
		return _resolve_gamepad(events)

	return _resolve_keyboard(events)


func _resolve_gamepad(events: Array[InputEvent]) -> Texture2D:
	# Two passes: preferred type first, then fallback
	for event: InputEvent in events:
		if prefer_axis and event is InputEventJoypadMotion:
			var icon: Texture2D = _gamepad_icon_map.get_icon_for_event(event)
			if icon != null:
				return icon
		elif not prefer_axis and event is InputEventJoypadButton:
			var icon: Texture2D = _gamepad_icon_map.get_icon_for_event(event)
			if icon != null:
				return icon

	for event: InputEvent in events:
		if prefer_axis and event is InputEventJoypadButton:
			var icon: Texture2D = _gamepad_icon_map.get_icon_for_event(event)
			if icon != null:
				return icon
		elif not prefer_axis and event is InputEventJoypadMotion:
			var icon: Texture2D = _gamepad_icon_map.get_icon_for_event(event)
			if icon != null:
				return icon

	return null


func _resolve_keyboard(events: Array[InputEvent]) -> Texture2D:
	if keyb_texture_override != null:
		return keyb_texture_override
	for event: InputEvent in events:
		if event is InputEventKey:
			var key: Key = event.physical_keycode if event.physical_keycode != KEY_NONE else event.keycode
			var icon: Texture2D = KeyboardIconMap.get_keyboard_icon(key)
			if icon != null:
				return icon

	for event: InputEvent in events:
		if event is InputEventMouseButton:
			var icon: Texture2D = KeyboardIconMap.get_mouse_icon(event.button_index)
			if icon != null:
				return icon

	return KeyboardIconMap.get_mouse_motion_icon(action)


func _on_device_changed(device: InputManager.Device) -> void:
	_gamepad_icon_map.set_device(device)
