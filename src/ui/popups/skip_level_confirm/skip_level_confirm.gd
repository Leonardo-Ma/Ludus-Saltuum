# TODO Change to extend an abstract popup class
## Confirmation popup for skipping the current level chunk
extends PopupTemplate

@export var popups_view: PopupsManager

# TODO Check if should move this to respective yes and no buttons
@onready var _yes_button: Button = %YesButton
@onready var _no_button: Button = %NoButton


func _ready() -> void:
	process_mode = PROCESS_MODE_ALWAYS
	hide()
	_yes_button.pressed.connect(_on_yes_pressed)
	_no_button.pressed.connect(_on_no_pressed)


func _unhandled_input(event: InputEvent) -> void:
	if not event.is_action_pressed("skip_level") or event.is_echo():
		return

	if not ApplicationStateManager.is_gameplay_active():
		return

	if popups_view.request_open(self):
		get_viewport().set_input_as_handled()


func hide_popup() -> void:
	hide()


func show_popup() -> void:
	popups_view.request_open(self)


func _on_yes_pressed() -> void:
	popups_view.close_open_popup()
	ChunkManager.skip_current_chunk()


func _on_no_pressed() -> void:
	popups_view.close_open_popup()
