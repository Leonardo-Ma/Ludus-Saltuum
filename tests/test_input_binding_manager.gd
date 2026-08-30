## Verifies InputBindingManager rebind, conflict detection, and reset defaults behavior
extends Node

const _TEST_ACTION: StringName = &"jump"
const _OTHER_ACTION: StringName = &"attack"

var _original_events: Array[InputEvent] = []
var _original_other_events: Array[InputEvent] = []


func _ready() -> void:
	if not OS.is_debug_build():
		queue_free()
		return

	_original_events = InputMap.action_get_events(_TEST_ACTION).duplicate()
	_original_other_events = InputMap.action_get_events(_OTHER_ACTION).duplicate()

	_test_rebind_replaces_keyboard_binding_only()
	_test_has_conflict_detects_shared_keyboard_binding()
	_test_reset_action_restores_default()

	_restore_original_bindings()
	print("InputBindingManager test completed.")
	self.queue_free()


func _test_rebind_replaces_keyboard_binding_only() -> void:
	var gamepad_before: Array[InputEvent] = InputMap.action_get_events(_TEST_ACTION).filter(
		func(e: InputEvent) -> bool: return e is InputEventJoypadButton
	)

	var new_key: InputEventKey = InputEventKey.new()
	new_key.physical_keycode = KEY_Y
	InputBindingManager.rebind(_TEST_ACTION, new_key)

	var keyboard_event: InputEventKey = InputBindingManager.get_keyboard_event(_TEST_ACTION)
	assert(keyboard_event != null, "InputBindingManager: rebind did not add keyboard event")
	assert(keyboard_event.physical_keycode == KEY_Y, "InputBindingManager: rebind did not apply new keycode")

	var gamepad_after: Array[InputEvent] = InputMap.action_get_events(_TEST_ACTION).filter(
		func(e: InputEvent) -> bool: return e is InputEventJoypadButton
	)
	assert(gamepad_after.size() == gamepad_before.size(), "InputBindingManager: rebind altered gamepad bindings")


func _test_has_conflict_detects_shared_keyboard_binding() -> void:
	var shared_key: InputEventKey = InputEventKey.new()
	shared_key.physical_keycode = KEY_Y
	InputBindingManager.rebind(_TEST_ACTION, shared_key)
	InputBindingManager.rebind(_OTHER_ACTION, shared_key)

	assert(InputBindingManager.has_conflict(_TEST_ACTION), "InputBindingManager: expected conflict on '%s'" % _TEST_ACTION)
	assert(InputBindingManager.has_conflict(_OTHER_ACTION), "InputBindingManager: conflict should be symmetric")


func _test_reset_action_restores_default() -> void:
	var different_key: InputEventKey = InputEventKey.new()
	different_key.physical_keycode = KEY_Z
	InputBindingManager.rebind(_TEST_ACTION, different_key)

	InputBindingManager.reset_action(_TEST_ACTION)

	var restored: InputEventKey = InputBindingManager.get_keyboard_event(_TEST_ACTION)
	var default_key: InputEventKey = _original_events.filter(func(e: InputEvent) -> bool: return e is InputEventKey).front() as InputEventKey
	assert(restored != null, "InputBindingManager: reset_action left no keyboard event")
	assert(restored.physical_keycode == default_key.physical_keycode, "InputBindingManager: reset_action did not restore default keycode")


func _restore_original_bindings() -> void:
	InputMap.action_erase_events(_TEST_ACTION)
	for event: InputEvent in _original_events:
		InputMap.action_add_event(_TEST_ACTION, event)

	InputMap.action_erase_events(_OTHER_ACTION)
	for event: InputEvent in _original_other_events:
		InputMap.action_add_event(_OTHER_ACTION, event)

	InputBindingManager._save()
	InputBindingManager.binding_changed.emit(_OTHER_ACTION)
