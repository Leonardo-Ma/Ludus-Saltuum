## Verifies InputBindingManager rebind, conflict detection, reset defaults, signal, and cleanup

extends Node

const _TEST_ACTION: StringName = &"jump"
const _OTHER_ACTION: StringName = &"attack"

var _original_events: Array[InputEvent] = []
var _original_other_events: Array[InputEvent] = []

var _config_backup: PackedByteArray = PackedByteArray()
var _had_config_file: bool = false

var _binding_changed_actions: Array[StringName] = []


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	# Snapshot the original InputMap state before any test modifies it.
	assert(InputMap.has_action(_TEST_ACTION), "InputBindingManager test: missing test action '%s'" % _TEST_ACTION)

	assert(InputMap.has_action(_OTHER_ACTION), "InputBindingManager test: missing test action '%s'" % _OTHER_ACTION)

	_original_events = InputMap.action_get_events(_TEST_ACTION).duplicate()
	_original_other_events = InputMap.action_get_events(_OTHER_ACTION).duplicate()

	# Snapshot the persisted configuration so the tests cannot permanently
	# modify the user's saved key bindings.
	_had_config_file = FileAccess.file_exists(InputBindingManager._SAVE_PATH)

	if _had_config_file:
		_config_backup = FileAccess.get_file_as_bytes(InputBindingManager._SAVE_PATH)

	# Listen to the public signal so the test verifies the UI notification
	# contract used by the key-binding UI.
	InputBindingManager.binding_changed.connect(_on_binding_changed)

	_test_rebind_replaces_keyboard_binding_only()
	_test_has_conflict_detects_shared_keyboard_binding()
	_test_reset_action_restores_default()
	_test_binding_changed_signal()

	_restore_original_bindings()

	_restore_config_file()

	if InputBindingManager.binding_changed.is_connected(_on_binding_changed):
		InputBindingManager.binding_changed.disconnect(_on_binding_changed)

	print("InputBindingManager test completed.")
	queue_free()


func _on_binding_changed(action: StringName) -> void:
	_binding_changed_actions.append(action)


func _restore_config_file() -> void:
	if _had_config_file:
		var file: FileAccess = FileAccess.open(InputBindingManager._SAVE_PATH, FileAccess.WRITE)

		assert(file != null, "InputBindingManager test: could not restore saved config")

		if file != null:
			file.store_buffer(_config_backup)

	elif FileAccess.file_exists(InputBindingManager._SAVE_PATH):
		DirAccess.remove_absolute(InputBindingManager._SAVE_PATH)


func _test_rebind_replaces_keyboard_binding_only() -> void:
	var gamepad_before: Array[InputEvent] = (InputMap.action_get_events(_TEST_ACTION).filter(
			func(event: InputEvent) -> bool:
				return event is InputEventJoypadButton,
		))

	var new_key: InputEventKey = InputEventKey.new()
	new_key.physical_keycode = KEY_Y

	_binding_changed_actions.clear()

	InputBindingManager.rebind(_TEST_ACTION, new_key)

	var keyboard_event: InputEventKey = (InputBindingManager.get_keyboard_event(_TEST_ACTION))

	var gamepad_after: Array[InputEvent] = (InputMap.action_get_events(_TEST_ACTION).filter(
			func(event: InputEvent) -> bool:
				return event is InputEventJoypadButton,
		))

	assert(keyboard_event != null, "InputBindingManager: rebind did not add keyboard event")

	if keyboard_event != null:
		assert(keyboard_event.physical_keycode == KEY_Y, "InputBindingManager: rebind did not apply new keycode")

	assert(gamepad_after.size() == gamepad_before.size(), "InputBindingManager: rebind altered gamepad bindings")

	assert(_binding_changed_actions.has(_TEST_ACTION), "InputBindingManager: rebind did not emit binding_changed for '%s'" % _TEST_ACTION)

	_restore_action(_TEST_ACTION)


func _restore_action(action: StringName) -> void:
	InputMap.action_erase_events(action)

	var source: Array[InputEvent] = (_original_events
		if action == _TEST_ACTION
		else _original_other_events)

	for event: InputEvent in source:
		InputMap.action_add_event(action, event)


func _test_has_conflict_detects_shared_keyboard_binding() -> void:
	var shared_key: InputEventKey = InputEventKey.new()
	shared_key.physical_keycode = KEY_Y

	InputBindingManager.rebind(_TEST_ACTION, shared_key)

	InputBindingManager.rebind(_OTHER_ACTION, shared_key)

	assert(InputBindingManager.has_conflict(_TEST_ACTION), "InputBindingManager: expected conflict on '%s'" % _TEST_ACTION)

	assert(InputBindingManager.has_conflict(_OTHER_ACTION), "InputBindingManager: conflict should be symmetric")

	_restore_action(_TEST_ACTION)
	_restore_action(_OTHER_ACTION)


func _test_reset_action_restores_default() -> void:
	var default_key: InputEventKey = null

	for event: InputEvent in _original_events:
		if event is InputEventKey:
			default_key = event
			break

	assert(default_key != null, "InputBindingManager test: '%s' has no default keyboard binding" % _TEST_ACTION)

	if default_key == null:
		return

	var different_key: InputEventKey = InputEventKey.new()
	different_key.physical_keycode = KEY_Z

	_binding_changed_actions.clear()

	InputBindingManager.rebind(_TEST_ACTION, different_key)

	assert(_binding_changed_actions.has(_TEST_ACTION), "InputBindingManager: rebind did not emit binding_changed before reset")

	_binding_changed_actions.clear()

	InputBindingManager.reset_action(_TEST_ACTION)

	var restored: InputEventKey = (InputBindingManager.get_keyboard_event(_TEST_ACTION))

	assert(restored != null, "InputBindingManager: reset_action left no keyboard event")

	if restored != null:
		assert(restored.physical_keycode == default_key.physical_keycode, "InputBindingManager: reset_action did not restore default keycode")

	assert(_binding_changed_actions.has(_TEST_ACTION), "InputBindingManager: reset_action did not emit binding_changed for '%s'" % _TEST_ACTION)

	_restore_action(_TEST_ACTION)


func _test_binding_changed_signal() -> void:
	_binding_changed_actions.clear()

	var new_key: InputEventKey = InputEventKey.new()
	new_key.physical_keycode = KEY_Y

	InputBindingManager.rebind(_TEST_ACTION, new_key)

	assert(_binding_changed_actions.size() == 1, "InputBindingManager: rebind should emit exactly one binding_changed signal")

	if _binding_changed_actions.size() == 1:
		assert(_binding_changed_actions[0] == _TEST_ACTION, "InputBindingManager: binding_changed emitted for wrong action")

	_binding_changed_actions.clear()

	InputBindingManager.reset_action(_TEST_ACTION)

	assert(_binding_changed_actions.size() == 1, "InputBindingManager: reset_action should emit exactly one binding_changed signal")

	if _binding_changed_actions.size() == 1:
		assert(_binding_changed_actions[0] == _TEST_ACTION, "InputBindingManager: reset_action emitted binding_changed for wrong action")

	_restore_action(_TEST_ACTION)


func _restore_original_bindings() -> void:
	_restore_action(_TEST_ACTION)
	_restore_action(_OTHER_ACTION)

	# _restore_action() directly changes InputMap, so it never emits signals to update UI
	InputBindingManager.binding_changed.emit(_TEST_ACTION)

	InputBindingManager.binding_changed.emit(_OTHER_ACTION)
