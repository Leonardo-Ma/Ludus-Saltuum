extends UIButton


func _button_ready() -> void:
	ApplicationStateManager.main_menu_opened.connect(_check_if_has_saves)
	SaveManager.save_changed.connect(_on_save_changed)
	_check_if_has_saves()


func _button_pressed() -> void:
	ApplicationStateManager.request_open_menu(ApplicationStateManager.GameState.SAVE_MENU)


func _on_save_changed(_slot_index: int) -> void:
	_check_if_has_saves()


func _check_if_has_saves() -> void:
	if SaveManager.has_any_save():
		visible = true
		return
	visible = false
