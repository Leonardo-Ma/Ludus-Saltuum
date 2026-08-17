## Populates rebinding rows and manages keyboard capture for rebind
class_name KeyBindingsPanel
extends VBoxContainer

@export var _row_scene: PackedScene

var _listening: StringName = &""
var _rows: Dictionary[StringName, RebindingRow] = {}

@onready var _container: VBoxContainer = %RowsContainer


func _ready() -> void:
	assert(_row_scene != null, "KeyBindingsPanel: _row_scene not assigned in " + name)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visibility_changed.connect(_on_visibility_changed)
	_populate()


func _input(event: InputEvent) -> void:
	if _listening == &"" or not event.is_pressed() or event.is_echo():
		return
	if not event is InputEventKey:
		return
	if (event as InputEventKey).physical_keycode == KEY_ESCAPE:
		_stop_listening()
	else:
		InputBindingManager.rebind(_listening, event)
		_stop_listening()
	get_viewport().set_input_as_handled()


func _populate() -> void:
	for action: StringName in InputBindingManager.REBINDABLE_ACTIONS:
		var row: RebindingRow = _row_scene.instantiate() as RebindingRow
		_container.add_child(row)
		_rows[action] = row
		row.setup(action)
		row.rebind_requested.connect(_start_listening)
		row.reset_requested.connect(InputBindingManager.reset_action)


func _start_listening(action: StringName) -> void:
	if _listening != &"":
		_rows[_listening].set_listening(false)
	_listening = action
	_rows[action].set_listening(true)


func _stop_listening() -> void:
	if _listening == &"":
		return
	_rows[_listening].set_listening(false)
	_listening = &""


func _on_visibility_changed() -> void:
	if not visible:
		_stop_listening()
