## Icon row action label | clickable keyboard icon | read-only gamepad icon | per-row reset
class_name RebindingRow
extends PanelContainer

signal rebind_requested(action: StringName)
signal reset_requested(action: StringName)

const _ACTION_ICON_SCENE: PackedScene = preload("uid://bnp3oyipkidl1")

var _action: StringName = &""
var _listening: bool = false
var _has_conflict: bool = false
var _pulse_tween: Tween

@onready var _actions_icons_container: HBoxContainer = %ActionsIconsContainer
@onready var _key_button: Button = %KeyButton
@onready var _gamepad_icons: HBoxContainer = %GamepadIconsContainer
@onready var _reset_button: Button = %ResetButton

var _gamepad_icon_map: GamepadIconMap = GamepadIconMap.new()


func setup(action: StringName) -> void:
	for action_icon: CompressedTexture2D in InputBindingManager.REBINDABLE_ACTIONS_ICONS[action]:
		var new_icon_scene: Node = _ACTION_ICON_SCENE.instantiate()
		new_icon_scene.texture = action_icon

		_actions_icons_container.add_child(new_icon_scene)

	_action = action
	_key_button.pressed.connect(
		func() -> void:
			rebind_requested.emit(_action),
	)
	_reset_button.pressed.connect(
		func() -> void:
			reset_requested.emit(_action),
	)
	_gamepad_icon_map.map_changed.connect(_refresh_gamepad)
	InputBindingManager.binding_changed.connect(_on_binding_changed)
	InputManager.device_changed.connect(_on_device_changed)
	_refresh_icon()
	_refresh_gamepad()
	_update_gamepad_visibility()


func set_listening(active: bool) -> void:
	_listening = active
	_key_button.disabled = active
	_reset_button.disabled = active
	if _pulse_tween and _pulse_tween.is_valid():
		_pulse_tween.kill()
	if active:
		_pulse_tween = create_tween().set_loops()
		_pulse_tween.tween_property(_key_button, "modulate", Color(0.4, 0.8, 1.0, 1.0), 0.5)
		_pulse_tween.tween_property(_key_button, "modulate", Color.WHITE, 0.5)
	else:
		_refresh_icon()
		_update_conflict_color()


## Called by KeyBindingsPanel after any rebind
func set_conflict(has_conflict: bool) -> void:
	_has_conflict = has_conflict
	if not _listening:
		_update_conflict_color()


func _update_conflict_color() -> void:
	_key_button.modulate = Color.RED if _has_conflict else Color.WHITE


func _on_binding_changed(action: StringName) -> void:
	if action == _action:
		_refresh_icon()


func _on_device_changed(_device: InputManager.Device) -> void:
	_update_gamepad_visibility()
	_refresh_gamepad()


func _update_gamepad_visibility() -> void:
	_gamepad_icons.visible = InputManager.is_gamepad_active()


func _refresh_icon() -> void:
	var keyboard_event: InputEventKey = InputBindingManager.get_keyboard_event(_action)

	if keyboard_event != null:
		var key: Key = keyboard_event.physical_keycode if keyboard_event.physical_keycode != KEY_NONE else keyboard_event.keycode
		_key_button.icon = KeyboardIconMap.get_keyboard_icon(key)
		return

	var mouse_event: InputEventMouseButton = InputBindingManager.get_mouse_event(_action)
	_key_button.icon = KeyboardIconMap.get_mouse_icon(mouse_event.button_index) if mouse_event != null else null


func _refresh_gamepad() -> void:
	var gamepad_events: Array[InputEvent] = []

	for event: InputEvent in InputMap.action_get_events(_action):
		if _gamepad_icon_map.get_icon_for_event(event) != null:
			gamepad_events.append(event)

	var icons: Array[TextureRect] = []
	for child: Node in _gamepad_icons.get_children():
		var icon: TextureRect = child as TextureRect
		assert(icon != null, "Non-TextureRect child in " + _gamepad_icons.name)
		icons.append(icon)

	for index: int in icons.size():
		var icon: TextureRect = icons[index]

		if index >= gamepad_events.size() or not InputManager.is_gamepad_active():
			icon.visible = false
			icon.texture = null
			continue

		icon.visible = true
		icon.texture = _gamepad_icon_map.get_icon_for_event(gamepad_events[index])
