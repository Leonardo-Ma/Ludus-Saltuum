extends UIButton


func _button_ready() -> void:
	pass


func _button_pressed() -> void:
	OS.shell_open(ProjectSettings.globalize_path(SaveManager.SAVE_DIR))
