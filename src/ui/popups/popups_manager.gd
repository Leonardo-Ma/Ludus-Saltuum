## Coordinates popup exclusivity and cancel input
class_name PopupsManager
extends Control

@onready var confirmation_popup: ConfirmationPopup = $ConfirmationPopup

var _active_popup: PopupTemplate = null
var _was_visible_before_popup: bool = false

var _previous_focus_owner: Control


func _ready() -> void:
	for child: Node in get_children():
		assert(child is PopupTemplate, "Invalid popup child in " + name + ": " + child.name)

	assert(confirmation_popup != null and confirmation_popup.get_parent() == self, "ConfirmationPopup must be assigned as a direct child of " + name)

	for popup: PopupTemplate in get_children():
		popup.hide_popup()

	confirmation_popup.choice_made.connect(_on_confirmation_choice_made)
	ApplicationStateManager.state_changed.connect(_on_application_state_changed)


func _unhandled_input(event: InputEvent) -> void:
	if not is_visible_in_tree() or _active_popup == null:
		return

	if event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close_open_popup()


func has_open_popup() -> bool:
	return _active_popup != null


func open_confirmation(icons: Array[CompressedTexture2D]) -> bool:
	if has_open_popup():
		return false

	confirmation_popup.prepare_confirmation(icons)
	return _open_popup(confirmation_popup)


func request_open(popup: PopupTemplate) -> bool:
	if has_open_popup() or not is_visible_in_tree():
		return false

	assert(popup.get_parent() == self, "Popup does not belong to " + name)
	return _open_popup(popup)


func _open_popup(popup: PopupTemplate) -> bool:
	if has_open_popup():
		return false

	_was_visible_before_popup = visible
	visible = true
	_active_popup = popup
	PauseManager.request_pause("active_popup")
	MouseModeManager.request_mode(&"popup", Input.MOUSE_MODE_VISIBLE)
	_previous_focus_owner = get_viewport().gui_get_focus_owner()

	popup.show()
	return true


func close_open_popup() -> void:
	if _active_popup == null:
		return

	var popup: PopupTemplate = _active_popup
	_active_popup = null
	PauseManager.release_pause("active_popup")
	MouseModeManager.release(&"popup")
	popup.hide_popup()
	_restore_previous_focus.call_deferred()
	visible = _was_visible_before_popup


func close_all_popups() -> void:
	close_open_popup()


func _on_confirmation_choice_made(_confirmed: bool) -> void:
	if _active_popup == confirmation_popup:
		close_open_popup()


func _on_application_state_changed(_new_state: ApplicationStateManager.GameState, _previous_state: ApplicationStateManager.GameState) -> void:
	close_all_popups()


func _restore_previous_focus() -> void:
	await get_tree().process_frame

	if not is_instance_valid(_previous_focus_owner):
		return

	if not _previous_focus_owner.is_visible_in_tree():
		return

	if _previous_focus_owner.focus_mode == Control.FOCUS_NONE:
		return

	_previous_focus_owner.grab_focus()
	_previous_focus_owner = null
