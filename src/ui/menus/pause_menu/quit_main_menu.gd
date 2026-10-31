extends UIButton


func _button_ready() -> void:
	pass


func _button_pressed() -> void:
	ApplicationStateManager.request_main_menu()
