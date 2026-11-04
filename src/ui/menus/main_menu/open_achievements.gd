extends UIButton


func _button_ready() -> void:
	if OS.has_feature("demo"):
		visible = false


func _button_pressed() -> void:
	ApplicationStateManager.request_open_menu(ApplicationStateManager.GameState.ACHIEVEMENTS_MENU)
