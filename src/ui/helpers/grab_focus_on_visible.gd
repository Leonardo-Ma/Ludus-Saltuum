## Grabs focus when parent becomes visible and a gamepad is active
## Attach to first focusable button in each menu
extends Control

@onready var button: BaseButton = get_parent()


func _ready() -> void:
	get_parent().visibility_changed.connect(_on_parent_visibility_changed)
	InputManager.device_changed.connect(_on_device_changed)

# add to grab focus only if gamepad is present: InputManager.is_gamepad_active()
	if button.is_visible_in_tree():
		print_debug(button.name, " Has focus")
		await get_tree().process_frame
		button.grab_focus()


func _on_parent_visibility_changed() -> void:
	# add to grab focus only if gamepad is present: InputManager.is_gamepad_active()
	if button.is_visible_in_tree() and not button.has_focus():
		button.grab_focus()
		print_debug(button.name, " Has focus")


func _on_device_changed(device: InputManager.Device) -> void:
	if device != InputManager.Device.KEYBOARD_MOUSE and button.is_visible_in_tree() and get_viewport().gui_get_focus_owner() == null:
		button.grab_focus()
		print_debug(button.name, " Has focus")
