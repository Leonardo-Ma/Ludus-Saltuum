class_name SaveNamePopup
extends PopupTemplate

## Edits a save's display name and keeps the draft visible if writing fails

signal close_requested

var _submit: Callable

@onready var _slot_number_label: Label = %SlotNumberLabel
@onready var _name_input: LineEdit = %NameInput
@onready var _confirm_button: Button = %ConfirmButton
@onready var _cancel_button: Button = %CancelButton
@onready var _error_icon: TextureRect = %ErrorIcon


func _ready() -> void:
	_name_input.text_submitted.connect(_on_text_submitted)
	_confirm_button.pressed.connect(_on_confirm_pressed)
	_cancel_button.pressed.connect(close_requested.emit)


func prepare(slot_index: int, current_name: String, submit: Callable) -> void:
	_submit = submit
	_slot_number_label.text = "%02d" % (slot_index + 1)
	_name_input.text = current_name
	_error_icon.hide()


func focus_name() -> void:
	_name_input.grab_focus()
	_name_input.edit()
	_name_input.caret_column = _name_input.text.length()
	_name_input.select_all()


func hide_popup() -> void:
	_name_input.cancel_ime()
	hide()
	_submit = Callable()


func _input(event: InputEvent) -> void:
	if not is_visible_in_tree() or not event.is_action_pressed(&"ui_cancel", false, true):
		return

	get_viewport().set_input_as_handled()
	if _name_input.has_ime_text():
		_name_input.cancel_ime()
		return
	close_requested.emit()


func _unhandled_input(_event: InputEvent) -> void:
	if is_visible_in_tree():
		get_viewport().set_input_as_handled()


func _on_text_submitted(_display_name: String) -> void:
	if _name_input.has_ime_text():
		_name_input.apply_ime()
		return
	_on_confirm_pressed()


func _on_confirm_pressed() -> void:
	if _name_input.has_ime_text():
		_name_input.apply_ime()
	var saved: bool = _submit.call(_name_input.text)
	if saved:
		close_requested.emit()
	else:
		_error_icon.show()
