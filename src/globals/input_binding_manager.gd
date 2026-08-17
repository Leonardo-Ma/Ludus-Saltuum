## Manages key rebinding and persists bindings
extends Node

signal binding_changed(action: StringName)

const _SAVE_PATH: String = "user://key_bindings.cfg"
const _SECTION: String = "bindings"

## In display order
const REBINDABLE_ACTIONS: Array[StringName] = [
	&"move_left",
	&"move_right",
	&"move_forward",
	&"move_backward",
	&"jump",
	&"attack",
	#&"interact",
	#&"ui_accept",
	#&"ui_cancel",
	&"return_to_checkpoint",
	#&"open_shop",
	&"look_left",
	&"look_right",
	&"look_up",
	&"look_down",
]

const REBINDABLE_ACTIONS_ICONS: Dictionary[StringName, Array] = {
	&"move_left": [Icons.CHARACTER_MOVEMENT, Icons.ARROW_LEFT],
	&"move_right": [Icons.CHARACTER_MOVEMENT, Icons.ARROW_RIGHT],
	&"move_forward": [Icons.CHARACTER_MOVEMENT, Icons.ARROW_UP],
	&"move_backward": [Icons.CHARACTER_MOVEMENT, Icons.ARROW_DOWN],
	&"jump": [Icons.JUMP],
	&"attack": [Icons.ATTACK],
	#&"interact": [ , ],
	#&"ui_accept": [ , ],
	#&"ui_cancel": [ , ],
	&"return_to_checkpoint": [Icons.UNDO, Icons.FLAG],
	#&"open_shop": [ , ],
	&"look_left": [Icons.EYE, Icons.ARROW_LEFT],
	&"look_right": [Icons.EYE, Icons.ARROW_RIGHT],
	&"look_up": [Icons.EYE, Icons.ARROW_UP],
	&"look_down": [Icons.EYE, Icons.ARROW_DOWN],
}

## Before user overrides
var _defaults: Dictionary = {}


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	assert(REBINDABLE_ACTIONS.size() == REBINDABLE_ACTIONS_ICONS.size(), "Each action should have an icon.")
	_cache_defaults()
	_load()


## Replaces the first keyboard binding for [param action] with [param event]
## Sets red if has conflicts. See [method has_conflict]
## Gamepad bindings are preserved
func rebind(action: StringName, event: InputEvent) -> void:
	assert(InputMap.has_action(action), "InputBindingManager: unknown action " + action)
	assert(event is InputEventKey, "InputBindingManager: rebind only supports InputEventKey in " + name)
	_remove_keyboard_bindings(action)
	InputMap.action_add_event(action, event)
	_save()
	binding_changed.emit(action)


## True if [param action]'s keyboard binding is shared with another rebindable action
func has_conflict(action: StringName) -> bool:
	var event: InputEventKey = get_keyboard_event(action)
	if event == null:
		return false
	for other_action: StringName in REBINDABLE_ACTIONS:
		if other_action == action:
			continue
		var other_event: InputEventKey = get_keyboard_event(other_action)
		if other_event != null and _keys_match(event, other_event):
			return true
	return false


# NOTE UNUSED
func _clear_conflicting_bindings(action: StringName, new_event: InputEventKey) -> void:
	for other_action: StringName in REBINDABLE_ACTIONS:
		if other_action == action:
			continue
		for other_event: InputEvent in InputMap.action_get_events(other_action).duplicate():
			if other_event is InputEventKey and _keys_match(other_event, new_event):
				InputMap.action_erase_event(other_action, other_event)
				binding_changed.emit(other_action)


func _keys_match(a: InputEventKey, b: InputEventKey) -> bool:
	var a_code: Key = a.physical_keycode if a.physical_keycode != KEY_NONE else a.keycode
	var b_code: Key = b.physical_keycode if b.physical_keycode != KEY_NONE else b.keycode
	return a_code == b_code


## Resets rebindable action to project default
func reset_action(action: StringName) -> void:
	assert(_defaults.has(action), "InputBindingManager: no default cached for " + action)
	InputMap.action_erase_events(action)
	for event: InputEvent in _defaults[action]:
		InputMap.action_add_event(action, event)
	_save()
	binding_changed.emit(action)


func reset_all() -> void:
	print_debug("Key bindings reset to default")
	for action: StringName in REBINDABLE_ACTIONS:
		reset_action(action)


## Returns first mouse [InputEventMouseButton] for [param action], or null if none
func get_mouse_event(action: StringName) -> InputEventMouseButton:
	assert(InputMap.has_action(action), "InputBindingManager: unknown action " + action)
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventMouseButton:
			return event
	return null


## Returns first keyboard [InputEventKey] for [param action], or null if none
func get_keyboard_event(action: StringName) -> InputEventKey:
	assert(InputMap.has_action(action), "InputBindingManager: unknown action " + action)
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			return event
	return null


func _cache_defaults() -> void:
	for action: StringName in REBINDABLE_ACTIONS:
		assert(InputMap.has_action(action), "InputBindingManager: action missing from project InputMap: " + action)
		_defaults[action] = InputMap.action_get_events(action).duplicate()


func _remove_keyboard_bindings(action: StringName) -> void:
	for event: InputEvent in InputMap.action_get_events(action).duplicate():
		if event is InputEventKey:
			InputMap.action_erase_event(action, event)


func _save() -> void:
	var config: ConfigFile = ConfigFile.new()
	for action: StringName in REBINDABLE_ACTIONS:
		var event: InputEventKey = get_keyboard_event(action)
		if event == null:
			continue
		(
			config
			. set_value(
				_SECTION,
				action,
				{
					&"physical": int(event.physical_keycode),
					&"logical": int(event.keycode),
				}
			)
		)
	config.save(_SAVE_PATH)


func _load() -> void:
	var config: ConfigFile = ConfigFile.new()
	if config.load(_SAVE_PATH) != OK:
		return
	for action: StringName in REBINDABLE_ACTIONS:
		if not config.has_section_key(_SECTION, action):
			continue
		var raw: Variant = config.get_value(_SECTION, action)
		var event: InputEventKey = InputEventKey.new()
		if raw is Dictionary:
			event.physical_keycode = (raw.get(&"physical", 0)) as Key
			event.keycode = (raw.get(&"logical", 0)) as Key
		elif raw is int:
			event.keycode = raw as Key
		_remove_keyboard_bindings(action)
		InputMap.action_add_event(action, event)
