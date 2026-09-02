## Grabs focus when parent becomes visible
## Attach to first focusable button in each menu
extends Control

@onready var button: BaseButton = get_parent()


func _ready() -> void:
	get_parent().visibility_changed.connect(_on_parent_visibility_changed)
	InputManager.device_changed.connect(_on_device_changed)

	if button.is_visible_in_tree():
		await get_tree().process_frame
		button.grab_focus()


func _on_parent_visibility_changed() -> void:
	if not button.is_visible_in_tree():
		return

	if InputManager.is_gamepad_active():
		await get_tree().process_frame
		button.grab_focus()
		print_debug(button.name, " Has focus")


func _on_device_changed(device: InputManager.Device) -> void:
	if device == InputManager.Device.KEYBOARD_MOUSE:
		return

	if not button.is_visible_in_tree():
		return

	await get_tree().process_frame
	button.grab_focus()
	print_debug(button.name, " Has focus")
