extends UIButton


func _button_ready() -> void:
	ApplicationStateManager.main_menu_opened.connect(_check_if_has_saves)
	_check_if_has_saves()


func _button_pressed() -> void:
	ApplicationStateManager.request_save_menu()


func _check_if_has_saves() -> void:
	if SaveManager.has_any_save():
		visible = true
		return
	visible = false
